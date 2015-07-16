// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_PROGRAM_CACHE_H_
#define GPU_COMMAND_BUFFER_SERVICE_PROGRAM_CACHE_H_

#include <map>
#include <string>

#include "base/containers/hash_tables.h"
#include "base/sha1.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/shader_manager.h"

namespace gpu {
namespace gles2 {

class Shader;

// Program cache base class for caching linked gpu programs
class GPU_EXPORT ProgramCache {
 public:
  static const size_t kHashLength = base::kSHA1Length;

  typedef std::map<std::string, GLint> LocationMap;

  enum LinkedProgramStatus {
    LINK_UNKNOWN,
    LINK_SUCCEEDED
  };

  enum ProgramLoadResult {
    PROGRAM_LOAD_FAILURE,
    PROGRAM_LOAD_SUCCESS
  };

  ProgramCache();
  virtual ~ProgramCache();

  LinkedProgramStatus GetLinkedProgramStatus(
      const std::string& shader_signature_a,
      const std::string& shader_signature_b,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode) const;

  // Loads the linked program from the cache.  If the program is not found or
  // there was an error, PROGRAM_LOAD_FAILURE should be returned.
  virtual ProgramLoadResult LoadLinkedProgram(
      GLuint program,
      Shader* shader_a,
      Shader* shader_b,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      const ShaderCacheCallback& shader_callback) = 0;

  // Saves the program into the cache.  If successful, the implementation should
  // call LinkedProgramCacheSuccess.
  virtual void SaveLinkedProgram(
      GLuint program,
      const Shader* shader_a,
      const Shader* shader_b,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      const ShaderCacheCallback& shader_callback) = 0;

  virtual void LoadProgram(const std::string& program) = 0;

  // clears the cache
  void Clear();

  // Only for testing
  void LinkedProgramCacheSuccess(const std::string& shader_signature_a,
       const std::string& shader_signature_b,
       const LocationMap* bind_attrib_location_map,
       const std::vector<std::string>& transform_feedback_varyings,
       GLenum transform_feedback_buffer_mode);

 protected:
  // called by implementing class after a shader was successfully cached
  void LinkedProgramCacheSuccess(const std::string& program_hash);

  // result is not null terminated
  void ComputeShaderHash(const std::string& shader,
                         char* result) const;

  // result is not null terminated.  hashed shaders are expected to be
  // kHashLength in length
  void ComputeProgramHash(
      const char* hashed_shader_0,
      const char* hashed_shader_1,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      char* result) const;

  void Evict(const std::string& program_hash);

 private:
  typedef base::hash_map<std::string,
                         LinkedProgramStatus> LinkStatusMap;

  // called to clear the backend cache
  virtual void ClearBackend() = 0;

  LinkStatusMap link_status_;

  DISALLOW_COPY_AND_ASSIGN(ProgramCache);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_PROGRAM_CACHE_H_
