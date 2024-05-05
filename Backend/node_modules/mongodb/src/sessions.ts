import { promisify } from 'util';

import { Binary, type Document, Long, type Timestamp } from './bson';
import type { CommandOptions, Connection } from './cmap/connection';
import { ConnectionPoolMetrics } from './cmap/metrics';
import { isSharded } from './cmap/wire_protocol/shared';
import { PINNED, UNPINNED } from './constants';
import type { AbstractCursor } from './cursor/abstract_cursor';
import {
  type AnyError,
  isRetryableWriteError,
  MongoAPIError,
  MongoCompatibilityError,
  MONGODB_ERROR_CODES,
  type MongoDriverError,
  MongoError,
  MongoErrorLabel,
  MongoExpiredSessionError,
  MongoInvalidArgumentError,
  MongoRuntimeError,
  MongoServerError,
  MongoTransactionError,
  MongoWriteConcernError
} from './error';
import type { MongoClient, MongoOptions } from './mongo_client';
import { TypedEventEmitter } from './mongo_types';
import { executeOperation } from './operations/execute_operation';
import { RunAdminCommandOperation } from './operations/run_command';
import { ReadConcernLevel } from './read_concern';
import { ReadPreference } from './read_preference';
import { _advanceClusterTime, type ClusterTime, TopologyType } from './sdam/common';
import {
  isTransactionCommand,
  Transaction,
  type TransactionOptions,
  TxnState
} from './transactions';
import {
  ByteUtils,
  calculateDurationInMs,
  type Callback,
  commandSupportsReadConcern,
  isPromiseLike,
  List,
  maxWireVersion,
  now,
  uuidV4
} from './utils';
import { WriteConcern } from './write_concern';

const minWireVersionForShardedTransactions = 8;

/** @public */
export interface ClientSessionOptions {
  /** Whether causal consistency should be enabled on this session */
  causalConsistency?: boolean;
  /** Whether all read operations should be read from the same snapshot for this session (NOTE: not compatible with `causalConsistency=true`) */
  snapshot?: boolean;
  /** The default TransactionOptions to use for transactions started on this session. */
  defaultTransactionOptions?: TransactionOptions;

  /** @internal */
  owner?: symbol | AbstractCursor;
  /** @internal */
  explicit?: boolean;
  /** @internal */
  initialClusterTime?: ClusterTime;
}

/** @public */
export type WithTransactionCallback<T = any> = (session: ClientSession) => Promise<T>;

/** @public */
export type ClientSessionEvents = {
  ended(session: ClientSession): void;
};

/** @internal */
const kServerSession = Symbol('serverSession');
/** @internal */
const kSnapshotTime = Symbol('snapshotTime');
/** @internal */
const kSnapshotEnabled = Symbol('snapshotEnabled');
/** @internal */
const kPinnedConnection = Symbol('pinnedConnection');
/** @internal Accumulates total number of increments to add to txnNumber when applying session to command */
const kTxnNumberIncrement = Symbol('txnNumberIncrement');

/** @public */
export interface EndSessionOptions {
  /**
   * An optional error which caused the call to end this session
   * @internal
   */
  error?: AnyError;
  force?: boolean;
  forceClear?: boolean;
}

/**
 * A class representing a client session on the server
 *
 * NOTE: not meant to be instantiated directly.
 * @public
 */
export class ClientSession extends TypedEventEmitter<ClientSessionEvents> {
  /** @internal */
  client: MongoClient;
  /** @internal */
  sessionPool: ServerSessionPool;
  hasEnded: boolean;
  clientOptions?: MongoOptions;
  supports: { causalConsistency: boolean };
  clusterTime?: ClusterTime;
  operationTime?: Timestamp;
  explicit: boolean;
  /** @internal */
  owner?: symbol | AbstractCursor;
  defaultTransactionOptions: TransactionOptions;
  transaction: Transaction;
  /** @internal */
  [kServerSession]: ServerSession | null;
  /** @internal */
  [kSnapshotTime]?: Timestamp;
  /** @internal */
  [kSnapshotEnabled] = false;
  /** @internal */
  [kPinnedConnection]?: Connection;
  /** @internal */
  [kTxnNumberIncrement]: number;

