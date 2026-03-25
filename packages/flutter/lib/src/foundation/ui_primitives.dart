// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui_primitives/ui_primitives.dart' as ui_primitives;
export 'package:ui_primitives/ui_primitives.dart'
    show
        DiagnosticLevel,
        DiagnosticPropertiesBuilder,
        Diagnosticable,
        DiagnosticsNode,
        DiagnosticsSerializationDelegate,
        DiagnosticsTreeStyle,
        ErrorDescription,
        Listenable,
        TextTreeConfiguration,
        ValueListenable,
        ValueNotifier,
        VoidCallback;

// TODO: consider renaming FlutterError to UiError
typedef FlutterError = ui_primitives.UiError;
typedef FlutterErrorDetails = ui_primitives.UiErrorDetails;
