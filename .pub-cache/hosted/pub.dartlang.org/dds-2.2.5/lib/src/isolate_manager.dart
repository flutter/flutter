// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart';

import 'client.dart';
import 'constants.dart';
import 'cpu_samples_manager.dart';
import 'dds_impl.dart';
import 'utils/mutex.dart';

/// This file contains functionality used to track the running state of
/// all isolates in a given Dart process.
///
/// [_RunningIsolate] is a representation of a single live isolate and contains
/// running state information for that isolate. In addition, approvals from
/// clients used to synchronize isolate resuming across multiple clients are
/// tracked in this class.
///
/// The [IsolateManager] keeps track of all the isolates in the
/// target process and handles isolate lifecycle events including:
///   - Startup
///   - Shutdown
///   - Pauses
///
/// The [IsolateManager] also handles the `resume` RPC, which checks the
/// resume approvals in the target [_RunningIsolate] to determine if the
/// isolate should be resumed or wait for additional approvals to be granted.

enum _IsolateState {
  start,
  running,
  pauseStart,
  pauseExit,
  pausePostRequest,
}

class _RunningIsolate {
  _RunningIsolate(this.isolateManager, this.id, this.name)
      : cpuSamplesManager = CpuSamplesManager(
          isolateManager.dds,
          id,
        );

  // State setters.
  void pausedOnExit() => _state = _IsolateState.pauseExit;

  void pausedOnStart() => _state = _IsolateState.pauseStart;

  void pausedPostRequest() => _state = _IsolateState.pausePostRequest;

  void resumed() => running();

  void running() => _state = _IsolateState.running;

  void started() => _state = _IsolateState.start;

  /// Resumes the isolate if all clients which need to approve a resume have
  /// done so. Called when the last client of a given name disconnects or
  /// changes name to ensure we don't deadlock waiting for approval to resume
  /// from a disconnected client.
  Future<void> maybeResumeAfterClientChange(String? clientName) async {
    // Remove approvals from the disconnected client.
    _resumeApprovalsByName.remove(clientName);

    if (shouldResume()) {
      clearResumeApprovals();
      await isolateManager.dds.vmServiceClient.sendRequest('resume', {
        'isolateId': id,
      });
    }
  }

  /// Returns true if this isolate should resume given its client approvals
  /// state.
  ///
  /// If `resumingClient` is provided, it will be added to the set of clients
  /// which have provided approval to resume this isolate. If not provided,
  /// the existing approvals state will be examined to see if the isolate
  /// should resume due to a client disconnect or name change.
  bool shouldResume({DartDevelopmentServiceClient? resumingClient}) {
    if (resumingClient != null) {
      // Mark approval by the client.
      _resumeApprovalsByName.add(resumingClient.name);
    }
    final requiredClientApprovals = <String>{};
    final permissions =
        isolateManager.dds.clientManager.clientResumePermissions;

    // Determine which clients require approval for this pause type.
    permissions.forEach((clientName, clientNamePermissions) {
      if (clientNamePermissions.permissionsMask & _isolateStateMask != 0) {
        requiredClientApprovals.add(clientName!);
      }
    });

    // We require at least a single client to resume, even if that client
    // doesn't require resume approval.
    if (_resumeApprovalsByName.isEmpty) {
      return false;
    }
    // If all the required approvals are present, we should resume.
    return _resumeApprovalsByName.containsAll(requiredClientApprovals);
  }

  /// Resets the internal resume approvals state.
  ///
  /// Should always be called after an isolate is resumed.
  void clearResumeApprovals() => _resumeApprovalsByName.clear();

  Future<Map<String, dynamic>> getCachedCpuSamples(String userTag) async {
    final repo = cpuSamplesManager.cpuSamplesCaches[userTag];
    if (repo == null) {
      throw json_rpc.RpcException.invalidParams(
        'CPU sample caching is not enabled for tag: "$userTag"',
      );
    }
    await repo.populateFunctionDetails(isolateManager.dds, id);
    return repo.toJson();
  }

  void handleEvent(Event event) {
    switch (event.kind) {
      case EventKind.kCpuSamples:
        cpuSamplesManager.handleCpuSamplesEvent(event);
        return;
      default:
        return;
    }
  }

  int get _isolateStateMask => isolateStateToMaskMapping[_state] ?? 0;

  static const isolateStateToMaskMapping = {
    _IsolateState.pauseStart: PauseTypeMasks.pauseOnStartMask,
    _IsolateState.pausePostRequest: PauseTypeMasks.pauseOnReloadMask,
    _IsolateState.pauseExit: PauseTypeMasks.pauseOnExitMask,
  };

  final IsolateManager isolateManager;
  final CpuSamplesManager cpuSamplesManager;
  final String name;
  final String id;
  final Set<String?> _resumeApprovalsByName = {};
  _IsolateState? _state;
}

class IsolateManager {
  IsolateManager(this.dds);

