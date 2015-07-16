// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/buffer_manager.h"
#include <limits>
#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/context_state.h"
#include "gpu/command_buffer/service/error_state.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"

namespace gpu {
namespace gles2 {

BufferManager::BufferManager(
    MemoryTracker* memory_tracker,
    FeatureInfo* feature_info)
    : memory_tracker_(
          new MemoryTypeTracker(memory_tracker, MemoryTracker::kManaged)),
      feature_info_(feature_info),
      allow_buffers_on_multiple_targets_(false),
      allow_fixed_attribs_(false),
      buffer_count_(0),
      have_context_(true),
      use_client_side_arrays_for_stream_buffers_(
          feature_info ? feature_info->workarounds(
              ).use_client_side_arrays_for_stream_buffers : 0) {
}

BufferManager::~BufferManager() {
  DCHECK(buffers_.empty());
  CHECK_EQ(buffer_count_, 0u);
}

void BufferManager::Destroy(bool have_context) {
  have_context_ = have_context;
  buffers_.clear();
  DCHECK_EQ(0u, memory_tracker_->GetMemRepresented());
}

void BufferManager::CreateBuffer(GLuint client_id, GLuint service_id) {
  scoped_refptr<Buffer> buffer(new Buffer(this, service_id));
  std::pair<BufferMap::iterator, bool> result =
      buffers_.insert(std::make_pair(client_id, buffer));
  DCHECK(result.second);
}

Buffer* BufferManager::GetBuffer(
    GLuint client_id) {
  BufferMap::iterator it = buffers_.find(client_id);
  return it != buffers_.end() ? it->second.get() : NULL;
}

void BufferManager::RemoveBuffer(GLuint client_id) {
  BufferMap::iterator it = buffers_.find(client_id);
  if (it != buffers_.end()) {
    Buffer* buffer = it->second.get();
    buffer->MarkAsDeleted();
    buffers_.erase(it);
  }
}

void BufferManager::StartTracking(Buffer* /* buffer */) {
  ++buffer_count_;
}

void BufferManager::StopTracking(Buffer* buffer) {
  memory_tracker_->TrackMemFree(buffer->size());
  --buffer_count_;
}

Buffer::MappedRange::MappedRange(
    GLintptr offset, GLsizeiptr size, GLenum access, void* pointer,
    scoped_refptr<gpu::Buffer> shm)
    : offset(offset),
      size(size),
      access(access),
      pointer(pointer),
      shm(shm) {
  DCHECK(pointer);
  DCHECK(shm.get() && GetShmPointer());
}

Buffer::MappedRange::~MappedRange() {
}

void* Buffer::MappedRange::GetShmPointer() const {
  DCHECK(shm.get());
  return shm->GetDataAddress(static_cast<unsigned int>(offset),
                             static_cast<unsigned int>(size));
}

Buffer::Buffer(BufferManager* manager, GLuint service_id)
    : manager_(manager),
      size_(0),
      deleted_(false),
      shadowed_(false),
      is_client_side_array_(false),
      service_id_(service_id),
      target_(0),
      usage_(GL_STATIC_DRAW) {
  manager_->StartTracking(this);
}

Buffer::~Buffer() {
  if (manager_) {
    if (manager_->have_context_) {
      GLuint id = service_id();
      glDeleteBuffersARB(1, &id);
    }
    manager_->StopTracking(this);
    manager_ = NULL;
  }
}

void Buffer::SetInfo(
    GLsizeiptr size, GLenum usage, bool shadow, const GLvoid* data,
    bool is_client_side_array) {
  usage_ = usage;
  is_client_side_array_ = is_client_side_array;
  ClearCache();
  if (size != size_ || shadow != shadowed_) {
    shadowed_ = shadow;
    size_ = size;
    if (shadowed_) {
      shadow_.reset(new int8[size]);
    } else {
      shadow_.reset();
    }
  }
  if (shadowed_) {
    if (data) {
      memcpy(shadow_.get(), data, size);
    } else {
      memset(shadow_.get(), 0, size);
    }
  }
  mapped_range_.reset(nullptr);
}

bool Buffer::CheckRange(
    GLintptr offset, GLsizeiptr size) const {
  int32 end = 0;
  return offset >= 0 && size >= 0 &&
         offset <= std::numeric_limits<int32>::max() &&
         size <= std::numeric_limits<int32>::max() &&
         SafeAddInt32(offset, size, &end) && end <= size_;
}

bool Buffer::SetRange(
    GLintptr offset, GLsizeiptr size, const GLvoid * data) {
  if (!CheckRange(offset, size)) {
    return false;
  }
  if (shadowed_) {
    memcpy(shadow_.get() + offset, data, size);
    ClearCache();
  }
  return true;
}

const void* Buffer::GetRange(
    GLintptr offset, GLsizeiptr size) const {
  if (!shadowed_) {
    return NULL;
  }
  if (!CheckRange(offset, size)) {
    return NULL;
  }
  return shadow_.get() + offset;
}

void Buffer::ClearCache() {
  range_set_.clear();
}

template <typename T>
GLuint GetMaxValue(const void* data, GLuint offset, GLsizei count) {
  GLuint max_value = 0;
  const T* element = reinterpret_cast<const T*>(
      static_cast<const int8*>(data) + offset);
  const T* end = element + count;
  for (; element < end; ++element) {
    if (*element > max_value) {
      max_value = *element;
    }
  }
  return max_value;
}

bool Buffer::GetMaxValueForRange(
    GLuint offset, GLsizei count, GLenum type, GLuint* max_value) {
  Range range(offset, count, type);
  RangeToMaxValueMap::iterator it = range_set_.find(range);
  if (it != range_set_.end()) {
    *max_value = it->second;
    return true;
  }

  uint32 size;
  if (!SafeMultiplyUint32(
      count, GLES2Util::GetGLTypeSizeForTexturesAndBuffers(type), &size)) {
    return false;
  }

  if (!SafeAddUint32(offset, size, &size)) {
    return false;
  }

  if (size > static_cast<uint32>(size_)) {
    return false;
  }

  if (!shadowed_) {
    return false;
  }

  // Scan the range for the max value and store
  GLuint max_v = 0;
  switch (type) {
    case GL_UNSIGNED_BYTE:
      max_v = GetMaxValue<uint8>(shadow_.get(), offset, count);
      break;
    case GL_UNSIGNED_SHORT:
      // Check we are not accessing an odd byte for a 2 byte value.
      if ((offset & 1) != 0) {
        return false;
      }
      max_v = GetMaxValue<uint16>(shadow_.get(), offset, count);
      break;
    case GL_UNSIGNED_INT:
      // Check we are not accessing a non aligned address for a 4 byte value.
      if ((offset & 3) != 0) {
        return false;
      }
      max_v = GetMaxValue<uint32>(shadow_.get(), offset, count);
      break;
    default:
      NOTREACHED();  // should never get here by validation.
      break;
  }
  range_set_.insert(std::make_pair(range, max_v));
  *max_value = max_v;
  return true;
}

bool BufferManager::GetClientId(GLuint service_id, GLuint* client_id) const {
  // This doesn't need to be fast. It's only used during slow queries.
  for (BufferMap::const_iterator it = buffers_.begin();
       it != buffers_.end(); ++it) {
    if (it->second->service_id() == service_id) {
      *client_id = it->first;
      return true;
    }
  }
  return false;
}

bool BufferManager::IsUsageClientSideArray(GLenum usage) {
  return usage == GL_STREAM_DRAW && use_client_side_arrays_for_stream_buffers_;
}

bool BufferManager::UseNonZeroSizeForClientSideArrayBuffer() {
  return feature_info_.get() &&
         feature_info_->workarounds()
             .use_non_zero_size_for_client_side_stream_buffers;
}

void BufferManager::SetInfo(
    Buffer* buffer, GLsizeiptr size, GLenum usage, const GLvoid* data) {
  DCHECK(buffer);
  memory_tracker_->TrackMemFree(buffer->size());
  const bool is_client_side_array = IsUsageClientSideArray(usage);
  const bool support_fixed_attribs =
    gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2;
  const bool shadow = buffer->target() == GL_ELEMENT_ARRAY_BUFFER ||
                      allow_buffers_on_multiple_targets_ ||
                      (allow_fixed_attribs_ && !support_fixed_attribs) ||
                      is_client_side_array;
  buffer->SetInfo(size, usage, shadow, data, is_client_side_array);
  memory_tracker_->TrackMemAlloc(buffer->size());
}

void BufferManager::ValidateAndDoBufferData(
    ContextState* context_state, GLenum target, GLsizeiptr size,
    const GLvoid * data, GLenum usage) {
  ErrorState* error_state = context_state->GetErrorState();
  if (!feature_info_->validators()->buffer_target.IsValid(target)) {
    ERRORSTATE_SET_GL_ERROR_INVALID_ENUM(
        error_state, "glBufferData", target, "target");
    return;
  }
  if (!feature_info_->validators()->buffer_usage.IsValid(usage)) {
    ERRORSTATE_SET_GL_ERROR_INVALID_ENUM(
        error_state, "glBufferData", usage, "usage");
    return;
  }
  if (size < 0) {
    ERRORSTATE_SET_GL_ERROR(
        error_state, GL_INVALID_VALUE, "glBufferData", "size < 0");
    return;
  }

  Buffer* buffer = GetBufferInfoForTarget(context_state, target);
  if (!buffer) {
    ERRORSTATE_SET_GL_ERROR(
        error_state, GL_INVALID_VALUE, "glBufferData", "unknown buffer");
    return;
  }

  if (!memory_tracker_->EnsureGPUMemoryAvailable(size)) {
    ERRORSTATE_SET_GL_ERROR(
        error_state, GL_OUT_OF_MEMORY, "glBufferData", "out of memory");
    return;
  }

  DoBufferData(error_state, buffer, size, usage, data);
}


void BufferManager::DoBufferData(
    ErrorState* error_state,
    Buffer* buffer,
    GLsizeiptr size,
    GLenum usage,
    const GLvoid* data) {
  // Clear the buffer to 0 if no initial data was passed in.
  scoped_ptr<int8[]> zero;
  if (!data) {
    zero.reset(new int8[size]);
    memset(zero.get(), 0, size);
    data = zero.get();
  }

  ERRORSTATE_COPY_REAL_GL_ERRORS_TO_WRAPPER(error_state, "glBufferData");
  if (IsUsageClientSideArray(usage)) {
    GLsizei empty_size = UseNonZeroSizeForClientSideArrayBuffer() ? 1 : 0;
    glBufferData(buffer->target(), empty_size, NULL, usage);
  } else {
    glBufferData(buffer->target(), size, data, usage);
  }
  GLenum error = ERRORSTATE_PEEK_GL_ERROR(error_state, "glBufferData");
  if (error == GL_NO_ERROR) {
    SetInfo(buffer, size, usage, data);
  } else {
    SetInfo(buffer, 0, usage, NULL);
  }
}

void BufferManager::ValidateAndDoBufferSubData(
  ContextState* context_state, GLenum target, GLintptr offset, GLsizeiptr size,
  const GLvoid * data) {
  ErrorState* error_state = context_state->GetErrorState();
  Buffer* buffer = GetBufferInfoForTarget(context_state, target);
  if (!buffer) {
    ERRORSTATE_SET_GL_ERROR(error_state, GL_INVALID_VALUE, "glBufferSubData",
                            "unknown buffer");
    return;
  }

  DoBufferSubData(error_state, buffer, offset, size, data);
}

void BufferManager::DoBufferSubData(
    ErrorState* error_state,
    Buffer* buffer,
    GLintptr offset,
    GLsizeiptr size,
    const GLvoid* data) {
  if (!buffer->SetRange(offset, size, data)) {
    ERRORSTATE_SET_GL_ERROR(
        error_state, GL_INVALID_VALUE, "glBufferSubData", "out of range");
    return;
  }

  if (!buffer->IsClientSideArray()) {
    glBufferSubData(buffer->target(), offset, size, data);
  }
}

void BufferManager::ValidateAndDoGetBufferParameteriv(
    ContextState* context_state, GLenum target, GLenum pname, GLint* params) {
  Buffer* buffer = GetBufferInfoForTarget(context_state, target);
  if (!buffer) {
    ERRORSTATE_SET_GL_ERROR(
        context_state->GetErrorState(), GL_INVALID_OPERATION,
        "glGetBufferParameteriv", "no buffer bound for target");
    return;
  }
  switch (pname) {
    case GL_BUFFER_SIZE:
      *params = buffer->size();
      break;
    case GL_BUFFER_USAGE:
      *params = buffer->usage();
      break;
    default:
      NOTREACHED();
  }
}

bool BufferManager::SetTarget(Buffer* buffer, GLenum target) {
  // Check that we are not trying to bind it to a different target.
  if (buffer->target() != 0 && buffer->target() != target &&
      !allow_buffers_on_multiple_targets_) {
    return false;
  }
  if (buffer->target() == 0) {
    buffer->set_target(target);
  }
  return true;
}

// Since one BufferManager can be shared by multiple decoders, ContextState is
// passed in each time and not just passed in during initialization.
Buffer* BufferManager::GetBufferInfoForTarget(
    ContextState* state, GLenum target) const {
  switch (target) {
    case GL_ARRAY_BUFFER:
      return state->bound_array_buffer.get();
    case GL_ELEMENT_ARRAY_BUFFER:
      return state->vertex_attrib_manager->element_array_buffer();
    case GL_COPY_READ_BUFFER:
    case GL_COPY_WRITE_BUFFER:
    case GL_PIXEL_PACK_BUFFER:
    case GL_PIXEL_UNPACK_BUFFER:
    case GL_TRANSFORM_FEEDBACK_BUFFER:
    case GL_UNIFORM_BUFFER:
      NOTIMPLEMENTED();
      return nullptr;
    default:
      NOTREACHED();
      return nullptr;
  }
}

}  // namespace gles2
}  // namespace gpu


