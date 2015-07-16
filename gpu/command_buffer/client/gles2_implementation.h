// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_IMPLEMENTATION_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_IMPLEMENTATION_H_

#include <GLES2/gl2.h>

#include <list>
#include <map>
#include <queue>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "gpu/command_buffer/client/buffer_tracker.h"
#include "gpu/command_buffer/client/client_context_state.h"
#include "gpu/command_buffer/client/context_support.h"
#include "gpu/command_buffer/client/gles2_cmd_helper.h"
#include "gpu/command_buffer/client/gles2_impl_export.h"
#include "gpu/command_buffer/client/gles2_interface.h"
#include "gpu/command_buffer/client/mapped_memory.h"
#include "gpu/command_buffer/client/query_tracker.h"
#include "gpu/command_buffer/client/ref_counted.h"
#include "gpu/command_buffer/client/ring_buffer.h"
#include "gpu/command_buffer/client/share_group.h"
#include "gpu/command_buffer/common/capabilities.h"
#include "gpu/command_buffer/common/debug_marker_manager.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/common/id_allocator.h"

#if !defined(NDEBUG) && !defined(__native_client__) && !defined(GLES2_CONFORMANCE_TESTS)  // NOLINT
  #if defined(GLES2_INLINE_OPTIMIZATION)
    // TODO(gman): Replace with macros that work with inline optmization.
    #define GPU_CLIENT_SINGLE_THREAD_CHECK()
    #define GPU_CLIENT_LOG(args)
    #define GPU_CLIENT_LOG_CODE_BLOCK(code)
    #define GPU_CLIENT_DCHECK_CODE_BLOCK(code)
  #else
    #include "base/logging.h"
    #define GPU_CLIENT_SINGLE_THREAD_CHECK() SingleThreadChecker checker(this);
    #define GPU_CLIENT_LOG(args)  DLOG_IF(INFO, debug_) << args;
    #define GPU_CLIENT_LOG_CODE_BLOCK(code) code
    #define GPU_CLIENT_DCHECK_CODE_BLOCK(code) code
    #define GPU_CLIENT_DEBUG
  #endif
#else
  #define GPU_CLIENT_SINGLE_THREAD_CHECK()
  #define GPU_CLIENT_LOG(args)
  #define GPU_CLIENT_LOG_CODE_BLOCK(code)
  #define GPU_CLIENT_DCHECK_CODE_BLOCK(code)
#endif

#if defined(GPU_CLIENT_DEBUG)
  // Set to 1 to have the client fail when a GL error is generated.
  // This helps find bugs in the renderer since the debugger stops on the error.
#  if 0
#    define GL_CLIENT_FAIL_GL_ERRORS
#  endif
#endif

// Check that destination pointers point to initialized memory.
// When the context is lost, calling GL function has no effect so if destination
// pointers point to initialized memory it can often lead to crash bugs. eg.
//
// GLsizei len;
// glGetShaderSource(shader, max_size, &len, buffer);
// std::string src(buffer, buffer + len);  // len can be uninitialized here!!!
//
// Because this check is not official GL this check happens only on Chrome code,
// not Pepper.
//
// If it was up to us we'd just always write to the destination but the OpenGL
// spec defines the behavior of OpenGL functions, not us. :-(
#if defined(__native_client__) || defined(GLES2_CONFORMANCE_TESTS)
  #define GPU_CLIENT_VALIDATE_DESTINATION_INITALIZATION_ASSERT(v)
  #define GPU_CLIENT_DCHECK(v)
#elif defined(GPU_DCHECK)
  #define GPU_CLIENT_VALIDATE_DESTINATION_INITALIZATION_ASSERT(v) GPU_DCHECK(v)
  #define GPU_CLIENT_DCHECK(v) GPU_DCHECK(v)
#elif defined(DCHECK)
  #define GPU_CLIENT_VALIDATE_DESTINATION_INITALIZATION_ASSERT(v) DCHECK(v)
  #define GPU_CLIENT_DCHECK(v) DCHECK(v)
#else
  #define GPU_CLIENT_VALIDATE_DESTINATION_INITALIZATION_ASSERT(v) ASSERT(v)
  #define GPU_CLIENT_DCHECK(v) ASSERT(v)
#endif

