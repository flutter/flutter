// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../usage.dart';
import '../uuid/uuid.dart';

String postEncode(Map<String, dynamic> map) {
  // &foo=bar
  return map.keys.map((key) {
    var value = '${map[key]}';
    return '$key=${Uri.encodeComponent(value)}';
  }).join('&');
}

/// A throttling algorithm. This models the throttling after a bucket with
/// water dripping into it at the rate of 1 drop per second. If the bucket has
/// water when an operation is requested, 1 drop of water is removed and the
/// operation is performed. If not the operation is skipped. This algorithm
/// lets operations be performed in bursts without throttling, but holds the
/// overall average rate of operations to 1 per second.
class ThrottlingBucket {
  final int startingCount;
  int drops;
  late int _lastReplenish;

  ThrottlingBucket(this.startingCount) : drops = startingCount {
    _lastReplenish = DateTime.now().millisecondsSinceEpoch;
  }

  bool removeDrop() {
    _checkReplenish();

    if (drops <= 0) {
      return false;
    } else {
      drops--;
      return true;
    }
  }

  void _checkReplenish() {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_lastReplenish + 1000 < now) {
      final inc = (now - _lastReplenish) ~/ 1000;
      drops = math.min(drops + inc, startingCount);
      _lastReplenish += (1000 * inc);
    }
  }
}

class AnalyticsImpl implements Analytics {
  static const String _defaultAnalyticsUrl =
      'https://www.google-analytics.com/collect';

  static const String _defaultAnalyticsBatchingUrl =
      'https://www.google-analytics.com/batch';

  @override
  final String trackingId;
  @override
  final String? applicationName;
  @override
  final String? applicationVersion;

  final PersistentProperties properties;
  final PostHandler postHandler;

  final ThrottlingBucket _bucket = ThrottlingBucket(20);
  final Map<String, dynamic> _variableMap = {};

  final List<Future> _futures = [];

  @override
  AnalyticsOpt analyticsOpt = AnalyticsOpt.optOut;

  final Duration? _batchingDelay;
  final Queue<String> _batchedEvents = Queue<String>();
  bool _isSendingScheduled = false;

  final String _url;
  final String _batchingUrl;

  final StreamController<Map<String, dynamic>> _sendController =
      StreamController.broadcast(sync: true);

  AnalyticsImpl(
    this.trackingId,
    this.properties,
    this.postHandler, {
    this.applicationName,
    this.applicationVersion,
    String? analyticsUrl,
    String? analyticsBatchingUrl,
    Duration? batchingDelay,
  })  : _url = analyticsUrl ?? _defaultAnalyticsUrl,
        _batchingDelay = batchingDelay,
        _batchingUrl = analyticsBatchingUrl ?? _defaultAnalyticsBatchingUrl {
    if (applicationName != null) setSessionValue('an', applicationName);
    if (applicationVersion != null) setSessionValue('av', applicationVersion);
  }

  bool? _firstRun;

  @override
  bool get firstRun {
    if (_firstRun == null) {
      _firstRun = properties['firstRun'] == null;

      if (properties['firstRun'] != false) {
        properties['firstRun'] = false;
      }
    }

    return _firstRun!;
  }

  @override
  bool get enabled {
    var optIn = analyticsOpt == AnalyticsOpt.optIn;
    return optIn
        ? properties['enabled'] == true
        : properties['enabled'] != false;
  }

  @override
  set enabled(bool value) {
    properties['enabled'] = value;
  }

  @override
  Future sendScreenView(String viewName, {Map<String, String>? parameters}) {
    var args = <String, String>{'cd': viewName, ...?parameters};
    return _enqueuePayload('screenview', args);
  }

  @override
  Future sendEvent(String category, String action,
      {String? label, int? value, Map<String, String>? parameters}) {
    final args = <String, String>{
      'ec': category,
      'ea': action,
      if (label != null) 'el': label,
      if (value != null) 'ev': value.toString(),
      ...?parameters
    };

    return _enqueuePayload('event', args);
  }

  @override
  Future sendSocial(String network, String action, String target) {
    var args = <String, String>{'sn': network, 'sa': action, 'st': target};
    return _enqueuePayload('social', args);
  }

  @override
  Future sendTiming(String variableName, int time,
      {String? category, String? label}) {
    var args = <String, String>{
      'utv': variableName,
      'utt': time.toString(),
      if (label != null) 'utl': label,
      if (category != null) 'utc': category,
    };

    return _enqueuePayload('timing', args);
  }

  @override
  AnalyticsTimer startTimer(String variableName,
      {String? category, String? label}) {
    return AnalyticsTimer(this, variableName, category: category, label: label);
  }

  @override
  Future sendException(String description, {bool? fatal}) {
    // We trim exceptions to a max length; google analytics will apply it's own
    // truncation, likely around 150 chars or so.
    const maxExceptionLength = 1000;

    // In order to ensure that the client of this API is not sending any PII
    // data, we strip out any stack trace that may reference a path on the
    // user's drive (file:/...).
    if (description.contains('file:/')) {
      description = description.substring(0, description.indexOf('file:/'));
    }

    description = description.replaceAll('\n', '; ');

    if (description.length > maxExceptionLength) {
      description = description.substring(0, maxExceptionLength);
    }

    var args = <String, String>{
      'exd': description,
      if (fatal != null && fatal) 'exf': '1',
    };
    return _enqueuePayload('exception', args);
  }

