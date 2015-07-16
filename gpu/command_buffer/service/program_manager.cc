// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/program_manager.h"

#include <algorithm>
#include <set>
#include <utility>
#include <vector>

#include "base/basictypes.h"
#include "base/command_line.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram.h"
#include "base/numerics/safe_math.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/time/time.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/command_buffer/service/program_cache.h"
#include "gpu/command_buffer/service/shader_manager.h"
#include "third_party/re2/re2/re2.h"

using base::TimeDelta;
using base::TimeTicks;

namespace gpu {
namespace gles2 {

namespace {

int ShaderTypeToIndex(GLenum shader_type) {
  switch (shader_type) {
    case GL_VERTEX_SHADER:
      return 0;
    case GL_FRAGMENT_SHADER:
      return 1;
    default:
      NOTREACHED();
      return 0;
  }
}

// Given a name like "foo.bar[123].moo[456]" sets new_name to "foo.bar[123].moo"
// and sets element_index to 456. returns false if element expression was not a
// whole decimal number. For example: "foo[1b2]"
bool GetUniformNameSansElement(
    const std::string& name, int* element_index, std::string* new_name) {
  DCHECK(element_index);
  DCHECK(new_name);
  if (name.size() < 3 || name[name.size() - 1] != ']') {
    *element_index = 0;
    *new_name = name;
    return true;
  }

  // Look for an array specification.
  size_t open_pos = name.find_last_of('[');
  if (open_pos == std::string::npos ||
      open_pos >= name.size() - 2) {
    return false;
  }

  base::CheckedNumeric<GLint> index = 0;
  size_t last = name.size() - 1;
  for (size_t pos = open_pos + 1; pos < last; ++pos) {
    int8 digit = name[pos] - '0';
    if (digit < 0 || digit > 9) {
      return false;
    }
    index = index * 10 + digit;
  }
  if (!index.IsValid()) {
    return false;
  }

  *element_index = index.ValueOrDie();
  *new_name = name.substr(0, open_pos);
  return true;
}

bool IsBuiltInFragmentVarying(const std::string& name) {
  // Built-in variables for fragment shaders.
  const char* kBuiltInVaryings[] = {
      "gl_FragCoord",
      "gl_FrontFacing",
      "gl_PointCoord"
  };
  for (size_t ii = 0; ii < arraysize(kBuiltInVaryings); ++ii) {
    if (name == kBuiltInVaryings[ii])
      return true;
  }
  return false;
}

bool IsBuiltInInvariant(
    const VaryingMap& varyings, const std::string& name) {
  VaryingMap::const_iterator hit = varyings.find(name);
  if (hit == varyings.end())
    return false;
  return hit->second.isInvariant;
}

uint32 ComputeOffset(const void* start, const void* position) {
  return static_cast<const uint8*>(position) -
         static_cast<const uint8*>(start);
}

}  // anonymous namespace.

Program::UniformInfo::UniformInfo()
    : size(0),
      type(GL_NONE),
      fake_location_base(0),
      is_array(false) {
}

Program::UniformInfo::UniformInfo(GLsizei _size,
                                  GLenum _type,
                                  int _fake_location_base,
                                  const std::string& _name)
    : size(_size),
      type(_type),
      accepts_api_type(0),
      fake_location_base(_fake_location_base),
      is_array(false),
      name(_name) {
  switch (type) {
    case GL_INT:
      accepts_api_type = kUniform1i;
      break;
    case GL_INT_VEC2:
      accepts_api_type = kUniform2i;
      break;
    case GL_INT_VEC3:
      accepts_api_type = kUniform3i;
      break;
    case GL_INT_VEC4:
      accepts_api_type = kUniform4i;
      break;

    case GL_BOOL:
      accepts_api_type = kUniform1i | kUniform1f;
      break;
    case GL_BOOL_VEC2:
      accepts_api_type = kUniform2i | kUniform2f;
      break;
    case GL_BOOL_VEC3:
      accepts_api_type = kUniform3i | kUniform3f;
      break;
    case GL_BOOL_VEC4:
      accepts_api_type = kUniform4i | kUniform4f;
      break;

    case GL_FLOAT:
      accepts_api_type = kUniform1f;
      break;
    case GL_FLOAT_VEC2:
      accepts_api_type = kUniform2f;
      break;
    case GL_FLOAT_VEC3:
      accepts_api_type = kUniform3f;
      break;
    case GL_FLOAT_VEC4:
      accepts_api_type = kUniform4f;
      break;

    case GL_FLOAT_MAT2:
      accepts_api_type = kUniformMatrix2f;
      break;
    case GL_FLOAT_MAT3:
      accepts_api_type = kUniformMatrix3f;
      break;
    case GL_FLOAT_MAT4:
      accepts_api_type = kUniformMatrix4f;
      break;

    case GL_SAMPLER_2D:
    case GL_SAMPLER_2D_RECT_ARB:
    case GL_SAMPLER_CUBE:
    case GL_SAMPLER_3D_OES:
    case GL_SAMPLER_EXTERNAL_OES:
      accepts_api_type = kUniform1i;
      break;
    default:
      NOTREACHED() << "Unhandled UniformInfo type " << type;
      break;
  }
}

Program::UniformInfo::~UniformInfo() {}

bool ProgramManager::IsInvalidPrefix(const char* name, size_t length) {
  static const char kInvalidPrefix[] = { 'g', 'l', '_' };
  return (length >= sizeof(kInvalidPrefix) &&
      memcmp(name, kInvalidPrefix, sizeof(kInvalidPrefix)) == 0);
}

Program::Program(ProgramManager* manager, GLuint service_id)
    : manager_(manager),
      use_count_(0),
      max_attrib_name_length_(0),
      max_uniform_name_length_(0),
      service_id_(service_id),
      deleted_(false),
      valid_(false),
      link_status_(false),
      uniforms_cleared_(false),
      num_uniforms_(0),
      transform_feedback_buffer_mode_(GL_NONE) {
  manager_->StartTracking(this);
}

void Program::Reset() {
  valid_ = false;
  link_status_ = false;
  num_uniforms_ = 0;
  max_uniform_name_length_ = 0;
  max_attrib_name_length_ = 0;
  attrib_infos_.clear();
  uniform_infos_.clear();
  sampler_indices_.clear();
  attrib_location_to_index_map_.clear();
}

std::string Program::ProcessLogInfo(
    const std::string& log) {
  std::string output;
  re2::StringPiece input(log);
  std::string prior_log;
  std::string hashed_name;
  while (RE2::Consume(&input,
                      "(.*?)(webgl_[0123456789abcdefABCDEF]+)",
                      &prior_log,
                      &hashed_name)) {
    output += prior_log;

    const std::string* original_name =
        GetOriginalNameFromHashedName(hashed_name);
    if (original_name)
      output += *original_name;
    else
      output += hashed_name;
  }

  return output + input.as_string();
}

void Program::UpdateLogInfo() {
  GLint max_len = 0;
  glGetProgramiv(service_id_, GL_INFO_LOG_LENGTH, &max_len);
  if (max_len == 0) {
    set_log_info(NULL);
    return;
  }
  scoped_ptr<char[]> temp(new char[max_len]);
  GLint len = 0;
  glGetProgramInfoLog(service_id_, max_len, &len, temp.get());
  DCHECK(max_len == 0 || len < max_len);
  DCHECK(len == 0 || temp[len] == '\0');
  std::string log(temp.get(), len);
  set_log_info(ProcessLogInfo(log).c_str());
}

void Program::ClearUniforms(
    std::vector<uint8>* zero_buffer) {
  DCHECK(zero_buffer);
  if (uniforms_cleared_) {
    return;
  }
  uniforms_cleared_ = true;
  for (size_t ii = 0; ii < uniform_infos_.size(); ++ii) {
    const UniformInfo& uniform_info = uniform_infos_[ii];
    if (!uniform_info.IsValid()) {
      continue;
    }
    GLint location = uniform_info.element_locations[0];
    GLsizei size = uniform_info.size;
    uint32 unit_size =  GLES2Util::GetGLDataTypeSizeForUniforms(
        uniform_info.type);
    uint32 size_needed = size * unit_size;
    if (size_needed > zero_buffer->size()) {
      zero_buffer->resize(size_needed, 0u);
    }
    const void* zero = &(*zero_buffer)[0];
    switch (uniform_info.type) {
    case GL_FLOAT:
      glUniform1fv(location, size, reinterpret_cast<const GLfloat*>(zero));
      break;
    case GL_FLOAT_VEC2:
      glUniform2fv(location, size, reinterpret_cast<const GLfloat*>(zero));
      break;
    case GL_FLOAT_VEC3:
      glUniform3fv(location, size, reinterpret_cast<const GLfloat*>(zero));
      break;
    case GL_FLOAT_VEC4:
      glUniform4fv(location, size, reinterpret_cast<const GLfloat*>(zero));
      break;
    case GL_INT:
    case GL_BOOL:
    case GL_SAMPLER_2D:
    case GL_SAMPLER_CUBE:
    case GL_SAMPLER_EXTERNAL_OES:
    case GL_SAMPLER_3D_OES:
    case GL_SAMPLER_2D_RECT_ARB:
      glUniform1iv(location, size, reinterpret_cast<const GLint*>(zero));
      break;
    case GL_INT_VEC2:
    case GL_BOOL_VEC2:
      glUniform2iv(location, size, reinterpret_cast<const GLint*>(zero));
      break;
    case GL_INT_VEC3:
    case GL_BOOL_VEC3:
      glUniform3iv(location, size, reinterpret_cast<const GLint*>(zero));
      break;
    case GL_INT_VEC4:
    case GL_BOOL_VEC4:
      glUniform4iv(location, size, reinterpret_cast<const GLint*>(zero));
      break;
    case GL_FLOAT_MAT2:
      glUniformMatrix2fv(
          location, size, false, reinterpret_cast<const GLfloat*>(zero));
      break;
    case GL_FLOAT_MAT3:
      glUniformMatrix3fv(
          location, size, false, reinterpret_cast<const GLfloat*>(zero));
      break;
    case GL_FLOAT_MAT4:
      glUniformMatrix4fv(
          location, size, false, reinterpret_cast<const GLfloat*>(zero));
      break;
    default:
      NOTREACHED();
      break;
    }
  }
}

namespace {

struct UniformData {
  UniformData() : size(-1), type(GL_NONE), location(0), added(false) {
  }
  std::string queried_name;
  std::string corrected_name;
  std::string original_name;
  GLsizei size;
  GLenum type;
  GLint location;
  bool added;
};

struct UniformDataComparer {
  bool operator()(const UniformData& lhs, const UniformData& rhs) const {
    return lhs.queried_name < rhs.queried_name;
  }
};

}  // anonymous namespace

void Program::Update() {
  Reset();
  UpdateLogInfo();
  link_status_ = true;
  uniforms_cleared_ = false;
  GLint num_attribs = 0;
  GLint max_len = 0;
  GLint max_location = -1;
  glGetProgramiv(service_id_, GL_ACTIVE_ATTRIBUTES, &num_attribs);
  glGetProgramiv(service_id_, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &max_len);
  // TODO(gman): Should we check for error?
  scoped_ptr<char[]> name_buffer(new char[max_len]);
  for (GLint ii = 0; ii < num_attribs; ++ii) {
    GLsizei length = 0;
    GLsizei size = 0;
    GLenum type = 0;
    glGetActiveAttrib(
        service_id_, ii, max_len, &length, &size, &type, name_buffer.get());
    DCHECK(max_len == 0 || length < max_len);
    DCHECK(length == 0 || name_buffer[length] == '\0');
    if (!ProgramManager::IsInvalidPrefix(name_buffer.get(), length)) {
      std::string original_name;
      GetVertexAttribData(name_buffer.get(), &original_name, &type);
      // TODO(gman): Should we check for error?
      GLint location = glGetAttribLocation(service_id_, name_buffer.get());
      if (location > max_location) {
        max_location = location;
      }
      attrib_infos_.push_back(
          VertexAttrib(1, type, original_name, location));
      max_attrib_name_length_ = std::max(
          max_attrib_name_length_, static_cast<GLsizei>(original_name.size()));
    }
  }

  // Create attrib location to index map.
  attrib_location_to_index_map_.resize(max_location + 1);
  for (GLint ii = 0; ii <= max_location; ++ii) {
    attrib_location_to_index_map_[ii] = -1;
  }
  for (size_t ii = 0; ii < attrib_infos_.size(); ++ii) {
    const VertexAttrib& info = attrib_infos_[ii];
    attrib_location_to_index_map_[info.location] = ii;
  }

#if !defined(NDEBUG)
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableGPUServiceLoggingGPU)) {
    DVLOG(1) << "----: attribs for service_id: " << service_id();
    for (size_t ii = 0; ii < attrib_infos_.size(); ++ii) {
      const VertexAttrib& info = attrib_infos_[ii];
      DVLOG(1) << ii << ": loc = " << info.location
               << ", size = " << info.size
               << ", type = " << GLES2Util::GetStringEnum(info.type)
               << ", name = " << info.name;
    }
  }
#endif

