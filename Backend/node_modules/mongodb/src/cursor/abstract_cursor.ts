import { Readable, Transform } from 'stream';

import { type BSONSerializeOptions, type Document, Long, pluckBSONSerializeOptions } from '../bson';
import {
  type AnyError,
  MongoAPIError,
  MongoCursorExhaustedError,
  MongoCursorInUseError,
  MongoInvalidArgumentError,
  MongoNetworkError,
  MongoRuntimeError,
  MongoTailableCursorError
} from '../error';
import type { MongoClient } from '../mongo_client';
import { type TODO_NODE_3286, TypedEventEmitter } from '../mongo_types';
import { executeOperation, type ExecutionResult } from '../operations/execute_operation';
import { GetMoreOperation } from '../operations/get_more';
import { KillCursorsOperation } from '../operations/kill_cursors';
import { ReadConcern, type ReadConcernLike } from '../read_concern';
import { ReadPreference, type ReadPreferenceLike } from '../read_preference';
import type { Server } from '../sdam/server';
import { ClientSession, maybeClearPinnedConnection } from '../sessions';
import { List, type MongoDBNamespace, ns } from '../utils';

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
export const CURSOR_FLAGS = [
  'tailable',
  'oplogReplay',
  'noCursorTimeout',
  'awaitData',
  'exhaust',
  'partial'
] as const;

/** @public */
export interface CursorStreamOptions {
  /** A transformation method applied to each document emitted by the stream */
  transform?(this: void, doc: Document): Document;
}

/** @public */
export type CursorFlag = (typeof CURSOR_FLAGS)[number];

/** @public */
export interface AbstractCursorOptions extends BSONSerializeOptions {
  session?: ClientSession;
  readPreference?: ReadPreferenceLike;
  readConcern?: ReadConcernLike;
  /**
   * Specifies the number of documents to return in each response from MongoDB
   */
  batchSize?: number;
  /**
   * When applicable `maxTimeMS` controls the amount of time the initial command
   * that constructs a cursor should take. (ex. find, aggregate, listCollections)
   */
  maxTimeMS?: number;
  /**
   * When applicable `maxAwaitTimeMS` controls the amount of time subsequent getMores
   * that a cursor uses to fetch more data should take. (ex. cursor.next())
   */
  maxAwaitTimeMS?: number;
  /**
   * Comment to apply to the operation.
   *
   * In server versions pre-4.4, 'comment' must be string.  A server
   * error will be thrown if any other type is provided.
   *
   * In server versions 4.4 and above, 'comment' can be any valid BSON type.
   */
  comment?: unknown;
  /**
   * By default, MongoDB will automatically close a cursor when the
   * client has exhausted all results in the cursor. However, for [capped collections](https://www.mongodb.com/docs/manual/core/capped-collections)
   * you may use a Tailable Cursor that remains open after the client exhausts
   * the results in the initial cursor.
   */
  tailable?: boolean;
  /**
   * If awaitData is set to true, when the cursor reaches the end of the capped collection,
   * MongoDB blocks the query thread for a period of time waiting for new data to arrive.
   * When new data is inserted into the capped collection, the blocked thread is signaled
   * to wake up and return the next batch to the client.
   */
  awaitData?: boolean;
  noCursorTimeout?: boolean;
}

/** @internal */
export type InternalAbstractCursorOptions = Omit<AbstractCursorOptions, 'readPreference'> & {
  // resolved
  readPreference: ReadPreference;
  readConcern?: ReadConcern;

  // cursor flags, some are deprecated
  oplogReplay?: boolean;
  exhaust?: boolean;
  partial?: boolean;
};

/** @public */
export type AbstractCursorEvents = {
  [AbstractCursor.CLOSE](): void;
};

/** @public */
export abstract class AbstractCursor<
  TSchema = any,
  CursorEvents extends AbstractCursorEvents = AbstractCursorEvents
