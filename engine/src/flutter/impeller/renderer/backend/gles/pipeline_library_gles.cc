// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_library_gles.h"

#include <algorithm>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "fml/closure.h"
#include "impeller/base/promise.h"
#include "impeller/renderer/backend/gles/description_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/shader_function_gles.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {

static const constexpr char* kParallelShaderCompileExt =
    "GL_KHR_parallel_shader_compile";

// How many links may be started before the library checks them. Every link
// occupies a thread of the driver, so starting all of them at once takes the
// cores that the Dart isolate needs while it starts. This is the bound that
// ContextVK::ChooseThreadCountForWorkers uses for the same reason, see
// https://github.com/flutter/flutter/issues/143540
static size_t MaxPendingLinks() {
  return std::clamp<size_t>(std::thread::hardware_concurrency() / 2, 1, 4);
}

// Only ANGLE is enabled for now. It cross compiles every program to HLSL,
// which is what makes a link expensive, and it is the only GLES driver the
// change was measured on.
static bool HasParallelShaderCompile(
    const std::shared_ptr<ReactorGLES>& reactor) {
  if (!reactor) {
    return false;
  }
  const DescriptionGLES* description = reactor->GetProcTable().GetDescription();
  return description != nullptr && description->IsANGLE() &&
         description->HasExtension(kParallelShaderCompileExt);
}

PipelineLibraryGLES::PipelineLibraryGLES(
    std::shared_ptr<ReactorGLES> reactor,
    std::shared_ptr<fml::BasicTaskRunner> io_task_runner)
    : reactor_(std::move(reactor)),
      compile_queue_(
          PipelineCompileQueueGLES::Create(std::move(io_task_runner))),
      supports_parallel_shader_compile_(HasParallelShaderCompile(reactor_)),
      max_pending_links_(MaxPendingLinks()) {}

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

static void LogShaderCompilationFailure(const ProcTableGLES& gl,
                                        GLuint shader,
                                        std::string_view name,
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
    case ShaderStage::kCompute:
      stream << "compute";
      break;
  }
  stream << " shader for '" << name << "' with error:" << std::endl;
  stream << GetShaderInfoLog(gl, shader) << std::endl;
  stream << "Shader source was: " << std::endl;
  stream << GetShaderSource(gl, shader) << std::endl;
  VALIDATION_LOG << stream.str();
}

static bool CheckCompileStatus(
    const ProcTableGLES& gl,
    const PipelineDescriptor& descriptor,
    GLuint vert_shader,
    GLuint frag_shader,
    const std::shared_ptr<const ShaderFunction>& vert_function,
    const std::shared_ptr<const ShaderFunction>& frag_function) {
  GLint vert_status = GL_FALSE;
  GLint frag_status = GL_FALSE;

  gl.GetShaderiv(vert_shader, GL_COMPILE_STATUS, &vert_status);
  gl.GetShaderiv(frag_shader, GL_COMPILE_STATUS, &frag_status);

  if (vert_status != GL_TRUE) {
    LogShaderCompilationFailure(
        gl, vert_shader, descriptor.GetLabel(),
        *ShaderFunctionGLES::Cast(*vert_function).GetSourceMapping(),
        ShaderStage::kVertex);
    return false;
  }

  if (frag_status != GL_TRUE) {
    LogShaderCompilationFailure(
        gl, frag_shader, descriptor.GetLabel(),
        *ShaderFunctionGLES::Cast(*frag_function).GetSourceMapping(),
        ShaderStage::kFragment);
    return false;
  }
  return true;
}

// Shaders stay attached to their program until FinishProgramLink checks the
// link status.
struct ProgramShaders {
  GLuint vert = 0;
  GLuint frag = 0;
};