  max_len = 0;
  GLint num_uniforms = 0;
  glGetProgramiv(service_id_, GL_ACTIVE_UNIFORMS, &num_uniforms);
  glGetProgramiv(service_id_, GL_ACTIVE_UNIFORM_MAX_LENGTH, &max_len);
  name_buffer.reset(new char[max_len]);

  // Reads all the names.
  std::vector<UniformData> uniform_data;
  for (GLint ii = 0; ii < num_uniforms; ++ii) {
    GLsizei length = 0;
    UniformData data;
    glGetActiveUniform(
        service_id_, ii, max_len, &length,
        &data.size, &data.type, name_buffer.get());
    DCHECK(max_len == 0 || length < max_len);
    DCHECK(length == 0 || name_buffer[length] == '\0');
    if (!ProgramManager::IsInvalidPrefix(name_buffer.get(), length)) {
      data.queried_name = std::string(name_buffer.get());
      GetCorrectedUniformData(
          data.queried_name,
          &data.corrected_name, &data.original_name, &data.size, &data.type);
      uniform_data.push_back(data);
    }
  }

  // NOTE: We don't care if 2 uniforms are bound to the same location.
  // One of them will take preference. The spec allows this, same as
  // BindAttribLocation.
  //
  // The reason we don't check is if we were to fail we'd have to
  // restore the previous program but since we've already linked successfully
  // at this point the previous program is gone.

  // Assigns the uniforms with bindings.
  size_t next_available_index = 0;
  for (size_t ii = 0; ii < uniform_data.size(); ++ii) {
    UniformData& data = uniform_data[ii];
    data.location = glGetUniformLocation(
        service_id_, data.queried_name.c_str());
    // remove "[0]"
    std::string short_name;
    int element_index = 0;
    bool good = GetUniformNameSansElement(data.queried_name, &element_index,
                                          &short_name);
    DCHECK(good);
    LocationMap::const_iterator it = bind_uniform_location_map_.find(
        short_name);
    if (it != bind_uniform_location_map_.end()) {
      data.added = AddUniformInfo(
          data.size, data.type, data.location, it->second, data.corrected_name,
          data.original_name, &next_available_index);
    }
  }

