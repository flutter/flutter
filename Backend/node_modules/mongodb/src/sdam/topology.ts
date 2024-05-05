import { promisify } from 'util';

import type { BSONSerializeOptions, Document } from '../bson';
import type { MongoCredentials } from '../cmap/auth/mongo_credentials';
import type { ConnectionEvents } from '../cmap/connection';
import type { ConnectionPoolEvents } from '../cmap/connection_pool';
import type { ClientMetadata } from '../cmap/handshake/client_metadata';
import { DEFAULT_OPTIONS, FEATURE_FLAGS } from '../connection_string';
import {
  CLOSE,
  CONNECT,
  ERROR,
  LOCAL_SERVER_EVENTS,
  OPEN,
  SERVER_CLOSED,
  SERVER_DESCRIPTION_CHANGED,
  SERVER_OPENING,
  SERVER_RELAY_EVENTS,
  TIMEOUT,
  TOPOLOGY_CLOSED,
  TOPOLOGY_DESCRIPTION_CHANGED,
  TOPOLOGY_OPENING
} from '../constants';
import {
  MongoCompatibilityError,
  type MongoDriverError,
  MongoError,
  MongoErrorLabel,
  MongoRuntimeError,
  MongoServerSelectionError,
  MongoTopologyClosedError
} from '../error';
import type { MongoClient, ServerApi } from '../mongo_client';
import { MongoLoggableComponent, type MongoLogger, SeverityLevel } from '../mongo_logger';
import { TypedEventEmitter } from '../mongo_types';
import { ReadPreference, type ReadPreferenceLike } from '../read_preference';
import type { ClientSession } from '../sessions';
import type { Transaction } from '../transactions';
import {
  type Callback,
  type EventEmitterWithState,
  HostAddress,
  List,
  makeStateMachine,
  now,
  ns,
  shuffle,
  TimeoutController
} from '../utils';
import {
  _advanceClusterTime,
  type ClusterTime,
  drainTimerQueue,
  ServerType,
  STATE_CLOSED,
  STATE_CLOSING,
  STATE_CONNECTED,
  STATE_CONNECTING,
  type TimerQueue,
  TopologyType
} from './common';
import {
  ServerClosedEvent,
  ServerDescriptionChangedEvent,
  ServerOpeningEvent,
  TopologyClosedEvent,
  TopologyDescriptionChangedEvent,
  TopologyOpeningEvent
} from './events';
import type { ServerMonitoringMode } from './monitor';
import { Server, type ServerEvents, type ServerOptions } from './server';
import { compareTopologyVersion, ServerDescription } from './server_description';
import { readPreferenceServerSelector, type ServerSelector } from './server_selection';
import {
  ServerSelectionFailedEvent,
  ServerSelectionStartedEvent,
  ServerSelectionSucceededEvent,
  WaitingForSuitableServerEvent
} from './server_selection_events';
import { SrvPoller, type SrvPollingEvent } from './srv_polling';
import { TopologyDescription } from './topology_description';

// Global state
let globalTopologyCounter = 0;

const stateTransition = makeStateMachine({
  [STATE_CLOSED]: [STATE_CLOSED, STATE_CONNECTING],
  [STATE_CONNECTING]: [STATE_CONNECTING, STATE_CLOSING, STATE_CONNECTED, STATE_CLOSED],
  [STATE_CONNECTED]: [STATE_CONNECTED, STATE_CLOSING, STATE_CLOSED],
  [STATE_CLOSING]: [STATE_CLOSING, STATE_CLOSED]
});

/** @internal */
const kCancelled = Symbol('cancelled');
/** @internal */
const kWaitQueue = Symbol('waitQueue');

/** @internal */
export type ServerSelectionCallback = Callback<Server>;

/** @internal */
export interface ServerSelectionRequest {
  serverSelector: ServerSelector;
  topologyDescription: TopologyDescription;
  mongoLogger: MongoLogger | undefined;
  transaction?: Transaction;
  startTime: number;
  callback: ServerSelectionCallback;
  [kCancelled]?: boolean;
  timeoutController: TimeoutController;
  operationName: string;
  waitingLogged: boolean;
  previousServer?: ServerDescription;
}

