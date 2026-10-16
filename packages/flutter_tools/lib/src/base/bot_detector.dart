// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'platform.dart';

class BotDetector {
  const BotDetector({required this._platform});

  final Platform _platform;

  Future<bool> get isRunningOnBot async {
    final String? bot = _platform.environment['BOT'];
    if ( // Explicitly stated to not be a bot.
    bot == 'false' ||
        bot == '0'
        // Set by the IDEs to the IDE name, so a strong signal that this is not a bot.
        ||
        _platform.environment.containsKey('FLUTTER_HOST')
        // When set, GA logs to a local file (normally for tests) so we don't need to filter.
        ||
        _platform.environment.containsKey('FLUTTER_ANALYTICS_LOG_FILE')) {
      return false;
    }

    final String? ci = _platform.environment['CI'];
    return bot == 'true' ||
        bot == '1'
        // https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
        ||
        _platform.environment['TRAVIS'] == 'true' ||
        _platform.environment['CONTINUOUS_INTEGRATION'] == 'true' ||
        (ci != null && ci.isNotEmpty && ci != 'false' && ci != '0') // Travis and AppVeyor
        // https://www.appveyor.com/docs/environment-variables/
        ||
        _platform.environment.containsKey('APPVEYOR')
        // https://cirrus-ci.org/guide/writing-tasks/#environment-variables
        ||
        _platform.environment.containsKey('CIRRUS_CI')
        // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html
        ||
        (_platform.environment.containsKey('AWS_REGION') &&
            _platform.environment.containsKey('CODEBUILD_INITIATOR'))
        // https://wiki.jenkins.io/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-belowJenkinsSetEnvironmentVariables
        ||
        _platform.environment.containsKey('JENKINS_URL')
        // https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables
        ||
        _platform.environment.containsKey('GITHUB_ACTIONS')
        // Properties on Flutter's Chrome Infra bots.
        ||
        _platform.environment['CHROME_HEADLESS'] == '1' ||
        _platform.environment.containsKey('BUILDBOT_BUILDERNAME') ||
        _platform.environment.containsKey('SWARMING_TASK_ID')
        // Property when running on borg.
        ||
        _platform.environment.containsKey('BORG_ALLOC_DIR')
        // Property when running on Azure.
        ||
        _platform.environment.containsKey('AZURE_HTTP_USER_AGENT')
        // https://learn.microsoft.com/en-us/azure/devops/pipelines/build/variables
        ||
        _platform.environment.containsKey('TF_BUILD');
  }
}
