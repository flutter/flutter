// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

final String repoDir = _computeRepoDir();

String get dartVm => Platform.executable;

main(List<String> args) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  List<Future> futures = <Future>[];
  futures.add(run("pkg/front_end/test/spelling_test_src_suite.dart",
      ["--", "spelling_test_src/_fe_analyzer_shared/..."]));
  futures.add(run(
      "pkg/front_end/test/explicit_creation_git_test.dart", ["--shared-only"],
      filter: false));
  futures.add(run("pkg/front_end/test/lint_suite.dart",
      ["--", "lint/_fe_analyzer_shared/..."]));
  await Future.wait(futures);
  print("\n-----------------------\n");
  print("Done with exitcode $exitCode in ${stopwatch.elapsedMilliseconds} ms");
}

Future<void> run(String script, List<String> scriptArguments,
    {bool filter = true}) async {
  List<String> arguments = [];
  arguments.add("$script");
  arguments.addAll(scriptArguments);

  Stopwatch stopwatch = new Stopwatch()..start();
  ProcessResult result =
      await Process.run(dartVm, arguments, workingDirectory: repoDir);
  String runWhat = "${dartVm} ${arguments.join(' ')}";
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    print("-----");
    print("Running: $runWhat: "
        "Failed with exit code ${result.exitCode} "
        "in ${stopwatch.elapsedMilliseconds} ms.");
    String stdout = result.stdout.toString();
    if (filter) {
      List<String> lines = stdout.split("\n");
      int lastIgnored = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith("[ ")) lastIgnored = i;
      }
      lines.removeRange(0, lastIgnored + 1);
      stdout = lines.join("\n");
    }
    stdout = stdout.trim();
    if (stdout.isNotEmpty) {
      print(stdout);
      print("-----");
    }
  } else {
    print("Running: $runWhat: Done in ${stopwatch.elapsedMilliseconds} ms.");
  }
}

String _computeRepoDir() {
  ProcessResult result = Process.runSync(
      'git', ['rev-parse', '--show-toplevel'],
      runInShell: true,
      workingDirectory: new File.fromUri(Platform.script).parent.path);
  return (result.stdout as String).trim();
}