  /**
   * Create a client session.
   * @internal
   * @param client - The current client
   * @param sessionPool - The server session pool (Internal Class)
   * @param options - Optional settings
   * @param clientOptions - Optional settings provided when creating a MongoClient
   */
  constructor(
    client: MongoClient,
    sessionPool: ServerSessionPool,
    options: ClientSessionOptions,
    clientOptions?: MongoOptions
  ) {
    super();

    if (client == null) {
      // TODO(NODE-3483)
      throw new MongoRuntimeError('ClientSession requires a MongoClient');
    }

    if (sessionPool == null || !(sessionPool instanceof ServerSessionPool)) {
      // TODO(NODE-3483)
      throw new MongoRuntimeError('ClientSession requires a ServerSessionPool');
    }

    options = options ?? {};

    if (options.snapshot === true) {
      this[kSnapshotEnabled] = true;
      if (options.causalConsistency === true) {
        throw new MongoInvalidArgumentError(
          'Properties "causalConsistency" and "snapshot" are mutually exclusive'
        );
      }
    }

    this.client = client;
    this.sessionPool = sessionPool;
    this.hasEnded = false;
    this.clientOptions = clientOptions;

    this.explicit = !!options.explicit;
    this[kServerSession] = this.explicit ? this.sessionPool.acquire() : null;
    this[kTxnNumberIncrement] = 0;

    const defaultCausalConsistencyValue = this.explicit && options.snapshot !== true;
    this.supports = {
      // if we can enable causal consistency, do so by default
      causalConsistency: options.causalConsistency ?? defaultCausalConsistencyValue
    };

    this.clusterTime = options.initialClusterTime;

    this.operationTime = undefined;
    this.owner = options.owner;
    this.defaultTransactionOptions = Object.assign({}, options.defaultTransactionOptions);
    this.transaction = new Transaction();
  }

  /** The server id associated with this session */
  get id(): ServerSessionId | undefined {
    return this[kServerSession]?.id;
  }

  get serverSession(): ServerSession {
    let serverSession = this[kServerSession];
    if (serverSession == null) {
      if (this.explicit) {
        throw new MongoRuntimeError('Unexpected null serverSession for an explicit session');
      }
      if (this.hasEnded) {
        throw new MongoRuntimeError('Unexpected null serverSession for an ended implicit session');
      }
      serverSession = this.sessionPool.acquire();
      this[kServerSession] = serverSession;
    }
    return serverSession;
  }

  /** Whether or not this session is configured for snapshot reads */
  get snapshotEnabled(): boolean {
    return this[kSnapshotEnabled];
  }

  get loadBalanced(): boolean {
    return this.client.topology?.description.type === TopologyType.LoadBalanced;
  }

  /** @internal */
  get pinnedConnection(): Connection | undefined {
    return this[kPinnedConnection];
  }

  /** @internal */
  pin(conn: Connection): void {
    if (this[kPinnedConnection]) {
      throw TypeError('Cannot pin multiple connections to the same session');
    }

    this[kPinnedConnection] = conn;
    conn.emit(
      PINNED,
      this.inTransaction() ? ConnectionPoolMetrics.TXN : ConnectionPoolMetrics.CURSOR
    );
  }

  /** @internal */
  unpin(options?: { force?: boolean; forceClear?: boolean; error?: AnyError }): void {
    if (this.loadBalanced) {
      return maybeClearPinnedConnection(this, options);
    }

    this.transaction.unpinServer();
  }

  get isPinned(): boolean {
    return this.loadBalanced ? !!this[kPinnedConnection] : this.transaction.isPinned;
  }

