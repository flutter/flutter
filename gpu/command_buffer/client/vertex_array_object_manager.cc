// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/vertex_array_object_manager.h"

#include "base/logging.h"
#include "gpu/command_buffer/client/gles2_cmd_helper.h"
#include "gpu/command_buffer/client/gles2_implementation.h"

namespace gpu {
namespace gles2 {

static GLsizei RoundUpToMultipleOf4(GLsizei size) {
  return (size + 3) & ~3;
}

// A 32-bit and 64-bit compatible way of converting a pointer to a GLuint.
static GLuint ToGLuint(const void* ptr) {
  return static_cast<GLuint>(reinterpret_cast<size_t>(ptr));
}

// This class tracks VertexAttribPointers and helps emulate client side buffers.
//
// The way client side buffers work is we shadow all the Vertex Attribs so we
// know which ones are pointing to client side buffers.
//
// At Draw time, for any attribs pointing to client side buffers we copy them
// to a special VBO and reset the actual vertex attrib pointers to point to this
// VBO.
//
// This also means we have to catch calls to query those values so that when
// an attrib is a client side buffer we pass the info back the user expects.

class GLES2_IMPL_EXPORT VertexArrayObject {
 public:
  // Info about Vertex Attributes. This is used to track what the user currently
  // has bound on each Vertex Attribute so we can simulate client side buffers
  // at glDrawXXX time.
  class VertexAttrib {
   public:
    VertexAttrib()
        : enabled_(false),
          buffer_id_(0),
          size_(4),
          type_(GL_FLOAT),
          normalized_(GL_FALSE),
          pointer_(NULL),
          gl_stride_(0),
          divisor_(0) {
    }

    bool enabled() const {
      return enabled_;
    }

    void set_enabled(bool enabled) {
      enabled_ = enabled;
    }

    GLuint buffer_id() const {
      return buffer_id_;
    }

    void set_buffer_id(GLuint id) {
      buffer_id_ = id;
    }

    GLenum type() const {
      return type_;
    }

    GLint size() const {
      return size_;
    }

    GLsizei stride() const {
      return gl_stride_;
    }

    GLboolean normalized() const {
      return normalized_;
    }

    const GLvoid* pointer() const {
      return pointer_;
    }

    bool IsClientSide() const {
      return buffer_id_ == 0;
    }

    GLuint divisor() const {
      return divisor_;
    }

    void SetInfo(
        GLuint buffer_id,
        GLint size,
        GLenum type,
        GLboolean normalized,
        GLsizei gl_stride,
        const GLvoid* pointer) {
      buffer_id_ = buffer_id;
      size_ = size;
      type_ = type;
      normalized_ = normalized;
      gl_stride_ = gl_stride;
      pointer_ = pointer;
    }

    void SetDivisor(GLuint divisor) {
      divisor_ = divisor;
    }

   private:
    // Whether or not this attribute is enabled.
    bool enabled_;

    // The id of the buffer. 0 = client side buffer.
    GLuint buffer_id_;

    // Number of components (1, 2, 3, 4).
    GLint size_;

    // GL_BYTE, GL_FLOAT, etc. See glVertexAttribPointer.
    GLenum type_;

    // GL_TRUE or GL_FALSE
    GLboolean normalized_;

    // The pointer/offset into the buffer.
    const GLvoid* pointer_;

    // The stride that will be used to access the buffer. This is the bogus GL
    // stride where 0 = compute the stride based on size and type.
    GLsizei gl_stride_;

    // Divisor, for geometry instancing.
    GLuint divisor_;
  };

  typedef std::vector<VertexAttrib> VertexAttribs;

  explicit VertexArrayObject(GLuint max_vertex_attribs);

  void UnbindBuffer(GLuint id);

  bool BindElementArray(GLuint id);

  bool HaveEnabledClientSideBuffers() const;

  void SetAttribEnable(GLuint index, bool enabled);

  void SetAttribPointer(
    GLuint buffer_id,
    GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride,
    const void* ptr);

  bool GetVertexAttrib(
      GLuint index, GLenum pname, uint32* param) const;

  void SetAttribDivisor(GLuint index, GLuint divisor);

  bool GetAttribPointer(GLuint index, GLenum pname, void** ptr) const;

  const VertexAttribs& vertex_attribs() const {
    return vertex_attribs_;
  }

