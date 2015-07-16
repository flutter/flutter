// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A class to emulate GLES2 over command buffers.

#include "gpu/command_buffer/client/gles2_implementation.h"

#include <GLES2/gl2ext.h>
#include <GLES2/gl2extchromium.h>
#include <GLES3/gl3.h>
#include <algorithm>
#include <limits>
#include <map>
#include <queue>
#include <set>
#include <sstream>
#include <string>
#include "base/bind.h"
#include "base/compiler_specific.h"
#include "base/numerics/safe_math.h"
#include "gpu/command_buffer/client/buffer_tracker.h"
#include "gpu/command_buffer/client/gpu_control.h"
#include "gpu/command_buffer/client/program_info_manager.h"
#include "gpu/command_buffer/client/query_tracker.h"
#include "gpu/command_buffer/client/transfer_buffer.h"
#include "gpu/command_buffer/client/vertex_array_object_manager.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/common/trace_event.h"

#if defined(GPU_CLIENT_DEBUG)
#include "base/command_line.h"
#include "gpu/command_buffer/client/gpu_switches.h"
#endif

namespace gpu {
namespace gles2 {

// A 32-bit and 64-bit compatible way of converting a pointer to a GLuint.
static GLuint ToGLuint(const void* ptr) {
  return static_cast<GLuint>(reinterpret_cast<size_t>(ptr));
}

#if !defined(_MSC_VER)
const size_t GLES2Implementation::kMaxSizeOfSimpleResult;
const unsigned int GLES2Implementation::kStartingOffset;
#endif

GLES2Implementation::GLStaticState::GLStaticState() {
}

GLES2Implementation::GLStaticState::~GLStaticState() {
}

GLES2Implementation::SingleThreadChecker::SingleThreadChecker(
    GLES2Implementation* gles2_implementation)
    : gles2_implementation_(gles2_implementation) {
  CHECK_EQ(0, gles2_implementation_->use_count_);
  ++gles2_implementation_->use_count_;
}

GLES2Implementation::SingleThreadChecker::~SingleThreadChecker() {
  --gles2_implementation_->use_count_;
  CHECK_EQ(0, gles2_implementation_->use_count_);
}

GLES2Implementation::GLES2Implementation(
    GLES2CmdHelper* helper,
    ShareGroup* share_group,
    TransferBufferInterface* transfer_buffer,
    bool bind_generates_resource,
    bool lose_context_when_out_of_memory,
    bool support_client_side_arrays,
    GpuControl* gpu_control)
    : helper_(helper),
      transfer_buffer_(transfer_buffer),
      angle_pack_reverse_row_order_status_(kUnknownExtensionStatus),
      chromium_framebuffer_multisample_(kUnknownExtensionStatus),
      pack_alignment_(4),
      unpack_alignment_(4),
      unpack_flip_y_(false),
      unpack_row_length_(0),
      unpack_image_height_(0),
      unpack_skip_rows_(0),
      unpack_skip_pixels_(0),
      unpack_skip_images_(0),
      pack_reverse_row_order_(false),
      active_texture_unit_(0),
      bound_framebuffer_(0),
      bound_read_framebuffer_(0),
      bound_renderbuffer_(0),
      bound_valuebuffer_(0),
      current_program_(0),
      bound_array_buffer_id_(0),
      bound_pixel_pack_transfer_buffer_id_(0),
      bound_pixel_unpack_transfer_buffer_id_(0),
      async_upload_token_(0),
      async_upload_sync_(NULL),
      async_upload_sync_shm_id_(0),
      async_upload_sync_shm_offset_(0),
      error_bits_(0),
      debug_(false),
      lose_context_when_out_of_memory_(lose_context_when_out_of_memory),
      support_client_side_arrays_(support_client_side_arrays),
      use_count_(0),
      error_message_callback_(NULL),
      current_trace_stack_(0),
      gpu_control_(gpu_control),
      capabilities_(gpu_control->GetCapabilities()),
      weak_ptr_factory_(this) {
  DCHECK(helper);
  DCHECK(transfer_buffer);
  DCHECK(gpu_control);

  std::stringstream ss;
  ss << std::hex << this;
  this_in_hex_ = ss.str();

  GPU_CLIENT_LOG_CODE_BLOCK({
    debug_ = base::CommandLine::ForCurrentProcess()->HasSwitch(
        switches::kEnableGPUClientLogging);
  });

  share_group_ =
      (share_group ? share_group : new ShareGroup(bind_generates_resource));
  DCHECK(share_group_->bind_generates_resource() == bind_generates_resource);

  memset(&reserved_ids_, 0, sizeof(reserved_ids_));
}

bool GLES2Implementation::Initialize(
    unsigned int starting_transfer_buffer_size,
    unsigned int min_transfer_buffer_size,
    unsigned int max_transfer_buffer_size,
    unsigned int mapped_memory_limit) {
  TRACE_EVENT0("gpu", "GLES2Implementation::Initialize");
  DCHECK_GE(starting_transfer_buffer_size, min_transfer_buffer_size);
  DCHECK_LE(starting_transfer_buffer_size, max_transfer_buffer_size);
  DCHECK_GE(min_transfer_buffer_size, kStartingOffset);

  if (!transfer_buffer_->Initialize(
      starting_transfer_buffer_size,
      kStartingOffset,
      min_transfer_buffer_size,
      max_transfer_buffer_size,
      kAlignment,
      kSizeToFlush)) {
    return false;
  }

  mapped_memory_.reset(
      new MappedMemoryManager(
          helper_,
          base::Bind(&GLES2Implementation::PollAsyncUploads,
                     // The mapped memory manager is owned by |this| here, and
                     // since its destroyed before before we destroy ourselves
                     // we don't need extra safety measures for this closure.
                     base::Unretained(this)),
          mapped_memory_limit));

  unsigned chunk_size = 2 * 1024 * 1024;
  if (mapped_memory_limit != kNoLimit) {
    // Use smaller chunks if the client is very memory conscientious.
    chunk_size = std::min(mapped_memory_limit / 4, chunk_size);
  }
  mapped_memory_->set_chunk_size_multiple(chunk_size);

  GLStaticState::ShaderPrecisionMap* shader_precisions =
      &static_state_.shader_precisions;
  capabilities_.VisitPrecisions([shader_precisions](
      GLenum shader, GLenum type, Capabilities::ShaderPrecision* result) {
    const GLStaticState::ShaderPrecisionKey key(shader, type);
    cmds::GetShaderPrecisionFormat::Result cached_result = {
        true, result->min_range, result->max_range, result->precision};
    shader_precisions->insert(std::make_pair(key, cached_result));
  });

  util_.set_num_compressed_texture_formats(
      capabilities_.num_compressed_texture_formats);
  util_.set_num_shader_binary_formats(capabilities_.num_shader_binary_formats);

  texture_units_.reset(
      new TextureUnit[capabilities_.max_combined_texture_image_units]);

  query_tracker_.reset(new QueryTracker(mapped_memory_.get()));
  buffer_tracker_.reset(new BufferTracker(mapped_memory_.get()));

  query_id_allocator_.reset(new IdAllocator());
  if (support_client_side_arrays_) {
    GetIdHandler(id_namespaces::kBuffers)->MakeIds(
       this, kClientSideArrayId, arraysize(reserved_ids_), &reserved_ids_[0]);
  }

  vertex_array_object_manager_.reset(new VertexArrayObjectManager(
      capabilities_.max_vertex_attribs, reserved_ids_[0], reserved_ids_[1],
      support_client_side_arrays_));

  // GL_BIND_GENERATES_RESOURCE_CHROMIUM state must be the same
  // on Client & Service.
  if (capabilities_.bind_generates_resource_chromium !=
      (share_group_->bind_generates_resource() ? 1 : 0)) {
    SetGLError(GL_INVALID_OPERATION,
               "Initialize",
               "Service bind_generates_resource mismatch.");
    return false;
  }

  return true;
}

GLES2Implementation::~GLES2Implementation() {
  // Make sure the queries are finished otherwise we'll delete the
  // shared memory (mapped_memory_) which will free the memory used
  // by the queries. The GPU process when validating that memory is still
  // shared will fail and abort (ie, it will stop running).
  WaitForCmd();
  query_tracker_.reset();

  // GLES2Implementation::Initialize() could fail before allocating
  // reserved_ids_, so we need delete them carefully.
  if (support_client_side_arrays_ && reserved_ids_[0]) {
    DeleteBuffers(arraysize(reserved_ids_), &reserved_ids_[0]);
  }

  // Release remaining BufferRange mem; This is when a MapBufferRange() is
  // called but not the UnmapBuffer() pair.
  ClearMappedBufferRangeMap();

  // Release any per-context data in share group.
  share_group_->FreeContext(this);

  buffer_tracker_.reset();

  FreeAllAsyncUploadBuffers();

  if (async_upload_sync_) {
    mapped_memory_->Free(async_upload_sync_);
    async_upload_sync_ = NULL;
  }

  // Make sure the commands make it the service.
  WaitForCmd();
}

GLES2CmdHelper* GLES2Implementation::helper() const {
  return helper_;
}

IdHandlerInterface* GLES2Implementation::GetIdHandler(int namespace_id) const {
  return share_group_->GetIdHandler(namespace_id);
}

IdAllocator* GLES2Implementation::GetIdAllocator(int namespace_id) const {
  if (namespace_id == id_namespaces::kQueries)
    return query_id_allocator_.get();
  NOTREACHED();
  return NULL;
}

void* GLES2Implementation::GetResultBuffer() {
  return transfer_buffer_->GetResultBuffer();
}

int32 GLES2Implementation::GetResultShmId() {
  return transfer_buffer_->GetShmId();
}

uint32 GLES2Implementation::GetResultShmOffset() {
  return transfer_buffer_->GetResultOffset();
}

void GLES2Implementation::FreeUnusedSharedMemory() {
  mapped_memory_->FreeUnused();
}

void GLES2Implementation::FreeEverything() {
  FreeAllAsyncUploadBuffers();
  WaitForCmd();
  query_tracker_->Shrink();
  FreeUnusedSharedMemory();
  transfer_buffer_->Free();
  helper_->FreeRingBuffer();
}

void GLES2Implementation::RunIfContextNotLost(const base::Closure& callback) {
  if (!helper_->IsContextLost())
    callback.Run();
}

void GLES2Implementation::SignalSyncPoint(uint32 sync_point,
                                          const base::Closure& callback) {
  gpu_control_->SignalSyncPoint(
      sync_point,
      base::Bind(&GLES2Implementation::RunIfContextNotLost,
                 weak_ptr_factory_.GetWeakPtr(),
                 callback));
}

void GLES2Implementation::SignalQuery(uint32 query,
                                      const base::Closure& callback) {
  // Flush previously entered commands to ensure ordering with any
  // glBeginQueryEXT() calls that may have been put into the context.
  ShallowFlushCHROMIUM();
  gpu_control_->SignalQuery(
      query,
      base::Bind(&GLES2Implementation::RunIfContextNotLost,
                 weak_ptr_factory_.GetWeakPtr(),
                 callback));
}

void GLES2Implementation::SetSurfaceVisible(bool visible) {
  TRACE_EVENT1(
      "gpu", "GLES2Implementation::SetSurfaceVisible", "visible", visible);
  // TODO(piman): This probably should be ShallowFlushCHROMIUM().
  Flush();
  gpu_control_->SetSurfaceVisible(visible);
  if (!visible)
    FreeEverything();
}

void GLES2Implementation::WaitForCmd() {
  TRACE_EVENT0("gpu", "GLES2::WaitForCmd");
  helper_->CommandBufferHelper::Finish();
}

bool GLES2Implementation::IsExtensionAvailable(const char* ext) {
  const char* extensions =
      reinterpret_cast<const char*>(GetStringHelper(GL_EXTENSIONS));
  if (!extensions)
    return false;

  int length = strlen(ext);
  while (true) {
    int n = strcspn(extensions, " ");
    if (n == length && 0 == strncmp(ext, extensions, length)) {
      return true;
    }
    if ('\0' == extensions[n]) {
      return false;
    }
    extensions += n + 1;
  }
}

bool GLES2Implementation::IsExtensionAvailableHelper(
    const char* extension, ExtensionStatus* status) {
  switch (*status) {
    case kAvailableExtensionStatus:
      return true;
    case kUnavailableExtensionStatus:
      return false;
    default: {
      bool available = IsExtensionAvailable(extension);
      *status = available ? kAvailableExtensionStatus :
                            kUnavailableExtensionStatus;
      return available;
    }
  }
}

bool GLES2Implementation::IsAnglePackReverseRowOrderAvailable() {
  return IsExtensionAvailableHelper(
      "GL_ANGLE_pack_reverse_row_order",
      &angle_pack_reverse_row_order_status_);
}

bool GLES2Implementation::IsChromiumFramebufferMultisampleAvailable() {
  return IsExtensionAvailableHelper(
      "GL_CHROMIUM_framebuffer_multisample",
      &chromium_framebuffer_multisample_);
}

const std::string& GLES2Implementation::GetLogPrefix() const {
  const std::string& prefix(debug_marker_manager_.GetMarker());
  return prefix.empty() ? this_in_hex_ : prefix;
}

GLenum GLES2Implementation::GetError() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetError()");
  GLenum err = GetGLError();
  GPU_CLIENT_LOG("returned " << GLES2Util::GetStringError(err));
  return err;
}

GLenum GLES2Implementation::GetClientSideGLError() {
  if (error_bits_ == 0) {
    return GL_NO_ERROR;
  }

  GLenum error = GL_NO_ERROR;
  for (uint32 mask = 1; mask != 0; mask = mask << 1) {
    if ((error_bits_ & mask) != 0) {
      error = GLES2Util::GLErrorBitToGLError(mask);
      break;
    }
  }
  error_bits_ &= ~GLES2Util::GLErrorToErrorBit(error);
  return error;
}

GLenum GLES2Implementation::GetGLError() {
  TRACE_EVENT0("gpu", "GLES2::GetGLError");
  // Check the GL error first, then our wrapped error.
  typedef cmds::GetError::Result Result;
  Result* result = GetResultAs<Result*>();
  // If we couldn't allocate a result the context is lost.
  if (!result) {
    return GL_NO_ERROR;
  }
  *result = GL_NO_ERROR;
  helper_->GetError(GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  GLenum error = *result;
  if (error == GL_NO_ERROR) {
    error = GetClientSideGLError();
  } else {
    // There was an error, clear the corresponding wrapped error.
    error_bits_ &= ~GLES2Util::GLErrorToErrorBit(error);
  }
  return error;
}

#if defined(GL_CLIENT_FAIL_GL_ERRORS)
void GLES2Implementation::FailGLError(GLenum error) {
  if (error != GL_NO_ERROR) {
    NOTREACHED() << "Error";
  }
}
// NOTE: Calling GetGLError overwrites data in the result buffer.
void GLES2Implementation::CheckGLError() {
  FailGLError(GetGLError());
}
#endif  // defined(GPU_CLIENT_FAIL_GL_ERRORS)

void GLES2Implementation::SetGLError(
    GLenum error, const char* function_name, const char* msg) {
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] Client Synthesized Error: "
                 << GLES2Util::GetStringError(error) << ": "
                 << function_name << ": " << msg);
  FailGLError(error);
  if (msg) {
    last_error_ = msg;
  }
  if (error_message_callback_) {
    std::string temp(GLES2Util::GetStringError(error)  + " : " +
                     function_name + ": " + (msg ? msg : ""));
    error_message_callback_->OnErrorMessage(temp.c_str(), 0);
  }
  error_bits_ |= GLES2Util::GLErrorToErrorBit(error);

  if (error == GL_OUT_OF_MEMORY && lose_context_when_out_of_memory_) {
    helper_->LoseContextCHROMIUM(GL_GUILTY_CONTEXT_RESET_ARB,
                                 GL_UNKNOWN_CONTEXT_RESET_ARB);
  }
}

void GLES2Implementation::SetGLErrorInvalidEnum(
    const char* function_name, GLenum value, const char* label) {
  SetGLError(GL_INVALID_ENUM, function_name,
             (std::string(label) + " was " +
              GLES2Util::GetStringEnum(value)).c_str());
}

bool GLES2Implementation::GetBucketContents(uint32 bucket_id,
                                            std::vector<int8>* data) {
  TRACE_EVENT0("gpu", "GLES2::GetBucketContents");
  DCHECK(data);
  const uint32 kStartSize = 32 * 1024;
  ScopedTransferBufferPtr buffer(kStartSize, helper_, transfer_buffer_);
  if (!buffer.valid()) {
    return false;
  }
  typedef cmd::GetBucketStart::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  *result = 0;
  helper_->GetBucketStart(
      bucket_id, GetResultShmId(), GetResultShmOffset(),
      buffer.size(), buffer.shm_id(), buffer.offset());
  WaitForCmd();
  uint32 size = *result;
  data->resize(size);
  if (size > 0u) {
    uint32 offset = 0;
    while (size) {
      if (!buffer.valid()) {
        buffer.Reset(size);
        if (!buffer.valid()) {
          return false;
        }
        helper_->GetBucketData(
            bucket_id, offset, buffer.size(), buffer.shm_id(), buffer.offset());
        WaitForCmd();
      }
      uint32 size_to_copy = std::min(size, buffer.size());
      memcpy(&(*data)[offset], buffer.address(), size_to_copy);
      offset += size_to_copy;
      size -= size_to_copy;
      buffer.Release();
    }
    // Free the bucket. This is not required but it does free up the memory.
    // and we don't have to wait for the result so from the client's perspective
    // it's cheap.
    helper_->SetBucketSize(bucket_id, 0);
  }
  return true;
}

void GLES2Implementation::SetBucketContents(
    uint32 bucket_id, const void* data, size_t size) {
  DCHECK(data);
  helper_->SetBucketSize(bucket_id, size);
  if (size > 0u) {
    uint32 offset = 0;
    while (size) {
      ScopedTransferBufferPtr buffer(size, helper_, transfer_buffer_);
      if (!buffer.valid()) {
        return;
      }
      memcpy(buffer.address(), static_cast<const int8*>(data) + offset,
             buffer.size());
      helper_->SetBucketData(
          bucket_id, offset, buffer.size(), buffer.shm_id(), buffer.offset());
      offset += buffer.size();
      size -= buffer.size();
    }
  }
}

void GLES2Implementation::SetBucketAsCString(
    uint32 bucket_id, const char* str) {
  // NOTE: strings are passed NULL terminated. That means the empty
  // string will have a size of 1 and no-string will have a size of 0
  if (str) {
    SetBucketContents(bucket_id, str, strlen(str) + 1);
  } else {
    helper_->SetBucketSize(bucket_id, 0);
  }
}

bool GLES2Implementation::GetBucketAsString(
    uint32 bucket_id, std::string* str) {
  DCHECK(str);
  std::vector<int8> data;
  // NOTE: strings are passed NULL terminated. That means the empty
  // string will have a size of 1 and no-string will have a size of 0
  if (!GetBucketContents(bucket_id, &data)) {
    return false;
  }
  if (data.empty()) {
    return false;
  }
  str->assign(&data[0], &data[0] + data.size() - 1);
  return true;
}

void GLES2Implementation::SetBucketAsString(
    uint32 bucket_id, const std::string& str) {
  // NOTE: strings are passed NULL terminated. That means the empty
  // string will have a size of 1 and no-string will have a size of 0
  SetBucketContents(bucket_id, str.c_str(), str.size() + 1);
}

void GLES2Implementation::Disable(GLenum cap) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glDisable("
                 << GLES2Util::GetStringCapability(cap) << ")");
  bool changed = false;
  if (!state_.SetCapabilityState(cap, false, &changed) || changed) {
    helper_->Disable(cap);
  }
  CheckGLError();
}

void GLES2Implementation::Enable(GLenum cap) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glEnable("
                 << GLES2Util::GetStringCapability(cap) << ")");
  bool changed = false;
  if (!state_.SetCapabilityState(cap, true, &changed) || changed) {
    helper_->Enable(cap);
  }
  CheckGLError();
}

GLboolean GLES2Implementation::IsEnabled(GLenum cap) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glIsEnabled("
                 << GLES2Util::GetStringCapability(cap) << ")");
  bool state = false;
  if (!state_.GetEnabled(cap, &state)) {
    typedef cmds::IsEnabled::Result Result;
    Result* result = GetResultAs<Result*>();
    if (!result) {
      return GL_FALSE;
    }
    *result = 0;
    helper_->IsEnabled(cap, GetResultShmId(), GetResultShmOffset());
    WaitForCmd();
    state = (*result) != 0;
  }

  GPU_CLIENT_LOG("returned " << state);
  CheckGLError();
  return state;
}

