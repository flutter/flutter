"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MongoClient = exports.ServerApiVersion = void 0;
const fs_1 = require("fs");
const util_1 = require("util");
const bson_1 = require("./bson");
const change_stream_1 = require("./change_stream");
const mongo_credentials_1 = require("./cmap/auth/mongo_credentials");
const providers_1 = require("./cmap/auth/providers");
const connection_string_1 = require("./connection_string");
const constants_1 = require("./constants");
const db_1 = require("./db");
const error_1 = require("./error");
const mongo_client_auth_providers_1 = require("./mongo_client_auth_providers");
const mongo_logger_1 = require("./mongo_logger");
const mongo_types_1 = require("./mongo_types");
const execute_operation_1 = require("./operations/execute_operation");
const run_command_1 = require("./operations/run_command");
const read_preference_1 = require("./read_preference");
const server_selection_1 = require("./sdam/server_selection");
const topology_1 = require("./sdam/topology");
const sessions_1 = require("./sessions");
const utils_1 = require("./utils");
/** @public */
exports.ServerApiVersion = Object.freeze({
    v1: '1'
});
/** @internal */
const kOptions = Symbol('options');
/**
 * The **MongoClient** class is a class that allows for making Connections to MongoDB.
 * @public
 *
 * @remarks
 * The programmatically provided options take precedence over the URI options.
 *
 * @example
 * ```ts
 * import { MongoClient } from 'mongodb';
 *
 * // Enable command monitoring for debugging
 * const client = new MongoClient('mongodb://localhost:27017', { monitorCommands: true });
 *
 * client.on('commandStarted', started => console.log(started));
 * client.db().collection('pets');
 * await client.insertOne({ name: 'spot', kind: 'dog' });
 * ```
 */
