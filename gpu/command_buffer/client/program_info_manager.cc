// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/program_info_manager.h"

namespace {

template<typename T> static T LocalGetAs(
    const std::vector<int8>& data, uint32 offset, size_t size) {
  const int8* p = &data[0] + offset;
  if (offset + size > data.size()) {
    NOTREACHED();
    return NULL;
  }
  return static_cast<T>(static_cast<const void*>(p));
}

}  // namespace anonymous

namespace gpu {
namespace gles2 {

ProgramInfoManager::Program::VertexAttrib::VertexAttrib(
    GLsizei _size, GLenum _type, const std::string& _name, GLint _location)
    : size(_size),
      type(_type),
      location(_location),
      name(_name) {
}

ProgramInfoManager::Program::VertexAttrib::~VertexAttrib() {
}

ProgramInfoManager::Program::UniformInfo::UniformInfo(
    GLsizei _size, GLenum _type, const std::string& _name)
    : size(_size),
      type(_type),
      name(_name) {
  is_array = (!name.empty() && name[name.size() - 1] == ']');
  DCHECK(!(size > 1 && !is_array));
}

ProgramInfoManager::Program::UniformInfo::~UniformInfo() {
}

ProgramInfoManager::Program::UniformES3::UniformES3()
    : block_index(-1),
      offset(-1),
      array_stride(-1),
      matrix_stride(-1),
      is_row_major(0) {
}

ProgramInfoManager::Program::UniformES3::~UniformES3() {
}

ProgramInfoManager::Program::UniformBlock::UniformBlock()
    : binding(0),
      data_size(0),
      referenced_by_vertex_shader(false),
      referenced_by_fragment_shader(false) {
}

ProgramInfoManager::Program::UniformBlock::~UniformBlock() {
}

ProgramInfoManager::Program::TransformFeedbackVarying::
TransformFeedbackVarying()
    : size(0),
      type(0) {
}

ProgramInfoManager::Program::TransformFeedbackVarying::
~TransformFeedbackVarying() {
}

ProgramInfoManager::Program::Program()
    : cached_es2_(false),
      max_attrib_name_length_(0),
      max_uniform_name_length_(0),
      link_status_(false),
      cached_es3_uniform_blocks_(false),
      active_uniform_block_max_name_length_(0),
      cached_es3_transform_feedback_varyings_(false),
      transform_feedback_varying_max_length_(0),
      cached_es3_uniformsiv_(false) {
}

ProgramInfoManager::Program::~Program() {
}

// TODO(gman): Add a faster lookup.
GLint ProgramInfoManager::Program::GetAttribLocation(
    const std::string& name) const {
  for (GLuint ii = 0; ii < attrib_infos_.size(); ++ii) {
    const VertexAttrib& info = attrib_infos_[ii];
    if (info.name == name) {
      return info.location;
    }
  }
  return -1;
}

const ProgramInfoManager::Program::VertexAttrib*
ProgramInfoManager::Program::GetAttribInfo(GLint index) const {
  return (static_cast<size_t>(index) < attrib_infos_.size()) ?
      &attrib_infos_[index] : NULL;
}

const ProgramInfoManager::Program::UniformInfo*
ProgramInfoManager::Program::GetUniformInfo(GLint index) const {
  return (static_cast<size_t>(index) < uniform_infos_.size()) ?
      &uniform_infos_[index] : NULL;
}

const ProgramInfoManager::Program::UniformBlock*
ProgramInfoManager::Program::GetUniformBlock(GLuint index) const {
  return (index < uniform_blocks_.size()) ? &uniform_blocks_[index] : NULL;
}

GLint ProgramInfoManager::Program::GetUniformLocation(
    const std::string& name) const {
  bool getting_array_location = false;
  size_t open_pos = std::string::npos;
  int index = 0;
  if (!GLES2Util::ParseUniformName(
      name, &open_pos, &index, &getting_array_location)) {
    return -1;
  }
  for (GLuint ii = 0; ii < uniform_infos_.size(); ++ii) {
    const UniformInfo& info = uniform_infos_[ii];
    if (info.name == name ||
        (info.is_array &&
         info.name.compare(0, info.name.size() - 3, name) == 0)) {
      return info.element_locations[0];
    } else if (getting_array_location && info.is_array) {
      // Look for an array specification.
      size_t open_pos_2 = info.name.find_last_of('[');
      if (open_pos_2 == open_pos &&
          name.compare(0, open_pos, info.name, 0, open_pos) == 0) {
        if (index >= 0 && index < info.size) {
          return info.element_locations[index];
        }
      }
    }
  }
  return -1;
}

GLuint ProgramInfoManager::Program::GetUniformIndex(
    const std::string& name) const {
  // TODO(zmo): Maybe build a hashed_map for faster lookup.
  for (GLuint ii = 0; ii < uniform_infos_.size(); ++ii) {
    const UniformInfo& info = uniform_infos_[ii];
    // For an array, either "var" or "var[0]" is considered as a match.
    // See "OpenGL ES 3.0.0, Section 2.11.3 Program Objects."
    if (info.name == name ||
        (info.is_array &&
         info.name.compare(0, info.name.size() - 3, name) == 0)) {
      return ii;
    }
  }
  return GL_INVALID_INDEX;
}

GLint ProgramInfoManager::Program::GetFragDataLocation(
    const std::string& name) const {
  base::hash_map<std::string, GLint>::const_iterator iter =
      frag_data_locations_.find(name);
  if (iter == frag_data_locations_.end())
    return -1;
  return iter->second;
}

void ProgramInfoManager::Program::CacheFragDataLocation(
    const std::string& name, GLint loc) {
  frag_data_locations_[name] = loc;
}

bool ProgramInfoManager::Program::GetProgramiv(
    GLenum pname, GLint* params) {
  switch (pname) {
    case GL_LINK_STATUS:
      *params = static_cast<GLint>(link_status_);
      return true;
    case GL_ACTIVE_ATTRIBUTES:
      *params = static_cast<GLint>(attrib_infos_.size());
      return true;
    case GL_ACTIVE_ATTRIBUTE_MAX_LENGTH:
      *params = static_cast<GLint>(max_attrib_name_length_);
      return true;
    case GL_ACTIVE_UNIFORMS:
      *params = static_cast<GLint>(uniform_infos_.size());
      return true;
    case GL_ACTIVE_UNIFORM_MAX_LENGTH:
      *params = static_cast<GLint>(max_uniform_name_length_);
      return true;
    case GL_ACTIVE_UNIFORM_BLOCKS:
      *params = static_cast<GLint>(uniform_blocks_.size());
      return true;
    case GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH:
      *params = static_cast<GLint>(active_uniform_block_max_name_length_);
      return true;
    case GL_TRANSFORM_FEEDBACK_VARYINGS:
      *params = static_cast<GLint>(transform_feedback_varyings_.size());
      return true;
    case GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH:
      *params = static_cast<GLint>(transform_feedback_varying_max_length_);
      return true;
    default:
      NOTREACHED();
      break;
  }
  return false;
}

GLuint ProgramInfoManager::Program::GetUniformBlockIndex(
    const std::string& name) const {
  for (size_t ii = 0; ii < uniform_blocks_.size(); ++ii) {
    if (uniform_blocks_[ii].name == name) {
      return static_cast<GLuint>(ii);
    }
  }
  return GL_INVALID_INDEX;
}

void ProgramInfoManager::Program::UniformBlockBinding(
    GLuint index , GLuint binding) {
  if (index < uniform_blocks_.size()) {
    uniform_blocks_[index].binding = binding;
  }
}

const ProgramInfoManager::Program::TransformFeedbackVarying*
ProgramInfoManager::Program::GetTransformFeedbackVarying(GLuint index) const {
  return (index < transform_feedback_varyings_.size()) ?
      &transform_feedback_varyings_[index] : NULL;
}

bool ProgramInfoManager::Program::GetUniformsiv(
    GLsizei count, const GLuint* indices, GLenum pname, GLint* params) {
  if (count == 0) {
    // At this point, pname has already been validated.
    return true;
  }
  DCHECK(count > 0 && indices);
  size_t num_uniforms = uniform_infos_.size();
  if (num_uniforms == 0) {
    num_uniforms = uniforms_es3_.size();
  }
  if (static_cast<size_t>(count) > num_uniforms) {
    return false;
  }
  for (GLsizei ii = 0; ii < count; ++ii) {
    if (indices[ii] >= num_uniforms) {
      return false;
    }
  }
  if (!params) {
    return true;
  }
  switch (pname) {
    case GL_UNIFORM_SIZE:
      DCHECK_EQ(num_uniforms, uniform_infos_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = static_cast<GLint>(uniform_infos_[indices[ii]].size);
      }
      return true;
    case GL_UNIFORM_TYPE:
      DCHECK_EQ(num_uniforms, uniform_infos_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = static_cast<GLint>(uniform_infos_[indices[ii]].type);
      }
      return true;
    case GL_UNIFORM_NAME_LENGTH:
      DCHECK_EQ(num_uniforms, uniform_infos_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = static_cast<GLint>(
            uniform_infos_[indices[ii]].name.length() + 1);
      }
      return true;
    case GL_UNIFORM_BLOCK_INDEX:
      DCHECK_EQ(num_uniforms, uniforms_es3_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = uniforms_es3_[indices[ii]].block_index;
      }
      return true;
    case GL_UNIFORM_OFFSET:
      DCHECK_EQ(num_uniforms, uniforms_es3_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = uniforms_es3_[indices[ii]].offset;
      }
      return true;
    case GL_UNIFORM_ARRAY_STRIDE:
      DCHECK_EQ(num_uniforms, uniforms_es3_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = uniforms_es3_[indices[ii]].array_stride;
      }
      return true;
    case GL_UNIFORM_MATRIX_STRIDE:
      DCHECK_EQ(num_uniforms, uniforms_es3_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = uniforms_es3_[indices[ii]].matrix_stride;
      }
      return true;
    case GL_UNIFORM_IS_ROW_MAJOR:
      DCHECK_EQ(num_uniforms, uniforms_es3_.size());
      for (GLsizei ii = 0; ii < count; ++ii) {
        params[ii] = uniforms_es3_[indices[ii]].is_row_major;
      }
      return true;
    default:
      NOTREACHED();
      break;
  }
  return false;
}

void ProgramInfoManager::Program::UpdateES2(const std::vector<int8>& result) {
  if (cached_es2_) {
    return;
  }
  if (result.empty()) {
    // This should only happen on a lost context.
    return;
  }
  DCHECK_GE(result.size(), sizeof(ProgramInfoHeader));
  const ProgramInfoHeader* header = LocalGetAs<const ProgramInfoHeader*>(
      result, 0, sizeof(header));
  link_status_ = header->link_status != 0;
  if (!link_status_) {
    return;
  }
  DCHECK_EQ(0u, attrib_infos_.size());
  DCHECK_EQ(0u, uniform_infos_.size());
  DCHECK_EQ(0, max_attrib_name_length_);
  DCHECK_EQ(0, max_uniform_name_length_);
  const ProgramInput* inputs = LocalGetAs<const ProgramInput*>(
      result, sizeof(*header),
      sizeof(ProgramInput) * (header->num_attribs + header->num_uniforms));
  const ProgramInput* input = inputs;
  for (uint32 ii = 0; ii < header->num_attribs; ++ii) {
    const int32* location = LocalGetAs<const int32*>(
        result, input->location_offset, sizeof(int32));
    const char* name_buf = LocalGetAs<const char*>(
        result, input->name_offset, input->name_length);
    std::string name(name_buf, input->name_length);
    attrib_infos_.push_back(
        VertexAttrib(input->size, input->type, name, *location));
    max_attrib_name_length_ = std::max(
        static_cast<GLsizei>(name.size() + 1), max_attrib_name_length_);
    ++input;
  }
  for (uint32 ii = 0; ii < header->num_uniforms; ++ii) {
    const int32* locations = LocalGetAs<const int32*>(
        result, input->location_offset, sizeof(int32) * input->size);
    const char* name_buf = LocalGetAs<const char*>(
        result, input->name_offset, input->name_length);
    std::string name(name_buf, input->name_length);
    UniformInfo info(input->size, input->type, name);
    max_uniform_name_length_ = std::max(
        static_cast<GLsizei>(name.size() + 1), max_uniform_name_length_);
    for (int32 jj = 0; jj < input->size; ++jj) {
      info.element_locations.push_back(locations[jj]);
    }
    uniform_infos_.push_back(info);
    ++input;
  }
  DCHECK_EQ(header->num_attribs + header->num_uniforms,
            static_cast<uint32>(input - inputs));
  cached_es2_ = true;
}

void ProgramInfoManager::Program::UpdateES3UniformBlocks(
    const std::vector<int8>& result) {
  if (cached_es3_uniform_blocks_) {
    return;
  }
  if (result.empty()) {
    // This should only happen on a lost context.
    return;
  }
  DCHECK_EQ(0u, uniform_blocks_.size());
  DCHECK_EQ(0u, active_uniform_block_max_name_length_);

  // |result| comes from GPU process. We consider it trusted data. Therefore,
  // no need to check for overflows as the GPU side did the checks already.
  uint32_t header_size = sizeof(UniformBlocksHeader);
  DCHECK_GE(result.size(), header_size);
  const UniformBlocksHeader* header = LocalGetAs<const UniformBlocksHeader*>(
      result, 0, header_size);
  DCHECK(header);
  if (header->num_uniform_blocks == 0) {
    DCHECK_EQ(result.size(), header_size);
    // TODO(zmo): Here we can't tell if no uniform blocks are defined, or
    // the previous link failed.
    return;
  }
  uniform_blocks_.resize(header->num_uniform_blocks);

  uint32_t entry_size = sizeof(UniformBlockInfo) * header->num_uniform_blocks;
  DCHECK_GE(result.size(), header_size + entry_size);
  uint32_t data_size = result.size() - header_size - entry_size;
  DCHECK_LT(0u, data_size);
  const UniformBlockInfo* entries = LocalGetAs<const UniformBlockInfo*>(
      result, header_size, entry_size);
  DCHECK(entries);
  const char* data = LocalGetAs<const char*>(
      result, header_size + entry_size, data_size);
  DCHECK(data);

  uint32_t size = 0;
  for (uint32_t ii = 0; ii < header->num_uniform_blocks; ++ii) {
    uniform_blocks_[ii].binding = static_cast<GLuint>(entries[ii].binding);
    uniform_blocks_[ii].data_size = static_cast<GLuint>(entries[ii].data_size);
    uniform_blocks_[ii].active_uniform_indices.resize(
        entries[ii].active_uniforms);
    uniform_blocks_[ii].referenced_by_vertex_shader = static_cast<GLboolean>(
        entries[ii].referenced_by_vertex_shader);
    uniform_blocks_[ii].referenced_by_fragment_shader = static_cast<GLboolean>(
        entries[ii].referenced_by_fragment_shader);
    // Uniform block names can't be empty strings.
    DCHECK_LT(1u, entries[ii].name_length);
    if (entries[ii].name_length > active_uniform_block_max_name_length_) {
      active_uniform_block_max_name_length_ = entries[ii].name_length;
    }
    size += entries[ii].name_length;
    DCHECK_GE(data_size, size);
    uniform_blocks_[ii].name = std::string(data, entries[ii].name_length - 1);
    data += entries[ii].name_length;
    size += entries[ii].active_uniforms * sizeof(uint32_t);
    DCHECK_GE(data_size, size);
    const uint32_t* indices = reinterpret_cast<const uint32_t*>(data);
    for (uint32_t uu = 0; uu < entries[ii].active_uniforms; ++uu) {
      uniform_blocks_[ii].active_uniform_indices[uu] =
          static_cast<GLuint>(indices[uu]);
    }
    indices += entries[ii].active_uniforms;
    data = reinterpret_cast<const char*>(indices);
  }
  DCHECK_EQ(data_size, size);
  cached_es3_uniform_blocks_ = true;
}

void ProgramInfoManager::Program::UpdateES3Uniformsiv(
    const std::vector<int8>& result) {
  if (cached_es3_uniformsiv_) {
    return;
  }
  if (result.empty()) {
    // This should only happen on a lost context.
    return;
  }
  DCHECK_EQ(0u, uniforms_es3_.size());

  // |result| comes from GPU process. We consider it trusted data. Therefore,
  // no need to check for overflows as the GPU side did the checks already.
  uint32_t header_size = sizeof(UniformsES3Header);
  DCHECK_GE(result.size(), header_size);
  const UniformsES3Header* header = LocalGetAs<const UniformsES3Header*>(
      result, 0, header_size);
  DCHECK(header);
  if (header->num_uniforms == 0) {
    DCHECK_EQ(result.size(), header_size);
    // TODO(zmo): Here we can't tell if no uniforms are defined, or
    // the previous link failed.
    return;
  }
  uniforms_es3_.resize(header->num_uniforms);

  uint32_t entry_size = sizeof(UniformES3Info) * header->num_uniforms;
  DCHECK_EQ(result.size(), header_size + entry_size);
  const UniformES3Info* entries = LocalGetAs<const UniformES3Info*>(
      result, header_size, entry_size);
  DCHECK(entries);

  for (uint32_t ii = 0; ii < header->num_uniforms; ++ii) {
    uniforms_es3_[ii].block_index = entries[ii].block_index;
    uniforms_es3_[ii].offset = entries[ii].offset;
    uniforms_es3_[ii].array_stride = entries[ii].array_stride;
    uniforms_es3_[ii].matrix_stride = entries[ii].matrix_stride;
    uniforms_es3_[ii].is_row_major = entries[ii].is_row_major;
  }
  cached_es3_uniformsiv_ = true;
}

void ProgramInfoManager::Program::UpdateES3TransformFeedbackVaryings(
    const std::vector<int8>& result) {
  if (cached_es3_transform_feedback_varyings_) {
    return;
  }
  if (result.empty()) {
    // This should only happen on a lost context.
    return;
  }
  DCHECK_EQ(0u, transform_feedback_varyings_.size());
  DCHECK_EQ(0u, transform_feedback_varying_max_length_);

  // |result| comes from GPU process. We consider it trusted data. Therefore,
  // no need to check for overflows as the GPU side did the checks already.
  uint32_t header_size = sizeof(TransformFeedbackVaryingsHeader);
  DCHECK_GE(result.size(), header_size);
  const TransformFeedbackVaryingsHeader* header =
      LocalGetAs<const TransformFeedbackVaryingsHeader*>(
          result, 0, header_size);
  DCHECK(header);
  if (header->num_transform_feedback_varyings == 0) {
    DCHECK_EQ(result.size(), header_size);
    // TODO(zmo): Here we can't tell if no TransformFeedback varyings are
    // defined, or the previous link failed.
    return;
  }
  transform_feedback_varyings_.resize(header->num_transform_feedback_varyings);

  uint32_t entry_size = sizeof(TransformFeedbackVaryingInfo) *
      header->num_transform_feedback_varyings;
  DCHECK_GE(result.size(), header_size + entry_size);
  uint32_t data_size = result.size() - header_size - entry_size;
  DCHECK_LT(0u, data_size);
  const TransformFeedbackVaryingInfo* entries =
      LocalGetAs<const TransformFeedbackVaryingInfo*>(
          result, header_size, entry_size);
  DCHECK(entries);
  const char* data = LocalGetAs<const char*>(
      result, header_size + entry_size, data_size);
  DCHECK(data);

  uint32_t size = 0;
  for (uint32_t ii = 0; ii < header->num_transform_feedback_varyings; ++ii) {
    transform_feedback_varyings_[ii].size =
        static_cast<GLsizei>(entries[ii].size);
    transform_feedback_varyings_[ii].type =
        static_cast<GLenum>(entries[ii].type);
    DCHECK_LE(1u, entries[ii].name_length);
    if (entries[ii].name_length > transform_feedback_varying_max_length_) {
      transform_feedback_varying_max_length_ = entries[ii].name_length;
    }
    size += entries[ii].name_length;
    DCHECK_GE(data_size, size);
    transform_feedback_varyings_[ii].name =
        std::string(data, entries[ii].name_length - 1);
    data += entries[ii].name_length;
  }
  DCHECK_EQ(data_size, size);
  cached_es3_transform_feedback_varyings_ = true;
}

bool ProgramInfoManager::Program::IsCached(ProgramInfoType type) const {
  switch (type) {
    case kES2:
      return cached_es2_;
    case kES3UniformBlocks:
      return cached_es3_uniform_blocks_;
    case kES3TransformFeedbackVaryings:
      return cached_es3_transform_feedback_varyings_;
    case kES3Uniformsiv:
      return cached_es3_uniformsiv_;
    case kNone:
      return true;
    default:
      NOTREACHED();
      return true;
  }
}


ProgramInfoManager::ProgramInfoManager() {
}

ProgramInfoManager::~ProgramInfoManager() {
}

ProgramInfoManager::Program* ProgramInfoManager::GetProgramInfo(
    GLES2Implementation* gl, GLuint program, ProgramInfoType type) {
  lock_.AssertAcquired();
  ProgramInfoMap::iterator it = program_infos_.find(program);
  if (it == program_infos_.end()) {
    return NULL;
  }
  Program* info = &it->second;
  if (info->IsCached(type))
    return info;

  std::vector<int8> result;
  switch (type) {
    case kES2:
      {
        base::AutoUnlock unlock(lock_);
        // lock_ can't be held across IPC call or else it may deadlock in
        // pepper. http://crbug.com/418651
        gl->GetProgramInfoCHROMIUMHelper(program, &result);
      }
      info->UpdateES2(result);
      break;
    case kES3UniformBlocks:
      {
        base::AutoUnlock unlock(lock_);
        // lock_ can't be held across IPC call or else it may deadlock in
        // pepper. http://crbug.com/418651
        gl->GetUniformBlocksCHROMIUMHelper(program, &result);
      }
      info->UpdateES3UniformBlocks(result);
      break;
    case kES3TransformFeedbackVaryings:
      {
        base::AutoUnlock unlock(lock_);
        // lock_ can't be held across IPC call or else it may deadlock in
        // pepper. http://crbug.com/418651
        gl->GetTransformFeedbackVaryingsCHROMIUMHelper(program, &result);
      }
      info->UpdateES3TransformFeedbackVaryings(result);
    case kES3Uniformsiv:
      {
        base::AutoUnlock unlock(lock_);
        // lock_ can't be held across IPC call or else it may deadlock in
        // pepper. http://crbug.com/418651
        gl->GetUniformsES3CHROMIUMHelper(program, &result);
      }
      info->UpdateES3Uniformsiv(result);
    default:
      NOTREACHED();
      return NULL;
  }
  return info;
}

void ProgramInfoManager::CreateInfo(GLuint program) {
  base::AutoLock auto_lock(lock_);
  program_infos_.erase(program);
  std::pair<ProgramInfoMap::iterator, bool> result =
      program_infos_.insert(std::make_pair(program, Program()));

  DCHECK(result.second);
}

void ProgramInfoManager::DeleteInfo(GLuint program) {
  base::AutoLock auto_lock(lock_);
  program_infos_.erase(program);
}

bool ProgramInfoManager::GetProgramiv(
    GLES2Implementation* gl, GLuint program, GLenum pname, GLint* params) {
  base::AutoLock auto_lock(lock_);
  ProgramInfoType type = kNone;
  switch (pname) {
    case GL_ACTIVE_ATTRIBUTES:
    case GL_ACTIVE_ATTRIBUTE_MAX_LENGTH:
    case GL_ACTIVE_UNIFORMS:
    case GL_ACTIVE_UNIFORM_MAX_LENGTH:
    case GL_LINK_STATUS:
      type = kES2;
      break;
    case GL_ACTIVE_UNIFORM_BLOCKS:
    case GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH:
      type = kES3UniformBlocks;
      break;
    case GL_TRANSFORM_FEEDBACK_VARYINGS:
    case GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH:
      type = kES3TransformFeedbackVaryings;
      break;
    default:
      return false;
  }
  Program* info = GetProgramInfo(gl, program, type);
  if (!info) {
    return false;
  }
  return info->GetProgramiv(pname, params);
}

bool ProgramInfoManager::GetActiveUniformsiv(
    GLES2Implementation* gl, GLuint program, GLsizei count,
    const GLuint* indices, GLenum pname, GLint* params) {
  base::AutoLock auto_lock(lock_);
  ProgramInfoType type = kNone;
  switch (pname) {
    case GL_UNIFORM_SIZE:
    case GL_UNIFORM_TYPE:
    case GL_UNIFORM_NAME_LENGTH:
      type = kES2;
      break;
    case GL_UNIFORM_BLOCK_INDEX:
    case GL_UNIFORM_OFFSET:
    case GL_UNIFORM_ARRAY_STRIDE:
    case GL_UNIFORM_MATRIX_STRIDE:
    case GL_UNIFORM_IS_ROW_MAJOR:
      type = kES3Uniformsiv;
      break;
    default:
      return false;
  }
  Program* info = GetProgramInfo(gl, program, type);
  if (info) {
    return info->GetUniformsiv(count, indices, pname, params);
  }
  return gl->GetActiveUniformsivHelper(program, count, indices, pname, params);
}

GLint ProgramInfoManager::GetAttribLocation(
    GLES2Implementation* gl, GLuint program, const char* name) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES2);
    if (info) {
      return info->GetAttribLocation(name);
    }
  }
  return gl->GetAttribLocationHelper(program, name);
}

