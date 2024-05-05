import type { Document } from '../bson';
import {
  isRetryableReadError,
  isRetryableWriteError,
  MongoCompatibilityError,
  MONGODB_ERROR_CODES,
  MongoError,
  MongoErrorLabel,
  MongoExpiredSessionError,
  MongoInvalidArgumentError,
  MongoNetworkError,
  MongoNotConnectedError,
  MongoRuntimeError,
  MongoServerError,
  MongoTransactionError,
  MongoUnexpectedServerResponseError
} from '../error';
import type { MongoClient } from '../mongo_client';
import { ReadPreference } from '../read_preference';
import type { Server } from '../sdam/server';
import type { ServerDescription } from '../sdam/server_description';
import {
  sameServerSelector,
  secondaryWritableServerSelector,
  type ServerSelector
} from '../sdam/server_selection';
import type { Topology } from '../sdam/topology';
import type { ClientSession } from '../sessions';
import { supportsRetryableWrites } from '../utils';
import { AbstractOperation, Aspect } from './operation';

const MMAPv1_RETRY_WRITES_ERROR_CODE = MONGODB_ERROR_CODES.IllegalOperation;
const MMAPv1_RETRY_WRITES_ERROR_MESSAGE =
  'This MongoDB deployment does not support retryable writes. Please add retryWrites=false to your connection string.';

type ResultTypeFromOperation<TOperation> = TOperation extends AbstractOperation<infer K>
  ? K
  : never;

/** @internal */
export interface ExecutionResult {
  /** The server selected for the operation */
  server: Server;
  /** The session used for this operation, may be implicitly created */
  session?: ClientSession;
  /** The raw server response for the operation */
  response: Document;
}

/**
 * Executes the given operation with provided arguments.
 * @internal
 *
 * @remarks
 * Allows for a single point of entry to provide features such as implicit sessions, which
 * are required by the Driver Sessions specification in the event that a ClientSession is
 * not provided.
 *
 * The expectation is that this function:
 * - Connects the MongoClient if it has not already been connected
 * - Creates a session if none is provided and cleans up the session it creates
 * - Selects a server based on readPreference or various factors
 * - Retries an operation if it fails for certain errors, see {@link retryOperation}
 *
 * @typeParam T - The operation's type
 * @typeParam TResult - The type of the operation's result, calculated from T
 *
 * @param client - The MongoClient to execute this operation with
 * @param operation - The operation to execute
 */
export async function executeOperation<
  T extends AbstractOperation<TResult>,
  TResult = ResultTypeFromOperation<T>
