// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/shader_manager.h"

#include <utility>

#include "base/logging.h"
#include "base/strings/string_util.h"

namespace gpu {
namespace gles2 {

namespace {

// Given a variable name | a[0].b.c[0] |, return |a|.
std::string GetTopVariableName(const std::string& fullname) {
  size_t pos = fullname.find_first_of("[.");
  if (pos == std::string::npos)
    return fullname;
  return fullname.substr(0, pos);
}

}  // namespace anonymous

Shader::Shader(GLuint service_id, GLenum shader_type)
      : use_count_(0),
        shader_state_(kShaderStateWaiting),
        marked_for_deletion_(false),
        service_id_(service_id),
        shader_type_(shader_type),
        source_type_(kANGLE),
        valid_(false) {
}

Shader::~Shader() {
}

void Shader::Destroy() {
  if (service_id_) {
    DeleteServiceID();
  }
}

void Shader::RequestCompile(scoped_refptr<ShaderTranslatorInterface> translator,
                            TranslatedShaderSourceType type) {
  shader_state_ = kShaderStateCompileRequested;
  translator_ = translator;
  source_type_ = type;
  last_compiled_source_ = source_;
}

void Shader::DoCompile() {
  // We require that RequestCompile() must be called before DoCompile(),
  // so we can return early if the shader state is not what we expect.
  if (shader_state_ != kShaderStateCompileRequested) {
    return;
  }

  // Signify the shader has been compiled, whether or not it is valid
  // is dependent on the |valid_| member variable.
  shader_state_ = kShaderStateCompiled;
  valid_ = false;

  // Translate GL ES 2.0 shader to Desktop GL shader and pass that to
  // glShaderSource and then glCompileShader.
  const char* source_for_driver = last_compiled_source_.c_str();
  ShaderTranslatorInterface* translator = translator_.get();
  if (translator) {
    bool success = translator->Translate(last_compiled_source_,
                                         &log_info_,
                                         &translated_source_,
                                         &attrib_map_,
                                         &uniform_map_,
                                         &varying_map_,
                                         &name_map_);
    if (!success) {
      return;
    }
    source_for_driver = translated_source_.c_str();
  }

  glShaderSource(service_id_, 1, &source_for_driver, NULL);
  glCompileShader(service_id_);
  if (source_type_ == kANGLE) {
    GLint max_len = 0;
    glGetShaderiv(service_id_,
                  GL_TRANSLATED_SHADER_SOURCE_LENGTH_ANGLE,
                  &max_len);
    source_for_driver = "\0";
    translated_source_.resize(max_len);
    if (max_len) {
      GLint len = 0;
      glGetTranslatedShaderSourceANGLE(
          service_id_, translated_source_.size(),
          &len, &translated_source_.at(0));
      DCHECK(max_len == 0 || len < max_len);
      DCHECK(len == 0 || translated_source_[len] == '\0');
      translated_source_.resize(len);
      source_for_driver = translated_source_.c_str();
    }
  }

  GLint status = GL_FALSE;
  glGetShaderiv(service_id_, GL_COMPILE_STATUS, &status);
  if (status == GL_TRUE) {
    valid_ = true;
  } else {
    valid_ = false;

    // We cannot reach here if we are using the shader translator.
    // All invalid shaders must be rejected by the translator.
    // All translated shaders must compile.
    std::string translator_log = log_info_;

    GLint max_len = 0;
    glGetShaderiv(service_id_, GL_INFO_LOG_LENGTH, &max_len);
    log_info_.resize(max_len);
    if (max_len) {
      GLint len = 0;
      glGetShaderInfoLog(service_id_, log_info_.size(), &len, &log_info_.at(0));
      DCHECK(max_len == 0 || len < max_len);
      DCHECK(len == 0 || log_info_[len] == '\0');
      log_info_.resize(len);
    }

    LOG_IF(ERROR, translator)
        << "Shader translator allowed/produced an invalid shader "
        << "unless the driver is buggy:"
        << "\n--Log from shader translator--\n" << translator_log
        << "\n--original-shader--\n" << last_compiled_source_
        << "\n--translated-shader--\n" << source_for_driver
        << "\n--info-log--\n" << log_info_;
  }
}

void Shader::IncUseCount() {
  ++use_count_;
}

void Shader::DecUseCount() {
  --use_count_;
  DCHECK_GE(use_count_, 0);
  if (service_id_ && use_count_ == 0 && marked_for_deletion_) {
    DeleteServiceID();
  }
}

void Shader::MarkForDeletion() {
  DCHECK(!marked_for_deletion_);
  DCHECK_NE(service_id_, 0u);

  marked_for_deletion_ = true;
  if (use_count_ == 0) {
    DeleteServiceID();
  }
}

void Shader::DeleteServiceID() {
  DCHECK_NE(service_id_, 0u);
  glDeleteShader(service_id_);
  service_id_ = 0;
}

const sh::Attribute* Shader::GetAttribInfo(const std::string& name) const {
  // Vertex attributes can't be arrays or structs (GLSL ES 3.00.4, section
  // 4.3.4, "Input Variables"), so |name| is the top level name used as
  // the AttributeMap key.
  AttributeMap::const_iterator it = attrib_map_.find(name);
  return it != attrib_map_.end() ? &it->second : NULL;
}

const std::string* Shader::GetAttribMappedName(
    const std::string& original_name) const {
  for (AttributeMap::const_iterator it = attrib_map_.begin();
       it != attrib_map_.end(); ++it) {
    if (it->second.name == original_name)
      return &(it->first);
  }
  return NULL;
}

const std::string* Shader::GetOriginalNameFromHashedName(
    const std::string& hashed_name) const {
  NameMap::const_iterator it = name_map_.find(hashed_name);
  if (it != name_map_.end())
    return &(it->second);
  return NULL;
}

const sh::Uniform* Shader::GetUniformInfo(const std::string& name) const {
  UniformMap::const_iterator it = uniform_map_.find(GetTopVariableName(name));
  return it != uniform_map_.end() ? &it->second : NULL;
}

const sh::Varying* Shader::GetVaryingInfo(const std::string& name) const {
  VaryingMap::const_iterator it = varying_map_.find(GetTopVariableName(name));
  return it != varying_map_.end() ? &it->second : NULL;
}

ShaderManager::ShaderManager() {}

ShaderManager::~ShaderManager() {
  DCHECK(shaders_.empty());
}

void ShaderManager::Destroy(bool have_context) {
  while (!shaders_.empty()) {
    if (have_context) {
      Shader* shader = shaders_.begin()->second.get();
      shader->Destroy();
    }
    shaders_.erase(shaders_.begin());
  }
}

Shader* ShaderManager::CreateShader(
    GLuint client_id,
    GLuint service_id,
    GLenum shader_type) {
  std::pair<ShaderMap::iterator, bool> result =
      shaders_.insert(std::make_pair(
          client_id, scoped_refptr<Shader>(
              new Shader(service_id, shader_type))));
  DCHECK(result.second);
  return result.first->second.get();
}

Shader* ShaderManager::GetShader(GLuint client_id) {
  ShaderMap::iterator it = shaders_.find(client_id);
  return it != shaders_.end() ? it->second.get() : NULL;
}

bool ShaderManager::GetClientId(GLuint service_id, GLuint* client_id) const {
  // This doesn't need to be fast. It's only used during slow queries.
  for (ShaderMap::const_iterator it = shaders_.begin();
       it != shaders_.end(); ++it) {
    if (it->second->service_id() == service_id) {
      *client_id = it->first;
      return true;
    }
  }
  return false;
}

bool ShaderManager::IsOwned(Shader* shader) {
  for (ShaderMap::iterator it = shaders_.begin();
       it != shaders_.end(); ++it) {
    if (it->second.get() == shader) {
      return true;
    }
  }
  return false;
}

void ShaderManager::RemoveShader(Shader* shader) {
  DCHECK(shader);
  DCHECK(IsOwned(shader));
  if (shader->IsDeleted() && !shader->InUse()) {
    for (ShaderMap::iterator it = shaders_.begin();
         it != shaders_.end(); ++it) {
      if (it->second.get() == shader) {
        shaders_.erase(it);
        return;
      }
    }
    NOTREACHED();
  }
}

void ShaderManager::Delete(Shader* shader) {
  DCHECK(shader);
  DCHECK(IsOwned(shader));
  shader->MarkForDeletion();
  RemoveShader(shader);
}

void ShaderManager::UseShader(Shader* shader) {
  DCHECK(shader);
  DCHECK(IsOwned(shader));
  shader->IncUseCount();
}

void ShaderManager::UnuseShader(Shader* shader) {
  DCHECK(shader);
  DCHECK(IsOwned(shader));
  shader->DecUseCount();
  RemoveShader(shader);
}

}  // namespace gles2
}  // namespace gpu
