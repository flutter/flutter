import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// This should be used when you need to put a widget on top of the webview.
///
/// This does nothing on mobile, but on web it will allow the child widget to
/// intercept gestures.
class WebViewAware extends StatelessWidget {
  /// Child widget
  final Widget child;

  /// If set to true, a red box will appear around the widget
  final bool debug;

  /// Constructor
  const WebViewAware({
    Key? key,
    required this.child,
    this.debug = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      key: key,
      debug: debug,
      child: child,
    );
  }
}
