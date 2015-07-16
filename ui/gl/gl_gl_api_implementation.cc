// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_gl_api_implementation.h"

#include <algorithm>
#include <vector>

#include "base/command_line.h"
#include "base/strings/string_util.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_state_restorer.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gl_switches.h"
#include "ui/gl/gl_version_info.h"

namespace gfx {

// The GL Api being used. This could be g_real_gl or gl_trace_gl
static GLApi* g_gl = NULL;
// A GL Api that calls directly into the driver.
static RealGLApi* g_real_gl = NULL;
// A GL Api that does nothing but warn about illegal GL calls without a context
// current.
static NoContextGLApi* g_no_context_gl = NULL;
// A GL Api that calls TRACE and then calls another GL api.
static TraceGLApi* g_trace_gl = NULL;
// GL version used when initializing dynamic bindings.
static GLVersionInfo* g_version_info = NULL;

namespace {

static inline GLenum GetInternalFormat(GLenum internal_format) {
  if (gfx::GetGLImplementation() != gfx::kGLImplementationEGLGLES2) {
    if (internal_format == GL_BGRA_EXT || internal_format == GL_BGRA8_EXT)
      return GL_RGBA8;
  }
  return internal_format;
}

// TODO(epenner): Could the above function be merged into this and removed?
static inline GLenum GetTexInternalFormat(GLenum internal_format,
                                          GLenum format,
                                          GLenum type) {
  GLenum gl_internal_format = GetInternalFormat(internal_format);

  // g_version_info must be initialized when this function is bound.
  DCHECK(gfx::g_version_info);
  if (gfx::g_version_info->is_es3) {
    if (format == GL_RED_EXT) {
      switch (type) {
        case GL_UNSIGNED_BYTE:
          gl_internal_format = GL_R8_EXT;
          break;
        case GL_HALF_FLOAT_OES:
          gl_internal_format = GL_R16F_EXT;
          break;
        case GL_FLOAT:
          gl_internal_format = GL_R32F_EXT;
          break;
        default:
          NOTREACHED();
          break;
      }
      return gl_internal_format;
    } else if (format == GL_RG_EXT) {
      switch (type) {
        case GL_UNSIGNED_BYTE:
          gl_internal_format = GL_RG8_EXT;
          break;
        case GL_HALF_FLOAT_OES:
          gl_internal_format = GL_RG16F_EXT;
          break;
        case GL_FLOAT:
          gl_internal_format = GL_RG32F_EXT;
          break;
        default:
          NOTREACHED();
          break;
      }
      return gl_internal_format;
    }
  }

  if (type == GL_FLOAT && gfx::g_version_info->is_angle &&
      gfx::g_version_info->is_es && gfx::g_version_info->major_version == 2) {
    // It's possible that the texture is using a sized internal format, and
    // ANGLE exposing GLES2 API doesn't support those.
    // TODO(oetuaho@nvidia.com): Remove these conversions once ANGLE has the
    // support.
    // http://code.google.com/p/angleproject/issues/detail?id=556
    switch (format) {
      case GL_RGBA:
        gl_internal_format = GL_RGBA;
        break;
      case GL_RGB:
        gl_internal_format = GL_RGB;
        break;
      default:
        break;
    }
  }

  if (gfx::g_version_info->is_es)
    return gl_internal_format;

  if (type == GL_FLOAT) {
    switch (format) {
      case GL_RGBA:
        gl_internal_format = GL_RGBA32F_ARB;
        break;
      case GL_RGB:
        gl_internal_format = GL_RGB32F_ARB;
        break;
      case GL_LUMINANCE_ALPHA:
        gl_internal_format = GL_LUMINANCE_ALPHA32F_ARB;
        break;
      case GL_LUMINANCE:
        gl_internal_format = GL_LUMINANCE32F_ARB;
        break;
      case GL_ALPHA:
        gl_internal_format = GL_ALPHA32F_ARB;
        break;
      default:
        NOTREACHED();
        break;
    }
  } else if (type == GL_HALF_FLOAT_OES) {
    switch (format) {
      case GL_RGBA:
        gl_internal_format = GL_RGBA16F_ARB;
        break;
      case GL_RGB:
        gl_internal_format = GL_RGB16F_ARB;
        break;
      case GL_LUMINANCE_ALPHA:
        gl_internal_format = GL_LUMINANCE_ALPHA16F_ARB;
        break;
      case GL_LUMINANCE:
        gl_internal_format = GL_LUMINANCE16F_ARB;
        break;
      case GL_ALPHA:
        gl_internal_format = GL_ALPHA16F_ARB;
        break;
      default:
        NOTREACHED();
        break;
    }
  }
  return gl_internal_format;
}

static inline GLenum GetTexType(GLenum type) {
   if (gfx::GetGLImplementation() != gfx::kGLImplementationEGLGLES2) {
     if (type == GL_HALF_FLOAT_OES)
       return GL_HALF_FLOAT_ARB;
   }
   return type;
}

static void GL_BINDING_CALL CustomTexImage2D(
    GLenum target, GLint level, GLint internalformat,
    GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type,
    const void* pixels) {
  GLenum gl_internal_format = GetTexInternalFormat(
      internalformat, format, type);
  GLenum gl_type = GetTexType(type);
  g_driver_gl.orig_fn.glTexImage2DFn(
      target, level, gl_internal_format, width, height, border, format, gl_type,
      pixels);
}

static void GL_BINDING_CALL CustomTexSubImage2D(
      GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
      GLsizei height, GLenum format, GLenum type, const void* pixels) {
  GLenum gl_type = GetTexType(type);
  g_driver_gl.orig_fn.glTexSubImage2DFn(
      target, level, xoffset, yoffset, width, height, format, gl_type, pixels);
}

static void GL_BINDING_CALL CustomTexStorage2DEXT(
    GLenum target, GLsizei levels, GLenum internalformat, GLsizei width,
    GLsizei height) {
  GLenum gl_internal_format = GetInternalFormat(internalformat);
  g_driver_gl.orig_fn.glTexStorage2DEXTFn(
      target, levels, gl_internal_format, width, height);
}

static void GL_BINDING_CALL CustomRenderbufferStorageEXT(
    GLenum target, GLenum internalformat, GLsizei width, GLsizei height) {
  GLenum gl_internal_format = GetInternalFormat(internalformat);
  g_driver_gl.orig_fn.glRenderbufferStorageEXTFn(
      target, gl_internal_format, width, height);
}

// The ANGLE and IMG variants of glRenderbufferStorageMultisample currently do
// not support BGRA render buffers so only the EXT one is customized. If
// GL_CHROMIUM_renderbuffer_format_BGRA8888 support is added to ANGLE then the
// ANGLE version should also be customized.
static void GL_BINDING_CALL CustomRenderbufferStorageMultisampleEXT(
    GLenum target, GLsizei samples, GLenum internalformat, GLsizei width,
    GLsizei height) {
  GLenum gl_internal_format = GetInternalFormat(internalformat);
  g_driver_gl.orig_fn.glRenderbufferStorageMultisampleEXTFn(
      target, samples, gl_internal_format, width, height);
}

}  // anonymous namespace

void DriverGL::InitializeCustomDynamicBindings(GLContext* context) {
  InitializeDynamicBindings(context);

  DCHECK(orig_fn.glTexImage2DFn == NULL);
  orig_fn.glTexImage2DFn = fn.glTexImage2DFn;
  fn.glTexImage2DFn =
      reinterpret_cast<glTexImage2DProc>(CustomTexImage2D);

  DCHECK(orig_fn.glTexSubImage2DFn == NULL);
  orig_fn.glTexSubImage2DFn = fn.glTexSubImage2DFn;
  fn.glTexSubImage2DFn =
      reinterpret_cast<glTexSubImage2DProc>(CustomTexSubImage2D);

  DCHECK(orig_fn.glTexStorage2DEXTFn == NULL);
  orig_fn.glTexStorage2DEXTFn = fn.glTexStorage2DEXTFn;
  fn.glTexStorage2DEXTFn =
      reinterpret_cast<glTexStorage2DEXTProc>(CustomTexStorage2DEXT);

  DCHECK(orig_fn.glRenderbufferStorageEXTFn == NULL);
  orig_fn.glRenderbufferStorageEXTFn = fn.glRenderbufferStorageEXTFn;
  fn.glRenderbufferStorageEXTFn =
      reinterpret_cast<glRenderbufferStorageEXTProc>(
      CustomRenderbufferStorageEXT);

  DCHECK(orig_fn.glRenderbufferStorageMultisampleEXTFn == NULL);
  orig_fn.glRenderbufferStorageMultisampleEXTFn =
      fn.glRenderbufferStorageMultisampleEXTFn;
  fn.glRenderbufferStorageMultisampleEXTFn =
      reinterpret_cast<glRenderbufferStorageMultisampleEXTProc>(
      CustomRenderbufferStorageMultisampleEXT);
}

static void GL_BINDING_CALL NullDrawClearFn(GLbitfield mask) {
  if (!g_driver_gl.null_draw_bindings_enabled)
    g_driver_gl.orig_fn.glClearFn(mask);
}

static void GL_BINDING_CALL
NullDrawDrawArraysFn(GLenum mode, GLint first, GLsizei count) {
  if (!g_driver_gl.null_draw_bindings_enabled)
    g_driver_gl.orig_fn.glDrawArraysFn(mode, first, count);
}

static void GL_BINDING_CALL NullDrawDrawElementsFn(GLenum mode,
                                                   GLsizei count,
                                                   GLenum type,
                                                   const void* indices) {
  if (!g_driver_gl.null_draw_bindings_enabled)
    g_driver_gl.orig_fn.glDrawElementsFn(mode, count, type, indices);
}

void DriverGL::InitializeNullDrawBindings() {
  DCHECK(orig_fn.glClearFn == NULL);
  orig_fn.glClearFn = fn.glClearFn;
  fn.glClearFn = NullDrawClearFn;

  DCHECK(orig_fn.glDrawArraysFn == NULL);
  orig_fn.glDrawArraysFn = fn.glDrawArraysFn;
  fn.glDrawArraysFn = NullDrawDrawArraysFn;

  DCHECK(orig_fn.glDrawElementsFn == NULL);
  orig_fn.glDrawElementsFn = fn.glDrawElementsFn;
  fn.glDrawElementsFn = NullDrawDrawElementsFn;

  null_draw_bindings_enabled = true;
}

bool DriverGL::HasInitializedNullDrawBindings() {
  return orig_fn.glClearFn != NULL && orig_fn.glDrawArraysFn != NULL &&
         orig_fn.glDrawElementsFn != NULL;
}

bool DriverGL::SetNullDrawBindingsEnabled(bool enabled) {
  DCHECK(orig_fn.glClearFn != NULL);
  DCHECK(orig_fn.glDrawArraysFn != NULL);
  DCHECK(orig_fn.glDrawElementsFn != NULL);

  bool before = null_draw_bindings_enabled;
  null_draw_bindings_enabled = enabled;
  return before;
}

void InitializeStaticGLBindingsGL() {
  g_current_gl_context_tls = new base::ThreadLocalPointer<GLApi>;
  g_driver_gl.InitializeStaticBindings();
  if (!g_real_gl) {
    g_real_gl = new RealGLApi();
    g_trace_gl = new TraceGLApi(g_real_gl);
    g_no_context_gl = new NoContextGLApi();
  }
  g_real_gl->Initialize(&g_driver_gl);
  g_gl = g_real_gl;
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableGPUServiceTracing)) {
    g_gl = g_trace_gl;
  }
  SetGLToRealGLApi();
}