bool GLES2Implementation::GetHelper(GLenum pname, GLint* params) {
  // TODO(zmo): For all the BINDING points, there is a possibility where
  // resources are shared among multiple contexts, that the cached points
  // are invalid. It is not a problem for now, but once we allow resource
  // sharing in WebGL, we need to implement a mechanism to allow correct
  // client side binding points tracking.  crbug.com/465562.

  // ES2 parameters.
  switch (pname) {
    case GL_ACTIVE_TEXTURE:
      *params = active_texture_unit_ + GL_TEXTURE0;
      return true;
    case GL_ARRAY_BUFFER_BINDING:
      *params = bound_array_buffer_id_;
      return true;
    case GL_ELEMENT_ARRAY_BUFFER_BINDING:
      *params =
          vertex_array_object_manager_->bound_element_array_buffer();
      return true;
    case GL_FRAMEBUFFER_BINDING:
      *params = bound_framebuffer_;
      return true;
    case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
      *params = capabilities_.max_combined_texture_image_units;
      return true;
    case GL_MAX_CUBE_MAP_TEXTURE_SIZE:
      *params = capabilities_.max_cube_map_texture_size;
      return true;
    case GL_MAX_FRAGMENT_UNIFORM_VECTORS:
      *params = capabilities_.max_fragment_uniform_vectors;
      return true;
    case GL_MAX_RENDERBUFFER_SIZE:
      *params = capabilities_.max_renderbuffer_size;
      return true;
    case GL_MAX_TEXTURE_IMAGE_UNITS:
      *params = capabilities_.max_texture_image_units;
      return true;
    case GL_MAX_TEXTURE_SIZE:
      *params = capabilities_.max_texture_size;
      return true;
    case GL_MAX_VARYING_VECTORS:
      *params = capabilities_.max_varying_vectors;
      return true;
    case GL_MAX_VERTEX_ATTRIBS:
      *params = capabilities_.max_vertex_attribs;
      return true;
    case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
      *params = capabilities_.max_vertex_texture_image_units;
      return true;
    case GL_MAX_VERTEX_UNIFORM_VECTORS:
      *params = capabilities_.max_vertex_uniform_vectors;
      return true;
    case GL_NUM_COMPRESSED_TEXTURE_FORMATS:
      *params = capabilities_.num_compressed_texture_formats;
      return true;
    case GL_NUM_SHADER_BINARY_FORMATS:
      *params = capabilities_.num_shader_binary_formats;
      return true;
    case GL_RENDERBUFFER_BINDING:
      *params = bound_renderbuffer_;
      return true;
    case GL_TEXTURE_BINDING_2D:
      *params = texture_units_[active_texture_unit_].bound_texture_2d;
      return true;
    case GL_TEXTURE_BINDING_CUBE_MAP:
      *params = texture_units_[active_texture_unit_].bound_texture_cube_map;
      return true;

    // Non-standard parameters.
    case GL_TEXTURE_BINDING_EXTERNAL_OES:
      *params =
          texture_units_[active_texture_unit_].bound_texture_external_oes;
      return true;
    case GL_PIXEL_PACK_TRANSFER_BUFFER_BINDING_CHROMIUM:
      *params = bound_pixel_pack_transfer_buffer_id_;
      return true;
    case GL_PIXEL_UNPACK_TRANSFER_BUFFER_BINDING_CHROMIUM:
      *params = bound_pixel_unpack_transfer_buffer_id_;
      return true;
    case GL_READ_FRAMEBUFFER_BINDING:
      if (IsChromiumFramebufferMultisampleAvailable()) {
        *params = bound_read_framebuffer_;
        return true;
      }
      break;

    // Non-cached parameters.
    case GL_ALIASED_LINE_WIDTH_RANGE:
    case GL_ALIASED_POINT_SIZE_RANGE:
    case GL_ALPHA_BITS:
    case GL_BLEND:
    case GL_BLEND_COLOR:
    case GL_BLEND_DST_ALPHA:
    case GL_BLEND_DST_RGB:
    case GL_BLEND_EQUATION_ALPHA:
    case GL_BLEND_EQUATION_RGB:
    case GL_BLEND_SRC_ALPHA:
    case GL_BLEND_SRC_RGB:
    case GL_BLUE_BITS:
    case GL_COLOR_CLEAR_VALUE:
    case GL_COLOR_WRITEMASK:
    case GL_COMPRESSED_TEXTURE_FORMATS:
    case GL_CULL_FACE:
    case GL_CULL_FACE_MODE:
    case GL_CURRENT_PROGRAM:
    case GL_DEPTH_BITS:
    case GL_DEPTH_CLEAR_VALUE:
    case GL_DEPTH_FUNC:
    case GL_DEPTH_RANGE:
    case GL_DEPTH_TEST:
    case GL_DEPTH_WRITEMASK:
    case GL_DITHER:
    case GL_FRONT_FACE:
    case GL_GENERATE_MIPMAP_HINT:
    case GL_GREEN_BITS:
    case GL_IMPLEMENTATION_COLOR_READ_FORMAT:
    case GL_IMPLEMENTATION_COLOR_READ_TYPE:
    case GL_LINE_WIDTH:
    case GL_MAX_VIEWPORT_DIMS:
    case GL_PACK_ALIGNMENT:
    case GL_POLYGON_OFFSET_FACTOR:
    case GL_POLYGON_OFFSET_FILL:
    case GL_POLYGON_OFFSET_UNITS:
    case GL_RED_BITS:
    case GL_SAMPLE_ALPHA_TO_COVERAGE:
    case GL_SAMPLE_BUFFERS:
    case GL_SAMPLE_COVERAGE:
    case GL_SAMPLE_COVERAGE_INVERT:
    case GL_SAMPLE_COVERAGE_VALUE:
    case GL_SAMPLES:
    case GL_SCISSOR_BOX:
    case GL_SCISSOR_TEST:
    case GL_SHADER_BINARY_FORMATS:
    case GL_SHADER_COMPILER:
    case GL_STENCIL_BACK_FAIL:
    case GL_STENCIL_BACK_FUNC:
    case GL_STENCIL_BACK_PASS_DEPTH_FAIL:
    case GL_STENCIL_BACK_PASS_DEPTH_PASS:
    case GL_STENCIL_BACK_REF:
    case GL_STENCIL_BACK_VALUE_MASK:
    case GL_STENCIL_BACK_WRITEMASK:
    case GL_STENCIL_BITS:
    case GL_STENCIL_CLEAR_VALUE:
    case GL_STENCIL_FAIL:
    case GL_STENCIL_FUNC:
    case GL_STENCIL_PASS_DEPTH_FAIL:
    case GL_STENCIL_PASS_DEPTH_PASS:
    case GL_STENCIL_REF:
    case GL_STENCIL_TEST:
    case GL_STENCIL_VALUE_MASK:
    case GL_STENCIL_WRITEMASK:
    case GL_SUBPIXEL_BITS:
    case GL_UNPACK_ALIGNMENT:
    case GL_VIEWPORT:
      return false;
    default:
      break;
  }

  if (capabilities_.major_version < 3) {
    return false;
  }

  // ES3 parameters.
  switch (pname) {
    case GL_MAJOR_VERSION:
      *params = capabilities_.major_version;
      return true;
    case GL_MAX_3D_TEXTURE_SIZE:
      *params = capabilities_.max_3d_texture_size;
      return true;
    case GL_MAX_ARRAY_TEXTURE_LAYERS:
      *params = capabilities_.max_array_texture_layers;
      return true;
    case GL_MAX_COLOR_ATTACHMENTS:
      *params = capabilities_.max_color_attachments;
      return true;
    case GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS:
      *params = capabilities_.max_combined_fragment_uniform_components;
      return true;
    case GL_MAX_COMBINED_UNIFORM_BLOCKS:
      *params = capabilities_.max_combined_uniform_blocks;
      return true;
    case GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS:
      *params = capabilities_.max_combined_vertex_uniform_components;
      return true;
    case GL_MAX_DRAW_BUFFERS:
      *params = capabilities_.max_draw_buffers;
      return true;
    case GL_MAX_ELEMENT_INDEX:
      *params = capabilities_.max_element_index;
      return true;
    case GL_MAX_ELEMENTS_INDICES:
      *params = capabilities_.max_elements_indices;
      return true;
    case GL_MAX_ELEMENTS_VERTICES:
      *params = capabilities_.max_elements_vertices;
      return true;
    case GL_MAX_FRAGMENT_INPUT_COMPONENTS:
      *params = capabilities_.max_fragment_input_components;
      return true;
    case GL_MAX_FRAGMENT_UNIFORM_BLOCKS:
      *params = capabilities_.max_fragment_uniform_blocks;
      return true;
    case GL_MAX_FRAGMENT_UNIFORM_COMPONENTS:
      *params = capabilities_.max_fragment_uniform_components;
      return true;
    case GL_MAX_PROGRAM_TEXEL_OFFSET:
      *params = capabilities_.max_program_texel_offset;
      return true;
    case GL_MAX_SAMPLES:
      *params = capabilities_.max_samples;
      return true;
    case GL_MAX_SERVER_WAIT_TIMEOUT:
      *params = capabilities_.max_server_wait_timeout;
      return true;
    case GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS:
      *params = capabilities_.max_transform_feedback_interleaved_components;
      return true;
    case GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS:
      *params = capabilities_.max_transform_feedback_separate_attribs;
      return true;
    case GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS:
      *params = capabilities_.max_transform_feedback_separate_components;
      return true;
    case GL_MAX_UNIFORM_BLOCK_SIZE:
      *params = capabilities_.max_uniform_block_size;
      return true;
    case GL_MAX_UNIFORM_BUFFER_BINDINGS:
      *params = capabilities_.max_uniform_buffer_bindings;
      return true;
    case GL_MAX_VARYING_COMPONENTS:
      *params = capabilities_.max_varying_components;
      return true;
    case GL_MAX_VERTEX_OUTPUT_COMPONENTS:
      *params = capabilities_.max_vertex_output_components;
      return true;
    case GL_MAX_VERTEX_UNIFORM_BLOCKS:
      *params = capabilities_.max_vertex_uniform_blocks;
      return true;
    case GL_MAX_VERTEX_UNIFORM_COMPONENTS:
      *params = capabilities_.max_vertex_uniform_components;
      return true;
    case GL_MIN_PROGRAM_TEXEL_OFFSET:
      *params = capabilities_.min_program_texel_offset;
      return true;
    case GL_MINOR_VERSION:
      *params = capabilities_.minor_version;
      return true;
    case GL_NUM_EXTENSIONS:
      *params = capabilities_.num_extensions;
      return true;
    case GL_NUM_PROGRAM_BINARY_FORMATS:
      *params = capabilities_.num_program_binary_formats;
      return true;
    case GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT:
      *params = capabilities_.uniform_buffer_offset_alignment;
      return true;

    // Non-cached ES3 parameters.
    case GL_COPY_READ_BUFFER_BINDING:
    case GL_COPY_WRITE_BUFFER_BINDING:
    case GL_DRAW_BUFFER0:
    case GL_DRAW_BUFFER1:
    case GL_DRAW_BUFFER2:
    case GL_DRAW_BUFFER3:
    case GL_DRAW_BUFFER4:
    case GL_DRAW_BUFFER5:
    case GL_DRAW_BUFFER6:
    case GL_DRAW_BUFFER7:
    case GL_DRAW_BUFFER8:
    case GL_DRAW_BUFFER9:
    case GL_DRAW_BUFFER10:
    case GL_DRAW_BUFFER11:
    case GL_DRAW_BUFFER12:
    case GL_DRAW_BUFFER13:
    case GL_DRAW_BUFFER14:
    case GL_DRAW_BUFFER15:
    case GL_DRAW_FRAMEBUFFER_BINDING:
    case GL_FRAGMENT_SHADER_DERIVATIVE_HINT:
    case GL_MAX_TEXTURE_LOD_BIAS:
    case GL_PACK_ROW_LENGTH:
    case GL_PACK_SKIP_PIXELS:
    case GL_PACK_SKIP_ROWS:
    case GL_PIXEL_PACK_BUFFER_BINDING:
    case GL_PIXEL_UNPACK_BUFFER_BINDING:
    case GL_PRIMITIVE_RESTART_FIXED_INDEX:
    case GL_PROGRAM_BINARY_FORMATS:
    case GL_RASTERIZER_DISCARD:
    case GL_READ_BUFFER:
    case GL_READ_FRAMEBUFFER_BINDING:
    case GL_SAMPLER_BINDING:
    case GL_TEXTURE_BINDING_2D_ARRAY:
    case GL_TEXTURE_BINDING_3D:
    case GL_TRANSFORM_FEEDBACK_BINDING:
    case GL_TRANSFORM_FEEDBACK_ACTIVE:
    case GL_TRANSFORM_FEEDBACK_BUFFER_BINDING:
    case GL_TRANSFORM_FEEDBACK_PAUSED:
    case GL_TRANSFORM_FEEDBACK_BUFFER_SIZE:
    case GL_TRANSFORM_FEEDBACK_BUFFER_START:
    case GL_UNIFORM_BUFFER_BINDING:
    case GL_UNIFORM_BUFFER_SIZE:
    case GL_UNIFORM_BUFFER_START:
    case GL_UNPACK_IMAGE_HEIGHT:
    case GL_UNPACK_ROW_LENGTH:
    case GL_UNPACK_SKIP_IMAGES:
    case GL_UNPACK_SKIP_PIXELS:
    case GL_UNPACK_SKIP_ROWS:
    case GL_VERTEX_ARRAY_BINDING:
      return false;
    default:
      return false;
  }
}

bool GLES2Implementation::GetBooleanvHelper(GLenum pname, GLboolean* params) {
  // TODO(gman): Make this handle pnames that return more than 1 value.
  GLint value;
  if (!GetHelper(pname, &value)) {
    return false;
  }
  *params = static_cast<GLboolean>(value);
  return true;
}

bool GLES2Implementation::GetFloatvHelper(GLenum pname, GLfloat* params) {
  // TODO(gman): Make this handle pnames that return more than 1 value.
  GLint value;
  if (!GetHelper(pname, &value)) {
    return false;
  }
  *params = static_cast<GLfloat>(value);
  return true;
}

bool GLES2Implementation::GetInteger64vHelper(GLenum pname, GLint64* params) {
  // TODO(zmo): we limit values to 32-bit, which is OK for now.
  GLint value;
  if (!GetHelper(pname, &value)) {
    return false;
  }
  *params = value;
  return true;
}

bool GLES2Implementation::GetIntegervHelper(GLenum pname, GLint* params) {
  return GetHelper(pname, params);
}

bool GLES2Implementation::GetIntegeri_vHelper(
    GLenum pname, GLuint index, GLint* data) {
  // TODO(zmo): Implement client side caching.
  return false;
}

bool GLES2Implementation::GetInteger64i_vHelper(
    GLenum pname, GLuint index, GLint64* data) {
  // TODO(zmo): Implement client side caching.
  return false;
}

bool GLES2Implementation::GetInternalformativHelper(
    GLenum target, GLenum format, GLenum pname, GLsizei bufSize,
    GLint* params) {
  // TODO(zmo): Implement the client side caching.
  return false;
}

bool GLES2Implementation::GetSyncivHelper(
    GLsync sync, GLenum pname, GLsizei bufsize, GLsizei* length,
    GLint* values) {
  GLint value = 0;
  switch (pname) {
    case GL_OBJECT_TYPE:
      value = GL_SYNC_FENCE;
      break;
    case GL_SYNC_CONDITION:
      value = GL_SYNC_GPU_COMMANDS_COMPLETE;
      break;
    case GL_SYNC_FLAGS:
      value = 0;
      break;
    default:
      return false;
  }
  if (bufsize > 0) {
    DCHECK(values);
    *values = value;
  }
  if (length) {
    *length = 1;
  }
  return true;
}

GLuint GLES2Implementation::GetMaxValueInBufferCHROMIUMHelper(
    GLuint buffer_id, GLsizei count, GLenum type, GLuint offset) {
  typedef cmds::GetMaxValueInBufferCHROMIUM::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return 0;
  }
  *result = 0;
  helper_->GetMaxValueInBufferCHROMIUM(
      buffer_id, count, type, offset, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  return *result;
}

GLuint GLES2Implementation::GetMaxValueInBufferCHROMIUM(
    GLuint buffer_id, GLsizei count, GLenum type, GLuint offset) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetMaxValueInBufferCHROMIUM("
                 << buffer_id << ", " << count << ", "
                 << GLES2Util::GetStringGetMaxIndexType(type)
                 << ", " << offset << ")");
  GLuint result = GetMaxValueInBufferCHROMIUMHelper(
      buffer_id, count, type, offset);
  GPU_CLIENT_LOG("returned " << result);
  CheckGLError();
  return result;
}

void GLES2Implementation::RestoreElementAndArrayBuffers(bool restore) {
  if (restore) {
    RestoreArrayBuffer(restore);
    // Restore the element array binding.
    // We only need to restore it if it wasn't a client side array.
    if (vertex_array_object_manager_->bound_element_array_buffer() == 0) {
      helper_->BindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
  }
}

void GLES2Implementation::RestoreArrayBuffer(bool restore) {
  if (restore) {
    // Restore the user's current binding.
    helper_->BindBuffer(GL_ARRAY_BUFFER, bound_array_buffer_id_);
  }
}

void GLES2Implementation::DrawElements(
    GLenum mode, GLsizei count, GLenum type, const void* indices) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glDrawElements("
      << GLES2Util::GetStringDrawMode(mode) << ", "
      << count << ", "
      << GLES2Util::GetStringIndexType(type) << ", "
      << static_cast<const void*>(indices) << ")");
  DrawElementsImpl(mode, count, type, indices, "glDrawRangeElements");
}

void GLES2Implementation::DrawRangeElements(
    GLenum mode, GLuint start, GLuint end,
    GLsizei count, GLenum type, const void* indices) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glDrawRangeElements("
      << GLES2Util::GetStringDrawMode(mode) << ", "
      << start << ", " << end << ", " << count << ", "
      << GLES2Util::GetStringIndexType(type) << ", "
      << static_cast<const void*>(indices) << ")");
  if (end < start) {
    SetGLError(GL_INVALID_VALUE, "glDrawRangeElements", "end < start");
    return;
  }
  DrawElementsImpl(mode, count, type, indices, "glDrawRangeElements");
}

void GLES2Implementation::DrawElementsImpl(
    GLenum mode, GLsizei count, GLenum type, const void* indices,
    const char* func_name) {
  if (count < 0) {
    SetGLError(GL_INVALID_VALUE, func_name, "count < 0");
    return;
  }
  bool simulated = false;
  GLuint offset = ToGLuint(indices);
  if (count > 0) {
    if (vertex_array_object_manager_->bound_element_array_buffer() != 0 &&
        !ValidateOffset(func_name, reinterpret_cast<GLintptr>(indices))) {
      return;
    }
    if (!vertex_array_object_manager_->SetupSimulatedIndexAndClientSideBuffers(
        func_name, this, helper_, count, type, 0, indices,
        &offset, &simulated)) {
      return;
    }
  }
  helper_->DrawElements(mode, count, type, offset);
  RestoreElementAndArrayBuffers(simulated);
  CheckGLError();
}

void GLES2Implementation::Flush() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glFlush()");
  // Insert the cmd to call glFlush
  helper_->Flush();
  // Flush our command buffer
  // (tell the service to execute up to the flush cmd.)
  helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::ShallowFlushCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glShallowFlushCHROMIUM()");
  // Flush our command buffer
  // (tell the service to execute up to the flush cmd.)
  helper_->CommandBufferHelper::Flush();
  // TODO(piman): Add the FreeEverything() logic here.
}

void GLES2Implementation::OrderingBarrierCHROMIUM() {
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glOrderingBarrierCHROMIUM");
  // Flush command buffer at the GPU channel level.  May be implemented as
  // Flush().
  helper_->CommandBufferHelper::OrderingBarrier();
}

void GLES2Implementation::Finish() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  FinishHelper();
}

void GLES2Implementation::ShallowFinishCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  TRACE_EVENT0("gpu", "GLES2::ShallowFinishCHROMIUM");
  // Flush our command buffer (tell the service to execute up to the flush cmd
  // and don't return until it completes).
  helper_->CommandBufferHelper::Finish();
}

void GLES2Implementation::FinishHelper() {
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glFinish()");
  TRACE_EVENT0("gpu", "GLES2::Finish");
  // Insert the cmd to call glFinish
  helper_->Finish();
  // Finish our command buffer
  // (tell the service to execute up to the Finish cmd and wait for it to
  // execute.)
  helper_->CommandBufferHelper::Finish();
}

void GLES2Implementation::SwapBuffers() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glSwapBuffers()");
  // TODO(piman): Strictly speaking we'd want to insert the token after the
  // swap, but the state update with the updated token might not have happened
  // by the time the SwapBuffer callback gets called, forcing us to synchronize
  // with the GPU process more than needed. So instead, make it happen before.
  // All it means is that we could be slightly looser on the kMaxSwapBuffers
  // semantics if the client doesn't use the callback mechanism, and by chance
  // the scheduler yields between the InsertToken and the SwapBuffers.
  swap_buffers_tokens_.push(helper_->InsertToken());
  helper_->SwapBuffers();
  helper_->CommandBufferHelper::Flush();
  // Wait if we added too many swap buffers. Add 1 to kMaxSwapBuffers to
  // compensate for TODO above.
  if (swap_buffers_tokens_.size() > kMaxSwapBuffers + 1) {
    helper_->WaitForToken(swap_buffers_tokens_.front());
    swap_buffers_tokens_.pop();
  }
}

void GLES2Implementation::SwapInterval(int interval) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glSwapInterval("
      << interval << ")");
  helper_->SwapInterval(interval);
}

void GLES2Implementation::BindAttribLocation(
  GLuint program, GLuint index, const char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glBindAttribLocation("
      << program << ", " << index << ", " << name << ")");
  SetBucketAsString(kResultBucketId, name);
  helper_->BindAttribLocationBucket(program, index, kResultBucketId);
  helper_->SetBucketSize(kResultBucketId, 0);
  CheckGLError();
}

void GLES2Implementation::BindUniformLocationCHROMIUM(
  GLuint program, GLint location, const char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glBindUniformLocationCHROMIUM("
      << program << ", " << location << ", " << name << ")");
  SetBucketAsString(kResultBucketId, name);
  helper_->BindUniformLocationCHROMIUMBucket(
      program, location, kResultBucketId);
  helper_->SetBucketSize(kResultBucketId, 0);
  CheckGLError();
}

void GLES2Implementation::GetVertexAttribPointerv(
    GLuint index, GLenum pname, void** ptr) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetVertexAttribPointer("
      << index << ", " << GLES2Util::GetStringVertexPointer(pname) << ", "
      << static_cast<void*>(ptr) << ")");
  GPU_CLIENT_LOG_CODE_BLOCK(int32 num_results = 1);
  if (!vertex_array_object_manager_->GetAttribPointer(index, pname, ptr)) {
    TRACE_EVENT0("gpu", "GLES2::GetVertexAttribPointerv");
    typedef cmds::GetVertexAttribPointerv::Result Result;
    Result* result = GetResultAs<Result*>();
    if (!result) {
      return;
    }
    result->SetNumResults(0);
    helper_->GetVertexAttribPointerv(
      index, pname, GetResultShmId(), GetResultShmOffset());
    WaitForCmd();
    result->CopyResult(ptr);
    GPU_CLIENT_LOG_CODE_BLOCK(num_results = result->GetNumResults());
  }
  GPU_CLIENT_LOG_CODE_BLOCK({
    for (int32 i = 0; i < num_results; ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << ptr[i]);
    }
  });
  CheckGLError();
}

