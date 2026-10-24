// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import 'platform.dart';

class BotDetector {
  const BotDetector({required this._platform});

  final Platform _platform;

  bool get isRunningOnBot {
    final Map<String, String> environment = _platform.environment;
    // Set by IDEs to the IDE name, so a strong signal that this is not a bot.
    if (environment.containsKey('FLUTTER_HOST')) {
      return false;
    }
    // When set, GA logs to a local file (normally for tests) so we don't need to filter.
    if (environment.containsKey('FLUTTER_ANALYTICS_LOG_FILE')) {
      return false;
    }

    return Analytics.isBot(environment);
  }
}