  /**
   * Ends this session on the server
   *
   * @param options - Optional settings. Currently reserved for future use
   */
  async endSession(options?: EndSessionOptions): Promise<void> {
    try {
      if (this.inTransaction()) {
        await this.abortTransaction();
      }
      if (!this.hasEnded) {
        const serverSession = this[kServerSession];
        if (serverSession != null) {
          // release the server session back to the pool
          this.sessionPool.release(serverSession);
          // Make sure a new serverSession never makes it onto this ClientSession
          Object.defineProperty(this, kServerSession, {
            value: ServerSession.clone(serverSession),
            writable: false
          });
        }
        // mark the session as ended, and emit a signal
        this.hasEnded = true;
        this.emit('ended', this);
      }
    } catch {
      // spec indicates that we should ignore all errors for `endSessions`
    } finally {
      maybeClearPinnedConnection(this, { force: true, ...options });
    }
  }

  /**
   * Advances the operationTime for a ClientSession.
   *
   * @param operationTime - the `BSON.Timestamp` of the operation type it is desired to advance to
   */
  advanceOperationTime(operationTime: Timestamp): void {
    if (this.operationTime == null) {
      this.operationTime = operationTime;
      return;
    }

    if (operationTime.greaterThan(this.operationTime)) {
      this.operationTime = operationTime;
    }
  }

  /**
   * Advances the clusterTime for a ClientSession to the provided clusterTime of another ClientSession
   *
   * @param clusterTime - the $clusterTime returned by the server from another session in the form of a document containing the `BSON.Timestamp` clusterTime and signature
   */
  advanceClusterTime(clusterTime: ClusterTime): void {
    if (!clusterTime || typeof clusterTime !== 'object') {
      throw new MongoInvalidArgumentError('input cluster time must be an object');
    }
    if (!clusterTime.clusterTime || clusterTime.clusterTime._bsontype !== 'Timestamp') {
      throw new MongoInvalidArgumentError(
        'input cluster time "clusterTime" property must be a valid BSON Timestamp'
      );
    }
    if (
      !clusterTime.signature ||
      clusterTime.signature.hash?._bsontype !== 'Binary' ||
      (typeof clusterTime.signature.keyId !== 'bigint' &&
        typeof clusterTime.signature.keyId !== 'number' &&
        clusterTime.signature.keyId?._bsontype !== 'Long') // apparently we decode the key to number?
    ) {
      throw new MongoInvalidArgumentError(
        'input cluster time must have a valid "signature" property with BSON Binary hash and BSON Long keyId'
      );
    }

    _advanceClusterTime(this, clusterTime);
  }

  /**
   * Used to determine if this session equals another
   *
   * @param session - The session to compare to
   */
  equals(session: ClientSession): boolean {
    if (!(session instanceof ClientSession)) {
      return false;
    }

    if (this.id == null || session.id == null) {
      return false;
    }

    return ByteUtils.equals(this.id.id.buffer, session.id.id.buffer);
  }

  /**
   * Increment the transaction number on the internal ServerSession
   *
   * @privateRemarks
   * This helper increments a value stored on the client session that will be
   * added to the serverSession's txnNumber upon applying it to a command.
   * This is because the serverSession is lazily acquired after a connection is obtained
   */
  incrementTransactionNumber(): void {
    this[kTxnNumberIncrement] += 1;
  }

  /** @returns whether this session is currently in a transaction or not */
  inTransaction(): boolean {
    return this.transaction.isActive;
  }

  /**
   * Starts a new transaction with the given options.
   *
   * @param options - Options for the transaction
   */
  startTransaction(options?: TransactionOptions): void {
    if (this[kSnapshotEnabled]) {
      throw new MongoCompatibilityError('Transactions are not supported in snapshot sessions');
    }

    if (this.inTransaction()) {
      throw new MongoTransactionError('Transaction already in progress');
    }

    if (this.isPinned && this.transaction.isCommitted) {
      this.unpin();
    }

    const topologyMaxWireVersion = maxWireVersion(this.client.topology);
    if (
      isSharded(this.client.topology) &&
      topologyMaxWireVersion != null &&
      topologyMaxWireVersion < minWireVersionForShardedTransactions
    ) {
      throw new MongoCompatibilityError(
        'Transactions are not supported on sharded clusters in MongoDB < 4.2.'
      );
    }

    // increment txnNumber
    this.incrementTransactionNumber();
    // create transaction state
    this.transaction = new Transaction({
      readConcern:
        options?.readConcern ??
        this.defaultTransactionOptions.readConcern ??
        this.clientOptions?.readConcern,
      writeConcern:
        options?.writeConcern ??
        this.defaultTransactionOptions.writeConcern ??
        this.clientOptions?.writeConcern,
      readPreference:
        options?.readPreference ??
        this.defaultTransactionOptions.readPreference ??
        this.clientOptions?.readPreference,
      maxCommitTimeMS: options?.maxCommitTimeMS ?? this.defaultTransactionOptions.maxCommitTimeMS
    });

    this.transaction.transition(TxnState.STARTING_TRANSACTION);
  }

