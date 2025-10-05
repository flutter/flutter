// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/persistent_preferences.dart';
import 'package:test/fake.dart';
import 'package:widget_preview_scaffold/src/dtd/dtd_services.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/test_flutter_command_runner.dart';
import '../../../commands.shard/permeable/utils/project_testing_utils.dart';

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject();
}

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
          fs: MemoryFileSystem.test(),
          logger: logger,
          shutdownHooks: ShutdownHooks(),
          dtdLauncher: DtdLauncher(
            logger: logger,
            artifacts: globals.artifacts!,
            processManager: globals.processManager,
          ),
          onHotRestartPreviewerRequest: hotRestartRequestCompleter.complete,
          project: FakeFlutterProject(),
        );
        await dtdServer.launchAndConnect();

        // Connect to the DTD instance and invoke the hot restart endpoint.
        final dtd = WidgetPreviewScaffoldDtdServices();
        await dtd.connect(dtdUri: dtdServer.dtdUri);

        await dtd.hotRestartPreviewer();

        // Ensure the custom handler is actually invoked.
        await hotRestartRequestCompleter.future;
      },
      overrides: <Type, Generator>{ProcessManager: () => loggingProcessManager},
    );

    testUsingContext(
      'can set and retreive values from $PersistentPreferences',
      () async {
        dtdServer = WidgetPreviewDtdServices(
          fs: MemoryFileSystem.test(),
          logger: logger,
          shutdownHooks: ShutdownHooks(),
          dtdLauncher: DtdLauncher(
            logger: logger,
            artifacts: globals.artifacts!,
            processManager: globals.processManager,
          ),
          onHotRestartPreviewerRequest: () {},
          project: FakeFlutterProject(),
        );
        await dtdServer.launchAndConnect();

        // The properties file should be created by the PersistentProperties constructor.
        final File preferencesFile = dtdServer.preferences.file;
        expect(preferencesFile.existsSync(), true);

        // Connect to the DTD instance.
        final dtd = WidgetPreviewScaffoldDtdServices();
        await dtd.connect(dtdUri: dtdServer.dtdUri);

        const kTestKey = 'myKey';

        // The preferences file should be empty.
        expect(await dtd.getPreference(kTestKey), null);
        expect(preferencesFile.readAsStringSync(), isEmpty);

        // Set a preference and ensure it's read back.
        const kFirstValue = 'foo';
        await dtd.setPreference(kTestKey, kFirstValue);
        expect(await dtd.getPreference(kTestKey), kFirstValue);
        expect(json.decode(preferencesFile.readAsStringSync()), {
          kTestKey: kFirstValue,
        });

        // Overwrite kTestKey and ensure it's read back.
        const kSecondValue = 'bar';
        await dtd.setPreference(kTestKey, kSecondValue);
        expect(await dtd.getPreference(kTestKey), kSecondValue);
        expect(json.decode(preferencesFile.readAsStringSync()), {
          kTestKey: kSecondValue,
        });

        // Write a flag.
        const kFlagKey = 'flag';
        await dtd.setPreference(kFlagKey, true);
        expect(await dtd.getFlag(kFlagKey), true);
        expect(json.decode(preferencesFile.readAsStringSync()), {
          kFlagKey: true,
          kTestKey: kSecondValue,
        });

        // Remove an entry.
        await dtd.setPreference(kTestKey, null);
        expect(await dtd.getPreference(kTestKey), null);
        expect(json.decode(preferencesFile.readAsStringSync()), {
          kFlagKey: true,
        });
      },
    );
  });
}
