import type { AzureAccessToken } from './azure_service_workflow';
import { Cache, ExpiringCacheEntry } from './cache';

/** @internal */
export class AzureTokenEntry extends ExpiringCacheEntry {
  token: string;

  /**
   * Instantiate the entry.
   */
  constructor(token: string, expiration: number) {
    super(expiration);
    this.token = token;
  }
}

/**
 * A cache of access tokens from Azure.
 * @internal
 */
export class AzureTokenCache extends Cache<AzureTokenEntry> {
  /**
   * Add an entry to the cache.
   */
  addEntry(tokenAudience: string, token: AzureAccessToken): AzureTokenEntry {
    const entry = new AzureTokenEntry(token.access_token, token.expires_in);
    this.entries.set(tokenAudience, entry);
    return entry;
  }

  /**
   * Create a cache key.
   */
  cacheKey(tokenAudience: string): string {
    return tokenAudience;
  }

  /**
   * Delete an entry from the cache.
   */
  deleteEntry(tokenAudience: string): void {
    this.entries.delete(tokenAudience);
  }

  /**
   * Get an Azure token entry from the cache.
   */
  getEntry(tokenAudience: string): AzureTokenEntry | undefined {
    return this.entries.get(tokenAudience);
  }
}
