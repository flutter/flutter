// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_library_gles.h"

#include <sstream>
#include <string>

#include "flutter/fml/container.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/promise.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/shader_function_gles.h"

namespace impeller {

PipelineLibraryGLES::PipelineLibraryGLES(ReactorGLES::Ref reactor)
    : reactor_(std::move(reactor)) {}

static std::string GetShaderInfoLog(const ProcTableGLES& gl, GLuint shader) {
  GLint log_length = 0;
  gl.GetShaderiv(shader, GL_INFO_LOG_LENGTH, &log_length);
  if (log_length == 0) {
    return "";
  }
  auto log_buffer =
      reinterpret_cast<char*>(std::calloc(log_length, sizeof(char)));
  gl.GetShaderInfoLog(shader, log_length, &log_length, log_buffer);
  auto log_string = std::string(log_buffer, log_length);
  std::free(log_buffer);
  return log_string;
}

static void LogShaderCompilationFailure(const ProcTableGLES& gl,
                                        GLuint shader,
                                        const std::string& name,
                                        const fml::Mapping& source_mapping,
                                        ShaderStage stage) {
  std::stringstream stream;
  stream << "Failed to compile ";
  switch (stage) {
    case ShaderStage::kUnknown:
      stream << "unknown";
      break;
    case ShaderStage::kVertex:
      stream << "vertex";
      break;
    case ShaderStage::kFragment:
      stream << "fragment";
      break;
    case ShaderStage::kTessellationControl:
      stream << "tessellation control";
      break;
    case ShaderStage::kTessellationEvaluation:
      stream << "tessellation evaluation";
      break;
    case ShaderStage::kCompute:
      stream << "compute";
      break;
  }
  stream << " shader for '" << name << "' with error:" << std::endl;
  stream << GetShaderInfoLog(gl, shader) << std::endl;
  stream << "Shader source was: " << std::endl;
  stream << std::string{reinterpret_cast<const char*>(
                            source_mapping.GetMapping()),
                        source_mapping.GetSize()}
         << std::endl;
  VALIDATION_LOG << stream.str();
}

static bool LinkProgram(
    const ReactorGLES& reactor,
    const std::shared_ptr<PipelineGLES>& pipeline,
    const std::shared_ptr<const ShaderFunction>& vert_function,
    const std::shared_ptr<const ShaderFunction>& frag_function) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  const auto& descriptor = pipeline->GetDescriptor();

  auto vert_mapping =
      ShaderFunctionGLES::Cast(*vert_function).GetSourceMapping();
  auto frag_mapping =
      ShaderFunctionGLES::Cast(*frag_function).GetSourceMapping();

  const auto& gl = reactor.GetProcTable();

  auto vert_shader = gl.CreateShader(GL_VERTEX_SHADER);
  auto frag_shader = gl.CreateShader(GL_FRAGMENT_SHADER);

  if (vert_shader == 0 || frag_shader == 0) {
    VALIDATION_LOG << "Could not create shader handles.";
    return false;
  }

  gl.SetDebugLabel(DebugResourceType::kShader, vert_shader,
                   SPrintF("%s Vertex Shader", descriptor.GetLabel().c_str()));
  gl.SetDebugLabel(
      DebugResourceType::kShader, frag_shader,
      SPrintF("%s Fragment Shader", descriptor.GetLabel().c_str()));

  fml::ScopedCleanupClosure delete_vert_shader(
      [&gl, vert_shader]() { gl.DeleteShader(vert_shader); });
  fml::ScopedCleanupClosure delete_frag_shader(
      [&gl, frag_shader]() { gl.DeleteShader(frag_shader); });

  gl.ShaderSourceMapping(vert_shader, *vert_mapping);
  gl.ShaderSourceMapping(frag_shader, *frag_mapping);

  gl.CompileShader(vert_shader);
  gl.CompileShader(frag_shader);

  GLint vert_status = GL_FALSE;
  GLint frag_status = GL_FALSE;

  gl.GetShaderiv(vert_shader, GL_COMPILE_STATUS, &vert_status);
  gl.GetShaderiv(frag_shader, GL_COMPILE_STATUS, &frag_status);

  if (vert_status != GL_TRUE) {
    LogShaderCompilationFailure(gl, vert_shader, descriptor.GetLabel(),
                                *vert_mapping, ShaderStage::kVertex);
    return false;
  }

  if (frag_status != GL_TRUE) {
    LogShaderCompilationFailure(gl, frag_shader, descriptor.GetLabel(),
                                *frag_mapping, ShaderStage::kFragment);
    return false;
  }

