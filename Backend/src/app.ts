import { Hono } from "hono";
import { logger } from "hono/logger";
import { secureHeaders } from "hono/secure-headers";
import type { AppConfig } from "./env.js";
import { apiKeyAuth } from "./middleware/apiKey.js";
import { rateLimit } from "./middleware/rateLimit.js";
import { createBooksRoute } from "./routes/books.js";
import { health } from "./routes/health.js";

export function createApp(config: AppConfig): Hono {
  const app = new Hono();

  app.use("*", logger());
  app.use("*", secureHeaders());

  // Unauthenticated: used by Fly.io health checks.
  app.route("/health", health);

  app.use("/v1/*", apiKeyAuth(config.apiKey));
  app.use("/v1/*", rateLimit({ windowMs: 60_000, max: 30 }));
  app.route(
    "/v1/books",
    createBooksRoute({
      applicationId: config.rakutenApplicationId,
      accessKey: config.rakutenAccessKey,
      affiliateId: config.rakutenAffiliateId,
    }),
  );

  app.notFound((c) => c.json({ error: "not found" }, 404));

  return app;
}