>(client: MongoClient, operation: T): Promise<TResult> {
  if (!(operation instanceof AbstractOperation)) {
    // TODO(NODE-3483): Extend MongoRuntimeError
    throw new MongoRuntimeError('This method requires a valid operation instance');
  }

  if (client.topology == null) {
    // Auto connect on operation
    if (client.s.hasBeenClosed) {
      throw new MongoNotConnectedError('Client must be connected before running operations');
    }
    client.s.options[Symbol.for('@@mdb.skipPingOnConnect')] = true;
    try {
      await client.connect();
    } finally {
      delete client.s.options[Symbol.for('@@mdb.skipPingOnConnect')];
    }
  }

  const { topology } = client;
  if (topology == null) {
    throw new MongoRuntimeError('client.connect did not create a topology but also did not throw');
  }

  // The driver sessions spec mandates that we implicitly create sessions for operations
  // that are not explicitly provided with a session.
  let session = operation.session;
  let owner: symbol | undefined;

  if (session == null) {
    owner = Symbol();
    session = client.startSession({ owner, explicit: false });
  } else if (session.hasEnded) {
    throw new MongoExpiredSessionError('Use of expired sessions is not permitted');
  } else if (session.snapshotEnabled && !topology.capabilities.supportsSnapshotReads) {
    throw new MongoCompatibilityError('Snapshot reads require MongoDB 5.0 or later');
  } else if (session.client !== client) {
    throw new MongoInvalidArgumentError('ClientSession must be from the same MongoClient');
  }

  const readPreference = operation.readPreference ?? ReadPreference.primary;
  const inTransaction = !!session?.inTransaction();

  if (inTransaction && !readPreference.equals(ReadPreference.primary)) {
    throw new MongoTransactionError(
      `Read preference in a transaction must be primary, not: ${readPreference.mode}`
    );
  }

  if (session?.isPinned && session.transaction.isCommitted && !operation.bypassPinningCheck) {
    session.unpin();
  }

  let selector: ReadPreference | ServerSelector;

  if (operation.hasAspect(Aspect.MUST_SELECT_SAME_SERVER)) {
    // GetMore and KillCursor operations must always select the same server, but run through
    // server selection to potentially force monitor checks if the server is
    // in an unknown state.
    selector = sameServerSelector(operation.server?.description);
  } else if (operation.trySecondaryWrite) {
    // If operation should try to write to secondary use the custom server selector
    // otherwise provide the read preference.
    selector = secondaryWritableServerSelector(topology.commonWireVersion, readPreference);
  } else {
    selector = readPreference;
  }

  const server = await topology.selectServerAsync(selector, {
    session,
    operationName: operation.commandName
  });

  if (session == null) {
    // No session also means it is not retryable, early exit
    return operation.execute(server, undefined);
  }

  if (!operation.hasAspect(Aspect.RETRYABLE)) {
    // non-retryable operation, early exit
    try {
      return await operation.execute(server, session);
    } finally {
      if (session?.owner != null && session.owner === owner) {
        await session.endSession().catch(() => null);
      }
    }
  }

  const willRetryRead = topology.s.options.retryReads && !inTransaction && operation.canRetryRead;

  const willRetryWrite =
    topology.s.options.retryWrites &&
    !inTransaction &&
    supportsRetryableWrites(server) &&
    operation.canRetryWrite;

  const hasReadAspect = operation.hasAspect(Aspect.READ_OPERATION);
  const hasWriteAspect = operation.hasAspect(Aspect.WRITE_OPERATION);
  const willRetry = (hasReadAspect && willRetryRead) || (hasWriteAspect && willRetryWrite);

  if (hasWriteAspect && willRetryWrite) {
    operation.options.willRetryWrite = true;
    session.incrementTransactionNumber();
  }

  try {
    return await operation.execute(server, session);
  } catch (operationError) {
    if (willRetry && operationError instanceof MongoError) {
      return await retryOperation(operation, operationError, {
        session,
        topology,
        selector,
        previousServer: server.description
      });
    }
    throw operationError;
  } finally {
    if (session?.owner != null && session.owner === owner) {
      await session.endSession().catch(() => null);
    }
  }
}

/** @internal */
type RetryOptions = {
  session: ClientSession;
  topology: Topology;
  selector: ReadPreference | ServerSelector;
  previousServer: ServerDescription;
};

async function retryOperation<
  T extends AbstractOperation<TResult>,
  TResult = ResultTypeFromOperation<T>
>(
  operation: T,
  originalError: MongoError,
  { session, topology, selector, previousServer }: RetryOptions
): Promise<TResult> {
  const isWriteOperation = operation.hasAspect(Aspect.WRITE_OPERATION);
  const isReadOperation = operation.hasAspect(Aspect.READ_OPERATION);

  if (isWriteOperation && originalError.code === MMAPv1_RETRY_WRITES_ERROR_CODE) {
    throw new MongoServerError({
      message: MMAPv1_RETRY_WRITES_ERROR_MESSAGE,
      errmsg: MMAPv1_RETRY_WRITES_ERROR_MESSAGE,
      originalError
    });
  }

  if (isWriteOperation && !isRetryableWriteError(originalError)) {
    throw originalError;
  }

  if (isReadOperation && !isRetryableReadError(originalError)) {
    throw originalError;
  }

  if (
    originalError instanceof MongoNetworkError &&
    session.isPinned &&
    !session.inTransaction() &&
    operation.hasAspect(Aspect.CURSOR_CREATING)
  ) {
    // If we have a cursor and the initial command fails with a network error,
    // we can retry it on another connection. So we need to check it back in, clear the
    // pool for the service id, and retry again.
    session.unpin({ force: true, forceClear: true });
  }

  // select a new server, and attempt to retry the operation
  const server = await topology.selectServerAsync(selector, {
    session,
    operationName: operation.commandName,
    previousServer
  });

  if (isWriteOperation && !supportsRetryableWrites(server)) {
    throw new MongoUnexpectedServerResponseError(
      'Selected server does not support retryable writes'
    );
  }

  try {
    return await operation.execute(server, session);
  } catch (retryError) {
    if (
      retryError instanceof MongoError &&
      retryError.hasErrorLabel(MongoErrorLabel.NoWritesPerformed)
    ) {
      throw originalError;
    }
    throw retryError;
  }
}
