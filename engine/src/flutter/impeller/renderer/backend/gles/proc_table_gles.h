// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <string>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/renderer/backend/gles/capabilities_gles.h"
#include "impeller/renderer/backend/gles/description_gles.h"
#include "impeller/renderer/backend/gles/gles.h"

namespace impeller {

const char* GLErrorToString(GLenum value);
bool GLErrorIsFatal(GLenum value);

struct AutoErrorCheck {
  const PFNGLGETERRORPROC error_fn;
  const char* name;

  AutoErrorCheck(PFNGLGETERRORPROC error, const char* name)
      : error_fn(error), name(name) {}

  ~AutoErrorCheck() {
    if (error_fn) {
      auto error = error_fn();
      if (error == GL_NO_ERROR) {
        return;
      }
      if (GLErrorIsFatal(error)) {
        FML_LOG(FATAL) << "Fatal GL Error " << GLErrorToString(error) << "("
                       << error << ")"
                       << " encountered on call to " << name;
      } else {
        FML_LOG(ERROR) << "GL Error " << GLErrorToString(error) << "(" << error
                       << ")"
                       << " encountered on call to " << name;
      }
    }
  }
};

template <class T>
struct GLProc {
  using GLFunctionType = T;

  //----------------------------------------------------------------------------
  /// The name of the GL function.
  ///
  const char* name = nullptr;

  //----------------------------------------------------------------------------
  /// The pointer to the GL function.
  ///
  GLFunctionType* function = nullptr;

  //----------------------------------------------------------------------------
  /// An optional error function. If present, all calls will be followed by an
  /// error check.
  ///
  PFNGLGETERRORPROC error_fn = nullptr;

  //----------------------------------------------------------------------------
  /// @brief      Call the GL function with the appropriate parameters. Lookup
  ///             the documentation for the GL function being called to
  ///             understand the arguments and return types. The arguments
  ///             types must match and will be type checked.
  ///
  template <class... Args>
  auto operator()(Args&&... args) const {
#ifdef IMPELLER_DEBUG
    AutoErrorCheck error(error_fn, name);
#endif  // IMPELLER_DEBUG
#ifdef IMPELLER_TRACE_ALL_GL_CALLS
    TRACE_EVENT0("impeller", name);
#endif  // IMPELLER_TRACE_ALL_GL_CALLS
    return function(std::forward<Args>(args)...);
  }

  constexpr bool IsAvailable() const { return function != nullptr; }

