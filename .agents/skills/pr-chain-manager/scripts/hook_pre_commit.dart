// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Lifecycle hook interceptor for `PreToolUse` on `run_command`.
///
/// If `git commit` is attempted on `android-embedder-migration-v10/*`,
/// it validates the PR chain alignment before allowing the commit to proceed.
void main() async {
  try {
    final String rawInput = await utf8.decoder.bind(stdin).join();
    if (rawInput.trim().isEmpty) {
      stdout.writeln('{"decision": "allow"}');
      return;
    }

    final data = jsonDecode(rawInput) as Map<String, dynamic>;
    final toolCall = data['toolCall'] as Map<String, dynamic>?;
    final args = toolCall?['args'] as Map<String, dynamic>?;
    final String commandLine = (args?['CommandLine'] as String?) ?? '';

    // Only intercept git commit commands
    if (commandLine.contains('git commit')) {
      const guardScript =
          '/usr/local/google/home/boetger/src/flutter/.agents/skills/pr-chain-manager/scripts/pre_commit_guard.sh';
      final ProcessResult result = await Process.run(guardScript, <String>[]);

      if (result.exitCode != 0) {
        final reason = 'Pre-Commit Guard Denied Commit:\n${result.stderr}\n${result.stdout}';
        stdout.writeln(jsonEncode(<String, dynamic>{'decision': 'deny', 'reason': reason}));
        return;
      }
    }

    stdout.writeln('{"decision": "allow"}');
  } catch (e) {
    // On unexpected hook error, fail open to avoid trapping the agent
    stdout.writeln('{"decision": "allow"}');
  }
}
