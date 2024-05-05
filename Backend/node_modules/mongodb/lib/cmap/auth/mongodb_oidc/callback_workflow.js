"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CallbackWorkflow = void 0;
const bson_1 = require("bson");
const error_1 = require("../../../error");
const utils_1 = require("../../../utils");
const providers_1 = require("../providers");
const callback_lock_cache_1 = require("./callback_lock_cache");
const token_entry_cache_1 = require("./token_entry_cache");
/** The current version of OIDC implementation. */
const OIDC_VERSION = 0;
/** 5 minutes in seconds */
const TIMEOUT_S = 300;
/** Properties allowed on results of callbacks. */
const RESULT_PROPERTIES = ['accessToken', 'expiresInSeconds', 'refreshToken'];
/** Error message when the callback result is invalid. */
const CALLBACK_RESULT_ERROR = 'User provided OIDC callbacks must return a valid object with an accessToken.';
/**
 * OIDC implementation of a callback based workflow.
 * @internal
 */
class CallbackWorkflow {
    /**
     * Instantiate the workflow
     */
    constructor() {
        this.cache = new token_entry_cache_1.TokenEntryCache();
        this.callbackCache = new callback_lock_cache_1.CallbackLockCache();
    }
    /**
     * Get the document to add for speculative authentication. This also needs
     * to add a db field from the credentials source.
     */
    async speculativeAuth(credentials) {
        const document = startCommandDocument(credentials);
        document.db = credentials.source;
        return { speculativeAuthenticate: document };
    }
    /**
     * Execute the OIDC callback workflow.
     */
    async execute(connection, credentials, reauthenticating, response) {
        // Get the callbacks with locks from the callback lock cache.
        const { requestCallback, refreshCallback, callbackHash } = this.callbackCache.getEntry(connection, credentials);
        // Look for an existing entry in the cache.
        const entry = this.cache.getEntry(connection.address, credentials.username, callbackHash);
        let result;
        if (entry) {
            // Reauthentication cannot use a token from the cache since the server has
            // stated it is invalid by the request for reauthentication.
            if (entry.isValid() && !reauthenticating) {
                // Presence of a valid cache entry means we can skip to the finishing step.
                result = await this.finishAuthentication(connection, credentials, entry.tokenResult, response?.speculativeAuthenticate?.conversationId);
            }
            else {
                // Presence of an expired cache entry means we must fetch a new one and
                // then execute the final step.
                const tokenResult = await this.fetchAccessToken(connection, credentials, entry.serverInfo, reauthenticating, callbackHash, requestCallback, refreshCallback);
                try {
                    result = await this.finishAuthentication(connection, credentials, tokenResult, reauthenticating ? undefined : response?.speculativeAuthenticate?.conversationId);
                }
                catch (error) {
                    // If we are reauthenticating and this errors with reauthentication
                    // required, we need to do the entire process over again and clear
                    // the cache entry.
                    if (reauthenticating &&
                        error instanceof error_1.MongoError &&
                        error.code === error_1.MONGODB_ERROR_CODES.Reauthenticate) {
                        this.cache.deleteEntry(connection.address, credentials.username, callbackHash);
                        result = await this.execute(connection, credentials, reauthenticating);
                    }
                    else {
                        throw error;
                    }
                }
            }
        }
        else {
            // No entry in the cache requires us to do all authentication steps
            // from start to finish, including getting a fresh token for the cache.
            const startDocument = await this.startAuthentication(connection, credentials, reauthenticating, response);
            const conversationId = startDocument.conversationId;
            const serverResult = bson_1.BSON.deserialize(startDocument.payload.buffer);
            const tokenResult = await this.fetchAccessToken(connection, credentials, serverResult, reauthenticating, callbackHash, requestCallback, refreshCallback);
            result = await this.finishAuthentication(connection, credentials, tokenResult, conversationId);
        }
        return result;
    }
    /**
     * Starts the callback authentication process. If there is a speculative
     * authentication document from the initial handshake, then we will use that
     * value to get the issuer, otherwise we will send the saslStart command.
     */
    async startAuthentication(connection, credentials, reauthenticating, response) {
        let result;
        if (!reauthenticating && response?.speculativeAuthenticate) {
            result = response.speculativeAuthenticate;
        }
        else {
            result = await connection.command((0, utils_1.ns)(credentials.source), startCommandDocument(credentials), undefined);
        }
        return result;
    }
    /**
     * Finishes the callback authentication process.
     */
    async finishAuthentication(connection, credentials, tokenResult, conversationId) {
        const result = await connection.command((0, utils_1.ns)(credentials.source), finishCommandDocument(tokenResult.accessToken, conversationId), undefined);
        return result;
    }
    /**
     * Fetches an access token using either the request or refresh callbacks and
     * puts it in the cache.
     */
    async fetchAccessToken(connection, credentials, serverInfo, reauthenticating, callbackHash, requestCallback, refreshCallback) {
        // Get the token from the cache.
        const entry = this.cache.getEntry(connection.address, credentials.username, callbackHash);
        let result;
        const context = { timeoutSeconds: TIMEOUT_S, version: OIDC_VERSION };
        // Check if there's a token in the cache.
        if (entry) {
            // If the cache entry is valid, return the token result.
            if (entry.isValid() && !reauthenticating) {
                return entry.tokenResult;
            }
            // If the cache entry is not valid, remove it from the cache and first attempt
            // to use the refresh callback to get a new token. If no refresh callback
            // exists, then fallback to the request callback.
            if (refreshCallback) {
                context.refreshToken = entry.tokenResult.refreshToken;
                result = await refreshCallback(serverInfo, context);
            }
            else {
                result = await requestCallback(serverInfo, context);
            }
        }
        else {
            // With no token in the cache we use the request callback.
            result = await requestCallback(serverInfo, context);
        }
        // Validate that the result returned by the callback is acceptable. If it is not
        // we must clear the token result from the cache.
        if (isCallbackResultInvalid(result)) {
            this.cache.deleteEntry(connection.address, credentials.username, callbackHash);
            throw new error_1.MongoMissingCredentialsError(CALLBACK_RESULT_ERROR);
        }
        // Cleanup the cache.
        this.cache.deleteExpiredEntries();
        // Put the new entry into the cache.
        this.cache.addEntry(connection.address, credentials.username || '', callbackHash, result, serverInfo);
        return result;
    }
}
exports.CallbackWorkflow = CallbackWorkflow;
/**
 * Generate the finishing command document for authentication. Will be a
 * saslStart or saslContinue depending on the presence of a conversation id.
 */