// Compiles both shaders and starts the program link.
//
// With GL_KHR_parallel_shader_compile, a status query waits for the compiler,
// so a deferred link leaves every status query to FinishProgramLink. A
// deferred link also flags the shaders for deletion right away. GL frees them
// when they are detached or when the program is deleted, so they do not leak
// if FinishProgramLink never runs.
static bool StartProgramLink(
    const ReactorGLES& reactor,
    const std::shared_ptr<PipelineGLES>& pipeline,
    const std::shared_ptr<const ShaderFunction>& vert_function,
    const std::shared_ptr<const ShaderFunction>& frag_function,
    bool deferred,
    ProgramShaders* shaders) {
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
                   std::format("{} Vertex Shader", descriptor.GetLabel()));
  gl.SetDebugLabel(DebugResourceType::kShader, frag_shader,
                   std::format("{} Fragment Shader", descriptor.GetLabel()));

  fml::ScopedCleanupClosure delete_vert_shader(
      [&gl, vert_shader]() { gl.DeleteShader(vert_shader); });
  fml::ScopedCleanupClosure delete_frag_shader(
      [&gl, frag_shader]() { gl.DeleteShader(frag_shader); });

  gl.ShaderSourceMapping(vert_shader, *vert_mapping,
                         descriptor.GetSpecializationConstants());
  gl.ShaderSourceMapping(frag_shader, *frag_mapping,
                         descriptor.GetSpecializationConstants());

  gl.CompileShader(vert_shader);
  gl.CompileShader(frag_shader);

  if (!deferred && !CheckCompileStatus(gl, descriptor, vert_shader, frag_shader,
                                       vert_function, frag_function)) {
    return false;
  }

  auto program = reactor.GetGLHandle(pipeline->GetProgramHandle());
  if (!program.has_value()) {
    VALIDATION_LOG << "Could not get program handle from reactor.";
    return false;
  }

  gl.AttachShader(*program, vert_shader);
  gl.AttachShader(*program, frag_shader);

  for (const auto& stage_input :
       descriptor.GetVertexDescriptor()->GetStageInputs()) {
    gl.BindAttribLocation(*program,                                   //
                          static_cast<GLuint>(stage_input.location),  //
                          stage_input.name                            //
    );
  }

  gl.LinkProgram(*program);

  if (deferred) {
    gl.DeleteShader(vert_shader);
    gl.DeleteShader(frag_shader);
  }
  delete_vert_shader.Release();
  delete_frag_shader.Release();
  shaders->vert = vert_shader;
  shaders->frag = frag_shader;
  return true;
}

// Checks the result of StartProgramLink, then detaches the shaders. A shader
// of a deferred link is already flagged for deletion, so detaching frees it.
static bool FinishProgramLink(
    const ReactorGLES& reactor,
    const std::shared_ptr<PipelineGLES>& pipeline,
    const std::shared_ptr<const ShaderFunction>& vert_function,
    const std::shared_ptr<const ShaderFunction>& frag_function,
    const ProgramShaders& shaders,
    bool deferred) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  const auto& descriptor = pipeline->GetDescriptor();
  const auto& gl = reactor.GetProcTable();
  const GLuint vert_shader = shaders.vert;
  const GLuint frag_shader = shaders.frag;

  fml::ScopedCleanupClosure delete_vert_shader([&gl, vert_shader, deferred]() {
    if (!deferred) {
      gl.DeleteShader(vert_shader);
    }
  });
  fml::ScopedCleanupClosure delete_frag_shader([&gl, frag_shader, deferred]() {
    if (!deferred) {
      gl.DeleteShader(frag_shader);
    }
  });

  auto program = reactor.GetGLHandle(pipeline->GetProgramHandle());
  if (!program.has_value()) {
    VALIDATION_LOG << "Could not get program handle from reactor.";
    return false;
  }

  fml::ScopedCleanupClosure detach_vert_shader(
      [&gl, program = *program, vert_shader]() {
        gl.DetachShader(program, vert_shader);
      });
  fml::ScopedCleanupClosure detach_frag_shader(
      [&gl, program = *program, frag_shader]() {
        gl.DetachShader(program, frag_shader);
      });

  if (deferred && !CheckCompileStatus(gl, descriptor, vert_shader, frag_shader,
                                      vert_function, frag_function)) {
    return false;
  }

  GLint link_status = GL_FALSE;
  gl.GetProgramiv(*program, GL_LINK_STATUS, &link_status);

  if (link_status != GL_TRUE) {
    VALIDATION_LOG << "Could not link shader program: "
                   << gl.GetProgramInfoLogString(*program)
                   << "\nVertex Shader:\n"
                   << GetShaderSource(gl, vert_shader) << "\nFragment Shader:\n"
                   << GetShaderSource(gl, frag_shader);
    return false;
  }
  return true;
}