#define GPU_CLIENT_VALIDATE_DESTINATION_INITALIZATION(type, ptr) \
    GPU_CLIENT_VALIDATE_DESTINATION_INITALIZATION_ASSERT(ptr && \
        (ptr[0] == static_cast<type>(0) || ptr[0] == static_cast<type>(-1)));

#define GPU_CLIENT_VALIDATE_DESTINATION_OPTIONAL_INITALIZATION(type, ptr) \
    GPU_CLIENT_VALIDATE_DESTINATION_INITALIZATION_ASSERT(!ptr || \
        (ptr[0] == static_cast<type>(0) || ptr[0] == static_cast<type>(-1)));

struct GLUniformDefinitionCHROMIUM;

namespace gpu {

class GpuControl;
class ScopedTransferBufferPtr;
class TransferBufferInterface;

namespace gles2 {

class ImageFactory;
class VertexArrayObjectManager;

class GLES2ImplementationErrorMessageCallback {
 public:
  virtual ~GLES2ImplementationErrorMessageCallback() { }
  virtual void OnErrorMessage(const char* msg, int id) = 0;
};

// This class emulates GLES2 over command buffers. It can be used by a client
// program so that the program does not need deal with shared memory and command
// buffer management. See gl2_lib.h.  Note that there is a performance gain to
// be had by changing your code to use command buffers directly by using the
// GLES2CmdHelper but that entails changing your code to use and deal with
// shared memory and synchronization issues.
class GLES2_IMPL_EXPORT GLES2Implementation
    : NON_EXPORTED_BASE(public GLES2Interface),
      NON_EXPORTED_BASE(public ContextSupport) {
 public:
  enum MappedMemoryLimit {
    kNoLimit = MappedMemoryManager::kNoLimit,
  };

  // Stores GL state that never changes.
  struct GLES2_IMPL_EXPORT GLStaticState {
    GLStaticState();
    ~GLStaticState();

    typedef std::pair<GLenum, GLenum> ShaderPrecisionKey;
    typedef std::map<ShaderPrecisionKey,
                     cmds::GetShaderPrecisionFormat::Result>
        ShaderPrecisionMap;
    ShaderPrecisionMap shader_precisions;
  };

  // The maxiumum result size from simple GL get commands.
  static const size_t kMaxSizeOfSimpleResult = 16 * sizeof(uint32);  // NOLINT.

  // used for testing only. If more things are reseved add them here.
  static const unsigned int kStartingOffset = kMaxSizeOfSimpleResult;

  // Size in bytes to issue async flush for transfer buffer.
  static const unsigned int kSizeToFlush = 256 * 1024;

  // The bucket used for results. Public for testing only.
  static const uint32 kResultBucketId = 1;

  // Alignment of allocations.
  static const unsigned int kAlignment = 4;

  // GL names for the buffers used to emulate client side buffers.
  static const GLuint kClientSideArrayId = 0xFEDCBA98u;
  static const GLuint kClientSideElementArrayId = 0xFEDCBA99u;

  // Number of swap buffers allowed before waiting.
  static const size_t kMaxSwapBuffers = 2;

  GLES2Implementation(GLES2CmdHelper* helper,
                      ShareGroup* share_group,
                      TransferBufferInterface* transfer_buffer,
                      bool bind_generates_resource,
                      bool lose_context_when_out_of_memory,
                      bool support_client_side_arrays,
                      GpuControl* gpu_control);

  ~GLES2Implementation() override;

  bool Initialize(
      unsigned int starting_transfer_buffer_size,
      unsigned int min_transfer_buffer_size,
      unsigned int max_transfer_buffer_size,
      unsigned int mapped_memory_limit);

  // The GLES2CmdHelper being used by this GLES2Implementation. You can use
  // this to issue cmds at a lower level for certain kinds of optimization.
  GLES2CmdHelper* helper() const;

  // Gets client side generated errors.
  GLenum GetClientSideGLError();

  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gpu/command_buffer/client/gles2_implementation_autogen.h"

  void DisableVertexAttribArray(GLuint index) override;
  void EnableVertexAttribArray(GLuint index) override;
  void GetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params) override;
  void GetVertexAttribiv(GLuint index, GLenum pname, GLint* params) override;