GLint ProgramInfoManager::GetUniformLocation(
    GLES2Implementation* gl, GLuint program, const char* name) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES2);
    if (info) {
      return info->GetUniformLocation(name);
    }
  }
  return gl->GetUniformLocationHelper(program, name);
}

GLint ProgramInfoManager::GetFragDataLocation(
    GLES2Implementation* gl, GLuint program, const char* name) {
  // TODO(zmo): make FragData locations part of the ProgramInfo that are
  // fetched altogether from the service side.  See crbug.com/452104.
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kNone);
    if (info) {
      GLint possible_loc = info->GetFragDataLocation(name);
      if (possible_loc != -1)
        return possible_loc;
    }
  }
  GLint loc = gl->GetFragDataLocationHelper(program, name);
  if (loc != -1) {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kNone);
    if (info) {
      info->CacheFragDataLocation(name, loc);
    }
  }
  return loc;
}

bool ProgramInfoManager::GetActiveAttrib(
    GLES2Implementation* gl,
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length,
    GLint* size, GLenum* type, char* name) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES2);
    if (info) {
      const Program::VertexAttrib* attrib_info = info->GetAttribInfo(index);
      if (attrib_info) {
        if (size) {
          *size = attrib_info->size;
        }
        if (type) {
          *type = attrib_info->type;
        }
        if (length || name) {
          GLsizei max_size = std::min(
              static_cast<size_t>(bufsize) - 1,
              std::max(static_cast<size_t>(0), attrib_info->name.size()));
          if (length) {
            *length = max_size;
          }
          if (name && bufsize > 0) {
            memcpy(name, attrib_info->name.c_str(), max_size);
            name[max_size] = '\0';
          }
        }
        return true;
      }
    }
  }
  return gl->GetActiveAttribHelper(
      program, index, bufsize, length, size, type, name);
}

