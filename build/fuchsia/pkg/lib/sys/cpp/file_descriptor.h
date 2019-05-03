// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_SYS_CPP_FILE_DESCRIPTOR_H_
#define LIB_SYS_CPP_FILE_DESCRIPTOR_H_

#include <fuchsia/sys/cpp/fidl.h>

namespace sys {

// Clone the given file descriptor as a |fuchsia::sys::FileDescriptorPtr|.
//
// For example, the returned |fuchsia::sys::FileDescriptorPtr| is suitable for
// use as the stdout or stderr when creating a component. To obtain only a
// |zx_handle_t|, consider calling |fdio_fd_clone| directory instead.
//
// Returns |nullptr| if |fd| is invalid or cannot be cloned.
fuchsia::sys::FileDescriptorPtr CloneFileDescriptor(int fd);

}  // namespace sys

#endif  // LIB_SYS_CPP_FILE_DESCRIPTOR_H_

