// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import 'context.dart';

class BotDetector {
  BotDetector({
    @required Platform platform,
  }) : _platform = platform;

  final Platform _platform;

  bool get isRunningOnBot {
    if (
        // Explicitly stated to not be a bot.
        _platform.environment['BOT'] == 'false'

        // Set by the IDEs to the IDE name, so a strong signal that this is not a bot.
        || _platform.environment.containsKey('FLUTTER_HOST')
        // When set, GA logs to a local file (normally for tests) so we don't need to filter.
        || _platform.environment.containsKey('FLUTTER_ANALYTICS_LOG_FILE')
    ) {
      return false;
    }

    return _platform.environment['BOT'] == 'true'

        // https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
        || _platform.environment['TRAVIS'] == 'true'
        || _platform.environment['CONTINUOUS_INTEGRATION'] == 'true'
        || _platform.environment.containsKey('CI') // Travis and AppVeyor

        // https://www.appveyor.com/docs/environment-variables/
        || _platform.environment.containsKey('APPVEYOR')

        // https://cirrus-ci.org/guide/writing-tasks/#environment-variables
        || _platform.environment.containsKey('CIRRUS_CI')

        // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
        || (_platform.environment.containsKey('AWS_REGION') &&
            _platform.environment.containsKey('CODEBUILD_INITIATOR'))

        // https://wiki.jenkins.io/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-belowJenkinsSetEnvironmentVariables
        || _platform.environment.containsKey('JENKINS_URL')

        // Properties on Flutter's Chrome Infra bots.
        || _platform.environment['CHROME_HEADLESS'] == '1'
        || _platform.environment.containsKey('BUILDBOT_BUILDERNAME')
        || _platform.environment.containsKey('SWARMING_TASK_ID');
  }
}

bool isRunningOnBot(Platform platform) {
  final BotDetector botDetector = context.get<BotDetector>() ?? BotDetector(platform: platform);
  return botDetector.isRunningOnBot;
}
