// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

typedef CompletionCallback<T> = void Function(bool success);

base class CommandBuffer extends NativeFieldWrapperClass1 {
  final GpuContext _gpuContext;

  /// Creates a new CommandBuffer.
  CommandBuffer._(this._gpuContext) {
    _initialize(_gpuContext);
  }

  /// Query sets written by passes created from this command buffer, tracked so
  /// their pending resolves can be completed once the GPU retires the work.
  final List<TimestampQuerySet> _timestampQuerySets = <TimestampQuerySet>[];

  /// Creates a render pass targeting [renderTarget].
  ///
  /// [timestampWrites] records GPU timestamps at the pass's execution
  /// boundaries. Read them back with [TimestampQuerySet.resolve] after
  /// [submit].
  RenderPass createRenderPass(
    RenderTarget renderTarget, {
    TimestampWrites? timestampWrites,
  }) {
    final RenderPass pass = RenderPass._(
      _gpuContext,
      this,
      renderTarget,
      timestampWrites,
    );
    if (timestampWrites != null &&
        !_timestampQuerySets.contains(timestampWrites.querySet)) {
      _timestampQuerySets.add(timestampWrites.querySet);
    }
    return pass;
  }

  void submit({CompletionCallback? completionCallback}) {
    if (_timestampQuerySets.isEmpty) {
      final String? error = _submit(completionCallback);
      if (error != null) {
        throw Exception(error);
      }
      return;
    }

    final List<TimestampQuerySet> querySets = List<TimestampQuerySet>.of(
      _timestampQuerySets,
    );
    _timestampQuerySets.clear();
    for (final TimestampQuerySet querySet in querySets) {
      querySet._onSubmitted();
    }
    final String? error = _submit((bool success) {
      for (final TimestampQuerySet querySet in querySets) {
        querySet._onRetired();
      }
      completionCallback?.call(success);
    });
    if (error != null) {
      // Nothing was scheduled, so nothing will ever retire these.
      for (final TimestampQuerySet querySet in querySets) {
        querySet._onRetired();
      }
      throw Exception(error);
    }
  }

  /// Wrap with native counterpart.
  @Native<Bool Function(Handle, Pointer<Void>)>(
    symbol: 'InternalFlutterGpu_CommandBuffer_Initialize',
  )
  external bool _initialize(GpuContext gpuContext);

  @Native<Handle Function(Pointer<Void>, Handle)>(
    symbol: 'InternalFlutterGpu_CommandBuffer_Submit',
  )
  external String? _submit(CompletionCallback? completionCallback);
}
