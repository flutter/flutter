

import 'package:flutter/widgets.dart';

import 'binding.dart';

/// Ensure the [WidgetsBinding] is initialized.
WidgetsBinding ensureInitialized([@visibleForTesting Map<String, String> environment]) {
  AutomatedTestWidgetsFlutterBinding();
  assert(WidgetsBinding.instance is TestWidgetsFlutterBinding);
  return WidgetsBinding.instance;
}

/// This method is a noop on the web.
void setupHttpOverrides() { }

/// This method is a noop on the web.
void mockFlutterAssets() { }
