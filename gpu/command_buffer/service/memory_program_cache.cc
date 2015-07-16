// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/memory_program_cache.h"

#include "base/base64.h"
#include "base/command_line.h"
#include "base/metrics/histogram.h"
#include "base/sha1.h"
#include "base/strings/string_number_conversions.h"
#include "gpu/command_buffer/common/constants.h"
#include "gpu/command_buffer/service/disk_cache_proto.pb.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/gpu_switches.h"
#include "gpu/command_buffer/service/shader_manager.h"
#include "ui/gl/gl_bindings.h"

namespace {

size_t GetCacheSizeBytes() {
  const base::CommandLine* command_line =
      base::CommandLine::ForCurrentProcess();
  if (command_line->HasSwitch(switches::kGpuProgramCacheSizeKb)) {
    size_t size;
    if (base::StringToSizeT(
        command_line->GetSwitchValueNative(switches::kGpuProgramCacheSizeKb),
        &size))
      return size * 1024;
  }
  return gpu::kDefaultMaxProgramCacheMemoryBytes;
}

}  // anonymous namespace

namespace gpu {
namespace gles2 {

namespace {

enum ShaderMapType {
  ATTRIB_MAP = 0,
  UNIFORM_MAP,
  VARYING_MAP
};

void FillShaderVariableProto(
    ShaderVariableProto* proto, const sh::ShaderVariable& variable) {
  proto->set_type(variable.type);
  proto->set_precision(variable.precision);
  proto->set_name(variable.name);
  proto->set_mapped_name(variable.mappedName);
  proto->set_array_size(variable.arraySize);
  proto->set_static_use(variable.staticUse);
  for (size_t ii = 0; ii < variable.fields.size(); ++ii) {
    ShaderVariableProto* field = proto->add_fields();
    FillShaderVariableProto(field, variable.fields[ii]);
  }
  proto->set_struct_name(variable.structName);
}

void FillShaderAttributeProto(
    ShaderAttributeProto* proto, const sh::Attribute& attrib) {
  FillShaderVariableProto(proto->mutable_basic(), attrib);
  proto->set_location(attrib.location);
}

void FillShaderUniformProto(
    ShaderUniformProto* proto, const sh::Uniform& uniform) {
  FillShaderVariableProto(proto->mutable_basic(), uniform);
}

void FillShaderVaryingProto(
    ShaderVaryingProto* proto, const sh::Varying& varying) {
  FillShaderVariableProto(proto->mutable_basic(), varying);
  proto->set_interpolation(varying.interpolation);
  proto->set_is_invariant(varying.isInvariant);
}

void FillShaderProto(ShaderProto* proto, const char* sha,
                     const Shader* shader) {
  proto->set_sha(sha, gpu::gles2::ProgramCache::kHashLength);
  for (AttributeMap::const_iterator iter = shader->attrib_map().begin();
       iter != shader->attrib_map().end(); ++iter) {
    ShaderAttributeProto* info = proto->add_attribs();
    FillShaderAttributeProto(info, iter->second);
  }
  for (UniformMap::const_iterator iter = shader->uniform_map().begin();
       iter != shader->uniform_map().end(); ++iter) {
    ShaderUniformProto* info = proto->add_uniforms();
    FillShaderUniformProto(info, iter->second);
  }
  for (VaryingMap::const_iterator iter = shader->varying_map().begin();
       iter != shader->varying_map().end(); ++iter) {
    ShaderVaryingProto* info = proto->add_varyings();
    FillShaderVaryingProto(info, iter->second);
  }
}

void RetrieveShaderVariableInfo(
    const ShaderVariableProto& proto, sh::ShaderVariable* variable) {
  variable->type = proto.type();
  variable->precision = proto.precision();
  variable->name = proto.name();
  variable->mappedName = proto.mapped_name();
  variable->arraySize = proto.array_size();
  variable->staticUse = proto.static_use();
  variable->fields.resize(proto.fields_size());
  for (int ii = 0; ii < proto.fields_size(); ++ii)
    RetrieveShaderVariableInfo(proto.fields(ii), &(variable->fields[ii]));
  variable->structName = proto.struct_name();
}

void RetrieveShaderAttributeInfo(
    const ShaderAttributeProto& proto, AttributeMap* map) {
  sh::Attribute attrib;
  RetrieveShaderVariableInfo(proto.basic(), &attrib);
  attrib.location = proto.location();
  (*map)[proto.basic().mapped_name()] = attrib;
}

void RetrieveShaderUniformInfo(
    const ShaderUniformProto& proto, UniformMap* map) {
  sh::Uniform uniform;
  RetrieveShaderVariableInfo(proto.basic(), &uniform);
  (*map)[proto.basic().mapped_name()] = uniform;
}

void RetrieveShaderVaryingInfo(
    const ShaderVaryingProto& proto, VaryingMap* map) {
  sh::Varying varying;
  RetrieveShaderVariableInfo(proto.basic(), &varying);
  varying.interpolation = static_cast<sh::InterpolationType>(
      proto.interpolation());
  varying.isInvariant = proto.is_invariant();
  (*map)[proto.basic().mapped_name()] = varying;
}

void RunShaderCallback(const ShaderCacheCallback& callback,
                       GpuProgramProto* proto,
                       std::string sha_string) {
  std::string shader;
  proto->SerializeToString(&shader);

  std::string key;
  base::Base64Encode(sha_string, &key);
  callback.Run(key, shader);
}

}  // namespace

MemoryProgramCache::MemoryProgramCache()
    : max_size_bytes_(GetCacheSizeBytes()),
      curr_size_bytes_(0),
      store_(ProgramMRUCache::NO_AUTO_EVICT) {
}

MemoryProgramCache::MemoryProgramCache(const size_t max_cache_size_bytes)
    : max_size_bytes_(max_cache_size_bytes),
      curr_size_bytes_(0),
      store_(ProgramMRUCache::NO_AUTO_EVICT) {
}

MemoryProgramCache::~MemoryProgramCache() {}

void MemoryProgramCache::ClearBackend() {
  store_.Clear();
  DCHECK_EQ(0U, curr_size_bytes_);
}

ProgramCache::ProgramLoadResult MemoryProgramCache::LoadLinkedProgram(
    GLuint program,
    Shader* shader_a,
    Shader* shader_b,
    const LocationMap* bind_attrib_location_map,
    const std::vector<std::string>& transform_feedback_varyings,
    GLenum transform_feedback_buffer_mode,
    const ShaderCacheCallback& shader_callback) {
  char a_sha[kHashLength];
  char b_sha[kHashLength];
  DCHECK(shader_a && !shader_a->last_compiled_source().empty() &&
         shader_b && !shader_b->last_compiled_source().empty());
  ComputeShaderHash(
      shader_a->last_compiled_signature(), a_sha);
  ComputeShaderHash(
      shader_b->last_compiled_signature(), b_sha);

  char sha[kHashLength];
  ComputeProgramHash(a_sha,
                     b_sha,
                     bind_attrib_location_map,
                     transform_feedback_varyings,
                     transform_feedback_buffer_mode,
                     sha);
  const std::string sha_string(sha, kHashLength);

  ProgramMRUCache::iterator found = store_.Get(sha_string);
  if (found == store_.end()) {
    return PROGRAM_LOAD_FAILURE;
  }
  const scoped_refptr<ProgramCacheValue> value = found->second;
  glProgramBinary(program,
                  value->format(),
                  static_cast<const GLvoid*>(value->data()),
                  value->length());
  GLint success = 0;
  glGetProgramiv(program, GL_LINK_STATUS, &success);
  if (success == GL_FALSE) {
    return PROGRAM_LOAD_FAILURE;
  }
  shader_a->set_attrib_map(value->attrib_map_0());
  shader_a->set_uniform_map(value->uniform_map_0());
  shader_a->set_varying_map(value->varying_map_0());
  shader_b->set_attrib_map(value->attrib_map_1());
  shader_b->set_uniform_map(value->uniform_map_1());
  shader_b->set_varying_map(value->varying_map_1());

  if (!shader_callback.is_null() &&
      !base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kDisableGpuShaderDiskCache)) {
    scoped_ptr<GpuProgramProto> proto(
        GpuProgramProto::default_instance().New());
    proto->set_sha(sha, kHashLength);
    proto->set_format(value->format());
    proto->set_program(value->data(), value->length());

    FillShaderProto(proto->mutable_vertex_shader(), a_sha, shader_a);
    FillShaderProto(proto->mutable_fragment_shader(), b_sha, shader_b);
    RunShaderCallback(shader_callback, proto.get(), sha_string);
  }