bool GLES2Implementation::DeleteProgramHelper(GLuint program) {
  if (!GetIdHandler(id_namespaces::kProgramsAndShaders)->FreeIds(
      this, 1, &program, &GLES2Implementation::DeleteProgramStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteProgram", "id not created by this context.");
    return false;
  }
  if (program == current_program_) {
    current_program_ = 0;
  }
  return true;
}

void GLES2Implementation::DeleteProgramStub(
    GLsizei n, const GLuint* programs) {
  DCHECK_EQ(1, n);
  share_group_->program_info_manager()->DeleteInfo(programs[0]);
  helper_->DeleteProgram(programs[0]);
}

bool GLES2Implementation::DeleteShaderHelper(GLuint shader) {
  if (!GetIdHandler(id_namespaces::kProgramsAndShaders)->FreeIds(
      this, 1, &shader, &GLES2Implementation::DeleteShaderStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteShader", "id not created by this context.");
    return false;
  }
  return true;
}

void GLES2Implementation::DeleteShaderStub(
    GLsizei n, const GLuint* shaders) {
  DCHECK_EQ(1, n);
  share_group_->program_info_manager()->DeleteInfo(shaders[0]);
  helper_->DeleteShader(shaders[0]);
}

void GLES2Implementation::DeleteSyncHelper(GLsync sync) {
  GLuint sync_uint = ToGLuint(sync);
  if (!GetIdHandler(id_namespaces::kSyncs)->FreeIds(
      this, 1, &sync_uint, &GLES2Implementation::DeleteSyncStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteSync", "id not created by this context.");
  }
}

void GLES2Implementation::DeleteSyncStub(GLsizei n, const GLuint* syncs) {
  DCHECK_EQ(1, n);
  helper_->DeleteSync(syncs[0]);
}

GLint GLES2Implementation::GetAttribLocationHelper(
    GLuint program, const char* name) {
  typedef cmds::GetAttribLocation::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return -1;
  }
  *result = -1;
  SetBucketAsCString(kResultBucketId, name);
  helper_->GetAttribLocation(
      program, kResultBucketId, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  helper_->SetBucketSize(kResultBucketId, 0);
  return *result;
}

GLint GLES2Implementation::GetAttribLocation(
    GLuint program, const char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetAttribLocation(" << program
      << ", " << name << ")");
  TRACE_EVENT0("gpu", "GLES2::GetAttribLocation");
  GLint loc = share_group_->program_info_manager()->GetAttribLocation(
      this, program, name);
  GPU_CLIENT_LOG("returned " << loc);
  CheckGLError();
  return loc;
}

GLint GLES2Implementation::GetUniformLocationHelper(
    GLuint program, const char* name) {
  typedef cmds::GetUniformLocation::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return -1;
  }
  *result = -1;
  SetBucketAsCString(kResultBucketId, name);
  helper_->GetUniformLocation(program, kResultBucketId,
                                    GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  helper_->SetBucketSize(kResultBucketId, 0);
  return *result;
}

GLint GLES2Implementation::GetUniformLocation(
    GLuint program, const char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetUniformLocation(" << program
      << ", " << name << ")");
  TRACE_EVENT0("gpu", "GLES2::GetUniformLocation");
  GLint loc = share_group_->program_info_manager()->GetUniformLocation(
      this, program, name);
  GPU_CLIENT_LOG("returned " << loc);
  CheckGLError();
  return loc;
}

bool GLES2Implementation::GetUniformIndicesHelper(
    GLuint program, GLsizei count, const char* const* names, GLuint* indices) {
  typedef cmds::GetUniformIndices::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  result->SetNumResults(0);
  if (!PackStringsToBucket(count, names, NULL, "glGetUniformIndices")) {
    return false;
  }
  helper_->GetUniformIndices(program, kResultBucketId,
                             GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  if (result->GetNumResults() != count) {
    return false;
  }
  result->CopyResult(indices);
  return true;
}

void GLES2Implementation::GetUniformIndices(
    GLuint program, GLsizei count, const char* const* names, GLuint* indices) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetUniformIndices(" << program
      << ", " << count << ", " << names << ", " << indices << ")");
  TRACE_EVENT0("gpu", "GLES2::GetUniformIndices");
  if (count < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetUniformIndices", "count < 0");
    return;
  }
  if (count == 0) {
    return;
  }
  bool success = share_group_->program_info_manager()->GetUniformIndices(
      this, program, count, names, indices);
  if (success) {
    GPU_CLIENT_LOG_CODE_BLOCK({
      for (GLsizei ii = 0; ii < count; ++ii) {
        GPU_CLIENT_LOG("  " << ii << ": " << indices[ii]);
      }
    });
  }
  CheckGLError();
}

bool GLES2Implementation::GetProgramivHelper(
    GLuint program, GLenum pname, GLint* params) {
  bool got_value = share_group_->program_info_manager()->GetProgramiv(
      this, program, pname, params);
  GPU_CLIENT_LOG_CODE_BLOCK({
    if (got_value) {
      GPU_CLIENT_LOG("  0: " << *params);
    }
  });
  return got_value;
}

GLint GLES2Implementation::GetFragDataLocationHelper(
    GLuint program, const char* name) {
  typedef cmds::GetFragDataLocation::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return -1;
  }
  *result = -1;
  SetBucketAsCString(kResultBucketId, name);
  helper_->GetFragDataLocation(
      program, kResultBucketId, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  helper_->SetBucketSize(kResultBucketId, 0);
  return *result;
}

GLint GLES2Implementation::GetFragDataLocation(
    GLuint program, const char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetFragDataLocation("
      << program << ", " << name << ")");
  TRACE_EVENT0("gpu", "GLES2::GetFragDataLocation");
  GLint loc = share_group_->program_info_manager()->GetFragDataLocation(
      this, program, name);
  GPU_CLIENT_LOG("returned " << loc);
  CheckGLError();
  return loc;
}

GLuint GLES2Implementation::GetUniformBlockIndexHelper(
    GLuint program, const char* name) {
  typedef cmds::GetUniformBlockIndex::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return GL_INVALID_INDEX;
  }
  *result = GL_INVALID_INDEX;
  SetBucketAsCString(kResultBucketId, name);
  helper_->GetUniformBlockIndex(
      program, kResultBucketId, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  helper_->SetBucketSize(kResultBucketId, 0);
  return *result;
}

GLuint GLES2Implementation::GetUniformBlockIndex(
    GLuint program, const char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetUniformBlockIndex("
      << program << ", " << name << ")");
  TRACE_EVENT0("gpu", "GLES2::GetUniformBlockIndex");
  GLuint index = share_group_->program_info_manager()->GetUniformBlockIndex(
      this, program, name);
  GPU_CLIENT_LOG("returned " << index);
  CheckGLError();
  return index;
}

void GLES2Implementation::LinkProgram(GLuint program) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glLinkProgram(" << program << ")");
  helper_->LinkProgram(program);
  share_group_->program_info_manager()->CreateInfo(program);
  CheckGLError();
}

void GLES2Implementation::ShaderBinary(
    GLsizei n, const GLuint* shaders, GLenum binaryformat, const void* binary,
    GLsizei length) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glShaderBinary(" << n << ", "
      << static_cast<const void*>(shaders) << ", "
      << GLES2Util::GetStringEnum(binaryformat) << ", "
      << static_cast<const void*>(binary) << ", "
      << length << ")");
  if (n < 0) {
    SetGLError(GL_INVALID_VALUE, "glShaderBinary", "n < 0.");
    return;
  }
  if (length < 0) {
    SetGLError(GL_INVALID_VALUE, "glShaderBinary", "length < 0.");
    return;
  }
  // TODO(gman): ShaderBinary should use buckets.
  unsigned int shader_id_size = n * sizeof(*shaders);
  ScopedTransferBufferArray<GLint> buffer(
      shader_id_size + length, helper_, transfer_buffer_);
  if (!buffer.valid() || buffer.num_elements() != shader_id_size + length) {
    SetGLError(GL_OUT_OF_MEMORY, "glShaderBinary", "out of memory.");
    return;
  }
  void* shader_ids = buffer.elements();
  void* shader_data = buffer.elements() + shader_id_size;
  memcpy(shader_ids, shaders, shader_id_size);
  memcpy(shader_data, binary, length);
  helper_->ShaderBinary(
      n,
      buffer.shm_id(),
      buffer.offset(),
      binaryformat,
      buffer.shm_id(),
      buffer.offset() + shader_id_size,
      length);
  CheckGLError();
}

void GLES2Implementation::PixelStorei(GLenum pname, GLint param) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glPixelStorei("
      << GLES2Util::GetStringPixelStore(pname) << ", "
      << param << ")");
  switch (pname) {
    case GL_PACK_ALIGNMENT:
        pack_alignment_ = param;
        break;
    case GL_UNPACK_ALIGNMENT:
        unpack_alignment_ = param;
        break;
    case GL_UNPACK_ROW_LENGTH_EXT:
        unpack_row_length_ = param;
        return;
    case GL_UNPACK_IMAGE_HEIGHT:
        unpack_image_height_ = param;
        return;
    case GL_UNPACK_SKIP_ROWS_EXT:
        unpack_skip_rows_ = param;
        return;
    case GL_UNPACK_SKIP_PIXELS_EXT:
        unpack_skip_pixels_ = param;
        return;
    case GL_UNPACK_SKIP_IMAGES:
        unpack_skip_images_ = param;
        return;
    case GL_UNPACK_FLIP_Y_CHROMIUM:
        unpack_flip_y_ = (param != 0);
        break;
    case GL_PACK_REVERSE_ROW_ORDER_ANGLE:
        pack_reverse_row_order_ =
            IsAnglePackReverseRowOrderAvailable() ? (param != 0) : false;
        break;
    default:
        break;
  }
  helper_->PixelStorei(pname, param);
  CheckGLError();
}

void GLES2Implementation::VertexAttribIPointer(
    GLuint index, GLint size, GLenum type, GLsizei stride, const void* ptr) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glVertexAttribIPointer("
      << index << ", "
      << size << ", "
      << GLES2Util::GetStringVertexAttribIType(type) << ", "
      << stride << ", "
      << ptr << ")");
  // Record the info on the client side.
  if (!vertex_array_object_manager_->SetAttribPointer(
      bound_array_buffer_id_, index, size, type, GL_FALSE, stride, ptr)) {
    SetGLError(GL_INVALID_OPERATION, "glVertexAttribIPointer",
               "client side arrays are not allowed in vertex array objects.");
    return;
  }
  if (!support_client_side_arrays_ || bound_array_buffer_id_ != 0) {
    // Only report NON client side buffers to the service.
    if (!ValidateOffset("glVertexAttribIPointer",
                        reinterpret_cast<GLintptr>(ptr))) {
      return;
    }
    helper_->VertexAttribIPointer(index, size, type, stride, ToGLuint(ptr));
  }
  CheckGLError();
}

void GLES2Implementation::VertexAttribPointer(
    GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride,
    const void* ptr) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glVertexAttribPointer("
      << index << ", "
      << size << ", "
      << GLES2Util::GetStringVertexAttribType(type) << ", "
      << GLES2Util::GetStringBool(normalized) << ", "
      << stride << ", "
      << ptr << ")");
  // Record the info on the client side.
  if (!vertex_array_object_manager_->SetAttribPointer(
      bound_array_buffer_id_, index, size, type, normalized, stride, ptr)) {
    SetGLError(GL_INVALID_OPERATION, "glVertexAttribPointer",
               "client side arrays are not allowed in vertex array objects.");
    return;
  }
  if (!support_client_side_arrays_ || bound_array_buffer_id_ != 0) {
    // Only report NON client side buffers to the service.
    if (!ValidateOffset("glVertexAttribPointer",
                        reinterpret_cast<GLintptr>(ptr))) {
      return;
    }
    helper_->VertexAttribPointer(index, size, type, normalized, stride,
                                 ToGLuint(ptr));
  }
  CheckGLError();
}

void GLES2Implementation::VertexAttribDivisorANGLE(
    GLuint index, GLuint divisor) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glVertexAttribDivisorANGLE("
      << index << ", "
      << divisor << ") ");
  // Record the info on the client side.
  vertex_array_object_manager_->SetAttribDivisor(index, divisor);
  helper_->VertexAttribDivisorANGLE(index, divisor);
  CheckGLError();
}

void GLES2Implementation::BufferDataHelper(
    GLenum target, GLsizeiptr size, const void* data, GLenum usage) {
  if (!ValidateSize("glBufferData", size))
    return;

#if defined(MEMORY_SANITIZER) && !defined(OS_NACL)
  // Do not upload uninitialized data. Even if it's not a bug, it can cause a
  // bogus MSan report during a readback later. This is because MSan doesn't
  // understand shared memory and would assume we were reading back the same
  // unintialized data.
  if (data) __msan_check_mem_is_initialized(data, size);
#endif

  GLuint buffer_id;
  if (GetBoundPixelTransferBuffer(target, "glBufferData", &buffer_id)) {
    if (!buffer_id) {
      return;
    }

    BufferTracker::Buffer* buffer = buffer_tracker_->GetBuffer(buffer_id);
    if (buffer)
      RemoveTransferBuffer(buffer);

    // Create new buffer.
    buffer = buffer_tracker_->CreateBuffer(buffer_id, size);
    DCHECK(buffer);
    if (buffer->address() && data)
      memcpy(buffer->address(), data, size);
    return;
  }

  RemoveMappedBufferRangeByTarget(target);

  // If there is no data just send BufferData
  if (size == 0 || !data) {
    helper_->BufferData(target, size, 0, 0, usage);
    return;
  }

  // See if we can send all at once.
  ScopedTransferBufferPtr buffer(size, helper_, transfer_buffer_);
  if (!buffer.valid()) {
    return;
  }

  if (buffer.size() >= static_cast<unsigned int>(size)) {
    memcpy(buffer.address(), data, size);
    helper_->BufferData(
        target,
        size,
        buffer.shm_id(),
        buffer.offset(),
        usage);
    return;
  }

  // Make the buffer with BufferData then send via BufferSubData
  helper_->BufferData(target, size, 0, 0, usage);
  BufferSubDataHelperImpl(target, 0, size, data, &buffer);
  CheckGLError();
}

void GLES2Implementation::BufferData(
    GLenum target, GLsizeiptr size, const void* data, GLenum usage) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glBufferData("
      << GLES2Util::GetStringBufferTarget(target) << ", "
      << size << ", "
      << static_cast<const void*>(data) << ", "
      << GLES2Util::GetStringBufferUsage(usage) << ")");
  BufferDataHelper(target, size, data, usage);
  CheckGLError();
}

void GLES2Implementation::BufferSubDataHelper(
    GLenum target, GLintptr offset, GLsizeiptr size, const void* data) {
  if (size == 0) {
    return;
  }

  if (!ValidateSize("glBufferSubData", size) ||
      !ValidateOffset("glBufferSubData", offset)) {
    return;
  }

  GLuint buffer_id;
  if (GetBoundPixelTransferBuffer(target, "glBufferSubData", &buffer_id)) {
    if (!buffer_id) {
      return;
    }
    BufferTracker::Buffer* buffer = buffer_tracker_->GetBuffer(buffer_id);
    if (!buffer) {
      SetGLError(GL_INVALID_VALUE, "glBufferSubData", "unknown buffer");
      return;
    }

    int32 end = 0;
    int32 buffer_size = buffer->size();
    if (!SafeAddInt32(offset, size, &end) || end > buffer_size) {
      SetGLError(GL_INVALID_VALUE, "glBufferSubData", "out of range");
      return;
    }

    if (buffer->address() && data)
      memcpy(static_cast<uint8*>(buffer->address()) + offset, data, size);
    return;
  }

  ScopedTransferBufferPtr buffer(size, helper_, transfer_buffer_);
  BufferSubDataHelperImpl(target, offset, size, data, &buffer);
}

void GLES2Implementation::BufferSubDataHelperImpl(
    GLenum target, GLintptr offset, GLsizeiptr size, const void* data,
    ScopedTransferBufferPtr* buffer) {
  DCHECK(buffer);
  DCHECK_GT(size, 0);

  const int8* source = static_cast<const int8*>(data);
  while (size) {
    if (!buffer->valid() || buffer->size() == 0) {
      buffer->Reset(size);
      if (!buffer->valid()) {
        return;
      }
    }
    memcpy(buffer->address(), source, buffer->size());
    helper_->BufferSubData(
        target, offset, buffer->size(), buffer->shm_id(), buffer->offset());
    offset += buffer->size();
    source += buffer->size();
    size -= buffer->size();
    buffer->Release();
  }
}

void GLES2Implementation::BufferSubData(
    GLenum target, GLintptr offset, GLsizeiptr size, const void* data) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glBufferSubData("
      << GLES2Util::GetStringBufferTarget(target) << ", "
      << offset << ", " << size << ", "
      << static_cast<const void*>(data) << ")");
  BufferSubDataHelper(target, offset, size, data);
  CheckGLError();
}

void GLES2Implementation::RemoveTransferBuffer(BufferTracker::Buffer* buffer) {
  int32 token = buffer->last_usage_token();
  uint32 async_token = buffer->last_async_upload_token();

  if (async_token) {
    if (HasAsyncUploadTokenPassed(async_token)) {
      buffer_tracker_->Free(buffer);
    } else {
      detached_async_upload_memory_.push_back(
          std::make_pair(buffer->address(), async_token));
      buffer_tracker_->Unmanage(buffer);
    }
  } else if (token) {
    if (helper_->HasTokenPassed(token))
      buffer_tracker_->Free(buffer);
    else
      buffer_tracker_->FreePendingToken(buffer, token);
  } else {
      buffer_tracker_->Free(buffer);
  }

  buffer_tracker_->RemoveBuffer(buffer->id());
}

bool GLES2Implementation::GetBoundPixelTransferBuffer(
    GLenum target,
    const char* function_name,
    GLuint* buffer_id) {
  *buffer_id = 0;

  switch (target) {
    case GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM:
      *buffer_id = bound_pixel_pack_transfer_buffer_id_;
      break;
    case GL_PIXEL_UNPACK_TRANSFER_BUFFER_CHROMIUM:
      *buffer_id = bound_pixel_unpack_transfer_buffer_id_;
      break;
    default:
      // Unknown target
      return false;
  }
  if (!*buffer_id) {
    SetGLError(GL_INVALID_OPERATION, function_name, "no buffer bound");
  }
  return true;
}

BufferTracker::Buffer*
GLES2Implementation::GetBoundPixelUnpackTransferBufferIfValid(
    GLuint buffer_id,
    const char* function_name,
    GLuint offset, GLsizei size) {
  DCHECK(buffer_id);
  BufferTracker::Buffer* buffer = buffer_tracker_->GetBuffer(buffer_id);
  if (!buffer) {
    SetGLError(GL_INVALID_OPERATION, function_name, "invalid buffer");
    return NULL;
  }
  if (buffer->mapped()) {
    SetGLError(GL_INVALID_OPERATION, function_name, "buffer mapped");
    return NULL;
  }
  if ((buffer->size() - offset) < static_cast<GLuint>(size)) {
    SetGLError(GL_INVALID_VALUE, function_name, "unpack size to large");
    return NULL;
  }
  return buffer;
}

void GLES2Implementation::CompressedTexImage2D(
    GLenum target, GLint level, GLenum internalformat, GLsizei width,
    GLsizei height, GLint border, GLsizei image_size, const void* data) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glCompressedTexImage2D("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << GLES2Util::GetStringCompressedTextureFormat(internalformat) << ", "
      << width << ", " << height << ", " << border << ", "
      << image_size << ", "
      << static_cast<const void*>(data) << ")");
  if (width < 0 || height < 0 || level < 0) {
    SetGLError(GL_INVALID_VALUE, "glCompressedTexImage2D", "dimension < 0");
    return;
  }
  if (border != 0) {
    SetGLError(GL_INVALID_VALUE, "glCompressedTexImage2D", "border != 0");
    return;
  }
  if (height == 0 || width == 0) {
    return;
  }
  // If there's a pixel unpack buffer bound use it when issuing
  // CompressedTexImage2D.
  if (bound_pixel_unpack_transfer_buffer_id_) {
    GLuint offset = ToGLuint(data);
    BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
        bound_pixel_unpack_transfer_buffer_id_,
        "glCompressedTexImage2D", offset, image_size);
    if (buffer && buffer->shm_id() != -1) {
      helper_->CompressedTexImage2D(
          target, level, internalformat, width, height, image_size,
          buffer->shm_id(), buffer->shm_offset() + offset);
      buffer->set_last_usage_token(helper_->InsertToken());
    }
    return;
  }
  SetBucketContents(kResultBucketId, data, image_size);
  helper_->CompressedTexImage2DBucket(
      target, level, internalformat, width, height, kResultBucketId);
  // Free the bucket. This is not required but it does free up the memory.
  // and we don't have to wait for the result so from the client's perspective
  // it's cheap.
  helper_->SetBucketSize(kResultBucketId, 0);
  CheckGLError();
}

void GLES2Implementation::CompressedTexSubImage2D(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
    GLsizei height, GLenum format, GLsizei image_size, const void* data) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glCompressedTexSubImage2D("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << xoffset << ", " << yoffset << ", "
      << width << ", " << height << ", "
      << GLES2Util::GetStringCompressedTextureFormat(format) << ", "
      << image_size << ", "
      << static_cast<const void*>(data) << ")");
  if (width < 0 || height < 0 || level < 0) {
    SetGLError(GL_INVALID_VALUE, "glCompressedTexSubImage2D", "dimension < 0");
    return;
  }
  // If there's a pixel unpack buffer bound use it when issuing
  // CompressedTexSubImage2D.
  if (bound_pixel_unpack_transfer_buffer_id_) {
    GLuint offset = ToGLuint(data);
    BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
        bound_pixel_unpack_transfer_buffer_id_,
        "glCompressedTexSubImage2D", offset, image_size);
    if (buffer && buffer->shm_id() != -1) {
      helper_->CompressedTexSubImage2D(
          target, level, xoffset, yoffset, width, height, format, image_size,
          buffer->shm_id(), buffer->shm_offset() + offset);
      buffer->set_last_usage_token(helper_->InsertToken());
      CheckGLError();
    }
    return;
  }
  SetBucketContents(kResultBucketId, data, image_size);
  helper_->CompressedTexSubImage2DBucket(
      target, level, xoffset, yoffset, width, height, format, kResultBucketId);
  // Free the bucket. This is not required but it does free up the memory.
  // and we don't have to wait for the result so from the client's perspective
  // it's cheap.
  helper_->SetBucketSize(kResultBucketId, 0);
  CheckGLError();
}

namespace {

void CopyRectToBuffer(
    const void* pixels,
    uint32 height,
    uint32 unpadded_row_size,
    uint32 pixels_padded_row_size,
    bool flip_y,
    void* buffer,
    uint32 buffer_padded_row_size) {
  const int8* source = static_cast<const int8*>(pixels);
  int8* dest = static_cast<int8*>(buffer);
  if (flip_y || pixels_padded_row_size != buffer_padded_row_size) {
    if (flip_y) {
      dest += buffer_padded_row_size * (height - 1);
    }
    // the last row is copied unpadded at the end
    for (; height > 1; --height) {
      memcpy(dest, source, buffer_padded_row_size);
      if (flip_y) {
        dest -= buffer_padded_row_size;
      } else {
        dest += buffer_padded_row_size;
      }
      source += pixels_padded_row_size;
    }
    memcpy(dest, source, unpadded_row_size);
  } else {
    uint32 size = (height - 1) * pixels_padded_row_size + unpadded_row_size;
    memcpy(dest, source, size);
  }
}

}  // anonymous namespace

