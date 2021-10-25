// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_ui/widgets/create_release_substeps.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../common.dart';

/// A fake class to be mocked in order to test if nextStep is being called.
class FakeNextStep {
  void nextStep() {}
}

const String _flutterRoot = '/flutter';
const String _checkoutsParentDirectory = '$_flutterRoot/dev/tools/';

void main() {
  const String candidateBranch = 'flutter-1.2-candidate.3';
  const String releaseChannel = 'dev';
  const String frameworkMirror = 'git@github.com:test/flutter.git';
  const String engineMirror = 'git@github.com:test/engine.git';
  const String engineCherrypick = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0,94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
  const String frameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
  const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
  const String increment = 'y';

  group('Capture and validate all parameters of a release initialization', () {
    testWidgets('Widget should capture all parameters correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.enterText(find.byKey(const Key('Candidate Branch')), candidateBranch);

      final StatefulElement createReleaseSubsteps = tester.element(find.byType(CreateReleaseSubsteps));
      final CreateReleaseSubstepsState createReleaseSubstepsState =
          createReleaseSubsteps.state as CreateReleaseSubstepsState;

      /// Tests the Release Channel dropdown menu.
      await tester.tap(find.byKey(const Key('Release Channel')));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData['Release Channel'], equals(null));
      await tester.tap(find.text(releaseChannel).last);
      await tester.pumpAndSettle(); // finish the menu animation

      await tester.enterText(find.byKey(const Key('Framework Mirror')), frameworkMirror);
      await tester.enterText(find.byKey(const Key('Engine Mirror')), engineMirror);
      await tester.enterText(find.byKey(const Key('Engine Cherrypicks (if necessary)')), engineCherrypick);
      await tester.enterText(find.byKey(const Key('Framework Cherrypicks (if necessary)')), frameworkCherrypick);
      await tester.enterText(find.byKey(const Key('Dart Revision (if necessary)')), dartRevision);

      /// Tests the Increment dropdown menu.
      await tester.tap(find.byKey(const Key('Increment')));
      await tester.pumpAndSettle(); // finish the menu animation
      expect(createReleaseSubstepsState.releaseData['Increment'], equals(null));
      await tester.tap(find.text(increment).last);
      await tester.pumpAndSettle(); // finish the menu animation

      expect(
        createReleaseSubstepsState.releaseData,
        equals(
          <String, String>{
            'Candidate Branch': candidateBranch,
            'Release Channel': releaseChannel,
            'Framework Mirror': frameworkMirror,
            'Engine Mirror': engineMirror,
            'Engine Cherrypicks (if necessary)': engineCherrypick,
            'Framework Cherrypicks (if necessary)': frameworkCherrypick,
            'Dart Revision (if necessary)': dartRevision,
            'Increment': increment,
          },
        ),
      );
    });
  });

  group('The desktop app is connected with the CLI conductor', () {
    const String exceptionMsg = 'There is a conductor Exception';

    testWidgets('Is able to display a conductor exception in the UI', (WidgetTester tester) async {
      final FakeStartContext startContext = FakeStartContext();

      startContext.addCommand(FakeCommand(
        command: const <String>['git', 'clone', '--origin', 'upstream', '--', EngineRepository.defaultUpstream, '${_checkoutsParentDirectory}flutter_conductor_checkouts/engine'],
        onRun: () => throw ConductorException(exceptionMsg),
      ));

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });

    testWidgets('Is able to display a general exception in the UI', (WidgetTester tester) async {
      final FakeStartContext startContext = FakeStartContext();
      const String exceptionMsg = 'There is a general Exception';

      startContext.addCommand(FakeCommand(
        command: const <String>['git', 'clone', '--origin', 'upstream', '--', EngineRepository.defaultUpstream, '${_checkoutsParentDirectory}flutter_conductor_checkouts/engine'],
        onRun: () => throw Exception(exceptionMsg),
      ));

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));

      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.textContaining(exceptionMsg), findsOneWidget);
    });

    testWidgets('Proceeds to the next step if there is no exception', (WidgetTester tester) async {
      final StartContext startContext = FakeStartContext();
      final FakeNextStep fakeNextStep = FakeNextStep();

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: fakeNextStep.nextStep,
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
    });

    testWidgets('Is able to display the loading UI, and hides it after release is done', (WidgetTester tester) async {
      final FakeStartContext startContext = FakeStartContext();

      // This completer signifies the completion of `startContext.run()`
      // function
      final Completer<void> completer = Completer<void>();

      startContext.addCommand(FakeCommand(
        command: const <String>['git', 'clone', '--origin', 'upstream', '--', EngineRepository.defaultUpstream, '${_checkoutsParentDirectory}flutter_conductor_checkouts/engine'],
        completer: completer,
      ));

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Material(
                child: ListView(
                  children: <Widget>[
                    CreateReleaseSubsteps(
                      nextStep: () {},
                      startContext: startContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final Finder continueButton = find.byKey(const Key('step1continue'));
      expect(continueButton, findsOneWidget);
      await tester.drag(continueButton, const Offset(-250, 0));
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, false);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<ElevatedButton>(continueButton).enabled, true);
    });
  });
}

