// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_GL_CONNECTION_H_
#define FLOW_GL_CONNECTION_H_

#include "lib/ftl/macros.h"
#include "open_gl.h"

#include <string>
#include <set>

#ifdef major
#undef major
#endif

#ifdef minor
#undef minor
#endif

namespace flow {

class GLConnection {
 public:
  struct Version {
    union {
      struct {
        size_t major;
        size_t minor;
        size_t release;
      };
      size_t items[3];
    };

    std::string vendorString;

    bool isES;

    Version() : major(0), minor(0), release(0), isES(false) {}

    Version(size_t theMajor, size_t theMinor, size_t theRelease)
        : major(theMajor), minor(theMinor), release(theRelease), isES(false) {}
  };

  GLConnection();

  ~GLConnection();

  const std::string& Vendor() const;

  const std::string& Renderer() const;

  std::string Platform() const;

  const Version& GLVersion() const;

  std::string VersionString() const;

  const Version& ShadingLanguageVersion() const;

  std::string ShadingLanguageVersionString() const;

  const std::set<std::string>& Extensions() const;

  std::string Description() const;

 private:
  std::string vendor_;
  std::string renderer_;
  Version version_;
  Version shading_language_version_;
  std::set<std::string> extensions_;

  FTL_DISALLOW_COPY_AND_ASSIGN(GLConnection);
};

}  // namespace flow

#endif  // FLOW_GL_CONNECTION_H_