static bool LinkProgram(
    const ReactorGLES& reactor,
    const std::shared_ptr<PipelineGLES>& pipeline,
    const std::shared_ptr<const ShaderFunction>& vert_function,
    const std::shared_ptr<const ShaderFunction>& frag_function) {
  ProgramShaders shaders;
  if (!StartProgramLink(reactor, pipeline, vert_function, frag_function,
                        /*deferred=*/false, &shaders)) {
    return false;
  }
  return FinishProgramLink(reactor, pipeline, vert_function, frag_function,
                           shaders, /*deferred=*/false);
}

static bool IsProgramLinked(const ReactorGLES& reactor,
                            const PipelineGLES& pipeline) {
  auto program = reactor.GetGLHandle(pipeline.GetProgramHandle());
  if (!program.has_value()) {
    return false;
  }
  GLint link_status = GL_FALSE;
  reactor.GetProcTable().GetProgramiv(*program, GL_LINK_STATUS, &link_status);
  return link_status == GL_TRUE;
}

// |PipelineLibrary|
bool PipelineLibraryGLES::IsValid() const {
  return reactor_ != nullptr;
}

std::shared_ptr<PipelineGLES> PipelineLibraryGLES::CreatePipeline(
    const std::weak_ptr<PipelineLibrary>& weak_library,
    const PipelineDescriptor& desc,
    const std::shared_ptr<const ShaderFunction>& vert_function,
    const std::shared_ptr<const ShaderFunction>& frag_function,
    bool threadsafe,
    std::shared_ptr<PipelinePromise> deferred_promise) {
  auto strong_library = weak_library.lock();

  if (!strong_library) {
    VALIDATION_LOG << "Library was collected before a pending pipeline "
                      "creation could finish.";
    return nullptr;
  }

  auto& library = PipelineLibraryGLES::Cast(*strong_library);

  const auto& reactor = library.GetReactor();

  if (!reactor) {
    return nullptr;
  }

  auto program_key = ProgramKey{vert_function, frag_function,
                                desc.GetSpecializationConstants()};

  auto cached_program = library.GetProgramForKey(program_key);

  const auto has_cached_program = !!cached_program;

  std::shared_ptr<UniqueHandleGLES> program_handle = nullptr;
  if (has_cached_program) {
    program_handle = std::move(cached_program);
  } else {
    program_handle = threadsafe ? std::make_shared<UniqueHandleGLES>(
                                      reactor, HandleType::kProgram)
                                : std::make_shared<UniqueHandleGLES>(
                                      UniqueHandleGLES::MakeUntracked(
                                          reactor, HandleType::kProgram));
  }

  auto pipeline = std::shared_ptr<PipelineGLES>(
      new PipelineGLES(reactor,       //
                       weak_library,  //
                       desc,          //
                       std::move(program_handle)));

  auto program = reactor->GetGLHandle(pipeline->GetProgramHandle());

  if (!program.has_value()) {
    VALIDATION_LOG << "Could not obtain program handle.";
    return nullptr;
  }

  if (deferred_promise) {
    ProgramShaders shaders;
    if (!has_cached_program) {
      if (!StartProgramLink(*reactor, pipeline, vert_function, frag_function,
                            /*deferred=*/true, &shaders)) {
        VALIDATION_LOG << "Could not link pipeline program.";
        return nullptr;
      }
      // Other variants of this program reuse it while it links.
      library.SetProgramForKey(program_key, pipeline->GetSharedHandle());
    }
    library.WatchQueueForDrain();
    size_t pending_count = 0;
    {
      Lock lock(library.pending_mutex_);
      library.pending_pipelines_.push_back(PendingPipeline{
          .pipeline = pipeline,
          .promise = std::move(deferred_promise),
          .program_key = std::move(program_key),
          .vert_shader = shaders.vert,
          .frag_shader = shaders.frag,
      });
      pending_count = library.pending_pipelines_.size();
    }
    // The queue tells the library when it runs out of jobs. An idle queue
    // never sends that report, and at the limit the library does not wait
    // for it, so both cases check the links here.
    if (pending_count >= library.max_pending_links_ ||
        !library.compile_queue_->IsProcessingJobs()) {
      library.FinishPendingPipelines(*reactor);
    }
    return pipeline;
  }

  const auto link_result = !has_cached_program ? LinkProgram(*reactor,       //
                                                             pipeline,       //
                                                             vert_function,  //
                                                             frag_function   //
                                                             )
                                               : true;

  if (!link_result) {
    VALIDATION_LOG << "Could not link pipeline program.";
    return nullptr;
  }

  // A cached program can still be linking on another thread. The status
  // query waits for that link.
  if (has_cached_program && library.SupportsParallelShaderCompile() &&
      !IsProgramLinked(*reactor, *pipeline)) {
    VALIDATION_LOG << "Could not link pipeline program.";
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

  if (!has_cached_program) {
    library.SetProgramForKey(program_key, pipeline->GetSharedHandle());
  }

  return pipeline;
}

void PipelineLibraryGLES::WatchQueueForDrain() {
  {
    Lock lock(pending_mutex_);
    if (is_watching_queue_) {
      return;
    }
    is_watching_queue_ = true;
  }
  // The callback runs on the same task runner as the compile jobs, and the
  // reactor keeps an operation on the thread that added it, so the check runs
  // on that thread and never next to a link on another one.
  std::weak_ptr<PipelineLibrary> weak_this = weak_from_this();
  compile_queue_->SetOnDrained([weak_this]() {
    auto thiz = weak_this.lock();
    if (!thiz) {
      return;
    }
    auto& library = PipelineLibraryGLES::Cast(*thiz);
    {
      Lock lock(library.pending_mutex_);
      if (library.pending_pipelines_.empty()) {
        return;
      }
    }
    const bool result =
        library.reactor_->AddOperation([weak_this](const ReactorGLES& reactor) {
          if (auto library = weak_this.lock()) {
            PipelineLibraryGLES::Cast(*library).FinishPendingPipelines(reactor);
          }
        });
    if (!result) {
      // The reactor is gone, so no thread can check the links anymore.
      library.FailPendingPipelines();
      return;
    }
    // An accepted operation still waits for a reaction of this thread when the
    // reactor could not react now, and that reaction never comes once the
    // thread gives up the context, so we check the list as well.
    bool still_pending = false;
    {
      Lock lock(library.pending_mutex_);
      still_pending = !library.pending_pipelines_.empty();
    }
    if (still_pending) {
      library.FailPendingPipelines();
    }
  });
}

void PipelineLibraryGLES::FinishPendingPipelines(const ReactorGLES& reactor) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  // The compile queue runs its jobs one at a time, so this never runs at the
  // same time as a job that starts a link.
  FML_DCHECK(!compile_queue_ || compile_queue_->RunningJobCount() <= 1);

  std::vector<PendingPipeline> pending;
  {
    Lock lock(pending_mutex_);
    pending.swap(pending_pipelines_);
  }

  for (auto& item : pending) {
    item.promise->set_value(FinishPipeline(reactor, item));
  }
}

