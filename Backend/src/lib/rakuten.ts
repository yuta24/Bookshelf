// Rakuten migrated this API off `app.rakuten.co.jp` in 2026; the old domain
// was fully decommissioned on 2026-05-13 and now only 403s.
const RAKUTEN_ENDPOINT = "https://openapi.rakuten.co.jp/services/api/BooksTotal/Search/20170404";
const REQUEST_TIMEOUT_MS = 8_000;

export interface RakutenConfig {
  applicationId: string;
  // Required alongside applicationId since the 2026 auth overhaul. Issued
  // together with applicationId when (re-)registering the app in the
  // Rakuten Developers console.
  accessKey: string;
  affiliateId?: string;
}

export interface RakutenSearchParams {
  keyword?: string;
  genreId?: string;
  sort?: string;
}

export interface Book {
  title: string;
  author: string;
  price: number;
  affiliateUrl: string | null;
  imageUrl: string;
  isbn: string;
  publisher: string;
  caption: string | null;
  salesDate: string;
}

export class RakutenApiError extends Error {
  readonly status?: number;

  constructor(message: string, status?: number) {
    super(message);
    this.name = "RakutenApiError";
    this.status = status;
  }
}

export async function searchBooks(config: RakutenConfig, params: RakutenSearchParams): Promise<Book[]> {
  const url = buildRequestUrl(config, params);

  let response: Response;
  try {
    response = await fetch(url, {
      headers: { accept: "application/json" },
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
  } catch {
    throw new RakutenApiError("failed to reach rakuten api");
  }

  if (!response.ok) {
    throw new RakutenApiError(`rakuten api responded with status ${response.status}`, response.status);
  }

  const body: unknown = await response.json();
  return mapRakutenResponse(body);
}

export function buildRequestUrl(config: RakutenConfig, params: RakutenSearchParams): URL {
  const url = new URL(RAKUTEN_ENDPOINT);
  url.searchParams.set("applicationId", config.applicationId);
  url.searchParams.set("accessKey", config.accessKey);
  if (config.affiliateId) {
    url.searchParams.set("affiliateId", config.affiliateId);
  }
  url.searchParams.set("format", "json");
  url.searchParams.set("formatVersion", "2");
  url.searchParams.set("outOfStockFlag", "1");
  url.searchParams.set("booksGenreId", params.genreId ?? "001");
  if (params.keyword) {
    url.searchParams.set("keyword", params.keyword);
  }
  if (params.sort) {
    url.searchParams.set("sort", params.sort);
  }
  return url;
}

export function mapRakutenResponse(body: unknown): Book[] {
  if (!isRecord(body) || !Array.isArray(body.Items)) {
    return [];
  }

  return body.Items.filter(isRecord)
    .map(toBook)
    .filter((book): book is Book => book !== null);
}

function toBook(item: Record<string, unknown>): Book | null {
  const { title, author, itemPrice, largeImageUrl, isbn, publisherName, salesDate } = item;

  if (
    typeof title !== "string" ||
    typeof author !== "string" ||
    typeof itemPrice !== "number" ||
    typeof largeImageUrl !== "string" ||
    typeof isbn !== "string" ||
    typeof publisherName !== "string" ||
    typeof salesDate !== "string"
  ) {
    return null;
  }

  return {
    title,
    author,
    price: itemPrice,
    affiliateUrl: typeof item.affiliateUrl === "string" ? item.affiliateUrl : null,
    imageUrl: largeImageUrl,
    isbn,
    publisher: publisherName,
    caption: typeof item.itemCaption === "string" ? item.itemCaption : null,
    salesDate,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
