import type { IdPServerInfo, IdPServerResponse } from '../mongodb_oidc';
import { Cache, ExpiringCacheEntry } from './cache';

/* Default expiration is now for when no expiration provided */
const DEFAULT_EXPIRATION_SECS = 0;

/** @internal */
export class TokenEntry extends ExpiringCacheEntry {
  tokenResult: IdPServerResponse;
  serverInfo: IdPServerInfo;

  /**
   * Instantiate the entry.
   */
  constructor(tokenResult: IdPServerResponse, serverInfo: IdPServerInfo, expiration: number) {
    super(expiration);
    this.tokenResult = tokenResult;
    this.serverInfo = serverInfo;
  }
}

/**
 * Cache of OIDC token entries.
 * @internal
 */
export class TokenEntryCache extends Cache<TokenEntry> {
  /**
   * Set an entry in the token cache.
   */
  addEntry(
    address: string,
    username: string,
    callbackHash: string,
    tokenResult: IdPServerResponse,
    serverInfo: IdPServerInfo
  ): TokenEntry {
    const entry = new TokenEntry(
      tokenResult,
      serverInfo,
      tokenResult.expiresInSeconds ?? DEFAULT_EXPIRATION_SECS
    );
    this.entries.set(this.cacheKey(address, username, callbackHash), entry);
    return entry;
  }

  /**
   * Delete an entry from the cache.
   */
  deleteEntry(address: string, username: string, callbackHash: string): void {
    this.entries.delete(this.cacheKey(address, username, callbackHash));
  }

  /**
   * Get an entry from the cache.
   */
  getEntry(address: string, username: string, callbackHash: string): TokenEntry | undefined {
    return this.entries.get(this.cacheKey(address, username, callbackHash));
  }

  /**
   * Delete all expired entries from the cache.
   */
  deleteExpiredEntries(): void {
    for (const [key, entry] of this.entries) {
      if (!entry.isValid()) {
        this.entries.delete(key);
      }
    }
  }

  /**
   * Create a cache key from the address and username.
   */
  cacheKey(address: string, username: string, callbackHash: string): string {
    return this.hashedCacheKey(address, username, callbackHash);
  }
}
