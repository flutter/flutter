// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/gl_description.h"

#include <algorithm>
#include <iomanip>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

static std::string GetGLString(const ProcTableGLES& gl, GLenum name) {
  auto str = gl.GetString(name);
  if (str == nullptr) {
    return "";
  }
  return reinterpret_cast<const char*>(str);
}

GLDescription::GLDescription(const ProcTableGLES& gl)
    : vendor_(GetGLString(gl, GL_VENDOR)),
      renderer_(GetGLString(gl, GL_RENDERER)),
      gl_version_(GetGLString(gl, GL_VERSION)),
      sl_version_(GetGLString(gl, GL_SHADING_LANGUAGE_VERSION)) {
  const auto extensions = GetGLString(gl, GL_EXTENSIONS);
  std::stringstream extensions_stream(extensions);
  std::string extension;
  while (std::getline(extensions_stream, extension, ' ')) {
    extensions_.insert(extension);
  }
  is_valid_ = true;
}

GLDescription::~GLDescription() = default;

bool GLDescription::IsValid() const {
  return is_valid_;
}

std::string GLDescription::GetString() const {
  if (!IsValid()) {
    return "Unknown Renderer.";
  }

  std::vector<std::pair<std::string, std::string>> items;

  items.emplace_back(std::make_pair("Vendor", vendor_));
  items.emplace_back(std::make_pair("Renderer", renderer_));
  items.emplace_back(std::make_pair("GL Version", gl_version_));
  items.emplace_back(std::make_pair("Shading Language Version", sl_version_));
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

}  // namespace impeller