bool ProgramInfoManager::GetActiveUniform(
    GLES2Implementation* gl,
    GLuint program, GLuint index, GLsizei bufsize, GLsizei* length,
    GLint* size, GLenum* type, char* name) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES2);
    if (info) {
      const Program::UniformInfo* uniform_info = info->GetUniformInfo(index);
      if (uniform_info) {
        if (size) {
          *size = uniform_info->size;
        }
        if (type) {
          *type = uniform_info->type;
        }
        if (length || name) {
          GLsizei max_size = std::min(
              static_cast<size_t>(bufsize) - 1,
              std::max(static_cast<size_t>(0), uniform_info->name.size()));
          if (length) {
            *length = max_size;
          }
          if (name && bufsize > 0) {
            memcpy(name, uniform_info->name.c_str(), max_size);
            name[max_size] = '\0';
          }
        }
        return true;
      }
    }
  }
  return gl->GetActiveUniformHelper(
      program, index, bufsize, length, size, type, name);
}

GLuint ProgramInfoManager::GetUniformBlockIndex(
    GLES2Implementation* gl, GLuint program, const char* name) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES3UniformBlocks);
    if (info) {
      return info->GetUniformBlockIndex(name);
    }
  }
  return gl->GetUniformBlockIndexHelper(program, name);
}

