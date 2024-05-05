"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Collection = void 0;
const bson_1 = require("./bson");
const ordered_1 = require("./bulk/ordered");
const unordered_1 = require("./bulk/unordered");
const change_stream_1 = require("./change_stream");
const aggregation_cursor_1 = require("./cursor/aggregation_cursor");
const find_cursor_1 = require("./cursor/find_cursor");
const list_indexes_cursor_1 = require("./cursor/list_indexes_cursor");
const list_search_indexes_cursor_1 = require("./cursor/list_search_indexes_cursor");
const error_1 = require("./error");
const bulk_write_1 = require("./operations/bulk_write");
const count_1 = require("./operations/count");
const count_documents_1 = require("./operations/count_documents");
const delete_1 = require("./operations/delete");
const distinct_1 = require("./operations/distinct");
const drop_1 = require("./operations/drop");
const estimated_document_count_1 = require("./operations/estimated_document_count");
const execute_operation_1 = require("./operations/execute_operation");
const find_and_modify_1 = require("./operations/find_and_modify");
const indexes_1 = require("./operations/indexes");
const insert_1 = require("./operations/insert");
const is_capped_1 = require("./operations/is_capped");
const options_operation_1 = require("./operations/options_operation");
const rename_1 = require("./operations/rename");
const create_1 = require("./operations/search_indexes/create");
const drop_2 = require("./operations/search_indexes/drop");
const update_1 = require("./operations/search_indexes/update");
const update_2 = require("./operations/update");
const read_concern_1 = require("./read_concern");
const read_preference_1 = require("./read_preference");
const utils_1 = require("./utils");
const write_concern_1 = require("./write_concern");
/**
 * The **Collection** class is an internal class that embodies a MongoDB collection
 * allowing for insert/find/update/delete and other command operation on that MongoDB collection.
 *
 * **COLLECTION Cannot directly be instantiated**
 * @public
 *
 * @example
 * ```ts
 * import { MongoClient } from 'mongodb';
 *
 * interface Pet {
 *   name: string;
 *   kind: 'dog' | 'cat' | 'fish';
 * }
 *
 * const client = new MongoClient('mongodb://localhost:27017');
 * const pets = client.db().collection<Pet>('pets');
 *
 * const petCursor = pets.find();
 *
 * for await (const pet of petCursor) {
 *   console.log(`${pet.name} is a ${pet.kind}!`);
 * }
 * ```
 */