void GLES2Implementation::TexImage2D(
    GLenum target, GLint level, GLint internalformat, GLsizei width,
    GLsizei height, GLint border, GLenum format, GLenum type,
    const void* pixels) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glTexImage2D("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << GLES2Util::GetStringTextureInternalFormat(internalformat) << ", "
      << width << ", " << height << ", " << border << ", "
      << GLES2Util::GetStringTextureFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << static_cast<const void*>(pixels) << ")");
  if (level < 0 || height < 0 || width < 0) {
    SetGLError(GL_INVALID_VALUE, "glTexImage2D", "dimension < 0");
    return;
  }
  if (border != 0) {
    SetGLError(GL_INVALID_VALUE, "glTexImage2D", "border != 0");
    return;
  }
  uint32 size;
  uint32 unpadded_row_size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
          width, height, 1, format, type, unpack_alignment_, &size,
          &unpadded_row_size, &padded_row_size)) {
    SetGLError(GL_INVALID_VALUE, "glTexImage2D", "image size too large");
    return;
  }

  // If there's a pixel unpack buffer bound use it when issuing TexImage2D.
  if (bound_pixel_unpack_transfer_buffer_id_) {
    GLuint offset = ToGLuint(pixels);
    BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
        bound_pixel_unpack_transfer_buffer_id_,
        "glTexImage2D", offset, size);
    if (buffer && buffer->shm_id() != -1) {
      helper_->TexImage2D(
          target, level, internalformat, width, height, format, type,
          buffer->shm_id(), buffer->shm_offset() + offset);
      buffer->set_last_usage_token(helper_->InsertToken());
      CheckGLError();
    }
    return;
  }

  // If there's no data just issue TexImage2D
  if (!pixels) {
    helper_->TexImage2D(
       target, level, internalformat, width, height, format, type,
       0, 0);
    CheckGLError();
    return;
  }

  // compute the advance bytes per row for the src pixels
  uint32 src_padded_row_size;
  if (unpack_row_length_ > 0) {
    if (!GLES2Util::ComputeImagePaddedRowSize(
        unpack_row_length_, format, type, unpack_alignment_,
        &src_padded_row_size)) {
      SetGLError(
          GL_INVALID_VALUE, "glTexImage2D", "unpack row length too large");
      return;
    }
  } else {
    src_padded_row_size = padded_row_size;
  }

  // advance pixels pointer past the skip rows and skip pixels
  pixels = reinterpret_cast<const int8*>(pixels) +
      unpack_skip_rows_ * src_padded_row_size;
  if (unpack_skip_pixels_) {
    uint32 group_size = GLES2Util::ComputeImageGroupSize(format, type);
    pixels = reinterpret_cast<const int8*>(pixels) +
        unpack_skip_pixels_ * group_size;
  }

  // Check if we can send it all at once.
  ScopedTransferBufferPtr buffer(size, helper_, transfer_buffer_);
  if (!buffer.valid()) {
    return;
  }

  if (buffer.size() >= size) {
    CopyRectToBuffer(
        pixels, height, unpadded_row_size, src_padded_row_size, unpack_flip_y_,
        buffer.address(), padded_row_size);
    helper_->TexImage2D(
        target, level, internalformat, width, height, format, type,
        buffer.shm_id(), buffer.offset());
    CheckGLError();
    return;
  }

  // No, so send it using TexSubImage2D.
  helper_->TexImage2D(
     target, level, internalformat, width, height, format, type,
     0, 0);
  TexSubImage2DImpl(
      target, level, 0, 0, width, height, format, type, unpadded_row_size,
      pixels, src_padded_row_size, GL_TRUE, &buffer, padded_row_size);
  CheckGLError();
}

void GLES2Implementation::TexImage3D(
    GLenum target, GLint level, GLint internalformat, GLsizei width,
    GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type,
    const void* pixels) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glTexImage3D("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << GLES2Util::GetStringTextureInternalFormat(internalformat) << ", "
      << width << ", " << height << ", " << depth << ", " << border << ", "
      << GLES2Util::GetStringTextureFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << static_cast<const void*>(pixels) << ")");
  if (level < 0 || height < 0 || width < 0 || depth < 0) {
    SetGLError(GL_INVALID_VALUE, "glTexImage3D", "dimension < 0");
    return;
  }
  if (border != 0) {
    SetGLError(GL_INVALID_VALUE, "glTexImage3D", "border != 0");
    return;
  }
  uint32 size;
  uint32 unpadded_row_size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
          width, height, depth, format, type, unpack_alignment_, &size,
          &unpadded_row_size, &padded_row_size)) {
    SetGLError(GL_INVALID_VALUE, "glTexImage3D", "image size too large");
    return;
  }

  // If there's a pixel unpack buffer bound use it when issuing TexImage3D.
  if (bound_pixel_unpack_transfer_buffer_id_) {
    GLuint offset = ToGLuint(pixels);
    BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
        bound_pixel_unpack_transfer_buffer_id_,
        "glTexImage3D", offset, size);
    if (buffer && buffer->shm_id() != -1) {
      helper_->TexImage3D(
          target, level, internalformat, width, height, depth, format, type,
          buffer->shm_id(), buffer->shm_offset() + offset);
      buffer->set_last_usage_token(helper_->InsertToken());
      CheckGLError();
    }
    return;
  }

  // If there's no data just issue TexImage3D
  if (!pixels) {
    helper_->TexImage3D(
       target, level, internalformat, width, height, depth, format, type,
       0, 0);
    CheckGLError();
    return;
  }

  // compute the advance bytes per row for the src pixels
  uint32 src_padded_row_size;
  if (unpack_row_length_ > 0) {
    if (!GLES2Util::ComputeImagePaddedRowSize(
        unpack_row_length_, format, type, unpack_alignment_,
        &src_padded_row_size)) {
      SetGLError(
          GL_INVALID_VALUE, "glTexImage3D", "unpack row length too large");
      return;
    }
  } else {
    src_padded_row_size = padded_row_size;
  }
  uint32 src_height = unpack_image_height_ > 0 ? unpack_image_height_ : height;

  // advance pixels pointer past the skip images/rows/pixels
  pixels = reinterpret_cast<const int8*>(pixels) +
      unpack_skip_images_ * src_padded_row_size * src_height +
      unpack_skip_rows_ * src_padded_row_size;
  if (unpack_skip_pixels_) {
    uint32 group_size = GLES2Util::ComputeImageGroupSize(format, type);
    pixels = reinterpret_cast<const int8*>(pixels) +
        unpack_skip_pixels_ * group_size;
  }

  // Check if we can send it all at once.
  ScopedTransferBufferPtr buffer(size, helper_, transfer_buffer_);
  if (!buffer.valid()) {
    return;
  }

  if (buffer.size() >= size) {
    void* buffer_pointer = buffer.address();
    for (GLsizei z = 0; z < depth; ++z) {
      // Only the last row of the last image is unpadded.
      uint32 src_unpadded_row_size =
          (z == depth - 1) ? unpadded_row_size : src_padded_row_size;
      // TODO(zmo): Ignore flip_y flag for now.
      CopyRectToBuffer(
          pixels, height, src_unpadded_row_size, src_padded_row_size, false,
          buffer_pointer, padded_row_size);
      pixels = reinterpret_cast<const int8*>(pixels) +
          src_padded_row_size * src_height;
      buffer_pointer = reinterpret_cast<int8*>(buffer_pointer) +
          padded_row_size * height;
    }
    helper_->TexImage3D(
        target, level, internalformat, width, height, depth, format, type,
        buffer.shm_id(), buffer.offset());
    CheckGLError();
    return;
  }

  // No, so send it using TexSubImage3D.
  helper_->TexImage3D(
     target, level, internalformat, width, height, depth, format, type,
     0, 0);
  TexSubImage3DImpl(
      target, level, 0, 0, 0, width, height, depth, format, type,
      unpadded_row_size, pixels, src_padded_row_size, GL_TRUE, &buffer,
      padded_row_size);
  CheckGLError();
}

void GLES2Implementation::TexSubImage2D(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
    GLsizei height, GLenum format, GLenum type, const void* pixels) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glTexSubImage2D("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << xoffset << ", " << yoffset << ", "
      << width << ", " << height << ", "
      << GLES2Util::GetStringTextureFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << static_cast<const void*>(pixels) << ")");

  if (level < 0 || height < 0 || width < 0) {
    SetGLError(GL_INVALID_VALUE, "glTexSubImage2D", "dimension < 0");
    return;
  }
  if (height == 0 || width == 0) {
    return;
  }

  uint32 temp_size;
  uint32 unpadded_row_size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
        width, height, 1, format, type, unpack_alignment_, &temp_size,
        &unpadded_row_size, &padded_row_size)) {
    SetGLError(GL_INVALID_VALUE, "glTexSubImage2D", "size to large");
    return;
  }

  // If there's a pixel unpack buffer bound use it when issuing TexSubImage2D.
  if (bound_pixel_unpack_transfer_buffer_id_) {
    GLuint offset = ToGLuint(pixels);
    BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
        bound_pixel_unpack_transfer_buffer_id_,
        "glTexSubImage2D", offset, temp_size);
    if (buffer && buffer->shm_id() != -1) {
      helper_->TexSubImage2D(
          target, level, xoffset, yoffset, width, height, format, type,
          buffer->shm_id(), buffer->shm_offset() + offset, false);
      buffer->set_last_usage_token(helper_->InsertToken());
      CheckGLError();
    }
    return;
  }

  // compute the advance bytes per row for the src pixels
  uint32 src_padded_row_size;
  if (unpack_row_length_ > 0) {
    if (!GLES2Util::ComputeImagePaddedRowSize(
        unpack_row_length_, format, type, unpack_alignment_,
        &src_padded_row_size)) {
      SetGLError(
          GL_INVALID_VALUE, "glTexImage2D", "unpack row length too large");
      return;
    }
  } else {
    src_padded_row_size = padded_row_size;
  }

  // advance pixels pointer past the skip rows and skip pixels
  pixels = reinterpret_cast<const int8*>(pixels) +
      unpack_skip_rows_ * src_padded_row_size;
  if (unpack_skip_pixels_) {
    uint32 group_size = GLES2Util::ComputeImageGroupSize(format, type);
    pixels = reinterpret_cast<const int8*>(pixels) +
        unpack_skip_pixels_ * group_size;
  }

  ScopedTransferBufferPtr buffer(temp_size, helper_, transfer_buffer_);
  TexSubImage2DImpl(
      target, level, xoffset, yoffset, width, height, format, type,
      unpadded_row_size, pixels, src_padded_row_size, GL_FALSE, &buffer,
      padded_row_size);
  CheckGLError();
}

void GLES2Implementation::TexSubImage3D(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset,
    GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type,
    const void* pixels) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glTexSubImage3D("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << xoffset << ", " << yoffset << ", " << zoffset << ", "
      << width << ", " << height << ", " << depth << ", "
      << GLES2Util::GetStringTextureFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << static_cast<const void*>(pixels) << ")");

  if (level < 0 || height < 0 || width < 0 || depth < 0) {
    SetGLError(GL_INVALID_VALUE, "glTexSubImage3D", "dimension < 0");
    return;
  }
  if (height == 0 || width == 0 || depth == 0) {
    return;
  }

  uint32 temp_size;
  uint32 unpadded_row_size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
          width, height, depth, format, type, unpack_alignment_, &temp_size,
          &unpadded_row_size, &padded_row_size)) {
    SetGLError(GL_INVALID_VALUE, "glTexSubImage3D", "size to large");
    return;
  }

  // If there's a pixel unpack buffer bound use it when issuing TexSubImage2D.
  if (bound_pixel_unpack_transfer_buffer_id_) {
    GLuint offset = ToGLuint(pixels);
    BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
        bound_pixel_unpack_transfer_buffer_id_,
        "glTexSubImage3D", offset, temp_size);
    if (buffer && buffer->shm_id() != -1) {
      helper_->TexSubImage3D(
          target, level, xoffset, yoffset, zoffset, width, height, depth,
          format, type, buffer->shm_id(), buffer->shm_offset() + offset, false);
      buffer->set_last_usage_token(helper_->InsertToken());
      CheckGLError();
    }
    return;
  }

  // compute the advance bytes per row for the src pixels
  uint32 src_padded_row_size;
  if (unpack_row_length_ > 0) {
    if (!GLES2Util::ComputeImagePaddedRowSize(
        unpack_row_length_, format, type, unpack_alignment_,
        &src_padded_row_size)) {
      SetGLError(
          GL_INVALID_VALUE, "glTexImage3D", "unpack row length too large");
      return;
    }
  } else {
    src_padded_row_size = padded_row_size;
  }
  uint32 src_height = unpack_image_height_ > 0 ? unpack_image_height_ : height;

  // advance pixels pointer past the skip images/rows/pixels
  pixels = reinterpret_cast<const int8*>(pixels) +
      unpack_skip_images_ * src_padded_row_size * src_height +
      unpack_skip_rows_ * src_padded_row_size;
  if (unpack_skip_pixels_) {
    uint32 group_size = GLES2Util::ComputeImageGroupSize(format, type);
    pixels = reinterpret_cast<const int8*>(pixels) +
        unpack_skip_pixels_ * group_size;
  }

  ScopedTransferBufferPtr buffer(temp_size, helper_, transfer_buffer_);
  TexSubImage3DImpl(
      target, level, xoffset, yoffset, zoffset, width, height, depth,
      format, type, unpadded_row_size, pixels, src_padded_row_size, GL_FALSE,
      &buffer, padded_row_size);
  CheckGLError();
}

static GLint ComputeNumRowsThatFitInBuffer(
    uint32 padded_row_size, uint32 unpadded_row_size,
    unsigned int size, GLsizei remaining_rows) {
  DCHECK_GE(unpadded_row_size, 0u);
  if (padded_row_size == 0) {
    return 1;
  }
  GLint num_rows = size / padded_row_size;
  if (num_rows + 1 == remaining_rows &&
      size - num_rows * padded_row_size >= unpadded_row_size) {
    num_rows++;
  }
  return num_rows;
}

void GLES2Implementation::TexSubImage2DImpl(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
    GLsizei height, GLenum format, GLenum type, uint32 unpadded_row_size,
    const void* pixels, uint32 pixels_padded_row_size, GLboolean internal,
    ScopedTransferBufferPtr* buffer, uint32 buffer_padded_row_size) {
  DCHECK(buffer);
  DCHECK_GE(level, 0);
  DCHECK_GT(height, 0);
  DCHECK_GT(width, 0);

  const int8* source = reinterpret_cast<const int8*>(pixels);
  GLint original_yoffset = yoffset;
  // Transfer by rows.
  while (height) {
    unsigned int desired_size =
        buffer_padded_row_size * (height - 1) + unpadded_row_size;
    if (!buffer->valid() || buffer->size() == 0) {
      buffer->Reset(desired_size);
      if (!buffer->valid()) {
        return;
      }
    }

    GLint num_rows = ComputeNumRowsThatFitInBuffer(
        buffer_padded_row_size, unpadded_row_size, buffer->size(), height);
    num_rows = std::min(num_rows, height);
    CopyRectToBuffer(
        source, num_rows, unpadded_row_size, pixels_padded_row_size,
        unpack_flip_y_, buffer->address(), buffer_padded_row_size);
    GLint y = unpack_flip_y_ ? original_yoffset + height - num_rows : yoffset;
    helper_->TexSubImage2D(
        target, level, xoffset, y, width, num_rows, format, type,
        buffer->shm_id(), buffer->offset(), internal);
    buffer->Release();
    yoffset += num_rows;
    source += num_rows * pixels_padded_row_size;
    height -= num_rows;
  }
}

void GLES2Implementation::TexSubImage3DImpl(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei zoffset,
    GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type,
    uint32 unpadded_row_size, const void* pixels, uint32 pixels_padded_row_size,
    GLboolean internal, ScopedTransferBufferPtr* buffer,
    uint32 buffer_padded_row_size) {
  DCHECK(buffer);
  DCHECK_GE(level, 0);
  DCHECK_GT(height, 0);
  DCHECK_GT(width, 0);
  DCHECK_GT(depth, 0);
  const int8* source = reinterpret_cast<const int8*>(pixels);
  GLsizei total_rows = height * depth;
  GLint row_index = 0, depth_index = 0;
  while (total_rows) {
    // Each time, we either copy one or more images, or copy one or more rows
    // within a single image, depending on the buffer size limit.
    GLsizei max_rows;
    unsigned int desired_size;
    if (row_index > 0) {
      // We are in the middle of an image. Send the remaining of the image.
      max_rows = height - row_index;
      if (total_rows <= height) {
        // Last image, so last row is unpadded.
        desired_size = buffer_padded_row_size * (max_rows - 1) +
            unpadded_row_size;
      } else {
        desired_size = buffer_padded_row_size * max_rows;
      }
    } else {
      // Send all the remaining data if possible.
      max_rows = total_rows;
      desired_size =
          buffer_padded_row_size * (max_rows - 1) + unpadded_row_size;
    }
    if (!buffer->valid() || buffer->size() == 0) {
      buffer->Reset(desired_size);
      if (!buffer->valid()) {
        return;
      }
    }
    GLint num_rows = ComputeNumRowsThatFitInBuffer(
        buffer_padded_row_size, unpadded_row_size, buffer->size(), total_rows);
    num_rows = std::min(num_rows, max_rows);
    GLint num_images = num_rows / height;
    GLsizei my_height, my_depth;
    if (num_images > 0) {
      num_rows = num_images * height;
      my_height = height;
      my_depth = num_images;
    } else {
      my_height = num_rows;
      my_depth = 1;
    }

    // TODO(zmo): Ignore flip_y flag for now.
    if (num_images > 0) {
      int8* buffer_pointer = reinterpret_cast<int8*>(buffer->address());
      uint32 src_height =
          unpack_image_height_ > 0 ? unpack_image_height_ : height;
      uint32 image_size_dst = buffer_padded_row_size * height;
      uint32 image_size_src = pixels_padded_row_size * src_height;
      for (GLint ii = 0; ii < num_images; ++ii) {
        uint32 my_unpadded_row_size;
        if (total_rows == num_rows && ii + 1 == num_images)
          my_unpadded_row_size = unpadded_row_size;
        else
          my_unpadded_row_size = pixels_padded_row_size;
        CopyRectToBuffer(
            source + ii * image_size_src, my_height, my_unpadded_row_size,
            pixels_padded_row_size, false, buffer_pointer + ii * image_size_dst,
            buffer_padded_row_size);
      }
    } else {
      uint32 my_unpadded_row_size;
      if (total_rows == num_rows)
        my_unpadded_row_size = unpadded_row_size;
      else
        my_unpadded_row_size = pixels_padded_row_size;
      CopyRectToBuffer(
          source, my_height, my_unpadded_row_size, pixels_padded_row_size,
          false, buffer->address(), buffer_padded_row_size);
    }
    helper_->TexSubImage3D(
        target, level, xoffset, yoffset + row_index, zoffset + depth_index,
        width, my_height, my_depth,
        format, type, buffer->shm_id(), buffer->offset(), internal);
    buffer->Release();

    total_rows -= num_rows;
    if (total_rows > 0) {
      GLint num_image_paddings;
      if (num_images > 0) {
        DCHECK_EQ(row_index, 0);
        depth_index += num_images;
        num_image_paddings = num_images;
      } else {
        row_index = (row_index + my_height) % height;
        num_image_paddings = 0;
        if (my_height > 0 && row_index == 0) {
          depth_index++;
          num_image_paddings++;
        }
      }
      source += num_rows * pixels_padded_row_size;
      if (unpack_image_height_ > height && num_image_paddings > 0) {
        source += num_image_paddings * (unpack_image_height_ - height) *
            pixels_padded_row_size;
      }
    }
  }
}

