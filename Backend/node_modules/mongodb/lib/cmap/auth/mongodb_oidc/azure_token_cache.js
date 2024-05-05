"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AzureTokenCache = exports.AzureTokenEntry = void 0;
const cache_1 = require("./cache");
/** @internal */
class AzureTokenEntry extends cache_1.ExpiringCacheEntry {
    /**
     * Instantiate the entry.
     */
    constructor(token, expiration) {
        super(expiration);
        this.token = token;
    }
}
exports.AzureTokenEntry = AzureTokenEntry;
/**
 * A cache of access tokens from Azure.
 * @internal
 */
class AzureTokenCache extends cache_1.Cache {
    /**
     * Add an entry to the cache.
     */
    addEntry(tokenAudience, token) {
        const entry = new AzureTokenEntry(token.access_token, token.expires_in);
        this.entries.set(tokenAudience, entry);
        return entry;
    }
    /**
     * Create a cache key.
     */
    cacheKey(tokenAudience) {
        return tokenAudience;
    }
    /**
     * Delete an entry from the cache.
     */
    deleteEntry(tokenAudience) {
        this.entries.delete(tokenAudience);
    }
    /**
     * Get an Azure token entry from the cache.
     */
    getEntry(tokenAudience) {
        return this.entries.get(tokenAudience);
    }
}
exports.AzureTokenCache = AzureTokenCache;
//# sourceMappingURL=azure_token_cache.js.map