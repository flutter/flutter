// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_SHADER_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_SHADER_MANAGER_H_

#include <string>
#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/shader_translator.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

// This is used to keep the source code for a shader. This is because in order
// to emluate GLES2 the shaders will have to be re-written before passed to
// the underlying OpenGL. But, when the user calls glGetShaderSource they
// should get the source they passed in, not the re-written source.
class GPU_EXPORT Shader : public base::RefCounted<Shader> {
 public:
  enum TranslatedShaderSourceType {
    kANGLE,
    kGL,  // GL or GLES
  };

  enum ShaderState {
    kShaderStateWaiting,
    kShaderStateCompileRequested,
    kShaderStateCompiled, // Signifies compile happened, not valid compile.
  };

  void RequestCompile(scoped_refptr<ShaderTranslatorInterface> translator,
                      TranslatedShaderSourceType type);

  void DoCompile();

  ShaderState shader_state() const {
    return shader_state_;
  }

  GLuint service_id() const {
    return marked_for_deletion_ ? 0 : service_id_;
  }

  GLenum shader_type() const {
    return shader_type_;
  }

  const std::string& source() const {
    return source_;
  }

  void set_source(const std::string& source) {
    source_ = source;
  }

  const std::string& translated_source() const {
    return translated_source_;
  }

  std::string last_compiled_source() const {
    return last_compiled_source_;
  }

  std::string last_compiled_signature() const {
    if (translator_.get()) {
      return last_compiled_source_ +
             translator_->GetStringForOptionsThatWouldAffectCompilation();
    }
    return last_compiled_source_;
  }

  const sh::Attribute* GetAttribInfo(const std::string& name) const;
  const sh::Uniform* GetUniformInfo(const std::string& name) const;
  const sh::Varying* GetVaryingInfo(const std::string& name) const;

  // If the original_name is not found, return NULL.
  const std::string* GetAttribMappedName(
      const std::string& original_name) const;

  // If the hashed_name is not found, return NULL.
  const std::string* GetOriginalNameFromHashedName(
      const std::string& hashed_name) const;

  const std::string& log_info() const {
    return log_info_;
  }

  bool valid() const {
    return shader_state_ == kShaderStateCompiled && valid_;
  }

  bool IsDeleted() const {
    return marked_for_deletion_;
  }

  bool InUse() const {
    DCHECK_GE(use_count_, 0);
    return use_count_ != 0;
  }

  // Used by program cache.
  const AttributeMap& attrib_map() const {
    return attrib_map_;
  }

  // Used by program cache.
  const UniformMap& uniform_map() const {
    return uniform_map_;
  }

  // Used by program cache.
  const VaryingMap& varying_map() const {
    return varying_map_;
  }

  // Used by program cache.
  void set_attrib_map(const AttributeMap& attrib_map) {
    // copied because cache might be cleared
    attrib_map_ = AttributeMap(attrib_map);
  }

  // Used by program cache.
  void set_uniform_map(const UniformMap& uniform_map) {
    // copied because cache might be cleared
    uniform_map_ = UniformMap(uniform_map);
  }

  // Used by program cache.
  void set_varying_map(const VaryingMap& varying_map) {
    // copied because cache might be cleared
    varying_map_ = VaryingMap(varying_map);
  }

 private:
  friend class base::RefCounted<Shader>;
  friend class ShaderManager;

  Shader(GLuint service_id, GLenum shader_type);
  ~Shader();

  // Must be called only if we currently own the context. Forces the deletion
  // of the underlying shader service id.
  void Destroy();

  void IncUseCount();
  void DecUseCount();
  void MarkForDeletion();
  void DeleteServiceID();

  int use_count_;

  // The current state of the shader.
  ShaderState shader_state_;

  // The shader has been marked for deletion.
  bool marked_for_deletion_;

  // The shader this Shader is tracking.
  GLuint service_id_;

  // Type of shader - GL_VERTEX_SHADER or GL_FRAGMENT_SHADER.
  GLenum shader_type_;

  // Translated source type when shader was last requested to be compiled.
  TranslatedShaderSourceType source_type_;

  // Translator to use, set when shader was last requested to be compiled.
  scoped_refptr<ShaderTranslatorInterface> translator_;

  // True if compilation succeeded.
  bool valid_;

  // The shader source as passed to glShaderSource.
  std::string source_;

  // The source the last compile used.
  std::string last_compiled_source_;

  // The translated shader source.
  std::string translated_source_;

  // The shader translation log.
  std::string log_info_;

  // The type info when the shader was last compiled.
  AttributeMap attrib_map_;
  UniformMap uniform_map_;
  VaryingMap varying_map_;

  // The name hashing info when the shader was last compiled.
  NameMap name_map_;
};

// Tracks the Shaders.
//
// NOTE: To support shared resources an instance of this class will
// need to be shared by multiple GLES2Decoders.
class GPU_EXPORT ShaderManager {
 public:
  ShaderManager();
  ~ShaderManager();

  // Must call before destruction.
  void Destroy(bool have_context);

  // Creates a shader for the given shader ID.
  Shader* CreateShader(
      GLuint client_id,
      GLuint service_id,
      GLenum shader_type);

  // Gets an existing shader info for the given shader ID. Returns NULL if none
  // exists.
  Shader* GetShader(GLuint client_id);

  // Gets a client id for a given service id.
  bool GetClientId(GLuint service_id, GLuint* client_id) const;

  void Delete(Shader* shader);

  // Mark a shader as used
  void UseShader(Shader* shader);

  // Unmark a shader as used. If it has been deleted and is not used
  // then we free the shader.
  void UnuseShader(Shader* shader);

  // Check if a Shader is owned by this ShaderManager.
  bool IsOwned(Shader* shader);

 private:
  friend class Shader;

  // Info for each shader by service side shader Id.
  typedef base::hash_map<GLuint, scoped_refptr<Shader> > ShaderMap;
  ShaderMap shaders_;

  void RemoveShader(Shader* shader);

  DISALLOW_COPY_AND_ASSIGN(ShaderManager);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_SHADER_MANAGER_H_

