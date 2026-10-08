// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_library_gles.h"

#include <sstream>
#include <string>

#include "flutter/fml/trace_event.h"
#include "impeller/base/promise.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/shader_function_gles.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {

PipelineLibraryGLES::PipelineLibraryGLES(
    std::shared_ptr<ReactorGLES> reactor,
    std::shared_ptr<fml::BasicTaskRunner> io_task_runner)
    : reactor_(std::move(reactor)),
      compile_queue_(
          PipelineCompileQueueGLES::Create(std::move(io_task_runner))) {}

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

static std::string GetShaderSource(const ProcTableGLES& gl, GLuint shader) {
  // Arbitrarily chosen size that should be larger than most shaders.
  // Since this only fires on compilation errors the performance shouldn't
  // matter.
  auto data = static_cast<char*>(malloc(10240));
  GLsizei length;
  gl.GetShaderSource(shader, 10240, &length, data);

  auto result = std::string{data, static_cast<size_t>(length)};
  free(data);
  return result;
}

static std::string GetShaderCompilationFailureMessage(const ProcTableGLES& gl,
                                                      GLuint shader,
                                                      std::string_view name,
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
    case ShaderStage::kCompute:
      stream << "compute";
      break;
  }
  stream << " shader for '" << name << "' with error:" << std::endl;
  stream << GetShaderInfoLog(gl, shader) << std::endl;
  stream << "Shader source was: " << std::endl;
  stream << GetShaderSource(gl, shader) << std::endl;
  return stream.str();
}

PipelineLibraryGLES::PendingProgram::PendingProgram(
    std::shared_ptr<ReactorGLES> reactor,
    PipelineDescriptor desc,
    std::shared_ptr<const ShaderFunction> vert_function,
    std::shared_ptr<const ShaderFunction> frag_function,
    bool threadsafe)
    : reactor_(std::move(reactor)),
      desc_(std::move(desc)),
      vert_function_(std::move(vert_function)),
      frag_function_(std::move(frag_function)),
      threadsafe_(threadsafe) {}

PipelineLibraryGLES::PendingProgram::~PendingProgram() {
  ReleaseShaders();
}

absl::Status PipelineLibraryGLES::PendingProgram::Compile() {
  TRACE_EVENT0("impeller", "PendingProgram::Compile");

  handle_ =
      threadsafe_
          ? std::make_shared<UniqueHandleGLES>(reactor_, HandleType::kProgram)
          : std::make_shared<UniqueHandleGLES>(UniqueHandleGLES::MakeUntracked(
                reactor_, HandleType::kProgram));

  std::optional<GLuint> program = reactor_->GetGLHandle(handle_->Get());
  if (!program.has_value()) {
    return absl::InternalError("Could not obtain program handle.");
  }
  program_ = *program;

  if (absl::Status status = CompileShaders(); !status.ok()) {
    ReleaseShaders();
    return status;
  }

  const ProcTableGLES& gl = reactor_->GetProcTable();
  gl.AttachShader(program_, vert_shader_);
  gl.AttachShader(program_, frag_shader_);
  shaders_attached_ = true;

  for (const ShaderStageIOSlot& stage_input :
       desc_.GetVertexDescriptor()->GetStageInputs()) {
    gl.BindAttribLocation(program_,                                   //
                          static_cast<GLuint>(stage_input.location),  //
                          stage_input.name                            //
    );
  }

  gl.LinkProgram(program_);
  link_pending_ = true;
  return absl::OkStatus();
}

absl::StatusOr<std::shared_ptr<UniqueHandleGLES>>
PipelineLibraryGLES::PendingProgram::Wait() {
  TRACE_EVENT0("impeller", "PendingProgram::Wait");
  if (!link_pending_) {
    return absl::FailedPreconditionError(
        "Compile must succeed before calling Wait.");
  }
  link_pending_ = false;
  absl::Status status = CheckLinkStatus();
  ReleaseShaders();
  if (!status.ok()) {
    return status;
  }
  return handle_;
}

