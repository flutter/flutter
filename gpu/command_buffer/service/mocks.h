// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains definitions for mock objects, used for testing.

// TODO(apatrick): This file "manually" defines some mock objects. Using gMock
// would be definitely preferable, unfortunately it doesn't work on Windows yet.

#ifndef GPU_COMMAND_BUFFER_SERVICE_MOCKS_H_
#define GPU_COMMAND_BUFFER_SERVICE_MOCKS_H_

#include <string>
#include <vector>

#include "base/logging.h"
#include "gpu/command_buffer/service/cmd_parser.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/command_buffer/service/program_cache.h"
#include "gpu/command_buffer/service/shader_translator.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace gpu {

// Mocks an AsyncAPIInterface, using GMock.
class AsyncAPIMock : public AsyncAPIInterface {
 public:
  explicit AsyncAPIMock(bool default_do_commands);
  virtual ~AsyncAPIMock();

  error::Error FakeDoCommands(unsigned int num_commands,
                              const void* buffer,
                              int num_entries,
                              int* entries_processed);

  // Predicate that matches args passed to DoCommand, by looking at the values.
  class IsArgs {
   public:
    IsArgs(unsigned int arg_count, const void* args)
        : arg_count_(arg_count),
          args_(static_cast<CommandBufferEntry*>(const_cast<void*>(args))) {
    }

    bool operator() (const void* _args) const {
      const CommandBufferEntry* args =
          static_cast<const CommandBufferEntry*>(_args) + 1;
      for (unsigned int i = 0; i < arg_count_; ++i) {
        if (args[i].value_uint32 != args_[i].value_uint32) return false;
      }
      return true;
    }

   private:
    unsigned int arg_count_;
    CommandBufferEntry *args_;
  };

  MOCK_METHOD3(DoCommand, error::Error(
      unsigned int command,
      unsigned int arg_count,
      const void* cmd_data));

  MOCK_METHOD4(DoCommands,
               error::Error(unsigned int num_commands,
                            const void* buffer,
                            int num_entries,
                            int* entries_processed));

  const char* GetCommandName(unsigned int command_id) const {
    return "";
  };

  // Sets the engine, to forward SetToken commands to it.
  void set_engine(CommandBufferEngine *engine) { engine_ = engine; }

  // Forwards the SetToken commands to the engine.
  void SetToken(unsigned int command,
                unsigned int arg_count,
                const void* _args);

 private:
  CommandBufferEngine *engine_;
};

namespace gles2 {

class MockShaderTranslator : public ShaderTranslatorInterface {
 public:
  MockShaderTranslator();

  MOCK_METHOD5(Init, bool(
      sh::GLenum shader_type,
      ShShaderSpec shader_spec,
      const ShBuiltInResources* resources,
      GlslImplementationType glsl_implementation_type,
      ShCompileOptions driver_bug_workarounds));
  MOCK_CONST_METHOD7(Translate, bool(
      const std::string& shader_source,
      std::string* info_log,
      std::string* translated_source,
      AttributeMap* attrib_map,
      UniformMap* uniform_map,
      VaryingMap* varying_map,
      NameMap* name_map));
  MOCK_CONST_METHOD0(
      GetStringForOptionsThatWouldAffectCompilation, std::string());
 private:
  ~MockShaderTranslator() override;
};

class MockProgramCache : public ProgramCache {
 public:
  MockProgramCache();
  virtual ~MockProgramCache();

  MOCK_METHOD7(LoadLinkedProgram, ProgramLoadResult(
      GLuint program,
      Shader* shader_a,
      Shader* shader_b,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      const ShaderCacheCallback& callback));

  MOCK_METHOD7(SaveLinkedProgram, void(
      GLuint program,
      const Shader* shader_a,
      const Shader* shader_b,
      const LocationMap* bind_attrib_location_map,
      const std::vector<std::string>& transform_feedback_varyings,
      GLenum transform_feedback_buffer_mode,
      const ShaderCacheCallback& callback));
  MOCK_METHOD1(LoadProgram, void(const std::string&));

 private:
  MOCK_METHOD0(ClearBackend, void());
};

class MockMemoryTracker : public MemoryTracker {
 public:
  MockMemoryTracker();

  MOCK_METHOD3(TrackMemoryAllocatedChange, void(
      size_t old_size, size_t new_size, Pool pool));
  MOCK_METHOD1(EnsureGPUMemoryAvailable, bool(size_t size_needed));

 private:
  friend class ::testing::StrictMock<MockMemoryTracker>;
  friend class base::RefCounted< ::testing::StrictMock<MockMemoryTracker> >;
  virtual ~MockMemoryTracker();
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_MOCKS_H_
