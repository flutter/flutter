/* 5 minutes in milliseconds */
const EXPIRATION_BUFFER_MS = 300000;

/**
 * An entry in a cache that can expire in a certain amount of time.
 */
export abstract class ExpiringCacheEntry {
  expiration: number;

  /**
   * Create a new expiring token entry.
   */
  constructor(expiration: number) {
    this.expiration = this.expirationTime(expiration);
  }
  /**
   * The entry is still valid if the expiration is more than
   * 5 minutes from the expiration time.
   */
  isValid() {
    return this.expiration - Date.now() > EXPIRATION_BUFFER_MS;
  }

  /**
   * Get an expiration time in milliseconds past epoch.
   */
  private expirationTime(expiresInSeconds: number): number {
    return Date.now() + expiresInSeconds * 1000;
  }
}

/**
 * Base class for OIDC caches.
 */
export abstract class Cache<T> {
  entries: Map<string, T>;

  /**
   * Create a new cache.
   */
  constructor() {
    this.entries = new Map<string, T>();
  }

  /**
   * Clear the cache.
   */
  clear() {
    this.entries.clear();
  }

  /**
   * Implement the cache key for the token.
   */
  abstract cacheKey(address: string, username: string, callbackHash: string): string;

  /**
   * Create a cache key from the address and username.
   */
  hashedCacheKey(address: string, username: string, callbackHash: string): string {
    return JSON.stringify([address, username, callbackHash]);
  }
}