bool GLES2Implementation::GetActiveAttribHelper(
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size,
    GLenum* type, char* name) {
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  typedef cmds::GetActiveAttrib::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  // Set as failed so if the command fails we'll recover.
  result->success = false;
  helper_->GetActiveAttrib(program, index, kResultBucketId,
                           GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  if (result->success) {
    if (size) {
      *size = result->size;
    }
    if (type) {
      *type = result->type;
    }
    if (length || name) {
      std::vector<int8> str;
      GetBucketContents(kResultBucketId, &str);
      GLsizei max_size = std::min(static_cast<size_t>(bufsize) - 1,
                                  std::max(static_cast<size_t>(0),
                                           str.size() - 1));
      if (length) {
        *length = max_size;
      }
      if (name && bufsize > 0) {
        memcpy(name, &str[0], max_size);
        name[max_size] = '\0';
      }
    }
  }
  return result->success != 0;
}

void GLES2Implementation::GetActiveAttrib(
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size,
    GLenum* type, char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetActiveAttrib("
      << program << ", " << index << ", " << bufsize << ", "
      << static_cast<const void*>(length) << ", "
      << static_cast<const void*>(size) << ", "
      << static_cast<const void*>(type) << ", "
      << static_cast<const void*>(name) << ", ");
  if (bufsize < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetActiveAttrib", "bufsize < 0");
    return;
  }
  TRACE_EVENT0("gpu", "GLES2::GetActiveAttrib");
  bool success = share_group_->program_info_manager()->GetActiveAttrib(
        this, program, index, bufsize, length, size, type, name);
  if (success) {
    if (size) {
      GPU_CLIENT_LOG("  size: " << *size);
    }
    if (type) {
      GPU_CLIENT_LOG("  type: " << GLES2Util::GetStringEnum(*type));
    }
    if (name) {
      GPU_CLIENT_LOG("  name: " << name);
    }
  }
  CheckGLError();
}

bool GLES2Implementation::GetActiveUniformHelper(
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size,
    GLenum* type, char* name) {
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  typedef cmds::GetActiveUniform::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  // Set as failed so if the command fails we'll recover.
  result->success = false;
  helper_->GetActiveUniform(program, index, kResultBucketId,
                            GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  if (result->success) {
    if (size) {
      *size = result->size;
    }
    if (type) {
      *type = result->type;
    }
    if (length || name) {
      std::vector<int8> str;
      GetBucketContents(kResultBucketId, &str);
      GLsizei max_size = std::min(static_cast<size_t>(bufsize) - 1,
                                  std::max(static_cast<size_t>(0),
                                           str.size() - 1));
      if (length) {
        *length = max_size;
      }
      if (name && bufsize > 0) {
        memcpy(name, &str[0], max_size);
        name[max_size] = '\0';
      }
    }
  }
  return result->success != 0;
}

void GLES2Implementation::GetActiveUniform(
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size,
    GLenum* type, char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetActiveUniform("
      << program << ", " << index << ", " << bufsize << ", "
      << static_cast<const void*>(length) << ", "
      << static_cast<const void*>(size) << ", "
      << static_cast<const void*>(type) << ", "
      << static_cast<const void*>(name) << ", ");
  if (bufsize < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetActiveUniform", "bufsize < 0");
    return;
  }
  TRACE_EVENT0("gpu", "GLES2::GetActiveUniform");
  bool success = share_group_->program_info_manager()->GetActiveUniform(
      this, program, index, bufsize, length, size, type, name);
  if (success) {
    if (size) {
      GPU_CLIENT_LOG("  size: " << *size);
    }
    if (type) {
      GPU_CLIENT_LOG("  type: " << GLES2Util::GetStringEnum(*type));
    }
    if (name) {
      GPU_CLIENT_LOG("  name: " << name);
    }
  }
  CheckGLError();
}

bool GLES2Implementation::GetActiveUniformBlockNameHelper(
    GLuint program, GLuint index, GLsizei bufsize,
    GLsizei* length, char* name) {
  DCHECK_LE(0, bufsize);
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  typedef cmds::GetActiveUniformBlockName::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  // Set as failed so if the command fails we'll recover.
  *result = 0;
  helper_->GetActiveUniformBlockName(program, index, kResultBucketId,
                                     GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  if (*result) {
    if (bufsize == 0) {
      if (length) {
        *length = 0;
      }
    } else if (length || name) {
      std::vector<int8> str;
      GetBucketContents(kResultBucketId, &str);
      DCHECK_GT(str.size(), 0u);
      GLsizei max_size =
          std::min(bufsize, static_cast<GLsizei>(str.size())) - 1;
      if (length) {
        *length = max_size;
      }
      if (name) {
        memcpy(name, &str[0], max_size);
        name[max_size] = '\0';
      }
    }
  }
  return *result != 0;
}

void GLES2Implementation::GetActiveUniformBlockName(
    GLuint program, GLuint index, GLsizei bufsize,
    GLsizei* length, char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetActiveUniformBlockName("
      << program << ", " << index << ", " << bufsize << ", "
      << static_cast<const void*>(length) << ", "
      << static_cast<const void*>(name) << ")");
  if (bufsize < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetActiveUniformBlockName", "bufsize < 0");
    return;
  }
  TRACE_EVENT0("gpu", "GLES2::GetActiveUniformBlockName");
  bool success =
      share_group_->program_info_manager()->GetActiveUniformBlockName(
          this, program, index, bufsize, length, name);
  if (success) {
    if (name) {
      GPU_CLIENT_LOG("  name: " << name);
    }
  }
  CheckGLError();
}

bool GLES2Implementation::GetActiveUniformBlockivHelper(
    GLuint program, GLuint index, GLenum pname, GLint* params) {
  typedef cmds::GetActiveUniformBlockiv::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  result->SetNumResults(0);
  helper_->GetActiveUniformBlockiv(
      program, index, pname, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  if (result->GetNumResults() > 0) {
    if (params) {
      result->CopyResult(params);
    }
    GPU_CLIENT_LOG_CODE_BLOCK({
      for (int32_t i = 0; i < result->GetNumResults(); ++i) {
        GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
      }
    });
    return true;
  }
  return false;
}

void GLES2Implementation::GetActiveUniformBlockiv(
    GLuint program, GLuint index, GLenum pname, GLint* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetActiveUniformBlockiv("
      << program << ", " << index << ", "
      << GLES2Util::GetStringUniformBlockParameter(pname) << ", "
      << static_cast<const void*>(params) << ")");
  TRACE_EVENT0("gpu", "GLES2::GetActiveUniformBlockiv");
  bool success =
      share_group_->program_info_manager()->GetActiveUniformBlockiv(
          this, program, index, pname, params);
  if (success) {
    if (params) {
      // TODO(zmo): For GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, there will
      // be more than one value returned in params.
      GPU_CLIENT_LOG("  params: " << params[0]);
    }
  }
  CheckGLError();
}

bool GLES2Implementation::GetActiveUniformsivHelper(
    GLuint program, GLsizei count, const GLuint* indices,
    GLenum pname, GLint* params) {
  typedef cmds::GetActiveUniformsiv::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  result->SetNumResults(0);
  base::CheckedNumeric<size_t> bytes = static_cast<size_t>(count);
  bytes *= sizeof(GLuint);
  if (!bytes.IsValid()) {
    SetGLError(GL_INVALID_VALUE, "glGetActiveUniformsiv", "count overflow");
    return false;
  }
  SetBucketContents(kResultBucketId, indices, bytes.ValueOrDefault(0));
  helper_->GetActiveUniformsiv(
      program, kResultBucketId, pname, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  bool success = result->GetNumResults() == count;
  if (success) {
    if (params) {
      result->CopyResult(params);
    }
    GPU_CLIENT_LOG_CODE_BLOCK({
      for (int32_t i = 0; i < result->GetNumResults(); ++i) {
        GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
      }
    });
  }
  helper_->SetBucketSize(kResultBucketId, 0);
  return success;
}

void GLES2Implementation::GetActiveUniformsiv(
    GLuint program, GLsizei count, const GLuint* indices,
    GLenum pname, GLint* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetActiveUniformsiv("
      << program << ", " << count << ", "
      << static_cast<const void*>(indices) << ", "
      << GLES2Util::GetStringUniformParameter(pname) << ", "
      << static_cast<const void*>(params) << ")");
  TRACE_EVENT0("gpu", "GLES2::GetActiveUniformsiv");
  if (count < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetActiveUniformsiv", "count < 0");
    return;
  }
  bool success = share_group_->program_info_manager()->GetActiveUniformsiv(
      this, program, count, indices, pname, params);
  if (success) {
    if (params) {
      GPU_CLIENT_LOG_CODE_BLOCK({
        for (GLsizei ii = 0; ii < count; ++ii) {
          GPU_CLIENT_LOG("  " << ii << ": " << params[ii]);
        }
      });
    }
  }
  CheckGLError();
}

void GLES2Implementation::GetAttachedShaders(
    GLuint program, GLsizei maxcount, GLsizei* count, GLuint* shaders) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetAttachedShaders("
      << program << ", " << maxcount << ", "
      << static_cast<const void*>(count) << ", "
      << static_cast<const void*>(shaders) << ", ");
  if (maxcount < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetAttachedShaders", "maxcount < 0");
    return;
  }
  TRACE_EVENT0("gpu", "GLES2::GetAttachedShaders");
  typedef cmds::GetAttachedShaders::Result Result;
  uint32 size = Result::ComputeSize(maxcount);
  Result* result = static_cast<Result*>(transfer_buffer_->Alloc(size));
  if (!result) {
    return;
  }
  result->SetNumResults(0);
  helper_->GetAttachedShaders(
    program,
    transfer_buffer_->GetShmId(),
    transfer_buffer_->GetOffset(result),
    size);
  int32 token = helper_->InsertToken();
  WaitForCmd();
  if (count) {
    *count = result->GetNumResults();
  }
  result->CopyResult(shaders);
  GPU_CLIENT_LOG_CODE_BLOCK({
    for (int32 i = 0; i < result->GetNumResults(); ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
    }
  });
  transfer_buffer_->FreePendingToken(result, token);
  CheckGLError();
}

void GLES2Implementation::GetShaderPrecisionFormat(
    GLenum shadertype, GLenum precisiontype, GLint* range, GLint* precision) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetShaderPrecisionFormat("
      << GLES2Util::GetStringShaderType(shadertype) << ", "
      << GLES2Util::GetStringShaderPrecision(precisiontype) << ", "
      << static_cast<const void*>(range) << ", "
      << static_cast<const void*>(precision) << ", ");
  TRACE_EVENT0("gpu", "GLES2::GetShaderPrecisionFormat");
  typedef cmds::GetShaderPrecisionFormat::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return;
  }

  GLStaticState::ShaderPrecisionKey key(shadertype, precisiontype);
  GLStaticState::ShaderPrecisionMap::iterator i =
      static_state_.shader_precisions.find(key);
  if (i != static_state_.shader_precisions.end()) {
    *result = i->second;
  } else {
    result->success = false;
    helper_->GetShaderPrecisionFormat(
        shadertype, precisiontype, GetResultShmId(), GetResultShmOffset());
    WaitForCmd();
    if (result->success)
      static_state_.shader_precisions[key] = *result;
  }

  if (result->success) {
    if (range) {
      range[0] = result->min_range;
      range[1] = result->max_range;
      GPU_CLIENT_LOG("  min_range: " << range[0]);
      GPU_CLIENT_LOG("  min_range: " << range[1]);
    }
    if (precision) {
      precision[0] = result->precision;
      GPU_CLIENT_LOG("  min_range: " << precision[0]);
    }
  }
  CheckGLError();
}

const GLubyte* GLES2Implementation::GetStringHelper(GLenum name) {
  const char* result = NULL;
  // Clears the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->GetString(name, kResultBucketId);
  std::string str;
  if (GetBucketAsString(kResultBucketId, &str)) {
    // Adds extensions implemented on client side only.
    switch (name) {
      case GL_EXTENSIONS:
        str += std::string(str.empty() ? "" : " ") +
            "GL_CHROMIUM_flipy "
            "GL_EXT_unpack_subimage "
            "GL_CHROMIUM_map_sub";
        if (capabilities_.image)
          str += " GL_CHROMIUM_image GL_CHROMIUM_gpu_memory_buffer_image";
        if (capabilities_.future_sync_points)
          str += " GL_CHROMIUM_future_sync_point";
        break;
      default:
        break;
    }

    // Because of WebGL the extensions can change. We have to cache each unique
    // result since we don't know when the client will stop referring to a
    // previous one it queries.
    GLStringMap::iterator it = gl_strings_.find(name);
    if (it == gl_strings_.end()) {
      std::set<std::string> strings;
      std::pair<GLStringMap::iterator, bool> insert_result =
          gl_strings_.insert(std::make_pair(name, strings));
      DCHECK(insert_result.second);
      it = insert_result.first;
    }
    std::set<std::string>& string_set = it->second;
    std::set<std::string>::const_iterator sit = string_set.find(str);
    if (sit != string_set.end()) {
      result = sit->c_str();
    } else {
      std::pair<std::set<std::string>::const_iterator, bool> insert_result =
          string_set.insert(str);
      DCHECK(insert_result.second);
      result = insert_result.first->c_str();
    }
  }
  return reinterpret_cast<const GLubyte*>(result);
}

const GLubyte* GLES2Implementation::GetString(GLenum name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetString("
      << GLES2Util::GetStringStringType(name) << ")");
  TRACE_EVENT0("gpu", "GLES2::GetString");
  const GLubyte* result = GetStringHelper(name);
  GPU_CLIENT_LOG("  returned " << reinterpret_cast<const char*>(result));
  CheckGLError();
  return result;
}

bool GLES2Implementation::GetTransformFeedbackVaryingHelper(
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size,
    GLenum* type, char* name) {
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  typedef cmds::GetTransformFeedbackVarying::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  // Set as failed so if the command fails we'll recover.
  result->success = false;
  helper_->GetTransformFeedbackVarying(
      program, index, kResultBucketId, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  if (result->success) {
    if (size) {
      *size = result->size;
    }
    if (type) {
      *type = result->type;
    }
    if (length || name) {
      std::vector<int8> str;
      GetBucketContents(kResultBucketId, &str);
      GLsizei max_size = std::min(bufsize, static_cast<GLsizei>(str.size()));
      if (max_size > 0) {
        --max_size;
      }
      if (length) {
        *length = max_size;
      }
      if (name) {
        if (max_size > 0) {
          memcpy(name, &str[0], max_size);
          name[max_size] = '\0';
        } else if (bufsize > 0) {
          name[0] = '\0';
        }
      }
    }
  }
  return result->success != 0;
}

void GLES2Implementation::GetTransformFeedbackVarying(
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size,
    GLenum* type, char* name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetTransformFeedbackVarying("
      << program << ", " << index << ", " << bufsize << ", "
      << static_cast<const void*>(length) << ", "
      << static_cast<const void*>(size) << ", "
      << static_cast<const void*>(type) << ", "
      << static_cast<const void*>(name) << ", ");
  if (bufsize < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetTransformFeedbackVarying",
               "bufsize < 0");
    return;
  }
  TRACE_EVENT0("gpu", "GLES2::GetTransformFeedbackVarying");
  bool success =
      share_group_->program_info_manager()->GetTransformFeedbackVarying(
          this, program, index, bufsize, length, size, type, name);
  if (success) {
    if (size) {
      GPU_CLIENT_LOG("  size: " << *size);
    }
    if (type) {
      GPU_CLIENT_LOG("  type: " << GLES2Util::GetStringEnum(*type));
    }
    if (name) {
      GPU_CLIENT_LOG("  name: " << name);
    }
  }
  CheckGLError();
}

void GLES2Implementation::GetUniformfv(
    GLuint program, GLint location, GLfloat* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetUniformfv("
      << program << ", " << location << ", "
      << static_cast<const void*>(params) << ")");
  TRACE_EVENT0("gpu", "GLES2::GetUniformfv");
  typedef cmds::GetUniformfv::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return;
  }
  result->SetNumResults(0);
  helper_->GetUniformfv(
      program, location, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  result->CopyResult(params);
  GPU_CLIENT_LOG_CODE_BLOCK({
    for (int32 i = 0; i < result->GetNumResults(); ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
    }
  });
  CheckGLError();
}

void GLES2Implementation::GetUniformiv(
    GLuint program, GLint location, GLint* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetUniformiv("
      << program << ", " << location << ", "
      << static_cast<const void*>(params) << ")");
  TRACE_EVENT0("gpu", "GLES2::GetUniformiv");
  typedef cmds::GetUniformiv::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return;
  }
  result->SetNumResults(0);
  helper_->GetUniformiv(
      program, location, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  GetResultAs<cmds::GetUniformfv::Result*>()->CopyResult(params);
  GPU_CLIENT_LOG_CODE_BLOCK({
    for (int32 i = 0; i < result->GetNumResults(); ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
    }
  });
  CheckGLError();
}

void GLES2Implementation::ReadPixels(
    GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format,
    GLenum type, void* pixels) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glReadPixels("
      << xoffset << ", " << yoffset << ", "
      << width << ", " << height << ", "
      << GLES2Util::GetStringReadPixelFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << static_cast<const void*>(pixels) << ")");
  if (width < 0 || height < 0) {
    SetGLError(GL_INVALID_VALUE, "glReadPixels", "dimensions < 0");
    return;
  }
  if (width == 0 || height == 0) {
    return;
  }

  // glReadPixel pads the size of each row of pixels by an amount specified by
  // glPixelStorei. So, we have to take that into account both in the fact that
  // the pixels returned from the ReadPixel command will include that padding
  // and that when we copy the results to the user's buffer we need to not
  // write those padding bytes but leave them as they are.

  TRACE_EVENT0("gpu", "GLES2::ReadPixels");
  typedef cmds::ReadPixels::Result Result;

  int8* dest = reinterpret_cast<int8*>(pixels);
  uint32 temp_size;
  uint32 unpadded_row_size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, 2, 1, format, type, pack_alignment_, &temp_size,
      &unpadded_row_size, &padded_row_size)) {
    SetGLError(GL_INVALID_VALUE, "glReadPixels", "size too large.");
    return;
  }

  if (bound_pixel_pack_transfer_buffer_id_) {
    GLuint offset = ToGLuint(pixels);
    BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
        bound_pixel_pack_transfer_buffer_id_,
        "glReadPixels", offset, padded_row_size * height);
    if (buffer && buffer->shm_id() != -1) {
      helper_->ReadPixels(xoffset, yoffset, width, height, format, type,
                          buffer->shm_id(), buffer->shm_offset(),
                          0, 0, true);
      CheckGLError();
    }
    return;
  }

  if (!pixels) {
    SetGLError(GL_INVALID_OPERATION, "glReadPixels", "pixels = NULL");
    return;
  }

  // Transfer by rows.
  // The max rows we can transfer.
  while (height) {
    GLsizei desired_size = padded_row_size * (height - 1) + unpadded_row_size;
    ScopedTransferBufferPtr buffer(desired_size, helper_, transfer_buffer_);
    if (!buffer.valid()) {
      return;
    }
    GLint num_rows = ComputeNumRowsThatFitInBuffer(
        padded_row_size, unpadded_row_size, buffer.size(), height);
    num_rows = std::min(num_rows, height);
    // NOTE: We must look up the address of the result area AFTER allocation
    // of the transfer buffer since the transfer buffer may be reallocated.
    Result* result = GetResultAs<Result*>();
    if (!result) {
      return;
    }
    *result = 0;  // mark as failed.
    helper_->ReadPixels(
        xoffset, yoffset, width, num_rows, format, type,
        buffer.shm_id(), buffer.offset(),
        GetResultShmId(), GetResultShmOffset(),
        false);
    WaitForCmd();
    if (*result != 0) {
      // when doing a y-flip we have to iterate through top-to-bottom chunks
      // of the dst. The service side handles reversing the rows within a
      // chunk.
      int8* rows_dst;
      if (pack_reverse_row_order_) {
          rows_dst = dest + (height - num_rows) * padded_row_size;
      } else {
          rows_dst = dest;
      }
      // We have to copy 1 row at a time to avoid writing pad bytes.
      const int8* src = static_cast<const int8*>(buffer.address());
      for (GLint yy = 0; yy < num_rows; ++yy) {
        memcpy(rows_dst, src, unpadded_row_size);
        rows_dst += padded_row_size;
        src += padded_row_size;
      }
      if (!pack_reverse_row_order_) {
        dest = rows_dst;
      }
    }
    // If it was not marked as successful exit.
    if (*result == 0) {
      return;
    }
    yoffset += num_rows;
    height -= num_rows;
  }
  CheckGLError();
}

void GLES2Implementation::ActiveTexture(GLenum texture) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glActiveTexture("
      << GLES2Util::GetStringEnum(texture) << ")");
  GLuint texture_index = texture - GL_TEXTURE0;
  if (texture_index >=
      static_cast<GLuint>(capabilities_.max_combined_texture_image_units)) {
    SetGLErrorInvalidEnum(
        "glActiveTexture", texture, "texture");
    return;
  }

  active_texture_unit_ = texture_index;
  helper_->ActiveTexture(texture);
  CheckGLError();
}

void GLES2Implementation::GenBuffersHelper(
    GLsizei /* n */, const GLuint* /* buffers */) {
}

void GLES2Implementation::GenFramebuffersHelper(
    GLsizei /* n */, const GLuint* /* framebuffers */) {
}

void GLES2Implementation::GenRenderbuffersHelper(
    GLsizei /* n */, const GLuint* /* renderbuffers */) {
}

void GLES2Implementation::GenTexturesHelper(
    GLsizei /* n */, const GLuint* /* textures */) {
}

void GLES2Implementation::GenVertexArraysOESHelper(
    GLsizei n, const GLuint* arrays) {
  vertex_array_object_manager_->GenVertexArrays(n, arrays);
}

void GLES2Implementation::GenQueriesEXTHelper(
    GLsizei /* n */, const GLuint* /* queries */) {
}

void GLES2Implementation::GenValuebuffersCHROMIUMHelper(
    GLsizei /* n */,
    const GLuint* /* valuebuffers */) {
}

void GLES2Implementation::GenSamplersHelper(
    GLsizei /* n */, const GLuint* /* samplers */) {
}

void GLES2Implementation::GenTransformFeedbacksHelper(
    GLsizei /* n */, const GLuint* /* transformfeedbacks */) {
}

// NOTE #1: On old versions of OpenGL, calling glBindXXX with an unused id
// generates a new resource. On newer versions of OpenGL they don't. The code
// related to binding below will need to change if we switch to the new OpenGL
// model. Specifically it assumes a bind will succeed which is always true in
// the old model but possibly not true in the new model if another context has
// deleted the resource.

// NOTE #2: There is a bug in some BindXXXHelpers, that IDs might be marked as
// used even when Bind has failed. However, the bug is minor compared to the
// overhead & duplicated checking in client side.

void GLES2Implementation::BindBufferHelper(
    GLenum target, GLuint buffer_id) {
  // TODO(gman): See note #1 above.
  bool changed = false;
  switch (target) {
    case GL_ARRAY_BUFFER:
      if (bound_array_buffer_id_ != buffer_id) {
        bound_array_buffer_id_ = buffer_id;
        changed = true;
      }
      break;
    case GL_ELEMENT_ARRAY_BUFFER:
      changed = vertex_array_object_manager_->BindElementArray(buffer_id);
      break;
    case GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM:
      bound_pixel_pack_transfer_buffer_id_ = buffer_id;
      break;
    case GL_PIXEL_UNPACK_TRANSFER_BUFFER_CHROMIUM:
      bound_pixel_unpack_transfer_buffer_id_ = buffer_id;
      break;
    default:
      changed = true;
      break;
  }
  // TODO(gman): See note #2 above.
  if (changed) {
    GetIdHandler(id_namespaces::kBuffers)->MarkAsUsedForBind(
        this, target, buffer_id, &GLES2Implementation::BindBufferStub);
  }
}

