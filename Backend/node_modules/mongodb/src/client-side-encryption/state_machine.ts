import * as fs from 'fs/promises';
import { type MongoCryptContext, type MongoCryptKMSRequest } from 'mongodb-client-encryption';
import * as net from 'net';
import * as tls from 'tls';

import {
  type BSONSerializeOptions,
  deserialize,
  type Document,
  pluckBSONSerializeOptions,
  serialize
} from '../bson';
import { type ProxyOptions } from '../cmap/connection';
import { getSocks, type SocksLib } from '../deps';
import { type MongoClient, type MongoClientOptions } from '../mongo_client';
import { BufferPool, MongoDBCollectionNamespace, promiseWithResolvers } from '../utils';
import { type DataKey } from './client_encryption';
import { MongoCryptError } from './errors';
import { type MongocryptdManager } from './mongocryptd_manager';
import { type ClientEncryptionDataKeyProvider, type KMSProviders } from './providers';

let socks: SocksLib | null = null;
function loadSocks(): SocksLib {
  if (socks == null) {
    const socksImport = getSocks();
    if ('kModuleError' in socksImport) {
      throw socksImport.kModuleError;
    }
    socks = socksImport;
  }
  return socks;
}

// libmongocrypt states
const MONGOCRYPT_CTX_ERROR = 0;
const MONGOCRYPT_CTX_NEED_MONGO_COLLINFO = 1;
const MONGOCRYPT_CTX_NEED_MONGO_MARKINGS = 2;
const MONGOCRYPT_CTX_NEED_MONGO_KEYS = 3;
const MONGOCRYPT_CTX_NEED_KMS_CREDENTIALS = 7;
const MONGOCRYPT_CTX_NEED_KMS = 4;
const MONGOCRYPT_CTX_READY = 5;
const MONGOCRYPT_CTX_DONE = 6;

const HTTPS_PORT = 443;

const stateToString = new Map([
  [MONGOCRYPT_CTX_ERROR, 'MONGOCRYPT_CTX_ERROR'],
  [MONGOCRYPT_CTX_NEED_MONGO_COLLINFO, 'MONGOCRYPT_CTX_NEED_MONGO_COLLINFO'],
  [MONGOCRYPT_CTX_NEED_MONGO_MARKINGS, 'MONGOCRYPT_CTX_NEED_MONGO_MARKINGS'],
  [MONGOCRYPT_CTX_NEED_MONGO_KEYS, 'MONGOCRYPT_CTX_NEED_MONGO_KEYS'],
  [MONGOCRYPT_CTX_NEED_KMS_CREDENTIALS, 'MONGOCRYPT_CTX_NEED_KMS_CREDENTIALS'],
  [MONGOCRYPT_CTX_NEED_KMS, 'MONGOCRYPT_CTX_NEED_KMS'],
  [MONGOCRYPT_CTX_READY, 'MONGOCRYPT_CTX_READY'],
  [MONGOCRYPT_CTX_DONE, 'MONGOCRYPT_CTX_DONE']
]);

const INSECURE_TLS_OPTIONS = [
  'tlsInsecure',
  'tlsAllowInvalidCertificates',
  'tlsAllowInvalidHostnames',

  // These options are disallowed by the spec, so we explicitly filter them out if provided, even
  // though the StateMachine does not declare support for these options.
  'tlsDisableOCSPEndpointCheck',
  'tlsDisableCertificateRevocationCheck'
];

/**
 * Helper function for logging. Enabled by setting the environment flag MONGODB_CRYPT_DEBUG.
 * @param msg - Anything you want to be logged.
 */
function debug(msg: unknown) {
  if (process.env.MONGODB_CRYPT_DEBUG) {
    // eslint-disable-next-line no-console
    console.error(msg);
  }
}

declare module 'mongodb-client-encryption' {
  // the properties added to `MongoCryptContext` here are only used for the `StateMachine`'s
  // execute method and are not part of the C++ bindings.
  interface MongoCryptContext {
    id: number;
    document: Document;
    ns: string;
  }
}

/**
 * @public
 *
 * TLS options to use when connecting. The spec specifically calls out which insecure
 * tls options are not allowed:
 *
 *  - tlsAllowInvalidCertificates
 *  - tlsAllowInvalidHostnames
 *  - tlsInsecure
 *
 * These options are not included in the type, and are ignored if provided.
 */
export type ClientEncryptionTlsOptions = Pick<
  MongoClientOptions,
  'tlsCAFile' | 'tlsCertificateKeyFile' | 'tlsCertificateKeyFilePassword'
>;

