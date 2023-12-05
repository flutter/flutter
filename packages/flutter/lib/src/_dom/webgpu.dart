// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'webidl.dart';

typedef GPUBufferUsageFlags = int;
typedef GPUMapModeFlags = int;
typedef GPUTextureUsageFlags = int;
typedef GPUShaderStageFlags = int;
typedef GPUBindingResource = JSObject;
typedef GPUPipelineConstantValue = num;
typedef GPUColorWriteFlags = int;
typedef GPUImageCopyExternalImageSource = JSObject;
typedef GPUBufferDynamicOffset = int;
typedef GPUStencilValue = int;
typedef GPUSampleMask = int;
typedef GPUDepthBias = int;
typedef GPUSize64 = int;
typedef GPUIntegerCoordinate = int;
typedef GPUIndex32 = int;
typedef GPUSize32 = int;
typedef GPUSignedOffset32 = int;
typedef GPUSize64Out = int;
typedef GPUIntegerCoordinateOut = int;
typedef GPUSize32Out = int;
typedef GPUFlagsConstant = int;
typedef GPUColor = JSObject;
typedef GPUOrigin2D = JSObject;
typedef GPUOrigin3D = JSObject;
typedef GPUExtent3D = JSObject;
typedef GPUPowerPreference = String;
typedef GPUFeatureName = String;
typedef GPUBufferMapState = String;
typedef GPUTextureDimension = String;
typedef GPUTextureViewDimension = String;
typedef GPUTextureAspect = String;
typedef GPUTextureFormat = String;
typedef GPUAddressMode = String;
typedef GPUFilterMode = String;
typedef GPUMipmapFilterMode = String;
typedef GPUCompareFunction = String;
typedef GPUBufferBindingType = String;
typedef GPUSamplerBindingType = String;
typedef GPUTextureSampleType = String;
typedef GPUStorageTextureAccess = String;
typedef GPUCompilationMessageType = String;
typedef GPUPipelineErrorReason = String;
typedef GPUAutoLayoutMode = String;
typedef GPUPrimitiveTopology = String;
typedef GPUFrontFace = String;
typedef GPUCullMode = String;
typedef GPUBlendFactor = String;
typedef GPUBlendOperation = String;
typedef GPUStencilOperation = String;
typedef GPUIndexFormat = String;
typedef GPUVertexFormat = String;
typedef GPUVertexStepMode = String;
typedef GPULoadOp = String;
typedef GPUStoreOp = String;
typedef GPUQueryType = String;
typedef GPUCanvasAlphaMode = String;
typedef GPUDeviceLostReason = String;
typedef GPUErrorFilter = String;

@JS()
@staticInterop
@anonymous
class GPUObjectDescriptorBase {
  external factory GPUObjectDescriptorBase({String label});
}

extension GPUObjectDescriptorBaseExtension on GPUObjectDescriptorBase {
  external set label(String value);
  external String get label;
}

@JS('GPUSupportedLimits')
@staticInterop
class GPUSupportedLimits {}

extension GPUSupportedLimitsExtension on GPUSupportedLimits {
  external int get maxTextureDimension1D;
  external int get maxTextureDimension2D;
  external int get maxTextureDimension3D;
  external int get maxTextureArrayLayers;
  external int get maxBindGroups;
  external int get maxBindGroupsPlusVertexBuffers;
  external int get maxBindingsPerBindGroup;
  external int get maxDynamicUniformBuffersPerPipelineLayout;
  external int get maxDynamicStorageBuffersPerPipelineLayout;
  external int get maxSampledTexturesPerShaderStage;
  external int get maxSamplersPerShaderStage;
  external int get maxStorageBuffersPerShaderStage;
  external int get maxStorageTexturesPerShaderStage;
  external int get maxUniformBuffersPerShaderStage;
  external int get maxUniformBufferBindingSize;
  external int get maxStorageBufferBindingSize;
  external int get minUniformBufferOffsetAlignment;
  external int get minStorageBufferOffsetAlignment;
  external int get maxVertexBuffers;
  external int get maxBufferSize;
  external int get maxVertexAttributes;
  external int get maxVertexBufferArrayStride;
  external int get maxInterStageShaderComponents;
  external int get maxInterStageShaderVariables;
  external int get maxColorAttachments;
  external int get maxColorAttachmentBytesPerSample;
  external int get maxComputeWorkgroupStorageSize;
  external int get maxComputeInvocationsPerWorkgroup;
  external int get maxComputeWorkgroupSizeX;
  external int get maxComputeWorkgroupSizeY;
  external int get maxComputeWorkgroupSizeZ;
  external int get maxComputeWorkgroupsPerDimension;
}

@JS('GPUSupportedFeatures')
@staticInterop
class GPUSupportedFeatures {}

extension GPUSupportedFeaturesExtension on GPUSupportedFeatures {}

@JS('WGSLLanguageFeatures')
@staticInterop
class WGSLLanguageFeatures {}

extension WGSLLanguageFeaturesExtension on WGSLLanguageFeatures {}

@JS('GPUAdapterInfo')
@staticInterop
class GPUAdapterInfo {}

extension GPUAdapterInfoExtension on GPUAdapterInfo {
  external String get vendor;
  external String get architecture;
  external String get device;
  external String get description;
}

@JS('GPU')
@staticInterop
class GPU {}

extension GPUExtension on GPU {
  external JSPromise requestAdapter([GPURequestAdapterOptions options]);
  external GPUTextureFormat getPreferredCanvasFormat();
  external WGSLLanguageFeatures get wgslLanguageFeatures;
}

@JS()
@staticInterop
@anonymous
class GPURequestAdapterOptions {
  external factory GPURequestAdapterOptions({
    GPUPowerPreference powerPreference,
    bool forceFallbackAdapter,
  });
}

extension GPURequestAdapterOptionsExtension on GPURequestAdapterOptions {
  external set powerPreference(GPUPowerPreference value);
  external GPUPowerPreference get powerPreference;
  external set forceFallbackAdapter(bool value);
  external bool get forceFallbackAdapter;
}

@JS('GPUAdapter')
@staticInterop
class GPUAdapter {}

extension GPUAdapterExtension on GPUAdapter {
  external JSPromise requestDevice([GPUDeviceDescriptor descriptor]);
  external JSPromise requestAdapterInfo([JSArray unmaskHints]);
  external GPUSupportedFeatures get features;
  external GPUSupportedLimits get limits;
  external bool get isFallbackAdapter;
}

@JS()
@staticInterop
@anonymous
class GPUDeviceDescriptor implements GPUObjectDescriptorBase {
  external factory GPUDeviceDescriptor({
    JSArray requiredFeatures,
    JSAny requiredLimits,
    GPUQueueDescriptor defaultQueue,
  });
}

extension GPUDeviceDescriptorExtension on GPUDeviceDescriptor {
  external set requiredFeatures(JSArray value);
  external JSArray get requiredFeatures;
  external set requiredLimits(JSAny value);
  external JSAny get requiredLimits;
  external set defaultQueue(GPUQueueDescriptor value);
  external GPUQueueDescriptor get defaultQueue;
}

@JS('GPUDevice')
@staticInterop
class GPUDevice implements EventTarget {}