GLApi* GetCurrentGLApi() {
  return g_current_gl_context_tls->Get();
}

void SetGLApi(GLApi* api) {
  g_current_gl_context_tls->Set(api);
}

void SetGLToRealGLApi() {
  SetGLApi(g_gl);
}

void SetGLApiToNoContext() {
  SetGLApi(g_no_context_gl);
}

const GLVersionInfo* GetGLVersionInfo() {
  return g_version_info;
}

void InitializeDynamicGLBindingsGL(GLContext* context) {
  g_driver_gl.InitializeCustomDynamicBindings(context);
  DCHECK(context && context->IsCurrent(NULL) && !g_version_info);
  g_version_info = new GLVersionInfo(context->GetGLVersion().c_str(),
      context->GetGLRenderer().c_str());
}

void InitializeDebugGLBindingsGL() {
  g_driver_gl.InitializeDebugBindings();
}

void InitializeNullDrawGLBindingsGL() {
  g_driver_gl.InitializeNullDrawBindings();
}

bool HasInitializedNullDrawGLBindingsGL() {
  return g_driver_gl.HasInitializedNullDrawBindings();
}

bool SetNullDrawGLBindingsEnabledGL(bool enabled) {
  return g_driver_gl.SetNullDrawBindingsEnabled(enabled);
}