class FakeStartContext extends StartContext {
  factory FakeStartContext({
    String candidateBranch = 'flutter-1.2-candidate.3',
    Checkouts? checkouts,
    String? dartRevision,
    List<String> engineCherrypickRevisions = const <String>[],
    String engineMirror = 'git@github:user/engine',
    String engineUpstream = EngineRepository.defaultUpstream,
    List<String> frameworkCherrypickRevisions = const <String>[],
    String frameworkMirror = 'git@github:user/flutter',
    String frameworkUpstream = FrameworkRepository.defaultUpstream,
    Directory? flutterRoot,
    String incrementLetter = 'm',
    FakeProcessManager? processManager,
    String releaseChannel = 'dev',
    File? stateFile,
    Stdio? stdio,
  }) {
    final FileSystem fileSystem = MemoryFileSystem.test();
    flutterRoot ??= fileSystem.directory(_flutterRoot);
    stateFile ??= fileSystem.file(kStateFileName);
    final Platform platform = FakePlatform(
      environment: <String, String>{'HOME': '/path/to/user/home'},
      operatingSystem: const LocalPlatform().operatingSystem,
      pathSeparator: r'/',
    );
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    stdio ??= TestStdio();
    checkouts = Checkouts(
      fileSystem: fileSystem,
      parentDirectory: fileSystem.directory(_checkoutsParentDirectory),
      platform: platform,
      processManager: processManager,
      stdio: stdio,
    );
    return FakeStartContext._(
        candidateBranch: candidateBranch,
        checkouts: checkouts,
        dartRevision: dartRevision,
        engineCherrypickRevisions: engineCherrypickRevisions,
        engineMirror: engineMirror,
        engineUpstream: engineUpstream,
        flutterRoot: flutterRoot,
        frameworkCherrypickRevisions: frameworkCherrypickRevisions,
        frameworkMirror: frameworkMirror,
        frameworkUpstream: frameworkUpstream,
        incrementLetter: incrementLetter,
        processManager: processManager,
        releaseChannel: releaseChannel,
        stateFile: stateFile,
        stdio: stdio,
    );
  }

  FakeStartContext._({
    required String candidateBranch,
    required Checkouts checkouts,
    String? dartRevision,
    required List<String> engineCherrypickRevisions,
    required String engineMirror,
    required String engineUpstream,
    required List<String> frameworkCherrypickRevisions,
    required String frameworkMirror,
    required String frameworkUpstream,
    required Directory flutterRoot,
    required String incrementLetter,
    required ProcessManager processManager,
    required String releaseChannel,
    required File stateFile,
    required Stdio stdio,
  }) : super(
        candidateBranch: candidateBranch,
        checkouts: checkouts,
        dartRevision: dartRevision,
        engineCherrypickRevisions: engineCherrypickRevisions,
        engineMirror: engineMirror,
        engineUpstream: engineUpstream,
        flutterRoot: flutterRoot,
        frameworkCherrypickRevisions: frameworkCherrypickRevisions,
        frameworkMirror: frameworkMirror,
        frameworkUpstream: frameworkUpstream,
        incrementLetter: incrementLetter,
        processManager: processManager,
        releaseChannel: releaseChannel,
        stateFile: stateFile,
        stdio: stdio,
  );

  void addCommand(FakeCommand command) {
    (checkouts.processManager as FakeProcessManager).addCommand(command);
  }

  void addCommands(List<FakeCommand> commands) {
    (checkouts.processManager as FakeProcessManager).addCommands(commands);
  }
}
