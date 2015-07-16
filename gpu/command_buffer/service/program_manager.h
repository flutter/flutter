// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_PROGRAM_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_PROGRAM_MANAGER_H_

#include <map>
#include <string>
#include <vector>
#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "gpu/command_buffer/service/common_decoder.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "gpu/command_buffer/service/shader_manager.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

class ProgramCache;
class ProgramManager;
class Shader;
class ShaderManager;

// This is used to track which attributes a particular program needs
// so we can verify at glDrawXXX time that every attribute is either disabled
// or if enabled that it points to a valid source.
class GPU_EXPORT Program : public base::RefCounted<Program> {
 public:
  static const int kMaxAttachedShaders = 2;

  enum VaryingsPackingOption {
    kCountOnlyStaticallyUsed,
    kCountAll
  };

  enum UniformApiType {
    kUniformNone = 0,
    kUniform1i = 1 << 0,
    kUniform2i = 1 << 1,
    kUniform3i = 1 << 2,
    kUniform4i = 1 << 3,
    kUniform1f = 1 << 4,
    kUniform2f = 1 << 5,
    kUniform3f = 1 << 6,
    kUniform4f = 1 << 7,
    kUniformMatrix2f = 1 << 8,
    kUniformMatrix3f = 1 << 9,
    kUniformMatrix4f = 1 << 10,
  };

  struct UniformInfo {
    UniformInfo();
    UniformInfo(
        GLsizei _size, GLenum _type, GLint _fake_location_base,
        const std::string& _name);
    ~UniformInfo();

    bool IsValid() const {
      return size != 0;
    }

    bool IsSampler() const {
      return type == GL_SAMPLER_2D || type == GL_SAMPLER_2D_RECT_ARB ||
             type == GL_SAMPLER_CUBE || type == GL_SAMPLER_EXTERNAL_OES;
    }

    GLsizei size;
    GLenum type;
    uint32 accepts_api_type;
    GLint fake_location_base;
    bool is_array;
    std::string name;
    std::vector<GLint> element_locations;
    std::vector<GLuint> texture_units;
  };
  struct VertexAttrib {
    VertexAttrib(GLsizei _size, GLenum _type, const std::string& _name,
                 GLint _location)
        : size(_size),
          type(_type),
          location(_location),
          name(_name) {
    }
    GLsizei size;
    GLenum type;
    GLint location;
    std::string name;
  };

  typedef std::vector<UniformInfo> UniformInfoVector;
  typedef std::vector<VertexAttrib> AttribInfoVector;
  typedef std::vector<int> SamplerIndices;
  typedef std::map<std::string, GLint> LocationMap;

  Program(ProgramManager* manager, GLuint service_id);

  GLuint service_id() const {
    return service_id_;
  }

  const SamplerIndices& sampler_indices() {
    return sampler_indices_;
  }

  const AttribInfoVector& GetAttribInfos() const {
    return attrib_infos_;
  }

  const VertexAttrib* GetAttribInfo(GLint index) const {
    return (static_cast<size_t>(index) < attrib_infos_.size()) ?
       &attrib_infos_[index] : NULL;
  }

  GLint GetAttribLocation(const std::string& original_name) const;

  const VertexAttrib* GetAttribInfoByLocation(GLuint location) const {
    if (location < attrib_location_to_index_map_.size()) {
      GLint index = attrib_location_to_index_map_[location];
      if (index >= 0) {
        return &attrib_infos_[index];
      }
    }
    return NULL;
  }

  const UniformInfo* GetUniformInfo(GLint index) const;

  // If the original name is not found, return NULL.
  const std::string* GetAttribMappedName(
      const std::string& original_name) const;

  // If the hashed name is not found, return NULL.
  const std::string* GetOriginalNameFromHashedName(
      const std::string& hashed_name) const;

  // Gets the fake location of a uniform by name.
  GLint GetUniformFakeLocation(const std::string& name) const;

  // Gets the UniformInfo of a uniform by location.
  const UniformInfo* GetUniformInfoByFakeLocation(
      GLint fake_location, GLint* real_location, GLint* array_index) const;

  // Gets all the program info.
  void GetProgramInfo(
      ProgramManager* manager, CommonDecoder::Bucket* bucket) const;

  // Gets all the UniformBlock info.
  // Return false on overflow.
  bool GetUniformBlocks(CommonDecoder::Bucket* bucket) const;

  // Gets all the TransformFeedbackVarying info.
  // Return false on overflow.
  bool GetTransformFeedbackVaryings(CommonDecoder::Bucket* bucket) const;

