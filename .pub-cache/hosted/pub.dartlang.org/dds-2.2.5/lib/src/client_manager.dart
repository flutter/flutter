// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'client.dart';
import 'constants.dart';
import 'dds_impl.dart';
import 'named_lookup.dart';
import 'stream_manager.dart';

/// [_ClientResumePermissions] associates a list of
/// [DartDevelopmentServiceClient]s, all of the same client name, with a
/// permissions mask used to determine which pause event types require approval
/// from one of the listed clients before resuming an isolate.
class _ClientResumePermissions {
  final List<DartDevelopmentServiceClient> clients = [];
  int permissionsMask = 0;
}

/// The [ClientManager] has the responsibility of managing all state and
/// requests related to client connections, including:
///   - A list of all currently connected clients
///   - Tracking client names and associated permissions for isolate resume
///     synchronization
///   - Handling RPC invocations which change client state
class ClientManager {
  ClientManager(this.dds);

  /// Initialize state for a newly connected client.
  void addClient(DartDevelopmentServiceClient client) {
    _setClientNameHelper(
      client,
      client.defaultClientName,
    );
    clients.add(client);
    client.listen().then((_) => removeClient(client));
    if (clients.length == 1) {
      dds.isolateManager.initialize().then((_) {
        dds.streamManager.streamListen(
          null,
          StreamManager.kDebugStream,
        );
      });
    }
  }

  /// Cleanup state for a disconnected client.
  void removeClient(DartDevelopmentServiceClient client) {
    _clearClientName(client);
    clients.remove(client);
    if (clients.isEmpty) {
      dds.streamManager.streamCancel(
        null,
        StreamManager.kDebugStream,
      );
    }
  }

  /// Cleanup clients on DDS shutdown.
  Future<void> shutdown() async {
    // Close all incoming websocket connections.
    final futures = <Future>[];
    // Copy `clients` to guard against modification while iterating.
    for (final client in clients.toList()) {
      futures.add(client.close());
    }
    await Future.wait(futures);
  }

  /// Associates a name with a given client.
  ///
  /// The provided client name is used to track isolate resume approvals.
  Map<String, dynamic> setClientName(
    DartDevelopmentServiceClient client,
    json_rpc.Parameters parameters,
  ) {
    _setClientNameHelper(client, parameters['name'].asString);
    return RPCResponses.success;
  }

  /// Require permission from this client before resuming an isolate.
  Map<String, dynamic> requirePermissionToResume(
    DartDevelopmentServiceClient client,
    json_rpc.Parameters parameters,
  ) {
    int pauseTypeMask = 0;
    if (parameters['onPauseStart'].asBoolOr(false)) {
      pauseTypeMask |= PauseTypeMasks.pauseOnStartMask;
    }
    if (parameters['onPauseReload'].asBoolOr(false)) {
      pauseTypeMask |= PauseTypeMasks.pauseOnReloadMask;
    }
    if (parameters['onPauseExit'].asBoolOr(false)) {
      pauseTypeMask |= PauseTypeMasks.pauseOnExitMask;
    }

    clientResumePermissions[client.name!]!.permissionsMask = pauseTypeMask;
    return RPCResponses.success;
  }

  /// Changes `client`'s name to `name` while also updating resume permissions
  /// and approvals.
  void _setClientNameHelper(
    DartDevelopmentServiceClient client,
    String name,
  ) {
    _clearClientName(client);
    client.name = name.isEmpty ? client.defaultClientName : name;
    clientResumePermissions.putIfAbsent(
      client.name!,
      () => _ClientResumePermissions(),
    );
    clientResumePermissions[client.name!]!.clients.add(client);
  }

  /// Resets the client's name while also cleaning up resume permissions and
  /// approvals.
  void _clearClientName(
    DartDevelopmentServiceClient client,
  ) {
    final name = client.name;
    client.name = null;
    final clientsForName = clientResumePermissions[name];
    if (clientsForName != null) {
      clientsForName.clients.remove(client);
      // If this was the last client with a given name, cleanup resume
      // permissions.
      if (clientsForName.clients.isEmpty) {
        clientResumePermissions.remove(name);

        // Check to see if we need to resume any isolates now that the last
        // client of a given name has disconnected or changed names.
        //
        // An isolate will be resumed in this situation if:
        //
        // 1) This client required resume approvals for the current pause event
        // associated with the isolate and all other required resume approvals
        // have been provided by other clients.
        //
        // OR
        //
        // 2) This client required resume approvals for the current pause event
        // associated with the isolate, no other clients require resume approvals
        // for the current pause event, and at least one client has issued a resume
        // request.
        dds.isolateManager.isolates.forEach(
          (_, isolate) async =>
              await isolate.maybeResumeAfterClientChange(name),
        );
      }
    }
  }

  DartDevelopmentServiceClient? findFirstClientThatHandlesService(
      String service) {
    for (final client in clients) {
      if (client.services.containsKey(service)) {
        return client;
      }
    }
    return null;
  }

  // Handles namespace generation for service extensions.
  static const _kServicePrologue = 's';
  final NamedLookup<DartDevelopmentServiceClient> clients = NamedLookup(
    prologue: _kServicePrologue,
  );

  /// Mapping of client names to all clients of that name and their resume
  /// permissions.
  final Map<String?, _ClientResumePermissions> clientResumePermissions = {};

  final DartDevelopmentServiceImpl dds;
}
