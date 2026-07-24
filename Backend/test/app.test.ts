import { afterEach, describe, expect, it, vi } from "vitest";
import { createApp } from "../src/app.js";
import type { AppConfig } from "../src/env.js";

const config: AppConfig = {
  rakutenApplicationId: "test-app-id",
  rakutenAccessKey: "pk_test-access-key",
  rakutenAffiliateId: undefined,
  apiKey: "test-api-key",
  port: 0,
};

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("GET /health", () => {
  it("is reachable without an API key", async () => {
    const app = createApp(config);
    const res = await app.request("/health");

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: "ok" });
  });
});

describe("GET /v1/books/search", () => {
  it("rejects requests without an API key", async () => {
    const app = createApp(config);
    const res = await app.request("/v1/books/search?keyword=foo");

    expect(res.status).toBe(401);
  });

  it("rejects requests with the wrong API key", async () => {
    const app = createApp(config);
    const res = await app.request("/v1/books/search?keyword=foo", {
      headers: { "x-api-key": "wrong" },
    });

    expect(res.status).toBe(401);
  });

  it("requires a keyword or isbn query parameter", async () => {
    const app = createApp(config);
    const res = await app.request("/v1/books/search", {
      headers: { "x-api-key": config.apiKey },
    });

    expect(res.status).toBe(400);
  });

  it("proxies to the Rakuten API and never exposes credentials to the caller", async () => {
    const fetchMock = vi.fn(async (input: URL | RequestInfo) => {
      const url = new URL(input.toString());
      expect(url.hostname).toBe("openapi.rakuten.co.jp");
      expect(url.searchParams.get("applicationId")).toBe("test-app-id");
      expect(url.searchParams.get("accessKey")).toBe("pk_test-access-key");
      expect(url.searchParams.get("keyword")).toBe("dune");

      return new Response(
        JSON.stringify({
          Items: [
            {
              title: "Dune",
              author: "Frank Herbert",
              itemPrice: 900,
              largeImageUrl: "https://example.com/dune.jpg",
              isbn: "9780000000001",
              publisherName: "Some Publisher",
              salesDate: "1965年",
            },
          ],
        }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    const app = createApp(config);
    const res = await app.request("/v1/books/search?keyword=dune", {
      headers: { "x-api-key": config.apiKey },
    });
    const body = (await res.json()) as { items: unknown[] };

    expect(res.status).toBe(200);
    expect(body.items).toHaveLength(1);
    expect(JSON.stringify(body)).not.toContain("test-app-id");
    expect(JSON.stringify(body)).not.toContain("pk_test-access-key");
  });

  it("returns 502 when the Rakuten API fails", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response("error", { status: 500 })),
    );

    const app = createApp(config);
    const res = await app.request("/v1/books/search?keyword=dune", {
      headers: { "x-api-key": config.apiKey },
    });

    expect(res.status).toBe(502);
  });
});

describe("GET /v1/books", () => {
  it("rejects an unsupported sort value", async () => {
    const app = createApp(config);
    const res = await app.request("/v1/books?sort=invalid", {
      headers: { "x-api-key": config.apiKey },
    });

    expect(res.status).toBe(400);
  });
});