  void Reset() {
    name = nullptr;
    function = nullptr;
    error_fn = nullptr;
  }
};

#define FOR_EACH_IMPELLER_PROC(PROC)         \
  PROC(ActiveTexture);                       \
  PROC(AttachShader);                        \
  PROC(BindAttribLocation);                  \
  PROC(BindBuffer);                          \
  PROC(BindFramebuffer);                     \
  PROC(BindRenderbuffer);                    \
  PROC(BindTexture);                         \
  PROC(BlendEquationSeparate);               \
  PROC(BlendFuncSeparate);                   \
  PROC(BufferData);                          \
  PROC(CheckFramebufferStatus);              \
  PROC(Clear);                               \
  PROC(ClearColor);                          \
  PROC(ClearDepthf);                         \
  PROC(ClearStencil);                        \
  PROC(ColorMask);                           \
  PROC(CompileShader);                       \
  PROC(CreateProgram);                       \
  PROC(CreateShader);                        \
  PROC(CullFace);                            \
  PROC(DeleteBuffers);                       \
  PROC(DeleteFramebuffers);                  \
  PROC(DeleteProgram);                       \
  PROC(DeleteRenderbuffers);                 \
  PROC(DeleteShader);                        \
  PROC(DeleteTextures);                      \
  PROC(DepthFunc);                           \
  PROC(DepthMask);                           \
  PROC(DepthRangef);                         \
  PROC(DetachShader);                        \
  PROC(Disable);                             \
  PROC(DisableVertexAttribArray);            \
  PROC(DrawArrays);                          \
  PROC(DrawElements);                        \
  PROC(Enable);                              \
  PROC(EnableVertexAttribArray);             \
  PROC(Flush);                               \
  PROC(FramebufferRenderbuffer);             \
  PROC(FramebufferTexture2D);                \
  PROC(FrontFace);                           \
  PROC(GenBuffers);                          \
  PROC(GenerateMipmap);                      \
  PROC(GenFramebuffers);                     \
  PROC(GenRenderbuffers);                    \
  PROC(GenTextures);                         \
  PROC(GetActiveUniform);                    \
  PROC(GetBooleanv);                         \
  PROC(GetFloatv);                           \
  PROC(GetFramebufferAttachmentParameteriv); \
  PROC(GetIntegerv);                         \
  PROC(GetProgramInfoLog);                   \
  PROC(GetProgramiv);                        \
  PROC(GetShaderInfoLog);                    \
  PROC(GetShaderiv);                         \
  PROC(GetString);                           \
  PROC(GetStringi);                          \
  PROC(GetUniformLocation);                  \
  PROC(IsBuffer);                            \
  PROC(IsFramebuffer);                       \
  PROC(IsProgram);                           \
  PROC(IsRenderbuffer);                      \
  PROC(IsShader);                            \
  PROC(IsTexture);                           \
  PROC(LinkProgram);                         \
  PROC(RenderbufferStorage);                 \
  PROC(Scissor);                             \
  PROC(ShaderBinary);                        \
  PROC(ShaderSource);                        \
  PROC(StencilFuncSeparate);                 \
  PROC(StencilMaskSeparate);                 \
  PROC(StencilOpSeparate);                   \
  PROC(TexImage2D);                          \
  PROC(TexParameteri);                       \
  PROC(Uniform1fv);                          \
  PROC(Uniform1i);                           \
  PROC(Uniform2fv);                          \
  PROC(Uniform3fv);                          \
  PROC(Uniform4fv);                          \
  PROC(UniformMatrix4fv);                    \
  PROC(UseProgram);                          \
  PROC(VertexAttribPointer);                 \
  PROC(Viewport);                            \
  PROC(ReadPixels);

#define FOR_EACH_IMPELLER_GLES3_PROC(PROC) PROC(BlitFramebuffer);

#define FOR_EACH_IMPELLER_EXT_PROC(PROC)   \
  PROC(DiscardFramebufferEXT);             \
  PROC(FramebufferTexture2DMultisampleEXT) \
  PROC(PushDebugGroupKHR);                 \
  PROC(PopDebugGroupKHR);                  \
  PROC(ObjectLabelKHR);                    \
  PROC(RenderbufferStorageMultisampleEXT);

enum class DebugResourceType {
  kTexture,
  kBuffer,
  kProgram,
  kShader,
  kRenderBuffer,
  kFrameBuffer,
};

class ProcTableGLES {
 public:
  using Resolver = std::function<void*(const char* function_name)>;
  explicit ProcTableGLES(Resolver resolver);

  ~ProcTableGLES();

#define IMPELLER_PROC(name) \
  GLProc<decltype(gl##name)> name = {"gl" #name, nullptr};

  FOR_EACH_IMPELLER_PROC(IMPELLER_PROC);
  FOR_EACH_IMPELLER_GLES3_PROC(IMPELLER_PROC);
  FOR_EACH_IMPELLER_EXT_PROC(IMPELLER_PROC);

#undef IMPELLER_PROC

  bool IsValid() const;

  void ShaderSourceMapping(GLuint shader, const fml::Mapping& mapping) const;

  const DescriptionGLES* GetDescription() const;

  const CapabilitiesGLES* GetCapabilities() const;

  std::string DescribeCurrentFramebuffer() const;

  std::string GetProgramInfoLogString(GLuint program) const;

  bool IsCurrentFramebufferComplete() const;

  bool SetDebugLabel(DebugResourceType type,
                     GLint name,
                     const std::string& label) const;

  void PushDebugGroup(const std::string& string) const;

  void PopDebugGroup() const;

 private:
  bool is_valid_ = false;
  std::unique_ptr<DescriptionGLES> description_;
  std::unique_ptr<CapabilitiesGLES> capabilities_;
  GLint debug_label_max_length_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(ProcTableGLES);
};

}  // namespace impeller
