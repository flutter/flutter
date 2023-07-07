// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
// ignore: implementation_imports
import 'package:vm_service/src/vm_service.dart';

extension DdsExtension on VmService {
  static bool _factoriesRegistered = false;
  static Version? _ddsVersion;

  /// The [getDartDevelopmentServiceVersion] RPC is used to determine what version of
  /// the Dart Development Service Protocol is served by a DDS instance.
  ///
  /// The result of this call is cached for subsequent invocations.
  Future<Version> getDartDevelopmentServiceVersion() async {
    _ddsVersion ??= await _callHelper<Version>(
      'getDartDevelopmentServiceVersion',
    );
    return _ddsVersion!;
  }

  /// The [getCachedCpuSamples] RPC is used to retrieve a cache of CPU samples
  /// collected under a [UserTag] with name `userTag`.
  Future<CachedCpuSamples> getCachedCpuSamples(
      String isolateId, String userTag) async {
    if (!(await _versionCheck(1, 3))) {
      throw UnimplementedError('getCachedCpuSamples requires DDS version 1.3');
    }
    return _callHelper<CachedCpuSamples>('getCachedCpuSamples', args: {
      'isolateId': isolateId,
      'userTag': userTag,
    });
  }

  /// The [getAvailableCachedCpuSamples] RPC is used to determine which caches of CPU samples
  /// are available. Caches are associated with individual [UserTag] names and are specified
  /// when DDS is started via the `cachedUserTags` parameter.
  Future<AvailableCachedCpuSamples> getAvailableCachedCpuSamples() async {
    if (!(await _versionCheck(1, 3))) {
      throw UnimplementedError(
        'getAvailableCachedCpuSamples requires DDS version 1.3',
      );
    }
    return _callHelper<AvailableCachedCpuSamples>(
      'getAvailableCachedCpuSamples',
    );
  }

  /// Retrieve the event history for `stream`.
  ///
  /// If `stream` does not have event history collected, a parameter error is
  /// returned.
  Future<StreamHistory> getStreamHistory(String stream) async {
    if (!(await _versionCheck(1, 2))) {
      throw UnimplementedError('getStreamHistory requires DDS version 1.2');
    }
    return _callHelper<StreamHistory>('getStreamHistory', args: {
      'stream': stream,
    });
  }

  /// Returns the stream for a given stream id which includes historical
  /// events.
  ///
  /// If `stream` does not have event history collected, a parameter error is
  /// sent over the returned [Stream].
  Stream<Event> onEventWithHistory(String stream) {
    late StreamController<Event> controller;
    late StreamQueue<Event> streamEvents;

    controller = StreamController<Event>(onListen: () async {
      streamEvents = StreamQueue<Event>(onEvent(stream));
      final history = (await getStreamHistory(stream)).history;
      Event? firstStreamEvent;
      unawaited(streamEvents.peek.then((e) {
        firstStreamEvent = e;
      }));
      for (final event in history) {
        if (firstStreamEvent != null &&
            event.timestamp! > firstStreamEvent!.timestamp!) {
          break;
        }
        controller.sink.add(event);
      }
      unawaited(controller.sink.addStream(streamEvents.rest));
    }, onCancel: () {
      try {
        streamEvents.cancel();
      } on StateError {
        // Underlying stream may have already been cancelled.
      }
    });

    return controller.stream;
  }

  /// Returns a new [Stream<Event>] of `Logging` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onLoggingEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onLoggingEventWithHistory => onEventWithHistory('Logging');

  /// Returns a new [Stream<Event>] of `Stdout` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onStdoutEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onStdoutEventWithHistory => onEventWithHistory('Stdout');

  /// Returns a new [Stream<Event>] of `Stderr` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onStderrEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onStderrEventWithHistory => onEventWithHistory('Stderr');

  /// Returns a new [Stream<Event>] of `Extension` events which outputs
  /// historical events before streaming real-time events.
  ///
  /// Note: unlike [onExtensionEvent], the returned stream is a single
  /// subscription stream and a new stream is created for each invocation of
  /// this getter.
  Stream<Event> get onExtensionEventWithHistory =>
      onEventWithHistory('Extension');

  Future<bool> _versionCheck(int major, int minor) async {
    _ddsVersion ??= await getDartDevelopmentServiceVersion();
    return ((_ddsVersion!.major == major && _ddsVersion!.minor! >= minor) ||
        (_ddsVersion!.major! > major));
  }