  /**
   * Commits the currently active transaction in this session.
   */
  async commitTransaction(): Promise<void> {
    return endTransactionAsync(this, 'commitTransaction');
  }

  /**
   * Aborts the currently active transaction in this session.
   */
  async abortTransaction(): Promise<void> {
    return endTransactionAsync(this, 'abortTransaction');
  }

  /**
   * This is here to ensure that ClientSession is never serialized to BSON.
   */
  toBSON(): never {
    throw new MongoRuntimeError('ClientSession cannot be serialized to BSON.');
  }

  /**
   * Starts a transaction and runs a provided function, ensuring the commitTransaction is always attempted when all operations run in the function have completed.
   *
   * **IMPORTANT:** This method requires the user to return a Promise, and `await` all operations.
   *
   * @remarks
   * This function:
   * - If all operations successfully complete and the `commitTransaction` operation is successful, then this function will return the result of the provided function.
   * - If the transaction is unable to complete or an error is thrown from within the provided function, then this function will throw an error.
   *   - If the transaction is manually aborted within the provided function it will not throw.
   * - May be called multiple times if the driver needs to attempt to retry the operations.
   *
   * Checkout a descriptive example here:
   * @see https://www.mongodb.com/blog/post/quick-start-nodejs--mongodb--how-to-implement-transactions
   *
   * @param fn - callback to run within a transaction
   * @param options - optional settings for the transaction
   * @returns A raw command response or undefined
   */
  async withTransaction<T = any>(
    fn: WithTransactionCallback<T>,
    options?: TransactionOptions
  ): Promise<T> {
    const startTime = now();
    return attemptTransaction(this, startTime, fn, options);
  }
}

const MAX_WITH_TRANSACTION_TIMEOUT = 120000;
const NON_DETERMINISTIC_WRITE_CONCERN_ERRORS = new Set([
  'CannotSatisfyWriteConcern',
  'UnknownReplWriteConcern',
  'UnsatisfiableWriteConcern'
]);

function hasNotTimedOut(startTime: number, max: number) {
  return calculateDurationInMs(startTime) < max;
}

function isUnknownTransactionCommitResult(err: MongoError) {
  const isNonDeterministicWriteConcernError =
    err instanceof MongoServerError &&
    err.codeName &&
    NON_DETERMINISTIC_WRITE_CONCERN_ERRORS.has(err.codeName);

  return (
    isMaxTimeMSExpiredError(err) ||
    (!isNonDeterministicWriteConcernError &&
      err.code !== MONGODB_ERROR_CODES.UnsatisfiableWriteConcern &&
      err.code !== MONGODB_ERROR_CODES.UnknownReplWriteConcern)
  );
}

export function maybeClearPinnedConnection(
  session: ClientSession,
  options?: EndSessionOptions
): void {
  // unpin a connection if it has been pinned
  const conn = session[kPinnedConnection];
  const error = options?.error;

  if (
    session.inTransaction() &&
    error &&
    error instanceof MongoError &&
    error.hasErrorLabel(MongoErrorLabel.TransientTransactionError)
  ) {
    return;
  }

  const topology = session.client.topology;
  // NOTE: the spec talks about what to do on a network error only, but the tests seem to
  //       to validate that we don't unpin on _all_ errors?
  if (conn && topology != null) {
    const servers = Array.from(topology.s.servers.values());
    const loadBalancer = servers[0];

    if (options?.error == null || options?.force) {
      loadBalancer.pool.checkIn(conn);
      conn.emit(
        UNPINNED,
        session.transaction.state !== TxnState.NO_TRANSACTION
          ? ConnectionPoolMetrics.TXN
          : ConnectionPoolMetrics.CURSOR
      );

      if (options?.forceClear) {
        loadBalancer.pool.clear({ serviceId: conn.serviceId });
      }
    }

    session[kPinnedConnection] = undefined;
  }
}

