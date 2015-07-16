// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/program_cache.h"

#include <string>
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/shader_manager.h"

namespace gpu {
namespace gles2 {

ProgramCache::ProgramCache() {}
ProgramCache::~ProgramCache() {}

void ProgramCache::Clear() {
  ClearBackend();
  link_status_.clear();
}

ProgramCache::LinkedProgramStatus ProgramCache::GetLinkedProgramStatus(
    const std::string& shader_signature_a,
    const std::string& shader_signature_b,
    const std::map<std::string, GLint>* bind_attrib_location_map,
    const std::vector<std::string>& transform_feedback_varyings,
    GLenum transform_feedback_buffer_mode) const {
  char a_sha[kHashLength];
  char b_sha[kHashLength];
  ComputeShaderHash(shader_signature_a, a_sha);
  ComputeShaderHash(shader_signature_b, b_sha);

  char sha[kHashLength];
  ComputeProgramHash(a_sha,
                     b_sha,
                     bind_attrib_location_map,
                     transform_feedback_varyings,
                     transform_feedback_buffer_mode,
                     sha);
  const std::string sha_string(sha, kHashLength);

  LinkStatusMap::const_iterator found = link_status_.find(sha_string);
  if (found == link_status_.end()) {
    return ProgramCache::LINK_UNKNOWN;
  } else {
    return found->second;
  }
}

void ProgramCache::LinkedProgramCacheSuccess(
    const std::string& shader_signature_a,
    const std::string& shader_signature_b,
    const LocationMap* bind_attrib_location_map,
    const std::vector<std::string>& transform_feedback_varyings,
    GLenum transform_feedback_buffer_mode) {
  char a_sha[kHashLength];
  char b_sha[kHashLength];
  ComputeShaderHash(shader_signature_a, a_sha);
  ComputeShaderHash(shader_signature_b, b_sha);
  char sha[kHashLength];
  ComputeProgramHash(a_sha,
                     b_sha,
                     bind_attrib_location_map,
                     transform_feedback_varyings,
                     transform_feedback_buffer_mode,
                     sha);
  const std::string sha_string(sha, kHashLength);

  LinkedProgramCacheSuccess(sha_string);
}

void ProgramCache::LinkedProgramCacheSuccess(const std::string& program_hash) {
  link_status_[program_hash] = LINK_SUCCEEDED;
}

void ProgramCache::ComputeShaderHash(
    const std::string& str,
    char* result) const {
  base::SHA1HashBytes(reinterpret_cast<const unsigned char*>(str.c_str()),
                      str.length(), reinterpret_cast<unsigned char*>(result));
}

void ProgramCache::Evict(const std::string& program_hash) {
  link_status_.erase(program_hash);
}

namespace {
size_t CalculateMapSize(const std::map<std::string, GLint>* map) {
  if (!map) {
    return 0;
  }
  size_t total = 0;
  for (auto it = map->begin(); it != map->end(); ++it) {
    total += 4 + it->first.length();
  }
  return total;
}

size_t CalculateVaryingsSize(const std::vector<std::string>& varyings) {
  size_t total = 0;
  for (auto& varying : varyings) {
    total += 1 + varying.length();
  }
  return total;
}
}  // anonymous namespace

void ProgramCache::ComputeProgramHash(
    const char* hashed_shader_0,
    const char* hashed_shader_1,
    const std::map<std::string, GLint>* bind_attrib_location_map,
    const std::vector<std::string>& transform_feedback_varyings,
    GLenum transform_feedback_buffer_mode,
    char* result) const {
  const size_t shader0_size = kHashLength;
  const size_t shader1_size = kHashLength;
  const size_t map_size = CalculateMapSize(bind_attrib_location_map);
  const size_t var_size = CalculateVaryingsSize(transform_feedback_varyings);
  const size_t total_size = shader0_size + shader1_size + map_size + var_size
      + sizeof(transform_feedback_buffer_mode);

  scoped_ptr<unsigned char[]> buffer(new unsigned char[total_size]);
  memcpy(buffer.get(), hashed_shader_0, shader0_size);
  memcpy(&buffer[shader0_size], hashed_shader_1, shader1_size);
  size_t current_pos = shader0_size + shader1_size;
  if (map_size != 0) {
    // copy our map
    for (auto it = bind_attrib_location_map->begin();
         it != bind_attrib_location_map->end();
         ++it) {
      const size_t name_size = it->first.length();
      memcpy(&buffer.get()[current_pos], it->first.c_str(), name_size);
      current_pos += name_size;
      const GLint value = it->second;
      buffer[current_pos++] = value >> 24;
      buffer[current_pos++] = static_cast<unsigned char>(value >> 16);
      buffer[current_pos++] = static_cast<unsigned char>(value >> 8);
      buffer[current_pos++] = static_cast<unsigned char>(value);
    }
  }

  if (var_size != 0) {
    // copy transform feedback varyings
    for (auto& varying : transform_feedback_varyings) {
      const size_t name_size = varying.length();
      memcpy(&buffer.get()[current_pos], varying.c_str(), name_size);
      current_pos += name_size;
      buffer[current_pos++] = ' ';
    }
  }
  memcpy(&buffer[current_pos], &transform_feedback_buffer_mode,
      sizeof(transform_feedback_buffer_mode));
  base::SHA1HashBytes(buffer.get(),
                      total_size, reinterpret_cast<unsigned char*>(result));
}

}  // namespace gles2
}  // namespace gpu
