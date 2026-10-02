// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/test/pipeline_library_gles_test_utils.h"

#include <chrono>
#include <cstring>
#include <future>
#include <string>
#include <vector>

#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/gles/pipeline_library_gles.h"
#include "impeller/renderer/shader_library.h"
#include "impeller/renderer/vertex_descriptor.h"

namespace impeller::testing {

DeferredLinkState* g_deferred_links = nullptr;

namespace {

bool IsSet(const std::unordered_map<GLuint, bool>& values, GLuint id) {
  std::unordered_map<GLuint, bool>::const_iterator found = values.find(id);
  return found != values.end() && found->second;
}

GLuint GL_APIENTRY DeferredCreateShader(GLenum type) {
  GLuint id = g_deferred_links->next++;
  g_deferred_links->shaders[id] =
      !(g_deferred_links->fail_compile && type == GL_VERTEX_SHADER);
  return id;
}
GLuint GL_APIENTRY DeferredCreateProgram() {
  g_deferred_links->programs++;
  return g_deferred_links->next++;
}
void GL_APIENTRY DeferredLinkProgram(GLuint program) {
  g_deferred_links->links++;
  g_deferred_links->linked[program] =
      !g_deferred_links->fail_compile && !g_deferred_links->fail_link;
}
void GL_APIENTRY DeferredGetShaderiv(GLuint shader,
                                     GLenum pname,
                                     GLint* value) {
  *value = 0;
  if (pname == GL_COMPILE_STATUS) {
    g_deferred_links->compile_queries++;
    *value = IsSet(g_deferred_links->shaders, shader) ? GL_TRUE : GL_FALSE;
  }
}
void GL_APIENTRY DeferredGetProgramiv(GLuint program,
                                      GLenum pname,
                                      GLint* value) {
  if (pname == GL_COMPLETION_STATUS_KHR) {
    g_deferred_links->completion_queries++;
    // A driver that rejects the query leaves the value unchanged
    if (g_deferred_links->completion_supported) {
      *value = IsSet(g_deferred_links->completed, program) ? GL_TRUE : GL_FALSE;
    }
    return;
  }
  *value = 0;
  if (pname == GL_LINK_STATUS) {
    g_deferred_links->link_queries++;
    *value = IsSet(g_deferred_links->linked, program) ? GL_TRUE : GL_FALSE;
  }
}
void GL_APIENTRY DeferredDetachShader(GLuint program, GLuint shader) {
  g_deferred_links->detached++;
}
void GL_APIENTRY DeferredDeleteShader(GLuint shader) {
  g_deferred_links->deleted_shaders++;
}
GLboolean GL_APIENTRY DeferredIsProgram(GLuint program) {
  return program != 0 ? GL_TRUE : GL_FALSE;
}
GLint GL_APIENTRY DeferredGetUniformLocation(GLuint program,
                                             const GLchar* name) {
  return -1;
}
void GL_APIENTRY DeferredGetText(GLuint object,
                                 GLsizei size,
                                 GLsizei* length,
                                 GLchar* text) {
  if (length) {
    *length = 0;
  }
  if (size > 0 && text) {
    text[0] = '\0';
  }
}
void* DeferredLinkResolver(const char* name) {
  if (strcmp(name, "glCreateShader") == 0) {
    return reinterpret_cast<void*>(DeferredCreateShader);
  }
  if (strcmp(name, "glCreateProgram") == 0) {
    return reinterpret_cast<void*>(DeferredCreateProgram);
  }
  if (strcmp(name, "glLinkProgram") == 0) {
    return reinterpret_cast<void*>(DeferredLinkProgram);
  }
  if (strcmp(name, "glGetShaderiv") == 0) {
    return reinterpret_cast<void*>(DeferredGetShaderiv);
  }
  if (strcmp(name, "glGetProgramiv") == 0) {
    return reinterpret_cast<void*>(DeferredGetProgramiv);
  }
  if (strcmp(name, "glDetachShader") == 0) {
    return reinterpret_cast<void*>(DeferredDetachShader);
  }
  if (strcmp(name, "glDeleteShader") == 0) {
    return reinterpret_cast<void*>(DeferredDeleteShader);
  }
  if (strcmp(name, "glIsProgram") == 0) {
    return reinterpret_cast<void*>(DeferredIsProgram);
  }
  if (strcmp(name, "glGetUniformLocation") == 0) {
    return reinterpret_cast<void*>(DeferredGetUniformLocation);
  }
  if (strcmp(name, "glGetShaderSource") == 0 ||
      strcmp(name, "glGetShaderInfoLog") == 0 ||
      strcmp(name, "glGetProgramInfoLog") == 0) {
    return reinterpret_cast<void*>(DeferredGetText);
  }
  return kMockResolverGLES(name);
}

}  // namespace

DeferredLinkHarness::DeferredLinkHarness(size_t max_pending_links,
                                         bool parallel_shader_compile) {
  g_deferred_links = &state;
  reset_deferred_links.SetClosure([]() { g_deferred_links = nullptr; });
  std::vector<const char*> extensions;
  if (parallel_shader_compile) {
    extensions.push_back("GL_KHR_parallel_shader_compile");
  }
  mock_gles = MockGLES::Init(extensions, "OpenGL ES 3.0 (ANGLE 2.1.0)",
                             DeferredLinkResolver);
  runner = std::make_shared<DeferredLinkRunner>();
  context = ContextGLES::Create(
      Flags{}, std::make_unique<ProcTableGLES>(DeferredLinkResolver),
      std::vector<std::shared_ptr<fml::Mapping>>{},
      /*enable_gpu_tracing=*/false, runner);
  FML_CHECK(context);
  worker = std::make_shared<ToggleWorker>(true);
  context->AddReactorWorker(worker);
  auto base_context = std::static_pointer_cast<Context>(context);
  std::shared_ptr<ShaderLibrary> shader_library =
      base_context->GetShaderLibrary();
  for (ShaderStage stage : {ShaderStage::kVertex, ShaderStage::kFragment}) {
    // ComputeShaderWithDefines inserts specialization constants after the
    // first line and rejects a source without a newline, so the source has
    // the #version first line that impellerc emits
    shader_library->RegisterFunction(
        "deferred", stage,
        std::make_shared<fml::DataMapping>(
            std::string("#version 100\nvoid main() {}")),
        [](bool result) { EXPECT_TRUE(result); });
  }
  desc.SetVertexDescriptor(std::make_shared<VertexDescriptor>());
  desc.AddStageEntrypoint(
      shader_library->GetFunction("deferred", ShaderStage::kVertex));
  desc.AddStageEntrypoint(
      shader_library->GetFunction("deferred", ShaderStage::kFragment));
  library = base_context->GetPipelineLibrary();
  PipelineLibraryGLES::Cast(*library).SetMaxPendingLinksForTesting(
      max_pending_links);
}

bool IsReady(const PipelineFuture<PipelineDescriptor>& future) {
  return future.future.wait_for(std::chrono::seconds(0)) ==
         std::future_status::ready;
}

}  // namespace impeller::testing