function isMaxTimeMSExpiredError(err: MongoError) {
  if (err == null || !(err instanceof MongoServerError)) {
    return false;
  }

  return (
    err.code === MONGODB_ERROR_CODES.MaxTimeMSExpired ||
    (err.writeConcernError && err.writeConcernError.code === MONGODB_ERROR_CODES.MaxTimeMSExpired)
  );
}

function attemptTransactionCommit<T>(
  session: ClientSession,
  startTime: number,
  fn: WithTransactionCallback<T>,
  result: any,
  options: TransactionOptions
): Promise<T> {
  return session.commitTransaction().then(
    () => result,
    (err: MongoError) => {
      if (
        err instanceof MongoError &&
        hasNotTimedOut(startTime, MAX_WITH_TRANSACTION_TIMEOUT) &&
        !isMaxTimeMSExpiredError(err)
      ) {
        if (err.hasErrorLabel(MongoErrorLabel.UnknownTransactionCommitResult)) {
          return attemptTransactionCommit(session, startTime, fn, result, options);
        }

        if (err.hasErrorLabel(MongoErrorLabel.TransientTransactionError)) {
          return attemptTransaction(session, startTime, fn, options);
        }
      }

      throw err;
    }
  );
}

const USER_EXPLICIT_TXN_END_STATES = new Set<TxnState>([
  TxnState.NO_TRANSACTION,
  TxnState.TRANSACTION_COMMITTED,
  TxnState.TRANSACTION_ABORTED
]);

function userExplicitlyEndedTransaction(session: ClientSession) {
  return USER_EXPLICIT_TXN_END_STATES.has(session.transaction.state);
}

function attemptTransaction<T>(
  session: ClientSession,
  startTime: number,
  fn: WithTransactionCallback<T>,
  options: TransactionOptions = {}
): Promise<any> {
  session.startTransaction(options);

  let promise;
  try {
    promise = fn(session);
  } catch (err) {
    promise = Promise.reject(err);
  }

  if (!isPromiseLike(promise)) {
    session.abortTransaction().catch(() => null);
    return Promise.reject(
      new MongoInvalidArgumentError('Function provided to `withTransaction` must return a Promise')
    );
  }

  return promise.then(
    result => {
      if (userExplicitlyEndedTransaction(session)) {
        return result;
      }

      return attemptTransactionCommit(session, startTime, fn, result, options);
    },
    err => {
      function maybeRetryOrThrow(err: MongoError): Promise<any> {
        if (
          err instanceof MongoError &&
          err.hasErrorLabel(MongoErrorLabel.TransientTransactionError) &&
          hasNotTimedOut(startTime, MAX_WITH_TRANSACTION_TIMEOUT)
        ) {
          return attemptTransaction(session, startTime, fn, options);
        }

        if (isMaxTimeMSExpiredError(err)) {
          err.addErrorLabel(MongoErrorLabel.UnknownTransactionCommitResult);
        }

        throw err;
      }

      if (session.inTransaction()) {
        return session.abortTransaction().then(() => maybeRetryOrThrow(err));
      }

      return maybeRetryOrThrow(err);
    }
  );
}

const endTransactionAsync = promisify(
  endTransaction as (
    session: ClientSession,
    commandName: 'abortTransaction' | 'commitTransaction',
    callback: (error: Error) => void
  ) => void
);

