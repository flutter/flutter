// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

base class ColorAttachment {
  ColorAttachment(
      {this.loadAction = LoadAction.clear,
      this.storeAction = StoreAction.store,
      this.clearColor = const ui.Color(0x00000000),
      required this.texture,
      this.resolveTexture = null});

  LoadAction loadAction;
  StoreAction storeAction;
  ui.Color clearColor;
  Texture texture;
  Texture? resolveTexture;
}

base class StencilAttachment {
  StencilAttachment(
      {this.loadAction = LoadAction.clear,
      this.storeAction = StoreAction.dontCare,
      this.clearStencil = 0,
      required this.texture});

  LoadAction loadAction;
  StoreAction storeAction;
  int clearStencil;
  Texture texture;
}

/// A descriptor for RenderPass creation. Defines the output targets for raster
/// pipelines.
base class RenderTarget {}

base class RenderPass extends NativeFieldWrapperClass1 {
  /// Creates a new RenderPass.
  RenderPass._(CommandBuffer commandBuffer, ColorAttachment colorAttachment,
      StencilAttachment? stencilAttachment) {
    _initialize();
    String? error;
    error = _setColorAttachment(
        colorAttachment.loadAction.index,
        colorAttachment.storeAction.index,
        colorAttachment.clearColor.value,
        colorAttachment.texture,
        colorAttachment.resolveTexture);
    if (error != null) {
      throw Exception(error);
    }
    if (stencilAttachment != null) {
      error = _setStencilAttachment(
          stencilAttachment.loadAction.index,
          stencilAttachment.storeAction.index,
          stencilAttachment.clearStencil,
          stencilAttachment.texture);
      if (error != null) {
        throw Exception(error);
      }
    }
    error = _begin(commandBuffer);
    if (error != null) {
      throw Exception(error);
    }
  }

  void bindPipeline(RenderPipeline pipeline) {
    _bindPipeline(pipeline);
  }

  void bindVertexBuffer(BufferView bufferView, int vertexCount) {
    bufferView.buffer._bindAsVertexBuffer(
        this, bufferView.offsetInBytes, bufferView.lengthInBytes, vertexCount);
  }

  void bindUniform(UniformSlot slot, BufferView bufferView) {
    bool success = bufferView.buffer._bindAsUniform(
        this, slot, bufferView.offsetInBytes, bufferView.lengthInBytes);
    if (!success) {
      throw Exception("Failed to bind uniform slot");
    }
  }

  void draw() {
    if (!_draw()) {
      throw Exception("Failed to append draw");
    }
  }

  /// Wrap with native counterpart.
  @Native<Void Function(Handle)>(
      symbol: 'InternalFlutterGpu_RenderPass_Initialize')
  external void _initialize();

  @Native<Handle Function(Pointer<Void>, Int, Int, Int, Pointer<Void>, Handle)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetColorAttachment')
  external String? _setColorAttachment(int loadAction, int storeAction,
      int clearColor, Texture texture, Texture? resolveTexture);

  @Native<Handle Function(Pointer<Void>, Int, Int, Int, Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetStencilAttachment')
  external String? _setStencilAttachment(
      int loadAction, int storeAction, int clearStencil, Texture texture);

  @Native<Handle Function(Pointer<Void>, Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_RenderPass_Begin')
  external String? _begin(CommandBuffer commandBuffer);

  @Native<Void Function(Pointer<Void>, Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_RenderPass_BindPipeline')
  external void _bindPipeline(RenderPipeline pipeline);

  @Native<Void Function(Pointer<Void>, Pointer<Void>, Int, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_BindVertexBufferDevice')
  external void _bindVertexBufferDevice(DeviceBuffer buffer, int offsetInBytes,
      int lengthInBytes, int vertexCount);

  @Native<Void Function(Pointer<Void>, Pointer<Void>, Int, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_BindVertexBufferHost')
  external void _bindVertexBufferHost(
      HostBuffer buffer, int offsetInBytes, int lengthInBytes, int vertexCount);

  @Native<Bool Function(Pointer<Void>, Int, Int, Pointer<Void>, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_BindUniformDevice')
  external bool _bindUniformDevice(int stage, int slotId, DeviceBuffer buffer,
      int offsetInBytes, int lengthInBytes);

  @Native<Bool Function(Pointer<Void>, Int, Int, Pointer<Void>, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_BindUniformHost')
  external bool _bindUniformHost(int stage, int slotId, HostBuffer buffer,
      int offsetInBytes, int lengthInBytes);

  @Native<Bool Function(Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_RenderPass_Draw')
  external bool _draw();
}
