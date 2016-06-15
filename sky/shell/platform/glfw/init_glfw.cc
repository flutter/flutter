// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/glfw/init_glfw.h"

#include <GLFW/glfw3.h>
#include <memory>
#include <string>

#include "base/command_line.h"
#include "sky/shell/platform/glfw/platform_view_glfw.h"
#include "sky/shell/platform/glfw/window_impl.h"
#include "sky/shell/switches.h"
#include "ui/gl/gl_surface.h"

namespace sky {
namespace shell {

static bool IsDartFile(const std::string& script_uri) {
  std::string dart_extension = ".dart";
  return script_uri.rfind(dart_extension) ==
         (script_uri.size() - dart_extension.size());
}

bool InitInteractive() {
  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  auto args = command_line.GetArgs();
  if (args.empty())
    return false;

  std::string bundle_path =
      command_line.GetSwitchValueASCII(sky::shell::switches::kFLX);

  if (bundle_path.empty()) {
    // Alternatively, use the first positional argument.
    bundle_path = args[0];
  }

  if (bundle_path.empty())
    return false;

  if (!glfwInit())
    return false;

  GLFWwindow* window = glfwCreateWindow(640, 480, "Flutter", NULL, NULL);
  if (!window) {
    glfwTerminate();
    return false;
  }

  glfwMakeContextCurrent(window);
  CHECK(gfx::GLSurface::InitializeOneOff());
  glfwMakeContextCurrent(NULL);

  if (IsDartFile(bundle_path)) {
    // Load directly from source.
    // TODO(abarth): Listen for a GLFW callback to delete this window.
    (new WindowImpl(window))->RunFromFile(bundle_path);
  } else {
    std::string script_uri = std::string("file://") + bundle_path;
    // Load from a bundle.
    // TODO(abarth): Listen for a GLFW callback to delete this window.
    (new WindowImpl(window))->RunFromBundle(script_uri, bundle_path);
  }
  return true;
}


}  // namespace shell
}  // namespace sky
