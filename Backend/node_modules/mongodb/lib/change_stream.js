"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChangeStream = void 0;
const collection_1 = require("./collection");
const constants_1 = require("./constants");
const change_stream_cursor_1 = require("./cursor/change_stream_cursor");
const db_1 = require("./db");
const error_1 = require("./error");
const mongo_client_1 = require("./mongo_client");
const mongo_types_1 = require("./mongo_types");
const utils_1 = require("./utils");
/** @internal */
const kCursorStream = Symbol('cursorStream');
/** @internal */
const kClosed = Symbol('closed');
/** @internal */
const kMode = Symbol('mode');
const CHANGE_STREAM_OPTIONS = [
    'resumeAfter',
    'startAfter',
    'startAtOperationTime',
    'fullDocument',
    'fullDocumentBeforeChange',
    'showExpandedEvents'
];
const CHANGE_DOMAIN_TYPES = {
    COLLECTION: Symbol('Collection'),
    DATABASE: Symbol('Database'),
    CLUSTER: Symbol('Cluster')
};
const CHANGE_STREAM_EVENTS = [constants_1.RESUME_TOKEN_CHANGED, constants_1.END, constants_1.CLOSE];
const NO_RESUME_TOKEN_ERROR = 'A change stream document has been received that lacks a resume token (_id).';
const CHANGESTREAM_CLOSED_ERROR = 'ChangeStream is closed';
/**
 * Creates a new Change Stream instance. Normally created using {@link Collection#watch|Collection.watch()}.
 * @public
 */