  // Gather all info through glGetActiveUniformsiv, except for size, type,
  // name_length, which we gather through glGetActiveUniform in
  // glGetProgramInfoCHROMIUM.
  bool GetUniformsES3(CommonDecoder::Bucket* bucket) const;

  // Sets the sampler values for a uniform.
  // This is safe to call for any location. If the location is not
  // a sampler uniform nothing will happen.
  // Returns false if fake_location is a sampler and any value
  // is >= num_texture_units. Returns true otherwise.
  bool SetSamplers(
      GLint num_texture_units, GLint fake_location,
      GLsizei count, const GLint* value);

  bool IsDeleted() const {
    return deleted_;
  }

  void GetProgramiv(GLenum pname, GLint* params);

  bool IsValid() const {
    return valid_;
  }

  bool AttachShader(ShaderManager* manager, Shader* shader);
  bool DetachShader(ShaderManager* manager, Shader* shader);

  void CompileAttachedShaders();
  bool AttachedShadersExist() const;
  bool CanLink() const;

  // Performs glLinkProgram and related activities.
  bool Link(ShaderManager* manager,
            VaryingsPackingOption varyings_packing_option,
            const ShaderCacheCallback& shader_callback);

  // Performs glValidateProgram and related activities.
  void Validate();

  const std::string* log_info() const {
    return log_info_.get();
  }

  bool InUse() const {
    DCHECK_GE(use_count_, 0);
    return use_count_ != 0;
  }

  // Sets attribute-location binding from a glBindAttribLocation() call.
  void SetAttribLocationBinding(const std::string& attrib, GLint location) {
    bind_attrib_location_map_[attrib] = location;
  }

  // Sets uniform-location binding from a glBindUniformLocationCHROMIUM call.
  // returns false if error.
  bool SetUniformLocationBinding(const std::string& name, GLint location);

  // Detects if there are attribute location conflicts from
  // glBindAttribLocation() calls.
  // We only consider the declared attributes in the program.
  bool DetectAttribLocationBindingConflicts() const;

  // Detects if there are uniforms of the same name but different type
  // or precision in vertex/fragment shaders.
  // Return true and set the first found conflicting hashed name to
  // conflicting_name if such cases are detected.
  bool DetectUniformsMismatch(std::string* conflicting_name) const;

  // Return true if a varying is statically used in fragment shader, but it
  // is not declared in vertex shader.
  bool DetectVaryingsMismatch(std::string* conflicting_name) const;

  // Return true if any built-in invariant matching rules are broken as in
  // GLSL ES spec 1.00.17, section 4.6.4, Invariance and Linkage.
  bool DetectBuiltInInvariantConflicts() const;

  // Return true if an uniform and an attribute share the same name.
  bool DetectGlobalNameConflicts(std::string* conflicting_name) const;

  // Return false if varyings can't be packed into the max available
  // varying registers.
  bool CheckVaryingsPacking(VaryingsPackingOption option) const;

  void TransformFeedbackVaryings(GLsizei count, const char* const* varyings,
      GLenum buffer_mode);

  // Visible for testing
  const LocationMap& bind_attrib_location_map() const {
    return bind_attrib_location_map_;
  }

  const std::vector<std::string>& transform_feedback_varyings() const {
    return transform_feedback_varyings_;
  }

  GLenum transform_feedback_buffer_mode() const {
    return transform_feedback_buffer_mode_;
  }

 private:
  friend class base::RefCounted<Program>;
  friend class ProgramManager;

  ~Program();

  void set_log_info(const char* str) {
    log_info_.reset(str ? new std::string(str) : NULL);
  }

  void ClearLinkStatus() {
    link_status_ = false;
  }

  void IncUseCount() {
    ++use_count_;
  }

  void DecUseCount() {
    --use_count_;
    DCHECK_GE(use_count_, 0);
  }

  void MarkAsDeleted() {
    DCHECK(!deleted_);
    deleted_ =  true;
  }

  // Resets the program.
  void Reset();

  // Updates the program info after a successful link.
  void Update();

  // Process the program log, replacing the hashed names with original names.
  std::string ProcessLogInfo(const std::string& log);

  // Updates the program log info from GL
  void UpdateLogInfo();

  // Clears all the uniforms.
  void ClearUniforms(std::vector<uint8>* zero_buffer);

  // If long attribate names are mapped during shader translation, call
  // glBindAttribLocation() again with the mapped names.
  // This is called right before the glLink() call, but after shaders are
  // translated.
  void ExecuteBindAttribLocationCalls();

  bool AddUniformInfo(
      GLsizei size, GLenum type, GLint location, GLint fake_base_location,
      const std::string& name, const std::string& original_name,
      size_t* next_available_index);