extension GPUDeviceExtension on GPUDevice {
  external void destroy();
  external GPUBuffer createBuffer(GPUBufferDescriptor descriptor);
  external GPUTexture createTexture(GPUTextureDescriptor descriptor);
  external GPUSampler createSampler([GPUSamplerDescriptor descriptor]);
  external GPUExternalTexture importExternalTexture(
      GPUExternalTextureDescriptor descriptor);
  external GPUBindGroupLayout createBindGroupLayout(
      GPUBindGroupLayoutDescriptor descriptor);
  external GPUPipelineLayout createPipelineLayout(
      GPUPipelineLayoutDescriptor descriptor);
  external GPUBindGroup createBindGroup(GPUBindGroupDescriptor descriptor);
  external GPUShaderModule createShaderModule(
      GPUShaderModuleDescriptor descriptor);
  external GPUComputePipeline createComputePipeline(
      GPUComputePipelineDescriptor descriptor);
  external GPURenderPipeline createRenderPipeline(
      GPURenderPipelineDescriptor descriptor);
  external JSPromise createComputePipelineAsync(
      GPUComputePipelineDescriptor descriptor);
  external JSPromise createRenderPipelineAsync(
      GPURenderPipelineDescriptor descriptor);
  external GPUCommandEncoder createCommandEncoder(
      [GPUCommandEncoderDescriptor descriptor]);
  external GPURenderBundleEncoder createRenderBundleEncoder(
      GPURenderBundleEncoderDescriptor descriptor);
  external GPUQuerySet createQuerySet(GPUQuerySetDescriptor descriptor);
  external void pushErrorScope(GPUErrorFilter filter);
  external JSPromise popErrorScope();
  external GPUSupportedFeatures get features;
  external GPUSupportedLimits get limits;
  external GPUQueue get queue;
  external JSPromise get lost;
  external set onuncapturederror(EventHandler value);
  external EventHandler get onuncapturederror;
  external set label(String value);
  external String get label;
}

@JS('GPUBuffer')
@staticInterop
class GPUBuffer {}

