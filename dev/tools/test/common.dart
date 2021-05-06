// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:args/args.dart';
import 'package:dev_tools/stdio.dart';
import 'package:file/file.dart';
import 'package:test/test.dart';

export 'package:test/test.dart' hide isInstanceOf;

/// A matcher that compares the type of the actual value to the type argument T.
TypeMatcher<T> isInstanceOf<T>() => isA<T>();

void tryToDelete(Directory directory) {
  // This should not be necessary, but it turns out that
  // on Windows it's common for deletions to fail due to
  // bogus (we think) "access denied" errors.
  try {
    directory.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    print('Failed to delete ${directory.path}: $error');
  }
}

Matcher throwsExceptionWith(String messageSubString) {
  return throwsA(
      isA<Exception>().having(
          (Exception e) => e.toString(),
          'description',
          contains(messageSubString),
      ),
  );
}

class TestStdio extends Stdio {
  TestStdio({
    this.verbose = false,
    List<String>? stdin,
  }) : _stdin = stdin ?? <String>[];

  String get error => logs.where((String log) => log.startsWith(r'[error] ')).join('\n');

  String get stdout => logs.where((String log) {
    return log.startsWith(r'[status] ') || log.startsWith(r'[trace] ');
  }).join('\n');

  final bool verbose;
  late final List<String> _stdin;

  @override
  String readLineSync() {
    if (_stdin.isEmpty) {
      throw Exception('Unexpected call to readLineSync!');
    }
    return _stdin.removeAt(0);
  }
}

class FakeArgResults implements ArgResults {
  FakeArgResults({
    required String level,
    required String commit,
    String remote = 'upstream',
    bool justPrint = false,
    bool autoApprove = true, // so we don't have to mock stdin
    bool help = false,
    bool force = false,
    bool skipTagging = false,
  }) : _parsedArgs = <String, dynamic>{
    'increment': level,
    'commit': commit,
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
  dynamic operator [](String name) {
    return _parsedArgs[name];
  }

  @override
  bool wasParsed(String name) {
    assert(false, 'not yet implemented');
    return false;
  }
}
