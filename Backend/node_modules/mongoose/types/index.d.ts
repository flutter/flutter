/// <reference path="./aggregate.d.ts" />
/// <reference path="./callback.d.ts" />
/// <reference path="./collection.d.ts" />
/// <reference path="./connection.d.ts" />
/// <reference path="./cursor.d.ts" />
/// <reference path="./document.d.ts" />
/// <reference path="./error.d.ts" />
/// <reference path="./expressions.d.ts" />
/// <reference path="./helpers.d.ts" />
/// <reference path="./middlewares.d.ts" />
/// <reference path="./indexes.d.ts" />
/// <reference path="./models.d.ts" />
/// <reference path="./mongooseoptions.d.ts" />
/// <reference path="./pipelinestage.d.ts" />
/// <reference path="./populate.d.ts" />
/// <reference path="./query.d.ts" />
/// <reference path="./schemaoptions.d.ts" />
/// <reference path="./schematypes.d.ts" />
/// <reference path="./session.d.ts" />
/// <reference path="./types.d.ts" />
/// <reference path="./utility.d.ts" />
/// <reference path="./validation.d.ts" />
/// <reference path="./inferschematype.d.ts" />
/// <reference path="./virtuals.d.ts" />
/// <reference path="./augmentations.d.ts" />

declare class NativeDate extends global.Date { }

declare module 'mongoose' {
  import Kareem = require('kareem');
  import events = require('events');
  import mongodb = require('mongodb');
  import mongoose = require('mongoose');

  export type Mongoose = typeof mongoose;

  /**
   * Mongoose constructor. The exports object of the `mongoose` module is an instance of this
   * class. Most apps will only use this one instance.
   */
  export const Mongoose: new (options?: MongooseOptions | null) => Mongoose;

  export let Promise: any;

  /**
   * Can be extended to explicitly type specific models.
   */
  export interface Models {
    [modelName: string]: Model<any>
  }

  /** An array containing all models associated with this Mongoose instance. */
  export const models: Models;

  /**
   * Removes the model named `name` from the default connection, if it exists.
   * You can use this function to clean up any models you created in your tests to
   * prevent OverwriteModelErrors.
   */
  export function deleteModel(name: string | RegExp): Mongoose;

  /**
   * Sanitizes query filters against query selector injection attacks by wrapping
   * any nested objects that have a property whose name starts with `$` in a `$eq`.
   */
  export function sanitizeFilter<T>(filter: FilterQuery<T>): FilterQuery<T>;

  /** Gets mongoose options */
  export function get<K extends keyof MongooseOptions>(key: K): MongooseOptions[K];

  /* ! ignore */
  export type CompileModelOptions = {
    overwriteModels?: boolean,
    connection?: Connection
  };

  export function model<TSchema extends Schema = any>(
    name: string,
    schema?: TSchema,
    collection?: string,
    options?: CompileModelOptions
  ): Model<
  InferSchemaType<TSchema>,
  ObtainSchemaGeneric<TSchema, 'TQueryHelpers'>,
  ObtainSchemaGeneric<TSchema, 'TInstanceMethods'>,
  ObtainSchemaGeneric<TSchema, 'TVirtuals'>,
  HydratedDocument<
  InferSchemaType<TSchema>,
  ObtainSchemaGeneric<TSchema, 'TVirtuals'> & ObtainSchemaGeneric<TSchema, 'TInstanceMethods'>,
  ObtainSchemaGeneric<TSchema, 'TQueryHelpers'>
  >,
  TSchema
  > & ObtainSchemaGeneric<TSchema, 'TStaticMethods'>;

  export function model<T>(name: string, schema?: Schema<T, any, any> | Schema<T & Document, any, any>, collection?: string, options?: CompileModelOptions): Model<T>;

  export function model<T, U, TQueryHelpers = {}>(
    name: string,
    schema?: Schema<T, any, any, TQueryHelpers, any, any, any>,
    collection?: string,
    options?: CompileModelOptions
  ): U;

  /** Returns an array of model names created on this instance of Mongoose. */
  export function modelNames(): Array<string>;

  /**
   * Overwrites the current driver used by this Mongoose instance. A driver is a
   * Mongoose-specific interface that defines functions like `find()`.
   */
  export function setDriver(driver: any): Mongoose;

  /** The node-mongodb-native driver Mongoose uses. */
  export { mongodb as mongo };

  /** Declares a global plugin executed on all Schemas. */
  export function plugin(fn: (schema: Schema, opts?: any) => void, opts?: any): Mongoose;

