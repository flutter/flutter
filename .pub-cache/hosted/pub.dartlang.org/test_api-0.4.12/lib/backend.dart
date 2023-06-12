// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('package:test_api is not intended for general use. '
    'Please use package:test.')
library test_api.backend;

export 'src/backend/metadata.dart' show Metadata;
export 'src/backend/platform_selector.dart' show PlatformSelector;
export 'src/backend/remote_exception.dart' show RemoteException;
export 'src/backend/remote_listener.dart' show RemoteListener;
export 'src/backend/runtime.dart' show Runtime;
export 'src/backend/stack_trace_formatter.dart' show StackTraceFormatter;
export 'src/backend/stack_trace_mapper.dart' show StackTraceMapper;
export 'src/backend/suite_platform.dart' show SuitePlatform;