> extends TypedEventEmitter<CursorEvents> {
  /** @internal */
  [kId]: Long | null;
  /** @internal */
  [kSession]: ClientSession;
  /** @internal */
  [kServer]?: Server;
  /** @internal */
  [kNamespace]: MongoDBNamespace;
  /** @internal */
  [kDocuments]: List<TSchema>;
  /** @internal */
  [kClient]: MongoClient;
  /** @internal */
  [kTransform]?: (doc: TSchema) => any;
  /** @internal */
  [kInitialized]: boolean;
  /** @internal */
  [kClosed]: boolean;
  /** @internal */
  [kKilled]: boolean;
  /** @internal */
  [kOptions]: InternalAbstractCursorOptions;

  /** @event */
  static readonly CLOSE = 'close' as const;

  /** @internal */
  constructor(
    client: MongoClient,
    namespace: MongoDBNamespace,
    options: AbstractCursorOptions = {}
  ) {
    super();

    if (!client.s.isMongoClient) {
      throw new MongoRuntimeError('Cursor must be constructed with MongoClient');
    }
    this[kClient] = client;
    this[kNamespace] = namespace;
    this[kId] = null;
    this[kDocuments] = new List();
    this[kInitialized] = false;
    this[kClosed] = false;
    this[kKilled] = false;
    this[kOptions] = {
      readPreference:
        options.readPreference && options.readPreference instanceof ReadPreference
          ? options.readPreference
          : ReadPreference.primary,
      ...pluckBSONSerializeOptions(options)
    };

    const readConcern = ReadConcern.fromOptions(options);
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

    if (options.session instanceof ClientSession) {
      this[kSession] = options.session;
    } else {
      this[kSession] = this[kClient].startSession({ owner: this, explicit: false });
    }
  }

  get id(): Long | undefined {
    return this[kId] ?? undefined;
  }

  /** @internal */
  get isDead() {
    return (this[kId]?.isZero() ?? false) || this[kClosed] || this[kKilled];
  }

  /** @internal */
  get client(): MongoClient {
    return this[kClient];
  }

  /** @internal */
  get server(): Server | undefined {
    return this[kServer];
  }

  get namespace(): MongoDBNamespace {
    return this[kNamespace];
  }

  get readPreference(): ReadPreference {
    return this[kOptions].readPreference;
  }

  get readConcern(): ReadConcern | undefined {
    return this[kOptions].readConcern;
  }

  /** @internal */
  get session(): ClientSession {
    return this[kSession];
  }

  set session(clientSession: ClientSession) {
    this[kSession] = clientSession;
  }

  /** @internal */
  get cursorOptions(): InternalAbstractCursorOptions {
    return this[kOptions];
  }

  get closed(): boolean {
    return this[kClosed];
  }

  get killed(): boolean {
    return this[kKilled];
  }

  get loadBalanced(): boolean {
    return !!this[kClient].topology?.loadBalanced;
  }

  /** Returns current buffered documents length */
  bufferedCount(): number {
    return this[kDocuments].length;
  }

  /** Returns current buffered documents */
  readBufferedDocuments(number?: number): TSchema[] {
    const bufferedDocs: TSchema[] = [];
    const documentsToRead = Math.min(number ?? this[kDocuments].length, this[kDocuments].length);

    for (let count = 0; count < documentsToRead; count++) {
      const document = this[kDocuments].shift();
      if (document != null) {
        bufferedDocs.push(document);
      }
    }

    return bufferedDocs;
  }

  async *[Symbol.asyncIterator](): AsyncGenerator<TSchema, void, void> {
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
            const message =
              'Cursor returned a `null` document, but the cursor is not exhausted.  Mapping documents to `null` is not supported in the cursor transform.';

            await cleanupCursor(this, { needsToEmitClosed: true }).catch(() => null);

            throw new MongoAPIError(message);
          }
          break;
        }

        yield document;

        if (this[kId] === Long.ZERO) {
          // Cursor exhausted
          break;
        }
      }
    } finally {
      // Only close the cursor if it has not already been closed. This finally clause handles
      // the case when a user would break out of a for await of loop early.
      if (!this.closed) {
        await this.close().catch(() => null);
      }
    }
  }

  stream(options?: CursorStreamOptions): Readable & AsyncIterable<TSchema> {
    if (options?.transform) {
      const transform = options.transform;
      const readable = new ReadableCursorStream(this);

      const transformedStream = readable.pipe(
        new Transform({
          objectMode: true,
          highWaterMark: 1,
          transform(chunk, _, callback) {
            try {
              const transformed = transform(chunk);
              callback(undefined, transformed);
            } catch (err) {
              callback(err);
            }
          }
        })
      );

      // Bubble errors to transformed stream, because otherwise no way
      // to handle this error.
      readable.on('error', err => transformedStream.emit('error', err));

      return transformedStream;
    }

    return new ReadableCursorStream(this);
  }

  async hasNext(): Promise<boolean> {
    if (this[kId] === Long.ZERO) {
      return false;
    }

    if (this[kDocuments].length !== 0) {
      return true;
    }

    const doc = await next<TSchema>(this, { blocking: true, transform: false });

    if (doc) {
      this[kDocuments].unshift(doc);
      return true;
    }

    return false;
  }

  /** Get the next available document from the cursor, returns null if no more documents are available. */
  async next(): Promise<TSchema | null> {
    if (this[kId] === Long.ZERO) {
      throw new MongoCursorExhaustedError();
    }

    return next(this, { blocking: true, transform: true });
  }

  /**
   * Try to get the next available document from the cursor or `null` if an empty batch is returned
   */
  async tryNext(): Promise<TSchema | null> {
    if (this[kId] === Long.ZERO) {
      throw new MongoCursorExhaustedError();
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
  async forEach(iterator: (doc: TSchema) => boolean | void): Promise<void> {
    if (typeof iterator !== 'function') {
      throw new MongoInvalidArgumentError('Argument "iterator" must be a function');
    }
    for await (const document of this) {
      const result = iterator(document);
      if (result === false) {
        break;
      }
    }
  }

  async close(): Promise<void> {
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
  async toArray(): Promise<TSchema[]> {
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
  addCursorFlag(flag: CursorFlag, value: boolean): this {
    assertUninitialized(this);
    if (!CURSOR_FLAGS.includes(flag)) {
      throw new MongoInvalidArgumentError(`Flag ${flag} is not one of ${CURSOR_FLAGS}`);
    }

    if (typeof value !== 'boolean') {
      throw new MongoInvalidArgumentError(`Flag ${flag} must be a boolean value`);
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
  map<T = any>(transform: (doc: TSchema) => T): AbstractCursor<T> {
    assertUninitialized(this);
    const oldTransform = this[kTransform] as (doc: TSchema) => TSchema; // TODO(NODE-3283): Improve transform typing
    if (oldTransform) {
      this[kTransform] = doc => {
        return transform(oldTransform(doc));
      };
    } else {
      this[kTransform] = transform;
    }

    return this as unknown as AbstractCursor<T>;
  }

  /**
   * Set the ReadPreference for the cursor.
   *
   * @param readPreference - The new read preference for the cursor.
   */
  withReadPreference(readPreference: ReadPreferenceLike): this {
    assertUninitialized(this);
    if (readPreference instanceof ReadPreference) {
      this[kOptions].readPreference = readPreference;
    } else if (typeof readPreference === 'string') {
      this[kOptions].readPreference = ReadPreference.fromString(readPreference);
    } else {
      throw new MongoInvalidArgumentError(`Invalid read preference: ${readPreference}`);
    }

    return this;
  }

  /**
   * Set the ReadPreference for the cursor.
   *
   * @param readPreference - The new read preference for the cursor.
   */
  withReadConcern(readConcern: ReadConcernLike): this {
    assertUninitialized(this);
    const resolvedReadConcern = ReadConcern.fromOptions({ readConcern });
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
  maxTimeMS(value: number): this {
    assertUninitialized(this);
    if (typeof value !== 'number') {
      throw new MongoInvalidArgumentError('Argument for maxTimeMS must be a number');
    }

    this[kOptions].maxTimeMS = value;
    return this;
  }

  /**
   * Set the batch size for the cursor.
   *
   * @param value - The number of documents to return per batch. See {@link https://www.mongodb.com/docs/manual/reference/command/find/|find command documentation}.
   */
  batchSize(value: number): this {
    assertUninitialized(this);
    if (this[kOptions].tailable) {
      throw new MongoTailableCursorError('Tailable cursor does not support batchSize');
    }

    if (typeof value !== 'number') {
      throw new MongoInvalidArgumentError('Operation "batchSize" requires an integer');
    }

    this[kOptions].batchSize = value;
    return this;
  }

  /**
   * Rewind this cursor to its uninitialized state. Any options that are present on the cursor will
   * remain in effect. Iterating this cursor will cause new queries to be sent to the server, even
   * if the resultant data has already been retrieved by this cursor.
   */
  rewind(): void {
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

  /**
   * Returns a new uninitialized copy of this cursor, with options matching those that have been set on the current instance
   */
  abstract clone(): AbstractCursor<TSchema>;

  /** @internal */
  protected abstract _initialize(session: ClientSession | undefined): Promise<ExecutionResult>;

  /** @internal */
  async getMore(batchSize: number): Promise<Document | null> {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const getMoreOperation = new GetMoreOperation(this[kNamespace], this[kId]!, this[kServer]!, {
      ...this[kOptions],
      session: this[kSession],
      batchSize
    });

    return executeOperation(this[kClient], getMoreOperation);
  }

  /**
   * @internal
   *
   * This function is exposed for the unified test runner's createChangeStream
   * operation.  We cannot refactor to use the abstract _initialize method without
   * a significant refactor.
   */
  async [kInit](): Promise<void> {
    try {
      const state = await this._initialize(this[kSession]);
      const response = state.response;
      this[kServer] = state.server;
      if (response.cursor) {
        // TODO(NODE-2674): Preserve int64 sent from MongoDB
        this[kId] =
          typeof response.cursor.id === 'number'
            ? Long.fromNumber(response.cursor.id)
            : typeof response.cursor.id === 'bigint'
            ? Long.fromBigInt(response.cursor.id)
            : response.cursor.id;

        if (response.cursor.ns) {
          this[kNamespace] = ns(response.cursor.ns);
        }

        this[kDocuments].pushMany(response.cursor.firstBatch);
      }

      // When server responses return without a cursor document, we close this cursor
      // and return the raw server response. This is often the case for explain commands
      // for example
      if (this[kId] == null) {
        this[kId] = Long.ZERO;
        // TODO(NODE-3286): ExecutionResult needs to accept a generic parameter
        this[kDocuments].push(state.response as TODO_NODE_3286);
      }

      // the cursor is now initialized, even if it is dead
      this[kInitialized] = true;
    } catch (error) {
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
async function next<T>(
  cursor: AbstractCursor<T>,
  {
    blocking,
    transform
  }: {
    blocking: boolean;
    transform: boolean;
  }
): Promise<T | null> {
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
        } catch (error) {
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
        const cursorId =
          typeof response.cursor.id === 'number'
            ? Long.fromNumber(response.cursor.id)
            : typeof response.cursor.id === 'bigint'
            ? Long.fromBigInt(response.cursor.id)
            : response.cursor.id;

        cursor[kDocuments].pushMany(response.cursor.nextBatch);
        cursor[kId] = cursorId;
      }
    } catch (error) {
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

async function cleanupCursor(
  cursor: AbstractCursor,
  options: { error?: AnyError | undefined; needsToEmitClosed?: boolean } | undefined
): Promise<void> {
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
    if (cursor.loadBalanced && error instanceof MongoNetworkError) {
      return completeCleanup();
    }
  }

  if (cursorId == null || server == null || cursorId.isZero() || cursorNs == null) {
    if (needsToEmitClosed) {
      cursor[kClosed] = true;
      cursor[kId] = Long.ZERO;
      cursor.emit(AbstractCursor.CLOSE);
    }

    if (session) {
      if (session.owner === cursor) {
        await session.endSession({ error });
        return;
      }

      if (!session.inTransaction()) {
        maybeClearPinnedConnection(session, { error });
      }
    }

    return;
  }

  async function completeCleanup() {
    if (session) {
      if (session.owner === cursor) {
        try {
          await session.endSession({ error });
        } finally {
          cursor.emit(AbstractCursor.CLOSE);
        }
        return;
      }

      if (!session.inTransaction()) {
        maybeClearPinnedConnection(session, { error });
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
    await executeOperation(
      cursor[kClient],
      new KillCursorsOperation(cursorId, cursorNs, server, { session })
    ).catch(() => null);
  } finally {
    await completeCleanup();
  }
}

/** @internal */
export function assertUninitialized(cursor: AbstractCursor): void {
  if (cursor[kInitialized]) {
    throw new MongoCursorInUseError();
  }
}

class ReadableCursorStream extends Readable {
  private _cursor: AbstractCursor;
  private _readInProgress = false;

  constructor(cursor: AbstractCursor) {
    super({
      objectMode: true,
      autoDestroy: false,
      highWaterMark: 1
    });
    this._cursor = cursor;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  override _read(size: number): void {
    if (!this._readInProgress) {
      this._readInProgress = true;
      this._readNext();
    }
  }

  override _destroy(error: Error | null, callback: (error?: Error | null) => void): void {
    this._cursor.close().then(
      () => callback(error),
      closeError => callback(closeError)
    );
  }

  private _readNext() {
    next(this._cursor, { blocking: true, transform: true }).then(
      result => {
        if (result == null) {
          this.push(null);
        } else if (this.destroyed) {
          this._cursor.close().catch(() => null);
        } else {
          if (this.push(result)) {
            return this._readNext();
          }

          this._readInProgress = false;
        }
      },
      err => {
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
      }
    );
  }
}
