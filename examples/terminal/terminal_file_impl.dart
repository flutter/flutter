// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:core';
import 'dart:mojo.core';
import 'package:mojo/services/files/public/interfaces/file.mojom.dart' as files;
import 'package:mojo/services/files/public/interfaces/types.mojom.dart' as files;

import 'terminal_display.dart';

// This implements a |mojo.files.File| that acts like a (pseudo)terminal. Bytes
// written to the |File| will be read by this implementation and passed on to
// the (Dart) |TerminalDisplay| (using |putChar()|). A read from the |File| will
// be completed if/when |TerminalDisplay| makes a byte available (via
// |getChar()|).
// TODO(vtl): This implementation is very incomplete.
class TerminalFileImpl implements files.File {
  final files.FileStub stub;
  final TerminalDisplay _display;

  TerminalFileImpl(this._display) : stub = new files.FileStub.unbound() {
    stub.impl = this;
  }

  // |files.File| implementation:

  @override
  Future close(Function responseFactory) async {
    // TODO(vtl): We should probably do more than just say OK.
    return responseFactory(files.Error_OK);
  }

  @override
  Future read(int numBytesToRead, int offset, int whence,
      Function responseFactory) async {
    if (numBytesToRead < 0) {
      return responseFactory(files.Error_INVALID_ARGUMENT, null);
    }

    // TODO(vtl): Error if |offset|/|whence| not appropriate.

    if (numBytesToRead == 0) {
      return responseFactory(files.Error_OK, []);
    }

    return responseFactory(files.Error_OK, [await _display.getChar()]);
  }

  @override
  Future write(List<int> bytesToWrite, int offset, int whence,
      Function responseFactory) async {
    // TODO(vtl): Error if |offset|/|whence| not appropriate.

    for (var c in bytesToWrite) {
      _display.putChar(c);
    }
    return responseFactory(files.Error_OK, bytesToWrite.length);
  }

  @override
  Future readToStream(MojoDataPipeProducer source, int offset, int whence,
      int numBytesToRead, Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED);
  }

  @override
  Future writeFromStream(MojoDataPipeConsumer sink, int offset, int whence,
      Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED);
  }

  @override
  Future tell(Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED, 0);
  }

  @override
  Future seek(int offset, int whence, Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED, 0);
  }

  @override
  Future stat(Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED, null);
  }

  @override
  Future truncate(int size, Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED);
  }

  @override
  Future touch(files.TimespecOrNow atime, files.TimespecOrNow mtime,
      Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED);
  }

  @override
  Future dup(Object file, Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED);
  }

  @override
  Future reopen(Object file, int openFlags, Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED);
  }

  @override
  Future asBuffer(Function responseFactory) async {
    // TODO(vtl)
    return responseFactory(files.Error_UNIMPLEMENTED, null);
  }
}
