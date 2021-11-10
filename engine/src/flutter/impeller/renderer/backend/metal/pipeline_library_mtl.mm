// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/pipeline_library_mtl.h"

#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_mtl.h"
#include "impeller/renderer/backend/metal/shader_function_mtl.h"
#include "impeller/renderer/backend/metal/vertex_descriptor_mtl.h"

namespace impeller {

PipelineLibraryMTL::PipelineLibraryMTL(id<MTLDevice> device)
    : device_(device) {}

PipelineLibraryMTL::~PipelineLibraryMTL() = default;

// TODO(csg): Make PipelineDescriptor a struct and move this to formats_mtl.
static MTLRenderPipelineDescriptor* GetMTLRenderPipelineDescriptor(
    const PipelineDescriptor& desc) {
  auto descriptor = [[MTLRenderPipelineDescriptor alloc] init];
  descriptor.label = @(desc.GetLabel().c_str());
  descriptor.sampleCount = desc.GetSampleCount();

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

std::future<std::shared_ptr<Pipeline>> PipelineLibraryMTL::GetRenderPipeline(
    PipelineDescriptor descriptor) {
  auto promise = std::make_shared<std::promise<std::shared_ptr<Pipeline>>>();
  auto future = promise->get_future();
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    promise->set_value(nullptr);
    return future;
  }

  // TODO(csg): There is a bug here where multiple calls to GetRenderPipeline
  // will result in multiple render pipelines of the same descriptor being
  // created till the first instance of the creation invokes its completion
  // callback.

  auto thiz = shared_from_this();

  auto completion_handler =
      ^(id<MTLRenderPipelineState> _Nullable render_pipeline_state,
        NSError* _Nullable error) {
        if (error != nil) {
          FML_LOG(ERROR) << "Could not create render pipeline: "
                         << error.localizedDescription.UTF8String;
          promise->set_value(nullptr);
        } else {
          auto new_pipeline = std::shared_ptr<PipelineMTL>(new PipelineMTL(
              descriptor,                                        //
              render_pipeline_state,                             //
              CreateDepthStencilDescriptor(descriptor, device_)  //
              ));
          promise->set_value(new_pipeline);
          this->SavePipeline(descriptor, new_pipeline);
        }
      };
  [device_ newRenderPipelineStateWithDescriptor:GetMTLRenderPipelineDescriptor(
                                                    descriptor)
                              completionHandler:completion_handler];
  return future;
}

void PipelineLibraryMTL::SavePipeline(
    PipelineDescriptor descriptor,
    std::shared_ptr<const Pipeline> pipeline) {
  pipelines_[descriptor] = std::move(pipeline);
}

}  // namespace impeller
