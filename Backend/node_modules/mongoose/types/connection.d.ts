declare module 'mongoose' {
  import mongodb = require('mongodb');
  import events = require('events');

  /** The Mongoose module's default connection. Equivalent to `mongoose.connections[0]`, see [`connections`](#mongoose_Mongoose-connections). */
  const connection: Connection;

  /** An array containing all connections associated with this Mongoose instance. */
  const connections: Connection[];

  /** Opens Mongoose's default connection to MongoDB, see [connections docs](https://mongoosejs.com/docs/connections.html) */
  function connect(uri: string, options?: ConnectOptions): Promise<Mongoose>;

  /** Creates a Connection instance. */
  function createConnection(uri: string, options?: ConnectOptions): Connection;
  function createConnection(): Connection;

  function disconnect(): Promise<void>;

  /**
   * Connection ready state
   *
   * - 0 = disconnected
   * - 1 = connected
   * - 2 = connecting
   * - 3 = disconnecting
   * - 99 = uninitialized
   */
  enum ConnectionStates {
    disconnected = 0,
    connected = 1,
    connecting = 2,
    disconnecting = 3,
    uninitialized = 99,
  }

  /** Expose connection states for user-land */
  const STATES: typeof ConnectionStates;

  interface ConnectOptions extends mongodb.MongoClientOptions {
    /** Set to false to [disable buffering](http://mongoosejs.com/docs/faq.html#callback_never_executes) on all models associated with this connection. */
    bufferCommands?: boolean;
    /** The name of the database you want to use. If not provided, Mongoose uses the database name from connection string. */
    dbName?: string;
    /** username for authentication, equivalent to `options.auth.user`. Maintained for backwards compatibility. */
    user?: string;
    /** password for authentication, equivalent to `options.auth.password`. Maintained for backwards compatibility. */
    pass?: string;
    /** Set to false to disable automatic index creation for all models associated with this connection. */
    autoIndex?: boolean;
    /** Set to `false` to disable Mongoose automatically calling `createCollection()` on every model created on this connection. */
    autoCreate?: boolean;
  }

  class Connection extends events.EventEmitter implements SessionStarter {
    /** Returns a promise that resolves when this connection successfully connects to MongoDB */
    asPromise(): Promise<this>;

    /** Closes the connection */
    close(force?: boolean): Promise<void>;

    /** Closes and destroys the connection. Connection once destroyed cannot be reopened */
    destroy(force?: boolean): Promise<void>;

    /** Retrieves a collection, creating it if not cached. */
    collection<T extends AnyObject = AnyObject>(name: string, options?: mongodb.CreateCollectionOptions): Collection<T>;

    /** A hash of the collections associated with this connection */
    readonly collections: { [index: string]: Collection };

    /** A hash of the global options that are associated with this connection */
    readonly config: any;

    /** The mongodb.Db instance, set when the connection is opened */
    readonly db: mongodb.Db;

    /**
     * Helper for `createCollection()`. Will explicitly create the given collection
     * with specified options. Used to create [capped collections](https://www.mongodb.com/docs/manual/core/capped-collections/)
     * and [views](https://www.mongodb.com/docs/manual/core/views/) from mongoose.
     */
    createCollection<T extends AnyObject = AnyObject>(name: string, options?: mongodb.CreateCollectionOptions): Promise<mongodb.Collection<T>>;

    /**
     * https://mongoosejs.com/docs/api/connection.html#Connection.prototype.createCollections()
     */
    createCollections(continueOnError?: boolean): Promise<Record<string, Error | mongodb.Collection<any>>>;

    /**
     * Removes the model named `name` from this connection, if it exists. You can
     * use this function to clean up any models you created in your tests to
     * prevent OverwriteModelErrors.
     */
    deleteModel(name: string | RegExp): this;

    /**
     * Helper for `dropCollection()`. Will delete the given collection, including
     * all documents and indexes.
     */
    dropCollection(collection: string): Promise<void>;

    /**
     * Helper for `dropDatabase()`. Deletes the given database, including all
     * collections, documents, and indexes.
     */
    dropDatabase(): Promise<void>;

    /** Gets the value of the option `key`. */
    get(key: string): any;

    /**
     * Returns the [MongoDB driver `MongoClient`](https://mongodb.github.io/node-mongodb-native/4.9/classes/MongoClient.html) instance
     * that this connection uses to talk to MongoDB.
     */
    getClient(): mongodb.MongoClient;

    /**
     * The host name portion of the URI. If multiple hosts, such as a replica set,
     * this will contain the first host name in the URI
     */
    readonly host: string;

    /**
     * A number identifier for this connection. Used for debugging when
     * you have [multiple connections](/docs/connections.html#multiple_connections).
     */
    readonly id: number;

    /**
     * Helper for MongoDB Node driver's `listCollections()`.
     * Returns an array of collection names.
     */
    listCollections(): Promise<Pick<mongodb.CollectionInfo, 'name' | 'type'>[]>;

    /**
     * A [POJO](https://masteringjs.io/tutorials/fundamentals/pojo) containing
     * a map from model names to models. Contains all models that have been
     * added to this connection using [`Connection#model()`](/docs/api/connection.html#connection_Connection-model).
     */
    readonly models: Readonly<{ [index: string]: Model<any> }>;

    /** Defines or retrieves a model. */
    model<TSchema extends Schema = any>(
      name: string,
      schema?: TSchema,
      collection?: string,
      options?: CompileModelOptions
    ): Model<
    InferSchemaType<TSchema>,
    ObtainSchemaGeneric<TSchema, 'TQueryHelpers'>,
    ObtainSchemaGeneric<TSchema, 'TInstanceMethods'>,
    {},
    HydratedDocument<
    InferSchemaType<TSchema>,
    ObtainSchemaGeneric<TSchema, 'TInstanceMethods'>,
    ObtainSchemaGeneric<TSchema, 'TQueryHelpers'>
    >,
    TSchema> & ObtainSchemaGeneric<TSchema, 'TStaticMethods'>;
    model<T, U, TQueryHelpers = {}>(
      name: string,
      schema?: Schema<T, any, any, TQueryHelpers, any, any, any>,
      collection?: string,
      options?: CompileModelOptions
    ): U;
    model<T>(name: string, schema?: Schema<T, any, any>, collection?: string, options?: CompileModelOptions): Model<T>;

    /** Returns an array of model names created on this connection. */
    modelNames(): Array<string>;

    /** The name of the database this connection points to. */
    readonly name: string;

    /** Opens the connection with a URI using `MongoClient.connect()`. */
    openUri(uri: string, options?: ConnectOptions): Promise<Connection>;

    /** The password specified in the URI */
    readonly pass: string;

    /**
     * The port portion of the URI. If multiple hosts, such as a replica set,
     * this will contain the port from the first host name in the URI.
     */
    readonly port: number;

    /** Declares a plugin executed on all schemas you pass to `conn.model()` */
    plugin<S extends Schema = Schema, O = AnyObject>(fn: (schema: S, opts?: any) => void, opts?: O): Connection;

    /** The plugins that will be applied to all models created on this connection. */
    plugins: Array<any>;

    /**
     * Connection ready state
     *
     * - 0 = disconnected
     * - 1 = connected
     * - 2 = connecting
     * - 3 = disconnecting
     * - 99 = uninitialized
     */
    readonly readyState: ConnectionStates;

    /** Sets the value of the option `key`. */
    set(key: string, value: any): any;

    /**
     * Set the [MongoDB driver `MongoClient`](https://mongodb.github.io/node-mongodb-native/4.9/classes/MongoClient.html) instance
     * that this connection uses to talk to MongoDB. This is useful if you already have a MongoClient instance, and want to
     * reuse it.
     */
    setClient(client: mongodb.MongoClient): this;

    /**
     * _Requires MongoDB >= 3.6.0._ Starts a [MongoDB session](https://www.mongodb.com/docs/manual/release-notes/3.6/#client-sessions)
     * for benefits like causal consistency, [retryable writes](https://www.mongodb.com/docs/manual/core/retryable-writes/),
     * and [transactions](http://thecodebarbarian.com/a-node-js-perspective-on-mongodb-4-transactions.html).
     */
    startSession(options?: ClientSessionOptions): Promise<ClientSession>;

    /**
     * Makes the indexes in MongoDB match the indexes defined in every model's
     * schema. This function will drop any indexes that are not defined in
     * the model's schema except the `_id` index, and build any indexes that
     * are in your schema but not in MongoDB.
     */
    syncIndexes(options?: SyncIndexesOptions): Promise<ConnectionSyncIndexesResult>;

    /**
     * _Requires MongoDB >= 3.6.0._ Executes the wrapped async function
     * in a transaction. Mongoose will commit the transaction if the
     * async function executes successfully and attempt to retry if
     * there was a retryable error.
     */
    transaction(fn: (session: mongodb.ClientSession) => Promise<any>, options?: mongodb.TransactionOptions): Promise<void>;

    /** Switches to a different database using the same connection pool. */
    useDb(name: string, options?: { useCache?: boolean, noListener?: boolean }): Connection;

    /** The username specified in the URI */
    readonly user: string;

    /** Watches the entire underlying database for changes. Similar to [`Model.watch()`](/docs/api/model.html#model_Model-watch). */
    watch<ResultType extends mongodb.Document = any>(pipeline?: Array<any>, options?: mongodb.ChangeStreamOptions): mongodb.ChangeStream<ResultType>;

    withSession<T = any>(executor: (session: ClientSession) => Promise<T>): T;
  }

}