/** @internal */
export interface TopologyPrivate {
  /** the id of this topology */
  id: number;
  /** passed in options */
  options: TopologyOptions;
  /** initial seedlist of servers to connect to */
  seedlist: HostAddress[];
  /** initial state */
  state: string;
  /** the topology description */
  description: TopologyDescription;
  serverSelectionTimeoutMS: number;
  heartbeatFrequencyMS: number;
  minHeartbeatFrequencyMS: number;
  /** A map of server instances to normalized addresses */
  servers: Map<string, Server>;
  credentials?: MongoCredentials;
  clusterTime?: ClusterTime;
  /** timers created for the initial connect to a server */
  connectionTimers: TimerQueue;

  /** related to srv polling */
  srvPoller?: SrvPoller;
  detectShardedTopology: (event: TopologyDescriptionChangedEvent) => void;
  detectSrvRecords: (event: SrvPollingEvent) => void;
}

/** @internal */
export interface TopologyOptions extends BSONSerializeOptions, ServerOptions {
  srvMaxHosts: number;
  srvServiceName: string;
  hosts: HostAddress[];
  retryWrites: boolean;
  retryReads: boolean;
  /** How long to block for server selection before throwing an error */
  serverSelectionTimeoutMS: number;
  /** The name of the replica set to connect to */
  replicaSet?: string;
  srvHost?: string;
  srvPoller?: SrvPoller;
  /** Indicates that a client should directly connect to a node without attempting to discover its topology type */
  directConnection: boolean;
  loadBalanced: boolean;
  metadata: ClientMetadata;
  extendedMetadata: Promise<Document>;
  serverMonitoringMode: ServerMonitoringMode;
  /** MongoDB server API version */
  serverApi?: ServerApi;
  [featureFlag: symbol]: any;
}

/** @public */
export interface ConnectOptions {
  readPreference?: ReadPreference;
}

/** @public */
export interface SelectServerOptions {
  readPreference?: ReadPreferenceLike;
  /** How long to block for server selection before throwing an error */
  serverSelectionTimeoutMS?: number;
  session?: ClientSession;
  operationName: string;
  previousServer?: ServerDescription;
}

/** @public */
export type TopologyEvents = {
  /** Top level MongoClient doesn't emit this so it is marked: @internal */
  connect(topology: Topology): void;
  serverOpening(event: ServerOpeningEvent): void;
  serverClosed(event: ServerClosedEvent): void;
  serverDescriptionChanged(event: ServerDescriptionChangedEvent): void;
  topologyClosed(event: TopologyClosedEvent): void;
  topologyOpening(event: TopologyOpeningEvent): void;
  topologyDescriptionChanged(event: TopologyDescriptionChangedEvent): void;
  error(error: Error): void;
  /** @internal */
  open(topology: Topology): void;
  close(): void;
  timeout(): void;
} & Omit<ServerEvents, 'connect'> &
  ConnectionPoolEvents &
  ConnectionEvents &
  EventEmitterWithState;
/**
 * A container of server instances representing a connection to a MongoDB topology.
 * @internal
 */
export class Topology extends TypedEventEmitter<TopologyEvents> {
  /** @internal */
  s: TopologyPrivate;
  /** @internal */
  [kWaitQueue]: List<ServerSelectionRequest>;
  /** @internal */
  hello?: Document;
  /** @internal */
  _type?: string;

  client!: MongoClient;

  /** @event */
  static readonly SERVER_OPENING = SERVER_OPENING;
  /** @event */
  static readonly SERVER_CLOSED = SERVER_CLOSED;
  /** @event */
  static readonly SERVER_DESCRIPTION_CHANGED = SERVER_DESCRIPTION_CHANGED;
  /** @event */
  static readonly TOPOLOGY_OPENING = TOPOLOGY_OPENING;
  /** @event */
  static readonly TOPOLOGY_CLOSED = TOPOLOGY_CLOSED;
  /** @event */
  static readonly TOPOLOGY_DESCRIPTION_CHANGED = TOPOLOGY_DESCRIPTION_CHANGED;
  /** @event */
  static readonly ERROR = ERROR;
  /** @event */
  static readonly OPEN = OPEN;
  /** @event */
  static readonly CONNECT = CONNECT;
  /** @event */
  static readonly CLOSE = CLOSE;
  /** @event */
  static readonly TIMEOUT = TIMEOUT;

  selectServerAsync: (
    selector: string | ReadPreference | ServerSelector,
    options: SelectServerOptions
  ) => Promise<Server>;

