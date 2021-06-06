// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <ModelIO/ModelIO.h>
#import <simd/simd.h>
#import "ShaderTypes.h"

#include "assets_location.h"
#include "flutter/fml/logging.h"
#include "impeller/compositor/formats_metal.h"
#include "impeller/compositor/surface.h"
#include "impeller/entity/entity_renderer.h"
#include "impeller/primitives/box_primitive.h"
#include "impeller_renderer.h"
#include "shaders_location.h"

static const NSUInteger kMaxBuffersInFlight = 3;

static const size_t kAlignedUniformsSize = (sizeof(Uniforms) & ~0xFF) + 0x100;

@implementation ImpellerRenderer {
  dispatch_semaphore_t _inFlightSemaphore;
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;

  id<MTLBuffer> _dynamicUniformBuffer;
  id<MTLRenderPipelineState> _pipelineState;
  id<MTLDepthStencilState> _depthState;
  id<MTLTexture> _colorMap;
  MTLVertexDescriptor* _mtlVertexDescriptor;

  uint32_t _uniformBufferOffset;

  uint8_t _uniformBufferIndex;

  void* _uniformBufferAddress;

  matrix_float4x4 _projectionMatrix;

  float _rotation;

  MTKMesh* _mesh;
  std::unique_ptr<impeller::Renderer> renderer_;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView*)view {
  self = [super init];
  if (self) {
    _device = view.device;
    _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
    [self _loadMetalWithView:view];
    [self _loadAssets];
  }

  renderer_ = std::make_unique<impeller::EntityRenderer>(
      impeller::ImpellerShadersDirectory());
  FML_CHECK(renderer_->IsValid()) << "Impeller Renderer is not valid.";
  return self;
}

- (void)_loadMetalWithView:(nonnull MTKView*)view {
  /// Load Metal state objects and initialize renderer dependent view properties

  view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
  view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
  view.sampleCount = 1;

  _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

  _mtlVertexDescriptor.attributes[VertexAttributePosition].format =
      MTLVertexFormatFloat3;
  _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
  _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex =
      BufferIndexMeshPositions;

  _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format =
      MTLVertexFormatFloat2;
  _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
  _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex =
      BufferIndexMeshGenerics;

  _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = 12;
  _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
  _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction =
      MTLVertexStepFunctionPerVertex;

  _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stride = 8;
  _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = 1;
  _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepFunction =
      MTLVertexStepFunctionPerVertex;

  auto shader_library_path =
      impeller::ImpellerShadersLocation("impeller_host.metallib");

  FML_CHECK(shader_library_path.has_value());

  NSError* shader_library_error = nil;

  id<MTLLibrary> defaultLibrary =
      [_device newLibraryWithFile:@(shader_library_path.value().c_str())
                            error:&shader_library_error];

  id<MTLFunction> vertexFunction =
      [defaultLibrary newFunctionWithName:@"vertexShader"];

  id<MTLFunction> fragmentFunction =
      [defaultLibrary newFunctionWithName:@"fragmentShader"];

  MTLRenderPipelineDescriptor* pipelineStateDescriptor =
      [[MTLRenderPipelineDescriptor alloc] init];
  pipelineStateDescriptor.label = @"MyPipeline";
  pipelineStateDescriptor.sampleCount = view.sampleCount;
  pipelineStateDescriptor.vertexFunction = vertexFunction;
  pipelineStateDescriptor.fragmentFunction = fragmentFunction;
  pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
  pipelineStateDescriptor.colorAttachments[0].pixelFormat =
      view.colorPixelFormat;
  pipelineStateDescriptor.depthAttachmentPixelFormat =
      view.depthStencilPixelFormat;
  pipelineStateDescriptor.stencilAttachmentPixelFormat =
      view.depthStencilPixelFormat;

  NSError* error = NULL;
  _pipelineState =
      [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                              error:&error];
  if (!_pipelineState) {
    NSLog(@"Failed to created pipeline state, error %@", error);
  }

  MTLDepthStencilDescriptor* depthStateDesc =
      [[MTLDepthStencilDescriptor alloc] init];
  depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
  depthStateDesc.depthWriteEnabled = YES;
  _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

  NSUInteger uniformBufferSize = kAlignedUniformsSize * kMaxBuffersInFlight;

  _dynamicUniformBuffer =
      [_device newBufferWithLength:uniformBufferSize
                           options:MTLResourceStorageModeShared];

  _dynamicUniformBuffer.label = @"UniformBuffer";

  _commandQueue = [_device newCommandQueue];
}