  // Assigns the uniforms that were not bound.
  for (size_t ii = 0; ii < uniform_data.size(); ++ii) {
    const UniformData& data = uniform_data[ii];
    if (!data.added) {
      AddUniformInfo(
          data.size, data.type, data.location, -1, data.corrected_name,
          data.original_name, &next_available_index);
    }
  }

#if !defined(NDEBUG)
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableGPUServiceLoggingGPU)) {
    DVLOG(1) << "----: uniforms for service_id: " << service_id();
    for (size_t ii = 0; ii < uniform_infos_.size(); ++ii) {
      const UniformInfo& info = uniform_infos_[ii];
      if (info.IsValid()) {
        DVLOG(1) << ii << ": loc = " << info.element_locations[0]
                 << ", size = " << info.size
                 << ", type = " << GLES2Util::GetStringEnum(info.type)
                 << ", name = " << info.name;
      }
    }
  }
#endif

  valid_ = true;
}

void Program::ExecuteBindAttribLocationCalls() {
  for (LocationMap::const_iterator it = bind_attrib_location_map_.begin();
       it != bind_attrib_location_map_.end(); ++it) {
    const std::string* mapped_name = GetAttribMappedName(it->first);
    if (mapped_name)
      glBindAttribLocation(service_id_, it->second, mapped_name->c_str());
  }
}

bool Program::Link(ShaderManager* manager,
                   Program::VaryingsPackingOption varyings_packing_option,
                   const ShaderCacheCallback& shader_callback) {
  ClearLinkStatus();

  if (!AttachedShadersExist()) {
    set_log_info("missing shaders");
    return false;
  }

  TimeTicks before_time = TimeTicks::Now();
  bool link = true;
  ProgramCache* cache = manager_->program_cache_;
  if (cache) {
    DCHECK(!attached_shaders_[0]->last_compiled_source().empty() &&
           !attached_shaders_[1]->last_compiled_source().empty());
    ProgramCache::LinkedProgramStatus status = cache->GetLinkedProgramStatus(
        attached_shaders_[0]->last_compiled_signature(),
        attached_shaders_[1]->last_compiled_signature(),
        &bind_attrib_location_map_,
        transform_feedback_varyings_,
        transform_feedback_buffer_mode_);

    if (status == ProgramCache::LINK_SUCCEEDED) {
      ProgramCache::ProgramLoadResult success =
          cache->LoadLinkedProgram(service_id(),
                                   attached_shaders_[0].get(),
                                   attached_shaders_[1].get(),
                                   &bind_attrib_location_map_,
                                   transform_feedback_varyings_,
                                   transform_feedback_buffer_mode_,
                                   shader_callback);
      link = success != ProgramCache::PROGRAM_LOAD_SUCCESS;
      UMA_HISTOGRAM_BOOLEAN("GPU.ProgramCache.LoadBinarySuccess", !link);
    }
  }

  if (link) {
    CompileAttachedShaders();

    if (!CanLink()) {
      set_log_info("invalid shaders");
      return false;
    }
    if (DetectAttribLocationBindingConflicts()) {
      set_log_info("glBindAttribLocation() conflicts");
      return false;
    }
    std::string conflicting_name;
    if (DetectUniformsMismatch(&conflicting_name)) {
      std::string info_log = "Uniforms with the same name but different "
                             "type/precision: " + conflicting_name;
      set_log_info(ProcessLogInfo(info_log).c_str());
      return false;
    }
    if (DetectVaryingsMismatch(&conflicting_name)) {
      std::string info_log = "Varyings with the same name but different type, "
                             "or statically used varyings in fragment shader "
                             "are not declared in vertex shader: " +
                             conflicting_name;
      set_log_info(ProcessLogInfo(info_log).c_str());
      return false;
    }
    if (DetectBuiltInInvariantConflicts()) {
      set_log_info("Invariant settings for certain built-in varyings "
                   "have to match");
      return false;
    }
    if (DetectGlobalNameConflicts(&conflicting_name)) {
      std::string info_log = "Name conflicts between an uniform and an "
                             "attribute: " + conflicting_name;
      set_log_info(ProcessLogInfo(info_log).c_str());
      return false;
    }
    if (!CheckVaryingsPacking(varyings_packing_option)) {
      set_log_info("Varyings over maximum register limit");
      return false;
    }

    ExecuteBindAttribLocationCalls();
    before_time = TimeTicks::Now();
    if (cache && gfx::g_driver_gl.ext.b_GL_ARB_get_program_binary) {
      glProgramParameteri(service_id(),
                          PROGRAM_BINARY_RETRIEVABLE_HINT,
                          GL_TRUE);
    }
    glLinkProgram(service_id());
  }

  GLint success = 0;
  glGetProgramiv(service_id(), GL_LINK_STATUS, &success);
  if (success == GL_TRUE) {
    Update();
    if (link) {
      if (cache) {
        cache->SaveLinkedProgram(service_id(),
                                 attached_shaders_[0].get(),
                                 attached_shaders_[1].get(),
                                 &bind_attrib_location_map_,
                                 transform_feedback_varyings_,
                                 transform_feedback_buffer_mode_,
                                 shader_callback);
      }
      UMA_HISTOGRAM_CUSTOM_COUNTS(
          "GPU.ProgramCache.BinaryCacheMissTime",
          static_cast<base::HistogramBase::Sample>(
              (TimeTicks::Now() - before_time).InMicroseconds()),
          0,
          static_cast<base::HistogramBase::Sample>(
              TimeDelta::FromSeconds(10).InMicroseconds()),
          50);
    } else {
      UMA_HISTOGRAM_CUSTOM_COUNTS(
          "GPU.ProgramCache.BinaryCacheHitTime",
          static_cast<base::HistogramBase::Sample>(
              (TimeTicks::Now() - before_time).InMicroseconds()),
          0,
          static_cast<base::HistogramBase::Sample>(
              TimeDelta::FromSeconds(1).InMicroseconds()),
          50);
    }
  } else {
    UpdateLogInfo();
  }
  return success == GL_TRUE;
}

void Program::Validate() {
  if (!IsValid()) {
    set_log_info("program not linked");
    return;
  }
  glValidateProgram(service_id());
  UpdateLogInfo();
}

GLint Program::GetUniformFakeLocation(
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
    if (!info.IsValid()) {
      continue;
    }
    if (info.name == name ||
        (info.is_array &&
         info.name.compare(0, info.name.size() - 3, name) == 0)) {
      return info.fake_location_base;
    } else if (getting_array_location && info.is_array) {
      // Look for an array specification.
      size_t open_pos_2 = info.name.find_last_of('[');
      if (open_pos_2 == open_pos &&
          name.compare(0, open_pos, info.name, 0, open_pos) == 0) {
        if (index >= 0 && index < info.size) {
          DCHECK_GT(static_cast<int>(info.element_locations.size()), index);
          if (info.element_locations[index] == -1)
            return -1;
          return ProgramManager::MakeFakeLocation(
              info.fake_location_base, index);
        }
      }
    }
  }
  return -1;
}

