// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

abstract class _IOResourceInfo {
  final String type;
  final int id;
  String get name;
  static int _count = 0;

  static final Stopwatch _sw = Stopwatch()..start();
  static final _startTime = DateTime.now().millisecondsSinceEpoch;

  static int get timestamp => _startTime + _sw.elapsedMicroseconds ~/ 1000;

  _IOResourceInfo(this.type) : id = _IOResourceInfo.getNextID();

  /// Get the full set of values for a specific implementation. This is normally
  /// looked up based on an id from a referenceValueMap.
  Map<String, dynamic> get fullValueMap;

  /// The reference map, used to return a list of values, e.g., getting
  /// all open sockets. The structure of this is shared among all subclasses.
  Map<String, dynamic> get referenceValueMap => {
        // The type for a reference object is prefixed with @ in observatory.
        'type': '@$type',
        'id': id,
        'name': name,
      };

  static int getNextID() => _count++;
}

abstract class _ReadWriteResourceInfo extends _IOResourceInfo {
  int readBytes;
  int writeBytes;
  int readCount;
  int writeCount;
  int lastReadTime;
  int lastWriteTime;

  // Not all call sites use this. In some cases, e.g., a socket, a read does
  // not always mean that we actually read some bytes (we may do a read to see
  // if there are some bytes available).
  void addRead(int bytes) {
    readBytes += bytes;
    readCount++;
    lastReadTime = _IOResourceInfo.timestamp;
  }

  // In cases where we read but did not necessarily get any bytes, use this to
  // update the readCount and timestamp. Manually update totalRead if any bytes
  // where actually read.
  void didRead() {
    addRead(0);
  }

  void addWrite(int bytes) {
    writeBytes += bytes;
    writeCount++;
    lastWriteTime = _IOResourceInfo.timestamp;
  }

  _ReadWriteResourceInfo(String type)
      : readBytes = 0,
        writeBytes = 0,
        readCount = 0,
        writeCount = 0,
        lastReadTime = 0,
        lastWriteTime = 0,
        super(type);

  Map<String, dynamic> get fullValueMap => {
        'type': type,
        'id': id,
        'name': name,
        'readBytes': readBytes,
        'writeBytes': writeBytes,
        'readCount': readCount,
        'writeCount': writeCount,
        'lastReadTime': lastReadTime,
        'lastWriteTime': lastWriteTime
      };
}

class _FileResourceInfo extends _ReadWriteResourceInfo {
  static const String _type = 'OpenFile';

  final RandomAccessFile file;

  static Map<int, _FileResourceInfo> openFiles = {};

  _FileResourceInfo(this.file) : super(_type) {
    fileOpened(this);
  }

  static fileOpened(_FileResourceInfo info) {
    assert(!openFiles.containsKey(info.id));
    openFiles[info.id] = info;
  }

  static fileClosed(_FileResourceInfo info) {
    assert(openFiles.containsKey(info.id));
    openFiles.remove(info.id);
  }

  static Iterable<Map<String, dynamic>> getOpenFilesList() {
    return List.from(openFiles.values.map(
      (e) => e.referenceValueMap,
    ));
  }

  static Future<ServiceExtensionResponse> getOpenFiles(
      String function, Map<String, String> params) {
    assert(function == 'ext.dart.io.getOpenFiles');
    final data = {
      'type': 'OpenFileList',
      'files': getOpenFilesList(),
    };
    final jsonValue = json.encode(data);
    return Future.value(ServiceExtensionResponse.result(jsonValue));
  }

  Map<String, dynamic> get fileInfoMap => fullValueMap;

  static Future<ServiceExtensionResponse> getOpenFileInfoMapByID(
      String function, Map<String, String> params) {
    final id = int.parse(params['id']!);
    final result = openFiles.containsKey(id) ? openFiles[id]!.fileInfoMap : {};
    final jsonValue = json.encode(result);
    return Future.value(ServiceExtensionResponse.result(jsonValue));
  }

  String get name => file.path;
}

abstract class _Process implements Process {
  abstract String _path;
  abstract List<String> _arguments;
  abstract String? _workingDirectory;
}

class _SpawnedProcessResourceInfo extends _IOResourceInfo {
  static const String _type = 'SpawnedProcess';
  final _Process process;
  final int startedAt;

  static Map<int, _SpawnedProcessResourceInfo> startedProcesses =
      Map<int, _SpawnedProcessResourceInfo>();

  _SpawnedProcessResourceInfo(this.process)
      : startedAt = _IOResourceInfo.timestamp,
        super(_type) {
    processStarted(this);
  }

  String get name => process._path;

  void stopped() => processStopped(this);

  Map<String, dynamic> get fullValueMap => {
        'type': type,
        'id': id,
        'name': name,
        'pid': process.pid,
        'startedAt': startedAt,
        'arguments': process._arguments,
        'workingDirectory':
            process._workingDirectory == null ? '.' : process._workingDirectory,
      };

  static processStarted(_SpawnedProcessResourceInfo info) {
    assert(!startedProcesses.containsKey(info.id));
    startedProcesses[info.id] = info;
  }

  static processStopped(_SpawnedProcessResourceInfo info) {
    assert(startedProcesses.containsKey(info.id));
    startedProcesses.remove(info.id);
  }

  static Iterable<Map<String, dynamic>> getStartedProcessesList() =>
      List.from(startedProcesses.values.map(
        (e) => e.referenceValueMap,
      ));

  static Future<ServiceExtensionResponse> getStartedProcesses(
      String function, Map<String, String> params) {
    assert(function == 'ext.dart.io.getSpawnedProcesses');
    final data = {
      'type': 'SpawnedProcessList',
      'processes': getStartedProcessesList(),
    };
    final jsonValue = json.encode(data);
    return Future.value(ServiceExtensionResponse.result(jsonValue));
  }

  static Future<ServiceExtensionResponse> getProcessInfoMapById(
      String function, Map<String, String> params) {
    final id = int.parse(params['id']!);
    final result = startedProcesses.containsKey(id)
        ? startedProcesses[id]!.fullValueMap
        : {};
    final jsonValue = json.encode(result);
    return Future.value(ServiceExtensionResponse.result(jsonValue));
  }
}