void ClearGLBindingsGL() {
  if (g_real_gl) {
    delete g_real_gl;
    g_real_gl = NULL;
  }
  if (g_trace_gl) {
    delete g_trace_gl;
    g_trace_gl = NULL;
  }
  if (g_no_context_gl) {
    delete g_no_context_gl;
    g_no_context_gl = NULL;
  }
  g_gl = NULL;
  g_driver_gl.ClearBindings();
  if (g_current_gl_context_tls) {
    delete g_current_gl_context_tls;
    g_current_gl_context_tls = NULL;
  }
  if (g_version_info) {
    delete g_version_info;
    g_version_info = NULL;
  }
}

GLApi::GLApi() {
}

GLApi::~GLApi() {
  if (GetCurrentGLApi() == this)
    SetGLApi(NULL);
}

GLApiBase::GLApiBase()
    : driver_(NULL) {
}

GLApiBase::~GLApiBase() {
}

void GLApiBase::InitializeBase(DriverGL* driver) {
  driver_ = driver;
}

RealGLApi::RealGLApi() {
}

RealGLApi::~RealGLApi() {
}

void RealGLApi::Initialize(DriverGL* driver) {
  InitializeBase(driver);
}

void RealGLApi::glFlushFn() {
  GLApiBase::glFlushFn();
}

