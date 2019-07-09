// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:yaml/yaml.dart';

import 'base/io.dart';
import 'base/process_manager.dart';
import 'globals.dart';

class SubHook {
  SubHook({
    this.cmds,
    this.beforeHookExecutable,
    this.beforeHookArgument,
    this.afterHookExecutable,
    this.afterHookArgument
  });
  final List<String> cmds;
  final String beforeHookExecutable;
  final String beforeHookArgument;
  final String afterHookExecutable;
  final String afterHookArgument;

  static Future<ProcessResult> _runHookProcess(bool isBeforeHook, String workingDir, String hookCommand, String hookArgument, List<String> arguments) async{
    if(hookCommand?.isEmpty ?? true) {
      return null;
    }
    final List<String> innerCommand = <String>['$hookCommand', '$hookArgument']; 
    final String argumentConcated = arguments?.join(' ') ?? '';
    if (argumentConcated.isNotEmpty) {
      innerCommand.add('"$argumentConcated"');
    }
    printTrace('executing ${isBeforeHook == true ? "beforeHook" : "afterHook"}: '+innerCommand.join(' '));
    try {
        final ProcessResult result = processManager.runSync(
          innerCommand,
          workingDirectory: workingDir,
          runInShell: true
        );
        printTrace('Exit code ${result.exitCode} from: ${innerCommand.join(' ')}');
        printTrace('stdout: \'${result.stdout.toString().trim()}\', stderr:\'${result.stderr.toString().trim()}:\'');
        return result;
    } catch (error) {
        printTrace('Error occurred with message: ${error.toString()}');
    }
    return null;
  }

  Future<ProcessResult> runBeforeHook(String workingDir, List<String> arguments) async {
    return await _runHookProcess(true, workingDir, beforeHookExecutable, beforeHookArgument, arguments);
  }

  Future<ProcessResult> runAfterHook(String workingDir, List<String> arguments) async{
    return await _runHookProcess(false, workingDir, afterHookExecutable, afterHookArgument, arguments);
  }
}

class Hooks {
    Hooks({
    this.subhooks,
  });

  factory Hooks.fromYaml(dynamic yaml) {
    final List<SubHook> subhooks = <SubHook>[];    
    try {
        if (yaml != null) {
          final YamlMap yamlSpec = loadYaml(yaml);
          final YamlMap commandsSpec = yamlSpec['commands'];
          parseYamp(subhooks, <String>[], commandsSpec);
        }
    } catch (_) {
        
    }
    return Hooks(
          subhooks: subhooks,
        );
  }

  static void parseYamp(List<SubHook> subhooks,List<String> subCmds, YamlMap yamlMap) {
    yamlMap?.nodes?.forEach((dynamic key, YamlNode yamlNode) {
      final String subCmdName = key.value;
      if (subCmdName == 'hook') {
        if (!(yamlNode is YamlMap)) {
          return;
        }
        final YamlMap yamlMap = yamlNode;
        String beforeHookExecutable;
        String beforeHookArgument;
        String afterHookExecutable;
        String afterHookArgument;
        yamlMap?.nodes?.forEach((dynamic key, YamlNode yamlNode) {
          final String hookName = key.value;
          final YamlMap yamlMap = yamlNode.value;
          if (hookName == 'before') {
            beforeHookExecutable = yamlMap.nodes['executable'].value;
            beforeHookArgument = yamlMap.nodes['argument'].value;
          } else if (hookName == 'after') {
            afterHookExecutable = yamlMap.nodes['executable'].value;
            afterHookArgument = yamlMap.nodes['argument'].value;
          }
        });
        if((beforeHookExecutable?.isNotEmpty ?? false) || 
          (afterHookExecutable?.isNotEmpty ?? false)) {
          subhooks.add(SubHook(cmds: subCmds, 
                            beforeHookExecutable: beforeHookExecutable, 
                            beforeHookArgument: beforeHookArgument, 
                            afterHookExecutable: afterHookExecutable, 
                            afterHookArgument: afterHookArgument));
        }
        return;
       }
      final List<String> tmpCmds = subCmds.sublist(0)..add(subCmdName);
      parseYamp(subhooks, tmpCmds, yamlNode);
    });
  }

  final List<SubHook> subhooks;
}