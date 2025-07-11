// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/test_flutter_command_runner.dart';
import '../utils/project_testing_utils.dart';

void main() {
  late WidgetPreviewDtdServices dtdServer;
  late LoggingProcessManager loggingProcessManager;
  late Logger logger;

  setUp(() async {
    loggingProcessManager = LoggingProcessManager();
    logger = BufferLogger.test();
  });

  tearDown(() async {
    await dtdServer.shutdownHooks.runShutdownHooks(logger);
  });

  group('$WidgetPreviewDtdServices', () {
    testUsingContext(
      'handles ${WidgetPreviewDtdServices.kHotRestartPreviewer} invocations',
      () async {
        // Start DTD and register the widget preview DTD services with a custom handler for hot
        // restart requests.
        final hotRestartRequestCompleter = Completer<void>();
        dtdServer = WidgetPreviewDtdServices(
          logger: logger,
          shutdownHooks: ShutdownHooks(),
          dtdLauncher: DtdLauncher(
            logger: logger,
            artifacts: globals.artifacts!,
            processManager: globals.processManager,
          ),
          onHotRestartPreviewerRequest: hotRestartRequestCompleter.complete,
        );
        await dtdServer.launchAndConnect();

        // Connect to the DTD instance and invoke the hot restart endpoint.
        final DartToolingDaemon dtd = await DartToolingDaemon.connect(dtdServer.dtdUri!);
        final DTDResponse response = await dtd.call(
          WidgetPreviewDtdServices.kWidgetPreviewService,
          WidgetPreviewDtdServices.kHotRestartPreviewer,
        );

        // This will throw if the response is not an instance of Success.
        expect(() => Success.fromDTDResponse(response), returnsNormally);

        // Ensure the custom handler is actually invoked.
        await hotRestartRequestCompleter.future;
      },
      overrides: <Type, Generator>{ProcessManager: () => loggingProcessManager},
    );
  });
}