  // ContextSupport implementation.
  void Swap() override;
  void PartialSwapBuffers(const gfx::Rect& sub_buffer) override;
  void ScheduleOverlayPlane(int plane_z_order,
                            gfx::OverlayTransform plane_transform,
                            unsigned overlay_texture_id,
                            const gfx::Rect& display_bounds,
                            const gfx::RectF& uv_rect) override;
  GLuint InsertFutureSyncPointCHROMIUM() override;
  void RetireSyncPointCHROMIUM(GLuint sync_point) override;

  void GetProgramInfoCHROMIUMHelper(GLuint program, std::vector<int8>* result);
  GLint GetAttribLocationHelper(GLuint program, const char* name);
  GLint GetUniformLocationHelper(GLuint program, const char* name);
  GLint GetFragDataLocationHelper(GLuint program, const char* name);
  bool GetActiveAttribHelper(
      GLuint program, GLuint index, GLsizei bufsize, GLsizei* length,
      GLint* size, GLenum* type, char* name);
  bool GetActiveUniformHelper(
      GLuint program, GLuint index, GLsizei bufsize, GLsizei* length,
      GLint* size, GLenum* type, char* name);
  void GetUniformBlocksCHROMIUMHelper(
      GLuint program, std::vector<int8>* result);
  void GetUniformsES3CHROMIUMHelper(
      GLuint program, std::vector<int8>* result);
  GLuint GetUniformBlockIndexHelper(GLuint program, const char* name);
  bool GetActiveUniformBlockNameHelper(
      GLuint program, GLuint index, GLsizei bufsize,
      GLsizei* length, char* name);
  bool GetActiveUniformBlockivHelper(
      GLuint program, GLuint index, GLenum pname, GLint* params);
  void GetTransformFeedbackVaryingsCHROMIUMHelper(
      GLuint program, std::vector<int8>* result);
  bool GetTransformFeedbackVaryingHelper(
      GLuint program, GLuint index, GLsizei bufsize, GLsizei* length,
      GLint* size, GLenum* type, char* name);
  bool GetUniformIndicesHelper(
      GLuint program, GLsizei count, const char* const* names, GLuint* indices);
  bool GetActiveUniformsivHelper(
      GLuint program, GLsizei count, const GLuint* indices,
      GLenum pname, GLint* params);
  bool GetSyncivHelper(
      GLsync sync, GLenum pname, GLsizei bufsize, GLsizei* length,
      GLint* values);

  void FreeUnusedSharedMemory();
  void FreeEverything();

  // ContextSupport implementation.
  void SignalSyncPoint(uint32 sync_point,
                       const base::Closure& callback) override;
  void SignalQuery(uint32 query, const base::Closure& callback) override;
  void SetSurfaceVisible(bool visible) override;

  void SetErrorMessageCallback(
      GLES2ImplementationErrorMessageCallback* callback) {
    error_message_callback_ = callback;
  }

  ShareGroup* share_group() const {
    return share_group_.get();
  }

  const Capabilities& capabilities() const {
    return capabilities_;
  }

  GpuControl* gpu_control() {
    return gpu_control_;
  }

  ShareGroupContextData* share_group_context_data() {
    return &share_group_context_data_;
  }

 private:
  friend class GLES2ImplementationTest;
  friend class VertexArrayObjectManager;

  // Used to track whether an extension is available
  enum ExtensionStatus {
      kAvailableExtensionStatus,
      kUnavailableExtensionStatus,
      kUnknownExtensionStatus
  };

  // Base class for mapped resources.
  struct MappedResource {
    MappedResource(GLenum _access, int _shm_id, void* mem, unsigned int offset)
        : access(_access),
          shm_id(_shm_id),
          shm_memory(mem),
          shm_offset(offset) {
    }

    // access mode. Currently only GL_WRITE_ONLY is valid
    GLenum access;

    // Shared memory ID for buffer.
    int shm_id;

    // Address of shared memory
    void* shm_memory;

    // Offset of shared memory
    unsigned int shm_offset;
  };

  // Used to track mapped textures.
  struct MappedTexture : public MappedResource {
    MappedTexture(
        GLenum access,
        int shm_id,
        void* shm_mem,
        unsigned int shm_offset,
        GLenum _target,
        GLint _level,
        GLint _xoffset,
        GLint _yoffset,
        GLsizei _width,
        GLsizei _height,
        GLenum _format,
        GLenum _type)
        : MappedResource(access, shm_id, shm_mem, shm_offset),
          target(_target),
          level(_level),
          xoffset(_xoffset),
          yoffset(_yoffset),
          width(_width),
          height(_height),
          format(_format),
          type(_type) {
    }

