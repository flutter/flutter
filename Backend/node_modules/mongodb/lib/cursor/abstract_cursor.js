"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.assertUninitialized = exports.AbstractCursor = exports.CURSOR_FLAGS = void 0;
const stream_1 = require("stream");
const bson_1 = require("../bson");
const error_1 = require("../error");
const mongo_types_1 = require("../mongo_types");
const execute_operation_1 = require("../operations/execute_operation");
const get_more_1 = require("../operations/get_more");
const kill_cursors_1 = require("../operations/kill_cursors");
const read_concern_1 = require("../read_concern");
const read_preference_1 = require("../read_preference");
const sessions_1 = require("../sessions");
const utils_1 = require("../utils");
/** @internal */
const kId = Symbol('id');
/** @internal */
const kDocuments = Symbol('documents');
/** @internal */
const kServer = Symbol('server');
/** @internal */
const kNamespace = Symbol('namespace');
/** @internal */
const kClient = Symbol('client');
/** @internal */
const kSession = Symbol('session');
/** @internal */
const kOptions = Symbol('options');
/** @internal */
const kTransform = Symbol('transform');
/** @internal */
const kInitialized = Symbol('initialized');
/** @internal */
const kClosed = Symbol('closed');
/** @internal */
const kKilled = Symbol('killed');
/** @internal */
const kInit = Symbol('kInit');
/** @public */
exports.CURSOR_FLAGS = [
    'tailable',
    'oplogReplay',
    'noCursorTimeout',
    'awaitData',
    'exhaust',
    'partial'
];
/** @public */
class AbstractCursor extends mongo_types_1.TypedEventEmitter {
    /** @internal */
    constructor(client, namespace, options = {}) {
        super();
        if (!client.s.isMongoClient) {
            throw new error_1.MongoRuntimeError('Cursor must be constructed with MongoClient');
        }
        this[kClient] = client;
        this[kNamespace] = namespace;
        this[kId] = null;
        this[kDocuments] = new utils_1.List();
        this[kInitialized] = false;
        this[kClosed] = false;
        this[kKilled] = false;
        this[kOptions] = {
            readPreference: options.readPreference && options.readPreference instanceof read_preference_1.ReadPreference
                ? options.readPreference
                : read_preference_1.ReadPreference.primary,
            ...(0, bson_1.pluckBSONSerializeOptions)(options)
        };
        const readConcern = read_concern_1.ReadConcern.fromOptions(options);
        if (readConcern) {
            this[kOptions].readConcern = readConcern;
        }
        if (typeof options.batchSize === 'number') {
            this[kOptions].batchSize = options.batchSize;
        }
        // we check for undefined specifically here to allow falsy values
        // eslint-disable-next-line no-restricted-syntax
        if (options.comment !== undefined) {
            this[kOptions].comment = options.comment;
        }
        if (typeof options.maxTimeMS === 'number') {
            this[kOptions].maxTimeMS = options.maxTimeMS;
        }
        if (typeof options.maxAwaitTimeMS === 'number') {
            this[kOptions].maxAwaitTimeMS = options.maxAwaitTimeMS;
        }
        if (options.session instanceof sessions_1.ClientSession) {
            this[kSession] = options.session;
        }
        else {
            this[kSession] = this[kClient].startSession({ owner: this, explicit: false });
        }
    }
    get id() {
        return this[kId] ?? undefined;
    }
    /** @internal */
    get isDead() {
        return (this[kId]?.isZero() ?? false) || this[kClosed] || this[kKilled];
    }
    /** @internal */
    get client() {
        return this[kClient];
    }
    /** @internal */
    get server() {
        return this[kServer];
    }
    get namespace() {
        return this[kNamespace];
    }
    get readPreference() {
        return this[kOptions].readPreference;
    }
    get readConcern() {
        return this[kOptions].readConcern;
    }
    /** @internal */
    get session() {
        return this[kSession];
    }
    set session(clientSession) {
        this[kSession] = clientSession;
    }
    /** @internal */
    get cursorOptions() {
        return this[kOptions];
    }
    get closed() {
        return this[kClosed];
    }
    get killed() {
        return this[kKilled];
    }
    get loadBalanced() {
        return !!this[kClient].topology?.loadBalanced;
    }
    /** Returns current buffered documents length */
    bufferedCount() {
        return this[kDocuments].length;
    }
    /** Returns current buffered documents */
    readBufferedDocuments(number) {
        const bufferedDocs = [];
        const documentsToRead = Math.min(number ?? this[kDocuments].length, this[kDocuments].length);
        for (let count = 0; count < documentsToRead; count++) {
            const document = this[kDocuments].shift();
            if (document != null) {
                bufferedDocs.push(document);
            }
        }
        return bufferedDocs;
    }
    async *[Symbol.asyncIterator]() {
        if (this.closed) {
            return;
        }
        try {
            while (true) {
                const document = await this.next();
                // Intentional strict null check, because users can map cursors to falsey values.
                // We allow mapping to all values except for null.
                // eslint-disable-next-line no-restricted-syntax
                if (document === null) {
                    if (!this.closed) {
                        const message = 'Cursor returned a `null` document, but the cursor is not exhausted.  Mapping documents to `null` is not supported in the cursor transform.';
                        await cleanupCursor(this, { needsToEmitClosed: true }).catch(() => null);
                        throw new error_1.MongoAPIError(message);
                    }
                    break;
                }
                yield document;
                if (this[kId] === bson_1.Long.ZERO) {
                    // Cursor exhausted
                    break;
                }
            }
        }
        finally {
            // Only close the cursor if it has not already been closed. This finally clause handles
            // the case when a user would break out of a for await of loop early.
            if (!this.closed) {
                await this.close().catch(() => null);
            }
        }
    }
    stream(options) {
        if (options?.transform) {
            const transform = options.transform;
            const readable = new ReadableCursorStream(this);
            const transformedStream = readable.pipe(new stream_1.Transform({
                objectMode: true,
                highWaterMark: 1,
                transform(chunk, _, callback) {
                    try {
                        const transformed = transform(chunk);
                        callback(undefined, transformed);
                    }
                    catch (err) {
                        callback(err);
                    }
                }
            }));
            // Bubble errors to transformed stream, because otherwise no way
            // to handle this error.
            readable.on('error', err => transformedStream.emit('error', err));
            return transformedStream;
        }
        return new ReadableCursorStream(this);
    }
    async hasNext() {
        if (this[kId] === bson_1.Long.ZERO) {
            return false;
        }
        if (this[kDocuments].length !== 0) {
            return true;
        }
        const doc = await next(this, { blocking: true, transform: false });
        if (doc) {
            this[kDocuments].unshift(doc);
            return true;
        }
        return false;
    }
    /** Get the next available document from the cursor, returns null if no more documents are available. */
    async next() {
        if (this[kId] === bson_1.Long.ZERO) {
            throw new error_1.MongoCursorExhaustedError();
        }
        return next(this, { blocking: true, transform: true });
    }
    /**
     * Try to get the next available document from the cursor or `null` if an empty batch is returned
     */
    async tryNext() {
        if (this[kId] === bson_1.Long.ZERO) {
            throw new error_1.MongoCursorExhaustedError();
        }
        return next(this, { blocking: false, transform: true });
    }
    /**
     * Iterates over all the documents for this cursor using the iterator, callback pattern.
     *
     * If the iterator returns `false`, iteration will stop.
     *
     * @param iterator - The iteration callback.
     * @deprecated - Will be removed in a future release. Use for await...of instead.
     */
    async forEach(iterator) {
        if (typeof iterator !== 'function') {
            throw new error_1.MongoInvalidArgumentError('Argument "iterator" must be a function');
        }
        for await (const document of this) {
            const result = iterator(document);
            if (result === false) {
                break;
            }
        }
    }
    async close() {
        const needsToEmitClosed = !this[kClosed];
        this[kClosed] = true;
        await cleanupCursor(this, { needsToEmitClosed });
    }
    /**
     * Returns an array of documents. The caller is responsible for making sure that there
     * is enough memory to store the results. Note that the array only contains partial
     * results when this cursor had been previously accessed. In that case,
     * cursor.rewind() can be used to reset the cursor.
     */
    async toArray() {
        const array = [];
        for await (const document of this) {
            array.push(document);
        }
        return array;
    }
    /**
     * Add a cursor flag to the cursor
     *
     * @param flag - The flag to set, must be one of following ['tailable', 'oplogReplay', 'noCursorTimeout', 'awaitData', 'partial' -.
     * @param value - The flag boolean value.
     */
    addCursorFlag(flag, value) {
        assertUninitialized(this);
        if (!exports.CURSOR_FLAGS.includes(flag)) {
            throw new error_1.MongoInvalidArgumentError(`Flag ${flag} is not one of ${exports.CURSOR_FLAGS}`);
        }
        if (typeof value !== 'boolean') {
            throw new error_1.MongoInvalidArgumentError(`Flag ${flag} must be a boolean value`);
        }
        this[kOptions][flag] = value;
        return this;
    }
    /**
     * Map all documents using the provided function
     * If there is a transform set on the cursor, that will be called first and the result passed to
     * this function's transform.
     *
     * @remarks
     *
     * **Note** Cursors use `null` internally to indicate that there are no more documents in the cursor. Providing a mapping
     * function that maps values to `null` will result in the cursor closing itself before it has finished iterating
     * all documents.  This will **not** result in a memory leak, just surprising behavior.  For example:
     *
     * ```typescript
     * const cursor = collection.find({});
     * cursor.map(() => null);
     *
     * const documents = await cursor.toArray();
     * // documents is always [], regardless of how many documents are in the collection.
     * ```
     *
     * Other falsey values are allowed:
     *
     * ```typescript
     * const cursor = collection.find({});
     * cursor.map(() => '');
     *
     * const documents = await cursor.toArray();
     * // documents is now an array of empty strings
     * ```
     *
     * **Note for Typescript Users:** adding a transform changes the return type of the iteration of this cursor,
     * it **does not** return a new instance of a cursor. This means when calling map,
     * you should always assign the result to a new variable in order to get a correctly typed cursor variable.
     * Take note of the following example:
     *
     * @example
     * ```typescript
     * const cursor: FindCursor<Document> = coll.find();
     * const mappedCursor: FindCursor<number> = cursor.map(doc => Object.keys(doc).length);
     * const keyCounts: number[] = await mappedCursor.toArray(); // cursor.toArray() still returns Document[]
     * ```
     * @param transform - The mapping transformation method.
     */
    map(transform) {
        assertUninitialized(this);
        const oldTransform = this[kTransform]; // TODO(NODE-3283): Improve transform typing
        if (oldTransform) {
            this[kTransform] = doc => {
                return transform(oldTransform(doc));
            };
        }
        else {
            this[kTransform] = transform;
        }
        return this;
    }
    /**
     * Set the ReadPreference for the cursor.
     *
     * @param readPreference - The new read preference for the cursor.
     */
    withReadPreference(readPreference) {
        assertUninitialized(this);
        if (readPreference instanceof read_preference_1.ReadPreference) {
            this[kOptions].readPreference = readPreference;
        }
        else if (typeof readPreference === 'string') {
            this[kOptions].readPreference = read_preference_1.ReadPreference.fromString(readPreference);
        }
        else {
            throw new error_1.MongoInvalidArgumentError(`Invalid read preference: ${readPreference}`);
        }
        return this;
    }
    /**
     * Set the ReadPreference for the cursor.
     *
     * @param readPreference - The new read preference for the cursor.
     */
    withReadConcern(readConcern) {
        assertUninitialized(this);
        const resolvedReadConcern = read_concern_1.ReadConcern.fromOptions({ readConcern });
        if (resolvedReadConcern) {
            this[kOptions].readConcern = resolvedReadConcern;
        }
        return this;
    }
    /**
     * Set a maxTimeMS on the cursor query, allowing for hard timeout limits on queries (Only supported on MongoDB 2.6 or higher)
     *
     * @param value - Number of milliseconds to wait before aborting the query.
     */
    maxTimeMS(value) {
        assertUninitialized(this);
        if (typeof value !== 'number') {
            throw new error_1.MongoInvalidArgumentError('Argument for maxTimeMS must be a number');
        }
        this[kOptions].maxTimeMS = value;
        return this;
    }
    /**
     * Set the batch size for the cursor.
     *
     * @param value - The number of documents to return per batch. See {@link https://www.mongodb.com/docs/manual/reference/command/find/|find command documentation}.
     */
    batchSize(value) {
        assertUninitialized(this);
        if (this[kOptions].tailable) {
            throw new error_1.MongoTailableCursorError('Tailable cursor does not support batchSize');
        }
        if (typeof value !== 'number') {
            throw new error_1.MongoInvalidArgumentError('Operation "batchSize" requires an integer');
        }
        this[kOptions].batchSize = value;
        return this;
    }
    /**
     * Rewind this cursor to its uninitialized state. Any options that are present on the cursor will
     * remain in effect. Iterating this cursor will cause new queries to be sent to the server, even
     * if the resultant data has already been retrieved by this cursor.
     */
    rewind() {
        if (!this[kInitialized]) {
            return;
        }
        this[kId] = null;
        this[kDocuments].clear();
        this[kClosed] = false;
        this[kKilled] = false;
        this[kInitialized] = false;
        const session = this[kSession];
        if (session) {
            // We only want to end this session if we created it, and it hasn't ended yet
            if (session.explicit === false) {
                if (!session.hasEnded) {
                    session.endSession().catch(() => null);
                }
                this[kSession] = this.client.startSession({ owner: this, explicit: false });
            }
        }
    }
    /** @internal */
    async getMore(batchSize) {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        const getMoreOperation = new get_more_1.GetMoreOperation(this[kNamespace], this[kId], this[kServer], {
            ...this[kOptions],
            session: this[kSession],
            batchSize
        });
        return (0, execute_operation_1.executeOperation)(this[kClient], getMoreOperation);
    }
    /**
     * @internal
     *
     * This function is exposed for the unified test runner's createChangeStream
     * operation.  We cannot refactor to use the abstract _initialize method without
     * a significant refactor.
     */
    async [kInit]() {
        try {
            const state = await this._initialize(this[kSession]);
            const response = state.response;
            this[kServer] = state.server;
            if (response.cursor) {
                // TODO(NODE-2674): Preserve int64 sent from MongoDB
                this[kId] =
                    typeof response.cursor.id === 'number'
                        ? bson_1.Long.fromNumber(response.cursor.id)
                        : typeof response.cursor.id === 'bigint'
                            ? bson_1.Long.fromBigInt(response.cursor.id)
                            : response.cursor.id;
                if (response.cursor.ns) {
                    this[kNamespace] = (0, utils_1.ns)(response.cursor.ns);
                }
                this[kDocuments].pushMany(response.cursor.firstBatch);
            }
            // When server responses return without a cursor document, we close this cursor
            // and return the raw server response. This is often the case for explain commands
            // for example
            if (this[kId] == null) {
                this[kId] = bson_1.Long.ZERO;
                // TODO(NODE-3286): ExecutionResult needs to accept a generic parameter
                this[kDocuments].push(state.response);
            }
            // the cursor is now initialized, even if it is dead
            this[kInitialized] = true;
        }
        catch (error) {
            // the cursor is now initialized, even if an error occurred
            this[kInitialized] = true;
            await cleanupCursor(this, { error });
            throw error;
        }
        if (this.isDead) {
            await cleanupCursor(this, undefined);
        }
        return;
    }
}
/** @event */
AbstractCursor.CLOSE = 'close';
exports.AbstractCursor = AbstractCursor;
/**
 * @param cursor - the cursor on which to call `next`
 * @param blocking - a boolean indicating whether or not the cursor should `block` until data
 *     is available.  Generally, this flag is set to `false` because if the getMore returns no documents,
 *     the cursor has been exhausted.  In certain scenarios (ChangeStreams, tailable await cursors and
 *     `tryNext`, for example) blocking is necessary because a getMore returning no documents does
 *     not indicate the end of the cursor.
 * @param transform - if true, the cursor's transform function is applied to the result document (if the transform exists)
 * @returns the next document in the cursor, or `null`.  When `blocking` is `true`, a `null` document means
 * the cursor has been exhausted.  Otherwise, it means that there is no document available in the cursor's buffer.
 */