  /**
   * @param seedlist - a list of HostAddress instances to connect to
   */
  constructor(
    client: MongoClient,
    seeds: string | string[] | HostAddress | HostAddress[],
    options: TopologyOptions
  ) {
    super();

    this.client = client;
    this.selectServerAsync = promisify(
      (
        selector: string | ReadPreference | ServerSelector,
        options: SelectServerOptions,
        callback: (e: Error, r: Server) => void
      ) => this.selectServer(selector, options, callback as any)
    );

    // Options should only be undefined in tests, MongoClient will always have defined options
    options = options ?? {
      hosts: [HostAddress.fromString('localhost:27017')],
      ...Object.fromEntries(DEFAULT_OPTIONS.entries()),
      ...Object.fromEntries(FEATURE_FLAGS.entries())
    };

    if (typeof seeds === 'string') {
      seeds = [HostAddress.fromString(seeds)];
    } else if (!Array.isArray(seeds)) {
      seeds = [seeds];
    }

    const seedlist: HostAddress[] = [];
    for (const seed of seeds) {
      if (typeof seed === 'string') {
        seedlist.push(HostAddress.fromString(seed));
      } else if (seed instanceof HostAddress) {
        seedlist.push(seed);
      } else {
        // FIXME(NODE-3483): May need to be a MongoParseError
        throw new MongoRuntimeError(`Topology cannot be constructed from ${JSON.stringify(seed)}`);
      }
    }

    const topologyType = topologyTypeFromOptions(options);
    const topologyId = globalTopologyCounter++;

    const selectedHosts =
      options.srvMaxHosts == null ||
      options.srvMaxHosts === 0 ||
      options.srvMaxHosts >= seedlist.length
        ? seedlist
        : shuffle(seedlist, options.srvMaxHosts);

    const serverDescriptions = new Map();
    for (const hostAddress of selectedHosts) {
      serverDescriptions.set(hostAddress.toString(), new ServerDescription(hostAddress));
    }

    this[kWaitQueue] = new List();
    this.s = {
      // the id of this topology
      id: topologyId,
      // passed in options
      options,
      // initial seedlist of servers to connect to
      seedlist,
      // initial state
      state: STATE_CLOSED,
      // the topology description
      description: new TopologyDescription(
        topologyType,
        serverDescriptions,
        options.replicaSet,
        undefined,
        undefined,
        undefined,
        options
      ),
      serverSelectionTimeoutMS: options.serverSelectionTimeoutMS,
      heartbeatFrequencyMS: options.heartbeatFrequencyMS,
      minHeartbeatFrequencyMS: options.minHeartbeatFrequencyMS,
      // a map of server instances to normalized addresses
      servers: new Map(),
      credentials: options?.credentials,
      clusterTime: undefined,

      // timer management
      connectionTimers: new Set<NodeJS.Timeout>(),
      detectShardedTopology: ev => this.detectShardedTopology(ev),
      detectSrvRecords: ev => this.detectSrvRecords(ev)
    };

    this.mongoLogger = client.mongoLogger;
    this.component = 'topology';

    if (options.srvHost && !options.loadBalanced) {
      this.s.srvPoller =
        options.srvPoller ??
        new SrvPoller({
          heartbeatFrequencyMS: this.s.heartbeatFrequencyMS,
          srvHost: options.srvHost,
          srvMaxHosts: options.srvMaxHosts,
          srvServiceName: options.srvServiceName
        });

      this.on(Topology.TOPOLOGY_DESCRIPTION_CHANGED, this.s.detectShardedTopology);
    }
  }

  private detectShardedTopology(event: TopologyDescriptionChangedEvent) {
    const previousType = event.previousDescription.type;
    const newType = event.newDescription.type;

    const transitionToSharded =
      previousType !== TopologyType.Sharded && newType === TopologyType.Sharded;
    const srvListeners = this.s.srvPoller?.listeners(SrvPoller.SRV_RECORD_DISCOVERY);
    const listeningToSrvPolling = !!srvListeners?.includes(this.s.detectSrvRecords);

    if (transitionToSharded && !listeningToSrvPolling) {
      this.s.srvPoller?.on(SrvPoller.SRV_RECORD_DISCOVERY, this.s.detectSrvRecords);
      this.s.srvPoller?.start();
    }
  }

  private detectSrvRecords(ev: SrvPollingEvent) {
    const previousTopologyDescription = this.s.description;
    this.s.description = this.s.description.updateFromSrvPollingEvent(
      ev,
      this.s.options.srvMaxHosts
    );
    if (this.s.description === previousTopologyDescription) {
      // Nothing changed, so return
      return;
    }

    updateServers(this);

    this.emitAndLog(
      Topology.TOPOLOGY_DESCRIPTION_CHANGED,
      new TopologyDescriptionChangedEvent(
        this.s.id,
        previousTopologyDescription,
        this.s.description
      )
    );
  }

