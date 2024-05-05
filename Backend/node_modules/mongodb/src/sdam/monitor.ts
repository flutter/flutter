import { clearTimeout, setTimeout } from 'timers';

import { type Document, Long } from '../bson';
import { connect, makeConnection, makeSocket, performInitialHandshake } from '../cmap/connect';
import type { Connection, ConnectionOptions } from '../cmap/connection';
import { getFAASEnv } from '../cmap/handshake/client_metadata';
import { LEGACY_HELLO_COMMAND } from '../constants';
import { MongoError, MongoErrorLabel, MongoNetworkTimeoutError } from '../error';
import { MongoLoggableComponent } from '../mongo_logger';
import { CancellationToken, TypedEventEmitter } from '../mongo_types';
import type { Callback, EventEmitterWithState } from '../utils';
import { calculateDurationInMs, makeStateMachine, now, ns } from '../utils';
import { ServerType, STATE_CLOSED, STATE_CLOSING } from './common';
import {
  ServerHeartbeatFailedEvent,
  ServerHeartbeatStartedEvent,
  ServerHeartbeatSucceededEvent
} from './events';
import { Server } from './server';
import type { TopologyVersion } from './server_description';

/** @internal */
const kServer = Symbol('server');
/** @internal */
const kMonitorId = Symbol('monitorId');
/** @internal */
const kCancellationToken = Symbol('cancellationToken');
/** @internal */
const kRoundTripTime = Symbol('roundTripTime');

const STATE_IDLE = 'idle';
const STATE_MONITORING = 'monitoring';
const stateTransition = makeStateMachine({
  [STATE_CLOSING]: [STATE_CLOSING, STATE_IDLE, STATE_CLOSED],
  [STATE_CLOSED]: [STATE_CLOSED, STATE_MONITORING],
  [STATE_IDLE]: [STATE_IDLE, STATE_MONITORING, STATE_CLOSING],
  [STATE_MONITORING]: [STATE_MONITORING, STATE_IDLE, STATE_CLOSING]
});

const INVALID_REQUEST_CHECK_STATES = new Set([STATE_CLOSING, STATE_CLOSED, STATE_MONITORING]);
function isInCloseState(monitor: Monitor) {
  return monitor.s.state === STATE_CLOSED || monitor.s.state === STATE_CLOSING;
}

/** @public */
export const ServerMonitoringMode = Object.freeze({
  auto: 'auto',
  poll: 'poll',
  stream: 'stream'
} as const);

/** @public */
export type ServerMonitoringMode = (typeof ServerMonitoringMode)[keyof typeof ServerMonitoringMode];

/** @internal */
export interface MonitorPrivate {
  state: string;
}

/** @public */
export interface MonitorOptions
  extends Omit<ConnectionOptions, 'id' | 'generation' | 'hostAddress'> {
  connectTimeoutMS: number;
  heartbeatFrequencyMS: number;
  minHeartbeatFrequencyMS: number;
  serverMonitoringMode: ServerMonitoringMode;
}

/** @public */
export type MonitorEvents = {
  serverHeartbeatStarted(event: ServerHeartbeatStartedEvent): void;
  serverHeartbeatSucceeded(event: ServerHeartbeatSucceededEvent): void;
  serverHeartbeatFailed(event: ServerHeartbeatFailedEvent): void;
  resetServer(error?: MongoError): void;
  resetConnectionPool(): void;
  close(): void;
} & EventEmitterWithState;

/** @internal */
export class Monitor extends TypedEventEmitter<MonitorEvents> {
  /** @internal */
  s: MonitorPrivate;
  address: string;
  options: Readonly<
    Pick<
      MonitorOptions,
      | 'connectTimeoutMS'
      | 'heartbeatFrequencyMS'
      | 'minHeartbeatFrequencyMS'
      | 'serverMonitoringMode'
    >
  >;
  connectOptions: ConnectionOptions;
  isRunningInFaasEnv: boolean;
  [kServer]: Server;
  connection: Connection | null;
  [kCancellationToken]: CancellationToken;
  /** @internal */
  [kMonitorId]?: MonitorInterval;
  rttPinger?: RTTPinger;
  /** @internal */
  override component = MongoLoggableComponent.TOPOLOGY;

