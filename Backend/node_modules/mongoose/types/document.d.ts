declare module 'mongoose' {
  import mongodb = require('mongodb');

  /** A list of paths to skip. If set, Mongoose will validate every modified path that is not in this list. */
  type pathsToSkip = string[] | string;

  interface DocumentSetOptions {
    merge?: boolean;

    [key: string]: any;
  }

  /**
   * Generic types for Document:
   * *  T - the type of _id
   * *  TQueryHelpers - Object with any helpers that should be mixed into the Query type
   * *  DocType - the type of the actual Document created
   */
  class Document<T = any, TQueryHelpers = any, DocType = any> {
    constructor(doc?: any);

    /** This documents _id. */
    _id?: T;

    /** This documents __v. */
    __v?: any;

    /** Assert that a given path or paths is populated. Throws an error if not populated. */
    $assertPopulated<Paths = {}>(path: string | string[], values?: Partial<Paths>): Omit<this, keyof Paths> & Paths;

    /** Returns a deep clone of this document */
    $clone(): this;

    /* Get all subdocs (by bfs) */
    $getAllSubdocs(): Document[];

    /** Don't run validation on this path or persist changes to this path. */
    $ignore(path: string): void;

    /** Checks if a path is set to its default. */
    $isDefault(path: string): boolean;

    /** Getter/setter, determines whether the document was removed or not. */
    $isDeleted(val?: boolean): boolean;

    /** Returns an array of all populated documents associated with the query */
    $getPopulatedDocs(): Document[];

    /**
     * Increments the numeric value at `path` by the given `val`.
     * When you call `save()` on this document, Mongoose will send a
     * `$inc` as opposed to a `$set`.
     */
    $inc(path: string | string[], val?: number): this;

    /**
     * Returns true if the given path is nullish or only contains empty objects.
     * Useful for determining whether this subdoc will get stripped out by the
     * [minimize option](/docs/guide.html#minimize).
     */
    $isEmpty(path: string): boolean;

    /** Checks if a path is invalid */
    $isValid(path: string): boolean;

    /**
     * Empty object that you can use for storing properties on the document. This
     * is handy for passing data to middleware without conflicting with Mongoose
     * internals.
     */
    $locals: Record<string, unknown>;

    /** Marks a path as valid, removing existing validation errors. */
    $markValid(path: string): void;

    /** Returns the model with the given name on this document's associated connection. */
    $model<ModelType = Model<unknown>>(name: string): ModelType;
    $model<ModelType = Model<DocType>>(): ModelType;

    /**
     * A string containing the current operation that Mongoose is executing
     * on this document. Can be `null`, `'save'`, `'validate'`, or `'remove'`.
     */
    $op: 'save' | 'validate' | 'remove' | null;

    /**
     * Getter/setter around the session associated with this document. Used to
     * automatically set `session` if you `save()` a doc that you got from a
     * query with an associated session.
     */
    $session(session?: ClientSession | null): ClientSession | null;

    /** Alias for `set()`, used internally to avoid conflicts */
    $set(path: string | Record<string, any>, val: any, type: any, options?: DocumentSetOptions): this;
    $set(path: string | Record<string, any>, val: any, options?: DocumentSetOptions): this;
    $set(value: string | Record<string, any>): this;

    /** Set this property to add additional query filters when Mongoose saves this document and `isNew` is false. */
    $where: Record<string, unknown>;

    /** If this is a discriminator model, `baseModelName` is the name of the base model. */
    baseModelName?: string;

    /** Collection the model uses. */
    collection: Collection;

    /** Connection the model uses. */
    db: Connection;

    /** Removes this document from the db. */
    deleteOne(options?: QueryOptions): QueryWithHelpers<
      mongodb.DeleteResult,
      this,
      TQueryHelpers,
      DocType,
      'deleteOne'
    >;

    /**
     * Takes a populated field and returns it to its unpopulated state. If called with
     * no arguments, then all populated fields are returned to their unpopulated state.
     */
    depopulate(path?: string | string[]): this;

    /**
     * Returns the list of paths that have been directly modified. A direct
     * modified path is a path that you explicitly set, whether via `doc.foo = 'bar'`,
     * `Object.assign(doc, { foo: 'bar' })`, or `doc.set('foo', 'bar')`.
     */
    directModifiedPaths(): Array<string>;

    /**
     * Returns true if this document is equal to another document.
     *
     * Documents are considered equal when they have matching `_id`s, unless neither
     * document has an `_id`, in which case this function falls back to using
     * `deepEqual()`.
     */
    equals(doc: Document<T>): boolean;

    /** Returns the current validation errors. */
    errors?: Error.ValidationError;

    /** Returns the value of a path. */
    get<T extends keyof DocType>(path: T, type?: any, options?: any): DocType[T];
    get(path: string, type?: any, options?: any): any;

    /**
     * Returns the changes that happened to the document
     * in the format that will be sent to MongoDB.
     */
    getChanges(): UpdateQuery<this>;

    /** The string version of this documents _id. */
    id?: any;

    /** Signal that we desire an increment of this documents version. */
    increment(): this;

    /**
    * Initializes the document without setters or marking anything modified.
    * Called internally after a document is returned from mongodb. Normally,
    * you do **not** need to call this function on your own.
    */
    init(obj: AnyObject, opts?: AnyObject): this;

    /** Marks a path as invalid, causing validation to fail. */
    invalidate<T extends keyof DocType>(path: T, errorMsg: string | NativeError, value?: any, kind?: string): NativeError | null;
    invalidate(path: string, errorMsg: string | NativeError, value?: any, kind?: string): NativeError | null;

    /** Returns true if `path` was directly set and modified, else false. */
    isDirectModified<T extends keyof DocType>(path: T | Array<T>): boolean;
    isDirectModified(path: string | Array<string>): boolean;

    /** Checks if `path` was explicitly selected. If no projection, always returns true. */
    isDirectSelected<T extends keyof DocType>(path: T): boolean;
    isDirectSelected(path: string): boolean;

    /** Checks if `path` is in the `init` state, that is, it was set by `Document#init()` and not modified since. */
    isInit<T extends keyof DocType>(path: T): boolean;
    isInit(path: string): boolean;

    /**
     * Returns true if any of the given paths are modified, else false. If no arguments, returns `true` if any path
     * in this document is modified.
     */
    isModified<T extends keyof DocType>(path?: T | Array<T>, options?: { ignoreAtomics?: boolean } | null): boolean;
    isModified(path?: string | Array<string>, options?: { ignoreAtomics?: boolean } | null): boolean;

    /** Boolean flag specifying if the document is new. */
    isNew: boolean;

    /** Checks if `path` was selected in the source query which initialized this document. */
    isSelected<T extends keyof DocType>(path: T): boolean;
    isSelected(path: string): boolean;

    /** Marks the path as having pending changes to write to the db. */
    markModified<T extends keyof DocType>(path: T, scope?: any): void;
    markModified(path: string, scope?: any): void;

    /** Returns the model with the given name on this document's associated connection. */
    model<ModelType = Model<unknown>>(name: string): ModelType;
    model<ModelType = Model<DocType>>(): ModelType;

    /** Returns the list of paths that have been modified. */
    modifiedPaths(options?: { includeChildren?: boolean }): Array<string>;

    /**
     * Overwrite all values in this document with the values of `obj`, except
     * for immutable properties. Behaves similarly to `set()`, except for it
     * unsets all properties that aren't in `obj`.
     */
    overwrite(obj: AnyObject): this;

    /**
     * If this document is a subdocument or populated document, returns the
     * document's parent. Returns undefined otherwise.
     */
    $parent(): Document | undefined;

    /** Populates document references. */
    populate<Paths = {}>(path: string | PopulateOptions | (string | PopulateOptions)[]): Promise<MergeType<this, Paths>>;
    populate<Paths = {}>(path: string, select?: string | AnyObject, model?: Model<any>, match?: AnyObject, options?: PopulateOptions): Promise<MergeType<this, Paths>>;

    /** Gets _id(s) used during population of the given `path`. If the path was not populated, returns `undefined`. */
    populated(path: string): any;

    /** Sends a replaceOne command with this document `_id` as the query selector. */
    replaceOne(replacement?: AnyObject, options?: QueryOptions | null): Query<any, this>;

    /** Saves this document by inserting a new document into the database if [document.isNew](/docs/api/document.html#document_Document-isNew) is `true`, or sends an [updateOne](/docs/api/document.html#document_Document-updateOne) operation with just the modified paths if `isNew` is `false`. */
    save(options?: SaveOptions): Promise<this>;

    /** The document's schema. */
    schema: Schema;

    /** Sets the value of a path, or many paths. */
    set<T extends keyof DocType>(path: T, val: DocType[T], type: any, options?: DocumentSetOptions): this;
    set(path: string | Record<string, any>, val: any, type: any, options?: DocumentSetOptions): this;
    set(path: string | Record<string, any>, val: any, options?: DocumentSetOptions): this;
    set(value: string | Record<string, any>): this;

    /** The return value of this method is used in calls to JSON.stringify(doc). */
    toJSON<T = Require_id<DocType>>(options?: ToObjectOptions & { flattenMaps?: true }): FlattenMaps<T>;
    toJSON<T = Require_id<DocType>>(options: ToObjectOptions & { flattenMaps: false }): T;

    /** Converts this document into a plain-old JavaScript object ([POJO](https://masteringjs.io/tutorials/fundamentals/pojo)). */
    toObject<T = Require_id<DocType>>(options?: ToObjectOptions): Require_id<T>;

    /** Clears the modified state on the specified path. */
    unmarkModified<T extends keyof DocType>(path: T): void;
    unmarkModified(path: string): void;

    /** Sends an updateOne command with this document `_id` as the query selector. */
    updateOne(update?: UpdateQuery<this> | UpdateWithAggregationPipeline, options?: QueryOptions | null): Query<any, this>;

    /** Executes registered validation rules for this document. */
    validate<T extends keyof DocType>(pathsToValidate?: T | T[], options?: AnyObject): Promise<void>;
    validate(pathsToValidate?: pathsToValidate, options?: AnyObject): Promise<void>;
    validate(options: { pathsToSkip?: pathsToSkip }): Promise<void>;

    /** Executes registered validation rules (skipping asynchronous validators) for this document. */
    validateSync(options: { pathsToSkip?: pathsToSkip, [k: string]: any }): Error.ValidationError | null;
    validateSync<T extends keyof DocType>(pathsToValidate?: T | T[], options?: AnyObject): Error.ValidationError | null;
    validateSync(pathsToValidate?: pathsToValidate, options?: AnyObject): Error.ValidationError | null;
  }
}
