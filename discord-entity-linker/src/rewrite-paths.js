export const ENTITY_OUTPUT_BASE_URL = "http://100.106.69.9:3000/output/";

// Matches:
// 1. ~/clawd/...  or  ~/clawd/output/...
// 2. /home/<user>/clawd/...  or  /home/<user>/clawd/output/...
// 3. /Users/<user>/clawd/...  or  /Users/<user>/clawd/output/...
// 4. ~/.openclaw/workspace/...  or  ~/.openclaw-<name>/workspace/...
// 5. Bare output/ at start of line or after whitespace/punctuation (e.g. "output/soteria/file.md")
const PATTERNS = [
  // ~/clawd/ paths (with optional output/ prefix)
  { regex: /(?:~|\/Users\/[^/\s]+|\/home\/[^/\s]+)\/clawd\/(?:output\/)?([^\s<>()\[\]{}"'`]+)/g },
  // ~/.openclaw*/workspace/ paths
  { regex: /~\/\.openclaw(?:-[a-zA-Z0-9]+)?\/workspace\/([^\s<>()\[\]{}"'`]+)/g },
  // Bare output/ paths (must be preceded by start-of-line, whitespace, or common delimiters)
  { regex: /(?:^|(?<=[\s:]))output\/([^\s<>()\[\]{}"'`]+)/gm },
];

const TRAILING_PUNCTUATION_PATTERN = /[.,!?;:]+$/;

export function getEntityOutputBaseUrl() {
  const override = globalThis.process?.env?.ENTITY_OUTPUT_BASE_URL?.trim();
  if (!override) {
    return ENTITY_OUTPUT_BASE_URL;
  }

  return override.endsWith("/") ? override : `${override}/`;
}

function splitTrailingPunctuation(relativePath) {
  const normalizedPath = String(relativePath).replace(/^\/+/, "");
  const trailingPunctuation = normalizedPath.match(TRAILING_PUNCTUATION_PATTERN)?.[0] ?? "";

  if (!trailingPunctuation) {
    return { path: normalizedPath, trailingPunctuation: "" };
  }

  return {
    path: normalizedPath.slice(0, -trailingPunctuation.length),
    trailingPunctuation,
  };
}

export function replaceEntityPaths(text) {
  if (typeof text !== "string" || text.length === 0) {
    return text;
  }

  const baseUrl = getEntityOutputBaseUrl();
  let result = text;

  for (const { regex } of PATTERNS) {
    // Reset regex state for each call
    const re = new RegExp(regex.source, regex.flags);
    result = result.replace(re, (_match, relativePath) => {
      const { path, trailingPunctuation } = splitTrailingPunctuation(relativePath);
      const url = `${baseUrl}${path}`;

      if (!trailingPunctuation) {
        return url;
      }

      return `<${url}>${trailingPunctuation}`;
    });
  }

  return result;
}