    // These match the arguments to TexSubImage2D.
    GLenum target;
    GLint level;
    GLint xoffset;
    GLint yoffset;
    GLsizei width;
    GLsizei height;
    GLenum format;
    GLenum type;
  };

  // Used to track mapped buffers.
  struct MappedBuffer : public MappedResource {
    MappedBuffer(
        GLenum access,
        int shm_id,
        void* shm_mem,
        unsigned int shm_offset,
        GLenum _target,
        GLintptr _offset,
        GLsizeiptr _size)
        : MappedResource(access, shm_id, shm_mem, shm_offset),
          target(_target),
          offset(_offset),
          size(_size) {
    }

    // These match the arguments to BufferSubData.
    GLenum target;
    GLintptr offset;
    GLsizeiptr size;
  };

  struct TextureUnit {
    TextureUnit()
        : bound_texture_2d(0),
          bound_texture_cube_map(0),
          bound_texture_external_oes(0) {}

    // texture currently bound to this unit's GL_TEXTURE_2D with glBindTexture
    GLuint bound_texture_2d;

    // texture currently bound to this unit's GL_TEXTURE_CUBE_MAP with
    // glBindTexture
    GLuint bound_texture_cube_map;

    // texture currently bound to this unit's GL_TEXTURE_EXTERNAL_OES with
    // glBindTexture
    GLuint bound_texture_external_oes;
  };

  // Checks for single threaded access.
  class SingleThreadChecker {
   public:
    explicit SingleThreadChecker(GLES2Implementation* gles2_implementation);
    ~SingleThreadChecker();

   private:
    GLES2Implementation* gles2_implementation_;
  };

  // Gets the value of the result.
  template <typename T>
  T GetResultAs() {
    return static_cast<T>(GetResultBuffer());
  }

  void* GetResultBuffer();
  int32 GetResultShmId();
  uint32 GetResultShmOffset();

  // Lazily determines if GL_ANGLE_pack_reverse_row_order is available
  bool IsAnglePackReverseRowOrderAvailable();
  bool IsChromiumFramebufferMultisampleAvailable();

  bool IsExtensionAvailableHelper(
      const char* extension, ExtensionStatus* status);

  // Gets the GLError through our wrapper.
  GLenum GetGLError();

  // Sets our wrapper for the GLError.
  void SetGLError(GLenum error, const char* function_name, const char* msg);
  void SetGLErrorInvalidEnum(
      const char* function_name, GLenum value, const char* label);

  // Returns the last error and clears it. Useful for debugging.
  const std::string& GetLastError() {
    return last_error_;
  }

  // Waits for all commands to execute.
  void WaitForCmd();

  // TODO(gman): These bucket functions really seem like they belong in
  // CommandBufferHelper (or maybe BucketHelper?). Unfortunately they need
  // a transfer buffer to function which is currently managed by this class.

  // Gets the contents of a bucket.
  bool GetBucketContents(uint32 bucket_id, std::vector<int8>* data);

  // Sets the contents of a bucket.
  void SetBucketContents(uint32 bucket_id, const void* data, size_t size);

  // Sets the contents of a bucket as a string.
  void SetBucketAsCString(uint32 bucket_id, const char* str);

  // Gets the contents of a bucket as a string. Returns false if there is no
  // string available which is a separate case from the empty string.
  bool GetBucketAsString(uint32 bucket_id, std::string* str);

  // Sets the contents of a bucket as a string.
  void SetBucketAsString(uint32 bucket_id, const std::string& str);

  // Returns true if id is reserved.
  bool IsBufferReservedId(GLuint id);
  bool IsFramebufferReservedId(GLuint id) { return false; }
  bool IsRenderbufferReservedId(GLuint id) { return false; }
  bool IsTextureReservedId(GLuint id) { return false; }
  bool IsVertexArrayReservedId(GLuint id) { return false; }
  bool IsProgramReservedId(GLuint id) { return false; }
  bool IsValuebufferReservedId(GLuint id) { return false; }
  bool IsSamplerReservedId(GLuint id) { return false; }
  bool IsTransformFeedbackReservedId(GLuint id) { return false; }