absl::Status PipelineLibraryGLES::PendingProgram::CompileShaders() {
  const ProcTableGLES& gl = reactor_->GetProcTable();
  const std::shared_ptr<const fml::Mapping>& vert_mapping =
      ShaderFunctionGLES::Cast(*vert_function_).GetSourceMapping();
  const std::shared_ptr<const fml::Mapping>& frag_mapping =
      ShaderFunctionGLES::Cast(*frag_function_).GetSourceMapping();

  vert_shader_ = gl.CreateShader(GL_VERTEX_SHADER);
  frag_shader_ = gl.CreateShader(GL_FRAGMENT_SHADER);
  if (vert_shader_ == 0 || frag_shader_ == 0) {
    return absl::InternalError("Could not create shader handles.");
  }

  gl.SetDebugLabel(DebugResourceType::kShader, vert_shader_,
                   std::format("{} Vertex Shader", desc_.GetLabel()));
  gl.SetDebugLabel(DebugResourceType::kShader, frag_shader_,
                   std::format("{} Fragment Shader", desc_.GetLabel()));

  gl.ShaderSourceMapping(vert_shader_, *vert_mapping,
                         desc_.GetSpecializationConstants());
  gl.ShaderSourceMapping(frag_shader_, *frag_mapping,
                         desc_.GetSpecializationConstants());

  gl.CompileShader(vert_shader_);
  gl.CompileShader(frag_shader_);

  GLint vert_status = GL_FALSE;
  GLint frag_status = GL_FALSE;
  gl.GetShaderiv(vert_shader_, GL_COMPILE_STATUS, &vert_status);
  gl.GetShaderiv(frag_shader_, GL_COMPILE_STATUS, &frag_status);

  if (vert_status != GL_TRUE) {
    return absl::InternalError(GetShaderCompilationFailureMessage(
        gl, vert_shader_, desc_.GetLabel(), ShaderStage::kVertex));
  }
  if (frag_status != GL_TRUE) {
    return absl::InternalError(GetShaderCompilationFailureMessage(
        gl, frag_shader_, desc_.GetLabel(), ShaderStage::kFragment));
  }
  return absl::OkStatus();
}

absl::Status PipelineLibraryGLES::PendingProgram::CheckLinkStatus() const {
  const ProcTableGLES& gl = reactor_->GetProcTable();
  GLint link_status = GL_FALSE;
  gl.GetProgramiv(program_, GL_LINK_STATUS, &link_status);
  if (link_status == GL_TRUE) {
    return absl::OkStatus();
  }
  std::stringstream stream;
  stream << "Could not link shader program: "
         << gl.GetProgramInfoLogString(program_) << "\nVertex Shader:\n"
         << GetShaderSource(gl, vert_shader_) << "\nFragment Shader:\n"
         << GetShaderSource(gl, frag_shader_);
  return absl::InternalError(stream.str());
}

void PipelineLibraryGLES::PendingProgram::ReleaseShaders() {
  if (vert_shader_ == 0 && frag_shader_ == 0) {
    return;
  }
  const ProcTableGLES& gl = reactor_->GetProcTable();
  if (shaders_attached_) {
    gl.DetachShader(program_, vert_shader_);
    gl.DetachShader(program_, frag_shader_);
    shaders_attached_ = false;
  }
  gl.DeleteShader(vert_shader_);
  gl.DeleteShader(frag_shader_);
  vert_shader_ = 0;
  frag_shader_ = 0;
}

// |PipelineLibrary|
bool PipelineLibraryGLES::IsValid() const {
  return reactor_ != nullptr;
}

std::shared_ptr<PipelineGLES> PipelineLibraryGLES::CreatePipeline(
    const std::weak_ptr<PipelineLibrary>& weak_library,
    const std::shared_ptr<ReactorGLES>& reactor,
    const PipelineDescriptor& desc,
    std::shared_ptr<UniqueHandleGLES> program_handle) {
  auto pipeline = std::shared_ptr<PipelineGLES>(
      new PipelineGLES(reactor,       //
                       weak_library,  //
                       desc,          //
                       std::move(program_handle)));

  std::optional<GLuint> program =
      reactor->GetGLHandle(pipeline->GetProgramHandle());
  if (!program.has_value()) {
    VALIDATION_LOG << "Could not obtain program handle.";
    return nullptr;
  }

  if (!pipeline->BuildVertexDescriptor(reactor->GetProcTable(),
                                       program.value())) {
    VALIDATION_LOG << "Could not build pipeline vertex descriptors.";
    return nullptr;
  }

  if (!pipeline->IsValid()) {
    VALIDATION_LOG << "Pipeline validation checks failed.";
    return nullptr;
  }

  return pipeline;
}

