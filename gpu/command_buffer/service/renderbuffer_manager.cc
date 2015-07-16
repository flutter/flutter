// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/renderbuffer_manager.h"

#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "base/trace_event/trace_event.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "ui/gl/gl_implementation.h"

namespace gpu {
namespace gles2 {

// This should contain everything to uniquely identify a Renderbuffer.
static const char RenderbufferTag[] = "|Renderbuffer|";
struct RenderbufferSignature {
  GLenum internal_format_;
  GLsizei samples_;
  GLsizei width_;
  GLsizei height_;

  // Since we will be hashing this signature structure, the padding must be
  // zero initialized. Although the C++11 specifications specify that this is
  // true, we will use a constructor with a memset to further enforce it instead
  // of relying on compilers adhering to this deep dark corner specification.
  RenderbufferSignature(GLenum internal_format,
                        GLsizei samples,
                        GLsizei width,
                        GLsizei height) {
    memset(this, 0, sizeof(RenderbufferSignature));
    internal_format_ = internal_format;
    samples_ = samples;
    width_ = width;
    height_ = height;
  }
};

RenderbufferManager::RenderbufferManager(
    MemoryTracker* memory_tracker,
    GLint max_renderbuffer_size,
    GLint max_samples,
    bool depth24_supported)
    : memory_tracker_(
          new MemoryTypeTracker(memory_tracker, MemoryTracker::kUnmanaged)),
      max_renderbuffer_size_(max_renderbuffer_size),
      max_samples_(max_samples),
      depth24_supported_(depth24_supported),
      num_uncleared_renderbuffers_(0),
      renderbuffer_count_(0),
      have_context_(true) {
}

RenderbufferManager::~RenderbufferManager() {
  DCHECK(renderbuffers_.empty());
  // If this triggers, that means something is keeping a reference to
  // a Renderbuffer belonging to this.
  CHECK_EQ(renderbuffer_count_, 0u);

  DCHECK_EQ(0, num_uncleared_renderbuffers_);
}

size_t Renderbuffer::EstimatedSize() {
  uint32 size = 0;
  manager_->ComputeEstimatedRenderbufferSize(
      width_, height_, samples_, internal_format_, &size);
  return size;
}


size_t Renderbuffer::GetSignatureSize() const {
  return sizeof(RenderbufferTag) + sizeof(RenderbufferSignature);
}

void Renderbuffer::AddToSignature(std::string* signature) const {
  DCHECK(signature);
  RenderbufferSignature signature_data(internal_format_,
                                       samples_,
                                       width_,
                                       height_);

  signature->append(RenderbufferTag, sizeof(RenderbufferTag));
  signature->append(reinterpret_cast<const char*>(&signature_data),
                    sizeof(signature_data));
}

Renderbuffer::Renderbuffer(RenderbufferManager* manager,
                           GLuint client_id,
                           GLuint service_id)
    : manager_(manager),
      client_id_(client_id),
      service_id_(service_id),
      cleared_(true),
      has_been_bound_(false),
      samples_(0),
      internal_format_(GL_RGBA4),
      width_(0),
      height_(0) {
  manager_->StartTracking(this);
}

Renderbuffer::~Renderbuffer() {
  if (manager_) {
    if (manager_->have_context_) {
      GLuint id = service_id();
      glDeleteRenderbuffersEXT(1, &id);
    }
    manager_->StopTracking(this);
    manager_ = NULL;
  }
}

void RenderbufferManager::Destroy(bool have_context) {
  have_context_ = have_context;
  renderbuffers_.clear();
  DCHECK_EQ(0u, memory_tracker_->GetMemRepresented());
}

void RenderbufferManager::StartTracking(Renderbuffer* /* renderbuffer */) {
  ++renderbuffer_count_;
}

void RenderbufferManager::StopTracking(Renderbuffer* renderbuffer) {
  --renderbuffer_count_;
  if (!renderbuffer->cleared()) {
    --num_uncleared_renderbuffers_;
  }
  memory_tracker_->TrackMemFree(renderbuffer->EstimatedSize());
}

void RenderbufferManager::SetInfo(
    Renderbuffer* renderbuffer,
    GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height) {
  DCHECK(renderbuffer);
  if (!renderbuffer->cleared()) {
    --num_uncleared_renderbuffers_;
  }
  memory_tracker_->TrackMemFree(renderbuffer->EstimatedSize());
  renderbuffer->SetInfo(samples, internalformat, width, height);
  memory_tracker_->TrackMemAlloc(renderbuffer->EstimatedSize());
  if (!renderbuffer->cleared()) {
    ++num_uncleared_renderbuffers_;
  }
}

void RenderbufferManager::SetCleared(Renderbuffer* renderbuffer,
                                     bool cleared) {
  DCHECK(renderbuffer);
  if (!renderbuffer->cleared()) {
    --num_uncleared_renderbuffers_;
  }
  renderbuffer->set_cleared(cleared);
  if (!renderbuffer->cleared()) {
    ++num_uncleared_renderbuffers_;
  }
}

void RenderbufferManager::CreateRenderbuffer(
    GLuint client_id, GLuint service_id) {
  scoped_refptr<Renderbuffer> renderbuffer(
      new Renderbuffer(this, client_id, service_id));
  std::pair<RenderbufferMap::iterator, bool> result =
      renderbuffers_.insert(std::make_pair(client_id, renderbuffer));
  DCHECK(result.second);
  if (!renderbuffer->cleared()) {
    ++num_uncleared_renderbuffers_;
  }
}

Renderbuffer* RenderbufferManager::GetRenderbuffer(
    GLuint client_id) {
  RenderbufferMap::iterator it = renderbuffers_.find(client_id);
  return it != renderbuffers_.end() ? it->second.get() : NULL;
}

void RenderbufferManager::RemoveRenderbuffer(GLuint client_id) {
  RenderbufferMap::iterator it = renderbuffers_.find(client_id);
  if (it != renderbuffers_.end()) {
    Renderbuffer* renderbuffer = it->second.get();
    renderbuffer->MarkAsDeleted();
    renderbuffers_.erase(it);
  }
}

bool RenderbufferManager::ComputeEstimatedRenderbufferSize(int width,
                                                           int height,
                                                           int samples,
                                                           int internal_format,
                                                           uint32* size) const {
  DCHECK(size);

  uint32 temp = 0;
  if (!SafeMultiplyUint32(width, height, &temp)) {
    return false;
  }
  if (!SafeMultiplyUint32(temp, samples, &temp)) {
    return false;
  }
  GLenum impl_format = InternalRenderbufferFormatToImplFormat(internal_format);
  if (!SafeMultiplyUint32(
      temp, GLES2Util::RenderbufferBytesPerPixel(impl_format), &temp)) {
    return false;
  }
  *size = temp;
  return true;
}

GLenum RenderbufferManager::InternalRenderbufferFormatToImplFormat(
    GLenum impl_format) const {
  if (gfx::GetGLImplementation() != gfx::kGLImplementationEGLGLES2) {
    switch (impl_format) {
      case GL_DEPTH_COMPONENT16:
        return GL_DEPTH_COMPONENT;
      case GL_RGBA4:
      case GL_RGB5_A1:
        return GL_RGBA;
      case GL_RGB565:
        return GL_RGB;
    }
  } else {
    // Upgrade 16-bit depth to 24-bit if possible.
    if (impl_format == GL_DEPTH_COMPONENT16 && depth24_supported_)
      return GL_DEPTH_COMPONENT24;
  }
  return impl_format;
}

}  // namespace gles2
}  // namespace gpu