async function next(cursor, { blocking, transform }) {
    if (cursor.closed) {
        return null;
    }
    do {
        if (cursor[kId] == null) {
            // All cursors must operate within a session, one must be made implicitly if not explicitly provided
            await cursor[kInit]();
        }
        if (cursor[kDocuments].length !== 0) {
            const doc = cursor[kDocuments].shift();
            if (doc != null && transform && cursor[kTransform]) {
                try {
                    return cursor[kTransform](doc);
                }
                catch (error) {
                    // `cleanupCursorAsync` should never throw, but if it does we want to throw the original
                    // error instead.
                    await cleanupCursor(cursor, { error, needsToEmitClosed: true }).catch(() => null);
                    throw error;
                }
            }
            return doc;
        }
        if (cursor.isDead) {
            // if the cursor is dead, we clean it up
            // cleanupCursorAsync should never throw, but if it does it indicates a bug in the driver
            // and we should surface the error
            await cleanupCursor(cursor, {});
            return null;
        }
        // otherwise need to call getMore
        const batchSize = cursor[kOptions].batchSize || 1000;
        try {
            const response = await cursor.getMore(batchSize);
            if (response) {
                const cursorId = typeof response.cursor.id === 'number'
                    ? bson_1.Long.fromNumber(response.cursor.id)
                    : typeof response.cursor.id === 'bigint'
                        ? bson_1.Long.fromBigInt(response.cursor.id)
                        : response.cursor.id;
                cursor[kDocuments].pushMany(response.cursor.nextBatch);
                cursor[kId] = cursorId;
            }
        }
        catch (error) {
            // `cleanupCursorAsync` should never throw, but if it does we want to throw the original
            // error instead.
            await cleanupCursor(cursor, { error }).catch(() => null);
            throw error;
        }
        if (cursor.isDead) {
            // If we successfully received a response from a cursor BUT the cursor indicates that it is exhausted,
            // we intentionally clean up the cursor to release its session back into the pool before the cursor
            // is iterated.  This prevents a cursor that is exhausted on the server from holding
            // onto a session indefinitely until the AbstractCursor is iterated.
            //
            // cleanupCursorAsync should never throw, but if it does it indicates a bug in the driver
            // and we should surface the error
            await cleanupCursor(cursor, {});
        }
        if (cursor[kDocuments].length === 0 && blocking === false) {
            return null;
        }
    } while (!cursor.isDead || cursor[kDocuments].length !== 0);
    return null;
}
async function cleanupCursor(cursor, options) {
    const cursorId = cursor[kId];
    const cursorNs = cursor[kNamespace];
    const server = cursor[kServer];
    const session = cursor[kSession];
    const error = options?.error;
    // Cursors only emit closed events once the client-side cursor has been exhausted fully or there
    // was an error.  Notably, when the server returns a cursor id of 0 and a non-empty batch, we
    // cleanup the cursor but don't emit a `close` event.
    const needsToEmitClosed = options?.needsToEmitClosed ?? cursor[kDocuments].length === 0;
    if (error) {
        if (cursor.loadBalanced && error instanceof error_1.MongoNetworkError) {
            return completeCleanup();
        }
    }
    if (cursorId == null || server == null || cursorId.isZero() || cursorNs == null) {
        if (needsToEmitClosed) {
            cursor[kClosed] = true;
            cursor[kId] = bson_1.Long.ZERO;
            cursor.emit(AbstractCursor.CLOSE);
        }
        if (session) {
            if (session.owner === cursor) {
                await session.endSession({ error });
                return;
            }
            if (!session.inTransaction()) {
                (0, sessions_1.maybeClearPinnedConnection)(session, { error });
            }
        }
        return;
    }
    async function completeCleanup() {
        if (session) {
            if (session.owner === cursor) {
                try {
                    await session.endSession({ error });
                }
                finally {
                    cursor.emit(AbstractCursor.CLOSE);
                }
                return;
            }
            if (!session.inTransaction()) {
                (0, sessions_1.maybeClearPinnedConnection)(session, { error });
            }
        }
        cursor.emit(AbstractCursor.CLOSE);
        return;
    }
    cursor[kKilled] = true;
    if (session.hasEnded) {
        return completeCleanup();
    }
    try {
        await (0, execute_operation_1.executeOperation)(cursor[kClient], new kill_cursors_1.KillCursorsOperation(cursorId, cursorNs, server, { session })).catch(() => null);
    }
    finally {
        await completeCleanup();
    }
}
/** @internal */
function assertUninitialized(cursor) {
    if (cursor[kInitialized]) {
        throw new error_1.MongoCursorInUseError();
    }
}
exports.assertUninitialized = assertUninitialized;
class ReadableCursorStream extends stream_1.Readable {
    constructor(cursor) {
        super({
            objectMode: true,
            autoDestroy: false,
            highWaterMark: 1
        });
        this._readInProgress = false;
        this._cursor = cursor;
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _read(size) {
        if (!this._readInProgress) {
            this._readInProgress = true;
            this._readNext();
        }
    }
    _destroy(error, callback) {
        this._cursor.close().then(() => callback(error), closeError => callback(closeError));
    }
    _readNext() {
        next(this._cursor, { blocking: true, transform: true }).then(result => {
            if (result == null) {
                this.push(null);
            }
            else if (this.destroyed) {
                this._cursor.close().catch(() => null);
            }
            else {
                if (this.push(result)) {
                    return this._readNext();
                }
                this._readInProgress = false;
            }
        }, err => {
            // NOTE: This is questionable, but we have a test backing the behavior. It seems the
            //       desired behavior is that a stream ends cleanly when a user explicitly closes
            //       a client during iteration. Alternatively, we could do the "right" thing and
            //       propagate the error message by removing this special case.
            if (err.message.match(/server is closed/)) {
                this._cursor.close().catch(() => null);
                return this.push(null);
            }
            // NOTE: This is also perhaps questionable. The rationale here is that these errors tend
            //       to be "operation was interrupted", where a cursor has been closed but there is an
            //       active getMore in-flight. This used to check if the cursor was killed but once
            //       that changed to happen in cleanup legitimate errors would not destroy the
            //       stream. There are change streams test specifically test these cases.
            if (err.message.match(/operation was interrupted/)) {
                return this.push(null);
            }
            // NOTE: The two above checks on the message of the error will cause a null to be pushed
            //       to the stream, thus closing the stream before the destroy call happens. This means
            //       that either of those error messages on a change stream will not get a proper
            //       'error' event to be emitted (the error passed to destroy). Change stream resumability
            //       relies on that error event to be emitted to create its new cursor and thus was not
            //       working on 4.4 servers because the error emitted on failover was "interrupted at
            //       shutdown" while on 5.0+ it is "The server is in quiesce mode and will shut down".
            //       See NODE-4475.
            return this.destroy(err);
        });
    }
}
//# sourceMappingURL=abstract_cursor.js.map