  /** Getter/setter around function for pluralizing collection names. */
  export function pluralize(fn?: ((str: string) => string) | null): ((str: string) => string) | null;

  /** Sets mongoose options */
  export function set<K extends keyof MongooseOptions>(key: K, value: MongooseOptions[K]): Mongoose;
  export function set(options: { [K in keyof MongooseOptions]: MongooseOptions[K] }): Mongoose;

  /** The Mongoose version */
  export const version: string;

  export type AnyKeys<T> = { [P in keyof T]?: T[P] | any };
  export interface AnyObject {
    [k: string]: any
  }

  export type Require_id<T> = T extends { _id?: infer U }
    ? IfAny<U, T & { _id: Types.ObjectId }, T & Required<{ _id: U }>>
    : T & { _id: Types.ObjectId };

  /** Helper type for getting the hydrated document type from the raw document type. The hydrated document type is what `new MyModel()` returns. */
  export type HydratedDocument<
    DocType,
    TOverrides = {},
    TQueryHelpers = {}
  > = IfAny<
    DocType,
    any,
    TOverrides extends Record<string, never> ?
      Document<unknown, TQueryHelpers, DocType> & Require_id<DocType> :
      IfAny<
        TOverrides,
        Document<unknown, TQueryHelpers, DocType> & Require_id<DocType>,
        Document<unknown, TQueryHelpers, DocType> & MergeType<
          Require_id<DocType>,
          TOverrides
        >
      >
  >;
  export type HydratedSingleSubdocument<DocType, TOverrides = {}> = Types.Subdocument<unknown> & Require_id<DocType> & TOverrides;
  export type HydratedArraySubdocument<DocType, TOverrides = {}> = Types.ArraySubdocument<unknown> & Require_id<DocType> & TOverrides;

  export type HydratedDocumentFromSchema<TSchema extends Schema> = HydratedDocument<
  InferSchemaType<TSchema>,
  ObtainSchemaGeneric<TSchema, 'TInstanceMethods'>,
  ObtainSchemaGeneric<TSchema, 'TQueryHelpers'>
  >;

  export interface TagSet {
    [k: string]: string;
  }

  export interface ToObjectOptions<THydratedDocumentType = HydratedDocument<unknown>> {
    /** apply all getters (path and virtual getters) */
    getters?: boolean;
    /** apply virtual getters (can override getters option) */
    virtuals?: boolean | string[];
    /** if `options.virtuals = true`, you can set `options.aliases = false` to skip applying aliases. This option is a no-op if `options.virtuals = false`. */
    aliases?: boolean;
    /** remove empty objects (defaults to true) */
    minimize?: boolean;
    /** if set, mongoose will call this function to allow you to transform the returned object */
    transform?: boolean | ((
      doc: THydratedDocumentType,
      ret: Record<string, any>,
      options: ToObjectOptions<THydratedDocumentType>
    ) => any);
    /** if true, replace any conventionally populated paths with the original id in the output. Has no affect on virtual populated paths. */
    depopulate?: boolean;
    /** if false, exclude the version key (`__v` by default) from the output */
    versionKey?: boolean;
    /** if true, convert Maps to POJOs. Useful if you want to `JSON.stringify()` the result of `toObject()`. */
    flattenMaps?: boolean;
    /** if true, convert any ObjectIds in the result to 24 character hex strings. */
    flattenObjectIds?: boolean;
    /** If true, omits fields that are excluded in this document's projection. Unless you specified a projection, this will omit any field that has `select: false` in the schema. */
    useProjection?: boolean;
  }

  export type DiscriminatorModel<M, T> = T extends Model<infer T, infer TQueryHelpers, infer TInstanceMethods, infer TVirtuals>
    ?
    M extends Model<infer M, infer MQueryHelpers, infer MInstanceMethods, infer MVirtuals>
      ? Model<Omit<M, keyof T> & T, MQueryHelpers | TQueryHelpers, MInstanceMethods | TInstanceMethods, MVirtuals | TVirtuals>
      : M
    : M;

  export type DiscriminatorSchema<DocType, M, TInstanceMethods, TQueryHelpers, TVirtuals, TStaticMethods, DisSchema> =
    DisSchema extends Schema<infer DisSchemaEDocType, infer DisSchemaM, infer DisSchemaInstanceMethods, infer DisSchemaQueryhelpers, infer DisSchemaVirtuals, infer DisSchemaStatics>
      ? Schema<MergeType<DocType, DisSchemaEDocType>, DiscriminatorModel<DisSchemaM, M>, DisSchemaInstanceMethods | TInstanceMethods, DisSchemaQueryhelpers | TQueryHelpers, DisSchemaVirtuals | TVirtuals, DisSchemaStatics & TStaticMethods>
      : Schema<DocType, M, TInstanceMethods, TQueryHelpers, TVirtuals, TStaticMethods>;