  /**
   * @returns A `TopologyDescription` for this topology
   */
  get description(): TopologyDescription {
    return this.s.description;
  }

  get loadBalanced(): boolean {
    return this.s.options.loadBalanced;
  }

  get serverApi(): ServerApi | undefined {
    return this.s.options.serverApi;
  }

  get capabilities(): ServerCapabilities {
    return new ServerCapabilities(this.lastHello());
  }

  /** Initiate server connect */
  connect(callback: Callback): void;
  connect(options: ConnectOptions, callback: Callback): void;
  connect(options?: ConnectOptions | Callback, callback?: Callback): void {
    if (typeof options === 'function') (callback = options), (options = {});
    options = options ?? {};
    if (this.s.state === STATE_CONNECTED) {
      if (typeof callback === 'function') {
        callback();
      }

      return;
    }

    stateTransition(this, STATE_CONNECTING);

    // emit SDAM monitoring events
    this.emitAndLog(Topology.TOPOLOGY_OPENING, new TopologyOpeningEvent(this.s.id));

    // emit an event for the topology change
    this.emitAndLog(
      Topology.TOPOLOGY_DESCRIPTION_CHANGED,
      new TopologyDescriptionChangedEvent(
        this.s.id,
        new TopologyDescription(TopologyType.Unknown), // initial is always Unknown
        this.s.description
      )
    );

    // connect all known servers, then attempt server selection to connect
    const serverDescriptions = Array.from(this.s.description.servers.values());
    this.s.servers = new Map(
      serverDescriptions.map(serverDescription => [
        serverDescription.address,
        createAndConnectServer(this, serverDescription)
      ])
    );

    // In load balancer mode we need to fake a server description getting
    // emitted from the monitor, since the monitor doesn't exist.
    if (this.s.options.loadBalanced) {
      for (const description of serverDescriptions) {
        const newDescription = new ServerDescription(description.hostAddress, undefined, {
          loadBalanced: this.s.options.loadBalanced
        });
        this.serverUpdateHandler(newDescription);
      }
    }

    const exitWithError = (error: Error) =>
      callback ? callback(error) : this.emit(Topology.ERROR, error);

    const readPreference = options.readPreference ?? ReadPreference.primary;
    const selectServerOptions = { operationName: 'ping', ...options };
    this.selectServer(
      readPreferenceServerSelector(readPreference),
      selectServerOptions,
      (err, server) => {
        if (err) {
          this.close();
          return exitWithError(err);
        }

        const skipPingOnConnect = this.s.options[Symbol.for('@@mdb.skipPingOnConnect')] === true;
        if (!skipPingOnConnect && server && this.s.credentials) {
          server.command(ns('admin.$cmd'), { ping: 1 }, {}).then(() => {
            stateTransition(this, STATE_CONNECTED);
            this.emit(Topology.OPEN, this);
            this.emit(Topology.CONNECT, this);

            callback?.(undefined, this);
          }, exitWithError);

          return;
        }

        stateTransition(this, STATE_CONNECTED);
        this.emit(Topology.OPEN, this);
        this.emit(Topology.CONNECT, this);

        callback?.(undefined, this);
      }
    );
  }

  /** Close this topology */
  close(): void {
    if (this.s.state === STATE_CLOSED || this.s.state === STATE_CLOSING) {
      return;
    }

    for (const server of this.s.servers.values()) {
      destroyServer(server, this);
    }

    this.s.servers.clear();

    stateTransition(this, STATE_CLOSING);

    drainWaitQueue(this[kWaitQueue], new MongoTopologyClosedError());
    drainTimerQueue(this.s.connectionTimers);

    if (this.s.srvPoller) {
      this.s.srvPoller.stop();
      this.s.srvPoller.removeListener(SrvPoller.SRV_RECORD_DISCOVERY, this.s.detectSrvRecords);
    }

    this.removeListener(Topology.TOPOLOGY_DESCRIPTION_CHANGED, this.s.detectShardedTopology);

    stateTransition(this, STATE_CLOSED);

    // emit an event for close
    this.emitAndLog(Topology.TOPOLOGY_CLOSED, new TopologyClosedEvent(this.s.id));
  }