void RealGLApi::glFinishFn() {
  GLApiBase::glFinishFn();
}

TraceGLApi::~TraceGLApi() {
}

NoContextGLApi::NoContextGLApi() {
}

NoContextGLApi::~NoContextGLApi() {
}

VirtualGLApi::VirtualGLApi()
    : real_context_(NULL),
      current_context_(NULL) {
}

VirtualGLApi::~VirtualGLApi() {
}

void VirtualGLApi::Initialize(DriverGL* driver, GLContext* real_context) {
  InitializeBase(driver);
  real_context_ = real_context;

  DCHECK(real_context->IsCurrent(NULL));
  std::string ext_string(
      reinterpret_cast<const char*>(driver_->fn.glGetStringFn(GL_EXTENSIONS)));
  std::vector<std::string> ext;
  Tokenize(ext_string, " ", &ext);

  std::vector<std::string>::iterator it;
  // We can't support GL_EXT_occlusion_query_boolean which is
  // based on GL_ARB_occlusion_query without a lot of work virtualizing
  // queries.
  it = std::find(ext.begin(), ext.end(), "GL_EXT_occlusion_query_boolean");
  if (it != ext.end())
    ext.erase(it);

  extensions_ = JoinString(ext, " ");
}

bool VirtualGLApi::MakeCurrent(GLContext* virtual_context, GLSurface* surface) {
  bool switched_contexts = g_current_gl_context_tls->Get() != this;
  GLSurface* current_surface = GLSurface::GetCurrent();
  if (switched_contexts || surface != current_surface) {
    // MakeCurrent 'lite' path that avoids potentially expensive MakeCurrent()
    // calls if the GLSurface uses the same underlying surface or renders to
    // an FBO.
    if (switched_contexts || !current_surface ||
        !virtual_context->IsCurrent(surface)) {
      if (!real_context_->MakeCurrent(surface)) {
        return false;
      }
    }
  }

  bool state_dirtied_externally = real_context_->GetStateWasDirtiedExternally();
  real_context_->SetStateWasDirtiedExternally(false);

  DCHECK_EQ(real_context_, GLContext::GetRealCurrent());
  DCHECK(real_context_->IsCurrent(NULL));
  DCHECK(virtual_context->IsCurrent(surface));

  if (state_dirtied_externally || switched_contexts ||
      virtual_context != current_context_) {
#if DCHECK_IS_ON()
    GLenum error = glGetErrorFn();
    // Accepting a context loss error here enables using debug mode to work on
    // context loss handling in virtual context mode.
    // There should be no other errors from the previous context leaking into
    // the new context.
    DCHECK(error == GL_NO_ERROR || error == GL_CONTEXT_LOST_KHR);
#endif

    // Set all state that is different from the real state
    GLApi* temp = GetCurrentGLApi();
    SetGLToRealGLApi();
    if (virtual_context->GetGLStateRestorer()->IsInitialized()) {
      virtual_context->GetGLStateRestorer()->RestoreState(
          (current_context_ && !state_dirtied_externally && !switched_contexts)
              ? current_context_->GetGLStateRestorer()
              : NULL);
    }
    SetGLApi(temp);
    current_context_ = virtual_context;
  }
  SetGLApi(this);

  virtual_context->SetCurrent(surface);
  if (!surface->OnMakeCurrent(virtual_context)) {
    LOG(ERROR) << "Could not make GLSurface current.";
    return false;
  }
  return true;
}

void VirtualGLApi::OnReleaseVirtuallyCurrent(GLContext* virtual_context) {
  if (current_context_ == virtual_context)
    current_context_ = NULL;
}

const GLubyte* VirtualGLApi::glGetStringFn(GLenum name) {
  switch (name) {
    case GL_EXTENSIONS:
      return reinterpret_cast<const GLubyte*>(extensions_.c_str());
    default:
      return driver_->fn.glGetStringFn(name);
  }
}

void VirtualGLApi::glFlushFn() {
  GLApiBase::glFlushFn();
}

void VirtualGLApi::glFinishFn() {
  GLApiBase::glFinishFn();
}

ScopedSetGLToRealGLApi::ScopedSetGLToRealGLApi()
    : old_gl_api_(GetCurrentGLApi()) {
  SetGLToRealGLApi();
}

ScopedSetGLToRealGLApi::~ScopedSetGLToRealGLApi() {
  SetGLApi(old_gl_api_);
}

}  // namespace gfx