void GLES2Implementation::BindBufferStub(GLenum target, GLuint buffer) {
  helper_->BindBuffer(target, buffer);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::BindBufferBaseHelper(
    GLenum target, GLuint index, GLuint buffer_id) {
  // TODO(zmo): See note #1 above.
  // TODO(zmo): See note #2 above.
  GetIdHandler(id_namespaces::kBuffers)->MarkAsUsedForBind(
      this, target, index, buffer_id, &GLES2Implementation::BindBufferBaseStub);
}

void GLES2Implementation::BindBufferBaseStub(
    GLenum target, GLuint index, GLuint buffer) {
  helper_->BindBufferBase(target, index, buffer);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::BindBufferRangeHelper(
    GLenum target, GLuint index, GLuint buffer_id,
    GLintptr offset, GLsizeiptr size) {
  // TODO(zmo): See note #1 above.
  // TODO(zmo): See note #2 above.
  GetIdHandler(id_namespaces::kBuffers)->MarkAsUsedForBind(
      this, target, index, buffer_id, offset, size,
      &GLES2Implementation::BindBufferRangeStub);
}

void GLES2Implementation::BindBufferRangeStub(
    GLenum target, GLuint index, GLuint buffer,
    GLintptr offset, GLsizeiptr size) {
  helper_->BindBufferRange(target, index, buffer, offset, size);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::BindFramebufferHelper(
    GLenum target, GLuint framebuffer) {
  // TODO(gman): See note #1 above.
  bool changed = false;
  switch (target) {
    case GL_FRAMEBUFFER:
      if (bound_framebuffer_ != framebuffer ||
          bound_read_framebuffer_ != framebuffer) {
        bound_framebuffer_ = framebuffer;
        bound_read_framebuffer_ = framebuffer;
        changed = true;
      }
      break;
    case GL_READ_FRAMEBUFFER:
      if (!IsChromiumFramebufferMultisampleAvailable()) {
        SetGLErrorInvalidEnum("glBindFramebuffer", target, "target");
        return;
      }
      if (bound_read_framebuffer_ != framebuffer) {
        bound_read_framebuffer_ = framebuffer;
        changed = true;
      }
      break;
    case GL_DRAW_FRAMEBUFFER:
      if (!IsChromiumFramebufferMultisampleAvailable()) {
        SetGLErrorInvalidEnum("glBindFramebuffer", target, "target");
        return;
      }
      if (bound_framebuffer_ != framebuffer) {
        bound_framebuffer_ = framebuffer;
        changed = true;
      }
      break;
    default:
      SetGLErrorInvalidEnum("glBindFramebuffer", target, "target");
      return;
  }

  if (changed) {
    GetIdHandler(id_namespaces::kFramebuffers)->MarkAsUsedForBind(
        this, target, framebuffer, &GLES2Implementation::BindFramebufferStub);
  }
}

void GLES2Implementation::BindFramebufferStub(GLenum target,
                                              GLuint framebuffer) {
  helper_->BindFramebuffer(target, framebuffer);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::BindRenderbufferHelper(
    GLenum target, GLuint renderbuffer) {
  // TODO(gman): See note #1 above.
  bool changed = false;
  switch (target) {
    case GL_RENDERBUFFER:
      if (bound_renderbuffer_ != renderbuffer) {
        bound_renderbuffer_ = renderbuffer;
        changed = true;
      }
      break;
    default:
      changed = true;
      break;
  }
  // TODO(zmo): See note #2 above.
  if (changed) {
    GetIdHandler(id_namespaces::kRenderbuffers)->MarkAsUsedForBind(
        this, target, renderbuffer,
        &GLES2Implementation::BindRenderbufferStub);
  }
}

void GLES2Implementation::BindRenderbufferStub(GLenum target,
                                               GLuint renderbuffer) {
  helper_->BindRenderbuffer(target, renderbuffer);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::BindSamplerHelper(GLuint unit,
                                            GLuint sampler) {
  helper_->BindSampler(unit, sampler);
}

void GLES2Implementation::BindTextureHelper(GLenum target, GLuint texture) {
  // TODO(gman): See note #1 above.
  // TODO(gman): Change this to false once we figure out why it's failing
  //     on daisy.
  bool changed = true;
  TextureUnit& unit = texture_units_[active_texture_unit_];
  switch (target) {
    case GL_TEXTURE_2D:
      if (unit.bound_texture_2d != texture) {
        unit.bound_texture_2d = texture;
        changed = true;
      }
      break;
    case GL_TEXTURE_CUBE_MAP:
      if (unit.bound_texture_cube_map != texture) {
        unit.bound_texture_cube_map = texture;
        changed = true;
      }
      break;
    case GL_TEXTURE_EXTERNAL_OES:
      if (unit.bound_texture_external_oes != texture) {
        unit.bound_texture_external_oes = texture;
        changed = true;
      }
      break;
    default:
      changed = true;
      break;
  }
  // TODO(gman): See note #2 above.
  if (changed) {
    GetIdHandler(id_namespaces::kTextures)->MarkAsUsedForBind(
        this, target, texture, &GLES2Implementation::BindTextureStub);
  }
}

void GLES2Implementation::BindTextureStub(GLenum target, GLuint texture) {
  helper_->BindTexture(target, texture);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::BindTransformFeedbackHelper(
    GLenum target, GLuint transformfeedback) {
  helper_->BindTransformFeedback(target, transformfeedback);
}

void GLES2Implementation::BindVertexArrayOESHelper(GLuint array) {
  bool changed = false;
  if (vertex_array_object_manager_->BindVertexArray(array, &changed)) {
    if (changed) {
      // Unlike other BindXXXHelpers we don't call MarkAsUsedForBind
      // because unlike other resources VertexArrayObject ids must
      // be generated by GenVertexArrays. A random id to Bind will not
      // generate a new object.
      helper_->BindVertexArrayOES(array);
    }
  } else {
    SetGLError(
        GL_INVALID_OPERATION, "glBindVertexArrayOES",
        "id was not generated with glGenVertexArrayOES");
  }
}

void GLES2Implementation::BindValuebufferCHROMIUMHelper(GLenum target,
                                                        GLuint valuebuffer) {
  bool changed = false;
  switch (target) {
    case GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM:
      if (bound_valuebuffer_ != valuebuffer) {
        bound_valuebuffer_ = valuebuffer;
        changed = true;
      }
      break;
    default:
      changed = true;
      break;
  }
  // TODO(gman): See note #2 above.
  if (changed) {
    GetIdHandler(id_namespaces::kValuebuffers)->MarkAsUsedForBind(
        this, target, valuebuffer,
        &GLES2Implementation::BindValuebufferCHROMIUMStub);
  }
}

void GLES2Implementation::BindValuebufferCHROMIUMStub(GLenum target,
                                                      GLuint valuebuffer) {
  helper_->BindValuebufferCHROMIUM(target, valuebuffer);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
}

void GLES2Implementation::UseProgramHelper(GLuint program) {
  if (current_program_ != program) {
    current_program_ = program;
    helper_->UseProgram(program);
  }
}

bool GLES2Implementation::IsBufferReservedId(GLuint id) {
  return vertex_array_object_manager_->IsReservedId(id);
}

void GLES2Implementation::DeleteBuffersHelper(
    GLsizei n, const GLuint* buffers) {
  if (!GetIdHandler(id_namespaces::kBuffers)->FreeIds(
      this, n, buffers, &GLES2Implementation::DeleteBuffersStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteBuffers", "id not created by this context.");
    return;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (buffers[ii] == bound_array_buffer_id_) {
      bound_array_buffer_id_ = 0;
    }
    vertex_array_object_manager_->UnbindBuffer(buffers[ii]);

    BufferTracker::Buffer* buffer = buffer_tracker_->GetBuffer(buffers[ii]);
    if (buffer)
      RemoveTransferBuffer(buffer);

    if (buffers[ii] == bound_pixel_unpack_transfer_buffer_id_) {
      bound_pixel_unpack_transfer_buffer_id_ = 0;
    }

    RemoveMappedBufferRangeById(buffers[ii]);
  }
}

void GLES2Implementation::DeleteBuffersStub(
    GLsizei n, const GLuint* buffers) {
  helper_->DeleteBuffersImmediate(n, buffers);
}


void GLES2Implementation::DeleteFramebuffersHelper(
    GLsizei n, const GLuint* framebuffers) {
  if (!GetIdHandler(id_namespaces::kFramebuffers)->FreeIds(
      this, n, framebuffers, &GLES2Implementation::DeleteFramebuffersStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteFramebuffers", "id not created by this context.");
    return;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (framebuffers[ii] == bound_framebuffer_) {
      bound_framebuffer_ = 0;
    }
    if (framebuffers[ii] == bound_read_framebuffer_) {
      bound_read_framebuffer_ = 0;
    }
  }
}

void GLES2Implementation::DeleteFramebuffersStub(
    GLsizei n, const GLuint* framebuffers) {
  helper_->DeleteFramebuffersImmediate(n, framebuffers);
}

void GLES2Implementation::DeleteRenderbuffersHelper(
    GLsizei n, const GLuint* renderbuffers) {
  if (!GetIdHandler(id_namespaces::kRenderbuffers)->FreeIds(
      this, n, renderbuffers, &GLES2Implementation::DeleteRenderbuffersStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteRenderbuffers", "id not created by this context.");
    return;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (renderbuffers[ii] == bound_renderbuffer_) {
      bound_renderbuffer_ = 0;
    }
  }
}

void GLES2Implementation::DeleteRenderbuffersStub(
    GLsizei n, const GLuint* renderbuffers) {
  helper_->DeleteRenderbuffersImmediate(n, renderbuffers);
}

void GLES2Implementation::DeleteTexturesHelper(
    GLsizei n, const GLuint* textures) {
  if (!GetIdHandler(id_namespaces::kTextures)->FreeIds(
      this, n, textures, &GLES2Implementation::DeleteTexturesStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteTextures", "id not created by this context.");
    return;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    for (GLint tt = 0; tt < capabilities_.max_combined_texture_image_units;
         ++tt) {
      TextureUnit& unit = texture_units_[tt];
      if (textures[ii] == unit.bound_texture_2d) {
        unit.bound_texture_2d = 0;
      }
      if (textures[ii] == unit.bound_texture_cube_map) {
        unit.bound_texture_cube_map = 0;
      }
      if (textures[ii] == unit.bound_texture_external_oes) {
        unit.bound_texture_external_oes = 0;
      }
    }
  }
}

void GLES2Implementation::DeleteTexturesStub(GLsizei n,
                                             const GLuint* textures) {
  helper_->DeleteTexturesImmediate(n, textures);
}

void GLES2Implementation::DeleteVertexArraysOESHelper(
    GLsizei n, const GLuint* arrays) {
  vertex_array_object_manager_->DeleteVertexArrays(n, arrays);
  if (!GetIdHandler(id_namespaces::kVertexArrays)->FreeIds(
      this, n, arrays, &GLES2Implementation::DeleteVertexArraysOESStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteVertexArraysOES", "id not created by this context.");
    return;
  }
}

void GLES2Implementation::DeleteVertexArraysOESStub(
    GLsizei n, const GLuint* arrays) {
  helper_->DeleteVertexArraysOESImmediate(n, arrays);
}

void GLES2Implementation::DeleteValuebuffersCHROMIUMHelper(
    GLsizei n,
    const GLuint* valuebuffers) {
  if (!GetIdHandler(id_namespaces::kValuebuffers)
           ->FreeIds(this, n, valuebuffers,
                     &GLES2Implementation::DeleteValuebuffersCHROMIUMStub)) {
    SetGLError(GL_INVALID_VALUE, "glDeleteValuebuffersCHROMIUM",
               "id not created by this context.");
    return;
  }
  for (GLsizei ii = 0; ii < n; ++ii) {
    if (valuebuffers[ii] == bound_valuebuffer_) {
      bound_valuebuffer_ = 0;
    }
  }
}

void GLES2Implementation::DeleteSamplersStub(
    GLsizei n, const GLuint* samplers) {
  helper_->DeleteSamplersImmediate(n, samplers);
}

void GLES2Implementation::DeleteSamplersHelper(
    GLsizei n, const GLuint* samplers) {
  if (!GetIdHandler(id_namespaces::kSamplers)->FreeIds(
      this, n, samplers, &GLES2Implementation::DeleteSamplersStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteSamplers", "id not created by this context.");
    return;
  }
}

void GLES2Implementation::DeleteTransformFeedbacksStub(
    GLsizei n, const GLuint* transformfeedbacks) {
  helper_->DeleteTransformFeedbacksImmediate(n, transformfeedbacks);
}

void GLES2Implementation::DeleteTransformFeedbacksHelper(
    GLsizei n, const GLuint* transformfeedbacks) {
  if (!GetIdHandler(id_namespaces::kTransformFeedbacks)->FreeIds(
      this, n, transformfeedbacks,
      &GLES2Implementation::DeleteTransformFeedbacksStub)) {
    SetGLError(
        GL_INVALID_VALUE,
        "glDeleteTransformFeedbacks", "id not created by this context.");
    return;
  }
}

void GLES2Implementation::DeleteValuebuffersCHROMIUMStub(
    GLsizei n,
    const GLuint* valuebuffers) {
  helper_->DeleteValuebuffersCHROMIUMImmediate(n, valuebuffers);
}

void GLES2Implementation::DisableVertexAttribArray(GLuint index) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG(
      "[" << GetLogPrefix() << "] glDisableVertexAttribArray(" << index << ")");
  vertex_array_object_manager_->SetAttribEnable(index, false);
  helper_->DisableVertexAttribArray(index);
  CheckGLError();
}

void GLES2Implementation::EnableVertexAttribArray(GLuint index) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glEnableVertexAttribArray("
      << index << ")");
  vertex_array_object_manager_->SetAttribEnable(index, true);
  helper_->EnableVertexAttribArray(index);
  CheckGLError();
}

void GLES2Implementation::DrawArrays(GLenum mode, GLint first, GLsizei count) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glDrawArrays("
      << GLES2Util::GetStringDrawMode(mode) << ", "
      << first << ", " << count << ")");
  if (count < 0) {
    SetGLError(GL_INVALID_VALUE, "glDrawArrays", "count < 0");
    return;
  }
  bool simulated = false;
  if (!vertex_array_object_manager_->SetupSimulatedClientSideBuffers(
      "glDrawArrays", this, helper_, first + count, 0, &simulated)) {
    return;
  }
  helper_->DrawArrays(mode, first, count);
  RestoreArrayBuffer(simulated);
  CheckGLError();
}

void GLES2Implementation::GetVertexAttribfv(
    GLuint index, GLenum pname, GLfloat* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetVertexAttribfv("
      << index << ", "
      << GLES2Util::GetStringVertexAttribute(pname) << ", "
      << static_cast<const void*>(params) << ")");
  uint32 value = 0;
  if (vertex_array_object_manager_->GetVertexAttrib(index, pname, &value)) {
    *params = static_cast<float>(value);
    return;
  }
  TRACE_EVENT0("gpu", "GLES2::GetVertexAttribfv");
  typedef cmds::GetVertexAttribfv::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return;
  }
  result->SetNumResults(0);
  helper_->GetVertexAttribfv(
      index, pname, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  result->CopyResult(params);
  GPU_CLIENT_LOG_CODE_BLOCK({
    for (int32 i = 0; i < result->GetNumResults(); ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
    }
  });
  CheckGLError();
}

void GLES2Implementation::GetVertexAttribiv(
    GLuint index, GLenum pname, GLint* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGetVertexAttribiv("
      << index << ", "
      << GLES2Util::GetStringVertexAttribute(pname) << ", "
      << static_cast<const void*>(params) << ")");
  uint32 value = 0;
  if (vertex_array_object_manager_->GetVertexAttrib(index, pname, &value)) {
    *params = value;
    return;
  }
  TRACE_EVENT0("gpu", "GLES2::GetVertexAttribiv");
  typedef cmds::GetVertexAttribiv::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return;
  }
  result->SetNumResults(0);
  helper_->GetVertexAttribiv(
      index, pname, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  result->CopyResult(params);
  GPU_CLIENT_LOG_CODE_BLOCK({
    for (int32 i = 0; i < result->GetNumResults(); ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
    }
  });
  CheckGLError();
}

void GLES2Implementation::Swap() {
  SwapBuffers();
}

void GLES2Implementation::PartialSwapBuffers(const gfx::Rect& sub_buffer) {
  PostSubBufferCHROMIUM(
      sub_buffer.x(), sub_buffer.y(), sub_buffer.width(), sub_buffer.height());
}

static GLenum GetGLESOverlayTransform(gfx::OverlayTransform plane_transform) {
  switch (plane_transform) {
    case gfx::OVERLAY_TRANSFORM_INVALID:
      break;
    case gfx::OVERLAY_TRANSFORM_NONE:
      return GL_OVERLAY_TRANSFORM_NONE_CHROMIUM;
    case gfx::OVERLAY_TRANSFORM_FLIP_HORIZONTAL:
      return GL_OVERLAY_TRANSFORM_FLIP_HORIZONTAL_CHROMIUM;
    case gfx::OVERLAY_TRANSFORM_FLIP_VERTICAL:
      return GL_OVERLAY_TRANSFORM_FLIP_VERTICAL_CHROMIUM;
    case gfx::OVERLAY_TRANSFORM_ROTATE_90:
      return GL_OVERLAY_TRANSFORM_ROTATE_90_CHROMIUM;
    case gfx::OVERLAY_TRANSFORM_ROTATE_180:
      return GL_OVERLAY_TRANSFORM_ROTATE_180_CHROMIUM;
    case gfx::OVERLAY_TRANSFORM_ROTATE_270:
      return GL_OVERLAY_TRANSFORM_ROTATE_270_CHROMIUM;
  }
  NOTREACHED();
  return GL_OVERLAY_TRANSFORM_NONE_CHROMIUM;
}

void GLES2Implementation::ScheduleOverlayPlane(
    int plane_z_order,
    gfx::OverlayTransform plane_transform,
    unsigned overlay_texture_id,
    const gfx::Rect& display_bounds,
    const gfx::RectF& uv_rect) {
  ScheduleOverlayPlaneCHROMIUM(plane_z_order,
                               GetGLESOverlayTransform(plane_transform),
                               overlay_texture_id,
                               display_bounds.x(),
                               display_bounds.y(),
                               display_bounds.width(),
                               display_bounds.height(),
                               uv_rect.x(),
                               uv_rect.y(),
                               uv_rect.width(),
                               uv_rect.height());
}

GLboolean GLES2Implementation::EnableFeatureCHROMIUM(
    const char* feature) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glEnableFeatureCHROMIUM("
                 << feature << ")");
  TRACE_EVENT0("gpu", "GLES2::EnableFeatureCHROMIUM");
  typedef cmds::EnableFeatureCHROMIUM::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return false;
  }
  *result = 0;
  SetBucketAsCString(kResultBucketId, feature);
  helper_->EnableFeatureCHROMIUM(
      kResultBucketId, GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  helper_->SetBucketSize(kResultBucketId, 0);
  GPU_CLIENT_LOG("   returned " << GLES2Util::GetStringBool(*result));
  return *result != 0;
}

void* GLES2Implementation::MapBufferSubDataCHROMIUM(
    GLuint target, GLintptr offset, GLsizeiptr size, GLenum access) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glMapBufferSubDataCHROMIUM("
      << target << ", " << offset << ", " << size << ", "
      << GLES2Util::GetStringEnum(access) << ")");
  // NOTE: target is NOT checked because the service will check it
  // and we don't know what targets are valid.
  if (access != GL_WRITE_ONLY) {
    SetGLErrorInvalidEnum(
        "glMapBufferSubDataCHROMIUM", access, "access");
    return NULL;
  }
  if (!ValidateSize("glMapBufferSubDataCHROMIUM", size) ||
      !ValidateOffset("glMapBufferSubDataCHROMIUM", offset)) {
    return NULL;
  }

  int32 shm_id;
  unsigned int shm_offset;
  void* mem = mapped_memory_->Alloc(size, &shm_id, &shm_offset);
  if (!mem) {
    SetGLError(GL_OUT_OF_MEMORY, "glMapBufferSubDataCHROMIUM", "out of memory");
    return NULL;
  }

  std::pair<MappedBufferMap::iterator, bool> result =
     mapped_buffers_.insert(std::make_pair(
         mem,
         MappedBuffer(
             access, shm_id, mem, shm_offset, target, offset, size)));
  DCHECK(result.second);
  GPU_CLIENT_LOG("  returned " << mem);
  return mem;
}

void GLES2Implementation::UnmapBufferSubDataCHROMIUM(const void* mem) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG(
      "[" << GetLogPrefix() << "] glUnmapBufferSubDataCHROMIUM(" << mem << ")");
  MappedBufferMap::iterator it = mapped_buffers_.find(mem);
  if (it == mapped_buffers_.end()) {
    SetGLError(
        GL_INVALID_VALUE, "UnmapBufferSubDataCHROMIUM", "buffer not mapped");
    return;
  }
  const MappedBuffer& mb = it->second;
  helper_->BufferSubData(
      mb.target, mb.offset, mb.size, mb.shm_id, mb.shm_offset);
  mapped_memory_->FreePendingToken(mb.shm_memory, helper_->InsertToken());
  mapped_buffers_.erase(it);
  CheckGLError();
}

GLuint GLES2Implementation::GetBoundBufferHelper(GLenum target) {
  GLenum binding = GLES2Util::MapBufferTargetToBindingEnum(target);
  GLint id = 0;
  bool cached = GetHelper(binding, &id);
  DCHECK(cached);
  return static_cast<GLuint>(id);
}

void GLES2Implementation::RemoveMappedBufferRangeByTarget(GLenum target) {
  GLuint buffer = GetBoundBufferHelper(target);
  RemoveMappedBufferRangeById(buffer);
}

void GLES2Implementation::RemoveMappedBufferRangeById(GLuint buffer) {
  if (buffer > 0) {
    auto iter = mapped_buffer_range_map_.find(buffer);
    if (iter != mapped_buffer_range_map_.end() && iter->second.shm_memory) {
      mapped_memory_->FreePendingToken(
          iter->second.shm_memory, helper_->InsertToken());
      mapped_buffer_range_map_.erase(iter);
    }
  }
}

void GLES2Implementation::ClearMappedBufferRangeMap() {
  for (auto& buffer_range : mapped_buffer_range_map_) {
    if (buffer_range.second.shm_memory) {
      mapped_memory_->FreePendingToken(
          buffer_range.second.shm_memory, helper_->InsertToken());
    }
  }
  mapped_buffer_range_map_.clear();
}

void* GLES2Implementation::MapBufferRange(
    GLenum target, GLintptr offset, GLsizeiptr size, GLbitfield access) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glMapBufferRange("
      << GLES2Util::GetStringEnum(target) << ", " << offset << ", "
      << size << ", " << access << ")");
  if (!ValidateSize("glMapBufferRange", size) ||
      !ValidateOffset("glMapBufferRange", offset)) {
    return nullptr;
  }

  int32 shm_id;
  unsigned int shm_offset;
  void* mem = mapped_memory_->Alloc(size, &shm_id, &shm_offset);
  if (!mem) {
    SetGLError(GL_OUT_OF_MEMORY, "glMapBufferRange", "out of memory");
    return nullptr;
  }

  typedef cmds::MapBufferRange::Result Result;
  Result* result = GetResultAs<Result*>();
  *result = 0;
  helper_->MapBufferRange(target, offset, size, access, shm_id, shm_offset,
                          GetResultShmId(), GetResultShmOffset());
  // TODO(zmo): For write only mode with MAP_INVALID_*_BIT, we should
  // consider an early return without WaitForCmd(). crbug.com/465804.
  WaitForCmd();
  if (*result) {
    const GLbitfield kInvalidateBits =
        GL_MAP_INVALIDATE_BUFFER_BIT | GL_MAP_INVALIDATE_RANGE_BIT;
    if ((access & kInvalidateBits) != 0) {
      // We do not read back from the buffer, therefore, we set the client
      // side memory to zero to avoid uninitialized data.
      memset(mem, 0, size);
    }
    GLuint buffer = GetBoundBufferHelper(target);
    DCHECK_NE(0u, buffer);
    // glMapBufferRange fails on an already mapped buffer.
    DCHECK(mapped_buffer_range_map_.find(buffer) ==
           mapped_buffer_range_map_.end());
    auto iter = mapped_buffer_range_map_.insert(std::make_pair(
        buffer,
        MappedBuffer(access, shm_id, mem, shm_offset, target, offset, size)));
    DCHECK(iter.second);
  } else {
    mapped_memory_->Free(mem);
    mem = nullptr;
  }

  GPU_CLIENT_LOG("  returned " << mem);
  CheckGLError();
  return mem;
}

GLboolean GLES2Implementation::UnmapBuffer(GLenum target) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glUnmapBuffer("
      << GLES2Util::GetStringEnum(target) << ")");
  switch (target) {
    case GL_ARRAY_BUFFER:
    case GL_ELEMENT_ARRAY_BUFFER:
    case GL_COPY_READ_BUFFER:
    case GL_COPY_WRITE_BUFFER:
    case GL_PIXEL_PACK_BUFFER:
    case GL_PIXEL_UNPACK_BUFFER:
    case GL_TRANSFORM_FEEDBACK_BUFFER:
    case GL_UNIFORM_BUFFER:
      break;
    default:
      SetGLError(GL_INVALID_ENUM, "glUnmapBuffer", "invalid target");
      return GL_FALSE;
  }
  GLuint buffer = GetBoundBufferHelper(target);
  if (buffer == 0) {
    SetGLError(GL_INVALID_OPERATION, "glUnmapBuffer", "no buffer bound");
    return GL_FALSE;
  }
  auto iter = mapped_buffer_range_map_.find(buffer);
  if (iter == mapped_buffer_range_map_.end()) {
    SetGLError(GL_INVALID_OPERATION, "glUnmapBuffer", "buffer is unmapped");
    return GL_FALSE;
  }

  helper_->UnmapBuffer(target);
  RemoveMappedBufferRangeById(buffer);
  // TODO(zmo): There is a rare situation that data might be corrupted and
  // GL_FALSE should be returned. We lose context on that sitatuon, so we
  // don't have to WaitForCmd().
  GPU_CLIENT_LOG("  returned " << GL_TRUE);
  CheckGLError();
  return GL_TRUE;
}

void* GLES2Implementation::MapTexSubImage2DCHROMIUM(
     GLenum target,
     GLint level,
     GLint xoffset,
     GLint yoffset,
     GLsizei width,
     GLsizei height,
     GLenum format,
     GLenum type,
     GLenum access) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glMapTexSubImage2DCHROMIUM("
      << target << ", " << level << ", "
      << xoffset << ", " << yoffset << ", "
      << width << ", " << height << ", "
      << GLES2Util::GetStringTextureFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << GLES2Util::GetStringEnum(access) << ")");
  if (access != GL_WRITE_ONLY) {
    SetGLErrorInvalidEnum(
        "glMapTexSubImage2DCHROMIUM", access, "access");
    return NULL;
  }
  // NOTE: target is NOT checked because the service will check it
  // and we don't know what targets are valid.
  if (level < 0 || xoffset < 0 || yoffset < 0 || width < 0 || height < 0) {
    SetGLError(
        GL_INVALID_VALUE, "glMapTexSubImage2DCHROMIUM", "bad dimensions");
    return NULL;
  }
  uint32 size;
  if (!GLES2Util::ComputeImageDataSizes(
      width, height, 1, format, type, unpack_alignment_, &size, NULL, NULL)) {
    SetGLError(
        GL_INVALID_VALUE, "glMapTexSubImage2DCHROMIUM", "image size too large");
    return NULL;
  }
  int32 shm_id;
  unsigned int shm_offset;
  void* mem = mapped_memory_->Alloc(size, &shm_id, &shm_offset);
  if (!mem) {
    SetGLError(GL_OUT_OF_MEMORY, "glMapTexSubImage2DCHROMIUM", "out of memory");
    return NULL;
  }

  std::pair<MappedTextureMap::iterator, bool> result =
     mapped_textures_.insert(std::make_pair(
         mem,
         MappedTexture(
             access, shm_id, mem, shm_offset,
             target, level, xoffset, yoffset, width, height, format, type)));
  DCHECK(result.second);
  GPU_CLIENT_LOG("  returned " << mem);
  return mem;
}

void GLES2Implementation::UnmapTexSubImage2DCHROMIUM(const void* mem) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG(
      "[" << GetLogPrefix() << "] glUnmapTexSubImage2DCHROMIUM(" << mem << ")");
  MappedTextureMap::iterator it = mapped_textures_.find(mem);
  if (it == mapped_textures_.end()) {
    SetGLError(
        GL_INVALID_VALUE, "UnmapTexSubImage2DCHROMIUM", "texture not mapped");
    return;
  }
  const MappedTexture& mt = it->second;
  helper_->TexSubImage2D(
      mt.target, mt.level, mt.xoffset, mt.yoffset, mt.width, mt.height,
      mt.format, mt.type, mt.shm_id, mt.shm_offset, GL_FALSE);
  mapped_memory_->FreePendingToken(mt.shm_memory, helper_->InsertToken());
  mapped_textures_.erase(it);
  CheckGLError();
}

void GLES2Implementation::ResizeCHROMIUM(GLuint width, GLuint height,
                                         float scale_factor) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glResizeCHROMIUM("
                 << width << ", " << height << ", " << scale_factor << ")");
  helper_->ResizeCHROMIUM(width, height, scale_factor);
  CheckGLError();
}

const GLchar* GLES2Implementation::GetRequestableExtensionsCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix()
      << "] glGetRequestableExtensionsCHROMIUM()");
  TRACE_EVENT0("gpu",
               "GLES2Implementation::GetRequestableExtensionsCHROMIUM()");
  const char* result = NULL;
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->GetRequestableExtensionsCHROMIUM(kResultBucketId);
  std::string str;
  if (GetBucketAsString(kResultBucketId, &str)) {
    // The set of requestable extensions shrinks as we enable
    // them. Because we don't know when the client will stop referring
    // to a previous one it queries (see GetString) we need to cache
    // the unique results.
    std::set<std::string>::const_iterator sit =
        requestable_extensions_set_.find(str);
    if (sit != requestable_extensions_set_.end()) {
      result = sit->c_str();
    } else {
      std::pair<std::set<std::string>::const_iterator, bool> insert_result =
          requestable_extensions_set_.insert(str);
      DCHECK(insert_result.second);
      result = insert_result.first->c_str();
    }
  }
  GPU_CLIENT_LOG("  returned " << result);
  return reinterpret_cast<const GLchar*>(result);
}

