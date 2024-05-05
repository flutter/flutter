import { type AuthProvider } from './cmap/auth/auth_provider';
import { GSSAPI } from './cmap/auth/gssapi';
import { MongoCR } from './cmap/auth/mongocr';
import { MongoDBAWS } from './cmap/auth/mongodb_aws';
import { MongoDBOIDC } from './cmap/auth/mongodb_oidc';
import { Plain } from './cmap/auth/plain';
import { AuthMechanism } from './cmap/auth/providers';
import { ScramSHA1, ScramSHA256 } from './cmap/auth/scram';
import { X509 } from './cmap/auth/x509';
import { MongoInvalidArgumentError } from './error';

/** @internal */
const AUTH_PROVIDERS = new Map<AuthMechanism | string, () => AuthProvider>([
  [AuthMechanism.MONGODB_AWS, () => new MongoDBAWS()],
  [AuthMechanism.MONGODB_CR, () => new MongoCR()],
  [AuthMechanism.MONGODB_GSSAPI, () => new GSSAPI()],
  [AuthMechanism.MONGODB_OIDC, () => new MongoDBOIDC()],
  [AuthMechanism.MONGODB_PLAIN, () => new Plain()],
  [AuthMechanism.MONGODB_SCRAM_SHA1, () => new ScramSHA1()],
  [AuthMechanism.MONGODB_SCRAM_SHA256, () => new ScramSHA256()],
  [AuthMechanism.MONGODB_X509, () => new X509()]
]);

/**
 * Create a set of providers per client
 * to avoid sharing the provider's cache between different clients.
 * @internal
 */
export class MongoClientAuthProviders {
  private existingProviders: Map<AuthMechanism | string, AuthProvider> = new Map();

  /**
   * Get or create an authentication provider based on the provided mechanism.
   * We don't want to create all providers at once, as some providers may not be used.
   * @param name - The name of the provider to get or create.
   * @returns The provider.
   * @throws MongoInvalidArgumentError if the mechanism is not supported.
   * @internal
   */
  getOrCreateProvider(name: AuthMechanism | string): AuthProvider {
    const authProvider = this.existingProviders.get(name);
    if (authProvider) {
      return authProvider;
    }

    const provider = AUTH_PROVIDERS.get(name)?.();
    if (!provider) {
      throw new MongoInvalidArgumentError(`authMechanism ${name} not supported`);
    }

    this.existingProviders.set(name, provider);
    return provider;
  }
}
