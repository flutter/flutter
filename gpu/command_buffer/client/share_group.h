// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_SHARE_GROUP_H_
#define GPU_COMMAND_BUFFER_CLIENT_SHARE_GROUP_H_

#include <GLES2/gl2.h>
#include "base/memory/scoped_ptr.h"
#include "gles2_impl_export.h"
#include "gpu/command_buffer/client/ref_counted.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"

namespace gpu {
namespace gles2 {

class GLES2Implementation;
class GLES2ImplementationTest;
class ProgramInfoManager;

typedef void (GLES2Implementation::*DeleteFn)(GLsizei n, const GLuint* ids);
typedef void (GLES2Implementation::*BindFn)(GLenum target, GLuint id);
typedef void (GLES2Implementation::*BindIndexedFn)( \
    GLenum target, GLuint index, GLuint id);
typedef void (GLES2Implementation::*BindIndexedRangeFn)( \
    GLenum target, GLuint index, GLuint id, GLintptr offset, GLsizeiptr size);

class ShareGroupContextData {
 public:
  struct IdHandlerData {
    IdHandlerData();
    ~IdHandlerData();

    std::vector<GLuint> freed_ids_;
    uint32 flush_generation_;
  };

  IdHandlerData* id_handler_data(int namespace_id) {
    return &id_handler_data_[namespace_id];
  }

 private:
  IdHandlerData id_handler_data_[id_namespaces::kNumIdNamespaces];
};

// Base class for IdHandlers
class IdHandlerInterface {
 public:
  IdHandlerInterface() { }
  virtual ~IdHandlerInterface() { }

  // Makes some ids at or above id_offset.
  virtual void MakeIds(
      GLES2Implementation* gl_impl,
      GLuint id_offset, GLsizei n, GLuint* ids) = 0;

  // Frees some ids.
  virtual bool FreeIds(
      GLES2Implementation* gl_impl, GLsizei n, const GLuint* ids,
      DeleteFn delete_fn) = 0;

  // Marks an id as used for glBind functions. id = 0 does nothing.
  virtual bool MarkAsUsedForBind(
      GLES2Implementation* gl_impl,
      GLenum target,
      GLuint id,
      BindFn bind_fn) = 0;
  // This is for glBindBufferBase.
  virtual bool MarkAsUsedForBind(
      GLES2Implementation* gl_impl,
      GLenum target,
      GLuint index,
      GLuint id,
      BindIndexedFn bind_fn) = 0;
  // This is for glBindBufferRange.
  virtual bool MarkAsUsedForBind(
      GLES2Implementation* gl_impl,
      GLenum target,
      GLuint index,
      GLuint id,
      GLintptr offset,
      GLsizeiptr size,
      BindIndexedRangeFn bind_fn) = 0;

  // Called when a context in the share group is destructed.
  virtual void FreeContext(GLES2Implementation* gl_impl) = 0;
};

// ShareGroup manages shared resources for contexts that are sharing resources.
class GLES2_IMPL_EXPORT ShareGroup
    : public gpu::RefCountedThreadSafe<ShareGroup> {
 public:
  ShareGroup(bool bind_generates_resource);

  bool bind_generates_resource() const {
    return bind_generates_resource_;
  }

  IdHandlerInterface* GetIdHandler(int namespace_id) const {
    return id_handlers_[namespace_id].get();
  }

  ProgramInfoManager* program_info_manager() {
    return program_info_manager_.get();
  }

  void FreeContext(GLES2Implementation* gl_impl) {
    for (int i = 0; i < id_namespaces::kNumIdNamespaces; ++i) {
      id_handlers_[i]->FreeContext(gl_impl);
    }
  }

 private:
  friend class gpu::RefCountedThreadSafe<ShareGroup>;
  friend class gpu::gles2::GLES2ImplementationTest;
  ~ShareGroup();

  // Install a new program info manager. Used for testing only;
  void set_program_info_manager(ProgramInfoManager* manager);

  scoped_ptr<IdHandlerInterface> id_handlers_[id_namespaces::kNumIdNamespaces];
  scoped_ptr<ProgramInfoManager> program_info_manager_;

  bool bind_generates_resource_;

  DISALLOW_COPY_AND_ASSIGN(ShareGroup);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_SHARE_GROUP_H_