  return PROGRAM_LOAD_SUCCESS;
}

void MemoryProgramCache::SaveLinkedProgram(
    GLuint program,
    const Shader* shader_a,
    const Shader* shader_b,
    const LocationMap* bind_attrib_location_map,
    const std::vector<std::string>& transform_feedback_varyings,
    GLenum transform_feedback_buffer_mode,
    const ShaderCacheCallback& shader_callback) {
  GLenum format;
  GLsizei length = 0;
  glGetProgramiv(program, GL_PROGRAM_BINARY_LENGTH_OES, &length);
  if (length == 0 || static_cast<unsigned int>(length) > max_size_bytes_) {
    return;
  }
  scoped_ptr<char[]> binary(new char[length]);
  glGetProgramBinary(program,
                     length,
                     NULL,
                     &format,
                     binary.get());
  UMA_HISTOGRAM_COUNTS("GPU.ProgramCache.ProgramBinarySizeBytes", length);

  char a_sha[kHashLength];
  char b_sha[kHashLength];
  DCHECK(shader_a && !shader_a->last_compiled_source().empty() &&
         shader_b && !shader_b->last_compiled_source().empty());
  ComputeShaderHash(
      shader_a->last_compiled_signature(), a_sha);
  ComputeShaderHash(
      shader_b->last_compiled_signature(), b_sha);

  char sha[kHashLength];
  ComputeProgramHash(a_sha,
                     b_sha,
                     bind_attrib_location_map,
                     transform_feedback_varyings,
                     transform_feedback_buffer_mode,
                     sha);
  const std::string sha_string(sha, sizeof(sha));

  UMA_HISTOGRAM_COUNTS("GPU.ProgramCache.MemorySizeBeforeKb",
                       curr_size_bytes_ / 1024);

  // Evict any cached program with the same key in favor of the least recently
  // accessed.
  ProgramMRUCache::iterator existing = store_.Peek(sha_string);
  if(existing != store_.end())
    store_.Erase(existing);

  while (curr_size_bytes_ + length > max_size_bytes_) {
    DCHECK(!store_.empty());
    store_.Erase(store_.rbegin());
  }

  if (!shader_callback.is_null() &&
      !base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kDisableGpuShaderDiskCache)) {
    scoped_ptr<GpuProgramProto> proto(
        GpuProgramProto::default_instance().New());
    proto->set_sha(sha, kHashLength);
    proto->set_format(format);
    proto->set_program(binary.get(), length);

    FillShaderProto(proto->mutable_vertex_shader(), a_sha, shader_a);
    FillShaderProto(proto->mutable_fragment_shader(), b_sha, shader_b);
    RunShaderCallback(shader_callback, proto.get(), sha_string);
  }