  constructor(server: Server, options: MonitorOptions) {
    super();

    this[kServer] = server;
    this.connection = null;
    this[kCancellationToken] = new CancellationToken();
    this[kCancellationToken].setMaxListeners(Infinity);
    this[kMonitorId] = undefined;
    this.s = {
      state: STATE_CLOSED
    };
    this.address = server.description.address;
    this.options = Object.freeze({
      connectTimeoutMS: options.connectTimeoutMS ?? 10000,
      heartbeatFrequencyMS: options.heartbeatFrequencyMS ?? 10000,
      minHeartbeatFrequencyMS: options.minHeartbeatFrequencyMS ?? 500,
      serverMonitoringMode: options.serverMonitoringMode
    });
    this.isRunningInFaasEnv = getFAASEnv() != null;
    this.mongoLogger = this[kServer].topology.client?.mongoLogger;

    const cancellationToken = this[kCancellationToken];
    // TODO: refactor this to pull it directly from the pool, requires new ConnectionPool integration
    const connectOptions = {
      id: '<monitor>' as const,
      generation: server.pool.generation,
      cancellationToken,
      hostAddress: server.description.hostAddress,
      ...options,
      // force BSON serialization options
      raw: false,
      useBigInt64: false,
      promoteLongs: true,
      promoteValues: true,
      promoteBuffers: true
    };

    // ensure no authentication is used for monitoring
    delete connectOptions.credentials;
    if (connectOptions.autoEncrypter) {
      delete connectOptions.autoEncrypter;
    }

    this.connectOptions = Object.freeze(connectOptions);
  }

  connect(): void {
    if (this.s.state !== STATE_CLOSED) {
      return;
    }

    // start
    const heartbeatFrequencyMS = this.options.heartbeatFrequencyMS;
    const minHeartbeatFrequencyMS = this.options.minHeartbeatFrequencyMS;
    this[kMonitorId] = new MonitorInterval(monitorServer(this), {
      heartbeatFrequencyMS: heartbeatFrequencyMS,
      minHeartbeatFrequencyMS: minHeartbeatFrequencyMS,
      immediate: true
    });
  }

  requestCheck(): void {
    if (INVALID_REQUEST_CHECK_STATES.has(this.s.state)) {
      return;
    }

    this[kMonitorId]?.wake();
  }

  reset(): void {
    const topologyVersion = this[kServer].description.topologyVersion;
    if (isInCloseState(this) || topologyVersion == null) {
      return;
    }

    stateTransition(this, STATE_CLOSING);
    resetMonitorState(this);

    // restart monitor
    stateTransition(this, STATE_IDLE);

    // restart monitoring
    const heartbeatFrequencyMS = this.options.heartbeatFrequencyMS;
    const minHeartbeatFrequencyMS = this.options.minHeartbeatFrequencyMS;
    this[kMonitorId] = new MonitorInterval(monitorServer(this), {
      heartbeatFrequencyMS: heartbeatFrequencyMS,
      minHeartbeatFrequencyMS: minHeartbeatFrequencyMS
    });
  }

  close(): void {
    if (isInCloseState(this)) {
      return;
    }

    stateTransition(this, STATE_CLOSING);
    resetMonitorState(this);

    // close monitor
    this.emit('close');
    stateTransition(this, STATE_CLOSED);
  }
}

function resetMonitorState(monitor: Monitor) {
  monitor[kMonitorId]?.stop();
  monitor[kMonitorId] = undefined;

  monitor.rttPinger?.close();
  monitor.rttPinger = undefined;

  monitor[kCancellationToken].emit('cancel');

  monitor.connection?.destroy();
  monitor.connection = null;
}

function useStreamingProtocol(monitor: Monitor, topologyVersion: TopologyVersion | null): boolean {
  // If we have no topology version we always poll no matter
  // what the user provided, since the server does not support
  // the streaming protocol.
  if (topologyVersion == null) return false;

  const serverMonitoringMode = monitor.options.serverMonitoringMode;
  if (serverMonitoringMode === ServerMonitoringMode.poll) return false;
  if (serverMonitoringMode === ServerMonitoringMode.stream) return true;

  // If we are in auto mode, we need to figure out if we're in a FaaS
  // environment or not and choose the appropriate mode.
  if (monitor.isRunningInFaasEnv) return false;
  return true;
}

