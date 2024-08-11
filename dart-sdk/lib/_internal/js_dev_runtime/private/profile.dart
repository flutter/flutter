// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file supports profiling dynamic calls.
part of dart._debugger;

class _MethodStats {
  final String typeName;
  final String frame;
  double count = 0.0;

  _MethodStats(this.typeName, this.frame);
}

class _CallMethodRecord {
  var jsError;
  var type;

  _CallMethodRecord(this.jsError, this.type);
}

/// Size for the random sample of dynamic calls.
int _callRecordSampleSize = 5000;

/// If the number of dynamic calls exceeds [_callRecordSampleSize] this list
/// will represent a random sample of the dynamic calls made.
var _callMethodRecords = <_CallMethodRecord>[];

/// If the number of dynamic calls exceeds [_callRecordSampleSize] this value
/// will be greater than [_callMethodRecords.length].
int _totalCallRecords = 0;

/// Minimum number of samples to consider a profile entry relevant.
/// This could be set a lot higher. We set this value so users are not
/// confused into thinking that a dynamic call that occurred once but was
/// randomly included in the sample is relevant.
num _minCount = 2;

/// Cache mapping from raw stack frames to source mapped stack frames to
/// speedup lookup of source map frames when running the profiler.
/// The number of source map entries looked up makes caching more important
/// in this case than for typical source map use cases.
var _frameMappingCache = <String, String>{};

List<List<Object>> getDynamicStats() {
  // Process the accumulated method stats. This may be quite slow as processing
  // stack traces is expensive. If there are performance blockers, we should
  // switch to a sampling approach that caps the number of _callMethodRecords
  // and uses random sampling to decide whether to add each additional record
  // to the sample. Main change required is that we need to still show the total
  // raw number of dynamic calls so that the magnitude of the dynamic call
  // performance hit is clear to users.

  var callMethodStats = <String, _MethodStats>{};
  if (_callMethodRecords.length > 0) {
    // Ratio between total record count and sampled records count.
    var recordRatio = _totalCallRecords / _callMethodRecords.length;
    for (var record in _callMethodRecords) {
      String stackStr = JS<String>('!', '#.stack', record.jsError);
      var frames = stackStr.split('\n');
      // Skip first two lines as the first couple frames are from the dart
      // runtime.
      var src = frames
          .skip(2)
          .map((f) => _frameMappingCache.putIfAbsent(
              f, () => stackTraceMapper!('\n$f')))
          .firstWhere((f) => !f.startsWith('dart:'), orElse: () => '');

      var actualTypeName = dart.typeName(record.type);
      callMethodStats
          .putIfAbsent(
              "$actualTypeName <$src>", () => _MethodStats(actualTypeName, src))
          .count += recordRatio;
    }

    // filter out all calls that did not occur at least _minCount times in the
    // random sample if we are dealing with a random sample instead of a
    // complete profile.
    if (_totalCallRecords != _callMethodRecords.length) {
      for (var k in callMethodStats.keys.toList()) {
        var stats = callMethodStats[k]!;
        var threshold = _minCount * recordRatio;
        if (stats.count + 0.001 < threshold) {
          callMethodStats.remove(k);
        }
      }
    }
  }
  _callMethodRecords.clear();
  _totalCallRecords = 0;
  var keys = callMethodStats.keys.toList();
  keys.sort(
      (a, b) => callMethodStats[b]!.count.compareTo(callMethodStats[a]!.count));
  var ret = <List<Object>>[];
  for (var key in keys) {
    var stats = callMethodStats[key]!;
    ret.add([stats.typeName, stats.frame, stats.count.round()]);
  }
  return ret;
}

clearDynamicStats() {
  _callMethodRecords.clear();
}

// We need to set this property while the sdk is only partially initialized
// so we cannot use a regular Dart field.
bool get _trackProfile => JS<bool>('!', 'dart.__trackProfile');

trackCall(obj) {
  if (JS<bool>('!', '!#', _trackProfile)) return;
  int index = -1;
  _totalCallRecords++;
  if (_callMethodRecords.length == _callRecordSampleSize) {
    // Ensure that each sample has an equal
    // _callRecordSampleSize / _totalCallRecords chance of inclusion
    // by choosing to include the new record in the sample the with the
    // appropriate probability randomly evicting one of the existing records.
    // Unfortunately we can't use the excellent Random.nextInt method defined
    // by Dart from within this library.
    index = JS<int>('!', 'Math.floor(Math.random() * #)', _totalCallRecords);
    if (index >= _callMethodRecords.length) return; // don't sample
  }
  var record =
      _CallMethodRecord(JS('', 'new Error()'), dart.getReifiedType(obj));
  if (index == -1) {
    _callMethodRecords.add(record);
  } else {
    _callMethodRecords[index] = record;
  }
}
