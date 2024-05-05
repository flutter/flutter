declare module 'mongoose' {
  import mongodb = require('mongodb');

  export type Condition<T> = T | QuerySelector<T | any> | any;

  /**
   * Filter query to select the documents that match the query
   * @example
   * ```js
   * { age: { $gte: 30 } }
   * ```
   */
  type FilterQuery<T> = {
    [P in keyof T]?: Condition<T[P]>;
  } & RootQuerySelector<T>;

  type MongooseBaseQueryOptionKeys =
    | 'context'
    | 'multipleCastError'
    | 'overwriteDiscriminatorKey'
    | 'populate'
    | 'runValidators'
    | 'sanitizeProjection'
    | 'sanitizeFilter'
    | 'setDefaultsOnInsert'
    | 'strict'
    | 'strictQuery'
    | 'translateAliases';

  type MongooseQueryOptions<
    DocType = unknown,
    Keys extends keyof QueryOptions<DocType> = MongooseBaseQueryOptionKeys | 'timestamps' | 'lean'
  > = Pick<QueryOptions<DocType>, Keys> & {
    [other: string]: any;
  };

  type MongooseBaseQueryOptions<DocType = unknown> = MongooseQueryOptions<DocType, MongooseBaseQueryOptionKeys>;

  type MongooseUpdateQueryOptions<DocType = unknown> = MongooseQueryOptions<
    DocType,
    MongooseBaseQueryOptionKeys | 'timestamps'
  >;

  type ProjectionFields<DocType> = { [Key in keyof DocType]?: any } & Record<string, any>;

  type QueryWithHelpers<ResultType, DocType, THelpers = {}, RawDocType = DocType, QueryOp = 'find'> = Query<ResultType, DocType, THelpers, RawDocType, QueryOp> & THelpers;

  type QuerySelector<T> = {
    // Comparison
    $eq?: T;
    $gt?: T;
    $gte?: T;
    $in?: [T] extends AnyArray<any> ? Unpacked<T>[] : T[];
    $lt?: T;
    $lte?: T;
    $ne?: T;
    $nin?: [T] extends AnyArray<any> ? Unpacked<T>[] : T[];
    // Logical
    $not?: T extends string ? QuerySelector<T> | RegExp : QuerySelector<T>;
    // Element
    /**
     * When `true`, `$exists` matches the documents that contain the field,
     * including documents where the field value is null.
     */
    $exists?: boolean;
    $type?: string | number;
    // Evaluation
    $expr?: any;
    $jsonSchema?: any;
    $mod?: T extends number ? [number, number] : never;
    $regex?: T extends string ? RegExp | string : never;
    $options?: T extends string ? string : never;
    // Geospatial
    // TODO: define better types for geo queries
    $geoIntersects?: { $geometry: object };
    $geoWithin?: object;
    $near?: object;
    $nearSphere?: object;
    $maxDistance?: number;
    // Array
    // TODO: define better types for $all and $elemMatch
    $all?: T extends AnyArray<any> ? any[] : never;
    $elemMatch?: T extends AnyArray<any> ? object : never;
    $size?: T extends AnyArray<any> ? number : never;
    // Bitwise
    $bitsAllClear?: number | mongodb.Binary | number[];
    $bitsAllSet?: number | mongodb.Binary | number[];
    $bitsAnyClear?: number | mongodb.Binary | number[];
    $bitsAnySet?: number | mongodb.Binary | number[];
  };

  type RootQuerySelector<T> = {
    /** @see https://www.mongodb.com/docs/manual/reference/operator/query/and/#op._S_and */
    $and?: Array<FilterQuery<T>>;
    /** @see https://www.mongodb.com/docs/manual/reference/operator/query/nor/#op._S_nor */
    $nor?: Array<FilterQuery<T>>;
    /** @see https://www.mongodb.com/docs/manual/reference/operator/query/or/#op._S_or */
    $or?: Array<FilterQuery<T>>;
    /** @see https://www.mongodb.com/docs/manual/reference/operator/query/text */
    $text?: {
      $search: string;
      $language?: string;
      $caseSensitive?: boolean;
      $diacriticSensitive?: boolean;
    };
    /** @see https://www.mongodb.com/docs/manual/reference/operator/query/where/#op._S_where */
    $where?: string | Function;
    /** @see https://www.mongodb.com/docs/manual/reference/operator/query/comment/#op._S_comment */
    $comment?: string;
    // we could not find a proper TypeScript generic to support nested queries e.g. 'user.friends.name'
    // this will mark all unrecognized properties as any (including nested queries)
    [key: string]: any;
  };

  interface QueryTimestampsConfig {
    createdAt?: boolean;
    updatedAt?: boolean;
  }

  interface QueryOptions<DocType = unknown> extends
    PopulateOption,
    SessionOption {
    arrayFilters?: { [key: string]: any }[];
    batchSize?: number;
    collation?: mongodb.CollationOptions;
    comment?: any;
    context?: string;
    explain?: mongodb.ExplainVerbosityLike;
    fields?: any | string;
    hint?: mongodb.Hint;
    /**
     * If truthy, mongoose will return the document as a plain JavaScript object rather than a mongoose document.
     */
    lean?: boolean | Record<string, any>;
    limit?: number;
    maxTimeMS?: number;
    multi?: boolean;
    multipleCastError?: boolean;
    /**
     * By default, `findOneAndUpdate()` returns the document as it was **before**
     * `update` was applied. If you set `new: true`, `findOneAndUpdate()` will
     * instead give you the object after `update` was applied.
     */
    new?: boolean;

    overwriteDiscriminatorKey?: boolean;
    projection?: ProjectionType<DocType>;
    /**
     * if true, returns the full ModifyResult rather than just the document
     */
    includeResultMetadata?: boolean;
    readPreference?: string | mongodb.ReadPreferenceMode;
    /**
     * An alias for the `new` option. `returnOriginal: false` is equivalent to `new: true`.
     */
    returnOriginal?: boolean;
    /**
     * Another alias for the `new` option. `returnOriginal` is deprecated so this should be used.
     */
    returnDocument?: 'before' | 'after';
    /**
     * Set to true to enable `update validators`
     * (https://mongoosejs.com/docs/validation.html#update-validators). Defaults to false.
     */
    runValidators?: boolean;
    /* Set to `true` to automatically sanitize potentially unsafe user-generated query projections */
    sanitizeProjection?: boolean;
    /**
     * Set to `true` to automatically sanitize potentially unsafe query filters by stripping out query selectors that
     * aren't explicitly allowed using `mongoose.trusted()`.
     */
    sanitizeFilter?: boolean;
    setDefaultsOnInsert?: boolean;
    skip?: number;
    sort?: any;
    /** overwrites the schema's strict mode option */
    strict?: boolean | string;
    /**
     * equal to `strict` by default, may be `false`, `true`, or `'throw'`. Sets the default
     * [strictQuery](https://mongoosejs.com/docs/guide.html#strictQuery) mode for schemas.
     */
    strictQuery?: boolean | 'throw';
    tailable?: number;
    /**
     * If set to `false` and schema-level timestamps are enabled,
     * skip timestamps for this update. Note that this allows you to overwrite
     * timestamps. Does nothing if schema-level timestamps are not set.
     */
    timestamps?: boolean | QueryTimestampsConfig;
    /**
     * If `true`, convert any aliases in filter, projection, update, and distinct
     * to their database property names. Defaults to false.
     */
    translateAliases?: boolean;
    upsert?: boolean;
    useBigInt64?: boolean;
    writeConcern?: mongodb.WriteConcern;

    [other: string]: any;
  }

  type QueryOpThatReturnsDocument = 'find' | 'findOne' | 'findOneAndUpdate' | 'findOneAndReplace' | 'findOneAndDelete';

  type GetLeanResultType<RawDocType, ResultType, QueryOp> = QueryOp extends QueryOpThatReturnsDocument
    ? (ResultType extends any[] ? Require_id<FlattenMaps<RawDocType>>[] : Require_id<FlattenMaps<RawDocType>>)
    : ResultType;

  class Query<ResultType, DocType, THelpers = {}, RawDocType = DocType, QueryOp = 'find'> implements SessionOperation {
    _mongooseOptions: MongooseQueryOptions<DocType>;

    /**
     * Returns a wrapper around a [mongodb driver cursor](https://mongodb.github.io/node-mongodb-native/4.9/classes/FindCursor.html).
     * A QueryCursor exposes a Streams3 interface, as well as a `.next()` function.
     * This is equivalent to calling `.cursor()` with no arguments.
     */
    [Symbol.asyncIterator](): AsyncIterableIterator<Unpacked<ResultType>>;

    /** Executes the query */
    exec(): Promise<ResultType>;

    $where(argument: string | Function): QueryWithHelpers<
      DocType[],
      DocType,
      THelpers,
      RawDocType,
      QueryOp
    >;

    /** Specifies an `$all` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    all(path: string, val: Array<any>): this;
    all(val: Array<any>): this;

    /** Sets the allowDiskUse option for the query (ignored for < 4.4.0) */
    allowDiskUse(value: boolean): this;

    /** Specifies arguments for an `$and` condition. */
    and(array: FilterQuery<RawDocType>[]): this;

    /** Specifies the batchSize option. */
    batchSize(val: number): this;

    /** Specifies a `$box` condition */
    box(lower: number[], upper: number[]): this;
    box(val: any): this;

    /**
     * Casts this query to the schema of `model`.
     *
     * @param {Model} [model] the model to cast to. If not set, defaults to `this.model`
     * @param {Object} [obj] If not set, defaults to this query's conditions
     * @return {Object} the casted `obj`
     */
    cast(model?: Model<any, THelpers> | null, obj?: any): any;

    /**
     * Executes the query returning a `Promise` which will be
     * resolved with either the doc(s) or rejected with the error.
     * Like `.then()`, but only takes a rejection handler.
     */
    catch: Promise<ResultType>['catch'];

    /**
     * Executes the query returning a `Promise` which will be
     * resolved with `.finally()` chained.
     */
    finally: Promise<ResultType>['finally'];

    // Returns a string representation of this query.
    [Symbol.toStringTag]: string;

    /** Specifies a `$center` or `$centerSphere` condition. */
    circle(path: string, area: any): this;
    circle(area: any): this;

    /** Make a copy of this query so you can re-execute it. */
    clone(): this;

    /** Adds a collation to this op (MongoDB 3.4 and up) */
    collation(value: mongodb.CollationOptions): this;

    /** Specifies the `comment` option. */
    comment(val: string): this;

    /** Specifies this query as a `countDocuments` query. */
    countDocuments(
      criteria?: FilterQuery<RawDocType>,
      options?: QueryOptions<DocType>
    ): QueryWithHelpers<number, DocType, THelpers, RawDocType, 'countDocuments'>;

    /**
     * Returns a wrapper around a [mongodb driver cursor](https://mongodb.github.io/node-mongodb-native/4.9/classes/FindCursor.html).
     * A QueryCursor exposes a Streams3 interface, as well as a `.next()` function.
     */
    cursor(options?: QueryOptions<DocType>): Cursor<Unpacked<ResultType>, QueryOptions<DocType>>;

    /**
     * Declare and/or execute this query as a `deleteMany()` operation. Works like
     * remove, except it deletes _every_ document that matches `filter` in the
     * collection, regardless of the value of `single`.
     */
    deleteMany(
      filter?: FilterQuery<RawDocType>,
      options?: QueryOptions<DocType>
    ): QueryWithHelpers<any, DocType, THelpers, RawDocType, 'deleteMany'>;
    deleteMany(filter: FilterQuery<RawDocType>): QueryWithHelpers<
      any,
      DocType,
      THelpers,
      RawDocType,
      'deleteMany'
    >;
    deleteMany(): QueryWithHelpers<any, DocType, THelpers, RawDocType, 'deleteMany'>;

    /**
     * Declare and/or execute this query as a `deleteOne()` operation. Works like
     * remove, except it deletes at most one document regardless of the `single`
     * option.
     */
    deleteOne(
      filter?: FilterQuery<RawDocType>,
      options?: QueryOptions<DocType>
    ): QueryWithHelpers<any, DocType, THelpers, RawDocType, 'deleteOne'>;
    deleteOne(filter: FilterQuery<RawDocType>): QueryWithHelpers<
      any,
      DocType,
      THelpers,
      RawDocType,
      'deleteOne'
    >;
    deleteOne(): QueryWithHelpers<any, DocType, THelpers, RawDocType, 'deleteOne'>;

    /** Creates a `distinct` query: returns the distinct values of the given `field` that match `filter`. */
    distinct<DocKey extends string, ResultType = unknown>(
      field: DocKey,
      filter?: FilterQuery<RawDocType>
    ): QueryWithHelpers<Array<DocKey extends keyof DocType ? Unpacked<DocType[DocKey]> : ResultType>, DocType, THelpers, RawDocType, 'distinct'>;

    /** Specifies a `$elemMatch` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    elemMatch<K = string>(path: K, val: any): this;
    elemMatch(val: Function | any): this;

    /**
     * Gets/sets the error flag on this query. If this flag is not null or
     * undefined, the `exec()` promise will reject without executing.
     */
    error(): NativeError | null;
    error(val: NativeError | null): this;

    /** Specifies the complementary comparison value for paths specified with `where()` */
    equals(val: any): this;

    /** Creates a `estimatedDocumentCount` query: counts the number of documents in the collection. */
    estimatedDocumentCount(options?: QueryOptions<DocType>): QueryWithHelpers<
      number,
      DocType,
      THelpers,
      RawDocType,
      'estimatedDocumentCount'
    >;

    /** Specifies a `$exists` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    exists<K = string>(path: K, val: boolean): this;
    exists(val: boolean): this;

    /**
     * Sets the [`explain` option](https://www.mongodb.com/docs/manual/reference/method/cursor.explain/),
     * which makes this query return detailed execution stats instead of the actual
     * query result. This method is useful for determining what index your queries
     * use.
     */
    explain(verbose?: mongodb.ExplainVerbosityLike): this;

    /** Creates a `find` query: gets a list of documents that match `filter`. */
    find(
      filter: FilterQuery<RawDocType>,
      projection?: ProjectionType<RawDocType> | null,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<Array<DocType>, DocType, THelpers, RawDocType, 'find'>;
    find(
      filter: FilterQuery<RawDocType>,
      projection?: ProjectionType<RawDocType> | null
    ): QueryWithHelpers<Array<DocType>, DocType, THelpers, RawDocType, 'find'>;
    find(
      filter: FilterQuery<RawDocType>
    ): QueryWithHelpers<Array<DocType>, DocType, THelpers, RawDocType, 'find'>;
    find(): QueryWithHelpers<Array<DocType>, DocType, THelpers, RawDocType, 'find'>;

    /** Declares the query a findOne operation. When executed, returns the first found document. */
    findOne(
      filter?: FilterQuery<RawDocType>,
      projection?: ProjectionType<RawDocType> | null,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOne'>;
    findOne(
      filter?: FilterQuery<RawDocType>,
      projection?: ProjectionType<RawDocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOne'>;
    findOne(
      filter?: FilterQuery<RawDocType>
    ): QueryWithHelpers<DocType | null, RawDocType, THelpers, RawDocType, 'findOne'>;

    /** Creates a `findOneAndDelete` query: atomically finds the given document, deletes it, and returns the document as it was before deletion. */
    findOneAndDelete(
      filter?: FilterQuery<RawDocType>,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOneAndDelete'>;

    /** Creates a `findOneAndUpdate` query: atomically find the first document that matches `filter` and apply `update`. */
    findOneAndUpdate(
      filter: FilterQuery<RawDocType>,
      update: UpdateQuery<RawDocType>,
      options: QueryOptions<DocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<ModifyResult<DocType>, DocType, THelpers, RawDocType, 'findOneAndUpdate'>;
    findOneAndUpdate(
      filter: FilterQuery<RawDocType>,
      update: UpdateQuery<RawDocType>,
      options: QueryOptions<DocType> & { upsert: true } & ReturnsNewDoc
    ): QueryWithHelpers<DocType, DocType, THelpers, RawDocType, 'findOneAndUpdate'>;
    findOneAndUpdate(
      filter?: FilterQuery<RawDocType>,
      update?: UpdateQuery<RawDocType>,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOneAndUpdate'>;

    /** Declares the query a findById operation. When executed, returns the document with the given `_id`. */
    findById(
      id: mongodb.ObjectId | any,
      projection?: ProjectionType<RawDocType> | null,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOne'>;
    findById(
      id: mongodb.ObjectId | any,
      projection?: ProjectionType<RawDocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOne'>;
    findById(
      id: mongodb.ObjectId | any
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOne'>;

    /** Creates a `findByIdAndDelete` query, filtering by the given `_id`. */
    findByIdAndDelete(
      id: mongodb.ObjectId | any,
      options: QueryOptions<DocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<ModifyResult<DocType>, DocType, THelpers, RawDocType, 'findOneAndDelete'>;
    findByIdAndDelete(
      id?: mongodb.ObjectId | any,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOneAndDelete'>;

    /** Creates a `findOneAndUpdate` query, filtering by the given `_id`. */
    findByIdAndUpdate(
      id: mongodb.ObjectId | any,
      update: UpdateQuery<RawDocType>,
      options: QueryOptions<DocType> & { includeResultMetadata: true }
    ): QueryWithHelpers<any, DocType, THelpers, RawDocType, 'findOneAndUpdate'>;
    findByIdAndUpdate(
      id: mongodb.ObjectId | any,
      update: UpdateQuery<RawDocType>,
      options: QueryOptions<DocType> & { upsert: true } & ReturnsNewDoc
    ): QueryWithHelpers<DocType, DocType, THelpers, RawDocType, 'findOneAndUpdate'>;
    findByIdAndUpdate(
      id?: mongodb.ObjectId | any,
      update?: UpdateQuery<RawDocType>,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOneAndUpdate'>;
    findByIdAndUpdate(
      id: mongodb.ObjectId | any,
      update: UpdateQuery<RawDocType>
    ): QueryWithHelpers<DocType | null, DocType, THelpers, RawDocType, 'findOneAndUpdate'>;

    /** Specifies a `$geometry` condition */
    geometry(object: { type: string, coordinates: any[] }): this;

    /**
     * For update operations, returns the value of a path in the update's `$set`.
     * Useful for writing getters/setters that can work with both update operations
     * and `save()`.
     */
    get(path: string): any;

    /** Returns the current query filter (also known as conditions) as a POJO. */
    getFilter(): FilterQuery<RawDocType>;

    /** Gets query options. */
    getOptions(): QueryOptions<DocType>;

    /** Gets a list of paths to be populated by this query */
    getPopulatedPaths(): Array<string>;

    /** Returns the current query filter. Equivalent to `getFilter()`. */
    getQuery(): FilterQuery<RawDocType>;

    /** Returns the current update operations as a JSON object. */
    getUpdate(): UpdateQuery<DocType> | UpdateWithAggregationPipeline | null;

    /** Specifies a `$gt` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    gt<K = string>(path: K, val: any): this;
    gt(val: number): this;

    /** Specifies a `$gte` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    gte<K = string>(path: K, val: any): this;
    gte(val: number): this;

    /** Sets query hints. */
    hint(val: any): this;

    /** Specifies an `$in` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    in<K = string>(path: K, val: any[]): this;
    in(val: Array<any>): this;

    /** Declares an intersects query for `geometry()`. */
    intersects(arg?: any): this;

    /** Requests acknowledgement that this operation has been persisted to MongoDB's on-disk journal. */
    j(val: boolean | null): this;

    /** Sets the lean option. */
    lean<
      LeanResultType = GetLeanResultType<RawDocType, ResultType, QueryOp>
    >(
      val?: boolean | any
    ): QueryWithHelpers<
      ResultType extends null
        ? LeanResultType | null
        : LeanResultType,
      DocType,
      THelpers,
      RawDocType,
      QueryOp
      >;

    /** Specifies the maximum number of documents the query will return. */
    limit(val: number): this;

    /** Specifies a `$lt` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    lt<K = string>(path: K, val: any): this;
    lt(val: number): this;

    /** Specifies a `$lte` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    lte<K = string>(path: K, val: any): this;
    lte(val: number): this;

    /**
     * Runs a function `fn` and treats the return value of `fn` as the new value
     * for the query to resolve to.
     */
    transform<MappedType>(fn: (doc: ResultType) => MappedType): QueryWithHelpers<MappedType, DocType, THelpers, RawDocType, QueryOp>;

    /** Specifies an `$maxDistance` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    maxDistance(path: string, val: number): this;
    maxDistance(val: number): this;

    /**
     * Sets the [maxTimeMS](https://www.mongodb.com/docs/manual/reference/method/cursor.maxTimeMS/)
     * option. This will tell the MongoDB server to abort if the query or write op
     * has been running for more than `ms` milliseconds.
     */
    maxTimeMS(ms: number): this;

    /** Merges another Query or conditions object into this one. */
    merge(source: Query<any, any> | FilterQuery<RawDocType>): this;

    /** Specifies a `$mod` condition, filters documents for documents whose `path` property is a number that is equal to `remainder` modulo `divisor`. */
    mod<K = string>(path: K, val: number): this;
    mod(val: Array<number>): this;

    /** The model this query was created from */
    model: Model<any>; // Can't use DocType, causes "Type instantiation is excessively deep"

    /**
     * Getter/setter around the current mongoose-specific options for this query
     * Below are the current Mongoose-specific options.
     */
    mongooseOptions(val?: MongooseQueryOptions): MongooseQueryOptions;

    /** Specifies a `$ne` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    ne<K = string>(path: K, val: any): this;
    ne(val: any): this;

    /** Specifies a `$near` or `$nearSphere` condition */
    near<K = string>(path: K, val: any): this;
    near(val: any): this;

    /** Specifies an `$nin` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    nin<K = string>(path: K, val: any[]): this;
    nin(val: Array<any>): this;

    /** Specifies arguments for an `$nor` condition. */
    nor(array: Array<FilterQuery<RawDocType>>): this;

    /** Specifies arguments for an `$or` condition. */
    or(array: Array<FilterQuery<RawDocType>>): this;

    /**
     * Make this query throw an error if no documents match the given `filter`.
     * This is handy for integrating with async/await, because `orFail()` saves you
     * an extra `if` statement to check if no document was found.
     */
    orFail(err?: NativeError | (() => NativeError)): QueryWithHelpers<NonNullable<ResultType>, DocType, THelpers, RawDocType, QueryOp>;

    /** Specifies a `$polygon` condition */
    polygon(path: string, ...coordinatePairs: number[][]): this;
    polygon(...coordinatePairs: number[][]): this;

    /** Specifies paths which should be populated with other documents. */
    populate<Paths = {}>(
      path: string | string[],
      select?: string | any,
      model?: string | Model<any, THelpers>,
      match?: any
    ): QueryWithHelpers<
      UnpackedIntersection<ResultType, Paths>,
      DocType,
      THelpers,
      UnpackedIntersection<RawDocType, Paths>,
      QueryOp
    >;
    populate<Paths = {}>(
      options: PopulateOptions | (PopulateOptions | string)[]
    ): QueryWithHelpers<
      UnpackedIntersection<ResultType, Paths>,
      DocType,
      THelpers,
      UnpackedIntersection<RawDocType, Paths>,
      QueryOp
    >;

    /** Add pre middleware to this query instance. Doesn't affect other queries. */
    pre(fn: Function): this;

    /** Add post middleware to this query instance. Doesn't affect other queries. */
    post(fn: Function): this;

    /** Get/set the current projection (AKA fields). Pass `null` to remove the current projection. */
    projection(fields?: ProjectionFields<DocType> | string): ProjectionFields<DocType>;
    projection(fields: null): null;
    projection(): ProjectionFields<DocType> | null;

    /** Determines the MongoDB nodes from which to read. */
    read(mode: string | mongodb.ReadPreferenceMode, tags?: any[]): this;

    /** Sets the readConcern option for the query. */
    readConcern(level: string): this;

    /** Specifies a `$regex` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    regex<K = string>(path: K, val: RegExp): this;
    regex(val: string | RegExp): this;

    /**
     * Declare and/or execute this query as a replaceOne() operation. Same as
     * `update()`, except MongoDB will replace the existing document and will
     * not accept any [atomic](https://www.mongodb.com/docs/manual/tutorial/model-data-for-atomic-operations/#pattern) operators (`$set`, etc.)
     */
    replaceOne(
      filter?: FilterQuery<RawDocType>,
      replacement?: DocType | AnyObject,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<any, DocType, THelpers, RawDocType, 'replaceOne'>;

    /** Specifies which document fields to include or exclude (also known as the query "projection") */
    select<RawDocTypeOverride extends { [P in keyof RawDocType]?: any } = {}>(
      arg: string | string[] | Record<string, number | boolean | string | object>
    ): QueryWithHelpers<
      IfEquals<
        RawDocTypeOverride,
        {},
        ResultType,
        ResultType extends any[] ?
          ResultType extends HydratedDocument<any>[] ?
            HydratedDocument<RawDocTypeOverride>[] :
            RawDocTypeOverride[] :
          ResultType extends HydratedDocument<any> ?
            HydratedDocument<RawDocTypeOverride> :
            RawDocTypeOverride
      >,
      DocType,
      THelpers,
      IfEquals<
        RawDocTypeOverride,
        {},
        RawDocType,
        RawDocTypeOverride
      >,
      QueryOp
    >;

    /** Determines if field selection has been made. */
    selected(): boolean;

    /** Determines if exclusive field selection has been made. */
    selectedExclusively(): boolean;

    /** Determines if inclusive field selection has been made. */
    selectedInclusively(): boolean;

    /**
     * Sets the [MongoDB session](https://www.mongodb.com/docs/manual/reference/server-sessions/)
     * associated with this query. Sessions are how you mark a query as part of a
     * [transaction](/docs/transactions.html).
     */
    session(session: mongodb.ClientSession | null): this;

    /**
     * Adds a `$set` to this query's update without changing the operation.
     * This is useful for query middleware so you can add an update regardless
     * of whether you use `updateOne()`, `updateMany()`, `findOneAndUpdate()`, etc.
     */
    set(path: string | Record<string, unknown>, value?: any): this;

    /** Sets query options. Some options only make sense for certain operations. */
    setOptions(options: QueryOptions<DocType>, overwrite?: boolean): this;

    /** Sets the query conditions to the provided JSON object. */
    setQuery(val: FilterQuery<RawDocType> | null): void;

    setUpdate(update: UpdateQuery<RawDocType> | UpdateWithAggregationPipeline): void;

    /** Specifies an `$size` query condition. When called with one argument, the most recent path passed to `where()` is used. */
    size<K = string>(path: K, val: number): this;
    size(val: number): this;

    /** Specifies the number of documents to skip. */
    skip(val: number): this;

    /** Specifies a `$slice` projection for an array. */
    slice(path: string, val: number | Array<number>): this;
    slice(val: number | Array<number>): this;

    /** Sets the sort order. If an object is passed, values allowed are `asc`, `desc`, `ascending`, `descending`, `1`, and `-1`. */
    sort(
      arg?: string | { [key: string]: SortOrder | { $meta: any } } | [string, SortOrder][] | undefined | null,
      options?: { override?: boolean }
    ): this;

    /** Sets the tailable option (for use with capped collections). */
    tailable(bool?: boolean, opts?: {
      numberOfRetries?: number;
      tailableRetryInterval?: number;
    }): this;

    /**
     * Executes the query returning a `Promise` which will be
     * resolved with either the doc(s) or rejected with the error.
     */
    then: Promise<ResultType>['then'];

    /** Converts this query to a customized, reusable query constructor with all arguments and options retained. */
    toConstructor<RetType = typeof Query>(): RetType;

    /**
     * Declare and/or execute this query as an updateMany() operation. Same as
     * `update()`, except MongoDB will update _all_ documents that match
     * `filter` (as opposed to just the first one) regardless of the value of
     * the `multi` option.
     */
    updateMany(
      filter?: FilterQuery<RawDocType>,
      update?: UpdateQuery<RawDocType> | UpdateWithAggregationPipeline,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<UpdateWriteOpResult, DocType, THelpers, RawDocType, 'updateMany'>;

    /**
     * Declare and/or execute this query as an updateOne() operation. Same as
     * `update()`, except it does not support the `multi` or `overwrite` options.
     */
    updateOne(
      filter?: FilterQuery<RawDocType>,
      update?: UpdateQuery<RawDocType> | UpdateWithAggregationPipeline,
      options?: QueryOptions<DocType> | null
    ): QueryWithHelpers<UpdateWriteOpResult, DocType, THelpers, RawDocType, 'updateOne'>;

    /**
     * Sets the specified number of `mongod` servers, or tag set of `mongod` servers,
     * that must acknowledge this write before this write is considered successful.
     */
    w(val: string | number | null): this;

    /** Specifies a path for use with chaining. */
    where(path: string, val?: any): this;
    where(obj: object): this;
    where(): this;

    /** Defines a `$within` or `$geoWithin` argument for geo-spatial queries. */
    within(val?: any): this;

    /**
     * If [`w > 1`](/docs/api/query.html#query_Query-w), the maximum amount of time to
     * wait for this write to propagate through the replica set before this
     * operation fails. The default is `0`, which means no timeout.
     */
    wtimeout(ms: number): this;
  }
}
