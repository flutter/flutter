"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TokenEntryCache = exports.TokenEntry = void 0;
const cache_1 = require("./cache");
/* Default expiration is now for when no expiration provided */
const DEFAULT_EXPIRATION_SECS = 0;
/** @internal */
class TokenEntry extends cache_1.ExpiringCacheEntry {
    /**
     * Instantiate the entry.
     */
    constructor(tokenResult, serverInfo, expiration) {
        super(expiration);
        this.tokenResult = tokenResult;
        this.serverInfo = serverInfo;
    }
}
exports.TokenEntry = TokenEntry;
/**
 * Cache of OIDC token entries.
 * @internal
 */
class TokenEntryCache extends cache_1.Cache {
    /**
     * Set an entry in the token cache.
     */
    addEntry(address, username, callbackHash, tokenResult, serverInfo) {
        const entry = new TokenEntry(tokenResult, serverInfo, tokenResult.expiresInSeconds ?? DEFAULT_EXPIRATION_SECS);
        this.entries.set(this.cacheKey(address, username, callbackHash), entry);
        return entry;
    }
    /**
     * Delete an entry from the cache.
     */
    deleteEntry(address, username, callbackHash) {
        this.entries.delete(this.cacheKey(address, username, callbackHash));
    }
    /**
     * Get an entry from the cache.
     */
    getEntry(address, username, callbackHash) {
        return this.entries.get(this.cacheKey(address, username, callbackHash));
    }
    /**
     * Delete all expired entries from the cache.
     */
    deleteExpiredEntries() {
        for (const [key, entry] of this.entries) {
            if (!entry.isValid()) {
                this.entries.delete(key);
            }
        }
    }
    /**
     * Create a cache key from the address and username.
     */
    cacheKey(address, username, callbackHash) {
        return this.hashedCacheKey(address, username, callbackHash);
    }
}
exports.TokenEntryCache = TokenEntryCache;
//# sourceMappingURL=token_entry_cache.js.map