function endTransaction(
  session: ClientSession,
  commandName: 'abortTransaction' | 'commitTransaction',
  callback: Callback<void>
) {
  // handle any initial problematic cases
  const txnState = session.transaction.state;

  if (txnState === TxnState.NO_TRANSACTION) {
    callback(new MongoTransactionError('No transaction started'));
    return;
  }

  if (commandName === 'commitTransaction') {
    if (
      txnState === TxnState.STARTING_TRANSACTION ||
      txnState === TxnState.TRANSACTION_COMMITTED_EMPTY
    ) {
      // the transaction was never started, we can safely exit here
      session.transaction.transition(TxnState.TRANSACTION_COMMITTED_EMPTY);
      callback();
      return;
    }

    if (txnState === TxnState.TRANSACTION_ABORTED) {
      callback(
        new MongoTransactionError('Cannot call commitTransaction after calling abortTransaction')
      );
      return;
    }
  } else {
    if (txnState === TxnState.STARTING_TRANSACTION) {
      // the transaction was never started, we can safely exit here
      session.transaction.transition(TxnState.TRANSACTION_ABORTED);
      callback();
      return;
    }

    if (txnState === TxnState.TRANSACTION_ABORTED) {
      callback(new MongoTransactionError('Cannot call abortTransaction twice'));
      return;
    }

    if (
      txnState === TxnState.TRANSACTION_COMMITTED ||
      txnState === TxnState.TRANSACTION_COMMITTED_EMPTY
    ) {
      callback(
        new MongoTransactionError('Cannot call abortTransaction after calling commitTransaction')
      );
      return;
    }
  }

  // construct and send the command
  const command: Document = { [commandName]: 1 };

  // apply a writeConcern if specified
  let writeConcern;
  if (session.transaction.options.writeConcern) {
    writeConcern = Object.assign({}, session.transaction.options.writeConcern);
  } else if (session.clientOptions && session.clientOptions.writeConcern) {
    writeConcern = { w: session.clientOptions.writeConcern.w };
  }

  if (txnState === TxnState.TRANSACTION_COMMITTED) {
    writeConcern = Object.assign({ wtimeoutMS: 10000 }, writeConcern, { w: 'majority' });
  }

  if (writeConcern) {
    WriteConcern.apply(command, writeConcern);
  }

  if (commandName === 'commitTransaction' && session.transaction.options.maxTimeMS) {
    Object.assign(command, { maxTimeMS: session.transaction.options.maxTimeMS });
  }

  function commandHandler(error?: Error) {
    if (commandName !== 'commitTransaction') {
      session.transaction.transition(TxnState.TRANSACTION_ABORTED);
      if (session.loadBalanced) {
        maybeClearPinnedConnection(session, { force: false });
      }

      // The spec indicates that we should ignore all errors on `abortTransaction`
      return callback();
    }

    session.transaction.transition(TxnState.TRANSACTION_COMMITTED);
    if (error instanceof MongoError) {
      if (
        isRetryableWriteError(error) ||
        error instanceof MongoWriteConcernError ||
        isMaxTimeMSExpiredError(error)
      ) {
        if (isUnknownTransactionCommitResult(error)) {
          error.addErrorLabel(MongoErrorLabel.UnknownTransactionCommitResult);

          // per txns spec, must unpin session in this case
          session.unpin({ error });
        }
      } else if (error.hasErrorLabel(MongoErrorLabel.TransientTransactionError)) {
        session.unpin({ error });
      }
    }

    callback(error);
  }

  if (session.transaction.recoveryToken) {
    command.recoveryToken = session.transaction.recoveryToken;
  }

  const handleFirstCommandAttempt = (error?: Error) => {
    if (command.abortTransaction) {
      // always unpin on abort regardless of command outcome
      session.unpin();
    }

    if (error instanceof MongoError && isRetryableWriteError(error)) {
      // SPEC-1185: apply majority write concern when retrying commitTransaction
      if (command.commitTransaction) {
        // per txns spec, must unpin session in this case
        session.unpin({ force: true });

        command.writeConcern = Object.assign({ wtimeout: 10000 }, command.writeConcern, {
          w: 'majority'
        });
      }

      executeOperation(
        session.client,
        new RunAdminCommandOperation(command, {
          session,
          readPreference: ReadPreference.primary,
          bypassPinningCheck: true
        })
      ).then(() => commandHandler(), commandHandler);
      return;
    }

    commandHandler(error);
  };

  // send the command
  executeOperation(
    session.client,
    new RunAdminCommandOperation(command, {
      session,
      readPreference: ReadPreference.primary,
      bypassPinningCheck: true
    })
  ).then(() => handleFirstCommandAttempt(), handleFirstCommandAttempt);
}