  /**
   * Selects a server according to the selection predicate provided
   *
   * @param selector - An optional selector to select servers by, defaults to a random selection within a latency window
   * @param options - Optional settings related to server selection
   * @param callback - The callback used to indicate success or failure
   * @returns An instance of a `Server` meeting the criteria of the predicate provided
   */
  selectServer(
    selector: string | ReadPreference | ServerSelector,
    options: SelectServerOptions,
    callback: Callback<Server>
  ): void {
    let serverSelector;
    if (typeof selector !== 'function') {
      if (typeof selector === 'string') {
        serverSelector = readPreferenceServerSelector(ReadPreference.fromString(selector));
      } else {
        let readPreference;
        if (selector instanceof ReadPreference) {
          readPreference = selector;
        } else {
          ReadPreference.translate(options);
          readPreference = options.readPreference || ReadPreference.primary;
        }

        serverSelector = readPreferenceServerSelector(readPreference as ReadPreference);
      }
    } else {
      serverSelector = selector;
    }

    options = { serverSelectionTimeoutMS: this.s.serverSelectionTimeoutMS, ...options };
    if (
      this.client.mongoLogger?.willLog(MongoLoggableComponent.SERVER_SELECTION, SeverityLevel.DEBUG)
    ) {
      this.client.mongoLogger?.debug(
        MongoLoggableComponent.SERVER_SELECTION,
        new ServerSelectionStartedEvent(selector, this.description, options.operationName)
      );
    }

    const isSharded = this.description.type === TopologyType.Sharded;
    const session = options.session;
    const transaction = session && session.transaction;

    if (isSharded && transaction && transaction.server) {
      if (
        this.client.mongoLogger?.willLog(
          MongoLoggableComponent.SERVER_SELECTION,
          SeverityLevel.DEBUG
        )
      ) {
        this.client.mongoLogger?.debug(
          MongoLoggableComponent.SERVER_SELECTION,
          new ServerSelectionSucceededEvent(
            selector,
            this.description,
            transaction.server.pool.address,
            options.operationName
          )
        );
      }
      callback(undefined, transaction.server);
      return;
    }

    const waitQueueMember: ServerSelectionRequest = {
      serverSelector,
      topologyDescription: this.description,
      mongoLogger: this.client.mongoLogger,
      transaction,
      callback,
      timeoutController: new TimeoutController(options.serverSelectionTimeoutMS),
      startTime: now(),
      operationName: options.operationName,
      waitingLogged: false,
      previousServer: options.previousServer
    };

    waitQueueMember.timeoutController.signal.addEventListener('abort', () => {
      waitQueueMember[kCancelled] = true;
      waitQueueMember.timeoutController.clear();
      const timeoutError = new MongoServerSelectionError(
        `Server selection timed out after ${options.serverSelectionTimeoutMS} ms`,
        this.description
      );
      if (
        this.client.mongoLogger?.willLog(
          MongoLoggableComponent.SERVER_SELECTION,
          SeverityLevel.DEBUG
        )
      ) {
        this.client.mongoLogger?.debug(
          MongoLoggableComponent.SERVER_SELECTION,
          new ServerSelectionFailedEvent(
            selector,
            this.description,
            timeoutError,
            options.operationName
          )
        );
      }
      waitQueueMember.callback(timeoutError);
    });

    this[kWaitQueue].push(waitQueueMember);
    processWaitQueue(this);
  }

