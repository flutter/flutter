declare module 'mongoose' {
  import mongodb = require('mongodb');

  interface SchemaTimestampsConfig {
    createdAt?: boolean | string;
    updatedAt?: boolean | string;
    currentTime?: () => (NativeDate | number);
  }

  type TypeKeyBaseType = string;

  type DefaultTypeKey = 'type';
  interface SchemaOptions<
    DocType = unknown,
    TInstanceMethods = {},
    QueryHelpers = {},
    TStaticMethods = {},
    TVirtuals = {},
    THydratedDocumentType = HydratedDocument<DocType, TInstanceMethods, QueryHelpers>
  > {
    /**
     * By default, Mongoose's init() function creates all the indexes defined in your model's schema by
     * calling Model.createIndexes() after you successfully connect to MongoDB. If you want to disable
     * automatic index builds, you can set autoIndex to false.
     */
    autoIndex?: boolean;
    /**
     * Similar to autoIndex, except for automatically creates any Atlas search indexes defined in your
     * schema. Unlike autoIndex, this option defaults to false.
     */
    autoSearchIndex?: boolean;
    /**
     * If set to `true`, Mongoose will call Model.createCollection() to create the underlying collection
     * in MongoDB if autoCreate is set to true. Calling createCollection() sets the collection's default
     * collation based on the collation option and establishes the collection as a capped collection if
     * you set the capped schema option.
     */
    autoCreate?: boolean;
    /**
     * By default, mongoose buffers commands when the connection goes down until the driver manages to reconnect.
     * To disable buffering, set bufferCommands to false.
     */
    bufferCommands?: boolean;
    /**
     * If bufferCommands is on, this option sets the maximum amount of time Mongoose buffering will wait before
     * throwing an error. If not specified, Mongoose will use 10000 (10 seconds).
     */
    bufferTimeoutMS?: number;
    /**
     * Mongoose supports MongoDBs capped collections. To specify the underlying MongoDB collection be capped, set
     * the capped option to the maximum size of the collection in bytes.
     */
    capped?: boolean | number | { size?: number; max?: number; autoIndexId?: boolean; };
    /** Sets a default collation for every query and aggregation. */
    collation?: mongodb.CollationOptions;

    /** Arbitrary options passed to `createCollection()` */
    collectionOptions?: mongodb.CreateCollectionOptions;

    /** The timeseries option to use when creating the model's collection. */
    timeseries?: mongodb.TimeSeriesCollectionOptions;

    /** The number of seconds after which a document in a timeseries collection expires. */
    expireAfterSeconds?: number;

    /** The time after which a document in a timeseries collection expires. */
    expires?: number | string;

    /**
     * Mongoose by default produces a collection name by passing the model name to the utils.toCollectionName
     * method. This method pluralizes the name. Set this option if you need a different name for your collection.
     */
    collection?: string;
    /**
     * When you define a [discriminator](/docs/discriminators.html), Mongoose adds a path to your
     * schema that stores which discriminator a document is an instance of. By default, Mongoose
     * adds an `__t` path, but you can set `discriminatorKey` to overwrite this default.
     *
     * @default '__t'
     */
    discriminatorKey?: string;

    /**
     * Option for nested Schemas.
     *
     * If true, skip building indexes on this schema's path.
     *
     * @default false
     */
    excludeIndexes?: boolean;
    /**
     * Mongoose assigns each of your schemas an id virtual getter by default which returns the document's _id field
     * cast to a string, or in the case of ObjectIds, its hexString.
     */
    id?: boolean;
    /**
     * Mongoose assigns each of your schemas an _id field by default if one is not passed into the Schema
     * constructor. The type assigned is an ObjectId to coincide with MongoDB's default behavior. If you
     * don't want an _id added to your schema at all, you may disable it using this option.
     */
    _id?: boolean;
    /**
     * Mongoose will, by default, "minimize" schemas by removing empty objects. This behavior can be
     * overridden by setting minimize option to false. It will then store empty objects.
     */
    minimize?: boolean;
    /**
     * Optimistic concurrency is a strategy to ensure the document you're updating didn't change between when you
     * loaded it using find() or findOne(), and when you update it using save(). Set to `true` to enable
     * optimistic concurrency.
     */
    optimisticConcurrency?: boolean;
    /**
     * If `plugin()` called with tags, Mongoose will only apply plugins to schemas that have
     * a matching tag in `pluginTags`
     */
    pluginTags?: string[];
    /**
     * Allows setting query#read options at the schema level, providing us a way to apply default ReadPreferences
     * to all queries derived from a model.
     */
    read?: string;
    /** Allows setting write concern at the schema level. */
    writeConcern?: WriteConcern;
    /** defaults to true. */
    safe?: boolean | { w?: number | string; wtimeout?: number; j?: boolean };
    /**
     * The shardKey option is used when we have a sharded MongoDB architecture. Each sharded collection is
     * given a shard key which must be present in all insert/update operations. We just need to set this
     * schema option to the same shard key and we'll be all set.
     */
    shardKey?: Record<string, unknown>;
    /**
     * The strict option, (enabled by default), ensures that values passed to our model constructor that were not
     * specified in our schema do not get saved to the db.
     */
    strict?: boolean | 'throw';
    /**
     * equal to `strict` by default, may be `false`, `true`, or `'throw'`. Sets the default
     * [strictQuery](https://mongoosejs.com/docs/guide.html#strictQuery) mode for schemas.
     */
    strictQuery?: boolean | 'throw';
    /** Exactly the same as the toObject option but only applies when the document's toJSON method is called. */
    toJSON?: ToObjectOptions<THydratedDocumentType>;
    /**
     * Documents have a toObject method which converts the mongoose document into a plain JavaScript object.
     * This method accepts a few options. Instead of applying these options on a per-document basis, we may
     * declare the options at the schema level and have them applied to all of the schema's documents by
     * default.
     */
    toObject?: ToObjectOptions<THydratedDocumentType>;
    /**
     * By default, if you have an object with key 'type' in your schema, mongoose will interpret it as a
     * type declaration. However, for applications like geoJSON, the 'type' property is important. If you want to
     * control which key mongoose uses to find type declarations, set the 'typeKey' schema option.
     */
    typeKey?: string;

    /**
     * By default, documents are automatically validated before they are saved to the database. This is to
     * prevent saving an invalid document. If you want to handle validation manually, and be able to save
     * objects which don't pass validation, you can set validateBeforeSave to false.
     */
    validateBeforeSave?: boolean;
    /**
     * By default, validation will run on modified and required paths before saving to the database.
     * You can choose to have Mongoose only validate modified paths by setting validateModifiedOnly to true.
     */
    validateModifiedOnly?: boolean;
    /**
     * The versionKey is a property set on each document when first created by Mongoose. This keys value
     * contains the internal revision of the document. The versionKey option is a string that represents
     * the path to use for versioning. The default is '__v'.
     *
     * @default '__v'
     */
    versionKey?: string | boolean;
    /**
     * By default, Mongoose will automatically select() any populated paths for you, unless you explicitly exclude them.
     *
     * @default true
     */
    selectPopulatedPaths?: boolean;
    /**
     * skipVersioning allows excluding paths from versioning (i.e., the internal revision will not be
     * incremented even if these paths are updated). DO NOT do this unless you know what you're doing.
     * For subdocuments, include this on the parent document using the fully qualified path.
     */
    skipVersioning?: { [key: string]: boolean; };
    /**
     * Validation errors in a single nested schema are reported
     * both on the child and on the parent schema.
     * Set storeSubdocValidationError to false on the child schema
     * to make Mongoose only report the parent error.
     */
    storeSubdocValidationError?: boolean;
    /**
     * The timestamps option tells mongoose to assign createdAt and updatedAt fields to your schema. The type
     * assigned is Date. By default, the names of the fields are createdAt and updatedAt. Customize the
     * field names by setting timestamps.createdAt and timestamps.updatedAt.
     */
    timestamps?: boolean | SchemaTimestampsConfig;

    /**
     * Using `save`, `isNew`, and other Mongoose reserved names as schema path names now triggers a warning, not an error.
     * You can suppress the warning by setting { suppressReservedKeysWarning: true } schema options. Keep in mind that this
     * can break plugins that rely on these reserved names.
     */
    suppressReservedKeysWarning?: boolean,

    /**
     * Model Statics methods.
     */
    statics?: IfEquals<
      TStaticMethods,
      {},
      { [name: string]: (this: Model<DocType>, ...args: any[]) => unknown },
      AddThisParameter<TStaticMethods, Model<DocType>>
    >

    /**
     * Document instance methods.
     */
    methods?: IfEquals<
    TInstanceMethods,
    {},
    Record<any, (this: THydratedDocumentType, ...args: any) => unknown>,
    AddThisParameter<TInstanceMethods, THydratedDocumentType> & AnyObject
    >

    /**
     * Query helper functions.
     */
    query?: IfEquals<
    QueryHelpers,
    {},
    Record<any, <T extends QueryWithHelpers<unknown, THydratedDocumentType, QueryHelpers, DocType>>(this: T, ...args: any) => T>,
    QueryHelpers
    >

    /**
     * Set whether to cast non-array values to arrays.
     * @default true
     */
    castNonArrays?: boolean;

    /**
     * Virtual paths.
     */
    virtuals?: SchemaOptionsVirtualsPropertyType<DocType, TVirtuals, TInstanceMethods>,

    /**
     * Set to `true` to default to overwriting models with the same name when calling `mongoose.model()`, as opposed to throwing an `OverwriteModelError`.
     * @default false
     */
    overwriteModels?: boolean;
  }

  interface DefaultSchemaOptions {
    typeKey: 'type';
    id: true;
    _id: true;
    timestamps: false;
    versionKey: '__v'
  }
}
