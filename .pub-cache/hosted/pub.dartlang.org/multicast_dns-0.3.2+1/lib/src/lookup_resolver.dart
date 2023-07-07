// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:multicast_dns/src/resource_record.dart';

/// Class for maintaining state about pending mDNS requests.
class PendingRequest extends LinkedListEntry<PendingRequest> {
  /// Creates a new PendingRequest.
  PendingRequest(this.type, this.domainName, this.controller);

  /// The [ResourceRecordType] of the request.
  final int type;

  /// The domain name to look up via mDNS.
  ///
  /// For example, `'_http._tcp.local` to look up HTTP services on the local
  /// domain.
  final String domainName;

  /// A StreamController managing the request.
  final StreamController<ResourceRecord> controller;

  /// The timer for the request.
  Timer? timer;
}

/// Class for keeping track of pending lookups and processing incoming
/// query responses.
class LookupResolver {
  final LinkedList<PendingRequest> _pendingRequests =
      LinkedList<PendingRequest>();

  /// Adds a request and returns a [Stream] of [ResourceRecord] responses.
  Stream<T> addPendingRequest<T extends ResourceRecord>(
      int type, String name, Duration timeout) {
    final StreamController<T> controller = StreamController<T>();
    final PendingRequest request = PendingRequest(type, name, controller);
    final Timer timer = Timer(timeout, () {
      request.unlink();
      controller.close();
    });
    request.timer = timer;
    _pendingRequests.add(request);
    return controller.stream;
  }

  /// Parses [ResoureRecord]s received and delivers them to the appropriate
  /// listener(s) added via [addPendingRequest].
  void handleResponse(List<ResourceRecord> response) {
    for (final ResourceRecord r in response) {
      final int type = r.resourceRecordType;
      String name = r.name.toLowerCase();
      if (name.endsWith('.')) {
        name = name.substring(0, name.length - 1);
      }

      bool responseMatches(PendingRequest request) {
        String requestName = request.domainName.toLowerCase();
        // make, e.g. "_http" become "_http._tcp.local".
        if (!requestName.endsWith('local')) {
          if (!requestName.endsWith('._tcp.local') &&
              !requestName.endsWith('._udp.local') &&
              !requestName.endsWith('._tcp') &&
              !requestName.endsWith('.udp')) {
            requestName += '._tcp';
          }
          requestName += '.local';
        }
        return requestName == name && request.type == type;
      }

      for (final PendingRequest pendingRequest in _pendingRequests) {
        if (responseMatches(pendingRequest)) {
          if (pendingRequest.controller.isClosed) {
            return;
          }
          pendingRequest.controller.add(r);
        }
      }
    }
  }

  /// Removes any pending requests and ends processing.
  void clearPendingRequests() {
    while (_pendingRequests.isNotEmpty) {
      final PendingRequest request = _pendingRequests.first;
      request.unlink();
      request.timer?.cancel();
      request.controller.close();
    }
  }
}
