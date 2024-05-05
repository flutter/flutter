"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MongoClientAuthProviders = void 0;
const gssapi_1 = require("./cmap/auth/gssapi");
const mongocr_1 = require("./cmap/auth/mongocr");
const mongodb_aws_1 = require("./cmap/auth/mongodb_aws");
const mongodb_oidc_1 = require("./cmap/auth/mongodb_oidc");
const plain_1 = require("./cmap/auth/plain");
const providers_1 = require("./cmap/auth/providers");
const scram_1 = require("./cmap/auth/scram");
const x509_1 = require("./cmap/auth/x509");
const error_1 = require("./error");
/** @internal */
const AUTH_PROVIDERS = new Map([
    [providers_1.AuthMechanism.MONGODB_AWS, () => new mongodb_aws_1.MongoDBAWS()],
    [providers_1.AuthMechanism.MONGODB_CR, () => new mongocr_1.MongoCR()],
    [providers_1.AuthMechanism.MONGODB_GSSAPI, () => new gssapi_1.GSSAPI()],
    [providers_1.AuthMechanism.MONGODB_OIDC, () => new mongodb_oidc_1.MongoDBOIDC()],
    [providers_1.AuthMechanism.MONGODB_PLAIN, () => new plain_1.Plain()],
    [providers_1.AuthMechanism.MONGODB_SCRAM_SHA1, () => new scram_1.ScramSHA1()],
    [providers_1.AuthMechanism.MONGODB_SCRAM_SHA256, () => new scram_1.ScramSHA256()],
    [providers_1.AuthMechanism.MONGODB_X509, () => new x509_1.X509()]
]);
/**
 * Create a set of providers per client
 * to avoid sharing the provider's cache between different clients.
 * @internal
 */
class MongoClientAuthProviders {
    constructor() {
        this.existingProviders = new Map();
    }
    /**
     * Get or create an authentication provider based on the provided mechanism.
     * We don't want to create all providers at once, as some providers may not be used.
     * @param name - The name of the provider to get or create.
     * @returns The provider.
     * @throws MongoInvalidArgumentError if the mechanism is not supported.
     * @internal
     */
    getOrCreateProvider(name) {
        const authProvider = this.existingProviders.get(name);
        if (authProvider) {
            return authProvider;
        }
        const provider = AUTH_PROVIDERS.get(name)?.();
        if (!provider) {
            throw new error_1.MongoInvalidArgumentError(`authMechanism ${name} not supported`);
        }
        this.existingProviders.set(name, provider);
        return provider;
    }
}
exports.MongoClientAuthProviders = MongoClientAuthProviders;
//# sourceMappingURL=mongo_client_auth_providers.js.map