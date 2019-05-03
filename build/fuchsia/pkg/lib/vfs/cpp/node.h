// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_NODE_H_
#define LIB_VFS_CPP_NODE_H_

#include <fuchsia/io/cpp/fidl.h>
#include <lib/async/dispatcher.h>
#include <lib/fidl/cpp/binding.h>
#include <limits.h>

namespace vfs {

bool IsValidName(const std::string& name);

class Connection;

// An object in a file system.
//
// Implements the |fuchsia.io.Node| interface. Incoming connections are owned by
// this object and will be destroyed when this object is destroyed.
//
// Subclass to implement a particular kind of file system object.
//
// See also:
//
//  * File, which is a subclass for file objects.
//  * Directory, which is a subclass for directory objects.
//
// This class is thread safe.
class Node {
 public:
  Node();
  virtual ~Node();

  Node(const Node&) = delete;
  Node& operator=(const Node&) = delete;

  // Notifies |Node| that it should remove and return
  // |connection| from its list as it is getting closed.
  virtual std::unique_ptr<Connection> Close(Connection* connection);

  // Implementation of |fuchsia.io.Node/Describe|.
  //
  // Subclass must override this method to describe themselves accurately.
  virtual void Describe(fuchsia::io::NodeInfo* out_info) = 0;

  // Implementation of |fuchsia.io.Node/Sync|.
  virtual zx_status_t Sync();

  // Implementation of |fuchsia.io.Node/GetAttr|.
  virtual zx_status_t GetAttr(
      fuchsia::io::NodeAttributes* out_attributes) const;

  // Implementation of |fuchsia.io.Node/SetAttr|.
  virtual zx_status_t SetAttr(uint32_t flags,
                              const fuchsia::io::NodeAttributes& attributes);

  // Implementation of |fuchsia.io.Node/Clone|.
  virtual void Clone(uint32_t flags, uint32_t parent_flags,
                     fidl::InterfaceRequest<fuchsia::io::Node> object,
                     async_dispatcher_t* dispatcher);

  // Validate flags on |Serve|.
  //
  // Returns |ZX_ERR_NOT_DIR| if |OPEN_FLAG_DIRECTORY| is set and |IsDirectory|
  // returns false.
  //
  // Calls |GetProhibitiveFlags| flags and if one of the flag is in prohibitive
  // list, returns |ZX_ERR_INVALID_ARGS|.
  //
  // Calls |GetAdditionalAllowedFlags|, appends |OPEN_FLAG_DESCRIBE|,
  // |OPEN_FLAG_NODE_REFERENCE|, |OPEN_FLAG_DIRECTORY| (only if |IsDirectory|
  // returns true) to those flags and returns |ZX_ERR_NOT_SUPPORTED| if flags
  // are not found in allowed list.
  //
  // Returns ZX_OK if none of the above cases are true.
  zx_status_t ValidateFlags(uint32_t flags) const;

  // Validate flags on |ServeWithMode|.
  //
  // Calls |GetAttr| and checks that mode should not be anything other than
  // |MODE_PROTECTION_MASK| and one in attr. Returns |ZX_ERR_INVALID_ARGS| if it
  // is, else returns |ZX_OK|.
  zx_status_t ValidateMode(uint32_t mode) const;

  // Establishes a connection for |request| using the given |flags|.
  //
  // Waits for messages asynchronously on the |request| channel using
  // |dispatcher|. If |dispatcher| is |nullptr|, the implementation will call
  // |async_get_default_dispatcher| to obtain the default dispatcher for the
  // current thread.
  //
  // Calls |Connect| after validating flags and modes.
  zx_status_t Serve(uint32_t flags, zx::channel request,
                    async_dispatcher_t* dispatcher = nullptr);

  // Validates |mode| and passes request to serve
  //
  // Would be called by |Open|.
  zx_status_t ServeWithMode(uint32_t flags, uint32_t mode, zx::channel request,
                            async_dispatcher_t* dispatcher = nullptr);

  // Find an entry in this directory with the given |name|.
  //
  // The entry is returned via |out_node|. The returned entry is owned by this
  // directory.
  //
  // Returns |ZX_ERR_NOT_FOUND| if no entry exists.
  // Default implementation in this class return |ZX_ERR_NOT_DIR| if
  // |IsDirectory| is false, else throws error with |ZX_ASSERT|.
  //
  // All directory types should implement this method.
  virtual zx_status_t Lookup(const std::string& name, Node** out_node) const;

  // Return true if |Node| is a remote node.
  // This function is used in |Directory::Open| to correctly open those kind of
  // nodes.
  virtual bool IsRemote() const;

 protected:
  // Called by |Serve| after validating flags and modes.
  // This should be implemented by sub classes which doesn't create a
  // connection class.
  //
  // Default implementation:
  // Uses |CreateConnection| to create a connection appropriate for the
  // concrete type of this object.
  virtual zx_status_t Connect(uint32_t flags, zx::channel request,
                              async_dispatcher_t* dispatcher);

  // Filters out flags that are invalid when combined with
  // |OPEN_FLAG_NODE_REFERENCE|.
  // Allowed flags are |OPEN_FLAG_DIRECTORY| and |OPEN_FLAG_DESCRIBE|.
  uint32_t FilterRefFlags(uint32_t flags);

  // Sends OnOpen event on error status if |OPEN_FLAG_DESCRIBE| is set.
  void SendOnOpenEventOnError(uint32_t flags, zx::channel request,
                              zx_status_t status);

  // Store given connection.
  void AddConnection(std::unique_ptr<Connection> connection);

  // Creates a |Connection| appropriate for the concrete type of this object.
  //
  // Subclasses must override this method to create an appropriate connection.
  // The returned connection should be in an "unbound" state.
  //
  // Typically called by |Serve|.
  virtual zx_status_t CreateConnection(
      uint32_t flags, std::unique_ptr<Connection>* connection) = 0;

  // Return true if |Node| is a directory.
  // This function is used in |ValidateFlags| and |Lookup| to return correct
  // error.
  //
  // This should be overridden by every implementation.
  virtual bool IsDirectory() const = 0;

  // Additional Allowed flags for use in |ValidateFlags|.
  //
  // See documentation of  |ValidateFlags| for exact details.
  virtual uint32_t GetAdditionalAllowedFlags() const;

  // Prohibitive flags use in |ValidateFlags|.
  //
  // See documentation of  |ValidateFlags| for exact details.
  virtual uint32_t GetProhibitiveFlags() const;

  // guards connection_
  mutable std::mutex mutex_;
  // The active connections associated with this object.
  std::vector<std::unique_ptr<Connection>> connections_ __TA_GUARDED(mutex_);
};

}  // namespace vfs

#endif  // LIB_VFS_CPP_NODE_H_
