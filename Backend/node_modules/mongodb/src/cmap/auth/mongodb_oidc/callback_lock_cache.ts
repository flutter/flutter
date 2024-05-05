import { MongoInvalidArgumentError } from '../../../error';
import type { Connection } from '../../connection';
import type { MongoCredentials } from '../mongo_credentials';
import type {
  IdPServerInfo,
  IdPServerResponse,
  OIDCCallbackContext,
  OIDCRefreshFunction,
  OIDCRequestFunction
} from '../mongodb_oidc';
import { Cache } from './cache';

/** Error message for when request callback is missing. */
const REQUEST_CALLBACK_REQUIRED_ERROR =
  'Auth mechanism property REQUEST_TOKEN_CALLBACK is required.';
/* Counter for function "hashes".*/
let FN_HASH_COUNTER = 0;
/* No function present function */
const NO_FUNCTION: OIDCRequestFunction = async () => ({ accessToken: 'test' });
/* The map of function hashes */
const FN_HASHES = new WeakMap<OIDCRequestFunction | OIDCRefreshFunction, number>();
/* Put the no function hash in the map. */
FN_HASHES.set(NO_FUNCTION, FN_HASH_COUNTER);

/**
 * An entry of callbacks in the cache.
 */
interface CallbacksEntry {
  requestCallback: OIDCRequestFunction;
  refreshCallback?: OIDCRefreshFunction;
  callbackHash: string;
}

/**
 * A cache of request and refresh callbacks per server/user.
 */
export class CallbackLockCache extends Cache<CallbacksEntry> {
  /**
   * Get the callbacks for the connection and credentials. If an entry does not
   * exist a new one will get set.
   */
  getEntry(connection: Connection, credentials: MongoCredentials): CallbacksEntry {
    const requestCallback = credentials.mechanismProperties.REQUEST_TOKEN_CALLBACK;
    const refreshCallback = credentials.mechanismProperties.REFRESH_TOKEN_CALLBACK;
    if (!requestCallback) {
      throw new MongoInvalidArgumentError(REQUEST_CALLBACK_REQUIRED_ERROR);
    }
    const callbackHash = hashFunctions(requestCallback, refreshCallback);
    const key = this.cacheKey(connection.address, credentials.username, callbackHash);
    const entry = this.entries.get(key);
    if (entry) {
      return entry;
    }
    return this.addEntry(key, callbackHash, requestCallback, refreshCallback);
  }

  /**
   * Set locked callbacks on for connection and credentials.
   */
  private addEntry(
    key: string,
    callbackHash: string,
    requestCallback: OIDCRequestFunction,
    refreshCallback?: OIDCRefreshFunction
  ): CallbacksEntry {
    const entry = {
      requestCallback: withLock(requestCallback),
      refreshCallback: refreshCallback ? withLock(refreshCallback) : undefined,
      callbackHash: callbackHash
    };
    this.entries.set(key, entry);
    return entry;
  }

  /**
   * Create a cache key from the address and username.
   */
  cacheKey(address: string, username: string, callbackHash: string): string {
    return this.hashedCacheKey(address, username, callbackHash);
  }
}

/**
 * Ensure the callback is only executed one at a time.
 */
function withLock(callback: OIDCRequestFunction | OIDCRefreshFunction) {
  let lock: Promise<any> = Promise.resolve();
  return async (info: IdPServerInfo, context: OIDCCallbackContext): Promise<IdPServerResponse> => {
    await lock;
    lock = lock.then(() => callback(info, context));
    return lock;
  };
}

/**
 * Get the hash string for the request and refresh functions.
 */
function hashFunctions(requestFn: OIDCRequestFunction, refreshFn?: OIDCRefreshFunction): string {
  let requestHash = FN_HASHES.get(requestFn);
  let refreshHash = FN_HASHES.get(refreshFn ?? NO_FUNCTION);
  if (requestHash == null) {
    // Create a new one for the function and put it in the map.
    FN_HASH_COUNTER++;
    requestHash = FN_HASH_COUNTER;
    FN_HASHES.set(requestFn, FN_HASH_COUNTER);
  }
  if (refreshHash == null && refreshFn) {
    // Create a new one for the function and put it in the map.
    FN_HASH_COUNTER++;
    refreshHash = FN_HASH_COUNTER;
    FN_HASHES.set(refreshFn, FN_HASH_COUNTER);
  }
  return `${requestHash}-${refreshHash}`;
}
