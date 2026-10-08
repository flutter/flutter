// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../bin/android_embedder_ratchet.dart' as ratchet;

void main() {
  group('stripCommentsAndLiterals', () {
    test('removes line and block comments but keeps newlines', () {
      const source = 'a // Shell\nb /* Shell\n Shell */ c\n';
      expect(ratchet.stripCommentsAndLiterals(source), 'a \nb \n c\n');
    });

    test('empties string and character literals', () {
      const source = r'''x("Shell \" Shell"); y('"'); z('\'');''';
      expect(ratchet.stripCommentsAndLiterals(source), 'x(""); y(\'\'); z(\'\');');
    });

    test('empties raw string literals', () {
      const source = 'R"json({"Shell": 1})json" Shell';
      expect(ratchet.stripCommentsAndLiterals(source), 'R"" Shell');
    });

    test('does not treat digit separators as character literals', () {
      const source = "int x = 1'000; Shell s;";
      expect(ratchet.stripCommentsAndLiterals(source), source);
    });
  });

  group('isTestSource', () {
    test('matches unit tests, mocks and test directories', () {
      expect(
        ratchet.isTestSource('shell/platform/android/android_shell_holder_unittests.cc'),
        true,
      );
      expect(ratchet.isTestSource('shell/platform/android/jni/jni_mock.h'), true);
      expect(ratchet.isTestSource('shell/platform/android/jni/mock_jni_env.h'), true);
      expect(ratchet.isTestSource('shell/platform/android/surface/android_surface_mock.cc'), true);
      expect(ratchet.isTestSource('shell/platform/android/test/foo.cc'), true);
    });

    test('does not match production sources', () {
      expect(ratchet.isTestSource('shell/platform/android/android_shell_holder.cc'), false);
      expect(ratchet.isTestSource('shell/platform/android/platform_view_android.h'), false);
    });
  });

  group('includes', () {
    test('resolves engine includes with and without the flutter/ prefix', () {
      expect(ratchet.resolveEngineInclude('flutter/shell/common/shell.h'), 'shell/common/shell.h');
      expect(ratchet.resolveEngineInclude('common/settings.h'), 'common/settings.h');
      expect(ratchet.resolveEngineInclude('unicode/uchar.h'), isNull);
      expect(ratchet.resolveEngineInclude('local.h'), isNull);
    });

    test('classifies allowed, embedder-internal and engine-internal headers', () {
      expect(ratchet.isEngineInternalInclude('fml/logging.h'), false);
      expect(ratchet.isEngineInternalInclude('common/settings.h'), false);
      expect(ratchet.isEngineInternalInclude('common/graphics/texture.h'), true);
      expect(ratchet.isEngineInternalInclude('shell/platform/android/jni/jni.h'), false);
      expect(ratchet.isEngineInternalInclude('shell/common/shell.h'), true);
      expect(ratchet.isEngineInternalInclude('shell/platform/embedder/embedder_engine.h'), false);
      expect(ratchet.isEmbedderInternalInclude('shell/platform/embedder/embedder_engine.h'), true);
      expect(ratchet.isEmbedderInternalInclude('shell/platform/embedder/embedder.h'), false);
    });
  });

  group('gnDepLabels', () {
    const buildGn = '''
source_set("other") {
  deps = [ "//flutter/flow" ]
}

source_set("flutter_shell_native_src") {
  sources = [ "a.cc" ]  # A comment with a { brace.
  public_deps = [
    ":local",
    "//flutter/common",
    "//flutter/flow",
  ]
  if (enable_vulkan) {
    deps += [ "//flutter/vulkan" ]
  }
  deps = [
    "//flutter/fml:fml",
    "//flutter/shell/platform/android/jni",
    "//third_party/abseil",
  ]
}
''';

    test('collects deps and public_deps of the named target only', () {
      expect(ratchet.gnDepLabels(buildGn, 'flutter_shell_native_src'), <String>[
        ':local',
        '//flutter/common',
        '//flutter/flow',
        '//flutter/vulkan',
        '//flutter/fml:fml',
        '//flutter/shell/platform/android/jni',
        '//third_party/abseil',
      ]);
    });

    test('counts only disallowed engine labels', () {
      final List<String> disallowed = ratchet
          .gnDepLabels(buildGn, 'flutter_shell_native_src')
          .where(ratchet.isDisallowedGnLabel)
          .toList();
      expect(disallowed, <String>['//flutter/flow', '//flutter/vulkan']);
    });

    test('throws for a missing target', () {
      expect(
        () => ratchet.gnDepLabels(buildGn, 'missing'),
        throwsA(isA<ratchet.RatchetException>()),
      );
    });
  });

  group('measure', () {
    late io.Directory root;

    setUp(() {
      root = io.Directory.systemTemp.createTempSync('android_embedder_ratchet_test');
      void write(String relative, String contents) {
        io.File(path.join(root.path, relative))
          ..createSync(recursive: true)
          ..writeAsStringSync(contents);
      }

      write('shell/platform/android/android_shell_holder.cc', '''
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"
#include "common/settings.h"
#include "common/graphics/texture.h"
// Shell in a comment does not count.
std::unique_ptr<Shell> shell_;
Shell& GetShell() { return engine_->GetShell(); }
EmbedderEngine* engine_;
''');
      write('shell/platform/android/platform_view_android_jni_impl.cc', '''
ANDROID_SHELL_HOLDER->GetPlatformView()->ScheduleFrame();
ANDROID_SHELL_HOLDER -> GetPlatformView ()->SetSemanticsEnabled(true);
ANDROID_SHELL_HOLDER->GetEngineHandle();
''');
      write('shell/platform/android/platform_view_android.h', '''
class AndroidSurfaceFactoryImpl : public AndroidSurfaceFactory {
  ~AndroidSurfaceFactoryImpl() override;
  void C() override;
};
class PlatformViewAndroid final : public PlatformView {
  ~PlatformViewAndroid() override;
  void A() override;
  void B() override;  // override
};
''');
      write('shell/platform/android/android_shell_holder_unittests.cc', 'Shell Shell Shell');
      write('shell/platform/android/BUILD.gn', '''
source_set("flutter_shell_native_src") {
  public_deps = [ "//flutter/fml", "//flutter/flow" ]
}
''');
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    test('counts every metric in non-test sources', () {
      final Map<String, int> counts = ratchet.measure(ratchet.AndroidSources.load(root));
      expect(counts, <String, int>{
        'shell_refs': 2,
        'get_shell_calls': 2,
        'embedder_engine_refs': 1,
        'embedder_internal_includes': 1,
        'engine_internal_includes': 2,
        'jni_platform_view_calls': 2,
        'platform_view_android_overrides': 2,
        'gn_internal_deps': 1,
      });
    });
  });

  group('check', () {
    ratchet.RatchetFile recorded(int count, ratchet.Enforcement enforcement) {
      return ratchet.RatchetFile(
        metrics: <String, ratchet.RecordedMetric>{
          'm': ratchet.RecordedMetric(count: count, enforcement: enforcement),
        },
        history: const <ratchet.Increase>[],
      );
    }

    test('passes when counts match', () {
      expect(
        ratchet.check(recorded(3, ratchet.Enforcement.ratchet), <String, int>{'m': 3}).passed,
        true,
      );
    });

    test('fails when a ratcheted count rises', () {
      final ratchet.CheckResult result = ratchet.check(
        recorded(3, ratchet.Enforcement.ratchet),
        <String, int>{'m': 4},
      );
      expect(result.passed, false);
      expect(result.errors.single, contains('rose from 3 to 4'));
    });

    test('fails when a ratcheted count drops without being recorded', () {
      final ratchet.CheckResult result = ratchet.check(
        recorded(3, ratchet.Enforcement.ratchet),
        <String, int>{'m': 2},
      );
      expect(result.passed, false);
      expect(result.errors.single, contains('dropped from 3 to 2'));
    });

    test('fails when a zero-enforced count is not zero', () {
      expect(
        ratchet.check(recorded(0, ratchet.Enforcement.zero), <String, int>{'m': 1}).passed,
        false,
      );
      expect(
        ratchet.check(recorded(0, ratchet.Enforcement.zero), <String, int>{'m': 0}).passed,
        true,
      );
    });

    test('only notes changes to report metrics', () {
      final ratchet.CheckResult result = ratchet.check(
        recorded(3, ratchet.Enforcement.report),
        <String, int>{'m': 5},
      );
      expect(result.passed, true);
      expect(result.notes.single, contains('changed from 3 to 5'));
    });

    test('fails for unrecorded and stale metrics', () {
      expect(
        ratchet.check(recorded(3, ratchet.Enforcement.ratchet), <String, int>{'n': 3}).errors,
        hasLength(2),
      );
    });
  });

  group('update', () {
    const empty = ratchet.RatchetFile(
      metrics: <String, ratchet.RecordedMetric>{},
      history: <ratchet.Increase>[],
    );

    test('records new metrics with their default enforcement', () {
      final ratchet.RatchetFile file = ratchet.update(empty, <String, int>{
        'shell_refs': 4,
        'gn_internal_deps': 9,
      });
      expect(file.metrics['shell_refs']!.enforcement, ratchet.Enforcement.ratchet);
      expect(file.metrics['gn_internal_deps']!.enforcement, ratchet.Enforcement.report);
      expect(file.history, isEmpty);
    });

    test('refuses an increase that is not allowed', () {
      final ratchet.RatchetFile file = ratchet.update(empty, <String, int>{'shell_refs': 4});
      expect(
        () => ratchet.update(file, <String, int>{'shell_refs': 5}),
        throwsA(isA<ratchet.RatchetException>()),
      );
    });

    test('requires a reason for an allowed increase and records it', () {
      final ratchet.RatchetFile file = ratchet.update(empty, <String, int>{'shell_refs': 4});
      expect(
        () => ratchet.update(
          file,
          <String, int>{'shell_refs': 5},
          allowIncrease: <String>{'shell_refs'},
        ),
        throwsA(isA<ratchet.RatchetException>()),
      );
      final ratchet.RatchetFile raised = ratchet.update(
        file,
        <String, int>{'shell_refs': 5},
        allowIncrease: <String>{'shell_refs'},
        reason: 'Wrap the Shell in EmbedderEngine.',
      );
      expect(raised.metrics['shell_refs']!.count, 5);
      expect(raised.history.single.reason, 'Wrap the Shell in EmbedderEngine.');
    });

    test('records decreases without a reason', () {
      final ratchet.RatchetFile file = ratchet.update(empty, <String, int>{'shell_refs': 4});
      expect(ratchet.update(file, <String, int>{'shell_refs': 1}).metrics['shell_refs']!.count, 1);
    });

    test('only enforces zero for metrics that are zero', () {
      final ratchet.RatchetFile file = ratchet.update(empty, <String, int>{'shell_refs': 1});
      expect(
        () => ratchet.update(
          file,
          <String, int>{'shell_refs': 1},
          enforce: <String, ratchet.Enforcement>{'shell_refs': ratchet.Enforcement.zero},
        ),
        throwsA(isA<ratchet.RatchetException>()),
      );
      final ratchet.RatchetFile enforced = ratchet.update(
        file,
        <String, int>{'shell_refs': 0},
        enforce: <String, ratchet.Enforcement>{'shell_refs': ratchet.Enforcement.zero},
      );
      expect(enforced.metrics['shell_refs']!.enforcement, ratchet.Enforcement.zero);
    });

    test('round-trips through JSON', () {
      final ratchet.RatchetFile file = ratchet.update(
        ratchet.update(empty, <String, int>{'shell_refs': 1}),
        <String, int>{'shell_refs': 2},
        allowIncrease: <String>{'shell_refs'},
        reason: 'why',
      );
      final parsed = ratchet.RatchetFile.parse(file.toJson());
      expect(parsed.toJson(), file.toJson());
    });
  });
}
