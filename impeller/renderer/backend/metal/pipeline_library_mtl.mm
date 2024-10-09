// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/pipeline_library_mtl.h"

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>

#include "flutter/fml/build_config.h"
#include "flutter/fml/container.h"
#include "impeller/base/promise.h"
#include "impeller/renderer/backend/metal/compute_pipeline_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_mtl.h"
#include "impeller/renderer/backend/metal/shader_function_mtl.h"
#include "impeller/renderer/backend/metal/vertex_descriptor_mtl.h"

namespace impeller {

PipelineLibraryMTL::PipelineLibraryMTL(id<MTLDevice> device)
    : device_(device) {}

PipelineLibraryMTL::~PipelineLibraryMTL() = default;

using Callback = std::function<void(MTLRenderPipelineDescriptor*)>;

static void GetMTLRenderPipelineDescriptor(const PipelineDescriptor& desc,
                                           const Callback& callback) {
  auto descriptor = [[MTLRenderPipelineDescriptor alloc] init];
  descriptor.label = @(desc.GetLabel().c_str());
  descriptor.rasterSampleCount = static_cast<NSUInteger>(desc.GetSampleCount());
  bool created_specialized_function = false;

  if (const auto& vertex_descriptor = desc.GetVertexDescriptor()) {
    VertexDescriptorMTL vertex_descriptor_mtl;
    if (vertex_descriptor_mtl.SetStageInputsAndLayout(
            vertex_descriptor->GetStageInputs(),
            vertex_descriptor->GetStageLayouts())) {
      descriptor.vertexDescriptor =
          vertex_descriptor_mtl.GetMTLVertexDescriptor();
    }
  }

  for (const auto& item : desc.GetColorAttachmentDescriptors()) {
    descriptor.colorAttachments[item.first] =
        ToMTLRenderPipelineColorAttachmentDescriptor(item.second);
  }

  descriptor.depthAttachmentPixelFormat =
      ToMTLPixelFormat(desc.GetDepthPixelFormat());
  descriptor.stencilAttachmentPixelFormat =
      ToMTLPixelFormat(desc.GetStencilPixelFormat());

  const auto& constants = desc.GetSpecializationConstants();
  for (const auto& entry : desc.GetStageEntrypoints()) {
    if (entry.first == ShaderStage::kVertex) {
      descriptor.vertexFunction =
          ShaderFunctionMTL::Cast(*entry.second).GetMTLFunction();
    }
    if (entry.first == ShaderStage::kFragment) {
      if (constants.empty()) {
        descriptor.fragmentFunction =
            ShaderFunctionMTL::Cast(*entry.second).GetMTLFunction();
      } else {
        // This code only expects a single specialized function per pipeline.
        FML_CHECK(!created_specialized_function);
        created_specialized_function = true;
        ShaderFunctionMTL::Cast(*entry.second)
            .GetMTLFunctionSpecialized(
                constants, [callback, descriptor](id<MTLFunction> function) {
                  descriptor.fragmentFunction = function;
                  callback(descriptor);
                });
      }
    }
  }

  if (!created_specialized_function) {
    callback(descriptor);
  }
}

static MTLComputePipelineDescriptor* GetMTLComputePipelineDescriptor(
    const ComputePipelineDescriptor& desc) {
  auto descriptor = [[MTLComputePipelineDescriptor alloc] init];
  descriptor.label = @(desc.GetLabel().c_str());
  descriptor.computeFunction =
      ShaderFunctionMTL::Cast(*desc.GetStageEntrypoint()).GetMTLFunction();
  return descriptor;
}

static id<MTLDepthStencilState> CreateDepthStencilDescriptor(
    const PipelineDescriptor& desc,
    id<MTLDevice> device) {
  auto descriptor = ToMTLDepthStencilDescriptor(
      desc.GetDepthStencilAttachmentDescriptor(),  //
      desc.GetFrontStencilAttachmentDescriptor(),  //
      desc.GetBackStencilAttachmentDescriptor()    //
  );
  return [device newDepthStencilStateWithDescriptor:descriptor];
}

// |PipelineLibrary|
bool PipelineLibraryMTL::IsValid() const {
  return device_ != nullptr;
}

// |PipelineLibrary|
PipelineFuture<PipelineDescriptor> PipelineLibraryMTL::GetPipeline(
    PipelineDescriptor descriptor,
    bool async) {
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    return found->second;
  }