/** @public */
export type CSFLEKMSTlsOptions = {
  aws?: ClientEncryptionTlsOptions;
  gcp?: ClientEncryptionTlsOptions;
  kmip?: ClientEncryptionTlsOptions;
  local?: ClientEncryptionTlsOptions;
  azure?: ClientEncryptionTlsOptions;
};

/**
 * @internal
 *
 * An interface representing an object that can be passed to the `StateMachine.execute` method.
 *
 * Not all properties are required for all operations.
 */
export interface StateMachineExecutable {
  _keyVaultNamespace: string;
  _keyVaultClient: MongoClient;
  askForKMSCredentials: () => Promise<KMSProviders>;

  /** only used for auto encryption */
  _metaDataClient?: MongoClient;
  /** only used for auto encryption */
  _mongocryptdClient?: MongoClient;
  /** only used for auto encryption */
  _mongocryptdManager?: MongocryptdManager;
}

export type StateMachineOptions = {
  /** socks5 proxy options, if set. */
  proxyOptions: ProxyOptions;

  /** TLS options for KMS requests, if set. */
  tlsOptions: CSFLEKMSTlsOptions;
} & Pick<BSONSerializeOptions, 'promoteLongs' | 'promoteValues'>;

/**
 * @internal
 * An internal class that executes across a MongoCryptContext until either
 * a finishing state or an error is reached. Do not instantiate directly.
 */
export class StateMachine {
  constructor(
    private options: StateMachineOptions,
    private bsonOptions = pluckBSONSerializeOptions(options)
  ) {}

  /**
   * Executes the state machine according to the specification
   */
  async execute<T extends Document>(
    executor: StateMachineExecutable,
    context: MongoCryptContext
  ): Promise<T> {
    const keyVaultNamespace = executor._keyVaultNamespace;
    const keyVaultClient = executor._keyVaultClient;
    const metaDataClient = executor._metaDataClient;
    const mongocryptdClient = executor._mongocryptdClient;
    const mongocryptdManager = executor._mongocryptdManager;
    let result: T | null = null;

    while (context.state !== MONGOCRYPT_CTX_DONE && context.state !== MONGOCRYPT_CTX_ERROR) {
      debug(`[context#${context.id}] ${stateToString.get(context.state) || context.state}`);

      switch (context.state) {
        case MONGOCRYPT_CTX_NEED_MONGO_COLLINFO: {
          const filter = deserialize(context.nextMongoOperation());
          if (!metaDataClient) {
            throw new MongoCryptError(
              'unreachable state machine state: entered MONGOCRYPT_CTX_NEED_MONGO_COLLINFO but metadata client is undefined'
            );
          }
          const collInfo = await this.fetchCollectionInfo(metaDataClient, context.ns, filter);

          if (collInfo) {
            context.addMongoOperationResponse(collInfo);
          }

          context.finishMongoOperation();
          break;
        }

        case MONGOCRYPT_CTX_NEED_MONGO_MARKINGS: {
          const command = context.nextMongoOperation();
          if (!mongocryptdClient) {
            throw new MongoCryptError(
              'unreachable state machine state: entered MONGOCRYPT_CTX_NEED_MONGO_MARKINGS but mongocryptdClient is undefined'
            );
          }

          // When we are using the shared library, we don't have a mongocryptd manager.
          const markedCommand: Uint8Array = mongocryptdManager
            ? await mongocryptdManager.withRespawn(
                this.markCommand.bind(this, mongocryptdClient, context.ns, command)
              )
            : await this.markCommand(mongocryptdClient, context.ns, command);

          context.addMongoOperationResponse(markedCommand);
          context.finishMongoOperation();
          break;
        }

        case MONGOCRYPT_CTX_NEED_MONGO_KEYS: {
          const filter = context.nextMongoOperation();
          const keys = await this.fetchKeys(keyVaultClient, keyVaultNamespace, filter);

          if (keys.length === 0) {
            // This is kind of a hack.  For `rewrapManyDataKey`, we have tests that
            // guarantee that when there are no matching keys, `rewrapManyDataKey` returns
            // nothing.  We also have tests for auto encryption that guarantee for `encrypt`
            // we return an error when there are no matching keys.  This error is generated in
            // subsequent iterations of the state machine.
            // Some apis (`encrypt`) throw if there are no filter matches and others (`rewrapManyDataKey`)
            // do not.  We set the result manually here, and let the state machine continue.  `libmongocrypt`
            // will inform us if we need to error by setting the state to `MONGOCRYPT_CTX_ERROR` but
            // otherwise we'll return `{ v: [] }`.
            result = { v: [] } as any as T;
          }
          for await (const key of keys) {
            context.addMongoOperationResponse(serialize(key));
          }

          context.finishMongoOperation();

          break;
        }

        case MONGOCRYPT_CTX_NEED_KMS_CREDENTIALS: {
          const kmsProviders = await executor.askForKMSCredentials();
          context.provideKMSProviders(serialize(kmsProviders));
          break;
        }

        case MONGOCRYPT_CTX_NEED_KMS: {
          const requests = Array.from(this.requests(context));
          await Promise.all(requests);

          context.finishKMSRequests();
          break;
        }

        case MONGOCRYPT_CTX_READY: {
          const finalizedContext = context.finalize();
          // @ts-expect-error finalize can change the state, check for error
          if (context.state === MONGOCRYPT_CTX_ERROR) {
            const message = context.status.message || 'Finalization error';
            throw new MongoCryptError(message);
          }
          result = deserialize(finalizedContext, this.options) as T;
          break;
        }

        default:
          throw new MongoCryptError(`Unknown state: ${context.state}`);
      }
    }

    if (context.state === MONGOCRYPT_CTX_ERROR || result == null) {
      const message = context.status.message;
      if (!message) {
        debug(
          `unidentifiable error in MongoCrypt - received an error status from \`libmongocrypt\` but received no error message.`
        );
      }
      throw new MongoCryptError(
        message ??
          'unidentifiable error in MongoCrypt - received an error status from `libmongocrypt` but received no error message.'
      );
    }

    return result;
  }