GLint Program::GetAttribLocation(
    const std::string& original_name) const {
  for (GLuint ii = 0; ii < attrib_infos_.size(); ++ii) {
    const VertexAttrib& info = attrib_infos_[ii];
    if (info.name == original_name) {
      return info.location;
    }
  }
  return -1;
}

const Program::UniformInfo*
    Program::GetUniformInfoByFakeLocation(
        GLint fake_location, GLint* real_location, GLint* array_index) const {
  DCHECK(real_location);
  DCHECK(array_index);
  if (fake_location < 0) {
    return NULL;
  }

  GLint uniform_index = GetUniformInfoIndexFromFakeLocation(fake_location);
  if (uniform_index >= 0 &&
      static_cast<size_t>(uniform_index) < uniform_infos_.size()) {
    const UniformInfo& uniform_info = uniform_infos_[uniform_index];
    if (!uniform_info.IsValid()) {
      return NULL;
    }
    GLint element_index = GetArrayElementIndexFromFakeLocation(fake_location);
    if (element_index < uniform_info.size) {
      *real_location = uniform_info.element_locations[element_index];
      *array_index = element_index;
      return &uniform_info;
    }
  }
  return NULL;
}

const std::string* Program::GetAttribMappedName(
    const std::string& original_name) const {
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    Shader* shader = attached_shaders_[ii].get();
    if (shader) {
      const std::string* mapped_name =
          shader->GetAttribMappedName(original_name);
      if (mapped_name)
        return mapped_name;
    }
  }
  return NULL;
}

const std::string* Program::GetOriginalNameFromHashedName(
    const std::string& hashed_name) const {
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    Shader* shader = attached_shaders_[ii].get();
    if (shader) {
      const std::string* original_name =
          shader->GetOriginalNameFromHashedName(hashed_name);
      if (original_name)
        return original_name;
    }
  }
  return NULL;
}

bool Program::SetUniformLocationBinding(
    const std::string& name, GLint location) {
  std::string short_name;
  int element_index = 0;
  if (!GetUniformNameSansElement(name, &element_index, &short_name) ||
      element_index != 0) {
    return false;
  }

  bind_uniform_location_map_[short_name] = location;
  return true;
}

// Note: This is only valid to call right after a program has been linked
// successfully.
void Program::GetCorrectedUniformData(
    const std::string& name,
    std::string* corrected_name, std::string* original_name,
    GLsizei* size, GLenum* type) const {
  DCHECK(corrected_name && original_name && size && type);
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    Shader* shader = attached_shaders_[ii].get();
    if (!shader)
      continue;
    const sh::ShaderVariable* info = NULL;
    const sh::Uniform* uniform = shader->GetUniformInfo(name);
    bool found = false;
    if (uniform)
      found = uniform->findInfoByMappedName(name, &info, original_name);
    if (found) {
      const std::string kArraySpec("[0]");
      if (info->arraySize > 0 && !EndsWith(name, kArraySpec, true)) {
        *corrected_name = name + kArraySpec;
        *original_name += kArraySpec;
      } else {
        *corrected_name = name;
      }
      *type = info->type;
      *size = std::max(1u, info->arraySize);
      return;
    }
  }
  // TODO(zmo): this path should never be reached unless there is a serious
  // bug in the driver or in ANGLE translator.
  *corrected_name = name;
  *original_name = name;
}

void Program::GetVertexAttribData(
    const std::string& name, std::string* original_name, GLenum* type) const {
  DCHECK(original_name);
  DCHECK(type);
  Shader* shader = attached_shaders_[ShaderTypeToIndex(GL_VERTEX_SHADER)].get();
  if (shader) {
    // Vertex attributes can not be arrays or structs (GLSL ES 3.00.4, section
    // 4.3.4, "Input Variables"), so the top level sh::Attribute returns the
    // information we need.
    const sh::Attribute* info = shader->GetAttribInfo(name);
    if (info) {
      *original_name = info->name;
      *type = info->type;
      return;
    }
  }
  // TODO(zmo): this path should never be reached unless there is a serious
  // bug in the driver or in ANGLE translator.
  *original_name = name;
}

bool Program::AddUniformInfo(
        GLsizei size, GLenum type, GLint location, GLint fake_base_location,
        const std::string& name, const std::string& original_name,
        size_t* next_available_index) {
  DCHECK(next_available_index);
  const char* kArraySpec = "[0]";
  size_t uniform_index =
      fake_base_location >= 0 ? fake_base_location : *next_available_index;
  if (uniform_infos_.size() < uniform_index + 1) {
    uniform_infos_.resize(uniform_index + 1);
  }

  // return if this location is already in use.
  if (uniform_infos_[uniform_index].IsValid()) {
    DCHECK_GE(fake_base_location, 0);
    return false;
  }

  uniform_infos_[uniform_index] = UniformInfo(
      size, type, uniform_index, original_name);
  ++num_uniforms_;

  UniformInfo& info = uniform_infos_[uniform_index];
  info.element_locations.resize(size);
  info.element_locations[0] = location;
  DCHECK_GE(size, 0);
  size_t num_texture_units = info.IsSampler() ? static_cast<size_t>(size) : 0u;
  info.texture_units.clear();
  info.texture_units.resize(num_texture_units, 0);

  if (size > 1) {
    // Go through the array element locations looking for a match.
    // We can skip the first element because it's the same as the
    // the location without the array operators.
    size_t array_pos = name.rfind(kArraySpec);
    std::string base_name = name;
    if (name.size() > 3) {
      if (array_pos != name.size() - 3) {
        info.name = name + kArraySpec;
      } else {
        base_name = name.substr(0, name.size() - 3);
      }
    }
    for (GLsizei ii = 1; ii < info.size; ++ii) {
      std::string element_name(base_name + "[" + base::IntToString(ii) + "]");
      info.element_locations[ii] =
          glGetUniformLocation(service_id_, element_name.c_str());
    }
  }

  info.is_array =
     (size > 1 ||
      (info.name.size() > 3 &&
       info.name.rfind(kArraySpec) == info.name.size() - 3));

  if (info.IsSampler()) {
    sampler_indices_.push_back(info.fake_location_base);
  }
  max_uniform_name_length_ =
      std::max(max_uniform_name_length_,
               static_cast<GLsizei>(info.name.size()));

  while (*next_available_index < uniform_infos_.size() &&
         uniform_infos_[*next_available_index].IsValid()) {
    *next_available_index = *next_available_index + 1;
  }

  return true;
}

const Program::UniformInfo*
    Program::GetUniformInfo(
        GLint index) const {
  if (static_cast<size_t>(index) >= uniform_infos_.size()) {
    return NULL;
  }

  const UniformInfo& info = uniform_infos_[index];
  return info.IsValid() ? &info : NULL;
}

bool Program::SetSamplers(
    GLint num_texture_units, GLint fake_location,
    GLsizei count, const GLint* value) {
  if (fake_location < 0) {
    return true;
  }
  GLint uniform_index = GetUniformInfoIndexFromFakeLocation(fake_location);
  if (uniform_index >= 0 &&
      static_cast<size_t>(uniform_index) < uniform_infos_.size()) {
    UniformInfo& info = uniform_infos_[uniform_index];
    if (!info.IsValid()) {
      return false;
    }
    GLint element_index = GetArrayElementIndexFromFakeLocation(fake_location);
    if (element_index < info.size) {
      count = std::min(info.size - element_index, count);
      if (info.IsSampler() && count > 0) {
        for (GLsizei ii = 0; ii < count; ++ii) {
          if (value[ii] < 0 || value[ii] >= num_texture_units) {
            return false;
          }
        }
        std::copy(value, value + count,
                  info.texture_units.begin() + element_index);
        return true;
      }
    }
  }
  return true;
}

