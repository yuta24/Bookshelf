import { Hono, type Context } from "hono";
import { RakutenApiError, searchBooks, type RakutenConfig } from "../lib/rakuten.js";

const ALLOWED_SORTS = new Set(["-releaseDate", "sales"]);

export function createBooksRoute(config: RakutenConfig): Hono {
  const books = new Hono();

  // GET /v1/books/search?keyword=... or ?isbn=...
  books.get("/search", async (c) => {
    const keyword = c.req.query("keyword")?.trim();
    const isbn = c.req.query("isbn")?.trim();
    const query = isbn || keyword;

    if (!query) {
      return c.json({ error: "either `keyword` or `isbn` query parameter is required" }, 400);
    }

    try {
      const items = await searchBooks(config, { keyword: query });
      return c.json({ items });
    } catch (error) {
      return handleRakutenError(c, error);
    }
  });

  // GET /v1/books?genreId=001&sort=-releaseDate  (new arrivals / bestsellers)
  books.get("/", async (c) => {
    const genreId = c.req.query("genreId") ?? "001";
    const sort = c.req.query("sort") ?? "-releaseDate";

    if (!ALLOWED_SORTS.has(sort)) {
      return c.json({ error: "`sort` must be one of: -releaseDate, sales" }, 400);
    }

    try {
      const items = await searchBooks(config, { genreId, sort });
      return c.json({ items });
    } catch (error) {
      return handleRakutenError(c, error);
    }
  });

  return books;
}

function handleRakutenError(c: Context, error: unknown): Response {
  if (error instanceof RakutenApiError) {
    console.error("rakuten api error", error.status, error.message);
    return c.json({ error: "failed to fetch from rakuten api" }, 502);
  }
  console.error("unexpected error handling books route", error);
  return c.json({ error: "internal server error" }, 500);
}