  /**
   * Handles the request to the KMS service. Exposed for testing purposes. Do not directly invoke.
   * @param kmsContext - A C++ KMS context returned from the bindings
   * @returns A promise that resolves when the KMS reply has be fully parsed
   */
  async kmsRequest(request: MongoCryptKMSRequest): Promise<void> {
    const parsedUrl = request.endpoint.split(':');
    const port = parsedUrl[1] != null ? Number.parseInt(parsedUrl[1], 10) : HTTPS_PORT;
    const options: tls.ConnectionOptions & { host: string; port: number } = {
      host: parsedUrl[0],
      servername: parsedUrl[0],
      port
    };
    const message = request.message;
    const buffer = new BufferPool();

    const netSocket: net.Socket = new net.Socket();
    let socket: tls.TLSSocket;

    function destroySockets() {
      for (const sock of [socket, netSocket]) {
        if (sock) {
          sock.removeAllListeners();
          sock.destroy();
        }
      }
    }

    function ontimeout() {
      return new MongoCryptError('KMS request timed out');
    }

    function onerror(cause: Error) {
      return new MongoCryptError('KMS request failed', { cause });
    }

    function onclose() {
      return new MongoCryptError('KMS request closed');
    }

    const tlsOptions = this.options.tlsOptions;
    if (tlsOptions) {
      const kmsProvider = request.kmsProvider as ClientEncryptionDataKeyProvider;
      const providerTlsOptions = tlsOptions[kmsProvider];
      if (providerTlsOptions) {
        const error = this.validateTlsOptions(kmsProvider, providerTlsOptions);
        if (error) {
          throw error;
        }
        try {
          await this.setTlsOptions(providerTlsOptions, options);
        } catch (err) {
          throw onerror(err);
        }
      }
    }

    const {
      promise: willConnect,
      reject: rejectOnNetSocketError,
      resolve: resolveOnNetSocketConnect
    } = promiseWithResolvers<void>();
    netSocket
      .once('timeout', () => rejectOnNetSocketError(ontimeout()))
      .once('error', err => rejectOnNetSocketError(onerror(err)))
      .once('close', () => rejectOnNetSocketError(onclose()))
      .once('connect', () => resolveOnNetSocketConnect());

    try {
      if (this.options.proxyOptions && this.options.proxyOptions.proxyHost) {
        netSocket.connect({
          host: this.options.proxyOptions.proxyHost,
          port: this.options.proxyOptions.proxyPort || 1080
        });
        await willConnect;

        try {
          socks ??= loadSocks();
          options.socket = (
            await socks.SocksClient.createConnection({
              existing_socket: netSocket,
              command: 'connect',
              destination: { host: options.host, port: options.port },
              proxy: {
                // host and port are ignored because we pass existing_socket
                host: 'iLoveJavaScript',
                port: 0,
                type: 5,
                userId: this.options.proxyOptions.proxyUsername,
                password: this.options.proxyOptions.proxyPassword
              }
            })
          ).socket;
        } catch (err) {
          throw onerror(err);
        }
      }

      socket = tls.connect(options, () => {
        socket.write(message);
      });

      const {
        promise: willResolveKmsRequest,
        reject: rejectOnTlsSocketError,
        resolve
      } = promiseWithResolvers<void>();
      socket
        .once('timeout', () => rejectOnTlsSocketError(ontimeout()))
        .once('error', err => rejectOnTlsSocketError(onerror(err)))
        .once('close', () => rejectOnTlsSocketError(onclose()))
        .on('data', data => {
          buffer.append(data);
          while (request.bytesNeeded > 0 && buffer.length) {
            const bytesNeeded = Math.min(request.bytesNeeded, buffer.length);
            request.addResponse(buffer.read(bytesNeeded));
          }

          if (request.bytesNeeded <= 0) {
            resolve();
          }
        });
      await willResolveKmsRequest;
    } finally {
      // There's no need for any more activity on this socket at this point.
      destroySockets();
    }
  }

