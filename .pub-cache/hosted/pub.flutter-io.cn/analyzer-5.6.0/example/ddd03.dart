import 'dart:convert';
import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';

void main() async {
  // var path = '/Users/scheglov/dart/flutter_plugins/packages/camera';
  var path = '/Users/scheglov/dart/flutter_plugins/packages';

  while (true) {
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    var fileContentCache = FileContentCache(resourceProvider);
    var unlinkedUnitStore = UnlinkedUnitStoreImpl();

    var collection = AnalysisContextCollectionImpl(
      byteStore: MemoryByteStore(),
      resourceProvider: resourceProvider,
      fileContentCache: fileContentCache,
      unlinkedUnitStore: unlinkedUnitStore,
      sdkPath: '/Users/scheglov/Applications/dart-sdk',
      // performanceLog: PerformanceLog(stdout),
      includedPaths: [
        path,
      ],
      packagesFile:
          '/Users/scheglov/dart/flutter_plugins/packages/camera/camera/.dart_tool/package_config.json',
    );

    // print('[Analysis contexts: ${collection.contexts.length}]');

    var timer = Stopwatch()..start();
    for (var analysisContext in collection.contexts) {
      // print(analysisContext.contextRoot.root.path);
      for (var filePath in analysisContext.contextRoot.analyzedFiles()) {
        if (filePath.endsWith('.dart')) {
          // print('  $filePath');
          var analysisSession = analysisContext.currentSession;
          await analysisSession.getResolvedUnit(filePath);
        }
      }
    }
    timer.stop();
    print('[time: ${timer.elapsedMilliseconds} ms]');

    var profiler = ProcessProfiler.getProfilerForPlatform()!;
    print((await profiler.getProcessUsage(pid))!.memoryMB);
  }

  // var analysisContext = collection.contextFor(path);
  // var unitResult = await analysisContext.currentSession.getResolvedUnit(path);
  // unitResult as ResolvedUnitResult;

  // await Future<void>.delayed(const Duration(days: 1));
}


/// A class that can return memory and cpu usage information for a given
/// process.
abstract class ProcessProfiler {
  ProcessProfiler._();

  Future<UsageInfo?> getProcessUsage(int processId);

  /// Return a [ProcessProfiler] instance suitable for the current host
  /// platform. This can return `null` if we're not able to gather memory and
  /// cpu information for the current platform.
  static ProcessProfiler? getProfilerForPlatform() {
    if (Platform.isLinux || Platform.isMacOS) {
      return _PosixProcessProfiler();
    }

    if (Platform.isWindows) {
      return _WindowsProcessProfiler();
    }

    // Not a supported platform.
    return null;
  }
}

class UsageInfo {
  /// A number between 0.0 and 100.0 * the number of host CPUs (but typically
  /// never more than slightly above 100.0).
  final double? cpuPercentage;

  /// The process memory usage in kilobytes.
  final int memoryKB;

  UsageInfo(this.cpuPercentage, this.memoryKB);

  double get memoryMB => memoryKB / 1024;

  @override
  String toString() {
    if (cpuPercentage != null) {
      return '$cpuPercentage% ${memoryMB.toStringAsFixed(1)}MB';
    }
    return '${memoryMB.toStringAsFixed(1)}MB';
  }
}

class _PosixProcessProfiler extends ProcessProfiler {
  static final RegExp stringSplitRegExp = RegExp(r'\s+');

  _PosixProcessProfiler() : super._();

  @override
  Future<UsageInfo?> getProcessUsage(int processId) {
    try {
      // Execution time is typically 2-4ms.
      var future =
      Process.run('ps', ['-o', '%cpu=,rss=', processId.toString()]);
      return future.then((ProcessResult result) {
        if (result.exitCode != 0) {
          return Future.value(null);
        }

        return Future.value(_parse(result.stdout as String));
      });
    } catch (e) {
      return Future.error(e);
    }
  }

  UsageInfo? _parse(String psResults) {
    try {
      // "  0.0 378940"
      var line = psResults.split('\n').first.trim();
      var values = line.split(stringSplitRegExp);
      return UsageInfo(double.parse(values[0]), int.parse(values[1]));
    } catch (e) {
      return null;
    }
  }
}

class _WindowsProcessProfiler extends ProcessProfiler {
  _WindowsProcessProfiler() : super._();

  @override
  Future<UsageInfo?> getProcessUsage(int processId) async {
    try {
      var result = await Process.run(
          'tasklist', ['/FI', 'PID eq $processId', '/NH', '/FO', 'csv']);

      if (result.exitCode != 0) {
        return Future.value(null);
      }

      return Future.value(_parse(result.stdout as String));
    } catch (e) {
      return Future.error(e);
    }
  }

  UsageInfo? _parse(String tasklistResults) {
    try {
      var lines = tasklistResults.split(RegExp("\r?\n"));
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        // Hacky parsing of csv line.
        var entries = jsonDecode("[$line]") as List;
        if (entries.length != 5) continue;
        // E.g. 123,456 K
        var memory = entries[4] as String;
        memory = memory.substring(0, memory.indexOf(" "));
        memory = memory.replaceAll(",", "");
        memory = memory.replaceAll(".", "");
        return UsageInfo(null, int.parse(memory));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