bool ProgramInfoManager::GetActiveUniformBlockName(
    GLES2Implementation* gl, GLuint program, GLuint index,
    GLsizei buf_size, GLsizei* length, char* name) {
  DCHECK_LE(0, buf_size);
  if (!name) {
    buf_size = 0;
  }
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES3UniformBlocks);
    if (info) {
      const Program::UniformBlock* uniform_block = info->GetUniformBlock(index);
      if (uniform_block) {
        if (buf_size == 0) {
          if (length) {
            *length = 0;
          }
        } else if (length || name) {
          GLsizei max_size = std::min(
              buf_size - 1, static_cast<GLsizei>(uniform_block->name.size()));
          if (length) {
            *length = max_size;
          }
          if (name) {
            memcpy(name, uniform_block->name.data(), max_size);
            name[max_size] = '\0';
          }
        }
        return true;
      }
    }
  }
  return gl->GetActiveUniformBlockNameHelper(
      program, index, buf_size, length, name);
}

bool ProgramInfoManager::GetActiveUniformBlockiv(
    GLES2Implementation* gl, GLuint program, GLuint index,
    GLenum pname, GLint* params) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES3UniformBlocks);
    if (info) {
      const Program::UniformBlock* uniform_block = info->GetUniformBlock(index);
      bool valid_pname;
      switch (pname) {
        case GL_UNIFORM_BLOCK_BINDING:
        case GL_UNIFORM_BLOCK_DATA_SIZE:
        case GL_UNIFORM_BLOCK_NAME_LENGTH:
        case GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS:
        case GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES:
        case GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER:
        case GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER:
          valid_pname = true;
          break;
        default:
          valid_pname = false;
          break;
      }
      if (uniform_block && valid_pname && params) {
        switch (pname) {
          case GL_UNIFORM_BLOCK_BINDING:
            *params = static_cast<GLint>(uniform_block->binding);
            break;
          case GL_UNIFORM_BLOCK_DATA_SIZE:
            *params = static_cast<GLint>(uniform_block->data_size);
            break;
          case GL_UNIFORM_BLOCK_NAME_LENGTH:
            *params = static_cast<GLint>(uniform_block->name.size()) + 1;
            break;
          case GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS:
            *params = static_cast<GLint>(
                uniform_block->active_uniform_indices.size());
            break;
          case GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES:
            for (size_t ii = 0;
                 ii < uniform_block->active_uniform_indices.size(); ++ii) {
              params[ii] = static_cast<GLint>(
                  uniform_block->active_uniform_indices[ii]);
            }
            break;
          case GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER:
            *params = static_cast<GLint>(
                uniform_block->referenced_by_vertex_shader);
            break;
          case GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER:
            *params = static_cast<GLint>(
                uniform_block->referenced_by_fragment_shader);
            break;
          default:
            NOTREACHED();
        }
        return true;
      }
    }
  }
  return gl->GetActiveUniformBlockivHelper(program, index, pname, params);
}

