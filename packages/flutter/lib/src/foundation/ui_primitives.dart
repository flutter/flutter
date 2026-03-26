// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui_primitives/ui_primitives.dart' as ui_primitives;
export 'package:ui_primitives/ui_primitives.dart'
    show
        DebugPrintCallback,
        DiagnosticLevel,
        DiagnosticPropertiesBuilder,
        Diagnosticable,
        DiagnosticableNode,
        DiagnosticableTree,
        DiagnosticableTreeMixin,
        DiagnosticableTreeNode,
        DiagnosticsBlock,
        DiagnosticsNode,
        DiagnosticsProperty,
        DiagnosticsSerializationDelegate,
        DiagnosticsStackTrace,
        DiagnosticsTreeStyle,
        DoubleProperty,
        EnumProperty,
        ErrorDescription,
        ErrorHint,
        ErrorSpacer,
        ErrorSummary,
        FlagProperty,
        FlagsSummary,
        IntProperty,
        IterableProperty,
        Listenable,
        MessageProperty,
        ObjectFlagProperty,
        PartialStackFrame,
        PercentProperty,
        RepetitiveStackFrameFilter,
        StackFilter,
        StackFrame,
        StringProperty,
        TextTreeConfiguration,
        TextTreeRenderer,
        ValueListenable,
        ValueNotifier,
        VoidCallback,
        debugPrint,
        debugPrintStack,
        debugPrintSynchronously,
        debugPrintThrottled,
        debugWordWrap,
        describeEnum,
        describeIdentity,
        kNoDefaultValue,
        shortHash,
        singleLineTextConfiguration,
        sparseTextConfiguration;

/// Error class used to report Flutter-specific assertion failures and
/// contract violations.
///
/// See also:
///
///  * <https://docs.flutter.dev/testing/errors>, more information about error
///    handling in Flutter.
typedef FlutterError = ui_primitives.UiError;

/// Class for information provided to [FlutterExceptionHandler] callbacks.
///
/// {@tool snippet}
/// This is an example of using [UiErrorDetails] when calling
/// [UiError.reportError].
///
/// ```dart
/// void main() {
///   try {
///     // Try to do something!
///   } catch (error) {
///     // Catch & report error.
///     FlutterError.reportError(FlutterErrorDetails(
///       exception: error,
///       library: 'Flutter test framework',
///       context: ErrorSummary('while running async test code'),
///     ));
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///   * [UiError.onError], which is called whenever the Flutter framework
///     catches an error.
typedef FlutterErrorDetails = ui_primitives.UiErrorDetails;