  void BindBufferHelper(GLenum target, GLuint buffer);
  void BindBufferBaseHelper(GLenum target, GLuint index, GLuint buffer);
  void BindBufferRangeHelper(GLenum target, GLuint index, GLuint buffer,
                             GLintptr offset, GLsizeiptr size);
  void BindFramebufferHelper(GLenum target, GLuint framebuffer);
  void BindRenderbufferHelper(GLenum target, GLuint renderbuffer);
  void BindSamplerHelper(GLuint unit, GLuint sampler);
  void BindTextureHelper(GLenum target, GLuint texture);
  void BindTransformFeedbackHelper(GLenum target, GLuint transformfeedback);
  void BindVertexArrayOESHelper(GLuint array);
  void BindValuebufferCHROMIUMHelper(GLenum target, GLuint valuebuffer);
  void UseProgramHelper(GLuint program);

  void BindBufferStub(GLenum target, GLuint buffer);
  void BindBufferBaseStub(GLenum target, GLuint index, GLuint buffer);
  void BindBufferRangeStub(GLenum target, GLuint index, GLuint buffer,
                           GLintptr offset, GLsizeiptr size);
  void BindFramebufferStub(GLenum target, GLuint framebuffer);
  void BindRenderbufferStub(GLenum target, GLuint renderbuffer);
  void BindTextureStub(GLenum target, GLuint texture);
  void BindValuebufferCHROMIUMStub(GLenum target, GLuint valuebuffer);

  void GenBuffersHelper(GLsizei n, const GLuint* buffers);
  void GenFramebuffersHelper(GLsizei n, const GLuint* framebuffers);
  void GenRenderbuffersHelper(GLsizei n, const GLuint* renderbuffers);
  void GenTexturesHelper(GLsizei n, const GLuint* textures);
  void GenVertexArraysOESHelper(GLsizei n, const GLuint* arrays);
  void GenQueriesEXTHelper(GLsizei n, const GLuint* queries);
  void GenValuebuffersCHROMIUMHelper(GLsizei n, const GLuint* valuebuffers);
  void GenSamplersHelper(GLsizei n, const GLuint* samplers);
  void GenTransformFeedbacksHelper(GLsizei n, const GLuint* transformfeedbacks);

  void DeleteBuffersHelper(GLsizei n, const GLuint* buffers);
  void DeleteFramebuffersHelper(GLsizei n, const GLuint* framebuffers);
  void DeleteRenderbuffersHelper(GLsizei n, const GLuint* renderbuffers);
  void DeleteTexturesHelper(GLsizei n, const GLuint* textures);
  bool DeleteProgramHelper(GLuint program);
  bool DeleteShaderHelper(GLuint shader);
  void DeleteQueriesEXTHelper(GLsizei n, const GLuint* queries);
  void DeleteVertexArraysOESHelper(GLsizei n, const GLuint* arrays);
  void DeleteValuebuffersCHROMIUMHelper(GLsizei n, const GLuint* valuebuffers);
  void DeleteSamplersHelper(GLsizei n, const GLuint* samplers);
  void DeleteTransformFeedbacksHelper(
      GLsizei n, const GLuint* transformfeedbacks);
  void DeleteSyncHelper(GLsync sync);

  void DeleteBuffersStub(GLsizei n, const GLuint* buffers);
  void DeleteFramebuffersStub(GLsizei n, const GLuint* framebuffers);
  void DeleteRenderbuffersStub(GLsizei n, const GLuint* renderbuffers);
  void DeleteTexturesStub(GLsizei n, const GLuint* textures);
  void DeleteProgramStub(GLsizei n, const GLuint* programs);
  void DeleteShaderStub(GLsizei n, const GLuint* shaders);
  void DeleteVertexArraysOESStub(GLsizei n, const GLuint* arrays);
  void DeleteValuebuffersCHROMIUMStub(GLsizei n, const GLuint* valuebuffers);
  void DeleteSamplersStub(GLsizei n, const GLuint* samplers);
  void DeleteTransformFeedbacksStub(
      GLsizei n, const GLuint* transformfeedbacks);
  void DeleteSyncStub(GLsizei n, const GLuint* syncs);

