// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_CONFIGURATION_H_
#define MOJO_EDK_EMBEDDER_CONFIGURATION_H_

#include <stddef.h>

namespace mojo {
namespace embedder {

// A set of constants that the Mojo system internally uses. These values should
// be consistent across all processes on the same system.
//
// In general, there should be no need to change these values from their
// defaults. However, if you do change them, you must do so before
// initialization.
struct Configuration {
  // Maximum number of open (Mojo) handles. The default is 1,000,000.
  //
  // TODO(vtl): This doesn't count "live" handles, some of which may live in
  // messages.
  size_t max_handle_table_size;

  // Maximum number of active memory mappings. The default is 1,000,000.
  size_t max_mapping_table_sze;

  // Upper limit of |MojoWaitMany()|'s |num_handles|. The default is 1,000,000.
  // Must be same as or smaller than |max_handle_table_size|.
  size_t max_wait_many_num_handles;

  // Maximum data size of messages sent over message pipes, in bytes. The
  // default is 4MB.
  size_t max_message_num_bytes;

  // Maximum number of handles that can be attached to messages sent over
  // message pipes. The default is 10,000.
  size_t max_message_num_handles;

  // Maximum capacity of a data pipe, in bytes. The default is 256MB. This value
  // must fit into a |uint32_t|. WARNING: If you bump it closer to 2^32, you
  // must audit all the code to check that we don't overflow (2^31 would
  // definitely be risky; up to 2^30 is probably okay).
  size_t max_data_pipe_capacity_bytes;

  // Default data pipe capacity, if not specified explicitly in the creation
  // options. The default is 1MB.
  size_t default_data_pipe_capacity_bytes;

  // Alignment for the "start" of the data buffer used by data pipes. (The
  // alignment of elements will depend on this and the element size.)  The
  // default is 16 bytes.
  size_t data_pipe_buffer_alignment_bytes;

  // Maximum size of a single shared memory segment, in bytes. The default is
  // 1GB.
  //
  // TODO(vtl): Set this hard limit appropriately (e.g., higher on 64-bit).
  // (This will also entail some auditing to make sure I'm not messing up my
  // checks anywhere.)
  size_t max_shared_memory_num_bytes;
};

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_CONFIGURATION_H_
