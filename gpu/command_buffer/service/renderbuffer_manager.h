// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_RENDERBUFFER_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_RENDERBUFFER_MANAGER_H_

#include <string>
#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

class RenderbufferManager;

// Info about a Renderbuffer.
class GPU_EXPORT Renderbuffer
    : public base::RefCounted<Renderbuffer> {
 public:
  Renderbuffer(RenderbufferManager* manager,
               GLuint client_id,
               GLuint service_id);

  GLuint service_id() const {
    return service_id_;
  }

  GLuint client_id() const {
    return client_id_;
  }

  bool cleared() const {
    return cleared_;
  }

  GLenum internal_format() const {
    return internal_format_;
  }

  GLsizei samples() const {
    return samples_;
  }

  GLsizei width() const {
    return width_;
  }

  GLsizei height() const {
    return height_;
  }

  bool IsDeleted() const {
    return client_id_ == 0;
  }

  void MarkAsValid() {
    has_been_bound_ = true;
  }

  bool IsValid() const {
    return has_been_bound_ && !IsDeleted();
  }

  size_t EstimatedSize();

  size_t GetSignatureSize() const;
  void AddToSignature(std::string* signature) const;

 private:
  friend class RenderbufferManager;
  friend class base::RefCounted<Renderbuffer>;

  ~Renderbuffer();

  void set_cleared(bool cleared) {
    cleared_ = cleared;
  }

  void SetInfo(
      GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height) {
    samples_ = samples;
    internal_format_ = internalformat;
    width_ = width;
    height_ = height;
    cleared_ = false;
  }

  void MarkAsDeleted() {
    client_id_ = 0;
  }

  // RenderbufferManager that owns this Renderbuffer.
  RenderbufferManager* manager_;

  // Client side renderbuffer id.
  GLuint client_id_;

  // Service side renderbuffer id.
  GLuint service_id_;

  // Whether this renderbuffer has been cleared
  bool cleared_;

  // Whether this renderbuffer has ever been bound.
  bool has_been_bound_;

  // Number of samples (for multi-sampled renderbuffers)
  GLsizei samples_;

  // Renderbuffer internalformat set through RenderbufferStorage().
  GLenum internal_format_;

  // Dimensions of renderbuffer.
  GLsizei width_;
  GLsizei height_;
};

// This class keeps track of the renderbuffers and whether or not they have
// been cleared.
class GPU_EXPORT RenderbufferManager {
 public:
  RenderbufferManager(MemoryTracker* memory_tracker,
                      GLint max_renderbuffer_size,
                      GLint max_samples,
                      bool depth24_supported);
  ~RenderbufferManager();

  GLint max_renderbuffer_size() const {
    return max_renderbuffer_size_;
  }

  GLint max_samples() const {
    return max_samples_;
  }

  bool HaveUnclearedRenderbuffers() const {
    return num_uncleared_renderbuffers_ != 0;
  }

  void SetInfo(
      Renderbuffer* renderbuffer,
      GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);

  void SetCleared(Renderbuffer* renderbuffer, bool cleared);

  // Must call before destruction.
  void Destroy(bool have_context);

  // Creates a Renderbuffer for the given renderbuffer ids.
  void CreateRenderbuffer(GLuint client_id, GLuint service_id);

  // Gets the renderbuffer for the given renderbuffer id.
  Renderbuffer* GetRenderbuffer(GLuint client_id);

  // Removes a renderbuffer for the given renderbuffer id.
  void RemoveRenderbuffer(GLuint client_id);

  size_t mem_represented() const {
    return memory_tracker_->GetMemRepresented();
  }

  bool ComputeEstimatedRenderbufferSize(int width,
                                        int height,
                                        int samples,
                                        int internal_format,
                                        uint32* size) const;
  GLenum InternalRenderbufferFormatToImplFormat(GLenum impl_format) const;

 private:
  friend class Renderbuffer;

  void StartTracking(Renderbuffer* renderbuffer);
  void StopTracking(Renderbuffer* renderbuffer);

  scoped_ptr<MemoryTypeTracker> memory_tracker_;

  GLint max_renderbuffer_size_;
  GLint max_samples_;
  bool depth24_supported_;

  int num_uncleared_renderbuffers_;

  // Counts the number of Renderbuffer allocated with 'this' as its manager.
  // Allows to check no Renderbuffer will outlive this.
  unsigned renderbuffer_count_;

  bool have_context_;

  // Info for each renderbuffer in the system.
  typedef base::hash_map<GLuint, scoped_refptr<Renderbuffer> > RenderbufferMap;
  RenderbufferMap renderbuffers_;

  DISALLOW_COPY_AND_ASSIGN(RenderbufferManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_RENDERBUFFER_MANAGER_H_