void Program::GetProgramiv(GLenum pname, GLint* params) {
  switch (pname) {
    case GL_ACTIVE_ATTRIBUTES:
      *params = attrib_infos_.size();
      break;
    case GL_ACTIVE_ATTRIBUTE_MAX_LENGTH:
      // Notice +1 to accomodate NULL terminator.
      *params = max_attrib_name_length_ + 1;
      break;
    case GL_ACTIVE_UNIFORMS:
      *params = num_uniforms_;
      break;
    case GL_ACTIVE_UNIFORM_MAX_LENGTH:
      // Notice +1 to accomodate NULL terminator.
      *params = max_uniform_name_length_ + 1;
      break;
    case GL_LINK_STATUS:
      *params = link_status_;
      break;
    case GL_INFO_LOG_LENGTH:
      // Notice +1 to accomodate NULL terminator.
      *params = log_info_.get() ? (log_info_->size() + 1) : 0;
      break;
    case GL_DELETE_STATUS:
      *params = deleted_;
      break;
    case GL_VALIDATE_STATUS:
      if (!IsValid()) {
        *params = GL_FALSE;
      } else {
        glGetProgramiv(service_id_, pname, params);
      }
      break;
    default:
      glGetProgramiv(service_id_, pname, params);
      break;
  }
}

bool Program::AttachShader(
    ShaderManager* shader_manager,
    Shader* shader) {
  DCHECK(shader_manager);
  DCHECK(shader);
  int index = ShaderTypeToIndex(shader->shader_type());
  if (attached_shaders_[index].get() != NULL) {
    return false;
  }
  attached_shaders_[index] = scoped_refptr<Shader>(shader);
  shader_manager->UseShader(shader);
  return true;
}

bool Program::DetachShader(
    ShaderManager* shader_manager,
    Shader* shader) {
  DCHECK(shader_manager);
  DCHECK(shader);
  if (attached_shaders_[ShaderTypeToIndex(shader->shader_type())].get() !=
      shader) {
    return false;
  }
  attached_shaders_[ShaderTypeToIndex(shader->shader_type())] = NULL;
  shader_manager->UnuseShader(shader);
  return true;
}

void Program::DetachShaders(ShaderManager* shader_manager) {
  DCHECK(shader_manager);
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    if (attached_shaders_[ii].get()) {
      DetachShader(shader_manager, attached_shaders_[ii].get());
    }
  }
}

void Program::CompileAttachedShaders() {
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    Shader* shader = attached_shaders_[ii].get();
    if (shader) {
      shader->DoCompile();
    }
  }
}

bool Program::AttachedShadersExist() const {
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    if (!attached_shaders_[ii].get())
      return false;
  }
  return true;
}

bool Program::CanLink() const {
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    if (!attached_shaders_[ii].get() || !attached_shaders_[ii]->valid()) {
      return false;
    }
  }
  return true;
}

bool Program::DetectAttribLocationBindingConflicts() const {
  std::set<GLint> location_binding_used;
  for (LocationMap::const_iterator it = bind_attrib_location_map_.begin();
       it != bind_attrib_location_map_.end(); ++it) {
    // Find out if an attribute is statically used in this program's shaders.
    const sh::Attribute* attrib = NULL;
    const std::string* mapped_name = GetAttribMappedName(it->first);
    if (!mapped_name)
      continue;
    for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
      if (!attached_shaders_[ii].get() || !attached_shaders_[ii]->valid())
        continue;
      attrib = attached_shaders_[ii]->GetAttribInfo(*mapped_name);
      if (attrib) {
        if (attrib->staticUse)
          break;
        else
          attrib = NULL;
      }
    }
    if (attrib) {
      size_t num_of_locations = 1;
      switch (attrib->type) {
        case GL_FLOAT_MAT2:
          num_of_locations = 2;
          break;
        case GL_FLOAT_MAT3:
          num_of_locations = 3;
          break;
        case GL_FLOAT_MAT4:
          num_of_locations = 4;
          break;
        default:
          break;
      }
      for (size_t ii = 0; ii < num_of_locations; ++ii) {
        GLint loc = it->second + ii;
        std::pair<std::set<GLint>::iterator, bool> result =
            location_binding_used.insert(loc);
        if (!result.second)
          return true;
      }
    }
  }
  return false;
}

bool Program::DetectUniformsMismatch(std::string* conflicting_name) const {
  typedef std::map<std::string, const sh::Uniform*> UniformPointerMap;
  UniformPointerMap uniform_pointer_map;
  for (int ii = 0; ii < kMaxAttachedShaders; ++ii) {
    const UniformMap& shader_uniforms = attached_shaders_[ii]->uniform_map();
    for (UniformMap::const_iterator iter = shader_uniforms.begin();
         iter != shader_uniforms.end(); ++iter) {
      const std::string& name = iter->first;
      UniformPointerMap::iterator hit = uniform_pointer_map.find(name);
      if (hit == uniform_pointer_map.end()) {
        uniform_pointer_map[name] = &(iter->second);
      } else {
        // If a uniform is in the map, i.e., it has already been declared by
        // another shader, then the type, precision, etc. must match.
        if (hit->second->isSameUniformAtLinkTime(iter->second))
          continue;
        *conflicting_name = name;
        return true;
      }
    }
  }
  return false;
}

bool Program::DetectVaryingsMismatch(std::string* conflicting_name) const {
  DCHECK(attached_shaders_[0].get() &&
         attached_shaders_[0]->shader_type() == GL_VERTEX_SHADER &&
         attached_shaders_[1].get() &&
         attached_shaders_[1]->shader_type() == GL_FRAGMENT_SHADER);
  const VaryingMap* vertex_varyings = &(attached_shaders_[0]->varying_map());
  const VaryingMap* fragment_varyings = &(attached_shaders_[1]->varying_map());

  for (VaryingMap::const_iterator iter = fragment_varyings->begin();
       iter != fragment_varyings->end(); ++iter) {
    const std::string& name = iter->first;
    if (IsBuiltInFragmentVarying(name))
      continue;

    VaryingMap::const_iterator hit = vertex_varyings->find(name);
    if (hit == vertex_varyings->end()) {
      if (iter->second.staticUse) {
        *conflicting_name = name;
        return true;
      }
      continue;
    }

    if (!hit->second.isSameVaryingAtLinkTime(iter->second)) {
      *conflicting_name = name;
      return true;
    }

  }
  return false;
}

bool Program::DetectBuiltInInvariantConflicts() const {
  DCHECK(attached_shaders_[0].get() &&
         attached_shaders_[0]->shader_type() == GL_VERTEX_SHADER &&
         attached_shaders_[1].get() &&
         attached_shaders_[1]->shader_type() == GL_FRAGMENT_SHADER);
  const VaryingMap& vertex_varyings = attached_shaders_[0]->varying_map();
  const VaryingMap& fragment_varyings = attached_shaders_[1]->varying_map();

  bool gl_position_invariant = IsBuiltInInvariant(
      vertex_varyings, "gl_Position");
  bool gl_point_size_invariant = IsBuiltInInvariant(
      vertex_varyings, "gl_PointSize");

  bool gl_frag_coord_invariant = IsBuiltInInvariant(
      fragment_varyings, "gl_FragCoord");
  bool gl_point_coord_invariant = IsBuiltInInvariant(
      fragment_varyings, "gl_PointCoord");

  return ((gl_frag_coord_invariant && !gl_position_invariant) ||
          (gl_point_coord_invariant && !gl_point_size_invariant));
}

