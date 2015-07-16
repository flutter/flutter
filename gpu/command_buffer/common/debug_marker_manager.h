// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_DEBUG_MARKER_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_DEBUG_MARKER_MANAGER_H_

#include <stack>
#include <string>
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

// Tracks debug marker.
class GPU_EXPORT DebugMarkerManager {
 public:
   DebugMarkerManager();
   ~DebugMarkerManager();

  // Gets the current marker on the top group.
  const std::string& GetMarker() const;
  // Sets the current marker on the top group.
  void SetMarker(const std::string& marker);
  // Pushes a new group.
  void PushGroup(const std::string& name);
  // Removes the top group. This is safe to call even when stack is empty.
  void PopGroup(void);

 private:
  // Info about Buffers currently in the system.
  class Group {
   public:
    explicit Group(const std::string& name);
    ~Group();

    const std::string& name() const {
      return name_;
    }

    void SetMarker(const std::string& marker);

    const std::string& marker() const {
      return marker_;
    }

   private:
    std::string name_;
    std::string marker_;
  };

  typedef std::stack<Group> GroupStack;

  GroupStack group_stack_;
  std::string empty_;
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_DEBUG_MARKER_MANAGER_H_