// |PipelineLibrary|
PipelineFuture<PipelineDescriptor> PipelineLibraryGLES::GetPipeline(
    PipelineDescriptor descriptor,
    bool async,
    bool threadsafe) {
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    return found->second;
  }

  if (!reactor_) {
    return {
        descriptor,
        RealizedFuture<std::shared_ptr<Pipeline<PipelineDescriptor>>>(nullptr)};
  }

  std::shared_ptr<const ShaderFunction> vert_function =
      descriptor.GetEntrypointForStage(ShaderStage::kVertex);
  std::shared_ptr<const ShaderFunction> frag_function =
      descriptor.GetEntrypointForStage(ShaderStage::kFragment);

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

  std::weak_ptr<PipelineLibrary> weak_this = weak_from_this();
  std::shared_ptr<ReactorGLES> reactor = reactor_;
  auto generation_task = [promise, weak_this, descriptor, vert_function,
                          frag_function, threadsafe, reactor]() {
    std::shared_ptr<PipelineLibrary> thiz = weak_this.lock();
    if (!thiz) {
      promise->set_value(nullptr);
      return;
    }
    const bool result = reactor->AddOperation([promise,        //
                                               weak_this,      //
                                               descriptor,     //
                                               vert_function,  //
                                               frag_function,  //
                                               threadsafe      //
    ](const ReactorGLES&) {
      std::shared_ptr<PipelineLibrary> strong_library = weak_this.lock();
      if (!strong_library) {
        VALIDATION_LOG << "Library was collected before a pending pipeline "
                          "creation could finish.";
        promise->set_value(nullptr);
        return;
      }
      auto& library = PipelineLibraryGLES::Cast(*strong_library);
      const std::shared_ptr<ReactorGLES>& reactor = library.GetReactor();
      if (!reactor) {
        promise->set_value(nullptr);
        return;
      }

      auto program_key = ProgramKey{vert_function, frag_function,
                                    descriptor.GetSpecializationConstants()};
      std::shared_ptr<UniqueHandleGLES> program =
          library.GetCachedProgram(program_key);
      if (!program) {
        PendingProgram pending_program(reactor, descriptor, vert_function,
                                       frag_function, threadsafe);
        absl::StatusOr<std::shared_ptr<UniqueHandleGLES>> linked_program;
        if (absl::Status status = pending_program.Compile(); status.ok()) {
          linked_program = pending_program.Wait();
        } else {
          linked_program = std::move(status);
        }
        if (!linked_program.ok()) {
          VALIDATION_LOG << "Could not link pipeline program: "
                         << linked_program.status().message();
          promise->set_value(nullptr);
          return;
        }
        program = *std::move(linked_program);
        library.CacheProgram(program_key, program);
      }
      promise->set_value(
          CreatePipeline(weak_this, reactor, descriptor, std::move(program)));
    });
    FML_CHECK(result);
  };

  if (async && compile_queue_) {
    compile_queue_->PostJobForDescriptor(descriptor,
                                         std::move(generation_task));
  } else {
    generation_task();
  }

  return pipeline_future;
}

// |PipelineLibrary|
PipelineFuture<ComputePipelineDescriptor> PipelineLibraryGLES::GetPipeline(
    ComputePipelineDescriptor descriptor,
    bool async) {
  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>>();
  promise->set_value(nullptr);
  return {descriptor, promise->get_future()};
}

// |PipelineLibrary|
bool PipelineLibraryGLES::HasPipeline(const PipelineDescriptor& descriptor) {
  return pipelines_.find(descriptor) != pipelines_.end();
}

// |PipelineLibrary|
void PipelineLibraryGLES::RemovePipelinesWithEntryPoint(
    std::shared_ptr<const ShaderFunction> function) {
  Lock lock(programs_mutex_);

  PipelineMap::iterator it = pipelines_.begin();
  while (it != pipelines_.end()) {
    const PipelineDescriptor& desc = it->first;
    if (desc.GetEntrypointForStage(function->GetStage())->IsEqual(*function)) {
      const std::shared_ptr<const ShaderFunction>& vert_function =
          desc.GetEntrypointForStage(ShaderStage::kVertex);
      const std::shared_ptr<const ShaderFunction>& frag_function =
          desc.GetEntrypointForStage(ShaderStage::kFragment);
      ProgramKey program_key{vert_function, frag_function,
                             desc.GetSpecializationConstants()};
      programs_.erase(program_key);
      it = pipelines_.erase(it);
    } else {
      it++;
    }
  }
}

// |PipelineLibrary|
PipelineLibraryGLES::~PipelineLibraryGLES() = default;

const std::shared_ptr<ReactorGLES>& PipelineLibraryGLES::GetReactor() const {
  return reactor_;
}

std::shared_ptr<UniqueHandleGLES> PipelineLibraryGLES::GetCachedProgram(
    const ProgramKey& key) {
  Lock lock(programs_mutex_);
  auto found = programs_.find(key);
  if (found != programs_.end()) {
    return found->second;
  }
  return nullptr;
}

void PipelineLibraryGLES::CacheProgram(
    const ProgramKey& key,
    std::shared_ptr<UniqueHandleGLES> program) {
  Lock lock(programs_mutex_);
  programs_[key] = std::move(program);
}

// |PipelineLibrary|
void PipelineLibraryGLES::PerformEagerly(const PipelineDescriptor& descriptor) {
  if (compile_queue_) {
    compile_queue_->PerformJobEagerly(descriptor);
  }
}

}  // namespace impeller
