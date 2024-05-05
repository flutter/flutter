"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FindCursor = exports.FLAGS = void 0;
const bson_1 = require("../bson");
const error_1 = require("../error");
const count_1 = require("../operations/count");
const execute_operation_1 = require("../operations/execute_operation");
const find_1 = require("../operations/find");
const sort_1 = require("../sort");
const utils_1 = require("../utils");
const abstract_cursor_1 = require("./abstract_cursor");
/** @internal */
const kFilter = Symbol('filter');
/** @internal */
const kNumReturned = Symbol('numReturned');
/** @internal */
const kBuiltOptions = Symbol('builtOptions');
/** @public Flags allowed for cursor */
exports.FLAGS = [
    'tailable',
    'oplogReplay',
    'noCursorTimeout',
    'awaitData',
    'exhaust',
    'partial'
];
/** @public */
class FindCursor extends abstract_cursor_1.AbstractCursor {
    /** @internal */
    constructor(client, namespace, filter = {}, options = {}) {
        super(client, namespace, options);
        this[kFilter] = filter;
        this[kBuiltOptions] = options;
        if (options.sort != null) {
            this[kBuiltOptions].sort = (0, sort_1.formatSort)(options.sort);
        }
    }
    clone() {
        const clonedOptions = (0, utils_1.mergeOptions)({}, this[kBuiltOptions]);
        delete clonedOptions.session;
        return new FindCursor(this.client, this.namespace, this[kFilter], {
            ...clonedOptions
        });
    }
    map(transform) {
        return super.map(transform);
    }
    /** @internal */
    async _initialize(session) {
        const findOperation = new find_1.FindOperation(undefined, this.namespace, this[kFilter], {
            ...this[kBuiltOptions],
            ...this.cursorOptions,
            session
        });
        const response = await (0, execute_operation_1.executeOperation)(this.client, findOperation);
        // the response is not a cursor when `explain` is enabled
        this[kNumReturned] = response.cursor?.firstBatch?.length;
        // TODO: NODE-2882
        return { server: findOperation.server, session, response };
    }
    /** @internal */
    async getMore(batchSize) {
        const numReturned = this[kNumReturned];
        if (numReturned) {
            // TODO(DRIVERS-1448): Remove logic to enforce `limit` in the driver
            const limit = this[kBuiltOptions].limit;
            batchSize =
                limit && limit > 0 && numReturned + batchSize > limit ? limit - numReturned : batchSize;
            if (batchSize <= 0) {
                // this is an optimization for the special case of a limit for a find command to avoid an
                // extra getMore when the limit has been reached and the limit is a multiple of the batchSize.
                // This is a consequence of the new query engine in 5.0 having no knowledge of the limit as it
                // produces results for the find command.  Once a batch is filled up, it is returned and only
                // on the subsequent getMore will the query framework consider the limit, determine the cursor
                // is exhausted and return a cursorId of zero.
                // instead, if we determine there are no more documents to request from the server, we preemptively
                // close the cursor
                await this.close().catch(() => null);
                return { cursor: { id: bson_1.Long.ZERO, nextBatch: [] } };
            }
        }
        const response = await super.getMore(batchSize);
        // TODO: wrap this in some logic to prevent it from happening if we don't need this support
        if (response) {
            this[kNumReturned] = this[kNumReturned] + response.cursor.nextBatch.length;
        }
        return response;
    }
    /**
     * Get the count of documents for this cursor
     * @deprecated Use `collection.estimatedDocumentCount` or `collection.countDocuments` instead
     */
    async count(options) {
        (0, utils_1.emitWarningOnce)('cursor.count is deprecated and will be removed in the next major version, please use `collection.estimatedDocumentCount` or `collection.countDocuments` instead ');
        if (typeof options === 'boolean') {
            throw new error_1.MongoInvalidArgumentError('Invalid first parameter to count');
        }
        return (0, execute_operation_1.executeOperation)(this.client, new count_1.CountOperation(this.namespace, this[kFilter], {
            ...this[kBuiltOptions],
            ...this.cursorOptions,
            ...options
        }));
    }
    /** Execute the explain for the cursor */
    async explain(verbosity) {
        return (0, execute_operation_1.executeOperation)(this.client, new find_1.FindOperation(undefined, this.namespace, this[kFilter], {
            ...this[kBuiltOptions],
            ...this.cursorOptions,
            explain: verbosity ?? true
        }));
    }
    /** Set the cursor query */
    filter(filter) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kFilter] = filter;
        return this;
    }
    /**
     * Set the cursor hint
     *
     * @param hint - If specified, then the query system will only consider plans using the hinted index.
     */
    hint(hint) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].hint = hint;
        return this;
    }
    /**
     * Set the cursor min
     *
     * @param min - Specify a $min value to specify the inclusive lower bound for a specific index in order to constrain the results of find(). The $min specifies the lower bound for all keys of a specific index in order.
     */
    min(min) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].min = min;
        return this;
    }
    /**
     * Set the cursor max
     *
     * @param max - Specify a $max value to specify the exclusive upper bound for a specific index in order to constrain the results of find(). The $max specifies the upper bound for all keys of a specific index in order.
     */
    max(max) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].max = max;
        return this;
    }
    /**
     * Set the cursor returnKey.
     * If set to true, modifies the cursor to only return the index field or fields for the results of the query, rather than documents.
     * If set to true and the query does not use an index to perform the read operation, the returned documents will not contain any fields.
     *
     * @param value - the returnKey value.
     */
    returnKey(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].returnKey = value;
        return this;
    }
    /**
     * Modifies the output of a query by adding a field $recordId to matching documents. $recordId is the internal key which uniquely identifies a document in a collection.
     *
     * @param value - The $showDiskLoc option has now been deprecated and replaced with the showRecordId field. $showDiskLoc will still be accepted for OP_QUERY stye find.
     */
    showRecordId(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].showRecordId = value;
        return this;
    }
    /**
     * Add a query modifier to the cursor query
     *
     * @param name - The query modifier (must start with $, such as $orderby etc)
     * @param value - The modifier value.
     */
    addQueryModifier(name, value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        if (name[0] !== '$') {
            throw new error_1.MongoInvalidArgumentError(`${name} is not a valid query modifier`);
        }
        // Strip of the $
        const field = name.substr(1);
        // NOTE: consider some TS magic for this
        switch (field) {
            case 'comment':
                this[kBuiltOptions].comment = value;
                break;
            case 'explain':
                this[kBuiltOptions].explain = value;
                break;
            case 'hint':
                this[kBuiltOptions].hint = value;
                break;
            case 'max':
                this[kBuiltOptions].max = value;
                break;
            case 'maxTimeMS':
                this[kBuiltOptions].maxTimeMS = value;
                break;
            case 'min':
                this[kBuiltOptions].min = value;
                break;
            case 'orderby':
                this[kBuiltOptions].sort = (0, sort_1.formatSort)(value);
                break;
            case 'query':
                this[kFilter] = value;
                break;
            case 'returnKey':
                this[kBuiltOptions].returnKey = value;
                break;
            case 'showDiskLoc':
                this[kBuiltOptions].showRecordId = value;
                break;
            default:
                throw new error_1.MongoInvalidArgumentError(`Invalid query modifier: ${name}`);
        }
        return this;
    }
    /**
     * Add a comment to the cursor query allowing for tracking the comment in the log.
     *
     * @param value - The comment attached to this query.
     */
    comment(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].comment = value;
        return this;
    }
    /**
     * Set a maxAwaitTimeMS on a tailing cursor query to allow to customize the timeout value for the option awaitData (Only supported on MongoDB 3.2 or higher, ignored otherwise)
     *
     * @param value - Number of milliseconds to wait before aborting the tailed query.
     */
    maxAwaitTimeMS(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        if (typeof value !== 'number') {
            throw new error_1.MongoInvalidArgumentError('Argument for maxAwaitTimeMS must be a number');
        }
        this[kBuiltOptions].maxAwaitTimeMS = value;
        return this;
    }
    /**
     * Set a maxTimeMS on the cursor query, allowing for hard timeout limits on queries (Only supported on MongoDB 2.6 or higher)
     *
     * @param value - Number of milliseconds to wait before aborting the query.
     */
    maxTimeMS(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        if (typeof value !== 'number') {
            throw new error_1.MongoInvalidArgumentError('Argument for maxTimeMS must be a number');
        }
        this[kBuiltOptions].maxTimeMS = value;
        return this;
    }
    /**
     * Add a project stage to the aggregation pipeline
     *
     * @remarks
     * In order to strictly type this function you must provide an interface
     * that represents the effect of your projection on the result documents.
     *
     * By default chaining a projection to your cursor changes the returned type to the generic
     * {@link Document} type.
     * You should specify a parameterized type to have assertions on your final results.
     *
     * @example
     * ```typescript
     * // Best way
     * const docs: FindCursor<{ a: number }> = cursor.project<{ a: number }>({ _id: 0, a: true });
     * // Flexible way
     * const docs: FindCursor<Document> = cursor.project({ _id: 0, a: true });
     * ```
     *
     * @remarks
     *
     * **Note for Typescript Users:** adding a transform changes the return type of the iteration of this cursor,
     * it **does not** return a new instance of a cursor. This means when calling project,
     * you should always assign the result to a new variable in order to get a correctly typed cursor variable.
     * Take note of the following example:
     *
     * @example
     * ```typescript
     * const cursor: FindCursor<{ a: number; b: string }> = coll.find();
     * const projectCursor = cursor.project<{ a: number }>({ _id: 0, a: true });
     * const aPropOnlyArray: {a: number}[] = await projectCursor.toArray();
     *
     * // or always use chaining and save the final cursor
     *
     * const cursor = coll.find().project<{ a: string }>({
     *   _id: 0,
     *   a: { $convert: { input: '$a', to: 'string' }
     * }});
     * ```
     */
    project(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].projection = value;
        return this;
    }
    /**
     * Sets the sort order of the cursor query.
     *
     * @param sort - The key or keys set for the sort.
     * @param direction - The direction of the sorting (1 or -1).
     */
    sort(sort, direction) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        if (this[kBuiltOptions].tailable) {
            throw new error_1.MongoTailableCursorError('Tailable cursor does not support sorting');
        }
        this[kBuiltOptions].sort = (0, sort_1.formatSort)(sort, direction);
        return this;
    }
    /**
     * Allows disk use for blocking sort operations exceeding 100MB memory. (MongoDB 3.2 or higher)
     *
     * @remarks
     * {@link https://www.mongodb.com/docs/manual/reference/command/find/#find-cmd-allowdiskuse | find command allowDiskUse documentation}
     */
    allowDiskUse(allow = true) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        if (!this[kBuiltOptions].sort) {
            throw new error_1.MongoInvalidArgumentError('Option "allowDiskUse" requires a sort specification');
        }
        // As of 6.0 the default is true. This allows users to get back to the old behavior.
        if (!allow) {
            this[kBuiltOptions].allowDiskUse = false;
            return this;
        }
        this[kBuiltOptions].allowDiskUse = true;
        return this;
    }
    /**
     * Set the collation options for the cursor.
     *
     * @param value - The cursor collation options (MongoDB 3.4 or higher) settings for update operation (see 3.4 documentation for available fields).
     */
    collation(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kBuiltOptions].collation = value;
        return this;
    }
    /**
     * Set the limit for the cursor.
     *
     * @param value - The limit for the cursor query.
     */
    limit(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        if (this[kBuiltOptions].tailable) {
            throw new error_1.MongoTailableCursorError('Tailable cursor does not support limit');
        }
        if (typeof value !== 'number') {
            throw new error_1.MongoInvalidArgumentError('Operation "limit" requires an integer');
        }
        this[kBuiltOptions].limit = value;
        return this;
    }
    /**
     * Set the skip for the cursor.
     *
     * @param value - The skip for the cursor query.
     */
    skip(value) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        if (this[kBuiltOptions].tailable) {
            throw new error_1.MongoTailableCursorError('Tailable cursor does not support skip');
        }
        if (typeof value !== 'number') {
            throw new error_1.MongoInvalidArgumentError('Operation "skip" requires an integer');
        }
        this[kBuiltOptions].skip = value;
        return this;
    }
}
exports.FindCursor = FindCursor;
//# sourceMappingURL=find_cursor.js.map