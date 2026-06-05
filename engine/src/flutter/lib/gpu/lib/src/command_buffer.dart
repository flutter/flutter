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

  bool _submitted = false;

  /// Whether [submit] has been called on this command buffer.
  bool get submitted => _submitted;

  RenderPass createRenderPass(RenderTarget renderTarget) {
    return RenderPass._(_gpuContext, this, renderTarget);
  }

  void submit({CompletionCallback? completionCallback}) {
    if (_submitted) {
      throw StateError('CommandBuffer has already been submitted.');
    }
    String? error = _submit(completionCallback);
    if (error != null) {
      throw Exception(error);
    }
    _submitted = true;
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