/** @public */
export type ServerSessionId = { id: Binary };

/**
 * Reflects the existence of a session on the server. Can be reused by the session pool.
 * WARNING: not meant to be instantiated directly. For internal use only.
 * @public
 */
export class ServerSession {
  id: ServerSessionId;
  lastUse: number;
  txnNumber: number;
  isDirty: boolean;

  /** @internal */
  constructor() {
    this.id = { id: new Binary(uuidV4(), Binary.SUBTYPE_UUID) };
    this.lastUse = now();
    this.txnNumber = 0;
    this.isDirty = false;
  }

  /**
   * Determines if the server session has timed out.
   *
   * @param sessionTimeoutMinutes - The server's "logicalSessionTimeoutMinutes"
   */
  hasTimedOut(sessionTimeoutMinutes: number): boolean {
    // Take the difference of the lastUse timestamp and now, which will result in a value in
    // milliseconds, and then convert milliseconds to minutes to compare to `sessionTimeoutMinutes`
    const idleTimeMinutes = Math.round(
      ((calculateDurationInMs(this.lastUse) % 86400000) % 3600000) / 60000
    );

    return idleTimeMinutes > sessionTimeoutMinutes - 1;
  }

  /**
   * @internal
   * Cloning meant to keep a readable reference to the server session data
   * after ClientSession has ended
   */
  static clone(serverSession: ServerSession): Readonly<ServerSession> {
    const arrayBuffer = new ArrayBuffer(16);
    const idBytes = Buffer.from(arrayBuffer);
    idBytes.set(serverSession.id.id.buffer);

    const id = new Binary(idBytes, serverSession.id.id.sub_type);

    // Manual prototype construction to avoid modifying the constructor of this class
    return Object.setPrototypeOf(
      {
        id: { id },
        lastUse: serverSession.lastUse,
        txnNumber: serverSession.txnNumber,
        isDirty: serverSession.isDirty
      },
      ServerSession.prototype
    );
  }
}

/**
 * Maintains a pool of Server Sessions.
 * For internal use only
 * @internal
 */
export class ServerSessionPool {
  client: MongoClient;
  sessions: List<ServerSession>;

  constructor(client: MongoClient) {
    if (client == null) {
      throw new MongoRuntimeError('ServerSessionPool requires a MongoClient');
    }

    this.client = client;
    this.sessions = new List<ServerSession>();
  }

  /**
   * Acquire a Server Session from the pool.
   * Iterates through each session in the pool, removing any stale sessions
   * along the way. The first non-stale session found is removed from the
   * pool and returned. If no non-stale session is found, a new ServerSession is created.
   */
  acquire(): ServerSession {
    const sessionTimeoutMinutes = this.client.topology?.logicalSessionTimeoutMinutes ?? 10;

    let session: ServerSession | null = null;

    // Try to obtain from session pool
    while (this.sessions.length > 0) {
      const potentialSession = this.sessions.shift();
      if (
        potentialSession != null &&
        (!!this.client.topology?.loadBalanced ||
          !potentialSession.hasTimedOut(sessionTimeoutMinutes))
      ) {
        session = potentialSession;
        break;
      }
    }

    // If nothing valid came from the pool make a new one
    if (session == null) {
      session = new ServerSession();
    }

    return session;
  }

  /**
   * Release a session to the session pool
   * Adds the session back to the session pool if the session has not timed out yet.
   * This method also removes any stale sessions from the pool.
   *
   * @param session - The session to release to the pool
   */
  release(session: ServerSession): void {
    const sessionTimeoutMinutes = this.client.topology?.logicalSessionTimeoutMinutes ?? 10;

    if (this.client.topology?.loadBalanced && !sessionTimeoutMinutes) {
      this.sessions.unshift(session);
    }

    if (!sessionTimeoutMinutes) {
      return;
    }

    this.sessions.prune(session => session.hasTimedOut(sessionTimeoutMinutes));

    if (!session.hasTimedOut(sessionTimeoutMinutes)) {
      if (session.isDirty) {
        return;
      }

      // otherwise, readd this session to the session pool
      this.sessions.unshift(session);
    }
  }
}