std::shared_ptr<PipelineGLES> PipelineLibraryGLES::FinishPipeline(
    const ReactorGLES& reactor,
    const PendingPipeline& item) {
  const auto& pipeline = item.pipeline;
  // StartProgramLink returns both shaders or none.
  const bool owns_link = item.vert_shader != 0;

  const bool link_result =
      owns_link
          ? FinishProgramLink(reactor, pipeline, item.program_key.vertex_shader,
                              item.program_key.fragment_shader,
                              ProgramShaders{.vert = item.vert_shader,
                                             .frag = item.frag_shader},
                              /*deferred=*/true)
          : IsProgramLinked(reactor, *pipeline);

  auto fail = [&]() -> std::shared_ptr<PipelineGLES> {
    if (owns_link) {
      RemoveProgramForKey(item.program_key, pipeline->GetSharedHandle());
    }
    return nullptr;
  };

  if (!link_result) {
    VALIDATION_LOG << "Could not link pipeline program.";
    return fail();
  }

  auto program = reactor.GetGLHandle(pipeline->GetProgramHandle());
  if (!program.has_value()) {
    VALIDATION_LOG << "Could not obtain program handle.";
    return fail();
  }

  if (!pipeline->BuildVertexDescriptor(reactor.GetProcTable(),
                                       program.value())) {
    VALIDATION_LOG << "Could not build pipeline vertex descriptors.";
    return fail();
  }

  if (!pipeline->IsValid()) {
    VALIDATION_LOG << "Pipeline validation checks failed.";
    return fail();
  }

  return pipeline;
}

