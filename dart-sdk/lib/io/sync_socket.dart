// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// A low-level class for communicating synchronously over a TCP socket.
///
/// Warning: [RawSynchronousSocket] should probably only be used to connect to
/// 'localhost'. The operations below will block the calling thread to wait for
/// a response from the network. The thread can process no other events while
/// waiting for these operations to complete. [RawSynchronousSocket] is not
/// suitable for applications that require high performance or asynchronous I/O
/// such as a server. Instead such applications should use the non-blocking
/// sockets and asynchronous operations in the [Socket] or [RawSocket] classes.
abstract interface class RawSynchronousSocket {
  /// Creates a new socket connection and returns a [RawSynchronousSocket].
  ///
  /// The [host] can either be a [String] or an [InternetAddress].
  /// If [host] is a [String], [connectSync] will perform a
  /// [InternetAddress.lookup] and try all returned [InternetAddress]es,
  /// until connected.
  /// Unless a connection was established,
  /// the error from the first failing connection is returned.
  external static RawSynchronousSocket connectSync(host, int port);

  /// The number of received and unread bytes in the socket that can be read.
  int available();

  /// Closes the [RawSynchronousSocket].
  ///
  /// Once [closeSync] has been called, attempting to call [readSync],
  /// [readIntoSync], [writeFromSync], [remoteAddress], and [remotePort] will
  /// cause a [SocketException] to be thrown.
  void closeSync();

  /// Reads bytes into an existing [buffer].
  ///
  /// Reads bytes and writes then into the range of [buffer]
  /// from [start] to [end].
  /// The [start] must be non-negative and no greater than [buffer].length.
  /// If [end] is omitted, it defaults to [buffer].length.
  /// Otherwise [end] must be no less than [start]
  /// and no greater than [buffer].length.
  ///
  /// Returns the number of bytes read. This maybe be less than `end - start`
  /// if the file doesn't have that many bytes to read.
  int readIntoSync(List<int> buffer, [int start = 0, int? end]);

  /// Reads up to [bytes] bytes from the socket.
  ///
  /// Blocks and waits for a response of up to a specified number of bytes
  /// sent by the socket. [bytes] specifies the maximum number of bytes to
  /// be read. Returns the list of bytes read, which could be less than the
  /// value specified by [bytes].
  List<int>? readSync(int bytes);

  /// Shuts down a socket in the provided direction.
  ///
  /// Calling shutdown will never throw an exception and calling it several times
  /// is supported. If both [SocketDirection.receive] and [SocketDirection.send]
  /// directions are closed, the socket is closed completely, the same as if
  /// [closeSync] has been called.
  void shutdown(SocketDirection direction);

  /// Writes from a [buffer] to the socket.
  ///
  /// Will read the buffer from index [start] to index [end].
  /// The [start] must be non-negative and no greater than [buffer].length.
  /// If [end] is omitted, it defaults to [buffer].length.
  /// Otherwise [end] must be no less than [start]
  /// and no greater than [buffer].length.
  void writeFromSync(List<int> buffer, [int start = 0, int? end]);

  /// The port used by this socket.
  int get port;

  /// The remote port connected to by this socket.
  int get remotePort;

  /// The [InternetAddress] used to connect this socket.
  InternetAddress get address;

  /// The remote [InternetAddress] connected to by this socket.
  InternetAddress get remoteAddress;
}
