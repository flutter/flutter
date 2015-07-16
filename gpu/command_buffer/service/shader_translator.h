// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_SHADER_TRANSLATOR_H_
#define GPU_COMMAND_BUFFER_SERVICE_SHADER_TRANSLATOR_H_

#include <string>

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/observer_list.h"
#include "gpu/gpu_export.h"
#include "third_party/angle/include/GLSLANG/ShaderLang.h"

namespace gpu {
namespace gles2 {

// Mapping between variable name and info.
typedef base::hash_map<std::string, sh::Attribute> AttributeMap;
typedef base::hash_map<std::string, sh::Uniform> UniformMap;
typedef base::hash_map<std::string, sh::Varying> VaryingMap;
// Mapping between hashed name and original name.
typedef base::hash_map<std::string, std::string> NameMap;

// Translates a GLSL ES 2.0 shader to desktop GLSL shader, or just
// validates GLSL ES 2.0 shaders on a true GLSL ES implementation.
class ShaderTranslatorInterface
    : public base::RefCounted<ShaderTranslatorInterface> {
 public:
  ShaderTranslatorInterface() {}
  enum GlslImplementationType {
    kGlsl,
    kGlslES
  };

  // Initializes the translator.
  // Must be called once before using the translator object.
  virtual bool Init(
      sh::GLenum shader_type,
      ShShaderSpec shader_spec,
      const ShBuiltInResources* resources,
      GlslImplementationType glsl_implementation_type,
      ShCompileOptions driver_bug_workarounds) = 0;

  // Translates the given shader source.
  // Returns true if translation is successful, false otherwise.
  // Always fill |info_log| if it's non-null.
  // Upon success, fill |translated_shader|, |attrib_map|, |uniform_map|,
  // |varying_map|, and |name_map| if they are non-null.
  virtual bool Translate(const std::string& shader_source,
                         std::string* info_log,
                         std::string* translated_shader,
                         AttributeMap* attrib_map,
                         UniformMap* uniform_map,
                         VaryingMap* varying_map,
                         NameMap* name_map) const = 0;

  // Return a string that is unique for a specfic set of options that would
  // possibly affect compilation.
  virtual std::string GetStringForOptionsThatWouldAffectCompilation() const = 0;

 protected:
  virtual ~ShaderTranslatorInterface() {}

 private:
  friend class base::RefCounted<ShaderTranslatorInterface>;
  DISALLOW_COPY_AND_ASSIGN(ShaderTranslatorInterface);
};

// Implementation of ShaderTranslatorInterface
class GPU_EXPORT ShaderTranslator
    : NON_EXPORTED_BASE(public ShaderTranslatorInterface) {
 public:
  class DestructionObserver {
   public:
    DestructionObserver();
    virtual ~DestructionObserver();

    virtual void OnDestruct(ShaderTranslator* translator) = 0;

   private:
    DISALLOW_COPY_AND_ASSIGN(DestructionObserver);
  };

  ShaderTranslator();

  // Overridden from ShaderTranslatorInterface.
  bool Init(sh::GLenum shader_type,
            ShShaderSpec shader_spec,
            const ShBuiltInResources* resources,
            GlslImplementationType glsl_implementation_type,
            ShCompileOptions driver_bug_workarounds) override;

  // Overridden from ShaderTranslatorInterface.
  bool Translate(const std::string& shader_source,
                 std::string* info_log,
                 std::string* translated_source,
                 AttributeMap* attrib_map,
                 UniformMap* uniform_map,
                 VaryingMap* varying_map,
                 NameMap* name_map) const override;

  std::string GetStringForOptionsThatWouldAffectCompilation() const override;

  void AddDestructionObserver(DestructionObserver* observer);
  void RemoveDestructionObserver(DestructionObserver* observer);

 private:
  ~ShaderTranslator() override;

  int GetCompileOptions() const;

  ShHandle compiler_;
  bool implementation_is_glsl_es_;
  ShCompileOptions driver_bug_workarounds_;
  base::ObserverList<DestructionObserver> destruction_observers_;
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_SHADER_TRANSLATOR_H_

