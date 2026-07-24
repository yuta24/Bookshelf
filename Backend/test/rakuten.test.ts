import { describe, expect, it } from "vitest";
import { buildRequestUrl, mapRakutenResponse } from "../src/lib/rakuten.js";

describe("buildRequestUrl", () => {
  it("includes credentials and default parameters, and never leaks affiliateId when absent", () => {
    const url = buildRequestUrl({ applicationId: "app-id", accessKey: "pk_test" }, { keyword: "hello" });

    expect(url.hostname).toBe("openapi.rakuten.co.jp");
    expect(url.searchParams.get("applicationId")).toBe("app-id");
    expect(url.searchParams.get("accessKey")).toBe("pk_test");
    expect(url.searchParams.get("affiliateId")).toBeNull();
    expect(url.searchParams.get("format")).toBe("json");
    expect(url.searchParams.get("formatVersion")).toBe("2");
    expect(url.searchParams.get("outOfStockFlag")).toBe("1");
    expect(url.searchParams.get("booksGenreId")).toBe("001");
    expect(url.searchParams.get("keyword")).toBe("hello");
  });

  it("forwards genreId, sort and affiliateId when provided", () => {
    const url = buildRequestUrl(
      { applicationId: "app-id", accessKey: "pk_test", affiliateId: "aff-id" },
      { genreId: "002", sort: "sales" },
    );

    expect(url.searchParams.get("affiliateId")).toBe("aff-id");
    expect(url.searchParams.get("booksGenreId")).toBe("002");
    expect(url.searchParams.get("sort")).toBe("sales");
    expect(url.searchParams.get("keyword")).toBeNull();
  });
});

describe("mapRakutenResponse", () => {
  it("maps a well-formed formatVersion=2 response", () => {
    const body = {
      Items: [
        {
          title: "Some Book",
          author: "Some Author",
          itemPrice: 1500,
          affiliateUrl: "https://example.com/aff",
          largeImageUrl: "https://example.com/image.jpg",
          isbn: "9784000000000",
          publisherName: "Some Publisher",
          itemCaption: "A caption",
          salesDate: "2024年01月",
        },
      ],
    };

    expect(mapRakutenResponse(body)).toEqual([
      {
        title: "Some Book",
        author: "Some Author",
        price: 1500,
        affiliateUrl: "https://example.com/aff",
        imageUrl: "https://example.com/image.jpg",
        isbn: "9784000000000",
        publisher: "Some Publisher",
        caption: "A caption",
        salesDate: "2024年01月",
      },
    ]);
  });

  it("drops malformed items instead of throwing", () => {
    const body = {
      Items: [{ title: "missing other required fields" }],
    };

    expect(mapRakutenResponse(body)).toEqual([]);
  });

  it("falls back to an empty list for unexpected shapes", () => {
    expect(mapRakutenResponse(null)).toEqual([]);
    expect(mapRakutenResponse({})).toEqual([]);
    expect(mapRakutenResponse({ Items: "not-an-array" })).toEqual([]);
  });

  it("defaults optional fields to null when absent", () => {
    const body = {
      Items: [
        {
          title: "Some Book",
          author: "Some Author",
          itemPrice: 1500,
          largeImageUrl: "https://example.com/image.jpg",
          isbn: "9784000000000",
          publisherName: "Some Publisher",
          salesDate: "2024年01月",
        },
      ],
    };

    const [book] = mapRakutenResponse(body);
    expect(book?.affiliateUrl).toBeNull();
    expect(book?.caption).toBeNull();
  });

  it("normalizes an empty affiliateUrl string to null instead of leaking an unparsable URL", () => {
    const body = {
      Items: [
        {
          title: "Some Book",
          author: "Some Author",
          itemPrice: 1500,
          affiliateUrl: "",
          largeImageUrl: "https://example.com/image.jpg",
          isbn: "9784000000000",
          publisherName: "Some Publisher",
          salesDate: "2024年01月",
        },
      ],
    };

    const [book] = mapRakutenResponse(body);
    expect(book?.affiliateUrl).toBeNull();
  });
});