  if (!IsValid()) {
    return {
        descriptor,
        RealizedFuture<std::shared_ptr<Pipeline<PipelineDescriptor>>>(nullptr)};
  }

  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<PipelineDescriptor>>>>();
  auto pipeline_future =
      PipelineFuture<PipelineDescriptor>{descriptor, promise->get_future()};
  pipelines_[descriptor] = pipeline_future;
  auto weak_this = weak_from_this();

  auto completion_handler =
      ^(id<MTLRenderPipelineState> _Nullable render_pipeline_state,
        NSError* _Nullable error) {
        if (error != nil) {
          VALIDATION_LOG << "Could not create render pipeline for "
                         << descriptor.GetLabel() << " :"
                         << error.localizedDescription.UTF8String;
          promise->set_value(nullptr);
          return;
        }

        auto strong_this = weak_this.lock();
        if (!strong_this) {
          promise->set_value(nullptr);
          return;
        }

        auto new_pipeline = std::shared_ptr<PipelineMTL>(new PipelineMTL(
            weak_this,
            descriptor,                                        //
            render_pipeline_state,                             //
            CreateDepthStencilDescriptor(descriptor, device_)  //
            ));
        promise->set_value(new_pipeline);
      };
  GetMTLRenderPipelineDescriptor(
      descriptor, [device = device_, completion_handler](
                      MTLRenderPipelineDescriptor* descriptor) {
        [device newRenderPipelineStateWithDescriptor:descriptor
                                   completionHandler:completion_handler];
      });
  return pipeline_future;
}

PipelineFuture<ComputePipelineDescriptor> PipelineLibraryMTL::GetPipeline(
    ComputePipelineDescriptor descriptor,
    bool async) {
  if (auto found = compute_pipelines_.find(descriptor);
      found != compute_pipelines_.end()) {
    return found->second;
  }

  if (!IsValid()) {
    return {
        descriptor,
        RealizedFuture<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>(
            nullptr)};
  }

  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>>();
  auto pipeline_future = PipelineFuture<ComputePipelineDescriptor>{
      descriptor, promise->get_future()};
  compute_pipelines_[descriptor] = pipeline_future;
  auto weak_this = weak_from_this();

  auto completion_handler =
      ^(id<MTLComputePipelineState> _Nullable compute_pipeline_state,
        MTLComputePipelineReflection* _Nullable reflection,
        NSError* _Nullable error) {
        if (error != nil) {
          VALIDATION_LOG << "Could not create compute pipeline: "
                         << error.localizedDescription.UTF8String;
          promise->set_value(nullptr);
          return;
        }

        auto strong_this = weak_this.lock();
        if (!strong_this) {
          VALIDATION_LOG << "Library was collected before a pending pipeline "
                            "creation could finish.";
          promise->set_value(nullptr);
          return;
        }

        auto new_pipeline = std::shared_ptr<ComputePipelineMTL>(
            new ComputePipelineMTL(weak_this,
                                   descriptor,             //
                                   compute_pipeline_state  //
                                   ));
        promise->set_value(new_pipeline);
      };
  [device_
      newComputePipelineStateWithDescriptor:GetMTLComputePipelineDescriptor(
                                                descriptor)
                                    options:MTLPipelineOptionNone
                          completionHandler:completion_handler];
  return pipeline_future;
}

// |PipelineLibrary|
bool PipelineLibraryMTL::HasPipeline(const PipelineDescriptor& descriptor) {
  return pipelines_.find(descriptor) != pipelines_.end();
}

// |PipelineLibrary|
void PipelineLibraryMTL::RemovePipelinesWithEntryPoint(
    std::shared_ptr<const ShaderFunction> function) {
  fml::erase_if(pipelines_, [&](auto item) {
    return item->first.GetEntrypointForStage(function->GetStage())
        ->IsEqual(*function);
  });
}

}  // namespace impeller