  /**
   * Update the internal TopologyDescription with a ServerDescription
   *
   * @param serverDescription - The server to update in the internal list of server descriptions
   */
  serverUpdateHandler(serverDescription: ServerDescription): void {
    if (!this.s.description.hasServer(serverDescription.address)) {
      return;
    }

    // ignore this server update if its from an outdated topologyVersion
    if (isStaleServerDescription(this.s.description, serverDescription)) {
      return;
    }

    // these will be used for monitoring events later
    const previousTopologyDescription = this.s.description;
    const previousServerDescription = this.s.description.servers.get(serverDescription.address);
    if (!previousServerDescription) {
      return;
    }

    // Driver Sessions Spec: "Whenever a driver receives a cluster time from
    // a server it MUST compare it to the current highest seen cluster time
    // for the deployment. If the new cluster time is higher than the
    // highest seen cluster time it MUST become the new highest seen cluster
    // time. Two cluster times are compared using only the BsonTimestamp
    // value of the clusterTime embedded field."
    const clusterTime = serverDescription.$clusterTime;
    if (clusterTime) {
      _advanceClusterTime(this, clusterTime);
    }

    // If we already know all the information contained in this updated description, then
    // we don't need to emit SDAM events, but still need to update the description, in order
    // to keep client-tracked attributes like last update time and round trip time up to date
    const equalDescriptions =
      previousServerDescription && previousServerDescription.equals(serverDescription);

    // first update the TopologyDescription
    this.s.description = this.s.description.update(serverDescription);
    if (this.s.description.compatibilityError) {
      this.emit(Topology.ERROR, new MongoCompatibilityError(this.s.description.compatibilityError));
      return;
    }

    // emit monitoring events for this change
    if (!equalDescriptions) {
      const newDescription = this.s.description.servers.get(serverDescription.address);
      if (newDescription) {
        this.emit(
          Topology.SERVER_DESCRIPTION_CHANGED,
          new ServerDescriptionChangedEvent(
            this.s.id,
            serverDescription.address,
            previousServerDescription,
            newDescription
          )
        );
      }
    }

    // update server list from updated descriptions
    updateServers(this, serverDescription);

    // attempt to resolve any outstanding server selection attempts
    if (this[kWaitQueue].length > 0) {
      processWaitQueue(this);
    }

    if (!equalDescriptions) {
      this.emitAndLog(
        Topology.TOPOLOGY_DESCRIPTION_CHANGED,
        new TopologyDescriptionChangedEvent(
          this.s.id,
          previousTopologyDescription,
          this.s.description
        )
      );
    }
  }

  auth(credentials?: MongoCredentials, callback?: Callback): void {
    if (typeof credentials === 'function') (callback = credentials), (credentials = undefined);
    if (typeof callback === 'function') callback(undefined, true);
  }

  get clientMetadata(): ClientMetadata {
    return this.s.options.metadata;
  }

  isConnected(): boolean {
    return this.s.state === STATE_CONNECTED;
  }

  isDestroyed(): boolean {
    return this.s.state === STATE_CLOSED;
  }

  // NOTE: There are many places in code where we explicitly check the last hello
  //       to do feature support detection. This should be done any other way, but for
  //       now we will just return the first hello seen, which should suffice.
  lastHello(): Document {
    const serverDescriptions = Array.from(this.description.servers.values());
    if (serverDescriptions.length === 0) return {};
    const sd = serverDescriptions.filter(
      (sd: ServerDescription) => sd.type !== ServerType.Unknown
    )[0];

    const result = sd || { maxWireVersion: this.description.commonWireVersion };
    return result;
  }

  get commonWireVersion(): number | undefined {
    return this.description.commonWireVersion;
  }

  get logicalSessionTimeoutMinutes(): number | null {
    return this.description.logicalSessionTimeoutMinutes;
  }

  get clusterTime(): ClusterTime | undefined {
    return this.s.clusterTime;
  }

  set clusterTime(clusterTime: ClusterTime | undefined) {
    this.s.clusterTime = clusterTime;
  }
}

/** Destroys a server, and removes all event listeners from the instance */
function destroyServer(server: Server, topology: Topology) {
  for (const event of LOCAL_SERVER_EVENTS) {
    server.removeAllListeners(event);
  }

  server.destroy();
  topology.emitAndLog(
    Topology.SERVER_CLOSED,
    new ServerClosedEvent(topology.s.id, server.description.address)
  );

  for (const event of SERVER_RELAY_EVENTS) {
    server.removeAllListeners(event);
  }
}

/** Predicts the TopologyType from options */
function topologyTypeFromOptions(options?: TopologyOptions) {
  if (options?.directConnection) {
    return TopologyType.Single;
  }

  if (options?.replicaSet) {
    return TopologyType.ReplicaSetNoPrimary;
  }

  if (options?.loadBalanced) {
    return TopologyType.LoadBalanced;
  }

  return TopologyType.Unknown;
}

/**
 * Creates new server instances and attempts to connect them
 *
 * @param topology - The topology that this server belongs to
 * @param serverDescription - The description for the server to initialize and connect to
 */
function createAndConnectServer(topology: Topology, serverDescription: ServerDescription) {
  topology.emitAndLog(
    Topology.SERVER_OPENING,
    new ServerOpeningEvent(topology.s.id, serverDescription.address)
  );

  const server = new Server(topology, serverDescription, topology.s.options);
  for (const event of SERVER_RELAY_EVENTS) {
    server.on(event, (e: any) => topology.emit(event, e));
  }

  server.on(Server.DESCRIPTION_RECEIVED, description => topology.serverUpdateHandler(description));

  server.connect();
  return server;
}

/**
 * @param topology - Topology to update.
 * @param incomingServerDescription - New server description.
 */