bool PipelineLibraryGLES::SupportsParallelShaderCompile() const {
  return supports_parallel_shader_compile_;
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

  std::weak_ptr<PipelineLibrary> weak_this = weak_from_this();
  std::shared_ptr<ReactorGLES> reactor = reactor_;
  // A synchronous caller waits for the future on this thread, so only an
  // async job may return before its program is linked.
  // The queue owns this job while it waits, so a strong reference here would
  // keep the queue alive through the job it holds. A task runner that drops
  // its tasks would then leak both and leave the promise unset.
  std::weak_ptr<PipelineCompileQueueGLES> weak_compile_queue =
      async && supports_parallel_shader_compile_
          ? compile_queue_
          : std::shared_ptr<PipelineCompileQueueGLES>();
  auto generation_task = [promise, weak_this, descriptor, vert_function,
                          frag_function, threadsafe, reactor,
                          weak_compile_queue]() {
    auto thiz = weak_this.lock();
    if (!thiz) {
      promise->set_value(nullptr);
      return;
    }
    const bool result = reactor->AddOperation([promise,            //
                                               weak_this,          //
                                               descriptor,         //
                                               vert_function,      //
                                               frag_function,      //
                                               threadsafe,         //
                                               weak_compile_queue  //
    ](const ReactorGLES& reactor) {
      // The job that runs this holds the queue, so the lock succeeds while a
      // job of it runs on this thread.
      auto compile_queue = weak_compile_queue.lock();
      if (compile_queue && compile_queue->IsRunningJobOnCurrentThread()) {
        // The promise is set later unless the pipeline fails right away.
        if (!CreatePipeline(weak_this, descriptor, vert_function, frag_function,
                            threadsafe, promise)) {
          promise->set_value(nullptr);
        }
        return;
      }
      promise->set_value(CreatePipeline(weak_this, descriptor, vert_function,
                                        frag_function, threadsafe));
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
PipelineLibraryGLES::~PipelineLibraryGLES() {
  FailPendingPipelines();
}

void PipelineLibraryGLES::FailPendingPipelines() {
  std::vector<PendingPipeline> pending;
  {
    Lock lock(pending_mutex_);
    pending.swap(pending_pipelines_);
  }
  for (auto& item : pending) {
    // Nobody checks this link, so the cache must not hand the program to a
    // later request once the reactor works again. FinishPipeline removes it
    // the same way when the link fails.
    if (item.vert_shader != 0 && item.pipeline) {
      RemoveProgramForKey(item.program_key, item.pipeline->GetSharedHandle());
    }
    item.promise->set_value(nullptr);
  }
}

const std::shared_ptr<ReactorGLES>& PipelineLibraryGLES::GetReactor() const {
  return reactor_;
}

std::shared_ptr<UniqueHandleGLES> PipelineLibraryGLES::GetProgramForKey(
    const ProgramKey& key) {
  Lock lock(programs_mutex_);
  auto found = programs_.find(key);
  if (found != programs_.end()) {
    return found->second;
  }
  return nullptr;
}

void PipelineLibraryGLES::SetProgramForKey(
    const ProgramKey& key,
    std::shared_ptr<UniqueHandleGLES> program) {
  Lock lock(programs_mutex_);
  programs_[key] = std::move(program);
}

void PipelineLibraryGLES::RemoveProgramForKey(
    const ProgramKey& key,
    const std::shared_ptr<UniqueHandleGLES>& program) {
  Lock lock(programs_mutex_);
  auto found = programs_.find(key);
  if (found != programs_.end() && found->second == program) {
    programs_.erase(found);
  }
}

PipelineCompileQueue* PipelineLibraryGLES::GetPipelineCompileQueue() const {
  return compile_queue_.get();
}

}  // namespace impeller