  Future<T> _callHelper<T>(String method,
      {String? isolateId, Map args = const {}}) {
    if (!_factoriesRegistered) {
      _registerFactories();
    }
    return callMethod(
      method,
      args: {
        if (isolateId != null) 'isolateId': isolateId,
        ...args,
      },
    ).then((e) => e as T);
  }

  static void _registerFactories() {
    addTypeFactory('StreamHistory', StreamHistory.parse);
    addTypeFactory(
      'AvailableCachedCpuSamples',
      AvailableCachedCpuSamples.parse,
    );
    addTypeFactory('CachedCpuSamples', CachedCpuSamples.parse);
    _factoriesRegistered = true;
  }
}

/// A collection of historical [Event]s from some stream.
class StreamHistory extends Response {
  static StreamHistory? parse(Map<String, dynamic>? json) =>
      json == null ? null : StreamHistory._fromJson(json);

  StreamHistory({required List<Event> history}) : _history = history;

  StreamHistory._fromJson(Map<String, dynamic> json)
      : _history = json['history']
            .map(
              (e) => Event.parse(e),
            )
            .toList()
            .cast<Event>() {
    this.json = json;
  }

  @override
  String get type => 'StreamHistory';

  /// Historical [Event]s for a stream.
  List<Event> get history => UnmodifiableListView(_history);
  final List<Event> _history;
}

/// An extension of [CpuSamples] which represents a set of cached samples,
/// associated with a particular [UserTag] name.
class CachedCpuSamples extends CpuSamples {
  static CachedCpuSamples? parse(Map<String, dynamic>? json) =>
      json == null ? null : CachedCpuSamples._fromJson(json);

  CachedCpuSamples({
    required this.userTag,
    this.truncated,
    required int? samplePeriod,
    required int? maxStackDepth,
    required int? sampleCount,
    required int? timeSpan,
    required int? timeOriginMicros,
    required int? timeExtentMicros,
    required int? pid,
    required List<ProfileFunction>? functions,
    required List<CpuSample>? samples,
  }) : super(
          samplePeriod: samplePeriod,
          maxStackDepth: maxStackDepth,
          sampleCount: sampleCount,
          timeSpan: timeSpan,
          timeOriginMicros: timeOriginMicros,
          timeExtentMicros: timeExtentMicros,
          pid: pid,
          functions: functions,
          samples: samples,
        );

  CachedCpuSamples._fromJson(Map<String, dynamic> json)
      : userTag = json['userTag']!,
        truncated = json['truncated'],
        super(
          samplePeriod: json['samplePeriod'] ?? -1,
          maxStackDepth: json['maxStackDepth'] ?? -1,
          sampleCount: json['sampleCount'] ?? -1,
          timeSpan: json['timeSpan'] ?? -1,
          timeOriginMicros: json['timeOriginMicros'] ?? -1,
          timeExtentMicros: json['timeExtentMicros'] ?? -1,
          pid: json['pid'] ?? -1,
          functions: List<ProfileFunction>.from(
            createServiceObject(json['functions'], const ['ProfileFunction'])
                    as List? ??
                [],
          ),
          samples: List<CpuSample>.from(
            createServiceObject(json['samples'], const ['CpuSample'])
                    as List? ??
                [],
          ),
        );

  @override
  String get type => 'CachedCpuSamples';

  /// The name of the [UserTag] associated with this cache of [CpuSamples].
  final String userTag;

  /// Provided if the CPU sample cache has filled and older samples have been
  /// dropped.
  final bool? truncated;
}

/// A collection of [UserTag] names associated with caches of CPU samples.
class AvailableCachedCpuSamples extends Response {
  static AvailableCachedCpuSamples? parse(Map<String, dynamic>? json) =>
      json == null ? null : AvailableCachedCpuSamples._fromJson(json);

  AvailableCachedCpuSamples({
    required this.cacheNames,
  });

  AvailableCachedCpuSamples._fromJson(Map<String, dynamic> json)
      : cacheNames = List<String>.from(json['cacheNames']);

  @override
  String get type => 'AvailableCachedUserTagCpuSamples';

  /// A [List] of [UserTag] names associated with CPU sample caches.
  final List<String> cacheNames;
}
