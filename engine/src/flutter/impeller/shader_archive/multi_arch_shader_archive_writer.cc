// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/shader_archive/multi_arch_shader_archive_writer.h"

#include "impeller/base/validation.h"
#include "impeller/shader_archive/multi_arch_shader_archive_flatbuffers.h"

namespace impeller {

MultiArchShaderArchiveWriter::MultiArchShaderArchiveWriter() = default;

MultiArchShaderArchiveWriter::~MultiArchShaderArchiveWriter() = default;

bool MultiArchShaderArchiveWriter::RegisterShaderArchive(
    ArchiveRenderingBackend backend,
    std::shared_ptr<const fml::Mapping> mapping) {
  if (!mapping || mapping->GetMapping() == nullptr) {
    return false;
  }
  if (archives_.find(backend) != archives_.end()) {
    VALIDATION_LOG << "Multi-archive already has a shader library registered "
                      "for that backend.";
    return false;
  }
  archives_[backend] = std::move(mapping);
  return true;
}

constexpr fb::RenderingBackend ToRenderingBackend(
    ArchiveRenderingBackend backend) {
  switch (backend) {
    case ArchiveRenderingBackend::kMetal:
      return fb::RenderingBackend::kMetal;
    case ArchiveRenderingBackend::kVulkan:
      return fb::RenderingBackend::kVulkan;
    case ArchiveRenderingBackend::kOpenGLES:
      return fb::RenderingBackend::kOpenGLES;
  }
  FML_UNREACHABLE();
}

std::shared_ptr<fml::Mapping> MultiArchShaderArchiveWriter::CreateMapping()
    const {
  fb::MultiArchShaderArchiveT multi_archive;
  for (const auto& archive : archives_) {
    auto archive_blob = std::make_unique<fb::ShaderArchiveBlobT>();
    archive_blob->rendering_backend = ToRenderingBackend(archive.first);
    archive_blob->mapping = {
        archive.second->GetMapping(),
        archive.second->GetMapping() + archive.second->GetSize()};
    multi_archive.items.emplace_back(std::move(archive_blob));
  }
  auto builder = std::make_shared<flatbuffers::FlatBufferBuilder>();
  builder->Finish(
      fb::MultiArchShaderArchive::Pack(*builder.get(), &multi_archive),
      fb::MultiArchShaderArchiveIdentifier());
  return std::make_shared<fml::NonOwnedMapping>(builder->GetBufferPointer(),
                                                builder->GetSize(),
                                                [builder](auto, auto) {});
}

}  // namespace impeller
