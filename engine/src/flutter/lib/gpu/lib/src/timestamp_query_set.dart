// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

/// The timestamps read back from a [TimestampQuerySet].
base class TimestampQueryResults {
  const TimestampQueryResults(this.timestamps, this.disjoint);

  /// Nanosecond timestamps indexed by query slot. A null entry means the slot
  /// was never written, or the GPU discarded its result.
  ///
  /// These are points on the GPU's own timeline, not durations. Subtracting
  /// one from another only measures a pass when the GPU actually executed the
  /// two writes in the order they were recorded. Backends are free to
  /// reorder or overlap work across passes, so treat a negative or
  /// implausible difference as "not measurable this frame" rather than as an
  /// error.
  ///
  /// The origin of the timeline is arbitrary and differs between backends and
  /// between runs. Only differences are meaningful.
  final List<int?> timestamps;

  /// Whether the GPU reported that its timer was interrupted while these
  /// timestamps were recorded. Every entry in [timestamps] is unusable when
  /// this is true.
  final bool disjoint;
}

/// A fixed set of slots that render passes can write GPU timestamps into.
///
/// Create one with [GpuContext.createTimestampQuerySet], attach it to a pass
/// with [TimestampWrites], and read the slots back with [resolve] once the
/// GPU has retired the work.
base class TimestampQuerySet extends NativeFieldWrapperClass1 {
  /// Creates a new TimestampQuerySet.
  TimestampQuerySet._(GpuContext gpuContext, this.count) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'must be at least 1');
    }
    if (!_initialize(gpuContext, count)) {
      throw Exception(
        'TimestampQuerySet creation failed. Check '
        'GpuContext.doesSupportTimestampQueries first.',
      );
    }
  }

  /// The number of slots in this set.
  final int count;

  /// Command buffers referencing this set that the GPU has not retired yet.
  int _pendingSubmissions = 0;

  final List<Completer<TimestampQueryResults>> _pendingResolves =
      <Completer<TimestampQueryResults>>[];

  /// Reads back every slot in this set.
  ///
  /// Completes once the GPU has retired every command buffer that was
  /// submitted with a pass writing into this set. Results are never available
  /// in the frame that recorded them, so this never blocks the frame; it just
  /// completes later.
  ///
  /// When nothing is in flight, this completes with whatever the slots hold
  /// right now, which is all nulls for a set that has never been submitted.
  Future<TimestampQueryResults> resolve() {
    if (_pendingSubmissions == 0) {
      return Future<TimestampQueryResults>.value(_readBack());
    }
    final Completer<TimestampQueryResults> completer =
        Completer<TimestampQueryResults>();
    _pendingResolves.add(completer);
    return completer.future;
  }

  void _onSubmitted() {
    _pendingSubmissions++;
  }

  void _onRetired() {
    if (_pendingSubmissions > 0) {
      _pendingSubmissions--;
    }
    if (_pendingSubmissions > 0 || _pendingResolves.isEmpty) {
      return;
    }
    final TimestampQueryResults results = _readBack();
    final List<Completer<TimestampQueryResults>> completers =
        List<Completer<TimestampQueryResults>>.of(_pendingResolves);
    _pendingResolves.clear();
    for (final Completer<TimestampQueryResults> completer in completers) {
      completer.complete(results);
    }
  }

  TimestampQueryResults _readBack() {
    final Int64List raw = Int64List(count);
    final bool disjoint = _resolve(raw);
    return TimestampQueryResults(
      List<int?>.unmodifiable(<int?>[
        for (final int value in raw) value < 0 ? null : value,
      ]),
      disjoint,
    );
  }

  @Native<Bool Function(Handle, Pointer<Void>, Int)>(
    symbol: 'InternalFlutterGpu_TimestampQuerySet_Initialize',
  )
  external bool _initialize(GpuContext gpuContext, int queryCount);

  @Native<Bool Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_TimestampQuerySet_Resolve',
  )
  external bool _resolve(Int64List timestamps);
}

/// The timestamps a render pass writes at its own execution boundaries.
///
/// Writes are declared when the pass is created rather than recorded as free
/// floating commands, because backends can only sample counters at stage
/// boundaries.
base class TimestampWrites {
  TimestampWrites({
    required this.querySet,
    this.beginningOfPassWriteIndex,
    this.endOfPassWriteIndex,
  });

  /// The set the timestamps are written into.
  final TimestampQuerySet querySet;

  /// The slot written when the GPU begins executing the pass.
  final int? beginningOfPassWriteIndex;

  /// The slot written when the GPU finishes executing the pass.
  final int? endOfPassWriteIndex;

  void _validate() {
    _validateIndex(beginningOfPassWriteIndex, 'beginningOfPassWriteIndex');
    _validateIndex(endOfPassWriteIndex, 'endOfPassWriteIndex');
    if (beginningOfPassWriteIndex != null &&
        beginningOfPassWriteIndex == endOfPassWriteIndex) {
      throw ArgumentError(
        'TimestampWrites cannot write both pass boundaries into the same slot',
      );
    }
  }

  void _validateIndex(int? index, String name) {
    if (index != null && (index < 0 || index >= querySet.count)) {
      throw RangeError.range(index, 0, querySet.count - 1, name);
    }
  }
}