  auto program = reactor.GetGLHandle(pipeline->GetProgramHandle());
  if (!program.has_value()) {
    VALIDATION_LOG << "Could not get program handle from reactor.";
    return false;
  }

  gl.AttachShader(*program, vert_shader);
  gl.AttachShader(*program, frag_shader);

  fml::ScopedCleanupClosure detach_vert_shader(
      [&gl, program = *program, vert_shader]() {
        gl.DetachShader(program, vert_shader);
      });
  fml::ScopedCleanupClosure detach_frag_shader(
      [&gl, program = *program, frag_shader]() {
        gl.DetachShader(program, frag_shader);
      });

  for (const auto& stage_input :
       descriptor.GetVertexDescriptor()->GetStageInputs()) {
    gl.BindAttribLocation(*program,                                   //
                          static_cast<GLuint>(stage_input.location),  //
                          stage_input.name                            //
    );
  }

  gl.LinkProgram(*program);

  GLint link_status = GL_FALSE;
  gl.GetProgramiv(*program, GL_LINK_STATUS, &link_status);

  if (link_status != GL_TRUE) {
    VALIDATION_LOG << "Could not link shader program: "
                   << gl.GetProgramInfoLogString(*program);
    return false;
  }
  return true;
}

// |PipelineLibrary|
bool PipelineLibraryGLES::IsValid() const {
  return reactor_ != nullptr;
}

// |PipelineLibrary|
PipelineFuture<PipelineDescriptor> PipelineLibraryGLES::GetPipeline(
    PipelineDescriptor descriptor) {
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    return found->second;
  }

  if (!reactor_) {
    return {
        descriptor,
        RealizedFuture<std::shared_ptr<Pipeline<PipelineDescriptor>>>(nullptr)};
  }

  auto vert_function = descriptor.GetEntrypointForStage(ShaderStage::kVertex);
  auto frag_function = descriptor.GetEntrypointForStage(ShaderStage::kFragment);

  if (!vert_function || !frag_function) {
    VALIDATION_LOG
        << "Could not find stage entrypoint functions in pipeline descriptor.";
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

  auto result = reactor_->AddOperation(
      [promise, weak_this, reactor_ptr = reactor_, descriptor, vert_function,
       frag_function](const ReactorGLES& reactor) {
        auto strong_this = weak_this.lock();
        if (!strong_this) {
          promise->set_value(nullptr);
          VALIDATION_LOG << "Library was collected before a pending pipeline "
                            "creation could finish.";
          return;
        }
        auto pipeline = std::shared_ptr<PipelineGLES>(
            new PipelineGLES(reactor_ptr, strong_this, descriptor));
        auto program = reactor.GetGLHandle(pipeline->GetProgramHandle());
        if (!program.has_value()) {
          promise->set_value(nullptr);
          VALIDATION_LOG << "Could not obtain program handle.";
          return;
        }
        const auto link_result = LinkProgram(reactor,        //
                                             pipeline,       //
                                             vert_function,  //
                                             frag_function   //
        );
        if (!link_result) {
          promise->set_value(nullptr);
          VALIDATION_LOG << "Could not link pipeline program.";
          return;
        }
        if (!pipeline->BuildVertexDescriptor(reactor.GetProcTable(),
                                             program.value())) {
          promise->set_value(nullptr);
          VALIDATION_LOG << "Could not build pipeline vertex descriptors.";
          return;
        }
        if (!pipeline->IsValid()) {
          promise->set_value(nullptr);
          VALIDATION_LOG << "Pipeline validation checks failed.";
          return;
        }
        promise->set_value(std::move(pipeline));
      });
  FML_CHECK(result);

  return pipeline_future;
}

// |PipelineLibrary|
PipelineFuture<ComputePipelineDescriptor> PipelineLibraryGLES::GetPipeline(
    ComputePipelineDescriptor descriptor) {
  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>>();
  // TODO(dnfield): implement compute for GLES.
  promise->set_value(nullptr);
  return {descriptor, promise->get_future()};
}

// |PipelineLibrary|
void PipelineLibraryGLES::RemovePipelinesWithEntryPoint(
    std::shared_ptr<const ShaderFunction> function) {
  fml::erase_if(pipelines_, [&](auto item) {
    return item->first.GetEntrypointForStage(function->GetStage())
        ->IsEqual(*function);
  });
}

// |PipelineLibrary|
PipelineLibraryGLES::~PipelineLibraryGLES() = default;

}  // namespace impeller
