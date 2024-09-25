// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

base class ColorAttachment {
  ColorAttachment({
    this.loadAction = LoadAction.clear,
    this.storeAction = StoreAction.store,
    vm.Vector4? clearValue = null,
    required this.texture,
    this.resolveTexture = null,
  }) : clearValue = clearValue ?? vm.Vector4.zero();

  LoadAction loadAction;
  StoreAction storeAction;
  vm.Vector4 clearValue;

  Texture texture;
  Texture? resolveTexture;
}

base class DepthStencilAttachment {
  DepthStencilAttachment({
    this.depthLoadAction = LoadAction.clear,
    this.depthStoreAction = StoreAction.dontCare,
    this.depthClearValue = 0.0,
    this.stencilLoadAction = LoadAction.clear,
    this.stencilStoreAction = StoreAction.dontCare,
    this.stencilClearValue = 0,
    required this.texture,
  });

  LoadAction depthLoadAction;
  StoreAction depthStoreAction;
  double depthClearValue;

  LoadAction stencilLoadAction;
  StoreAction stencilStoreAction;
  int stencilClearValue;

  Texture texture;
}

base class StencilConfig {
  StencilConfig({
    this.compareFunction = CompareFunction.always,
    this.stencilFailureOperation = StencilOperation.keep,
    this.depthFailureOperation = StencilOperation.keep,
    this.depthStencilPassOperation = StencilOperation.keep,
    this.readMask = 0xFFFFFFFF,
    this.writeMask = 0xFFFFFFFF,
  });

  CompareFunction compareFunction;
  StencilOperation stencilFailureOperation;
  StencilOperation depthFailureOperation;
  StencilOperation depthStencilPassOperation;
  int readMask;
  int writeMask;
}

// Note: When modifying this enum, also update
//       `InternalFlutterGpu_RenderPass_SetStencilConfig` in `gpu/render_pass.cc`.
enum StencilFace {
  both,
  front,
  back,
}

base class ColorBlendEquation {
  ColorBlendEquation({
    this.colorBlendOperation = BlendOperation.add,
    this.sourceColorBlendFactor = BlendFactor.one,
    this.destinationColorBlendFactor = BlendFactor.oneMinusSourceAlpha,
    this.alphaBlendOperation = BlendOperation.add,
    this.sourceAlphaBlendFactor = BlendFactor.one,
    this.destinationAlphaBlendFactor = BlendFactor.oneMinusSourceAlpha,
  });

  BlendOperation colorBlendOperation;
  BlendFactor sourceColorBlendFactor;
  BlendFactor destinationColorBlendFactor;

  BlendOperation alphaBlendOperation;
  BlendFactor sourceAlphaBlendFactor;
  BlendFactor destinationAlphaBlendFactor;
}

base class SamplerOptions {
  SamplerOptions({
    this.minFilter = MinMagFilter.nearest,
    this.magFilter = MinMagFilter.nearest,
    this.mipFilter = MipFilter.nearest,
    this.widthAddressMode = SamplerAddressMode.clampToEdge,
    this.heightAddressMode = SamplerAddressMode.clampToEdge,
  });

  MinMagFilter minFilter;
  MinMagFilter magFilter;
  MipFilter mipFilter;
  SamplerAddressMode widthAddressMode;
  SamplerAddressMode heightAddressMode;
}

base class RenderTarget {
  const RenderTarget(
      {this.colorAttachments = const <ColorAttachment>[],
      this.depthStencilAttachment});

  RenderTarget.singleColor(ColorAttachment colorAttachment,
      {DepthStencilAttachment? depthStencilAttachment})
      : this(
            colorAttachments: [colorAttachment],
            depthStencilAttachment: depthStencilAttachment);

  final List<ColorAttachment> colorAttachments;
  final DepthStencilAttachment? depthStencilAttachment;
}

