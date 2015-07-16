// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_SHARE_GROUP_H_
#define UI_GL_GL_SHARE_GROUP_H_

#include <set>

#include "base/basictypes.h"
#include "base/memory/ref_counted.h"
#include "ui/gl/gl_export.h"

namespace gfx {

class GLContext;

// A group of GL contexts that share an ID namespace.
class GL_EXPORT GLShareGroup : public base::RefCounted<GLShareGroup> {
 public:
  GLShareGroup();

  // These two should only be called from the constructor and destructor of
  // GLContext.
  void AddContext(GLContext* context);
  void RemoveContext(GLContext* context);

  // Returns a handle to any initialized context in the share group or NULL if
  // there are no initialized contexts in the share group.
  void* GetHandle();

  // Returns a pointer to any initialized context in the share group
  // or NULL if there are no initialized contexts in the share group.
  GLContext* GetContext();

  // Sets and returns the unique shared GL context. Used for context
  // virtualization.
  void SetSharedContext(GLContext* context);
  GLContext* GetSharedContext();

 private:
  friend class base::RefCounted<GLShareGroup>;

  ~GLShareGroup();

  // References to GLContext are by raw pointer to avoid a reference count
  // cycle.
  typedef std::set<GLContext*> ContextSet;
  ContextSet contexts_;

  GLContext* shared_context_;

  DISALLOW_COPY_AND_ASSIGN(GLShareGroup);
};

}  // namespace gfx

#endif  // UI_GL_GL_SHARE_GROUP_H_