function finishCommandDocument(token, conversationId) {
    if (conversationId != null && typeof conversationId === 'number') {
        return {
            saslContinue: 1,
            conversationId: conversationId,
            payload: new bson_1.Binary(bson_1.BSON.serialize({ jwt: token }))
        };
    }
    // saslContinue requires a conversationId in the command to be valid so in this
    // case the server allows "step two" to actually be a saslStart with the token
    // as the jwt since the use of the cached value has no correlating conversating
    // on the particular connection.
    return {
        saslStart: 1,
        mechanism: providers_1.AuthMechanism.MONGODB_OIDC,
        payload: new bson_1.Binary(bson_1.BSON.serialize({ jwt: token }))
    };
}
/**
 * Determines if a result returned from a request or refresh callback
 * function is invalid. This means the result is nullish, doesn't contain
 * the accessToken required field, and does not contain extra fields.
 */
function isCallbackResultInvalid(tokenResult) {
    if (tokenResult == null || typeof tokenResult !== 'object')
        return true;
    if (!('accessToken' in tokenResult))
        return true;
    return !Object.getOwnPropertyNames(tokenResult).every(prop => RESULT_PROPERTIES.includes(prop));
}
/**
 * Generate the saslStart command document.
 */
function startCommandDocument(credentials) {
    const payload = {};
    if (credentials.username) {
        payload.n = credentials.username;
    }
    return {
        saslStart: 1,
        autoAuthorize: 1,
        mechanism: providers_1.AuthMechanism.MONGODB_OIDC,
        payload: new bson_1.Binary(bson_1.BSON.serialize(payload))
    };
}
//# sourceMappingURL=callback_workflow.js.map