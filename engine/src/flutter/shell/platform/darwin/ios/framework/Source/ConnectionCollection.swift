// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// A collection of active channel connections, tracked by unique IDs.
///
/// ConnectionIDs are guaranteed to be positive Int64s.
///
/// This class is not thread-safe. All accesses should happen from the
/// platform thread.
@objc(FlutterConnectionCollection)
public class ConnectionCollection: NSObject {
  public typealias ConnectionID = Int64

  // The connection ID of the most recently used connection, or 0 if none.
  private var counter: ConnectionID = 0

  // Active connections map of channel name to connection ID.
  private var connections: [String: ConnectionID] = [:]

  /// Acquires a new connection for the specified channel.
  @objc public func acquireConnection(forChannel channel: String) -> ConnectionID {
    counter += 1
    connections[channel] = counter
    return counter
  }

  /// Cleans up an active connection.
  ///
  /// Returns the name of the associated channel if successful, otherwise the
  /// empty string.
  @objc public func cleanupConnection(withID connectionID: ConnectionID) -> String {
    guard
      connectionID > 0,
      let entry = connections.first(where: { $0.value == connectionID })
    else { return "" }

    connections[entry.key] = nil
    return entry.key
  }

  /// Creates an error connection from an error code.
  @objc public static func makeErrorConnection(errorCode: Int64) -> ConnectionID {
    return abs(errorCode)
  }
}