function updateServers(topology: Topology, incomingServerDescription?: ServerDescription) {
  // update the internal server's description
  if (incomingServerDescription && topology.s.servers.has(incomingServerDescription.address)) {
    const server = topology.s.servers.get(incomingServerDescription.address);
    if (server) {
      server.s.description = incomingServerDescription;
      if (
        incomingServerDescription.error instanceof MongoError &&
        incomingServerDescription.error.hasErrorLabel(MongoErrorLabel.ResetPool)
      ) {
        const interruptInUseConnections = incomingServerDescription.error.hasErrorLabel(
          MongoErrorLabel.InterruptInUseConnections
        );

        server.pool.clear({ interruptInUseConnections });
      } else if (incomingServerDescription.error == null) {
        const newTopologyType = topology.s.description.type;
        const shouldMarkPoolReady =
          incomingServerDescription.isDataBearing ||
          (incomingServerDescription.type !== ServerType.Unknown &&
            newTopologyType === TopologyType.Single);
        if (shouldMarkPoolReady) {
          server.pool.ready();
        }
      }
    }
  }

  // add new servers for all descriptions we currently don't know about locally
  for (const serverDescription of topology.description.servers.values()) {
    if (!topology.s.servers.has(serverDescription.address)) {
      const server = createAndConnectServer(topology, serverDescription);
      topology.s.servers.set(serverDescription.address, server);
    }
  }

  // for all servers no longer known, remove their descriptions and destroy their instances
  for (const entry of topology.s.servers) {
    const serverAddress = entry[0];
    if (topology.description.hasServer(serverAddress)) {
      continue;
    }

    if (!topology.s.servers.has(serverAddress)) {
      continue;
    }

    const server = topology.s.servers.get(serverAddress);
    topology.s.servers.delete(serverAddress);

    // prepare server for garbage collection
    if (server) {
      destroyServer(server, topology);
    }
  }
}

function drainWaitQueue(queue: List<ServerSelectionRequest>, err?: MongoDriverError) {
  while (queue.length) {
    const waitQueueMember = queue.shift();
    if (!waitQueueMember) {
      continue;
    }

    waitQueueMember.timeoutController.clear();

    if (!waitQueueMember[kCancelled]) {
      if (err) {
        if (
          waitQueueMember.mongoLogger?.willLog(
            MongoLoggableComponent.SERVER_SELECTION,
            SeverityLevel.DEBUG
          )
        ) {
          waitQueueMember.mongoLogger?.debug(
            MongoLoggableComponent.SERVER_SELECTION,
            new ServerSelectionFailedEvent(
              waitQueueMember.serverSelector,
              waitQueueMember.topologyDescription,
              err,
              waitQueueMember.operationName
            )
          );
        }
      }
      waitQueueMember.callback(err);
    }
  }
}

