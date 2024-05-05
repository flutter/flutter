declare module 'mongoose' {
  import mongodb = require('mongodb');

  /**
   * Makes the indexes in MongoDB match the indexes defined in every model's
   * schema. This function will drop any indexes that are not defined in
   * the model's schema except the `_id` index, and build any indexes that
   * are in your schema but not in MongoDB.
   */
  function syncIndexes(options?: SyncIndexesOptions): Promise<ConnectionSyncIndexesResult>;

  interface IndexManager {
    /**
     * Similar to `ensureIndexes()`, except for it uses the [`createIndex`](https://mongodb.github.io/node-mongodb-native/4.9/classes/Collection.html#createIndex)
     * function.
     */
    createIndexes(options?: mongodb.CreateIndexesOptions): Promise<void>;

    /**
     * Does a dry-run of Model.syncIndexes(), meaning that
     * the result of this function would be the result of
     * Model.syncIndexes().
     */
    diffIndexes(options?: Record<string, unknown>): Promise<IndexesDiff>

    /**
     * Sends `createIndex` commands to mongo for each index declared in the schema.
     * The `createIndex` commands are sent in series.
     */
    ensureIndexes(options?: mongodb.CreateIndexesOptions): Promise<void>;

    /**
     * Lists the indexes currently defined in MongoDB. This may or may not be
     * the same as the indexes defined in your schema depending on whether you
     * use the [`autoIndex` option](/docs/guide.html#autoIndex) and if you
     * build indexes manually.
     */
    listIndexes(): Promise<Array<any>>;

    /**
     * Makes the indexes in MongoDB match the indexes defined in this model's
     * schema. This function will drop any indexes that are not defined in
     * the model's schema except the `_id` index, and build any indexes that
     * are in your schema but not in MongoDB.
     */
    syncIndexes(options?: SyncIndexesOptions): Promise<Array<string>>;
  }

  interface IndexesDiff {
    /** Indexes that would be created in mongodb. */
    toCreate: Array<any>
    /** Indexes that would be dropped in mongodb. */
    toDrop: Array<any>
  }

  type IndexDirection = 1 | -1 | '2d' | '2dsphere' | 'geoHaystack' | 'hashed' | 'text' | 'ascending' | 'asc' | 'descending' | 'desc';
  type IndexDefinition = Record<string, IndexDirection>;

  interface SyncIndexesOptions extends mongodb.CreateIndexesOptions {
    continueOnError?: boolean
  }
  type ConnectionSyncIndexesResult = Record<string, OneCollectionSyncIndexesResult>;
  type OneCollectionSyncIndexesResult = Array<string> & mongodb.MongoServerError;

  interface IndexOptions extends mongodb.CreateIndexesOptions {
    /**
     * `expires` utilizes the `ms` module from [guille](https://github.com/guille/) allowing us to use a friendlier syntax:
     *
     * @example
     * ```js
     * const schema = new Schema({ prop1: Date });
     *
     * // expire in 24 hours
     * schema.index({ prop1: 1 }, { expires: 60*60*24 })
     *
     * // expire in 24 hours
     * schema.index({ prop1: 1 }, { expires: '24h' })
     *
     * // expire in 1.5 hours
     * schema.index({ prop1: 1 }, { expires: '1.5h' })
     *
     * // expire in 7 days
     * schema.index({ prop1: 1 }, { expires: '7d' })
     * ```
     */
    expires?: number | string;
    weights?: Record<string, number>;
  }

  type SearchIndexDescription = mongodb.SearchIndexDescription;
}