  void BufferDataHelper(
      GLenum target, GLsizeiptr size, const void* data, GLenum usage);
  void BufferSubDataHelper(
      GLenum target, GLintptr offset, GLsizeiptr size, const void* data);
  void BufferSubDataHelperImpl(
      GLenum target, GLintptr offset, GLsizeiptr size, const void* data,
      ScopedTransferBufferPtr* buffer);

  GLuint CreateImageCHROMIUMHelper(ClientBuffer buffer,
                                   GLsizei width,
                                   GLsizei height,
                                   GLenum internalformat);
  void DestroyImageCHROMIUMHelper(GLuint image_id);
  GLuint CreateGpuMemoryBufferImageCHROMIUMHelper(GLsizei width,
                                                  GLsizei height,
                                                  GLenum internalformat,
                                                  GLenum usage);

  // Helper for GetVertexAttrib
  bool GetVertexAttribHelper(GLuint index, GLenum pname, uint32* param);

  GLuint GetMaxValueInBufferCHROMIUMHelper(
      GLuint buffer_id, GLsizei count, GLenum type, GLuint offset);

  void RestoreElementAndArrayBuffers(bool restore);
  void RestoreArrayBuffer(bool restrore);

  // The pixels pointer should already account for unpack skip
  // images/rows/pixels.
  void TexSubImage2DImpl(
      GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
      GLsizei height, GLenum format, GLenum type, uint32 unpadded_row_size,
      const void* pixels, uint32 pixels_padded_row_size, GLboolean internal,
      ScopedTransferBufferPtr* buffer, uint32 buffer_padded_row_size);
  void TexSubImage3DImpl(
      GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset,
      GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type,
      uint32 unpadded_row_size, const void* pixels,
      uint32 pixels_padded_row_size, GLboolean internal,
      ScopedTransferBufferPtr* buffer, uint32 buffer_padded_row_size);

  // Helpers for query functions.
  bool GetHelper(GLenum pname, GLint* params);
  GLuint GetBoundBufferHelper(GLenum target);
  bool GetBooleanvHelper(GLenum pname, GLboolean* params);
  bool GetBufferParameterivHelper(GLenum target, GLenum pname, GLint* params);
  bool GetFloatvHelper(GLenum pname, GLfloat* params);
  bool GetFramebufferAttachmentParameterivHelper(
      GLenum target, GLenum attachment, GLenum pname, GLint* params);
  bool GetInteger64vHelper(GLenum pname, GLint64* params);
  bool GetIntegervHelper(GLenum pname, GLint* params);
  bool GetIntegeri_vHelper(GLenum pname, GLuint index, GLint* data);
  bool GetInteger64i_vHelper(GLenum pname, GLuint index, GLint64* data);
  bool GetInternalformativHelper(
      GLenum target, GLenum format, GLenum pname, GLsizei bufSize,
      GLint* params);
  bool GetProgramivHelper(GLuint program, GLenum pname, GLint* params);
  bool GetSamplerParameterfvHelper(
      GLuint sampler, GLenum pname, GLfloat* params);
  bool GetSamplerParameterivHelper(
      GLuint sampler, GLenum pname, GLint* params);
  bool GetRenderbufferParameterivHelper(
      GLenum target, GLenum pname, GLint* params);
  bool GetShaderivHelper(GLuint shader, GLenum pname, GLint* params);
  bool GetTexParameterfvHelper(GLenum target, GLenum pname, GLfloat* params);
  bool GetTexParameterivHelper(GLenum target, GLenum pname, GLint* params);
  const GLubyte* GetStringHelper(GLenum name);

  bool IsExtensionAvailable(const char* ext);

  // Caches certain capabilties state. Return true if cached.
  bool SetCapabilityState(GLenum cap, bool enabled);

  IdHandlerInterface* GetIdHandler(int id_namespace) const;
  // IdAllocators for objects that can't be shared among contexts.
  // For now, used only for Queries. TODO(hj.r.chung) Should be added for
  // Framebuffer and Vertex array objects.
  IdAllocator* GetIdAllocator(int id_namespace) const;

  void FinishHelper();

  void RunIfContextNotLost(const base::Closure& callback);