base class RenderPass extends NativeFieldWrapperClass1 {
  /// Creates a new RenderPass.
  RenderPass._(CommandBuffer commandBuffer, RenderTarget renderTarget) {
    _initialize();
    String? error;
    for (final (index, color) in renderTarget.colorAttachments.indexed) {
      error = _setColorAttachment(
          index,
          color.loadAction.index,
          color.storeAction.index,
          color.clearValue.r,
          color.clearValue.g,
          color.clearValue.b,
          color.clearValue.a,
          color.texture,
          color.resolveTexture);
      if (error != null) {
        throw Exception(error);
      }
    }
    if (renderTarget.depthStencilAttachment != null) {
      final ds = renderTarget.depthStencilAttachment!;
      error = _setDepthStencilAttachment(
          ds.depthLoadAction.index,
          ds.depthStoreAction.index,
          ds.depthClearValue,
          ds.stencilLoadAction.index,
          ds.stencilStoreAction.index,
          ds.stencilClearValue,
          ds.texture);
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

  void bindIndexBuffer(
      BufferView bufferView, IndexType indexType, int indexCount) {
    bufferView.buffer._bindAsIndexBuffer(this, bufferView.offsetInBytes,
        bufferView.lengthInBytes, indexType, indexCount);
  }

  void bindUniform(UniformSlot slot, BufferView bufferView) {
    bool success = bufferView.buffer._bindAsUniform(
        this, slot, bufferView.offsetInBytes, bufferView.lengthInBytes);
    if (!success) {
      throw Exception("Failed to bind uniform");
    }
  }

  void bindTexture(UniformSlot slot, Texture texture,
      {SamplerOptions? sampler}) {
    if (sampler == null) {
      sampler = SamplerOptions();
    }

    bool success = _bindTexture(
        slot.shader,
        slot.uniformName,
        texture,
        sampler.minFilter.index,
        sampler.magFilter.index,
        sampler.mipFilter.index,
        sampler.widthAddressMode.index,
        sampler.heightAddressMode.index);
    if (!success) {
      throw Exception("Failed to bind texture");
    }
  }

  void clearBindings() {
    _clearBindings();
  }

  void setColorBlendEnable(bool enable, {int colorAttachmentIndex = 0}) {
    _setColorBlendEnable(colorAttachmentIndex, enable);
  }

  void setColorBlendEquation(ColorBlendEquation equation,
      {int colorAttachmentIndex = 0}) {
    _setColorBlendEquation(
        colorAttachmentIndex,
        equation.colorBlendOperation.index,
        equation.sourceColorBlendFactor.index,
        equation.destinationColorBlendFactor.index,
        equation.alphaBlendOperation.index,
        equation.sourceAlphaBlendFactor.index,
        equation.destinationAlphaBlendFactor.index);
  }

  void setDepthWriteEnable(bool enable) {
    _setDepthWriteEnable(enable);
  }

  void setDepthCompareOperation(CompareFunction compareFunction) {
    _setDepthCompareOperation(compareFunction.index);
  }

  void setStencilReference(int referenceValue) {
    if (referenceValue < 0 || referenceValue > 0xFFFFFFFF) {
      throw Exception(
          "The stencil reference value must be in the range [0, 2^32 - 1]");
    }
    _setStencilReference(referenceValue);
  }

  void setStencilConfig(StencilConfig configuration,
      {StencilFace targetFace = StencilFace.both}) {
    if (configuration.readMask < 0 || configuration.readMask > 0xFFFFFFFF) {
      throw Exception("The stencil read mask must be in the range [0, 255]");
    }
    if (configuration.writeMask < 0 || configuration.writeMask > 0xFFFFFFFF) {
      throw Exception("The stencil write mask must be in the range [0, 255]");
    }
    _setStencilConfig(
        configuration.compareFunction.index,
        configuration.stencilFailureOperation.index,
        configuration.depthFailureOperation.index,
        configuration.depthStencilPassOperation.index,
        configuration.readMask,
        configuration.writeMask,
        targetFace.index);
  }

  void setCullMode(CullMode cullMode) {
    _setCullMode(cullMode.index);
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

  @Native<
      Handle Function(
          Pointer<Void>,
          Int,
          Int,
          Int,
          Float,
          Float,
          Float,
          Float,
          Pointer<Void>,
          Handle)>(symbol: 'InternalFlutterGpu_RenderPass_SetColorAttachment')
  external String? _setColorAttachment(
      int colorAttachmentIndex,
      int loadAction,
      int storeAction,
      double clearColorR,
      double clearColorG,
      double clearColorB,
      double clearColorA,
      Texture texture,
      Texture? resolveTexture);

  @Native<
          Handle Function(
              Pointer<Void>, Int, Int, Float, Int, Int, Int, Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetDepthStencilAttachment')
  external String? _setDepthStencilAttachment(
      int depthLoadAction,
      int depthStoreAction,
      double depthClearValue,
      int stencilLoadAction,
      int stencilStoreAction,
      int stencilClearValue,
      Texture texture);

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

  @Native<Void Function(Pointer<Void>, Pointer<Void>, Int, Int, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_BindIndexBufferDevice')
  external void _bindIndexBufferDevice(DeviceBuffer buffer, int offsetInBytes,
      int lengthInBytes, int indexType, int indexCount);

  @Native<Void Function(Pointer<Void>, Pointer<Void>, Int, Int, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_BindIndexBufferHost')
  external void _bindIndexBufferHost(HostBuffer buffer, int offsetInBytes,
      int lengthInBytes, int indexType, int indexCount);

  @Native<
      Bool Function(Pointer<Void>, Pointer<Void>, Handle, Pointer<Void>, Int,
          Int)>(symbol: 'InternalFlutterGpu_RenderPass_BindUniformDevice')
  external bool _bindUniformDevice(Shader shader, String uniformName,
      DeviceBuffer buffer, int offsetInBytes, int lengthInBytes);

  @Native<
      Bool Function(Pointer<Void>, Pointer<Void>, Handle, Pointer<Void>, Int,
          Int)>(symbol: 'InternalFlutterGpu_RenderPass_BindUniformHost')
  external bool _bindUniformHost(Shader shader, String uniformName,
      HostBuffer buffer, int offsetInBytes, int lengthInBytes);

  @Native<
      Bool Function(
          Pointer<Void>,
          Pointer<Void>,
          Handle,
          Pointer<Void>,
          Int,
          Int,
          Int,
          Int,
          Int)>(symbol: 'InternalFlutterGpu_RenderPass_BindTexture')
  external bool _bindTexture(
      Shader shader,
      String uniformName,
      Texture texture,
      int minFilter,
      int magFilter,
      int mipFilter,
      int widthAddressMode,
      int heightAddressMode);

  @Native<Void Function(Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_RenderPass_ClearBindings')
  external void _clearBindings();

  @Native<Void Function(Pointer<Void>, Int, Bool)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetColorBlendEnable')
  external void _setColorBlendEnable(int colorAttachmentIndex, bool enable);

  @Native<Void Function(Pointer<Void>, Int, Int, Int, Int, Int, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetColorBlendEquation')
  external void _setColorBlendEquation(
      int colorAttachmentIndex,
      int colorBlendOperation,
      int sourceColorBlendFactor,
      int destinationColorBlendFactor,
      int alphaBlendOperation,
      int sourceAlphaBlendFactor,
      int destinationAlphaBlendFactor);

  @Native<Void Function(Pointer<Void>, Bool)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetDepthWriteEnable')
  external void _setDepthWriteEnable(bool enable);

  @Native<Void Function(Pointer<Void>, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetDepthCompareOperation')
  external void _setDepthCompareOperation(int compareOperation);

  @Native<Void Function(Pointer<Void>, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetStencilReference')
  external void _setStencilReference(int referenceValue);

  @Native<Void Function(Pointer<Void>, Int, Int, Int, Int, Int, Int, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetStencilConfig')
  external void _setStencilConfig(
      int compareFunction,
      int stencilFailureOperation,
      int depthFailureOperation,
      int depthStencilPassOperation,
      int readMask,
      int writeMask,
      int target_face);

  @Native<Void Function(Pointer<Void>, Int)>(
      symbol: 'InternalFlutterGpu_RenderPass_SetCullMode')
  external void _setCullMode(int cullMode);

  @Native<Bool Function(Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_RenderPass_Draw')
  external bool _draw();
}