bool Program::DetectGlobalNameConflicts(std::string* conflicting_name) const {
  DCHECK(attached_shaders_[0].get() &&
         attached_shaders_[0]->shader_type() == GL_VERTEX_SHADER &&
         attached_shaders_[1].get() &&
         attached_shaders_[1]->shader_type() == GL_FRAGMENT_SHADER);
  const UniformMap* uniforms[2];
  uniforms[0] = &(attached_shaders_[0]->uniform_map());
  uniforms[1] = &(attached_shaders_[1]->uniform_map());
  const AttributeMap* attribs =
      &(attached_shaders_[0]->attrib_map());

  for (AttributeMap::const_iterator iter = attribs->begin();
       iter != attribs->end(); ++iter) {
    for (int ii = 0; ii < 2; ++ii) {
      if (uniforms[ii]->find(iter->first) != uniforms[ii]->end()) {
        *conflicting_name = iter->first;
        return true;
      }
    }
  }
  return false;
}

bool Program::CheckVaryingsPacking(
    Program::VaryingsPackingOption option) const {
  DCHECK(attached_shaders_[0].get() &&
         attached_shaders_[0]->shader_type() == GL_VERTEX_SHADER &&
         attached_shaders_[1].get() &&
         attached_shaders_[1]->shader_type() == GL_FRAGMENT_SHADER);
  const VaryingMap* vertex_varyings = &(attached_shaders_[0]->varying_map());
  const VaryingMap* fragment_varyings = &(attached_shaders_[1]->varying_map());

  std::map<std::string, ShVariableInfo> combined_map;

  for (VaryingMap::const_iterator iter = fragment_varyings->begin();
       iter != fragment_varyings->end(); ++iter) {
    if (!iter->second.staticUse && option == kCountOnlyStaticallyUsed)
      continue;
    if (!IsBuiltInFragmentVarying(iter->first)) {
      VaryingMap::const_iterator vertex_iter =
          vertex_varyings->find(iter->first);
      if (vertex_iter == vertex_varyings->end() ||
          (!vertex_iter->second.staticUse &&
           option == kCountOnlyStaticallyUsed))
        continue;
    }

    ShVariableInfo var;
    var.type = static_cast<sh::GLenum>(iter->second.type);
    var.size = std::max(1u, iter->second.arraySize);
    combined_map[iter->first] = var;
  }

  if (combined_map.size() == 0)
    return true;
  scoped_ptr<ShVariableInfo[]> variables(
      new ShVariableInfo[combined_map.size()]);
  size_t index = 0;
  for (std::map<std::string, ShVariableInfo>::const_iterator iter =
           combined_map.begin();
       iter != combined_map.end(); ++iter) {
    variables[index].type = iter->second.type;
    variables[index].size = iter->second.size;
    ++index;
  }
  return ShCheckVariablesWithinPackingLimits(
      static_cast<int>(manager_->max_varying_vectors()),
      variables.get(),
      combined_map.size());
}

void Program::GetProgramInfo(
    ProgramManager* manager, CommonDecoder::Bucket* bucket) const {
  // NOTE: It seems to me the math in here does not need check for overflow
  // because the data being calucated from has various small limits. The max
  // number of attribs + uniforms is somewhere well under 1024. The maximum size
  // of an identifier is 256 characters.
  uint32 num_locations = 0;
  uint32 total_string_size = 0;

  for (size_t ii = 0; ii < attrib_infos_.size(); ++ii) {
    const VertexAttrib& info = attrib_infos_[ii];
    num_locations += 1;
    total_string_size += info.name.size();
  }

  for (size_t ii = 0; ii < uniform_infos_.size(); ++ii) {
    const UniformInfo& info = uniform_infos_[ii];
    if (info.IsValid()) {
      num_locations += info.element_locations.size();
      total_string_size += info.name.size();
    }
  }

  uint32 num_inputs = attrib_infos_.size() + num_uniforms_;
  uint32 input_size = num_inputs * sizeof(ProgramInput);
  uint32 location_size = num_locations * sizeof(int32);
  uint32 size = sizeof(ProgramInfoHeader) +
      input_size + location_size + total_string_size;

  bucket->SetSize(size);
  ProgramInfoHeader* header = bucket->GetDataAs<ProgramInfoHeader*>(0, size);
  ProgramInput* inputs = bucket->GetDataAs<ProgramInput*>(
      sizeof(ProgramInfoHeader), input_size);
  int32* locations = bucket->GetDataAs<int32*>(
      sizeof(ProgramInfoHeader) + input_size, location_size);
  char* strings = bucket->GetDataAs<char*>(
      sizeof(ProgramInfoHeader) + input_size + location_size,
      total_string_size);
  DCHECK(header);
  DCHECK(inputs);
  DCHECK(locations);
  DCHECK(strings);

  header->link_status = link_status_;
  header->num_attribs = attrib_infos_.size();
  header->num_uniforms = num_uniforms_;

  for (size_t ii = 0; ii < attrib_infos_.size(); ++ii) {
    const VertexAttrib& info = attrib_infos_[ii];
    inputs->size = info.size;
    inputs->type = info.type;
    inputs->location_offset = ComputeOffset(header, locations);
    inputs->name_offset = ComputeOffset(header, strings);
    inputs->name_length = info.name.size();
    *locations++ = info.location;
    memcpy(strings, info.name.c_str(), info.name.size());
    strings += info.name.size();
    ++inputs;
  }

  for (size_t ii = 0; ii < uniform_infos_.size(); ++ii) {
    const UniformInfo& info = uniform_infos_[ii];
    if (info.IsValid()) {
      inputs->size = info.size;
      inputs->type = info.type;
      inputs->location_offset = ComputeOffset(header, locations);
      inputs->name_offset = ComputeOffset(header, strings);
      inputs->name_length = info.name.size();
      DCHECK(static_cast<size_t>(info.size) == info.element_locations.size());
      for (size_t jj = 0; jj < info.element_locations.size(); ++jj) {
        if (info.element_locations[jj] == -1)
          *locations++ = -1;
        else
          *locations++ = ProgramManager::MakeFakeLocation(ii, jj);
      }
      memcpy(strings, info.name.c_str(), info.name.size());
      strings += info.name.size();
      ++inputs;
    }
  }

  DCHECK_EQ(ComputeOffset(header, strings), size);
}