  // Validate if an offset is valid, i.e., non-negative and fit into 32-bit.
  // If not, generate an approriate error, and return false.
  bool ValidateOffset(const char* func, GLintptr offset);

  // Validate if a size is valid, i.e., non-negative and fit into 32-bit.
  // If not, generate an approriate error, and return false.
  bool ValidateSize(const char* func, GLsizeiptr offset);

  // Remove the transfer buffer from the buffer tracker. For buffers used
  // asynchronously the memory is free:ed if the upload has completed. For
  // other buffers, the memory is either free:ed immediately or free:ed pending
  // a token.
  void RemoveTransferBuffer(BufferTracker::Buffer* buffer);

  // Returns true if the async upload token has passed.
  //
  // NOTE: This will detect wrapped async tokens by checking if the most
  // significant  bit of async token to check is 1 but the last read is 0, i.e.
  // the uint32 wrapped.
  bool HasAsyncUploadTokenPassed(uint32 token) const {
    return async_upload_sync_->HasAsyncUploadTokenPassed(token);
  }

  // Get the next async upload token.
  uint32 NextAsyncUploadToken();

  // Ensure that the shared memory used for synchronizing async upload tokens
  // has been mapped.
  //
  // Returns false on error, true on success.
  bool EnsureAsyncUploadSync();

  // Checks the last read asynchronously upload token and frees any unmanaged
  // transfer buffer that has its async token passed.
  void PollAsyncUploads();

  // Free every async upload buffer. If some async upload buffer is still in use
  // wait for them to finish before freeing.
  void FreeAllAsyncUploadBuffers();

  bool GetBoundPixelTransferBuffer(
      GLenum target, const char* function_name, GLuint* buffer_id);
  BufferTracker::Buffer* GetBoundPixelUnpackTransferBufferIfValid(
      GLuint buffer_id,
      const char* function_name, GLuint offset, GLsizei size);

  // Pack 2D arrays of char into a bucket.
  // Helper function for ShaderSource(), TransformFeedbackVaryings(), etc.
  bool PackStringsToBucket(GLsizei count,
                           const char* const* str,
                           const GLint* length,
                           const char* func_name);

  const std::string& GetLogPrefix() const;

#if defined(GL_CLIENT_FAIL_GL_ERRORS)
  void CheckGLError();
  void FailGLError(GLenum error);
#else
  void CheckGLError() { }
  void FailGLError(GLenum /* error */) { }
#endif

  void RemoveMappedBufferRangeByTarget(GLenum target);
  void RemoveMappedBufferRangeById(GLuint buffer);
  void ClearMappedBufferRangeMap();

  void DrawElementsImpl(GLenum mode, GLsizei count, GLenum type,
                        const void* indices, const char* func_name);

  GLES2Util util_;
  GLES2CmdHelper* helper_;
  TransferBufferInterface* transfer_buffer_;
  std::string last_error_;
  DebugMarkerManager debug_marker_manager_;
  std::string this_in_hex_;

  std::queue<int32> swap_buffers_tokens_;
  std::queue<int32> rate_limit_tokens_;

  ExtensionStatus angle_pack_reverse_row_order_status_;
  ExtensionStatus chromium_framebuffer_multisample_;

  GLStaticState static_state_;
  ClientContextState state_;

  // pack alignment as last set by glPixelStorei
  GLint pack_alignment_;

  // unpack alignment as last set by glPixelStorei
  GLint unpack_alignment_;

  // unpack yflip as last set by glPixelstorei
  bool unpack_flip_y_;

  // unpack row length as last set by glPixelStorei
  GLint unpack_row_length_;

  // unpack image height as last set by glPixelStorei
  GLint unpack_image_height_;

  // unpack skip rows as last set by glPixelStorei
  GLint unpack_skip_rows_;

  // unpack skip pixels as last set by glPixelStorei
  GLint unpack_skip_pixels_;

  // unpack skip images as last set by glPixelStorei
  GLint unpack_skip_images_;

  // pack reverse row order as last set by glPixelstorei
  bool pack_reverse_row_order_;

  scoped_ptr<TextureUnit[]> texture_units_;

  // 0 to gl_state_.max_combined_texture_image_units.
  GLuint active_texture_unit_;

  GLuint bound_framebuffer_;
  GLuint bound_read_framebuffer_;
  GLuint bound_renderbuffer_;
  GLuint bound_valuebuffer_;

