// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/shader_archive/multi_arch_shader_archive.h"

#include "impeller/shader_archive/multi_arch_shader_archive_flatbuffers.h"

namespace impeller {

constexpr ArchiveRenderingBackend ToArchiveRenderingBackend(
    fb::RenderingBackend backend) {
  switch (backend) {
    case fb::RenderingBackend::kOpenGLES:
      return ArchiveRenderingBackend::kOpenGLES;
    case fb::RenderingBackend::kVulkan:
      return ArchiveRenderingBackend::kVulkan;
    case fb::RenderingBackend::kMetal:
      return ArchiveRenderingBackend::kMetal;
  }
  FML_UNREACHABLE();
}

std::shared_ptr<ShaderArchive> MultiArchShaderArchive::CreateArchiveFromMapping(
    const std::shared_ptr<const fml::Mapping>& mapping,
    ArchiveRenderingBackend backend) {
  {
    auto multi_archive = std::make_shared<MultiArchShaderArchive>(mapping);
    if (multi_archive->IsValid()) {
      return multi_archive->GetShaderArchive(backend);
    }
  }
  {
    auto single_archive =
        std::shared_ptr<ShaderArchive>(new ShaderArchive(mapping));
    if (single_archive->IsValid()) {
      return single_archive;
    }
  }
  return nullptr;
}

MultiArchShaderArchive::MultiArchShaderArchive(
    const std::shared_ptr<const fml::Mapping>& mapping) {
  if (!mapping) {
    return;
  }

  if (!fb::MultiArchShaderArchiveBufferHasIdentifier(mapping->GetMapping())) {
    return;
  }

  const auto* multi_arch = fb::GetMultiArchShaderArchive(mapping->GetMapping());

  if (!multi_arch) {
    return;
  }

  if (auto archives = multi_arch->items()) {
    for (auto i = archives->begin(), end = archives->end(); i != end; i++) {
      // This implementation is unable to handle multiple archives for the same
      // backend.
      backend_mappings_[ToArchiveRenderingBackend(i->rendering_backend())] =
          std::make_shared<fml::NonOwnedMapping>(i->mapping()->Data(),
                                                 i->mapping()->size(),
                                                 [mapping](auto, auto) {
                                                   // Just hold the mapping.
                                                 });
    }
  }

  is_valid_ = true;
}

MultiArchShaderArchive::~MultiArchShaderArchive() = default;

bool MultiArchShaderArchive::IsValid() const {
  return is_valid_;
}

std::shared_ptr<const fml::Mapping> MultiArchShaderArchive::GetArchive(
    ArchiveRenderingBackend backend) const {
  auto found = backend_mappings_.find(backend);
  if (found == backend_mappings_.end()) {
    return nullptr;
  }
  return found->second;
}

std::shared_ptr<ShaderArchive> MultiArchShaderArchive::GetShaderArchive(
    ArchiveRenderingBackend backend) const {
  auto archive = GetArchive(backend);
  if (!archive) {
    return nullptr;
  }
  auto shader_archive =
      std::shared_ptr<ShaderArchive>(new ShaderArchive(std::move(archive)));
  if (!shader_archive->IsValid()) {
    return nullptr;
  }
  return shader_archive;
}

}  // namespace impeller
