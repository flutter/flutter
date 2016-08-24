// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'base/logger.dart';
import 'build_info.dart';
import 'device.dart';
import 'globals.dart';
import 'vmservice.dart';
import 'cli/command.dart';
import 'cli/commandline.dart';

abstract class RunnerCommand extends Command {
  final ResidentRunner runner;

  RunnerCommand(this.runner, String name, List<Command> children)
      : super(name, children);

  String get helpShort;
  String get helpLong;
}

int _sortCommands(Command a, Command b) => a.name.compareTo(b.name);

class HelpCommand extends RunnerCommand {
  HelpCommand(ResidentRunner runner) : super(runner, 'help', null);

  String _nameAndAlias(Command cmd) {
    if (cmd.alias == null) {
      return cmd.fullName;
    } else {
      return '${cmd.fullName}, ${cmd.alias}';
    }
  }

  @override
  Future<Null> run(List<String> args) async {
    if (args.length == 0) {
      // Print list of all top-level commands.
      List<Command> commands = runner.cmd.matchCommand(<String>[], false);
      commands.sort(_sortCommands);
      logger.printStatus('Commands:\n', emphasis: true);
      for (Command command in commands) {
        RunnerCommand rcommand = command;
        logger.printStatus('${_nameAndAlias(command).padRight(12)} '
                           '- ${rcommand.helpShort}');
      }
      logger.printStatus("\nHotkeys:", emphasis: true);
      logger.printStatus(
          "\n"
          "[TAB]        - complete a command (try 'p[TAB][TAB]')\n"
          "[Up Arrow]   - history previous\n"
          "[Down Arrow] - history next\n"
          "[^L]         - clear screen");
      List<HotKey> keys = runner._commandLine.rootCommand.hotKeys;
      for (int i = 0; i < keys.length; i++) {
        HotKey key = keys[i];
        logger.printStatus(
            "${key.userName.padRight(12)} - '${key.expansion}'");
      }
      logger.printStatus(
          "\nFor more information on a specific command type "
          "'help <command>'\n"
          "Command prefixes are accepted (e.g. 'h' for 'help')\n");
    } else {
      // Print any matching commands.
      List<Command> commands = runner.cmd.matchCommand(args, true);
      commands.sort(_sortCommands);
      if (commands.isEmpty) {
        String line = args.join(' ');
        logger.printStatus("No command matches '$line'");
        return;
      }
      logger.printStatus('');
      for (Command command in commands) {
        RunnerCommand rcommand = command;
        logger.printStatus(_nameAndAlias(command), emphasis: true);
        logger.printStatus(rcommand.helpLong);

        List<String> newArgs = <String>[];
        newArgs.addAll(args.take(args.length - 1));
        newArgs.add(command.name);
        newArgs.add('');
        List<Command> subCommands = runner.cmd.matchCommand(newArgs, false);
        subCommands.remove(command);
        if (subCommands.isNotEmpty) {
          subCommands.sort(_sortCommands);
          logger.printStatus('Subcommands:\n');
          for (Command subCommand in subCommands) {
            RunnerCommand rSubCommand = subCommand;
            logger.printStatus('    ${subCommand.fullName.padRight(16)} '
                      '- ${rSubCommand.helpShort}');
          }
          logger.printStatus('');
        }
      }
    }
  }

  @override
  Future<List<String>> complete(List<String> args) {
    List<Command> commands = runner.cmd.matchCommand(args, false);
    List<String> result = commands.map((Command cmd) => '${cmd.fullName} ');
    return new Future<List<String>>.value(result);
  }

  @override
  String helpShort = 'List commands or provide details about a specific command';

  @override
  String helpLong =
      'List commands or provide details about a specific command.\n'
      '\n'
      'Syntax: help            - Show a list of all commands\n'
      '        help <command>  - Help for a specific command\n';
}

class PrintCommand extends RunnerCommand {
  PrintCommand(ResidentRunner runner) : super(runner, 'print', null);