  // The program in use by glUseProgram
  GLuint current_program_;

  // The currently bound array buffer.
  GLuint bound_array_buffer_id_;

  // The currently bound pixel transfer buffers.
  GLuint bound_pixel_pack_transfer_buffer_id_;
  GLuint bound_pixel_unpack_transfer_buffer_id_;

  // The current asynchronous pixel buffer upload token.
  uint32 async_upload_token_;

  // The shared memory used for synchronizing asynchronous upload tokens.
  AsyncUploadSync* async_upload_sync_;
  int32 async_upload_sync_shm_id_;
  unsigned int async_upload_sync_shm_offset_;

  // Unmanaged pixel transfer buffer memory pending asynchronous upload token.
  typedef std::list<std::pair<void*, uint32> > DetachedAsyncUploadMemoryList;
  DetachedAsyncUploadMemoryList detached_async_upload_memory_;

  // Client side management for vertex array objects. Needed to correctly
  // track client side arrays.
  scoped_ptr<VertexArrayObjectManager> vertex_array_object_manager_;

  GLuint reserved_ids_[2];

  // Current GL error bits.
  uint32 error_bits_;

  // Whether or not to print debugging info.
  bool debug_;

  // When true, the context is lost when a GL_OUT_OF_MEMORY error occurs.
  const bool lose_context_when_out_of_memory_;

  // Whether or not to support client side arrays.
  const bool support_client_side_arrays_;

  // Used to check for single threaded access.
  int use_count_;

  // Map of GLenum to Strings for glGetString.  We need to cache these because
  // the pointer passed back to the client has to remain valid for eternity.
  typedef std::map<uint32, std::set<std::string> > GLStringMap;
  GLStringMap gl_strings_;

  // Similar cache for glGetRequestableExtensionsCHROMIUM. We don't
  // have an enum for this so handle it separately.
  std::set<std::string> requestable_extensions_set_;

  typedef std::map<const void*, MappedBuffer> MappedBufferMap;
  MappedBufferMap mapped_buffers_;

  // TODO(zmo): Consolidate |mapped_buffers_| and |mapped_buffer_range_map_|.
  typedef base::hash_map<GLuint, MappedBuffer> MappedBufferRangeMap;
  MappedBufferRangeMap mapped_buffer_range_map_;

  typedef std::map<const void*, MappedTexture> MappedTextureMap;
  MappedTextureMap mapped_textures_;

  scoped_ptr<MappedMemoryManager> mapped_memory_;

  scoped_refptr<ShareGroup> share_group_;
  ShareGroupContextData share_group_context_data_;

  scoped_ptr<QueryTracker> query_tracker_;
  typedef std::map<GLuint, QueryTracker::Query*> QueryMap;
  QueryMap current_queries_;
  scoped_ptr<IdAllocator> query_id_allocator_;

  scoped_ptr<BufferTracker> buffer_tracker_;

  GLES2ImplementationErrorMessageCallback* error_message_callback_;

  int current_trace_stack_;

  GpuControl* gpu_control_;

  Capabilities capabilities_;

  base::WeakPtrFactory<GLES2Implementation> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(GLES2Implementation);
};

inline bool GLES2Implementation::GetBufferParameterivHelper(
    GLenum /* target */, GLenum /* pname */, GLint* /* params */) {
  return false;
}

inline bool GLES2Implementation::GetFramebufferAttachmentParameterivHelper(
    GLenum /* target */,
    GLenum /* attachment */,
    GLenum /* pname */,
    GLint* /* params */) {
  return false;
}

inline bool GLES2Implementation::GetRenderbufferParameterivHelper(
    GLenum /* target */, GLenum /* pname */, GLint* /* params */) {
  return false;
}

inline bool GLES2Implementation::GetShaderivHelper(
    GLuint /* shader */, GLenum /* pname */, GLint* /* params */) {
  return false;
}

inline bool GLES2Implementation::GetTexParameterfvHelper(
    GLenum /* target */, GLenum /* pname */, GLfloat* /* params */) {
  return false;
}

inline bool GLES2Implementation::GetTexParameterivHelper(
    GLenum /* target */, GLenum /* pname */, GLint* /* params */) {
  return false;
}

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_IMPLEMENTATION_H_