- (void)_loadAssets {
  /// Load assets into metal objects

  NSError* error;

  MTKMeshBufferAllocator* metalAllocator =
      [[MTKMeshBufferAllocator alloc] initWithDevice:_device];

  MDLMesh* mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3){4, 4, 4}
                                          segments:(vector_uint3){2, 2, 2}
                                      geometryType:MDLGeometryTypeTriangles
                                     inwardNormals:NO
                                         allocator:metalAllocator];

  MDLVertexDescriptor* mdlVertexDescriptor =
      MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);

  mdlVertexDescriptor.attributes[VertexAttributePosition].name =
      MDLVertexAttributePosition;
  mdlVertexDescriptor.attributes[VertexAttributeTexcoord].name =
      MDLVertexAttributeTextureCoordinate;

  mdlMesh.vertexDescriptor = mdlVertexDescriptor;

  _mesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:_device error:&error];

  if (!_mesh || error) {
    NSLog(@"Error creating MetalKit mesh %@", error.localizedDescription);
  }

  MTKTextureLoader* textureLoader =
      [[MTKTextureLoader alloc] initWithDevice:_device];

  NSDictionary* textureLoaderOptions = @{
    MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
    MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
  };

  auto color_map_data = [NSData
      dataWithContentsOfFile:@(impeller::GetAssetLocation("ColorMap.png")
                                   .c_str())];

  _colorMap = [textureLoader newTextureWithData:color_map_data
                                        options:textureLoaderOptions
                                          error:&error];

  if (!_colorMap || error) {
    NSLog(@"Error creating texture %@", error.localizedDescription);
  }
}

- (void)_updateDynamicBufferState {
  /// Update the state of our uniform buffers before rendering

  _uniformBufferIndex = (_uniformBufferIndex + 1) % kMaxBuffersInFlight;

  _uniformBufferOffset = kAlignedUniformsSize * _uniformBufferIndex;

  _uniformBufferAddress =
      ((uint8_t*)_dynamicUniformBuffer.contents) + _uniformBufferOffset;
}

- (void)_updateGameState {
  /// Update any game state before encoding renderint commands to our drawable

  Uniforms* uniforms = (Uniforms*)_uniformBufferAddress;

  uniforms->projectionMatrix = _projectionMatrix;

  vector_float3 rotationAxis = {1, 1, 0};
  matrix_float4x4 modelMatrix = matrix4x4_rotation(_rotation, rotationAxis);
  matrix_float4x4 viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0);

  uniforms->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);

  _rotation += .01;
}

- (void)drawInMTKView:(nonnull MTKView*)view {
  impeller::Surface surface(
      impeller::FromMTLRenderPassDescriptor(view.currentRenderPassDescriptor));
  if (!renderer_->Render(surface)) {
    FML_LOG(ERROR) << "Could not render.";
  }
  /// Per frame updates here
  dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  commandBuffer.label = @"MyCommand";

  __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    dispatch_semaphore_signal(block_sema);
  }];

  [self _updateDynamicBufferState];

  [self _updateGameState];

  /// Delay getting the currentRenderPassDescriptor until we absolutely need it
  /// to avoid holding onto the drawable and blocking the display pipeline any
  /// longer than necessary
  MTLRenderPassDescriptor* renderPassDescriptor =
      view.currentRenderPassDescriptor;

  if (renderPassDescriptor != nil) {
    /// Final pass rendering code here

    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";

    [renderEncoder pushDebugGroup:@"DrawBox"];

    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder setDepthStencilState:_depthState];

    [renderEncoder setVertexBuffer:_dynamicUniformBuffer
                            offset:_uniformBufferOffset
                           atIndex:BufferIndexUniforms];

    [renderEncoder setFragmentBuffer:_dynamicUniformBuffer
                              offset:_uniformBufferOffset
                             atIndex:BufferIndexUniforms];

    for (NSUInteger bufferIndex = 0; bufferIndex < _mesh.vertexBuffers.count;
         bufferIndex++) {
      MTKMeshBuffer* vertexBuffer = _mesh.vertexBuffers[bufferIndex];
      if ((NSNull*)vertexBuffer != [NSNull null]) {
        [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                offset:vertexBuffer.offset
                               atIndex:bufferIndex];
      }
    }

    [renderEncoder setFragmentTexture:_colorMap atIndex:TextureIndexColor];

    for (MTKSubmesh* submesh in _mesh.submeshes) {
      [renderEncoder drawIndexedPrimitives:submesh.primitiveType
                                indexCount:submesh.indexCount
                                 indexType:submesh.indexType
                               indexBuffer:submesh.indexBuffer.buffer
                         indexBufferOffset:submesh.indexBuffer.offset];
    }

    [renderEncoder popDebugGroup];

    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:view.currentDrawable];
  }

  [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size {
  float aspect = size.width / (float)size.height;
  _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f),
                                                    aspect, 0.1f, 100.0f);
}

#pragma mark Matrix Math Utilities

// NOLINTNEXTLINE
matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz) {
  return (matrix_float4x4){
      {{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {tx, ty, tz, 1}}};
}

// NOLINTNEXTLINE
static matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis) {
  axis = vector_normalize(axis);
  float ct = cosf(radians);
  float st = sinf(radians);
  float ci = 1 - ct;
  float x = axis.x, y = axis.y, z = axis.z;

  return (matrix_float4x4){
      {{ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0},
       {x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0},
       {x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0},
       {0, 0, 0, 1}}};
}

// NOLINTNEXTLINE
matrix_float4x4 matrix_perspective_right_hand(float fovyRadians,
                                              float aspect,
                                              float nearZ,
                                              float farZ) {
  float ys = 1 / tanf(fovyRadians * 0.5);
  float xs = ys / aspect;
  float zs = farZ / (nearZ - farZ);

  return (matrix_float4x4){
      {{xs, 0, 0, 0}, {0, ys, 0, 0}, {0, 0, zs, -1}, {0, 0, nearZ * zs, 0}}};
}

@end