class Collection {
    /**
     * Create a new Collection instance
     * @internal
     */
    constructor(db, name, options) {
        // Internal state
        this.s = {
            db,
            options,
            namespace: new utils_1.MongoDBCollectionNamespace(db.databaseName, name),
            pkFactory: db.options?.pkFactory ?? utils_1.DEFAULT_PK_FACTORY,
            readPreference: read_preference_1.ReadPreference.fromOptions(options),
            bsonOptions: (0, bson_1.resolveBSONOptions)(options, db),
            readConcern: read_concern_1.ReadConcern.fromOptions(options),
            writeConcern: write_concern_1.WriteConcern.fromOptions(options)
        };
        this.client = db.client;
    }
    /**
     * The name of the database this collection belongs to
     */
    get dbName() {
        return this.s.namespace.db;
    }
    /**
     * The name of this collection
     */
    get collectionName() {
        return this.s.namespace.collection;
    }
    /**
     * The namespace of this collection, in the format `${this.dbName}.${this.collectionName}`
     */
    get namespace() {
        return this.fullNamespace.toString();
    }
    /**
     *  @internal
     *
     * The `MongoDBNamespace` for the collection.
     */
    get fullNamespace() {
        return this.s.namespace;
    }
    /**
     * The current readConcern of the collection. If not explicitly defined for
     * this collection, will be inherited from the parent DB
     */
    get readConcern() {
        if (this.s.readConcern == null) {
            return this.s.db.readConcern;
        }
        return this.s.readConcern;
    }
    /**
     * The current readPreference of the collection. If not explicitly defined for
     * this collection, will be inherited from the parent DB
     */
    get readPreference() {
        if (this.s.readPreference == null) {
            return this.s.db.readPreference;
        }
        return this.s.readPreference;
    }
    get bsonOptions() {
        return this.s.bsonOptions;
    }
    /**
     * The current writeConcern of the collection. If not explicitly defined for
     * this collection, will be inherited from the parent DB
     */
    get writeConcern() {
        if (this.s.writeConcern == null) {
            return this.s.db.writeConcern;
        }
        return this.s.writeConcern;
    }
    /** The current index hint for the collection */
    get hint() {
        return this.s.collectionHint;
    }
    set hint(v) {
        this.s.collectionHint = (0, utils_1.normalizeHintField)(v);
    }
    /**
     * Inserts a single document into MongoDB. If documents passed in do not contain the **_id** field,
     * one will be added to each of the documents missing it by the driver, mutating the document. This behavior
     * can be overridden by setting the **forceServerObjectId** flag.
     *
     * @param doc - The document to insert
     * @param options - Optional settings for the command
     */
    async insertOne(doc, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new insert_1.InsertOneOperation(this, doc, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Inserts an array of documents into MongoDB. If documents passed in do not contain the **_id** field,
     * one will be added to each of the documents missing it by the driver, mutating the document. This behavior
     * can be overridden by setting the **forceServerObjectId** flag.
     *
     * @param docs - The documents to insert
     * @param options - Optional settings for the command
     */
    async insertMany(docs, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new insert_1.InsertManyOperation(this, docs, (0, utils_1.resolveOptions)(this, options ?? { ordered: true })));
    }
    /**
     * Perform a bulkWrite operation without a fluent API
     *
     * Legal operation types are
     * - `insertOne`
     * - `replaceOne`
     * - `updateOne`
     * - `updateMany`
     * - `deleteOne`
     * - `deleteMany`
     *
     * If documents passed in do not contain the **_id** field,
     * one will be added to each of the documents missing it by the driver, mutating the document. This behavior
     * can be overridden by setting the **forceServerObjectId** flag.
     *
     * @param operations - Bulk operations to perform
     * @param options - Optional settings for the command
     * @throws MongoDriverError if operations is not an array
     */
    async bulkWrite(operations, options) {
        if (!Array.isArray(operations)) {
            throw new error_1.MongoInvalidArgumentError('Argument "operations" must be an array of documents');
        }
        return (0, execute_operation_1.executeOperation)(this.client, new bulk_write_1.BulkWriteOperation(this, operations, (0, utils_1.resolveOptions)(this, options ?? { ordered: true })));
    }
    /**
     * Update a single document in a collection
     *
     * The value of `update` can be either:
     * - UpdateFilter<TSchema> - A document that contains update operator expressions,
     * - Document[] - an aggregation pipeline.
     *
     * @param filter - The filter used to select the document to update
     * @param update - The modifications to apply
     * @param options - Optional settings for the command
     */
    async updateOne(filter, update, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new update_2.UpdateOneOperation(this, filter, update, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Replace a document in a collection with another document
     *
     * @param filter - The filter used to select the document to replace
     * @param replacement - The Document that replaces the matching document
     * @param options - Optional settings for the command
     */
    async replaceOne(filter, replacement, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new update_2.ReplaceOneOperation(this, filter, replacement, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Update multiple documents in a collection
     *
     * The value of `update` can be either:
     * - UpdateFilter<TSchema> - A document that contains update operator expressions,
     * - Document[] - an aggregation pipeline.
     *
     * @param filter - The filter used to select the document to update
     * @param update - The modifications to apply
     * @param options - Optional settings for the command
     */
    async updateMany(filter, update, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new update_2.UpdateManyOperation(this, filter, update, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Delete a document from a collection
     *
     * @param filter - The filter used to select the document to remove
     * @param options - Optional settings for the command
     */
    async deleteOne(filter = {}, options = {}) {
        return (0, execute_operation_1.executeOperation)(this.client, new delete_1.DeleteOneOperation(this, filter, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Delete multiple documents from a collection
     *
     * @param filter - The filter used to select the documents to remove
     * @param options - Optional settings for the command
     */
    async deleteMany(filter = {}, options = {}) {
        return (0, execute_operation_1.executeOperation)(this.client, new delete_1.DeleteManyOperation(this, filter, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Rename the collection.
     *
     * @remarks
     * This operation does not inherit options from the Db or MongoClient.
     *
     * @param newName - New name of of the collection.
     * @param options - Optional settings for the command
     */
    async rename(newName, options) {
        // Intentionally, we do not inherit options from parent for this operation.
        return (0, execute_operation_1.executeOperation)(this.client, new rename_1.RenameOperation(this, newName, {
            ...options,
            readPreference: read_preference_1.ReadPreference.PRIMARY
        }));
    }
    /**
     * Drop the collection from the database, removing it permanently. New accesses will create a new collection.
     *
     * @param options - Optional settings for the command
     */
    async drop(options) {
        return (0, execute_operation_1.executeOperation)(this.client, new drop_1.DropCollectionOperation(this.s.db, this.collectionName, options));
    }
    async findOne(filter = {}, options = {}) {
        const cursor = this.find(filter, options).limit(-1).batchSize(1);
        const res = await cursor.next();
        await cursor.close();
        return res;
    }
    find(filter = {}, options = {}) {
        return new find_cursor_1.FindCursor(this.client, this.s.namespace, filter, (0, utils_1.resolveOptions)(this, options));
    }
    /**
     * Returns the options of the collection.
     *
     * @param options - Optional settings for the command
     */
    async options(options) {
        return (0, execute_operation_1.executeOperation)(this.client, new options_operation_1.OptionsOperation(this, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Returns if the collection is a capped collection
     *
     * @param options - Optional settings for the command
     */
    async isCapped(options) {
        return (0, execute_operation_1.executeOperation)(this.client, new is_capped_1.IsCappedOperation(this, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Creates an index on the db and collection collection.
     *
     * @param indexSpec - The field name or index specification to create an index for
     * @param options - Optional settings for the command
     *
     * @example
     * ```ts
     * const collection = client.db('foo').collection('bar');
     *
     * await collection.createIndex({ a: 1, b: -1 });
     *
     * // Alternate syntax for { c: 1, d: -1 } that ensures order of indexes
     * await collection.createIndex([ [c, 1], [d, -1] ]);
     *
     * // Equivalent to { e: 1 }
     * await collection.createIndex('e');
     *
     * // Equivalent to { f: 1, g: 1 }
     * await collection.createIndex(['f', 'g'])
     *
     * // Equivalent to { h: 1, i: -1 }
     * await collection.createIndex([ { h: 1 }, { i: -1 } ]);
     *
     * // Equivalent to { j: 1, k: -1, l: 2d }
     * await collection.createIndex(['j', ['k', -1], { l: '2d' }])
     * ```
     */
    async createIndex(indexSpec, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new indexes_1.CreateIndexOperation(this, this.collectionName, indexSpec, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Creates multiple indexes in the collection, this method is only supported for
     * MongoDB 2.6 or higher. Earlier version of MongoDB will throw a command not supported
     * error.
     *
     * **Note**: Unlike {@link Collection#createIndex| createIndex}, this function takes in raw index specifications.
     * Index specifications are defined {@link https://www.mongodb.com/docs/manual/reference/command/createIndexes/| here}.
     *
     * @param indexSpecs - An array of index specifications to be created
     * @param options - Optional settings for the command
     *
     * @example
     * ```ts
     * const collection = client.db('foo').collection('bar');
     * await collection.createIndexes([
     *   // Simple index on field fizz
     *   {
     *     key: { fizz: 1 },
     *   }
     *   // wildcard index
     *   {
     *     key: { '$**': 1 }
     *   },
     *   // named index on darmok and jalad
     *   {
     *     key: { darmok: 1, jalad: -1 }
     *     name: 'tanagra'
     *   }
     * ]);
     * ```
     */
    async createIndexes(indexSpecs, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new indexes_1.CreateIndexesOperation(this, this.collectionName, indexSpecs, (0, utils_1.resolveOptions)(this, { ...options, maxTimeMS: undefined })));
    }
    /**
     * Drops an index from this collection.
     *
     * @param indexName - Name of the index to drop.
     * @param options - Optional settings for the command
     */
    async dropIndex(indexName, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new indexes_1.DropIndexOperation(this, indexName, {
            ...(0, utils_1.resolveOptions)(this, options),
            readPreference: read_preference_1.ReadPreference.primary
        }));
    }
    /**
     * Drops all indexes from this collection.
     *
     * @param options - Optional settings for the command
     */
    async dropIndexes(options) {
        try {
            await (0, execute_operation_1.executeOperation)(this.client, new indexes_1.DropIndexOperation(this, '*', (0, utils_1.resolveOptions)(this, options)));
            return true;
        }
        catch {
            return false;
        }
    }
    /**
     * Get the list of all indexes information for the collection.
     *
     * @param options - Optional settings for the command
     */
    listIndexes(options) {
        return new list_indexes_cursor_1.ListIndexesCursor(this, (0, utils_1.resolveOptions)(this, options));
    }
    /**
     * Checks if one or more indexes exist on the collection, fails on first non-existing index
     *
     * @param indexes - One or more index names to check.
     * @param options - Optional settings for the command
     */
    async indexExists(indexes, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new indexes_1.IndexExistsOperation(this, indexes, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Retrieves this collections index info.
     *
     * @param options - Optional settings for the command
     */
    async indexInformation(options) {
        return (0, execute_operation_1.executeOperation)(this.client, new indexes_1.IndexInformationOperation(this.s.db, this.collectionName, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Gets an estimate of the count of documents in a collection using collection metadata.
     * This will always run a count command on all server versions.
     *
     * due to an oversight in versions 5.0.0-5.0.8 of MongoDB, the count command,
     * which estimatedDocumentCount uses in its implementation, was not included in v1 of
     * the Stable API, and so users of the Stable API with estimatedDocumentCount are
     * recommended to upgrade their server version to 5.0.9+ or set apiStrict: false to avoid
     * encountering errors.
     *
     * @see {@link https://www.mongodb.com/docs/manual/reference/command/count/#behavior|Count: Behavior}
     * @param options - Optional settings for the command
     */
    async estimatedDocumentCount(options) {
        return (0, execute_operation_1.executeOperation)(this.client, new estimated_document_count_1.EstimatedDocumentCountOperation(this, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Gets the number of documents matching the filter.
     * For a fast count of the total documents in a collection see {@link Collection#estimatedDocumentCount| estimatedDocumentCount}.
     * **Note**: When migrating from {@link Collection#count| count} to {@link Collection#countDocuments| countDocuments}
     * the following query operators must be replaced:
     *
     * | Operator | Replacement |
     * | -------- | ----------- |
     * | `$where`   | [`$expr`][1] |
     * | `$near`    | [`$geoWithin`][2] with [`$center`][3] |
     * | `$nearSphere` | [`$geoWithin`][2] with [`$centerSphere`][4] |
     *
     * [1]: https://www.mongodb.com/docs/manual/reference/operator/query/expr/
     * [2]: https://www.mongodb.com/docs/manual/reference/operator/query/geoWithin/
     * [3]: https://www.mongodb.com/docs/manual/reference/operator/query/center/#op._S_center
     * [4]: https://www.mongodb.com/docs/manual/reference/operator/query/centerSphere/#op._S_centerSphere
     *
     * @param filter - The filter for the count
     * @param options - Optional settings for the command
     *
     * @see https://www.mongodb.com/docs/manual/reference/operator/query/expr/
     * @see https://www.mongodb.com/docs/manual/reference/operator/query/geoWithin/
     * @see https://www.mongodb.com/docs/manual/reference/operator/query/center/#op._S_center
     * @see https://www.mongodb.com/docs/manual/reference/operator/query/centerSphere/#op._S_centerSphere
     */
    async countDocuments(filter = {}, options = {}) {
        return (0, execute_operation_1.executeOperation)(this.client, new count_documents_1.CountDocumentsOperation(this, filter, (0, utils_1.resolveOptions)(this, options)));
    }
    async distinct(key, filter = {}, options = {}) {
        return (0, execute_operation_1.executeOperation)(this.client, new distinct_1.DistinctOperation(this, key, filter, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Retrieve all the indexes on the collection.
     *
     * @param options - Optional settings for the command
     */
    async indexes(options) {
        return (0, execute_operation_1.executeOperation)(this.client, new indexes_1.IndexesOperation(this, (0, utils_1.resolveOptions)(this, options)));
    }
    async findOneAndDelete(filter, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new find_and_modify_1.FindOneAndDeleteOperation(this, filter, (0, utils_1.resolveOptions)(this, options)));
    }
    async findOneAndReplace(filter, replacement, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new find_and_modify_1.FindOneAndReplaceOperation(this, filter, replacement, (0, utils_1.resolveOptions)(this, options)));
    }
    async findOneAndUpdate(filter, update, options) {
        return (0, execute_operation_1.executeOperation)(this.client, new find_and_modify_1.FindOneAndUpdateOperation(this, filter, update, (0, utils_1.resolveOptions)(this, options)));
    }
    /**
     * Execute an aggregation framework pipeline against the collection, needs MongoDB \>= 2.2
     *
     * @param pipeline - An array of aggregation pipelines to execute
     * @param options - Optional settings for the command
     */
    aggregate(pipeline = [], options) {
        if (!Array.isArray(pipeline)) {
            throw new error_1.MongoInvalidArgumentError('Argument "pipeline" must be an array of aggregation stages');
        }
        return new aggregation_cursor_1.AggregationCursor(this.client, this.s.namespace, pipeline, (0, utils_1.resolveOptions)(this, options));
    }
    /**
     * Create a new Change Stream, watching for new changes (insertions, updates, replacements, deletions, and invalidations) in this collection.
     *
     * @remarks
     * watch() accepts two generic arguments for distinct use cases:
     * - The first is to override the schema that may be defined for this specific collection
     * - The second is to override the shape of the change stream document entirely, if it is not provided the type will default to ChangeStreamDocument of the first argument
     * @example
     * By just providing the first argument I can type the change to be `ChangeStreamDocument<{ _id: number }>`
     * ```ts
     * collection.watch<{ _id: number }>()
     *   .on('change', change => console.log(change._id.toFixed(4)));
     * ```
     *
     * @example
     * Passing a second argument provides a way to reflect the type changes caused by an advanced pipeline.
     * Here, we are using a pipeline to have MongoDB filter for insert changes only and add a comment.
     * No need start from scratch on the ChangeStreamInsertDocument type!
     * By using an intersection we can save time and ensure defaults remain the same type!
     * ```ts
     * collection
     *   .watch<Schema, ChangeStreamInsertDocument<Schema> & { comment: string }>([
     *     { $addFields: { comment: 'big changes' } },
     *     { $match: { operationType: 'insert' } }
     *   ])
     *   .on('change', change => {
     *     change.comment.startsWith('big');
     *     change.operationType === 'insert';
     *     // No need to narrow in code because the generics did that for us!
     *     expectType<Schema>(change.fullDocument);
     *   });
     * ```
     *
     * @param pipeline - An array of {@link https://www.mongodb.com/docs/manual/reference/operator/aggregation-pipeline/|aggregation pipeline stages} through which to pass change stream documents. This allows for filtering (using $match) and manipulating the change stream documents.
     * @param options - Optional settings for the command
     * @typeParam TLocal - Type of the data being detected by the change stream
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
    /**
     * Initiate an Out of order batch write operation. All operations will be buffered into insert/update/remove commands executed out of order.
     *
     * @throws MongoNotConnectedError
     * @remarks
     * **NOTE:** MongoClient must be connected prior to calling this method due to a known limitation in this legacy implementation.
     * However, `collection.bulkWrite()` provides an equivalent API that does not require prior connecting.
     */
    initializeUnorderedBulkOp(options) {
        return new unordered_1.UnorderedBulkOperation(this, (0, utils_1.resolveOptions)(this, options));
    }
    /**
     * Initiate an In order bulk write operation. Operations will be serially executed in the order they are added, creating a new operation for each switch in types.
     *
     * @throws MongoNotConnectedError
     * @remarks
     * **NOTE:** MongoClient must be connected prior to calling this method due to a known limitation in this legacy implementation.
     * However, `collection.bulkWrite()` provides an equivalent API that does not require prior connecting.
     */
    initializeOrderedBulkOp(options) {
        return new ordered_1.OrderedBulkOperation(this, (0, utils_1.resolveOptions)(this, options));
    }
    /**
     * An estimated count of matching documents in the db to a filter.
     *
     * **NOTE:** This method has been deprecated, since it does not provide an accurate count of the documents
     * in a collection. To obtain an accurate count of documents in the collection, use {@link Collection#countDocuments| countDocuments}.
     * To obtain an estimated count of all documents in the collection, use {@link Collection#estimatedDocumentCount| estimatedDocumentCount}.
     *
     * @deprecated use {@link Collection#countDocuments| countDocuments} or {@link Collection#estimatedDocumentCount| estimatedDocumentCount} instead
     *
     * @param filter - The filter for the count.
     * @param options - Optional settings for the command
     */
    async count(filter = {}, options = {}) {
        return (0, execute_operation_1.executeOperation)(this.client, new count_1.CountOperation(this.fullNamespace, filter, (0, utils_1.resolveOptions)(this, options)));
    }
    listSearchIndexes(indexNameOrOptions, options) {
        options =
            typeof indexNameOrOptions === 'object' ? indexNameOrOptions : options == null ? {} : options;
        const indexName = indexNameOrOptions == null
            ? null
            : typeof indexNameOrOptions === 'object'
                ? null
                : indexNameOrOptions;
        return new list_search_indexes_cursor_1.ListSearchIndexesCursor(this, indexName, options);
    }
    /**
     * Creates a single search index for the collection.
     *
     * @param description - The index description for the new search index.
     * @returns A promise that resolves to the name of the new search index.
     *
     * @remarks Only available when used against a 7.0+ Atlas cluster.
     */
    async createSearchIndex(description) {
        const [index] = await this.createSearchIndexes([description]);
        return index;
    }
    /**
     * Creates multiple search indexes for the current collection.
     *
     * @param descriptions - An array of `SearchIndexDescription`s for the new search indexes.
     * @returns A promise that resolves to an array of the newly created search index names.
     *
     * @remarks Only available when used against a 7.0+ Atlas cluster.
     * @returns
     */
    async createSearchIndexes(descriptions) {
        return (0, execute_operation_1.executeOperation)(this.client, new create_1.CreateSearchIndexesOperation(this, descriptions));
    }
    /**
     * Deletes a search index by index name.
     *
     * @param name - The name of the search index to be deleted.
     *
     * @remarks Only available when used against a 7.0+ Atlas cluster.
     */
    async dropSearchIndex(name) {
        return (0, execute_operation_1.executeOperation)(this.client, new drop_2.DropSearchIndexOperation(this, name));
    }
    /**
     * Updates a search index by replacing the existing index definition with the provided definition.
     *
     * @param name - The name of the search index to update.
     * @param definition - The new search index definition.
     *
     * @remarks Only available when used against a 7.0+ Atlas cluster.
     */
    async updateSearchIndex(name, definition) {
        return (0, execute_operation_1.executeOperation)(this.client, new update_1.UpdateSearchIndexOperation(this, name, definition));
    }
}
exports.Collection = Collection;
//# sourceMappingURL=collection.js.map