  type QueryResultType<T> = T extends Query<infer ResultType, any> ? ResultType : never;

  type PluginFunction<
    DocType,
    M,
    TInstanceMethods,
    TQueryHelpers,
    TVirtuals,
    TStaticMethods> = (schema: Schema<DocType, M, TInstanceMethods, TQueryHelpers, TVirtuals, TStaticMethods>, opts?: any) => void;

  export class Schema<
    EnforcedDocType = any,
    TModelType = Model<EnforcedDocType, any, any, any>,
    TInstanceMethods = {},
    TQueryHelpers = {},
    TVirtuals = {},
    TStaticMethods = {},
    TSchemaOptions = DefaultSchemaOptions,
    DocType extends ApplySchemaOptions<
      ObtainDocumentType<DocType, EnforcedDocType, ResolveSchemaOptions<TSchemaOptions>>,
      ResolveSchemaOptions<TSchemaOptions>
    > = ApplySchemaOptions<
      ObtainDocumentType<any, EnforcedDocType, ResolveSchemaOptions<TSchemaOptions>>,
      ResolveSchemaOptions<TSchemaOptions>
    >,
    THydratedDocumentType = HydratedDocument<FlatRecord<DocType>, TVirtuals & TInstanceMethods>
  >
    extends events.EventEmitter {
    /**
     * Create a new schema
     */
    constructor(definition?: SchemaDefinition<SchemaDefinitionType<EnforcedDocType>, EnforcedDocType> | DocType, options?: SchemaOptions<FlatRecord<DocType>, TInstanceMethods, TQueryHelpers, TStaticMethods, TVirtuals, THydratedDocumentType> | ResolveSchemaOptions<TSchemaOptions>);

    /** Adds key path / schema type pairs to this schema. */
    add(obj: SchemaDefinition<SchemaDefinitionType<EnforcedDocType>> | Schema, prefix?: string): this;

    /**
     * Add an alias for `path`. This means getting or setting the `alias`
     * is equivalent to getting or setting the `path`.
     */
    alias(path: string, alias: string | string[]): this;

    /**
     * Array of child schemas (from document arrays and single nested subdocs)
     * and their corresponding compiled models. Each element of the array is
     * an object with 2 properties: `schema` and `model`.
     */
    childSchemas: { schema: Schema, model: any }[];

    /** Removes all indexes on this schema */
    clearIndexes(): this;

    /** Returns a copy of this schema */
    clone<T = this>(): T;

    discriminator<DisSchema = Schema>(name: string | number, schema: DisSchema): this;

    /** Returns a new schema that has the picked `paths` from this schema. */
    pick<T = this>(paths: string[], options?: SchemaOptions): T;

    /** Object containing discriminators defined on this schema */
    discriminators?: { [name: string]: Schema };

    /** Iterates the schemas paths similar to Array#forEach. */
    eachPath(fn: (path: string, type: SchemaType) => void): this;

    /** Defines an index (most likely compound) for this schema. */
    index(fields: IndexDefinition, options?: IndexOptions): this;

    /**
     * Define a search index for this schema.
     *
     * @remarks Search indexes are only supported when used against a 7.0+ Mongo Atlas cluster.
     */
    searchIndex(description: SearchIndexDescription): this;

    /**
     * Returns a list of indexes that this schema declares, via `schema.index()`
     * or by `index: true` in a path's options.
     */
    indexes(): Array<[IndexDefinition, IndexOptions]>;

    /** Gets a schema option. */
    get<K extends keyof SchemaOptions>(key: K): SchemaOptions[K];

    /**
     * Loads an ES6 class into a schema. Maps [setters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/set) + [getters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/get), [static methods](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/static),
     * and [instance methods](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes#Class_body_and_method_definitions)
     * to schema [virtuals](http://mongoosejs.com/docs/guide.html#virtuals),
     * [statics](http://mongoosejs.com/docs/guide.html#statics), and
     * [methods](http://mongoosejs.com/docs/guide.html#methods).
     */
    loadClass(model: Function, onlyVirtuals?: boolean): this;

    /** Adds an instance method to documents constructed from Models compiled from this schema. */
    method<Context = THydratedDocumentType>(name: string, fn: (this: Context, ...args: any[]) => any, opts?: any): this;
    method(obj: Partial<TInstanceMethods>): this;

    /** Object of currently defined methods on this schema. */
    methods: AddThisParameter<TInstanceMethods, THydratedDocumentType> & AnyObject;

    /** The original object passed to the schema constructor */
    obj: SchemaDefinition<SchemaDefinitionType<EnforcedDocType>, EnforcedDocType>;

    /** Returns a new schema that has the `paths` from the original schema, minus the omitted ones. */
    omit<T = this>(paths: string[], options?: SchemaOptions): T;

    /** Gets/sets schema paths. */
    path<ResultType extends SchemaType = SchemaType<any, THydratedDocumentType>>(path: string): ResultType;
    path<pathGeneric extends keyof EnforcedDocType>(path: pathGeneric): SchemaType<EnforcedDocType[pathGeneric]>;
    path(path: string, constructor: any): this;

    /** Lists all paths and their type in the schema. */
    paths: {
      [key: string]: SchemaType;
    };

    /** Returns the pathType of `path` for this schema. */
    pathType(path: string): string;

    /** Registers a plugin for this schema. */
    plugin<PFunc extends PluginFunction<DocType, TModelType, any, any, any, any>, POptions extends Parameters<PFunc>[1] = Parameters<PFunc>[1]>(fn: PFunc, opts?: POptions): this;

    /** Defines a post hook for the model. */

    // PostMiddlewareFunction
    // with errorHandler set to true
    post<T = Query<any, any>>(method: MongooseQueryMiddleware | MongooseQueryMiddleware[] | RegExp, options: SchemaPostOptions & { errorHandler: true }, fn: ErrorHandlingMiddlewareWithOption<T>): this;
    post<T = THydratedDocumentType>(method: MongooseDocumentMiddleware | MongooseDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { errorHandler: true }, fn: ErrorHandlingMiddlewareWithOption<T>): this;
    post<T extends Aggregate<any>>(method: 'aggregate' | RegExp, options: SchemaPostOptions & { errorHandler: true }, fn: ErrorHandlingMiddlewareWithOption<T, Array<any>>): this;
    post<T = TModelType>(method: 'insertMany' | RegExp, options: SchemaPostOptions & { errorHandler: true }, fn: ErrorHandlingMiddlewareWithOption<T>): this;

    // this = never since it never happens
    post<T = never>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: false, query: false }, fn: PostMiddlewareFunction<never, never>): this;
    post<T = never>(method: MongooseDistinctQueryMiddleware|MongooseDistinctQueryMiddleware[], options: SchemaPostOptions & { document: boolean, query: false }, fn: PostMiddlewareFunction<T, QueryResultType<T>>): this;
    post<T = never>(method: MongooseDistinctDocumentMiddleware | MongooseDistinctDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: false, query: true }, fn: PostMiddlewareFunction<T, T>): this;
    // this = Document
    post<T = THydratedDocumentType>(method: MongooseDistinctDocumentMiddleware|MongooseDistinctDocumentMiddleware[], fn: PostMiddlewareFunction<T, T>): this;
    post<T = THydratedDocumentType>(method: MongooseDistinctDocumentMiddleware|MongooseDistinctDocumentMiddleware[], options: SchemaPostOptions & SchemaPostOptions, fn: PostMiddlewareFunction<T, T>): this;
    post<T = THydratedDocumentType>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: true, query: false }, fn: PostMiddlewareFunction<T, T>): this;
    // this = Query
    post<T = Query<any, any>>(method: MongooseRawResultQueryMiddleware|MongooseRawResultQueryMiddleware[], fn: PostMiddlewareFunction<T, null | QueryResultType<T> | ModifyResult<QueryResultType<T>>>): this;
    post<T = Query<any, any>>(method: MongooseDefaultQueryMiddleware|MongooseDefaultQueryMiddleware[], fn: PostMiddlewareFunction<T, QueryResultType<T>>): this;
    post<T = Query<any, any>>(method: MongooseDistinctQueryMiddleware|MongooseDistinctQueryMiddleware[], options: SchemaPostOptions, fn: PostMiddlewareFunction<T, QueryResultType<T>>): this;
    post<T = Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: false, query: true }, fn: PostMiddlewareFunction<T, QueryResultType<T>>): this;
    // this = Union of Document and Query, could be called with any of them
    post<T = THydratedDocumentType|Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: true, query: true }, fn: PostMiddlewareFunction<T, T|QueryResultType<T>>): this;
    post<T = THydratedDocumentType|Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, fn: PostMiddlewareFunction<T, T|QueryResultType<T>>): this;

    // ErrorHandlingMiddlewareFunction
    // this = never since it never happens
    post<T = never>(method: MongooseDistinctQueryMiddleware|MongooseDistinctQueryMiddleware[], options: SchemaPostOptions & { document: boolean, query: false }, fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = never>(method: MongooseDistinctDocumentMiddleware|MongooseDistinctDocumentMiddleware[], options: SchemaPostOptions & { document: false, query: boolean }, fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = never>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: false, query: false }, fn: ErrorHandlingMiddlewareFunction<T>): this;
    // this = Document
    post<T = THydratedDocumentType>(method: MongooseDistinctDocumentMiddleware|MongooseDistinctDocumentMiddleware[], fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = THydratedDocumentType>(method: MongooseDistinctDocumentMiddleware|MongooseDistinctDocumentMiddleware[], options: SchemaPostOptions, fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = THydratedDocumentType>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: true, query: false }, fn: ErrorHandlingMiddlewareFunction<T>): this;
    // this = Query
    post<T = Query<any, any>>(method: MongooseDefaultQueryMiddleware|MongooseDefaultQueryMiddleware[], fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = Query<any, any>>(method: MongooseDistinctQueryMiddleware|MongooseDistinctQueryMiddleware[], options: SchemaPostOptions, fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: false, query: true }, fn: ErrorHandlingMiddlewareFunction<T>): this;
    // this = Union of Document and Query, could be called with any of them
    post<T = THydratedDocumentType|Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPostOptions & { document: true, query: true }, fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = THydratedDocumentType|Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, fn: ErrorHandlingMiddlewareFunction<T>): this;

    // method aggregate and insertMany with PostMiddlewareFunction
    post<T extends Aggregate<any>>(method: 'aggregate' | RegExp, fn: PostMiddlewareFunction<T, Array<AggregateExtract<T>>>): this;
    post<T extends Aggregate<any>>(method: 'aggregate' | RegExp, options: SchemaPostOptions, fn: PostMiddlewareFunction<T, Array<AggregateExtract<T>>>): this;
    post<T = TModelType>(method: 'insertMany' | RegExp, fn: PostMiddlewareFunction<T, T>): this;
    post<T = TModelType>(method: 'insertMany' | RegExp, options: SchemaPostOptions, fn: PostMiddlewareFunction<T, T>): this;

    // method aggregate and insertMany with ErrorHandlingMiddlewareFunction
    post<T extends Aggregate<any>>(method: 'aggregate' | RegExp, fn: ErrorHandlingMiddlewareFunction<T, Array<any>>): this;
    post<T extends Aggregate<any>>(method: 'aggregate' | RegExp, options: SchemaPostOptions, fn: ErrorHandlingMiddlewareFunction<T, Array<any>>): this;
    post<T = TModelType>(method: 'bulkWrite' | 'createCollection' | 'insertMany' | RegExp, fn: ErrorHandlingMiddlewareFunction<T>): this;
    post<T = TModelType>(method: 'bulkWrite' | 'createCollection' | 'insertMany' | RegExp, options: SchemaPostOptions, fn: ErrorHandlingMiddlewareFunction<T>): this;

    /** Defines a pre hook for the model. */
    // this = never since it never happens
    pre<T = never>(method: 'save', options: SchemaPreOptions & { document: false, query: boolean }, fn: PreSaveMiddlewareFunction<T>): this;
    pre<T = never>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPreOptions & { document: false, query: false }, fn: PreMiddlewareFunction<T>): this;
    pre<T = never>(method: MongooseDistinctQueryMiddleware|MongooseDistinctQueryMiddleware[], options: SchemaPreOptions & { document: boolean, query: false }, fn: PreMiddlewareFunction<T>): this;
    pre<T = never>(method: MongooseDistinctDocumentMiddleware | MongooseDistinctDocumentMiddleware[] | RegExp, options: SchemaPreOptions & { document: false, query: boolean }, fn: PreMiddlewareFunction<T>): this;
    // this = Union of Document and Query, could be called with any of them
    pre<T = THydratedDocumentType | Query<any, any>>(
      method: MongooseQueryAndDocumentMiddleware | MongooseQueryAndDocumentMiddleware[] | RegExp,
      options: SchemaPreOptions & { document: true, query: true },
      fn: PreMiddlewareFunction<T>
    ): this;
    // this = Document
    pre<T = THydratedDocumentType>(method: 'save', fn: PreSaveMiddlewareFunction<T>): this;
    pre<T = THydratedDocumentType>(method: MongooseDistinctDocumentMiddleware|MongooseDistinctDocumentMiddleware[], fn: PreMiddlewareFunction<T>): this;
    pre<T = THydratedDocumentType>(method: MongooseDistinctDocumentMiddleware|MongooseDistinctDocumentMiddleware[], options: SchemaPreOptions, fn: PreMiddlewareFunction<T>): this;
    pre<T = THydratedDocumentType>(
      method: MongooseQueryAndDocumentMiddleware | MongooseQueryAndDocumentMiddleware[] | RegExp,
      options: SchemaPreOptions & { document: true },
      fn: PreMiddlewareFunction<T>
    ): this;
    pre<T = THydratedDocumentType>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPreOptions & { document: true, query: false }, fn: PreMiddlewareFunction<T>): this;
    // this = Query
    pre<T = Query<any, any>>(method: MongooseDefaultQueryMiddleware|MongooseDefaultQueryMiddleware[], fn: PreMiddlewareFunction<T>): this;
    pre<T = Query<any, any>>(method: MongooseDistinctQueryMiddleware|MongooseDistinctQueryMiddleware[], options: SchemaPreOptions, fn: PreMiddlewareFunction<T>): this;
    pre<T = Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPreOptions & { document: false, query: true }, fn: PreMiddlewareFunction<T>): this;
    // this = Union of Document and Query, could be called with any of them
    pre<T = THydratedDocumentType|Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, options: SchemaPreOptions & { document: true, query: true }, fn: PreMiddlewareFunction<T>): this;
    pre<T = THydratedDocumentType|Query<any, any>>(method: MongooseQueryOrDocumentMiddleware | MongooseQueryOrDocumentMiddleware[] | RegExp, fn: PreMiddlewareFunction<T>): this;
    // method aggregate
    pre<T extends Aggregate<any>>(method: 'aggregate' | RegExp, fn: PreMiddlewareFunction<T>): this;
    /* method insertMany */
    pre<T = TModelType>(
      method: 'insertMany' | RegExp,
      fn: (
        this: T,
        next: (err?: CallbackError) => void,
        docs: any | Array<any>,
        options?: InsertManyOptions & { lean?: boolean }
      ) => void | Promise<void>
    ): this;
    /* method bulkWrite */
    pre<T = TModelType>(
      method: 'bulkWrite' | RegExp,
      fn: (
        this: T,
        next: (err?: CallbackError) => void,
        ops: Array<AnyBulkWriteOperation<any>>,
        options?: mongodb.BulkWriteOptions & MongooseBulkWriteOptions
      ) => void | Promise<void>
    ): this;
    /* method createCollection */
    pre<T = TModelType>(
      method: 'createCollection' | RegExp,
      fn: (
        this: T,
        next: (err?: CallbackError) => void,
        options?: mongodb.CreateCollectionOptions & Pick<SchemaOptions, 'expires'>
      ) => void | Promise<void>
    ): this;

    /** Object of currently defined query helpers on this schema. */
    query: TQueryHelpers;

    /** Adds a method call to the queue. */
    queue(name: string, args: any[]): this;

    /** Removes the given `path` (or [`paths`]). */
    remove(paths: string | Array<string>): this;

    /** Removes index by name or index spec */
    remove(index: string | AnyObject): this;

    /** Returns an Array of path strings that are required by this schema. */
    requiredPaths(invalidate?: boolean): string[];

    /** Sets a schema option. */
    set<K extends keyof SchemaOptions>(key: K, value: SchemaOptions[K], _tags?: any): this;

    /** Adds static "class" methods to Models compiled from this schema. */
    static<K extends keyof TStaticMethods>(name: K, fn: TStaticMethods[K]): this;
    static(obj: { [F in keyof TStaticMethods]: TStaticMethods[F] } & { [name: string]: (this: TModelType, ...args: any[]) => any }): this;
    static(name: string, fn: (this: TModelType, ...args: any[]) => any): this;

    /** Object of currently defined statics on this schema. */
    statics: { [F in keyof TStaticMethods]: TStaticMethods[F] } &
    { [name: string]: (this: TModelType, ...args: any[]) => unknown };

    /** Creates a virtual type with the given name. */
    virtual<T = HydratedDocument<DocType, TVirtuals & TInstanceMethods, TQueryHelpers>>(
      name: keyof TVirtuals | string,
      options?: VirtualTypeOptions<T, DocType>
    ): VirtualType<T>;

    /** Object of currently defined virtuals on this schema */
    virtuals: TVirtuals;

    /** Returns the virtual type with the given `name`. */
    virtualpath<T = THydratedDocumentType>(name: string): VirtualType<T> | null;

    static ObjectId: typeof Schema.Types.ObjectId;
  }

  export type NumberSchemaDefinition = typeof Number | 'number' | 'Number' | typeof Schema.Types.Number;
  export type StringSchemaDefinition = typeof String | 'string' | 'String' | typeof Schema.Types.String;
  export type BooleanSchemaDefinition = typeof Boolean | 'boolean' | 'Boolean' | typeof Schema.Types.Boolean;
  export type DateSchemaDefinition = typeof NativeDate | 'date' | 'Date' | typeof Schema.Types.Date;
  export type ObjectIdSchemaDefinition = 'ObjectId' | 'ObjectID' | typeof Schema.Types.ObjectId;

  export type SchemaDefinitionWithBuiltInClass<T> = T extends number
    ? NumberSchemaDefinition
    : T extends string
      ? StringSchemaDefinition
      : T extends boolean
        ? BooleanSchemaDefinition
        : T extends NativeDate
          ? DateSchemaDefinition
          : (Function | string);

  export type SchemaDefinitionProperty<T = undefined, EnforcedDocType = any> = SchemaDefinitionWithBuiltInClass<T> |
  SchemaTypeOptions<T extends undefined ? any : T, EnforcedDocType> |
    typeof SchemaType |
  Schema<any, any, any> |
  Schema<any, any, any>[] |
  SchemaTypeOptions<T extends undefined ? any : Unpacked<T>, EnforcedDocType>[] |
  Function[] |
  SchemaDefinition<T, EnforcedDocType> |
  SchemaDefinition<Unpacked<T>, EnforcedDocType>[] |
    typeof Schema.Types.Mixed |
  MixedSchemaTypeOptions<EnforcedDocType>;

  export type SchemaDefinition<T = undefined, EnforcedDocType = any> = T extends undefined
    ? { [path: string]: SchemaDefinitionProperty; }
    : { [path in keyof T]?: SchemaDefinitionProperty<T[path], EnforcedDocType>; };

  export type AnyArray<T> = T[] | ReadonlyArray<T>;
  export type ExtractMongooseArray<T> = T extends Types.Array<any> ? AnyArray<Unpacked<T>> : T;

  export interface MixedSchemaTypeOptions<EnforcedDocType> extends SchemaTypeOptions<Schema.Types.Mixed, EnforcedDocType> {
    type: typeof Schema.Types.Mixed;
  }

  export type RefType =
    | number
    | string
    | Buffer
    | undefined
    | Types.ObjectId
    | Types.Buffer
    | typeof Schema.Types.Number
    | typeof Schema.Types.String
    | typeof Schema.Types.Buffer
    | typeof Schema.Types.ObjectId;


  export type InferId<T> = T extends { _id?: any } ? T['_id'] : Types.ObjectId;

  export interface VirtualTypeOptions<HydratedDocType = Document, DocType = unknown> {
    /** If `ref` is not nullish, this becomes a populated virtual. */
    ref?: string | Function;

    /** The local field to populate on if this is a populated virtual. */
    localField?: string | ((this: HydratedDocType, doc: HydratedDocType) => string);

    /** The foreign field to populate on if this is a populated virtual. */
    foreignField?: string | ((this: HydratedDocType, doc: HydratedDocType) => string);

    /**
     * By default, a populated virtual is an array. If you set `justOne`,
     * the populated virtual will be a single doc or `null`.
     */
    justOne?: boolean;

    /** If you set this to `true`, Mongoose will call any custom getters you defined on this virtual. */
    getters?: boolean;

    /**
     * If you set this to `true`, `populate()` will set this virtual to the number of populated
     * documents, as opposed to the documents themselves, using `Query#countDocuments()`.
     */
    count?: boolean;

    /** Add an extra match condition to `populate()`. */
    match?: FilterQuery<any> | ((doc: Record<string, any>, virtual?: this) => Record<string, any> | null);

    /** Add a default `limit` to the `populate()` query. */
    limit?: number;

    /** Add a default `skip` to the `populate()` query. */
    skip?: number;

    /**
     * For legacy reasons, `limit` with `populate()` may give incorrect results because it only
     * executes a single query for every document being populated. If you set `perDocumentLimit`,
     * Mongoose will ensure correct `limit` per document by executing a separate query for each
     * document to `populate()`. For example, `.find().populate({ path: 'test', perDocumentLimit: 2 })`
     * will execute 2 additional queries if `.find()` returns 2 documents.
     */
    perDocumentLimit?: number;

    /** Additional options like `limit` and `lean`. */
    options?: QueryOptions<DocType> & { match?: AnyObject };

    /** Additional options for plugins */
    [extra: string]: any;
  }

  export class VirtualType<HydratedDocType> {
    /** Applies getters to `value`. */
    applyGetters(value: any, doc: Document): any;

    /** Applies setters to `value`. */
    applySetters(value: any, doc: Document): any;

    /** Adds a custom getter to this virtual. */
    get<T = HydratedDocType>(fn: (this: T, value: any, virtualType: VirtualType<T>, doc: T) => any): this;

    /** Adds a custom setter to this virtual. */
    set<T = HydratedDocType>(fn: (this: T, value: any, virtualType: VirtualType<T>, doc: T) => void): this;
  }

  export type ReturnsNewDoc = { new: true } | { returnOriginal: false } | { returnDocument: 'after' };

  export type ProjectionElementType = number | string;
  export type ProjectionType<T> = { [P in keyof T]?: ProjectionElementType } | AnyObject | string;

  export type SortValues = SortOrder;

  export type SortOrder = -1 | 1 | 'asc' | 'ascending' | 'desc' | 'descending';

  type _UpdateQuery<TSchema, AdditionalProperties = AnyObject> = {
    /** @see https://www.mongodb.com/docs/manual/reference/operator/update-field/ */
    $currentDate?: AnyKeys<TSchema> & AdditionalProperties;
    $inc?: AnyKeys<TSchema> & AdditionalProperties;
    $min?: AnyKeys<TSchema> & AdditionalProperties;
    $max?: AnyKeys<TSchema> & AdditionalProperties;
    $mul?: AnyKeys<TSchema> & AdditionalProperties;
    $rename?: Record<string, string>;
    $set?: AnyKeys<TSchema> & AdditionalProperties;
    $setOnInsert?: AnyKeys<TSchema> & AdditionalProperties;
    $unset?: AnyKeys<TSchema> & AdditionalProperties;

    /** @see https://www.mongodb.com/docs/manual/reference/operator/update-array/ */
    $addToSet?: AnyKeys<TSchema> & AdditionalProperties;
    $pop?: AnyKeys<TSchema> & AdditionalProperties;
    $pull?: AnyKeys<TSchema> & AdditionalProperties;
    $push?: AnyKeys<TSchema> & AdditionalProperties;
    $pullAll?: AnyKeys<TSchema> & AdditionalProperties;

    /** @see https://www.mongodb.com/docs/manual/reference/operator/update-bitwise/ */
    $bit?: AnyKeys<TSchema>;
  };

  export type UpdateWithAggregationPipeline = UpdateAggregationStage[];
  export type UpdateAggregationStage = { $addFields: any } |
  { $set: any } |
  { $project: any } |
  { $unset: any } |
  { $replaceRoot: any } |
  { $replaceWith: any };

  /**
   * Update query command to perform on the document
   * @example
   * ```js
   * { age: 30 }
   * ```
   */
  export type UpdateQuery<T> = AnyKeys<T> & _UpdateQuery<T> & AnyObject;

  /**
   * A more strict form of UpdateQuery that enforces updating only
   * known top-level properties.
   * @example
   * ```ts
   * function updateUser(_id: mongoose.Types.ObjectId, update: UpdateQueryKnownOnly<IUser>) {
   *   return User.updateOne({ _id }, update);
   * }
   * ```
   */
  export type UpdateQueryKnownOnly<T> = _UpdateQuery<T, {}>;

  export type FlattenMaps<T> = {
    [K in keyof T]: FlattenProperty<T[K]>;
  };

  /**
   * Separate type is needed for properties of union type (for example, Types.DocumentArray | undefined) to apply conditional check to each member of it
   * https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types
   */
  type FlattenProperty<T> = T extends Map<any, infer V>
    ? Record<string, V> : T extends TreatAsPrimitives
      ? T : T extends Types.DocumentArray<infer ItemType>
        ? Types.DocumentArray<FlattenMaps<ItemType>> : FlattenMaps<T>;

  export type actualPrimitives = string | boolean | number | bigint | symbol | null | undefined;
  export type TreatAsPrimitives = actualPrimitives | NativeDate | RegExp | symbol | Error | BigInt | Types.ObjectId | Buffer | Function;

  export type SchemaDefinitionType<T> = T extends Document ? Omit<T, Exclude<keyof Document, '_id' | 'id' | '__v'>> : T;

  /**
   * Helper to choose the best option between two type helpers
   */
  export type _pickObject<T1, T2, Fallback> = T1 extends false ? T2 extends false ? Fallback : T2 : T1;

  /* for ts-mongoose */
  export class mquery { }

  export function overwriteMiddlewareResult(val: any): Kareem.OverwriteMiddlewareResult;

  export function skipMiddlewareFunction(val: any): Kareem.SkipWrappedFunction;

  export default mongoose;
}
