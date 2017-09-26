// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import 'context.dart';

Flags get flags => context?.getVariable(Flags) ?? const _EmptyFlags();

class Flags {
  Flags(this._globalResults) {
    assert(_globalResults != null);
  }

  final ArgResults _globalResults;

  dynamic operator [](String key) {
    final ArgResults commandResults = _globalResults.command;
    if (commandResults?.options?.contains(key) ?? false) {
      return commandResults[key];
    } else if (_globalResults.options.contains(key)) {
      return _globalResults[key];
    }
    return null;
  }
}

class _EmptyFlags implements Flags {
  const _EmptyFlags();

  @override
  ArgResults get _globalResults => null;

  @override
  String operator [](String key) => null;
}
