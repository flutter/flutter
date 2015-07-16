// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/posix/file_descriptor_shuffle.h"

#include <unistd.h>
#include <stddef.h>
#include <ostream>

#include "base/posix/eintr_wrapper.h"
#include "base/logging.h"

namespace base {

bool PerformInjectiveMultimapDestructive(
    InjectiveMultimap* m, InjectionDelegate* delegate) {
  static const size_t kMaxExtraFDs = 16;
  int extra_fds[kMaxExtraFDs];
  unsigned next_extra_fd = 0;

  // DANGER: this function must not allocate or lock.
  // Cannot use STL iterators here, since debug iterators use locks.

  for (size_t i_index = 0; i_index < m->size(); ++i_index) {
    InjectiveMultimap::value_type* i = &(*m)[i_index];
    int temp_fd = -1;

    // We DCHECK the injectiveness of the mapping.
    for (size_t j_index = i_index + 1; j_index < m->size(); ++j_index) {
      InjectiveMultimap::value_type* j = &(*m)[j_index];
      DCHECK(i->dest != j->dest) << "Both fd " << i->source
          << " and " << j->source << " map to " << i->dest;
    }

    const bool is_identity = i->source == i->dest;

    for (size_t j_index = i_index + 1; j_index < m->size(); ++j_index) {
      InjectiveMultimap::value_type* j = &(*m)[j_index];
      if (!is_identity && i->dest == j->source) {
        if (temp_fd == -1) {
          if (!delegate->Duplicate(&temp_fd, i->dest))
            return false;
          if (next_extra_fd < kMaxExtraFDs) {
            extra_fds[next_extra_fd++] = temp_fd;
          } else {
            RAW_LOG(ERROR, "PerformInjectiveMultimapDestructive overflowed "
                           "extra_fds. Leaking file descriptors!");
          }
        }

        j->source = temp_fd;
        j->close = false;
      }

      if (i->close && i->source == j->dest)
        i->close = false;

      if (i->close && i->source == j->source) {
        i->close = false;
        j->close = true;
      }
    }

    if (!is_identity) {
      if (!delegate->Move(i->source, i->dest))
        return false;
    }

    if (!is_identity && i->close)
      delegate->Close(i->source);
  }

  for (unsigned i = 0; i < next_extra_fd; i++)
    delegate->Close(extra_fds[i]);

  return true;
}

bool PerformInjectiveMultimap(const InjectiveMultimap& m_in,
                              InjectionDelegate* delegate) {
  InjectiveMultimap m(m_in);
  return PerformInjectiveMultimapDestructive(&m, delegate);
}

bool FileDescriptorTableInjection::Duplicate(int* result, int fd) {
  *result = HANDLE_EINTR(dup(fd));
  return *result >= 0;
}

bool FileDescriptorTableInjection::Move(int src, int dest) {
  return HANDLE_EINTR(dup2(src, dest)) != -1;
}

void FileDescriptorTableInjection::Close(int fd) {
  int ret = IGNORE_EINTR(close(fd));
  DPCHECK(ret == 0);
}

}  // namespace base
