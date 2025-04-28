// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// A collection of active channel connections, tracked by unique IDs.
@objc(FlutterConnectionCollection)
public class ConnectionCollection: NSObject {
  public typealias ConnectionId = Int64

  /// The connection ID of the most recently used connection, or 0 if none.
  private var counter: ConnectionId = 0

  /// Active connections map of channel name to connection ID.
  private var connections: [String: ConnectionId] = [:]

  /// Acquires a new connection for the specified channel.
  @objc(acquireConnectionForChannel:)
  public func acquireConnection(channel: String) -> ConnectionId {
    counter += 1
    connections[channel] = counter
    return counter
  }

  /// Cleans up an active connection.
  ///
  /// Returns the name of the associated channel if successful, otherwise the
  /// empty string.
  @objc(cleanup:)
  public func cleanup(connection: ConnectionId) -> String {
    if connection > 0 {
      for (key, value) in connections {
        if value == connection {
          connections.removeValue(forKey: key)
          return key
        }
      }
    }
    return ""
  }

  /// Creates an error connection from an error code.
  @objc public static func makeErrorConnection(errorCode: Int64) -> ConnectionId {
    return abs(errorCode)
  }
}
