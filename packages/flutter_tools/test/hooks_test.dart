// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/hooks.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('parser', () {
    test('Hooks can deal with yaml of good format properly', () {
      final Hooks hooks = Hooks.fromYaml(yamlContentWithGoodFormat);

      expect(hooks.subhooks.length, 2);

      expect(hooks.subhooks[0].cmds.join(' '), 'doctor');
      expect(hooks.subhooks[0].beforeHookExecutable, 'perl');
      expect(hooks.subhooks[0].beforeHookArgument, 'flutter_tools_hook.pl');
      
      expect(hooks.subhooks[1].cmds.join(' '), 'build apk');
      expect(hooks.subhooks[1].beforeHookExecutable, 'python');
      expect(hooks.subhooks[1].beforeHookArgument, 'flutter_tools_hook.py');
    });

    test('Hooks can deal with yaml of bad format properly', () {
      Hooks hooks = Hooks.fromYaml(yamlContentWithBadFormat);
      expect(hooks.subhooks.length, 0);
      
      hooks = Hooks.fromYaml(null);
      expect(hooks.subhooks.length, 0);
    });
  });

  group('execution', () {
    MockProcessManager processManager;

    setUp(() {
      processManager = MockProcessManager();
    });

    testUsingContext('Hooks should execute as expected without argument', () async {
      final Hooks hooks = Hooks.fromYaml(yamlContentWithGoodFormat);
      final List<String> innerCommand = <String>['perl', 'flutter_tools_hook.pl'];
      when(processManager.runSync(
        innerCommand,
        workingDirectory: null,
        runInShell: true,
        ),
      ).thenReturn(ProcessResult(0, 0, 'OK', null));
      final ProcessResult processResult = await hooks.subhooks[0].runBeforeHook(null, null);
      expect(processResult.exitCode, 0);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    testUsingContext('Hooks should execute as expected with argument', () async {
      final Hooks hooks = Hooks.fromYaml(yamlContentWithGoodFormat);
      final List<String> innerCommand = <String>['/bin/sh', 'flutter_tools_hook.sh','"123"'];
      when(processManager.runSync(
        innerCommand,
        workingDirectory: null,
        runInShell: true,
        ),
      ).thenReturn(ProcessResult(0, 0, 'OK', null));
      final ProcessResult processResult = await hooks.subhooks[0].runAfterHook(null, <String>['123']);
      expect(processResult.exitCode, 0);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });
  });
}

const String yamlContentWithGoodFormat = '''
# Use the analysis options settings from the top level of the repo (not
# the ones from above, which include the `public_member_api_docs` rule).

commands:
  doctor:
    hook:
      before: 
        executable: "perl"
        argument: "flutter_tools_hook.pl"
      after: 
        executable: "/bin/sh"
        argument: "flutter_tools_hook.sh"
  build:
    apk:
      hook:
        before: 
          executable: "python"
          argument: "flutter_tools_hook.py"
        after: 
          executable: "ruby"
          argument: "flutter_tools_hook.rb"
''';

const String yamlContentWithBadFormat = '''
YAML CONTENT WITH BAD FORMAT
''';

class MockProcessManager extends Mock implements ProcessManager {}