  // Query uniform data returned by ANGLE translator by the mapped name.
  // Some drivers incorrectly return an uniform name of size-1 array without
  // "[0]". In this case, we correct the name by appending "[0]" to it.
  void GetCorrectedUniformData(
      const std::string& name,
      std::string* corrected_name, std::string* original_name,
      GLsizei* size, GLenum* type) const;

  // Query VertexAttrib data returned by ANGLE translator by the mapped name.
  void GetVertexAttribData(
      const std::string& name, std::string* original_name, GLenum* type) const;

  void DetachShaders(ShaderManager* manager);

  static inline GLint GetUniformInfoIndexFromFakeLocation(
      GLint fake_location) {
    return fake_location & 0xFFFF;
  }

  static inline GLint GetArrayElementIndexFromFakeLocation(
      GLint fake_location) {
    return (fake_location >> 16) & 0xFFFF;
  }

  ProgramManager* manager_;

  int use_count_;

  GLsizei max_attrib_name_length_;

  // Attrib by index.
  AttribInfoVector attrib_infos_;

  // Attrib by location to index.
  std::vector<GLint> attrib_location_to_index_map_;

  GLsizei max_uniform_name_length_;

  // Uniform info by index.
  UniformInfoVector uniform_infos_;

  // The indices of the uniforms that are samplers.
  SamplerIndices sampler_indices_;

  // The program this Program is tracking.
  GLuint service_id_;

  // Shaders by type of shader.
  scoped_refptr<Shader>
      attached_shaders_[kMaxAttachedShaders];

  // True if this program is marked as deleted.
  bool deleted_;

  // This is true if glLinkProgram was successful at least once.
  bool valid_;

  // This is true if glLinkProgram was successful last time it was called.
  bool link_status_;

  // True if the uniforms have been cleared.
  bool uniforms_cleared_;

  // This is different than uniform_infos_.size() because
  // that is a sparce array.
  GLint num_uniforms_;

  // Log info
  scoped_ptr<std::string> log_info_;

  // attribute-location binding map from glBindAttribLocation() calls.
  LocationMap bind_attrib_location_map_;

  // uniform-location binding map from glBindUniformLocationCHROMIUM() calls.
  LocationMap bind_uniform_location_map_;

  std::vector<std::string> transform_feedback_varyings_;

  GLenum transform_feedback_buffer_mode_;
};

// Tracks the Programs.
//
// NOTE: To support shared resources an instance of this class will
// need to be shared by multiple GLES2Decoders.
class GPU_EXPORT ProgramManager {
 public:
  explicit ProgramManager(ProgramCache* program_cache,
                          uint32 max_varying_vectors);
  ~ProgramManager();

  // Must call before destruction.
  void Destroy(bool have_context);

  // Creates a new program.
  Program* CreateProgram(GLuint client_id, GLuint service_id);

  // Gets a program.
  Program* GetProgram(GLuint client_id);

  // Gets a client id for a given service id.
  bool GetClientId(GLuint service_id, GLuint* client_id) const;

  // Gets the shader cache
  ProgramCache* program_cache() const;

  // Marks a program as deleted. If it is not used the program will be deleted.
  void MarkAsDeleted(ShaderManager* shader_manager, Program* program);

  // Marks a program as used.
  void UseProgram(Program* program);

  // Makes a program as unused. If deleted the program will be removed.
  void UnuseProgram(ShaderManager* shader_manager, Program* program);

  // Clears the uniforms for this program.
  void ClearUniforms(Program* program);

  // Returns true if prefix is invalid for gl.
  static bool IsInvalidPrefix(const char* name, size_t length);

  // Check if a Program is owned by this ProgramManager.
  bool IsOwned(Program* program);

  static int32 MakeFakeLocation(int32 index, int32 element);

  uint32 max_varying_vectors() const {
    return max_varying_vectors_;
  }

 private:
  friend class Program;

  void StartTracking(Program* program);
  void StopTracking(Program* program);

  void RemoveProgramInfoIfUnused(
      ShaderManager* shader_manager, Program* program);

  // Info for each "successfully linked" program by service side program Id.
  // TODO(gman): Choose a faster container.
  typedef std::map<GLuint, scoped_refptr<Program> > ProgramMap;
  ProgramMap programs_;

  // Counts the number of Program allocated with 'this' as its manager.
  // Allows to check no Program will outlive this.
  unsigned int program_count_;

  bool have_context_;

  // Used to clear uniforms.
  std::vector<uint8> zero_;

  ProgramCache* program_cache_;

  uint32 max_varying_vectors_;

  DISALLOW_COPY_AND_ASSIGN(ProgramManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_PROGRAM_MANAGER_H_