bool Program::GetUniformBlocks(CommonDecoder::Bucket* bucket) const {
  // The data is packed into the bucket in the following order
  //   1) header
  //   2) N entries of block data (except for name and indices)
  //   3) name1, indices1, name2, indices2, ..., nameN, indicesN
  //
  // We query all the data directly through GL calls, assuming they are
  // cheap through MANGLE.

  DCHECK(bucket);
  GLuint program = service_id();

  uint32_t header_size = sizeof(UniformBlocksHeader);
  bucket->SetSize(header_size);  // In case we fail.

  uint32_t num_uniform_blocks = 0;
  GLint param = GL_FALSE;
  // We assume program is a valid program service id.
  glGetProgramiv(program, GL_LINK_STATUS, &param);
  if (param == GL_TRUE) {
    param = 0;
    glGetProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS, &param);
    num_uniform_blocks = static_cast<uint32_t>(param);
  }
  if (num_uniform_blocks == 0) {
    // Although spec allows an implementation to return uniform block info
    // even if a link fails, for consistency, we disallow that.
    return true;
  }

  std::vector<UniformBlockInfo> blocks(num_uniform_blocks);
  base::CheckedNumeric<uint32_t> size = sizeof(UniformBlockInfo);
  size *= num_uniform_blocks;
  uint32_t entry_size = size.ValueOrDefault(0);
  size += header_size;
  std::vector<std::string> names(num_uniform_blocks);
  GLint max_name_length = 0;
  glGetProgramiv(
      program, GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH, &max_name_length);
  std::vector<GLchar> buffer(max_name_length);
  GLsizei length;
  for (uint32_t ii = 0; ii < num_uniform_blocks; ++ii) {
    param = 0;
    glGetActiveUniformBlockiv(program, ii, GL_UNIFORM_BLOCK_BINDING, &param);
    blocks[ii].binding = static_cast<uint32_t>(param);

    param = 0;
    glGetActiveUniformBlockiv(program, ii, GL_UNIFORM_BLOCK_DATA_SIZE, &param);
    blocks[ii].data_size = static_cast<uint32_t>(param);

    blocks[ii].name_offset = size.ValueOrDefault(0);
    param = 0;
    glGetActiveUniformBlockiv(
        program, ii, GL_UNIFORM_BLOCK_NAME_LENGTH, &param);
    DCHECK_GE(max_name_length, param);
    memset(&buffer[0], 0, param);
    length = 0;
    glGetActiveUniformBlockName(
        program, ii, static_cast<GLsizei>(param), &length, &buffer[0]);
    DCHECK_EQ(param, length + 1);
    names[ii] = std::string(&buffer[0], length);
    // TODO(zmo): optimize the name mapping lookup.
    const std::string* original_name = GetOriginalNameFromHashedName(names[ii]);
    if (original_name)
      names[ii] = *original_name;
    blocks[ii].name_length = names[ii].size() + 1;
    size += blocks[ii].name_length;

    param = 0;
    glGetActiveUniformBlockiv(
        program, ii, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &param);
    blocks[ii].active_uniforms = static_cast<uint32_t>(param);
    blocks[ii].active_uniform_offset = size.ValueOrDefault(0);
    base::CheckedNumeric<uint32_t> indices_size = blocks[ii].active_uniforms;
    indices_size *= sizeof(uint32_t);
    if (!indices_size.IsValid())
      return false;
    size += indices_size.ValueOrDefault(0);

    param = 0;
    glGetActiveUniformBlockiv(
        program, ii, GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER, &param);
    blocks[ii].referenced_by_vertex_shader = static_cast<uint32_t>(param);

    param = 0;
    glGetActiveUniformBlockiv(
        program, ii, GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER, &param);
    blocks[ii].referenced_by_fragment_shader = static_cast<uint32_t>(param);
  }
  if (!size.IsValid())
    return false;
  uint32_t total_size = size.ValueOrDefault(0);
  DCHECK_LE(header_size + entry_size, total_size);
  uint32_t data_size = total_size - header_size - entry_size;

  bucket->SetSize(total_size);
  UniformBlocksHeader* header =
      bucket->GetDataAs<UniformBlocksHeader*>(0, header_size);
  UniformBlockInfo* entries = bucket->GetDataAs<UniformBlockInfo*>(
      header_size, entry_size);
  char* data = bucket->GetDataAs<char*>(header_size + entry_size, data_size);
  DCHECK(header);
  DCHECK(entries);
  DCHECK(data);

  // Copy over data for the header and entries.
  header->num_uniform_blocks = num_uniform_blocks;
  memcpy(entries, &blocks[0], entry_size);

  std::vector<GLint> params;
  for (uint32_t ii = 0; ii < num_uniform_blocks; ++ii) {
    // Get active uniform name.
    memcpy(data, names[ii].c_str(), names[ii].length() + 1);
    data += names[ii].length() + 1;

    // Get active uniform indices.
    if (params.size() < blocks[ii].active_uniforms)
      params.resize(blocks[ii].active_uniforms);
    uint32_t num_bytes = blocks[ii].active_uniforms * sizeof(GLint);
    memset(&params[0], 0, num_bytes);
    glGetActiveUniformBlockiv(
        program, ii, GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, &params[0]);
    uint32_t* indices = reinterpret_cast<uint32_t*>(data);
    for (uint32_t uu = 0; uu < blocks[ii].active_uniforms; ++uu) {
      indices[uu] = static_cast<uint32_t>(params[uu]);
    }
    data += num_bytes;
  }
  DCHECK_EQ(ComputeOffset(header, data), total_size);
  return true;
}

bool Program::GetTransformFeedbackVaryings(
    CommonDecoder::Bucket* bucket) const {
  // The data is packed into the bucket in the following order
  //   1) header
  //   2) N entries of varying data (except for name)
  //   3) name1, name2, ..., nameN
  //
  // We query all the data directly through GL calls, assuming they are
  // cheap through MANGLE.

  DCHECK(bucket);
  GLuint program = service_id();

  uint32_t header_size = sizeof(TransformFeedbackVaryingsHeader);
  bucket->SetSize(header_size);  // In case we fail.

  uint32_t num_transform_feedback_varyings = 0;
  GLint param = GL_FALSE;
  // We assume program is a valid program service id.
  glGetProgramiv(program, GL_LINK_STATUS, &param);
  if (param == GL_TRUE) {
    param = 0;
    glGetProgramiv(program, GL_TRANSFORM_FEEDBACK_VARYINGS, &param);
    num_transform_feedback_varyings = static_cast<uint32_t>(param);
  }
  if (num_transform_feedback_varyings == 0) {
    return true;
  }

  std::vector<TransformFeedbackVaryingInfo> varyings(
      num_transform_feedback_varyings);
  base::CheckedNumeric<uint32_t> size = sizeof(TransformFeedbackVaryingInfo);
  size *= num_transform_feedback_varyings;
  uint32_t entry_size = size.ValueOrDefault(0);
  size += header_size;
  std::vector<std::string> names(num_transform_feedback_varyings);
  GLint max_name_length = 0;
  glGetProgramiv(
      program, GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH, &max_name_length);
  if (max_name_length < 1)
    max_name_length = 1;
  std::vector<char> buffer(max_name_length);
  for (uint32_t ii = 0; ii < num_transform_feedback_varyings; ++ii) {
    GLsizei var_size = 0;
    GLsizei var_name_length = 0;
    GLenum var_type = 0;
    glGetTransformFeedbackVarying(
        program, ii, max_name_length,
        &var_name_length, &var_size, &var_type, &buffer[0]);
    varyings[ii].size = static_cast<uint32_t>(var_size);
    varyings[ii].type = static_cast<uint32_t>(var_type);
    varyings[ii].name_offset = static_cast<uint32_t>(size.ValueOrDefault(0));
    DCHECK_GT(max_name_length, var_name_length);
    names[ii] = std::string(&buffer[0], var_name_length);
    // TODO(zmo): optimize the name mapping lookup.
    const std::string* original_name = GetOriginalNameFromHashedName(names[ii]);
    if (original_name)
      names[ii] = *original_name;
    varyings[ii].name_length = names[ii].size() + 1;
    size += names[ii].size();
    size += 1;
  }
  if (!size.IsValid())
    return false;
  uint32_t total_size = size.ValueOrDefault(0);
  DCHECK_LE(header_size + entry_size, total_size);
  uint32_t data_size = total_size - header_size - entry_size;

  bucket->SetSize(total_size);
  TransformFeedbackVaryingsHeader* header =
      bucket->GetDataAs<TransformFeedbackVaryingsHeader*>(0, header_size);
  TransformFeedbackVaryingInfo* entries =
      bucket->GetDataAs<TransformFeedbackVaryingInfo*>(header_size, entry_size);
  char* data = bucket->GetDataAs<char*>(header_size + entry_size, data_size);
  DCHECK(header);
  DCHECK(entries);
  DCHECK(data);

  // Copy over data for the header and entries.
  header->num_transform_feedback_varyings = num_transform_feedback_varyings;
  memcpy(entries, &varyings[0], entry_size);

  for (uint32_t ii = 0; ii < num_transform_feedback_varyings; ++ii) {
    memcpy(data, names[ii].c_str(), names[ii].length() + 1);
    data += names[ii].length() + 1;
  }
  DCHECK_EQ(ComputeOffset(header, data), total_size);
  return true;
}

