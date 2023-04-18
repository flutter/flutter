// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:conductor_core/src/stdio.dart';
import 'package:test/test.dart';

export 'package:test/test.dart' hide isInstanceOf;
export '../../../../packages/flutter_tools/test/src/fake_process_manager.dart';

Matcher throwsAssertionWith(final String messageSubString) {
  return throwsA(
      isA<AssertionError>().having(
          (final AssertionError e) => e.toString(),
          'description',
          contains(messageSubString),
      ),
  );
}

Matcher throwsExceptionWith(final String messageSubString) {
  return throwsA(
      isA<Exception>().having(
          (final Exception e) => e.toString(),
          'description',
          contains(messageSubString),
      ),
  );
}

class TestStdio extends Stdio {
  TestStdio({
    this.verbose = false,
    final List<String>? stdin,
  }) : stdin = stdin ?? <String>[];

  String get error => logs.where((final String log) => log.startsWith(r'[error] ')).join('\n');

  String get stdout => logs.where((final String log) {
    return log.startsWith(r'[status] ') || log.startsWith(r'[trace] ') || log.startsWith(r'[write] ');
  }).join('\n');

  final bool verbose;
  final List<String> stdin;

  @override
  String readLineSync() {
    if (stdin.isEmpty) {
      throw Exception('Unexpected call to readLineSync! Last stdout was ${logs.last}');
    }
    return stdin.removeAt(0);
  }
}

class FakeArgResults implements ArgResults {
  FakeArgResults({
    required final String? level,
    required final String candidateBranch,
    final String remote = 'upstream',
    final bool justPrint = false,
    final bool autoApprove = true, // so we don't have to mock stdin
    final bool help = false,
    final bool force = false,
    final bool skipTagging = false,
  }) : _parsedArgs = <String, dynamic>{
    'increment': level,
    'candidate-branch': candidateBranch,
    'remote': remote,
    'just-print': justPrint,
    'yes': autoApprove,
    'help': help,
    'force': force,
    'skip-tagging': skipTagging,
  };

  @override
  String? name;

  @override
  ArgResults? command;

  @override
  final List<String> rest = <String>[];

  @override
  List<String> get arguments {
    assert(false, 'not yet implemented');
    return <String>[];
  }

  final Map<String, dynamic> _parsedArgs;

  @override
  Iterable<String> get options {
    assert(false, 'not yet implemented');
    return <String>[];
  }

  @override
  dynamic operator [](final String name) {
    return _parsedArgs[name];
  }

  @override
  bool wasParsed(final String name) {
    assert(false, 'not yet implemented');
    return false;
  }
}