  store_.Put(sha_string,
             new ProgramCacheValue(length,
                                   format,
                                   binary.release(),
                                   sha_string,
                                   a_sha,
                                   shader_a->attrib_map(),
                                   shader_a->uniform_map(),
                                   shader_a->varying_map(),
                                   b_sha,
                                   shader_b->attrib_map(),
                                   shader_b->uniform_map(),
                                   shader_b->varying_map(),
                                   this));

  UMA_HISTOGRAM_COUNTS("GPU.ProgramCache.MemorySizeAfterKb",
                       curr_size_bytes_ / 1024);
}

void MemoryProgramCache::LoadProgram(const std::string& program) {
  scoped_ptr<GpuProgramProto> proto(GpuProgramProto::default_instance().New());
  if (proto->ParseFromString(program)) {
    AttributeMap vertex_attribs;
    UniformMap vertex_uniforms;
    VaryingMap vertex_varyings;
    for (int i = 0; i < proto->vertex_shader().attribs_size(); i++) {
      RetrieveShaderAttributeInfo(proto->vertex_shader().attribs(i),
                                  &vertex_attribs);
    }
    for (int i = 0; i < proto->vertex_shader().uniforms_size(); i++) {
      RetrieveShaderUniformInfo(proto->vertex_shader().uniforms(i),
                                &vertex_uniforms);
    }
    for (int i = 0; i < proto->vertex_shader().varyings_size(); i++) {
      RetrieveShaderVaryingInfo(proto->vertex_shader().varyings(i),
                                &vertex_varyings);
    }

    AttributeMap fragment_attribs;
    UniformMap fragment_uniforms;
    VaryingMap fragment_varyings;
    for (int i = 0; i < proto->fragment_shader().attribs_size(); i++) {
      RetrieveShaderAttributeInfo(proto->fragment_shader().attribs(i),
                                  &fragment_attribs);
    }
    for (int i = 0; i < proto->fragment_shader().uniforms_size(); i++) {
      RetrieveShaderUniformInfo(proto->fragment_shader().uniforms(i),
                                &fragment_uniforms);
    }
    for (int i = 0; i < proto->fragment_shader().varyings_size(); i++) {
      RetrieveShaderVaryingInfo(proto->fragment_shader().varyings(i),
                                &fragment_varyings);
    }

    scoped_ptr<char[]> binary(new char[proto->program().length()]);
    memcpy(binary.get(), proto->program().c_str(), proto->program().length());

    store_.Put(proto->sha(),
               new ProgramCacheValue(proto->program().length(),
                                     proto->format(),
                                     binary.release(),
                                     proto->sha(),
                                     proto->vertex_shader().sha().c_str(),
                                     vertex_attribs,
                                     vertex_uniforms,
                                     vertex_varyings,
                                     proto->fragment_shader().sha().c_str(),
                                     fragment_attribs,
                                     fragment_uniforms,
                                     fragment_varyings,
                                     this));

    UMA_HISTOGRAM_COUNTS("GPU.ProgramCache.MemorySizeAfterKb",
                         curr_size_bytes_ / 1024);
  } else {
    LOG(ERROR) << "Failed to parse proto file.";
  }
}