  final List<List<dynamic>> options = <List<dynamic>>[
      <dynamic>[ 'rendertree',
                 (ResidentRunner runner) => runner._debugDumpRenderTree() ],
      <dynamic>[ 'widgets',
                 (ResidentRunner runner) => runner._debugDumpApp() ],
  ];

  @override
  Future<Null> run(List<String> args) async {
    if (args.length != 1) {
      logger.printStatus("'$name' expects one argument");
      return;
    } else if (args.length == 1) {
      String name = args[0].trim();
      for (int i = 0; i < options.length; i++) {
        if (options[i][0].startsWith(name)) {
          await options[i][1](runner);
          return;
        }
      }
      logger.printStatus("unrecognized option: '$name'");
    }
  }

  @override
  Future<List<String>> complete(List<String> args) async {
    if (args.length != 1) {
      return <String>[args.join('')];
    }
    List<String> result = <String>[];
    String prefix = args[0];
    for (List<dynamic> option in options) {
      if (option[0].startsWith(prefix)) {
        result.add('${option[0]}');
      }
    }
    return result;
  }

  @override
  String helpShort = 'Print information about a flutter application';

  @override
  String helpLong =
      'Print information about a flutter application.\n'
      '\n'
      'Syntax: print <option>\n'
      '\n'
      'Options:\n'
      '  print rendertree      # Print the render tree\n'
      '  print widgets         # Print the widget hierarchy\n';
}

class QuitCommand extends RunnerCommand {
  QuitCommand(ResidentRunner runner) : super(runner, 'quit', null);

  @override
  Future<Null> run(List<String> args) async {
    if (args.length != 0) {
      logger.printStatus("'$name' expects no arguments");
      return;
    }
    await runner.stop();
  }

  @override
  String helpShort = 'Quit the flutter application';

  @override
  String helpLong =
      'Quit the application.\n'
      '\n'
      'Syntax: quit\n';
}

class _CommandLineNotifier implements Hider {
  _CommandLineNotifier(this.commandLine);

  CommandLine commandLine;

  @override
  void hide() {
    commandLine.hide();
  }

  @override
  void show() {
    commandLine.show();
  }
}


// Shared code between different resident application runners.
abstract class ResidentRunner {
  ResidentRunner(this.device, {
    this.target,
    this.debuggingOptions,
    this.usesTerminalUI: true
  });

  final Device device;
  final String target;
  final DebuggingOptions debuggingOptions;
  final bool usesTerminalUI;
  final Completer<int> _finished = new Completer<int>();

  VMService vmService;
  FlutterView currentView;
  StreamSubscription<String> _loggingSubscription;
  RootCommand cmd;
  CommandLine _commandLine;

