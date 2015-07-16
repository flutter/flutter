// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the GLES2Decoder class.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_H_
#define GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_H_

#include <vector>

#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "build/build_config.h"
#include "gpu/command_buffer/common/capabilities.h"
#include "gpu/command_buffer/service/common_decoder.h"
#include "gpu/command_buffer/service/logger.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gl/gl_context.h"

namespace gfx {
class GLContext;
class GLSurface;
}

namespace gpu {

class AsyncPixelTransferDelegate;
class AsyncPixelTransferManager;
struct Mailbox;

namespace gles2 {

class ContextGroup;
class ErrorState;
class GLES2Util;
class ImageManager;
class Logger;
class QueryManager;
class Texture;
class VertexArrayManager;
class ValuebufferManager;
struct ContextState;

struct DisallowedFeatures {
  DisallowedFeatures()
      : gpu_memory_manager(false) {
  }

  bool gpu_memory_manager;
};

typedef base::Callback<void(const std::string& key,
                            const std::string& shader)> ShaderCacheCallback;

// This class implements the AsyncAPIInterface interface, decoding GLES2
// commands and calling GL.
class GPU_EXPORT GLES2Decoder : public base::SupportsWeakPtr<GLES2Decoder>,
                                public CommonDecoder {
 public:
  typedef error::Error Error;
  typedef base::Callback<bool(uint32 id)> WaitSyncPointCallback;

  // The default stencil mask, which has all bits set.  This really should be a
  // GLuint, but we can't #include gl_bindings.h in this file without causing
  // macro redefinitions.
  static const unsigned int kDefaultStencilMask;

  // Creates a decoder.
  static GLES2Decoder* Create(ContextGroup* group);

  ~GLES2Decoder() override;

  bool initialized() const {
    return initialized_;
  }

  void set_initialized() {
    initialized_ = true;
  }

  bool unsafe_es3_apis_enabled() const {
    return unsafe_es3_apis_enabled_;
  }

  void set_unsafe_es3_apis_enabled(bool enabled) {
    unsafe_es3_apis_enabled_ = enabled;
  }

  bool debug() const {
    return debug_;
  }

  // Set to true to call glGetError after every command.
  void set_debug(bool debug) {
    debug_ = debug;
  }

  bool log_commands() const {
    return log_commands_;
  }

  // Set to true to LOG every command.
  void set_log_commands(bool log_commands) {
    log_commands_ = log_commands;
  }

  // Initializes the graphics context. Can create an offscreen
  // decoder with a frame buffer that can be referenced from the parent.
  // Takes ownership of GLContext.
  // Parameters:
  //  surface: the GL surface to render to.
  //  context: the GL context to render to.
  //  offscreen: whether to make the context offscreen or not. When FBO 0 is
  //      bound, offscreen contexts render to an internal buffer, onscreen ones
  //      to the surface.
  //  offscreen_size: the size if the GL context is offscreen.
  // Returns:
  //   true if successful.
  virtual bool Initialize(const scoped_refptr<gfx::GLSurface>& surface,
                          const scoped_refptr<gfx::GLContext>& context,
                          bool offscreen,
                          const gfx::Size& offscreen_size,
                          const DisallowedFeatures& disallowed_features,
                          const std::vector<int32>& attribs) = 0;

  // Destroys the graphics context.
  virtual void Destroy(bool have_context) = 0;

  // Set the surface associated with the default FBO.
  virtual void SetSurface(const scoped_refptr<gfx::GLSurface>& surface) = 0;

  virtual void ProduceFrontBuffer(const Mailbox& mailbox) = 0;

  // Resize an offscreen frame buffer.
  virtual bool ResizeOffscreenFrameBuffer(const gfx::Size& size) = 0;

  // Make this decoder's GL context current.
  virtual bool MakeCurrent() = 0;

  // Gets the GLES2 Util which holds info.
  virtual GLES2Util* GetGLES2Util() = 0;

  // Gets the associated GLContext.
  virtual gfx::GLContext* GetGLContext() = 0;

  // Gets the associated ContextGroup
  virtual ContextGroup* GetContextGroup() = 0;

  virtual Capabilities GetCapabilities() = 0;

  // Restores all of the decoder GL state.
  virtual void RestoreState(const ContextState* prev_state) = 0;

  // Restore States.
  virtual void RestoreActiveTexture() const = 0;
  virtual void RestoreAllTextureUnitBindings(
      const ContextState* prev_state) const = 0;
  virtual void RestoreActiveTextureUnitBinding(unsigned int target) const = 0;
  virtual void RestoreBufferBindings() const = 0;
  virtual void RestoreFramebufferBindings() const = 0;
  virtual void RestoreRenderbufferBindings() = 0;
  virtual void RestoreGlobalState() const = 0;
  virtual void RestoreProgramBindings() const = 0;
  virtual void RestoreTextureState(unsigned service_id) const = 0;
  virtual void RestoreTextureUnitBindings(unsigned unit) const = 0;

  virtual void ClearAllAttributes() const = 0;
  virtual void RestoreAllAttributes() const = 0;

  virtual void SetIgnoreCachedStateForTest(bool ignore) = 0;

  // Gets the QueryManager for this context.
  virtual QueryManager* GetQueryManager() = 0;

  // Gets the VertexArrayManager for this context.
  virtual VertexArrayManager* GetVertexArrayManager() = 0;

  // Gets the ImageManager for this context.
  virtual ImageManager* GetImageManager() = 0;

  // Gets the ValuebufferManager for this context.
  virtual ValuebufferManager* GetValuebufferManager() = 0;

  // Process any pending queries. Returns false if there are no pending queries.
  virtual bool ProcessPendingQueries(bool did_finish) = 0;

  // Returns false if there are no idle work to be made.
  virtual bool HasMoreIdleWork() = 0;

  virtual void PerformIdleWork() = 0;

  // Sets a callback which is called when a glResizeCHROMIUM command
  // is processed.
  virtual void SetResizeCallback(
      const base::Callback<void(gfx::Size, float)>& callback) = 0;

  // Interface to performing async pixel transfers.
  virtual AsyncPixelTransferManager* GetAsyncPixelTransferManager() = 0;
  virtual void ResetAsyncPixelTransferManagerForTest() = 0;
  virtual void SetAsyncPixelTransferManagerForTest(
      AsyncPixelTransferManager* manager) = 0;

  // Get the service texture ID corresponding to a client texture ID.
  // If no such record is found then return false.
  virtual bool GetServiceTextureId(uint32 client_texture_id,
                                   uint32* service_texture_id);

  // Provides detail about a lost context if one occurred.
  virtual error::ContextLostReason GetContextLostReason() = 0;

  // Clears a level of a texture
  // Returns false if a GL error should be generated.
  virtual bool ClearLevel(
      Texture* texture,
      unsigned target,
      int level,
      unsigned internal_format,
      unsigned format,
      unsigned type,
      int width,
      int height,
      bool is_texture_immutable) = 0;

  virtual ErrorState* GetErrorState() = 0;

  // A callback for messages from the decoder.
  virtual void SetShaderCacheCallback(const ShaderCacheCallback& callback) = 0;

  // Sets the callback for waiting on a sync point. The callback returns the
  // scheduling status (i.e. true if the channel is still scheduled).
  virtual void SetWaitSyncPointCallback(
      const WaitSyncPointCallback& callback) = 0;

  virtual void WaitForReadPixels(base::Closure callback) = 0;
  virtual uint32 GetTextureUploadCount() = 0;
  virtual base::TimeDelta GetTotalTextureUploadTime() = 0;
  virtual base::TimeDelta GetTotalProcessingCommandsTime() = 0;
  virtual void AddProcessingCommandsTime(base::TimeDelta) = 0;

  // Returns true if the context was lost either by GL_ARB_robustness, forced
  // context loss or command buffer parse error.
  virtual bool WasContextLost() const = 0;

  // Returns true if the context was lost specifically by GL_ARB_robustness.
  virtual bool WasContextLostByRobustnessExtension() const = 0;

  // Lose this context.
  virtual void MarkContextLost(error::ContextLostReason reason) = 0;

  virtual Logger* GetLogger() = 0;

  virtual void BeginDecoding();
  virtual void EndDecoding();

  virtual const ContextState* GetContextState() = 0;

 protected:
  GLES2Decoder();

 private:
  bool initialized_;
  bool debug_;
  bool log_commands_;
  bool unsafe_es3_apis_enabled_;

  DISALLOW_COPY_AND_ASSIGN(GLES2Decoder);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GLES2_CMD_DECODER_H_