function checkServer(monitor: Monitor, callback: Callback<Document | null>) {
  let start: number;
  let awaited: boolean;
  const topologyVersion = monitor[kServer].description.topologyVersion;
  const isAwaitable = useStreamingProtocol(monitor, topologyVersion);
  monitor.emitAndLogHeartbeat(
    Server.SERVER_HEARTBEAT_STARTED,
    monitor[kServer].topology.s.id,
    undefined,
    new ServerHeartbeatStartedEvent(monitor.address, isAwaitable)
  );

  function onHeartbeatFailed(err: Error) {
    monitor.connection?.destroy();
    monitor.connection = null;

    monitor.emitAndLogHeartbeat(
      Server.SERVER_HEARTBEAT_FAILED,
      monitor[kServer].topology.s.id,
      undefined,
      new ServerHeartbeatFailedEvent(monitor.address, calculateDurationInMs(start), err, awaited)
    );

    const error = !(err instanceof MongoError)
      ? new MongoError(MongoError.buildErrorMessage(err), { cause: err })
      : err;
    error.addErrorLabel(MongoErrorLabel.ResetPool);
    if (error instanceof MongoNetworkTimeoutError) {
      error.addErrorLabel(MongoErrorLabel.InterruptInUseConnections);
    }

    monitor.emit('resetServer', error);
    callback(err);
  }

  function onHeartbeatSucceeded(hello: Document) {
    if (!('isWritablePrimary' in hello)) {
      // Provide hello-style response document.
      hello.isWritablePrimary = hello[LEGACY_HELLO_COMMAND];
    }

    const duration =
      isAwaitable && monitor.rttPinger
        ? monitor.rttPinger.roundTripTime
        : calculateDurationInMs(start);

    monitor.emitAndLogHeartbeat(
      Server.SERVER_HEARTBEAT_SUCCEEDED,
      monitor[kServer].topology.s.id,
      hello.connectionId,
      new ServerHeartbeatSucceededEvent(monitor.address, duration, hello, isAwaitable)
    );

    if (isAwaitable) {
      // If we are using the streaming protocol then we immediately issue another 'started'
      // event, otherwise the "check" is complete and return to the main monitor loop
      monitor.emitAndLogHeartbeat(
        Server.SERVER_HEARTBEAT_STARTED,
        monitor[kServer].topology.s.id,
        undefined,
        new ServerHeartbeatStartedEvent(monitor.address, true)
      );
      // We have not actually sent an outgoing handshake, but when we get the next response we
      // want the duration to reflect the time since we last heard from the server
      start = now();
    } else {
      monitor.rttPinger?.close();
      monitor.rttPinger = undefined;

      callback(undefined, hello);
    }
  }

  const { connection } = monitor;
  if (connection && !connection.closed) {
    const { serverApi, helloOk } = connection;
    const connectTimeoutMS = monitor.options.connectTimeoutMS;
    const maxAwaitTimeMS = monitor.options.heartbeatFrequencyMS;

    const cmd = {
      [serverApi?.version || helloOk ? 'hello' : LEGACY_HELLO_COMMAND]: 1,
      ...(isAwaitable && topologyVersion
        ? { maxAwaitTimeMS, topologyVersion: makeTopologyVersion(topologyVersion) }
        : {})
    };

    const options = isAwaitable
      ? {
          socketTimeoutMS: connectTimeoutMS ? connectTimeoutMS + maxAwaitTimeMS : 0,
          exhaustAllowed: true
        }
      : { socketTimeoutMS: connectTimeoutMS };

    if (isAwaitable && monitor.rttPinger == null) {
      monitor.rttPinger = new RTTPinger(
        monitor[kCancellationToken],
        Object.assign(
          { heartbeatFrequencyMS: monitor.options.heartbeatFrequencyMS },
          monitor.connectOptions
        )
      );
    }

    // Record new start time before sending handshake
    start = now();

    if (isAwaitable) {
      awaited = true;
      return connection.exhaustCommand(ns('admin.$cmd'), cmd, options, (error, hello) => {
        if (error) return onHeartbeatFailed(error);
        return onHeartbeatSucceeded(hello);
      });
    }

    awaited = false;
    connection
      .command(ns('admin.$cmd'), cmd, options)
      .then(onHeartbeatSucceeded, onHeartbeatFailed);

    return;
  }

  // connecting does an implicit `hello`
  (async () => {
    const socket = await makeSocket(monitor.connectOptions);
    const connection = makeConnection(monitor.connectOptions, socket);
    // The start time is after socket creation but before the handshake
    start = now();
    try {
      await performInitialHandshake(connection, monitor.connectOptions);
      return connection;
    } catch (error) {
      connection.destroy();
      throw error;
    }
  })().then(
    connection => {
      if (isInCloseState(monitor)) {
        connection.destroy();
        return;
      }

      monitor.connection = connection;
      monitor.emitAndLogHeartbeat(
        Server.SERVER_HEARTBEAT_SUCCEEDED,
        monitor[kServer].topology.s.id,
        connection.hello?.connectionId,
        new ServerHeartbeatSucceededEvent(
          monitor.address,
          calculateDurationInMs(start),
          connection.hello,
          useStreamingProtocol(monitor, connection.hello?.topologyVersion)
        )
      );

      callback(undefined, connection.hello);
    },
    error => {
      monitor.connection = null;
      awaited = false;
      onHeartbeatFailed(error);
    }
  );
}