  /// Handles state changes for isolates.
  void handleIsolateEvent(Event event) {
    // There's no interesting information about isolate state associated with
    // and IsolateSpawn event.
    // TODO(bkonyi): why isn't IsolateSpawn in package:vm_service
    if (event.kind! == ServiceEvents.isolateSpawn) {
      return;
    }

    final isolateData = event.isolate!;
    final id = isolateData.id!;
    final name = isolateData.name!;
    _updateIsolateState(id, name, event.kind!);
  }

  void routeEventToIsolate(Event event) {
    final isolateId = event.isolate!.id!;
    if (isolates.containsKey(isolateId)) {
      isolates[isolateId]!.handleEvent(event);
    }
  }

  void _updateIsolateState(String id, String name, String eventKind) {
    _mutex.runGuarded(
      () {
        switch (eventKind) {
          case ServiceEvents.isolateStart:
            isolateStarted(id, name);
            break;
          case ServiceEvents.isolateExit:
            isolateExited(id);
            break;
          default:
            final isolate = isolates[id];
            // The isolate may have disappeared after the state event was sent.
            if (isolate == null) {
              return;
            }
            switch (eventKind) {
              case ServiceEvents.pauseExit:
                isolate.pausedOnExit();
                break;
              case ServiceEvents.pausePostRequest:
                isolate.pausedPostRequest();
                break;
              case ServiceEvents.pauseStart:
                isolate.pausedOnStart();
                break;
              case ServiceEvents.resume:
                isolate.resumed();
                break;
              default:
                break;
            }
        }
      },
    );
  }

  /// Initializes the set of running isolates.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await _mutex.runGuarded(
      () async {
        final vm = await dds.vmServiceClient.sendRequest('getVM');
        final List<Map> isolateRefs =
            vm['isolates'].cast<Map<String, dynamic>>();
        // Check the pause event for each isolate to determine whether or not the
        // isolate is already paused.
        for (final isolateRef in isolateRefs) {
          final id = isolateRef['id'];
          final isolate = await dds.vmServiceClient.sendRequest('getIsolate', {
            'isolateId': id,
          });
          final name = isolate['name'];
          if (isolate.containsKey('pauseEvent')) {
            isolates[id] = _RunningIsolate(this, id, name);
            final eventKind = isolate['pauseEvent']['kind'];
            _updateIsolateState(id, name, eventKind);
          } else {
            // If the isolate doesn't have a pauseEvent, assume it's running.
            isolateStarted(id, name);
          }
        }
        if (dds.cachedUserTags.isNotEmpty) {
          await dds.vmServiceClient.sendRequest(
            'streamCpuSamplesWithUserTag',
            {
              'userTags': dds.cachedUserTags,
            },
          );
        }
      },
    );
    _initialized = true;
  }

  /// Initializes state for a newly started isolate.
  void isolateStarted(String id, String name) {
    final isolate = _RunningIsolate(this, id, name);
    isolate.running();
    isolates[id] = isolate;
  }

  /// Cleans up state for an isolate that has exited.
  void isolateExited(String id) {
    isolates.remove(id);
  }

  /// Handles `resume` RPC requests. If the client requires that approval be
  /// given before resuming an isolate, this method will:
  ///
  ///   - Update the approval state for the isolate.
  ///   - Resume the isolate if approval has been given by all clients which
  ///     require approval.
  ///
  /// Returns a collected sentinel if the isolate no longer exists.
  Future<Map<String, dynamic>> resumeIsolate(
    DartDevelopmentServiceClient client,
    json_rpc.Parameters parameters,
  ) async {
    return await _mutex.runGuarded(
      () async {
        final isolateId = parameters['isolateId'].asString;
        final isolate = isolates[isolateId];
        if (isolate == null) {
          return RPCResponses.collectedSentinel;
        }
        if (isolate.shouldResume(resumingClient: client)) {
          isolate.clearResumeApprovals();
          return await _sendResumeRequest(isolateId, parameters);
        }
        return RPCResponses.success;
      },
    );
  }

  Future<Map<String, dynamic>> getCachedCpuSamples(
      json_rpc.Parameters parameters) async {
    final isolateId = parameters['isolateId'].asString;
    if (!isolates.containsKey(isolateId)) {
      return RPCResponses.collectedSentinel;
    }
    final isolate = isolates[isolateId]!;
    final userTag = parameters['userTag'].asString;
    return await isolate.getCachedCpuSamples(userTag);
  }

  /// Forwards a `resume` request to the VM service.
  Future<Map<String, dynamic>> _sendResumeRequest(
    String isolateId,
    json_rpc.Parameters parameters,
  ) async {
    const invalidFrameIndex = -1;
    final step = parameters['step'].asStringOr('');
    final frameIndex = parameters['frameIndex'].asIntOr(invalidFrameIndex);
    final resumeResult = await dds.vmServiceClient.sendRequest('resume', {
      'isolateId': isolateId,
      if (step.isNotEmpty) 'step': step,
      if (frameIndex != invalidFrameIndex) 'frameIndex': frameIndex,
    });
    return resumeResult;
  }

  bool _initialized = false;
  final DartDevelopmentServiceImpl dds;
  final _mutex = Mutex();
  final Map<String, _RunningIsolate> isolates = {};
}
