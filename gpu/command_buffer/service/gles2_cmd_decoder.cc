// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

#include <stdio.h>

#include <algorithm>
#include <list>
#include <map>
#include <queue>
#include <stack>
#include <string>
#include <vector>

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/callback_helpers.h"
#include "base/command_line.h"
#include "base/memory/scoped_ptr.h"
#include "base/numerics/safe_math.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/trace_event/trace_event.h"
#include "base/trace_event/trace_event_synthetic_delay.h"
#include "build/build_config.h"
#define GLES2_GPU_SERVICE 1
#include "gpu/command_buffer/common/debug_marker_manager.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/common/id_allocator.h"
#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"
#include "gpu/command_buffer/service/async_pixel_transfer_manager.h"
#include "gpu/command_buffer/service/buffer_manager.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/context_state.h"
#include "gpu/command_buffer/service/error_state.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/service/framebuffer_manager.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_clear_framebuffer.h"
#include "gpu/command_buffer/service/gles2_cmd_copy_texture_chromium.h"
#include "gpu/command_buffer/service/gles2_cmd_validation.h"
#include "gpu/command_buffer/service/gpu_state_tracer.h"
#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/command_buffer/service/gpu_tracer.h"
#include "gpu/command_buffer/service/image_manager.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/command_buffer/service/program_manager.h"
#include "gpu/command_buffer/service/query_manager.h"
#include "gpu/command_buffer/service/renderbuffer_manager.h"
#include "gpu/command_buffer/service/shader_manager.h"
#include "gpu/command_buffer/service/shader_translator.h"
#include "gpu/command_buffer/service/shader_translator_cache.h"
#include "gpu/command_buffer/service/texture_manager.h"
#include "gpu/command_buffer/service/valuebuffer_manager.h"
#include "gpu/command_buffer/service/vertex_array_manager.h"
#include "gpu/command_buffer/service/vertex_attrib_manager.h"
#include "third_party/smhasher/src/City.h"
#include "ui/gl/gl_fence.h"
#include "ui/gl/gl_image.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface.h"

#if defined(OS_MACOSX)
#include <IOSurface/IOSurfaceAPI.h>
// Note that this must be included after gl_bindings.h to avoid conflicts.
#include <OpenGL/CGLIOSurface.h>
#endif

#if defined(OS_WIN)
#include "base/win/win_util.h"
#endif

namespace gpu {
namespace gles2 {

namespace {

const char kOESDerivativeExtension[] = "GL_OES_standard_derivatives";
const char kEXTFragDepthExtension[] = "GL_EXT_frag_depth";
const char kEXTDrawBuffersExtension[] = "GL_EXT_draw_buffers";
const char kEXTShaderTextureLodExtension[] = "GL_EXT_shader_texture_lod";

const GLfloat kIdentityMatrix[16] = {1.0f, 0.0f, 0.0f, 0.0f,
                                     0.0f, 1.0f, 0.0f, 0.0f,
                                     0.0f, 0.0f, 1.0f, 0.0f,
                                     0.0f, 0.0f, 0.0f, 1.0f};

static bool PrecisionMeetsSpecForHighpFloat(GLint rangeMin,
                                            GLint rangeMax,
                                            GLint precision) {
  return (rangeMin >= 62) && (rangeMax >= 62) && (precision >= 16);
}

static void GetShaderPrecisionFormatImpl(GLenum shader_type,
                                         GLenum precision_type,
                                         GLint* range, GLint* precision) {
  switch (precision_type) {
    case GL_LOW_INT:
    case GL_MEDIUM_INT:
    case GL_HIGH_INT:
      // These values are for a 32-bit twos-complement integer format.
      range[0] = 31;
      range[1] = 30;
      *precision = 0;
      break;
    case GL_LOW_FLOAT:
    case GL_MEDIUM_FLOAT:
    case GL_HIGH_FLOAT:
      // These values are for an IEEE single-precision floating-point format.
      range[0] = 127;
      range[1] = 127;
      *precision = 23;
      break;
    default:
      NOTREACHED();
      break;
  }

  if (gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2 &&
      gfx::g_driver_gl.fn.glGetShaderPrecisionFormatFn) {
    // This function is sometimes defined even though it's really just
    // a stub, so we need to set range and precision as if it weren't
    // defined before calling it.
    // On Mac OS with some GPUs, calling this generates a
    // GL_INVALID_OPERATION error. Avoid calling it on non-GLES2
    // platforms.
    glGetShaderPrecisionFormat(shader_type, precision_type,
                               range, precision);

    // TODO(brianderson): Make the following official workarounds.

    // Some drivers have bugs where they report the ranges as a negative number.
    // Taking the absolute value here shouldn't hurt because negative numbers
    // aren't expected anyway.
    range[0] = abs(range[0]);
    range[1] = abs(range[1]);

    // If the driver reports a precision for highp float that isn't actually
    // highp, don't pretend like it's supported because shader compilation will
    // fail anyway.
    if (precision_type == GL_HIGH_FLOAT &&
        !PrecisionMeetsSpecForHighpFloat(range[0], range[1], *precision)) {
      range[0] = 0;
      range[1] = 0;
      *precision = 0;
    }
  }
}

static gfx::OverlayTransform GetGFXOverlayTransform(GLenum plane_transform) {
  switch (plane_transform) {
    case GL_OVERLAY_TRANSFORM_NONE_CHROMIUM:
      return gfx::OVERLAY_TRANSFORM_NONE;
    case GL_OVERLAY_TRANSFORM_FLIP_HORIZONTAL_CHROMIUM:
      return gfx::OVERLAY_TRANSFORM_FLIP_HORIZONTAL;
    case GL_OVERLAY_TRANSFORM_FLIP_VERTICAL_CHROMIUM:
      return gfx::OVERLAY_TRANSFORM_FLIP_VERTICAL;
    case GL_OVERLAY_TRANSFORM_ROTATE_90_CHROMIUM:
      return gfx::OVERLAY_TRANSFORM_ROTATE_90;
    case GL_OVERLAY_TRANSFORM_ROTATE_180_CHROMIUM:
      return gfx::OVERLAY_TRANSFORM_ROTATE_180;
    case GL_OVERLAY_TRANSFORM_ROTATE_270_CHROMIUM:
      return gfx::OVERLAY_TRANSFORM_ROTATE_270;
    default:
      return gfx::OVERLAY_TRANSFORM_INVALID;
  }
}

}  // namespace

class GLES2DecoderImpl;

// Local versions of the SET_GL_ERROR macros
#define LOCAL_SET_GL_ERROR(error, function_name, msg) \
    ERRORSTATE_SET_GL_ERROR(state_.GetErrorState(), error, function_name, msg)
#define LOCAL_SET_GL_ERROR_INVALID_ENUM(function_name, value, label) \
    ERRORSTATE_SET_GL_ERROR_INVALID_ENUM(state_.GetErrorState(), \
                                         function_name, value, label)
#define LOCAL_SET_GL_ERROR_INVALID_PARAM(error, function_name, pname) \
    ERRORSTATE_SET_GL_ERROR_INVALID_PARAM(state_.GetErrorState(), error, \
                                          function_name, pname)
#define LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER(function_name) \
    ERRORSTATE_COPY_REAL_GL_ERRORS_TO_WRAPPER(state_.GetErrorState(), \
                                              function_name)
#define LOCAL_PEEK_GL_ERROR(function_name) \
    ERRORSTATE_PEEK_GL_ERROR(state_.GetErrorState(), function_name)
#define LOCAL_CLEAR_REAL_GL_ERRORS(function_name) \
    ERRORSTATE_CLEAR_REAL_GL_ERRORS(state_.GetErrorState(), function_name)
#define LOCAL_PERFORMANCE_WARNING(msg) \
    PerformanceWarning(__FILE__, __LINE__, msg)
#define LOCAL_RENDER_WARNING(msg) \
    RenderWarning(__FILE__, __LINE__, msg)

// Check that certain assumptions the code makes are true. There are places in
// the code where shared memory is passed direclty to GL. Example, glUniformiv,
// glShaderSource. The command buffer code assumes GLint and GLsizei (and maybe
// a few others) are 32bits. If they are not 32bits the code will have to change
// to call those GL functions with service side memory and then copy the results
// to shared memory, converting the sizes.
static_assert(sizeof(GLint) == sizeof(uint32),  // NOLINT
              "GLint should be the same size as uint32");
static_assert(sizeof(GLsizei) == sizeof(uint32),  // NOLINT
              "GLsizei should be the same size as uint32");
static_assert(sizeof(GLfloat) == sizeof(float),  // NOLINT
              "GLfloat should be the same size as float");

// TODO(kbr): the use of this anonymous namespace core dumps the
// linker on Mac OS X 10.6 when the symbol ordering file is used
// namespace {

// Returns the address of the first byte after a struct.
template <typename T>
const void* AddressAfterStruct(const T& pod) {
  return reinterpret_cast<const uint8*>(&pod) + sizeof(pod);
}

// Returns the address of the frst byte after the struct or NULL if size >
// immediate_data_size.
template <typename RETURN_TYPE, typename COMMAND_TYPE>
RETURN_TYPE GetImmediateDataAs(const COMMAND_TYPE& pod,
                               uint32 size,
                               uint32 immediate_data_size) {
  return (size <= immediate_data_size) ?
      static_cast<RETURN_TYPE>(const_cast<void*>(AddressAfterStruct(pod))) :
      NULL;
}

// Computes the data size for certain gl commands like glUniform.
bool ComputeDataSize(
    GLuint count,
    size_t size,
    unsigned int elements_per_unit,
    uint32* dst) {
  uint32 value;
  if (!SafeMultiplyUint32(count, size, &value)) {
    return false;
  }
  if (!SafeMultiplyUint32(value, elements_per_unit, &value)) {
    return false;
  }
  *dst = value;
  return true;
}

// Return true if a character belongs to the ASCII subset as defined in
// GLSL ES 1.0 spec section 3.1.
static bool CharacterIsValidForGLES(unsigned char c) {
  // Printing characters are valid except " $ ` @ \ ' DEL.
  if (c >= 32 && c <= 126 &&
      c != '"' &&
      c != '$' &&
      c != '`' &&
      c != '@' &&
      c != '\\' &&
      c != '\'') {
    return true;
  }
  // Horizontal tab, line feed, vertical tab, form feed, carriage return
  // are also valid.
  if (c >= 9 && c <= 13) {
    return true;
  }

  return false;
}

static bool StringIsValidForGLES(const char* str) {
  for (; *str; ++str) {
    if (!CharacterIsValidForGLES(*str)) {
      return false;
    }
  }
  return true;
}

// This class prevents any GL errors that occur when it is in scope from
// being reported to the client.
class ScopedGLErrorSuppressor {
 public:
  explicit ScopedGLErrorSuppressor(
      const char* function_name, ErrorState* error_state);
  ~ScopedGLErrorSuppressor();
 private:
  const char* function_name_;
  ErrorState* error_state_;
  DISALLOW_COPY_AND_ASSIGN(ScopedGLErrorSuppressor);
};

// Temporarily changes a decoder's bound texture and restore it when this
// object goes out of scope. Also temporarily switches to using active texture
// unit zero in case the client has changed that to something invalid.
class ScopedTextureBinder {
 public:
  explicit ScopedTextureBinder(ContextState* state, GLuint id, GLenum target);
  ~ScopedTextureBinder();

 private:
  ContextState* state_;
  GLenum target_;
  DISALLOW_COPY_AND_ASSIGN(ScopedTextureBinder);
};

// Temporarily changes a decoder's bound render buffer and restore it when this
// object goes out of scope.
class ScopedRenderBufferBinder {
 public:
  explicit ScopedRenderBufferBinder(ContextState* state, GLuint id);
  ~ScopedRenderBufferBinder();

 private:
  ContextState* state_;
  DISALLOW_COPY_AND_ASSIGN(ScopedRenderBufferBinder);
};

// Temporarily changes a decoder's bound frame buffer and restore it when this
// object goes out of scope.
class ScopedFrameBufferBinder {
 public:
  explicit ScopedFrameBufferBinder(GLES2DecoderImpl* decoder, GLuint id);
  ~ScopedFrameBufferBinder();

 private:
  GLES2DecoderImpl* decoder_;
  DISALLOW_COPY_AND_ASSIGN(ScopedFrameBufferBinder);
};

// Temporarily changes a decoder's bound frame buffer to a resolved version of
// the multisampled offscreen render buffer if that buffer is multisampled, and,
// if it is bound or enforce_internal_framebuffer is true. If internal is
// true, the resolved framebuffer is not visible to the parent.
class ScopedResolvedFrameBufferBinder {
 public:
  explicit ScopedResolvedFrameBufferBinder(GLES2DecoderImpl* decoder,
                                           bool enforce_internal_framebuffer,
                                           bool internal);
  ~ScopedResolvedFrameBufferBinder();

 private:
  GLES2DecoderImpl* decoder_;
  bool resolve_and_bind_;
  DISALLOW_COPY_AND_ASSIGN(ScopedResolvedFrameBufferBinder);
};

class ScopedModifyPixels {
 public:
  explicit ScopedModifyPixels(TextureRef* ref);
  ~ScopedModifyPixels();

 private:
  TextureRef* ref_;
};

ScopedModifyPixels::ScopedModifyPixels(TextureRef* ref) : ref_(ref) {
  if (ref_)
    ref_->texture()->OnWillModifyPixels();
}

ScopedModifyPixels::~ScopedModifyPixels() {
  if (ref_)
    ref_->texture()->OnDidModifyPixels();
}

class ScopedRenderTo {
 public:
  explicit ScopedRenderTo(Framebuffer* framebuffer);
  ~ScopedRenderTo();

 private:
  const Framebuffer* framebuffer_;
};

ScopedRenderTo::ScopedRenderTo(Framebuffer* framebuffer)
    : framebuffer_(framebuffer) {
  if (framebuffer)
    framebuffer_->OnWillRenderTo();
}

ScopedRenderTo::~ScopedRenderTo() {
  if (framebuffer_)
    framebuffer_->OnDidRenderTo();
}

// Encapsulates an OpenGL texture.
class BackTexture {
 public:
  explicit BackTexture(MemoryTracker* memory_tracker, ContextState* state);
  ~BackTexture();

  // Create a new render texture.
  void Create();

  // Set the initial size and format of a render texture or resize it.
  bool AllocateStorage(const gfx::Size& size, GLenum format, bool zero);

  // Copy the contents of the currently bound frame buffer.
  void Copy(const gfx::Size& size, GLenum format);

  // Destroy the render texture. This must be explicitly called before
  // destroying this object.
  void Destroy();

  // Invalidate the texture. This can be used when a context is lost and it is
  // not possible to make it current in order to free the resource.
  void Invalidate();

  GLuint id() const {
    return id_;
  }

  gfx::Size size() const {
    return size_;
  }

 private:
  MemoryTypeTracker memory_tracker_;
  ContextState* state_;
  size_t bytes_allocated_;
  GLuint id_;
  gfx::Size size_;
  DISALLOW_COPY_AND_ASSIGN(BackTexture);
};

// Encapsulates an OpenGL render buffer of any format.
class BackRenderbuffer {
 public:
  explicit BackRenderbuffer(
      RenderbufferManager* renderbuffer_manager,
      MemoryTracker* memory_tracker,
      ContextState* state);
  ~BackRenderbuffer();

  // Create a new render buffer.
  void Create();

  // Set the initial size and format of a render buffer or resize it.
  bool AllocateStorage(const FeatureInfo* feature_info,
                       const gfx::Size& size,
                       GLenum format,
                       GLsizei samples);

  // Destroy the render buffer. This must be explicitly called before destroying
  // this object.
  void Destroy();

  // Invalidate the render buffer. This can be used when a context is lost and
  // it is not possible to make it current in order to free the resource.
  void Invalidate();

  GLuint id() const {
    return id_;
  }

 private:
  RenderbufferManager* renderbuffer_manager_;
  MemoryTypeTracker memory_tracker_;
  ContextState* state_;
  size_t bytes_allocated_;
  GLuint id_;
  DISALLOW_COPY_AND_ASSIGN(BackRenderbuffer);
};

// Encapsulates an OpenGL frame buffer.
class BackFramebuffer {
 public:
  explicit BackFramebuffer(GLES2DecoderImpl* decoder);
  ~BackFramebuffer();

  // Create a new frame buffer.
  void Create();

  // Attach a color render buffer to a frame buffer.
  void AttachRenderTexture(BackTexture* texture);

  // Attach a render buffer to a frame buffer. Note that this unbinds any
  // currently bound frame buffer.
  void AttachRenderBuffer(GLenum target, BackRenderbuffer* render_buffer);

  // Destroy the frame buffer. This must be explicitly called before destroying
  // this object.
  void Destroy();

  // Invalidate the frame buffer. This can be used when a context is lost and it
  // is not possible to make it current in order to free the resource.
  void Invalidate();

  // See glCheckFramebufferStatusEXT.
  GLenum CheckStatus();

  GLuint id() const {
    return id_;
  }

 private:
  GLES2DecoderImpl* decoder_;
  GLuint id_;
  DISALLOW_COPY_AND_ASSIGN(BackFramebuffer);
};

struct FenceCallback {
  FenceCallback()
      : fence(gfx::GLFence::Create()) {
    DCHECK(fence);
  }
  std::vector<base::Closure> callbacks;
  scoped_ptr<gfx::GLFence> fence;
};

class AsyncUploadTokenCompletionObserver
    : public AsyncPixelTransferCompletionObserver {
 public:
  explicit AsyncUploadTokenCompletionObserver(uint32 async_upload_token)
      : async_upload_token_(async_upload_token) {
  }

  void DidComplete(const AsyncMemoryParams& mem_params) override {
    DCHECK(mem_params.buffer().get());
    void* data = mem_params.GetDataAddress();
    AsyncUploadSync* sync = static_cast<AsyncUploadSync*>(data);
    sync->SetAsyncUploadToken(async_upload_token_);
  }

 private:
  ~AsyncUploadTokenCompletionObserver() override {}

  uint32 async_upload_token_;

  DISALLOW_COPY_AND_ASSIGN(AsyncUploadTokenCompletionObserver);
};

// }  // anonymous namespace.

// static
const unsigned int GLES2Decoder::kDefaultStencilMask =
    static_cast<unsigned int>(-1);

bool GLES2Decoder::GetServiceTextureId(uint32 client_texture_id,
                                       uint32* service_texture_id) {
  return false;
}

GLES2Decoder::GLES2Decoder()
    : initialized_(false),
      debug_(false),
      log_commands_(false),
      unsafe_es3_apis_enabled_(false) {
}

GLES2Decoder::~GLES2Decoder() {
}

void GLES2Decoder::BeginDecoding() {}

void GLES2Decoder::EndDecoding() {}

// This class implements GLES2Decoder so we don't have to expose all the GLES2
// cmd stuff to outside this class.
class GLES2DecoderImpl : public GLES2Decoder,
                         public FramebufferManager::TextureDetachObserver,
                         public ErrorStateClient {
 public:
  explicit GLES2DecoderImpl(ContextGroup* group);
  ~GLES2DecoderImpl() override;

  // Overridden from AsyncAPIInterface.
  Error DoCommand(unsigned int command,
                  unsigned int arg_count,
                  const void* args) override;

  error::Error DoCommands(unsigned int num_commands,
                          const void* buffer,
                          int num_entries,
                          int* entries_processed) override;

  template <bool DebugImpl>
  error::Error DoCommandsImpl(unsigned int num_commands,
                              const void* buffer,
                              int num_entries,
                              int* entries_processed);

  // Overridden from AsyncAPIInterface.
  const char* GetCommandName(unsigned int command_id) const override;

  // Overridden from GLES2Decoder.
  bool Initialize(const scoped_refptr<gfx::GLSurface>& surface,
                  const scoped_refptr<gfx::GLContext>& context,
                  bool offscreen,
                  const gfx::Size& offscreen_size,
                  const DisallowedFeatures& disallowed_features,
                  const std::vector<int32>& attribs) override;
  void Destroy(bool have_context) override;
  void SetSurface(const scoped_refptr<gfx::GLSurface>& surface) override;
  void ProduceFrontBuffer(const Mailbox& mailbox) override;
  bool ResizeOffscreenFrameBuffer(const gfx::Size& size) override;
  void UpdateParentTextureInfo();
  bool MakeCurrent() override;
  GLES2Util* GetGLES2Util() override { return &util_; }
  gfx::GLContext* GetGLContext() override { return context_.get(); }
  ContextGroup* GetContextGroup() override { return group_.get(); }
  Capabilities GetCapabilities() override;
  void RestoreState(const ContextState* prev_state) override;

  void RestoreActiveTexture() const override { state_.RestoreActiveTexture(); }
  void RestoreAllTextureUnitBindings(
      const ContextState* prev_state) const override {
    state_.RestoreAllTextureUnitBindings(prev_state);
  }
  void RestoreActiveTextureUnitBinding(unsigned int target) const override {
    state_.RestoreActiveTextureUnitBinding(target);
  }
  void RestoreBufferBindings() const override {
    state_.RestoreBufferBindings();
  }
  void RestoreGlobalState() const override { state_.RestoreGlobalState(NULL); }
  void RestoreProgramBindings() const override {
    state_.RestoreProgramBindings();
  }
  void RestoreTextureUnitBindings(unsigned unit) const override {
    state_.RestoreTextureUnitBindings(unit, NULL);
  }
  void RestoreFramebufferBindings() const override;
  void RestoreRenderbufferBindings() override;
  void RestoreTextureState(unsigned service_id) const override;

  void ClearAllAttributes() const override;
  void RestoreAllAttributes() const override;

  QueryManager* GetQueryManager() override { return query_manager_.get(); }
  VertexArrayManager* GetVertexArrayManager() override {
    return vertex_array_manager_.get();
  }
  ImageManager* GetImageManager() override { return image_manager_.get(); }

  ValuebufferManager* GetValuebufferManager() override {
    return valuebuffer_manager();
  }

  bool ProcessPendingQueries(bool did_finish) override;

  bool HasMoreIdleWork() override;
  void PerformIdleWork() override;

  void WaitForReadPixels(base::Closure callback) override;

  void SetResizeCallback(
      const base::Callback<void(gfx::Size, float)>& callback) override;

  Logger* GetLogger() override;

  void BeginDecoding() override;
  void EndDecoding() override;

  ErrorState* GetErrorState() override;
  const ContextState* GetContextState() override { return &state_; }

  void SetShaderCacheCallback(const ShaderCacheCallback& callback) override;
  void SetWaitSyncPointCallback(const WaitSyncPointCallback& callback) override;

  AsyncPixelTransferManager* GetAsyncPixelTransferManager() override;
  void ResetAsyncPixelTransferManagerForTest() override;
  void SetAsyncPixelTransferManagerForTest(
      AsyncPixelTransferManager* manager) override;
  void SetIgnoreCachedStateForTest(bool ignore) override;
  void ProcessFinishedAsyncTransfers();

  bool GetServiceTextureId(uint32 client_texture_id,
                           uint32* service_texture_id) override;

  uint32 GetTextureUploadCount() override;
  base::TimeDelta GetTotalTextureUploadTime() override;
  base::TimeDelta GetTotalProcessingCommandsTime() override;
  void AddProcessingCommandsTime(base::TimeDelta) override;

  // Restores the current state to the user's settings.
  void RestoreCurrentFramebufferBindings();

  // Sets DEPTH_TEST, STENCIL_TEST and color mask for the current framebuffer.
  void ApplyDirtyState();

  // These check the state of the currently bound framebuffer or the
  // backbuffer if no framebuffer is bound.
  // If all_draw_buffers is false, only check with COLOR_ATTACHMENT0, otherwise
  // check with all attached and enabled color attachments.
  bool BoundFramebufferHasColorAttachmentWithAlpha(bool all_draw_buffers);
  bool BoundFramebufferHasDepthAttachment();
  bool BoundFramebufferHasStencilAttachment();

  error::ContextLostReason GetContextLostReason() override;

  // Overridden from FramebufferManager::TextureDetachObserver:
  void OnTextureRefDetachedFromFramebuffer(TextureRef* texture) override;

  // Overriden from ErrorStateClient.
  void OnContextLostError() override;
  void OnOutOfMemoryError() override;

  // Ensure Renderbuffer corresponding to last DoBindRenderbuffer() is bound.
  void EnsureRenderbufferBound();

  // Helpers to facilitate calling into compatible extensions.
  static void RenderbufferStorageMultisampleHelper(
      const FeatureInfo* feature_info,
      GLenum target,
      GLsizei samples,
      GLenum internal_format,
      GLsizei width,
      GLsizei height);

  void BlitFramebufferHelper(GLint srcX0,
                             GLint srcY0,
                             GLint srcX1,
                             GLint srcY1,
                             GLint dstX0,
                             GLint dstY0,
                             GLint dstX1,
                             GLint dstY1,
                             GLbitfield mask,
                             GLenum filter);

 private:
  friend class ScopedFrameBufferBinder;
  friend class ScopedResolvedFrameBufferBinder;
  friend class BackFramebuffer;

  // Initialize or re-initialize the shader translator.
  bool InitializeShaderTranslator();

  void UpdateCapabilities();

  // Helpers for the glGen and glDelete functions.
  bool GenTexturesHelper(GLsizei n, const GLuint* client_ids);
  void DeleteTexturesHelper(GLsizei n, const GLuint* client_ids);
  bool GenBuffersHelper(GLsizei n, const GLuint* client_ids);
  void DeleteBuffersHelper(GLsizei n, const GLuint* client_ids);
  bool GenFramebuffersHelper(GLsizei n, const GLuint* client_ids);
  void DeleteFramebuffersHelper(GLsizei n, const GLuint* client_ids);
  bool GenRenderbuffersHelper(GLsizei n, const GLuint* client_ids);
  void DeleteRenderbuffersHelper(GLsizei n, const GLuint* client_ids);
  bool GenValuebuffersCHROMIUMHelper(GLsizei n, const GLuint* client_ids);
  void DeleteValuebuffersCHROMIUMHelper(GLsizei n, const GLuint* client_ids);
  bool GenQueriesEXTHelper(GLsizei n, const GLuint* client_ids);
  void DeleteQueriesEXTHelper(GLsizei n, const GLuint* client_ids);
  bool GenVertexArraysOESHelper(GLsizei n, const GLuint* client_ids);
  void DeleteVertexArraysOESHelper(GLsizei n, const GLuint* client_ids);

  // Helper for async upload token completion notification callback.
  base::Closure AsyncUploadTokenCompletionClosure(uint32 async_upload_token,
                                                  uint32 sync_data_shm_id,
                                                  uint32 sync_data_shm_offset);



  // Workarounds
  void OnFboChanged() const;
  void OnUseFramebuffer() const;

  error::ContextLostReason GetContextLostReasonFromResetStatus(
      GLenum reset_status) const;

  // TODO(gman): Cache these pointers?
  BufferManager* buffer_manager() {
    return group_->buffer_manager();
  }

  RenderbufferManager* renderbuffer_manager() {
    return group_->renderbuffer_manager();
  }

  FramebufferManager* framebuffer_manager() {
    return group_->framebuffer_manager();
  }

  ValuebufferManager* valuebuffer_manager() {
    return group_->valuebuffer_manager();
  }

  ProgramManager* program_manager() {
    return group_->program_manager();
  }

  ShaderManager* shader_manager() {
    return group_->shader_manager();
  }

  ShaderTranslatorCache* shader_translator_cache() {
    return group_->shader_translator_cache();
  }

  const TextureManager* texture_manager() const {
    return group_->texture_manager();
  }

  TextureManager* texture_manager() {
    return group_->texture_manager();
  }

  MailboxManager* mailbox_manager() {
    return group_->mailbox_manager();
  }

  ImageManager* image_manager() { return image_manager_.get(); }

  VertexArrayManager* vertex_array_manager() {
    return vertex_array_manager_.get();
  }

  MemoryTracker* memory_tracker() {
    return group_->memory_tracker();
  }

  bool EnsureGPUMemoryAvailable(size_t estimated_size) {
    MemoryTracker* tracker = memory_tracker();
    if (tracker) {
      return tracker->EnsureGPUMemoryAvailable(estimated_size);
    }
    return true;
  }

  bool IsOffscreenBufferMultisampled() const {
    return offscreen_target_samples_ > 1;
  }

  // Creates a Texture for the given texture.
  TextureRef* CreateTexture(
      GLuint client_id, GLuint service_id) {
    return texture_manager()->CreateTexture(client_id, service_id);
  }

  // Gets the texture info for the given texture. Returns NULL if none exists.
  TextureRef* GetTexture(GLuint client_id) const {
    return texture_manager()->GetTexture(client_id);
  }

  // Deletes the texture info for the given texture.
  void RemoveTexture(GLuint client_id) {
    texture_manager()->RemoveTexture(client_id);
  }

  // Get the size (in pixels) of the currently bound frame buffer (either FBO
  // or regular back buffer).
  gfx::Size GetBoundReadFrameBufferSize();

  // Get the format of the currently bound frame buffer (either FBO or regular
  // back buffer)
  GLenum GetBoundReadFrameBufferTextureType();
  GLenum GetBoundReadFrameBufferInternalFormat();
  GLenum GetBoundDrawFrameBufferInternalFormat();

  // Wrapper for CompressedTexImage2D commands.
  error::Error DoCompressedTexImage2D(
      GLenum target,
      GLint level,
      GLenum internal_format,
      GLsizei width,
      GLsizei height,
      GLint border,
      GLsizei image_size,
      const void* data);

  // Wrapper for CompressedTexSubImage2D.
  void DoCompressedTexSubImage2D(
      GLenum target,
      GLint level,
      GLint xoffset,
      GLint yoffset,
      GLsizei width,
      GLsizei height,
      GLenum format,
      GLsizei imageSize,
      const void * data);

  // Wrapper for CopyTexImage2D.
  void DoCopyTexImage2D(
      GLenum target,
      GLint level,
      GLenum internal_format,
      GLint x,
      GLint y,
      GLsizei width,
      GLsizei height,
      GLint border);

  // Wrapper for SwapBuffers.
  void DoSwapBuffers();

  // Wrapper for SwapInterval.
  void DoSwapInterval(int interval);

  // Wrapper for CopyTexSubImage2D.
  void DoCopyTexSubImage2D(
      GLenum target,
      GLint level,
      GLint xoffset,
      GLint yoffset,
      GLint x,
      GLint y,
      GLsizei width,
      GLsizei height);

  // Validation for TexSubImage2D.
  bool ValidateTexSubImage2D(
      error::Error* error,
      const char* function_name,
      GLenum target,
      GLint level,
      GLint xoffset,
      GLint yoffset,
      GLsizei width,
      GLsizei height,
      GLenum format,
      GLenum type,
      const void * data);

  // Wrapper for TexSubImage2D.
  error::Error DoTexSubImage2D(
      GLenum target,
      GLint level,
      GLint xoffset,
      GLint yoffset,
      GLsizei width,
      GLsizei height,
      GLenum format,
      GLenum type,
      const void * data);

  // Extra validation for async tex(Sub)Image2D.
  bool ValidateAsyncTransfer(
      const char* function_name,
      TextureRef* texture_ref,
      GLenum target,
      GLint level,
      const void * data);

  // Wrapper for TexImageIOSurface2DCHROMIUM.
  void DoTexImageIOSurface2DCHROMIUM(
      GLenum target,
      GLsizei width,
      GLsizei height,
      GLuint io_surface_id,
      GLuint plane);

  void DoCopyTextureCHROMIUM(GLenum target,
                             GLuint source_id,
                             GLuint dest_id,
                             GLenum internal_format,
                             GLenum dest_type);

  void DoCopySubTextureCHROMIUM(GLenum target,
                                GLuint source_id,
                                GLuint dest_id,
                                GLint xoffset,
                                GLint yoffset);

  // Wrapper for TexStorage2DEXT.
  void DoTexStorage2DEXT(
      GLenum target,
      GLint levels,
      GLenum internal_format,
      GLsizei width,
      GLsizei height);

  void DoProduceTextureCHROMIUM(GLenum target, const GLbyte* key);
  void DoProduceTextureDirectCHROMIUM(GLuint texture, GLenum target,
      const GLbyte* key);
  void ProduceTextureRef(std::string func_name, TextureRef* texture_ref,
      GLenum target, const GLbyte* data);

  void EnsureTextureForClientId(GLenum target, GLuint client_id);
  void DoConsumeTextureCHROMIUM(GLenum target, const GLbyte* key);
  void DoCreateAndConsumeTextureCHROMIUM(GLenum target, const GLbyte* key,
    GLuint client_id);

  bool DoIsValuebufferCHROMIUM(GLuint client_id);
  void DoBindValueBufferCHROMIUM(GLenum target, GLuint valuebuffer);
  void DoSubscribeValueCHROMIUM(GLenum target, GLenum subscription);
  void DoPopulateSubscribedValuesCHROMIUM(GLenum target);
  void DoUniformValueBufferCHROMIUM(GLint location,
                                    GLenum target,
                                    GLenum subscription);

  void DoBindTexImage2DCHROMIUM(
      GLenum target,
      GLint image_id);
  void DoReleaseTexImage2DCHROMIUM(
      GLenum target,
      GLint image_id);

  void DoTraceEndCHROMIUM(void);

  void DoDrawBuffersEXT(GLsizei count, const GLenum* bufs);

  void DoLoseContextCHROMIUM(GLenum current, GLenum other);

  void DoMatrixLoadfCHROMIUM(GLenum matrix_mode, const GLfloat* matrix);
  void DoMatrixLoadIdentityCHROMIUM(GLenum matrix_mode);

  // Creates a Program for the given program.
  Program* CreateProgram(
      GLuint client_id, GLuint service_id) {
    return program_manager()->CreateProgram(client_id, service_id);
  }

  // Gets the program info for the given program. Returns NULL if none exists.
  Program* GetProgram(GLuint client_id) {
    return program_manager()->GetProgram(client_id);
  }

#if defined(NDEBUG)
  void LogClientServiceMapping(
      const char* /* function_name */,
      GLuint /* client_id */,
      GLuint /* service_id */) {
  }
  template<typename T>
  void LogClientServiceForInfo(
      T* /* info */, GLuint /* client_id */, const char* /* function_name */) {
  }
#else
  void LogClientServiceMapping(
      const char* function_name, GLuint client_id, GLuint service_id) {
    if (service_logging_) {
      VLOG(1) << "[" << logger_.GetLogPrefix() << "] " << function_name
              << ": client_id = " << client_id
              << ", service_id = " << service_id;
    }
  }
  template<typename T>
  void LogClientServiceForInfo(
      T* info, GLuint client_id, const char* function_name) {
    if (info) {
      LogClientServiceMapping(function_name, client_id, info->service_id());
    }
  }
#endif

  // Gets the program info for the given program. If it's not a program
  // generates a GL error. Returns NULL if not program.
  Program* GetProgramInfoNotShader(
      GLuint client_id, const char* function_name) {
    Program* program = GetProgram(client_id);
    if (!program) {
      if (GetShader(client_id)) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name, "shader passed for program");
      } else {
        LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "unknown program");
      }
    }
    LogClientServiceForInfo(program, client_id, function_name);
    return program;
  }


  // Creates a Shader for the given shader.
  Shader* CreateShader(
      GLuint client_id,
      GLuint service_id,
      GLenum shader_type) {
    return shader_manager()->CreateShader(
        client_id, service_id, shader_type);
  }

  // Gets the shader info for the given shader. Returns NULL if none exists.
  Shader* GetShader(GLuint client_id) {
    return shader_manager()->GetShader(client_id);
  }

  // Gets the shader info for the given shader. If it's not a shader generates a
  // GL error. Returns NULL if not shader.
  Shader* GetShaderInfoNotProgram(
      GLuint client_id, const char* function_name) {
    Shader* shader = GetShader(client_id);
    if (!shader) {
      if (GetProgram(client_id)) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name, "program passed for shader");
      } else {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_VALUE, function_name, "unknown shader");
      }
    }
    LogClientServiceForInfo(shader, client_id, function_name);
    return shader;
  }

  // Creates a buffer info for the given buffer.
  void CreateBuffer(GLuint client_id, GLuint service_id) {
    return buffer_manager()->CreateBuffer(client_id, service_id);
  }

  // Gets the buffer info for the given buffer.
  Buffer* GetBuffer(GLuint client_id) {
    Buffer* buffer = buffer_manager()->GetBuffer(client_id);
    return buffer;
  }

  // Removes any buffers in the VertexAtrribInfos and BufferInfos. This is used
  // on glDeleteBuffers so we can make sure the user does not try to render
  // with deleted buffers.
  void RemoveBuffer(GLuint client_id);

  // Creates a framebuffer info for the given framebuffer.
  void CreateFramebuffer(GLuint client_id, GLuint service_id) {
    return framebuffer_manager()->CreateFramebuffer(client_id, service_id);
  }

  // Gets the framebuffer info for the given framebuffer.
  Framebuffer* GetFramebuffer(GLuint client_id) {
    return framebuffer_manager()->GetFramebuffer(client_id);
  }

  // Removes the framebuffer info for the given framebuffer.
  void RemoveFramebuffer(GLuint client_id) {
    framebuffer_manager()->RemoveFramebuffer(client_id);
  }

  // Creates a renderbuffer info for the given renderbuffer.
  void CreateRenderbuffer(GLuint client_id, GLuint service_id) {
    return renderbuffer_manager()->CreateRenderbuffer(
        client_id, service_id);
  }

  // Gets the renderbuffer info for the given renderbuffer.
  Renderbuffer* GetRenderbuffer(GLuint client_id) {
    return renderbuffer_manager()->GetRenderbuffer(client_id);
  }

  // Removes the renderbuffer info for the given renderbuffer.
  void RemoveRenderbuffer(GLuint client_id) {
    renderbuffer_manager()->RemoveRenderbuffer(client_id);
  }

  // Creates a valuebuffer info for the given valuebuffer.
  void CreateValuebuffer(GLuint client_id) {
    return valuebuffer_manager()->CreateValuebuffer(client_id);
  }

  // Gets the valuebuffer info for a given valuebuffer.
  Valuebuffer* GetValuebuffer(GLuint client_id) {
    return valuebuffer_manager()->GetValuebuffer(client_id);
  }

  // Removes the valuebuffer info for the given valuebuffer.
  void RemoveValuebuffer(GLuint client_id) {
    valuebuffer_manager()->RemoveValuebuffer(client_id);
  }

  // Gets the vertex attrib manager for the given vertex array.
  VertexAttribManager* GetVertexAttribManager(GLuint client_id) {
    VertexAttribManager* info =
        vertex_array_manager()->GetVertexAttribManager(client_id);
    return info;
  }

  // Removes the vertex attrib manager for the given vertex array.
  void RemoveVertexAttribManager(GLuint client_id) {
    vertex_array_manager()->RemoveVertexAttribManager(client_id);
  }

  // Creates a vertex attrib manager for the given vertex array.
  scoped_refptr<VertexAttribManager> CreateVertexAttribManager(
      GLuint client_id,
      GLuint service_id,
      bool client_visible) {
    return vertex_array_manager()->CreateVertexAttribManager(
        client_id, service_id, group_->max_vertex_attribs(), client_visible);
  }

  void DoBindAttribLocation(GLuint client_id, GLuint index, const char* name);
  void DoBindUniformLocationCHROMIUM(
      GLuint client_id, GLint location, const char* name);

  error::Error GetAttribLocationHelper(
      GLuint client_id, uint32 location_shm_id, uint32 location_shm_offset,
      const std::string& name_str);

  error::Error GetUniformLocationHelper(
      GLuint client_id, uint32 location_shm_id, uint32 location_shm_offset,
      const std::string& name_str);

  error::Error GetFragDataLocationHelper(
      GLuint client_id, uint32 location_shm_id, uint32 location_shm_offset,
      const std::string& name_str);

  // Wrapper for glShaderSource.
  void DoShaderSource(
      GLuint client_id, GLsizei count, const char** data, const GLint* length);

  // Wrapper for glTransformFeedbackVaryings.
  void DoTransformFeedbackVaryings(
      GLuint client_program_id, GLsizei count, const char* const* varyings,
      GLenum buffer_mode);

  // Clear any textures used by the current program.
  bool ClearUnclearedTextures();

  // Clears any uncleared attachments attached to the given frame buffer.
  // Returns false if there was a generated GL error.
  void ClearUnclearedAttachments(GLenum target, Framebuffer* framebuffer);

  // overridden from GLES2Decoder
  bool ClearLevel(Texture* texture,
                  unsigned target,
                  int level,
                  unsigned internal_format,
                  unsigned format,
                  unsigned type,
                  int width,
                  int height,
                  bool is_texture_immutable) override;

  // Restore all GL state that affects clearing.
  void RestoreClearState();

  // Remembers the state of some capabilities.
  // Returns: true if glEnable/glDisable should actually be called.
  bool SetCapabilityState(GLenum cap, bool enabled);

  // Check that the currently bound framebuffers are valid.
  // Generates GL error if not.
  bool CheckBoundFramebuffersValid(const char* func_name);

  // Check that the currently bound read framebuffer has a color image
  // attached. Generates GL error if not.
  bool CheckBoundReadFramebufferColorAttachment(const char* func_name);

  // Check that the currently bound read framebuffer's color image
  // isn't the target texture of the glCopyTex{Sub}Image2D.
  bool FormsTextureCopyingFeedbackLoop(TextureRef* texture, GLint level);

  // Check if a framebuffer meets our requirements.
  bool CheckFramebufferValid(
      Framebuffer* framebuffer,
      GLenum target,
      const char* func_name);

  // Check if the current valuebuffer exists and is valid. If not generates
  // the appropriate GL error. Returns true if the current valuebuffer is in
  // a usable state.
  bool CheckCurrentValuebuffer(const char* function_name);

  // Check if the current valuebuffer exists and is valiud and that the
  // value buffer is actually subscribed to the given subscription
  bool CheckCurrentValuebufferForSubscription(GLenum subscription,
                                              const char* function_name);

  // Check if the location can be used for the given subscription target. If not
  // generates the appropriate GL error. Returns true if the location is usable
  bool CheckSubscriptionTarget(GLint location,
                               GLenum subscription,
                               const char* function_name);

  // Checks if the current program exists and is valid. If not generates the
  // appropriate GL error.  Returns true if the current program is in a usable
  // state.
  bool CheckCurrentProgram(const char* function_name);

  // Checks if the current program exists and is valid and that location is not
  // -1. If the current program is not valid generates the appropriate GL
  // error. Returns true if the current program is in a usable state and
  // location is not -1.
  bool CheckCurrentProgramForUniform(GLint location, const char* function_name);

  // Checks if the current program samples a texture that is also the color
  // image of the current bound framebuffer, i.e., the source and destination
  // of the draw operation are the same.
  bool CheckDrawingFeedbackLoops();

  // Checks if |api_type| is valid for the given uniform
  // If the api type is not valid generates the appropriate GL
  // error. Returns true if |api_type| is valid for the uniform
  bool CheckUniformForApiType(const Program::UniformInfo* info,
                              const char* function_name,
                              Program::UniformApiType api_type);

  // Gets the type of a uniform for a location in the current program. Sets GL
  // errors if the current program is not valid. Returns true if the current
  // program is valid and the location exists. Adjusts count so it
  // does not overflow the uniform.
  bool PrepForSetUniformByLocation(GLint fake_location,
                                   const char* function_name,
                                   Program::UniformApiType api_type,
                                   GLint* real_location,
                                   GLenum* type,
                                   GLsizei* count);

  // Gets the service id for any simulated backbuffer fbo.
  GLuint GetBackbufferServiceId() const;

  // Helper for glGetBooleanv, glGetFloatv and glGetIntegerv
  bool GetHelper(GLenum pname, GLint* params, GLsizei* num_written);

  // Helper for glGetVertexAttrib
  void GetVertexAttribHelper(
    const VertexAttrib* attrib, GLenum pname, GLint* param);

  // Wrapper for glActiveTexture
  void DoActiveTexture(GLenum texture_unit);

  // Wrapper for glAttachShader
  void DoAttachShader(GLuint client_program_id, GLint client_shader_id);

  // Wrapper for glBindBuffer since we need to track the current targets.
  void DoBindBuffer(GLenum target, GLuint buffer);

  // Wrapper for glBindFramebuffer since we need to track the current targets.
  void DoBindFramebuffer(GLenum target, GLuint framebuffer);

  // Wrapper for glBindRenderbuffer since we need to track the current targets.
  void DoBindRenderbuffer(GLenum target, GLuint renderbuffer);

  // Wrapper for glBindTexture since we need to track the current targets.
  void DoBindTexture(GLenum target, GLuint texture);

  // Wrapper for glBindVertexArrayOES
  void DoBindVertexArrayOES(GLuint array);
  void EmulateVertexArrayState();

  // Wrapper for glBlitFramebufferCHROMIUM.
  void DoBlitFramebufferCHROMIUM(
      GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1,
      GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1,
      GLbitfield mask, GLenum filter);

  // Wrapper for glBufferSubData.
  void DoBufferSubData(
    GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid * data);

  // Wrapper for glCheckFramebufferStatus
  GLenum DoCheckFramebufferStatus(GLenum target);

  // Wrapper for glClear
  error::Error DoClear(GLbitfield mask);

  // Wrappers for various state.
  void DoDepthRangef(GLclampf znear, GLclampf zfar);
  void DoSampleCoverage(GLclampf value, GLboolean invert);

  // Wrapper for glCompileShader.
  void DoCompileShader(GLuint shader);

  // Wrapper for glDetachShader
  void DoDetachShader(GLuint client_program_id, GLint client_shader_id);

  // Wrapper for glDisable
  void DoDisable(GLenum cap);

  // Wrapper for glDisableVertexAttribArray.
  void DoDisableVertexAttribArray(GLuint index);

  // Wrapper for glDiscardFramebufferEXT, since we need to track undefined
  // attachments.
  void DoDiscardFramebufferEXT(GLenum target,
                               GLsizei numAttachments,
                               const GLenum* attachments);

  // Wrapper for glEnable
  void DoEnable(GLenum cap);

  // Wrapper for glEnableVertexAttribArray.
  void DoEnableVertexAttribArray(GLuint index);

  // Wrapper for glFinish.
  void DoFinish();

  // Wrapper for glFlush.
  void DoFlush();

  // Wrapper for glFramebufferRenderbufffer.
  void DoFramebufferRenderbuffer(
      GLenum target, GLenum attachment, GLenum renderbuffertarget,
      GLuint renderbuffer);

  // Wrapper for glFramebufferTexture2D.
  void DoFramebufferTexture2D(
      GLenum target, GLenum attachment, GLenum textarget, GLuint texture,
      GLint level);

  // Wrapper for glFramebufferTexture2DMultisampleEXT.
  void DoFramebufferTexture2DMultisample(
      GLenum target, GLenum attachment, GLenum textarget,
      GLuint texture, GLint level, GLsizei samples);

  // Common implementation for both DoFramebufferTexture2D wrappers.
  void DoFramebufferTexture2DCommon(const char* name,
      GLenum target, GLenum attachment, GLenum textarget,
      GLuint texture, GLint level, GLsizei samples);

  // Wrapper for glFramebufferTextureLayer.
  void DoFramebufferTextureLayer(
      GLenum target, GLenum attachment, GLuint texture, GLint level,
      GLint layer);

  // Wrapper for glGenerateMipmap
  void DoGenerateMipmap(GLenum target);

  // Helper for DoGetBooleanv, Floatv, and Intergerv to adjust pname
  // to account for different pname values defined in different extension
  // variants.
  GLenum AdjustGetPname(GLenum pname);

  // Wrapper for DoGetBooleanv.
  void DoGetBooleanv(GLenum pname, GLboolean* params);

  // Wrapper for DoGetFloatv.
  void DoGetFloatv(GLenum pname, GLfloat* params);

  // Wrapper for glGetFramebufferAttachmentParameteriv.
  void DoGetFramebufferAttachmentParameteriv(
      GLenum target, GLenum attachment, GLenum pname, GLint* params);

  // Wrapper for glGetInteger64v.
  void DoGetInteger64v(GLenum pname, GLint64* params);

  // Wrapper for glGetIntegerv.
  void DoGetIntegerv(GLenum pname, GLint* params);

  // Gets the max value in a range in a buffer.
  GLuint DoGetMaxValueInBufferCHROMIUM(
      GLuint buffer_id, GLsizei count, GLenum type, GLuint offset);

  // Wrapper for glGetBufferParameteriv.
  void DoGetBufferParameteriv(
      GLenum target, GLenum pname, GLint* params);

  // Wrapper for glGetProgramiv.
  void DoGetProgramiv(
      GLuint program_id, GLenum pname, GLint* params);

  // Wrapper for glRenderbufferParameteriv.
  void DoGetRenderbufferParameteriv(
      GLenum target, GLenum pname, GLint* params);

  // Wrapper for glGetShaderiv
  void DoGetShaderiv(GLuint shader, GLenum pname, GLint* params);

  // Wrappers for glGetTexParameter.
  void DoGetTexParameterfv(GLenum target, GLenum pname, GLfloat* params);
  void DoGetTexParameteriv(GLenum target, GLenum pname, GLint* params);
  void InitTextureMaxAnisotropyIfNeeded(GLenum target, GLenum pname);

  // Wrappers for glGetVertexAttrib.
  void DoGetVertexAttribfv(GLuint index, GLenum pname, GLfloat *params);
  void DoGetVertexAttribiv(GLuint index, GLenum pname, GLint *params);

  // Wrappers for glIsXXX functions.
  bool DoIsEnabled(GLenum cap);
  bool DoIsBuffer(GLuint client_id);
  bool DoIsFramebuffer(GLuint client_id);
  bool DoIsProgram(GLuint client_id);
  bool DoIsRenderbuffer(GLuint client_id);
  bool DoIsShader(GLuint client_id);
  bool DoIsTexture(GLuint client_id);
  bool DoIsVertexArrayOES(GLuint client_id);

  // Wrapper for glLinkProgram
  void DoLinkProgram(GLuint program);

  // Wrapper for glRenderbufferStorage.
  void DoRenderbufferStorage(
      GLenum target, GLenum internalformat, GLsizei width, GLsizei height);

  // Handler for glRenderbufferStorageMultisampleCHROMIUM.
  void DoRenderbufferStorageMultisampleCHROMIUM(
      GLenum target, GLsizei samples, GLenum internalformat,
      GLsizei width, GLsizei height);

  // Handler for glRenderbufferStorageMultisampleEXT
  // (multisampled_render_to_texture).
  void DoRenderbufferStorageMultisampleEXT(
      GLenum target, GLsizei samples, GLenum internalformat,
      GLsizei width, GLsizei height);

  // Common validation for multisample extensions.
  bool ValidateRenderbufferStorageMultisample(GLsizei samples,
                                              GLenum internalformat,
                                              GLsizei width,
                                              GLsizei height);

  // Verifies that the currently bound multisample renderbuffer is valid
  // Very slow! Only done on platforms with driver bugs that return invalid
  // buffers under memory pressure
  bool VerifyMultisampleRenderbufferIntegrity(
      GLuint renderbuffer, GLenum format);

  // Wrapper for glReleaseShaderCompiler.
  void DoReleaseShaderCompiler() { }

  // Wrappers for glSamplerParameter*v functions.
  void DoSamplerParameterfv(
      GLuint sampler, GLenum pname, const GLfloat* params);
  void DoSamplerParameteriv(GLuint sampler, GLenum pname, const GLint* params);

  // Wrappers for glTexParameter functions.
  void DoTexParameterf(GLenum target, GLenum pname, GLfloat param);
  void DoTexParameteri(GLenum target, GLenum pname, GLint param);
  void DoTexParameterfv(GLenum target, GLenum pname, const GLfloat* params);
  void DoTexParameteriv(GLenum target, GLenum pname, const GLint* params);

  // Wrappers for glUniform1i and glUniform1iv as according to the GLES2
  // spec only these 2 functions can be used to set sampler uniforms.
  void DoUniform1i(GLint fake_location, GLint v0);
  void DoUniform1iv(GLint fake_location, GLsizei count, const GLint* value);
  void DoUniform2iv(GLint fake_location, GLsizei count, const GLint* value);
  void DoUniform3iv(GLint fake_location, GLsizei count, const GLint* value);
  void DoUniform4iv(GLint fake_location, GLsizei count, const GLint* value);

  // Wrappers for glUniformfv because some drivers don't correctly accept
  // bool uniforms.
  void DoUniform1fv(GLint fake_location, GLsizei count, const GLfloat* value);
  void DoUniform2fv(GLint fake_location, GLsizei count, const GLfloat* value);
  void DoUniform3fv(GLint fake_location, GLsizei count, const GLfloat* value);
  void DoUniform4fv(GLint fake_location, GLsizei count, const GLfloat* value);

  void DoUniformMatrix2fv(
      GLint fake_location, GLsizei count, GLboolean transpose,
      const GLfloat* value);
  void DoUniformMatrix3fv(
      GLint fake_location, GLsizei count, GLboolean transpose,
      const GLfloat* value);
  void DoUniformMatrix4fv(
      GLint fake_location, GLsizei count, GLboolean transpose,
      const GLfloat* value);

  bool SetVertexAttribValue(
    const char* function_name, GLuint index, const GLfloat* value);

  // Wrappers for glVertexAttrib??
  void DoVertexAttrib1f(GLuint index, GLfloat v0);
  void DoVertexAttrib2f(GLuint index, GLfloat v0, GLfloat v1);
  void DoVertexAttrib3f(GLuint index, GLfloat v0, GLfloat v1, GLfloat v2);
  void DoVertexAttrib4f(
      GLuint index, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
  void DoVertexAttrib1fv(GLuint index, const GLfloat *v);
  void DoVertexAttrib2fv(GLuint index, const GLfloat *v);
  void DoVertexAttrib3fv(GLuint index, const GLfloat *v);
  void DoVertexAttrib4fv(GLuint index, const GLfloat *v);

  // Wrapper for glViewport
  void DoViewport(GLint x, GLint y, GLsizei width, GLsizei height);

  // Wrapper for glUseProgram
  void DoUseProgram(GLuint program);

  // Wrapper for glValidateProgram.
  void DoValidateProgram(GLuint program_client_id);

  void DoInsertEventMarkerEXT(GLsizei length, const GLchar* marker);
  void DoPushGroupMarkerEXT(GLsizei length, const GLchar* group);
  void DoPopGroupMarkerEXT(void);

  // Gets the number of values that will be returned by glGetXXX. Returns
  // false if pname is unknown.
  bool GetNumValuesReturnedForGLGet(GLenum pname, GLsizei* num_values);

  // Checks if the current program and vertex attributes are valid for drawing.
  bool IsDrawValid(
      const char* function_name, GLuint max_vertex_accessed, bool instanced,
      GLsizei primcount);

  // Returns true if successful, simulated will be true if attrib0 was
  // simulated.
  bool SimulateAttrib0(
      const char* function_name, GLuint max_vertex_accessed, bool* simulated);
  void RestoreStateForAttrib(GLuint attrib, bool restore_array_binding);

  // If an image is bound to texture, this will call Will/DidUseTexImage
  // if needed.
  void DoWillUseTexImageIfNeeded(Texture* texture, GLenum textarget);
  void DoDidUseTexImageIfNeeded(Texture* texture, GLenum textarget);

  // Returns false if textures were replaced.
  bool PrepareTexturesForRender();
  void RestoreStateForTextures();

  // Returns true if GL_FIXED attribs were simulated.
  bool SimulateFixedAttribs(
      const char* function_name,
      GLuint max_vertex_accessed, bool* simulated, GLsizei primcount);
  void RestoreStateForSimulatedFixedAttribs();

  // Handle DrawArrays and DrawElements for both instanced and non-instanced
  // cases (primcount is always 1 for non-instanced).
  error::Error DoDrawArrays(
      const char* function_name,
      bool instanced, GLenum mode, GLint first, GLsizei count,
      GLsizei primcount);
  error::Error DoDrawElements(
      const char* function_name,
      bool instanced, GLenum mode, GLsizei count, GLenum type,
      int32 offset, GLsizei primcount);

  GLenum GetBindTargetForSamplerType(GLenum type) {
    DCHECK(type == GL_SAMPLER_2D || type == GL_SAMPLER_CUBE ||
           type == GL_SAMPLER_EXTERNAL_OES || type == GL_SAMPLER_2D_RECT_ARB);
    switch (type) {
      case GL_SAMPLER_2D:
        return GL_TEXTURE_2D;
      case GL_SAMPLER_CUBE:
        return GL_TEXTURE_CUBE_MAP;
      case GL_SAMPLER_EXTERNAL_OES:
        return GL_TEXTURE_EXTERNAL_OES;
      case GL_SAMPLER_2D_RECT_ARB:
        return GL_TEXTURE_RECTANGLE_ARB;
    }

    NOTREACHED();
    return 0;
  }

  // Gets the framebuffer info for a particular target.
  Framebuffer* GetFramebufferInfoForTarget(GLenum target) {
    Framebuffer* framebuffer = NULL;
    switch (target) {
      case GL_FRAMEBUFFER:
      case GL_DRAW_FRAMEBUFFER_EXT:
        framebuffer = framebuffer_state_.bound_draw_framebuffer.get();
        break;
      case GL_READ_FRAMEBUFFER_EXT:
        framebuffer = framebuffer_state_.bound_read_framebuffer.get();
        break;
      default:
        NOTREACHED();
        break;
    }
    return framebuffer;
  }

  Renderbuffer* GetRenderbufferInfoForTarget(
      GLenum target) {
    Renderbuffer* renderbuffer = NULL;
    switch (target) {
      case GL_RENDERBUFFER:
        renderbuffer = state_.bound_renderbuffer.get();
        break;
      default:
        NOTREACHED();
        break;
    }
    return renderbuffer;
  }

  // Validates the program and location for a glGetUniform call and returns
  // a SizeResult setup to receive the result. Returns true if glGetUniform
  // should be called.
  bool GetUniformSetup(GLuint program,
                       GLint fake_location,
                       uint32 shm_id,
                       uint32 shm_offset,
                       error::Error* error,
                       GLint* real_location,
                       GLuint* service_id,
                       void** result,
                       GLenum* result_type,
                       GLsizei* result_size);

  bool WasContextLost() const override;
  bool WasContextLostByRobustnessExtension() const override;
  void MarkContextLost(error::ContextLostReason reason) override;
  bool CheckResetStatus();

#if defined(OS_MACOSX)
  void ReleaseIOSurfaceForTexture(GLuint texture_id);
#endif

  bool ValidateCompressedTexDimensions(
      const char* function_name,
      GLint level, GLsizei width, GLsizei height, GLenum format);
  bool ValidateCompressedTexFuncData(
      const char* function_name,
      GLsizei width, GLsizei height, GLenum format, size_t size);
  bool ValidateCompressedTexSubDimensions(
    const char* function_name,
    GLenum target, GLint level, GLint xoffset, GLint yoffset,
    GLsizei width, GLsizei height, GLenum format,
    Texture* texture);
  bool ValidateCopyTextureCHROMIUM(const char* function_name,
                                   GLenum target,
                                   TextureRef* source_texture_ref,
                                   TextureRef* dest_texture_ref,
                                   GLenum dest_internal_format);

  void RenderWarning(const char* filename, int line, const std::string& msg);
  void PerformanceWarning(
      const char* filename, int line, const std::string& msg);

  const FeatureInfo::FeatureFlags& features() const {
    return feature_info_->feature_flags();
  }

  const FeatureInfo::Workarounds& workarounds() const {
    return feature_info_->workarounds();
  }

  bool ShouldDeferDraws() {
    return !offscreen_target_frame_buffer_.get() &&
           framebuffer_state_.bound_draw_framebuffer.get() == NULL &&
           surface_->DeferDraws();
  }

  bool ShouldDeferReads() {
    return !offscreen_target_frame_buffer_.get() &&
           framebuffer_state_.bound_read_framebuffer.get() == NULL &&
           surface_->DeferDraws();
  }

  bool IsRobustnessSupported() {
    return has_robustness_extension_ &&
           context_->WasAllocatedUsingRobustnessExtension();
  }

  error::Error WillAccessBoundFramebufferForDraw() {
    if (ShouldDeferDraws())
      return error::kDeferCommandUntilLater;
    if (!offscreen_target_frame_buffer_.get() &&
        !framebuffer_state_.bound_draw_framebuffer.get() &&
        !surface_->SetBackbufferAllocation(true))
      return error::kLostContext;
    return error::kNoError;
  }

  error::Error WillAccessBoundFramebufferForRead() {
    if (ShouldDeferReads())
      return error::kDeferCommandUntilLater;
    if (!offscreen_target_frame_buffer_.get() &&
        !framebuffer_state_.bound_read_framebuffer.get() &&
        !surface_->SetBackbufferAllocation(true))
      return error::kLostContext;
    return error::kNoError;
  }

  // Set remaining commands to process to 0 to force DoCommands to return
  // and allow context preemption and GPU watchdog checks in GpuScheduler().
  void ExitCommandProcessingEarly() { commands_to_process_ = 0; }

  void ProcessPendingReadPixels();
  void FinishReadPixels(const cmds::ReadPixels& c, GLuint buffer);

  // Generate a member function prototype for each command in an automated and
  // typesafe way.
#define GLES2_CMD_OP(name) \
  Error Handle##name(uint32 immediate_data_size, const void* data);

  GLES2_COMMAND_LIST(GLES2_CMD_OP)

  #undef GLES2_CMD_OP

  // The GL context this decoder renders to on behalf of the client.
  scoped_refptr<gfx::GLSurface> surface_;
  scoped_refptr<gfx::GLContext> context_;

  // The ContextGroup for this decoder uses to track resources.
  scoped_refptr<ContextGroup> group_;

  DebugMarkerManager debug_marker_manager_;
  Logger logger_;

  // All the state for this context.
  ContextState state_;

  // Current width and height of the offscreen frame buffer.
  gfx::Size offscreen_size_;

  // Util to help with GL.
  GLES2Util util_;

  // unpack flip y as last set by glPixelStorei
  bool unpack_flip_y_;

  // unpack (un)premultiply alpha as last set by glPixelStorei
  bool unpack_premultiply_alpha_;
  bool unpack_unpremultiply_alpha_;

  // The buffer we bind to attrib 0 since OpenGL requires it (ES does not).
  GLuint attrib_0_buffer_id_;

  // The value currently in attrib_0.
  Vec4 attrib_0_value_;

  // Whether or not the attrib_0 buffer holds the attrib_0_value.
  bool attrib_0_buffer_matches_value_;

  // The size of attrib 0.
  GLsizei attrib_0_size_;

  // The buffer used to simulate GL_FIXED attribs.
  GLuint fixed_attrib_buffer_id_;

  // The size of fiixed attrib buffer.
  GLsizei fixed_attrib_buffer_size_;

  // The offscreen frame buffer that the client renders to. With EGL, the
  // depth and stencil buffers are separate. With regular GL there is a single
  // packed depth stencil buffer in offscreen_target_depth_render_buffer_.
  // offscreen_target_stencil_render_buffer_ is unused.
  scoped_ptr<BackFramebuffer> offscreen_target_frame_buffer_;
  scoped_ptr<BackTexture> offscreen_target_color_texture_;
  scoped_ptr<BackRenderbuffer> offscreen_target_color_render_buffer_;
  scoped_ptr<BackRenderbuffer> offscreen_target_depth_render_buffer_;
  scoped_ptr<BackRenderbuffer> offscreen_target_stencil_render_buffer_;
  GLenum offscreen_target_color_format_;
  GLenum offscreen_target_depth_format_;
  GLenum offscreen_target_stencil_format_;
  GLsizei offscreen_target_samples_;
  GLboolean offscreen_target_buffer_preserved_;

  // The copy that is saved when SwapBuffers is called.
  scoped_ptr<BackFramebuffer> offscreen_saved_frame_buffer_;
  scoped_ptr<BackTexture> offscreen_saved_color_texture_;
  scoped_refptr<TextureRef>
      offscreen_saved_color_texture_info_;

  // The copy that is used as the destination for multi-sample resolves.
  scoped_ptr<BackFramebuffer> offscreen_resolved_frame_buffer_;
  scoped_ptr<BackTexture> offscreen_resolved_color_texture_;
  GLenum offscreen_saved_color_format_;

  scoped_ptr<QueryManager> query_manager_;

  scoped_ptr<VertexArrayManager> vertex_array_manager_;

  scoped_ptr<ImageManager> image_manager_;

  base::Callback<void(gfx::Size, float)> resize_callback_;

  WaitSyncPointCallback wait_sync_point_callback_;

  ShaderCacheCallback shader_cache_callback_;

  scoped_ptr<AsyncPixelTransferManager> async_pixel_transfer_manager_;

  // The format of the back buffer_
  GLenum back_buffer_color_format_;
  bool back_buffer_has_depth_;
  bool back_buffer_has_stencil_;

  bool surfaceless_;

  // Backbuffer attachments that are currently undefined.
  uint32 backbuffer_needs_clear_bits_;

  // The current decoder error communicates the decoder error through command
  // processing functions that do not return the error value. Should be set only
  // if not returning an error.
  error::Error current_decoder_error_;

  bool use_shader_translator_;
  scoped_refptr<ShaderTranslatorInterface> vertex_translator_;
  scoped_refptr<ShaderTranslatorInterface> fragment_translator_;

  DisallowedFeatures disallowed_features_;

  // Cached from ContextGroup
  const Validators* validators_;
  scoped_refptr<FeatureInfo> feature_info_;

  int frame_number_;

  // Number of commands remaining to be processed in DoCommands().
  int commands_to_process_;

  bool has_robustness_extension_;
  error::ContextLostReason context_lost_reason_;
  bool context_was_lost_;
  bool reset_by_robustness_extension_;
  bool supports_post_sub_buffer_;

  // These flags are used to override the state of the shared feature_info_
  // member.  Because the same FeatureInfo instance may be shared among many
  // contexts, the assumptions on the availablity of extensions in WebGL
  // contexts may be broken.  These flags override the shared state to preserve
  // WebGL semantics.
  bool force_webgl_glsl_validation_;
  bool derivatives_explicitly_enabled_;
  bool frag_depth_explicitly_enabled_;
  bool draw_buffers_explicitly_enabled_;
  bool shader_texture_lod_explicitly_enabled_;

  bool compile_shader_always_succeeds_;

  // An optional behaviour to lose the context and group when OOM.
  bool lose_context_when_out_of_memory_;

  // Log extra info.
  bool service_logging_;

#if defined(OS_MACOSX)
  typedef std::map<GLuint, IOSurfaceRef> TextureToIOSurfaceMap;
  TextureToIOSurfaceMap texture_to_io_surface_map_;
#endif

  scoped_ptr<CopyTextureCHROMIUMResourceManager> copy_texture_CHROMIUM_;
  scoped_ptr<ClearFramebufferResourceManager> clear_framebuffer_blit_;

  // Cached values of the currently assigned viewport dimensions.
  GLsizei viewport_max_width_;
  GLsizei viewport_max_height_;

  // Command buffer stats.
  base::TimeDelta total_processing_commands_time_;

  // States related to each manager.
  DecoderTextureState texture_state_;
  DecoderFramebufferState framebuffer_state_;

  scoped_ptr<GPUTracer> gpu_tracer_;
  scoped_ptr<GPUStateTracer> gpu_state_tracer_;
  const unsigned char* cb_command_trace_category_;
  const unsigned char* gpu_decoder_category_;
  int gpu_trace_level_;
  bool gpu_trace_commands_;
  bool gpu_debug_commands_;

  std::queue<linked_ptr<FenceCallback> > pending_readpixel_fences_;

  // Used to validate multisample renderbuffers if needed
  GLuint validation_texture_;
  GLuint validation_fbo_multisample_;
  GLuint validation_fbo_;

  typedef gpu::gles2::GLES2Decoder::Error (GLES2DecoderImpl::*CmdHandler)(
      uint32 immediate_data_size,
      const void* data);

  // A struct to hold info about each command.
  struct CommandInfo {
    CmdHandler cmd_handler;
    uint8 arg_flags;   // How to handle the arguments for this command
    uint8 cmd_flags;   // How to handle this command
    uint16 arg_count;  // How many arguments are expected for this command.
  };

  // A table of CommandInfo for all the commands.
  static const CommandInfo command_info[kNumCommands - kStartPoint];

  DISALLOW_COPY_AND_ASSIGN(GLES2DecoderImpl);
};

const GLES2DecoderImpl::CommandInfo GLES2DecoderImpl::command_info[] = {
#define GLES2_CMD_OP(name)                                   \
  {                                                          \
    &GLES2DecoderImpl::Handle##name, cmds::name::kArgFlags,  \
        cmds::name::cmd_flags,                               \
        sizeof(cmds::name) / sizeof(CommandBufferEntry) - 1, \
  }                                                          \
  , /* NOLINT */
    GLES2_COMMAND_LIST(GLES2_CMD_OP)
#undef GLES2_CMD_OP
};

ScopedGLErrorSuppressor::ScopedGLErrorSuppressor(
    const char* function_name, ErrorState* error_state)
    : function_name_(function_name),
      error_state_(error_state) {
  ERRORSTATE_COPY_REAL_GL_ERRORS_TO_WRAPPER(error_state_, function_name_);
}

ScopedGLErrorSuppressor::~ScopedGLErrorSuppressor() {
  ERRORSTATE_CLEAR_REAL_GL_ERRORS(error_state_, function_name_);
}

static void RestoreCurrentTextureBindings(ContextState* state, GLenum target) {
  TextureUnit& info = state->texture_units[0];
  GLuint last_id;
  scoped_refptr<TextureRef> texture_ref;
  switch (target) {
    case GL_TEXTURE_2D:
      texture_ref = info.bound_texture_2d;
      break;
    case GL_TEXTURE_CUBE_MAP:
      texture_ref = info.bound_texture_cube_map;
      break;
    case GL_TEXTURE_EXTERNAL_OES:
      texture_ref = info.bound_texture_external_oes;
      break;
    case GL_TEXTURE_RECTANGLE_ARB:
      texture_ref = info.bound_texture_rectangle_arb;
      break;
    default:
      NOTREACHED();
      break;
  }
  if (texture_ref.get()) {
    last_id = texture_ref->service_id();
  } else {
    last_id = 0;
  }

  glBindTexture(target, last_id);
  glActiveTexture(GL_TEXTURE0 + state->active_texture_unit);
}

ScopedTextureBinder::ScopedTextureBinder(ContextState* state,
                                         GLuint id,
                                         GLenum target)
    : state_(state),
      target_(target) {
  ScopedGLErrorSuppressor suppressor(
      "ScopedTextureBinder::ctor", state_->GetErrorState());

  // TODO(apatrick): Check if there are any other states that need to be reset
  // before binding a new texture.
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(target, id);
}

ScopedTextureBinder::~ScopedTextureBinder() {
  ScopedGLErrorSuppressor suppressor(
      "ScopedTextureBinder::dtor", state_->GetErrorState());
  RestoreCurrentTextureBindings(state_, target_);
}

ScopedRenderBufferBinder::ScopedRenderBufferBinder(ContextState* state,
                                                   GLuint id)
    : state_(state) {
  ScopedGLErrorSuppressor suppressor(
      "ScopedRenderBufferBinder::ctor", state_->GetErrorState());
  glBindRenderbufferEXT(GL_RENDERBUFFER, id);
}

ScopedRenderBufferBinder::~ScopedRenderBufferBinder() {
  ScopedGLErrorSuppressor suppressor(
      "ScopedRenderBufferBinder::dtor", state_->GetErrorState());
  state_->RestoreRenderbufferBindings();
}

ScopedFrameBufferBinder::ScopedFrameBufferBinder(GLES2DecoderImpl* decoder,
                                                 GLuint id)
    : decoder_(decoder) {
  ScopedGLErrorSuppressor suppressor(
      "ScopedFrameBufferBinder::ctor", decoder_->GetErrorState());
  glBindFramebufferEXT(GL_FRAMEBUFFER, id);
  decoder->OnFboChanged();
}

ScopedFrameBufferBinder::~ScopedFrameBufferBinder() {
  ScopedGLErrorSuppressor suppressor(
      "ScopedFrameBufferBinder::dtor", decoder_->GetErrorState());
  decoder_->RestoreCurrentFramebufferBindings();
}

ScopedResolvedFrameBufferBinder::ScopedResolvedFrameBufferBinder(
    GLES2DecoderImpl* decoder, bool enforce_internal_framebuffer, bool internal)
    : decoder_(decoder) {
  resolve_and_bind_ = (
      decoder_->offscreen_target_frame_buffer_.get() &&
      decoder_->IsOffscreenBufferMultisampled() &&
      (!decoder_->framebuffer_state_.bound_read_framebuffer.get() ||
       enforce_internal_framebuffer));
  if (!resolve_and_bind_)
    return;

  ScopedGLErrorSuppressor suppressor(
      "ScopedResolvedFrameBufferBinder::ctor", decoder_->GetErrorState());
  glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT,
                       decoder_->offscreen_target_frame_buffer_->id());
  GLuint targetid;
  if (internal) {
    if (!decoder_->offscreen_resolved_frame_buffer_.get()) {
      decoder_->offscreen_resolved_frame_buffer_.reset(
          new BackFramebuffer(decoder_));
      decoder_->offscreen_resolved_frame_buffer_->Create();
      decoder_->offscreen_resolved_color_texture_.reset(
          new BackTexture(decoder->memory_tracker(), &decoder->state_));
      decoder_->offscreen_resolved_color_texture_->Create();

      DCHECK(decoder_->offscreen_saved_color_format_);
      decoder_->offscreen_resolved_color_texture_->AllocateStorage(
          decoder_->offscreen_size_, decoder_->offscreen_saved_color_format_,
          false);
      decoder_->offscreen_resolved_frame_buffer_->AttachRenderTexture(
          decoder_->offscreen_resolved_color_texture_.get());
      if (decoder_->offscreen_resolved_frame_buffer_->CheckStatus() !=
          GL_FRAMEBUFFER_COMPLETE) {
        LOG(ERROR) << "ScopedResolvedFrameBufferBinder failed "
                   << "because offscreen resolved FBO was incomplete.";
        return;
      }
    }
    targetid = decoder_->offscreen_resolved_frame_buffer_->id();
  } else {
    targetid = decoder_->offscreen_saved_frame_buffer_->id();
  }
  glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, targetid);
  const int width = decoder_->offscreen_size_.width();
  const int height = decoder_->offscreen_size_.height();
  decoder->state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);
  decoder->BlitFramebufferHelper(0,
                                 0,
                                 width,
                                 height,
                                 0,
                                 0,
                                 width,
                                 height,
                                 GL_COLOR_BUFFER_BIT,
                                 GL_NEAREST);
  glBindFramebufferEXT(GL_FRAMEBUFFER, targetid);
}

ScopedResolvedFrameBufferBinder::~ScopedResolvedFrameBufferBinder() {
  if (!resolve_and_bind_)
    return;

  ScopedGLErrorSuppressor suppressor(
      "ScopedResolvedFrameBufferBinder::dtor", decoder_->GetErrorState());
  decoder_->RestoreCurrentFramebufferBindings();
  if (decoder_->state_.enable_flags.scissor_test) {
    decoder_->state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, true);
  }
}

BackTexture::BackTexture(
    MemoryTracker* memory_tracker,
    ContextState* state)
    : memory_tracker_(memory_tracker, MemoryTracker::kUnmanaged),
      state_(state),
      bytes_allocated_(0),
      id_(0) {
}

BackTexture::~BackTexture() {
  // This does not destroy the render texture because that would require that
  // the associated GL context was current. Just check that it was explicitly
  // destroyed.
  DCHECK_EQ(id_, 0u);
}

void BackTexture::Create() {
  ScopedGLErrorSuppressor suppressor("BackTexture::Create",
                                     state_->GetErrorState());
  Destroy();
  glGenTextures(1, &id_);
  ScopedTextureBinder binder(state_, id_, GL_TEXTURE_2D);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  // TODO(apatrick): Attempt to diagnose crbug.com/97775. If SwapBuffers is
  // never called on an offscreen context, no data will ever be uploaded to the
  // saved offscreen color texture (it is deferred until to when SwapBuffers
  // is called). My idea is that some nvidia drivers might have a bug where
  // deleting a texture that has never been populated might cause a
  // crash.
  glTexImage2D(
      GL_TEXTURE_2D, 0, GL_RGBA, 16, 16, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

  bytes_allocated_ = 16u * 16u * 4u;
  memory_tracker_.TrackMemAlloc(bytes_allocated_);
}

bool BackTexture::AllocateStorage(
    const gfx::Size& size, GLenum format, bool zero) {
  DCHECK_NE(id_, 0u);
  ScopedGLErrorSuppressor suppressor("BackTexture::AllocateStorage",
                                     state_->GetErrorState());
  ScopedTextureBinder binder(state_, id_, GL_TEXTURE_2D);
  uint32 image_size = 0;
  GLES2Util::ComputeImageDataSizes(
      size.width(), size.height(), 1, format, GL_UNSIGNED_BYTE, 8, &image_size,
      NULL, NULL);

  if (!memory_tracker_.EnsureGPUMemoryAvailable(image_size)) {
    return false;
  }

  scoped_ptr<char[]> zero_data;
  if (zero) {
    zero_data.reset(new char[image_size]);
    memset(zero_data.get(), 0, image_size);
  }

  glTexImage2D(GL_TEXTURE_2D,
               0,  // mip level
               format,
               size.width(),
               size.height(),
               0,  // border
               format,
               GL_UNSIGNED_BYTE,
               zero_data.get());

  size_ = size;

  bool success = glGetError() == GL_NO_ERROR;
  if (success) {
    memory_tracker_.TrackMemFree(bytes_allocated_);
    bytes_allocated_ = image_size;
    memory_tracker_.TrackMemAlloc(bytes_allocated_);
  }
  return success;
}

void BackTexture::Copy(const gfx::Size& size, GLenum format) {
  DCHECK_NE(id_, 0u);
  ScopedGLErrorSuppressor suppressor("BackTexture::Copy",
                                     state_->GetErrorState());
  ScopedTextureBinder binder(state_, id_, GL_TEXTURE_2D);
  glCopyTexImage2D(GL_TEXTURE_2D,
                   0,  // level
                   format,
                   0, 0,
                   size.width(),
                   size.height(),
                   0);  // border
}

void BackTexture::Destroy() {
  if (id_ != 0) {
    ScopedGLErrorSuppressor suppressor("BackTexture::Destroy",
                                       state_->GetErrorState());
    glDeleteTextures(1, &id_);
    id_ = 0;
  }
  memory_tracker_.TrackMemFree(bytes_allocated_);
  bytes_allocated_ = 0;
}

void BackTexture::Invalidate() {
  id_ = 0;
}

BackRenderbuffer::BackRenderbuffer(
    RenderbufferManager* renderbuffer_manager,
    MemoryTracker* memory_tracker,
    ContextState* state)
    : renderbuffer_manager_(renderbuffer_manager),
      memory_tracker_(memory_tracker, MemoryTracker::kUnmanaged),
      state_(state),
      bytes_allocated_(0),
      id_(0) {
}

BackRenderbuffer::~BackRenderbuffer() {
  // This does not destroy the render buffer because that would require that
  // the associated GL context was current. Just check that it was explicitly
  // destroyed.
  DCHECK_EQ(id_, 0u);
}

void BackRenderbuffer::Create() {
  ScopedGLErrorSuppressor suppressor("BackRenderbuffer::Create",
                                     state_->GetErrorState());
  Destroy();
  glGenRenderbuffersEXT(1, &id_);
}

bool BackRenderbuffer::AllocateStorage(const FeatureInfo* feature_info,
                                       const gfx::Size& size,
                                       GLenum format,
                                       GLsizei samples) {
  ScopedGLErrorSuppressor suppressor(
      "BackRenderbuffer::AllocateStorage", state_->GetErrorState());
  ScopedRenderBufferBinder binder(state_, id_);

  uint32 estimated_size = 0;
  if (!renderbuffer_manager_->ComputeEstimatedRenderbufferSize(
           size.width(), size.height(), samples, format, &estimated_size)) {
    return false;
  }

  if (!memory_tracker_.EnsureGPUMemoryAvailable(estimated_size)) {
    return false;
  }

  if (samples <= 1) {
    glRenderbufferStorageEXT(GL_RENDERBUFFER,
                             format,
                             size.width(),
                             size.height());
  } else {
    GLES2DecoderImpl::RenderbufferStorageMultisampleHelper(feature_info,
                                                           GL_RENDERBUFFER,
                                                           samples,
                                                           format,
                                                           size.width(),
                                                           size.height());
  }
  bool success = glGetError() == GL_NO_ERROR;
  if (success) {
    // Mark the previously allocated bytes as free.
    memory_tracker_.TrackMemFree(bytes_allocated_);
    bytes_allocated_ = estimated_size;
    // Track the newly allocated bytes.
    memory_tracker_.TrackMemAlloc(bytes_allocated_);
  }
  return success;
}

void BackRenderbuffer::Destroy() {
  if (id_ != 0) {
    ScopedGLErrorSuppressor suppressor("BackRenderbuffer::Destroy",
                                       state_->GetErrorState());
    glDeleteRenderbuffersEXT(1, &id_);
    id_ = 0;
  }
  memory_tracker_.TrackMemFree(bytes_allocated_);
  bytes_allocated_ = 0;
}

void BackRenderbuffer::Invalidate() {
  id_ = 0;
}

BackFramebuffer::BackFramebuffer(GLES2DecoderImpl* decoder)
    : decoder_(decoder),
      id_(0) {
}

BackFramebuffer::~BackFramebuffer() {
  // This does not destroy the frame buffer because that would require that
  // the associated GL context was current. Just check that it was explicitly
  // destroyed.
  DCHECK_EQ(id_, 0u);
}

void BackFramebuffer::Create() {
  ScopedGLErrorSuppressor suppressor("BackFramebuffer::Create",
                                     decoder_->GetErrorState());
  Destroy();
  glGenFramebuffersEXT(1, &id_);
}

void BackFramebuffer::AttachRenderTexture(BackTexture* texture) {
  DCHECK_NE(id_, 0u);
  ScopedGLErrorSuppressor suppressor(
      "BackFramebuffer::AttachRenderTexture", decoder_->GetErrorState());
  ScopedFrameBufferBinder binder(decoder_, id_);
  GLuint attach_id = texture ? texture->id() : 0;
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER,
                            GL_COLOR_ATTACHMENT0,
                            GL_TEXTURE_2D,
                            attach_id,
                            0);
}

void BackFramebuffer::AttachRenderBuffer(GLenum target,
                                         BackRenderbuffer* render_buffer) {
  DCHECK_NE(id_, 0u);
  ScopedGLErrorSuppressor suppressor(
      "BackFramebuffer::AttachRenderBuffer", decoder_->GetErrorState());
  ScopedFrameBufferBinder binder(decoder_, id_);
  GLuint attach_id = render_buffer ? render_buffer->id() : 0;
  glFramebufferRenderbufferEXT(GL_FRAMEBUFFER,
                               target,
                               GL_RENDERBUFFER,
                               attach_id);
}

void BackFramebuffer::Destroy() {
  if (id_ != 0) {
    ScopedGLErrorSuppressor suppressor("BackFramebuffer::Destroy",
                                       decoder_->GetErrorState());
    glDeleteFramebuffersEXT(1, &id_);
    id_ = 0;
  }
}

void BackFramebuffer::Invalidate() {
  id_ = 0;
}

GLenum BackFramebuffer::CheckStatus() {
  DCHECK_NE(id_, 0u);
  ScopedGLErrorSuppressor suppressor("BackFramebuffer::CheckStatus",
                                     decoder_->GetErrorState());
  ScopedFrameBufferBinder binder(decoder_, id_);
  return glCheckFramebufferStatusEXT(GL_FRAMEBUFFER);
}

GLES2Decoder* GLES2Decoder::Create(ContextGroup* group) {
  return new GLES2DecoderImpl(group);
}

GLES2DecoderImpl::GLES2DecoderImpl(ContextGroup* group)
    : GLES2Decoder(),
      group_(group),
      logger_(&debug_marker_manager_),
      state_(group_->feature_info(), this, &logger_),
      unpack_flip_y_(false),
      unpack_premultiply_alpha_(false),
      unpack_unpremultiply_alpha_(false),
      attrib_0_buffer_id_(0),
      attrib_0_buffer_matches_value_(true),
      attrib_0_size_(0),
      fixed_attrib_buffer_id_(0),
      fixed_attrib_buffer_size_(0),
      offscreen_target_color_format_(0),
      offscreen_target_depth_format_(0),
      offscreen_target_stencil_format_(0),
      offscreen_target_samples_(0),
      offscreen_target_buffer_preserved_(true),
      offscreen_saved_color_format_(0),
      back_buffer_color_format_(0),
      back_buffer_has_depth_(false),
      back_buffer_has_stencil_(false),
      surfaceless_(false),
      backbuffer_needs_clear_bits_(0),
      current_decoder_error_(error::kNoError),
      use_shader_translator_(true),
      validators_(group_->feature_info()->validators()),
      feature_info_(group_->feature_info()),
      frame_number_(0),
      has_robustness_extension_(false),
      context_lost_reason_(error::kUnknown),
      context_was_lost_(false),
      reset_by_robustness_extension_(false),
      supports_post_sub_buffer_(false),
      force_webgl_glsl_validation_(false),
      derivatives_explicitly_enabled_(false),
      frag_depth_explicitly_enabled_(false),
      draw_buffers_explicitly_enabled_(false),
      shader_texture_lod_explicitly_enabled_(false),
      compile_shader_always_succeeds_(false),
      lose_context_when_out_of_memory_(false),
      service_logging_(base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableGPUServiceLoggingGPU)),
      viewport_max_width_(0),
      viewport_max_height_(0),
      texture_state_(group_->feature_info()
                         ->workarounds()
                         .texsubimage2d_faster_than_teximage2d),
      cb_command_trace_category_(TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED(
          TRACE_DISABLED_BY_DEFAULT("cb_command"))),
      gpu_decoder_category_(TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED(
          TRACE_DISABLED_BY_DEFAULT("gpu_decoder"))),
      gpu_trace_level_(2),
      gpu_trace_commands_(false),
      gpu_debug_commands_(false),
      validation_texture_(0),
      validation_fbo_multisample_(0),
      validation_fbo_(0) {
  DCHECK(group);

  attrib_0_value_.v[0] = 0.0f;
  attrib_0_value_.v[1] = 0.0f;
  attrib_0_value_.v[2] = 0.0f;
  attrib_0_value_.v[3] = 1.0f;

  // The shader translator is used for WebGL even when running on EGL
  // because additional restrictions are needed (like only enabling
  // GL_OES_standard_derivatives on demand).  It is used for the unit
  // tests because GLES2DecoderWithShaderTest.GetShaderInfoLogValidArgs passes
  // the empty string to CompileShader and this is not a valid shader.
  if (gfx::GetGLImplementation() == gfx::kGLImplementationMockGL ||
      base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kDisableGLSLTranslator)) {
    use_shader_translator_ = false;
  }
}

GLES2DecoderImpl::~GLES2DecoderImpl() {
}

bool GLES2DecoderImpl::Initialize(
    const scoped_refptr<gfx::GLSurface>& surface,
    const scoped_refptr<gfx::GLContext>& context,
    bool offscreen,
    const gfx::Size& offscreen_size,
    const DisallowedFeatures& disallowed_features,
    const std::vector<int32>& attribs) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::Initialize");
  DCHECK(context->IsCurrent(surface.get()));
  DCHECK(!context_.get());

  ContextCreationAttribHelper attrib_parser;
  if (!attrib_parser.Parse(attribs))
    return false;

  surfaceless_ = surface->IsSurfaceless() && !offscreen;

  set_initialized();
  gpu_state_tracer_ = GPUStateTracer::Create(&state_);

  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableGPUDebugging)) {
    set_debug(true);
  }

  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableGPUCommandLogging)) {
    set_log_commands(true);
  }

  compile_shader_always_succeeds_ =
      base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kCompileShaderAlwaysSucceeds);

  // Take ownership of the context and surface. The surface can be replaced with
  // SetSurface.
  context_ = context;
  surface_ = surface;

  // Create GPU Tracer for timing values.
  gpu_tracer_.reset(new GPUTracer(this));

  // Save the loseContextWhenOutOfMemory context creation attribute.
  lose_context_when_out_of_memory_ =
      attrib_parser.lose_context_when_out_of_memory;

  // If the failIfMajorPerformanceCaveat context creation attribute was true
  // and we are using a software renderer, fail.
  if (attrib_parser.fail_if_major_perf_caveat &&
      feature_info_->feature_flags().is_swiftshader) {
    group_ = NULL;  // Must not destroy ContextGroup if it is not initialized.
    Destroy(true);
    return false;
  }

  if (!group_->Initialize(this, disallowed_features)) {
    LOG(ERROR) << "GpuScheduler::InitializeCommon failed because group "
               << "failed to initialize.";
    group_ = NULL;  // Must not destroy ContextGroup if it is not initialized.
    Destroy(true);
    return false;
  }
  CHECK_GL_ERROR();

  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableUnsafeES3APIs) &&
      attrib_parser.es3_context_required &&
      feature_info_->IsES3Capable()) {
    feature_info_->EnableES3Validators();
    set_unsafe_es3_apis_enabled(true);
  }

  disallowed_features_ = disallowed_features;

  state_.attrib_values.resize(group_->max_vertex_attribs());
  vertex_array_manager_.reset(new VertexArrayManager());

  GLuint default_vertex_attrib_service_id = 0;
  if (features().native_vertex_array_object) {
    glGenVertexArraysOES(1, &default_vertex_attrib_service_id);
    glBindVertexArrayOES(default_vertex_attrib_service_id);
  }

  state_.default_vertex_attrib_manager =
      CreateVertexAttribManager(0, default_vertex_attrib_service_id, false);

  state_.default_vertex_attrib_manager->Initialize(
      group_->max_vertex_attribs(),
      feature_info_->workarounds().init_vertex_attributes);

  // vertex_attrib_manager is set to default_vertex_attrib_manager by this call
  DoBindVertexArrayOES(0);

  query_manager_.reset(new QueryManager(this, feature_info_.get()));

  image_manager_.reset(new ImageManager);

  util_.set_num_compressed_texture_formats(
      validators_->compressed_texture_format.GetValues().size());

  if (gfx::GetGLImplementation() != gfx::kGLImplementationEGLGLES2) {
    // We have to enable vertex array 0 on OpenGL or it won't render. Note that
    // OpenGL ES 2.0 does not have this issue.
    glEnableVertexAttribArray(0);
  }
  glGenBuffersARB(1, &attrib_0_buffer_id_);
  glBindBuffer(GL_ARRAY_BUFFER, attrib_0_buffer_id_);
  glVertexAttribPointer(0, 1, GL_FLOAT, GL_FALSE, 0, NULL);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glGenBuffersARB(1, &fixed_attrib_buffer_id_);

  state_.texture_units.resize(group_->max_texture_units());
  for (uint32 tt = 0; tt < state_.texture_units.size(); ++tt) {
    glActiveTexture(GL_TEXTURE0 + tt);
    // We want the last bind to be 2D.
    TextureRef* ref;
    if (features().oes_egl_image_external) {
      ref = texture_manager()->GetDefaultTextureInfo(
          GL_TEXTURE_EXTERNAL_OES);
      state_.texture_units[tt].bound_texture_external_oes = ref;
      glBindTexture(GL_TEXTURE_EXTERNAL_OES, ref ? ref->service_id() : 0);
    }
    if (features().arb_texture_rectangle) {
      ref = texture_manager()->GetDefaultTextureInfo(
          GL_TEXTURE_RECTANGLE_ARB);
      state_.texture_units[tt].bound_texture_rectangle_arb = ref;
      glBindTexture(GL_TEXTURE_RECTANGLE_ARB, ref ? ref->service_id() : 0);
    }
    ref = texture_manager()->GetDefaultTextureInfo(GL_TEXTURE_CUBE_MAP);
    state_.texture_units[tt].bound_texture_cube_map = ref;
    glBindTexture(GL_TEXTURE_CUBE_MAP, ref ? ref->service_id() : 0);
    ref = texture_manager()->GetDefaultTextureInfo(GL_TEXTURE_2D);
    state_.texture_units[tt].bound_texture_2d = ref;
    glBindTexture(GL_TEXTURE_2D, ref ? ref->service_id() : 0);
  }
  glActiveTexture(GL_TEXTURE0);
  CHECK_GL_ERROR();

  if (offscreen) {
    if (attrib_parser.samples > 0 && attrib_parser.sample_buffers > 0 &&
        features().chromium_framebuffer_multisample) {
      // Per ext_framebuffer_multisample spec, need max bound on sample count.
      // max_sample_count must be initialized to a sane value.  If
      // glGetIntegerv() throws a GL error, it leaves its argument unchanged.
      GLint max_sample_count = 1;
      glGetIntegerv(GL_MAX_SAMPLES_EXT, &max_sample_count);
      offscreen_target_samples_ = std::min(attrib_parser.samples,
                                           max_sample_count);
    } else {
      offscreen_target_samples_ = 1;
    }
    offscreen_target_buffer_preserved_ = attrib_parser.buffer_preserved;

    if (gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2) {
      const bool rgb8_supported =
          context_->HasExtension("GL_OES_rgb8_rgba8");
      // The only available default render buffer formats in GLES2 have very
      // little precision.  Don't enable multisampling unless 8-bit render
      // buffer formats are available--instead fall back to 8-bit textures.
      if (rgb8_supported && offscreen_target_samples_ > 1) {
        offscreen_target_color_format_ = attrib_parser.alpha_size > 0 ?
            GL_RGBA8 : GL_RGB8;
      } else {
        offscreen_target_samples_ = 1;
        offscreen_target_color_format_ = attrib_parser.alpha_size > 0 ?
            GL_RGBA : GL_RGB;
      }

      // ANGLE only supports packed depth/stencil formats, so use it if it is
      // available.
      const bool depth24_stencil8_supported =
          feature_info_->feature_flags().packed_depth24_stencil8;
      VLOG(1) << "GL_OES_packed_depth_stencil "
              << (depth24_stencil8_supported ? "" : "not ") << "supported.";
      if ((attrib_parser.depth_size > 0 || attrib_parser.stencil_size > 0) &&
          depth24_stencil8_supported) {
        offscreen_target_depth_format_ = GL_DEPTH24_STENCIL8;
        offscreen_target_stencil_format_ = 0;
      } else {
        // It may be the case that this depth/stencil combination is not
        // supported, but this will be checked later by CheckFramebufferStatus.
        offscreen_target_depth_format_ = attrib_parser.depth_size > 0 ?
            GL_DEPTH_COMPONENT16 : 0;
        offscreen_target_stencil_format_ = attrib_parser.stencil_size > 0 ?
            GL_STENCIL_INDEX8 : 0;
      }
    } else {
      offscreen_target_color_format_ = attrib_parser.alpha_size > 0 ?
          GL_RGBA : GL_RGB;

      // If depth is requested at all, use the packed depth stencil format if
      // it's available, as some desktop GL drivers don't support any non-packed
      // formats for depth attachments.
      const bool depth24_stencil8_supported =
          feature_info_->feature_flags().packed_depth24_stencil8;
      VLOG(1) << "GL_EXT_packed_depth_stencil "
              << (depth24_stencil8_supported ? "" : "not ") << "supported.";

      if ((attrib_parser.depth_size > 0 || attrib_parser.stencil_size > 0) &&
          depth24_stencil8_supported) {
        offscreen_target_depth_format_ = GL_DEPTH24_STENCIL8;
        offscreen_target_stencil_format_ = 0;
      } else {
        offscreen_target_depth_format_ = attrib_parser.depth_size > 0 ?
            GL_DEPTH_COMPONENT : 0;
        offscreen_target_stencil_format_ = attrib_parser.stencil_size > 0 ?
            GL_STENCIL_INDEX : 0;
      }
    }

    offscreen_saved_color_format_ = attrib_parser.alpha_size > 0 ?
        GL_RGBA : GL_RGB;

    // Create the target frame buffer. This is the one that the client renders
    // directly to.
    offscreen_target_frame_buffer_.reset(new BackFramebuffer(this));
    offscreen_target_frame_buffer_->Create();
    // Due to GLES2 format limitations, either the color texture (for
    // non-multisampling) or the color render buffer (for multisampling) will be
    // attached to the offscreen frame buffer.  The render buffer has more
    // limited formats available to it, but the texture can't do multisampling.
    if (IsOffscreenBufferMultisampled()) {
      offscreen_target_color_render_buffer_.reset(new BackRenderbuffer(
          renderbuffer_manager(), memory_tracker(), &state_));
      offscreen_target_color_render_buffer_->Create();
    } else {
      offscreen_target_color_texture_.reset(new BackTexture(
          memory_tracker(), &state_));
      offscreen_target_color_texture_->Create();
    }
    offscreen_target_depth_render_buffer_.reset(new BackRenderbuffer(
        renderbuffer_manager(), memory_tracker(), &state_));
    offscreen_target_depth_render_buffer_->Create();
    offscreen_target_stencil_render_buffer_.reset(new BackRenderbuffer(
        renderbuffer_manager(), memory_tracker(), &state_));
    offscreen_target_stencil_render_buffer_->Create();

    // Create the saved offscreen texture. The target frame buffer is copied
    // here when SwapBuffers is called.
    offscreen_saved_frame_buffer_.reset(new BackFramebuffer(this));
    offscreen_saved_frame_buffer_->Create();
    //
    offscreen_saved_color_texture_.reset(new BackTexture(
        memory_tracker(), &state_));
    offscreen_saved_color_texture_->Create();

    // Allocate the render buffers at their initial size and check the status
    // of the frame buffers is okay.
    if (!ResizeOffscreenFrameBuffer(offscreen_size)) {
      LOG(ERROR) << "Could not allocate offscreen buffer storage.";
      Destroy(true);
      return false;
    }

    state_.viewport_width = offscreen_size.width();
    state_.viewport_height = offscreen_size.height();

    // Allocate the offscreen saved color texture.
    DCHECK(offscreen_saved_color_format_);
    offscreen_saved_color_texture_->AllocateStorage(
        gfx::Size(1, 1), offscreen_saved_color_format_, true);

    offscreen_saved_frame_buffer_->AttachRenderTexture(
        offscreen_saved_color_texture_.get());
    if (offscreen_saved_frame_buffer_->CheckStatus() !=
        GL_FRAMEBUFFER_COMPLETE) {
      LOG(ERROR) << "Offscreen saved FBO was incomplete.";
      Destroy(true);
      return false;
    }

    // Bind to the new default frame buffer (the offscreen target frame buffer).
    // This should now be associated with ID zero.
    DoBindFramebuffer(GL_FRAMEBUFFER, 0);
  } else {
    glBindFramebufferEXT(GL_FRAMEBUFFER, GetBackbufferServiceId());
    // These are NOT if the back buffer has these proprorties. They are
    // if we want the command buffer to enforce them regardless of what
    // the real backbuffer is assuming the real back buffer gives us more than
    // we ask for. In other words, if we ask for RGB and we get RGBA then we'll
    // make it appear RGB. If on the other hand we ask for RGBA nd get RGB we
    // can't do anything about that.

    if (!surfaceless_) {
      GLint v = 0;
      glGetIntegerv(GL_ALPHA_BITS, &v);
      // This checks if the user requested RGBA and we have RGBA then RGBA. If
      // the user requested RGB then RGB. If the user did not specify a
      // preference than use whatever we were given. Same for DEPTH and STENCIL.
      back_buffer_color_format_ =
          (attrib_parser.alpha_size != 0 && v > 0) ? GL_RGBA : GL_RGB;
      glGetIntegerv(GL_DEPTH_BITS, &v);
      back_buffer_has_depth_ = attrib_parser.depth_size != 0 && v > 0;
      glGetIntegerv(GL_STENCIL_BITS, &v);
      back_buffer_has_stencil_ = attrib_parser.stencil_size != 0 && v > 0;
    }

    state_.viewport_width = surface->GetSize().width();
    state_.viewport_height = surface->GetSize().height();
  }

  // OpenGL ES 2.0 implicitly enables the desktop GL capability
  // VERTEX_PROGRAM_POINT_SIZE and doesn't expose this enum. This fact
  // isn't well documented; it was discovered in the Khronos OpenGL ES
  // mailing list archives. It also implicitly enables the desktop GL
  // capability GL_POINT_SPRITE to provide access to the gl_PointCoord
  // variable in fragment shaders.
  if (gfx::GetGLImplementation() != gfx::kGLImplementationEGLGLES2) {
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
    glEnable(GL_POINT_SPRITE);
  }

  has_robustness_extension_ =
      context->HasExtension("GL_ARB_robustness") ||
      context->HasExtension("GL_KHR_robustness") ||
      context->HasExtension("GL_EXT_robustness");

  if (!InitializeShaderTranslator()) {
    return false;
  }

  GLint viewport_params[4] = { 0 };
  glGetIntegerv(GL_MAX_VIEWPORT_DIMS, viewport_params);
  viewport_max_width_ = viewport_params[0];
  viewport_max_height_ = viewport_params[1];

  state_.scissor_width = state_.viewport_width;
  state_.scissor_height = state_.viewport_height;

  // Set all the default state because some GL drivers get it wrong.
  state_.InitCapabilities(NULL);
  state_.InitState(NULL);
  glActiveTexture(GL_TEXTURE0 + state_.active_texture_unit);

  DoBindBuffer(GL_ARRAY_BUFFER, 0);
  DoBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  DoBindFramebuffer(GL_FRAMEBUFFER, 0);
  DoBindRenderbuffer(GL_RENDERBUFFER, 0);
  DoBindValueBufferCHROMIUM(GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM, 0);

  bool call_gl_clear = !surfaceless_;
#if defined(OS_ANDROID)
  // Temporary workaround for Android WebView because this clear ignores the
  // clip and corrupts that external UI of the App. Not calling glClear is ok
  // because the system already clears the buffer before each draw. Proper
  // fix might be setting the scissor clip properly before initialize. See
  // crbug.com/259023 for details.
  call_gl_clear = surface_->GetHandle();
#endif
  if (call_gl_clear) {
    // Clear the backbuffer.
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
  }

  supports_post_sub_buffer_ = surface->SupportsPostSubBuffer();
  if (feature_info_->workarounds()
          .disable_post_sub_buffers_for_onscreen_surfaces &&
      !surface->IsOffscreen())
    supports_post_sub_buffer_ = false;

  if (feature_info_->workarounds().reverse_point_sprite_coord_origin) {
    glPointParameteri(GL_POINT_SPRITE_COORD_ORIGIN, GL_LOWER_LEFT);
  }

  if (feature_info_->workarounds().unbind_fbo_on_context_switch) {
    context_->SetUnbindFboOnMakeCurrent();
  }

  // Only compositor contexts are known to use only the subset of GL
  // that can be safely migrated between the iGPU and the dGPU. Mark
  // those contexts as safe to forcibly transition between the GPUs.
  // http://crbug.com/180876, http://crbug.com/227228
  if (!offscreen)
    context_->SetSafeToForceGpuSwitch();

  async_pixel_transfer_manager_.reset(
      AsyncPixelTransferManager::Create(context.get()));
  async_pixel_transfer_manager_->Initialize(texture_manager());

  if (workarounds().gl_clear_broken) {
    DCHECK(!clear_framebuffer_blit_.get());
    LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glClearWorkaroundInit");
    clear_framebuffer_blit_.reset(new ClearFramebufferResourceManager(this));
    if (LOCAL_PEEK_GL_ERROR("glClearWorkaroundInit") != GL_NO_ERROR)
      return false;
  }

  framebuffer_manager()->AddObserver(this);

  return true;
}

Capabilities GLES2DecoderImpl::GetCapabilities() {
  DCHECK(initialized());

  Capabilities caps;
  caps.VisitPrecisions([](GLenum shader, GLenum type,
                          Capabilities::ShaderPrecision* shader_precision) {
    GLint range[2] = {0, 0};
    GLint precision = 0;
    GetShaderPrecisionFormatImpl(shader, type, range, &precision);
    shader_precision->min_range = range[0];
    shader_precision->max_range = range[1];
    shader_precision->precision = precision;
  });
  DoGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
                &caps.max_combined_texture_image_units);
  DoGetIntegerv(GL_MAX_CUBE_MAP_TEXTURE_SIZE, &caps.max_cube_map_texture_size);
  DoGetIntegerv(GL_MAX_FRAGMENT_UNIFORM_VECTORS,
                &caps.max_fragment_uniform_vectors);
  DoGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &caps.max_renderbuffer_size);
  DoGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &caps.max_texture_image_units);
  DoGetIntegerv(GL_MAX_TEXTURE_SIZE, &caps.max_texture_size);
  DoGetIntegerv(GL_MAX_VARYING_VECTORS, &caps.max_varying_vectors);
  DoGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &caps.max_vertex_attribs);
  DoGetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
                &caps.max_vertex_texture_image_units);
  DoGetIntegerv(GL_MAX_VERTEX_UNIFORM_VECTORS,
                &caps.max_vertex_uniform_vectors);
  DoGetIntegerv(GL_NUM_COMPRESSED_TEXTURE_FORMATS,
                &caps.num_compressed_texture_formats);
  DoGetIntegerv(GL_NUM_SHADER_BINARY_FORMATS, &caps.num_shader_binary_formats);
  DoGetIntegerv(GL_BIND_GENERATES_RESOURCE_CHROMIUM,
                &caps.bind_generates_resource_chromium);
  if (unsafe_es3_apis_enabled()) {
    // TODO(zmo): Note that some parameter values could be more than 32-bit,
    // but for now we clamp them to 32-bit max.
    DoGetIntegerv(GL_MAX_3D_TEXTURE_SIZE, &caps.max_3d_texture_size);
    DoGetIntegerv(GL_MAX_ARRAY_TEXTURE_LAYERS, &caps.max_array_texture_layers);
    DoGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &caps.max_color_attachments);
    DoGetIntegerv(GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS,
                  &caps.max_combined_fragment_uniform_components);
    DoGetIntegerv(GL_MAX_COMBINED_UNIFORM_BLOCKS,
                  &caps.max_combined_uniform_blocks);
    DoGetIntegerv(GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS,
                  &caps.max_combined_vertex_uniform_components);
    DoGetIntegerv(GL_MAX_DRAW_BUFFERS, &caps.max_draw_buffers);
    DoGetIntegerv(GL_MAX_ELEMENT_INDEX, &caps.max_element_index);
    DoGetIntegerv(GL_MAX_ELEMENTS_INDICES, &caps.max_elements_indices);
    DoGetIntegerv(GL_MAX_ELEMENTS_VERTICES, &caps.max_elements_vertices);
    DoGetIntegerv(GL_MAX_FRAGMENT_INPUT_COMPONENTS,
                  &caps.max_fragment_input_components);
    DoGetIntegerv(GL_MAX_FRAGMENT_UNIFORM_BLOCKS,
                  &caps.max_fragment_uniform_blocks);
    DoGetIntegerv(GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
                  &caps.max_fragment_uniform_components);
    DoGetIntegerv(GL_MAX_PROGRAM_TEXEL_OFFSET,
                  &caps.max_program_texel_offset);
    DoGetIntegerv(GL_MAX_SAMPLES, &caps.max_samples);
    DoGetIntegerv(GL_MAX_SERVER_WAIT_TIMEOUT, &caps.max_server_wait_timeout);
    DoGetIntegerv(GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS,
                  &caps.max_transform_feedback_interleaved_components);
    DoGetIntegerv(GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS,
                  &caps.max_transform_feedback_separate_attribs);
    DoGetIntegerv(GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS,
                  &caps.max_transform_feedback_separate_components);
    DoGetIntegerv(GL_MAX_UNIFORM_BLOCK_SIZE, &caps.max_uniform_block_size);
    DoGetIntegerv(GL_MAX_UNIFORM_BUFFER_BINDINGS,
                  &caps.max_uniform_buffer_bindings);
    DoGetIntegerv(GL_MAX_VARYING_COMPONENTS, &caps.max_varying_components);
    DoGetIntegerv(GL_MAX_VERTEX_OUTPUT_COMPONENTS,
                  &caps.max_vertex_output_components);
    DoGetIntegerv(GL_MAX_VERTEX_UNIFORM_BLOCKS,
                  &caps.max_vertex_uniform_blocks);
    DoGetIntegerv(GL_MAX_VERTEX_UNIFORM_COMPONENTS,
                  &caps.max_vertex_uniform_components);
    DoGetIntegerv(GL_MIN_PROGRAM_TEXEL_OFFSET, &caps.min_program_texel_offset);
    DoGetIntegerv(GL_NUM_EXTENSIONS, &caps.num_extensions);
    DoGetIntegerv(GL_NUM_PROGRAM_BINARY_FORMATS,
                  &caps.num_program_binary_formats);
    DoGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT,
                  &caps.uniform_buffer_offset_alignment);
    // TODO(zmo): once we switch to MANGLE, we should query version numbers.
    caps.major_version = 3;
    caps.minor_version = 0;
  }

  caps.egl_image_external =
      feature_info_->feature_flags().oes_egl_image_external;
  caps.texture_format_atc =
      feature_info_->feature_flags().ext_texture_format_atc;
  caps.texture_format_bgra8888 =
      feature_info_->feature_flags().ext_texture_format_bgra8888;
  caps.texture_format_dxt1 =
      feature_info_->feature_flags().ext_texture_format_dxt1;
  caps.texture_format_dxt5 =
      feature_info_->feature_flags().ext_texture_format_dxt5;
  caps.texture_format_etc1 =
      feature_info_->feature_flags().oes_compressed_etc1_rgb8_texture;
  caps.texture_format_etc1_npot =
      caps.texture_format_etc1 && !workarounds().etc1_power_of_two_only;
  caps.texture_rectangle = feature_info_->feature_flags().arb_texture_rectangle;
  caps.texture_usage = feature_info_->feature_flags().angle_texture_usage;
  caps.texture_storage = feature_info_->feature_flags().ext_texture_storage;
  caps.discard_framebuffer =
      feature_info_->feature_flags().ext_discard_framebuffer;
  caps.sync_query = feature_info_->feature_flags().chromium_sync_query;

#if defined(OS_MACOSX)
  // This is unconditionally true on mac, no need to test for it at runtime.
  caps.iosurface = true;
#endif

  caps.post_sub_buffer = supports_post_sub_buffer_;
  caps.image = true;

  caps.blend_equation_advanced =
      feature_info_->feature_flags().blend_equation_advanced;
  caps.blend_equation_advanced_coherent =
      feature_info_->feature_flags().blend_equation_advanced_coherent;
  caps.texture_rg = feature_info_->feature_flags().ext_texture_rg;
  return caps;
}

void GLES2DecoderImpl::UpdateCapabilities() {
  util_.set_num_compressed_texture_formats(
      validators_->compressed_texture_format.GetValues().size());
  util_.set_num_shader_binary_formats(
      validators_->shader_binary_format.GetValues().size());
}

bool GLES2DecoderImpl::InitializeShaderTranslator() {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::InitializeShaderTranslator");

  if (!use_shader_translator_) {
    return true;
  }
  ShBuiltInResources resources;
  ShInitBuiltInResources(&resources);
  resources.MaxVertexAttribs = group_->max_vertex_attribs();
  resources.MaxVertexUniformVectors =
      group_->max_vertex_uniform_vectors();
  resources.MaxVaryingVectors = group_->max_varying_vectors();
  resources.MaxVertexTextureImageUnits =
      group_->max_vertex_texture_image_units();
  resources.MaxCombinedTextureImageUnits = group_->max_texture_units();
  resources.MaxTextureImageUnits = group_->max_texture_image_units();
  resources.MaxFragmentUniformVectors =
      group_->max_fragment_uniform_vectors();
  resources.MaxDrawBuffers = group_->max_draw_buffers();
  resources.MaxExpressionComplexity = 256;
  resources.MaxCallStackDepth = 256;

  GLint range[2] = { 0, 0 };
  GLint precision = 0;
  GetShaderPrecisionFormatImpl(GL_FRAGMENT_SHADER, GL_HIGH_FLOAT,
                               range, &precision);
  resources.FragmentPrecisionHigh =
      PrecisionMeetsSpecForHighpFloat(range[0], range[1], precision);

  if (force_webgl_glsl_validation_) {
    resources.OES_standard_derivatives = derivatives_explicitly_enabled_;
    resources.EXT_frag_depth = frag_depth_explicitly_enabled_;
    resources.EXT_draw_buffers = draw_buffers_explicitly_enabled_;
    if (!draw_buffers_explicitly_enabled_)
      resources.MaxDrawBuffers = 1;
    resources.EXT_shader_texture_lod = shader_texture_lod_explicitly_enabled_;
    resources.NV_draw_buffers =
        draw_buffers_explicitly_enabled_ && features().nv_draw_buffers;
  } else {
    resources.OES_standard_derivatives =
        features().oes_standard_derivatives ? 1 : 0;
    resources.ARB_texture_rectangle =
        features().arb_texture_rectangle ? 1 : 0;
    resources.OES_EGL_image_external =
        features().oes_egl_image_external ? 1 : 0;
    resources.EXT_draw_buffers =
        features().ext_draw_buffers ? 1 : 0;
    resources.EXT_frag_depth =
        features().ext_frag_depth ? 1 : 0;
    resources.EXT_shader_texture_lod =
        features().ext_shader_texture_lod ? 1 : 0;
    resources.NV_draw_buffers =
        features().nv_draw_buffers ? 1 : 0;
  }

  ShShaderSpec shader_spec;
  if (force_webgl_glsl_validation_) {
    shader_spec = unsafe_es3_apis_enabled() ? SH_WEBGL2_SPEC : SH_WEBGL_SPEC;
  } else {
    shader_spec = unsafe_es3_apis_enabled() ? SH_GLES3_SPEC : SH_GLES2_SPEC;
  }

  if ((shader_spec == SH_WEBGL_SPEC || shader_spec == SH_WEBGL2_SPEC) &&
      features().enable_shader_name_hashing)
    resources.HashFunction = &CityHash64;
  else
    resources.HashFunction = NULL;
  ShaderTranslatorInterface::GlslImplementationType implementation_type =
      gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2 ?
          ShaderTranslatorInterface::kGlslES : ShaderTranslatorInterface::kGlsl;
  int driver_bug_workarounds = 0;
  if (workarounds().needs_glsl_built_in_function_emulation)
    driver_bug_workarounds |= SH_EMULATE_BUILT_IN_FUNCTIONS;
  if (workarounds().init_gl_position_in_vertex_shader)
    driver_bug_workarounds |= SH_INIT_GL_POSITION;
  if (workarounds().unfold_short_circuit_as_ternary_operation)
    driver_bug_workarounds |= SH_UNFOLD_SHORT_CIRCUIT;
  if (workarounds().init_varyings_without_static_use)
    driver_bug_workarounds |= SH_INIT_VARYINGS_WITHOUT_STATIC_USE;
  if (workarounds().unroll_for_loop_with_sampler_array_index)
    driver_bug_workarounds |= SH_UNROLL_FOR_LOOP_WITH_SAMPLER_ARRAY_INDEX;
  if (workarounds().scalarize_vec_and_mat_constructor_args)
    driver_bug_workarounds |= SH_SCALARIZE_VEC_AND_MAT_CONSTRUCTOR_ARGS;
  if (workarounds().regenerate_struct_names)
    driver_bug_workarounds |= SH_REGENERATE_STRUCT_NAMES;

  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEmulateShaderPrecision))
    resources.WEBGL_debug_shader_precision = true;

  vertex_translator_ = shader_translator_cache()->GetTranslator(
      GL_VERTEX_SHADER,
      shader_spec,
      &resources,
      implementation_type,
      static_cast<ShCompileOptions>(driver_bug_workarounds));
  if (!vertex_translator_.get()) {
    LOG(ERROR) << "Could not initialize vertex shader translator.";
    Destroy(true);
    return false;
  }

  fragment_translator_ = shader_translator_cache()->GetTranslator(
      GL_FRAGMENT_SHADER,
      shader_spec,
      &resources,
      implementation_type,
      static_cast<ShCompileOptions>(driver_bug_workarounds));
  if (!fragment_translator_.get()) {
    LOG(ERROR) << "Could not initialize fragment shader translator.";
    Destroy(true);
    return false;
  }
  return true;
}

bool GLES2DecoderImpl::GenBuffersHelper(GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (GetBuffer(client_ids[ii])) {
      return false;
    }
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  glGenBuffersARB(n, service_ids.get());
  for (GLsizei ii = 0; ii < n; ++ii) {
    CreateBuffer(client_ids[ii], service_ids[ii]);
  }
  return true;
}

bool GLES2DecoderImpl::GenFramebuffersHelper(
    GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (GetFramebuffer(client_ids[ii])) {
      return false;
    }
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  glGenFramebuffersEXT(n, service_ids.get());
  for (GLsizei ii = 0; ii < n; ++ii) {
    CreateFramebuffer(client_ids[ii], service_ids[ii]);
  }
  return true;
}

bool GLES2DecoderImpl::GenRenderbuffersHelper(
    GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (GetRenderbuffer(client_ids[ii])) {
      return false;
    }
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  glGenRenderbuffersEXT(n, service_ids.get());
  for (GLsizei ii = 0; ii < n; ++ii) {
    CreateRenderbuffer(client_ids[ii], service_ids[ii]);
  }
  return true;
}

bool GLES2DecoderImpl::GenValuebuffersCHROMIUMHelper(GLsizei n,
                                                     const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (GetValuebuffer(client_ids[ii])) {
      return false;
    }
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    CreateValuebuffer(client_ids[ii]);
  }
  return true;
}

bool GLES2DecoderImpl::GenTexturesHelper(GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (GetTexture(client_ids[ii])) {
      return false;
    }
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  glGenTextures(n, service_ids.get());
  for (GLsizei ii = 0; ii < n; ++ii) {
    CreateTexture(client_ids[ii], service_ids[ii]);
  }
  return true;
}

void GLES2DecoderImpl::DeleteBuffersHelper(
    GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    Buffer* buffer = GetBuffer(client_ids[ii]);
    if (buffer && !buffer->IsDeleted()) {
      buffer->RemoveMappedRange();
      state_.vertex_attrib_manager->Unbind(buffer);
      if (state_.bound_array_buffer.get() == buffer) {
        state_.bound_array_buffer = NULL;
      }
      RemoveBuffer(client_ids[ii]);
    }
  }
}

void GLES2DecoderImpl::DeleteFramebuffersHelper(
    GLsizei n, const GLuint* client_ids) {
  bool supports_separate_framebuffer_binds =
     features().chromium_framebuffer_multisample;

  for (GLsizei ii = 0; ii < n; ++ii) {
    Framebuffer* framebuffer =
        GetFramebuffer(client_ids[ii]);
    if (framebuffer && !framebuffer->IsDeleted()) {
      if (framebuffer == framebuffer_state_.bound_draw_framebuffer.get()) {
        GLenum target = supports_separate_framebuffer_binds ?
            GL_DRAW_FRAMEBUFFER_EXT : GL_FRAMEBUFFER;

        // Unbind attachments on FBO before deletion.
        if (workarounds().unbind_attachments_on_bound_render_fbo_delete)
          framebuffer->DoUnbindGLAttachmentsForWorkaround(target);

        glBindFramebufferEXT(target, GetBackbufferServiceId());
        framebuffer_state_.bound_draw_framebuffer = NULL;
        framebuffer_state_.clear_state_dirty = true;
      }
      if (framebuffer == framebuffer_state_.bound_read_framebuffer.get()) {
        framebuffer_state_.bound_read_framebuffer = NULL;
        GLenum target = supports_separate_framebuffer_binds ?
            GL_READ_FRAMEBUFFER_EXT : GL_FRAMEBUFFER;
        glBindFramebufferEXT(target, GetBackbufferServiceId());
      }
      OnFboChanged();
      RemoveFramebuffer(client_ids[ii]);
    }
  }
}

void GLES2DecoderImpl::DeleteRenderbuffersHelper(
    GLsizei n, const GLuint* client_ids) {
  bool supports_separate_framebuffer_binds =
     features().chromium_framebuffer_multisample;
  for (GLsizei ii = 0; ii < n; ++ii) {
    Renderbuffer* renderbuffer =
        GetRenderbuffer(client_ids[ii]);
    if (renderbuffer && !renderbuffer->IsDeleted()) {
      if (state_.bound_renderbuffer.get() == renderbuffer) {
        state_.bound_renderbuffer = NULL;
      }
      // Unbind from current framebuffers.
      if (supports_separate_framebuffer_binds) {
        if (framebuffer_state_.bound_read_framebuffer.get()) {
          framebuffer_state_.bound_read_framebuffer
              ->UnbindRenderbuffer(GL_READ_FRAMEBUFFER_EXT, renderbuffer);
        }
        if (framebuffer_state_.bound_draw_framebuffer.get()) {
          framebuffer_state_.bound_draw_framebuffer
              ->UnbindRenderbuffer(GL_DRAW_FRAMEBUFFER_EXT, renderbuffer);
        }
      } else {
        if (framebuffer_state_.bound_draw_framebuffer.get()) {
          framebuffer_state_.bound_draw_framebuffer
              ->UnbindRenderbuffer(GL_FRAMEBUFFER, renderbuffer);
        }
      }
      framebuffer_state_.clear_state_dirty = true;
      RemoveRenderbuffer(client_ids[ii]);
    }
  }
}

void GLES2DecoderImpl::DeleteValuebuffersCHROMIUMHelper(
    GLsizei n,
    const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    Valuebuffer* valuebuffer = GetValuebuffer(client_ids[ii]);
    if (valuebuffer) {
      if (state_.bound_valuebuffer.get() == valuebuffer) {
        state_.bound_valuebuffer = NULL;
      }
      RemoveValuebuffer(client_ids[ii]);
    }
  }
}

void GLES2DecoderImpl::DeleteTexturesHelper(
    GLsizei n, const GLuint* client_ids) {
  bool supports_separate_framebuffer_binds =
     features().chromium_framebuffer_multisample;
  for (GLsizei ii = 0; ii < n; ++ii) {
    TextureRef* texture_ref = GetTexture(client_ids[ii]);
    if (texture_ref) {
      Texture* texture = texture_ref->texture();
      if (texture->IsAttachedToFramebuffer()) {
        framebuffer_state_.clear_state_dirty = true;
      }
      // Unbind texture_ref from texture_ref units.
      for (size_t jj = 0; jj < state_.texture_units.size(); ++jj) {
        state_.texture_units[jj].Unbind(texture_ref);
      }
      // Unbind from current framebuffers.
      if (supports_separate_framebuffer_binds) {
        if (framebuffer_state_.bound_read_framebuffer.get()) {
          framebuffer_state_.bound_read_framebuffer
              ->UnbindTexture(GL_READ_FRAMEBUFFER_EXT, texture_ref);
        }
        if (framebuffer_state_.bound_draw_framebuffer.get()) {
          framebuffer_state_.bound_draw_framebuffer
              ->UnbindTexture(GL_DRAW_FRAMEBUFFER_EXT, texture_ref);
        }
      } else {
        if (framebuffer_state_.bound_draw_framebuffer.get()) {
          framebuffer_state_.bound_draw_framebuffer
              ->UnbindTexture(GL_FRAMEBUFFER, texture_ref);
        }
      }
#if defined(OS_MACOSX)
      GLuint service_id = texture->service_id();
      if (texture->target() == GL_TEXTURE_RECTANGLE_ARB) {
        ReleaseIOSurfaceForTexture(service_id);
      }
#endif
      RemoveTexture(client_ids[ii]);
    }
  }
}

// }  // anonymous namespace

bool GLES2DecoderImpl::MakeCurrent() {
  if (!context_.get())
    return false;

  if (WasContextLost()) {
    LOG(ERROR) << "  GLES2DecoderImpl: Trying to make lost context current.";
    return false;
  }

  if (!context_->MakeCurrent(surface_.get())) {
    LOG(ERROR) << "  GLES2DecoderImpl: Context lost during MakeCurrent.";
    MarkContextLost(error::kMakeCurrentFailed);
    group_->LoseContexts(error::kUnknown);
    return false;
  }

  if (CheckResetStatus()) {
    LOG(ERROR)
        << "  GLES2DecoderImpl: Context reset detected after MakeCurrent.";
    group_->LoseContexts(error::kUnknown);
    return false;
  }

  ProcessFinishedAsyncTransfers();

  // Rebind the FBO if it was unbound by the context.
  if (workarounds().unbind_fbo_on_context_switch)
    RestoreFramebufferBindings();

  framebuffer_state_.clear_state_dirty = true;

  return true;
}

void GLES2DecoderImpl::ProcessFinishedAsyncTransfers() {
  ProcessPendingReadPixels();
  if (engine() && query_manager_.get())
    query_manager_->ProcessPendingTransferQueries();

  // TODO(epenner): Is there a better place to do this?
  // This needs to occur before we execute any batch of commands
  // from the client, as the client may have recieved an async
  // completion while issuing those commands.
  // "DidFlushStart" would be ideal if we had such a callback.
  async_pixel_transfer_manager_->BindCompletedAsyncTransfers();
}

static void RebindCurrentFramebuffer(
    GLenum target,
    Framebuffer* framebuffer,
    GLuint back_buffer_service_id) {
  GLuint framebuffer_id = framebuffer ? framebuffer->service_id() : 0;

  if (framebuffer_id == 0) {
    framebuffer_id = back_buffer_service_id;
  }

  glBindFramebufferEXT(target, framebuffer_id);
}

void GLES2DecoderImpl::RestoreCurrentFramebufferBindings() {
  framebuffer_state_.clear_state_dirty = true;

  if (!features().chromium_framebuffer_multisample) {
    RebindCurrentFramebuffer(
        GL_FRAMEBUFFER,
        framebuffer_state_.bound_draw_framebuffer.get(),
        GetBackbufferServiceId());
  } else {
    RebindCurrentFramebuffer(
        GL_READ_FRAMEBUFFER_EXT,
        framebuffer_state_.bound_read_framebuffer.get(),
        GetBackbufferServiceId());
    RebindCurrentFramebuffer(
        GL_DRAW_FRAMEBUFFER_EXT,
        framebuffer_state_.bound_draw_framebuffer.get(),
        GetBackbufferServiceId());
  }
  OnFboChanged();
}

bool GLES2DecoderImpl::CheckFramebufferValid(
    Framebuffer* framebuffer,
    GLenum target, const char* func_name) {
  if (!framebuffer) {
    if (surfaceless_)
      return false;
    if (backbuffer_needs_clear_bits_) {
      glClearColor(0, 0, 0, (GLES2Util::GetChannelsForFormat(
          offscreen_target_color_format_) & 0x0008) != 0 ? 0 : 1.f);
      state_.SetDeviceColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
      glClearStencil(0);
      state_.SetDeviceStencilMaskSeparate(GL_FRONT, kDefaultStencilMask);
      state_.SetDeviceStencilMaskSeparate(GL_BACK, kDefaultStencilMask);
      glClearDepth(1.0f);
      state_.SetDeviceDepthMask(GL_TRUE);
      state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);
      bool reset_draw_buffer = false;
      if ((backbuffer_needs_clear_bits_ & GL_COLOR_BUFFER_BIT) != 0 &&
          group_->draw_buffer() == GL_NONE) {
        reset_draw_buffer = true;
        GLenum buf = GL_BACK;
        if (GetBackbufferServiceId() != 0)  // emulated backbuffer
          buf = GL_COLOR_ATTACHMENT0;
        glDrawBuffersARB(1, &buf);
      }
      glClear(backbuffer_needs_clear_bits_);
      if (reset_draw_buffer) {
        GLenum buf = GL_NONE;
        glDrawBuffersARB(1, &buf);
      }
      backbuffer_needs_clear_bits_ = 0;
      RestoreClearState();
    }
    return true;
  }

  if (framebuffer_manager()->IsComplete(framebuffer)) {
    return true;
  }

  GLenum completeness = framebuffer->IsPossiblyComplete();
  if (completeness != GL_FRAMEBUFFER_COMPLETE) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_FRAMEBUFFER_OPERATION, func_name, "framebuffer incomplete");
    return false;
  }

  // Are all the attachments cleared?
  if (renderbuffer_manager()->HaveUnclearedRenderbuffers() ||
      texture_manager()->HaveUnclearedMips()) {
    if (!framebuffer->IsCleared()) {
      // Can we clear them?
      if (framebuffer->GetStatus(texture_manager(), target) !=
          GL_FRAMEBUFFER_COMPLETE) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_FRAMEBUFFER_OPERATION, func_name,
            "framebuffer incomplete (clear)");
        return false;
      }
      ClearUnclearedAttachments(target, framebuffer);
    }
  }

  if (!framebuffer_manager()->IsComplete(framebuffer)) {
    if (framebuffer->GetStatus(texture_manager(), target) !=
        GL_FRAMEBUFFER_COMPLETE) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_FRAMEBUFFER_OPERATION, func_name,
          "framebuffer incomplete (check)");
      return false;
    }
    framebuffer_manager()->MarkAsComplete(framebuffer);
  }

  // NOTE: At this point we don't know if the framebuffer is complete but
  // we DO know that everything that needs to be cleared has been cleared.
  return true;
}

bool GLES2DecoderImpl::CheckBoundFramebuffersValid(const char* func_name) {
  if (!features().chromium_framebuffer_multisample) {
    bool valid = CheckFramebufferValid(
        framebuffer_state_.bound_draw_framebuffer.get(), GL_FRAMEBUFFER_EXT,
        func_name);

    if (valid)
      OnUseFramebuffer();

    return valid;
  }
  return CheckFramebufferValid(framebuffer_state_.bound_draw_framebuffer.get(),
                               GL_DRAW_FRAMEBUFFER_EXT,
                               func_name) &&
         CheckFramebufferValid(framebuffer_state_.bound_read_framebuffer.get(),
                               GL_READ_FRAMEBUFFER_EXT,
                               func_name);
}

bool GLES2DecoderImpl::CheckBoundReadFramebufferColorAttachment(
    const char* func_name) {
  Framebuffer* framebuffer = features().chromium_framebuffer_multisample ?
      framebuffer_state_.bound_read_framebuffer.get() :
      framebuffer_state_.bound_draw_framebuffer.get();
  if (!framebuffer)
    return true;
  if (framebuffer->GetAttachment(GL_COLOR_ATTACHMENT0) == NULL) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, func_name, "no color image attached");
    return false;
  }
  return true;
}

bool GLES2DecoderImpl::FormsTextureCopyingFeedbackLoop(
    TextureRef* texture, GLint level) {
  Framebuffer* framebuffer = features().chromium_framebuffer_multisample ?
      framebuffer_state_.bound_read_framebuffer.get() :
      framebuffer_state_.bound_draw_framebuffer.get();
  if (!framebuffer)
    return false;
  const Framebuffer::Attachment* attachment = framebuffer->GetAttachment(
      GL_COLOR_ATTACHMENT0);
  if (!attachment)
    return false;
  return attachment->FormsFeedbackLoop(texture, level);
}

gfx::Size GLES2DecoderImpl::GetBoundReadFrameBufferSize() {
  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(GL_READ_FRAMEBUFFER_EXT);
  if (framebuffer != NULL) {
    const Framebuffer::Attachment* attachment =
        framebuffer->GetAttachment(GL_COLOR_ATTACHMENT0);
    if (attachment) {
      return gfx::Size(attachment->width(), attachment->height());
    }
    return gfx::Size(0, 0);
  } else if (offscreen_target_frame_buffer_.get()) {
    return offscreen_size_;
  } else {
    return surface_->GetSize();
  }
}

GLenum GLES2DecoderImpl::GetBoundReadFrameBufferTextureType() {
  Framebuffer* framebuffer =
    GetFramebufferInfoForTarget(GL_READ_FRAMEBUFFER_EXT);
  if (framebuffer != NULL) {
    return framebuffer->GetColorAttachmentTextureType();
  } else {
    return GL_UNSIGNED_BYTE;
  }
}

GLenum GLES2DecoderImpl::GetBoundReadFrameBufferInternalFormat() {
  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(GL_READ_FRAMEBUFFER_EXT);
  if (framebuffer != NULL) {
    return framebuffer->GetColorAttachmentFormat();
  } else if (offscreen_target_frame_buffer_.get()) {
    return offscreen_target_color_format_;
  } else {
    return back_buffer_color_format_;
  }
}

GLenum GLES2DecoderImpl::GetBoundDrawFrameBufferInternalFormat() {
  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(GL_DRAW_FRAMEBUFFER_EXT);
  if (framebuffer != NULL) {
    return framebuffer->GetColorAttachmentFormat();
  } else if (offscreen_target_frame_buffer_.get()) {
    return offscreen_target_color_format_;
  } else {
    return back_buffer_color_format_;
  }
}

void GLES2DecoderImpl::UpdateParentTextureInfo() {
  if (!offscreen_saved_color_texture_info_.get())
    return;
  GLenum target = offscreen_saved_color_texture_info_->texture()->target();
  glBindTexture(target, offscreen_saved_color_texture_info_->service_id());
  texture_manager()->SetLevelInfo(
      offscreen_saved_color_texture_info_.get(),
      GL_TEXTURE_2D,
      0,  // level
      GL_RGBA,
      offscreen_size_.width(),
      offscreen_size_.height(),
      1,  // depth
      0,  // border
      GL_RGBA,
      GL_UNSIGNED_BYTE,
      true);
  texture_manager()->SetParameteri(
      "UpdateParentTextureInfo",
      GetErrorState(),
      offscreen_saved_color_texture_info_.get(),
      GL_TEXTURE_MAG_FILTER,
      GL_LINEAR);
  texture_manager()->SetParameteri(
      "UpdateParentTextureInfo",
      GetErrorState(),
      offscreen_saved_color_texture_info_.get(),
      GL_TEXTURE_MIN_FILTER,
      GL_LINEAR);
  texture_manager()->SetParameteri(
      "UpdateParentTextureInfo",
      GetErrorState(),
      offscreen_saved_color_texture_info_.get(),
      GL_TEXTURE_WRAP_S,
      GL_CLAMP_TO_EDGE);
  texture_manager()->SetParameteri(
      "UpdateParentTextureInfo",
      GetErrorState(),
      offscreen_saved_color_texture_info_.get(),
      GL_TEXTURE_WRAP_T,
      GL_CLAMP_TO_EDGE);
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  glBindTexture(target, texture_ref ? texture_ref->service_id() : 0);
}

void GLES2DecoderImpl::SetResizeCallback(
    const base::Callback<void(gfx::Size, float)>& callback) {
  resize_callback_ = callback;
}

Logger* GLES2DecoderImpl::GetLogger() {
  return &logger_;
}

void GLES2DecoderImpl::BeginDecoding() {
  gpu_tracer_->BeginDecoding();
  gpu_trace_commands_ = gpu_tracer_->IsTracing() && *gpu_decoder_category_;
  gpu_debug_commands_ = log_commands() || debug() || gpu_trace_commands_ ||
                        (*cb_command_trace_category_ != 0);
}

void GLES2DecoderImpl::EndDecoding() {
  gpu_tracer_->EndDecoding();
}

ErrorState* GLES2DecoderImpl::GetErrorState() {
  return state_.GetErrorState();
}

void GLES2DecoderImpl::SetShaderCacheCallback(
    const ShaderCacheCallback& callback) {
  shader_cache_callback_ = callback;
}

void GLES2DecoderImpl::SetWaitSyncPointCallback(
    const WaitSyncPointCallback& callback) {
  wait_sync_point_callback_ = callback;
}

AsyncPixelTransferManager*
    GLES2DecoderImpl::GetAsyncPixelTransferManager() {
  return async_pixel_transfer_manager_.get();
}

void GLES2DecoderImpl::ResetAsyncPixelTransferManagerForTest() {
  async_pixel_transfer_manager_.reset();
}

void GLES2DecoderImpl::SetAsyncPixelTransferManagerForTest(
    AsyncPixelTransferManager* manager) {
  async_pixel_transfer_manager_ = make_scoped_ptr(manager);
}

bool GLES2DecoderImpl::GetServiceTextureId(uint32 client_texture_id,
                                           uint32* service_texture_id) {
  TextureRef* texture_ref = texture_manager()->GetTexture(client_texture_id);
  if (texture_ref) {
    *service_texture_id = texture_ref->service_id();
    return true;
  }
  return false;
}

uint32 GLES2DecoderImpl::GetTextureUploadCount() {
  return texture_state_.texture_upload_count +
         async_pixel_transfer_manager_->GetTextureUploadCount();
}

base::TimeDelta GLES2DecoderImpl::GetTotalTextureUploadTime() {
  return texture_state_.total_texture_upload_time +
         async_pixel_transfer_manager_->GetTotalTextureUploadTime();
}

base::TimeDelta GLES2DecoderImpl::GetTotalProcessingCommandsTime() {
  return total_processing_commands_time_;
}

void GLES2DecoderImpl::AddProcessingCommandsTime(base::TimeDelta time) {
  total_processing_commands_time_ += time;
}

void GLES2DecoderImpl::Destroy(bool have_context) {
  if (!initialized())
    return;

  DCHECK(!have_context || context_->IsCurrent(NULL));

  // Unbind everything.
  state_.vertex_attrib_manager = NULL;
  state_.default_vertex_attrib_manager = NULL;
  state_.texture_units.clear();
  state_.bound_array_buffer = NULL;
  state_.current_queries.clear();
  framebuffer_state_.bound_read_framebuffer = NULL;
  framebuffer_state_.bound_draw_framebuffer = NULL;
  state_.bound_renderbuffer = NULL;
  state_.bound_valuebuffer = NULL;

  if (offscreen_saved_color_texture_info_.get()) {
    DCHECK(offscreen_target_color_texture_);
    DCHECK_EQ(offscreen_saved_color_texture_info_->service_id(),
              offscreen_saved_color_texture_->id());
    offscreen_saved_color_texture_->Invalidate();
    offscreen_saved_color_texture_info_ = NULL;
  }
  if (have_context) {
    if (copy_texture_CHROMIUM_.get()) {
      copy_texture_CHROMIUM_->Destroy();
      copy_texture_CHROMIUM_.reset();
    }

    clear_framebuffer_blit_.reset();

    if (state_.current_program.get()) {
      program_manager()->UnuseProgram(shader_manager(),
                                      state_.current_program.get());
    }

    if (attrib_0_buffer_id_) {
      glDeleteBuffersARB(1, &attrib_0_buffer_id_);
    }
    if (fixed_attrib_buffer_id_) {
      glDeleteBuffersARB(1, &fixed_attrib_buffer_id_);
    }

    if (validation_texture_) {
      glDeleteTextures(1, &validation_texture_);
      glDeleteFramebuffersEXT(1, &validation_fbo_multisample_);
      glDeleteFramebuffersEXT(1, &validation_fbo_);
    }

    if (offscreen_target_frame_buffer_.get())
      offscreen_target_frame_buffer_->Destroy();
    if (offscreen_target_color_texture_.get())
      offscreen_target_color_texture_->Destroy();
    if (offscreen_target_color_render_buffer_.get())
      offscreen_target_color_render_buffer_->Destroy();
    if (offscreen_target_depth_render_buffer_.get())
      offscreen_target_depth_render_buffer_->Destroy();
    if (offscreen_target_stencil_render_buffer_.get())
      offscreen_target_stencil_render_buffer_->Destroy();
    if (offscreen_saved_frame_buffer_.get())
      offscreen_saved_frame_buffer_->Destroy();
    if (offscreen_saved_color_texture_.get())
      offscreen_saved_color_texture_->Destroy();
    if (offscreen_resolved_frame_buffer_.get())
      offscreen_resolved_frame_buffer_->Destroy();
    if (offscreen_resolved_color_texture_.get())
      offscreen_resolved_color_texture_->Destroy();
  } else {
    if (offscreen_target_frame_buffer_.get())
      offscreen_target_frame_buffer_->Invalidate();
    if (offscreen_target_color_texture_.get())
      offscreen_target_color_texture_->Invalidate();
    if (offscreen_target_color_render_buffer_.get())
      offscreen_target_color_render_buffer_->Invalidate();
    if (offscreen_target_depth_render_buffer_.get())
      offscreen_target_depth_render_buffer_->Invalidate();
    if (offscreen_target_stencil_render_buffer_.get())
      offscreen_target_stencil_render_buffer_->Invalidate();
    if (offscreen_saved_frame_buffer_.get())
      offscreen_saved_frame_buffer_->Invalidate();
    if (offscreen_saved_color_texture_.get())
      offscreen_saved_color_texture_->Invalidate();
    if (offscreen_resolved_frame_buffer_.get())
      offscreen_resolved_frame_buffer_->Invalidate();
    if (offscreen_resolved_color_texture_.get())
      offscreen_resolved_color_texture_->Invalidate();
  }

  // Current program must be cleared after calling ProgramManager::UnuseProgram.
  // Otherwise, we can leak objects. http://crbug.com/258772.
  // state_.current_program must be reset before group_ is reset because
  // the later deletes the ProgramManager object that referred by
  // state_.current_program object.
  state_.current_program = NULL;

  copy_texture_CHROMIUM_.reset();
  clear_framebuffer_blit_.reset();

  if (query_manager_.get()) {
    query_manager_->Destroy(have_context);
    query_manager_.reset();
  }

  if (vertex_array_manager_ .get()) {
    vertex_array_manager_->Destroy(have_context);
    vertex_array_manager_.reset();
  }

  if (image_manager_.get()) {
    image_manager_->Destroy(have_context);
    image_manager_.reset();
  }

  offscreen_target_frame_buffer_.reset();
  offscreen_target_color_texture_.reset();
  offscreen_target_color_render_buffer_.reset();
  offscreen_target_depth_render_buffer_.reset();
  offscreen_target_stencil_render_buffer_.reset();
  offscreen_saved_frame_buffer_.reset();
  offscreen_saved_color_texture_.reset();
  offscreen_resolved_frame_buffer_.reset();
  offscreen_resolved_color_texture_.reset();

  // Need to release these before releasing |group_| which may own the
  // ShaderTranslatorCache.
  fragment_translator_ = NULL;
  vertex_translator_ = NULL;

  // Should destroy the transfer manager before the texture manager held
  // by the context group.
  async_pixel_transfer_manager_.reset();

  // Destroy the GPU Tracer which may own some in process GPU Timings.
  if (gpu_tracer_) {
    gpu_tracer_->Destroy(have_context);
    gpu_tracer_.reset();
  }

  if (group_.get()) {
    framebuffer_manager()->RemoveObserver(this);
    group_->Destroy(this, have_context);
    group_ = NULL;
  }

  if (context_.get()) {
    context_->ReleaseCurrent(NULL);
    context_ = NULL;
  }

#if defined(OS_MACOSX)
  for (TextureToIOSurfaceMap::iterator it = texture_to_io_surface_map_.begin();
       it != texture_to_io_surface_map_.end(); ++it) {
    CFRelease(it->second);
  }
  texture_to_io_surface_map_.clear();
#endif
}

void GLES2DecoderImpl::SetSurface(
    const scoped_refptr<gfx::GLSurface>& surface) {
  DCHECK(context_->IsCurrent(NULL));
  DCHECK(surface_.get());
  surface_ = surface;
  RestoreCurrentFramebufferBindings();
}

void GLES2DecoderImpl::ProduceFrontBuffer(const Mailbox& mailbox) {
  if (!offscreen_saved_color_texture_.get()) {
    LOG(ERROR) << "Called ProduceFrontBuffer on a non-offscreen context";
    return;
  }
  if (!offscreen_saved_color_texture_info_.get()) {
    GLuint service_id = offscreen_saved_color_texture_->id();
    offscreen_saved_color_texture_info_ = TextureRef::Create(
        texture_manager(), 0, service_id);
    texture_manager()->SetTarget(offscreen_saved_color_texture_info_.get(),
                                 GL_TEXTURE_2D);
    UpdateParentTextureInfo();
  }
  mailbox_manager()->ProduceTexture(
      mailbox, offscreen_saved_color_texture_info_->texture());
}

bool GLES2DecoderImpl::ResizeOffscreenFrameBuffer(const gfx::Size& size) {
  bool is_offscreen = !!offscreen_target_frame_buffer_.get();
  if (!is_offscreen) {
    LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer called "
               << " with an onscreen framebuffer.";
    return false;
  }

  if (offscreen_size_ == size)
    return true;

  offscreen_size_ = size;
  int w = offscreen_size_.width();
  int h = offscreen_size_.height();
  if (w < 0 || h < 0 || h >= (INT_MAX / 4) / (w ? w : 1)) {
    LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer failed "
               << "to allocate storage due to excessive dimensions.";
    return false;
  }

  // Reallocate the offscreen target buffers.
  DCHECK(offscreen_target_color_format_);
  if (IsOffscreenBufferMultisampled()) {
    if (!offscreen_target_color_render_buffer_->AllocateStorage(
            feature_info_.get(),
            offscreen_size_,
            offscreen_target_color_format_,
            offscreen_target_samples_)) {
      LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer failed "
                 << "to allocate storage for offscreen target color buffer.";
      return false;
    }
  } else {
    if (!offscreen_target_color_texture_->AllocateStorage(
        offscreen_size_, offscreen_target_color_format_, false)) {
      LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer failed "
                 << "to allocate storage for offscreen target color texture.";
      return false;
    }
  }
  if (offscreen_target_depth_format_ &&
      !offscreen_target_depth_render_buffer_->AllocateStorage(
          feature_info_.get(),
          offscreen_size_,
          offscreen_target_depth_format_,
          offscreen_target_samples_)) {
    LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer failed "
               << "to allocate storage for offscreen target depth buffer.";
    return false;
  }
  if (offscreen_target_stencil_format_ &&
      !offscreen_target_stencil_render_buffer_->AllocateStorage(
          feature_info_.get(),
          offscreen_size_,
          offscreen_target_stencil_format_,
          offscreen_target_samples_)) {
    LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer failed "
               << "to allocate storage for offscreen target stencil buffer.";
    return false;
  }

  // Attach the offscreen target buffers to the target frame buffer.
  if (IsOffscreenBufferMultisampled()) {
    offscreen_target_frame_buffer_->AttachRenderBuffer(
        GL_COLOR_ATTACHMENT0,
        offscreen_target_color_render_buffer_.get());
  } else {
    offscreen_target_frame_buffer_->AttachRenderTexture(
        offscreen_target_color_texture_.get());
  }
  if (offscreen_target_depth_format_) {
    offscreen_target_frame_buffer_->AttachRenderBuffer(
        GL_DEPTH_ATTACHMENT,
        offscreen_target_depth_render_buffer_.get());
  }
  const bool packed_depth_stencil =
      offscreen_target_depth_format_ == GL_DEPTH24_STENCIL8;
  if (packed_depth_stencil) {
    offscreen_target_frame_buffer_->AttachRenderBuffer(
        GL_STENCIL_ATTACHMENT,
        offscreen_target_depth_render_buffer_.get());
  } else if (offscreen_target_stencil_format_) {
    offscreen_target_frame_buffer_->AttachRenderBuffer(
        GL_STENCIL_ATTACHMENT,
        offscreen_target_stencil_render_buffer_.get());
  }

  if (offscreen_target_frame_buffer_->CheckStatus() !=
      GL_FRAMEBUFFER_COMPLETE) {
      LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer failed "
                 << "because offscreen FBO was incomplete.";
    return false;
  }

  // Clear the target frame buffer.
  {
    ScopedFrameBufferBinder binder(this, offscreen_target_frame_buffer_->id());
    glClearColor(0, 0, 0, (GLES2Util::GetChannelsForFormat(
        offscreen_target_color_format_) & 0x0008) != 0 ? 0 : 1.f);
    state_.SetDeviceColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glClearStencil(0);
    state_.SetDeviceStencilMaskSeparate(GL_FRONT, kDefaultStencilMask);
    state_.SetDeviceStencilMaskSeparate(GL_BACK, kDefaultStencilMask);
    glClearDepth(0);
    state_.SetDeviceDepthMask(GL_TRUE);
    state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    RestoreClearState();
  }

  // Destroy the offscreen resolved framebuffers.
  if (offscreen_resolved_frame_buffer_.get())
    offscreen_resolved_frame_buffer_->Destroy();
  if (offscreen_resolved_color_texture_.get())
    offscreen_resolved_color_texture_->Destroy();
  offscreen_resolved_color_texture_.reset();
  offscreen_resolved_frame_buffer_.reset();

  return true;
}

error::Error GLES2DecoderImpl::HandleResizeCHROMIUM(uint32 immediate_data_size,
                                                    const void* cmd_data) {
  const gles2::cmds::ResizeCHROMIUM& c =
      *static_cast<const gles2::cmds::ResizeCHROMIUM*>(cmd_data);
  if (!offscreen_target_frame_buffer_.get() && surface_->DeferDraws())
    return error::kDeferCommandUntilLater;

  GLuint width = static_cast<GLuint>(c.width);
  GLuint height = static_cast<GLuint>(c.height);
  GLfloat scale_factor = c.scale_factor;
  TRACE_EVENT2("gpu", "glResizeChromium", "width", width, "height", height);

  width = std::max(1U, width);
  height = std::max(1U, height);

#if defined(OS_POSIX) && !defined(OS_MACOSX) && \
    !defined(UI_COMPOSITOR_IMAGE_TRANSPORT)
  // Make sure that we are done drawing to the back buffer before resizing.
  glFinish();
#endif
  bool is_offscreen = !!offscreen_target_frame_buffer_.get();
  if (is_offscreen) {
    if (!ResizeOffscreenFrameBuffer(gfx::Size(width, height))) {
      LOG(ERROR) << "GLES2DecoderImpl: Context lost because "
                 << "ResizeOffscreenFrameBuffer failed.";
      return error::kLostContext;
    }
  }

  if (!resize_callback_.is_null()) {
    resize_callback_.Run(gfx::Size(width, height), scale_factor);
    DCHECK(context_->IsCurrent(surface_.get()));
    if (!context_->IsCurrent(surface_.get())) {
      LOG(ERROR) << "GLES2DecoderImpl: Context lost because context no longer "
                 << "current after resize callback.";
      return error::kLostContext;
    }
  }

  return error::kNoError;
}

const char* GLES2DecoderImpl::GetCommandName(unsigned int command_id) const {
  if (command_id > kStartPoint && command_id < kNumCommands) {
    return gles2::GetCommandName(static_cast<CommandId>(command_id));
  }
  return GetCommonCommandName(static_cast<cmd::CommandId>(command_id));
}

// Decode a command, and call the corresponding GL functions.
// NOTE: DoCommand() is slower than calling DoCommands() on larger batches
// of commands at once, and is now only used for tests that need to track
// individual commands.
error::Error GLES2DecoderImpl::DoCommand(unsigned int command,
                                         unsigned int arg_count,
                                         const void* cmd_data) {
  return DoCommands(1, cmd_data, arg_count + 1, 0);
}

// Decode multiple commands, and call the corresponding GL functions.
// NOTE: 'buffer' is a pointer to the command buffer. As such, it could be
// changed by a (malicious) client at any time, so if validation has to happen,
// it should operate on a copy of them.
// NOTE: This is duplicating code from AsyncAPIInterface::DoCommands() in the
// interest of performance in this critical execution loop.
template <bool DebugImpl>
error::Error GLES2DecoderImpl::DoCommandsImpl(unsigned int num_commands,
                                              const void* buffer,
                                              int num_entries,
                                              int* entries_processed) {
  commands_to_process_ = num_commands;
  error::Error result = error::kNoError;
  const CommandBufferEntry* cmd_data =
      static_cast<const CommandBufferEntry*>(buffer);
  int process_pos = 0;
  unsigned int command = 0;

  while (process_pos < num_entries && result == error::kNoError &&
         commands_to_process_--) {
    const unsigned int size = cmd_data->value_header.size;
    command = cmd_data->value_header.command;

    if (size == 0) {
      result = error::kInvalidSize;
      break;
    }

    if (static_cast<int>(size) + process_pos > num_entries) {
      result = error::kOutOfBounds;
      break;
    }

    if (DebugImpl) {
      TRACE_EVENT_BEGIN0(TRACE_DISABLED_BY_DEFAULT("cb_command"),
                         GetCommandName(command));

      if (log_commands()) {
        LOG(ERROR) << "[" << logger_.GetLogPrefix() << "]"
                   << "cmd: " << GetCommandName(command);
      }
    }

    const unsigned int arg_count = size - 1;
    unsigned int command_index = command - kStartPoint - 1;
    if (command_index < arraysize(command_info)) {
      const CommandInfo& info = command_info[command_index];
      unsigned int info_arg_count = static_cast<unsigned int>(info.arg_count);
      if ((info.arg_flags == cmd::kFixed && arg_count == info_arg_count) ||
          (info.arg_flags == cmd::kAtLeastN && arg_count >= info_arg_count)) {
        bool doing_gpu_trace = false;
        if (DebugImpl && gpu_trace_commands_) {
          if (CMD_FLAG_GET_TRACE_LEVEL(info.cmd_flags) <= gpu_trace_level_) {
            doing_gpu_trace = true;
            gpu_tracer_->Begin(TRACE_DISABLED_BY_DEFAULT("gpu_decoder"),
                               GetCommandName(command),
                               kTraceDecoder);
          }
        }

        uint32 immediate_data_size = (arg_count - info_arg_count) *
                                     sizeof(CommandBufferEntry);  // NOLINT

        result = (this->*info.cmd_handler)(immediate_data_size, cmd_data);

        if (DebugImpl && doing_gpu_trace)
          gpu_tracer_->End(kTraceDecoder);

        if (DebugImpl && debug()) {
          GLenum error;
          while ((error = glGetError()) != GL_NO_ERROR) {
            LOG(ERROR) << "[" << logger_.GetLogPrefix() << "] "
                       << "GL ERROR: " << GLES2Util::GetStringEnum(error)
                       << " : " << GetCommandName(command);
            LOCAL_SET_GL_ERROR(error, "DoCommand", "GL error from driver");
          }
        }
      } else {
        result = error::kInvalidArguments;
      }
    } else {
      result = DoCommonCommand(command, arg_count, cmd_data);
    }

    if (DebugImpl) {
      TRACE_EVENT_END0(TRACE_DISABLED_BY_DEFAULT("cb_command"),
                       GetCommandName(command));
    }

    if (result == error::kNoError &&
        current_decoder_error_ != error::kNoError) {
      result = current_decoder_error_;
      current_decoder_error_ = error::kNoError;
    }

    if (result != error::kDeferCommandUntilLater) {
      process_pos += size;
      cmd_data += size;
    }
  }

  if (entries_processed)
    *entries_processed = process_pos;

  if (error::IsError(result)) {
    LOG(ERROR) << "Error: " << result << " for Command "
               << GetCommandName(command);
  }

  return result;
}

error::Error GLES2DecoderImpl::DoCommands(unsigned int num_commands,
                                          const void* buffer,
                                          int num_entries,
                                          int* entries_processed) {
  if (gpu_debug_commands_) {
    return DoCommandsImpl<true>(
        num_commands, buffer, num_entries, entries_processed);
  } else {
    return DoCommandsImpl<false>(
        num_commands, buffer, num_entries, entries_processed);
  }
}

void GLES2DecoderImpl::RemoveBuffer(GLuint client_id) {
  buffer_manager()->RemoveBuffer(client_id);
}

void GLES2DecoderImpl::DoFinish() {
  glFinish();
  ProcessPendingReadPixels();
  ProcessPendingQueries(true);
}

void GLES2DecoderImpl::DoFlush() {
  glFlush();
  ProcessPendingQueries(false);
}

void GLES2DecoderImpl::DoActiveTexture(GLenum texture_unit) {
  GLuint texture_index = texture_unit - GL_TEXTURE0;
  if (texture_index >= state_.texture_units.size()) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glActiveTexture", texture_unit, "texture_unit");
    return;
  }
  state_.active_texture_unit = texture_index;
  glActiveTexture(texture_unit);
}

void GLES2DecoderImpl::DoBindBuffer(GLenum target, GLuint client_id) {
  Buffer* buffer = NULL;
  GLuint service_id = 0;
  if (client_id != 0) {
    buffer = GetBuffer(client_id);
    if (!buffer) {
      if (!group_->bind_generates_resource()) {
        LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                           "glBindBuffer",
                           "id not generated by glGenBuffers");
        return;
      }

      // It's a new id so make a buffer buffer for it.
      glGenBuffersARB(1, &service_id);
      CreateBuffer(client_id, service_id);
      buffer = GetBuffer(client_id);
    }
  }
  LogClientServiceForInfo(buffer, client_id, "glBindBuffer");
  if (buffer) {
    if (!buffer_manager()->SetTarget(buffer, target)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glBindBuffer", "buffer bound to more than 1 target");
      return;
    }
    service_id = buffer->service_id();
  }
  switch (target) {
    case GL_ARRAY_BUFFER:
      state_.bound_array_buffer = buffer;
      break;
    case GL_ELEMENT_ARRAY_BUFFER:
      state_.vertex_attrib_manager->SetElementArrayBuffer(buffer);
      break;
    default:
      NOTREACHED();  // Validation should prevent us getting here.
      break;
  }
  glBindBuffer(target, service_id);
}

bool GLES2DecoderImpl::BoundFramebufferHasColorAttachmentWithAlpha(
    bool all_draw_buffers) {
  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(GL_DRAW_FRAMEBUFFER_EXT);
  if (!all_draw_buffers || !framebuffer) {
    return (GLES2Util::GetChannelsForFormat(
        GetBoundDrawFrameBufferInternalFormat()) & 0x0008) != 0;
  }
  return framebuffer->HasAlphaMRT();
}

bool GLES2DecoderImpl::BoundFramebufferHasDepthAttachment() {
  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(GL_DRAW_FRAMEBUFFER_EXT);
  if (framebuffer) {
    return framebuffer->HasDepthAttachment();
  }
  if (offscreen_target_frame_buffer_.get()) {
    return offscreen_target_depth_format_ != 0;
  }
  return back_buffer_has_depth_;
}

bool GLES2DecoderImpl::BoundFramebufferHasStencilAttachment() {
  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(GL_DRAW_FRAMEBUFFER_EXT);
  if (framebuffer) {
    return framebuffer->HasStencilAttachment();
  }
  if (offscreen_target_frame_buffer_.get()) {
    return offscreen_target_stencil_format_ != 0 ||
           offscreen_target_depth_format_ == GL_DEPTH24_STENCIL8;
  }
  return back_buffer_has_stencil_;
}

void GLES2DecoderImpl::ApplyDirtyState() {
  if (framebuffer_state_.clear_state_dirty) {
    bool have_alpha = BoundFramebufferHasColorAttachmentWithAlpha(true);
    state_.SetDeviceColorMask(state_.color_mask_red,
                              state_.color_mask_green,
                              state_.color_mask_blue,
                              state_.color_mask_alpha && have_alpha);

    bool have_depth = BoundFramebufferHasDepthAttachment();
    state_.SetDeviceDepthMask(state_.depth_mask && have_depth);

    bool have_stencil = BoundFramebufferHasStencilAttachment();
    state_.SetDeviceStencilMaskSeparate(
        GL_FRONT, have_stencil ? state_.stencil_front_writemask : 0);
    state_.SetDeviceStencilMaskSeparate(
        GL_BACK, have_stencil ? state_.stencil_back_writemask : 0);

    state_.SetDeviceCapabilityState(
        GL_DEPTH_TEST, state_.enable_flags.depth_test && have_depth);
    state_.SetDeviceCapabilityState(
        GL_STENCIL_TEST, state_.enable_flags.stencil_test && have_stencil);
    framebuffer_state_.clear_state_dirty = false;
  }
}

GLuint GLES2DecoderImpl::GetBackbufferServiceId() const {
  return (offscreen_target_frame_buffer_.get())
             ? offscreen_target_frame_buffer_->id()
             : (surface_.get() ? surface_->GetBackingFrameBufferObject() : 0);
}

void GLES2DecoderImpl::RestoreState(const ContextState* prev_state) {
  TRACE_EVENT1("gpu", "GLES2DecoderImpl::RestoreState",
               "context", logger_.GetLogPrefix());
  // Restore the Framebuffer first because of bugs in Intel drivers.
  // Intel drivers incorrectly clip the viewport settings to
  // the size of the current framebuffer object.
  RestoreFramebufferBindings();
  state_.RestoreState(prev_state);
}

void GLES2DecoderImpl::RestoreFramebufferBindings() const {
  GLuint service_id =
      framebuffer_state_.bound_draw_framebuffer.get()
          ? framebuffer_state_.bound_draw_framebuffer->service_id()
          : GetBackbufferServiceId();
  if (!features().chromium_framebuffer_multisample) {
    glBindFramebufferEXT(GL_FRAMEBUFFER, service_id);
  } else {
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER, service_id);
    service_id = framebuffer_state_.bound_read_framebuffer.get()
                     ? framebuffer_state_.bound_read_framebuffer->service_id()
                     : GetBackbufferServiceId();
    glBindFramebufferEXT(GL_READ_FRAMEBUFFER, service_id);
  }
  OnFboChanged();
}

void GLES2DecoderImpl::RestoreRenderbufferBindings() {
  state_.RestoreRenderbufferBindings();
}

void GLES2DecoderImpl::RestoreTextureState(unsigned service_id) const {
  Texture* texture = texture_manager()->GetTextureForServiceId(service_id);
  if (texture) {
    GLenum target = texture->target();
    glBindTexture(target, service_id);
    glTexParameteri(
        target, GL_TEXTURE_WRAP_S, texture->wrap_s());
    glTexParameteri(
        target, GL_TEXTURE_WRAP_T, texture->wrap_t());
    glTexParameteri(
        target, GL_TEXTURE_MIN_FILTER, texture->min_filter());
    glTexParameteri(
        target, GL_TEXTURE_MAG_FILTER, texture->mag_filter());
    RestoreTextureUnitBindings(state_.active_texture_unit);
  }
}

void GLES2DecoderImpl::ClearAllAttributes() const {
  // Must use native VAO 0, as RestoreAllAttributes can't fully restore
  // other VAOs.
  if (feature_info_->feature_flags().native_vertex_array_object)
    glBindVertexArrayOES(0);

  for (uint32 i = 0; i < group_->max_vertex_attribs(); ++i) {
    if (i != 0)  // Never disable attribute 0
      glDisableVertexAttribArray(i);
    if (features().angle_instanced_arrays)
      glVertexAttribDivisorANGLE(i, 0);
  }
}

void GLES2DecoderImpl::RestoreAllAttributes() const {
  state_.RestoreVertexAttribs();
}

void GLES2DecoderImpl::SetIgnoreCachedStateForTest(bool ignore) {
  state_.SetIgnoreCachedStateForTest(ignore);
}

void GLES2DecoderImpl::OnFboChanged() const {
  if (workarounds().restore_scissor_on_fbo_change)
    state_.fbo_binding_for_scissor_workaround_dirty = true;

  if (workarounds().gl_begin_gl_end_on_fbo_change_to_backbuffer) {
    GLint bound_fbo_unsigned = -1;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT, &bound_fbo_unsigned);
    GLuint bound_fbo = static_cast<GLuint>(bound_fbo_unsigned);
    if (surface_ && surface_->GetBackingFrameBufferObject() == bound_fbo)
      surface_->NotifyWasBound();
  }
}

// Called after the FBO is checked for completeness.
void GLES2DecoderImpl::OnUseFramebuffer() const {
  if (state_.fbo_binding_for_scissor_workaround_dirty) {
    state_.fbo_binding_for_scissor_workaround_dirty = false;
    // The driver forgets the correct scissor when modifying the FBO binding.
    glScissor(state_.scissor_x,
              state_.scissor_y,
              state_.scissor_width,
              state_.scissor_height);

    // crbug.com/222018 - Also on QualComm, the flush here avoids flicker,
    // it's unclear how this bug works.
    glFlush();
  }
}

void GLES2DecoderImpl::DoBindFramebuffer(GLenum target, GLuint client_id) {
  Framebuffer* framebuffer = NULL;
  GLuint service_id = 0;
  if (client_id != 0) {
    framebuffer = GetFramebuffer(client_id);
    if (!framebuffer) {
      if (!group_->bind_generates_resource()) {
        LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                           "glBindFramebuffer",
                           "id not generated by glGenFramebuffers");
        return;
      }

      // It's a new id so make a framebuffer framebuffer for it.
      glGenFramebuffersEXT(1, &service_id);
      CreateFramebuffer(client_id, service_id);
      framebuffer = GetFramebuffer(client_id);
    } else {
      service_id = framebuffer->service_id();
    }
    framebuffer->MarkAsValid();
  }
  LogClientServiceForInfo(framebuffer, client_id, "glBindFramebuffer");

  if (target == GL_FRAMEBUFFER || target == GL_DRAW_FRAMEBUFFER_EXT) {
    framebuffer_state_.bound_draw_framebuffer = framebuffer;
  }

  // vmiura: This looks like dup code
  if (target == GL_FRAMEBUFFER || target == GL_READ_FRAMEBUFFER_EXT) {
    framebuffer_state_.bound_read_framebuffer = framebuffer;
  }

  framebuffer_state_.clear_state_dirty = true;

  // If we are rendering to the backbuffer get the FBO id for any simulated
  // backbuffer.
  if (framebuffer == NULL) {
    service_id = GetBackbufferServiceId();
  }

  glBindFramebufferEXT(target, service_id);
  OnFboChanged();
}

void GLES2DecoderImpl::DoBindRenderbuffer(GLenum target, GLuint client_id) {
  Renderbuffer* renderbuffer = NULL;
  GLuint service_id = 0;
  if (client_id != 0) {
    renderbuffer = GetRenderbuffer(client_id);
    if (!renderbuffer) {
      if (!group_->bind_generates_resource()) {
        LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                           "glBindRenderbuffer",
                           "id not generated by glGenRenderbuffers");
        return;
      }

      // It's a new id so make a renderbuffer for it.
      glGenRenderbuffersEXT(1, &service_id);
      CreateRenderbuffer(client_id, service_id);
      renderbuffer = GetRenderbuffer(client_id);
    } else {
      service_id = renderbuffer->service_id();
    }
    renderbuffer->MarkAsValid();
  }
  LogClientServiceForInfo(renderbuffer, client_id, "glBindRenderbuffer");
  state_.bound_renderbuffer = renderbuffer;
  state_.bound_renderbuffer_valid = true;
  glBindRenderbufferEXT(GL_RENDERBUFFER, service_id);
}

void GLES2DecoderImpl::DoBindTexture(GLenum target, GLuint client_id) {
  TextureRef* texture_ref = NULL;
  GLuint service_id = 0;
  if (client_id != 0) {
    texture_ref = GetTexture(client_id);
    if (!texture_ref) {
      if (!group_->bind_generates_resource()) {
        LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                           "glBindTexture",
                           "id not generated by glGenTextures");
        return;
      }

      // It's a new id so make a texture texture for it.
      glGenTextures(1, &service_id);
      DCHECK_NE(0u, service_id);
      CreateTexture(client_id, service_id);
      texture_ref = GetTexture(client_id);
    }
  } else {
    texture_ref = texture_manager()->GetDefaultTextureInfo(target);
  }

  // Check the texture exists
  if (texture_ref) {
    Texture* texture = texture_ref->texture();
    // Check that we are not trying to bind it to a different target.
    if (texture->target() != 0 && texture->target() != target) {
      LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                         "glBindTexture",
                         "texture bound to more than 1 target.");
      return;
    }
    LogClientServiceForInfo(texture, client_id, "glBindTexture");
    if (texture->target() == 0) {
      texture_manager()->SetTarget(texture_ref, target);
    }
    glBindTexture(target, texture->service_id());
  } else {
    glBindTexture(target, 0);
  }

  TextureUnit& unit = state_.texture_units[state_.active_texture_unit];
  unit.bind_target = target;
  switch (target) {
    case GL_TEXTURE_2D:
      unit.bound_texture_2d = texture_ref;
      break;
    case GL_TEXTURE_CUBE_MAP:
      unit.bound_texture_cube_map = texture_ref;
      break;
    case GL_TEXTURE_EXTERNAL_OES:
      unit.bound_texture_external_oes = texture_ref;
      break;
    case GL_TEXTURE_RECTANGLE_ARB:
      unit.bound_texture_rectangle_arb = texture_ref;
      break;
    default:
      NOTREACHED();  // Validation should prevent us getting here.
      break;
  }
}

void GLES2DecoderImpl::DoDisableVertexAttribArray(GLuint index) {
  if (state_.vertex_attrib_manager->Enable(index, false)) {
    if (index != 0 ||
        gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2) {
      glDisableVertexAttribArray(index);
    }
  } else {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glDisableVertexAttribArray", "index out of range");
  }
}

void GLES2DecoderImpl::DoDiscardFramebufferEXT(GLenum target,
                                               GLsizei numAttachments,
                                               const GLenum* attachments) {
  if (workarounds().disable_discard_framebuffer)
    return;

  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(GL_FRAMEBUFFER);

  // Validates the attachments. If one of them fails
  // the whole command fails.
  for (GLsizei i = 0; i < numAttachments; ++i) {
    if ((framebuffer &&
        !validators_->attachment.IsValid(attachments[i])) ||
       (!framebuffer &&
        !validators_->backbuffer_attachment.IsValid(attachments[i]))) {
      LOCAL_SET_GL_ERROR_INVALID_ENUM(
          "glDiscardFramebufferEXT", attachments[i], "attachments");
      return;
    }
  }

  // Marks each one of them as not cleared
  for (GLsizei i = 0; i < numAttachments; ++i) {
    if (framebuffer) {
      framebuffer->MarkAttachmentAsCleared(renderbuffer_manager(),
                                           texture_manager(),
                                           attachments[i],
                                           false);
    } else {
      switch (attachments[i]) {
        case GL_COLOR_EXT:
          backbuffer_needs_clear_bits_ |= GL_COLOR_BUFFER_BIT;
          break;
        case GL_DEPTH_EXT:
          backbuffer_needs_clear_bits_ |= GL_DEPTH_BUFFER_BIT;
        case GL_STENCIL_EXT:
          backbuffer_needs_clear_bits_ |= GL_STENCIL_BUFFER_BIT;
          break;
        default:
          NOTREACHED();
          break;
      }
    }
  }

  // If the default framebuffer is bound but we are still rendering to an
  // FBO, translate attachment names that refer to default framebuffer
  // channels to corresponding framebuffer attachments.
  scoped_ptr<GLenum[]> translated_attachments(new GLenum[numAttachments]);
  for (GLsizei i = 0; i < numAttachments; ++i) {
    GLenum attachment = attachments[i];
    if (!framebuffer && GetBackbufferServiceId()) {
      switch (attachment) {
        case GL_COLOR_EXT:
          attachment = GL_COLOR_ATTACHMENT0;
          break;
        case GL_DEPTH_EXT:
          attachment = GL_DEPTH_ATTACHMENT;
          break;
        case GL_STENCIL_EXT:
          attachment = GL_STENCIL_ATTACHMENT;
          break;
        default:
          NOTREACHED();
          return;
      }
    }
    translated_attachments[i] = attachment;
  }

  ScopedRenderTo do_render(framebuffer);
  if (feature_info_->gl_version_info().is_es3) {
    glInvalidateFramebuffer(
        target, numAttachments, translated_attachments.get());
  } else {
    glDiscardFramebufferEXT(
        target, numAttachments, translated_attachments.get());
  }
}

void GLES2DecoderImpl::DoEnableVertexAttribArray(GLuint index) {
  if (state_.vertex_attrib_manager->Enable(index, true)) {
    glEnableVertexAttribArray(index);
  } else {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glEnableVertexAttribArray", "index out of range");
  }
}

void GLES2DecoderImpl::DoGenerateMipmap(GLenum target) {
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref ||
      !texture_manager()->CanGenerateMipmaps(texture_ref)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glGenerateMipmap", "Can not generate mips");
    return;
  }

  if (target == GL_TEXTURE_CUBE_MAP) {
    for (int i = 0; i < 6; ++i) {
      GLenum face = GL_TEXTURE_CUBE_MAP_POSITIVE_X + i;
      if (!texture_manager()->ClearTextureLevel(this, texture_ref, face, 0)) {
        LOCAL_SET_GL_ERROR(
            GL_OUT_OF_MEMORY, "glGenerateMipmap", "dimensions too big");
        return;
      }
    }
  } else {
    if (!texture_manager()->ClearTextureLevel(this, texture_ref, target, 0)) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, "glGenerateMipmap", "dimensions too big");
      return;
    }
  }

  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glGenerateMipmap");
  // Workaround for Mac driver bug. In the large scheme of things setting
  // glTexParamter twice for glGenerateMipmap is probably not a lage performance
  // hit so there's probably no need to make this conditional. The bug appears
  // to be that if the filtering mode is set to something that doesn't require
  // mipmaps for rendering, or is never set to something other than the default,
  // then glGenerateMipmap misbehaves.
  if (workarounds().set_texture_filter_before_generating_mipmap) {
    glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
  }
  glGenerateMipmapEXT(target);
  if (workarounds().set_texture_filter_before_generating_mipmap) {
    glTexParameteri(target, GL_TEXTURE_MIN_FILTER,
                    texture_ref->texture()->min_filter());
  }
  GLenum error = LOCAL_PEEK_GL_ERROR("glGenerateMipmap");
  if (error == GL_NO_ERROR) {
    texture_manager()->MarkMipmapsGenerated(texture_ref);
  }
}

bool GLES2DecoderImpl::GetHelper(
    GLenum pname, GLint* params, GLsizei* num_written) {
  DCHECK(num_written);
  if (gfx::GetGLImplementation() != gfx::kGLImplementationEGLGLES2) {
    switch (pname) {
      case GL_IMPLEMENTATION_COLOR_READ_FORMAT:
        *num_written = 1;
        // Return the GL implementation's preferred format and (see below type)
        // if we have the GL extension that exposes this. This allows the GPU
        // client to use the implementation's preferred format for glReadPixels
        // for optimisation.
        //
        // A conflicting extension (GL_ARB_ES2_compatibility) specifies an error
        // case when requested on integer/floating point buffers but which is
        // acceptable on GLES2 and with the GL_OES_read_format extension.
        //
        // Therefore if an error occurs we swallow the error and use the
        // internal implementation.
        if (params) {
          if (context_->HasExtension("GL_OES_read_format")) {
            ScopedGLErrorSuppressor suppressor("GLES2DecoderImpl::GetHelper",
                                               GetErrorState());
            glGetIntegerv(pname, params);
            if (glGetError() == GL_NO_ERROR)
              return true;
          }
          *params = GLES2Util::GetPreferredGLReadPixelsFormat(
              GetBoundReadFrameBufferInternalFormat());
        }
        return true;
      case GL_IMPLEMENTATION_COLOR_READ_TYPE:
        *num_written = 1;
        if (params) {
          if (context_->HasExtension("GL_OES_read_format")) {
            ScopedGLErrorSuppressor suppressor("GLES2DecoderImpl::GetHelper",
                                               GetErrorState());
            glGetIntegerv(pname, params);
            if (glGetError() == GL_NO_ERROR)
              return true;
          }
          *params = GLES2Util::GetPreferredGLReadPixelsType(
              GetBoundReadFrameBufferInternalFormat(),
              GetBoundReadFrameBufferTextureType());
        }
        return true;
      case GL_MAX_FRAGMENT_UNIFORM_VECTORS:
        *num_written = 1;
        if (params) {
          *params = group_->max_fragment_uniform_vectors();
        }
        return true;
      case GL_MAX_VARYING_VECTORS:
        *num_written = 1;
        if (params) {
          *params = group_->max_varying_vectors();
        }
        return true;
      case GL_MAX_VERTEX_UNIFORM_VECTORS:
        *num_written = 1;
        if (params) {
          *params = group_->max_vertex_uniform_vectors();
        }
        return true;
      }
  }
  switch (pname) {
    case GL_MAX_VIEWPORT_DIMS:
      if (offscreen_target_frame_buffer_.get()) {
        *num_written = 2;
        if (params) {
          params[0] = renderbuffer_manager()->max_renderbuffer_size();
          params[1] = renderbuffer_manager()->max_renderbuffer_size();
        }
        return true;
      }
      return false;
    case GL_MAX_SAMPLES:
      *num_written = 1;
      if (params) {
        params[0] = renderbuffer_manager()->max_samples();
      }
      return true;
    case GL_MAX_RENDERBUFFER_SIZE:
      *num_written = 1;
      if (params) {
        params[0] = renderbuffer_manager()->max_renderbuffer_size();
      }
      return true;
    case GL_MAX_TEXTURE_SIZE:
      *num_written = 1;
      if (params) {
        params[0] = texture_manager()->MaxSizeForTarget(GL_TEXTURE_2D);
      }
      return true;
    case GL_MAX_CUBE_MAP_TEXTURE_SIZE:
      *num_written = 1;
      if (params) {
        params[0] = texture_manager()->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP);
      }
      return true;
    case GL_MAX_COLOR_ATTACHMENTS_EXT:
      *num_written = 1;
      if (params) {
        params[0] = group_->max_color_attachments();
      }
      return true;
    case GL_MAX_DRAW_BUFFERS_ARB:
      *num_written = 1;
      if (params) {
        params[0] = group_->max_draw_buffers();
      }
      return true;
    case GL_ALPHA_BITS:
      *num_written = 1;
      if (params) {
        GLint v = 0;
        glGetIntegerv(GL_ALPHA_BITS, &v);
        params[0] = BoundFramebufferHasColorAttachmentWithAlpha(false) ? v : 0;
      }
      return true;
    case GL_DEPTH_BITS:
      *num_written = 1;
      if (params) {
        GLint v = 0;
        glGetIntegerv(GL_DEPTH_BITS, &v);
        params[0] = BoundFramebufferHasDepthAttachment() ? v : 0;
      }
      return true;
    case GL_STENCIL_BITS:
      *num_written = 1;
      if (params) {
        GLint v = 0;
        glGetIntegerv(GL_STENCIL_BITS, &v);
        params[0] = BoundFramebufferHasStencilAttachment() ? v : 0;
      }
      return true;
    case GL_COMPRESSED_TEXTURE_FORMATS:
      *num_written = validators_->compressed_texture_format.GetValues().size();
      if (params) {
        for (GLint ii = 0; ii < *num_written; ++ii) {
          params[ii] = validators_->compressed_texture_format.GetValues()[ii];
        }
      }
      return true;
    case GL_NUM_COMPRESSED_TEXTURE_FORMATS:
      *num_written = 1;
      if (params) {
        *params = validators_->compressed_texture_format.GetValues().size();
      }
      return true;
    case GL_NUM_SHADER_BINARY_FORMATS:
      *num_written = 1;
      if (params) {
        *params = validators_->shader_binary_format.GetValues().size();
      }
      return true;
    case GL_SHADER_BINARY_FORMATS:
      *num_written = validators_->shader_binary_format.GetValues().size();
      if (params) {
        for (GLint ii = 0; ii <  *num_written; ++ii) {
          params[ii] = validators_->shader_binary_format.GetValues()[ii];
        }
      }
      return true;
    case GL_SHADER_COMPILER:
      *num_written = 1;
      if (params) {
        *params = GL_TRUE;
      }
      return true;
    case GL_ARRAY_BUFFER_BINDING:
      *num_written = 1;
      if (params) {
        if (state_.bound_array_buffer.get()) {
          GLuint client_id = 0;
          buffer_manager()->GetClientId(state_.bound_array_buffer->service_id(),
                                        &client_id);
          *params = client_id;
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_ELEMENT_ARRAY_BUFFER_BINDING:
      *num_written = 1;
      if (params) {
        if (state_.vertex_attrib_manager->element_array_buffer()) {
          GLuint client_id = 0;
          buffer_manager()->GetClientId(
              state_.vertex_attrib_manager->element_array_buffer()->
                  service_id(), &client_id);
          *params = client_id;
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_FRAMEBUFFER_BINDING:
    // case GL_DRAW_FRAMEBUFFER_BINDING_EXT: (same as GL_FRAMEBUFFER_BINDING)
      *num_written = 1;
      if (params) {
        Framebuffer* framebuffer =
            GetFramebufferInfoForTarget(GL_FRAMEBUFFER);
        if (framebuffer) {
          GLuint client_id = 0;
          framebuffer_manager()->GetClientId(
              framebuffer->service_id(), &client_id);
          *params = client_id;
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_READ_FRAMEBUFFER_BINDING_EXT:
      *num_written = 1;
      if (params) {
        Framebuffer* framebuffer =
            GetFramebufferInfoForTarget(GL_READ_FRAMEBUFFER_EXT);
        if (framebuffer) {
          GLuint client_id = 0;
          framebuffer_manager()->GetClientId(
              framebuffer->service_id(), &client_id);
          *params = client_id;
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_RENDERBUFFER_BINDING:
      *num_written = 1;
      if (params) {
        Renderbuffer* renderbuffer =
            GetRenderbufferInfoForTarget(GL_RENDERBUFFER);
        if (renderbuffer) {
          *params = renderbuffer->client_id();
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_CURRENT_PROGRAM:
      *num_written = 1;
      if (params) {
        if (state_.current_program.get()) {
          GLuint client_id = 0;
          program_manager()->GetClientId(
              state_.current_program->service_id(), &client_id);
          *params = client_id;
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_VERTEX_ARRAY_BINDING_OES:
      *num_written = 1;
      if (params) {
        if (state_.vertex_attrib_manager.get() !=
            state_.default_vertex_attrib_manager.get()) {
          GLuint client_id = 0;
          vertex_array_manager_->GetClientId(
              state_.vertex_attrib_manager->service_id(), &client_id);
          *params = client_id;
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_TEXTURE_BINDING_2D:
      *num_written = 1;
      if (params) {
        TextureUnit& unit = state_.texture_units[state_.active_texture_unit];
        if (unit.bound_texture_2d.get()) {
          *params = unit.bound_texture_2d->client_id();
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_TEXTURE_BINDING_CUBE_MAP:
      *num_written = 1;
      if (params) {
        TextureUnit& unit = state_.texture_units[state_.active_texture_unit];
        if (unit.bound_texture_cube_map.get()) {
          *params = unit.bound_texture_cube_map->client_id();
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_TEXTURE_BINDING_EXTERNAL_OES:
      *num_written = 1;
      if (params) {
        TextureUnit& unit = state_.texture_units[state_.active_texture_unit];
        if (unit.bound_texture_external_oes.get()) {
          *params = unit.bound_texture_external_oes->client_id();
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_TEXTURE_BINDING_RECTANGLE_ARB:
      *num_written = 1;
      if (params) {
        TextureUnit& unit = state_.texture_units[state_.active_texture_unit];
        if (unit.bound_texture_rectangle_arb.get()) {
          *params = unit.bound_texture_rectangle_arb->client_id();
        } else {
          *params = 0;
        }
      }
      return true;
    case GL_UNPACK_FLIP_Y_CHROMIUM:
      *num_written = 1;
      if (params) {
        params[0] = unpack_flip_y_;
      }
      return true;
    case GL_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM:
      *num_written = 1;
      if (params) {
        params[0] = unpack_premultiply_alpha_;
      }
      return true;
    case GL_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM:
      *num_written = 1;
      if (params) {
        params[0] = unpack_unpremultiply_alpha_;
      }
      return true;
    case GL_BIND_GENERATES_RESOURCE_CHROMIUM:
      *num_written = 1;
      if (params) {
        params[0] = group_->bind_generates_resource() ? 1 : 0;
      }
      return true;
    default:
      if (pname >= GL_DRAW_BUFFER0_ARB &&
          pname < GL_DRAW_BUFFER0_ARB + group_->max_draw_buffers()) {
        *num_written = 1;
        if (params) {
          Framebuffer* framebuffer =
              GetFramebufferInfoForTarget(GL_FRAMEBUFFER);
          if (framebuffer) {
            params[0] = framebuffer->GetDrawBuffer(pname);
          } else {  // backbuffer
            if (pname == GL_DRAW_BUFFER0_ARB)
              params[0] = group_->draw_buffer();
            else
              params[0] = GL_NONE;
          }
        }
        return true;
      }
      *num_written = util_.GLGetNumValuesReturned(pname);
      return false;
  }
}

bool GLES2DecoderImpl::GetNumValuesReturnedForGLGet(
    GLenum pname, GLsizei* num_values) {
  if (state_.GetStateAsGLint(pname, NULL, num_values)) {
    return true;
  }
  return GetHelper(pname, NULL, num_values);
}

GLenum GLES2DecoderImpl::AdjustGetPname(GLenum pname) {
  if (GL_MAX_SAMPLES == pname &&
      features().use_img_for_multisampled_render_to_texture) {
    return GL_MAX_SAMPLES_IMG;
  }
  return pname;
}

void GLES2DecoderImpl::DoGetBooleanv(GLenum pname, GLboolean* params) {
  DCHECK(params);
  GLsizei num_written = 0;
  if (GetNumValuesReturnedForGLGet(pname, &num_written)) {
    scoped_ptr<GLint[]> values(new GLint[num_written]);
    if (!state_.GetStateAsGLint(pname, values.get(), &num_written)) {
      GetHelper(pname, values.get(), &num_written);
    }
    for (GLsizei ii = 0; ii < num_written; ++ii) {
      params[ii] = static_cast<GLboolean>(values[ii]);
    }
  } else {
    pname = AdjustGetPname(pname);
    glGetBooleanv(pname, params);
  }
}

void GLES2DecoderImpl::DoGetFloatv(GLenum pname, GLfloat* params) {
  DCHECK(params);
  GLsizei num_written = 0;
  if (!state_.GetStateAsGLfloat(pname, params, &num_written)) {
    if (GetHelper(pname, NULL, &num_written)) {
      scoped_ptr<GLint[]> values(new GLint[num_written]);
      GetHelper(pname, values.get(), &num_written);
      for (GLsizei ii = 0; ii < num_written; ++ii) {
        params[ii] = static_cast<GLfloat>(values[ii]);
      }
    } else {
      pname = AdjustGetPname(pname);
      glGetFloatv(pname, params);
    }
  }
}

void GLES2DecoderImpl::DoGetInteger64v(GLenum pname, GLint64* params) {
  DCHECK(params);
  pname = AdjustGetPname(pname);
  glGetInteger64v(pname, params);
}

void GLES2DecoderImpl::DoGetIntegerv(GLenum pname, GLint* params) {
  DCHECK(params);
  GLsizei num_written;
  if (!state_.GetStateAsGLint(pname, params, &num_written) &&
      !GetHelper(pname, params, &num_written)) {
    pname = AdjustGetPname(pname);
    glGetIntegerv(pname, params);
  }
}

void GLES2DecoderImpl::DoGetProgramiv(
    GLuint program_id, GLenum pname, GLint* params) {
  Program* program = GetProgramInfoNotShader(program_id, "glGetProgramiv");
  if (!program) {
    return;
  }
  program->GetProgramiv(pname, params);
}

void GLES2DecoderImpl::DoGetBufferParameteriv(
    GLenum target, GLenum pname, GLint* params) {
  // Just delegate it. Some validation is actually done before this.
  buffer_manager()->ValidateAndDoGetBufferParameteriv(
      &state_, target, pname, params);
}

void GLES2DecoderImpl::DoBindAttribLocation(
    GLuint program_id, GLuint index, const char* name) {
  if (!StringIsValidForGLES(name)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glBindAttribLocation", "Invalid character");
    return;
  }
  if (ProgramManager::IsInvalidPrefix(name, strlen(name))) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glBindAttribLocation", "reserved prefix");
    return;
  }
  if (index >= group_->max_vertex_attribs()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glBindAttribLocation", "index out of range");
    return;
  }
  Program* program = GetProgramInfoNotShader(
      program_id, "glBindAttribLocation");
  if (!program) {
    return;
  }
  // At this point, the program's shaders may not be translated yet,
  // therefore, we may not find the hashed attribute name.
  // glBindAttribLocation call with original name is useless.
  // So instead, we should simply cache the binding, and then call
  // Program::ExecuteBindAttribLocationCalls() right before link.
  program->SetAttribLocationBinding(name, static_cast<GLint>(index));
  // TODO(zmo): Get rid of the following glBindAttribLocation call.
  glBindAttribLocation(program->service_id(), index, name);
}

error::Error GLES2DecoderImpl::HandleBindAttribLocationBucket(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BindAttribLocationBucket& c =
      *static_cast<const gles2::cmds::BindAttribLocationBucket*>(cmd_data);
  GLuint program = static_cast<GLuint>(c.program);
  GLuint index = static_cast<GLuint>(c.index);
  Bucket* bucket = GetBucket(c.name_bucket_id);
  if (!bucket || bucket->size() == 0) {
    return error::kInvalidArguments;
  }
  std::string name_str;
  if (!bucket->GetAsString(&name_str)) {
    return error::kInvalidArguments;
  }
  DoBindAttribLocation(program, index, name_str.c_str());
  return error::kNoError;
}

void GLES2DecoderImpl::DoBindUniformLocationCHROMIUM(
    GLuint program_id, GLint location, const char* name) {
  if (!StringIsValidForGLES(name)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glBindUniformLocationCHROMIUM", "Invalid character");
    return;
  }
  if (ProgramManager::IsInvalidPrefix(name, strlen(name))) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glBindUniformLocationCHROMIUM", "reserved prefix");
    return;
  }
  if (location < 0 || static_cast<uint32>(location) >=
      (group_->max_fragment_uniform_vectors() +
       group_->max_vertex_uniform_vectors()) * 4) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glBindUniformLocationCHROMIUM", "location out of range");
    return;
  }
  Program* program = GetProgramInfoNotShader(
      program_id, "glBindUniformLocationCHROMIUM");
  if (!program) {
    return;
  }
  if (!program->SetUniformLocationBinding(name, location)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glBindUniformLocationCHROMIUM", "location out of range");
  }
}

error::Error GLES2DecoderImpl::HandleBindUniformLocationCHROMIUMBucket(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::BindUniformLocationCHROMIUMBucket& c =
      *static_cast<const gles2::cmds::BindUniformLocationCHROMIUMBucket*>(
          cmd_data);
  GLuint program = static_cast<GLuint>(c.program);
  GLint location = static_cast<GLint>(c.location);
  Bucket* bucket = GetBucket(c.name_bucket_id);
  if (!bucket || bucket->size() == 0) {
    return error::kInvalidArguments;
  }
  std::string name_str;
  if (!bucket->GetAsString(&name_str)) {
    return error::kInvalidArguments;
  }
  DoBindUniformLocationCHROMIUM(program, location, name_str.c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteShader(uint32 immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::DeleteShader& c =
      *static_cast<const gles2::cmds::DeleteShader*>(cmd_data);
  GLuint client_id = c.shader;
  if (client_id) {
    Shader* shader = GetShader(client_id);
    if (shader) {
      if (!shader->IsDeleted()) {
        shader_manager()->Delete(shader);
      }
    } else {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glDeleteShader", "unknown shader");
    }
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDeleteProgram(uint32 immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::DeleteProgram& c =
      *static_cast<const gles2::cmds::DeleteProgram*>(cmd_data);
  GLuint client_id = c.program;
  if (client_id) {
    Program* program = GetProgram(client_id);
    if (program) {
      if (!program->IsDeleted()) {
        program_manager()->MarkAsDeleted(shader_manager(), program);
      }
    } else {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glDeleteProgram", "unknown program");
    }
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::DoClear(GLbitfield mask) {
  DCHECK(!ShouldDeferDraws());
  if (CheckBoundFramebuffersValid("glClear")) {
    ApplyDirtyState();
    ScopedRenderTo do_render(framebuffer_state_.bound_draw_framebuffer.get());
    if (workarounds().gl_clear_broken) {
      ScopedGLErrorSuppressor suppressor("GLES2DecoderImpl::ClearWorkaround",
                                         GetErrorState());
      if (!BoundFramebufferHasDepthAttachment())
        mask &= ~GL_DEPTH_BUFFER_BIT;
      if (!BoundFramebufferHasStencilAttachment())
        mask &= ~GL_STENCIL_BUFFER_BIT;
      clear_framebuffer_blit_->ClearFramebuffer(
          this, GetBoundReadFrameBufferSize(), mask, state_.color_clear_red,
          state_.color_clear_green, state_.color_clear_blue,
          state_.color_clear_alpha, state_.depth_clear, state_.stencil_clear);
      return error::kNoError;
    }
    glClear(mask);
  }
  return error::kNoError;
}

void GLES2DecoderImpl::DoFramebufferRenderbuffer(
    GLenum target, GLenum attachment, GLenum renderbuffertarget,
    GLuint client_renderbuffer_id) {
  Framebuffer* framebuffer = GetFramebufferInfoForTarget(target);
  if (!framebuffer) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glFramebufferRenderbuffer", "no framebuffer bound");
    return;
  }
  GLuint service_id = 0;
  Renderbuffer* renderbuffer = NULL;
  if (client_renderbuffer_id) {
    renderbuffer = GetRenderbuffer(client_renderbuffer_id);
    if (!renderbuffer) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glFramebufferRenderbuffer", "unknown renderbuffer");
      return;
    }
    service_id = renderbuffer->service_id();
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glFramebufferRenderbuffer");
  glFramebufferRenderbufferEXT(
      target, attachment, renderbuffertarget, service_id);
  GLenum error = LOCAL_PEEK_GL_ERROR("glFramebufferRenderbuffer");
  if (error == GL_NO_ERROR) {
    framebuffer->AttachRenderbuffer(attachment, renderbuffer);
  }
  if (framebuffer == framebuffer_state_.bound_draw_framebuffer.get()) {
    framebuffer_state_.clear_state_dirty = true;
  }
  OnFboChanged();
}

void GLES2DecoderImpl::DoDisable(GLenum cap) {
  if (SetCapabilityState(cap, false)) {
    glDisable(cap);
  }
}

void GLES2DecoderImpl::DoEnable(GLenum cap) {
  if (SetCapabilityState(cap, true)) {
    glEnable(cap);
  }
}

void GLES2DecoderImpl::DoDepthRangef(GLclampf znear, GLclampf zfar) {
  state_.z_near = std::min(1.0f, std::max(0.0f, znear));
  state_.z_far = std::min(1.0f, std::max(0.0f, zfar));
  glDepthRange(znear, zfar);
}

void GLES2DecoderImpl::DoSampleCoverage(GLclampf value, GLboolean invert) {
  state_.sample_coverage_value = std::min(1.0f, std::max(0.0f, value));
  state_.sample_coverage_invert = (invert != 0);
  glSampleCoverage(state_.sample_coverage_value, invert);
}

// Assumes framebuffer is complete.
void GLES2DecoderImpl::ClearUnclearedAttachments(
    GLenum target, Framebuffer* framebuffer) {
  if (target == GL_READ_FRAMEBUFFER_EXT) {
    // bind this to the DRAW point, clear then bind back to READ
    // TODO(gman): I don't think there is any guarantee that an FBO that
    //   is complete on the READ attachment will be complete as a DRAW
    //   attachment.
    glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT, 0);
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, framebuffer->service_id());
  }
  GLbitfield clear_bits = 0;
  if (framebuffer->HasUnclearedColorAttachments()) {
    glClearColor(
        0.0f, 0.0f, 0.0f,
        (GLES2Util::GetChannelsForFormat(
             framebuffer->GetColorAttachmentFormat()) & 0x0008) != 0 ? 0.0f :
                                                                       1.0f);
    state_.SetDeviceColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    clear_bits |= GL_COLOR_BUFFER_BIT;
    if (feature_info_->feature_flags().ext_draw_buffers)
      framebuffer->PrepareDrawBuffersForClear();
  }

  if (framebuffer->HasUnclearedAttachment(GL_STENCIL_ATTACHMENT) ||
      framebuffer->HasUnclearedAttachment(GL_DEPTH_STENCIL_ATTACHMENT)) {
    glClearStencil(0);
    state_.SetDeviceStencilMaskSeparate(GL_FRONT, kDefaultStencilMask);
    state_.SetDeviceStencilMaskSeparate(GL_BACK, kDefaultStencilMask);
    clear_bits |= GL_STENCIL_BUFFER_BIT;
  }

  if (framebuffer->HasUnclearedAttachment(GL_DEPTH_ATTACHMENT) ||
      framebuffer->HasUnclearedAttachment(GL_DEPTH_STENCIL_ATTACHMENT)) {
    glClearDepth(1.0f);
    state_.SetDeviceDepthMask(GL_TRUE);
    clear_bits |= GL_DEPTH_BUFFER_BIT;
  }

  state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);
  glClear(clear_bits);

  if ((clear_bits & GL_COLOR_BUFFER_BIT) != 0 &&
      feature_info_->feature_flags().ext_draw_buffers)
    framebuffer->RestoreDrawBuffersAfterClear();

  framebuffer_manager()->MarkAttachmentsAsCleared(
      framebuffer, renderbuffer_manager(), texture_manager());

  RestoreClearState();

  if (target == GL_READ_FRAMEBUFFER_EXT) {
    glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT, framebuffer->service_id());
    Framebuffer* draw_framebuffer =
        GetFramebufferInfoForTarget(GL_DRAW_FRAMEBUFFER_EXT);
    GLuint service_id = draw_framebuffer ? draw_framebuffer->service_id() :
                                           GetBackbufferServiceId();
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, service_id);
  }
}

void GLES2DecoderImpl::RestoreClearState() {
  framebuffer_state_.clear_state_dirty = true;
  glClearColor(
      state_.color_clear_red, state_.color_clear_green, state_.color_clear_blue,
      state_.color_clear_alpha);
  glClearStencil(state_.stencil_clear);
  glClearDepth(state_.depth_clear);
  if (state_.enable_flags.scissor_test) {
    state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, true);
  }
}

GLenum GLES2DecoderImpl::DoCheckFramebufferStatus(GLenum target) {
  Framebuffer* framebuffer =
      GetFramebufferInfoForTarget(target);
  if (!framebuffer) {
    return GL_FRAMEBUFFER_COMPLETE;
  }
  GLenum completeness = framebuffer->IsPossiblyComplete();
  if (completeness != GL_FRAMEBUFFER_COMPLETE) {
    return completeness;
  }
  return framebuffer->GetStatus(texture_manager(), target);
}

void GLES2DecoderImpl::DoFramebufferTexture2D(
    GLenum target, GLenum attachment, GLenum textarget,
    GLuint client_texture_id, GLint level) {
  DoFramebufferTexture2DCommon(
    "glFramebufferTexture2D", target, attachment,
    textarget, client_texture_id, level, 0);
}

void GLES2DecoderImpl::DoFramebufferTexture2DMultisample(
    GLenum target, GLenum attachment, GLenum textarget,
    GLuint client_texture_id, GLint level, GLsizei samples) {
  DoFramebufferTexture2DCommon(
    "glFramebufferTexture2DMultisample", target, attachment,
    textarget, client_texture_id, level, samples);
}

void GLES2DecoderImpl::DoFramebufferTexture2DCommon(
    const char* name, GLenum target, GLenum attachment, GLenum textarget,
    GLuint client_texture_id, GLint level, GLsizei samples) {
  if (samples > renderbuffer_manager()->max_samples()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glFramebufferTexture2DMultisample", "samples too large");
    return;
  }
  Framebuffer* framebuffer = GetFramebufferInfoForTarget(target);
  if (!framebuffer) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        name, "no framebuffer bound.");
    return;
  }
  GLuint service_id = 0;
  TextureRef* texture_ref = NULL;
  if (client_texture_id) {
    texture_ref = GetTexture(client_texture_id);
    if (!texture_ref) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          name, "unknown texture_ref");
      return;
    }
    service_id = texture_ref->service_id();
  }

  if (!texture_manager()->ValidForTarget(textarget, level, 0, 0, 1)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        name, "level out of range");
    return;
  }

  if (texture_ref)
    DoWillUseTexImageIfNeeded(texture_ref->texture(), textarget);

  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER(name);
  if (0 == samples) {
    glFramebufferTexture2DEXT(target, attachment, textarget, service_id, level);
  } else {
    if (features().use_img_for_multisampled_render_to_texture) {
      glFramebufferTexture2DMultisampleIMG(target, attachment, textarget,
          service_id, level, samples);
    } else {
      glFramebufferTexture2DMultisampleEXT(target, attachment, textarget,
          service_id, level, samples);
    }
  }
  GLenum error = LOCAL_PEEK_GL_ERROR(name);
  if (error == GL_NO_ERROR) {
    framebuffer->AttachTexture(attachment, texture_ref, textarget, level,
         samples);
  }
  if (framebuffer == framebuffer_state_.bound_draw_framebuffer.get()) {
    framebuffer_state_.clear_state_dirty = true;
  }

  if (texture_ref)
    DoDidUseTexImageIfNeeded(texture_ref->texture(), textarget);

  OnFboChanged();
}

void GLES2DecoderImpl::DoFramebufferTextureLayer(
    GLenum target, GLenum attachment, GLuint client_texture_id,
    GLint level, GLint layer) {
  // TODO(zmo): Unsafe ES3 API, missing states update.
  GLuint service_id = 0;
  TextureRef* texture_ref = NULL;
  if (client_texture_id) {
    texture_ref = GetTexture(client_texture_id);
    if (!texture_ref) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glFramebufferTextureLayer", "unknown texture_ref");
      return;
    }
    service_id = texture_ref->service_id();
  }
  glFramebufferTextureLayer(target, attachment, service_id, level, layer);
}

void GLES2DecoderImpl::DoGetFramebufferAttachmentParameteriv(
    GLenum target, GLenum attachment, GLenum pname, GLint* params) {
  Framebuffer* framebuffer = GetFramebufferInfoForTarget(target);
  if (!framebuffer) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glGetFramebufferAttachmentParameteriv", "no framebuffer bound");
    return;
  }
  if (pname == GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME) {
    const Framebuffer::Attachment* attachment_object =
        framebuffer->GetAttachment(attachment);
    *params = attachment_object ? attachment_object->object_name() : 0;
  } else {
    if (pname == GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_SAMPLES_EXT &&
        features().use_img_for_multisampled_render_to_texture) {
      pname = GL_TEXTURE_SAMPLES_IMG;
    }
    glGetFramebufferAttachmentParameterivEXT(target, attachment, pname, params);
  }
}

void GLES2DecoderImpl::DoGetRenderbufferParameteriv(
    GLenum target, GLenum pname, GLint* params) {
  Renderbuffer* renderbuffer =
      GetRenderbufferInfoForTarget(GL_RENDERBUFFER);
  if (!renderbuffer) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glGetRenderbufferParameteriv", "no renderbuffer bound");
    return;
  }

  EnsureRenderbufferBound();
  switch (pname) {
    case GL_RENDERBUFFER_INTERNAL_FORMAT:
      *params = renderbuffer->internal_format();
      break;
    case GL_RENDERBUFFER_WIDTH:
      *params = renderbuffer->width();
      break;
    case GL_RENDERBUFFER_HEIGHT:
      *params = renderbuffer->height();
      break;
    case GL_RENDERBUFFER_SAMPLES_EXT:
      if (features().use_img_for_multisampled_render_to_texture) {
        glGetRenderbufferParameterivEXT(target, GL_RENDERBUFFER_SAMPLES_IMG,
            params);
      } else {
        glGetRenderbufferParameterivEXT(target, GL_RENDERBUFFER_SAMPLES_EXT,
            params);
      }
    default:
      glGetRenderbufferParameterivEXT(target, pname, params);
      break;
  }
}

void GLES2DecoderImpl::DoBlitFramebufferCHROMIUM(
    GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1,
    GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1,
    GLbitfield mask, GLenum filter) {
  DCHECK(!ShouldDeferReads() && !ShouldDeferDraws());

  if (!CheckBoundFramebuffersValid("glBlitFramebufferCHROMIUM")) {
    return;
  }

  state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);
  ScopedRenderTo do_render(framebuffer_state_.bound_draw_framebuffer.get());
  BlitFramebufferHelper(
      srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
  state_.SetDeviceCapabilityState(GL_SCISSOR_TEST,
                                  state_.enable_flags.scissor_test);
}

void GLES2DecoderImpl::EnsureRenderbufferBound() {
  if (!state_.bound_renderbuffer_valid) {
    state_.bound_renderbuffer_valid = true;
    glBindRenderbufferEXT(GL_RENDERBUFFER,
                          state_.bound_renderbuffer.get()
                              ? state_.bound_renderbuffer->service_id()
                              : 0);
  }
}

void GLES2DecoderImpl::RenderbufferStorageMultisampleHelper(
    const FeatureInfo* feature_info,
    GLenum target,
    GLsizei samples,
    GLenum internal_format,
    GLsizei width,
    GLsizei height) {
  // TODO(sievers): This could be resolved at the GL binding level, but the
  // binding process is currently a bit too 'brute force'.
  if (feature_info->gl_version_info().is_angle) {
    glRenderbufferStorageMultisampleANGLE(
        target, samples, internal_format, width, height);
  } else if (feature_info->feature_flags().use_core_framebuffer_multisample) {
    glRenderbufferStorageMultisample(
        target, samples, internal_format, width, height);
  } else {
    glRenderbufferStorageMultisampleEXT(
        target, samples, internal_format, width, height);
  }
}

void GLES2DecoderImpl::BlitFramebufferHelper(GLint srcX0,
                                             GLint srcY0,
                                             GLint srcX1,
                                             GLint srcY1,
                                             GLint dstX0,
                                             GLint dstY0,
                                             GLint dstX1,
                                             GLint dstY1,
                                             GLbitfield mask,
                                             GLenum filter) {
  // TODO(sievers): This could be resolved at the GL binding level, but the
  // binding process is currently a bit too 'brute force'.
  if (feature_info_->gl_version_info().is_angle) {
    glBlitFramebufferANGLE(
        srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
  } else if (feature_info_->feature_flags().use_core_framebuffer_multisample) {
    glBlitFramebuffer(
        srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
  } else {
    glBlitFramebufferEXT(
        srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
  }
}

bool GLES2DecoderImpl::ValidateRenderbufferStorageMultisample(
    GLsizei samples,
    GLenum internalformat,
    GLsizei width,
    GLsizei height) {
  if (samples > renderbuffer_manager()->max_samples()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glRenderbufferStorageMultisample", "samples too large");
    return false;
  }

  if (width > renderbuffer_manager()->max_renderbuffer_size() ||
      height > renderbuffer_manager()->max_renderbuffer_size()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glRenderbufferStorageMultisample", "dimensions too large");
    return false;
  }

  uint32 estimated_size = 0;
  if (!renderbuffer_manager()->ComputeEstimatedRenderbufferSize(
           width, height, samples, internalformat, &estimated_size)) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY,
        "glRenderbufferStorageMultisample", "dimensions too large");
    return false;
  }

  if (!EnsureGPUMemoryAvailable(estimated_size)) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY,
        "glRenderbufferStorageMultisample", "out of memory");
    return false;
  }

  return true;
}

void GLES2DecoderImpl::DoRenderbufferStorageMultisampleCHROMIUM(
    GLenum target, GLsizei samples, GLenum internalformat,
    GLsizei width, GLsizei height) {
  Renderbuffer* renderbuffer = GetRenderbufferInfoForTarget(GL_RENDERBUFFER);
  if (!renderbuffer) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glRenderbufferStorageMultisampleCHROMIUM",
                       "no renderbuffer bound");
    return;
  }

  if (!ValidateRenderbufferStorageMultisample(
      samples, internalformat, width, height)) {
    return;
  }

  EnsureRenderbufferBound();
  GLenum impl_format =
      renderbuffer_manager()->InternalRenderbufferFormatToImplFormat(
          internalformat);
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER(
      "glRenderbufferStorageMultisampleCHROMIUM");
  RenderbufferStorageMultisampleHelper(
      feature_info_.get(), target, samples, impl_format, width, height);
  GLenum error =
      LOCAL_PEEK_GL_ERROR("glRenderbufferStorageMultisampleCHROMIUM");
  if (error == GL_NO_ERROR) {
    if (workarounds().validate_multisample_buffer_allocation) {
      if (!VerifyMultisampleRenderbufferIntegrity(
          renderbuffer->service_id(), impl_format)) {
        LOCAL_SET_GL_ERROR(
            GL_OUT_OF_MEMORY,
            "glRenderbufferStorageMultisampleCHROMIUM", "out of memory");
        return;
      }
    }

    // TODO(gman): If renderbuffers tracked which framebuffers they were
    // attached to we could just mark those framebuffers as not complete.
    framebuffer_manager()->IncFramebufferStateChangeCount();
    renderbuffer_manager()->SetInfo(
        renderbuffer, samples, internalformat, width, height);
  }
}

// This is the handler for multisampled_render_to_texture extensions.
void GLES2DecoderImpl::DoRenderbufferStorageMultisampleEXT(
    GLenum target, GLsizei samples, GLenum internalformat,
    GLsizei width, GLsizei height) {
  Renderbuffer* renderbuffer = GetRenderbufferInfoForTarget(GL_RENDERBUFFER);
  if (!renderbuffer) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glRenderbufferStorageMultisampleEXT",
                       "no renderbuffer bound");
    return;
  }

  if (!ValidateRenderbufferStorageMultisample(
      samples, internalformat, width, height)) {
    return;
  }

  EnsureRenderbufferBound();
  GLenum impl_format =
      renderbuffer_manager()->InternalRenderbufferFormatToImplFormat(
          internalformat);
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glRenderbufferStorageMultisampleEXT");
  if (features().use_img_for_multisampled_render_to_texture) {
    glRenderbufferStorageMultisampleIMG(
        target, samples, impl_format, width, height);
  } else {
    glRenderbufferStorageMultisampleEXT(
        target, samples, impl_format, width, height);
  }
  GLenum error = LOCAL_PEEK_GL_ERROR("glRenderbufferStorageMultisampleEXT");
  if (error == GL_NO_ERROR) {
    // TODO(gman): If renderbuffers tracked which framebuffers they were
    // attached to we could just mark those framebuffers as not complete.
    framebuffer_manager()->IncFramebufferStateChangeCount();
    renderbuffer_manager()->SetInfo(
        renderbuffer, samples, internalformat, width, height);
  }
}

// This function validates the allocation of a multisampled renderbuffer
// by clearing it to a key color, blitting the contents to a texture, and
// reading back the color to ensure it matches the key.
bool GLES2DecoderImpl::VerifyMultisampleRenderbufferIntegrity(
    GLuint renderbuffer, GLenum format) {

  // Only validate color buffers.
  // These formats have been selected because they are very common or are known
  // to be used by the WebGL backbuffer. If problems are observed with other
  // color formats they can be added here.
  switch (format) {
    case GL_RGB:
    case GL_RGB8:
    case GL_RGBA:
    case GL_RGBA8:
      break;
    default:
      return true;
  }

  GLint draw_framebuffer, read_framebuffer;

  // Cache framebuffer and texture bindings.
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_framebuffer);
  glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_framebuffer);

  if (!validation_texture_) {
    GLint bound_texture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &bound_texture);

    // Create additional resources needed for the verification.
    glGenTextures(1, &validation_texture_);
    glGenFramebuffersEXT(1, &validation_fbo_multisample_);
    glGenFramebuffersEXT(1, &validation_fbo_);

    // Texture only needs to be 1x1.
    glBindTexture(GL_TEXTURE_2D, validation_texture_);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 1, 1, 0, GL_RGB,
        GL_UNSIGNED_BYTE, NULL);

    glBindFramebufferEXT(GL_FRAMEBUFFER, validation_fbo_);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
        GL_TEXTURE_2D, validation_texture_, 0);

    glBindTexture(GL_TEXTURE_2D, bound_texture);
  }

  glBindFramebufferEXT(GL_FRAMEBUFFER, validation_fbo_multisample_);
  glFramebufferRenderbufferEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
      GL_RENDERBUFFER, renderbuffer);

  // Cache current state and reset it to the values we require.
  GLboolean scissor_enabled = false;
  glGetBooleanv(GL_SCISSOR_TEST, &scissor_enabled);
  if (scissor_enabled)
    state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);

  GLboolean color_mask[4] = {GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE};
  glGetBooleanv(GL_COLOR_WRITEMASK, color_mask);
  state_.SetDeviceColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

  GLfloat clear_color[4] = {0.0f, 0.0f, 0.0f, 0.0f};
  glGetFloatv(GL_COLOR_CLEAR_VALUE, clear_color);
  glClearColor(1.0f, 0.0f, 1.0f, 1.0f);

  // Clear the buffer to the desired key color.
  glClear(GL_COLOR_BUFFER_BIT);

  // Blit from the multisample buffer to a standard texture.
  glBindFramebufferEXT(GL_READ_FRAMEBUFFER, validation_fbo_multisample_);
  glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER, validation_fbo_);

  BlitFramebufferHelper(
      0, 0, 1, 1, 0, 0, 1, 1, GL_COLOR_BUFFER_BIT, GL_NEAREST);

  // Read a pixel from the buffer.
  glBindFramebufferEXT(GL_FRAMEBUFFER, validation_fbo_);

  unsigned char pixel[3] = {0, 0, 0};
  glReadPixels(0, 0, 1, 1, GL_RGB, GL_UNSIGNED_BYTE, &pixel);

  // Detach the renderbuffer.
  glBindFramebufferEXT(GL_FRAMEBUFFER, validation_fbo_multisample_);
  glFramebufferRenderbufferEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
      GL_RENDERBUFFER, 0);

  // Restore cached state.
  if (scissor_enabled)
    state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, true);

  state_.SetDeviceColorMask(
      color_mask[0], color_mask[1], color_mask[2], color_mask[3]);
  glClearColor(clear_color[0], clear_color[1], clear_color[2], clear_color[3]);
  glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER, draw_framebuffer);
  glBindFramebufferEXT(GL_READ_FRAMEBUFFER, read_framebuffer);

  // Return true if the pixel matched the desired key color.
  return (pixel[0] == 0xFF &&
      pixel[1] == 0x00 &&
      pixel[2] == 0xFF);
}

void GLES2DecoderImpl::DoRenderbufferStorage(
  GLenum target, GLenum internalformat, GLsizei width, GLsizei height) {
  Renderbuffer* renderbuffer =
      GetRenderbufferInfoForTarget(GL_RENDERBUFFER);
  if (!renderbuffer) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glRenderbufferStorage", "no renderbuffer bound");
    return;
  }

  if (width > renderbuffer_manager()->max_renderbuffer_size() ||
      height > renderbuffer_manager()->max_renderbuffer_size()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glRenderbufferStorage", "dimensions too large");
    return;
  }

  uint32 estimated_size = 0;
  if (!renderbuffer_manager()->ComputeEstimatedRenderbufferSize(
           width, height, 1, internalformat, &estimated_size)) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY, "glRenderbufferStorage", "dimensions too large");
    return;
  }

  if (!EnsureGPUMemoryAvailable(estimated_size)) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY, "glRenderbufferStorage", "out of memory");
    return;
  }

  EnsureRenderbufferBound();
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glRenderbufferStorage");
  glRenderbufferStorageEXT(
      target,
      renderbuffer_manager()->InternalRenderbufferFormatToImplFormat(
          internalformat),
      width,
      height);
  GLenum error = LOCAL_PEEK_GL_ERROR("glRenderbufferStorage");
  if (error == GL_NO_ERROR) {
    // TODO(gman): If tetxures tracked which framebuffers they were attached to
    // we could just mark those framebuffers as not complete.
    framebuffer_manager()->IncFramebufferStateChangeCount();
    renderbuffer_manager()->SetInfo(
        renderbuffer, 1, internalformat, width, height);
  }
}

void GLES2DecoderImpl::DoLinkProgram(GLuint program_id) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::DoLinkProgram");
  Program* program = GetProgramInfoNotShader(
      program_id, "glLinkProgram");
  if (!program) {
    return;
  }

  LogClientServiceForInfo(program, program_id, "glLinkProgram");
  if (program->Link(shader_manager(),
                    workarounds().count_all_in_varyings_packing ?
                        Program::kCountAll : Program::kCountOnlyStaticallyUsed,
                    shader_cache_callback_)) {
    if (program == state_.current_program.get()) {
      if (workarounds().use_current_program_after_successful_link)
        glUseProgram(program->service_id());
      if (workarounds().clear_uniforms_before_first_program_use)
        program_manager()->ClearUniforms(program);
    }
  }

  // LinkProgram can be very slow.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
}

void GLES2DecoderImpl::DoSamplerParameterfv(
    GLuint sampler, GLenum pname, const GLfloat* params) {
  DCHECK(params);
  glSamplerParameterf(sampler, pname, params[0]);
}

void GLES2DecoderImpl::DoSamplerParameteriv(
    GLuint sampler, GLenum pname, const GLint* params) {
  DCHECK(params);
  glSamplerParameteri(sampler, pname, params[0]);
}

void GLES2DecoderImpl::DoTexParameterf(
    GLenum target, GLenum pname, GLfloat param) {
  TextureRef* texture = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexParameterf", "unknown texture");
    return;
  }

  texture_manager()->SetParameterf(
      "glTexParameterf", GetErrorState(), texture, pname, param);
}

void GLES2DecoderImpl::DoTexParameteri(
    GLenum target, GLenum pname, GLint param) {
  TextureRef* texture = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexParameteri", "unknown texture");
    return;
  }

  texture_manager()->SetParameteri(
      "glTexParameteri", GetErrorState(), texture, pname, param);
}

void GLES2DecoderImpl::DoTexParameterfv(
    GLenum target, GLenum pname, const GLfloat* params) {
  TextureRef* texture = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glTexParameterfv", "unknown texture");
    return;
  }

  texture_manager()->SetParameterf(
      "glTexParameterfv", GetErrorState(), texture, pname, *params);
}

void GLES2DecoderImpl::DoTexParameteriv(
  GLenum target, GLenum pname, const GLint* params) {
  TextureRef* texture = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glTexParameteriv", "unknown texture");
    return;
  }

  texture_manager()->SetParameteri(
      "glTexParameteriv", GetErrorState(), texture, pname, *params);
}

bool GLES2DecoderImpl::CheckCurrentValuebuffer(const char* function_name) {
  if (!state_.bound_valuebuffer.get()) {
    // There is no valuebuffer bound
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name,
                       "no valuebuffer in use");
    return false;
  }
  return true;
}

bool GLES2DecoderImpl::CheckCurrentValuebufferForSubscription(
    GLenum subscription,
    const char* function_name) {
  if (!CheckCurrentValuebuffer(function_name)) {
    return false;
  }
  if (!state_.bound_valuebuffer.get()->IsSubscribed(subscription)) {
    // The valuebuffer is not subscribed to the target
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name,
                       "valuebuffer is not subscribed");
    return false;
  }
  return true;
}

bool GLES2DecoderImpl::CheckSubscriptionTarget(GLint location,
                                               GLenum subscription,
                                               const char* function_name) {
  if (!CheckCurrentProgramForUniform(location, function_name)) {
    return false;
  }
  GLint real_location = -1;
  GLint array_index = -1;
  const Program::UniformInfo* info =
      state_.current_program->GetUniformInfoByFakeLocation(
          location, &real_location, &array_index);
  if (!info) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name, "unknown location");
    return false;
  }
  if ((ValuebufferManager::ApiTypeForSubscriptionTarget(subscription) &
       info->accepts_api_type) == 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name,
                       "wrong type for subscription");
    return false;
  }
  return true;
}

bool GLES2DecoderImpl::CheckCurrentProgram(const char* function_name) {
  if (!state_.current_program.get()) {
    // The program does not exist.
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name, "no program in use");
    return false;
  }
  if (!state_.current_program->InUse()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name, "program not linked");
    return false;
  }
  return true;
}

bool GLES2DecoderImpl::CheckCurrentProgramForUniform(
    GLint location, const char* function_name) {
  if (!CheckCurrentProgram(function_name)) {
    return false;
  }
  return location != -1;
}

bool GLES2DecoderImpl::CheckDrawingFeedbackLoops() {
  Framebuffer* framebuffer = GetFramebufferInfoForTarget(GL_FRAMEBUFFER);
  if (!framebuffer)
    return false;
  const Framebuffer::Attachment* attachment =
      framebuffer->GetAttachment(GL_COLOR_ATTACHMENT0);
  if (!attachment)
    return false;

  DCHECK(state_.current_program.get());
  const Program::SamplerIndices& sampler_indices =
      state_.current_program->sampler_indices();
  for (size_t ii = 0; ii < sampler_indices.size(); ++ii) {
    const Program::UniformInfo* uniform_info =
        state_.current_program->GetUniformInfo(sampler_indices[ii]);
    DCHECK(uniform_info);
    if (uniform_info->type != GL_SAMPLER_2D)
      continue;
    for (size_t jj = 0; jj < uniform_info->texture_units.size(); ++jj) {
      GLuint texture_unit_index = uniform_info->texture_units[jj];
      if (texture_unit_index >= state_.texture_units.size())
        continue;
      TextureUnit& texture_unit = state_.texture_units[texture_unit_index];
      TextureRef* texture_ref =
          texture_unit.GetInfoForSamplerType(GL_SAMPLER_2D).get();
      if (attachment->IsTexture(texture_ref))
        return true;
    }
  }
  return false;
}

bool GLES2DecoderImpl::CheckUniformForApiType(
    const Program::UniformInfo* info,
    const char* function_name,
    Program::UniformApiType api_type) {
  DCHECK(info);
  if ((api_type & info->accepts_api_type) == 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name,
                       "wrong uniform function for type");
    return false;
  }
  return true;
}

bool GLES2DecoderImpl::PrepForSetUniformByLocation(
    GLint fake_location,
    const char* function_name,
    Program::UniformApiType api_type,
    GLint* real_location,
    GLenum* type,
    GLsizei* count) {
  DCHECK(type);
  DCHECK(count);
  DCHECK(real_location);

  if (!CheckCurrentProgramForUniform(fake_location, function_name)) {
    return false;
  }
  GLint array_index = -1;
  const Program::UniformInfo* info =
      state_.current_program->GetUniformInfoByFakeLocation(
          fake_location, real_location, &array_index);
  if (!info) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name, "unknown location");
    return false;
  }
  if (!CheckUniformForApiType(info, function_name, api_type)) {
    return false;
  }
  if (*count > 1 && !info->is_array) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name, "count > 1 for non-array");
    return false;
  }
  *count = std::min(info->size - array_index, *count);
  if (*count <= 0) {
    return false;
  }
  *type = info->type;
  return true;
}

void GLES2DecoderImpl::DoUniform1i(GLint fake_location, GLint v0) {
  GLenum type = 0;
  GLsizei count = 1;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform1i",
                                   Program::kUniform1i,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  if (!state_.current_program->SetSamplers(
      state_.texture_units.size(), fake_location, 1, &v0)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glUniform1i", "texture unit out of range");
    return;
  }
  glUniform1i(real_location, v0);
}

void GLES2DecoderImpl::DoUniform1iv(
    GLint fake_location, GLsizei count, const GLint *value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform1iv",
                                   Program::kUniform1i,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  if (type == GL_SAMPLER_2D || type == GL_SAMPLER_2D_RECT_ARB ||
      type == GL_SAMPLER_CUBE || type == GL_SAMPLER_EXTERNAL_OES) {
    if (!state_.current_program->SetSamplers(
          state_.texture_units.size(), fake_location, count, value)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glUniform1iv", "texture unit out of range");
      return;
    }
  }
  glUniform1iv(real_location, count, value);
}

void GLES2DecoderImpl::DoUniform1fv(
    GLint fake_location, GLsizei count, const GLfloat* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform1fv",
                                   Program::kUniform1f,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  if (type == GL_BOOL) {
    scoped_ptr<GLint[]> temp(new GLint[count]);
    for (GLsizei ii = 0; ii < count; ++ii) {
      temp[ii] = static_cast<GLint>(value[ii] != 0.0f);
    }
    DoUniform1iv(real_location, count, temp.get());
  } else {
    glUniform1fv(real_location, count, value);
  }
}

void GLES2DecoderImpl::DoUniform2fv(
    GLint fake_location, GLsizei count, const GLfloat* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform2fv",
                                   Program::kUniform2f,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  if (type == GL_BOOL_VEC2) {
    GLsizei num_values = count * 2;
    scoped_ptr<GLint[]> temp(new GLint[num_values]);
    for (GLsizei ii = 0; ii < num_values; ++ii) {
      temp[ii] = static_cast<GLint>(value[ii] != 0.0f);
    }
    glUniform2iv(real_location, count, temp.get());
  } else {
    glUniform2fv(real_location, count, value);
  }
}

void GLES2DecoderImpl::DoUniform3fv(
    GLint fake_location, GLsizei count, const GLfloat* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform3fv",
                                   Program::kUniform3f,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  if (type == GL_BOOL_VEC3) {
    GLsizei num_values = count * 3;
    scoped_ptr<GLint[]> temp(new GLint[num_values]);
    for (GLsizei ii = 0; ii < num_values; ++ii) {
      temp[ii] = static_cast<GLint>(value[ii] != 0.0f);
    }
    glUniform3iv(real_location, count, temp.get());
  } else {
    glUniform3fv(real_location, count, value);
  }
}

void GLES2DecoderImpl::DoUniform4fv(
    GLint fake_location, GLsizei count, const GLfloat* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform4fv",
                                   Program::kUniform4f,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  if (type == GL_BOOL_VEC4) {
    GLsizei num_values = count * 4;
    scoped_ptr<GLint[]> temp(new GLint[num_values]);
    for (GLsizei ii = 0; ii < num_values; ++ii) {
      temp[ii] = static_cast<GLint>(value[ii] != 0.0f);
    }
    glUniform4iv(real_location, count, temp.get());
  } else {
    glUniform4fv(real_location, count, value);
  }
}

void GLES2DecoderImpl::DoUniform2iv(
    GLint fake_location, GLsizei count, const GLint* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform2iv",
                                   Program::kUniform2i,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  glUniform2iv(real_location, count, value);
}

void GLES2DecoderImpl::DoUniform3iv(
    GLint fake_location, GLsizei count, const GLint* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform3iv",
                                   Program::kUniform3i,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  glUniform3iv(real_location, count, value);
}

void GLES2DecoderImpl::DoUniform4iv(
    GLint fake_location, GLsizei count, const GLint* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniform4iv",
                                   Program::kUniform4i,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  glUniform4iv(real_location, count, value);
}

void GLES2DecoderImpl::DoUniformMatrix2fv(
    GLint fake_location, GLsizei count, GLboolean transpose,
    const GLfloat* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniformMatrix2fv",
                                   Program::kUniformMatrix2f,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  glUniformMatrix2fv(real_location, count, transpose, value);
}

void GLES2DecoderImpl::DoUniformMatrix3fv(
    GLint fake_location, GLsizei count, GLboolean transpose,
    const GLfloat* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniformMatrix3fv",
                                   Program::kUniformMatrix3f,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  glUniformMatrix3fv(real_location, count, transpose, value);
}

void GLES2DecoderImpl::DoUniformMatrix4fv(
    GLint fake_location, GLsizei count, GLboolean transpose,
    const GLfloat* value) {
  GLenum type = 0;
  GLint real_location = -1;
  if (!PrepForSetUniformByLocation(fake_location,
                                   "glUniformMatrix4fv",
                                   Program::kUniformMatrix4f,
                                   &real_location,
                                   &type,
                                   &count)) {
    return;
  }
  glUniformMatrix4fv(real_location, count, transpose, value);
}

void GLES2DecoderImpl::DoUseProgram(GLuint program_id) {
  GLuint service_id = 0;
  Program* program = NULL;
  if (program_id) {
    program = GetProgramInfoNotShader(program_id, "glUseProgram");
    if (!program) {
      return;
    }
    if (!program->IsValid()) {
      // Program was not linked successfully. (ie, glLinkProgram)
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION, "glUseProgram", "program not linked");
      return;
    }
    service_id = program->service_id();
  }
  if (state_.current_program.get()) {
    program_manager()->UnuseProgram(shader_manager(),
                                    state_.current_program.get());
  }
  state_.current_program = program;
  LogClientServiceMapping("glUseProgram", program_id, service_id);
  glUseProgram(service_id);
  if (state_.current_program.get()) {
    program_manager()->UseProgram(state_.current_program.get());
    if (workarounds().clear_uniforms_before_first_program_use)
      program_manager()->ClearUniforms(program);
  }
}

void GLES2DecoderImpl::RenderWarning(
    const char* filename, int line, const std::string& msg) {
  logger_.LogMessage(filename, line, std::string("RENDER WARNING: ") + msg);
}

void GLES2DecoderImpl::PerformanceWarning(
    const char* filename, int line, const std::string& msg) {
  logger_.LogMessage(filename, line,
                     std::string("PERFORMANCE WARNING: ") + msg);
}

void GLES2DecoderImpl::DoWillUseTexImageIfNeeded(
    Texture* texture, GLenum textarget) {
  // Image is already in use if texture is attached to a framebuffer.
  if (texture && !texture->IsAttachedToFramebuffer()) {
    gfx::GLImage* image = texture->GetLevelImage(textarget, 0);
    if (image) {
      ScopedGLErrorSuppressor suppressor(
          "GLES2DecoderImpl::DoWillUseTexImageIfNeeded",
          GetErrorState());
      glBindTexture(textarget, texture->service_id());
      image->WillUseTexImage();
      RestoreCurrentTextureBindings(&state_, textarget);
    }
  }
}

void GLES2DecoderImpl::DoDidUseTexImageIfNeeded(
    Texture* texture, GLenum textarget) {
  // Image is still in use if texture is attached to a framebuffer.
  if (texture && !texture->IsAttachedToFramebuffer()) {
    gfx::GLImage* image = texture->GetLevelImage(textarget, 0);
    if (image) {
      ScopedGLErrorSuppressor suppressor(
          "GLES2DecoderImpl::DoDidUseTexImageIfNeeded",
          GetErrorState());
      glBindTexture(textarget, texture->service_id());
      image->DidUseTexImage();
      RestoreCurrentTextureBindings(&state_, textarget);
    }
  }
}

bool GLES2DecoderImpl::PrepareTexturesForRender() {
  DCHECK(state_.current_program.get());
  if (!texture_manager()->HaveUnrenderableTextures() &&
      !texture_manager()->HaveImages()) {
    return true;
  }

  bool textures_set = false;
  const Program::SamplerIndices& sampler_indices =
     state_.current_program->sampler_indices();
  for (size_t ii = 0; ii < sampler_indices.size(); ++ii) {
    const Program::UniformInfo* uniform_info =
        state_.current_program->GetUniformInfo(sampler_indices[ii]);
    DCHECK(uniform_info);
    for (size_t jj = 0; jj < uniform_info->texture_units.size(); ++jj) {
      GLuint texture_unit_index = uniform_info->texture_units[jj];
      if (texture_unit_index < state_.texture_units.size()) {
        TextureUnit& texture_unit = state_.texture_units[texture_unit_index];
        TextureRef* texture_ref =
            texture_unit.GetInfoForSamplerType(uniform_info->type).get();
        GLenum textarget = GetBindTargetForSamplerType(uniform_info->type);
        if (!texture_ref || !texture_manager()->CanRender(texture_ref)) {
          textures_set = true;
          glActiveTexture(GL_TEXTURE0 + texture_unit_index);
          glBindTexture(
              textarget,
              texture_manager()->black_texture_id(uniform_info->type));
          if (!texture_ref) {
            LOCAL_RENDER_WARNING(
                std::string("there is no texture bound to the unit ") +
                base::IntToString(texture_unit_index));
          } else {
            LOCAL_RENDER_WARNING(
                std::string("texture bound to texture unit ") +
                base::IntToString(texture_unit_index) +
                " is not renderable. It maybe non-power-of-2 and have"
                " incompatible texture filtering.");
          }
          continue;
        }

        if (textarget != GL_TEXTURE_CUBE_MAP) {
          Texture* texture = texture_ref->texture();
          gfx::GLImage* image = texture->GetLevelImage(textarget, 0);
          if (image && !texture->IsAttachedToFramebuffer()) {
            ScopedGLErrorSuppressor suppressor(
                "GLES2DecoderImpl::PrepareTexturesForRender", GetErrorState());
            textures_set = true;
            glActiveTexture(GL_TEXTURE0 + texture_unit_index);
            image->WillUseTexImage();
            continue;
          }
        }
      }
      // else: should this be an error?
    }
  }
  return !textures_set;
}

void GLES2DecoderImpl::RestoreStateForTextures() {
  DCHECK(state_.current_program.get());
  const Program::SamplerIndices& sampler_indices =
      state_.current_program->sampler_indices();
  for (size_t ii = 0; ii < sampler_indices.size(); ++ii) {
    const Program::UniformInfo* uniform_info =
        state_.current_program->GetUniformInfo(sampler_indices[ii]);
    DCHECK(uniform_info);
    for (size_t jj = 0; jj < uniform_info->texture_units.size(); ++jj) {
      GLuint texture_unit_index = uniform_info->texture_units[jj];
      if (texture_unit_index < state_.texture_units.size()) {
        TextureUnit& texture_unit = state_.texture_units[texture_unit_index];
        TextureRef* texture_ref =
            texture_unit.GetInfoForSamplerType(uniform_info->type).get();
        if (!texture_ref || !texture_manager()->CanRender(texture_ref)) {
          glActiveTexture(GL_TEXTURE0 + texture_unit_index);
          // Get the texture_ref info that was previously bound here.
          texture_ref = texture_unit.bind_target == GL_TEXTURE_2D
                            ? texture_unit.bound_texture_2d.get()
                            : texture_unit.bound_texture_cube_map.get();
          glBindTexture(texture_unit.bind_target,
                        texture_ref ? texture_ref->service_id() : 0);
          continue;
        }

        if (texture_unit.bind_target != GL_TEXTURE_CUBE_MAP) {
          Texture* texture = texture_ref->texture();
          gfx::GLImage* image =
              texture->GetLevelImage(texture_unit.bind_target, 0);
          if (image && !texture->IsAttachedToFramebuffer()) {
            ScopedGLErrorSuppressor suppressor(
                "GLES2DecoderImpl::RestoreStateForTextures", GetErrorState());
            glActiveTexture(GL_TEXTURE0 + texture_unit_index);
            image->DidUseTexImage();
            continue;
          }
        }
      }
    }
  }
  // Set the active texture back to whatever the user had it as.
  glActiveTexture(GL_TEXTURE0 + state_.active_texture_unit);
}

bool GLES2DecoderImpl::ClearUnclearedTextures() {
  // Only check if there are some uncleared textures.
  if (!texture_manager()->HaveUnsafeTextures()) {
    return true;
  }

  // 1: Check all textures we are about to render with.
  if (state_.current_program.get()) {
    const Program::SamplerIndices& sampler_indices =
        state_.current_program->sampler_indices();
    for (size_t ii = 0; ii < sampler_indices.size(); ++ii) {
      const Program::UniformInfo* uniform_info =
          state_.current_program->GetUniformInfo(sampler_indices[ii]);
      DCHECK(uniform_info);
      for (size_t jj = 0; jj < uniform_info->texture_units.size(); ++jj) {
        GLuint texture_unit_index = uniform_info->texture_units[jj];
        if (texture_unit_index < state_.texture_units.size()) {
          TextureUnit& texture_unit = state_.texture_units[texture_unit_index];
          TextureRef* texture_ref =
              texture_unit.GetInfoForSamplerType(uniform_info->type).get();
          if (texture_ref && !texture_ref->texture()->SafeToRenderFrom()) {
            if (!texture_manager()->ClearRenderableLevels(this, texture_ref)) {
              return false;
            }
          }
        }
      }
    }
  }
  return true;
}

bool GLES2DecoderImpl::IsDrawValid(
    const char* function_name, GLuint max_vertex_accessed, bool instanced,
    GLsizei primcount) {
  DCHECK(instanced || primcount == 1);

  // NOTE: We specifically do not check current_program->IsValid() because
  // it could never be invalid since glUseProgram would have failed. While
  // glLinkProgram could later mark the program as invalid the previous
  // valid program will still function if it is still the current program.
  if (!state_.current_program.get()) {
    // The program does not exist.
    // But GL says no ERROR.
    LOCAL_RENDER_WARNING("Drawing with no current shader program.");
    return false;
  }

  if (CheckDrawingFeedbackLoops()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name,
        "Source and destination textures of the draw are the same.");
    return false;
  }

  return state_.vertex_attrib_manager
      ->ValidateBindings(function_name,
                         this,
                         feature_info_.get(),
                         state_.current_program.get(),
                         max_vertex_accessed,
                         instanced,
                         primcount);
}

bool GLES2DecoderImpl::SimulateAttrib0(
    const char* function_name, GLuint max_vertex_accessed, bool* simulated) {
  DCHECK(simulated);
  *simulated = false;

  if (gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2)
    return true;

  const VertexAttrib* attrib =
      state_.vertex_attrib_manager->GetVertexAttrib(0);
  // If it's enabled or it's not used then we don't need to do anything.
  bool attrib_0_used =
      state_.current_program->GetAttribInfoByLocation(0) != NULL;
  if (attrib->enabled() && attrib_0_used) {
    return true;
  }

  // Make a buffer with a single repeated vec4 value enough to
  // simulate the constant value that is supposed to be here.
  // This is required to emulate GLES2 on GL.
  GLuint num_vertices = max_vertex_accessed + 1;
  uint32 size_needed = 0;

  if (num_vertices == 0 ||
      !SafeMultiplyUint32(num_vertices, sizeof(Vec4), &size_needed) ||
      size_needed > 0x7FFFFFFFU) {
    LOCAL_SET_GL_ERROR(GL_OUT_OF_MEMORY, function_name, "Simulating attrib 0");
    return false;
  }

  LOCAL_PERFORMANCE_WARNING(
      "Attribute 0 is disabled. This has signficant performance penalty");

  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER(function_name);
  glBindBuffer(GL_ARRAY_BUFFER, attrib_0_buffer_id_);

  bool new_buffer = static_cast<GLsizei>(size_needed) > attrib_0_size_;
  if (new_buffer) {
    glBufferData(GL_ARRAY_BUFFER, size_needed, NULL, GL_DYNAMIC_DRAW);
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, function_name, "Simulating attrib 0");
      return false;
    }
  }

  const Vec4& value = state_.attrib_values[0];
  if (new_buffer ||
      (attrib_0_used &&
       (!attrib_0_buffer_matches_value_ ||
        (value.v[0] != attrib_0_value_.v[0] ||
         value.v[1] != attrib_0_value_.v[1] ||
         value.v[2] != attrib_0_value_.v[2] ||
         value.v[3] != attrib_0_value_.v[3])))) {
    std::vector<Vec4> temp(num_vertices, value);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_needed, &temp[0].v[0]);
    attrib_0_buffer_matches_value_ = true;
    attrib_0_value_ = value;
    attrib_0_size_ = size_needed;
  }

  glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, NULL);

  if (attrib->divisor())
    glVertexAttribDivisorANGLE(0, 0);

  *simulated = true;
  return true;
}

void GLES2DecoderImpl::RestoreStateForAttrib(
    GLuint attrib_index, bool restore_array_binding) {
  const VertexAttrib* attrib =
      state_.vertex_attrib_manager->GetVertexAttrib(attrib_index);
  if (restore_array_binding) {
    const void* ptr = reinterpret_cast<const void*>(attrib->offset());
    Buffer* buffer = attrib->buffer();
    glBindBuffer(GL_ARRAY_BUFFER, buffer ? buffer->service_id() : 0);
    glVertexAttribPointer(
        attrib_index, attrib->size(), attrib->type(), attrib->normalized(),
        attrib->gl_stride(), ptr);
  }
  if (attrib->divisor())
    glVertexAttribDivisorANGLE(attrib_index, attrib->divisor());
  glBindBuffer(
      GL_ARRAY_BUFFER, state_.bound_array_buffer.get() ?
          state_.bound_array_buffer->service_id() : 0);

  // Never touch vertex attribute 0's state (in particular, never
  // disable it) when running on desktop GL because it will never be
  // re-enabled.
  if (attrib_index != 0 ||
      gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2) {
    if (attrib->enabled()) {
      glEnableVertexAttribArray(attrib_index);
    } else {
      glDisableVertexAttribArray(attrib_index);
    }
  }
}

bool GLES2DecoderImpl::SimulateFixedAttribs(
    const char* function_name,
    GLuint max_vertex_accessed, bool* simulated, GLsizei primcount) {
  DCHECK(simulated);
  *simulated = false;
  if (gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2)
    return true;

  if (!state_.vertex_attrib_manager->HaveFixedAttribs()) {
    return true;
  }

  LOCAL_PERFORMANCE_WARNING(
      "GL_FIXED attributes have a signficant performance penalty");

  // NOTE: we could be smart and try to check if a buffer is used
  // twice in 2 different attribs, find the overlapping parts and therefore
  // duplicate the minimum amount of data but this whole code path is not meant
  // to be used normally. It's just here to pass that OpenGL ES 2.0 conformance
  // tests so we just add to the buffer attrib used.

  GLuint elements_needed = 0;
  const VertexAttribManager::VertexAttribList& enabled_attribs =
      state_.vertex_attrib_manager->GetEnabledVertexAttribs();
  for (VertexAttribManager::VertexAttribList::const_iterator it =
       enabled_attribs.begin(); it != enabled_attribs.end(); ++it) {
    const VertexAttrib* attrib = *it;
    const Program::VertexAttrib* attrib_info =
        state_.current_program->GetAttribInfoByLocation(attrib->index());
    GLuint max_accessed = attrib->MaxVertexAccessed(primcount,
                                                    max_vertex_accessed);
    GLuint num_vertices = max_accessed + 1;
    if (num_vertices == 0) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, function_name, "Simulating attrib 0");
      return false;
    }
    if (attrib_info &&
        attrib->CanAccess(max_accessed) &&
        attrib->type() == GL_FIXED) {
      uint32 elements_used = 0;
      if (!SafeMultiplyUint32(num_vertices, attrib->size(), &elements_used) ||
          !SafeAddUint32(elements_needed, elements_used, &elements_needed)) {
        LOCAL_SET_GL_ERROR(
            GL_OUT_OF_MEMORY, function_name, "simulating GL_FIXED attribs");
        return false;
      }
    }
  }

  const uint32 kSizeOfFloat = sizeof(float);  // NOLINT
  uint32 size_needed = 0;
  if (!SafeMultiplyUint32(elements_needed, kSizeOfFloat, &size_needed) ||
      size_needed > 0x7FFFFFFFU) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY, function_name, "simulating GL_FIXED attribs");
    return false;
  }

  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER(function_name);

  glBindBuffer(GL_ARRAY_BUFFER, fixed_attrib_buffer_id_);
  if (static_cast<GLsizei>(size_needed) > fixed_attrib_buffer_size_) {
    glBufferData(GL_ARRAY_BUFFER, size_needed, NULL, GL_DYNAMIC_DRAW);
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, function_name, "simulating GL_FIXED attribs");
      return false;
    }
  }

  // Copy the elements and convert to float
  GLintptr offset = 0;
  for (VertexAttribManager::VertexAttribList::const_iterator it =
       enabled_attribs.begin(); it != enabled_attribs.end(); ++it) {
    const VertexAttrib* attrib = *it;
    const Program::VertexAttrib* attrib_info =
        state_.current_program->GetAttribInfoByLocation(attrib->index());
    GLuint max_accessed = attrib->MaxVertexAccessed(primcount,
                                                  max_vertex_accessed);
    GLuint num_vertices = max_accessed + 1;
    if (num_vertices == 0) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, function_name, "Simulating attrib 0");
      return false;
    }
    if (attrib_info &&
        attrib->CanAccess(max_accessed) &&
        attrib->type() == GL_FIXED) {
      int num_elements = attrib->size() * num_vertices;
      const int src_size = num_elements * sizeof(int32);
      const int dst_size = num_elements * sizeof(float);
      scoped_ptr<float[]> data(new float[num_elements]);
      const int32* src = reinterpret_cast<const int32 *>(
          attrib->buffer()->GetRange(attrib->offset(), src_size));
      const int32* end = src + num_elements;
      float* dst = data.get();
      while (src != end) {
        *dst++ = static_cast<float>(*src++) / 65536.0f;
      }
      glBufferSubData(GL_ARRAY_BUFFER, offset, dst_size, data.get());
      glVertexAttribPointer(
          attrib->index(), attrib->size(), GL_FLOAT, false, 0,
          reinterpret_cast<GLvoid*>(offset));
      offset += dst_size;
    }
  }
  *simulated = true;
  return true;
}

void GLES2DecoderImpl::RestoreStateForSimulatedFixedAttribs() {
  // There's no need to call glVertexAttribPointer because we shadow all the
  // settings and passing GL_FIXED to it will not work.
  glBindBuffer(
      GL_ARRAY_BUFFER,
      state_.bound_array_buffer.get() ? state_.bound_array_buffer->service_id()
                                      : 0);
}

error::Error GLES2DecoderImpl::DoDrawArrays(
    const char* function_name,
    bool instanced,
    GLenum mode,
    GLint first,
    GLsizei count,
    GLsizei primcount) {
  error::Error error = WillAccessBoundFramebufferForDraw();
  if (error != error::kNoError)
    return error;
  if (!validators_->draw_mode.IsValid(mode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(function_name, mode, "mode");
    return error::kNoError;
  }
  if (count < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "count < 0");
    return error::kNoError;
  }
  if (primcount < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "primcount < 0");
    return error::kNoError;
  }
  if (!CheckBoundFramebuffersValid(function_name)) {
    return error::kNoError;
  }
  // We have to check this here because the prototype for glDrawArrays
  // is GLint not GLsizei.
  if (first < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "first < 0");
    return error::kNoError;
  }

  if (count == 0 || primcount == 0) {
    LOCAL_RENDER_WARNING("Render count or primcount is 0.");
    return error::kNoError;
  }

  GLuint max_vertex_accessed = first + count - 1;
  if (IsDrawValid(function_name, max_vertex_accessed, instanced, primcount)) {
    if (!ClearUnclearedTextures()) {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "out of memory");
      return error::kNoError;
    }
    bool simulated_attrib_0 = false;
    if (!SimulateAttrib0(
        function_name, max_vertex_accessed, &simulated_attrib_0)) {
      return error::kNoError;
    }
    bool simulated_fixed_attribs = false;
    if (SimulateFixedAttribs(
        function_name, max_vertex_accessed, &simulated_fixed_attribs,
        primcount)) {
      bool textures_set = !PrepareTexturesForRender();
      ApplyDirtyState();
      ScopedRenderTo do_render(framebuffer_state_.bound_draw_framebuffer.get());
      if (!instanced) {
        glDrawArrays(mode, first, count);
      } else {
        glDrawArraysInstancedANGLE(mode, first, count, primcount);
      }
      if (textures_set) {
        RestoreStateForTextures();
      }
      if (simulated_fixed_attribs) {
        RestoreStateForSimulatedFixedAttribs();
      }
    }
    if (simulated_attrib_0) {
      // We don't have to restore attrib 0 generic data at the end of this
      // function even if it is simulated. This is because we will simulate
      // it in each draw call, and attrib 0 generic data queries use cached
      // values instead of passing down to the underlying driver.
      RestoreStateForAttrib(0, false);
    }
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDrawArrays(uint32 immediate_data_size,
                                                const void* cmd_data) {
  // TODO(zmo): crbug.com/481184
  // On Desktop GL with versions lower than 4.3, we need to emulate
  // GL_PRIMITIVE_RESTART_FIXED_INDEX using glPrimitiveRestartIndex().
  const cmds::DrawArrays& c = *static_cast<const cmds::DrawArrays*>(cmd_data);
  return DoDrawArrays("glDrawArrays",
                      false,
                      static_cast<GLenum>(c.mode),
                      static_cast<GLint>(c.first),
                      static_cast<GLsizei>(c.count),
                      1);
}

error::Error GLES2DecoderImpl::HandleDrawArraysInstancedANGLE(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DrawArraysInstancedANGLE& c =
      *static_cast<const gles2::cmds::DrawArraysInstancedANGLE*>(cmd_data);
  if (!features().angle_instanced_arrays) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glDrawArraysInstancedANGLE", "function not available");
    return error::kNoError;
  }
  return DoDrawArrays("glDrawArraysIntancedANGLE",
                      true,
                      static_cast<GLenum>(c.mode),
                      static_cast<GLint>(c.first),
                      static_cast<GLsizei>(c.count),
                      static_cast<GLsizei>(c.primcount));
}

error::Error GLES2DecoderImpl::DoDrawElements(
    const char* function_name,
    bool instanced,
    GLenum mode,
    GLsizei count,
    GLenum type,
    int32 offset,
    GLsizei primcount) {
  error::Error error = WillAccessBoundFramebufferForDraw();
  if (error != error::kNoError)
    return error;
  if (!state_.vertex_attrib_manager->element_array_buffer()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name, "No element array buffer bound");
    return error::kNoError;
  }

  if (count < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "count < 0");
    return error::kNoError;
  }
  if (offset < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "offset < 0");
    return error::kNoError;
  }
  if (!validators_->draw_mode.IsValid(mode)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(function_name, mode, "mode");
    return error::kNoError;
  }
  if (!validators_->index_type.IsValid(type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(function_name, type, "type");
    return error::kNoError;
  }
  if (primcount < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "primcount < 0");
    return error::kNoError;
  }

  if (!CheckBoundFramebuffersValid(function_name)) {
    return error::kNoError;
  }

  if (count == 0 || primcount == 0) {
    return error::kNoError;
  }

  GLuint max_vertex_accessed;
  Buffer* element_array_buffer =
      state_.vertex_attrib_manager->element_array_buffer();

  if (!element_array_buffer->GetMaxValueForRange(
      offset, count, type, &max_vertex_accessed)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name, "range out of bounds for buffer");
    return error::kNoError;
  }

  if (IsDrawValid(function_name, max_vertex_accessed, instanced, primcount)) {
    if (!ClearUnclearedTextures()) {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "out of memory");
      return error::kNoError;
    }
    bool simulated_attrib_0 = false;
    if (!SimulateAttrib0(
        function_name, max_vertex_accessed, &simulated_attrib_0)) {
      return error::kNoError;
    }
    bool simulated_fixed_attribs = false;
    if (SimulateFixedAttribs(
        function_name, max_vertex_accessed, &simulated_fixed_attribs,
        primcount)) {
      bool textures_set = !PrepareTexturesForRender();
      ApplyDirtyState();
      // TODO(gman): Refactor to hide these details in BufferManager or
      // VertexAttribManager.
      const GLvoid* indices = reinterpret_cast<const GLvoid*>(offset);
      bool used_client_side_array = false;
      if (element_array_buffer->IsClientSideArray()) {
        used_client_side_array = true;
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        indices = element_array_buffer->GetRange(offset, 0);
      }

      ScopedRenderTo do_render(framebuffer_state_.bound_draw_framebuffer.get());
      if (!instanced) {
        glDrawElements(mode, count, type, indices);
      } else {
        glDrawElementsInstancedANGLE(mode, count, type, indices, primcount);
      }

      if (used_client_side_array) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,
                     element_array_buffer->service_id());
      }

      if (textures_set) {
        RestoreStateForTextures();
      }
      if (simulated_fixed_attribs) {
        RestoreStateForSimulatedFixedAttribs();
      }
    }
    if (simulated_attrib_0) {
      // We don't have to restore attrib 0 generic data at the end of this
      // function even if it is simulated. This is because we will simulate
      // it in each draw call, and attrib 0 generic data queries use cached
      // values instead of passing down to the underlying driver.
      RestoreStateForAttrib(0, false);
    }
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleDrawElements(uint32 immediate_data_size,
                                                  const void* cmd_data) {
  // TODO(zmo): crbug.com/481184
  // On Desktop GL with versions lower than 4.3, we need to emulate
  // GL_PRIMITIVE_RESTART_FIXED_INDEX using glPrimitiveRestartIndex().
  const gles2::cmds::DrawElements& c =
      *static_cast<const gles2::cmds::DrawElements*>(cmd_data);
  return DoDrawElements("glDrawElements",
                        false,
                        static_cast<GLenum>(c.mode),
                        static_cast<GLsizei>(c.count),
                        static_cast<GLenum>(c.type),
                        static_cast<int32>(c.index_offset),
                        1);
}

error::Error GLES2DecoderImpl::HandleDrawElementsInstancedANGLE(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::DrawElementsInstancedANGLE& c =
      *static_cast<const gles2::cmds::DrawElementsInstancedANGLE*>(cmd_data);
  if (!features().angle_instanced_arrays) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glDrawElementsInstancedANGLE", "function not available");
    return error::kNoError;
  }
  return DoDrawElements("glDrawElementsInstancedANGLE",
                        true,
                        static_cast<GLenum>(c.mode),
                        static_cast<GLsizei>(c.count),
                        static_cast<GLenum>(c.type),
                        static_cast<int32>(c.index_offset),
                        static_cast<GLsizei>(c.primcount));
}

GLuint GLES2DecoderImpl::DoGetMaxValueInBufferCHROMIUM(
    GLuint buffer_id, GLsizei count, GLenum type, GLuint offset) {
  GLuint max_vertex_accessed = 0;
  Buffer* buffer = GetBuffer(buffer_id);
  if (!buffer) {
    // TODO(gman): Should this be a GL error or a command buffer error?
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "GetMaxValueInBufferCHROMIUM", "unknown buffer");
  } else {
    if (!buffer->GetMaxValueForRange(
        offset, count, type, &max_vertex_accessed)) {
      // TODO(gman): Should this be a GL error or a command buffer error?
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "GetMaxValueInBufferCHROMIUM", "range out of bounds for buffer");
    }
  }
  return max_vertex_accessed;
}

void GLES2DecoderImpl::DoShaderSource(
    GLuint client_id, GLsizei count, const char** data, const GLint* length) {
  std::string str;
  for (GLsizei ii = 0; ii < count; ++ii) {
    if (length && length[ii] > 0)
      str.append(data[ii], length[ii]);
    else
      str.append(data[ii]);
  }
  Shader* shader = GetShaderInfoNotProgram(client_id, "glShaderSource");
  if (!shader) {
    return;
  }
  // Note: We don't actually call glShaderSource here. We wait until
  // we actually compile the shader.
  shader->set_source(str);
}

void GLES2DecoderImpl::DoTransformFeedbackVaryings(
    GLuint client_program_id, GLsizei count, const char* const* varyings,
    GLenum buffer_mode) {
  Program* program = GetProgramInfoNotShader(
      client_program_id, "glTransformFeedbackVaryings");
  if (!program) {
    return;
  }
  program->TransformFeedbackVaryings(count, varyings, buffer_mode);
  glTransformFeedbackVaryings(
      program->service_id(), count, varyings, buffer_mode);
}

void GLES2DecoderImpl::DoCompileShader(GLuint client_id) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::DoCompileShader");
  Shader* shader = GetShaderInfoNotProgram(client_id, "glCompileShader");
  if (!shader) {
    return;
  }

  scoped_refptr<ShaderTranslatorInterface> translator;
  if (use_shader_translator_) {
      translator = shader->shader_type() == GL_VERTEX_SHADER ?
                   vertex_translator_ : fragment_translator_;
  }

  const Shader::TranslatedShaderSourceType source_type =
      feature_info_->feature_flags().angle_translated_shader_source ?
      Shader::kANGLE : Shader::kGL;
  shader->RequestCompile(translator, source_type);
}

void GLES2DecoderImpl::DoGetShaderiv(
    GLuint shader_id, GLenum pname, GLint* params) {
  Shader* shader = GetShaderInfoNotProgram(shader_id, "glGetShaderiv");
  if (!shader) {
    return;
  }

  // Compile now for statuses that require it.
  switch (pname) {
    case GL_COMPILE_STATUS:
    case GL_INFO_LOG_LENGTH:
    case GL_TRANSLATED_SHADER_SOURCE_LENGTH_ANGLE:
      shader->DoCompile();
      break;

    default:
    break;
  }

  switch (pname) {
    case GL_SHADER_SOURCE_LENGTH:
      *params = shader->source().size();
      if (*params)
        ++(*params);
      return;
    case GL_COMPILE_STATUS:
      *params = compile_shader_always_succeeds_ ? true : shader->valid();
      return;
    case GL_INFO_LOG_LENGTH:
      *params = shader->log_info().size();
      if (*params)
        ++(*params);
      return;
    case GL_TRANSLATED_SHADER_SOURCE_LENGTH_ANGLE:
      *params = shader->translated_source().size();
      if (*params)
        ++(*params);
      return;
    default:
      break;
  }
  glGetShaderiv(shader->service_id(), pname, params);
}

error::Error GLES2DecoderImpl::HandleGetShaderSource(uint32 immediate_data_size,
                                                     const void* cmd_data) {
  const gles2::cmds::GetShaderSource& c =
      *static_cast<const gles2::cmds::GetShaderSource*>(cmd_data);
  GLuint shader_id = c.shader;
  uint32 bucket_id = static_cast<uint32>(c.bucket_id);
  Bucket* bucket = CreateBucket(bucket_id);
  Shader* shader = GetShaderInfoNotProgram(shader_id, "glGetShaderSource");
  if (!shader || shader->source().empty()) {
    bucket->SetSize(0);
    return error::kNoError;
  }
  bucket->SetFromString(shader->source().c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetTranslatedShaderSourceANGLE(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetTranslatedShaderSourceANGLE& c =
      *static_cast<const gles2::cmds::GetTranslatedShaderSourceANGLE*>(
          cmd_data);
  GLuint shader_id = c.shader;
  uint32 bucket_id = static_cast<uint32>(c.bucket_id);
  Bucket* bucket = CreateBucket(bucket_id);
  Shader* shader = GetShaderInfoNotProgram(
      shader_id, "glGetTranslatedShaderSourceANGLE");
  if (!shader) {
    bucket->SetSize(0);
    return error::kNoError;
  }

  // Make sure translator has been utilized in compile.
  shader->DoCompile();

  bucket->SetFromString(shader->translated_source().c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetProgramInfoLog(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetProgramInfoLog& c =
      *static_cast<const gles2::cmds::GetProgramInfoLog*>(cmd_data);
  GLuint program_id = c.program;
  uint32 bucket_id = static_cast<uint32>(c.bucket_id);
  Bucket* bucket = CreateBucket(bucket_id);
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetProgramInfoLog");
  if (!program || !program->log_info()) {
    bucket->SetFromString("");
    return error::kNoError;
  }
  bucket->SetFromString(program->log_info()->c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetShaderInfoLog(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetShaderInfoLog& c =
      *static_cast<const gles2::cmds::GetShaderInfoLog*>(cmd_data);
  GLuint shader_id = c.shader;
  uint32 bucket_id = static_cast<uint32>(c.bucket_id);
  Bucket* bucket = CreateBucket(bucket_id);
  Shader* shader = GetShaderInfoNotProgram(shader_id, "glGetShaderInfoLog");
  if (!shader) {
    bucket->SetFromString("");
    return error::kNoError;
  }

  // Shader must be compiled in order to get the info log.
  shader->DoCompile();

  bucket->SetFromString(shader->log_info().c_str());
  return error::kNoError;
}

bool GLES2DecoderImpl::DoIsEnabled(GLenum cap) {
  return state_.GetEnabled(cap);
}

bool GLES2DecoderImpl::DoIsBuffer(GLuint client_id) {
  const Buffer* buffer = GetBuffer(client_id);
  return buffer && buffer->IsValid() && !buffer->IsDeleted();
}

bool GLES2DecoderImpl::DoIsFramebuffer(GLuint client_id) {
  const Framebuffer* framebuffer =
      GetFramebuffer(client_id);
  return framebuffer && framebuffer->IsValid() && !framebuffer->IsDeleted();
}

bool GLES2DecoderImpl::DoIsProgram(GLuint client_id) {
  // IsProgram is true for programs as soon as they are created, until they are
  // deleted and no longer in use.
  const Program* program = GetProgram(client_id);
  return program != NULL && !program->IsDeleted();
}

bool GLES2DecoderImpl::DoIsRenderbuffer(GLuint client_id) {
  const Renderbuffer* renderbuffer =
      GetRenderbuffer(client_id);
  return renderbuffer && renderbuffer->IsValid() && !renderbuffer->IsDeleted();
}

bool GLES2DecoderImpl::DoIsShader(GLuint client_id) {
  // IsShader is true for shaders as soon as they are created, until they
  // are deleted and not attached to any programs.
  const Shader* shader = GetShader(client_id);
  return shader != NULL && !shader->IsDeleted();
}

bool GLES2DecoderImpl::DoIsTexture(GLuint client_id) {
  const TextureRef* texture_ref = GetTexture(client_id);
  return texture_ref && texture_ref->texture()->IsValid();
}

void GLES2DecoderImpl::DoAttachShader(
    GLuint program_client_id, GLint shader_client_id) {
  Program* program = GetProgramInfoNotShader(
      program_client_id, "glAttachShader");
  if (!program) {
    return;
  }
  Shader* shader = GetShaderInfoNotProgram(shader_client_id, "glAttachShader");
  if (!shader) {
    return;
  }
  if (!program->AttachShader(shader_manager(), shader)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glAttachShader",
        "can not attach more than one shader of the same type.");
    return;
  }
  glAttachShader(program->service_id(), shader->service_id());
}

void GLES2DecoderImpl::DoDetachShader(
    GLuint program_client_id, GLint shader_client_id) {
  Program* program = GetProgramInfoNotShader(
      program_client_id, "glDetachShader");
  if (!program) {
    return;
  }
  Shader* shader = GetShaderInfoNotProgram(shader_client_id, "glDetachShader");
  if (!shader) {
    return;
  }
  if (!program->DetachShader(shader_manager(), shader)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glDetachShader", "shader not attached to program");
    return;
  }
  glDetachShader(program->service_id(), shader->service_id());
}

void GLES2DecoderImpl::DoValidateProgram(GLuint program_client_id) {
  Program* program = GetProgramInfoNotShader(
      program_client_id, "glValidateProgram");
  if (!program) {
    return;
  }
  program->Validate();
}

void GLES2DecoderImpl::GetVertexAttribHelper(
    const VertexAttrib* attrib, GLenum pname, GLint* params) {
  switch (pname) {
    case GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING: {
        Buffer* buffer = attrib->buffer();
        if (buffer && !buffer->IsDeleted()) {
          GLuint client_id;
          buffer_manager()->GetClientId(buffer->service_id(), &client_id);
          *params = client_id;
        }
        break;
      }
    case GL_VERTEX_ATTRIB_ARRAY_ENABLED:
      *params = attrib->enabled();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_SIZE:
      *params = attrib->size();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_STRIDE:
      *params = attrib->gl_stride();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_TYPE:
      *params = attrib->type();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_NORMALIZED:
      *params = attrib->normalized();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE:
      *params = attrib->divisor();
      break;
    default:
      NOTREACHED();
      break;
  }
}

void GLES2DecoderImpl::DoGetTexParameterfv(
    GLenum target, GLenum pname, GLfloat* params) {
  InitTextureMaxAnisotropyIfNeeded(target, pname);
  glGetTexParameterfv(target, pname, params);
}

void GLES2DecoderImpl::DoGetTexParameteriv(
    GLenum target, GLenum pname, GLint* params) {
  InitTextureMaxAnisotropyIfNeeded(target, pname);
  glGetTexParameteriv(target, pname, params);
}

void GLES2DecoderImpl::InitTextureMaxAnisotropyIfNeeded(
    GLenum target, GLenum pname) {
  if (!workarounds().init_texture_max_anisotropy)
    return;
  if (pname != GL_TEXTURE_MAX_ANISOTROPY_EXT ||
      !validators_->texture_parameter.IsValid(pname)) {
    return;
  }

  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glGetTexParamter{fi}v", "unknown texture for target");
    return;
  }
  Texture* texture = texture_ref->texture();
  texture->InitTextureMaxAnisotropyIfNeeded(target);
}

void GLES2DecoderImpl::DoGetVertexAttribfv(
    GLuint index, GLenum pname, GLfloat* params) {
  VertexAttrib* attrib = state_.vertex_attrib_manager->GetVertexAttrib(index);
  if (!attrib) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glGetVertexAttribfv", "index out of range");
    return;
  }
  switch (pname) {
    case GL_CURRENT_VERTEX_ATTRIB: {
      const Vec4& value = state_.attrib_values[index];
      params[0] = value.v[0];
      params[1] = value.v[1];
      params[2] = value.v[2];
      params[3] = value.v[3];
      break;
    }
    default: {
      GLint value = 0;
      GetVertexAttribHelper(attrib, pname, &value);
      *params = static_cast<GLfloat>(value);
      break;
    }
  }
}

void GLES2DecoderImpl::DoGetVertexAttribiv(
    GLuint index, GLenum pname, GLint* params) {
  VertexAttrib* attrib = state_.vertex_attrib_manager->GetVertexAttrib(index);
  if (!attrib) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glGetVertexAttribiv", "index out of range");
    return;
  }
  switch (pname) {
    case GL_CURRENT_VERTEX_ATTRIB: {
      const Vec4& value = state_.attrib_values[index];
      params[0] = static_cast<GLint>(value.v[0]);
      params[1] = static_cast<GLint>(value.v[1]);
      params[2] = static_cast<GLint>(value.v[2]);
      params[3] = static_cast<GLint>(value.v[3]);
      break;
    }
    default:
      GetVertexAttribHelper(attrib, pname, params);
      break;
  }
}

bool GLES2DecoderImpl::SetVertexAttribValue(
    const char* function_name, GLuint index, const GLfloat* value) {
  if (index >= state_.attrib_values.size()) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "index out of range");
    return false;
  }
  Vec4& v = state_.attrib_values[index];
  v.v[0] = value[0];
  v.v[1] = value[1];
  v.v[2] = value[2];
  v.v[3] = value[3];
  return true;
}

void GLES2DecoderImpl::DoVertexAttrib1f(GLuint index, GLfloat v0) {
  GLfloat v[4] = { v0, 0.0f, 0.0f, 1.0f, };
  if (SetVertexAttribValue("glVertexAttrib1f", index, v)) {
    glVertexAttrib1f(index, v0);
  }
}

void GLES2DecoderImpl::DoVertexAttrib2f(GLuint index, GLfloat v0, GLfloat v1) {
  GLfloat v[4] = { v0, v1, 0.0f, 1.0f, };
  if (SetVertexAttribValue("glVertexAttrib2f", index, v)) {
    glVertexAttrib2f(index, v0, v1);
  }
}

void GLES2DecoderImpl::DoVertexAttrib3f(
    GLuint index, GLfloat v0, GLfloat v1, GLfloat v2) {
  GLfloat v[4] = { v0, v1, v2, 1.0f, };
  if (SetVertexAttribValue("glVertexAttrib3f", index, v)) {
    glVertexAttrib3f(index, v0, v1, v2);
  }
}

void GLES2DecoderImpl::DoVertexAttrib4f(
    GLuint index, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3) {
  GLfloat v[4] = { v0, v1, v2, v3, };
  if (SetVertexAttribValue("glVertexAttrib4f", index, v)) {
    glVertexAttrib4f(index, v0, v1, v2, v3);
  }
}

void GLES2DecoderImpl::DoVertexAttrib1fv(GLuint index, const GLfloat* v) {
  GLfloat t[4] = { v[0], 0.0f, 0.0f, 1.0f, };
  if (SetVertexAttribValue("glVertexAttrib1fv", index, t)) {
    glVertexAttrib1fv(index, v);
  }
}

void GLES2DecoderImpl::DoVertexAttrib2fv(GLuint index, const GLfloat* v) {
  GLfloat t[4] = { v[0], v[1], 0.0f, 1.0f, };
  if (SetVertexAttribValue("glVertexAttrib2fv", index, t)) {
    glVertexAttrib2fv(index, v);
  }
}

void GLES2DecoderImpl::DoVertexAttrib3fv(GLuint index, const GLfloat* v) {
  GLfloat t[4] = { v[0], v[1], v[2], 1.0f, };
  if (SetVertexAttribValue("glVertexAttrib3fv", index, t)) {
    glVertexAttrib3fv(index, v);
  }
}

void GLES2DecoderImpl::DoVertexAttrib4fv(GLuint index, const GLfloat* v) {
  if (SetVertexAttribValue("glVertexAttrib4fv", index, v)) {
    glVertexAttrib4fv(index, v);
  }
}

error::Error GLES2DecoderImpl::HandleVertexAttribIPointer(
    uint32 immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::VertexAttribIPointer& c =
      *static_cast<const gles2::cmds::VertexAttribIPointer*>(cmd_data);

  if (!state_.bound_array_buffer.get() ||
      state_.bound_array_buffer->IsDeleted()) {
    if (state_.vertex_attrib_manager.get() ==
        state_.default_vertex_attrib_manager.get()) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glVertexAttribIPointer", "no array buffer bound");
      return error::kNoError;
    } else if (c.offset != 0) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE,
          "glVertexAttribIPointer", "client side arrays are not allowed");
      return error::kNoError;
    }
  }

  GLuint indx = c.indx;
  GLint size = c.size;
  GLenum type = c.type;
  GLsizei stride = c.stride;
  GLsizei offset = c.offset;
  const void* ptr = reinterpret_cast<const void*>(offset);
  if (!validators_->vertex_attrib_i_type.IsValid(type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glVertexAttribIPointer", type, "type");
    return error::kNoError;
  }
  if (!validators_->vertex_attrib_size.IsValid(size)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribIPointer", "size GL_INVALID_VALUE");
    return error::kNoError;
  }
  if (indx >= group_->max_vertex_attribs()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribIPointer", "index out of range");
    return error::kNoError;
  }
  if (stride < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribIPointer", "stride < 0");
    return error::kNoError;
  }
  if (stride > 255) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribIPointer", "stride > 255");
    return error::kNoError;
  }
  if (offset < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribIPointer", "offset < 0");
    return error::kNoError;
  }
  GLsizei component_size =
      GLES2Util::GetGLTypeSizeForTexturesAndBuffers(type);
  // component_size must be a power of two to use & as optimized modulo.
  DCHECK(GLES2Util::IsPOT(component_size));
  if (offset & (component_size - 1)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glVertexAttribIPointer", "offset not valid for type");
    return error::kNoError;
  }
  if (stride & (component_size - 1)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glVertexAttribIPointer", "stride not valid for type");
    return error::kNoError;
  }
  state_.vertex_attrib_manager
      ->SetAttribInfo(indx,
                      state_.bound_array_buffer.get(),
                      size,
                      type,
                      GL_FALSE,
                      stride,
                      stride != 0 ? stride : component_size * size,
                      offset);
  glVertexAttribIPointer(indx, size, type, stride, ptr);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleVertexAttribPointer(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttribPointer& c =
      *static_cast<const gles2::cmds::VertexAttribPointer*>(cmd_data);

  if (!state_.bound_array_buffer.get() ||
      state_.bound_array_buffer->IsDeleted()) {
    if (state_.vertex_attrib_manager.get() ==
        state_.default_vertex_attrib_manager.get()) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glVertexAttribPointer", "no array buffer bound");
      return error::kNoError;
    } else if (c.offset != 0) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE,
          "glVertexAttribPointer", "client side arrays are not allowed");
      return error::kNoError;
    }
  }

  GLuint indx = c.indx;
  GLint size = c.size;
  GLenum type = c.type;
  GLboolean normalized = static_cast<GLboolean>(c.normalized);
  GLsizei stride = c.stride;
  GLsizei offset = c.offset;
  const void* ptr = reinterpret_cast<const void*>(offset);
  if (!validators_->vertex_attrib_type.IsValid(type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glVertexAttribPointer", type, "type");
    return error::kNoError;
  }
  if (!validators_->vertex_attrib_size.IsValid(size)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribPointer", "size GL_INVALID_VALUE");
    return error::kNoError;
  }
  if (indx >= group_->max_vertex_attribs()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribPointer", "index out of range");
    return error::kNoError;
  }
  if (stride < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribPointer", "stride < 0");
    return error::kNoError;
  }
  if (stride > 255) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribPointer", "stride > 255");
    return error::kNoError;
  }
  if (offset < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glVertexAttribPointer", "offset < 0");
    return error::kNoError;
  }
  GLsizei component_size =
      GLES2Util::GetGLTypeSizeForTexturesAndBuffers(type);
  // component_size must be a power of two to use & as optimized modulo.
  DCHECK(GLES2Util::IsPOT(component_size));
  if (offset & (component_size - 1)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glVertexAttribPointer", "offset not valid for type");
    return error::kNoError;
  }
  if (stride & (component_size - 1)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glVertexAttribPointer", "stride not valid for type");
    return error::kNoError;
  }
  state_.vertex_attrib_manager
      ->SetAttribInfo(indx,
                      state_.bound_array_buffer.get(),
                      size,
                      type,
                      normalized,
                      stride,
                      stride != 0 ? stride : component_size * size,
                      offset);
  // We support GL_FIXED natively on EGL/GLES2 implementations
  if (type != GL_FIXED || feature_info_->gl_version_info().is_es) {
    glVertexAttribPointer(indx, size, type, normalized, stride, ptr);
  }
  return error::kNoError;
}

void GLES2DecoderImpl::DoViewport(GLint x, GLint y, GLsizei width,
                                  GLsizei height) {
  state_.viewport_x = x;
  state_.viewport_y = y;
  state_.viewport_width = std::min(width, viewport_max_width_);
  state_.viewport_height = std::min(height, viewport_max_height_);
  glViewport(x, y, width, height);
}

error::Error GLES2DecoderImpl::HandleVertexAttribDivisorANGLE(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::VertexAttribDivisorANGLE& c =
      *static_cast<const gles2::cmds::VertexAttribDivisorANGLE*>(cmd_data);
  if (!features().angle_instanced_arrays) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glVertexAttribDivisorANGLE", "function not available");
    return error::kNoError;
  }
  GLuint index = c.index;
  GLuint divisor = c.divisor;
  if (index >= group_->max_vertex_attribs()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glVertexAttribDivisorANGLE", "index out of range");
    return error::kNoError;
  }

  state_.vertex_attrib_manager->SetDivisor(
      index,
      divisor);
  glVertexAttribDivisorANGLE(index, divisor);
  return error::kNoError;
}

template <typename pixel_data_type>
static void WriteAlphaData(
    void* pixels, uint32 row_count, uint32 channel_count,
    uint32 alpha_channel_index, uint32 unpadded_row_size,
    uint32 padded_row_size, pixel_data_type alpha_value) {
  DCHECK_GT(channel_count, 0U);
  DCHECK_EQ(unpadded_row_size % sizeof(pixel_data_type), 0U);
  uint32 unpadded_row_size_in_elements =
      unpadded_row_size / sizeof(pixel_data_type);
  DCHECK_EQ(padded_row_size % sizeof(pixel_data_type), 0U);
  uint32 padded_row_size_in_elements =
      padded_row_size / sizeof(pixel_data_type);
  pixel_data_type* dst =
      static_cast<pixel_data_type*>(pixels) + alpha_channel_index;
  for (uint32 yy = 0; yy < row_count; ++yy) {
    pixel_data_type* end = dst + unpadded_row_size_in_elements;
    for (pixel_data_type* d = dst; d < end; d += channel_count) {
      *d = alpha_value;
    }
    dst += padded_row_size_in_elements;
  }
}

void GLES2DecoderImpl::FinishReadPixels(
    const cmds::ReadPixels& c,
    GLuint buffer) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::FinishReadPixels");
  GLsizei width = c.width;
  GLsizei height = c.height;
  GLenum format = c.format;
  GLenum type = c.type;
  typedef cmds::ReadPixels::Result Result;
  uint32 pixels_size;
  Result* result = NULL;
  if (c.result_shm_id != 0) {
    result = GetSharedMemoryAs<Result*>(
        c.result_shm_id, c.result_shm_offset, sizeof(*result));
    if (!result) {
      if (buffer != 0) {
        glDeleteBuffersARB(1, &buffer);
      }
      return;
    }
  }
  GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, state_.pack_alignment, &pixels_size,
      NULL, NULL);
  void* pixels = GetSharedMemoryAs<void*>(
      c.pixels_shm_id, c.pixels_shm_offset, pixels_size);
  if (!pixels) {
    if (buffer != 0) {
      glDeleteBuffersARB(1, &buffer);
    }
    return;
  }

  if (buffer != 0) {
    glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, buffer);
    void* data;
    if (features().map_buffer_range) {
      data = glMapBufferRange(
          GL_PIXEL_PACK_BUFFER_ARB, 0, pixels_size, GL_MAP_READ_BIT);
    } else {
      data = glMapBuffer(GL_PIXEL_PACK_BUFFER_ARB, GL_READ_ONLY);
    }
    if (!data) {
      LOCAL_SET_GL_ERROR(GL_OUT_OF_MEMORY, "glMapBuffer",
                         "Unable to map memory for readback.");
      return;
    }
    memcpy(pixels, data, pixels_size);
    // GL_PIXEL_PACK_BUFFER_ARB is currently unused, so we don't
    // have to restore the state.
    glUnmapBuffer(GL_PIXEL_PACK_BUFFER_ARB);
    glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, 0);
    glDeleteBuffersARB(1, &buffer);
  }

  if (result != NULL) {
    *result = true;
  }

  GLenum read_format = GetBoundReadFrameBufferInternalFormat();
  uint32 channels_exist = GLES2Util::GetChannelsForFormat(read_format);
  if ((channels_exist & 0x0008) == 0 &&
      workarounds().clear_alpha_in_readpixels) {
    // Set the alpha to 255 because some drivers are buggy in this regard.
    uint32 temp_size;

    uint32 unpadded_row_size;
    uint32 padded_row_size;
    if (!GLES2Util::ComputeImageDataSizes(
            width, 2, 1, format, type, state_.pack_alignment, &temp_size,
            &unpadded_row_size, &padded_row_size)) {
      return;
    }

    uint32 channel_count = 0;
    uint32 alpha_channel = 0;
    switch (format) {
      case GL_RGBA:
      case GL_BGRA_EXT:
        channel_count = 4;
        alpha_channel = 3;
        break;
      case GL_ALPHA:
        channel_count = 1;
        alpha_channel = 0;
        break;
    }

    if (channel_count > 0) {
      switch (type) {
        case GL_UNSIGNED_BYTE:
          WriteAlphaData<uint8>(
              pixels, height, channel_count, alpha_channel, unpadded_row_size,
              padded_row_size, 0xFF);
          break;
        case GL_FLOAT:
          WriteAlphaData<float>(
              pixels, height, channel_count, alpha_channel, unpadded_row_size,
              padded_row_size, 1.0f);
          break;
        case GL_HALF_FLOAT:
          WriteAlphaData<uint16>(
              pixels, height, channel_count, alpha_channel, unpadded_row_size,
              padded_row_size, 0x3C00);
          break;
      }
    }
  }
}

error::Error GLES2DecoderImpl::HandleReadPixels(uint32 immediate_data_size,
                                                const void* cmd_data) {
  const gles2::cmds::ReadPixels& c =
      *static_cast<const gles2::cmds::ReadPixels*>(cmd_data);
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::HandleReadPixels");
  error::Error fbo_error = WillAccessBoundFramebufferForRead();
  if (fbo_error != error::kNoError)
    return fbo_error;
  GLint x = c.x;
  GLint y = c.y;
  GLsizei width = c.width;
  GLsizei height = c.height;
  GLenum format = c.format;
  GLenum type = c.type;
  GLboolean async = static_cast<GLboolean>(c.async);
  if (width < 0 || height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glReadPixels", "dimensions < 0");
    return error::kNoError;
  }
  typedef cmds::ReadPixels::Result Result;
  uint32 pixels_size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, state_.pack_alignment, &pixels_size,
      NULL, NULL)) {
    return error::kOutOfBounds;
  }
  void* pixels = GetSharedMemoryAs<void*>(
      c.pixels_shm_id, c.pixels_shm_offset, pixels_size);
  if (!pixels) {
    return error::kOutOfBounds;
  }
  Result* result = NULL;
  if (c.result_shm_id != 0) {
    result = GetSharedMemoryAs<Result*>(
        c.result_shm_id, c.result_shm_offset, sizeof(*result));
    if (!result) {
      return error::kOutOfBounds;
    }
  }

  if (!validators_->read_pixel_format.IsValid(format)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glReadPixels", format, "format");
    return error::kNoError;
  }
  if (!validators_->read_pixel_type.IsValid(type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glReadPixels", type, "type");
    return error::kNoError;
  }
  if ((format != GL_RGBA && format != GL_BGRA_EXT && format != GL_RGB &&
      format != GL_ALPHA) || type != GL_UNSIGNED_BYTE) {
    // format and type are acceptable enums but not guaranteed to be supported
    // for this framebuffer.  Have to ask gl if they are valid.
    GLint preferred_format = 0;
    DoGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &preferred_format);
    GLint preferred_type = 0;
    DoGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_TYPE, &preferred_type);
    if (format != static_cast<GLenum>(preferred_format) ||
        type != static_cast<GLenum>(preferred_type)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION, "glReadPixels", "format and type incompatible "
          "with the current read framebuffer");
      return error::kNoError;
    }
  }
  if (width == 0 || height == 0) {
    return error::kNoError;
  }

  // Get the size of the current fbo or backbuffer.
  gfx::Size max_size = GetBoundReadFrameBufferSize();

  int32 max_x;
  int32 max_y;
  if (!SafeAddInt32(x, width, &max_x) || !SafeAddInt32(y, height, &max_y)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glReadPixels", "dimensions out of range");
    return error::kNoError;
  }

  if (!CheckBoundReadFramebufferColorAttachment("glReadPixels")) {
    return error::kNoError;
  }

  if (!CheckBoundFramebuffersValid("glReadPixels")) {
    return error::kNoError;
  }

  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glReadPixels");

  ScopedResolvedFrameBufferBinder binder(this, false, true);

  if (x < 0 || y < 0 || max_x > max_size.width() || max_y > max_size.height()) {
    // The user requested an out of range area. Get the results 1 line
    // at a time.
    uint32 temp_size;
    uint32 unpadded_row_size;
    uint32 padded_row_size;
    if (!GLES2Util::ComputeImageDataSizes(
        width, 2, 1, format, type, state_.pack_alignment, &temp_size,
        &unpadded_row_size, &padded_row_size)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glReadPixels", "dimensions out of range");
      return error::kNoError;
    }

    GLint dest_x_offset = std::max(-x, 0);
    uint32 dest_row_offset;
    if (!GLES2Util::ComputeImageDataSizes(
        dest_x_offset, 1, 1, format, type, state_.pack_alignment,
        &dest_row_offset, NULL, NULL)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glReadPixels", "dimensions out of range");
      return error::kNoError;
    }

    // Copy each row into the larger dest rect.
    int8* dst = static_cast<int8*>(pixels);
    GLint read_x = std::max(0, x);
    GLint read_end_x = std::max(0, std::min(max_size.width(), max_x));
    GLint read_width = read_end_x - read_x;
    for (GLint yy = 0; yy < height; ++yy) {
      GLint ry = y + yy;

      // Clear the row.
      memset(dst, 0, unpadded_row_size);

      // If the row is in range, copy it.
      if (ry >= 0 && ry < max_size.height() && read_width > 0) {
        glReadPixels(
            read_x, ry, read_width, 1, format, type, dst + dest_row_offset);
      }
      dst += padded_row_size;
    }
  } else {
    if (async && features().use_async_readpixels) {
      GLuint buffer = 0;
      glGenBuffersARB(1, &buffer);
      glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, buffer);
      // For ANGLE client version 2, GL_STREAM_READ is not available.
      const GLenum usage_hint = feature_info_->gl_version_info().is_angle ?
          GL_STATIC_DRAW : GL_STREAM_READ;
      glBufferData(GL_PIXEL_PACK_BUFFER_ARB, pixels_size, NULL, usage_hint);
      GLenum error = glGetError();
      if (error == GL_NO_ERROR) {
        glReadPixels(x, y, width, height, format, type, 0);
        pending_readpixel_fences_.push(linked_ptr<FenceCallback>(
            new FenceCallback()));
        WaitForReadPixels(base::Bind(
            &GLES2DecoderImpl::FinishReadPixels,
            base::internal::SupportsWeakPtrBase::StaticAsWeakPtr
            <GLES2DecoderImpl>(this),
            c, buffer));
        glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, 0);
        return error::kNoError;
      } else {
        // On error, unbind pack buffer and fall through to sync readpixels
        glBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, 0);
        glDeleteBuffersARB(1, &buffer);
      }
    }
    glReadPixels(x, y, width, height, format, type, pixels);
  }
  GLenum error = LOCAL_PEEK_GL_ERROR("glReadPixels");
  if (error == GL_NO_ERROR) {
    if (result != NULL) {
      *result = true;
    }
    FinishReadPixels(c, 0);
  }

  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandlePixelStorei(uint32 immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::PixelStorei& c =
      *static_cast<const gles2::cmds::PixelStorei*>(cmd_data);
  GLenum pname = c.pname;
  GLenum param = c.param;
  if (!validators_->pixel_store.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glPixelStorei", pname, "pname");
    return error::kNoError;
  }
  switch (pname) {
    case GL_PACK_ALIGNMENT:
    case GL_UNPACK_ALIGNMENT:
        if (!validators_->pixel_store_alignment.IsValid(param)) {
            LOCAL_SET_GL_ERROR(
                GL_INVALID_VALUE, "glPixelStorei", "param GL_INVALID_VALUE");
            return error::kNoError;
        }
        break;
    case GL_UNPACK_FLIP_Y_CHROMIUM:
        unpack_flip_y_ = (param != 0);
        return error::kNoError;
    case GL_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM:
        unpack_premultiply_alpha_ = (param != 0);
        return error::kNoError;
    case GL_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM:
        unpack_unpremultiply_alpha_ = (param != 0);
        return error::kNoError;
    default:
        break;
  }
  glPixelStorei(pname, param);
  switch (pname) {
    case GL_PACK_ALIGNMENT:
        state_.pack_alignment = param;
        break;
    case GL_PACK_REVERSE_ROW_ORDER_ANGLE:
        state_.pack_reverse_row_order = (param != 0);
        break;
    case GL_UNPACK_ALIGNMENT:
        state_.unpack_alignment = param;
        break;
    default:
        // Validation should have prevented us from getting here.
        NOTREACHED();
        break;
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandlePostSubBufferCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::PostSubBufferCHROMIUM& c =
      *static_cast<const gles2::cmds::PostSubBufferCHROMIUM*>(cmd_data);
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::HandlePostSubBufferCHROMIUM");
  {
    TRACE_EVENT_SYNTHETIC_DELAY("gpu.PresentingFrame");
  }
  if (!supports_post_sub_buffer_) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glPostSubBufferCHROMIUM", "command not supported by surface");
    return error::kNoError;
  }
  bool is_tracing;
  TRACE_EVENT_CATEGORY_GROUP_ENABLED(TRACE_DISABLED_BY_DEFAULT("gpu.debug"),
                                     &is_tracing);
  if (is_tracing) {
    bool is_offscreen = !!offscreen_target_frame_buffer_.get();
    ScopedFrameBufferBinder binder(this, GetBackbufferServiceId());
    gpu_state_tracer_->TakeSnapshotWithCurrentFramebuffer(
        is_offscreen ? offscreen_size_ : surface_->GetSize());
  }
  if (surface_->PostSubBuffer(c.x, c.y, c.width, c.height)) {
    return error::kNoError;
  } else {
    LOG(ERROR) << "Context lost because PostSubBuffer failed.";
    return error::kLostContext;
  }
}

error::Error GLES2DecoderImpl::HandleScheduleOverlayPlaneCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::ScheduleOverlayPlaneCHROMIUM& c =
      *static_cast<const gles2::cmds::ScheduleOverlayPlaneCHROMIUM*>(cmd_data);
  TextureRef* ref = texture_manager()->GetTexture(c.overlay_texture_id);
  if (!ref) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE,
                       "glScheduleOverlayPlaneCHROMIUM",
                       "unknown texture");
    return error::kNoError;
  }
  gfx::GLImage* image =
      ref->texture()->GetLevelImage(ref->texture()->target(), 0);
  if (!image) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE,
                       "glScheduleOverlayPlaneCHROMIUM",
                       "unsupported texture format");
    return error::kNoError;
  }
  gfx::OverlayTransform transform = GetGFXOverlayTransform(c.plane_transform);
  if (transform == gfx::OVERLAY_TRANSFORM_INVALID) {
    LOCAL_SET_GL_ERROR(GL_INVALID_ENUM,
                       "glScheduleOverlayPlaneCHROMIUM",
                       "invalid transform enum");
    return error::kNoError;
  }
  if (!surface_->ScheduleOverlayPlane(
          c.plane_z_order,
          transform,
          image,
          gfx::Rect(c.bounds_x, c.bounds_y, c.bounds_width, c.bounds_height),
          gfx::RectF(c.uv_x, c.uv_y, c.uv_width, c.uv_height))) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glScheduleOverlayPlaneCHROMIUM",
                       "failed to schedule overlay");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::GetAttribLocationHelper(
    GLuint client_id, uint32 location_shm_id, uint32 location_shm_offset,
    const std::string& name_str) {
  if (!StringIsValidForGLES(name_str.c_str())) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glGetAttribLocation", "Invalid character");
    return error::kNoError;
  }
  Program* program = GetProgramInfoNotShader(
      client_id, "glGetAttribLocation");
  if (!program) {
    return error::kNoError;
  }
  if (!program->IsValid()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glGetAttribLocation", "program not linked");
    return error::kNoError;
  }
  GLint* location = GetSharedMemoryAs<GLint*>(
      location_shm_id, location_shm_offset, sizeof(GLint));
  if (!location) {
    return error::kOutOfBounds;
  }
  // Require the client to init this incase the context is lost and we are no
  // longer executing commands.
  if (*location != -1) {
    return error::kGenericError;
  }
  *location = program->GetAttribLocation(name_str);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetAttribLocation(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetAttribLocation& c =
      *static_cast<const gles2::cmds::GetAttribLocation*>(cmd_data);
  Bucket* bucket = GetBucket(c.name_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  std::string name_str;
  if (!bucket->GetAsString(&name_str)) {
    return error::kInvalidArguments;
  }
  return GetAttribLocationHelper(
    c.program, c.location_shm_id, c.location_shm_offset, name_str);
}

error::Error GLES2DecoderImpl::GetUniformLocationHelper(
    GLuint client_id, uint32 location_shm_id, uint32 location_shm_offset,
    const std::string& name_str) {
  if (!StringIsValidForGLES(name_str.c_str())) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glGetUniformLocation", "Invalid character");
    return error::kNoError;
  }
  Program* program = GetProgramInfoNotShader(
      client_id, "glGetUniformLocation");
  if (!program) {
    return error::kNoError;
  }
  if (!program->IsValid()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glGetUniformLocation", "program not linked");
    return error::kNoError;
  }
  GLint* location = GetSharedMemoryAs<GLint*>(
      location_shm_id, location_shm_offset, sizeof(GLint));
  if (!location) {
    return error::kOutOfBounds;
  }
  // Require the client to init this incase the context is lost an we are no
  // longer executing commands.
  if (*location != -1) {
    return error::kGenericError;
  }
  *location = program->GetUniformFakeLocation(name_str);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetUniformLocation(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetUniformLocation& c =
      *static_cast<const gles2::cmds::GetUniformLocation*>(cmd_data);
  Bucket* bucket = GetBucket(c.name_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  std::string name_str;
  if (!bucket->GetAsString(&name_str)) {
    return error::kInvalidArguments;
  }
  return GetUniformLocationHelper(
    c.program, c.location_shm_id, c.location_shm_offset, name_str);
}

error::Error GLES2DecoderImpl::HandleGetUniformIndices(
    uint32 immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetUniformIndices& c =
      *static_cast<const gles2::cmds::GetUniformIndices*>(cmd_data);
  Bucket* bucket = GetBucket(c.names_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  GLsizei count = 0;
  std::vector<char*> names;
  std::vector<GLint> len;
  if (!bucket->GetAsStrings(&count, &names, &len) || count <= 0) {
    return error::kInvalidArguments;
  }
  typedef cmds::GetUniformIndices::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.indices_shm_id, c.indices_shm_offset,
      Result::ComputeSize(static_cast<size_t>(count)));
  GLuint* indices = result ? result->GetData() : NULL;
  if (indices == NULL) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  Program* program = GetProgramInfoNotShader(c.program, "glGetUniformIndices");
  if (!program) {
    return error::kNoError;
  }
  GLuint service_id = program->service_id();
  GLint link_status = GL_FALSE;
  glGetProgramiv(service_id, GL_LINK_STATUS, &link_status);
  if (link_status != GL_TRUE) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
        "glGetUniformIndices", "program not linked");
    return error::kNoError;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetUniformIndices");
  glGetUniformIndices(service_id, count, &names[0], indices);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(count);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetUniformIndices", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::GetFragDataLocationHelper(
    GLuint client_id, uint32 location_shm_id, uint32 location_shm_offset,
    const std::string& name_str) {
  GLint* location = GetSharedMemoryAs<GLint*>(
      location_shm_id, location_shm_offset, sizeof(GLint));
  if (!location) {
    return error::kOutOfBounds;
  }
  // Require the client to init this incase the context is lost and we are no
  // longer executing commands.
  if (*location != -1) {
    return error::kGenericError;
  }
  Program* program = GetProgramInfoNotShader(
      client_id, "glGetFragDataLocation");
  if (!program) {
    return error::kNoError;
  }
  *location = glGetFragDataLocation(program->service_id(), name_str.c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetFragDataLocation(
    uint32 immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetFragDataLocation& c =
      *static_cast<const gles2::cmds::GetFragDataLocation*>(cmd_data);
  Bucket* bucket = GetBucket(c.name_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  std::string name_str;
  if (!bucket->GetAsString(&name_str)) {
    return error::kInvalidArguments;
  }
  return GetFragDataLocationHelper(
      c.program, c.location_shm_id, c.location_shm_offset, name_str);
}

error::Error GLES2DecoderImpl::HandleGetUniformBlockIndex(
    uint32 immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetUniformBlockIndex& c =
      *static_cast<const gles2::cmds::GetUniformBlockIndex*>(cmd_data);
  Bucket* bucket = GetBucket(c.name_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  std::string name_str;
  if (!bucket->GetAsString(&name_str)) {
    return error::kInvalidArguments;
  }
  GLuint* index = GetSharedMemoryAs<GLuint*>(
      c.index_shm_id, c.index_shm_offset, sizeof(GLuint));
  if (!index) {
    return error::kOutOfBounds;
  }
  // Require the client to init this in case the context is lost and we are no
  // longer executing commands.
  if (*index != GL_INVALID_INDEX) {
    return error::kGenericError;
  }
  Program* program = GetProgramInfoNotShader(
      c.program, "glGetUniformBlockIndex");
  if (!program) {
    return error::kNoError;
  }
  *index = glGetUniformBlockIndex(program->service_id(), name_str.c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetString(uint32 immediate_data_size,
                                               const void* cmd_data) {
  const gles2::cmds::GetString& c =
      *static_cast<const gles2::cmds::GetString*>(cmd_data);
  GLenum name = static_cast<GLenum>(c.name);
  if (!validators_->string_type.IsValid(name)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM("glGetString", name, "name");
    return error::kNoError;
  }
  const char* str = reinterpret_cast<const char*>(glGetString(name));
  std::string extensions;
  switch (name) {
    case GL_VERSION:
      str = "OpenGL ES 2.0 Chromium";
      break;
    case GL_SHADING_LANGUAGE_VERSION:
      str = "OpenGL ES GLSL ES 1.0 Chromium";
      break;
    case GL_RENDERER:
    case GL_VENDOR:
      // Return the unmasked VENDOR/RENDERER string for WebGL contexts.
      // They are used by WEBGL_debug_renderer_info.
      if (!force_webgl_glsl_validation_)
        str = "Chromium";
      break;
    case GL_EXTENSIONS:
      {
        // For WebGL contexts, strip out the OES derivatives and
        // EXT frag depth extensions if they have not been enabled.
        if (force_webgl_glsl_validation_) {
          extensions = feature_info_->extensions();
          if (!derivatives_explicitly_enabled_) {
            size_t offset = extensions.find(kOESDerivativeExtension);
            if (std::string::npos != offset) {
              extensions.replace(offset, arraysize(kOESDerivativeExtension),
                                 std::string());
            }
          }
          if (!frag_depth_explicitly_enabled_) {
            size_t offset = extensions.find(kEXTFragDepthExtension);
            if (std::string::npos != offset) {
              extensions.replace(offset, arraysize(kEXTFragDepthExtension),
                                 std::string());
            }
          }
          if (!draw_buffers_explicitly_enabled_) {
            size_t offset = extensions.find(kEXTDrawBuffersExtension);
            if (std::string::npos != offset) {
              extensions.replace(offset, arraysize(kEXTDrawBuffersExtension),
                                 std::string());
            }
          }
          if (!shader_texture_lod_explicitly_enabled_) {
            size_t offset = extensions.find(kEXTShaderTextureLodExtension);
            if (std::string::npos != offset) {
              extensions.replace(offset,
                                 arraysize(kEXTShaderTextureLodExtension),
                                 std::string());
            }
          }
        } else {
          extensions = feature_info_->extensions().c_str();
        }
        if (supports_post_sub_buffer_)
          extensions += " GL_CHROMIUM_post_sub_buffer";
        str = extensions.c_str();
      }
      break;
    default:
      break;
  }
  Bucket* bucket = CreateBucket(c.bucket_id);
  bucket->SetFromString(str);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleBufferData(uint32 immediate_data_size,
                                                const void* cmd_data) {
  const gles2::cmds::BufferData& c =
      *static_cast<const gles2::cmds::BufferData*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  GLsizeiptr size = static_cast<GLsizeiptr>(c.size);
  uint32 data_shm_id = static_cast<uint32>(c.data_shm_id);
  uint32 data_shm_offset = static_cast<uint32>(c.data_shm_offset);
  GLenum usage = static_cast<GLenum>(c.usage);
  const void* data = NULL;
  if (data_shm_id != 0 || data_shm_offset != 0) {
    data = GetSharedMemoryAs<const void*>(data_shm_id, data_shm_offset, size);
    if (!data) {
      return error::kOutOfBounds;
    }
  }
  buffer_manager()->ValidateAndDoBufferData(&state_, target, size, data, usage);
  return error::kNoError;
}

void GLES2DecoderImpl::DoBufferSubData(
  GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid * data) {
  // Just delegate it. Some validation is actually done before this.
  buffer_manager()->ValidateAndDoBufferSubData(
      &state_, target, offset, size, data);
}

bool GLES2DecoderImpl::ClearLevel(
    Texture* texture,
    unsigned target,
    int level,
    unsigned internal_format,
    unsigned format,
    unsigned type,
    int width,
    int height,
    bool is_texture_immutable) {
  uint32 channels = GLES2Util::GetChannelsForFormat(format);
  if (feature_info_->feature_flags().angle_depth_texture &&
      (channels & GLES2Util::kDepth) != 0) {
    // It's a depth format and ANGLE doesn't allow texImage2D or texSubImage2D
    // on depth formats.
    GLuint fb = 0;
    glGenFramebuffersEXT(1, &fb);
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, fb);

    bool have_stencil = (channels & GLES2Util::kStencil) != 0;
    GLenum attachment = have_stencil ? GL_DEPTH_STENCIL_ATTACHMENT :
                                       GL_DEPTH_ATTACHMENT;

    glFramebufferTexture2DEXT(GL_DRAW_FRAMEBUFFER_EXT, attachment, target,
                              texture->service_id(), level);
    // ANGLE promises a depth only attachment ok.
    if (glCheckFramebufferStatusEXT(GL_DRAW_FRAMEBUFFER_EXT) !=
        GL_FRAMEBUFFER_COMPLETE) {
      return false;
    }
    glClearStencil(0);
    state_.SetDeviceStencilMaskSeparate(GL_FRONT, kDefaultStencilMask);
    state_.SetDeviceStencilMaskSeparate(GL_BACK, kDefaultStencilMask);
    glClearDepth(1.0f);
    state_.SetDeviceDepthMask(GL_TRUE);
    state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);
    glClear(GL_DEPTH_BUFFER_BIT | (have_stencil ? GL_STENCIL_BUFFER_BIT : 0));

    RestoreClearState();

    glDeleteFramebuffersEXT(1, &fb);
    Framebuffer* framebuffer =
        GetFramebufferInfoForTarget(GL_DRAW_FRAMEBUFFER_EXT);
    GLuint fb_service_id =
        framebuffer ? framebuffer->service_id() : GetBackbufferServiceId();
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, fb_service_id);
    return true;
  }

  static const uint32 kMaxZeroSize = 1024 * 1024 * 4;

  uint32 size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
          width, height, 1, format, type, state_.unpack_alignment, &size,
          NULL, &padded_row_size)) {
    return false;
  }

  TRACE_EVENT1("gpu", "GLES2DecoderImpl::ClearLevel", "size", size);

  int tile_height;

  if (size > kMaxZeroSize) {
    if (kMaxZeroSize < padded_row_size) {
        // That'd be an awfully large texture.
        return false;
    }
    // We should never have a large total size with a zero row size.
    DCHECK_GT(padded_row_size, 0U);
    tile_height = kMaxZeroSize / padded_row_size;
    if (!GLES2Util::ComputeImageDataSizes(
            width, tile_height, 1, format, type, state_.unpack_alignment, &size,
            NULL, NULL)) {
      return false;
    }
  } else {
    tile_height = height;
  }

  // Assumes the size has already been checked.
  scoped_ptr<char[]> zero(new char[size]);
  memset(zero.get(), 0, size);
  glBindTexture(texture->target(), texture->service_id());

  bool has_images = texture->HasImages();
  GLint y = 0;
  while (y < height) {
    GLint h = y + tile_height > height ? height - y : tile_height;
    if (is_texture_immutable || h != height || has_images) {
      glTexSubImage2D(target, level, 0, y, width, h, format, type, zero.get());
    } else {
      glTexImage2D(
          target, level, internal_format, width, h, 0, format, type,
          zero.get());
    }
    y += tile_height;
  }
  TextureRef* bound_texture =
      texture_manager()->GetTextureInfoForTarget(&state_, texture->target());
  glBindTexture(texture->target(),
                bound_texture ? bound_texture->service_id() : 0);
  return true;
}

namespace {

const int kS3TCBlockWidth = 4;
const int kS3TCBlockHeight = 4;
const int kS3TCDXT1BlockSize = 8;
const int kS3TCDXT3AndDXT5BlockSize = 16;

bool IsValidDXTSize(GLint level, GLsizei size) {
  return (size == 1) ||
         (size == 2) || !(size % kS3TCBlockWidth);
}

bool IsValidPVRTCSize(GLint level, GLsizei size) {
  return GLES2Util::IsPOT(size);
}

}  // anonymous namespace.

bool GLES2DecoderImpl::ValidateCompressedTexFuncData(
    const char* function_name,
    GLsizei width, GLsizei height, GLenum format, size_t size) {
  unsigned int bytes_required = 0;

  switch (format) {
    case GL_ATC_RGB_AMD:
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
    case GL_ETC1_RGB8_OES: {
        int num_blocks_across =
            (width + kS3TCBlockWidth - 1) / kS3TCBlockWidth;
        int num_blocks_down =
            (height + kS3TCBlockHeight - 1) / kS3TCBlockHeight;
        int num_blocks = num_blocks_across * num_blocks_down;
        bytes_required = num_blocks * kS3TCDXT1BlockSize;
        break;
      }
    case GL_ATC_RGBA_EXPLICIT_ALPHA_AMD:
    case GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD:
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: {
        int num_blocks_across =
            (width + kS3TCBlockWidth - 1) / kS3TCBlockWidth;
        int num_blocks_down =
            (height + kS3TCBlockHeight - 1) / kS3TCBlockHeight;
        int num_blocks = num_blocks_across * num_blocks_down;
        bytes_required = num_blocks * kS3TCDXT3AndDXT5BlockSize;
        break;
      }
    case GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG: {
        bytes_required = (std::max(width, 8) * std::max(height, 8) * 4 + 7)/8;
        break;
      }
    case GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG: {
        bytes_required = (std::max(width, 16) * std::max(height, 8) * 2 + 7)/8;
        break;
      }
    default:
      LOCAL_SET_GL_ERROR_INVALID_ENUM(function_name, format, "format");
      return false;
  }

  if (size != bytes_required) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, function_name, "size is not correct for dimensions");
    return false;
  }

  return true;
}

bool GLES2DecoderImpl::ValidateCompressedTexDimensions(
    const char* function_name,
    GLint level, GLsizei width, GLsizei height, GLenum format) {
  switch (format) {
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: {
      if (!IsValidDXTSize(level, width) || !IsValidDXTSize(level, height)) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name,
            "width or height invalid for level");
        return false;
      }
      return true;
    }
    case GL_ATC_RGB_AMD:
    case GL_ATC_RGBA_EXPLICIT_ALPHA_AMD:
    case GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD:
    case GL_ETC1_RGB8_OES: {
      if (width <= 0 || height <= 0) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name,
            "width or height invalid for level");
        return false;
      }
      return true;
    }
    case GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG: {
      if (!IsValidPVRTCSize(level, width) ||
          !IsValidPVRTCSize(level, height)) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name,
            "width or height invalid for level");
        return false;
      }
      return true;
    }
    default:
      return false;
  }
}

bool GLES2DecoderImpl::ValidateCompressedTexSubDimensions(
    const char* function_name,
    GLenum target, GLint level, GLint xoffset, GLint yoffset,
    GLsizei width, GLsizei height, GLenum format,
    Texture* texture) {
  if (xoffset < 0 || yoffset < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, function_name, "xoffset or yoffset < 0");
    return false;
  }

  switch (format) {
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: {
      const int kBlockWidth = 4;
      const int kBlockHeight = 4;
      if ((xoffset % kBlockWidth) || (yoffset % kBlockHeight)) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name,
            "xoffset or yoffset not multiple of 4");
        return false;
      }
      GLsizei tex_width = 0;
      GLsizei tex_height = 0;
      if (!texture->GetLevelSize(target, level, &tex_width, &tex_height) ||
          width - xoffset > tex_width ||
          height - yoffset > tex_height) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name, "dimensions out of range");
        return false;
      }
      return ValidateCompressedTexDimensions(
          function_name, level, width, height, format);
    }
    case GL_ATC_RGB_AMD:
    case GL_ATC_RGBA_EXPLICIT_ALPHA_AMD:
    case GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD: {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION, function_name,
          "not supported for ATC textures");
      return false;
    }
    case GL_ETC1_RGB8_OES: {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION, function_name,
          "not supported for ECT1_RGB8_OES textures");
      return false;
    }
    case GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG: {
      if ((xoffset != 0) || (yoffset != 0)) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name,
            "xoffset and yoffset must be zero");
        return false;
      }
      GLsizei tex_width = 0;
      GLsizei tex_height = 0;
      if (!texture->GetLevelSize(target, level, &tex_width, &tex_height) ||
          width != tex_width ||
          height != tex_height) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, function_name,
            "dimensions must match existing texture level dimensions");
        return false;
      }
      return ValidateCompressedTexDimensions(
          function_name, level, width, height, format);
    }
    default:
      return false;
  }
}

error::Error GLES2DecoderImpl::DoCompressedTexImage2D(
  GLenum target,
  GLint level,
  GLenum internal_format,
  GLsizei width,
  GLsizei height,
  GLint border,
  GLsizei image_size,
  const void* data) {
  // TODO(gman): Validate image_size is correct for width, height and format.
  if (!validators_->texture_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glCompressedTexImage2D", target, "target");
    return error::kNoError;
  }
  if (!validators_->compressed_texture_format.IsValid(
      internal_format)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glCompressedTexImage2D", internal_format, "internal_format");
    return error::kNoError;
  }
  if (!texture_manager()->ValidForTarget(target, level, width, height, 1) ||
      border != 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glCompressedTexImage2D", "dimensions out of range");
    return error::kNoError;
  }
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glCompressedTexImage2D", "unknown texture target");
    return error::kNoError;
  }
  Texture* texture = texture_ref->texture();
  if (texture->IsImmutable()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCompressedTexImage2D", "texture is immutable");
    return error::kNoError;
  }

  if (!ValidateCompressedTexDimensions(
      "glCompressedTexImage2D", level, width, height, internal_format) ||
      !ValidateCompressedTexFuncData(
      "glCompressedTexImage2D", width, height, internal_format, image_size)) {
    return error::kNoError;
  }

  if (!EnsureGPUMemoryAvailable(image_size)) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY, "glCompressedTexImage2D", "out of memory");
    return error::kNoError;
  }

  if (texture->IsAttachedToFramebuffer()) {
    framebuffer_state_.clear_state_dirty = true;
  }

  scoped_ptr<int8[]> zero;
  if (!data) {
    zero.reset(new int8[image_size]);
    memset(zero.get(), 0, image_size);
    data = zero.get();
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glCompressedTexImage2D");
  glCompressedTexImage2D(
      target, level, internal_format, width, height, border, image_size, data);
  GLenum error = LOCAL_PEEK_GL_ERROR("glCompressedTexImage2D");
  if (error == GL_NO_ERROR) {
    texture_manager()->SetLevelInfo(
        texture_ref, target, level, internal_format,
        width, height, 1, border, 0, 0, true);
  }

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleCompressedTexImage2D(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CompressedTexImage2D& c =
      *static_cast<const gles2::cmds::CompressedTexImage2D*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLenum internal_format = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLint border = static_cast<GLint>(c.border);
  GLsizei image_size = static_cast<GLsizei>(c.imageSize);
  uint32 data_shm_id = static_cast<uint32>(c.data_shm_id);
  uint32 data_shm_offset = static_cast<uint32>(c.data_shm_offset);
  const void* data = NULL;
  if (data_shm_id != 0 || data_shm_offset != 0) {
    data = GetSharedMemoryAs<const void*>(
        data_shm_id, data_shm_offset, image_size);
    if (!data) {
      return error::kOutOfBounds;
    }
  }
  return DoCompressedTexImage2D(
      target, level, internal_format, width, height, border, image_size, data);
}

error::Error GLES2DecoderImpl::HandleCompressedTexImage2DBucket(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CompressedTexImage2DBucket& c =
      *static_cast<const gles2::cmds::CompressedTexImage2DBucket*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLenum internal_format = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLint border = static_cast<GLint>(c.border);
  Bucket* bucket = GetBucket(c.bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  uint32 data_size = bucket->size();
  GLsizei imageSize = data_size;
  const void* data = bucket->GetData(0, data_size);
  if (!data) {
    return error::kInvalidArguments;
  }
  return DoCompressedTexImage2D(
      target, level, internal_format, width, height, border,
      imageSize, data);
}

error::Error GLES2DecoderImpl::HandleCompressedTexSubImage2DBucket(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CompressedTexSubImage2DBucket& c =
      *static_cast<const gles2::cmds::CompressedTexSubImage2DBucket*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLenum format = static_cast<GLenum>(c.format);
  Bucket* bucket = GetBucket(c.bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  uint32 data_size = bucket->size();
  GLsizei imageSize = data_size;
  const void* data = bucket->GetData(0, data_size);
  if (!data) {
    return error::kInvalidArguments;
  }
  if (!validators_->texture_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_ENUM, "glCompressedTexSubImage2D", "target");
    return error::kNoError;
  }
  if (!validators_->compressed_texture_format.IsValid(format)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glCompressedTexSubImage2D", format, "format");
    return error::kNoError;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glCompressedTexSubImage2D", "width < 0");
    return error::kNoError;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glCompressedTexSubImage2D", "height < 0");
    return error::kNoError;
  }
  if (imageSize < 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glCompressedTexSubImage2D", "imageSize < 0");
    return error::kNoError;
  }
  DoCompressedTexSubImage2D(
      target, level, xoffset, yoffset, width, height, format, imageSize, data);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexImage2D(uint32 immediate_data_size,
                                                const void* cmd_data) {
  const gles2::cmds::TexImage2D& c =
      *static_cast<const gles2::cmds::TexImage2D*>(cmd_data);
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::HandleTexImage2D",
      "width", c.width, "height", c.height);
  // Set as failed for now, but if it successed, this will be set to not failed.
  texture_state_.tex_image_2d_failed = true;
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  // TODO(kloveless): Change TexImage2D command to use unsigned integer
  // for internalformat.
  GLenum internal_format = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLint border = static_cast<GLint>(c.border);
  GLenum format = static_cast<GLenum>(c.format);
  GLenum type = static_cast<GLenum>(c.type);
  uint32 pixels_shm_id = static_cast<uint32>(c.pixels_shm_id);
  uint32 pixels_shm_offset = static_cast<uint32>(c.pixels_shm_offset);
  uint32 pixels_size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, state_.unpack_alignment, &pixels_size,
      NULL, NULL)) {
    return error::kOutOfBounds;
  }
  const void* pixels = NULL;
  if (pixels_shm_id != 0 || pixels_shm_offset != 0) {
    pixels = GetSharedMemoryAs<const void*>(
        pixels_shm_id, pixels_shm_offset, pixels_size);
    if (!pixels) {
      return error::kOutOfBounds;
    }
  }

  TextureManager::DoTextImage2DArguments args = {
    target, level, internal_format, width, height, border, format, type,
    pixels, pixels_size};
  texture_manager()->ValidateAndDoTexImage2D(
      &texture_state_, &state_, &framebuffer_state_, args);

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexImage3D(uint32 immediate_data_size,
                                                const void* cmd_data) {
  // TODO(zmo): Unsafe ES3 API.
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;

  const gles2::cmds::TexImage3D& c =
      *static_cast<const gles2::cmds::TexImage3D*>(cmd_data);
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::HandleTexImage3D",
      "widthXheight", c.width * c.height, "depth", c.depth);
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLenum internal_format = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLsizei depth = static_cast<GLsizei>(c.depth);
  GLint border = static_cast<GLint>(c.border);
  GLenum format = static_cast<GLenum>(c.format);
  GLenum type = static_cast<GLenum>(c.type);
  uint32 pixels_shm_id = static_cast<uint32>(c.pixels_shm_id);
  uint32 pixels_shm_offset = static_cast<uint32>(c.pixels_shm_offset);
  uint32 pixels_size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, depth, format, type, state_.unpack_alignment, &pixels_size,
      NULL, NULL)) {
    return error::kOutOfBounds;
  }
  const void* pixels = NULL;
  if (pixels_shm_id != 0 || pixels_shm_offset != 0) {
    pixels = GetSharedMemoryAs<const void*>(
        pixels_shm_id, pixels_shm_offset, pixels_size);
    if (!pixels) {
      return error::kOutOfBounds;
    }
  }

  glTexImage3D(target, level, internal_format, width, height, depth, border,
               format, type, pixels);

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
  return error::kNoError;
}

void GLES2DecoderImpl::DoCompressedTexSubImage2D(
  GLenum target,
  GLint level,
  GLint xoffset,
  GLint yoffset,
  GLsizei width,
  GLsizei height,
  GLenum format,
  GLsizei image_size,
  const void * data) {
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCompressedTexSubImage2D", "unknown texture for target");
    return;
  }
  Texture* texture = texture_ref->texture();
  GLenum type = 0;
  GLenum internal_format = 0;
  if (!texture->GetLevelType(target, level, &type, &internal_format)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCompressedTexSubImage2D", "level does not exist.");
    return;
  }
  if (internal_format != format) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCompressedTexSubImage2D", "format does not match internal format.");
    return;
  }
  if (!texture->ValidForTexture(
      target, level, xoffset, yoffset, width, height, type)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glCompressedTexSubImage2D", "bad dimensions.");
    return;
  }

  if (!ValidateCompressedTexFuncData(
      "glCompressedTexSubImage2D", width, height, format, image_size) ||
      !ValidateCompressedTexSubDimensions(
      "glCompressedTexSubImage2D",
      target, level, xoffset, yoffset, width, height, format, texture)) {
    return;
  }


  // Note: There is no need to deal with texture cleared tracking here
  // because the validation above means you can only get here if the level
  // is already a matching compressed format and in that case
  // CompressedTexImage2D already cleared the texture.
  glCompressedTexSubImage2D(
      target, level, xoffset, yoffset, width, height, format, image_size, data);

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
}

static void Clip(
    GLint start, GLint range, GLint sourceRange,
    GLint* out_start, GLint* out_range) {
  DCHECK(out_start);
  DCHECK(out_range);
  if (start < 0) {
    range += start;
    start = 0;
  }
  GLint end = start + range;
  if (end > sourceRange) {
    range -= end - sourceRange;
  }
  *out_start = start;
  *out_range = range;
}

void GLES2DecoderImpl::DoCopyTexImage2D(
    GLenum target,
    GLint level,
    GLenum internal_format,
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height,
    GLint border) {
  DCHECK(!ShouldDeferReads());
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCopyTexImage2D", "unknown texture for target");
    return;
  }
  Texture* texture = texture_ref->texture();
  if (texture->IsImmutable()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glCopyTexImage2D", "texture is immutable");
    return;
  }
  if (!texture_manager()->ValidForTarget(target, level, width, height, 1) ||
      border != 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glCopyTexImage2D", "dimensions out of range");
    return;
  }
  if (!texture_manager()->ValidateFormatAndTypeCombination(
      state_.GetErrorState(), "glCopyTexImage2D", internal_format,
      GL_UNSIGNED_BYTE)) {
    return;
  }

  // Check we have compatible formats.
  GLenum read_format = GetBoundReadFrameBufferInternalFormat();
  uint32 channels_exist = GLES2Util::GetChannelsForFormat(read_format);
  uint32 channels_needed = GLES2Util::GetChannelsForFormat(internal_format);

  if ((channels_needed & channels_exist) != channels_needed) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glCopyTexImage2D", "incompatible format");
    return;
  }

  if ((channels_needed & (GLES2Util::kDepth | GLES2Util::kStencil)) != 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCopyTexImage2D", "can not be used with depth or stencil textures");
    return;
  }

  uint32 estimated_size = 0;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, internal_format, GL_UNSIGNED_BYTE,
      state_.unpack_alignment, &estimated_size, NULL, NULL)) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY, "glCopyTexImage2D", "dimensions too large");
    return;
  }

  if (!EnsureGPUMemoryAvailable(estimated_size)) {
    LOCAL_SET_GL_ERROR(GL_OUT_OF_MEMORY, "glCopyTexImage2D", "out of memory");
    return;
  }

  if (!CheckBoundReadFramebufferColorAttachment("glCopyTexImage2D")) {
    return;
  }

  if (FormsTextureCopyingFeedbackLoop(texture_ref, level)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCopyTexImage2D", "source and destination textures are the same");
    return;
  }

  if (!CheckBoundFramebuffersValid("glCopyTexImage2D")) {
    return;
  }

  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glCopyTexImage2D");
  ScopedResolvedFrameBufferBinder binder(this, false, true);
  gfx::Size size = GetBoundReadFrameBufferSize();

  if (texture->IsAttachedToFramebuffer()) {
    framebuffer_state_.clear_state_dirty = true;
  }

  // Clip to size to source dimensions
  GLint copyX = 0;
  GLint copyY = 0;
  GLint copyWidth = 0;
  GLint copyHeight = 0;
  Clip(x, width, size.width(), &copyX, &copyWidth);
  Clip(y, height, size.height(), &copyY, &copyHeight);

  if (copyX != x ||
      copyY != y ||
      copyWidth != width ||
      copyHeight != height) {
    // some part was clipped so clear the texture.
    if (!ClearLevel(texture, target, level, internal_format, internal_format,
                    GL_UNSIGNED_BYTE, width, height, texture->IsImmutable())) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, "glCopyTexImage2D", "dimensions too big");
      return;
    }
    if (copyHeight > 0 && copyWidth > 0) {
      GLint dx = copyX - x;
      GLint dy = copyY - y;
      GLint destX = dx;
      GLint destY = dy;
      ScopedModifyPixels modify(texture_ref);
      glCopyTexSubImage2D(target, level,
                          destX, destY, copyX, copyY,
                          copyWidth, copyHeight);
    }
  } else {
    ScopedModifyPixels modify(texture_ref);
    glCopyTexImage2D(target, level, internal_format,
                     copyX, copyY, copyWidth, copyHeight, border);
  }
  GLenum error = LOCAL_PEEK_GL_ERROR("glCopyTexImage2D");
  if (error == GL_NO_ERROR) {
    texture_manager()->SetLevelInfo(
        texture_ref, target, level, internal_format, width, height, 1,
        border, internal_format, GL_UNSIGNED_BYTE, true);
  }

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
}

void GLES2DecoderImpl::DoCopyTexSubImage2D(
    GLenum target,
    GLint level,
    GLint xoffset,
    GLint yoffset,
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height) {
  DCHECK(!ShouldDeferReads());
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCopyTexSubImage2D", "unknown texture for target");
    return;
  }
  Texture* texture = texture_ref->texture();
  GLenum type = 0;
  GLenum format = 0;
  if (!texture->GetLevelType(target, level, &type, &format) ||
      !texture->ValidForTexture(
          target, level, xoffset, yoffset, width, height, type)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glCopyTexSubImage2D", "bad dimensions.");
    return;
  }
  if (async_pixel_transfer_manager_->AsyncTransferIsInProgress(texture_ref)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCopyTexSubImage2D", "async upload pending for texture");
    return;
  }

  // Check we have compatible formats.
  GLenum read_format = GetBoundReadFrameBufferInternalFormat();
  uint32 channels_exist = GLES2Util::GetChannelsForFormat(read_format);
  uint32 channels_needed = GLES2Util::GetChannelsForFormat(format);

  if (!channels_needed ||
      (channels_needed & channels_exist) != channels_needed) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glCopyTexSubImage2D", "incompatible format");
    return;
  }

  if ((channels_needed & (GLES2Util::kDepth | GLES2Util::kStencil)) != 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCopySubImage2D", "can not be used with depth or stencil textures");
    return;
  }

  if (!CheckBoundReadFramebufferColorAttachment("glCopyTexSubImage2D")) {
    return;
  }

  if (FormsTextureCopyingFeedbackLoop(texture_ref, level)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCopyTexSubImage2D", "source and destination textures are the same");
    return;
  }

  if (!CheckBoundFramebuffersValid("glCopyTexSubImage2D")) {
    return;
  }

  ScopedResolvedFrameBufferBinder binder(this, false, true);
  gfx::Size size = GetBoundReadFrameBufferSize();
  GLint copyX = 0;
  GLint copyY = 0;
  GLint copyWidth = 0;
  GLint copyHeight = 0;
  Clip(x, width, size.width(), &copyX, &copyWidth);
  Clip(y, height, size.height(), &copyY, &copyHeight);

  if (xoffset != 0 || yoffset != 0 || width != size.width() ||
      height != size.height()) {
    if (!texture_manager()->ClearTextureLevel(this, texture_ref, target,
                                              level)) {
      LOCAL_SET_GL_ERROR(GL_OUT_OF_MEMORY, "glCopyTexSubImage2D",
                         "dimensions too big");
      return;
    }
  } else {
    // Write all pixels in below.
    texture_manager()->SetLevelCleared(texture_ref, target, level, true);
  }

  if (copyX != x ||
      copyY != y ||
      copyWidth != width ||
      copyHeight != height) {
    // some part was clipped so clear the sub rect.
    uint32 pixels_size = 0;
    if (!GLES2Util::ComputeImageDataSizes(
        width, height, 1, format, type, state_.unpack_alignment, &pixels_size,
        NULL, NULL)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glCopyTexSubImage2D", "dimensions too large");
      return;
    }
    scoped_ptr<char[]> zero(new char[pixels_size]);
    memset(zero.get(), 0, pixels_size);
    ScopedModifyPixels modify(texture_ref);
    glTexSubImage2D(
        target, level, xoffset, yoffset, width, height,
        format, type, zero.get());
  }

  if (copyHeight > 0 && copyWidth > 0) {
    GLint dx = copyX - x;
    GLint dy = copyY - y;
    GLint destX = xoffset + dx;
    GLint destY = yoffset + dy;
    ScopedModifyPixels modify(texture_ref);
    glCopyTexSubImage2D(target, level,
                        destX, destY, copyX, copyY,
                        copyWidth, copyHeight);
  }

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
}

bool GLES2DecoderImpl::ValidateTexSubImage2D(
    error::Error* error,
    const char* function_name,
    GLenum target,
    GLint level,
    GLint xoffset,
    GLint yoffset,
    GLsizei width,
    GLsizei height,
    GLenum format,
    GLenum type,
    const void * data) {
  (*error) = error::kNoError;
  if (!validators_->texture_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(function_name, target, "target");
    return false;
  }
  if (width < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "width < 0");
    return false;
  }
  if (height < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "height < 0");
    return false;
  }
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        function_name, "unknown texture for target");
    return false;
  }
  Texture* texture = texture_ref->texture();
  GLenum current_type = 0;
  GLenum internal_format = 0;
  if (!texture->GetLevelType(target, level, &current_type, &internal_format)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, function_name, "level does not exist.");
    return false;
  }
  if (!texture_manager()->ValidateTextureParameters(state_.GetErrorState(),
      function_name, format, type, internal_format, level)) {
    return false;
  }
  if (type != current_type) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        function_name, "type does not match type of texture.");
    return false;
  }
  if (async_pixel_transfer_manager_->AsyncTransferIsInProgress(texture_ref)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        function_name, "async upload pending for texture");
    return false;
  }
  if (!texture->ValidForTexture(
          target, level, xoffset, yoffset, width, height, type)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "bad dimensions.");
    return false;
  }
  if ((GLES2Util::GetChannelsForFormat(format) &
       (GLES2Util::kDepth | GLES2Util::kStencil)) != 0) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        function_name, "can not supply data for depth or stencil textures");
    return false;
  }
  if (data == NULL) {
    (*error) = error::kOutOfBounds;
    return false;
  }
  return true;
}

error::Error GLES2DecoderImpl::DoTexSubImage2D(
    GLenum target,
    GLint level,
    GLint xoffset,
    GLint yoffset,
    GLsizei width,
    GLsizei height,
    GLenum format,
    GLenum type,
    const void * data) {
  error::Error error = error::kNoError;
  if (!ValidateTexSubImage2D(&error, "glTexSubImage2D", target, level,
      xoffset, yoffset, width, height, format, type, data)) {
    return error;
  }
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  Texture* texture = texture_ref->texture();
  GLsizei tex_width = 0;
  GLsizei tex_height = 0;
  bool ok = texture->GetLevelSize(target, level, &tex_width, &tex_height);
  DCHECK(ok);
  if (xoffset != 0 || yoffset != 0 ||
      width != tex_width || height != tex_height) {
    if (!texture_manager()->ClearTextureLevel(this, texture_ref,
                                              target, level)) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, "glTexSubImage2D", "dimensions too big");
      return error::kNoError;
    }
    ScopedTextureUploadTimer timer(&texture_state_);
    glTexSubImage2D(
        target, level, xoffset, yoffset, width, height, format, type, data);
    return error::kNoError;
  }

  if (!texture_state_.texsubimage2d_faster_than_teximage2d &&
      !texture->IsImmutable() &&
      !texture->HasImages()) {
    ScopedTextureUploadTimer timer(&texture_state_);
    GLenum internal_format;
    GLenum tex_type;
    texture->GetLevelType(target, level, &tex_type, &internal_format);
    // NOTE: In OpenGL ES 2.0 border is always zero. If that changes we'll need
    // to look it up.
    glTexImage2D(
        target, level, internal_format, width, height, 0, format, type, data);
  } else {
    ScopedTextureUploadTimer timer(&texture_state_);
    glTexSubImage2D(
        target, level, xoffset, yoffset, width, height, format, type, data);
  }
  texture_manager()->SetLevelCleared(texture_ref, target, level, true);

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleTexSubImage2D(uint32 immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::TexSubImage2D& c =
      *static_cast<const gles2::cmds::TexSubImage2D*>(cmd_data);
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::HandleTexSubImage2D",
      "width", c.width, "height", c.height);
  GLboolean internal = static_cast<GLboolean>(c.internal);
  if (internal == GL_TRUE && texture_state_.tex_image_2d_failed)
    return error::kNoError;

  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLenum format = static_cast<GLenum>(c.format);
  GLenum type = static_cast<GLenum>(c.type);
  uint32 data_size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, state_.unpack_alignment, &data_size,
      NULL, NULL)) {
    return error::kOutOfBounds;
  }
  const void* pixels = GetSharedMemoryAs<const void*>(
      c.pixels_shm_id, c.pixels_shm_offset, data_size);
  return DoTexSubImage2D(
      target, level, xoffset, yoffset, width, height, format, type, pixels);
}

// TODO(zmo): Remove the below stub once we add the real function binding.
// Currently it's missing due to a gmock limitation.
static void glTexSubImage3D(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset,
    GLsizei height, GLsizei width, GLsizei depth, GLenum format, GLenum type,
    const void* pixels) {
  NOTIMPLEMENTED();
}

error::Error GLES2DecoderImpl::HandleTexSubImage3D(uint32 immediate_data_size,
                                                   const void* cmd_data) {
  // TODO(zmo): Unsafe ES3 API.
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;

  const gles2::cmds::TexSubImage3D& c =
      *static_cast<const gles2::cmds::TexSubImage3D*>(cmd_data);
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::HandleTexSubImage3D",
      "widthXheight", c.width * c.height, "depth", c.depth);
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  GLint zoffset = static_cast<GLint>(c.zoffset);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLsizei depth = static_cast<GLsizei>(c.depth);
  GLenum format = static_cast<GLenum>(c.format);
  GLenum type = static_cast<GLenum>(c.type);
  uint32 data_size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, depth, format, type, state_.unpack_alignment, &data_size,
      NULL, NULL)) {
    return error::kOutOfBounds;
  }
  const void* pixels = GetSharedMemoryAs<const void*>(
      c.pixels_shm_id, c.pixels_shm_offset, data_size);
  glTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height,
                  depth, format, type, pixels);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetVertexAttribPointerv(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetVertexAttribPointerv& c =
      *static_cast<const gles2::cmds::GetVertexAttribPointerv*>(cmd_data);
  GLuint index = static_cast<GLuint>(c.index);
  GLenum pname = static_cast<GLenum>(c.pname);
  typedef cmds::GetVertexAttribPointerv::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
        c.pointer_shm_id, c.pointer_shm_offset, Result::ComputeSize(1));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  if (!validators_->vertex_pointer.IsValid(pname)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glGetVertexAttribPointerv", pname, "pname");
    return error::kNoError;
  }
  if (index >= group_->max_vertex_attribs()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glGetVertexAttribPointerv", "index out of range.");
    return error::kNoError;
  }
  result->SetNumResults(1);
  *result->GetData() =
      state_.vertex_attrib_manager->GetVertexAttrib(index)->offset();
  return error::kNoError;
}

bool GLES2DecoderImpl::GetUniformSetup(GLuint program_id,
                                       GLint fake_location,
                                       uint32 shm_id,
                                       uint32 shm_offset,
                                       error::Error* error,
                                       GLint* real_location,
                                       GLuint* service_id,
                                       void** result_pointer,
                                       GLenum* result_type,
                                       GLsizei* result_size) {
  DCHECK(error);
  DCHECK(service_id);
  DCHECK(result_pointer);
  DCHECK(result_type);
  DCHECK(real_location);
  *error = error::kNoError;
  // Make sure we have enough room for the result on failure.
  SizedResult<GLint>* result;
  result = GetSharedMemoryAs<SizedResult<GLint>*>(
      shm_id, shm_offset, SizedResult<GLint>::ComputeSize(0));
  if (!result) {
    *error = error::kOutOfBounds;
    return false;
  }
  *result_pointer = result;
  // Set the result size to 0 so the client does not have to check for success.
  result->SetNumResults(0);
  Program* program = GetProgramInfoNotShader(program_id, "glGetUniform");
  if (!program) {
    return false;
  }
  if (!program->IsValid()) {
    // Program was not linked successfully. (ie, glLinkProgram)
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glGetUniform", "program not linked");
    return false;
  }
  *service_id = program->service_id();
  GLint array_index = -1;
  const Program::UniformInfo* uniform_info =
      program->GetUniformInfoByFakeLocation(
          fake_location, real_location, &array_index);
  if (!uniform_info) {
    // No such location.
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glGetUniform", "unknown location");
    return false;
  }
  GLenum type = uniform_info->type;
  GLsizei size = GLES2Util::GetGLDataTypeSizeForUniforms(type);
  if (size == 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glGetUniform", "unknown type");
    return false;
  }
  result = GetSharedMemoryAs<SizedResult<GLint>*>(
      shm_id, shm_offset, SizedResult<GLint>::ComputeSizeFromBytes(size));
  if (!result) {
    *error = error::kOutOfBounds;
    return false;
  }
  result->size = size;
  *result_size = size;
  *result_type = type;
  return true;
}

error::Error GLES2DecoderImpl::HandleGetUniformiv(uint32 immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::GetUniformiv& c =
      *static_cast<const gles2::cmds::GetUniformiv*>(cmd_data);
  GLuint program = c.program;
  GLint fake_location = c.location;
  GLuint service_id;
  GLenum result_type;
  GLsizei result_size;
  GLint real_location = -1;
  Error error;
  void* result;
  if (GetUniformSetup(program, fake_location, c.params_shm_id,
                      c.params_shm_offset, &error, &real_location, &service_id,
                      &result, &result_type, &result_size)) {
    glGetUniformiv(
        service_id, real_location,
        static_cast<cmds::GetUniformiv::Result*>(result)->GetData());
  }
  return error;
}

error::Error GLES2DecoderImpl::HandleGetUniformfv(uint32 immediate_data_size,
                                                  const void* cmd_data) {
  const gles2::cmds::GetUniformfv& c =
      *static_cast<const gles2::cmds::GetUniformfv*>(cmd_data);
  GLuint program = c.program;
  GLint fake_location = c.location;
  GLuint service_id;
  GLint real_location = -1;
  Error error;
  typedef cmds::GetUniformfv::Result Result;
  Result* result;
  GLenum result_type;
  GLsizei result_size;
  if (GetUniformSetup(program, fake_location, c.params_shm_id,
                      c.params_shm_offset, &error, &real_location, &service_id,
                      reinterpret_cast<void**>(&result), &result_type,
                      &result_size)) {
    if (result_type == GL_BOOL || result_type == GL_BOOL_VEC2 ||
        result_type == GL_BOOL_VEC3 || result_type == GL_BOOL_VEC4) {
      GLsizei num_values = result_size / sizeof(Result::Type);
      scoped_ptr<GLint[]> temp(new GLint[num_values]);
      glGetUniformiv(service_id, real_location, temp.get());
      GLfloat* dst = result->GetData();
      for (GLsizei ii = 0; ii < num_values; ++ii) {
        dst[ii] = (temp[ii] != 0);
      }
    } else {
      glGetUniformfv(service_id, real_location, result->GetData());
    }
  }
  return error;
}

error::Error GLES2DecoderImpl::HandleGetShaderPrecisionFormat(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetShaderPrecisionFormat& c =
      *static_cast<const gles2::cmds::GetShaderPrecisionFormat*>(cmd_data);
  GLenum shader_type = static_cast<GLenum>(c.shadertype);
  GLenum precision_type = static_cast<GLenum>(c.precisiontype);
  typedef cmds::GetShaderPrecisionFormat::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->success != 0) {
    return error::kInvalidArguments;
  }
  if (!validators_->shader_type.IsValid(shader_type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glGetShaderPrecisionFormat", shader_type, "shader_type");
    return error::kNoError;
  }
  if (!validators_->shader_precision.IsValid(precision_type)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glGetShaderPrecisionFormat", precision_type, "precision_type");
    return error::kNoError;
  }

  result->success = 1;  // true

  GLint range[2] = { 0, 0 };
  GLint precision = 0;
  GetShaderPrecisionFormatImpl(shader_type, precision_type, range, &precision);

  result->min_range = range[0];
  result->max_range = range[1];
  result->precision = precision;

  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetAttachedShaders(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetAttachedShaders& c =
      *static_cast<const gles2::cmds::GetAttachedShaders*>(cmd_data);
  uint32 result_size = c.result_size;
  GLuint program_id = static_cast<GLuint>(c.program);
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetAttachedShaders");
  if (!program) {
    return error::kNoError;
  }
  typedef cmds::GetAttachedShaders::Result Result;
  uint32 max_count = Result::ComputeMaxResults(result_size);
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, Result::ComputeSize(max_count));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  GLsizei count = 0;
  glGetAttachedShaders(
      program->service_id(), max_count, &count, result->GetData());
  for (GLsizei ii = 0; ii < count; ++ii) {
    if (!shader_manager()->GetClientId(result->GetData()[ii],
                                       &result->GetData()[ii])) {
      NOTREACHED();
      return error::kGenericError;
    }
  }
  result->SetNumResults(count);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetActiveUniform(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetActiveUniform& c =
      *static_cast<const gles2::cmds::GetActiveUniform*>(cmd_data);
  GLuint program_id = c.program;
  GLuint index = c.index;
  uint32 name_bucket_id = c.name_bucket_id;
  typedef cmds::GetActiveUniform::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->success != 0) {
    return error::kInvalidArguments;
  }
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetActiveUniform");
  if (!program) {
    return error::kNoError;
  }
  const Program::UniformInfo* uniform_info =
      program->GetUniformInfo(index);
  if (!uniform_info) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glGetActiveUniform", "index out of range");
    return error::kNoError;
  }
  result->success = 1;  // true.
  result->size = uniform_info->size;
  result->type = uniform_info->type;
  Bucket* bucket = CreateBucket(name_bucket_id);
  bucket->SetFromString(uniform_info->name.c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetActiveUniformBlockiv(
    uint32 immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetActiveUniformBlockiv& c =
      *static_cast<const gles2::cmds::GetActiveUniformBlockiv*>(cmd_data);
  GLuint program_id = c.program;
  GLuint index = static_cast<GLuint>(c.index);
  GLenum pname = static_cast<GLenum>(c.pname);
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetActiveUniformBlockiv");
  if (!program) {
    return error::kNoError;
  }
  GLuint service_id = program->service_id();
  GLint link_status = GL_FALSE;
  glGetProgramiv(service_id, GL_LINK_STATUS, &link_status);
  if (link_status != GL_TRUE) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
        "glGetActiveActiveUniformBlockiv", "program not linked");
    return error::kNoError;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetActiveUniformBlockiv");
  GLsizei num_values = 1;
  if (pname == GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES) {
    GLint num = 0;
    glGetActiveUniformBlockiv(
        service_id, index, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &num);
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
      // Assume this will the same error if calling with pname.
      LOCAL_SET_GL_ERROR(error, "GetActiveUniformBlockiv", "");
      return error::kNoError;
    }
    num_values = static_cast<GLsizei>(num);
  }
  typedef cmds::GetActiveUniformBlockiv::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(num_values));
  GLint* params = result ? result->GetData() : NULL;
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  glGetActiveUniformBlockiv(service_id, index, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetActiveUniformBlockiv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetActiveUniformBlockName(
    uint32 immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetActiveUniformBlockName& c =
      *static_cast<const gles2::cmds::GetActiveUniformBlockName*>(cmd_data);
  GLuint program_id = c.program;
  GLuint index = c.index;
  uint32 name_bucket_id = c.name_bucket_id;
  typedef cmds::GetActiveUniformBlockName::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (*result != 0) {
    return error::kInvalidArguments;
  }
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetActiveUniformBlockName");
  if (!program) {
    return error::kNoError;
  }
  GLuint service_id = program->service_id();
  GLint link_status = GL_FALSE;
  glGetProgramiv(service_id, GL_LINK_STATUS, &link_status);
  if (link_status != GL_TRUE) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
        "glGetActiveActiveUniformBlockName", "program not linked");
    return error::kNoError;
  }
  GLint max_length = 0;
  glGetProgramiv(
      service_id, GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH, &max_length);
  // Increase one so &buffer[0] is always valid.
  GLsizei buf_size = static_cast<GLsizei>(max_length) + 1;
  std::vector<char> buffer(buf_size);
  GLsizei length = 0;
  glGetActiveUniformBlockName(
      service_id, index, buf_size, &length, &buffer[0]);
  if (length == 0) {
    *result = 0;
    return error::kNoError;
  }
  *result = 1;
  Bucket* bucket = CreateBucket(name_bucket_id);
  DCHECK_GT(buf_size, length);
  DCHECK_EQ(0, buffer[length]);
  bucket->SetFromString(&buffer[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetActiveUniformsiv(
    uint32 immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetActiveUniformsiv& c =
      *static_cast<const gles2::cmds::GetActiveUniformsiv*>(cmd_data);
  GLuint program_id = c.program;
  GLenum pname = static_cast<GLenum>(c.pname);
  Bucket* bucket = GetBucket(c.indices_bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  GLsizei count = static_cast<GLsizei>(bucket->size() / sizeof(GLuint));
  const GLuint* indices = bucket->GetDataAs<const GLuint*>(0, bucket->size());
  typedef cmds::GetActiveUniformsiv::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.params_shm_id, c.params_shm_offset, Result::ComputeSize(count));
  GLint* params = result ? result->GetData() : NULL;
  if (params == NULL) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetActiveUniformsiv");
  if (!program) {
    return error::kNoError;
  }
  GLuint service_id = program->service_id();
  GLint link_status = GL_FALSE;
  glGetProgramiv(service_id, GL_LINK_STATUS, &link_status);
  if (link_status != GL_TRUE) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
        "glGetActiveUniformsiv", "program not linked");
    return error::kNoError;
  }
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetActiveUniformsiv");
  glGetActiveUniformsiv(service_id, count, indices, pname, params);
  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(count);
  } else {
    LOCAL_SET_GL_ERROR(error, "GetActiveUniformsiv", "");
  }
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetActiveAttrib(uint32 immediate_data_size,
                                                     const void* cmd_data) {
  const gles2::cmds::GetActiveAttrib& c =
      *static_cast<const gles2::cmds::GetActiveAttrib*>(cmd_data);
  GLuint program_id = c.program;
  GLuint index = c.index;
  uint32 name_bucket_id = c.name_bucket_id;
  typedef cmds::GetActiveAttrib::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->success != 0) {
    return error::kInvalidArguments;
  }
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetActiveAttrib");
  if (!program) {
    return error::kNoError;
  }
  const Program::VertexAttrib* attrib_info =
      program->GetAttribInfo(index);
  if (!attrib_info) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glGetActiveAttrib", "index out of range");
    return error::kNoError;
  }
  result->success = 1;  // true.
  result->size = attrib_info->size;
  result->type = attrib_info->type;
  Bucket* bucket = CreateBucket(name_bucket_id);
  bucket->SetFromString(attrib_info->name.c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleShaderBinary(uint32 immediate_data_size,
                                                  const void* cmd_data) {
#if 1  // No binary shader support.
  LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glShaderBinary", "not supported");
  return error::kNoError;
#else
  GLsizei n = static_cast<GLsizei>(c.n);
  if (n < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glShaderBinary", "n < 0");
    return error::kNoError;
  }
  GLsizei length = static_cast<GLsizei>(c.length);
  if (length < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glShaderBinary", "length < 0");
    return error::kNoError;
  }
  uint32 data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
  const GLuint* shaders = GetSharedMemoryAs<const GLuint*>(
      c.shaders_shm_id, c.shaders_shm_offset, data_size);
  GLenum binaryformat = static_cast<GLenum>(c.binaryformat);
  const void* binary = GetSharedMemoryAs<const void*>(
      c.binary_shm_id, c.binary_shm_offset, length);
  if (shaders == NULL || binary == NULL) {
    return error::kOutOfBounds;
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  for (GLsizei ii = 0; ii < n; ++ii) {
    Shader* shader = GetShader(shaders[ii]);
    if (!shader) {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glShaderBinary", "unknown shader");
      return error::kNoError;
    }
    service_ids[ii] = shader->service_id();
  }
  // TODO(gman): call glShaderBinary
  return error::kNoError;
#endif
}

void GLES2DecoderImpl::DoSwapBuffers() {
  bool is_offscreen = !!offscreen_target_frame_buffer_.get();

  int this_frame_number = frame_number_++;
  // TRACE_EVENT for gpu tests:
  TRACE_EVENT_INSTANT2("test_gpu", "SwapBuffersLatency",
                       TRACE_EVENT_SCOPE_THREAD,
                       "GLImpl", static_cast<int>(gfx::GetGLImplementation()),
                       "width", (is_offscreen ? offscreen_size_.width() :
                                 surface_->GetSize().width()));
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::DoSwapBuffers",
               "offscreen", is_offscreen,
               "frame", this_frame_number);
  {
    TRACE_EVENT_SYNTHETIC_DELAY("gpu.PresentingFrame");
  }

  ScopedGPUTrace scoped_gpu_trace(gpu_tracer_.get(), kTraceDecoder,
                                  "gpu_toplevel", "SwapBuffer");

  bool is_tracing;
  TRACE_EVENT_CATEGORY_GROUP_ENABLED(TRACE_DISABLED_BY_DEFAULT("gpu.debug"),
                                     &is_tracing);
  if (is_tracing) {
    ScopedFrameBufferBinder binder(this, GetBackbufferServiceId());
    gpu_state_tracer_->TakeSnapshotWithCurrentFramebuffer(
        is_offscreen ? offscreen_size_ : surface_->GetSize());
  }

  // If offscreen then don't actually SwapBuffers to the display. Just copy
  // the rendered frame to another frame buffer.
  if (is_offscreen) {
    TRACE_EVENT2("gpu", "Offscreen",
        "width", offscreen_size_.width(), "height", offscreen_size_.height());
    if (offscreen_size_ != offscreen_saved_color_texture_->size()) {
      // Workaround for NVIDIA driver bug on OS X; crbug.com/89557,
      // crbug.com/94163. TODO(kbr): figure out reproduction so Apple will
      // fix this.
      if (workarounds().needs_offscreen_buffer_workaround) {
        offscreen_saved_frame_buffer_->Create();
        glFinish();
      }

      // Allocate the offscreen saved color texture.
      DCHECK(offscreen_saved_color_format_);
      offscreen_saved_color_texture_->AllocateStorage(
          offscreen_size_, offscreen_saved_color_format_, false);

      offscreen_saved_frame_buffer_->AttachRenderTexture(
          offscreen_saved_color_texture_.get());
      if (offscreen_size_.width() != 0 && offscreen_size_.height() != 0) {
        if (offscreen_saved_frame_buffer_->CheckStatus() !=
            GL_FRAMEBUFFER_COMPLETE) {
          LOG(ERROR) << "GLES2DecoderImpl::ResizeOffscreenFrameBuffer failed "
                     << "because offscreen saved FBO was incomplete.";
          MarkContextLost(error::kUnknown);
          group_->LoseContexts(error::kUnknown);
          return;
        }

        // Clear the offscreen color texture.
        // TODO(piman): Is this still necessary?
        {
          ScopedFrameBufferBinder binder(this,
                                         offscreen_saved_frame_buffer_->id());
          glClearColor(0, 0, 0, 0);
          state_.SetDeviceColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
          state_.SetDeviceCapabilityState(GL_SCISSOR_TEST, false);
          glClear(GL_COLOR_BUFFER_BIT);
          RestoreClearState();
        }
      }

      UpdateParentTextureInfo();
    }

    if (offscreen_size_.width() == 0 || offscreen_size_.height() == 0)
      return;
    ScopedGLErrorSuppressor suppressor(
        "GLES2DecoderImpl::DoSwapBuffers", GetErrorState());

    if (IsOffscreenBufferMultisampled()) {
      // For multisampled buffers, resolve the frame buffer.
      ScopedResolvedFrameBufferBinder binder(this, true, false);
    } else {
      ScopedFrameBufferBinder binder(this,
                                     offscreen_target_frame_buffer_->id());

      if (offscreen_target_buffer_preserved_) {
        // Copy the target frame buffer to the saved offscreen texture.
        offscreen_saved_color_texture_->Copy(
            offscreen_saved_color_texture_->size(),
            offscreen_saved_color_format_);
      } else {
        // Flip the textures in the parent context via the texture manager.
        if (!!offscreen_saved_color_texture_info_.get())
          offscreen_saved_color_texture_info_->texture()->
              SetServiceId(offscreen_target_color_texture_->id());

        offscreen_saved_color_texture_.swap(offscreen_target_color_texture_);
        offscreen_target_frame_buffer_->AttachRenderTexture(
            offscreen_target_color_texture_.get());
      }

      // Ensure the side effects of the copy are visible to the parent
      // context. There is no need to do this for ANGLE because it uses a
      // single D3D device for all contexts.
      if (!feature_info_->gl_version_info().is_angle)
        glFlush();
    }
  } else {
    if (!surface_->SwapBuffers()) {
      LOG(ERROR) << "Context lost because SwapBuffers failed.";
      if (!CheckResetStatus()) {
        MarkContextLost(error::kUnknown);
        group_->LoseContexts(error::kUnknown);
      }
    }
  }

  // This may be a slow command.  Exit command processing to allow for
  // context preemption and GPU watchdog checks.
  ExitCommandProcessingEarly();
}

void GLES2DecoderImpl::DoSwapInterval(int interval) {
  context_->SetSwapInterval(interval);
}

error::Error GLES2DecoderImpl::HandleEnableFeatureCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::EnableFeatureCHROMIUM& c =
      *static_cast<const gles2::cmds::EnableFeatureCHROMIUM*>(cmd_data);
  Bucket* bucket = GetBucket(c.bucket_id);
  if (!bucket || bucket->size() == 0) {
    return error::kInvalidArguments;
  }
  typedef cmds::EnableFeatureCHROMIUM::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (*result != 0) {
    return error::kInvalidArguments;
  }
  std::string feature_str;
  if (!bucket->GetAsString(&feature_str)) {
    return error::kInvalidArguments;
  }

  // TODO(gman): make this some kind of table to function pointer thingy.
  if (feature_str.compare("pepper3d_allow_buffers_on_multiple_targets") == 0) {
    buffer_manager()->set_allow_buffers_on_multiple_targets(true);
  } else if (feature_str.compare("pepper3d_support_fixed_attribs") == 0) {
    buffer_manager()->set_allow_fixed_attribs(true);
    // TODO(gman): decide how to remove the need for this const_cast.
    // I could make validators_ non const but that seems bad as this is the only
    // place it is needed. I could make some special friend class of validators
    // just to allow this to set them. That seems silly. I could refactor this
    // code to use the extension mechanism or the initialization attributes to
    // turn this feature on. Given that the only real point of this is to make
    // the conformance tests pass and given that there is lots of real work that
    // needs to be done it seems like refactoring for one to one of those
    // methods is a very low priority.
    const_cast<Validators*>(validators_)->vertex_attrib_type.AddValue(GL_FIXED);
  } else if (feature_str.compare("webgl_enable_glsl_webgl_validation") == 0) {
    force_webgl_glsl_validation_ = true;
    InitializeShaderTranslator();
  } else {
    return error::kNoError;
  }

  *result = 1;  // true.
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetRequestableExtensionsCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetRequestableExtensionsCHROMIUM& c =
      *static_cast<const gles2::cmds::GetRequestableExtensionsCHROMIUM*>(
          cmd_data);
  Bucket* bucket = CreateBucket(c.bucket_id);
  scoped_refptr<FeatureInfo> info(new FeatureInfo());
  info->Initialize(disallowed_features_);
  bucket->SetFromString(info->extensions().c_str());
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleRequestExtensionCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::RequestExtensionCHROMIUM& c =
      *static_cast<const gles2::cmds::RequestExtensionCHROMIUM*>(cmd_data);
  Bucket* bucket = GetBucket(c.bucket_id);
  if (!bucket || bucket->size() == 0) {
    return error::kInvalidArguments;
  }
  std::string feature_str;
  if (!bucket->GetAsString(&feature_str)) {
    return error::kInvalidArguments;
  }

  bool desire_webgl_glsl_validation =
      feature_str.find("GL_CHROMIUM_webglsl") != std::string::npos;
  bool desire_standard_derivatives = false;
  bool desire_frag_depth = false;
  bool desire_draw_buffers = false;
  bool desire_shader_texture_lod = false;
  if (force_webgl_glsl_validation_) {
    desire_standard_derivatives =
        feature_str.find("GL_OES_standard_derivatives") != std::string::npos;
    desire_frag_depth =
        feature_str.find("GL_EXT_frag_depth") != std::string::npos;
    desire_draw_buffers =
        feature_str.find("GL_EXT_draw_buffers") != std::string::npos;
    desire_shader_texture_lod =
        feature_str.find("GL_EXT_shader_texture_lod") != std::string::npos;
  }

  if (desire_webgl_glsl_validation != force_webgl_glsl_validation_ ||
      desire_standard_derivatives != derivatives_explicitly_enabled_ ||
      desire_frag_depth != frag_depth_explicitly_enabled_ ||
      desire_draw_buffers != draw_buffers_explicitly_enabled_) {
    force_webgl_glsl_validation_ |= desire_webgl_glsl_validation;
    derivatives_explicitly_enabled_ |= desire_standard_derivatives;
    frag_depth_explicitly_enabled_ |= desire_frag_depth;
    draw_buffers_explicitly_enabled_ |= desire_draw_buffers;
    shader_texture_lod_explicitly_enabled_ |= desire_shader_texture_lod;
    InitializeShaderTranslator();
  }

  UpdateCapabilities();

  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetProgramInfoCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::GetProgramInfoCHROMIUM& c =
      *static_cast<const gles2::cmds::GetProgramInfoCHROMIUM*>(cmd_data);
  GLuint program_id = static_cast<GLuint>(c.program);
  uint32 bucket_id = c.bucket_id;
  Bucket* bucket = CreateBucket(bucket_id);
  bucket->SetSize(sizeof(ProgramInfoHeader));  // in case we fail.
  Program* program = NULL;
  program = GetProgram(program_id);
  if (!program || !program->IsValid()) {
    return error::kNoError;
  }
  program->GetProgramInfo(program_manager(), bucket);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetUniformBlocksCHROMIUM(
    uint32 immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetUniformBlocksCHROMIUM& c =
      *static_cast<const gles2::cmds::GetUniformBlocksCHROMIUM*>(cmd_data);
  GLuint program_id = static_cast<GLuint>(c.program);
  uint32 bucket_id = c.bucket_id;
  Bucket* bucket = CreateBucket(bucket_id);
  bucket->SetSize(sizeof(UniformBlocksHeader));  // in case we fail.
  Program* program = NULL;
  program = GetProgram(program_id);
  if (!program || !program->IsValid()) {
    return error::kNoError;
  }
  program->GetUniformBlocks(bucket);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetUniformsES3CHROMIUM(
    uint32 immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetUniformsES3CHROMIUM& c =
      *static_cast<const gles2::cmds::GetUniformsES3CHROMIUM*>(cmd_data);
  GLuint program_id = static_cast<GLuint>(c.program);
  uint32 bucket_id = c.bucket_id;
  Bucket* bucket = CreateBucket(bucket_id);
  bucket->SetSize(sizeof(UniformsES3Header));  // in case we fail.
  Program* program = NULL;
  program = GetProgram(program_id);
  if (!program || !program->IsValid()) {
    return error::kNoError;
  }
  program->GetUniformsES3(bucket);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetTransformFeedbackVarying(
    uint32 immediate_data_size,
    const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetTransformFeedbackVarying& c =
      *static_cast<const gles2::cmds::GetTransformFeedbackVarying*>(cmd_data);
  GLuint program_id = c.program;
  GLuint index = c.index;
  uint32 name_bucket_id = c.name_bucket_id;
  typedef cmds::GetTransformFeedbackVarying::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result));
  if (!result) {
    return error::kOutOfBounds;
  }
  // Check that the client initialized the result.
  if (result->success != 0) {
    return error::kInvalidArguments;
  }
  Program* program = GetProgramInfoNotShader(
      program_id, "glGetTransformFeedbackVarying");
  if (!program) {
    return error::kNoError;
  }
  GLuint service_id = program->service_id();
  GLint link_status = GL_FALSE;
  glGetProgramiv(service_id, GL_LINK_STATUS, &link_status);
  if (link_status != GL_TRUE) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
        "glGetTransformFeedbackVarying", "program not linked");
    return error::kNoError;
  }
  GLint max_length = 0;
  glGetProgramiv(
      service_id, GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH, &max_length);
  max_length = std::max(1, max_length);
  std::vector<char> buffer(max_length);
  GLsizei length = 0;
  GLsizei size = 0;
  GLenum type = 0;
  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("GetTransformFeedbackVarying");
  glGetTransformFeedbackVarying(
      service_id, index, max_length, &length, &size, &type, &buffer[0]);
  GLenum error = glGetError();
  if (error != GL_NO_ERROR) {
    LOCAL_SET_GL_ERROR(error, "glGetTransformFeedbackVarying", "");
    return error::kNoError;
  }
  result->success = 1;  // true.
  result->size = static_cast<int32_t>(size);
  result->type = static_cast<uint32_t>(type);
  Bucket* bucket = CreateBucket(name_bucket_id);
  DCHECK(length >= 0 && length < max_length);
  buffer[length] = '\0';  // Just to be safe.
  bucket->SetFromString(&buffer[0]);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleGetTransformFeedbackVaryingsCHROMIUM(
    uint32 immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::GetTransformFeedbackVaryingsCHROMIUM& c =
      *static_cast<const gles2::cmds::GetTransformFeedbackVaryingsCHROMIUM*>(
          cmd_data);
  GLuint program_id = static_cast<GLuint>(c.program);
  uint32 bucket_id = c.bucket_id;
  Bucket* bucket = CreateBucket(bucket_id);
  bucket->SetSize(sizeof(TransformFeedbackVaryingsHeader));  // in case we fail.
  Program* program = NULL;
  program = GetProgram(program_id);
  if (!program || !program->IsValid()) {
    return error::kNoError;
  }
  program->GetTransformFeedbackVaryings(bucket);
  return error::kNoError;
}

error::ContextLostReason GLES2DecoderImpl::GetContextLostReason() {
  return context_lost_reason_;
}

error::ContextLostReason GLES2DecoderImpl::GetContextLostReasonFromResetStatus(
    GLenum reset_status) const {
  switch (reset_status) {
    case GL_NO_ERROR:
      // TODO(kbr): improve the precision of the error code in this case.
      // Consider delegating to context for error code if MakeCurrent fails.
      return error::kUnknown;
    case GL_GUILTY_CONTEXT_RESET_ARB:
      return error::kGuilty;
    case GL_INNOCENT_CONTEXT_RESET_ARB:
      return error::kInnocent;
    case GL_UNKNOWN_CONTEXT_RESET_ARB:
      return error::kUnknown;
  }

  NOTREACHED();
  return error::kUnknown;
}

bool GLES2DecoderImpl::WasContextLost() const {
  return context_was_lost_;
}

bool GLES2DecoderImpl::WasContextLostByRobustnessExtension() const {
  return WasContextLost() && reset_by_robustness_extension_;
}

void GLES2DecoderImpl::MarkContextLost(error::ContextLostReason reason) {
  // Only lose the context once.
  if (WasContextLost())
    return;

  // Don't make GL calls in here, the context might not be current.
  context_lost_reason_ = reason;
  current_decoder_error_ = error::kLostContext;
  context_was_lost_ = true;

  // Some D3D drivers cannot recover from device lost in the GPU process
  // sandbox. Allow a new GPU process to launch.
  if (workarounds().exit_on_context_lost) {
    LOG(ERROR) << "Exiting GPU process because some drivers cannot reset"
               << " a D3D device in the Chrome GPU process sandbox.";
#if defined(OS_WIN)
    base::win::SetShouldCrashOnProcessDetach(false);
#endif
    exit(0);
  }
}

bool GLES2DecoderImpl::CheckResetStatus() {
  DCHECK(!WasContextLost());
  DCHECK(context_->IsCurrent(NULL));

  if (IsRobustnessSupported()) {
    // If the reason for the call was a GL error, we can try to determine the
    // reset status more accurately.
    GLenum driver_status = glGetGraphicsResetStatusARB();
    if (driver_status == GL_NO_ERROR)
      return false;

    LOG(ERROR) << (surface_->IsOffscreen() ? "Offscreen" : "Onscreen")
               << " context lost via ARB/EXT_robustness. Reset status = "
               << GLES2Util::GetStringEnum(driver_status);

    // Don't pretend we know which client was responsible.
    if (workarounds().use_virtualized_gl_contexts)
      driver_status = GL_UNKNOWN_CONTEXT_RESET_ARB;

    switch (driver_status) {
      case GL_GUILTY_CONTEXT_RESET_ARB:
        MarkContextLost(error::kGuilty);
        break;
      case GL_INNOCENT_CONTEXT_RESET_ARB:
        MarkContextLost(error::kInnocent);
        break;
      case GL_UNKNOWN_CONTEXT_RESET_ARB:
        MarkContextLost(error::kUnknown);
        break;
      default:
        NOTREACHED();
        return false;
    }
    reset_by_robustness_extension_ = true;
    return true;
  }
  return false;
}

error::Error GLES2DecoderImpl::HandleInsertSyncPointCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  return error::kUnknownCommand;
}

error::Error GLES2DecoderImpl::HandleWaitSyncPointCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::WaitSyncPointCHROMIUM& c =
      *static_cast<const gles2::cmds::WaitSyncPointCHROMIUM*>(cmd_data);
  uint32 sync_point = c.sync_point;
  if (wait_sync_point_callback_.is_null())
    return error::kNoError;

  return wait_sync_point_callback_.Run(sync_point) ?
      error::kNoError : error::kDeferCommandUntilLater;
}

error::Error GLES2DecoderImpl::HandleDiscardBackbufferCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  if (surface_->DeferDraws())
    return error::kDeferCommandUntilLater;
  if (!surface_->SetBackbufferAllocation(false))
    return error::kLostContext;
  backbuffer_needs_clear_bits_ |= GL_COLOR_BUFFER_BIT;
  backbuffer_needs_clear_bits_ |= GL_DEPTH_BUFFER_BIT;
  backbuffer_needs_clear_bits_ |= GL_STENCIL_BUFFER_BIT;
  return error::kNoError;
}

bool GLES2DecoderImpl::GenQueriesEXTHelper(
    GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (query_manager_->GetQuery(client_ids[ii])) {
      return false;
    }
  }
  query_manager_->GenQueries(n, client_ids);
  return true;
}

void GLES2DecoderImpl::DeleteQueriesEXTHelper(
    GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    QueryManager::Query* query = query_manager_->GetQuery(client_ids[ii]);
    if (query && !query->IsDeleted()) {
      ContextState::QueryMap::iterator it =
          state_.current_queries.find(query->target());
      if (it != state_.current_queries.end())
        state_.current_queries.erase(it);

      query->Destroy(true);
    }
    query_manager_->RemoveQuery(client_ids[ii]);
  }
}

bool GLES2DecoderImpl::ProcessPendingQueries(bool did_finish) {
  if (query_manager_.get() == NULL) {
    return false;
  }
  if (!query_manager_->ProcessPendingQueries(did_finish)) {
    current_decoder_error_ = error::kOutOfBounds;
  }
  return query_manager_->HavePendingQueries();
}

// Note that if there are no pending readpixels right now,
// this function will call the callback immediately.
void GLES2DecoderImpl::WaitForReadPixels(base::Closure callback) {
  if (features().use_async_readpixels && !pending_readpixel_fences_.empty()) {
    pending_readpixel_fences_.back()->callbacks.push_back(callback);
  } else {
    callback.Run();
  }
}

void GLES2DecoderImpl::ProcessPendingReadPixels() {
  while (!pending_readpixel_fences_.empty() &&
         pending_readpixel_fences_.front()->fence->HasCompleted()) {
    std::vector<base::Closure> callbacks =
        pending_readpixel_fences_.front()->callbacks;
    pending_readpixel_fences_.pop();
    for (size_t i = 0; i < callbacks.size(); i++) {
      callbacks[i].Run();
    }
  }
}

bool GLES2DecoderImpl::HasMoreIdleWork() {
  return !pending_readpixel_fences_.empty() ||
      async_pixel_transfer_manager_->NeedsProcessMorePendingTransfers();
}

void GLES2DecoderImpl::PerformIdleWork() {
  ProcessPendingReadPixels();
  if (!async_pixel_transfer_manager_->NeedsProcessMorePendingTransfers())
    return;
  async_pixel_transfer_manager_->ProcessMorePendingTransfers();
  ProcessFinishedAsyncTransfers();
}

error::Error GLES2DecoderImpl::HandleBeginQueryEXT(uint32 immediate_data_size,
                                                   const void* cmd_data) {
  const gles2::cmds::BeginQueryEXT& c =
      *static_cast<const gles2::cmds::BeginQueryEXT*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  GLuint client_id = static_cast<GLuint>(c.id);
  int32 sync_shm_id = static_cast<int32>(c.sync_data_shm_id);
  uint32 sync_shm_offset = static_cast<uint32>(c.sync_data_shm_offset);

  switch (target) {
    case GL_COMMANDS_ISSUED_CHROMIUM:
    case GL_LATENCY_QUERY_CHROMIUM:
    case GL_ASYNC_PIXEL_UNPACK_COMPLETED_CHROMIUM:
    case GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM:
    case GL_GET_ERROR_QUERY_CHROMIUM:
      break;
    case GL_COMMANDS_COMPLETED_CHROMIUM:
      if (!features().chromium_sync_query) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, "glBeginQueryEXT",
            "not enabled for commands completed queries");
        return error::kNoError;
      }
      break;
    default:
      if (!features().occlusion_query_boolean) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION, "glBeginQueryEXT",
            "not enabled for occlusion queries");
        return error::kNoError;
      }
      break;
  }

  if (state_.current_queries.find(target) != state_.current_queries.end()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glBeginQueryEXT", "query already in progress");
    return error::kNoError;
  }

  if (client_id == 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBeginQueryEXT", "id is 0");
    return error::kNoError;
  }

  QueryManager::Query* query = query_manager_->GetQuery(client_id);
  if (!query) {
    if (!query_manager_->IsValidQuery(client_id)) {
      LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                         "glBeginQueryEXT",
                         "id not made by glGenQueriesEXT");
      return error::kNoError;
    }
    query = query_manager_->CreateQuery(
        target, client_id, sync_shm_id, sync_shm_offset);
  }

  if (query->target() != target) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glBeginQueryEXT", "target does not match");
    return error::kNoError;
  } else if (query->shm_id() != sync_shm_id ||
             query->shm_offset() != sync_shm_offset) {
    DLOG(ERROR) << "Shared memory used by query not the same as before";
    return error::kInvalidArguments;
  }

  if (!query_manager_->BeginQuery(query)) {
    return error::kOutOfBounds;
  }

  state_.current_queries[target] = query;
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleEndQueryEXT(uint32 immediate_data_size,
                                                 const void* cmd_data) {
  const gles2::cmds::EndQueryEXT& c =
      *static_cast<const gles2::cmds::EndQueryEXT*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  uint32 submit_count = static_cast<GLuint>(c.submit_count);
  ContextState::QueryMap::iterator it = state_.current_queries.find(target);

  if (it == state_.current_queries.end()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, "glEndQueryEXT", "No active query");
    return error::kNoError;
  }

  QueryManager::Query* query = it->second.get();
  if (!query_manager_->EndQuery(query, submit_count)) {
    return error::kOutOfBounds;
  }

  query_manager_->ProcessPendingTransferQueries();

  state_.current_queries.erase(it);
  return error::kNoError;
}

bool GLES2DecoderImpl::GenVertexArraysOESHelper(
    GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (GetVertexAttribManager(client_ids[ii])) {
      return false;
    }
  }

  if (!features().native_vertex_array_object) {
    // Emulated VAO
    for (GLsizei ii = 0; ii < n; ++ii) {
      CreateVertexAttribManager(client_ids[ii], 0, true);
    }
  } else {
    scoped_ptr<GLuint[]> service_ids(new GLuint[n]);

    glGenVertexArraysOES(n, service_ids.get());
    for (GLsizei ii = 0; ii < n; ++ii) {
      CreateVertexAttribManager(client_ids[ii], service_ids[ii], true);
    }
  }

  return true;
}

void GLES2DecoderImpl::DeleteVertexArraysOESHelper(
    GLsizei n, const GLuint* client_ids) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    VertexAttribManager* vao =
        GetVertexAttribManager(client_ids[ii]);
    if (vao && !vao->IsDeleted()) {
      if (state_.vertex_attrib_manager.get() == vao) {
        DoBindVertexArrayOES(0);
      }
      RemoveVertexAttribManager(client_ids[ii]);
    }
  }
}

void GLES2DecoderImpl::DoBindVertexArrayOES(GLuint client_id) {
  VertexAttribManager* vao = NULL;
  if (client_id != 0) {
    vao = GetVertexAttribManager(client_id);
    if (!vao) {
      // Unlike most Bind* methods, the spec explicitly states that VertexArray
      // only allows names that have been previously generated. As such, we do
      // not generate new names here.
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glBindVertexArrayOES", "bad vertex array id.");
      current_decoder_error_ = error::kNoError;
      return;
    }
  } else {
    vao = state_.default_vertex_attrib_manager.get();
  }

  // Only set the VAO state if it's changed
  if (state_.vertex_attrib_manager.get() != vao) {
    state_.vertex_attrib_manager = vao;
    if (!features().native_vertex_array_object) {
      EmulateVertexArrayState();
    } else {
      GLuint service_id = vao->service_id();
      glBindVertexArrayOES(service_id);
    }
  }
}

// Used when OES_vertex_array_object isn't natively supported
void GLES2DecoderImpl::EmulateVertexArrayState() {
  // Setup the Vertex attribute state
  for (uint32 vv = 0; vv < group_->max_vertex_attribs(); ++vv) {
    RestoreStateForAttrib(vv, true);
  }

  // Setup the element buffer
  Buffer* element_array_buffer =
      state_.vertex_attrib_manager->element_array_buffer();
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,
      element_array_buffer ? element_array_buffer->service_id() : 0);
}

bool GLES2DecoderImpl::DoIsVertexArrayOES(GLuint client_id) {
  const VertexAttribManager* vao =
      GetVertexAttribManager(client_id);
  return vao && vao->IsValid() && !vao->IsDeleted();
}

#if defined(OS_MACOSX)
void GLES2DecoderImpl::ReleaseIOSurfaceForTexture(GLuint texture_id) {
  TextureToIOSurfaceMap::iterator it = texture_to_io_surface_map_.find(
      texture_id);
  if (it != texture_to_io_surface_map_.end()) {
    // Found a previous IOSurface bound to this texture; release it.
    IOSurfaceRef surface = it->second;
    CFRelease(surface);
    texture_to_io_surface_map_.erase(it);
  }
}
#endif

void GLES2DecoderImpl::DoTexImageIOSurface2DCHROMIUM(
    GLenum target, GLsizei width, GLsizei height,
    GLuint io_surface_id, GLuint plane) {
#if defined(OS_MACOSX)
  if (gfx::GetGLImplementation() != gfx::kGLImplementationDesktopGL) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTexImageIOSurface2DCHROMIUM", "only supported on desktop GL.");
    return;
  }

  if (target != GL_TEXTURE_RECTANGLE_ARB) {
    // This might be supported in the future, and if we could require
    // support for binding an IOSurface to a NPOT TEXTURE_2D texture, we
    // could delete a lot of code. For now, perform strict validation so we
    // know what's going on.
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTexImageIOSurface2DCHROMIUM",
        "requires TEXTURE_RECTANGLE_ARB target");
    return;
  }

  // Default target might be conceptually valid, but disallow it to avoid
  // accidents.
  TextureRef* texture_ref =
      texture_manager()->GetTextureInfoForTargetUnlessDefault(&state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTexImageIOSurface2DCHROMIUM", "no rectangle texture bound");
    return;
  }

  // Look up the new IOSurface. Note that because of asynchrony
  // between processes this might fail; during live resizing the
  // plugin process might allocate and release an IOSurface before
  // this process gets a chance to look it up. Hold on to any old
  // IOSurface in this case.
  IOSurfaceRef surface = IOSurfaceLookup(io_surface_id);
  if (!surface) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTexImageIOSurface2DCHROMIUM", "no IOSurface with the given ID");
    return;
  }

  // Release any IOSurface previously bound to this texture.
  ReleaseIOSurfaceForTexture(texture_ref->service_id());

  // Make sure we release the IOSurface even if CGLTexImageIOSurface2D fails.
  texture_to_io_surface_map_.insert(
      std::make_pair(texture_ref->service_id(), surface));

  CGLContextObj context =
      static_cast<CGLContextObj>(context_->GetHandle());

  CGLError err = CGLTexImageIOSurface2D(
      context,
      target,
      GL_RGBA,
      width,
      height,
      GL_BGRA,
      GL_UNSIGNED_INT_8_8_8_8_REV,
      surface,
      plane);

  if (err != kCGLNoError) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTexImageIOSurface2DCHROMIUM", "error in CGLTexImageIOSurface2D");
    return;
  }

  texture_manager()->SetLevelInfo(
      texture_ref, target, 0, GL_RGBA, width, height, 1, 0,
      GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, true);

#else
  LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
             "glTexImageIOSurface2DCHROMIUM", "not supported.");
#endif
}

static GLenum ExtractFormatFromStorageFormat(GLenum internalformat) {
  switch (internalformat) {
    case GL_RGB565:
      return GL_RGB;
    case GL_RGBA4:
      return GL_RGBA;
    case GL_RGB5_A1:
      return GL_RGBA;
    case GL_RGB8_OES:
      return GL_RGB;
    case GL_RGBA8_OES:
      return GL_RGBA;
    case GL_LUMINANCE8_ALPHA8_EXT:
      return GL_LUMINANCE_ALPHA;
    case GL_LUMINANCE8_EXT:
      return GL_LUMINANCE;
    case GL_ALPHA8_EXT:
      return GL_ALPHA;
    case GL_RGBA32F_EXT:
      return GL_RGBA;
    case GL_RGB32F_EXT:
      return GL_RGB;
    case GL_ALPHA32F_EXT:
      return GL_ALPHA;
    case GL_LUMINANCE32F_EXT:
      return GL_LUMINANCE;
    case GL_LUMINANCE_ALPHA32F_EXT:
      return GL_LUMINANCE_ALPHA;
    case GL_RGBA16F_EXT:
      return GL_RGBA;
    case GL_RGB16F_EXT:
      return GL_RGB;
    case GL_ALPHA16F_EXT:
      return GL_ALPHA;
    case GL_LUMINANCE16F_EXT:
      return GL_LUMINANCE;
    case GL_LUMINANCE_ALPHA16F_EXT:
      return GL_LUMINANCE_ALPHA;
    case GL_BGRA8_EXT:
      return GL_BGRA_EXT;
    case GL_SRGB8_ALPHA8_EXT:
      return GL_SRGB_ALPHA_EXT;
    default:
      return GL_NONE;
  }
}

bool GLES2DecoderImpl::ValidateCopyTextureCHROMIUM(
    const char* function_name,
    GLenum target,
    TextureRef* source_texture_ref,
    TextureRef* dest_texture_ref,
    GLenum dest_internal_format) {
  if (!source_texture_ref || !dest_texture_ref) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "unknown texture id");
    return false;
  }

  if (GL_TEXTURE_2D != target) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name,
                       "invalid texture target");
    return false;
  }

  Texture* source_texture = source_texture_ref->texture();
  Texture* dest_texture = dest_texture_ref->texture();
  if (source_texture == dest_texture) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name,
                       "source and destination textures are the same");
    return false;
  }

  if (dest_texture->target() != GL_TEXTURE_2D ||
      (source_texture->target() != GL_TEXTURE_2D &&
       source_texture->target() != GL_TEXTURE_RECTANGLE_ARB &&
       source_texture->target() != GL_TEXTURE_EXTERNAL_OES)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name,
                       "invalid texture target binding");
    return false;
  }

  GLenum source_type = 0;
  GLenum source_internal_format = 0;
  source_texture->GetLevelType(source_texture->target(), 0, &source_type,
                               &source_internal_format);

  // The destination format should be GL_RGB, or GL_RGBA. GL_ALPHA,
  // GL_LUMINANCE, and GL_LUMINANCE_ALPHA are not supported because they are not
  // renderable on some platforms.
  bool valid_dest_format = dest_internal_format == GL_RGB ||
                           dest_internal_format == GL_RGBA ||
                           dest_internal_format == GL_BGRA_EXT;
  bool valid_source_format = source_internal_format == GL_ALPHA ||
                             source_internal_format == GL_RGB ||
                             source_internal_format == GL_RGBA ||
                             source_internal_format == GL_LUMINANCE ||
                             source_internal_format == GL_LUMINANCE_ALPHA ||
                             source_internal_format == GL_BGRA_EXT;
  if (!valid_source_format || !valid_dest_format) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name,
                       "invalid internal format");
    return false;
  }
  return true;
}

void GLES2DecoderImpl::DoCopyTextureCHROMIUM(GLenum target,
                                             GLuint source_id,
                                             GLuint dest_id,
                                             GLenum internal_format,
                                             GLenum dest_type) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::DoCopyTextureCHROMIUM");

  TextureRef* source_texture_ref = GetTexture(source_id);
  TextureRef* dest_texture_ref = GetTexture(dest_id);
  Texture* source_texture = source_texture_ref->texture();
  Texture* dest_texture = dest_texture_ref->texture();
  int source_width = 0;
  int source_height = 0;
  gfx::GLImage* image =
      source_texture->GetLevelImage(source_texture->target(), 0);
  if (image) {
    gfx::Size size = image->GetSize();
    source_width = size.width();
    source_height = size.height();
    if (source_width <= 0 || source_height <= 0) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE,
          "glCopyTextureChromium", "invalid image size");
      return;
    }
  } else {
    if (!source_texture->GetLevelSize(
             source_texture->target(), 0, &source_width, &source_height)) {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE,
                         "glCopyTextureChromium",
                         "source texture has no level 0");
      return;
    }

    // Check that this type of texture is allowed.
    if (!texture_manager()->ValidForTarget(source_texture->target(), 0,
                                           source_width, source_height, 1)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_VALUE, "glCopyTextureCHROMIUM", "Bad dimensions");
      return;
    }
  }

  GLenum source_type = 0;
  GLenum source_internal_format = 0;
  source_texture->GetLevelType(
      source_texture->target(), 0, &source_type, &source_internal_format);

  if (dest_texture->IsImmutable()) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glCopyTextureCHROMIUM",
                       "texture is immutable");
    return;
  }

  if (!ValidateCopyTextureCHROMIUM("glCopyTextureCHROMIUM", target,
                                   source_texture_ref, dest_texture_ref,
                                   internal_format)) {
    return;
  }

  // Clear the source texture if necessary.
  if (!texture_manager()->ClearTextureLevel(this, source_texture_ref,
                                            source_texture->target(), 0)) {
    LOCAL_SET_GL_ERROR(GL_OUT_OF_MEMORY, "glCopyTextureCHROMIUM",
                       "dimensions too big");
    return;
  }

  // Defer initializing the CopyTextureCHROMIUMResourceManager until it is
  // needed because it takes 10s of milliseconds to initialize.
  if (!copy_texture_CHROMIUM_.get()) {
    LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glCopyTextureCHROMIUM");
    copy_texture_CHROMIUM_.reset(new CopyTextureCHROMIUMResourceManager());
    copy_texture_CHROMIUM_->Initialize(this);
    RestoreCurrentFramebufferBindings();
    if (LOCAL_PEEK_GL_ERROR("glCopyTextureCHROMIUM") != GL_NO_ERROR)
      return;
  }

  GLenum dest_type_previous = dest_type;
  GLenum dest_internal_format = internal_format;
  int dest_width = 0;
  int dest_height = 0;
  bool dest_level_defined =
      dest_texture->GetLevelSize(GL_TEXTURE_2D, 0, &dest_width, &dest_height);

  if (dest_level_defined) {
    dest_texture->GetLevelType(GL_TEXTURE_2D, 0, &dest_type_previous,
                               &dest_internal_format);
  }

  // Resize the destination texture to the dimensions of the source texture.
  if (!dest_level_defined || dest_width != source_width ||
      dest_height != source_height ||
      dest_internal_format != internal_format ||
      dest_type_previous != dest_type) {
    // Ensure that the glTexImage2D succeeds.
    LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glCopyTextureCHROMIUM");
    glBindTexture(GL_TEXTURE_2D, dest_texture->service_id());
    glTexImage2D(GL_TEXTURE_2D, 0, internal_format, source_width, source_height,
                 0, internal_format, dest_type, NULL);
    GLenum error = LOCAL_PEEK_GL_ERROR("glCopyTextureCHROMIUM");
    if (error != GL_NO_ERROR) {
      RestoreCurrentTextureBindings(&state_, GL_TEXTURE_2D);
      return;
    }

    texture_manager()->SetLevelInfo(
        dest_texture_ref, GL_TEXTURE_2D, 0, internal_format, source_width,
        source_height, 1, 0, internal_format, dest_type, true);
  } else {
    texture_manager()->SetLevelCleared(dest_texture_ref, GL_TEXTURE_2D, 0,
                                       true);
  }

  ScopedModifyPixels modify(dest_texture_ref);

  // Try using GLImage::CopyTexImage when possible.
  bool unpack_premultiply_alpha_change =
      unpack_premultiply_alpha_ ^ unpack_unpremultiply_alpha_;
  if (image && !unpack_flip_y_ && !unpack_premultiply_alpha_change) {
    glBindTexture(GL_TEXTURE_2D, dest_texture->service_id());
    if (image->CopyTexImage(GL_TEXTURE_2D))
      return;
  }

  DoWillUseTexImageIfNeeded(source_texture, source_texture->target());

  // GL_TEXTURE_EXTERNAL_OES texture requires apply a transform matrix
  // before presenting.
  if (source_texture->target() == GL_TEXTURE_EXTERNAL_OES) {
    // TODO(hkuang): get the StreamTexture transform matrix in GPU process
    // instead of using kIdentityMatrix crbug.com/226218.
    copy_texture_CHROMIUM_->DoCopyTextureWithTransform(
        this, source_texture->target(), source_texture->service_id(),
        dest_texture->service_id(), source_width, source_height, unpack_flip_y_,
        unpack_premultiply_alpha_, unpack_unpremultiply_alpha_,
        kIdentityMatrix);
  } else {
    copy_texture_CHROMIUM_->DoCopyTexture(
        this, source_texture->target(), source_texture->service_id(),
        source_internal_format, dest_texture->service_id(), internal_format,
        source_width, source_height, unpack_flip_y_, unpack_premultiply_alpha_,
        unpack_unpremultiply_alpha_);
  }

  DoDidUseTexImageIfNeeded(source_texture, source_texture->target());
}

void GLES2DecoderImpl::DoCopySubTextureCHROMIUM(GLenum target,
                                                GLuint source_id,
                                                GLuint dest_id,
                                                GLint xoffset,
                                                GLint yoffset) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::DoCopySubTextureCHROMIUM");

  TextureRef* source_texture_ref = GetTexture(source_id);
  TextureRef* dest_texture_ref = GetTexture(dest_id);
  Texture* source_texture = source_texture_ref->texture();
  Texture* dest_texture = dest_texture_ref->texture();
  int source_width = 0;
  int source_height = 0;
  gfx::GLImage* image =
      source_texture->GetLevelImage(source_texture->target(), 0);
  if (image) {
    gfx::Size size = image->GetSize();
    source_width = size.width();
    source_height = size.height();
    if (source_width <= 0 || source_height <= 0) {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopySubTextureCHROMIUM",
                         "invalid image size");
      return;
    }
  } else {
    if (!source_texture->GetLevelSize(source_texture->target(), 0,
                                      &source_width, &source_height)) {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopySubTextureCHROMIUM",
                         "source texture has no level 0");
      return;
    }

    // Check that this type of texture is allowed.
    if (!texture_manager()->ValidForTarget(source_texture->target(), 0,
                                           source_width, source_height, 1)) {
      LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopySubTextureCHROMIUM",
                         "source texture bad dimensions");
      return;
    }
  }

  GLenum source_type = 0;
  GLenum source_internal_format = 0;
  source_texture->GetLevelType(source_texture->target(), 0, &source_type,
                               &source_internal_format);
  GLenum dest_type = 0;
  GLenum dest_internal_format = 0;
  bool dest_level_defined = dest_texture->GetLevelType(
      dest_texture->target(), 0, &dest_type, &dest_internal_format);
  if (!dest_level_defined) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glCopySubTextureCHROMIUM",
                       "destination texture is not defined");
    return;
  }
  if (!dest_texture->ValidForTexture(dest_texture->target(), 0, xoffset,
                                     yoffset, source_width, source_height,
                                     dest_type)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "glCopySubTextureCHROMIUM",
                       "destination texture bad dimensions.");
    return;
  }

  if (!ValidateCopyTextureCHROMIUM("glCopySubTextureCHROMIUM", target,
                                   source_texture_ref, dest_texture_ref,
                                   dest_internal_format)) {
    return;
  }

  // Clear the source texture if necessary.
  if (!texture_manager()->ClearTextureLevel(this, source_texture_ref,
                                            source_texture->target(), 0)) {
    LOCAL_SET_GL_ERROR(GL_OUT_OF_MEMORY, "glCopySubTextureCHROMIUM",
                       "source texture dimensions too big");
    return;
  }

  // Defer initializing the CopyTextureCHROMIUMResourceManager until it is
  // needed because it takes 10s of milliseconds to initialize.
  if (!copy_texture_CHROMIUM_.get()) {
    LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glCopySubTextureCHROMIUM");
    copy_texture_CHROMIUM_.reset(new CopyTextureCHROMIUMResourceManager());
    copy_texture_CHROMIUM_->Initialize(this);
    RestoreCurrentFramebufferBindings();
    if (LOCAL_PEEK_GL_ERROR("glCopySubTextureCHROMIUM") != GL_NO_ERROR)
      return;
  }

  int dest_width = 0;
  int dest_height = 0;
  bool ok =
      dest_texture->GetLevelSize(GL_TEXTURE_2D, 0, &dest_width, &dest_height);
  DCHECK(ok);
  if (xoffset != 0 || yoffset != 0 || source_width != dest_width ||
      source_height != dest_height) {
    if (!texture_manager()->ClearTextureLevel(this, dest_texture_ref, target,
                                              0)) {
      LOCAL_SET_GL_ERROR(GL_OUT_OF_MEMORY, "glCopySubTextureCHROMIUM",
                         "destination texture dimensions too big");
      return;
    }
  } else {
    texture_manager()->SetLevelCleared(dest_texture_ref, GL_TEXTURE_2D, 0,
                                       true);
  }

  ScopedModifyPixels modify(dest_texture_ref);

  // Try using GLImage::CopyTexSubImage when possible.
  bool unpack_premultiply_alpha_change =
      unpack_premultiply_alpha_ ^ unpack_unpremultiply_alpha_;
  if (image && !unpack_flip_y_ && !unpack_premultiply_alpha_change &&
      !xoffset && !yoffset) {
    glBindTexture(GL_TEXTURE_2D, dest_texture->service_id());
    if (image->CopyTexImage(GL_TEXTURE_2D))
      return;
  }

  DoWillUseTexImageIfNeeded(source_texture, source_texture->target());

  // GL_TEXTURE_EXTERNAL_OES texture requires apply a transform matrix
  // before presenting.
  if (source_texture->target() == GL_TEXTURE_EXTERNAL_OES) {
    // TODO(hkuang): get the StreamTexture transform matrix in GPU process
    // instead of using kIdentityMatrix crbug.com/226218.
    copy_texture_CHROMIUM_->DoCopySubTextureWithTransform(
        this, source_texture->target(), source_texture->service_id(),
        dest_texture->service_id(), xoffset, yoffset, dest_width, dest_height,
        source_width, source_height, unpack_flip_y_, unpack_premultiply_alpha_,
        unpack_unpremultiply_alpha_, kIdentityMatrix);
  } else {
    copy_texture_CHROMIUM_->DoCopySubTexture(
        this, source_texture->target(), source_texture->service_id(),
        source_internal_format, dest_texture->service_id(),
        dest_internal_format, xoffset, yoffset, dest_width, dest_height,
        source_width, source_height, unpack_flip_y_, unpack_premultiply_alpha_,
        unpack_unpremultiply_alpha_);
  }

  DoDidUseTexImageIfNeeded(source_texture, source_texture->target());
}

static GLenum ExtractTypeFromStorageFormat(GLenum internalformat) {
  switch (internalformat) {
    case GL_RGB565:
      return GL_UNSIGNED_SHORT_5_6_5;
    case GL_RGBA4:
      return GL_UNSIGNED_SHORT_4_4_4_4;
    case GL_RGB5_A1:
      return GL_UNSIGNED_SHORT_5_5_5_1;
    case GL_RGB8_OES:
      return GL_UNSIGNED_BYTE;
    case GL_RGBA8_OES:
      return GL_UNSIGNED_BYTE;
    case GL_LUMINANCE8_ALPHA8_EXT:
      return GL_UNSIGNED_BYTE;
    case GL_LUMINANCE8_EXT:
      return GL_UNSIGNED_BYTE;
    case GL_ALPHA8_EXT:
      return GL_UNSIGNED_BYTE;
    case GL_RGBA32F_EXT:
      return GL_FLOAT;
    case GL_RGB32F_EXT:
      return GL_FLOAT;
    case GL_ALPHA32F_EXT:
      return GL_FLOAT;
    case GL_LUMINANCE32F_EXT:
      return GL_FLOAT;
    case GL_LUMINANCE_ALPHA32F_EXT:
      return GL_FLOAT;
    case GL_RGBA16F_EXT:
      return GL_HALF_FLOAT_OES;
    case GL_RGB16F_EXT:
      return GL_HALF_FLOAT_OES;
    case GL_ALPHA16F_EXT:
      return GL_HALF_FLOAT_OES;
    case GL_LUMINANCE16F_EXT:
      return GL_HALF_FLOAT_OES;
    case GL_LUMINANCE_ALPHA16F_EXT:
      return GL_HALF_FLOAT_OES;
    case GL_BGRA8_EXT:
      return GL_UNSIGNED_BYTE;
    default:
      return GL_NONE;
  }
}

void GLES2DecoderImpl::DoTexStorage2DEXT(
    GLenum target,
    GLint levels,
    GLenum internal_format,
    GLsizei width,
    GLsizei height) {
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::DoTexStorage2DEXT",
      "width", width, "height", height);
  if (!texture_manager()->ValidForTarget(target, 0, width, height, 1) ||
      TextureManager::ComputeMipMapCount(target, width, height, 1) < levels) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE, "glTexStorage2DEXT", "dimensions out of range");
    return;
  }
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTexStorage2DEXT", "unknown texture for target");
    return;
  }
  Texture* texture = texture_ref->texture();
  if (texture->IsAttachedToFramebuffer()) {
    framebuffer_state_.clear_state_dirty = true;
  }
  if (texture->IsImmutable()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTexStorage2DEXT", "texture is immutable");
    return;
  }

  GLenum format = ExtractFormatFromStorageFormat(internal_format);
  GLenum type = ExtractTypeFromStorageFormat(internal_format);

  {
    GLsizei level_width = width;
    GLsizei level_height = height;
    uint32 estimated_size = 0;
    for (int ii = 0; ii < levels; ++ii) {
      uint32 level_size = 0;
      if (!GLES2Util::ComputeImageDataSizes(
          level_width, level_height, 1, format, type, state_.unpack_alignment,
          &estimated_size, NULL, NULL) ||
          !SafeAddUint32(estimated_size, level_size, &estimated_size)) {
        LOCAL_SET_GL_ERROR(
            GL_OUT_OF_MEMORY, "glTexStorage2DEXT", "dimensions too large");
        return;
      }
      level_width = std::max(1, level_width >> 1);
      level_height = std::max(1, level_height >> 1);
    }
    if (!EnsureGPUMemoryAvailable(estimated_size)) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY, "glTexStorage2DEXT", "out of memory");
      return;
    }
  }

  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("glTexStorage2DEXT");
  glTexStorage2DEXT(target, levels, internal_format, width, height);
  GLenum error = LOCAL_PEEK_GL_ERROR("glTexStorage2DEXT");
  if (error == GL_NO_ERROR) {
    GLsizei level_width = width;
    GLsizei level_height = height;
    for (int ii = 0; ii < levels; ++ii) {
      texture_manager()->SetLevelInfo(
          texture_ref, target, ii, format,
          level_width, level_height, 1, 0, format, type, false);
      level_width = std::max(1, level_width >> 1);
      level_height = std::max(1, level_height >> 1);
    }
    texture->SetImmutable(true);
  }
}

error::Error GLES2DecoderImpl::HandleGenMailboxCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  return error::kUnknownCommand;
}

void GLES2DecoderImpl::DoProduceTextureCHROMIUM(GLenum target,
                                                const GLbyte* data) {
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::DoProduceTextureCHROMIUM",
      "context", logger_.GetLogPrefix(),
      "mailbox[0]", static_cast<unsigned char>(data[0]));

  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  ProduceTextureRef("glProduceTextureCHROMIUM", texture_ref, target, data);
}

void GLES2DecoderImpl::DoProduceTextureDirectCHROMIUM(GLuint client_id,
    GLenum target, const GLbyte* data) {
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::DoProduceTextureDirectCHROMIUM",
      "context", logger_.GetLogPrefix(),
      "mailbox[0]", static_cast<unsigned char>(data[0]));

  ProduceTextureRef("glProduceTextureDirectCHROMIUM", GetTexture(client_id),
      target, data);
}

void GLES2DecoderImpl::ProduceTextureRef(std::string func_name,
    TextureRef* texture_ref, GLenum target, const GLbyte* data) {
  const Mailbox& mailbox = *reinterpret_cast<const Mailbox*>(data);
  DLOG_IF(ERROR, !mailbox.Verify()) << func_name << " was passed a "
                                       "mailbox that was not generated by "
                                       "GenMailboxCHROMIUM.";

  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, func_name.c_str(), "unknown texture for target");
    return;
  }

  Texture* produced = texture_manager()->Produce(texture_ref);
  if (!produced) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, func_name.c_str(), "invalid texture");
    return;
  }

  if (produced->target() != target) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION, func_name.c_str(), "invalid target");
    return;
  }

  group_->mailbox_manager()->ProduceTexture(mailbox, produced);
}

void GLES2DecoderImpl::DoConsumeTextureCHROMIUM(GLenum target,
                                                const GLbyte* data) {
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::DoConsumeTextureCHROMIUM",
      "context", logger_.GetLogPrefix(),
      "mailbox[0]", static_cast<unsigned char>(data[0]));
  const Mailbox& mailbox = *reinterpret_cast<const Mailbox*>(data);
  DLOG_IF(ERROR, !mailbox.Verify()) << "ConsumeTextureCHROMIUM was passed a "
                                       "mailbox that was not generated by "
                                       "GenMailboxCHROMIUM.";

  scoped_refptr<TextureRef> texture_ref =
      texture_manager()->GetTextureInfoForTargetUnlessDefault(&state_, target);
  if (!texture_ref.get()) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glConsumeTextureCHROMIUM",
                       "unknown texture for target");
    return;
  }
  GLuint client_id = texture_ref->client_id();
  if (!client_id) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glConsumeTextureCHROMIUM", "unknown texture for target");
    return;
  }
  Texture* texture = group_->mailbox_manager()->ConsumeTexture(mailbox);
  if (!texture) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glConsumeTextureCHROMIUM", "invalid mailbox name");
    return;
  }
  if (texture->target() != target) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glConsumeTextureCHROMIUM", "invalid target");
    return;
  }

  DeleteTexturesHelper(1, &client_id);
  texture_ref = texture_manager()->Consume(client_id, texture);
  glBindTexture(target, texture_ref->service_id());

  TextureUnit& unit = state_.texture_units[state_.active_texture_unit];
  unit.bind_target = target;
  switch (target) {
    case GL_TEXTURE_2D:
      unit.bound_texture_2d = texture_ref;
      break;
    case GL_TEXTURE_CUBE_MAP:
      unit.bound_texture_cube_map = texture_ref;
      break;
    case GL_TEXTURE_EXTERNAL_OES:
      unit.bound_texture_external_oes = texture_ref;
      break;
    case GL_TEXTURE_RECTANGLE_ARB:
      unit.bound_texture_rectangle_arb = texture_ref;
      break;
    default:
      NOTREACHED();  // Validation should prevent us getting here.
      break;
  }
}

void GLES2DecoderImpl::EnsureTextureForClientId(
    GLenum target,
    GLuint client_id) {
  TextureRef* texture_ref = GetTexture(client_id);
  if (!texture_ref) {
    GLuint service_id;
    glGenTextures(1, &service_id);
    DCHECK_NE(0u, service_id);
    texture_ref = CreateTexture(client_id, service_id);
    texture_manager()->SetTarget(texture_ref, target);
    glBindTexture(target, service_id);
    RestoreCurrentTextureBindings(&state_, target);
  }
}

// If CreateAndConsumeTexture fails we still need to ensure that the client_id
// provided is associated with a service_id/TextureRef for consistency, even if
// the resulting texture is incomplete.
error::Error GLES2DecoderImpl::HandleCreateAndConsumeTextureCHROMIUMImmediate(
    uint32_t immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::CreateAndConsumeTextureCHROMIUMImmediate& c =
      *static_cast<
          const gles2::cmds::CreateAndConsumeTextureCHROMIUMImmediate*>(
          cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(GLbyte), 64, &data_size)) {
    return error::kOutOfBounds;
  }
  if (data_size > immediate_data_size) {
    return error::kOutOfBounds;
  }
  const GLbyte* mailbox =
      GetImmediateDataAs<const GLbyte*>(c, data_size, immediate_data_size);
  if (!validators_->texture_bind_target.IsValid(target)) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(
        "glCreateAndConsumeTextureCHROMIUM", target, "target");
    return error::kNoError;
  }
  if (mailbox == NULL) {
    return error::kOutOfBounds;
  }
  uint32_t client_id = c.client_id;
  DoCreateAndConsumeTextureCHROMIUM(target, mailbox, client_id);
  return error::kNoError;
}

void GLES2DecoderImpl::DoCreateAndConsumeTextureCHROMIUM(GLenum target,
    const GLbyte* data, GLuint client_id) {
  TRACE_EVENT2("gpu", "GLES2DecoderImpl::DoCreateAndConsumeTextureCHROMIUM",
      "context", logger_.GetLogPrefix(),
      "mailbox[0]", static_cast<unsigned char>(data[0]));
  const Mailbox& mailbox = *reinterpret_cast<const Mailbox*>(data);
  DLOG_IF(ERROR, !mailbox.Verify()) << "CreateAndConsumeTextureCHROMIUM was "
                                       "passed a mailbox that was not "
                                       "generated by GenMailboxCHROMIUM.";

  TextureRef* texture_ref = GetTexture(client_id);
  if (texture_ref) {
    // No need to call EnsureTextureForClientId here, the client_id already has
    // an associated texture.
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCreateAndConsumeTextureCHROMIUM", "client id already in use");
    return;
  }
  Texture* texture = group_->mailbox_manager()->ConsumeTexture(mailbox);
  if (!texture) {
    EnsureTextureForClientId(target, client_id);
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCreateAndConsumeTextureCHROMIUM", "invalid mailbox name");
    return;
  }

  if (texture->target() != target) {
    EnsureTextureForClientId(target, client_id);
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glCreateAndConsumeTextureCHROMIUM", "invalid target");
    return;
  }

  texture_ref = texture_manager()->Consume(client_id, texture);
}

bool GLES2DecoderImpl::DoIsValuebufferCHROMIUM(GLuint client_id) {
  const Valuebuffer* valuebuffer = GetValuebuffer(client_id);
  return valuebuffer && valuebuffer->IsValid();
}

void GLES2DecoderImpl::DoBindValueBufferCHROMIUM(GLenum target,
                                                 GLuint client_id) {
  Valuebuffer* valuebuffer = NULL;
  if (client_id != 0) {
    valuebuffer = GetValuebuffer(client_id);
    if (!valuebuffer) {
      if (!group_->bind_generates_resource()) {
        LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "glBindValuebufferCHROMIUM",
                           "id not generated by glBindValuebufferCHROMIUM");
        return;
      }

      // It's a new id so make a valuebuffer for it.
      CreateValuebuffer(client_id);
      valuebuffer = GetValuebuffer(client_id);
    }
    valuebuffer->MarkAsValid();
  }
  state_.bound_valuebuffer = valuebuffer;
}

void GLES2DecoderImpl::DoSubscribeValueCHROMIUM(GLenum target,
                                                GLenum subscription) {
  if (!CheckCurrentValuebuffer("glSubscribeValueCHROMIUM")) {
    return;
  }
  state_.bound_valuebuffer.get()->AddSubscription(subscription);
}

void GLES2DecoderImpl::DoPopulateSubscribedValuesCHROMIUM(GLenum target) {
  if (!CheckCurrentValuebuffer("glPopulateSubscribedValuesCHROMIUM")) {
    return;
  }
  valuebuffer_manager()->UpdateValuebufferState(state_.bound_valuebuffer.get());
}

void GLES2DecoderImpl::DoUniformValueBufferCHROMIUM(GLint location,
                                                    GLenum target,
                                                    GLenum subscription) {
  if (!CheckCurrentValuebufferForSubscription(
          subscription, "glPopulateSubscribedValuesCHROMIUM")) {
    return;
  }
  if (!CheckSubscriptionTarget(location, subscription,
                               "glPopulateSubscribedValuesCHROMIUM")) {
    return;
  }
  const ValueState* state =
      state_.bound_valuebuffer.get()->GetState(subscription);
  if (state) {
    switch (subscription) {
      case GL_MOUSE_POSITION_CHROMIUM:
        DoUniform2iv(location, 1, state->int_value);
        break;
      default:
        NOTREACHED() << "Unhandled uniform subscription target "
                     << subscription;
        break;
    }
  }
}

void GLES2DecoderImpl::DoInsertEventMarkerEXT(
    GLsizei length, const GLchar* marker) {
  if (!marker) {
    marker = "";
  }
  debug_marker_manager_.SetMarker(
      length ? std::string(marker, length) : std::string(marker));
}

void GLES2DecoderImpl::DoPushGroupMarkerEXT(
    GLsizei length, const GLchar* marker) {
  if (!marker) {
    marker = "";
  }
  std::string name = length ? std::string(marker, length) : std::string(marker);
  debug_marker_manager_.PushGroup(name);
  gpu_tracer_->Begin(TRACE_DISABLED_BY_DEFAULT("gpu_group_marker"), name,
                     kTraceGroupMarker);
}

void GLES2DecoderImpl::DoPopGroupMarkerEXT(void) {
  debug_marker_manager_.PopGroup();
  gpu_tracer_->End(kTraceGroupMarker);
}

void GLES2DecoderImpl::DoBindTexImage2DCHROMIUM(
    GLenum target, GLint image_id) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::DoBindTexImage2DCHROMIUM");

  if (target == GL_TEXTURE_CUBE_MAP) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_ENUM,
        "glBindTexImage2DCHROMIUM", "invalid target");
    return;
  }

  // Default target might be conceptually valid, but disallow it to avoid
  // accidents.
  TextureRef* texture_ref =
      texture_manager()->GetTextureInfoForTargetUnlessDefault(&state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glBindTexImage2DCHROMIUM", "no texture bound");
    return;
  }

  gfx::GLImage* gl_image = image_manager()->LookupImage(image_id);
  if (!gl_image) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glBindTexImage2DCHROMIUM", "no image found with the given ID");
    return;
  }

  {
    ScopedGLErrorSuppressor suppressor(
        "GLES2DecoderImpl::DoBindTexImage2DCHROMIUM", GetErrorState());
    if (!gl_image->BindTexImage(target)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glBindTexImage2DCHROMIUM", "fail to bind image with the given ID");
      return;
    }
  }

  gfx::Size size = gl_image->GetSize();
  texture_manager()->SetLevelInfo(
      texture_ref, target, 0, GL_RGBA, size.width(), size.height(), 1, 0,
      GL_RGBA, GL_UNSIGNED_BYTE, true);
  texture_manager()->SetLevelImage(texture_ref, target, 0, gl_image);
}

void GLES2DecoderImpl::DoReleaseTexImage2DCHROMIUM(
    GLenum target, GLint image_id) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::DoReleaseTexImage2DCHROMIUM");

  // Default target might be conceptually valid, but disallow it to avoid
  // accidents.
  TextureRef* texture_ref =
      texture_manager()->GetTextureInfoForTargetUnlessDefault(&state_, target);
  if (!texture_ref) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glReleaseTexImage2DCHROMIUM", "no texture bound");
    return;
  }

  gfx::GLImage* gl_image = image_manager()->LookupImage(image_id);
  if (!gl_image) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glReleaseTexImage2DCHROMIUM", "no image found with the given ID");
    return;
  }

  // Do nothing when image is not currently bound.
  if (texture_ref->texture()->GetLevelImage(target, 0) != gl_image)
    return;

  {
    ScopedGLErrorSuppressor suppressor(
        "GLES2DecoderImpl::DoReleaseTexImage2DCHROMIUM", GetErrorState());
    gl_image->ReleaseTexImage(target);
  }

  texture_manager()->SetLevelInfo(
      texture_ref, target, 0, GL_RGBA, 0, 0, 1, 0,
      GL_RGBA, GL_UNSIGNED_BYTE, false);
}

error::Error GLES2DecoderImpl::HandleTraceBeginCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::TraceBeginCHROMIUM& c =
      *static_cast<const gles2::cmds::TraceBeginCHROMIUM*>(cmd_data);
  Bucket* category_bucket = GetBucket(c.category_bucket_id);
  Bucket* name_bucket = GetBucket(c.name_bucket_id);
  if (!category_bucket || category_bucket->size() == 0 ||
      !name_bucket || name_bucket->size() == 0) {
    return error::kInvalidArguments;
  }

  std::string category_name;
  std::string trace_name;
  if (!category_bucket->GetAsString(&category_name) ||
      !name_bucket->GetAsString(&trace_name)) {
    return error::kInvalidArguments;
  }

  if (!gpu_tracer_->Begin(category_name, trace_name, kTraceCHROMIUM)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glTraceBeginCHROMIUM", "unable to create begin trace");
    return error::kNoError;
  }
  return error::kNoError;
}

void GLES2DecoderImpl::DoTraceEndCHROMIUM() {
  if (!gpu_tracer_->End(kTraceCHROMIUM)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glTraceEndCHROMIUM", "no trace begin found");
    return;
  }
}

void GLES2DecoderImpl::DoDrawBuffersEXT(
    GLsizei count, const GLenum* bufs) {
  if (count > static_cast<GLsizei>(group_->max_draw_buffers())) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_VALUE,
        "glDrawBuffersEXT", "greater than GL_MAX_DRAW_BUFFERS_EXT");
    return;
  }

  Framebuffer* framebuffer = GetFramebufferInfoForTarget(GL_FRAMEBUFFER);
  if (framebuffer) {
    for (GLsizei i = 0; i < count; ++i) {
      if (bufs[i] != static_cast<GLenum>(GL_COLOR_ATTACHMENT0 + i) &&
          bufs[i] != GL_NONE) {
        LOCAL_SET_GL_ERROR(
            GL_INVALID_OPERATION,
            "glDrawBuffersEXT",
            "bufs[i] not GL_NONE or GL_COLOR_ATTACHMENTi_EXT");
        return;
      }
    }
    glDrawBuffersARB(count, bufs);
    framebuffer->SetDrawBuffers(count, bufs);
  } else {  // backbuffer
    if (count > 1 ||
        (bufs[0] != GL_BACK && bufs[0] != GL_NONE)) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glDrawBuffersEXT",
          "more than one buffer or bufs not GL_NONE or GL_BACK");
      return;
    }
    GLenum mapped_buf = bufs[0];
    if (GetBackbufferServiceId() != 0 &&  // emulated backbuffer
        bufs[0] == GL_BACK) {
      mapped_buf = GL_COLOR_ATTACHMENT0;
    }
    glDrawBuffersARB(count, &mapped_buf);
    group_->set_draw_buffer(bufs[0]);
  }
}

void GLES2DecoderImpl::DoLoseContextCHROMIUM(GLenum current, GLenum other) {
  MarkContextLost(GetContextLostReasonFromResetStatus(current));
  group_->LoseContexts(GetContextLostReasonFromResetStatus(other));
  reset_by_robustness_extension_ = true;
}

void GLES2DecoderImpl::DoMatrixLoadfCHROMIUM(GLenum matrix_mode,
                                             const GLfloat* matrix) {
  DCHECK(matrix_mode == GL_PATH_PROJECTION_CHROMIUM ||
         matrix_mode == GL_PATH_MODELVIEW_CHROMIUM);
  if (!features().chromium_path_rendering) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glMatrixLoadfCHROMIUM",
                       "function not available");
    return;
  }

  GLfloat* target_matrix = matrix_mode == GL_PATH_PROJECTION_CHROMIUM
                               ? state_.projection_matrix
                               : state_.modelview_matrix;
  memcpy(target_matrix, matrix, sizeof(GLfloat) * 16);
  // The matrix_mode is either GL_PATH_MODELVIEW_NV or GL_PATH_PROJECTION_NV
  // since the values of the _NV and _CHROMIUM tokens match.
  glMatrixLoadfEXT(matrix_mode, matrix);
}

void GLES2DecoderImpl::DoMatrixLoadIdentityCHROMIUM(GLenum matrix_mode) {
  DCHECK(matrix_mode == GL_PATH_PROJECTION_CHROMIUM ||
         matrix_mode == GL_PATH_MODELVIEW_CHROMIUM);

  if (!features().chromium_path_rendering) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION,
                       "glMatrixLoadIdentityCHROMIUM",
                       "function not available");
    return;
  }

  GLfloat* target_matrix = matrix_mode == GL_PATH_PROJECTION_CHROMIUM
                               ? state_.projection_matrix
                               : state_.modelview_matrix;
  memcpy(target_matrix, kIdentityMatrix, sizeof(kIdentityMatrix));
  // The matrix_mode is either GL_PATH_MODELVIEW_NV or GL_PATH_PROJECTION_NV
  // since the values of the _NV and _CHROMIUM tokens match.
  glMatrixLoadIdentityEXT(matrix_mode);
}

bool GLES2DecoderImpl::ValidateAsyncTransfer(
    const char* function_name,
    TextureRef* texture_ref,
    GLenum target,
    GLint level,
    const void * data) {
  // We only support async uploads to 2D textures for now.
  if (GL_TEXTURE_2D != target) {
    LOCAL_SET_GL_ERROR_INVALID_ENUM(function_name, target, "target");
    return false;
  }
  // We only support uploads to level zero for now.
  if (level != 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, function_name, "level != 0");
    return false;
  }
  // A transfer buffer must be bound, even for asyncTexImage2D.
  if (data == NULL) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, function_name, "buffer == 0");
    return false;
  }
  // We only support one async transfer in progress.
  if (!texture_ref ||
      async_pixel_transfer_manager_->AsyncTransferIsInProgress(texture_ref)) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        function_name, "transfer already in progress");
    return false;
  }
  return true;
}

base::Closure GLES2DecoderImpl::AsyncUploadTokenCompletionClosure(
    uint32 async_upload_token,
    uint32 sync_data_shm_id,
    uint32 sync_data_shm_offset) {
  scoped_refptr<gpu::Buffer> buffer = GetSharedMemoryBuffer(sync_data_shm_id);
  if (!buffer.get() ||
      !buffer->GetDataAddress(sync_data_shm_offset, sizeof(AsyncUploadSync)))
    return base::Closure();

  AsyncMemoryParams mem_params(buffer,
                               sync_data_shm_offset,
                               sizeof(AsyncUploadSync));

  scoped_refptr<AsyncUploadTokenCompletionObserver> observer(
      new AsyncUploadTokenCompletionObserver(async_upload_token));

  return base::Bind(
      &AsyncPixelTransferManager::AsyncNotifyCompletion,
      base::Unretained(GetAsyncPixelTransferManager()),
      mem_params,
      observer);
}

error::Error GLES2DecoderImpl::HandleAsyncTexImage2DCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::AsyncTexImage2DCHROMIUM& c =
      *static_cast<const gles2::cmds::AsyncTexImage2DCHROMIUM*>(cmd_data);
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::HandleAsyncTexImage2DCHROMIUM");
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLenum internal_format = static_cast<GLenum>(c.internalformat);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLint border = static_cast<GLint>(c.border);
  GLenum format = static_cast<GLenum>(c.format);
  GLenum type = static_cast<GLenum>(c.type);
  uint32 pixels_shm_id = static_cast<uint32>(c.pixels_shm_id);
  uint32 pixels_shm_offset = static_cast<uint32>(c.pixels_shm_offset);
  uint32 pixels_size;
  uint32 async_upload_token = static_cast<uint32>(c.async_upload_token);
  uint32 sync_data_shm_id = static_cast<uint32>(c.sync_data_shm_id);
  uint32 sync_data_shm_offset = static_cast<uint32>(c.sync_data_shm_offset);

  base::ScopedClosureRunner scoped_completion_callback;
  if (async_upload_token) {
    base::Closure completion_closure =
        AsyncUploadTokenCompletionClosure(async_upload_token,
                                          sync_data_shm_id,
                                          sync_data_shm_offset);
    if (completion_closure.is_null())
      return error::kInvalidArguments;

    scoped_completion_callback.Reset(completion_closure);
  }

  // TODO(epenner): Move this and copies of this memory validation
  // into ValidateTexImage2D step.
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, state_.unpack_alignment, &pixels_size,
      NULL, NULL)) {
    return error::kOutOfBounds;
  }
  const void* pixels = NULL;
  if (pixels_shm_id != 0 || pixels_shm_offset != 0) {
    pixels = GetSharedMemoryAs<const void*>(
        pixels_shm_id, pixels_shm_offset, pixels_size);
    if (!pixels) {
      return error::kOutOfBounds;
    }
  }

  TextureManager::DoTextImage2DArguments args = {
    target, level, internal_format, width, height, border, format, type,
    pixels, pixels_size};
  TextureRef* texture_ref;
  // All the normal glTexSubImage2D validation.
  if (!texture_manager()->ValidateTexImage2D(
      &state_, "glAsyncTexImage2DCHROMIUM", args, &texture_ref)) {
    return error::kNoError;
  }

  // Extra async validation.
  Texture* texture = texture_ref->texture();
  if (!ValidateAsyncTransfer(
      "glAsyncTexImage2DCHROMIUM", texture_ref, target, level, pixels))
    return error::kNoError;

  // Don't allow async redefinition of a textures.
  if (texture->IsDefined()) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_OPERATION,
        "glAsyncTexImage2DCHROMIUM", "already defined");
    return error::kNoError;
  }

  if (!EnsureGPUMemoryAvailable(pixels_size)) {
    LOCAL_SET_GL_ERROR(
        GL_OUT_OF_MEMORY, "glAsyncTexImage2DCHROMIUM", "out of memory");
    return error::kNoError;
  }

  // Setup the parameters.
  AsyncTexImage2DParams tex_params = {
      target, level, static_cast<GLenum>(internal_format),
      width, height, border, format, type};
  AsyncMemoryParams mem_params(
      GetSharedMemoryBuffer(c.pixels_shm_id), c.pixels_shm_offset, pixels_size);

  // Set up the async state if needed, and make the texture
  // immutable so the async state stays valid. The level info
  // is set up lazily when the transfer completes.
  AsyncPixelTransferDelegate* delegate =
      async_pixel_transfer_manager_->CreatePixelTransferDelegate(texture_ref,
                                                                 tex_params);
  texture->SetImmutable(true);

  delegate->AsyncTexImage2D(
      tex_params,
      mem_params,
      base::Bind(&TextureManager::SetLevelInfoFromParams,
                 // The callback is only invoked if the transfer delegate still
                 // exists, which implies through manager->texture_ref->state
                 // ownership that both of these pointers are valid.
                 base::Unretained(texture_manager()),
                 base::Unretained(texture_ref),
                 tex_params));
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleAsyncTexSubImage2DCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::AsyncTexSubImage2DCHROMIUM& c =
      *static_cast<const gles2::cmds::AsyncTexSubImage2DCHROMIUM*>(cmd_data);
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::HandleAsyncTexSubImage2DCHROMIUM");
  GLenum target = static_cast<GLenum>(c.target);
  GLint level = static_cast<GLint>(c.level);
  GLint xoffset = static_cast<GLint>(c.xoffset);
  GLint yoffset = static_cast<GLint>(c.yoffset);
  GLsizei width = static_cast<GLsizei>(c.width);
  GLsizei height = static_cast<GLsizei>(c.height);
  GLenum format = static_cast<GLenum>(c.format);
  GLenum type = static_cast<GLenum>(c.type);
  uint32 async_upload_token = static_cast<uint32>(c.async_upload_token);
  uint32 sync_data_shm_id = static_cast<uint32>(c.sync_data_shm_id);
  uint32 sync_data_shm_offset = static_cast<uint32>(c.sync_data_shm_offset);

  base::ScopedClosureRunner scoped_completion_callback;
  if (async_upload_token) {
    base::Closure completion_closure =
        AsyncUploadTokenCompletionClosure(async_upload_token,
                                          sync_data_shm_id,
                                          sync_data_shm_offset);
    if (completion_closure.is_null())
      return error::kInvalidArguments;

    scoped_completion_callback.Reset(completion_closure);
  }

  // TODO(epenner): Move this and copies of this memory validation
  // into ValidateTexSubImage2D step.
  uint32 data_size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, state_.unpack_alignment, &data_size,
      NULL, NULL)) {
    return error::kOutOfBounds;
  }
  const void* pixels = GetSharedMemoryAs<const void*>(
      c.data_shm_id, c.data_shm_offset, data_size);

  // All the normal glTexSubImage2D validation.
  error::Error error = error::kNoError;
  if (!ValidateTexSubImage2D(&error, "glAsyncTexSubImage2DCHROMIUM",
      target, level, xoffset, yoffset, width, height, format, type, pixels)) {
    return error;
  }

  // Extra async validation.
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  Texture* texture = texture_ref->texture();
  if (!ValidateAsyncTransfer(
         "glAsyncTexSubImage2DCHROMIUM", texture_ref, target, level, pixels))
    return error::kNoError;

  // Guarantee async textures are always 'cleared' as follows:
  // - AsyncTexImage2D can not redefine an existing texture
  // - AsyncTexImage2D must initialize the entire image via non-null buffer.
  // - AsyncTexSubImage2D clears synchronously if not already cleared.
  // - Textures become immutable after an async call.
  // This way we know in all cases that an async texture is always clear.
  if (!texture->SafeToRenderFrom()) {
    if (!texture_manager()->ClearTextureLevel(this, texture_ref,
                                              target, level)) {
      LOCAL_SET_GL_ERROR(
          GL_OUT_OF_MEMORY,
          "glAsyncTexSubImage2DCHROMIUM", "dimensions too big");
      return error::kNoError;
    }
  }

  // Setup the parameters.
  AsyncTexSubImage2DParams tex_params = {target, level, xoffset, yoffset,
                                              width, height, format, type};
  AsyncMemoryParams mem_params(
      GetSharedMemoryBuffer(c.data_shm_id), c.data_shm_offset, data_size);
  AsyncPixelTransferDelegate* delegate =
      async_pixel_transfer_manager_->GetPixelTransferDelegate(texture_ref);
  if (!delegate) {
    // TODO(epenner): We may want to enforce exclusive use
    // of async APIs in which case this should become an error,
    // (the texture should have been async defined).
    AsyncTexImage2DParams define_params = {target, level,
                                                0, 0, 0, 0, 0, 0};
    texture->GetLevelSize(target, level, &define_params.width,
                                         &define_params.height);
    texture->GetLevelType(target, level, &define_params.type,
                                         &define_params.internal_format);
    // Set up the async state if needed, and make the texture
    // immutable so the async state stays valid.
    delegate = async_pixel_transfer_manager_->CreatePixelTransferDelegate(
        texture_ref, define_params);
    texture->SetImmutable(true);
  }

  delegate->AsyncTexSubImage2D(tex_params, mem_params);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleWaitAsyncTexImage2DCHROMIUM(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const gles2::cmds::WaitAsyncTexImage2DCHROMIUM& c =
      *static_cast<const gles2::cmds::WaitAsyncTexImage2DCHROMIUM*>(cmd_data);
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::HandleWaitAsyncTexImage2DCHROMIUM");
  GLenum target = static_cast<GLenum>(c.target);

  if (GL_TEXTURE_2D != target) {
    LOCAL_SET_GL_ERROR(
        GL_INVALID_ENUM, "glWaitAsyncTexImage2DCHROMIUM", "target");
    return error::kNoError;
  }
  TextureRef* texture_ref = texture_manager()->GetTextureInfoForTarget(
      &state_, target);
  if (!texture_ref) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glWaitAsyncTexImage2DCHROMIUM", "unknown texture");
    return error::kNoError;
  }
  AsyncPixelTransferDelegate* delegate =
      async_pixel_transfer_manager_->GetPixelTransferDelegate(texture_ref);
  if (!delegate) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION,
          "glWaitAsyncTexImage2DCHROMIUM", "No async transfer started");
    return error::kNoError;
  }
  delegate->WaitForTransferCompletion();
  ProcessFinishedAsyncTransfers();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleWaitAllAsyncTexImage2DCHROMIUM(
    uint32 immediate_data_size,
    const void* data) {
  TRACE_EVENT0("gpu", "GLES2DecoderImpl::HandleWaitAsyncTexImage2DCHROMIUM");

  GetAsyncPixelTransferManager()->WaitAllAsyncTexImage2D();
  ProcessFinishedAsyncTransfers();
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUniformBlockBinding(
    uint32_t immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::UniformBlockBinding& c =
      *static_cast<const gles2::cmds::UniformBlockBinding*>(cmd_data);
  GLuint client_id = c.program;
  GLuint index = static_cast<GLuint>(c.index);
  GLuint binding = static_cast<GLuint>(c.binding);
  Program* program = GetProgramInfoNotShader(
      client_id, "glUniformBlockBinding");
  if (!program) {
    return error::kNoError;
  }
  GLuint service_id = program->service_id();
  glUniformBlockBinding(service_id, index, binding);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleClientWaitSync(
    uint32_t immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::ClientWaitSync& c =
      *static_cast<const gles2::cmds::ClientWaitSync*>(cmd_data);
  GLuint sync = static_cast<GLuint>(c.sync);
  GLbitfield flags = static_cast<GLbitfield>(c.flags);
  GLuint64 timeout = GLES2Util::MapTwoUint32ToUint64(c.timeout_0, c.timeout_1);
  typedef cmds::ClientWaitSync::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
  if (*result_dst != GL_WAIT_FAILED) {
    return error::kInvalidArguments;
  }
  GLsync service_sync = 0;
  if (!group_->GetSyncServiceId(sync, &service_sync)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "ClientWaitSync", "invalid sync");
    return error::kNoError;
  }
  *result_dst = glClientWaitSync(service_sync, flags, timeout);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleWaitSync(
    uint32_t immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled())
    return error::kUnknownCommand;
  const gles2::cmds::WaitSync& c =
      *static_cast<const gles2::cmds::WaitSync*>(cmd_data);
  GLuint sync = static_cast<GLuint>(c.sync);
  GLbitfield flags = static_cast<GLbitfield>(c.flags);
  GLuint64 timeout = GLES2Util::MapTwoUint32ToUint64(c.timeout_0, c.timeout_1);
  GLsync service_sync = 0;
  if (!group_->GetSyncServiceId(sync, &service_sync)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "WaitSync", "invalid sync");
    return error::kNoError;
  }
  glWaitSync(service_sync, flags, timeout);
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleMapBufferRange(
    uint32_t immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled()) {
    return error::kUnknownCommand;
  }
  const gles2::cmds::MapBufferRange& c =
      *static_cast<const gles2::cmds::MapBufferRange*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);
  GLbitfield access = static_cast<GLbitfield>(c.access);
  GLintptr offset = static_cast<GLintptr>(c.offset);
  GLsizeiptr size = static_cast<GLsizeiptr>(c.size);

  typedef cmds::MapBufferRange::Result Result;
  Result* result = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result));
  if (!result) {
    return error::kOutOfBounds;
  }
  if (*result != 0) {
    *result = 0;
    return error::kInvalidArguments;
  }
  int8_t* mem =
      GetSharedMemoryAs<int8_t*>(c.data_shm_id, c.data_shm_offset, size);
  if (!mem) {
    return error::kOutOfBounds;
  }

  GLbitfield mask = GL_MAP_INVALIDATE_BUFFER_BIT;
  if ((access & mask) == mask) {
    // TODO(zmo): To be on the safe side, always map
    // GL_MAP_INVALIDATE_BUFFER_BIT to GL_MAP_INVALIDATE_RANGE_BIT.
    access = (access & ~GL_MAP_INVALIDATE_BUFFER_BIT);
    access = (access | GL_MAP_INVALIDATE_RANGE_BIT);
  }
  // TODO(zmo): Always filter out GL_MAP_UNSYNCHRONIZED_BIT to get rid of
  // undefined behaviors.
  mask = GL_MAP_READ_BIT | GL_MAP_UNSYNCHRONIZED_BIT;
  if ((access & mask) == mask) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "MapBufferRange",
                       "incompatible access bits");
    return error::kNoError;
  }
  access = (access & ~GL_MAP_UNSYNCHRONIZED_BIT);
  if ((access & GL_MAP_WRITE_BIT) == GL_MAP_WRITE_BIT &&
      (access & GL_MAP_INVALIDATE_RANGE_BIT) == 0) {
    access = (access | GL_MAP_READ_BIT);
  }
  void* ptr = glMapBufferRange(target, offset, size, access);
  if (ptr == nullptr) {
    return error::kNoError;
  }
  Buffer* buffer = buffer_manager()->GetBufferInfoForTarget(&state_, target);
  DCHECK(buffer);
  buffer->SetMappedRange(offset, size, access, ptr,
                         GetSharedMemoryBuffer(c.data_shm_id));
  if ((access & GL_MAP_INVALIDATE_RANGE_BIT) == 0) {
    memcpy(mem, ptr, size);
  }
  *result = 1;
  return error::kNoError;
}

error::Error GLES2DecoderImpl::HandleUnmapBuffer(
    uint32_t immediate_data_size, const void* cmd_data) {
  if (!unsafe_es3_apis_enabled()) {
    return error::kUnknownCommand;
  }
  const gles2::cmds::UnmapBuffer& c =
      *static_cast<const gles2::cmds::UnmapBuffer*>(cmd_data);
  GLenum target = static_cast<GLenum>(c.target);

  Buffer* buffer = buffer_manager()->GetBufferInfoForTarget(&state_, target);
  if (!buffer) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "UnmapBuffer", "no buffer bound");
    return error::kNoError;
  }
  const Buffer::MappedRange* mapped_range = buffer->GetMappedRange();
  if (!mapped_range) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "UnmapBuffer",
                       "buffer is unmapped");
    return error::kNoError;
  }
  if ((mapped_range->access & GL_MAP_WRITE_BIT) == 0 ||
      (mapped_range->access & GL_MAP_FLUSH_EXPLICIT_BIT) ==
           GL_MAP_FLUSH_EXPLICIT_BIT) {
    // If we don't need to write back, or explict flush is required, no copying
    // back is needed.
  } else {
    void* mem = mapped_range->GetShmPointer();
    if (!mem) {
      return error::kOutOfBounds;
    }
    DCHECK(mapped_range->pointer);
    memcpy(mapped_range->pointer, mem, mapped_range->size);
  }
  buffer->RemoveMappedRange();
  GLboolean rt = glUnmapBuffer(target);
  if (rt == GL_FALSE) {
    // At this point, we have already done the necessary validation, so
    // GL_FALSE indicates data corruption.
    // TODO(zmo): We could redo the map / copy data / unmap to recover, but
    // the second unmap could still return GL_FALSE. For now, we simply lose
    // the contexts in the share group.
    LOG(ERROR) << "glUnmapBuffer unexpectedly returned GL_FALSE";
    // Need to lose current context before broadcasting!
    MarkContextLost(error::kGuilty);
    group_->LoseContexts(error::kInnocent);
    return error::kLostContext;
  }
  return error::kNoError;
}

void GLES2DecoderImpl::OnTextureRefDetachedFromFramebuffer(
    TextureRef* texture_ref) {
  Texture* texture = texture_ref->texture();
  DoDidUseTexImageIfNeeded(texture, texture->target());
}

// Note that GL_LOST_CONTEXT is specific to GLES.
// For desktop GL we have to query the reset status proactively.
void GLES2DecoderImpl::OnContextLostError() {
  if (!WasContextLost()) {
    // Need to lose current context before broadcasting!
    CheckResetStatus();
    group_->LoseContexts(error::kUnknown);
    reset_by_robustness_extension_ = true;
  }
}

void GLES2DecoderImpl::OnOutOfMemoryError() {
  if (lose_context_when_out_of_memory_ && !WasContextLost()) {
    error::ContextLostReason other = error::kOutOfMemory;
    if (CheckResetStatus()) {
      other = error::kUnknown;
    } else {
      // Need to lose current context before broadcasting!
      MarkContextLost(error::kOutOfMemory);
    }
    group_->LoseContexts(other);
  }
}

// Include the auto-generated part of this file. We split this because it means
// we can easily edit the non-auto generated parts right here in this file
// instead of having to edit some template or the code generator.
#include "gpu/command_buffer/service/gles2_cmd_decoder_autogen.h"

}  // namespace gles2
}  // namespace gpu