function processWaitQueue(topology: Topology) {
  if (topology.s.state === STATE_CLOSED) {
    drainWaitQueue(topology[kWaitQueue], new MongoTopologyClosedError());
    return;
  }

  const isSharded = topology.description.type === TopologyType.Sharded;
  const serverDescriptions = Array.from(topology.description.servers.values());
  const membersToProcess = topology[kWaitQueue].length;
  for (let i = 0; i < membersToProcess; ++i) {
    const waitQueueMember = topology[kWaitQueue].shift();
    if (!waitQueueMember) {
      continue;
    }

    if (waitQueueMember[kCancelled]) {
      continue;
    }

    let selectedDescriptions;
    try {
      const serverSelector = waitQueueMember.serverSelector;
      const previousServer = waitQueueMember.previousServer;
      selectedDescriptions = serverSelector
        ? serverSelector(
            topology.description,
            serverDescriptions,
            previousServer ? [previousServer] : []
          )
        : serverDescriptions;
    } catch (e) {
      waitQueueMember.timeoutController.clear();
      if (
        topology.client.mongoLogger?.willLog(
          MongoLoggableComponent.SERVER_SELECTION,
          SeverityLevel.DEBUG
        )
      ) {
        topology.client.mongoLogger?.debug(
          MongoLoggableComponent.SERVER_SELECTION,
          new ServerSelectionFailedEvent(
            waitQueueMember.serverSelector,
            topology.description,
            e,
            waitQueueMember.operationName
          )
        );
      }
      waitQueueMember.callback(e);
      continue;
    }

    let selectedServer: Server | undefined;
    if (selectedDescriptions.length === 0) {
      if (!waitQueueMember.waitingLogged) {
        if (
          topology.client.mongoLogger?.willLog(
            MongoLoggableComponent.SERVER_SELECTION,
            SeverityLevel.INFORMATIONAL
          )
        ) {
          topology.client.mongoLogger?.info(
            MongoLoggableComponent.SERVER_SELECTION,
            new WaitingForSuitableServerEvent(
              waitQueueMember.serverSelector,
              topology.description,
              topology.s.serverSelectionTimeoutMS !== 0
                ? topology.s.serverSelectionTimeoutMS - (now() - waitQueueMember.startTime)
                : -1,
              waitQueueMember.operationName
            )
          );
        }
        waitQueueMember.waitingLogged = true;
      }
      topology[kWaitQueue].push(waitQueueMember);
      continue;
    } else if (selectedDescriptions.length === 1) {
      selectedServer = topology.s.servers.get(selectedDescriptions[0].address);
    } else {
      const descriptions = shuffle(selectedDescriptions, 2);
      const server1 = topology.s.servers.get(descriptions[0].address);
      const server2 = topology.s.servers.get(descriptions[1].address);

      selectedServer =
        server1 && server2 && server1.s.operationCount < server2.s.operationCount
          ? server1
          : server2;
    }

    if (!selectedServer) {
      const error = new MongoServerSelectionError(
        'server selection returned a server description but the server was not found in the topology',
        topology.description
      );
      if (
        topology.client.mongoLogger?.willLog(
          MongoLoggableComponent.SERVER_SELECTION,
          SeverityLevel.DEBUG
        )
      ) {
        topology.client.mongoLogger?.debug(
          MongoLoggableComponent.SERVER_SELECTION,
          new ServerSelectionFailedEvent(
            waitQueueMember.serverSelector,
            topology.description,
            error,
            waitQueueMember.operationName
          )
        );
      }
      waitQueueMember.callback(error);
      return;
    }
    const transaction = waitQueueMember.transaction;
    if (isSharded && transaction && transaction.isActive && selectedServer) {
      transaction.pinServer(selectedServer);
    }

    waitQueueMember.timeoutController.clear();

    if (
      topology.client.mongoLogger?.willLog(
        MongoLoggableComponent.SERVER_SELECTION,
        SeverityLevel.DEBUG
      )
    ) {
      topology.client.mongoLogger?.debug(
        MongoLoggableComponent.SERVER_SELECTION,
        new ServerSelectionSucceededEvent(
          waitQueueMember.serverSelector,
          waitQueueMember.topologyDescription,
          selectedServer.pool.address,
          waitQueueMember.operationName
        )
      );
    }
    waitQueueMember.callback(undefined, selectedServer);
  }

  if (topology[kWaitQueue].length > 0) {
    // ensure all server monitors attempt monitoring soon
    for (const [, server] of topology.s.servers) {
      process.nextTick(function scheduleServerCheck() {
        return server.requestCheck();
      });
    }
  }
}

function isStaleServerDescription(
  topologyDescription: TopologyDescription,
  incomingServerDescription: ServerDescription
) {
  const currentServerDescription = topologyDescription.servers.get(
    incomingServerDescription.address
  );
  const currentTopologyVersion = currentServerDescription?.topologyVersion;
  return (
    compareTopologyVersion(currentTopologyVersion, incomingServerDescription.topologyVersion) > 0
  );
}

/** @public */
export class ServerCapabilities {
  maxWireVersion: number;
  minWireVersion: number;

  constructor(hello: Document) {
    this.minWireVersion = hello.minWireVersion || 0;
    this.maxWireVersion = hello.maxWireVersion || 0;
  }

  get hasAggregationCursor(): boolean {
    return this.maxWireVersion >= 1;
  }

  get hasWriteCommands(): boolean {
    return this.maxWireVersion >= 2;
  }
  get hasTextSearch(): boolean {
    return this.minWireVersion >= 0;
  }

  get hasAuthCommands(): boolean {
    return this.maxWireVersion >= 1;
  }

  get hasListCollectionsCommand(): boolean {
    return this.maxWireVersion >= 3;
  }

  get hasListIndexesCommand(): boolean {
    return this.maxWireVersion >= 3;
  }

  get supportsSnapshotReads(): boolean {
    return this.maxWireVersion >= 13;
  }

  get commandsTakeWriteConcern(): boolean {
    return this.maxWireVersion >= 5;
  }

  get commandsTakeCollation(): boolean {
    return this.maxWireVersion >= 5;
  }
}