function monitorServer(monitor: Monitor) {
  return (callback: Callback) => {
    if (monitor.s.state === STATE_MONITORING) {
      process.nextTick(callback);
      return;
    }
    stateTransition(monitor, STATE_MONITORING);
    function done() {
      if (!isInCloseState(monitor)) {
        stateTransition(monitor, STATE_IDLE);
      }

      callback();
    }

    checkServer(monitor, (err, hello) => {
      if (err) {
        // otherwise an error occurred on initial discovery, also bail
        if (monitor[kServer].description.type === ServerType.Unknown) {
          return done();
        }
      }

      // if the check indicates streaming is supported, immediately reschedule monitoring
      if (useStreamingProtocol(monitor, hello?.topologyVersion)) {
        setTimeout(() => {
          if (!isInCloseState(monitor)) {
            monitor[kMonitorId]?.wake();
          }
        }, 0);
      }

      done();
    });
  };
}

function makeTopologyVersion(tv: TopologyVersion) {
  return {
    processId: tv.processId,
    // tests mock counter as just number, but in a real situation counter should always be a Long
    // TODO(NODE-2674): Preserve int64 sent from MongoDB
    counter: Long.isLong(tv.counter) ? tv.counter : Long.fromNumber(tv.counter)
  };
}

/** @internal */
export interface RTTPingerOptions extends ConnectionOptions {
  heartbeatFrequencyMS: number;
}

/** @internal */
export class RTTPinger {
  connection?: Connection;
  /** @internal */
  [kCancellationToken]: CancellationToken;
  /** @internal */
  [kRoundTripTime]: number;
  /** @internal */
  [kMonitorId]: NodeJS.Timeout;
  closed: boolean;

  constructor(cancellationToken: CancellationToken, options: RTTPingerOptions) {
    this.connection = undefined;
    this[kCancellationToken] = cancellationToken;
    this[kRoundTripTime] = 0;
    this.closed = false;

    const heartbeatFrequencyMS = options.heartbeatFrequencyMS;
    this[kMonitorId] = setTimeout(() => measureRoundTripTime(this, options), heartbeatFrequencyMS);
  }

  get roundTripTime(): number {
    return this[kRoundTripTime];
  }

  close(): void {
    this.closed = true;
    clearTimeout(this[kMonitorId]);

    this.connection?.destroy();
    this.connection = undefined;
  }
}

function measureRoundTripTime(rttPinger: RTTPinger, options: RTTPingerOptions) {
  const start = now();
  options.cancellationToken = rttPinger[kCancellationToken];
  const heartbeatFrequencyMS = options.heartbeatFrequencyMS;

  if (rttPinger.closed) {
    return;
  }

  function measureAndReschedule(conn?: Connection) {
    if (rttPinger.closed) {
      conn?.destroy();
      return;
    }

    if (rttPinger.connection == null) {
      rttPinger.connection = conn;
    }

    rttPinger[kRoundTripTime] = calculateDurationInMs(start);
    rttPinger[kMonitorId] = setTimeout(
      () => measureRoundTripTime(rttPinger, options),
      heartbeatFrequencyMS
    );
  }

  const connection = rttPinger.connection;
  if (connection == null) {
    connect(options).then(
      connection => {
        measureAndReschedule(connection);
      },
      () => {
        rttPinger.connection = undefined;
        rttPinger[kRoundTripTime] = 0;
      }
    );
    return;
  }

  const commandName =
    connection.serverApi?.version || connection.helloOk ? 'hello' : LEGACY_HELLO_COMMAND;
  connection.command(ns('admin.$cmd'), { [commandName]: 1 }, undefined).then(
    () => measureAndReschedule(),
    () => {
      rttPinger.connection?.destroy();
      rttPinger.connection = undefined;
      rttPinger[kRoundTripTime] = 0;
      return;
    }
  );
}

