declare module 'mongoose' {
  import stream = require('stream');

  interface MongooseOptions {
    /**
     * Set to `true` to set `allowDiskUse` to true to all aggregation operations by default.
     *
     * @default false
     */
    allowDiskUse?: boolean;
    /**
     * Set to `false` to skip applying global plugins to child schemas.
     *
     * @default true
     */
    applyPluginsToChildSchemas?: boolean;

    /**
     * Set to `true` to apply global plugins to discriminator schemas.
     * This typically isn't necessary because plugins are applied to the base schema and
     * discriminators copy all middleware, methods, statics, and properties from the base schema.
     *
     * @default false
     */
    applyPluginsToDiscriminators?: boolean;

    /**
     * autoCreate is `true` by default unless readPreference is secondary or secondaryPreferred,
     * which means Mongoose will attempt to create every model's underlying collection before
     * creating indexes. If readPreference is secondary or secondaryPreferred, Mongoose will
     * default to false for both autoCreate and autoIndex because both createCollection() and
     * createIndex() will fail when connected to a secondary.
     */
    autoCreate?: boolean;

    /**
     * Set to `false` to disable automatic index creation for all models associated with this Mongoose instance.
     *
     * @default true
     */
    autoIndex?: boolean;

    /**
     * enable/disable mongoose's buffering mechanism for all connections and models.
     *
     * @default true
     */
    bufferCommands?: boolean;

    /**
     * If bufferCommands is on, this option sets the maximum amount of time Mongoose
     * buffering will wait before throwing an error.
     * If not specified, Mongoose will use 10000 (10 seconds).
     *
     * @default 10000
     */
    bufferTimeoutMS?: number;

    /**
     * Set to `true` to `clone()` all schemas before compiling into a model.
     *
     * @default false
     */
    cloneSchemas?: boolean;

    /**
     * Set to `false` to disable the creation of the initial default connection.
     *
     * @default true
     */
    createInitialConnection?: boolean;

    /**
     * If `true`, prints the operations mongoose sends to MongoDB to the console.
     * If a writable stream is passed, it will log to that stream, without colorization.
     * If a callback function is passed, it will receive the collection name, the method
     * name, then all arguments passed to the method. For example, if you wanted to
     * replicate the default logging, you could output from the callback
     * `Mongoose: ${collectionName}.${methodName}(${methodArgs.join(', ')})`.
     *
     * @default false
     */
    debug?:
    | boolean
    | { color?: boolean; shell?: boolean; }
    | stream.Writable
    | ((collectionName: string, methodName: string, ...methodArgs: any[]) => void);

    /**
     * If `true`, adds a `id` virtual to all schemas unless overwritten on a per-schema basis.
     * @defaultValue true
     */
    id?: boolean;

    /**
     * If `false`, it will change the `createdAt` field to be [`immutable: false`](https://mongoosejs.com/docs/api/schematype.html#schematype_SchemaType-immutable)
     * which means you can update the `createdAt`.
     *
     * @default true
     */
    'timestamps.createdAt.immutable'?: boolean

    /** If set, attaches [maxTimeMS](https://www.mongodb.com/docs/manual/reference/operator/meta/maxTimeMS/) to every query */
    maxTimeMS?: number;

    /**
     * Mongoose adds a getter to MongoDB ObjectId's called `_id` that
     * returns `this` for convenience with populate. Set this to false to remove the getter.
     *
     * @default true
     */
    objectIdGetter?: boolean;

    /**
     * Set to `true` to default to overwriting models with the same name when calling
     * `mongoose.model()`, as opposed to throwing an `OverwriteModelError`.
     *
     * @default false
     */
    overwriteModels?: boolean;

    /**
     * If `false`, changes the default `returnOriginal` option to `findOneAndUpdate()`,
     * `findByIdAndUpdate`, and `findOneAndReplace()` to false. This is equivalent to
     * setting the `new` option to `true` for `findOneAndX()` calls by default. Read our
     * `findOneAndUpdate()` [tutorial](https://mongoosejs.com/docs/tutorials/findoneandupdate.html)
     * for more information.
     *
     * @default true
     */
    returnOriginal?: boolean;

    /**
     * Set to true to enable [update validators](
     * https://mongoosejs.com/docs/validation.html#update-validators
     * ) for all validators by default.
     *
     * @default false
     */
    runValidators?: boolean;

    /**
     * Sanitizes query filters against [query selector injection attacks](
     * https://thecodebarbarian.com/2014/09/04/defending-against-query-selector-injection-attacks.html
     * ) by wrapping any nested objects that have a property whose name starts with $ in a $eq.
     */
    sanitizeFilter?: boolean;

    sanitizeProjection?: boolean;

    /**
     * Set to false to opt out of Mongoose adding all fields that you `populate()`
     * to your `select()`. The schema-level option `selectPopulatedPaths` overwrites this one.
     *
     * @default true
     */
    selectPopulatedPaths?: boolean;

    /**
     * Mongoose also sets defaults on update() and findOneAndUpdate() when the upsert option is
     * set by adding your schema's defaults to a MongoDB $setOnInsert operator. You can disable
     * this behavior by setting the setDefaultsOnInsert option to false.
     *
     * @default true
     */
    setDefaultsOnInsert?: boolean;

    /**
     * Sets the default strict mode for schemas.
     * May be `false`, `true`, or `'throw'`.
     *
     * @default true
     */
    strict?: boolean | 'throw';

    /**
     * Set to `false` to allow populating paths that aren't in the schema.
     *
     * @default true
     */
    strictPopulate?: boolean;

    /**
     * Sets the default [strictQuery](https://mongoosejs.com/docs/guide.html#strictQuery) mode for schemas.
     * May be `false`, `true`, or `'throw'`.
     *
     * @default false
     */
    strictQuery?: boolean | 'throw';

    /**
     * Overwrites default objects to `toJSON()`, for determining how Mongoose
     * documents get serialized by `JSON.stringify()`
     *
     * @default { transform: true, flattenDecimals: true }
     */
    toJSON?: ToObjectOptions;

    /**
     * Overwrites default objects to `toObject()`
     *
     * @default { transform: true, flattenDecimals: true }
     */
    toObject?: ToObjectOptions;

    /**
     * If `true`, convert any aliases in filter, projection, update, and distinct
     * to their database property names. Defaults to false.
     */
    translateAliases?: boolean;
  }
}