MemoryProgramCache::ProgramCacheValue::ProgramCacheValue(
    GLsizei length,
    GLenum format,
    const char* data,
    const std::string& program_hash,
    const char* shader_0_hash,
    const AttributeMap& attrib_map_0,
    const UniformMap& uniform_map_0,
    const VaryingMap& varying_map_0,
    const char* shader_1_hash,
    const AttributeMap& attrib_map_1,
    const UniformMap& uniform_map_1,
    const VaryingMap& varying_map_1,
    MemoryProgramCache* program_cache)
    : length_(length),
      format_(format),
      data_(data),
      program_hash_(program_hash),
      shader_0_hash_(shader_0_hash, kHashLength),
      attrib_map_0_(attrib_map_0),
      uniform_map_0_(uniform_map_0),
      varying_map_0_(varying_map_0),
      shader_1_hash_(shader_1_hash, kHashLength),
      attrib_map_1_(attrib_map_1),
      uniform_map_1_(uniform_map_1),
      varying_map_1_(varying_map_1),
      program_cache_(program_cache) {
  program_cache_->curr_size_bytes_ += length_;
  program_cache_->LinkedProgramCacheSuccess(program_hash);
}

MemoryProgramCache::ProgramCacheValue::~ProgramCacheValue() {
  program_cache_->curr_size_bytes_ -= length_;
  program_cache_->Evict(program_hash_);
}

}  // namespace gles2
}  // namespace gpu