void ProgramInfoManager::UniformBlockBinding(
    GLES2Implementation* gl, GLuint program, GLuint index, GLuint binding) {
  GLuint max_bindings =
      static_cast<GLuint>(gl->capabilities().max_uniform_buffer_bindings);
  if (binding < max_bindings) {
    base::AutoLock auto_lock(lock_);
    // If UniformBlock info haven't been cached yet, skip updating the binding.
    Program* info = GetProgramInfo(gl, program, kNone);
    if (info) {
      info->UniformBlockBinding(index, binding);
    }
  }
}

bool ProgramInfoManager::GetTransformFeedbackVarying(
    GLES2Implementation* gl, GLuint program, GLuint index, GLsizei bufsize,
    GLsizei* length, GLsizei* size, GLenum* type, char* name) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES3TransformFeedbackVaryings);
    if (info) {
      const Program::TransformFeedbackVarying* varying =
          info->GetTransformFeedbackVarying(index);
      if (varying) {
        if (size) {
          *size = varying->size;
        }
        if (type) {
          *type = varying->type;
        }
        if (length || name) {
          GLsizei max_size = std::min(
              bufsize - 1, static_cast<GLsizei>(varying->name.size()));
          if (length) {
            *length = static_cast<GLsizei>(max_size);
          }
          if (name && bufsize > 0) {
            memcpy(name, varying->name.c_str(), max_size);
            name[max_size] = '\0';
          }
        }
        return true;
      }
    }
  }
  return gl->GetTransformFeedbackVaryingHelper(
      program, index, bufsize, length, size, type, name);
}

bool ProgramInfoManager::GetUniformIndices(GLES2Implementation* gl,
    GLuint program, GLsizei count, const char* const* names, GLuint* indices) {
  {
    base::AutoLock auto_lock(lock_);
    Program* info = GetProgramInfo(gl, program, kES2);
    if (info) {
      DCHECK_LT(0, count);
      DCHECK(names && indices);
      for (GLsizei ii = 0; ii < count; ++ii) {
        indices[ii] = info->GetUniformIndex(names[ii]);
      }
      return true;
    }
  }
  return gl->GetUniformIndicesHelper(program, count, names, indices);
}

}  // namespace gles2
}  // namespace gpu

