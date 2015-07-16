// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_MEMORY_PROGRAM_CACHE_H_
#define GPU_COMMAND_BUFFER_SERVICE_MEMORY_PROGRAM_CACHE_H_

#include <map>
#include <string>

#include "base/containers/hash_tables.h"
#include "base/containers/mru_cache.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/program_cache.h"

namespace gpu {
namespace gles2 {

// Program cache that stores binaries completely in-memory
class GPU_EXPORT MemoryProgramCache : public ProgramCache {
 public:
  MemoryProgramCache();
  explicit MemoryProgramCache(const size_t max_cache_size_bytes);
  ~MemoryProgramCache() override;

  ProgramLoadResult LoadLinkedProgram(
      GLuint program,
      Shader* shader_a,
      Shader* shader_b,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      const ShaderCacheCallback& shader_callback) override;
  void SaveLinkedProgram(
      GLuint program,
      const Shader* shader_a,
      const Shader* shader_b,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      const ShaderCacheCallback& shader_callback) override;

  void LoadProgram(const std::string& program) override;

 private:
  void ClearBackend() override;

  class ProgramCacheValue : public base::RefCounted<ProgramCacheValue> {
   public:
    ProgramCacheValue(GLsizei length,
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
                      MemoryProgramCache* program_cache);

    GLsizei length() const {
      return length_;
    }

    GLenum format() const {
      return format_;
    }

    const char* data() const {
      return data_.get();
    }

    const std::string& shader_0_hash() const {
      return shader_0_hash_;
    }

    const AttributeMap& attrib_map_0() const {
      return attrib_map_0_;
    }

    const UniformMap& uniform_map_0() const {
      return uniform_map_0_;
    }

    const VaryingMap& varying_map_0() const {
      return varying_map_0_;
    }

    const std::string& shader_1_hash() const {
      return shader_1_hash_;
    }

    const AttributeMap& attrib_map_1() const {
      return attrib_map_1_;
    }

    const UniformMap& uniform_map_1() const {
      return uniform_map_1_;
    }

    const VaryingMap& varying_map_1() const {
      return varying_map_1_;
    }

   private:
    friend class base::RefCounted<ProgramCacheValue>;

    ~ProgramCacheValue();

    const GLsizei length_;
    const GLenum format_;
    const scoped_ptr<const char[]> data_;
    const std::string program_hash_;
    const std::string shader_0_hash_;
    const AttributeMap attrib_map_0_;
    const UniformMap uniform_map_0_;
    const VaryingMap varying_map_0_;
    const std::string shader_1_hash_;
    const AttributeMap attrib_map_1_;
    const UniformMap uniform_map_1_;
    const VaryingMap varying_map_1_;
    MemoryProgramCache* const program_cache_;

    DISALLOW_COPY_AND_ASSIGN(ProgramCacheValue);
  };

  friend class ProgramCacheValue;

  typedef base::MRUCache<std::string,
                         scoped_refptr<ProgramCacheValue> > ProgramMRUCache;

  const size_t max_size_bytes_;
  size_t curr_size_bytes_;
  ProgramMRUCache store_;

  DISALLOW_COPY_AND_ASSIGN(MemoryProgramCache);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_MEMORY_PROGRAM_CACHE_H_
