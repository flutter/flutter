declare module 'mongoose' {
  import mongodb = require('mongodb');

  export interface DiscriminatorOptions {
    value?: string | number | ObjectId;
    clone?: boolean;
    overwriteModels?: boolean;
    mergeHooks?: boolean;
    mergePlugins?: boolean;
  }

  export interface AcceptsDiscriminator {
    /** Adds a discriminator type. */
    discriminator<D>(
      name: string | number,
      schema: Schema,
      value?: string | number | ObjectId | DiscriminatorOptions
    ): Model<D>;
    discriminator<T, U>(
      name: string | number,
      schema: Schema<T, U>,
      value?: string | number | ObjectId | DiscriminatorOptions
    ): U;
  }

  interface MongooseBulkWriteOptions extends mongodb.BulkWriteOptions {
    session?: ClientSession;
    skipValidation?: boolean;
    throwOnValidationError?: boolean;
    strict?: boolean | 'throw';
  }

  interface MongooseBulkSaveOptions extends mongodb.BulkWriteOptions {
    timestamps?: boolean;
    session?: ClientSession;
  }

  /**
   * @deprecated use AnyBulkWriteOperation instead
   */
  interface MongooseBulkWritePerWriteOptions {
    timestamps?: boolean;
    strict?: boolean | 'throw';
    session?: ClientSession;
    skipValidation?: boolean;
  }

  interface HydrateOptions {
    setters?: boolean;
    hydratedPopulatedDocs?: boolean;
  }

  interface InsertManyOptions extends
    PopulateOption,
    SessionOption {
    limit?: number;
    // @deprecated, use includeResultMetadata instead
    rawResult?: boolean;
    includeResultMetadata?: boolean;
    ordered?: boolean;
    lean?: boolean;
    throwOnValidationError?: boolean;
  }

  type InsertManyResult<T> = mongodb.InsertManyResult<T> & {
    insertedIds: {
      [key: number]: InferId<T>;
    };
    mongoose?: { validationErrors?: Array<Error.CastError | Error.ValidatorError> };
  };

  type UpdateWriteOpResult = mongodb.UpdateResult;

  interface MapReduceOptions<T, K, R> {
    map: Function | string;
    reduce: (key: K, vals: T[]) => R;
    /** query filter object. */
    query?: any;
    /** sort input objects using this key */
    sort?: any;
    /** max number of documents */
    limit?: number;
    /** keep temporary data default: false */
    keeptemp?: boolean;
    /** finalize function */
    finalize?: (key: K, val: R) => R;
    /** scope variables exposed to map/reduce/finalize during execution */
    scope?: any;
    /** it is possible to make the execution stay in JS. Provided in MongoDB > 2.0.X default: false */
    jsMode?: boolean;
    /** provide statistics on job execution time. default: false */
    verbose?: boolean;
    readPreference?: string;
    /** sets the output target for the map reduce job. default: {inline: 1} */
    out?: {
      /** the results are returned in an array */
      inline?: number;
      /**
       * {replace: 'collectionName'} add the results to collectionName: the
       * results replace the collection
       */
      replace?: string;
      /**
       * {reduce: 'collectionName'} add the results to collectionName: if
       * dups are detected, uses the reducer / finalize functions
       */
      reduce?: string;
      /**
       * {merge: 'collectionName'} add the results to collectionName: if
       * dups exist the new docs overwrite the old
       */
      merge?: string;
    };
  }

  interface GeoSearchOptions {
    /** x,y point to search for */
    near: number[];
    /** the maximum distance from the point near that a result can be */
    maxDistance: number;
    /** The maximum number of results to return */
    limit?: number;
    /** return the raw object instead of the Mongoose Model */
    lean?: boolean;
  }

  interface ModifyResult<T> {
    value: Require_id<T> | null;
    /** see https://www.mongodb.com/docs/manual/reference/command/findAndModify/#lasterrorobject */
    lastErrorObject?: {
      updatedExisting?: boolean;
      upserted?: mongodb.ObjectId;
    };
    ok: 0 | 1;
  }

  type WriteConcern = mongodb.WriteConcern;

  /** A list of paths to validate. If set, Mongoose will validate only the modified paths that are in the given list. */
  type PathsToValidate = string[] | string;
  /**
   * @deprecated
   */
  type pathsToValidate = PathsToValidate;

  interface SaveOptions extends
    SessionOption {
    checkKeys?: boolean;
    j?: boolean;
    safe?: boolean | WriteConcern;
    timestamps?: boolean | QueryTimestampsConfig;
    validateBeforeSave?: boolean;
    validateModifiedOnly?: boolean;
    w?: number | string;
    wtimeout?: number;
  }

  interface CreateOptions extends SaveOptions {
    ordered?: boolean;
    aggregateErrors?: boolean;
  }

  interface RemoveOptions extends SessionOption, Omit<mongodb.DeleteOptions, 'session'> {}

  const Model: Model<any>;

  export type AnyBulkWriteOperation<TSchema = AnyObject> = {
    insertOne: InsertOneModel<TSchema>;
  } | {
    replaceOne: ReplaceOneModel<TSchema>;
  } | {
    updateOne: UpdateOneModel<TSchema>;
  } | {
    updateMany: UpdateManyModel<TSchema>;
  } | {
    deleteOne: DeleteOneModel<TSchema>;
  } | {
    deleteMany: DeleteManyModel<TSchema>;
  };

  export interface InsertOneModel<TSchema> {
    document: mongodb.OptionalId<TSchema>
  }

  export interface ReplaceOneModel<TSchema = AnyObject> {
    /** The filter to limit the replaced document. */
    filter: FilterQuery<TSchema>;
    /** The document with which to replace the matched document. */
    replacement: mongodb.WithoutId<TSchema>;
    /** Specifies a collation. */
    collation?: mongodb.CollationOptions;
    /** The index to use. If specified, then the query system will only consider plans using the hinted index. */
    hint?: mongodb.Hint;
    /** When true, creates a new document if no document matches the query. */
    upsert?: boolean;
  }

  export interface UpdateOneModel<TSchema = AnyObject> {
    /** The filter to limit the updated documents. */
    filter: FilterQuery<TSchema>;
    /** A document or pipeline containing update operators. */
    update: UpdateQuery<TSchema>;
    /** A set of filters specifying to which array elements an update should apply. */
    arrayFilters?: AnyObject[];
    /** Specifies a collation. */
    collation?: mongodb.CollationOptions;
    /** The index to use. If specified, then the query system will only consider plans using the hinted index. */
    hint?: mongodb.Hint;
    /** When true, creates a new document if no document matches the query. */
    upsert?: boolean;
    /** When false, do not add timestamps. */
    timestamps?: boolean;
  }

  export interface UpdateManyModel<TSchema = AnyObject> {
    /** The filter to limit the updated documents. */
    filter: FilterQuery<TSchema>;
    /** A document or pipeline containing update operators. */
    update: UpdateQuery<TSchema>;
    /** A set of filters specifying to which array elements an update should apply. */
    arrayFilters?: AnyObject[];
    /** Specifies a collation. */
    collation?: mongodb.CollationOptions;
    /** The index to use. If specified, then the query system will only consider plans using the hinted index. */
    hint?: mongodb.Hint;
    /** When true, creates a new document if no document matches the query. */
    upsert?: boolean;
    /** When false, do not add timestamps. */
    timestamps?: boolean;
  }

  export interface DeleteOneModel<TSchema = AnyObject> {
    /** The filter to limit the deleted documents. */
    filter: FilterQuery<TSchema>;
    /** Specifies a collation. */
    collation?: mongodb.CollationOptions;
    /** The index to use. If specified, then the query system will only consider plans using the hinted index. */
    hint?: mongodb.Hint;
  }

  export interface DeleteManyModel<TSchema = AnyObject> {
    /** The filter to limit the deleted documents. */
    filter: FilterQuery<TSchema>;
    /** Specifies a collation. */
    collation?: mongodb.CollationOptions;
    /** The index to use. If specified, then the query system will only consider plans using the hinted index. */
    hint?: mongodb.Hint;
  }

  /**
   * Models are fancy constructors compiled from `Schema` definitions.
   * An instance of a model is called a document.
   * Models are responsible for creating and reading documents from the underlying MongoDB database
   */
  export interface Model<
    TRawDocType,
    TQueryHelpers = {},
    TInstanceMethods = {},
    TVirtuals = {},
    THydratedDocumentType = HydratedDocument<TRawDocType, TVirtuals & TInstanceMethods, TQueryHelpers>,
    TSchema = any> extends
    NodeJS.EventEmitter,
    AcceptsDiscriminator,
    IndexManager,
    SessionStarter {
    new <DocType = Partial<TRawDocType>>(doc?: DocType, fields?: any | null, options?: boolean | AnyObject): THydratedDocumentType;

    aggregate<R = any>(pipeline?: PipelineStage[], options?: AggregateOptions): Aggregate<Array<R>>;
    aggregate<R = any>(pipeline: PipelineStage[]): Aggregate<Array<R>>;

    /** Base Mongoose instance the model uses. */
    base: Mongoose;

    /**
     * If this is a discriminator model, `baseModelName` is the name of
     * the base model.
     */
    baseModelName: string | undefined;

    /* Cast the given POJO to the model's schema */
    castObject(obj: AnyObject, options?: { ignoreCastErrors?: boolean }): TRawDocType;

    /* Apply defaults to the given document or POJO. */
    applyDefaults(obj: AnyObject): AnyObject;
    applyDefaults(obj: TRawDocType): TRawDocType;

    /**
     * Sends multiple `insertOne`, `updateOne`, `updateMany`, `replaceOne`,
     * `deleteOne`, and/or `deleteMany` operations to the MongoDB server in one
     * command. This is faster than sending multiple independent operations (e.g.
     * if you use `create()`) because with `bulkWrite()` there is only one network
     * round trip to the MongoDB server.
     */
    bulkWrite<DocContents = TRawDocType>(
      writes: Array<AnyBulkWriteOperation<DocContents extends Document ? any : (DocContents extends {} ? DocContents : any)>>,
      options: MongooseBulkWriteOptions & { ordered: false }
    ): Promise<mongodb.BulkWriteResult & { mongoose?: { validationErrors: Error[] } }>;
    bulkWrite<DocContents = TRawDocType>(
      writes: Array<AnyBulkWriteOperation<DocContents extends Document ? any : (DocContents extends {} ? DocContents : any)>>,
      options?: MongooseBulkWriteOptions
    ): Promise<mongodb.BulkWriteResult>;

    /**
     * Sends multiple `save()` calls in a single `bulkWrite()`. This is faster than
     * sending multiple `save()` calls because with `bulkSave()` there is only one
     * network round trip to the MongoDB server.
     */
    bulkSave(documents: Array<Document>, options?: MongooseBulkSaveOptions): Promise<mongodb.BulkWriteResult>;

    /** Collection the model uses. */
    collection: Collection;

    /** Creates a `countDocuments` query: counts the number of documents that match `filter`. */
    countDocuments(
      filter?: FilterQuery<TRawDocType>,
      options?: (mongodb.CountOptions & MongooseBaseQueryOptions<TRawDocType>) | null
    ): QueryWithHelpers<
      number,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'countDocuments'
    >;

    /** Creates a new document or documents */
    create<DocContents = AnyKeys<TRawDocType>>(docs: Array<TRawDocType | DocContents>, options: CreateOptions & { aggregateErrors: true }): Promise<(THydratedDocumentType | Error)[]>;
    create<DocContents = AnyKeys<TRawDocType>>(docs: Array<TRawDocType | DocContents>, options?: CreateOptions): Promise<THydratedDocumentType[]>;
    create<DocContents = AnyKeys<TRawDocType>>(doc: DocContents | TRawDocType): Promise<THydratedDocumentType>;
    create<DocContents = AnyKeys<TRawDocType>>(...docs: Array<TRawDocType | DocContents>): Promise<THydratedDocumentType[]>;

    /**
     * Create the collection for this model. By default, if no indexes are specified,
     * mongoose will not create the collection for the model until any documents are
     * created. Use this method to create the collection explicitly.
     */
    createCollection<T extends mongodb.Document>(options?: mongodb.CreateCollectionOptions & Pick<SchemaOptions, 'expires'>): Promise<mongodb.Collection<T>>;

    /**
     * Create an [Atlas search index](https://www.mongodb.com/docs/atlas/atlas-search/create-index/).
     * This function only works when connected to MongoDB Atlas.
     */
    createSearchIndex(description: SearchIndexDescription): Promise<string>;

    /** Connection the model uses. */
    db: Connection;

    /**
     * Deletes all of the documents that match `conditions` from the collection.
     * Behaves like `remove()`, but deletes all documents that match `conditions`
     * regardless of the `single` option.
     */
    deleteMany(
      filter?: FilterQuery<TRawDocType>,
      options?: (mongodb.DeleteOptions & MongooseBaseQueryOptions<TRawDocType>) | null
    ): QueryWithHelpers<
      mongodb.DeleteResult,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'deleteMany'
    >;
    deleteMany(
      filter: FilterQuery<TRawDocType>
    ): QueryWithHelpers<
      mongodb.DeleteResult,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'deleteMany'
    >;

    /**
     * Deletes the first document that matches `conditions` from the collection.
     * Behaves like `remove()`, but deletes at most one document regardless of the
     * `single` option.
     */
    deleteOne(
      filter?: FilterQuery<TRawDocType>,
      options?: (mongodb.DeleteOptions & MongooseBaseQueryOptions<TRawDocType>) | null
    ): QueryWithHelpers<
      mongodb.DeleteResult,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'deleteOne'
    >;
    deleteOne(
      filter: FilterQuery<TRawDocType>
    ): QueryWithHelpers<
      mongodb.DeleteResult,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'deleteOne'
    >;

    /**
     * Delete an existing [Atlas search index](https://www.mongodb.com/docs/atlas/atlas-search/create-index/) by name.
     * This function only works when connected to MongoDB Atlas.
     */
    dropSearchIndex(name: string): Promise<void>;

    /**
     * Event emitter that reports any errors that occurred. Useful for global error
     * handling.
     */
    events: NodeJS.EventEmitter;

    /**
     * Finds a single document by its _id field. `findById(id)` is almost*
     * equivalent to `findOne({ _id: id })`. If you want to query by a document's
     * `_id`, use `findById()` instead of `findOne()`.
     */
    findById<ResultDoc = THydratedDocumentType>(
      id: any,
      projection: ProjectionType<TRawDocType> | null | undefined,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType, 'findOne'> | null,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOne'
    >;
    findById<ResultDoc = THydratedDocumentType>(
      id: any,
      projection?: ProjectionType<TRawDocType> | null,
      options?: QueryOptions<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOne'>;
    findById<ResultDoc = THydratedDocumentType>(
      id: any,
      projection?: ProjectionType<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOne'>;

    /** Finds one document. */
    findOne<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      projection: ProjectionType<TRawDocType> | null | undefined,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType, 'findOne'> | null,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOne'
    >;
    findOne<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>,
      projection?: ProjectionType<TRawDocType> | null,
      options?: QueryOptions<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOne'>;
    findOne<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>,
      projection?: ProjectionType<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOne'>;
    findOne<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOne'>;

    /**
     * Shortcut for creating a new Document from existing raw data, pre-saved in the DB.
     * The document returned has no paths marked as modified initially.
     */
    hydrate(obj: any, projection?: AnyObject, options?: HydrateOptions): THydratedDocumentType;

    /**
     * This function is responsible for building [indexes](https://www.mongodb.com/docs/manual/indexes/),
     * unless [`autoIndex`](http://mongoosejs.com/docs/guide.html#autoIndex) is turned off.
     * Mongoose calls this function automatically when a model is created using
     * [`mongoose.model()`](/docs/api/mongoose.html#mongoose_Mongoose-model) or
     * [`connection.model()`](/docs/api/connection.html#connection_Connection-model), so you
     * don't need to call it.
     */
    init(): Promise<THydratedDocumentType>;

    /** Inserts one or more new documents as a single `insertMany` call to the MongoDB server. */
    insertMany(
      docs: Array<TRawDocType>
    ): Promise<Array<THydratedDocumentType>>;
    insertMany(
      docs: Array<TRawDocType>,
      options: InsertManyOptions & { lean: true; }
    ): Promise<Array<Require_id<TRawDocType>>>;
    insertMany(
      doc: Array<TRawDocType>,
      options: InsertManyOptions & { ordered: false; rawResult: true; }
    ): Promise<mongodb.InsertManyResult<Require_id<TRawDocType>> & {
      mongoose: {
        validationErrors: (CastError | Error.ValidatorError)[];
        results: Array<
          Error |
          Object |
          THydratedDocumentType
        >
      }
    }>;
    insertMany(
      docs: Array<TRawDocType>,
      options: InsertManyOptions & { lean: true, rawResult: true; }
    ): Promise<mongodb.InsertManyResult<Require_id<TRawDocType>>>;
    insertMany(
      docs: Array<TRawDocType>,
      options: InsertManyOptions & { rawResult: true; }
    ): Promise<mongodb.InsertManyResult<Require_id<THydratedDocumentType>>>;
    insertMany(
      doc: Array<TRawDocType>,
      options: InsertManyOptions
    ): Promise<Array<THydratedDocumentType>>;
    insertMany<DocContents = TRawDocType>(
      docs: Array<DocContents | TRawDocType>,
      options: InsertManyOptions & { lean: true; }
    ): Promise<Array<Require_id<DocContents>>>;
    insertMany<DocContents = TRawDocType>(
      docs: DocContents | TRawDocType,
      options: InsertManyOptions & { lean: true; }
    ): Promise<Array<Require_id<DocContents>>>;
    insertMany<DocContents = TRawDocType>(
      doc: DocContents | TRawDocType,
      options: InsertManyOptions & { ordered: false; rawResult: true; }
    ): Promise<mongodb.InsertManyResult<Require_id<DocContents>> & {
      mongoose: {
        validationErrors: (CastError | Error.ValidatorError)[];
        results: Array<
          Error |
          Object |
          MergeType<THydratedDocumentType, DocContents>
        >
      }
    }>;
    insertMany<DocContents = TRawDocType>(
      docs: Array<DocContents | TRawDocType>,
      options: InsertManyOptions & { rawResult: true; }
    ): Promise<mongodb.InsertManyResult<Require_id<DocContents>>>;
    insertMany<DocContents = TRawDocType>(
      docs: Array<DocContents | TRawDocType>
    ): Promise<Array<MergeType<THydratedDocumentType, Omit<DocContents, '_id'>>>>;
    insertMany<DocContents = TRawDocType>(
      doc: DocContents,
      options: InsertManyOptions & { lean: true; }
    ): Promise<Array<Require_id<DocContents>>>;
    insertMany<DocContents = TRawDocType>(
      doc: DocContents,
      options: InsertManyOptions & { rawResult: true; }
    ): Promise<mongodb.InsertManyResult<Require_id<DocContents>>>;
    insertMany<DocContents = TRawDocType>(
      doc: DocContents,
      options: InsertManyOptions
    ): Promise<Array<MergeType<THydratedDocumentType, Omit<DocContents, '_id'>>>>;
    insertMany<DocContents = TRawDocType>(
      docs: Array<DocContents | TRawDocType>,
      options: InsertManyOptions
    ): Promise<Array<MergeType<THydratedDocumentType, Omit<DocContents, '_id'>>>>;
    insertMany<DocContents = TRawDocType>(
      doc: DocContents
    ): Promise<
      Array<MergeType<THydratedDocumentType, Omit<DocContents, '_id'>>>
    >;

    /** The name of the model */
    modelName: string;

    /** Populates document references. */
    populate(
      docs: Array<any>,
      options: PopulateOptions | Array<PopulateOptions> | string
    ): Promise<Array<THydratedDocumentType>>;
    populate(
      doc: any, options: PopulateOptions | Array<PopulateOptions> | string
    ): Promise<THydratedDocumentType>;
    populate<Paths>(
      docs: Array<any>,
      options: PopulateOptions | Array<PopulateOptions> | string
    ): Promise<Array<MergeType<THydratedDocumentType, Paths>>>;
    populate<Paths>(
      doc: any, options: PopulateOptions | Array<PopulateOptions> | string
    ): Promise<MergeType<THydratedDocumentType, Paths>>;

    /**
     * Update an existing [Atlas search index](https://www.mongodb.com/docs/atlas/atlas-search/create-index/).
     * This function only works when connected to MongoDB Atlas.
     */
    updateSearchIndex(name: string, definition: AnyObject): Promise<void>;

    /** Casts and validates the given object against this model's schema, passing the given `context` to custom validators. */
    validate(): Promise<void>;
    validate(obj: any): Promise<void>;
    validate(obj: any, pathsOrOptions: PathsToValidate): Promise<void>;
    validate(obj: any, pathsOrOptions: { pathsToSkip?: pathsToSkip }): Promise<void>;

    /** Watches the underlying collection for changes using [MongoDB change streams](https://www.mongodb.com/docs/manual/changeStreams/). */
    watch<ResultType extends mongodb.Document = any, ChangeType extends mongodb.ChangeStreamDocument = any>(pipeline?: Array<Record<string, unknown>>, options?: mongodb.ChangeStreamOptions & { hydrate?: boolean }): mongodb.ChangeStream<ResultType, ChangeType>;

    /** Adds a `$where` clause to this query */
    $where(argument: string | Function): QueryWithHelpers<Array<THydratedDocumentType>, THydratedDocumentType, TQueryHelpers, TRawDocType, 'find'>;

    /** Registered discriminators for this model. */
    discriminators: { [name: string]: Model<any> } | undefined;

    /** Translate any aliases fields/conditions so the final query or document object is pure */
    translateAliases(raw: any): any;

    /** Creates a `distinct` query: returns the distinct values of the given `field` that match `filter`. */
    distinct<DocKey extends string, ResultType = unknown>(
      field: DocKey,
      filter?: FilterQuery<TRawDocType>
    ): QueryWithHelpers<
      Array<DocKey extends keyof TRawDocType ? Unpacked<TRawDocType[DocKey]> : ResultType>,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'distinct'
    >;

    /** Creates a `estimatedDocumentCount` query: counts the number of documents in the collection. */
    estimatedDocumentCount(options?: QueryOptions<TRawDocType>): QueryWithHelpers<
      number,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'estimatedDocumentCount'
    >;

    /**
     * Returns a document with its `_id` if at least one document exists in the database that matches
     * the given `filter`, and `null` otherwise.
     */
    exists(
      filter: FilterQuery<TRawDocType>
    ): QueryWithHelpers<
      { _id: InferId<TRawDocType> } | null,
      THydratedDocumentType,
      TQueryHelpers,
      TRawDocType,
      'findOne'
    >;

    /** Creates a `find` query: gets a list of documents that match `filter`. */
    find<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      projection: ProjectionType<TRawDocType> | null | undefined,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType[], 'find'>,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'find'
    >;
    find<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      projection?: ProjectionType<TRawDocType> | null | undefined,
      options?: QueryOptions<TRawDocType> | null | undefined
    ): QueryWithHelpers<Array<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'find'>;
    find<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      projection?: ProjectionType<TRawDocType> | null | undefined
    ): QueryWithHelpers<Array<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'find'>;
    find<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>
    ): QueryWithHelpers<Array<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'find'>;
    find<ResultDoc = THydratedDocumentType>(
    ): QueryWithHelpers<Array<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'find'>;

    /** Creates a `findByIdAndDelete` query, filtering by the given `_id`. */
    findByIdAndDelete<ResultDoc = THydratedDocumentType>(
      id: mongodb.ObjectId | any,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType, 'findOneAndDelete'> | null,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOneAndDelete'
    >;
    findByIdAndDelete<ResultDoc = THydratedDocumentType>(
      id: mongodb.ObjectId | any,
      options: QueryOptions<TRawDocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<ModifyResult<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndDelete'>;
    findByIdAndDelete<ResultDoc = THydratedDocumentType>(
      id?: mongodb.ObjectId | any,
      options?: QueryOptions<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndDelete'>;

    /** Creates a `findOneAndUpdate` query, filtering by the given `_id`. */
    findByIdAndUpdate<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { includeResultMetadata: true, lean: true }
    ): QueryWithHelpers<
      ModifyResult<TRawDocType>,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOneAndUpdate'
    >;
    findByIdAndUpdate<ResultDoc = THydratedDocumentType>(
      id: mongodb.ObjectId | any,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType, 'findOneAndUpdate'> | null,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOneAndUpdate'
    >;
    findByIdAndUpdate<ResultDoc = THydratedDocumentType>(
      id: mongodb.ObjectId | any,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<ModifyResult<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndUpdate'>;
    findByIdAndUpdate<ResultDoc = THydratedDocumentType>(
      id: mongodb.ObjectId | any,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { upsert: true } & ReturnsNewDoc
    ): QueryWithHelpers<ResultDoc, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndUpdate'>;
    findByIdAndUpdate<ResultDoc = THydratedDocumentType>(
      id?: mongodb.ObjectId | any,
      update?: UpdateQuery<TRawDocType>,
      options?: QueryOptions<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndUpdate'>;
    findByIdAndUpdate<ResultDoc = THydratedDocumentType>(
      id: mongodb.ObjectId | any,
      update: UpdateQuery<TRawDocType>
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndUpdate'>;

    /** Creates a `findOneAndDelete` query: atomically finds the given document, deletes it, and returns the document as it was before deletion. */
    findOneAndDelete<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType, 'findOneAndDelete'> | null,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOneAndDelete'
    >;
    findOneAndDelete<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<ModifyResult<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndDelete'>;
    findOneAndDelete<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType> | null,
      options?: QueryOptions<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndDelete'>;

    /** Creates a `findOneAndReplace` query: atomically finds the given document and replaces it with `replacement`. */
    findOneAndReplace<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      replacement: TRawDocType | AnyObject,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType, 'findOneAndReplace'> | null,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOneAndReplace'
    >;
    findOneAndReplace<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      replacement: TRawDocType | AnyObject,
      options: QueryOptions<TRawDocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<ModifyResult<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndReplace'>;
    findOneAndReplace<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      replacement: TRawDocType | AnyObject,
      options: QueryOptions<TRawDocType> & { upsert: true } & ReturnsNewDoc
    ): QueryWithHelpers<ResultDoc, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndReplace'>;
    findOneAndReplace<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>,
      replacement?: TRawDocType | AnyObject,
      options?: QueryOptions<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndReplace'>;

    /** Creates a `findOneAndUpdate` query: atomically find the first document that matches `filter` and apply `update`. */
    findOneAndUpdate<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { includeResultMetadata: true, lean: true }
    ): QueryWithHelpers<
      ModifyResult<TRawDocType>,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOneAndUpdate'
    >;
    findOneAndUpdate<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { lean: true }
    ): QueryWithHelpers<
      GetLeanResultType<TRawDocType, TRawDocType, 'findOneAndUpdate'> | null,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'findOneAndUpdate'
    >;
    findOneAndUpdate<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<ModifyResult<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndUpdate'>;
    findOneAndUpdate<ResultDoc = THydratedDocumentType>(
      filter: FilterQuery<TRawDocType>,
      update: UpdateQuery<TRawDocType>,
      options: QueryOptions<TRawDocType> & { upsert: true } & ReturnsNewDoc
    ): QueryWithHelpers<ResultDoc, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndUpdate'>;
    findOneAndUpdate<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>,
      update?: UpdateQuery<TRawDocType>,
      options?: QueryOptions<TRawDocType> | null
    ): QueryWithHelpers<ResultDoc | null, ResultDoc, TQueryHelpers, TRawDocType, 'findOneAndUpdate'>;

    /** Creates a `replaceOne` query: finds the first document that matches `filter` and replaces it with `replacement`. */
    replaceOne<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>,
      replacement?: TRawDocType | AnyObject,
      options?: (mongodb.ReplaceOptions & MongooseQueryOptions<TRawDocType>) | null
    ): QueryWithHelpers<UpdateWriteOpResult, ResultDoc, TQueryHelpers, TRawDocType, 'replaceOne'>;

    /** Apply changes made to this model's schema after this model was compiled. */
    recompileSchema(): void;

    /** Schema the model uses. */
    schema: Schema<TRawDocType>;

    /** Creates a `updateMany` query: updates all documents that match `filter` with `update`. */
    updateMany<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>,
      update?: UpdateQuery<TRawDocType> | UpdateWithAggregationPipeline,
      options?: (mongodb.UpdateOptions & MongooseUpdateQueryOptions<TRawDocType>) | null
    ): QueryWithHelpers<UpdateWriteOpResult, ResultDoc, TQueryHelpers, TRawDocType, 'updateMany'>;

    /** Creates a `updateOne` query: updates the first document that matches `filter` with `update`. */
    updateOne<ResultDoc = THydratedDocumentType>(
      filter?: FilterQuery<TRawDocType>,
      update?: UpdateQuery<TRawDocType> | UpdateWithAggregationPipeline,
      options?: (mongodb.UpdateOptions & MongooseUpdateQueryOptions<TRawDocType>) | null
    ): QueryWithHelpers<UpdateWriteOpResult, ResultDoc, TQueryHelpers, TRawDocType, 'updateOne'>;

    /** Creates a Query, applies the passed conditions, and returns the Query. */
    where<ResultDoc = THydratedDocumentType>(
      path: string,
      val?: any
    ): QueryWithHelpers<Array<ResultDoc>, ResultDoc, TQueryHelpers, TRawDocType, 'find'>;
    where<ResultDoc = THydratedDocumentType>(obj: object): QueryWithHelpers<
      Array<ResultDoc>,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'find'
    >;
    where<ResultDoc = THydratedDocumentType>(): QueryWithHelpers<
      Array<ResultDoc>,
      ResultDoc,
      TQueryHelpers,
      TRawDocType,
      'find'
    >;
  }
}
