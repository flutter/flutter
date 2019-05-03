
// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/vfs/cpp/directory.h>

#include <fuchsia/io/cpp/fidl.h>
#include <lib/vfs/cpp/internal/directory_connection.h>
#include <zircon/errors.h>

namespace vfs {

Directory::Directory() = default;

Directory::~Directory() = default;

void Directory::Describe(fuchsia::io::NodeInfo* out_info) {
  out_info->set_directory(fuchsia::io::DirectoryObject());
}

zx_status_t Directory::Lookup(const std::string& name, Node** out_node) const {
  return ZX_ERR_NOT_SUPPORTED;
}

zx_status_t Directory::CreateConnection(
    uint32_t flags, std::unique_ptr<Connection>* connection) {
  *connection = std::make_unique<internal::DirectoryConnection>(flags, this);
  return ZX_OK;
}

uint32_t Directory::GetAdditionalAllowedFlags() const {
  // TODO(ZX-3251): overide this in PseudoDir and Lazydir and remove
  // OPEN_RIGHT_WRITABLE flag.
  return fuchsia::io::OPEN_RIGHT_READABLE | fuchsia::io::OPEN_RIGHT_WRITABLE |
         fuchsia::io::OPEN_FLAG_DIRECTORY;
}

uint32_t Directory::GetProhibitiveFlags() const {
  return fuchsia::io::OPEN_FLAG_CREATE |
         fuchsia::io::OPEN_FLAG_CREATE_IF_ABSENT |
         fuchsia::io::OPEN_FLAG_TRUNCATE | fuchsia::io::OPEN_FLAG_APPEND;
}

bool Directory::IsDirectory() const { return true; }

zx_status_t Directory::ValidatePath(const char* path, size_t path_len) {
  bool starts_with_dot_dot = (path_len > 1 && path[0] == '.' && path[1] == '.');
  if (path_len > NAME_MAX || (path_len == 2 && starts_with_dot_dot) ||
      (path_len > 2 && starts_with_dot_dot && path[2] == '/') ||
      (path_len > 0 && path[0] == '/')) {
    return ZX_ERR_INVALID_ARGS;
  }
  return ZX_OK;
}

zx_status_t Directory::WalkPath(const char* path, size_t path_len,
                                const char** out_path, size_t* out_len,
                                std::string* out_key, bool* out_is_self) {
  *out_path = path;
  *out_len = path_len;
  *out_is_self = false;
  zx_status_t status = ValidatePath(path, path_len);
  if (status != ZX_OK) {
    return status;
  }

  // remove any "./", ".//", etc
  while (path_len > 1 && path[0] == '.' && path[1] == '/') {
    path += 2;
    path_len -= 2;
    size_t index = 0u;
    while (index < path_len && path[index] == '/') {
      index++;
    }
    path += index;
    path_len -= index;
  }

  *out_path = path;
  *out_len = path_len;

  if (path_len == 0 || (path_len == 1 && path[0] == '.')) {
    *out_is_self = true;
    return ZX_OK;
  }

  // Lookup node
  const char* path_end = path + path_len;
  const char* match = std::find(path, path_end, '/');

  if (path_end == match) {
    // "/" not found
    *out_key = std::string(path, path_len);
    *out_len = 0;
    *out_path = path_end;
  } else {
    size_t index = std::distance(path, match);
    *out_key = std::string(path, index);

    // remove all '/'
    while (index < path_len && path[index] == '/') {
      index++;
    }
    *out_len -= index;
    *out_path += index;
  }
  return ZX_OK;
}

zx_status_t Directory::LookupPath(const char* path, size_t path_len,
                                  bool* out_is_dir, Node** out_node,
                                  const char** out_path, size_t* out_len) {
  Node* current_node = this;
  size_t new_path_len = path_len;
  const char* new_path = path;
  *out_is_dir = path_len == 0 || path[path_len - 1] == '/';
  do {
    std::string key;
    bool is_self = false;
    zx_status_t status = WalkPath(new_path, new_path_len, &new_path,
                                  &new_path_len, &key, &is_self);
    if (status != ZX_OK) {
      return status;
    }
    if (is_self) {
      *out_is_dir = true;
      *out_node = current_node;
      return ZX_OK;
    }
    Node* n = nullptr;
    status = current_node->Lookup(key, &n);
    if (status != ZX_OK) {
      return status;
    }
    current_node = n;
    if (current_node->IsRemote()) {
      break;
    }
  } while (new_path_len > 0);

  *out_node = current_node;
  *out_len = new_path_len;
  *out_path = new_path;
  return ZX_OK;
}

void Directory::Open(uint32_t flags, uint32_t mode, const char* path,
                     size_t path_len, zx::channel request,
                     async_dispatcher_t* dispatcher) {
  Node* n = nullptr;
  bool is_dir = false;
  size_t new_path_len = path_len;
  const char* new_path = path;
  zx_status_t status =
      LookupPath(path, path_len, &is_dir, &n, &new_path, &new_path_len);
  if (status != ZX_OK) {
    return SendOnOpenEventOnError(flags, std::move(request), status);
  }
  if (n->IsRemote() && new_path_len > 0) {
    fuchsia::io::DirectoryPtr temp_dir;
    zx_status_t status = n->Serve(fuchsia::io::OPEN_RIGHT_READABLE |
                                      fuchsia::io::OPEN_RIGHT_WRITABLE |
                                      fuchsia::io::OPEN_FLAG_DIRECTORY,
                                  temp_dir.NewRequest().TakeChannel());
    if (status != ZX_OK) {
      return SendOnOpenEventOnError(flags, std::move(request), status);
    }
    temp_dir->Open(
        flags, mode, std::string(new_path, new_path_len),
        fidl::InterfaceRequest<fuchsia::io::Node>(std::move(request)));
    return;
  }

  if (is_dir) {
    // append directory flag
    flags = flags | fuchsia::io::OPEN_FLAG_DIRECTORY;
  }
  n->ServeWithMode(flags, mode, std::move(request), dispatcher);
}

}  // namespace vfs
