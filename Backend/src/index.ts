import { serve } from "@hono/node-server";
import { createApp } from "./app.js";
import { loadConfig } from "./env.js";

const config = loadConfig();
const app = createApp(config);

serve({ fetch: app.fetch, port: config.port }, (info) => {
  console.log(`bookshelf-backend listening on http://localhost:${info.port}`);
});
