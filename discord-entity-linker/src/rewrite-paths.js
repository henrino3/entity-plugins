export const ENTITY_OUTPUT_BASE_URL = "http://100.106.69.9:3000/output/";

const LOCAL_OUTPUT_PATH_PATTERN =
  /(?:~|\/Users\/[^/\s]+|\/home\/[^/\s]+)\/clawd\/(?:output\/)?([^\s<>()\[\]{}"'`]+)/g;
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

  return text.replace(LOCAL_OUTPUT_PATH_PATTERN, (_match, relativePath) => {
    const { path, trailingPunctuation } = splitTrailingPunctuation(relativePath);
    const url = `${baseUrl}${path}`;

    if (!trailingPunctuation) {
      return url;
    }

    return `<${url}>${trailingPunctuation}`;
  });
}
