// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/description_gles.h"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <iomanip>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

static std::string GetGLString(const ProcTableGLES& gl, GLenum name) {
  auto str = gl.GetString(name);
  if (str == nullptr) {
    return "";
  }
  return reinterpret_cast<const char*>(str);
}

static std::string GetGLStringi(const ProcTableGLES& gl,
                                GLenum name,
                                int index) {
  auto str = gl.GetStringi(name, index);
  if (str == nullptr) {
    return "";
  }
  return reinterpret_cast<const char*>(str);
}

static bool DetermineIfES(const std::string& version) {
  return HasPrefix(version, "OpenGL ES");
}

static bool DetermineIfANGLE(const std::string& version) {
  return version.find("ANGLE") != std::string::npos;
}

static std::optional<Version> DetermineVersion(std::string version) {
  // Format for OpenGL "OpenGL<space>ES<space><version
  // number><space><vendor-specific information>".
  //
  // Format for OpenGL SL "OpenGL<space>ES<space>GLSL<space>ES<space><version
  // number><space><vendor-specific information>"
  //
  // The prefixes appear to be absent on Desktop GL.

  version = StripPrefix(version, "OpenGL ES ");
  version = StripPrefix(version, "GLSL ES ");

  if (version.empty()) {
    return std::nullopt;
  }

  std::stringstream stream;
  for (size_t i = 0; i < version.size(); i++) {
    const auto character = version[i];
    if (std::isdigit(character) || character == '.') {
      stream << character;
    } else {
      break;
    }
  }
  std::istringstream istream;
  istream.str(stream.str());
  std::vector<size_t> version_components;
  for (std::string version_component;
       std::getline(istream, version_component, '.');) {
    version_components.push_back(std::stoul(version_component));
  }
  return Version::FromVector(version_components);
}

static bool MaliDriverNeedsTextureUploadRebind(const std::string& version) {
  // Arm's version string includes a driver release, for example:
  // "OpenGL ES 3.2 v1.r18p0-01rel0...". If it is unavailable, retain the
  // workaround rather than assuming that the driver has been fixed.
  const auto marker = version.find(" v1.r");
  if (marker == std::string::npos) {
    return true;
  }
  const char* end = version.data() + version.size();
  unsigned int release = 0;
  const auto release_result =
      std::from_chars(version.data() + marker + 5, end, release);
  if (release_result.ec != std::errc{} || release_result.ptr == end ||
      *release_result.ptr != 'p') {
    return true;
  }
  unsigned int patch = 0;
  const auto patch_result = std::from_chars(release_result.ptr + 1, end, patch);
  if (patch_result.ec != std::errc{} ||
      (patch_result.ptr != end && *patch_result.ptr != '-')) {
    return true;
  }
  // Arm erratum EN_ID 1,792,661 affects Bifrost/Valhall r17p0-r23p0 and was
  // fixed in r24p0. OEM backports within that range cannot be detected.
  return release >= 17 && release < 24;
}

DescriptionGLES::DescriptionGLES(const ProcTableGLES& gl)
    : vendor_(GetGLString(gl, GL_VENDOR)),
      renderer_(GetGLString(gl, GL_RENDERER)),
      gl_version_string_(GetGLString(gl, GL_VERSION)),
      sl_version_string_(GetGLString(gl, GL_SHADING_LANGUAGE_VERSION)) {
  is_es_ = DetermineIfES(gl_version_string_);
  is_angle_ = DetermineIfANGLE(gl_version_string_);

  auto gl_version = DetermineVersion(gl_version_string_);
  if (!gl_version.has_value()) {
    VALIDATION_LOG << "Could not determine GL version.";
    return;
  }
  gl_version_ = gl_version.value();

  // GL_NUM_EXTENSIONS is only available in OpenGL 3+ and OpenGL ES 3+
  if (gl_version_.IsAtLeast(Version(3, 0, 0))) {
    int extension_count = 0;
    gl.GetIntegerv(GL_NUM_EXTENSIONS, &extension_count);
    for (auto i = 0; i < extension_count; i++) {
      extensions_.insert(GetGLStringi(gl, GL_EXTENSIONS, i));
    }
  } else {
    const auto extensions = GetGLString(gl, GL_EXTENSIONS);
    std::stringstream extensions_stream(extensions);
    std::string extension;
    while (std::getline(extensions_stream, extension, ' ')) {
      extensions_.insert(extension);
    }
  }

  auto sl_version = DetermineVersion(sl_version_string_);
  if (!sl_version.has_value()) {
    VALIDATION_LOG << "Could not determine SL version.";
    return;
  }
  sl_version_ = sl_version.value();

  needs_texture_upload_rebind_ =
      is_es_ && !is_angle_ &&
      (HasPrefix(renderer_, "Mali-G") ||
       HasPrefix(renderer_, "Immortalis-G")) &&
      MaliDriverNeedsTextureUploadRebind(gl_version_string_);

  is_valid_ = true;
}

DescriptionGLES::~DescriptionGLES() = default;

bool DescriptionGLES::IsValid() const {
  return is_valid_;
}

std::string DescriptionGLES::GetString() const {
  if (!IsValid()) {
    return "Unknown Renderer.";
  }

  std::vector<std::pair<std::string, std::string>> items;

  items.emplace_back(std::make_pair("Vendor", vendor_));
  items.emplace_back(std::make_pair("Renderer", renderer_));
  items.emplace_back(std::make_pair("GL Version", gl_version_string_));
  items.emplace_back(
      std::make_pair("Shading Language Version", sl_version_string_));
  items.emplace_back(
      std::make_pair("Extensions", std::to_string(extensions_.size())));

  size_t max_width = 0u;
  for (const auto& item : items) {
    max_width = std::max(max_width, item.first.size());
  }

  std::stringstream stream;
  stream << "OpenGL Renderer:" << std::endl;
  for (const auto& item : items) {
    stream << std::setw(max_width + 1) << item.first << ": " << item.second
           << std::endl;
  }

  const auto pad = std::string(max_width + 3, ' ');
  for (const auto& extension : extensions_) {
    stream << pad << extension << std::endl;
  }

  return stream.str();
}

Version DescriptionGLES::GetGlVersion() const {
  return gl_version_;
}

bool DescriptionGLES::IsES() const {
  return is_es_;
}

bool DescriptionGLES::IsANGLE() const {
  return is_angle_;
}

bool DescriptionGLES::NeedsTextureUploadRebind() const {
  return needs_texture_upload_rebind_;
}

bool DescriptionGLES::HasExtension(const std::string& ext) const {
  return extensions_.find(ext) != extensions_.end();
}

bool DescriptionGLES::HasDebugExtension() const {
  // Angle just logs calls instead of forwarding debug information to the
  // backend. This just overwhelms the logs and is of limited use. Disable on
  // Angle.
  return HasExtension("GL_KHR_debug") && !IsANGLE();
}

}  // namespace impeller