/**
 * Optionally decorate a command with sessions specific keys
 *
 * @param session - the session tracking transaction state
 * @param command - the command to decorate
 * @param options - Optional settings passed to calling operation
 *
 * @internal
 */
export function applySession(
  session: ClientSession,
  command: Document,
  options: CommandOptions
): MongoDriverError | undefined {
  if (session.hasEnded) {
    return new MongoExpiredSessionError();
  }

  // May acquire serverSession here
  const serverSession = session.serverSession;
  if (serverSession == null) {
    return new MongoRuntimeError('Unable to acquire server session');
  }

  if (options.writeConcern?.w === 0) {
    if (session && session.explicit) {
      // Error if user provided an explicit session to an unacknowledged write (SPEC-1019)
      return new MongoAPIError('Cannot have explicit session with unacknowledged writes');
    }
    return;
  }

  // mark the last use of this session, and apply the `lsid`
  serverSession.lastUse = now();
  command.lsid = serverSession.id;

  const inTxnOrTxnCommand = session.inTransaction() || isTransactionCommand(command);
  const isRetryableWrite = !!options.willRetryWrite;

  if (isRetryableWrite || inTxnOrTxnCommand) {
    serverSession.txnNumber += session[kTxnNumberIncrement];
    session[kTxnNumberIncrement] = 0;
    // TODO(NODE-2674): Preserve int64 sent from MongoDB
    command.txnNumber = Long.fromNumber(serverSession.txnNumber);
  }

  if (!inTxnOrTxnCommand) {
    if (session.transaction.state !== TxnState.NO_TRANSACTION) {
      session.transaction.transition(TxnState.NO_TRANSACTION);
    }

    if (
      session.supports.causalConsistency &&
      session.operationTime &&
      commandSupportsReadConcern(command)
    ) {
      command.readConcern = command.readConcern || {};
      Object.assign(command.readConcern, { afterClusterTime: session.operationTime });
    } else if (session[kSnapshotEnabled]) {
      command.readConcern = command.readConcern || { level: ReadConcernLevel.snapshot };
      if (session[kSnapshotTime] != null) {
        Object.assign(command.readConcern, { atClusterTime: session[kSnapshotTime] });
      }
    }

    return;
  }

  // now attempt to apply transaction-specific sessions data

  // `autocommit` must always be false to differentiate from retryable writes
  command.autocommit = false;

  if (session.transaction.state === TxnState.STARTING_TRANSACTION) {
    session.transaction.transition(TxnState.TRANSACTION_IN_PROGRESS);
    command.startTransaction = true;

    const readConcern =
      session.transaction.options.readConcern || session?.clientOptions?.readConcern;
    if (readConcern) {
      command.readConcern = readConcern;
    }

    if (session.supports.causalConsistency && session.operationTime) {
      command.readConcern = command.readConcern || {};
      Object.assign(command.readConcern, { afterClusterTime: session.operationTime });
    }
  }
  return;
}

export function updateSessionFromResponse(session: ClientSession, document: Document): void {
  if (document.$clusterTime) {
    _advanceClusterTime(session, document.$clusterTime);
  }

  if (document.operationTime && session && session.supports.causalConsistency) {
    session.advanceOperationTime(document.operationTime);
  }

  if (document.recoveryToken && session && session.inTransaction()) {
    session.transaction._recoveryToken = document.recoveryToken;
  }

  if (session?.[kSnapshotEnabled] && session[kSnapshotTime] == null) {
    // find and aggregate commands return atClusterTime on the cursor
    // distinct includes it in the response body
    const atClusterTime = document.cursor?.atClusterTime || document.atClusterTime;
    if (atClusterTime) {
      session[kSnapshotTime] = atClusterTime;
    }
  }
}
