// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gl_connection.h"

#include <sstream>
#include <vector>
#include <algorithm>
#include <iomanip>

namespace flow {

static std::string GLGetString(GLenum name) {
  auto string = reinterpret_cast<const char*>(glGetString(name));
  return string != nullptr ? string : "";
}

static GLConnection::Version GLGetVersion(GLenum name) {
  GLConnection::Version version;

  auto versionString = GLGetString(name);

  if (versionString.length() == 0) {
    return version;
  }

  {
    // Check for the GLSL ES prefix.
    const std::string glslesPrefix("OpenGL ES GLSL ES ");
    if (versionString.compare(0, glslesPrefix.length(), glslesPrefix) == 0) {
      version.isES = true;
      versionString = versionString.substr(glslesPrefix.length());
    }
  }

  {
    // Check for the GL ES prefix.
    const std::string glesPrefix("OpenGL ES ");
    if (versionString.compare(0, glesPrefix.length(), glesPrefix) == 0) {
      version.isES = true;
      versionString = versionString.substr(glesPrefix.length());
    }
  }

  std::istringstream stream(versionString);

  for (size_t i = 0; i < 3; i++) {
    size_t item = 0;
    if (stream >> item) {
      version.items[i] = item;

      if (stream.peek() == ' ') {
        stream.ignore(1);  // space
        stream >> version.vendorString;
        break;
      } else {
        stream.ignore(1);  // dot
      }
    } else {
      break;
    }
  }

  return version;
}

static std::string VersionToString(GLConnection::Version version) {
  if (version.major == 0 && version.minor == 0 && version.release == 0) {
    return "Unknown";
  }

  std::stringstream stream;

  stream << version.major << "." << version.minor;

  if (version.release != 0) {
    stream << "." << version.release;
  }

  if (version.vendorString.size() != 0) {
    stream << " " << version.vendorString;
  }

  if (version.isES) {
    stream << " ES";
  }

  return stream.str();
}

GLConnection::GLConnection()
    : vendor_(GLGetString(GL_VENDOR)),
      renderer_(GLGetString(GL_RENDERER)),
      version_(GLGetVersion(GL_VERSION)),
      shading_language_version_(GLGetVersion(GL_SHADING_LANGUAGE_VERSION)) {
  std::istringstream extensionsStream(GLGetString(GL_EXTENSIONS));
  extensionsStream >> std::skipws;
  std::string extension;
  while (extensionsStream >> extension) {
    extensions_.emplace(std::move(extension));
  }
}

GLConnection::~GLConnection() = default;

const std::string& GLConnection::Vendor() const {
  return vendor_;
}

const std::string& GLConnection::Renderer() const {
  return renderer_;
}

const GLConnection::Version& GLConnection::GLVersion() const {
  return version_;
}

std::string GLConnection::VersionString() const {
  return VersionToString(version_);
}

const GLConnection::Version& GLConnection::ShadingLanguageVersion() const {
  return shading_language_version_;
}

std::string GLConnection::ShadingLanguageVersionString() const {
  return VersionToString(shading_language_version_);
}

std::string GLConnection::Platform() const {
  std::stringstream stream;
  stream << Vendor() << ": " << Renderer();
  return stream.str();
}

const std::set<std::string>& GLConnection::Extensions() const {
  return extensions_;
}

std::string GLConnection::Description() const {
  std::vector<std::pair<std::string, std::string>> items;

  items.emplace_back("Vendor", Vendor());
  items.emplace_back("Renderer", Renderer());
  items.emplace_back("Version", VersionString());
  items.emplace_back("Shader Version", ShadingLanguageVersionString());

  std::string extensionsLabel("Extensions");

  size_t padding = extensionsLabel.size();

  for (const auto& item : items) {
    padding = std::max(padding, item.first.size());
  }

  padding += 1;

  std::stringstream stream;

  stream << std::endl;

  for (const auto& item : items) {
    stream << std::setw(padding) << item.first << std::setw(0) << ": "
           << item.second << std::endl;
  }

  if (extensions_.size() != 0) {
    std::string paddingString;
    paddingString.resize(padding + 2, ' ');

    stream << std::setw(padding) << extensionsLabel << std::setw(0) << ": "
           << extensions_.size() << " Available" << std::endl;

    for (const auto& extension : extensions_) {
      stream << paddingString << extension << std::endl;
    }
  }

  return stream.str();
}

}  // namespace flow