class ChangeStream extends mongo_types_1.TypedEventEmitter {
    /**
     * @internal
     *
     * @param parent - The parent object that created this change stream
     * @param pipeline - An array of {@link https://www.mongodb.com/docs/manual/reference/operator/aggregation-pipeline/|aggregation pipeline stages} through which to pass change stream documents
     */
    constructor(parent, pipeline = [], options = {}) {
        super();
        this.pipeline = pipeline;
        this.options = { ...options };
        delete this.options.writeConcern;
        if (parent instanceof collection_1.Collection) {
            this.type = CHANGE_DOMAIN_TYPES.COLLECTION;
        }
        else if (parent instanceof db_1.Db) {
            this.type = CHANGE_DOMAIN_TYPES.DATABASE;
        }
        else if (parent instanceof mongo_client_1.MongoClient) {
            this.type = CHANGE_DOMAIN_TYPES.CLUSTER;
        }
        else {
            throw new error_1.MongoChangeStreamError('Parent provided to ChangeStream constructor must be an instance of Collection, Db, or MongoClient');
        }
        this.parent = parent;
        this.namespace = parent.s.namespace;
        if (!this.options.readPreference && parent.readPreference) {
            this.options.readPreference = parent.readPreference;
        }
        // Create contained Change Stream cursor
        this.cursor = this._createChangeStreamCursor(options);
        this[kClosed] = false;
        this[kMode] = false;
        // Listen for any `change` listeners being added to ChangeStream
        this.on('newListener', eventName => {
            if (eventName === 'change' && this.cursor && this.listenerCount('change') === 0) {
                this._streamEvents(this.cursor);
            }
        });
        this.on('removeListener', eventName => {
            if (eventName === 'change' && this.listenerCount('change') === 0 && this.cursor) {
                this[kCursorStream]?.removeAllListeners('data');
            }
        });
    }
    /** @internal */
    get cursorStream() {
        return this[kCursorStream];
    }
    /** The cached resume token that is used to resume after the most recently returned change. */
    get resumeToken() {
        return this.cursor?.resumeToken;
    }
    /** Check if there is any document still available in the Change Stream */
    async hasNext() {
        this._setIsIterator();
        // Change streams must resume indefinitely while each resume event succeeds.
        // This loop continues until either a change event is received or until a resume attempt
        // fails.
        // eslint-disable-next-line no-constant-condition
        while (true) {
            try {
                const hasNext = await this.cursor.hasNext();
                return hasNext;
            }
            catch (error) {
                try {
                    await this._processErrorIteratorMode(error);
                }
                catch (error) {
                    try {
                        await this.close();
                    }
                    catch {
                        // We are not concerned with errors from close()
                    }
                    throw error;
                }
            }
        }
    }
    /** Get the next available document from the Change Stream. */
    async next() {
        this._setIsIterator();
        // Change streams must resume indefinitely while each resume event succeeds.
        // This loop continues until either a change event is received or until a resume attempt
        // fails.
        // eslint-disable-next-line no-constant-condition
        while (true) {
            try {
                const change = await this.cursor.next();
                const processedChange = this._processChange(change ?? null);
                return processedChange;
            }
            catch (error) {
                try {
                    await this._processErrorIteratorMode(error);
                }
                catch (error) {
                    try {
                        await this.close();
                    }
                    catch {
                        // We are not concerned with errors from close()
                    }
                    throw error;
                }
            }
        }
    }
    /**
     * Try to get the next available document from the Change Stream's cursor or `null` if an empty batch is returned
     */
    async tryNext() {
        this._setIsIterator();
        // Change streams must resume indefinitely while each resume event succeeds.
        // This loop continues until either a change event is received or until a resume attempt
        // fails.
        // eslint-disable-next-line no-constant-condition
        while (true) {
            try {
                const change = await this.cursor.tryNext();
                return change ?? null;
            }
            catch (error) {
                try {
                    await this._processErrorIteratorMode(error);
                }
                catch (error) {
                    try {
                        await this.close();
                    }
                    catch {
                        // We are not concerned with errors from close()
                    }
                    throw error;
                }
            }
        }
    }
    async *[Symbol.asyncIterator]() {
        if (this.closed) {
            return;
        }
        try {
            // Change streams run indefinitely as long as errors are resumable
            // So the only loop breaking condition is if `next()` throws
            while (true) {
                yield await this.next();
            }
        }
        finally {
            try {
                await this.close();
            }
            catch {
                // we're not concerned with errors from close()
            }
        }
    }
    /** Is the cursor closed */
    get closed() {
        return this[kClosed] || this.cursor.closed;
    }
    /** Close the Change Stream */
    async close() {
        this[kClosed] = true;
        const cursor = this.cursor;
        try {
            await cursor.close();
        }
        finally {
            this._endStream();
        }
    }
    /**
     * Return a modified Readable stream including a possible transform method.
     *
     * NOTE: When using a Stream to process change stream events, the stream will
     * NOT automatically resume in the case a resumable error is encountered.
     *
     * @throws MongoChangeStreamError if the underlying cursor or the change stream is closed
     */
    stream(options) {
        if (this.closed) {
            throw new error_1.MongoChangeStreamError(CHANGESTREAM_CLOSED_ERROR);
        }
        this.streamOptions = options;
        return this.cursor.stream(options);
    }
    /** @internal */
    _setIsEmitter() {
        if (this[kMode] === 'iterator') {
            // TODO(NODE-3485): Replace with MongoChangeStreamModeError
            throw new error_1.MongoAPIError('ChangeStream cannot be used as an EventEmitter after being used as an iterator');
        }
        this[kMode] = 'emitter';
    }
    /** @internal */
    _setIsIterator() {
        if (this[kMode] === 'emitter') {
            // TODO(NODE-3485): Replace with MongoChangeStreamModeError
            throw new error_1.MongoAPIError('ChangeStream cannot be used as an iterator after being used as an EventEmitter');
        }
        this[kMode] = 'iterator';
    }
    /**
     * Create a new change stream cursor based on self's configuration
     * @internal
     */
    _createChangeStreamCursor(options) {
        const changeStreamStageOptions = (0, utils_1.filterOptions)(options, CHANGE_STREAM_OPTIONS);
        if (this.type === CHANGE_DOMAIN_TYPES.CLUSTER) {
            changeStreamStageOptions.allChangesForCluster = true;
        }
        const pipeline = [{ $changeStream: changeStreamStageOptions }, ...this.pipeline];
        const client = this.type === CHANGE_DOMAIN_TYPES.CLUSTER
            ? this.parent
            : this.type === CHANGE_DOMAIN_TYPES.DATABASE
                ? this.parent.client
                : this.type === CHANGE_DOMAIN_TYPES.COLLECTION
                    ? this.parent.client
                    : null;
        if (client == null) {
            // This should never happen because of the assertion in the constructor
            throw new error_1.MongoRuntimeError(`Changestream type should only be one of cluster, database, collection. Found ${this.type.toString()}`);
        }
        const changeStreamCursor = new change_stream_cursor_1.ChangeStreamCursor(client, this.namespace, pipeline, options);
        for (const event of CHANGE_STREAM_EVENTS) {
            changeStreamCursor.on(event, e => this.emit(event, e));
        }
        if (this.listenerCount(ChangeStream.CHANGE) > 0) {
            this._streamEvents(changeStreamCursor);
        }
        return changeStreamCursor;
    }
    /** @internal */
    _closeEmitterModeWithError(error) {
        this.emit(ChangeStream.ERROR, error);
        this.close().catch(() => null);
    }
    /** @internal */
    _streamEvents(cursor) {
        this._setIsEmitter();
        const stream = this[kCursorStream] ?? cursor.stream();
        this[kCursorStream] = stream;
        stream.on('data', change => {
            try {
                const processedChange = this._processChange(change);
                this.emit(ChangeStream.CHANGE, processedChange);
            }
            catch (error) {
                this.emit(ChangeStream.ERROR, error);
            }
        });
        stream.on('error', error => this._processErrorStreamMode(error));
    }
    /** @internal */
    _endStream() {
        const cursorStream = this[kCursorStream];
        if (cursorStream) {
            ['data', 'close', 'end', 'error'].forEach(event => cursorStream.removeAllListeners(event));
            cursorStream.destroy();
        }
        this[kCursorStream] = undefined;
    }
    /** @internal */
    _processChange(change) {
        if (this[kClosed]) {
            // TODO(NODE-3485): Replace with MongoChangeStreamClosedError
            throw new error_1.MongoAPIError(CHANGESTREAM_CLOSED_ERROR);
        }
        // a null change means the cursor has been notified, implicitly closing the change stream
        if (change == null) {
            // TODO(NODE-3485): Replace with MongoChangeStreamClosedError
            throw new error_1.MongoRuntimeError(CHANGESTREAM_CLOSED_ERROR);
        }
        if (change && !change._id) {
            throw new error_1.MongoChangeStreamError(NO_RESUME_TOKEN_ERROR);
        }
        // cache the resume token
        this.cursor.cacheResumeToken(change._id);
        // wipe the startAtOperationTime if there was one so that there won't be a conflict
        // between resumeToken and startAtOperationTime if we need to reconnect the cursor
        this.options.startAtOperationTime = undefined;
        return change;
    }
    /** @internal */
    _processErrorStreamMode(changeStreamError) {
        // If the change stream has been closed explicitly, do not process error.
        if (this[kClosed])
            return;
        if ((0, error_1.isResumableError)(changeStreamError, this.cursor.maxWireVersion)) {
            this._endStream();
            this.cursor.close().catch(() => null);
            const topology = (0, utils_1.getTopology)(this.parent);
            topology.selectServer(this.cursor.readPreference, { operationName: 'reconnect topology in change stream' }, serverSelectionError => {
                if (serverSelectionError)
                    return this._closeEmitterModeWithError(changeStreamError);
                this.cursor = this._createChangeStreamCursor(this.cursor.resumeOptions);
            });
        }
        else {
            this._closeEmitterModeWithError(changeStreamError);
        }
    }
    /** @internal */
    async _processErrorIteratorMode(changeStreamError) {
        if (this[kClosed]) {
            // TODO(NODE-3485): Replace with MongoChangeStreamClosedError
            throw new error_1.MongoAPIError(CHANGESTREAM_CLOSED_ERROR);
        }
        if (!(0, error_1.isResumableError)(changeStreamError, this.cursor.maxWireVersion)) {
            try {
                await this.close();
            }
            catch {
                // ignore errors from close
            }
            throw changeStreamError;
        }
        await this.cursor.close().catch(() => null);
        const topology = (0, utils_1.getTopology)(this.parent);
        try {
            await topology.selectServerAsync(this.cursor.readPreference, {
                operationName: 'reconnect topology in change stream'
            });
            this.cursor = this._createChangeStreamCursor(this.cursor.resumeOptions);
        }
        catch {
            // if the topology can't reconnect, close the stream
            await this.close();
            throw changeStreamError;
        }
    }
}
/** @event */
ChangeStream.RESPONSE = constants_1.RESPONSE;
/** @event */
ChangeStream.MORE = constants_1.MORE;
/** @event */
ChangeStream.INIT = constants_1.INIT;
/** @event */
ChangeStream.CLOSE = constants_1.CLOSE;
/**
 * Fired for each new matching change in the specified namespace. Attaching a `change`
 * event listener to a Change Stream will switch the stream into flowing mode. Data will
 * then be passed as soon as it is available.
 * @event
 */
ChangeStream.CHANGE = constants_1.CHANGE;
/** @event */
ChangeStream.END = constants_1.END;
/** @event */
ChangeStream.ERROR = constants_1.ERROR;
/**
 * Emitted each time the change stream stores a new resume token.
 * @event
 */
ChangeStream.RESUME_TOKEN_CHANGED = constants_1.RESUME_TOKEN_CHANGED;
exports.ChangeStream = ChangeStream;
//# sourceMappingURL=change_stream.js.map