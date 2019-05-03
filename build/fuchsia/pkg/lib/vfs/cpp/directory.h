
// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_DIRECTORY_H_
#define LIB_VFS_CPP_DIRECTORY_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/vfs/cpp/node.h>
#include <stdint.h>

#include <string>

namespace vfs {

// A directory object in a file system.
//
// Implements the |fuchsia.io.Directory| interface. Incoming connections are
// owned by this object and will be destroyed when this object is destroyed.
//
// Subclass to implement specific directory semantics.
//
// See also:
//
//  * File, which represents file objects.
class Directory : public Node {
 public:
  Directory();
  ~Directory() override;

  // |Node| implementation
  zx_status_t Lookup(const std::string& name, Node** out_node) const override;

  // Override that describes this object as a directory.
  void Describe(fuchsia::io::NodeInfo* out_info) override;

  // Enumerates Directory
  //
  // |offset| will start with 0 and then implementation can set offset as it
  // pleases.
  //
  // Returns |ZX_OK| if able to read atleast one dentry else returns
  // |ZX_ERR_INVALID_ARGS| with |out_actual| as 0 and |out_offset| as |offset|.
  virtual zx_status_t Readdir(uint64_t offset, void* data, uint64_t len,
                              uint64_t* out_offset, uint64_t* out_actual) = 0;

  // Parses path and opens correct node.
  //
  // Called from |fuchsia.io.Directory#Open|.
  void Open(uint32_t flags, uint32_t mode, const char* path, size_t path_len,
            zx::channel request, async_dispatcher_t* dispatcher);

  // Validates passed path
  //
  // Returns |ZX_ERR_INVALID_ARGS| if path_len is more than |NAME_MAX| or if
  // |path| starts with ".." or "/".
  // Returns |ZX_OK| on valid path.
  static zx_status_t ValidatePath(const char* path, size_t path_len);

  // Walks provided path to find first node name in from path and then
  // sets |out_path| and |out_len| to correct position in path beyond current
  // node name and sets |out_key| to node name.
  //
  // Calls |ValidatePath| and returns |status| on error.
  // Sets |out_is_self| to true if path is empty or '.' or './'
  //
  // Supports paths like 'a/./b//.'
  // Supports repetitive '/'
  // Doesn't support 'a/../a/b'
  //
  // eg:
  // path ="a/b/c/d", out_path would be "b/c/d"
  // path =".", out_path would be ""
  // path ="./", out_path would be ""
  // path ="a/b/", out_path would be "b/"
  static zx_status_t WalkPath(const char* path, size_t path_len,
                              const char** out_path, size_t* out_len,
                              std::string* out_key, bool* out_is_self);

 protected:
  zx_status_t CreateConnection(
      uint32_t flags, std::unique_ptr<Connection>* connection) override;

  // Walks path and returns correct |node| inside this and containing directory
  // if found.
  // Sets |out_is_dir| to true if path has '/' or '/.' at the end.
  //
  // This function will return intermidiate node if |IsRemote| on that node is
  // true and will sets |out_path| and |out_len| as rest of the remaining path.
  // For example: if path is /a/b/c/d/f/g and c is a remote node, it will return
  // c in |out_node|, "d/f/g" in |out_path| and |out_len|.
  //
  // Calls |WalkPath| in loop and returns status on error. Returns
  // |ZX_ERR_NOT_DIR| if path tries to search for node within a non-directory
  // node type.
  zx_status_t LookupPath(const char* path, size_t path_len, bool* out_is_dir,
                         Node** out_node, const char** out_path,
                         size_t* out_len);

  bool IsDirectory() const override;

  uint32_t GetAdditionalAllowedFlags() const override;

  uint32_t GetProhibitiveFlags() const override;
};

}  // namespace vfs

#endif  // LIB_VFS_CPP_DIRECTORY_H_
