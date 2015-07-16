// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_VERSION_INFO_H_
#define UI_GL_GL_VERSION_INFO_H_

#include <string>
#include "base/basictypes.h"
#include "ui/gl/gl_export.h"

namespace gfx {

struct GL_EXPORT GLVersionInfo {
  GLVersionInfo(const char* version_str, const char* renderer_str);

  bool IsAtLeastGL(unsigned major, unsigned minor) const {
    return !is_es && (major_version > major ||
                      (major_version == major && minor_version >= minor));
  }

  bool IsLowerThanGL(unsigned major, unsigned minor) const {
    return !is_es && (major_version < major ||
                      (major_version == major && minor_version < minor));
  }

  bool IsAtLeastGLES(unsigned major, unsigned minor) const {
    return is_es && (major_version > major ||
                     (major_version == major && minor_version >= minor));
  }

  bool is_es;
  bool is_angle;
  unsigned major_version;
  unsigned minor_version;
  bool is_es3;

 private:
  DISALLOW_COPY_AND_ASSIGN(GLVersionInfo);
};

}  // namespace gfx

#endif // UI_GL_GL_VERSION_INFO_H_
