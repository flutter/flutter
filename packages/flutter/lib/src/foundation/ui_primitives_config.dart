import 'ui_primitives.dart';

/// Configures the error reporting for the ui_primitives package.
void configureErrorReportingInUiPrimitives() {
  FrameworkErrorReporter.instance = _FlutterErrorReporter();
}

class _FlutterErrorReporter implements FrameworkErrorReporter {
  @override
  FrameworkError errorByDetails(FrameworkErrorDetails details) {
    // TODO: implement errorByDetails
    throw UnimplementedError();
  }

  @override
  FrameworkError errorByMessage(String message) {
    return FlutterError(message);
  }

  @override
  void report(FrameworkErrorDetails details) {
    // TODO: implement report
  }
}