  GLuint bound_element_array_buffer() const {
    return bound_element_array_buffer_id_;
  }

 private:
  const VertexAttrib* GetAttrib(GLuint index) const;

  int num_client_side_pointers_enabled_;

  // The currently bound element array buffer.
  GLuint bound_element_array_buffer_id_;

  VertexAttribs vertex_attribs_;

  DISALLOW_COPY_AND_ASSIGN(VertexArrayObject);
};

VertexArrayObject::VertexArrayObject(GLuint max_vertex_attribs)
    : num_client_side_pointers_enabled_(0),
      bound_element_array_buffer_id_(0) {
  vertex_attribs_.resize(max_vertex_attribs);
}

void VertexArrayObject::UnbindBuffer(GLuint id) {
  if (id == 0) {
    return;
  }
  for (size_t ii = 0; ii < vertex_attribs_.size(); ++ii) {
    VertexAttrib& attrib = vertex_attribs_[ii];
    if (attrib.buffer_id() == id) {
      attrib.set_buffer_id(0);
      if (attrib.enabled()) {
        ++num_client_side_pointers_enabled_;
      }
    }
  }
  if (bound_element_array_buffer_id_ == id) {
    bound_element_array_buffer_id_ = 0;
  }
}

bool VertexArrayObject::BindElementArray(GLuint id) {
  if (id == bound_element_array_buffer_id_) {
    return false;
  }
  bound_element_array_buffer_id_ = id;
  return true;
}
bool VertexArrayObject::HaveEnabledClientSideBuffers() const {
  return num_client_side_pointers_enabled_ > 0;
}

void VertexArrayObject::SetAttribEnable(GLuint index, bool enabled) {
  if (index < vertex_attribs_.size()) {
    VertexAttrib& attrib = vertex_attribs_[index];
    if (attrib.enabled() != enabled) {
      if (attrib.IsClientSide()) {
        num_client_side_pointers_enabled_ += enabled ? 1 : -1;
        DCHECK_GE(num_client_side_pointers_enabled_, 0);
      }
      attrib.set_enabled(enabled);
    }
  }
}

void VertexArrayObject::SetAttribPointer(
    GLuint buffer_id,
    GLuint index,
    GLint size,
    GLenum type,
    GLboolean normalized,
    GLsizei stride,
    const void* ptr) {
  if (index < vertex_attribs_.size()) {
    VertexAttrib& attrib = vertex_attribs_[index];
    if (attrib.IsClientSide() && attrib.enabled()) {
      --num_client_side_pointers_enabled_;
      DCHECK_GE(num_client_side_pointers_enabled_, 0);
    }

    attrib.SetInfo(buffer_id, size, type, normalized, stride, ptr);

    if (attrib.IsClientSide() && attrib.enabled()) {
      ++num_client_side_pointers_enabled_;
    }
  }
}

bool VertexArrayObject::GetVertexAttrib(
    GLuint index, GLenum pname, uint32* param) const {
  const VertexAttrib* attrib = GetAttrib(index);
  if (!attrib) {
    return false;
  }

  switch (pname) {
    case GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING:
      *param = attrib->buffer_id();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_ENABLED:
      *param = attrib->enabled();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_SIZE:
      *param = attrib->size();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_STRIDE:
      *param = attrib->stride();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_TYPE:
      *param = attrib->type();
      break;
    case GL_VERTEX_ATTRIB_ARRAY_NORMALIZED:
      *param = attrib->normalized();
      break;
    default:
      return false;  // pass through to service side.
      break;
  }
  return true;
}

void VertexArrayObject::SetAttribDivisor(GLuint index, GLuint divisor) {
  if (index < vertex_attribs_.size()) {
    VertexAttrib& attrib = vertex_attribs_[index];
    attrib.SetDivisor(divisor);
  }
}

// Gets the Attrib pointer for an attrib but only if it's a client side
// pointer. Returns true if it got the pointer.
bool VertexArrayObject::GetAttribPointer(
    GLuint index, GLenum pname, void** ptr) const {
  const VertexAttrib* attrib = GetAttrib(index);
  if (attrib && pname == GL_VERTEX_ATTRIB_ARRAY_POINTER) {
    *ptr = const_cast<void*>(attrib->pointer());
    return true;
  }
  return false;
}

// Gets an attrib if it's in range and it's client side.
const VertexArrayObject::VertexAttrib* VertexArrayObject::GetAttrib(
    GLuint index) const {
  if (index < vertex_attribs_.size()) {
    const VertexAttrib* attrib = &vertex_attribs_[index];
    return attrib;
  }
  return NULL;
}

VertexArrayObjectManager::VertexArrayObjectManager(
    GLuint max_vertex_attribs,
    GLuint array_buffer_id,
    GLuint element_array_buffer_id,
    bool support_client_side_arrays)
    : max_vertex_attribs_(max_vertex_attribs),
      array_buffer_id_(array_buffer_id),
      array_buffer_size_(0),
      array_buffer_offset_(0),
      element_array_buffer_id_(element_array_buffer_id),
      element_array_buffer_size_(0),
      collection_buffer_size_(0),
      default_vertex_array_object_(new VertexArrayObject(max_vertex_attribs)),
      bound_vertex_array_object_(default_vertex_array_object_),
      support_client_side_arrays_(support_client_side_arrays) {
}

VertexArrayObjectManager::~VertexArrayObjectManager() {
  for (VertexArrayObjectMap::iterator it = vertex_array_objects_.begin();
       it != vertex_array_objects_.end(); ++it) {
    delete it->second;
  }
  delete default_vertex_array_object_;
}

bool VertexArrayObjectManager::IsReservedId(GLuint id) const {
  return (id != 0 &&
          (id == array_buffer_id_ || id == element_array_buffer_id_));
}

GLuint VertexArrayObjectManager::bound_element_array_buffer() const {
  return bound_vertex_array_object_->bound_element_array_buffer();
}

void VertexArrayObjectManager::UnbindBuffer(GLuint id) {
  bound_vertex_array_object_->UnbindBuffer(id);
}

bool VertexArrayObjectManager::BindElementArray(GLuint id) {
  return  bound_vertex_array_object_->BindElementArray(id);
}

void VertexArrayObjectManager::GenVertexArrays(
    GLsizei n, const GLuint* arrays) {
  DCHECK_GE(n, 0);
  for (GLsizei i = 0; i < n; ++i) {
    std::pair<VertexArrayObjectMap::iterator, bool> result =
        vertex_array_objects_.insert(std::make_pair(
            arrays[i], new VertexArrayObject(max_vertex_attribs_)));
    DCHECK(result.second);
  }
}

void VertexArrayObjectManager::DeleteVertexArrays(
    GLsizei n, const GLuint* arrays) {
  DCHECK_GE(n, 0);
  for (GLsizei i = 0; i < n; ++i) {
    GLuint id = arrays[i];
    if (id) {
      VertexArrayObjectMap::iterator it = vertex_array_objects_.find(id);
      if (it != vertex_array_objects_.end()) {
        if (bound_vertex_array_object_ == it->second) {
          bound_vertex_array_object_ = default_vertex_array_object_;
        }
        delete it->second;
        vertex_array_objects_.erase(it);
      }
    }
  }
}

bool VertexArrayObjectManager::BindVertexArray(GLuint array, bool* changed) {
  *changed = false;
  VertexArrayObject* vertex_array_object = default_vertex_array_object_;
  if (array != 0) {
    VertexArrayObjectMap::iterator it = vertex_array_objects_.find(array);
    if (it == vertex_array_objects_.end()) {
      return false;
    }
    vertex_array_object = it->second;
  }
  *changed = vertex_array_object != bound_vertex_array_object_;
  bound_vertex_array_object_ = vertex_array_object;
  return true;
}

bool VertexArrayObjectManager::HaveEnabledClientSideBuffers() const {
  return bound_vertex_array_object_->HaveEnabledClientSideBuffers();
}

void VertexArrayObjectManager::SetAttribEnable(GLuint index, bool enabled) {
  bound_vertex_array_object_->SetAttribEnable(index, enabled);
}

bool VertexArrayObjectManager::GetVertexAttrib(
    GLuint index, GLenum pname, uint32* param) {
  return bound_vertex_array_object_->GetVertexAttrib(index, pname, param);
}

bool VertexArrayObjectManager::GetAttribPointer(
    GLuint index, GLenum pname, void** ptr) const {
  return bound_vertex_array_object_->GetAttribPointer(index, pname, ptr);
}

bool VertexArrayObjectManager::SetAttribPointer(
    GLuint buffer_id,
    GLuint index,
    GLint size,
    GLenum type,
    GLboolean normalized,
    GLsizei stride,
    const void* ptr) {
  // Client side arrays are not allowed in vaos.
  if (buffer_id == 0 && !IsDefaultVAOBound()) {
    return false;
  }
  bound_vertex_array_object_->SetAttribPointer(
      buffer_id, index, size, type, normalized, stride, ptr);
  return true;
}

void VertexArrayObjectManager::SetAttribDivisor(GLuint index, GLuint divisor) {
  bound_vertex_array_object_->SetAttribDivisor(index, divisor);
}

// Collects the data into the collection buffer and returns the number of
// bytes collected.
GLsizei VertexArrayObjectManager::CollectData(
    const void* data,
    GLsizei bytes_per_element,
    GLsizei real_stride,
    GLsizei num_elements) {
  GLsizei bytes_needed = bytes_per_element * num_elements;
  if (collection_buffer_size_ < bytes_needed) {
    collection_buffer_.reset(new int8[bytes_needed]);
    collection_buffer_size_ = bytes_needed;
  }
  const int8* src = static_cast<const int8*>(data);
  int8* dst = collection_buffer_.get();
  int8* end = dst + bytes_per_element * num_elements;
  for (; dst < end; src += real_stride, dst += bytes_per_element) {
    memcpy(dst, src, bytes_per_element);
  }
  return bytes_needed;
}

bool VertexArrayObjectManager::IsDefaultVAOBound() const {
  return bound_vertex_array_object_ == default_vertex_array_object_;
}

// Returns true if buffers were setup.
bool VertexArrayObjectManager::SetupSimulatedClientSideBuffers(
    const char* function_name,
    GLES2Implementation* gl,
    GLES2CmdHelper* gl_helper,
    GLsizei num_elements,
    GLsizei primcount,
    bool* simulated) {
  *simulated = false;
  if (!support_client_side_arrays_)
    return true;
  if (!bound_vertex_array_object_->HaveEnabledClientSideBuffers()) {
    return true;
  }
  if (!IsDefaultVAOBound()) {
    gl->SetGLError(
        GL_INVALID_OPERATION, function_name,
        "client side arrays not allowed with vertex array object");
    return false;
  }
  *simulated = true;
  GLsizei total_size = 0;
  // Compute the size of the buffer we need.
  const VertexArrayObject::VertexAttribs& vertex_attribs =
      bound_vertex_array_object_->vertex_attribs();
  for (GLuint ii = 0; ii < vertex_attribs.size(); ++ii) {
    const VertexArrayObject::VertexAttrib& attrib = vertex_attribs[ii];
    if (attrib.IsClientSide() && attrib.enabled()) {
      size_t bytes_per_element =
          GLES2Util::GetGLTypeSizeForTexturesAndBuffers(attrib.type()) *
          attrib.size();
      GLsizei elements = (primcount && attrib.divisor() > 0) ?
          ((primcount - 1) / attrib.divisor() + 1) : num_elements;
      total_size += RoundUpToMultipleOf4(bytes_per_element * elements);
    }
  }
  gl_helper->BindBuffer(GL_ARRAY_BUFFER, array_buffer_id_);
  array_buffer_offset_ = 0;
  if (total_size > array_buffer_size_) {
    gl->BufferDataHelper(GL_ARRAY_BUFFER, total_size, NULL, GL_DYNAMIC_DRAW);
    array_buffer_size_ = total_size;
  }
  for (GLuint ii = 0; ii < vertex_attribs.size(); ++ii) {
    const VertexArrayObject::VertexAttrib& attrib = vertex_attribs[ii];
    if (attrib.IsClientSide() && attrib.enabled()) {
      size_t bytes_per_element =
          GLES2Util::GetGLTypeSizeForTexturesAndBuffers(attrib.type()) *
          attrib.size();
      GLsizei real_stride = attrib.stride() ?
          attrib.stride() : static_cast<GLsizei>(bytes_per_element);
      GLsizei elements = (primcount && attrib.divisor() > 0) ?
          ((primcount - 1) / attrib.divisor() + 1) : num_elements;
      GLsizei bytes_collected = CollectData(
          attrib.pointer(), bytes_per_element, real_stride, elements);
      gl->BufferSubDataHelper(
          GL_ARRAY_BUFFER, array_buffer_offset_, bytes_collected,
          collection_buffer_.get());
      gl_helper->VertexAttribPointer(
          ii, attrib.size(), attrib.type(), attrib.normalized(), 0,
          array_buffer_offset_);
      array_buffer_offset_ += RoundUpToMultipleOf4(bytes_collected);
      DCHECK_LE(array_buffer_offset_, array_buffer_size_);
    }
  }
  return true;
}

// Copies in indices to the service and returns the highest index accessed + 1
bool VertexArrayObjectManager::SetupSimulatedIndexAndClientSideBuffers(
    const char* function_name,
    GLES2Implementation* gl,
    GLES2CmdHelper* gl_helper,
    GLsizei count,
    GLenum type,
    GLsizei primcount,
    const void* indices,
    GLuint* offset,
    bool* simulated) {
  *simulated = false;
  *offset = ToGLuint(indices);
  if (!support_client_side_arrays_)
    return true;
  GLsizei num_elements = 0;
  if (bound_vertex_array_object_->bound_element_array_buffer() == 0) {
    *simulated = true;
    *offset = 0;
    GLsizei max_index = -1;
    switch (type) {
      case GL_UNSIGNED_BYTE: {
        const uint8* src = static_cast<const uint8*>(indices);
        for (GLsizei ii = 0; ii < count; ++ii) {
          if (src[ii] > max_index) {
            max_index = src[ii];
          }
        }
        break;
      }
      case GL_UNSIGNED_SHORT: {
        const uint16* src = static_cast<const uint16*>(indices);
        for (GLsizei ii = 0; ii < count; ++ii) {
          if (src[ii] > max_index) {
            max_index = src[ii];
          }
        }
        break;
      }
      case GL_UNSIGNED_INT: {
        uint32 max_glsizei = static_cast<uint32>(
            std::numeric_limits<GLsizei>::max());
        const uint32* src = static_cast<const uint32*>(indices);
        for (GLsizei ii = 0; ii < count; ++ii) {
          // Other parts of the API use GLsizei (signed) to store limits.
          // As such, if we encounter a index that cannot be represented with
          // an unsigned int we need to flag it as an error here.
          if(src[ii] > max_glsizei) {
            gl->SetGLError(
                GL_INVALID_OPERATION, function_name, "index too large.");
            return false;
          }
          GLsizei signed_index = static_cast<GLsizei>(src[ii]);
          if (signed_index > max_index) {
            max_index = signed_index;
          }
        }
        break;
      }
      default:
        break;
    }
    gl_helper->BindBuffer(GL_ELEMENT_ARRAY_BUFFER, element_array_buffer_id_);
    GLsizei bytes_per_element =
        GLES2Util::GetGLTypeSizeForTexturesAndBuffers(type);
    GLsizei bytes_needed = bytes_per_element * count;
    if (bytes_needed > element_array_buffer_size_) {
      element_array_buffer_size_ = bytes_needed;
      gl->BufferDataHelper(
          GL_ELEMENT_ARRAY_BUFFER, bytes_needed, NULL, GL_DYNAMIC_DRAW);
    }
    gl->BufferSubDataHelper(
        GL_ELEMENT_ARRAY_BUFFER, 0, bytes_needed, indices);

    num_elements = max_index + 1;
  } else if (bound_vertex_array_object_->HaveEnabledClientSideBuffers()) {
    // Index buffer is GL buffer. Ask the service for the highest vertex
    // that will be accessed. Note: It doesn't matter if another context
    // changes the contents of any of the buffers. The service will still
    // validate the indices. We just need to know how much to copy across.
    num_elements = gl->GetMaxValueInBufferCHROMIUMHelper(
        bound_vertex_array_object_->bound_element_array_buffer(),
        count, type, ToGLuint(indices)) + 1;
  }

  bool simulated_client_side_buffers = false;
  SetupSimulatedClientSideBuffers(
      function_name, gl, gl_helper, num_elements, primcount,
      &simulated_client_side_buffers);
  *simulated = *simulated || simulated_client_side_buffers;
  return true;
}

}  // namespace gles2
}  // namespace gpu