  @override
  dynamic getSessionValue(String param) => _variableMap[param];

  @override
  void setSessionValue(String param, dynamic value) {
    if (value == null) {
      _variableMap.remove(param);
    } else {
      _variableMap[param] = value;
    }
  }

  @override
  Stream<Map<String, dynamic>> get onSend => _sendController.stream;

  @override
  Future<List<dynamic>> waitForLastPing({Duration? timeout}) async {
    // If there are pending messages, send them now.
    if (_batchedEvents.isNotEmpty) {
      _trySendBatches(Completer<void>());
    }
    var f = Future.wait(_futures);
    if (timeout != null) f = f.timeout(timeout, onTimeout: () => []);
    return f;
  }

  @override
  void close() => postHandler.close();

  @override
  String get clientId => properties['clientId'] ??= Uuid().generateV4();

  /// Send raw data to analytics. Callers should generally use one of the typed
  /// methods (`sendScreenView`, `sendEvent`, ...).
  ///
  /// Valid values for [hitType] are: 'pageview', 'screenview', 'event',
  /// 'transaction', 'item', 'social', 'exception', and 'timing'.
  Future sendRaw(String hitType, Map<String, dynamic> args) {
    return _enqueuePayload(hitType, args);
  }

  /// Puts a single hit in the queue. If the queue was empty - start waiting
  /// for the result of [_batchingDelay] before sending all enqueued events.
  ///
  /// Valid values for [hitType] are: 'pageview', 'screenview', 'event',
  /// 'transaction', 'item', 'social', 'exception', and 'timing'.
  Future<void> _enqueuePayload(
    String hitType,
    Map<String, dynamic> args,
  ) async {
    if (!enabled) return;
    // TODO(sigurdm): Really all the 'send' methods should not return Futures
    // there is not much point in waiting for it. Only [waitForLastPing].
    final completer = Completer<void>();
    final eventArgs = <String, String>{
      ...args,
      ..._variableMap,
      'v': '1', // protocol version
      'tid': trackingId,
      'cid': clientId,
      't': hitType,
    };

    _sendController.add(eventArgs);
    _batchedEvents.add(postHandler.encodeHit(eventArgs));

    // If [_batchingDelay] is null we don't do batching.
    // TODO(sigurdm): reconsider this.
    final batchingDelay = _batchingDelay;
    if (batchingDelay == null) {
      _trySendBatches(completer);
    } else {
      // First check if we have a full batch - if so, send them immediately.
      if (_batchedEvents.length >= _maxHitsPerBatch ||
          _batchedEvents.fold<int>(0, (s, e) => s + e.length) >=
              _maxBytesPerBatch) {
        _trySendBatches(completer);
      } else if (!_isSendingScheduled) {
        _isSendingScheduled = true;
        // ignore: unawaited_futures
        Future.delayed(batchingDelay).then((value) {
          _isSendingScheduled = false;
          _trySendBatches(completer);
        });
      }
    }
    return completer.future;
  }

  // Send no more than 20 messages per batch.
  static const _maxHitsPerBatch = 20;
  // Send no more than 16K per batch.
  static const _maxBytesPerBatch = 16000;

  void _trySendBatches(Completer<void> completer) {
    final futures = <Future>[];
    while (_batchedEvents.isNotEmpty) {
      final batch = <String>[];
      final totalLength = 0;

      while (true) {
        if (_batchedEvents.isEmpty) break;
        if (totalLength + _batchedEvents.first.length > _maxBytesPerBatch) {
          break;
        }
        batch.add(_batchedEvents.removeFirst());
        if (batch.length == _maxHitsPerBatch) break;
      }
      if (_bucket.removeDrop()) {
        final future = postHandler.sendPost(
            batch.length == 1 ? _url : _batchingUrl, batch);
        _recordFuture(future);
        futures.add(future);
      }
    }
    completer.complete(Future.wait(futures).then((_) {}));
  }

  void _recordFuture(Future f) {
    _futures.add(f);
    f.whenComplete(() => _futures.remove(f));
  }
}

/// A persistent key/value store. An [AnalyticsImpl] instance expects to have
/// one of these injected into it.
///
/// There are default implementations for `dart:io` and `dart:html` clients.
///
/// The [name] parameter is used to uniquely store these properties on disk /
/// persistent storage.
abstract class PersistentProperties {
  final String name;

  PersistentProperties(this.name);

  dynamic operator [](String key);

  void operator []=(String key, dynamic value);

  /// Re-read settings from the backing store. This may be a no-op on some
  /// platforms.
  void syncSettings();
}

/// A utility class to perform HTTP POSTs.
///
/// An [AnalyticsImpl] instance expects to have one of these injected into it.
/// There are default implementations for `dart:io` and `dart:html` clients.
///
/// The POST information should be sent on a best-effort basis.
///
/// The `Future` from [sendPost] should complete when the operation is finished,
/// but failures to send the information should be silent.
abstract class PostHandler {
  Future sendPost(String url, List<String> batch);
  String encodeHit(Map<String, String> hit);

  /// Free any used resources.
  void close();
}