// TODO(gman): Remove this command. It's here for WebGL but is incompatible
// with VirtualGL contexts.
void GLES2Implementation::RequestExtensionCHROMIUM(const char* extension) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glRequestExtensionCHROMIUM("
                 << extension << ")");
  SetBucketAsCString(kResultBucketId, extension);
  helper_->RequestExtensionCHROMIUM(kResultBucketId);
  helper_->SetBucketSize(kResultBucketId, 0);

  struct ExtensionCheck {
    const char* extension;
    ExtensionStatus* status;
  };
  const ExtensionCheck checks[] = {
    {
      "GL_ANGLE_pack_reverse_row_order",
      &angle_pack_reverse_row_order_status_,
    },
    {
      "GL_CHROMIUM_framebuffer_multisample",
       &chromium_framebuffer_multisample_,
    },
  };
  const size_t kNumChecks = sizeof(checks)/sizeof(checks[0]);
  for (size_t ii = 0; ii < kNumChecks; ++ii) {
    const ExtensionCheck& check = checks[ii];
    if (*check.status == kUnavailableExtensionStatus &&
        !strcmp(extension, check.extension)) {
      *check.status = kUnknownExtensionStatus;
    }
  }
}

void GLES2Implementation::RateLimitOffscreenContextCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glRateLimitOffscreenCHROMIUM()");
  // Wait if this would add too many rate limit tokens.
  if (rate_limit_tokens_.size() == kMaxSwapBuffers) {
    helper_->WaitForToken(rate_limit_tokens_.front());
    rate_limit_tokens_.pop();
  }
  rate_limit_tokens_.push(helper_->InsertToken());
}

void GLES2Implementation::GetProgramInfoCHROMIUMHelper(
    GLuint program, std::vector<int8>* result) {
  DCHECK(result);
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->GetProgramInfoCHROMIUM(program, kResultBucketId);
  GetBucketContents(kResultBucketId, result);
}

void GLES2Implementation::GetProgramInfoCHROMIUM(
    GLuint program, GLsizei bufsize, GLsizei* size, void* info) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  if (bufsize < 0) {
    SetGLError(
        GL_INVALID_VALUE, "glProgramInfoCHROMIUM", "bufsize less than 0.");
    return;
  }
  if (size == NULL) {
    SetGLError(GL_INVALID_VALUE, "glProgramInfoCHROMIUM", "size is null.");
    return;
  }
  // Make sure they've set size to 0 else the value will be undefined on
  // lost context.
  DCHECK_EQ(0, *size);
  std::vector<int8> result;
  GetProgramInfoCHROMIUMHelper(program, &result);
  if (result.empty()) {
    return;
  }
  *size = result.size();
  if (!info) {
    return;
  }
  if (static_cast<size_t>(bufsize) < result.size()) {
    SetGLError(GL_INVALID_OPERATION,
               "glProgramInfoCHROMIUM", "bufsize is too small for result.");
    return;
  }
  memcpy(info, &result[0], result.size());
}

void GLES2Implementation::GetUniformBlocksCHROMIUMHelper(
    GLuint program, std::vector<int8>* result) {
  DCHECK(result);
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->GetUniformBlocksCHROMIUM(program, kResultBucketId);
  GetBucketContents(kResultBucketId, result);
}

void GLES2Implementation::GetUniformBlocksCHROMIUM(
    GLuint program, GLsizei bufsize, GLsizei* size, void* info) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  if (bufsize < 0) {
    SetGLError(
        GL_INVALID_VALUE, "glGetUniformBlocksCHROMIUM", "bufsize less than 0.");
    return;
  }
  if (size == NULL) {
    SetGLError(GL_INVALID_VALUE, "glGetUniformBlocksCHROMIUM", "size is null.");
    return;
  }
  // Make sure they've set size to 0 else the value will be undefined on
  // lost context.
  DCHECK_EQ(0, *size);
  std::vector<int8> result;
  GetUniformBlocksCHROMIUMHelper(program, &result);
  if (result.empty()) {
    return;
  }
  *size = result.size();
  if (!info) {
    return;
  }
  if (static_cast<size_t>(bufsize) < result.size()) {
    SetGLError(GL_INVALID_OPERATION, "glGetUniformBlocksCHROMIUM",
               "bufsize is too small for result.");
    return;
  }
  memcpy(info, &result[0], result.size());
}

void GLES2Implementation::GetUniformsES3CHROMIUMHelper(
    GLuint program, std::vector<int8>* result) {
  DCHECK(result);
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->GetUniformsES3CHROMIUM(program, kResultBucketId);
  GetBucketContents(kResultBucketId, result);
}

void GLES2Implementation::GetUniformsES3CHROMIUM(
    GLuint program, GLsizei bufsize, GLsizei* size, void* info) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  if (bufsize < 0) {
    SetGLError(
        GL_INVALID_VALUE, "glGetUniformsES3CHROMIUM", "bufsize less than 0.");
    return;
  }
  if (size == NULL) {
    SetGLError(GL_INVALID_VALUE, "glGetUniformsES3CHROMIUM", "size is null.");
    return;
  }
  // Make sure they've set size to 0 else the value will be undefined on
  // lost context.
  DCHECK_EQ(0, *size);
  std::vector<int8> result;
  GetUniformsES3CHROMIUMHelper(program, &result);
  if (result.empty()) {
    return;
  }
  *size = result.size();
  if (!info) {
    return;
  }
  if (static_cast<size_t>(bufsize) < result.size()) {
    SetGLError(GL_INVALID_OPERATION,
               "glGetUniformsES3CHROMIUM", "bufsize is too small for result.");
    return;
  }
  memcpy(info, &result[0], result.size());
}

void GLES2Implementation::GetTransformFeedbackVaryingsCHROMIUMHelper(
    GLuint program, std::vector<int8>* result) {
  DCHECK(result);
  // Clear the bucket so if the command fails nothing will be in it.
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->GetTransformFeedbackVaryingsCHROMIUM(program, kResultBucketId);
  GetBucketContents(kResultBucketId, result);
}

void GLES2Implementation::GetTransformFeedbackVaryingsCHROMIUM(
    GLuint program, GLsizei bufsize, GLsizei* size, void* info) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  if (bufsize < 0) {
    SetGLError(GL_INVALID_VALUE, "glGetTransformFeedbackVaryingsCHROMIUM",
               "bufsize less than 0.");
    return;
  }
  if (size == NULL) {
    SetGLError(GL_INVALID_VALUE, "glGetTransformFeedbackVaryingsCHROMIUM",
               "size is null.");
    return;
  }
  // Make sure they've set size to 0 else the value will be undefined on
  // lost context.
  DCHECK_EQ(0, *size);
  std::vector<int8> result;
  GetTransformFeedbackVaryingsCHROMIUMHelper(program, &result);
  if (result.empty()) {
    return;
  }
  *size = result.size();
  if (!info) {
    return;
  }
  if (static_cast<size_t>(bufsize) < result.size()) {
    SetGLError(GL_INVALID_OPERATION, "glGetTransformFeedbackVaryingsCHROMIUM",
               "bufsize is too small for result.");
    return;
  }
  memcpy(info, &result[0], result.size());
}

GLuint GLES2Implementation::CreateStreamTextureCHROMIUM(GLuint texture) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] CreateStreamTextureCHROMIUM("
      << texture << ")");
  TRACE_EVENT0("gpu", "GLES2::CreateStreamTextureCHROMIUM");
  helper_->CommandBufferHelper::Flush();
  return gpu_control_->CreateStreamTexture(texture);
}

void GLES2Implementation::PostSubBufferCHROMIUM(
    GLint x, GLint y, GLint width, GLint height) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] PostSubBufferCHROMIUM("
      << x << ", " << y << ", " << width << ", " << height << ")");
  TRACE_EVENT2("gpu", "GLES2::PostSubBufferCHROMIUM",
               "width", width, "height", height);

  // Same flow control as GLES2Implementation::SwapBuffers (see comments there).
  swap_buffers_tokens_.push(helper_->InsertToken());
  helper_->PostSubBufferCHROMIUM(x, y, width, height);
  helper_->CommandBufferHelper::Flush();
  if (swap_buffers_tokens_.size() > kMaxSwapBuffers + 1) {
    helper_->WaitForToken(swap_buffers_tokens_.front());
    swap_buffers_tokens_.pop();
  }
}

void GLES2Implementation::DeleteQueriesEXTHelper(
    GLsizei n, const GLuint* queries) {
  for (GLsizei ii = 0; ii < n; ++ii) {
    query_tracker_->RemoveQuery(queries[ii]);
    query_id_allocator_->FreeID(queries[ii]);
  }

  helper_->DeleteQueriesEXTImmediate(n, queries);
}

GLboolean GLES2Implementation::IsQueryEXT(GLuint id) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] IsQueryEXT(" << id << ")");

  // TODO(gman): To be spec compliant IDs from other contexts sharing
  // resources need to return true here even though you can't share
  // queries across contexts?
  return query_tracker_->GetQuery(id) != NULL;
}

void GLES2Implementation::BeginQueryEXT(GLenum target, GLuint id) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] BeginQueryEXT("
                 << GLES2Util::GetStringQueryTarget(target)
                 << ", " << id << ")");

  // if any outstanding queries INV_OP
  QueryMap::iterator it = current_queries_.find(target);
  if (it != current_queries_.end()) {
    SetGLError(
        GL_INVALID_OPERATION, "glBeginQueryEXT", "query already in progress");
    return;
  }

  // id = 0 INV_OP
  if (id == 0) {
    SetGLError(GL_INVALID_OPERATION, "glBeginQueryEXT", "id is 0");
    return;
  }

  // if not GENned INV_OPERATION
  if (!query_id_allocator_->InUse(id)) {
    SetGLError(GL_INVALID_OPERATION, "glBeginQueryEXT", "invalid id");
    return;
  }

  // if id does not have an object
  QueryTracker::Query* query = query_tracker_->GetQuery(id);
  if (!query) {
    query = query_tracker_->CreateQuery(id, target);
    if (!query) {
      SetGLError(GL_OUT_OF_MEMORY,
                 "glBeginQueryEXT",
                 "transfer buffer allocation failed");
      return;
    }
  } else if (query->target() != target) {
    SetGLError(
        GL_INVALID_OPERATION, "glBeginQueryEXT", "target does not match");
    return;
  }

  current_queries_[target] = query;

  query->Begin(this);
  CheckGLError();
}

void GLES2Implementation::EndQueryEXT(GLenum target) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] EndQueryEXT("
                 << GLES2Util::GetStringQueryTarget(target) << ")");
  // Don't do anything if the context is lost.
  if (helper_->IsContextLost()) {
    return;
  }

  QueryMap::iterator it = current_queries_.find(target);
  if (it == current_queries_.end()) {
    SetGLError(GL_INVALID_OPERATION, "glEndQueryEXT", "no active query");
    return;
  }

  QueryTracker::Query* query = it->second;
  query->End(this);
  current_queries_.erase(it);
  CheckGLError();
}

void GLES2Implementation::GetQueryivEXT(
    GLenum target, GLenum pname, GLint* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] GetQueryivEXT("
                 << GLES2Util::GetStringQueryTarget(target) << ", "
                 << GLES2Util::GetStringQueryParameter(pname) << ", "
                 << static_cast<const void*>(params) << ")");

  if (pname != GL_CURRENT_QUERY_EXT) {
    SetGLErrorInvalidEnum("glGetQueryivEXT", pname, "pname");
    return;
  }
  QueryMap::iterator it = current_queries_.find(target);
  if (it != current_queries_.end()) {
    QueryTracker::Query* query = it->second;
    *params = query->id();
  } else {
    *params = 0;
  }
  GPU_CLIENT_LOG("  " << *params);
  CheckGLError();
}

void GLES2Implementation::GetQueryObjectuivEXT(
    GLuint id, GLenum pname, GLuint* params) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] GetQueryivEXT(" << id << ", "
                 << GLES2Util::GetStringQueryObjectParameter(pname) << ", "
                 << static_cast<const void*>(params) << ")");

  QueryTracker::Query* query = query_tracker_->GetQuery(id);
  if (!query) {
    SetGLError(GL_INVALID_OPERATION, "glQueryObjectuivEXT", "unknown query id");
    return;
  }

  QueryMap::iterator it = current_queries_.find(query->target());
  if (it != current_queries_.end()) {
    SetGLError(
        GL_INVALID_OPERATION,
        "glQueryObjectuivEXT", "query active. Did you to call glEndQueryEXT?");
    return;
  }

  if (query->NeverUsed()) {
    SetGLError(
        GL_INVALID_OPERATION,
        "glQueryObjectuivEXT", "Never used. Did you call glBeginQueryEXT?");
    return;
  }

  switch (pname) {
    case GL_QUERY_RESULT_EXT:
      if (!query->CheckResultsAvailable(helper_)) {
        helper_->WaitForToken(query->token());
        if (!query->CheckResultsAvailable(helper_)) {
          FinishHelper();
          CHECK(query->CheckResultsAvailable(helper_));
        }
      }
      *params = query->GetResult();
      break;
    case GL_QUERY_RESULT_AVAILABLE_EXT:
      *params = query->CheckResultsAvailable(helper_);
      break;
    default:
      SetGLErrorInvalidEnum("glQueryObjectuivEXT", pname, "pname");
      break;
  }
  GPU_CLIENT_LOG("  " << *params);
  CheckGLError();
}

void GLES2Implementation::DrawArraysInstancedANGLE(
    GLenum mode, GLint first, GLsizei count, GLsizei primcount) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glDrawArraysInstancedANGLE("
      << GLES2Util::GetStringDrawMode(mode) << ", "
      << first << ", " << count << ", " << primcount << ")");
  if (count < 0) {
    SetGLError(GL_INVALID_VALUE, "glDrawArraysInstancedANGLE", "count < 0");
    return;
  }
  if (primcount < 0) {
    SetGLError(GL_INVALID_VALUE, "glDrawArraysInstancedANGLE", "primcount < 0");
    return;
  }
  if (primcount == 0) {
    return;
  }
  bool simulated = false;
  if (!vertex_array_object_manager_->SetupSimulatedClientSideBuffers(
      "glDrawArraysInstancedANGLE", this, helper_, first + count, primcount,
      &simulated)) {
    return;
  }
  helper_->DrawArraysInstancedANGLE(mode, first, count, primcount);
  RestoreArrayBuffer(simulated);
  CheckGLError();
}

void GLES2Implementation::DrawElementsInstancedANGLE(
    GLenum mode, GLsizei count, GLenum type, const void* indices,
    GLsizei primcount) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glDrawElementsInstancedANGLE("
      << GLES2Util::GetStringDrawMode(mode) << ", "
      << count << ", "
      << GLES2Util::GetStringIndexType(type) << ", "
      << static_cast<const void*>(indices) << ", "
      << primcount << ")");
  if (count < 0) {
    SetGLError(GL_INVALID_VALUE,
               "glDrawElementsInstancedANGLE", "count less than 0.");
    return;
  }
  if (count == 0) {
    return;
  }
  if (primcount < 0) {
    SetGLError(GL_INVALID_VALUE,
               "glDrawElementsInstancedANGLE", "primcount < 0");
    return;
  }
  if (primcount == 0) {
    return;
  }
  if (vertex_array_object_manager_->bound_element_array_buffer() != 0 &&
      !ValidateOffset("glDrawElementsInstancedANGLE",
                      reinterpret_cast<GLintptr>(indices))) {
    return;
  }
  GLuint offset = 0;
  bool simulated = false;
  if (!vertex_array_object_manager_->SetupSimulatedIndexAndClientSideBuffers(
      "glDrawElementsInstancedANGLE", this, helper_, count, type, primcount,
      indices, &offset, &simulated)) {
    return;
  }
  helper_->DrawElementsInstancedANGLE(mode, count, type, offset, primcount);
  RestoreElementAndArrayBuffers(simulated);
  CheckGLError();
}

void GLES2Implementation::GenMailboxCHROMIUM(
    GLbyte* mailbox) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glGenMailboxCHROMIUM("
      << static_cast<const void*>(mailbox) << ")");
  TRACE_EVENT0("gpu", "GLES2::GenMailboxCHROMIUM");

  gpu::Mailbox result = gpu::Mailbox::Generate();
  memcpy(mailbox, result.name, sizeof(result.name));
}

void GLES2Implementation::ProduceTextureCHROMIUM(GLenum target,
                                                 const GLbyte* data) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glProduceTextureCHROMIUM("
                     << static_cast<const void*>(data) << ")");
  const Mailbox& mailbox = *reinterpret_cast<const Mailbox*>(data);
  DCHECK(mailbox.Verify()) << "ProduceTextureCHROMIUM was passed a "
                              "mailbox that was not generated by "
                              "GenMailboxCHROMIUM.";
  helper_->ProduceTextureCHROMIUMImmediate(target, data);
  CheckGLError();
}

void GLES2Implementation::ProduceTextureDirectCHROMIUM(
    GLuint texture, GLenum target, const GLbyte* data) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glProduceTextureDirectCHROMIUM("
                     << static_cast<const void*>(data) << ")");
  const Mailbox& mailbox = *reinterpret_cast<const Mailbox*>(data);
  DCHECK(mailbox.Verify()) << "ProduceTextureDirectCHROMIUM was passed a "
                              "mailbox that was not generated by "
                              "GenMailboxCHROMIUM.";
  helper_->ProduceTextureDirectCHROMIUMImmediate(texture, target, data);
  CheckGLError();
}

void GLES2Implementation::ConsumeTextureCHROMIUM(GLenum target,
                                                 const GLbyte* data) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glConsumeTextureCHROMIUM("
                     << static_cast<const void*>(data) << ")");
  const Mailbox& mailbox = *reinterpret_cast<const Mailbox*>(data);
  DCHECK(mailbox.Verify()) << "ConsumeTextureCHROMIUM was passed a "
                              "mailbox that was not generated by "
                              "GenMailboxCHROMIUM.";
  helper_->ConsumeTextureCHROMIUMImmediate(target, data);
  CheckGLError();
}

GLuint GLES2Implementation::CreateAndConsumeTextureCHROMIUM(
    GLenum target, const GLbyte* data) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glCreateAndConsumeTextureCHROMIUM("
                     << static_cast<const void*>(data) << ")");
  const Mailbox& mailbox = *reinterpret_cast<const Mailbox*>(data);
  DCHECK(mailbox.Verify()) << "CreateAndConsumeTextureCHROMIUM was passed a "
                              "mailbox that was not generated by "
                              "GenMailboxCHROMIUM.";
  GLuint client_id;
  GetIdHandler(id_namespaces::kTextures)->MakeIds(this, 0, 1, &client_id);
  helper_->CreateAndConsumeTextureCHROMIUMImmediate(target,
      client_id, data);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
  CheckGLError();
  return client_id;
}

void GLES2Implementation::PushGroupMarkerEXT(
    GLsizei length, const GLchar* marker) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glPushGroupMarkerEXT("
      << length << ", " << marker << ")");
  if (!marker) {
    marker = "";
  }
  SetBucketAsString(
      kResultBucketId,
      (length ? std::string(marker, length) : std::string(marker)));
  helper_->PushGroupMarkerEXT(kResultBucketId);
  helper_->SetBucketSize(kResultBucketId, 0);
  debug_marker_manager_.PushGroup(
      length ? std::string(marker, length) : std::string(marker));
}