/**
 * @internal
 */
export interface MonitorIntervalOptions {
  /** The interval to execute a method on */
  heartbeatFrequencyMS: number;
  /** A minimum interval that must elapse before the method is called */
  minHeartbeatFrequencyMS: number;
  /** Whether the method should be called immediately when the interval is started  */
  immediate: boolean;
}

/**
 * @internal
 */
export class MonitorInterval {
  fn: (callback: Callback) => void;
  timerId: NodeJS.Timeout | undefined;
  lastExecutionEnded: number;
  isExpeditedCallToFnScheduled = false;
  stopped = false;
  isExecutionInProgress = false;
  hasExecutedOnce = false;

  heartbeatFrequencyMS: number;
  minHeartbeatFrequencyMS: number;

  constructor(fn: (callback: Callback) => void, options: Partial<MonitorIntervalOptions> = {}) {
    this.fn = fn;
    this.lastExecutionEnded = -Infinity;

    this.heartbeatFrequencyMS = options.heartbeatFrequencyMS ?? 1000;
    this.minHeartbeatFrequencyMS = options.minHeartbeatFrequencyMS ?? 500;

    if (options.immediate) {
      this._executeAndReschedule();
    } else {
      this._reschedule(undefined);
    }
  }

  wake() {
    const currentTime = now();
    const timeSinceLastCall = currentTime - this.lastExecutionEnded;

    // TODO(NODE-4674): Add error handling and logging to the monitor
    if (timeSinceLastCall < 0) {
      return this._executeAndReschedule();
    }

    if (this.isExecutionInProgress) {
      return;
    }

    // debounce multiple calls to wake within the `minInterval`
    if (this.isExpeditedCallToFnScheduled) {
      return;
    }

    // reschedule a call as soon as possible, ensuring the call never happens
    // faster than the `minInterval`
    if (timeSinceLastCall < this.minHeartbeatFrequencyMS) {
      this.isExpeditedCallToFnScheduled = true;
      this._reschedule(this.minHeartbeatFrequencyMS - timeSinceLastCall);
      return;
    }

    this._executeAndReschedule();
  }

  stop() {
    this.stopped = true;
    if (this.timerId) {
      clearTimeout(this.timerId);
      this.timerId = undefined;
    }

    this.lastExecutionEnded = -Infinity;
    this.isExpeditedCallToFnScheduled = false;
  }

  toString() {
    return JSON.stringify(this);
  }

  toJSON() {
    const currentTime = now();
    const timeSinceLastCall = currentTime - this.lastExecutionEnded;
    return {
      timerId: this.timerId != null ? 'set' : 'cleared',
      lastCallTime: this.lastExecutionEnded,
      isExpeditedCheckScheduled: this.isExpeditedCallToFnScheduled,
      stopped: this.stopped,
      heartbeatFrequencyMS: this.heartbeatFrequencyMS,
      minHeartbeatFrequencyMS: this.minHeartbeatFrequencyMS,
      currentTime,
      timeSinceLastCall
    };
  }

  private _reschedule(ms?: number) {
    if (this.stopped) return;
    if (this.timerId) {
      clearTimeout(this.timerId);
    }

    this.timerId = setTimeout(this._executeAndReschedule, ms || this.heartbeatFrequencyMS);
  }

  private _executeAndReschedule = () => {
    if (this.stopped) return;
    if (this.timerId) {
      clearTimeout(this.timerId);
    }

    this.isExpeditedCallToFnScheduled = false;
    this.isExecutionInProgress = true;

    this.fn(() => {
      this.lastExecutionEnded = now();
      this.isExecutionInProgress = false;
      this._reschedule(this.heartbeatFrequencyMS);
    });
  };
}
