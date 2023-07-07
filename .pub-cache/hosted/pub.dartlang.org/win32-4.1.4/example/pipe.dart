// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates using named pipes from Dart. To run this example, open two
// separate command windows. In the first, run:
//   dart example\pipe.dart server
//
// In the second, run:
//   dart example\pipe.dart client
//
// The first window will connect to a pipe and then block until a client pipe is
// activated. When the client is opened, it will receive the message from the
// server pipe and then both will exit.
//
// Example based on the following blog post:
//   https://peter.bloomfield.online/introduction-to-win32-named-pipes-cpp/

import 'dart:ffi';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const pipeName = r'\\.\pipe\dart_pipe';
const pipeMessage = '*** Hello Pipe World ***';

/// A named pipe client
class ClientCommand extends Command<void> {
  @override
  String get name => 'client';
  @override
  String get description => 'Execute the named pipe client.';

  @override
  void run() {
    final lpPipeName = pipeName.toNativeUtf16();
    final lpBuffer = wsalloc(128);
    final lpNumBytesRead = calloc<DWORD>();
    try {
      stdout.writeln('Connecting to pipe...');
      final pipe = CreateFile(
          lpPipeName,
          GENERIC_READ,
          FILE_SHARE_READ | FILE_SHARE_WRITE,
          nullptr,
          OPEN_EXISTING,
          FILE_ATTRIBUTE_NORMAL,
          NULL);
      if (pipe == INVALID_HANDLE_VALUE) {
        stderr.writeln('Failed to connect to pipe.');
        exit(1);
      }

      stdout.writeln('Reading data from pipe...');
      final result = ReadFile(pipe, lpBuffer, 128, lpNumBytesRead, nullptr);
      if (result == NULL) {
        stderr.writeln('Failed to read data from the pipe.');
      } else {
        final numBytesRead = lpNumBytesRead.value;
        stdout
          ..writeln('Number of bytes read: $numBytesRead')
          ..writeln('Message: ${lpBuffer.toDartString()}');
      }

      CloseHandle(pipe);
      stdout.writeln('Done.');
    } finally {
      free(lpPipeName);
      free(lpBuffer);
      free(lpNumBytesRead);
    }
  }
}

/// A named pipe server.
class ServerCommand extends Command<void> {
  @override
  String get name => 'server';
  @override
  String get description => 'Execute the named pipe server.';

  @override
  void run() {
    final lpPipeName = pipeName.toNativeUtf16();
    final lpPipeMessage = pipeMessage.toNativeUtf16();
    final lpNumBytesWritten = calloc<DWORD>();
    try {
      final pipe = CreateNamedPipe(lpPipeName, PIPE_ACCESS_OUTBOUND,
          PIPE_TYPE_BYTE, 1, 0, 0, 0, nullptr);
      if (pipe == NULL || pipe == INVALID_HANDLE_VALUE) {
        stderr.writeln('Failed to create outbound pipe instance.');
        exit(1);
      }

      stdout.writeln('Sending data to pipe...');
      var result = ConnectNamedPipe(pipe, nullptr);
      if (result == NULL) {
        CloseHandle(pipe);
        stderr.writeln('Failed to make connection on named pipe.');
        exit(1);
      }

      result = WriteFile(pipe, lpPipeMessage, pipeMessage.length * 2,
          lpNumBytesWritten, nullptr);
      if (result == NULL) {
        stderr.writeln('Failed to send data.');
      } else {
        final numBytesWritten = lpNumBytesWritten.value;
        stdout.writeln('Number of bytes sent: $numBytesWritten');
      }
      CloseHandle(pipe);
      stdout.writeln('Done.');
    } finally {
      free(lpPipeName);
      free(lpPipeMessage);
      free(lpNumBytesWritten);
    }
  }
}

void main(List<String> args) {
  CommandRunner<void>('pipe', 'A demonstration of Win32 named pipes.')
    ..addCommand(ClientCommand())
    ..addCommand(ServerCommand())
    ..run(args);
}
