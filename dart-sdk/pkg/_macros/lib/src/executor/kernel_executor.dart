// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../executor.dart';
import '../executor/serialization.dart';
import 'isolated_executor.dart' as isolated_executor;
import 'process_executor.dart' as process_executor;

/// Spawns a [MacroExecutor] as an isolate if possible, or with a new Dart
/// process if not.
///
/// Throws [StateError] if a Dart process is needed but the `dart` executable
/// can't be found next to [Platform.executable].
///
/// This is the only public api exposed by this library.
Future<MacroExecutor> start(SerializationMode serializationMode, Uri uriToSpawn,
    {List<String> arguments = const [], Uri? packageConfigUri}) {
  if (_isKernelRuntime) {
    return isolated_executor.start(serializationMode, uriToSpawn,
        arguments: arguments, packageConfigUri: packageConfigUri);
  }

  // Not running on the JIT, assume `dartaotruntime` or some other executable
  // in the SDK `bin` folder.
  File dartAotRuntime = File(Platform.resolvedExecutable);

  List<File> dartExecutables = ['dart', 'dart.exe']
      .map((name) => File.fromUri(dartAotRuntime.parent.uri.resolve(name)))
      .where((f) => f.existsSync())
      .toList();
  if (dartExecutables.isEmpty) {
    throw StateError('Failed to start macro executor from kernel: '
        "can't launch isolate and can't find dart executable next to "
        '${dartAotRuntime.path}.');
  }

  return process_executor.start(
      serializationMode,
      process_executor.CommunicationChannel.socket,
      dartExecutables.first.path,
      ['run', uriToSpawn.path, ...arguments]);
}

/// Note that this is lazy, by nature of being a final top level variable.
final bool _isKernelRuntime = _checkForKernelRuntime();

bool _checkForKernelRuntime() {
  // `createUriForKernelBlob` throws `UnsupportedError` if kernel blobs are not
  // supported at all. We don't actually want to register kernel so pass
  // invalid kernel, an empty list, resulting in an `ArgumentError` if kernel
  // blobs are supported.
  try {
    (Isolate.current as dynamic)
        .createUriForKernelBlob(Uint8List.fromList(const []));
    throw StateError('Expected failure.');
  } on UnsupportedError {
    return false;
  } on ArgumentError {
    return true;
  }
}
