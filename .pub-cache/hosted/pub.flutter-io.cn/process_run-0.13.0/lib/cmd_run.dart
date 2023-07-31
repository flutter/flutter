/// Prefer using shell
library process_run.cmd_run;

///
/// Command runner
///
import 'dart:async';
import 'dart:io';

import 'package:process_run/src/process_run.dart';

import 'src/process_cmd.dart';

export 'dartbin.dart'
    show
        dartChannel,
        dartVersion,
        dartExecutable,
        dartSdkBinDirPath,
        dartChannelBeta,
        dartChannelMaster,
        dartChannelStable,
        dartChannelDev,
        isFlutterSupportedSync,
        isFlutterSupported,
        dartSdkDirPath,
        getFlutterBinVersion,
        getFlutterBinChannel;
export 'dartbin.dart'
    show
        getFlutterBinVersion,
        getFlutterBinChannel,
        isFlutterSupported,
        isFlutterSupportedSync;
export 'process_run.dart'
    show
        // ignore: deprecated_member_use_from_same_package
        run,
        executableArgumentsToString,
        runExecutableArguments,
        argumentsToString,
        argumentToString;
export 'src/build_runner.dart' show PbrCmd;
export 'src/dartbin_cmd.dart'
    show
        // ignore: deprecated_member_use_from_same_package
        Dart2JsCmd,
        DartCmd,
        DartDocCmd, // ignore: deprecated_member_use_from_same_package
        DartFmtCmd, // ignore: deprecated_member_use_from_same_package
        DartDevcCmd,
        // ignore: deprecated_member_use_from_same_package
        DartAnalyzerCmd,
        PubCmd,
        PubGlobalRunCmd,
        PubRunCmd,
        getDartBinVersion,
        dartBinFileName,
        parsePlatformChannel,
        parsePlatformVersion;
// ignore: deprecated_member_use_from_same_package
export 'src/dev_cmd_run.dart' show devRunCmd;
export 'src/flutterbin_cmd.dart' show flutterExecutablePath, FlutterCmd;
export 'src/process_cmd.dart'
    show ProcessCmd, processCmdToDebugString, processResultToDebugString;
export 'src/webdev.dart' show WebDevCmd;

/// Command runner
///

///
/// Execute a predefined ProcessCmd command
///
/// if [commandVerbose] is true, it writes the command line executed preceeded by $ to stdout. It streams
/// stdout/error if [verbose] is true.
/// [verbose] implies [commandVerbose]
///
Future<ProcessResult> runCmd(ProcessCmd cmd,
        {bool? verbose,
        bool? commandVerbose,
        Stream<List<int>>? stdin,
        StreamSink<List<int>>? stdout,
        StreamSink<List<int>>? stderr}) =>
    processCmdRun(cmd,
        verbose: verbose,
        commandVerbose: commandVerbose,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr);
