// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/fragment_program.h"

#include "impeller/base/validation.h"

namespace impeller::interop {

FragmentProgram::FragmentProgram(const std::shared_ptr<fml::Mapping>& data) {
  if (data == nullptr || data->GetSize() == 0) {
    VALIDATION_LOG << "No data provided to create fragment program.";
    return;
  }

  auto stages = RuntimeStage::DecodeRuntimeStages(data);

  for (const auto& stage : stages) {
    if (auto data = stage.second) {
      stages_[stage.first] = std::move(data);
    }
  }

  if (stages_.empty()) {
    VALIDATION_LOG << "No valid runtime stages present in fragment program.";
    return;
  }

  is_valid_ = true;
}

FragmentProgram::~FragmentProgram() = default;

bool FragmentProgram::IsValid() const {
  return is_valid_;
}

static std::string AvailableStagesAsString(
    const std::set<RuntimeStageBackend>& stages) {
  std::stringstream stream;
  size_t count = 0;
  for (const auto& stage : stages) {
    stream << RuntimeStageBackendToString(stage);
    count++;
    if (count != stages.size()) {
      stream << ", ";
    }
  }
  return stream.str();
}

std::shared_ptr<RuntimeStage> FragmentProgram::FindRuntimeStage(
    RuntimeStageBackend backend) const {
  if (backend == RuntimeStageBackend::kOpenGLES3) {
    return FindRuntimeStage(RuntimeStageBackend::kOpenGLES);
  }
  auto found = stages_.find(backend);
  if (found == stages_.end()) {
    VALIDATION_LOG << "Could not find runtime shader for backend: "
                   << RuntimeStageBackendToString(backend)
                   << ". Shaders were packaged for "
                   << AvailableStagesAsString(GetAvailableStages())
                   << ". Check your shader compiler options.";
    return nullptr;
  }
  return found->second;
}

const char* RuntimeStageBackendToString(RuntimeStageBackend backend) {
  switch (backend) {
    case RuntimeStageBackend::kSkSL:
      return "SKSL";
    case RuntimeStageBackend::kMetal:
      return "Metal";
    case RuntimeStageBackend::kOpenGLES:
      return "OpenGL ES2";
    case RuntimeStageBackend::kOpenGLES3:
      return "OpenGL ES3";
    case RuntimeStageBackend::kVulkan:
      return "Vulkan";
  }
  return "Unknown";
}

std::set<RuntimeStageBackend> FragmentProgram::GetAvailableStages() const {
  std::set<RuntimeStageBackend> stages;
  for (const auto& stage : stages_) {
    stages.insert(stage.first);
  }
  return stages;
}

}  // namespace impeller::interop
