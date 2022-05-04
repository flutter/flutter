// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/pipeline_library_mtl.h"

#include "impeller/base/promise.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_mtl.h"
#include "impeller/renderer/backend/metal/shader_function_mtl.h"
#include "impeller/renderer/backend/metal/vertex_descriptor_mtl.h"

namespace impeller {

PipelineLibraryMTL::PipelineLibraryMTL(id<MTLDevice> device)
    : device_(device) {}

PipelineLibraryMTL::~PipelineLibraryMTL() = default;

static MTLRenderPipelineDescriptor* GetMTLRenderPipelineDescriptor(
    const PipelineDescriptor& desc) {
  auto descriptor = [[MTLRenderPipelineDescriptor alloc] init];
  descriptor.label = @(desc.GetLabel().c_str());
  descriptor.sampleCount = static_cast<NSUInteger>(desc.GetSampleCount());

  for (const auto& entry : desc.GetStageEntrypoints()) {
    if (entry.first == ShaderStage::kVertex) {
      descriptor.vertexFunction =
          ShaderFunctionMTL::Cast(*entry.second).GetMTLFunction();
    }
    if (entry.first == ShaderStage::kFragment) {
      descriptor.fragmentFunction =
          ShaderFunctionMTL::Cast(*entry.second).GetMTLFunction();
    }
  }

  if (const auto& vertex_descriptor = desc.GetVertexDescriptor()) {
    VertexDescriptorMTL vertex_descriptor_mtl;
    if (vertex_descriptor_mtl.SetStageInputs(
            vertex_descriptor->GetStageInputs())) {
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

  return descriptor;
}

// TODO(csg): Make PipelineDescriptor a struct and move this to formats_mtl.
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

PipelineFuture PipelineLibraryMTL::GetRenderPipeline(
    PipelineDescriptor descriptor) {
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    return found->second;
  }

  if (device_ == nil) {
    return RealizedFuture<std::shared_ptr<Pipeline>>(nullptr);
  }

  auto promise = std::make_shared<std::promise<std::shared_ptr<Pipeline>>>();
  auto future = PipelineFuture{promise->get_future()};
  pipelines_[descriptor] = future;
  auto weak_this = weak_from_this();

  auto completion_handler =
      ^(id<MTLRenderPipelineState> _Nullable render_pipeline_state,
        NSError* _Nullable error) {
        if (error != nil) {
          VALIDATION_LOG << "Could not create render pipeline: "
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

        auto new_pipeline = std::shared_ptr<PipelineMTL>(new PipelineMTL(
            weak_this,
            descriptor,                                        //
            render_pipeline_state,                             //
            CreateDepthStencilDescriptor(descriptor, device_)  //
            ));
        promise->set_value(new_pipeline);
      };
  [device_ newRenderPipelineStateWithDescriptor:GetMTLRenderPipelineDescriptor(
                                                    descriptor)
                              completionHandler:completion_handler];
  return future;
}

}  // namespace impeller