  /// Start the app and keep the process running during its lifetime.
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    String route,
    bool shouldBuild: true
  });

  Future<bool> restart({ bool fullRestart: false });

  Future<Null> stop() async {
    await stopEchoingDeviceLog();
    await preStop();
    return stopApp();
  }

  Future<Null> _debugDumpApp() async {
    if (vmService != null)
      await vmService.vm.refreshViews();

    await currentView.uiIsolate.flutterDebugDumpApp();
  }

  Future<Null> _debugDumpRenderTree() async {
    if (vmService != null)
      await vmService.vm.refreshViews();
    
    await currentView.uiIsolate.flutterDebugDumpRenderTree();
  }

  void registerSignalHandlers() {
    ProcessSignal.SIGINT.watch().listen((ProcessSignal signal) async {
      _resetTerminal();
      await cleanupAfterSignal();
      exit(0);
    });
    ProcessSignal.SIGTERM.watch().listen((ProcessSignal signal) async {
      _resetTerminal();
      await cleanupAfterSignal();
      exit(0);
    });
    ProcessSignal.SIGUSR1.watch().listen((ProcessSignal signal) async {
      printStatus('Caught SIGUSR1');
      await restart(fullRestart: false);
    });
    // TODO(turnidge): Use SIGWINCH to notify _commandline of window changes.
  }

  Future<Null> startEchoingDeviceLog() async {
    if (_loggingSubscription != null) {
      return;
    }
    _loggingSubscription = device.logReader.logLines.listen((String line) {
      if (!line.contains('Observatory listening on http') &&
          !line.contains('Diagnostic server listening on http'))
        printStatus(line);
    });
  }

  Future<Null> stopEchoingDeviceLog() async {
    if (_loggingSubscription != null) {
      await _loggingSubscription.cancel();
    }
    _loggingSubscription = null;
  }

  Future<Null> connectToServiceProtocol(int port) async {
    if (!debuggingOptions.debuggingEnabled) {
      return new Future<Null>.error('Error the service protocol is not enabled.');
    }
    vmService = await VMService.connect(port);
    printTrace('Connected to service protocol on port $port');
    await vmService.getVM();
    vmService.onExtensionEvent.listen((ServiceEvent event) {
      printTrace(event.toString());
    });
    vmService.onIsolateEvent.listen((ServiceEvent event) {
      printTrace(event.toString());
    });

    // Refresh the view list.
    await vmService.vm.refreshViews();
    currentView = vmService.vm.mainView;
    assert(currentView != null);

    // Listen for service protocol connection to close.
    vmService.done.whenComplete(() {
      appFinished();
    });
  }

  List<Command> buildCommandList() {
    List<Command> cmds = <Command>[];
    cmds.add(new HelpCommand(this));
    cmds.add(new PrintCommand(this));
    cmds.add(new QuitCommand(this));
    return cmds;
  }

  void addHotKeys(RootCommand root) {
    root.addHotKey('[F1]', terminal.keyF1, 'help');
    root.addHotKey('[F10]', terminal.keyF10, 'quit');
  }

  void appFinished() {
    if (_finished.isCompleted)
      return;
    _resetTerminal();
    _finished.complete(0);
    printStatus('Application finished.');
  }

  void _resetTerminal() {
    if (usesTerminalUI) {
      if (_commandLine != null) {
        logger.commandLine = null;
        CommandLine commandLine = _commandLine;
        _commandLine = null;
        commandLine.hide();
        commandLine.quit();
      }
    }
  }

  void setupTerminal() {
    if (usesTerminalUI) {
      if (!logger.quiet)
        printHelpSummary();

      cmd = new RootCommand(buildCommandList());
      addHotKeys(cmd);
      _commandLine = new CommandLine(cmd, terminal, prompt: '(flutter) ');
      logger.commandLine = new _CommandLineNotifier(_commandLine);
    }
  }

  Future<int> waitForAppToFinish() async {
    int exitCode = await _finished.future;
    await cleanupAtFinish();
    return exitCode;
  }

  Future<Null> preStop() async { }

  Future<Null> stopApp() async {
    if (vmService != null && !vmService.isClosed) {
      if ((currentView != null) && (currentView.uiIsolate != null)) {
        // TODO(johnmccutchan): Wait for the exit command to complete.
        currentView.uiIsolate.flutterExit();
        await new Future<Null>.delayed(new Duration(milliseconds: 100));
      }
    }
    appFinished();
  }

  /// Called when a signal has requested we exit.
  Future<Null> cleanupAfterSignal();
  /// Called right before we exit.
  Future<Null> cleanupAtFinish();
  /// Called to print help to the terminal.
  void printHelpSummary();
}

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([String target]) {
  if (target == null)
    target = '';
  String targetPath = path.absolute(target);
  if (FileSystemEntity.isDirectorySync(targetPath))
    return path.join(targetPath, 'lib', 'main.dart');
  else
    return targetPath;
}

String getMissingPackageHintForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
      return 'Is your project missing an android/AndroidManifest.xml?\nConsider running "flutter create ." to create one.';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Runner/Info.plist?\nConsider running "flutter create ." to create one.';
    default:
      return null;
  }
}

class DebugConnectionInfo {
  DebugConnectionInfo(this.port, { this.baseUri });

  final int port;
  final String baseUri;
}
