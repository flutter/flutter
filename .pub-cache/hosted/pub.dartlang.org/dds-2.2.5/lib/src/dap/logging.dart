// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart' as vm;

typedef Logger = void Function(String);

/// Wraps a [Logger] as a [vm/Log] to be passed to the VM Service library.
class VmServiceLogger extends vm.Log {
  final Logger _logger;

  VmServiceLogger(this._logger);

  @override
  void severe(String message) => _logger.call('ERROR: $message');

  @override
  void warning(String message) => _logger.call('WARN: $message');
}
