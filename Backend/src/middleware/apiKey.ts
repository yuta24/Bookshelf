import { timingSafeEqual } from "node:crypto";
import type { MiddlewareHandler } from "hono";

export function apiKeyAuth(expectedKey: string): MiddlewareHandler {
  return async (c, next) => {
    const provided = c.req.header("x-api-key");

    if (!provided || !safeEqual(provided, expectedKey)) {
      return c.json({ error: "unauthorized" }, 401);
    }

    await next();
  };
}

function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) {
    return false;
  }
  return timingSafeEqual(bufA, bufB);
}