  *requests(context: MongoCryptContext) {
    for (
      let request = context.nextKMSRequest();
      request != null;
      request = context.nextKMSRequest()
    ) {
      yield this.kmsRequest(request);
    }
  }

  /**
   * Validates the provided TLS options are secure.
   *
   * @param kmsProvider - The KMS provider name.
   * @param tlsOptions - The client TLS options for the provider.
   *
   * @returns An error if any option is invalid.
   */
  validateTlsOptions(
    kmsProvider: string,
    tlsOptions: ClientEncryptionTlsOptions
  ): MongoCryptError | void {
    const tlsOptionNames = Object.keys(tlsOptions);
    for (const option of INSECURE_TLS_OPTIONS) {
      if (tlsOptionNames.includes(option)) {
        return new MongoCryptError(`Insecure TLS options prohibited for ${kmsProvider}: ${option}`);
      }
    }
  }

  /**
   * Sets only the valid secure TLS options.
   *
   * @param tlsOptions - The client TLS options for the provider.
   * @param options - The existing connection options.
   */
  async setTlsOptions(
    tlsOptions: ClientEncryptionTlsOptions,
    options: tls.ConnectionOptions
  ): Promise<void> {
    if (tlsOptions.tlsCertificateKeyFile) {
      const cert = await fs.readFile(tlsOptions.tlsCertificateKeyFile);
      options.cert = options.key = cert;
    }
    if (tlsOptions.tlsCAFile) {
      options.ca = await fs.readFile(tlsOptions.tlsCAFile);
    }
    if (tlsOptions.tlsCertificateKeyFilePassword) {
      options.passphrase = tlsOptions.tlsCertificateKeyFilePassword;
    }
  }

  /**
   * Fetches collection info for a provided namespace, when libmongocrypt
   * enters the `MONGOCRYPT_CTX_NEED_MONGO_COLLINFO` state. The result is
   * used to inform libmongocrypt of the schema associated with this
   * namespace. Exposed for testing purposes. Do not directly invoke.
   *
   * @param client - A MongoClient connected to the topology
   * @param ns - The namespace to list collections from
   * @param filter - A filter for the listCollections command
   * @param callback - Invoked with the info of the requested collection, or with an error
   */
  async fetchCollectionInfo(
    client: MongoClient,
    ns: string,
    filter: Document
  ): Promise<Uint8Array | null> {
    const { db } = MongoDBCollectionNamespace.fromString(ns);

    const collections = await client
      .db(db)
      .listCollections(filter, {
        promoteLongs: false,
        promoteValues: false
      })
      .toArray();

    const info = collections.length > 0 ? serialize(collections[0]) : null;
    return info;
  }

  /**
   * Calls to the mongocryptd to provide markings for a command.
   * Exposed for testing purposes. Do not directly invoke.
   * @param client - A MongoClient connected to a mongocryptd
   * @param ns - The namespace (database.collection) the command is being executed on
   * @param command - The command to execute.
   * @param callback - Invoked with the serialized and marked bson command, or with an error
   */
  async markCommand(client: MongoClient, ns: string, command: Uint8Array): Promise<Uint8Array> {
    const options = { promoteLongs: false, promoteValues: false };
    const { db } = MongoDBCollectionNamespace.fromString(ns);
    const rawCommand = deserialize(command, options);

    const response = await client.db(db).command(rawCommand, options);

    return serialize(response, this.bsonOptions);
  }

  /**
   * Requests keys from the keyVault collection on the topology.
   * Exposed for testing purposes. Do not directly invoke.
   * @param client - A MongoClient connected to the topology
   * @param keyVaultNamespace - The namespace (database.collection) of the keyVault Collection
   * @param filter - The filter for the find query against the keyVault Collection
   * @param callback - Invoked with the found keys, or with an error
   */
  fetchKeys(
    client: MongoClient,
    keyVaultNamespace: string,
    filter: Uint8Array
  ): Promise<Array<DataKey>> {
    const { db: dbName, collection: collectionName } =
      MongoDBCollectionNamespace.fromString(keyVaultNamespace);

    return client
      .db(dbName)
      .collection<DataKey>(collectionName, { readConcern: { level: 'majority' } })
      .find(deserialize(filter))
      .toArray();
  }
}