class MongoClient extends mongo_types_1.TypedEventEmitter {
    constructor(url, options) {
        super();
        this[kOptions] = (0, connection_string_1.parseOptions)(url, this, options);
        const shouldSetLogger = Object.values(this[kOptions].mongoLoggerOptions.componentSeverities).some(value => value !== mongo_logger_1.SeverityLevel.OFF);
        this.mongoLogger = shouldSetLogger
            ? new mongo_logger_1.MongoLogger(this[kOptions].mongoLoggerOptions)
            : undefined;
        // eslint-disable-next-line @typescript-eslint/no-this-alias
        const client = this;
        // The internal state
        this.s = {
            url,
            bsonOptions: (0, bson_1.resolveBSONOptions)(this[kOptions]),
            namespace: (0, utils_1.ns)('admin'),
            hasBeenClosed: false,
            sessionPool: new sessions_1.ServerSessionPool(this),
            activeSessions: new Set(),
            authProviders: new mongo_client_auth_providers_1.MongoClientAuthProviders(),
            get options() {
                return client[kOptions];
            },
            get readConcern() {
                return client[kOptions].readConcern;
            },
            get writeConcern() {
                return client[kOptions].writeConcern;
            },
            get readPreference() {
                return client[kOptions].readPreference;
            },
            get isMongoClient() {
                return true;
            }
        };
        this.checkForNonGenuineHosts();
    }
    /** @internal */
    checkForNonGenuineHosts() {
        const documentDBHostnames = this[kOptions].hosts.filter((hostAddress) => (0, utils_1.isHostMatch)(utils_1.DOCUMENT_DB_CHECK, hostAddress.host));
        const srvHostIsDocumentDB = (0, utils_1.isHostMatch)(utils_1.DOCUMENT_DB_CHECK, this[kOptions].srvHost);
        const cosmosDBHostnames = this[kOptions].hosts.filter((hostAddress) => (0, utils_1.isHostMatch)(utils_1.COSMOS_DB_CHECK, hostAddress.host));
        const srvHostIsCosmosDB = (0, utils_1.isHostMatch)(utils_1.COSMOS_DB_CHECK, this[kOptions].srvHost);
        if (documentDBHostnames.length !== 0 || srvHostIsDocumentDB) {
            this.mongoLogger?.info('client', utils_1.DOCUMENT_DB_MSG);
        }
        else if (cosmosDBHostnames.length !== 0 || srvHostIsCosmosDB) {
            this.mongoLogger?.info('client', utils_1.COSMOS_DB_MSG);
        }
    }
    /** @see MongoOptions */
    get options() {
        return Object.freeze({ ...this[kOptions] });
    }
    get serverApi() {
        return this[kOptions].serverApi && Object.freeze({ ...this[kOptions].serverApi });
    }
    /**
     * Intended for APM use only
     * @internal
     */
    get monitorCommands() {
        return this[kOptions].monitorCommands;
    }
    set monitorCommands(value) {
        this[kOptions].monitorCommands = value;
    }
    /** @internal */
    get autoEncrypter() {
        return this[kOptions].autoEncrypter;
    }
    get readConcern() {
        return this.s.readConcern;
    }
    get writeConcern() {
        return this.s.writeConcern;
    }
    get readPreference() {
        return this.s.readPreference;
    }
    get bsonOptions() {
        return this.s.bsonOptions;
    }
    /**
     * Connect to MongoDB using a url
     *
     * @see docs.mongodb.org/manual/reference/connection-string/
     */
    async connect() {
        if (this.connectionLock) {
            return this.connectionLock;
        }
        try {
            this.connectionLock = this._connect();
            await this.connectionLock;
        }
        finally {
            // release
            this.connectionLock = undefined;
        }
        return this;
    }
    /**
     * Create a topology to open the connection, must be locked to avoid topology leaks in concurrency scenario.
     * Locking is enforced by the connect method.
     *
     * @internal
     */
    async _connect() {
        if (this.topology && this.topology.isConnected()) {
            return this;
        }
        const options = this[kOptions];
        if (options.tls) {
            if (typeof options.tlsCAFile === 'string') {
                options.ca ??= await fs_1.promises.readFile(options.tlsCAFile);
            }
            if (typeof options.tlsCRLFile === 'string') {
                options.crl ??= await fs_1.promises.readFile(options.tlsCRLFile);
            }
            if (typeof options.tlsCertificateKeyFile === 'string') {
                if (!options.key || !options.cert) {
                    const contents = await fs_1.promises.readFile(options.tlsCertificateKeyFile);
                    options.key ??= contents;
                    options.cert ??= contents;
                }
            }
        }
        if (typeof options.srvHost === 'string') {
            const hosts = await (0, connection_string_1.resolveSRVRecord)(options);
            for (const [index, host] of hosts.entries()) {
                options.hosts[index] = host;
            }
        }
        // It is important to perform validation of hosts AFTER SRV resolution, to check the real hostname,
        // but BEFORE we even attempt connecting with a potentially not allowed hostname
        if (options.credentials?.mechanism === providers_1.AuthMechanism.MONGODB_OIDC) {
            const allowedHosts = options.credentials?.mechanismProperties?.ALLOWED_HOSTS || mongo_credentials_1.DEFAULT_ALLOWED_HOSTS;
            const isServiceAuth = !!options.credentials?.mechanismProperties?.PROVIDER_NAME;
            if (!isServiceAuth) {
                for (const host of options.hosts) {
                    if (!(0, utils_1.hostMatchesWildcards)(host.toHostPort().host, allowedHosts)) {
                        throw new error_1.MongoInvalidArgumentError(`Host '${host}' is not valid for OIDC authentication with ALLOWED_HOSTS of '${allowedHosts.join(',')}'`);
                    }
                }
            }
        }
        this.topology = new topology_1.Topology(this, options.hosts, options);
        // Events can be emitted before initialization is complete so we have to
        // save the reference to the topology on the client ASAP if the event handlers need to access it
        this.topology.once(topology_1.Topology.OPEN, () => this.emit('open', this));
        for (const event of constants_1.MONGO_CLIENT_EVENTS) {
            this.topology.on(event, (...args) => this.emit(event, ...args));
        }
        const topologyConnect = async () => {
            try {
                await (0, util_1.promisify)(callback => this.topology?.connect(options, callback))();
            }
            catch (error) {
                this.topology?.close();
                throw error;
            }
        };
        if (this.autoEncrypter) {
            await this.autoEncrypter?.init();
            await topologyConnect();
            await options.encrypter.connectInternalClient();
        }
        else {
            await topologyConnect();
        }
        return this;
    }
    /**
     * Close the client and its underlying connections
     *
     * @param force - Force close, emitting no events
     */
    async close(force = false) {
        // There's no way to set hasBeenClosed back to false
        Object.defineProperty(this.s, 'hasBeenClosed', {
            value: true,
            enumerable: true,
            configurable: false,
            writable: false
        });
        const activeSessionEnds = Array.from(this.s.activeSessions, session => session.endSession());
        this.s.activeSessions.clear();
        await Promise.all(activeSessionEnds);
        if (this.topology == null) {
            return;
        }
        // If we would attempt to select a server and get nothing back we short circuit
        // to avoid the server selection timeout.
        const selector = (0, server_selection_1.readPreferenceServerSelector)(read_preference_1.ReadPreference.primaryPreferred);
        const topologyDescription = this.topology.description;
        const serverDescriptions = Array.from(topologyDescription.servers.values());
        const servers = selector(topologyDescription, serverDescriptions);
        if (servers.length !== 0) {
            const endSessions = Array.from(this.s.sessionPool.sessions, ({ id }) => id);
            if (endSessions.length !== 0) {
                await (0, execute_operation_1.executeOperation)(this, new run_command_1.RunAdminCommandOperation({ endSessions }, { readPreference: read_preference_1.ReadPreference.primaryPreferred, noResponse: true })).catch(() => null); // outcome does not matter;
            }
        }
        // clear out references to old topology
        const topology = this.topology;
        this.topology = undefined;
        topology.close();
        const { encrypter } = this[kOptions];
        if (encrypter) {
            await encrypter.close(this, force);
        }
    }
    /**
     * Create a new Db instance sharing the current socket connections.
     *
     * @param dbName - The name of the database we want to use. If not provided, use database name from connection string.
     * @param options - Optional settings for Db construction
     */
    db(dbName, options) {
        options = options ?? {};
        // Default to db from connection string if not provided
        if (!dbName) {
            dbName = this.options.dbName;
        }
        // Copy the options and add out internal override of the not shared flag
        const finalOptions = Object.assign({}, this[kOptions], options);
        // Return the db object
        const db = new db_1.Db(this, dbName, finalOptions);
        // Return the database
        return db;
    }
    /**
     * Connect to MongoDB using a url
     *
     * @remarks
     * The programmatically provided options take precedence over the URI options.
     *
     * @see https://www.mongodb.com/docs/manual/reference/connection-string/
     */
    static async connect(url, options) {
        const client = new this(url, options);
        return client.connect();
    }
    /**
     * Creates a new ClientSession. When using the returned session in an operation
     * a corresponding ServerSession will be created.
     *
     * @remarks
     * A ClientSession instance may only be passed to operations being performed on the same
     * MongoClient it was started from.
     */
    startSession(options) {
        const session = new sessions_1.ClientSession(this, this.s.sessionPool, { explicit: true, ...options }, this[kOptions]);
        this.s.activeSessions.add(session);
        session.once('ended', () => {
            this.s.activeSessions.delete(session);
        });
        return session;
    }
    async withSession(optionsOrExecutor, executor) {
        const options = {
            // Always define an owner
            owner: Symbol(),
            // If it's an object inherit the options
            ...(typeof optionsOrExecutor === 'object' ? optionsOrExecutor : {})
        };
        const withSessionCallback = typeof optionsOrExecutor === 'function' ? optionsOrExecutor : executor;
        if (withSessionCallback == null) {
            throw new error_1.MongoInvalidArgumentError('Missing required callback parameter');
        }
        const session = this.startSession(options);
        try {
            return await withSessionCallback(session);
        }
        finally {
            try {
                await session.endSession();
            }
            catch {
                // We are not concerned with errors from endSession()
            }
        }
    }
    /**
     * Create a new Change Stream, watching for new changes (insertions, updates,
     * replacements, deletions, and invalidations) in this cluster. Will ignore all
     * changes to system collections, as well as the local, admin, and config databases.
     *
     * @remarks
     * watch() accepts two generic arguments for distinct use cases:
     * - The first is to provide the schema that may be defined for all the data within the current cluster
     * - The second is to override the shape of the change stream document entirely, if it is not provided the type will default to ChangeStreamDocument of the first argument
     *
     * @param pipeline - An array of {@link https://www.mongodb.com/docs/manual/reference/operator/aggregation-pipeline/|aggregation pipeline stages} through which to pass change stream documents. This allows for filtering (using $match) and manipulating the change stream documents.
     * @param options - Optional settings for the command
     * @typeParam TSchema - Type of the data being detected by the change stream
     * @typeParam TChange - Type of the whole change stream document emitted
     */
    watch(pipeline = [], options = {}) {
        // Allow optionally not specifying a pipeline
        if (!Array.isArray(pipeline)) {
            options = pipeline;
            pipeline = [];
        }
        return new change_stream_1.ChangeStream(this, pipeline, (0, utils_1.resolveOptions)(this, options));
    }
}
exports.MongoClient = MongoClient;
//# sourceMappingURL=mongo_client.js.map