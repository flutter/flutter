// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';

import '../framework/cocoon.dart';

class UploadMetricsCommand extends Command<void> {
  UploadMetricsCommand() {
    argParser.addOption('results-file', help: 'Test results JSON to upload to Cocoon.');
    argParser.addOption(
      'service-account-token-file',
      help: 'Authentication token for uploading results.',
    );
  }

  @override
  String get name => 'upload-metrics';

  @override
  String get description => '[Flutter infrastructure] Upload metrics data to Cocoon';

  @override
  Future<void> run() async {
    final String resultsPath = argResults['results-file'] as String;
    final String serviceAccountTokenFile = argResults['service-account-token-file'] as String;

    final Cocoon cocoon = Cocoon(serviceAccountTokenPath: serviceAccountTokenFile);
    return cocoon.sendResultsPath(resultsPath);
  }
}
