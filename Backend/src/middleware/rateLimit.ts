import type { MiddlewareHandler } from "hono";

interface RateLimitOptions {
  windowMs: number;
  max: number;
}

export function rateLimit({ windowMs, max }: RateLimitOptions): MiddlewareHandler {
  const hits = new Map<string, { count: number; resetAt: number }>();

  const cleanup = setInterval(() => {
    const now = Date.now();
    for (const [key, entry] of hits) {
      if (entry.resetAt <= now) {
        hits.delete(key);
      }
    }
  }, windowMs);
  cleanup.unref();

  return async (c, next) => {
    // `Fly-Client-IP` is set by Fly's edge proxy and stripped/overwritten if a
    // client tries to spoof it, so it is safe to trust. Unlike
    // `X-Forwarded-For`, it must not be used as a fallback here: that header
    // is caller-controlled off Fly's edge, letting a client bypass the limit
    // by sending a fresh value on every request.
    const key = c.req.header("fly-client-ip") ?? "unknown";
    const now = Date.now();
    const entry = hits.get(key);

    if (!entry || entry.resetAt <= now) {
      hits.set(key, { count: 1, resetAt: now + windowMs });
    } else {
      entry.count += 1;
      if (entry.count > max) {
        return c.json({ error: "too many requests" }, 429);
      }
    }

    await next();
  };
}
