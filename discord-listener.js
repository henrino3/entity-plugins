#!/usr/bin/env node
/**
 * Entity Linker — Standalone Discord Message Listener
 * 
 * Watches all messages sent by the SuperAda bot in configured guilds.
 * When a message contains local file paths (~/clawd/..., /home/.../clawd/..., etc.),
 * it immediately edits the message to replace them with Entity HTTP URLs.
 * 
 * Runs as a separate process alongside OpenClaw — completely independent.
 * Uses the same bot token as SuperAda.
 */

import { Client, GatewayIntentBits, Partials } from "discord.js";
import { replaceEntityPaths } from "./src/rewrite-paths.js";

// --- Config ---
const BOT_TOKEN = process.env.DISCORD_BOT_TOKEN;
if (!BOT_TOKEN) {
  console.error("DISCORD_BOT_TOKEN is required");
  process.exit(1);
}

// Guild IDs to monitor (empty = all guilds)
const MONITOR_GUILD_IDS = process.env.MONITOR_GUILD_IDS
  ? process.env.MONITOR_GUILD_IDS.split(",").map(s => s.trim())
  : [];

// --- Client ---
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.DirectMessages,
  ],
  partials: [Partials.Message, Partials.Channel],
});

let botUserId = null;

client.once("ready", () => {
  botUserId = client.user.id;
  console.log(`[entity-linker] Logged in as ${client.user.tag} (${botUserId})`);
  console.log(`[entity-linker] Monitoring ${MONITOR_GUILD_IDS.length ? MONITOR_GUILD_IDS.join(", ") : "all guilds"}`);
});

client.on("messageCreate", async (message) => {
  // Only process our own bot's messages
  if (message.author.id !== botUserId) return;

  // Skip if no text content
  if (!message.content || message.content.length === 0) return;

  // Guild filter
  if (MONITOR_GUILD_IDS.length > 0 && message.guildId && !MONITOR_GUILD_IDS.includes(message.guildId)) return;

  // Attempt rewrite
  const rewritten = replaceEntityPaths(message.content);
  if (rewritten === message.content) return; // No paths found

  try {
    await message.edit(rewritten);
    console.log(`[entity-linker] Rewrote message ${message.id} in ${message.channel.id}`);
  } catch (err) {
    console.error(`[entity-linker] Failed to edit message ${message.id}:`, err.message);
  }
});

// Also handle message updates (in case OpenClaw edits a message with paths)
client.on("messageUpdate", async (_oldMessage, newMessage) => {
  // Fetch partial if needed
  if (newMessage.partial) {
    try { newMessage = await newMessage.fetch(); } catch { return; }
  }

  // Only process our own bot's messages
  if (newMessage.author?.id !== botUserId) return;
  if (!newMessage.content || newMessage.content.length === 0) return;

  // Guild filter
  if (MONITOR_GUILD_IDS.length > 0 && newMessage.guildId && !MONITOR_GUILD_IDS.includes(newMessage.guildId)) return;

  const rewritten = replaceEntityPaths(newMessage.content);
  if (rewritten === newMessage.content) return;

  try {
    await newMessage.edit(rewritten);
    console.log(`[entity-linker] Rewrote updated message ${newMessage.id}`);
  } catch (err) {
    // Avoid infinite edit loops — if edit fails, just log
    if (err.code !== 30046) { // Rate limited edits
      console.error(`[entity-linker] Failed to edit updated message ${newMessage.id}:`, err.message);
    }
  }
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("[entity-linker] SIGTERM received, shutting down...");
  client.destroy();
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("[entity-linker] SIGINT received, shutting down...");
  client.destroy();
  process.exit(0);
});

// --- Start ---
client.login(BOT_TOKEN).catch((err) => {
  console.error("[entity-linker] Login failed:", err.message);
  process.exit(1);
});
