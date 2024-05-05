"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Cache = exports.ExpiringCacheEntry = void 0;
/* 5 minutes in milliseconds */
const EXPIRATION_BUFFER_MS = 300000;
/**
 * An entry in a cache that can expire in a certain amount of time.
 */
class ExpiringCacheEntry {
    /**
     * Create a new expiring token entry.
     */
    constructor(expiration) {
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
    expirationTime(expiresInSeconds) {
        return Date.now() + expiresInSeconds * 1000;
    }
}
exports.ExpiringCacheEntry = ExpiringCacheEntry;
/**
 * Base class for OIDC caches.
 */
class Cache {
    /**
     * Create a new cache.
     */
    constructor() {
        this.entries = new Map();
    }
    /**
     * Clear the cache.
     */
    clear() {
        this.entries.clear();
    }
    /**
     * Create a cache key from the address and username.
     */
    hashedCacheKey(address, username, callbackHash) {
        return JSON.stringify([address, username, callbackHash]);
    }
}
exports.Cache = Cache;
//# sourceMappingURL=cache.js.map