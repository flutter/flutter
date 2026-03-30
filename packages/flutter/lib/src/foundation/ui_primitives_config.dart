import 'package:ui_primitives/ui_primitives.dart';

import 'assertions.dart';
import 'diagnostics.dart';

/// Configures the error reporting for the ui_primitives package.
void configureErrorReportingInUiPrimitives() {
  FrameworkErrorReporter.instance = _FlutterErrorReporter();
}

class _FlutterErrorReporter implements FrameworkErrorReporter {
  @override
  Error error(String message) => FlutterError(message);

  @override
  void report(FrameworkErrorDetails details) {
    final Type? type = details.dispatchingObject?.runtimeType;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: details.exception,
        stack: details.stack,
        library: 'foundation library',
        informationCollector: () => <DiagnosticsNode>[
          DiagnosticsProperty(
            'The $type sending notification was',
            details.dispatchingObject,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ],
        context: ErrorDescription('while dispatching notifications for $type'),
      ),
    );
  }
}