bool Program::GetUniformsES3(CommonDecoder::Bucket* bucket) const {
  // The data is packed into the bucket in the following order
  //   1) header
  //   2) N entries of UniformES3Info
  //
  // We query all the data directly through GL calls, assuming they are
  // cheap through MANGLE.

  DCHECK(bucket);
  GLuint program = service_id();

  uint32_t header_size = sizeof(UniformsES3Header);
  bucket->SetSize(header_size);  // In case we fail.

  GLsizei count = 0;
  GLint param = GL_FALSE;
  // We assume program is a valid program service id.
  glGetProgramiv(program, GL_LINK_STATUS, &param);
  if (param == GL_TRUE) {
    param = 0;
    glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &count);
  }
  if (count == 0) {
    return true;
  }

  base::CheckedNumeric<uint32_t> size = sizeof(UniformES3Info);
  size *= count;
  uint32_t entry_size = size.ValueOrDefault(0);
  size += header_size;
  if (!size.IsValid())
    return false;
  uint32_t total_size = size.ValueOrDefault(0);
  bucket->SetSize(total_size);
  UniformsES3Header* header =
      bucket->GetDataAs<UniformsES3Header*>(0, header_size);
  DCHECK(header);
  header->num_uniforms = static_cast<uint32_t>(count);

  // Instead of GetDataAs<UniformES3Info*>, we do GetDataAs<int32_t>. This is
  // because struct UniformES3Info is defined as five int32_t.
  // By doing this, we can fill the structs through loops.
  int32_t* entries =
      bucket->GetDataAs<int32_t*>(header_size, entry_size);
  DCHECK(entries);
  const size_t kStride = sizeof(UniformES3Info) / sizeof(int32_t);

  const GLenum kPname[] = {
    GL_UNIFORM_BLOCK_INDEX,
    GL_UNIFORM_OFFSET,
    GL_UNIFORM_ARRAY_STRIDE,
    GL_UNIFORM_MATRIX_STRIDE,
    GL_UNIFORM_IS_ROW_MAJOR,
  };
  const GLint kDefaultValue[] = { -1, -1, -1, -1, 0 };
  const size_t kNumPnames = arraysize(kPname);
  std::vector<GLuint> indices(count);
  for (GLsizei ii = 0; ii < count; ++ii) {
    indices[ii] = ii;
  }
  std::vector<GLint> params(count);
  for (size_t pname_index = 0; pname_index < kNumPnames; ++pname_index) {
    for (GLsizei ii = 0; ii < count; ++ii) {
      params[ii] = kDefaultValue[pname_index];
    }
    glGetActiveUniformsiv(
        program, count, &indices[0], kPname[pname_index], &params[0]);
    for (GLsizei ii = 0; ii < count; ++ii) {
      entries[kStride * ii + pname_index] = params[ii];
    }
  }
  return true;
}

void Program::TransformFeedbackVaryings(GLsizei count,
                                        const char* const* varyings,
                                        GLenum buffer_mode) {
  transform_feedback_varyings_.clear();
  for (GLsizei i = 0; i < count; ++i) {
    transform_feedback_varyings_.push_back(std::string(varyings[i]));
  }
  transform_feedback_buffer_mode_ = buffer_mode;
}

Program::~Program() {
  if (manager_) {
    if (manager_->have_context_) {
      glDeleteProgram(service_id());
    }
    manager_->StopTracking(this);
    manager_ = NULL;
  }
}


ProgramManager::ProgramManager(ProgramCache* program_cache,
                               uint32 max_varying_vectors)
    : program_count_(0),
      have_context_(true),
      program_cache_(program_cache),
      max_varying_vectors_(max_varying_vectors) { }

ProgramManager::~ProgramManager() {
  DCHECK(programs_.empty());
}

void ProgramManager::Destroy(bool have_context) {
  have_context_ = have_context;
  programs_.clear();
}

void ProgramManager::StartTracking(Program* /* program */) {
  ++program_count_;
}

void ProgramManager::StopTracking(Program* /* program */) {
  --program_count_;
}

Program* ProgramManager::CreateProgram(
    GLuint client_id, GLuint service_id) {
  std::pair<ProgramMap::iterator, bool> result =
      programs_.insert(
          std::make_pair(client_id,
                         scoped_refptr<Program>(
                             new Program(this, service_id))));
  DCHECK(result.second);
  return result.first->second.get();
}

Program* ProgramManager::GetProgram(GLuint client_id) {
  ProgramMap::iterator it = programs_.find(client_id);
  return it != programs_.end() ? it->second.get() : NULL;
}

bool ProgramManager::GetClientId(GLuint service_id, GLuint* client_id) const {
  // This doesn't need to be fast. It's only used during slow queries.
  for (ProgramMap::const_iterator it = programs_.begin();
       it != programs_.end(); ++it) {
    if (it->second->service_id() == service_id) {
      *client_id = it->first;
      return true;
    }
  }
  return false;
}

ProgramCache* ProgramManager::program_cache() const {
  return program_cache_;
}

bool ProgramManager::IsOwned(Program* program) {
  for (ProgramMap::iterator it = programs_.begin();
       it != programs_.end(); ++it) {
    if (it->second.get() == program) {
      return true;
    }
  }
  return false;
}

void ProgramManager::RemoveProgramInfoIfUnused(
    ShaderManager* shader_manager, Program* program) {
  DCHECK(shader_manager);
  DCHECK(program);
  DCHECK(IsOwned(program));
  if (program->IsDeleted() && !program->InUse()) {
    program->DetachShaders(shader_manager);
    for (ProgramMap::iterator it = programs_.begin();
         it != programs_.end(); ++it) {
      if (it->second.get() == program) {
        programs_.erase(it);
        return;
      }
    }
    NOTREACHED();
  }
}

void ProgramManager::MarkAsDeleted(
    ShaderManager* shader_manager,
    Program* program) {
  DCHECK(shader_manager);
  DCHECK(program);
  DCHECK(IsOwned(program));
  program->MarkAsDeleted();
  RemoveProgramInfoIfUnused(shader_manager, program);
}

void ProgramManager::UseProgram(Program* program) {
  DCHECK(program);
  DCHECK(IsOwned(program));
  program->IncUseCount();
}

void ProgramManager::UnuseProgram(
    ShaderManager* shader_manager,
    Program* program) {
  DCHECK(shader_manager);
  DCHECK(program);
  DCHECK(IsOwned(program));
  program->DecUseCount();
  RemoveProgramInfoIfUnused(shader_manager, program);
}

void ProgramManager::ClearUniforms(Program* program) {
  DCHECK(program);
  program->ClearUniforms(&zero_);
}

int32 ProgramManager::MakeFakeLocation(int32 index, int32 element) {
  return index + element * 0x10000;
}

}  // namespace gles2
}  // namespace gpu