void GLES2Implementation::InsertEventMarkerEXT(
    GLsizei length, const GLchar* marker) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glInsertEventMarkerEXT("
      << length << ", " << marker << ")");
  if (!marker) {
    marker = "";
  }
  SetBucketAsString(
      kResultBucketId,
      (length ? std::string(marker, length) : std::string(marker)));
  helper_->InsertEventMarkerEXT(kResultBucketId);
  helper_->SetBucketSize(kResultBucketId, 0);
  debug_marker_manager_.SetMarker(
      length ? std::string(marker, length) : std::string(marker));
}

void GLES2Implementation::PopGroupMarkerEXT() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glPopGroupMarkerEXT()");
  helper_->PopGroupMarkerEXT();
  debug_marker_manager_.PopGroup();
}

void GLES2Implementation::TraceBeginCHROMIUM(
    const char* category_name, const char* trace_name) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glTraceBeginCHROMIUM("
                 << category_name << ", " << trace_name << ")");
  SetBucketAsCString(kResultBucketId, category_name);
  SetBucketAsCString(kResultBucketId + 1, trace_name);
  helper_->TraceBeginCHROMIUM(kResultBucketId, kResultBucketId + 1);
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->SetBucketSize(kResultBucketId + 1, 0);
  current_trace_stack_++;
}

void GLES2Implementation::TraceEndCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glTraceEndCHROMIUM(" << ")");
  if (current_trace_stack_ == 0) {
    SetGLError(GL_INVALID_OPERATION, "glTraceEndCHROMIUM",
               "missing begin trace");
    return;
  }
  helper_->TraceEndCHROMIUM();
  current_trace_stack_--;
}

void* GLES2Implementation::MapBufferCHROMIUM(GLuint target, GLenum access) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glMapBufferCHROMIUM("
      << target << ", " << GLES2Util::GetStringEnum(access) << ")");
  switch (target)  {
    case GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM:
      if (access != GL_READ_ONLY) {
        SetGLError(GL_INVALID_ENUM, "glMapBufferCHROMIUM", "bad access mode");
        return NULL;
      }
      break;
    case GL_PIXEL_UNPACK_TRANSFER_BUFFER_CHROMIUM:
      if (access != GL_WRITE_ONLY) {
        SetGLError(GL_INVALID_ENUM, "glMapBufferCHROMIUM", "bad access mode");
        return NULL;
      }
      break;
    default:
      SetGLError(
          GL_INVALID_ENUM, "glMapBufferCHROMIUM", "invalid target");
      return NULL;
  }
  GLuint buffer_id;
  GetBoundPixelTransferBuffer(target, "glMapBufferCHROMIUM", &buffer_id);
  if (!buffer_id) {
    return NULL;
  }
  BufferTracker::Buffer* buffer = buffer_tracker_->GetBuffer(buffer_id);
  if (!buffer) {
    SetGLError(GL_INVALID_OPERATION, "glMapBufferCHROMIUM", "invalid buffer");
    return NULL;
  }
  if (buffer->mapped()) {
    SetGLError(GL_INVALID_OPERATION, "glMapBufferCHROMIUM", "already mapped");
    return NULL;
  }
  // Here we wait for previous transfer operations to be finished.
  // TODO(hubbe): AsyncTex(Sub)Image2dCHROMIUM does not currently work
  // with this method of synchronization. Until this is fixed,
  // MapBufferCHROMIUM will not block even if the transfer is not ready
  // for these calls.
  if (buffer->last_usage_token()) {
    helper_->WaitForToken(buffer->last_usage_token());
    buffer->set_last_usage_token(0);
  }
  buffer->set_mapped(true);

  GPU_CLIENT_LOG("  returned " << buffer->address());
  CheckGLError();
  return buffer->address();
}

GLboolean GLES2Implementation::UnmapBufferCHROMIUM(GLuint target) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG(
      "[" << GetLogPrefix() << "] glUnmapBufferCHROMIUM(" << target << ")");
  GLuint buffer_id;
  if (!GetBoundPixelTransferBuffer(target, "glMapBufferCHROMIUM", &buffer_id)) {
    SetGLError(GL_INVALID_ENUM, "glUnmapBufferCHROMIUM", "invalid target");
  }
  if (!buffer_id) {
    return false;
  }
  BufferTracker::Buffer* buffer = buffer_tracker_->GetBuffer(buffer_id);
  if (!buffer) {
    SetGLError(GL_INVALID_OPERATION, "glUnmapBufferCHROMIUM", "invalid buffer");
    return false;
  }
  if (!buffer->mapped()) {
    SetGLError(GL_INVALID_OPERATION, "glUnmapBufferCHROMIUM", "not mapped");
    return false;
  }
  buffer->set_mapped(false);
  CheckGLError();
  return true;
}

bool GLES2Implementation::EnsureAsyncUploadSync() {
  if (async_upload_sync_)
    return true;

  int32 shm_id;
  unsigned int shm_offset;
  void* mem = mapped_memory_->Alloc(sizeof(AsyncUploadSync),
                                    &shm_id,
                                    &shm_offset);
  if (!mem)
    return false;

  async_upload_sync_shm_id_ = shm_id;
  async_upload_sync_shm_offset_ = shm_offset;
  async_upload_sync_ = static_cast<AsyncUploadSync*>(mem);
  async_upload_sync_->Reset();

  return true;
}

uint32 GLES2Implementation::NextAsyncUploadToken() {
  async_upload_token_++;
  if (async_upload_token_ == 0)
    async_upload_token_++;
  return async_upload_token_;
}

void GLES2Implementation::PollAsyncUploads() {
  if (!async_upload_sync_)
    return;

  if (helper_->IsContextLost()) {
    DetachedAsyncUploadMemoryList::iterator it =
        detached_async_upload_memory_.begin();
    while (it != detached_async_upload_memory_.end()) {
      mapped_memory_->Free(it->first);
      it = detached_async_upload_memory_.erase(it);
    }
    return;
  }

  DetachedAsyncUploadMemoryList::iterator it =
      detached_async_upload_memory_.begin();
  while (it != detached_async_upload_memory_.end()) {
    if (HasAsyncUploadTokenPassed(it->second)) {
      mapped_memory_->Free(it->first);
      it = detached_async_upload_memory_.erase(it);
    } else {
      break;
    }
  }
}

void GLES2Implementation::FreeAllAsyncUploadBuffers() {
  // Free all completed unmanaged async uploads buffers.
  PollAsyncUploads();

  // Synchronously free rest of the unmanaged async upload buffers.
  if (!detached_async_upload_memory_.empty()) {
    WaitAllAsyncTexImage2DCHROMIUM();
    WaitForCmd();
    PollAsyncUploads();
  }
}

void GLES2Implementation::AsyncTexImage2DCHROMIUM(
    GLenum target, GLint level, GLenum internalformat, GLsizei width,
    GLsizei height, GLint border, GLenum format, GLenum type,
    const void* pixels) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glTexImage2D("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << GLES2Util::GetStringTextureInternalFormat(internalformat) << ", "
      << width << ", " << height << ", " << border << ", "
      << GLES2Util::GetStringTextureFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << static_cast<const void*>(pixels) << ")");
  if (level < 0 || height < 0 || width < 0) {
    SetGLError(GL_INVALID_VALUE, "glTexImage2D", "dimension < 0");
    return;
  }
  if (border != 0) {
    SetGLError(GL_INVALID_VALUE, "glTexImage2D", "border != 0");
    return;
  }
  uint32 size;
  uint32 unpadded_row_size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
          width, height, 1, format, type, unpack_alignment_, &size,
          &unpadded_row_size, &padded_row_size)) {
    SetGLError(GL_INVALID_VALUE, "glTexImage2D", "image size too large");
    return;
  }

  // If there's no data/buffer just issue the AsyncTexImage2D
  if (!pixels && !bound_pixel_unpack_transfer_buffer_id_) {
    helper_->AsyncTexImage2DCHROMIUM(
       target, level, internalformat, width, height, format, type,
       0, 0, 0, 0, 0);
    return;
  }

  if (!EnsureAsyncUploadSync()) {
    SetGLError(GL_OUT_OF_MEMORY, "glTexImage2D", "out of memory");
    return;
  }

  // Otherwise, async uploads require a transfer buffer to be bound.
  // TODO(hubbe): Make MapBufferCHROMIUM block if someone tries to re-use
  // the buffer before the transfer is finished. (Currently such
  // synchronization has to be handled manually.)
  GLuint offset = ToGLuint(pixels);
  BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
      bound_pixel_unpack_transfer_buffer_id_,
      "glAsyncTexImage2DCHROMIUM", offset, size);
  if (buffer && buffer->shm_id() != -1) {
    uint32 async_token = NextAsyncUploadToken();
    buffer->set_last_async_upload_token(async_token);
    helper_->AsyncTexImage2DCHROMIUM(
        target, level, internalformat, width, height, format, type,
        buffer->shm_id(), buffer->shm_offset() + offset,
        async_token,
        async_upload_sync_shm_id_, async_upload_sync_shm_offset_);
  }
}

void GLES2Implementation::AsyncTexSubImage2DCHROMIUM(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
    GLsizei height, GLenum format, GLenum type, const void* pixels) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glAsyncTexSubImage2DCHROMIUM("
      << GLES2Util::GetStringTextureTarget(target) << ", "
      << level << ", "
      << xoffset << ", " << yoffset << ", "
      << width << ", " << height << ", "
      << GLES2Util::GetStringTextureFormat(format) << ", "
      << GLES2Util::GetStringPixelType(type) << ", "
      << static_cast<const void*>(pixels) << ")");
  if (level < 0 || height < 0 || width < 0) {
    SetGLError(
        GL_INVALID_VALUE, "glAsyncTexSubImage2DCHROMIUM", "dimension < 0");
    return;
  }

  uint32 size;
  uint32 unpadded_row_size;
  uint32 padded_row_size;
  if (!GLES2Util::ComputeImageDataSizes(
        width, height, 1, format, type, unpack_alignment_, &size,
        &unpadded_row_size, &padded_row_size)) {
    SetGLError(
        GL_INVALID_VALUE, "glAsyncTexSubImage2DCHROMIUM", "size to large");
    return;
  }

  if (!EnsureAsyncUploadSync()) {
    SetGLError(GL_OUT_OF_MEMORY, "glTexImage2D", "out of memory");
    return;
  }

  // Async uploads require a transfer buffer to be bound.
  // TODO(hubbe): Make MapBufferCHROMIUM block if someone tries to re-use
  // the buffer before the transfer is finished. (Currently such
  // synchronization has to be handled manually.)
  GLuint offset = ToGLuint(pixels);
  BufferTracker::Buffer* buffer = GetBoundPixelUnpackTransferBufferIfValid(
      bound_pixel_unpack_transfer_buffer_id_,
      "glAsyncTexSubImage2DCHROMIUM", offset, size);
  if (buffer && buffer->shm_id() != -1) {
    uint32 async_token = NextAsyncUploadToken();
    buffer->set_last_async_upload_token(async_token);
    helper_->AsyncTexSubImage2DCHROMIUM(
        target, level, xoffset, yoffset, width, height, format, type,
        buffer->shm_id(), buffer->shm_offset() + offset,
        async_token,
        async_upload_sync_shm_id_, async_upload_sync_shm_offset_);
  }
}

void GLES2Implementation::WaitAsyncTexImage2DCHROMIUM(GLenum target) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glWaitAsyncTexImage2DCHROMIUM("
      << GLES2Util::GetStringTextureTarget(target) << ")");
  helper_->WaitAsyncTexImage2DCHROMIUM(target);
  CheckGLError();
}

void GLES2Implementation::WaitAllAsyncTexImage2DCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix()
      << "] glWaitAllAsyncTexImage2DCHROMIUM()");
  helper_->WaitAllAsyncTexImage2DCHROMIUM();
  CheckGLError();
}

GLuint GLES2Implementation::InsertSyncPointCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glInsertSyncPointCHROMIUM");
  helper_->CommandBufferHelper::Flush();
  return gpu_control_->InsertSyncPoint();
}

GLuint GLES2Implementation::InsertFutureSyncPointCHROMIUM() {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glInsertFutureSyncPointCHROMIUM");
  DCHECK(capabilities_.future_sync_points);
  return gpu_control_->InsertFutureSyncPoint();
}

void GLES2Implementation::RetireSyncPointCHROMIUM(GLuint sync_point) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glRetireSyncPointCHROMIUM("
                     << sync_point << ")");
  DCHECK(capabilities_.future_sync_points);
  helper_->CommandBufferHelper::Flush();
  gpu_control_->RetireSyncPoint(sync_point);
}

namespace {

bool ValidImageFormat(GLenum internalformat) {
  switch (internalformat) {
    case GL_RGB:
    case GL_RGBA:
      return true;
    default:
      return false;
  }
}

bool ValidImageUsage(GLenum usage) {
  switch (usage) {
    case GL_MAP_CHROMIUM:
    case GL_SCANOUT_CHROMIUM:
      return true;
    default:
      return false;
  }
}

}  // namespace

GLuint GLES2Implementation::CreateImageCHROMIUMHelper(ClientBuffer buffer,
                                                      GLsizei width,
                                                      GLsizei height,
                                                      GLenum internalformat) {
  if (width <= 0) {
    SetGLError(GL_INVALID_VALUE, "glCreateImageCHROMIUM", "width <= 0");
    return 0;
  }

  if (height <= 0) {
    SetGLError(GL_INVALID_VALUE, "glCreateImageCHROMIUM", "height <= 0");
    return 0;
  }

  if (!ValidImageFormat(internalformat)) {
    SetGLError(GL_INVALID_VALUE, "glCreateImageCHROMIUM", "invalid format");
    return 0;
  }

  int32_t image_id =
      gpu_control_->CreateImage(buffer, width, height, internalformat);
  if (image_id < 0) {
    SetGLError(GL_OUT_OF_MEMORY, "glCreateImageCHROMIUM", "image_id < 0");
    return 0;
  }
  return image_id;
}

GLuint GLES2Implementation::CreateImageCHROMIUM(ClientBuffer buffer,
                                                GLsizei width,
                                                GLsizei height,
                                                GLenum internalformat) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glCreateImageCHROMIUM(" << width
                     << ", " << height << ", "
                     << GLES2Util::GetStringImageInternalFormat(internalformat)
                     << ")");
  GLuint image_id =
      CreateImageCHROMIUMHelper(buffer, width, height, internalformat);
  CheckGLError();
  return image_id;
}

void GLES2Implementation::DestroyImageCHROMIUMHelper(GLuint image_id) {
  // Flush the command stream to make sure all pending commands
  // that may refer to the image_id are executed on the service side.
  helper_->CommandBufferHelper::Flush();
  gpu_control_->DestroyImage(image_id);
}

void GLES2Implementation::DestroyImageCHROMIUM(GLuint image_id) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glDestroyImageCHROMIUM("
      << image_id << ")");
  DestroyImageCHROMIUMHelper(image_id);
  CheckGLError();
}

GLuint GLES2Implementation::CreateGpuMemoryBufferImageCHROMIUMHelper(
    GLsizei width,
    GLsizei height,
    GLenum internalformat,
    GLenum usage) {
  if (width <= 0) {
    SetGLError(
        GL_INVALID_VALUE, "glCreateGpuMemoryBufferImageCHROMIUM", "width <= 0");
    return 0;
  }

  if (height <= 0) {
    SetGLError(GL_INVALID_VALUE,
               "glCreateGpuMemoryBufferImageCHROMIUM",
               "height <= 0");
    return 0;
  }

  if (!ValidImageFormat(internalformat)) {
    SetGLError(GL_INVALID_VALUE,
               "glCreateGpuMemoryBufferImageCHROMIUM",
               "invalid format");
    return 0;
  }

  if (!ValidImageUsage(usage)) {
    SetGLError(GL_INVALID_VALUE,
               "glCreateGpuMemoryBufferImageCHROMIUM",
               "invalid usage");
    return 0;
  }

  // Flush the command stream to ensure ordering in case the newly
  // returned image_id has recently been in use with a different buffer.
  helper_->CommandBufferHelper::Flush();
  int32_t image_id = gpu_control_->CreateGpuMemoryBufferImage(
      width, height, internalformat, usage);
  if (image_id < 0) {
    SetGLError(GL_OUT_OF_MEMORY,
               "glCreateGpuMemoryBufferImageCHROMIUM",
               "image_id < 0");
    return 0;
  }
  return image_id;
}

GLuint GLES2Implementation::CreateGpuMemoryBufferImageCHROMIUM(
    GLsizei width,
    GLsizei height,
    GLenum internalformat,
    GLenum usage) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix()
                     << "] glCreateGpuMemoryBufferImageCHROMIUM(" << width
                     << ", " << height << ", "
                     << GLES2Util::GetStringImageInternalFormat(internalformat)
                     << ", " << GLES2Util::GetStringImageUsage(usage) << ")");
  GLuint image_id = CreateGpuMemoryBufferImageCHROMIUMHelper(
      width, height, internalformat, usage);
  CheckGLError();
  return image_id;
}

bool GLES2Implementation::ValidateSize(const char* func, GLsizeiptr size) {
  if (size < 0) {
    SetGLError(GL_INVALID_VALUE, func, "size < 0");
    return false;
  }
  if (!base::IsValueInRangeForNumericType<int32_t>(size)) {
    SetGLError(GL_INVALID_OPERATION, func, "size more than 32-bit");
    return false;
  }
  return true;
}

bool GLES2Implementation::ValidateOffset(const char* func, GLintptr offset) {
  if (offset < 0) {
    SetGLError(GL_INVALID_VALUE, func, "offset < 0");
    return false;
  }
  if (!base::IsValueInRangeForNumericType<int32_t>(offset)) {
    SetGLError(GL_INVALID_OPERATION, func, "offset more than 32-bit");
    return false;
  }
  return true;
}

bool GLES2Implementation::GetSamplerParameterfvHelper(
    GLuint /* sampler */, GLenum /* pname */, GLfloat* /* params */) {
  // TODO(zmo): Implement client side caching.
  return false;
}

bool GLES2Implementation::GetSamplerParameterivHelper(
    GLuint /* sampler */, GLenum /* pname */, GLint* /* params */) {
  // TODO(zmo): Implement client side caching.
  return false;
}

bool GLES2Implementation::PackStringsToBucket(GLsizei count,
                                              const char* const* str,
                                              const GLint* length,
                                              const char* func_name) {
  DCHECK_LE(0, count);
  // Compute the total size.
  base::CheckedNumeric<size_t> total_size = count;
  total_size += 1;
  total_size *= sizeof(GLint);
  if (!total_size.IsValid()) {
    SetGLError(GL_INVALID_VALUE, func_name, "overflow");
    return false;
  }
  size_t header_size = total_size.ValueOrDefault(0);
  std::vector<GLint> header(count + 1);
  header[0] = static_cast<GLint>(count);
  for (GLsizei ii = 0; ii < count; ++ii) {
    GLint len = 0;
    if (str[ii]) {
      len = (length && length[ii] >= 0)
                ? length[ii]
                : base::checked_cast<GLint>(strlen(str[ii]));
    }
    total_size += len;
    total_size += 1;  // NULL at the end of each char array.
    if (!total_size.IsValid()) {
      SetGLError(GL_INVALID_VALUE, func_name, "overflow");
      return false;
    }
    header[ii + 1] = len;
  }
  // Pack data into a bucket on the service.
  helper_->SetBucketSize(kResultBucketId, total_size.ValueOrDefault(0));
  size_t offset = 0;
  for (GLsizei ii = 0; ii <= count; ++ii) {
    const char* src =
        (ii == 0) ? reinterpret_cast<const char*>(&header[0]) : str[ii - 1];
    base::CheckedNumeric<size_t> checked_size =
        (ii == 0) ? header_size : static_cast<size_t>(header[ii]);
    if (ii > 0) {
      checked_size += 1;  // NULL in the end.
    }
    if (!checked_size.IsValid()) {
      SetGLError(GL_INVALID_VALUE, func_name, "overflow");
      return false;
    }
    size_t size = checked_size.ValueOrDefault(0);
    while (size) {
      ScopedTransferBufferPtr buffer(size, helper_, transfer_buffer_);
      if (!buffer.valid() || buffer.size() == 0) {
        SetGLError(GL_OUT_OF_MEMORY, func_name, "too large");
        return false;
      }
      size_t copy_size = buffer.size();
      if (ii > 0 && buffer.size() == size)
        --copy_size;
      if (copy_size)
        memcpy(buffer.address(), src, copy_size);
      if (copy_size < buffer.size()) {
        // Append NULL in the end.
        DCHECK(copy_size + 1 == buffer.size());
        char* str = reinterpret_cast<char*>(buffer.address());
        str[copy_size] = 0;
      }
      helper_->SetBucketData(kResultBucketId, offset, buffer.size(),
                             buffer.shm_id(), buffer.offset());
      offset += buffer.size();
      src += buffer.size();
      size -= buffer.size();
    }
  }
  DCHECK_EQ(total_size.ValueOrDefault(0), offset);
  return true;
}

void GLES2Implementation::UniformBlockBinding(GLuint program,
                                              GLuint index,
                                              GLuint binding) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glUniformBlockBinding(" << program
                     << ", " << index << ", " << binding << ")");
  share_group_->program_info_manager()->UniformBlockBinding(
      this, program, index, binding);
  helper_->UniformBlockBinding(program, index, binding);
  CheckGLError();
}

GLenum GLES2Implementation::ClientWaitSync(
    GLsync sync, GLbitfield flags, GLuint64 timeout) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glClientWaitSync(" << sync
                 << ", " << flags << ", " << timeout << ")");
  typedef cmds::ClientWaitSync::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    SetGLError(GL_OUT_OF_MEMORY, "ClientWaitSync", "");
    return GL_WAIT_FAILED;
  }
  *result = GL_WAIT_FAILED;
  uint32_t v32_0 = 0, v32_1 = 0;
  GLES2Util::MapUint64ToTwoUint32(timeout, &v32_0, &v32_1);
  helper_->ClientWaitSync(
      ToGLuint(sync), flags, v32_0, v32_1,
      GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  GPU_CLIENT_LOG("returned " << *result);
  CheckGLError();
  return *result;
}

void GLES2Implementation::WaitSync(
    GLsync sync, GLbitfield flags, GLuint64 timeout) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] glWaitSync(" << sync << ", "
                 << flags << ", " << timeout << ")");
  uint32_t v32_0 = 0, v32_1 = 0;
  GLES2Util::MapUint64ToTwoUint32(timeout, &v32_0, &v32_1);
  helper_->WaitSync(ToGLuint(sync), flags, v32_0, v32_1);
  CheckGLError();
}

// Include the auto-generated part of this file. We split this because it means
// we can easily edit the non-auto generated parts right here in this file
// instead of having to edit some template or the code generator.
#include "gpu/command_buffer/client/gles2_implementation_impl_autogen.h"

}  // namespace gles2
}  // namespace gpu
