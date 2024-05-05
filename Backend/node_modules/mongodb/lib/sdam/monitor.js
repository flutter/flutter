"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MonitorInterval = exports.RTTPinger = exports.Monitor = exports.ServerMonitoringMode = void 0;
const timers_1 = require("timers");
const bson_1 = require("../bson");
const connect_1 = require("../cmap/connect");
const client_metadata_1 = require("../cmap/handshake/client_metadata");
const constants_1 = require("../constants");
const error_1 = require("../error");
const mongo_logger_1 = require("../mongo_logger");
const mongo_types_1 = require("../mongo_types");
const utils_1 = require("../utils");
const common_1 = require("./common");
const events_1 = require("./events");
const server_1 = require("./server");
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
const stateTransition = (0, utils_1.makeStateMachine)({
    [common_1.STATE_CLOSING]: [common_1.STATE_CLOSING, STATE_IDLE, common_1.STATE_CLOSED],
    [common_1.STATE_CLOSED]: [common_1.STATE_CLOSED, STATE_MONITORING],
    [STATE_IDLE]: [STATE_IDLE, STATE_MONITORING, common_1.STATE_CLOSING],
    [STATE_MONITORING]: [STATE_MONITORING, STATE_IDLE, common_1.STATE_CLOSING]
});
const INVALID_REQUEST_CHECK_STATES = new Set([common_1.STATE_CLOSING, common_1.STATE_CLOSED, STATE_MONITORING]);
function isInCloseState(monitor) {
    return monitor.s.state === common_1.STATE_CLOSED || monitor.s.state === common_1.STATE_CLOSING;
}
/** @public */
exports.ServerMonitoringMode = Object.freeze({
    auto: 'auto',
    poll: 'poll',
    stream: 'stream'
});
/** @internal */
class Monitor extends mongo_types_1.TypedEventEmitter {
    constructor(server, options) {
        super();
        /** @internal */
        this.component = mongo_logger_1.MongoLoggableComponent.TOPOLOGY;
        this[kServer] = server;
        this.connection = null;
        this[kCancellationToken] = new mongo_types_1.CancellationToken();
        this[kCancellationToken].setMaxListeners(Infinity);
        this[kMonitorId] = undefined;
        this.s = {
            state: common_1.STATE_CLOSED
        };
        this.address = server.description.address;
        this.options = Object.freeze({
            connectTimeoutMS: options.connectTimeoutMS ?? 10000,
            heartbeatFrequencyMS: options.heartbeatFrequencyMS ?? 10000,
            minHeartbeatFrequencyMS: options.minHeartbeatFrequencyMS ?? 500,
            serverMonitoringMode: options.serverMonitoringMode
        });
        this.isRunningInFaasEnv = (0, client_metadata_1.getFAASEnv)() != null;
        this.mongoLogger = this[kServer].topology.client?.mongoLogger;
        const cancellationToken = this[kCancellationToken];
        // TODO: refactor this to pull it directly from the pool, requires new ConnectionPool integration
        const connectOptions = {
            id: '<monitor>',
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
    connect() {
        if (this.s.state !== common_1.STATE_CLOSED) {
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
    requestCheck() {
        if (INVALID_REQUEST_CHECK_STATES.has(this.s.state)) {
            return;
        }
        this[kMonitorId]?.wake();
    }
    reset() {
        const topologyVersion = this[kServer].description.topologyVersion;
        if (isInCloseState(this) || topologyVersion == null) {
            return;
        }
        stateTransition(this, common_1.STATE_CLOSING);
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
    close() {
        if (isInCloseState(this)) {
            return;
        }
        stateTransition(this, common_1.STATE_CLOSING);
        resetMonitorState(this);
        // close monitor
        this.emit('close');
        stateTransition(this, common_1.STATE_CLOSED);
    }
}
exports.Monitor = Monitor;
function resetMonitorState(monitor) {
    monitor[kMonitorId]?.stop();
    monitor[kMonitorId] = undefined;
    monitor.rttPinger?.close();
    monitor.rttPinger = undefined;
    monitor[kCancellationToken].emit('cancel');
    monitor.connection?.destroy();
    monitor.connection = null;
}
function useStreamingProtocol(monitor, topologyVersion) {
    // If we have no topology version we always poll no matter
    // what the user provided, since the server does not support
    // the streaming protocol.
    if (topologyVersion == null)
        return false;
    const serverMonitoringMode = monitor.options.serverMonitoringMode;
    if (serverMonitoringMode === exports.ServerMonitoringMode.poll)
        return false;
    if (serverMonitoringMode === exports.ServerMonitoringMode.stream)
        return true;
    // If we are in auto mode, we need to figure out if we're in a FaaS
    // environment or not and choose the appropriate mode.
    if (monitor.isRunningInFaasEnv)
        return false;
    return true;
}
function checkServer(monitor, callback) {
    let start;
    let awaited;
    const topologyVersion = monitor[kServer].description.topologyVersion;
    const isAwaitable = useStreamingProtocol(monitor, topologyVersion);
    monitor.emitAndLogHeartbeat(server_1.Server.SERVER_HEARTBEAT_STARTED, monitor[kServer].topology.s.id, undefined, new events_1.ServerHeartbeatStartedEvent(monitor.address, isAwaitable));
    function onHeartbeatFailed(err) {
        monitor.connection?.destroy();
        monitor.connection = null;
        monitor.emitAndLogHeartbeat(server_1.Server.SERVER_HEARTBEAT_FAILED, monitor[kServer].topology.s.id, undefined, new events_1.ServerHeartbeatFailedEvent(monitor.address, (0, utils_1.calculateDurationInMs)(start), err, awaited));
        const error = !(err instanceof error_1.MongoError)
            ? new error_1.MongoError(error_1.MongoError.buildErrorMessage(err), { cause: err })
            : err;
        error.addErrorLabel(error_1.MongoErrorLabel.ResetPool);
        if (error instanceof error_1.MongoNetworkTimeoutError) {
            error.addErrorLabel(error_1.MongoErrorLabel.InterruptInUseConnections);
        }
        monitor.emit('resetServer', error);
        callback(err);
    }
    function onHeartbeatSucceeded(hello) {
        if (!('isWritablePrimary' in hello)) {
            // Provide hello-style response document.
            hello.isWritablePrimary = hello[constants_1.LEGACY_HELLO_COMMAND];
        }
        const duration = isAwaitable && monitor.rttPinger
            ? monitor.rttPinger.roundTripTime
            : (0, utils_1.calculateDurationInMs)(start);
        monitor.emitAndLogHeartbeat(server_1.Server.SERVER_HEARTBEAT_SUCCEEDED, monitor[kServer].topology.s.id, hello.connectionId, new events_1.ServerHeartbeatSucceededEvent(monitor.address, duration, hello, isAwaitable));
        if (isAwaitable) {
            // If we are using the streaming protocol then we immediately issue another 'started'
            // event, otherwise the "check" is complete and return to the main monitor loop
            monitor.emitAndLogHeartbeat(server_1.Server.SERVER_HEARTBEAT_STARTED, monitor[kServer].topology.s.id, undefined, new events_1.ServerHeartbeatStartedEvent(monitor.address, true));
            // We have not actually sent an outgoing handshake, but when we get the next response we
            // want the duration to reflect the time since we last heard from the server
            start = (0, utils_1.now)();
        }
        else {
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
            [serverApi?.version || helloOk ? 'hello' : constants_1.LEGACY_HELLO_COMMAND]: 1,
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
            monitor.rttPinger = new RTTPinger(monitor[kCancellationToken], Object.assign({ heartbeatFrequencyMS: monitor.options.heartbeatFrequencyMS }, monitor.connectOptions));
        }
        // Record new start time before sending handshake
        start = (0, utils_1.now)();
        if (isAwaitable) {
            awaited = true;
            return connection.exhaustCommand((0, utils_1.ns)('admin.$cmd'), cmd, options, (error, hello) => {
                if (error)
                    return onHeartbeatFailed(error);
                return onHeartbeatSucceeded(hello);
            });
        }
        awaited = false;
        connection
            .command((0, utils_1.ns)('admin.$cmd'), cmd, options)
            .then(onHeartbeatSucceeded, onHeartbeatFailed);
        return;
    }
    // connecting does an implicit `hello`
    (async () => {
        const socket = await (0, connect_1.makeSocket)(monitor.connectOptions);
        const connection = (0, connect_1.makeConnection)(monitor.connectOptions, socket);
        // The start time is after socket creation but before the handshake
        start = (0, utils_1.now)();
        try {
            await (0, connect_1.performInitialHandshake)(connection, monitor.connectOptions);
            return connection;
        }
        catch (error) {
            connection.destroy();
            throw error;
        }
    })().then(connection => {
        if (isInCloseState(monitor)) {
            connection.destroy();
            return;
        }
        monitor.connection = connection;
        monitor.emitAndLogHeartbeat(server_1.Server.SERVER_HEARTBEAT_SUCCEEDED, monitor[kServer].topology.s.id, connection.hello?.connectionId, new events_1.ServerHeartbeatSucceededEvent(monitor.address, (0, utils_1.calculateDurationInMs)(start), connection.hello, useStreamingProtocol(monitor, connection.hello?.topologyVersion)));
        callback(undefined, connection.hello);
    }, error => {
        monitor.connection = null;
        awaited = false;
        onHeartbeatFailed(error);
    });
}
function monitorServer(monitor) {
    return (callback) => {
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
                if (monitor[kServer].description.type === common_1.ServerType.Unknown) {
                    return done();
                }
            }
            // if the check indicates streaming is supported, immediately reschedule monitoring
            if (useStreamingProtocol(monitor, hello?.topologyVersion)) {
                (0, timers_1.setTimeout)(() => {
                    if (!isInCloseState(monitor)) {
                        monitor[kMonitorId]?.wake();
                    }
                }, 0);
            }
            done();
        });
    };
}
function makeTopologyVersion(tv) {
    return {
        processId: tv.processId,
        // tests mock counter as just number, but in a real situation counter should always be a Long
        // TODO(NODE-2674): Preserve int64 sent from MongoDB
        counter: bson_1.Long.isLong(tv.counter) ? tv.counter : bson_1.Long.fromNumber(tv.counter)
    };
}
/** @internal */
class RTTPinger {
    constructor(cancellationToken, options) {
        this.connection = undefined;
        this[kCancellationToken] = cancellationToken;
        this[kRoundTripTime] = 0;
        this.closed = false;
        const heartbeatFrequencyMS = options.heartbeatFrequencyMS;
        this[kMonitorId] = (0, timers_1.setTimeout)(() => measureRoundTripTime(this, options), heartbeatFrequencyMS);
    }
    get roundTripTime() {
        return this[kRoundTripTime];
    }
    close() {
        this.closed = true;
        (0, timers_1.clearTimeout)(this[kMonitorId]);
        this.connection?.destroy();
        this.connection = undefined;
    }
}
exports.RTTPinger = RTTPinger;
function measureRoundTripTime(rttPinger, options) {
    const start = (0, utils_1.now)();
    options.cancellationToken = rttPinger[kCancellationToken];
    const heartbeatFrequencyMS = options.heartbeatFrequencyMS;
    if (rttPinger.closed) {
        return;
    }
    function measureAndReschedule(conn) {
        if (rttPinger.closed) {
            conn?.destroy();
            return;
        }
        if (rttPinger.connection == null) {
            rttPinger.connection = conn;
        }
        rttPinger[kRoundTripTime] = (0, utils_1.calculateDurationInMs)(start);
        rttPinger[kMonitorId] = (0, timers_1.setTimeout)(() => measureRoundTripTime(rttPinger, options), heartbeatFrequencyMS);
    }
    const connection = rttPinger.connection;
    if (connection == null) {
        (0, connect_1.connect)(options).then(connection => {
            measureAndReschedule(connection);
        }, () => {
            rttPinger.connection = undefined;
            rttPinger[kRoundTripTime] = 0;
        });
        return;
    }
    const commandName = connection.serverApi?.version || connection.helloOk ? 'hello' : constants_1.LEGACY_HELLO_COMMAND;
    connection.command((0, utils_1.ns)('admin.$cmd'), { [commandName]: 1 }, undefined).then(() => measureAndReschedule(), () => {
        rttPinger.connection?.destroy();
        rttPinger.connection = undefined;
        rttPinger[kRoundTripTime] = 0;
        return;
    });
}
/**
 * @internal
 */
class MonitorInterval {
    constructor(fn, options = {}) {
        this.isExpeditedCallToFnScheduled = false;
        this.stopped = false;
        this.isExecutionInProgress = false;
        this.hasExecutedOnce = false;
        this._executeAndReschedule = () => {
            if (this.stopped)
                return;
            if (this.timerId) {
                (0, timers_1.clearTimeout)(this.timerId);
            }
            this.isExpeditedCallToFnScheduled = false;
            this.isExecutionInProgress = true;
            this.fn(() => {
                this.lastExecutionEnded = (0, utils_1.now)();
                this.isExecutionInProgress = false;
                this._reschedule(this.heartbeatFrequencyMS);
            });
        };
        this.fn = fn;
        this.lastExecutionEnded = -Infinity;
        this.heartbeatFrequencyMS = options.heartbeatFrequencyMS ?? 1000;
        this.minHeartbeatFrequencyMS = options.minHeartbeatFrequencyMS ?? 500;
        if (options.immediate) {
            this._executeAndReschedule();
        }
        else {
            this._reschedule(undefined);
        }
    }
    wake() {
        const currentTime = (0, utils_1.now)();
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
            (0, timers_1.clearTimeout)(this.timerId);
            this.timerId = undefined;
        }
        this.lastExecutionEnded = -Infinity;
        this.isExpeditedCallToFnScheduled = false;
    }
    toString() {
        return JSON.stringify(this);
    }
    toJSON() {
        const currentTime = (0, utils_1.now)();
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
    _reschedule(ms) {
        if (this.stopped)
            return;
        if (this.timerId) {
            (0, timers_1.clearTimeout)(this.timerId);
        }
        this.timerId = (0, timers_1.setTimeout)(this._executeAndReschedule, ms || this.heartbeatFrequencyMS);
    }
}
exports.MonitorInterval = MonitorInterval;
//# sourceMappingURL=monitor.js.map