extension GPUBufferExtension on GPUBuffer {
  external JSPromise mapAsync(
    GPUMapModeFlags mode, [
    GPUSize64 offset,
    GPUSize64 size,
  ]);
  external JSArrayBuffer getMappedRange([
    GPUSize64 offset,
    GPUSize64 size,
  ]);
  external void unmap();
  external void destroy();
  external GPUSize64Out get size;
  external GPUFlagsConstant get usage;
  external GPUBufferMapState get mapState;
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUBufferDescriptor implements GPUObjectDescriptorBase {
  external factory GPUBufferDescriptor({
    required GPUSize64 size,
    required GPUBufferUsageFlags usage,
    bool mappedAtCreation,
  });
}

extension GPUBufferDescriptorExtension on GPUBufferDescriptor {
  external set size(GPUSize64 value);
  external GPUSize64 get size;
  external set usage(GPUBufferUsageFlags value);
  external GPUBufferUsageFlags get usage;
  external set mappedAtCreation(bool value);
  external bool get mappedAtCreation;
}

@JS()
external $GPUBufferUsage get GPUBufferUsage;

@JS('GPUBufferUsage')
@staticInterop
abstract class $GPUBufferUsage {
  external static GPUFlagsConstant get MAP_READ;
  external static GPUFlagsConstant get MAP_WRITE;
  external static GPUFlagsConstant get COPY_SRC;
  external static GPUFlagsConstant get COPY_DST;
  external static GPUFlagsConstant get INDEX;
  external static GPUFlagsConstant get VERTEX;
  external static GPUFlagsConstant get UNIFORM;
  external static GPUFlagsConstant get STORAGE;
  external static GPUFlagsConstant get INDIRECT;
  external static GPUFlagsConstant get QUERY_RESOLVE;
}

@JS()
external $GPUMapMode get GPUMapMode;

@JS('GPUMapMode')
@staticInterop
abstract class $GPUMapMode {
  external static GPUFlagsConstant get READ;
  external static GPUFlagsConstant get WRITE;
}

@JS('GPUTexture')
@staticInterop
class GPUTexture {}

extension GPUTextureExtension on GPUTexture {
  external GPUTextureView createView([GPUTextureViewDescriptor descriptor]);
  external void destroy();
  external GPUIntegerCoordinateOut get width;
  external GPUIntegerCoordinateOut get height;
  external GPUIntegerCoordinateOut get depthOrArrayLayers;
  external GPUIntegerCoordinateOut get mipLevelCount;
  external GPUSize32Out get sampleCount;
  external GPUTextureDimension get dimension;
  external GPUTextureFormat get format;
  external GPUFlagsConstant get usage;
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUTextureDescriptor implements GPUObjectDescriptorBase {
  external factory GPUTextureDescriptor({
    required GPUExtent3D size,
    GPUIntegerCoordinate mipLevelCount,
    GPUSize32 sampleCount,
    GPUTextureDimension dimension,
    required GPUTextureFormat format,
    required GPUTextureUsageFlags usage,
    JSArray viewFormats,
  });
}

extension GPUTextureDescriptorExtension on GPUTextureDescriptor {
  external set size(GPUExtent3D value);
  external GPUExtent3D get size;
  external set mipLevelCount(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get mipLevelCount;
  external set sampleCount(GPUSize32 value);
  external GPUSize32 get sampleCount;
  external set dimension(GPUTextureDimension value);
  external GPUTextureDimension get dimension;
  external set format(GPUTextureFormat value);
  external GPUTextureFormat get format;
  external set usage(GPUTextureUsageFlags value);
  external GPUTextureUsageFlags get usage;
  external set viewFormats(JSArray value);
  external JSArray get viewFormats;
}

@JS()
external $GPUTextureUsage get GPUTextureUsage;

@JS('GPUTextureUsage')
@staticInterop
abstract class $GPUTextureUsage {
  external static GPUFlagsConstant get COPY_SRC;
  external static GPUFlagsConstant get COPY_DST;
  external static GPUFlagsConstant get TEXTURE_BINDING;
  external static GPUFlagsConstant get STORAGE_BINDING;
  external static GPUFlagsConstant get RENDER_ATTACHMENT;
}

@JS('GPUTextureView')
@staticInterop
class GPUTextureView {}

extension GPUTextureViewExtension on GPUTextureView {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUTextureViewDescriptor implements GPUObjectDescriptorBase {
  external factory GPUTextureViewDescriptor({
    GPUTextureFormat format,
    GPUTextureViewDimension dimension,
    GPUTextureAspect aspect,
    GPUIntegerCoordinate baseMipLevel,
    GPUIntegerCoordinate mipLevelCount,
    GPUIntegerCoordinate baseArrayLayer,
    GPUIntegerCoordinate arrayLayerCount,
  });
}

extension GPUTextureViewDescriptorExtension on GPUTextureViewDescriptor {
  external set format(GPUTextureFormat value);
  external GPUTextureFormat get format;
  external set dimension(GPUTextureViewDimension value);
  external GPUTextureViewDimension get dimension;
  external set aspect(GPUTextureAspect value);
  external GPUTextureAspect get aspect;
  external set baseMipLevel(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get baseMipLevel;
  external set mipLevelCount(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get mipLevelCount;
  external set baseArrayLayer(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get baseArrayLayer;
  external set arrayLayerCount(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get arrayLayerCount;
}

@JS('GPUExternalTexture')
@staticInterop
class GPUExternalTexture {}

extension GPUExternalTextureExtension on GPUExternalTexture {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUExternalTextureDescriptor implements GPUObjectDescriptorBase {
  external factory GPUExternalTextureDescriptor({
    required JSObject source,
    PredefinedColorSpace colorSpace,
  });
}

extension GPUExternalTextureDescriptorExtension
    on GPUExternalTextureDescriptor {
  external set source(JSObject value);
  external JSObject get source;
  external set colorSpace(PredefinedColorSpace value);
  external PredefinedColorSpace get colorSpace;
}

@JS('GPUSampler')
@staticInterop
class GPUSampler {}

extension GPUSamplerExtension on GPUSampler {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUSamplerDescriptor implements GPUObjectDescriptorBase {
  external factory GPUSamplerDescriptor({
    GPUAddressMode addressModeU,
    GPUAddressMode addressModeV,
    GPUAddressMode addressModeW,
    GPUFilterMode magFilter,
    GPUFilterMode minFilter,
    GPUMipmapFilterMode mipmapFilter,
    num lodMinClamp,
    num lodMaxClamp,
    GPUCompareFunction compare,
    int maxAnisotropy,
  });
}

extension GPUSamplerDescriptorExtension on GPUSamplerDescriptor {
  external set addressModeU(GPUAddressMode value);
  external GPUAddressMode get addressModeU;
  external set addressModeV(GPUAddressMode value);
  external GPUAddressMode get addressModeV;
  external set addressModeW(GPUAddressMode value);
  external GPUAddressMode get addressModeW;
  external set magFilter(GPUFilterMode value);
  external GPUFilterMode get magFilter;
  external set minFilter(GPUFilterMode value);
  external GPUFilterMode get minFilter;
  external set mipmapFilter(GPUMipmapFilterMode value);
  external GPUMipmapFilterMode get mipmapFilter;
  external set lodMinClamp(num value);
  external num get lodMinClamp;
  external set lodMaxClamp(num value);
  external num get lodMaxClamp;
  external set compare(GPUCompareFunction value);
  external GPUCompareFunction get compare;
  external set maxAnisotropy(int value);
  external int get maxAnisotropy;
}

@JS('GPUBindGroupLayout')
@staticInterop
class GPUBindGroupLayout {}

extension GPUBindGroupLayoutExtension on GPUBindGroupLayout {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUBindGroupLayoutDescriptor implements GPUObjectDescriptorBase {
  external factory GPUBindGroupLayoutDescriptor({required JSArray entries});
}

extension GPUBindGroupLayoutDescriptorExtension
    on GPUBindGroupLayoutDescriptor {
  external set entries(JSArray value);
  external JSArray get entries;
}

@JS()
@staticInterop
@anonymous
class GPUBindGroupLayoutEntry {
  external factory GPUBindGroupLayoutEntry({
    required GPUIndex32 binding,
    required GPUShaderStageFlags visibility,
    GPUBufferBindingLayout buffer,
    GPUSamplerBindingLayout sampler,
    GPUTextureBindingLayout texture,
    GPUStorageTextureBindingLayout storageTexture,
    GPUExternalTextureBindingLayout externalTexture,
  });
}

extension GPUBindGroupLayoutEntryExtension on GPUBindGroupLayoutEntry {
  external set binding(GPUIndex32 value);
  external GPUIndex32 get binding;
  external set visibility(GPUShaderStageFlags value);
  external GPUShaderStageFlags get visibility;
  external set buffer(GPUBufferBindingLayout value);
  external GPUBufferBindingLayout get buffer;
  external set sampler(GPUSamplerBindingLayout value);
  external GPUSamplerBindingLayout get sampler;
  external set texture(GPUTextureBindingLayout value);
  external GPUTextureBindingLayout get texture;
  external set storageTexture(GPUStorageTextureBindingLayout value);
  external GPUStorageTextureBindingLayout get storageTexture;
  external set externalTexture(GPUExternalTextureBindingLayout value);
  external GPUExternalTextureBindingLayout get externalTexture;
}

@JS()
external $GPUShaderStage get GPUShaderStage;

@JS('GPUShaderStage')
@staticInterop
abstract class $GPUShaderStage {
  external static GPUFlagsConstant get VERTEX;
  external static GPUFlagsConstant get FRAGMENT;
  external static GPUFlagsConstant get COMPUTE;
}

@JS()
@staticInterop
@anonymous
class GPUBufferBindingLayout {
  external factory GPUBufferBindingLayout({
    GPUBufferBindingType type,
    bool hasDynamicOffset,
    GPUSize64 minBindingSize,
  });
}

extension GPUBufferBindingLayoutExtension on GPUBufferBindingLayout {
  external set type(GPUBufferBindingType value);
  external GPUBufferBindingType get type;
  external set hasDynamicOffset(bool value);
  external bool get hasDynamicOffset;
  external set minBindingSize(GPUSize64 value);
  external GPUSize64 get minBindingSize;
}

@JS()
@staticInterop
@anonymous
class GPUSamplerBindingLayout {
  external factory GPUSamplerBindingLayout({GPUSamplerBindingType type});
}

extension GPUSamplerBindingLayoutExtension on GPUSamplerBindingLayout {
  external set type(GPUSamplerBindingType value);
  external GPUSamplerBindingType get type;
}

@JS()
@staticInterop
@anonymous
class GPUTextureBindingLayout {
  external factory GPUTextureBindingLayout({
    GPUTextureSampleType sampleType,
    GPUTextureViewDimension viewDimension,
    bool multisampled,
  });
}

extension GPUTextureBindingLayoutExtension on GPUTextureBindingLayout {
  external set sampleType(GPUTextureSampleType value);
  external GPUTextureSampleType get sampleType;
  external set viewDimension(GPUTextureViewDimension value);
  external GPUTextureViewDimension get viewDimension;
  external set multisampled(bool value);
  external bool get multisampled;
}

@JS()
@staticInterop
@anonymous
class GPUStorageTextureBindingLayout {
  external factory GPUStorageTextureBindingLayout({
    GPUStorageTextureAccess access,
    required GPUTextureFormat format,
    GPUTextureViewDimension viewDimension,
  });
}

extension GPUStorageTextureBindingLayoutExtension
    on GPUStorageTextureBindingLayout {
  external set access(GPUStorageTextureAccess value);
  external GPUStorageTextureAccess get access;
  external set format(GPUTextureFormat value);
  external GPUTextureFormat get format;
  external set viewDimension(GPUTextureViewDimension value);
  external GPUTextureViewDimension get viewDimension;
}

@JS()
@staticInterop
@anonymous
class GPUExternalTextureBindingLayout {
  external factory GPUExternalTextureBindingLayout();
}

@JS('GPUBindGroup')
@staticInterop
class GPUBindGroup {}

extension GPUBindGroupExtension on GPUBindGroup {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUBindGroupDescriptor implements GPUObjectDescriptorBase {
  external factory GPUBindGroupDescriptor({
    required GPUBindGroupLayout layout,
    required JSArray entries,
  });
}

extension GPUBindGroupDescriptorExtension on GPUBindGroupDescriptor {
  external set layout(GPUBindGroupLayout value);
  external GPUBindGroupLayout get layout;
  external set entries(JSArray value);
  external JSArray get entries;
}

@JS()
@staticInterop
@anonymous
class GPUBindGroupEntry {
  external factory GPUBindGroupEntry({
    required GPUIndex32 binding,
    required GPUBindingResource resource,
  });
}

extension GPUBindGroupEntryExtension on GPUBindGroupEntry {
  external set binding(GPUIndex32 value);
  external GPUIndex32 get binding;
  external set resource(GPUBindingResource value);
  external GPUBindingResource get resource;
}

@JS()
@staticInterop
@anonymous
class GPUBufferBinding {
  external factory GPUBufferBinding({
    required GPUBuffer buffer,
    GPUSize64 offset,
    GPUSize64 size,
  });
}

extension GPUBufferBindingExtension on GPUBufferBinding {
  external set buffer(GPUBuffer value);
  external GPUBuffer get buffer;
  external set offset(GPUSize64 value);
  external GPUSize64 get offset;
  external set size(GPUSize64 value);
  external GPUSize64 get size;
}

@JS('GPUPipelineLayout')
@staticInterop
class GPUPipelineLayout {}

extension GPUPipelineLayoutExtension on GPUPipelineLayout {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUPipelineLayoutDescriptor implements GPUObjectDescriptorBase {
  external factory GPUPipelineLayoutDescriptor(
      {required JSArray bindGroupLayouts});
}

extension GPUPipelineLayoutDescriptorExtension on GPUPipelineLayoutDescriptor {
  external set bindGroupLayouts(JSArray value);
  external JSArray get bindGroupLayouts;
}

@JS('GPUShaderModule')
@staticInterop
class GPUShaderModule {}

extension GPUShaderModuleExtension on GPUShaderModule {
  external JSPromise getCompilationInfo();
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUShaderModuleDescriptor implements GPUObjectDescriptorBase {
  external factory GPUShaderModuleDescriptor({
    required String code,
    JSObject sourceMap,
    JSAny hints,
  });
}

extension GPUShaderModuleDescriptorExtension on GPUShaderModuleDescriptor {
  external set code(String value);
  external String get code;
  external set sourceMap(JSObject value);
  external JSObject get sourceMap;
  external set hints(JSAny value);
  external JSAny get hints;
}

@JS()
@staticInterop
@anonymous
class GPUShaderModuleCompilationHint {
  external factory GPUShaderModuleCompilationHint({JSAny layout});
}

extension GPUShaderModuleCompilationHintExtension
    on GPUShaderModuleCompilationHint {
  external set layout(JSAny value);
  external JSAny get layout;
}

@JS('GPUCompilationMessage')
@staticInterop
class GPUCompilationMessage {}

extension GPUCompilationMessageExtension on GPUCompilationMessage {
  external String get message;
  external GPUCompilationMessageType get type;
  external int get lineNum;
  external int get linePos;
  external int get offset;
  external int get length;
}

@JS('GPUCompilationInfo')
@staticInterop
class GPUCompilationInfo {}

extension GPUCompilationInfoExtension on GPUCompilationInfo {
  external JSArray get messages;
}

@JS('GPUPipelineError')
@staticInterop
class GPUPipelineError implements DOMException {
  external factory GPUPipelineError(
    GPUPipelineErrorInit options, [
    String message,
  ]);
}

extension GPUPipelineErrorExtension on GPUPipelineError {
  external GPUPipelineErrorReason get reason;
}

@JS()
@staticInterop
@anonymous
class GPUPipelineErrorInit {
  external factory GPUPipelineErrorInit(
      {required GPUPipelineErrorReason reason});
}

extension GPUPipelineErrorInitExtension on GPUPipelineErrorInit {
  external set reason(GPUPipelineErrorReason value);
  external GPUPipelineErrorReason get reason;
}

@JS()
@staticInterop
@anonymous
class GPUPipelineDescriptorBase implements GPUObjectDescriptorBase {
  external factory GPUPipelineDescriptorBase({required JSAny layout});
}

extension GPUPipelineDescriptorBaseExtension on GPUPipelineDescriptorBase {
  external set layout(JSAny value);
  external JSAny get layout;
}

@JS()
@staticInterop
@anonymous
class GPUProgrammableStage {
  external factory GPUProgrammableStage({
    required GPUShaderModule module,
    required String entryPoint,
    JSAny constants,
  });
}

extension GPUProgrammableStageExtension on GPUProgrammableStage {
  external set module(GPUShaderModule value);
  external GPUShaderModule get module;
  external set entryPoint(String value);
  external String get entryPoint;
  external set constants(JSAny value);
  external JSAny get constants;
}

@JS('GPUComputePipeline')
@staticInterop
class GPUComputePipeline {}

extension GPUComputePipelineExtension on GPUComputePipeline {
  external GPUBindGroupLayout getBindGroupLayout(int index);
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUComputePipelineDescriptor implements GPUPipelineDescriptorBase {
  external factory GPUComputePipelineDescriptor(
      {required GPUProgrammableStage compute});
}

extension GPUComputePipelineDescriptorExtension
    on GPUComputePipelineDescriptor {
  external set compute(GPUProgrammableStage value);
  external GPUProgrammableStage get compute;
}

@JS('GPURenderPipeline')
@staticInterop
class GPURenderPipeline {}

extension GPURenderPipelineExtension on GPURenderPipeline {
  external GPUBindGroupLayout getBindGroupLayout(int index);
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPURenderPipelineDescriptor implements GPUPipelineDescriptorBase {
  external factory GPURenderPipelineDescriptor({
    required GPUVertexState vertex,
    GPUPrimitiveState primitive,
    GPUDepthStencilState depthStencil,
    GPUMultisampleState multisample,
    GPUFragmentState fragment,
  });
}

extension GPURenderPipelineDescriptorExtension on GPURenderPipelineDescriptor {
  external set vertex(GPUVertexState value);
  external GPUVertexState get vertex;
  external set primitive(GPUPrimitiveState value);
  external GPUPrimitiveState get primitive;
  external set depthStencil(GPUDepthStencilState value);
  external GPUDepthStencilState get depthStencil;
  external set multisample(GPUMultisampleState value);
  external GPUMultisampleState get multisample;
  external set fragment(GPUFragmentState value);
  external GPUFragmentState get fragment;
}

@JS()
@staticInterop
@anonymous
class GPUPrimitiveState {
  external factory GPUPrimitiveState({
    GPUPrimitiveTopology topology,
    GPUIndexFormat stripIndexFormat,
    GPUFrontFace frontFace,
    GPUCullMode cullMode,
    bool unclippedDepth,
  });
}

extension GPUPrimitiveStateExtension on GPUPrimitiveState {
  external set topology(GPUPrimitiveTopology value);
  external GPUPrimitiveTopology get topology;
  external set stripIndexFormat(GPUIndexFormat value);
  external GPUIndexFormat get stripIndexFormat;
  external set frontFace(GPUFrontFace value);
  external GPUFrontFace get frontFace;
  external set cullMode(GPUCullMode value);
  external GPUCullMode get cullMode;
  external set unclippedDepth(bool value);
  external bool get unclippedDepth;
}

@JS()
@staticInterop
@anonymous
class GPUMultisampleState {
  external factory GPUMultisampleState({
    GPUSize32 count,
    GPUSampleMask mask,
    bool alphaToCoverageEnabled,
  });
}

extension GPUMultisampleStateExtension on GPUMultisampleState {
  external set count(GPUSize32 value);
  external GPUSize32 get count;
  external set mask(GPUSampleMask value);
  external GPUSampleMask get mask;
  external set alphaToCoverageEnabled(bool value);
  external bool get alphaToCoverageEnabled;
}

@JS()
@staticInterop
@anonymous
class GPUFragmentState implements GPUProgrammableStage {
  external factory GPUFragmentState({required JSArray targets});
}

extension GPUFragmentStateExtension on GPUFragmentState {
  external set targets(JSArray value);
  external JSArray get targets;
}

@JS()
@staticInterop
@anonymous
class GPUColorTargetState {
  external factory GPUColorTargetState({
    required GPUTextureFormat format,
    GPUBlendState blend,
    GPUColorWriteFlags writeMask,
  });
}

extension GPUColorTargetStateExtension on GPUColorTargetState {
  external set format(GPUTextureFormat value);
  external GPUTextureFormat get format;
  external set blend(GPUBlendState value);
  external GPUBlendState get blend;
  external set writeMask(GPUColorWriteFlags value);
  external GPUColorWriteFlags get writeMask;
}

@JS()
@staticInterop
@anonymous
class GPUBlendState {
  external factory GPUBlendState({
    required GPUBlendComponent color,
    required GPUBlendComponent alpha,
  });
}

extension GPUBlendStateExtension on GPUBlendState {
  external set color(GPUBlendComponent value);
  external GPUBlendComponent get color;
  external set alpha(GPUBlendComponent value);
  external GPUBlendComponent get alpha;
}

@JS()
external $GPUColorWrite get GPUColorWrite;

@JS('GPUColorWrite')
@staticInterop
abstract class $GPUColorWrite {
  external static GPUFlagsConstant get RED;
  external static GPUFlagsConstant get GREEN;
  external static GPUFlagsConstant get BLUE;
  external static GPUFlagsConstant get ALPHA;
  external static GPUFlagsConstant get ALL;
}

@JS()
@staticInterop
@anonymous
class GPUBlendComponent {
  external factory GPUBlendComponent({
    GPUBlendOperation operation,
    GPUBlendFactor srcFactor,
    GPUBlendFactor dstFactor,
  });
}

extension GPUBlendComponentExtension on GPUBlendComponent {
  external set operation(GPUBlendOperation value);
  external GPUBlendOperation get operation;
  external set srcFactor(GPUBlendFactor value);
  external GPUBlendFactor get srcFactor;
  external set dstFactor(GPUBlendFactor value);
  external GPUBlendFactor get dstFactor;
}

@JS()
@staticInterop
@anonymous
class GPUDepthStencilState {
  external factory GPUDepthStencilState({
    required GPUTextureFormat format,
    required bool depthWriteEnabled,
    required GPUCompareFunction depthCompare,
    GPUStencilFaceState stencilFront,
    GPUStencilFaceState stencilBack,
    GPUStencilValue stencilReadMask,
    GPUStencilValue stencilWriteMask,
    GPUDepthBias depthBias,
    num depthBiasSlopeScale,
    num depthBiasClamp,
  });
}

extension GPUDepthStencilStateExtension on GPUDepthStencilState {
  external set format(GPUTextureFormat value);
  external GPUTextureFormat get format;
  external set depthWriteEnabled(bool value);
  external bool get depthWriteEnabled;
  external set depthCompare(GPUCompareFunction value);
  external GPUCompareFunction get depthCompare;
  external set stencilFront(GPUStencilFaceState value);
  external GPUStencilFaceState get stencilFront;
  external set stencilBack(GPUStencilFaceState value);
  external GPUStencilFaceState get stencilBack;
  external set stencilReadMask(GPUStencilValue value);
  external GPUStencilValue get stencilReadMask;
  external set stencilWriteMask(GPUStencilValue value);
  external GPUStencilValue get stencilWriteMask;
  external set depthBias(GPUDepthBias value);
  external GPUDepthBias get depthBias;
  external set depthBiasSlopeScale(num value);
  external num get depthBiasSlopeScale;
  external set depthBiasClamp(num value);
  external num get depthBiasClamp;
}

@JS()
@staticInterop
@anonymous
class GPUStencilFaceState {
  external factory GPUStencilFaceState({
    GPUCompareFunction compare,
    GPUStencilOperation failOp,
    GPUStencilOperation depthFailOp,
    GPUStencilOperation passOp,
  });
}

extension GPUStencilFaceStateExtension on GPUStencilFaceState {
  external set compare(GPUCompareFunction value);
  external GPUCompareFunction get compare;
  external set failOp(GPUStencilOperation value);
  external GPUStencilOperation get failOp;
  external set depthFailOp(GPUStencilOperation value);
  external GPUStencilOperation get depthFailOp;
  external set passOp(GPUStencilOperation value);
  external GPUStencilOperation get passOp;
}

@JS()
@staticInterop
@anonymous
class GPUVertexState implements GPUProgrammableStage {
  external factory GPUVertexState({JSArray buffers});
}

extension GPUVertexStateExtension on GPUVertexState {
  external set buffers(JSArray value);
  external JSArray get buffers;
}

@JS()
@staticInterop
@anonymous
class GPUVertexBufferLayout {
  external factory GPUVertexBufferLayout({
    required GPUSize64 arrayStride,
    GPUVertexStepMode stepMode,
    required JSArray attributes,
  });
}

extension GPUVertexBufferLayoutExtension on GPUVertexBufferLayout {
  external set arrayStride(GPUSize64 value);
  external GPUSize64 get arrayStride;
  external set stepMode(GPUVertexStepMode value);
  external GPUVertexStepMode get stepMode;
  external set attributes(JSArray value);
  external JSArray get attributes;
}

@JS()
@staticInterop
@anonymous
class GPUVertexAttribute {
  external factory GPUVertexAttribute({
    required GPUVertexFormat format,
    required GPUSize64 offset,
    required GPUIndex32 shaderLocation,
  });
}

extension GPUVertexAttributeExtension on GPUVertexAttribute {
  external set format(GPUVertexFormat value);
  external GPUVertexFormat get format;
  external set offset(GPUSize64 value);
  external GPUSize64 get offset;
  external set shaderLocation(GPUIndex32 value);
  external GPUIndex32 get shaderLocation;
}

@JS()
@staticInterop
@anonymous
class GPUImageDataLayout {
  external factory GPUImageDataLayout({
    GPUSize64 offset,
    GPUSize32 bytesPerRow,
    GPUSize32 rowsPerImage,
  });
}

extension GPUImageDataLayoutExtension on GPUImageDataLayout {
  external set offset(GPUSize64 value);
  external GPUSize64 get offset;
  external set bytesPerRow(GPUSize32 value);
  external GPUSize32 get bytesPerRow;
  external set rowsPerImage(GPUSize32 value);
  external GPUSize32 get rowsPerImage;
}

@JS()
@staticInterop
@anonymous
class GPUImageCopyBuffer implements GPUImageDataLayout {
  external factory GPUImageCopyBuffer({required GPUBuffer buffer});
}

extension GPUImageCopyBufferExtension on GPUImageCopyBuffer {
  external set buffer(GPUBuffer value);
  external GPUBuffer get buffer;
}

@JS()
@staticInterop
@anonymous
class GPUImageCopyTexture {
  external factory GPUImageCopyTexture({
    required GPUTexture texture,
    GPUIntegerCoordinate mipLevel,
    GPUOrigin3D origin,
    GPUTextureAspect aspect,
  });
}

extension GPUImageCopyTextureExtension on GPUImageCopyTexture {
  external set texture(GPUTexture value);
  external GPUTexture get texture;
  external set mipLevel(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get mipLevel;
  external set origin(GPUOrigin3D value);
  external GPUOrigin3D get origin;
  external set aspect(GPUTextureAspect value);
  external GPUTextureAspect get aspect;
}

@JS()
@staticInterop
@anonymous
class GPUImageCopyTextureTagged implements GPUImageCopyTexture {
  external factory GPUImageCopyTextureTagged({
    PredefinedColorSpace colorSpace,
    bool premultipliedAlpha,
  });
}

extension GPUImageCopyTextureTaggedExtension on GPUImageCopyTextureTagged {
  external set colorSpace(PredefinedColorSpace value);
  external PredefinedColorSpace get colorSpace;
  external set premultipliedAlpha(bool value);
  external bool get premultipliedAlpha;
}

@JS()
@staticInterop
@anonymous
class GPUImageCopyExternalImage {
  external factory GPUImageCopyExternalImage({
    required GPUImageCopyExternalImageSource source,
    GPUOrigin2D origin,
    bool flipY,
  });
}

extension GPUImageCopyExternalImageExtension on GPUImageCopyExternalImage {
  external set source(GPUImageCopyExternalImageSource value);
  external GPUImageCopyExternalImageSource get source;
  external set origin(GPUOrigin2D value);
  external GPUOrigin2D get origin;
  external set flipY(bool value);
  external bool get flipY;
}

@JS('GPUCommandBuffer')
@staticInterop
class GPUCommandBuffer {}

extension GPUCommandBufferExtension on GPUCommandBuffer {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUCommandBufferDescriptor implements GPUObjectDescriptorBase {
  external factory GPUCommandBufferDescriptor();
}

@JS('GPUCommandEncoder')
@staticInterop
class GPUCommandEncoder {}

extension GPUCommandEncoderExtension on GPUCommandEncoder {
  external GPURenderPassEncoder beginRenderPass(
      GPURenderPassDescriptor descriptor);
  external GPUComputePassEncoder beginComputePass(
      [GPUComputePassDescriptor descriptor]);
  external void copyBufferToBuffer(
    GPUBuffer source,
    GPUSize64 sourceOffset,
    GPUBuffer destination,
    GPUSize64 destinationOffset,
    GPUSize64 size,
  );
  external void copyBufferToTexture(
    GPUImageCopyBuffer source,
    GPUImageCopyTexture destination,
    GPUExtent3D copySize,
  );
  external void copyTextureToBuffer(
    GPUImageCopyTexture source,
    GPUImageCopyBuffer destination,
    GPUExtent3D copySize,
  );
  external void copyTextureToTexture(
    GPUImageCopyTexture source,
    GPUImageCopyTexture destination,
    GPUExtent3D copySize,
  );
  external void clearBuffer(
    GPUBuffer buffer, [
    GPUSize64 offset,
    GPUSize64 size,
  ]);
  external void writeTimestamp(
    GPUQuerySet querySet,
    GPUSize32 queryIndex,
  );
  external void resolveQuerySet(
    GPUQuerySet querySet,
    GPUSize32 firstQuery,
    GPUSize32 queryCount,
    GPUBuffer destination,
    GPUSize64 destinationOffset,
  );
  external GPUCommandBuffer finish([GPUCommandBufferDescriptor descriptor]);
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external void insertDebugMarker(String markerLabel);
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUCommandEncoderDescriptor implements GPUObjectDescriptorBase {
  external factory GPUCommandEncoderDescriptor();
}

@JS('GPUComputePassEncoder')
@staticInterop
class GPUComputePassEncoder {}

extension GPUComputePassEncoderExtension on GPUComputePassEncoder {
  external void setPipeline(GPUComputePipeline pipeline);
  external void dispatchWorkgroups(
    GPUSize32 workgroupCountX, [
    GPUSize32 workgroupCountY,
    GPUSize32 workgroupCountZ,
  ]);
  external void dispatchWorkgroupsIndirect(
    GPUBuffer indirectBuffer,
    GPUSize64 indirectOffset,
  );
  external void end();
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external void insertDebugMarker(String markerLabel);
  external void setBindGroup(
    GPUIndex32 index,
    GPUBindGroup? bindGroup, [
    JSObject dynamicOffsetsOrDynamicOffsetsData,
    GPUSize64 dynamicOffsetsDataStart,
    GPUSize32 dynamicOffsetsDataLength,
  ]);
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUComputePassTimestampWrites {
  external factory GPUComputePassTimestampWrites({
    required GPUQuerySet querySet,
    GPUSize32 beginningOfPassWriteIndex,
    GPUSize32 endOfPassWriteIndex,
  });
}

extension GPUComputePassTimestampWritesExtension
    on GPUComputePassTimestampWrites {
  external set querySet(GPUQuerySet value);
  external GPUQuerySet get querySet;
  external set beginningOfPassWriteIndex(GPUSize32 value);
  external GPUSize32 get beginningOfPassWriteIndex;
  external set endOfPassWriteIndex(GPUSize32 value);
  external GPUSize32 get endOfPassWriteIndex;
}

@JS()
@staticInterop
@anonymous
class GPUComputePassDescriptor implements GPUObjectDescriptorBase {
  external factory GPUComputePassDescriptor(
      {GPUComputePassTimestampWrites timestampWrites});
}

extension GPUComputePassDescriptorExtension on GPUComputePassDescriptor {
  external set timestampWrites(GPUComputePassTimestampWrites value);
  external GPUComputePassTimestampWrites get timestampWrites;
}

@JS('GPURenderPassEncoder')
@staticInterop
class GPURenderPassEncoder {}

extension GPURenderPassEncoderExtension on GPURenderPassEncoder {
  external void setViewport(
    num x,
    num y,
    num width,
    num height,
    num minDepth,
    num maxDepth,
  );
  external void setScissorRect(
    GPUIntegerCoordinate x,
    GPUIntegerCoordinate y,
    GPUIntegerCoordinate width,
    GPUIntegerCoordinate height,
  );
  external void setBlendConstant(GPUColor color);
  external void setStencilReference(GPUStencilValue reference);
  external void beginOcclusionQuery(GPUSize32 queryIndex);
  external void endOcclusionQuery();
  external void executeBundles(JSArray bundles);
  external void end();
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external void insertDebugMarker(String markerLabel);
  external void setBindGroup(
    GPUIndex32 index,
    GPUBindGroup? bindGroup, [
    JSObject dynamicOffsetsOrDynamicOffsetsData,
    GPUSize64 dynamicOffsetsDataStart,
    GPUSize32 dynamicOffsetsDataLength,
  ]);
  external void setPipeline(GPURenderPipeline pipeline);
  external void setIndexBuffer(
    GPUBuffer buffer,
    GPUIndexFormat indexFormat, [
    GPUSize64 offset,
    GPUSize64 size,
  ]);
  external void setVertexBuffer(
    GPUIndex32 slot,
    GPUBuffer? buffer, [
    GPUSize64 offset,
    GPUSize64 size,
  ]);
  external void draw(
    GPUSize32 vertexCount, [
    GPUSize32 instanceCount,
    GPUSize32 firstVertex,
    GPUSize32 firstInstance,
  ]);
  external void drawIndexed(
    GPUSize32 indexCount, [
    GPUSize32 instanceCount,
    GPUSize32 firstIndex,
    GPUSignedOffset32 baseVertex,
    GPUSize32 firstInstance,
  ]);
  external void drawIndirect(
    GPUBuffer indirectBuffer,
    GPUSize64 indirectOffset,
  );
  external void drawIndexedIndirect(
    GPUBuffer indirectBuffer,
    GPUSize64 indirectOffset,
  );
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPURenderPassTimestampWrites {
  external factory GPURenderPassTimestampWrites({
    required GPUQuerySet querySet,
    GPUSize32 beginningOfPassWriteIndex,
    GPUSize32 endOfPassWriteIndex,
  });
}

extension GPURenderPassTimestampWritesExtension
    on GPURenderPassTimestampWrites {
  external set querySet(GPUQuerySet value);
  external GPUQuerySet get querySet;
  external set beginningOfPassWriteIndex(GPUSize32 value);
  external GPUSize32 get beginningOfPassWriteIndex;
  external set endOfPassWriteIndex(GPUSize32 value);
  external GPUSize32 get endOfPassWriteIndex;
}

@JS()
@staticInterop
@anonymous
class GPURenderPassDescriptor implements GPUObjectDescriptorBase {
  external factory GPURenderPassDescriptor({
    required JSArray colorAttachments,
    GPURenderPassDepthStencilAttachment depthStencilAttachment,
    GPUQuerySet occlusionQuerySet,
    GPURenderPassTimestampWrites timestampWrites,
    GPUSize64 maxDrawCount,
  });
}

extension GPURenderPassDescriptorExtension on GPURenderPassDescriptor {
  external set colorAttachments(JSArray value);
  external JSArray get colorAttachments;
  external set depthStencilAttachment(
      GPURenderPassDepthStencilAttachment value);
  external GPURenderPassDepthStencilAttachment get depthStencilAttachment;
  external set occlusionQuerySet(GPUQuerySet value);
  external GPUQuerySet get occlusionQuerySet;
  external set timestampWrites(GPURenderPassTimestampWrites value);
  external GPURenderPassTimestampWrites get timestampWrites;
  external set maxDrawCount(GPUSize64 value);
  external GPUSize64 get maxDrawCount;
}

@JS()
@staticInterop
@anonymous
class GPURenderPassColorAttachment {
  external factory GPURenderPassColorAttachment({
    required GPUTextureView view,
    GPUTextureView resolveTarget,
    GPUColor clearValue,
    required GPULoadOp loadOp,
    required GPUStoreOp storeOp,
  });
}

extension GPURenderPassColorAttachmentExtension
    on GPURenderPassColorAttachment {
  external set view(GPUTextureView value);
  external GPUTextureView get view;
  external set resolveTarget(GPUTextureView value);
  external GPUTextureView get resolveTarget;
  external set clearValue(GPUColor value);
  external GPUColor get clearValue;
  external set loadOp(GPULoadOp value);
  external GPULoadOp get loadOp;
  external set storeOp(GPUStoreOp value);
  external GPUStoreOp get storeOp;
}

@JS()
@staticInterop
@anonymous
class GPURenderPassDepthStencilAttachment {
  external factory GPURenderPassDepthStencilAttachment({
    required GPUTextureView view,
    num depthClearValue,
    GPULoadOp depthLoadOp,
    GPUStoreOp depthStoreOp,
    bool depthReadOnly,
    GPUStencilValue stencilClearValue,
    GPULoadOp stencilLoadOp,
    GPUStoreOp stencilStoreOp,
    bool stencilReadOnly,
  });
}

extension GPURenderPassDepthStencilAttachmentExtension
    on GPURenderPassDepthStencilAttachment {
  external set view(GPUTextureView value);
  external GPUTextureView get view;
  external set depthClearValue(num value);
  external num get depthClearValue;
  external set depthLoadOp(GPULoadOp value);
  external GPULoadOp get depthLoadOp;
  external set depthStoreOp(GPUStoreOp value);
  external GPUStoreOp get depthStoreOp;
  external set depthReadOnly(bool value);
  external bool get depthReadOnly;
  external set stencilClearValue(GPUStencilValue value);
  external GPUStencilValue get stencilClearValue;
  external set stencilLoadOp(GPULoadOp value);
  external GPULoadOp get stencilLoadOp;
  external set stencilStoreOp(GPUStoreOp value);
  external GPUStoreOp get stencilStoreOp;
  external set stencilReadOnly(bool value);
  external bool get stencilReadOnly;
}

@JS()
@staticInterop
@anonymous
class GPURenderPassLayout implements GPUObjectDescriptorBase {
  external factory GPURenderPassLayout({
    required JSArray colorFormats,
    GPUTextureFormat depthStencilFormat,
    GPUSize32 sampleCount,
  });
}

extension GPURenderPassLayoutExtension on GPURenderPassLayout {
  external set colorFormats(JSArray value);
  external JSArray get colorFormats;
  external set depthStencilFormat(GPUTextureFormat value);
  external GPUTextureFormat get depthStencilFormat;
  external set sampleCount(GPUSize32 value);
  external GPUSize32 get sampleCount;
}

@JS('GPURenderBundle')
@staticInterop
class GPURenderBundle {}

extension GPURenderBundleExtension on GPURenderBundle {
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPURenderBundleDescriptor implements GPUObjectDescriptorBase {
  external factory GPURenderBundleDescriptor();
}

@JS('GPURenderBundleEncoder')
@staticInterop
class GPURenderBundleEncoder {}

extension GPURenderBundleEncoderExtension on GPURenderBundleEncoder {
  external GPURenderBundle finish([GPURenderBundleDescriptor descriptor]);
  external void pushDebugGroup(String groupLabel);
  external void popDebugGroup();
  external void insertDebugMarker(String markerLabel);
  external void setBindGroup(
    GPUIndex32 index,
    GPUBindGroup? bindGroup, [
    JSObject dynamicOffsetsOrDynamicOffsetsData,
    GPUSize64 dynamicOffsetsDataStart,
    GPUSize32 dynamicOffsetsDataLength,
  ]);
  external void setPipeline(GPURenderPipeline pipeline);
  external void setIndexBuffer(
    GPUBuffer buffer,
    GPUIndexFormat indexFormat, [
    GPUSize64 offset,
    GPUSize64 size,
  ]);
  external void setVertexBuffer(
    GPUIndex32 slot,
    GPUBuffer? buffer, [
    GPUSize64 offset,
    GPUSize64 size,
  ]);
  external void draw(
    GPUSize32 vertexCount, [
    GPUSize32 instanceCount,
    GPUSize32 firstVertex,
    GPUSize32 firstInstance,
  ]);
  external void drawIndexed(
    GPUSize32 indexCount, [
    GPUSize32 instanceCount,
    GPUSize32 firstIndex,
    GPUSignedOffset32 baseVertex,
    GPUSize32 firstInstance,
  ]);
  external void drawIndirect(
    GPUBuffer indirectBuffer,
    GPUSize64 indirectOffset,
  );
  external void drawIndexedIndirect(
    GPUBuffer indirectBuffer,
    GPUSize64 indirectOffset,
  );
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPURenderBundleEncoderDescriptor implements GPURenderPassLayout {
  external factory GPURenderBundleEncoderDescriptor({
    bool depthReadOnly,
    bool stencilReadOnly,
  });
}

extension GPURenderBundleEncoderDescriptorExtension
    on GPURenderBundleEncoderDescriptor {
  external set depthReadOnly(bool value);
  external bool get depthReadOnly;
  external set stencilReadOnly(bool value);
  external bool get stencilReadOnly;
}

@JS()
@staticInterop
@anonymous
class GPUQueueDescriptor implements GPUObjectDescriptorBase {
  external factory GPUQueueDescriptor();
}

@JS('GPUQueue')
@staticInterop
class GPUQueue {}

extension GPUQueueExtension on GPUQueue {
  external void submit(JSArray commandBuffers);
  external JSPromise onSubmittedWorkDone();
  external void writeBuffer(
    GPUBuffer buffer,
    GPUSize64 bufferOffset,
    AllowSharedBufferSource data, [
    GPUSize64 dataOffset,
    GPUSize64 size,
  ]);
  external void writeTexture(
    GPUImageCopyTexture destination,
    AllowSharedBufferSource data,
    GPUImageDataLayout dataLayout,
    GPUExtent3D size,
  );
  external void copyExternalImageToTexture(
    GPUImageCopyExternalImage source,
    GPUImageCopyTextureTagged destination,
    GPUExtent3D copySize,
  );
  external set label(String value);
  external String get label;
}

@JS('GPUQuerySet')
@staticInterop
class GPUQuerySet {}

extension GPUQuerySetExtension on GPUQuerySet {
  external void destroy();
  external GPUQueryType get type;
  external GPUSize32Out get count;
  external set label(String value);
  external String get label;
}

@JS()
@staticInterop
@anonymous
class GPUQuerySetDescriptor implements GPUObjectDescriptorBase {
  external factory GPUQuerySetDescriptor({
    required GPUQueryType type,
    required GPUSize32 count,
  });
}

extension GPUQuerySetDescriptorExtension on GPUQuerySetDescriptor {
  external set type(GPUQueryType value);
  external GPUQueryType get type;
  external set count(GPUSize32 value);
  external GPUSize32 get count;
}

@JS('GPUCanvasContext')
@staticInterop
class GPUCanvasContext {}

extension GPUCanvasContextExtension on GPUCanvasContext {
  external void configure(GPUCanvasConfiguration configuration);
  external void unconfigure();
  external GPUTexture getCurrentTexture();
  external JSObject get canvas;
}

@JS()
@staticInterop
@anonymous
class GPUCanvasConfiguration {
  external factory GPUCanvasConfiguration({
    required GPUDevice device,
    required GPUTextureFormat format,
    GPUTextureUsageFlags usage,
    JSArray viewFormats,
    PredefinedColorSpace colorSpace,
    GPUCanvasAlphaMode alphaMode,
  });
}

extension GPUCanvasConfigurationExtension on GPUCanvasConfiguration {
  external set device(GPUDevice value);
  external GPUDevice get device;
  external set format(GPUTextureFormat value);
  external GPUTextureFormat get format;
  external set usage(GPUTextureUsageFlags value);
  external GPUTextureUsageFlags get usage;
  external set viewFormats(JSArray value);
  external JSArray get viewFormats;
  external set colorSpace(PredefinedColorSpace value);
  external PredefinedColorSpace get colorSpace;
  external set alphaMode(GPUCanvasAlphaMode value);
  external GPUCanvasAlphaMode get alphaMode;
}

@JS('GPUDeviceLostInfo')
@staticInterop
class GPUDeviceLostInfo {}

extension GPUDeviceLostInfoExtension on GPUDeviceLostInfo {
  external GPUDeviceLostReason get reason;
  external String get message;
}

@JS('GPUError')
@staticInterop
class GPUError {}

extension GPUErrorExtension on GPUError {
  external String get message;
}

@JS('GPUValidationError')
@staticInterop
class GPUValidationError implements GPUError {
  external factory GPUValidationError(String message);
}

@JS('GPUOutOfMemoryError')
@staticInterop
class GPUOutOfMemoryError implements GPUError {
  external factory GPUOutOfMemoryError(String message);
}

@JS('GPUInternalError')
@staticInterop
class GPUInternalError implements GPUError {
  external factory GPUInternalError(String message);
}

@JS('GPUUncapturedErrorEvent')
@staticInterop
class GPUUncapturedErrorEvent implements Event {
  external factory GPUUncapturedErrorEvent(
    String type,
    GPUUncapturedErrorEventInit gpuUncapturedErrorEventInitDict,
  );
}

extension GPUUncapturedErrorEventExtension on GPUUncapturedErrorEvent {
  external GPUError get error;
}

@JS()
@staticInterop
@anonymous
class GPUUncapturedErrorEventInit implements EventInit {
  external factory GPUUncapturedErrorEventInit({required GPUError error});
}

extension GPUUncapturedErrorEventInitExtension on GPUUncapturedErrorEventInit {
  external set error(GPUError value);
  external GPUError get error;
}

@JS()
@staticInterop
@anonymous
class GPUColorDict {
  external factory GPUColorDict({
    required num r,
    required num g,
    required num b,
    required num a,
  });
}

extension GPUColorDictExtension on GPUColorDict {
  external set r(num value);
  external num get r;
  external set g(num value);
  external num get g;
  external set b(num value);
  external num get b;
  external set a(num value);
  external num get a;
}

@JS()
@staticInterop
@anonymous
class GPUOrigin2DDict {
  external factory GPUOrigin2DDict({
    GPUIntegerCoordinate x,
    GPUIntegerCoordinate y,
  });
}

extension GPUOrigin2DDictExtension on GPUOrigin2DDict {
  external set x(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get x;
  external set y(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get y;
}

@JS()
@staticInterop
@anonymous
class GPUOrigin3DDict {
  external factory GPUOrigin3DDict({
    GPUIntegerCoordinate x,
    GPUIntegerCoordinate y,
    GPUIntegerCoordinate z,
  });
}

extension GPUOrigin3DDictExtension on GPUOrigin3DDict {
  external set x(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get x;
  external set y(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get y;
  external set z(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get z;
}

@JS()
@staticInterop
@anonymous
class GPUExtent3DDict {
  external factory GPUExtent3DDict({
    required GPUIntegerCoordinate width,
    GPUIntegerCoordinate height,
    GPUIntegerCoordinate depthOrArrayLayers,
  });
}

extension GPUExtent3DDictExtension on GPUExtent3DDict {
  external set width(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get width;
  external set height(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get height;
  external set depthOrArrayLayers(GPUIntegerCoordinate value);
  external GPUIntegerCoordinate get depthOrArrayLayers;
}
