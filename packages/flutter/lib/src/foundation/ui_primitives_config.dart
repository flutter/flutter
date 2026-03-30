import 'package:ui_primitives/ui_primitives.dart';

import 'assertions.dart';
import 'change_notifier.dart';
import 'diagnostics.dart';

/// Configures the error reporting for the ui_primitives package.
void configureErrorReportingInUiPrimitives() {
  FrameworkErrorReporter.instance = _FlutterErrorReporter();
}

class _FlutterErrorReporter implements FrameworkErrorReporter {
  @override
  FrameworkError errorByDetails(FrameworkErrorDetails details) {}

  @override
  Error errorByMessage(String message) => FlutterError(message);

  @override
  void report(FrameworkErrorDetails details) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: details.exception,
        stack: details.stack,
        library: 'foundation library',
        context: ErrorDescription('while dispatching notifications for ${details.runtimeType}'),
        informationCollector: () => <DiagnosticsNode>[
          DiagnosticsProperty<Listenable>(
            'The ${details.runtimeType} sending notification was',
            details.dispatchingObject,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ],
      ),
    );
  }

  DiagnosticsNode _node(Object? object) {
    if (object is Listenable) {
      return _property<Listenable>(object);
    }
    return DiagnosticsNode(object);
  }

  DiagnosticsProperty<T> _property<T>(T object) {
    return DiagnosticsProperty<T>(
      'The ${object.runtimeType} sending notification was',
      object,
      style: DiagnosticsTreeStyle.errorProperty,
    );
  }
}
