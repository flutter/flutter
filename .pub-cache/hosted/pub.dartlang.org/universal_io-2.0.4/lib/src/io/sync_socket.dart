// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../io_impl_js.dart';

/// A low-level class for communicating synchronously over a TCP socket.
///
/// Warning: [RawSynchronousSocket] should probably only be used to connect to
/// 'localhost'. The operations below will block the calling thread to wait for
/// a response from the network. The thread can process no other events while
/// waiting for these operations to complete. [RawSynchronousSocket] is not
/// suitable for applications that require high performance or asynchronous I/O
/// such as a server. Instead such applications should use the non-blocking
/// sockets and asynchronous operations in the Socket or RawSocket classes.
abstract class RawSynchronousSocket {
  /// The [InternetAddress] used to connect this socket.
  InternetAddress get address;

  /// The port used by this socket.
  int get port;

  /// The remote [InternetAddress] connected to by this socket.
  InternetAddress get remoteAddress;

  /// The remote port connected to by this socket.
  int get remotePort;

  /// Returns the number of received and unread bytes in the socket that can be
  /// read.
  int available();

  /// Closes the [RawSynchronousSocket].
  ///
  /// Once [closeSync] has been called, attempting to call [readSync],
  /// [readIntoSync], [writeFromSync], [remoteAddress], and [remotePort] will
  /// cause a [SocketException] to be thrown.
  void closeSync();

  /// Reads into an existing [List<int>] from the socket into the range:
  /// [[start],[end]).
  ///
  /// Reads into an existing [List<int>] from the socket. If [start] is present,
  /// the bytes will be filled into [buffer] from index [start], otherwise index
  /// 0. If [end] is present, [end] - [start] bytes will be read into [buffer],
  /// otherwise up to [buffer.length]. If [end] == [start], no bytes are read.
  /// Returns the number of bytes read.
  int readIntoSync(List<int> buffer, [int start = 0, int? end]);

  /// Reads up to [bytes] bytes from the socket.
  ///
  /// Blocks and waits for a response of up to a specified number of bytes
  /// sent by the socket. [bytes] specifies the maximum number of bytes to
  /// be read. Returns the list of bytes read, which could be less than the
  /// value specified by [bytes].
  List<int> readSync(int bytes);

  /// Shutdown a socket in the provided direction.
  ///
  /// Calling shutdown will never throw an exception and calling it several times
  /// is supported. If both [SocketDirection.receive] and [SocketDirection.send]
  /// directions are closed, the socket is closed completely, the same as if
  /// [closeSync] has been called.
  void shutdown(SocketDirection direction);

  /// Writes data from a specified range in a [List<int>] to the socket.
  ///
  /// Writes into the socket from a [List<int>]. If [start] is present, the bytes
  /// will be written to the socket starting from index [start]. If [start] is
  /// not present, the bytes will be written starting from index 0. If [end] is
  /// present, the [end] - [start] bytes will be written into the socket starting
  /// at index [start]. If [end] is not provided, [buffer.length] elements will
  /// be written to the socket starting from index [start]. If [end] == [start],
  /// nothing happens.
  void writeFromSync(List<int> buffer, [int start = 0, int? end]);

  /// Creates a new socket connection and returns a [RawSynchronousSocket].
  ///
  /// [host] can either be a [String] or an [InternetAddress]. If [host] is a
  /// [String], [connectSync] will perform a [InternetAddress.lookup] and try
  /// all returned [InternetAddress]es, until connected. Unless a
  /// connection was established, the error from the first failing connection is
  /// returned.
  static RawSynchronousSocket connectSync(host, int port) {
    throw UnsupportedError('RawSynchronousSocket is unsupported');
  }
}
