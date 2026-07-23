export interface AppConfig {
  rakutenApplicationId: string;
  rakutenAffiliateId?: string;
  apiKey: string;
  port: number;
}

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function loadConfig(): AppConfig {
  return {
    rakutenApplicationId: required("RAKUTEN_APPLICATION_ID"),
    rakutenAffiliateId: process.env.RAKUTEN_AFFILIATE_ID || undefined,
    apiKey: required("API_KEY"),
    port: Number(process.env.PORT ?? 8080),
  };
}
