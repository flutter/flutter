// Copyright (c) 2007, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---
// Author: Sanjay Ghemawat
//         Chris Demetriou (refactoring)
//
// Collect profiling data.

#include <config.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/time.h>
#include <string.h>
#include <fcntl.h>

#include "profiledata.h"

#include "base/logging.h"
#include "base/sysinfo.h"

// All of these are initialized in profiledata.h.
const int ProfileData::kMaxStackDepth;
const int ProfileData::kAssociativity;
const int ProfileData::kBuckets;
const int ProfileData::kBufferLength;

ProfileData::Options::Options()
    : frequency_(1) {
}

// This function is safe to call from asynchronous signals (but is not
// re-entrant).  However, that's not part of its public interface.
void ProfileData::Evict(const Entry& entry) {
  const int d = entry.depth;
  const int nslots = d + 2;     // Number of slots needed in eviction buffer
  if (num_evicted_ + nslots > kBufferLength) {
    FlushEvicted();
    assert(num_evicted_ == 0);
    assert(nslots <= kBufferLength);
  }
  evict_[num_evicted_++] = entry.count;
  evict_[num_evicted_++] = d;
  memcpy(&evict_[num_evicted_], entry.stack, d * sizeof(Slot));
  num_evicted_ += d;
}

ProfileData::ProfileData()
    : hash_(0),
      evict_(0),
      num_evicted_(0),
      out_(-1),
      count_(0),
      evictions_(0),
      total_bytes_(0),
      fname_(0),
      start_time_(0) {
}

bool ProfileData::Start(const char* fname,
                        const ProfileData::Options& options) {
  if (enabled()) {
    return false;
  }

  // Open output file and initialize various data structures
  int fd = open(fname, O_CREAT | O_WRONLY | O_TRUNC, 0666);
  if (fd < 0) {
    // Can't open outfile for write
    return false;
  }

  start_time_ = time(NULL);
  fname_ = strdup(fname);

  // Reset counters
  num_evicted_ = 0;
  count_       = 0;
  evictions_   = 0;
  total_bytes_ = 0;

  hash_ = new Bucket[kBuckets];
  evict_ = new Slot[kBufferLength];
  memset(hash_, 0, sizeof(hash_[0]) * kBuckets);

  // Record special entries
  evict_[num_evicted_++] = 0;                     // count for header
  evict_[num_evicted_++] = 3;                     // depth for header
  evict_[num_evicted_++] = 0;                     // Version number
  CHECK_NE(0, options.frequency());
  int period = 1000000 / options.frequency();
  evict_[num_evicted_++] = period;                // Period (microseconds)
  evict_[num_evicted_++] = 0;                     // Padding

  out_ = fd;

  return true;
}

ProfileData::~ProfileData() {
  Stop();
}

// Dump /proc/maps data to fd.  Copied from heap-profile-table.cc.
#define NO_INTR(fn)  do {} while ((fn) < 0 && errno == EINTR)

static void FDWrite(int fd, const char* buf, size_t len) {
  while (len > 0) {
    ssize_t r;
    NO_INTR(r = write(fd, buf, len));
    RAW_CHECK(r >= 0, "write failed");
    buf += r;
    len -= r;
  }
}

static void DumpProcSelfMaps(int fd) {
  ProcMapsIterator::Buffer iterbuf;
  ProcMapsIterator it(0, &iterbuf);   // 0 means "current pid"

  uint64 start, end, offset;
  int64 inode;
  char *flags, *filename;
  ProcMapsIterator::Buffer linebuf;
  while (it.Next(&start, &end, &flags, &offset, &inode, &filename)) {
    int written = it.FormatLine(linebuf.buf_, sizeof(linebuf.buf_),
                                start, end, flags, offset, inode, filename,
                                0);
    FDWrite(fd, linebuf.buf_, written);
  }
}

void ProfileData::Stop() {
  if (!enabled()) {
    return;
  }

  // Move data from hash table to eviction buffer
  for (int b = 0; b < kBuckets; b++) {
    Bucket* bucket = &hash_[b];
    for (int a = 0; a < kAssociativity; a++) {
      if (bucket->entry[a].count > 0) {
        Evict(bucket->entry[a]);
      }
    }
  }

  if (num_evicted_ + 3 > kBufferLength) {
    // Ensure there is enough room for end of data marker
    FlushEvicted();
  }

  // Write end of data marker
  evict_[num_evicted_++] = 0;         // count
  evict_[num_evicted_++] = 1;         // depth
  evict_[num_evicted_++] = 0;         // end of data marker
  FlushEvicted();

  // Dump "/proc/self/maps" so we get list of mapped shared libraries
  DumpProcSelfMaps(out_);

  Reset();
  fprintf(stderr, "PROFILE: interrupts/evictions/bytes = %d/%d/%" PRIuS "\n",
          count_, evictions_, total_bytes_);
}

void ProfileData::Reset() {
  if (!enabled()) {
    return;
  }

  // Don't reset count_, evictions_, or total_bytes_ here.  They're used
  // by Stop to print information about the profile after reset, and are
  // cleared by Start when starting a new profile.
  close(out_);
  delete[] hash_;
  hash_ = 0;
  delete[] evict_;
  evict_ = 0;
  num_evicted_ = 0;
  free(fname_);
  fname_ = 0;
  start_time_ = 0;

  out_ = -1;
}

// This function is safe to call from asynchronous signals (but is not
// re-entrant).  However, that's not part of its public interface.
void ProfileData::GetCurrentState(State* state) const {
  if (enabled()) {
    state->enabled = true;
    state->start_time = start_time_;
    state->samples_gathered = count_;
    int buf_size = sizeof(state->profile_name);
    strncpy(state->profile_name, fname_, buf_size);
    state->profile_name[buf_size-1] = '\0';
  } else {
    state->enabled = false;
    state->start_time = 0;
    state->samples_gathered = 0;
    state->profile_name[0] = '\0';
  }
}

// This function is safe to call from asynchronous signals (but is not
// re-entrant).  However, that's not part of its public interface.
void ProfileData::FlushTable() {
  if (!enabled()) {
    return;
  }

  // Move data from hash table to eviction buffer
  for (int b = 0; b < kBuckets; b++) {
    Bucket* bucket = &hash_[b];
    for (int a = 0; a < kAssociativity; a++) {
      if (bucket->entry[a].count > 0) {
        Evict(bucket->entry[a]);
        bucket->entry[a].depth = 0;
        bucket->entry[a].count = 0;
      }
    }
  }

  // Write out all pending data
  FlushEvicted();
}

void ProfileData::Add(int depth, const void* const* stack) {
  if (!enabled()) {
    return;
  }

  if (depth > kMaxStackDepth) depth = kMaxStackDepth;
  RAW_CHECK(depth > 0, "ProfileData::Add depth <= 0");

  // Make hash-value
  Slot h = 0;
  for (int i = 0; i < depth; i++) {
    Slot slot = reinterpret_cast<Slot>(stack[i]);
    h = (h << 8) | (h >> (8*(sizeof(h)-1)));
    h += (slot * 31) + (slot * 7) + (slot * 3);
  }

  count_++;

  // See if table already has an entry for this trace
  bool done = false;
  Bucket* bucket = &hash_[h % kBuckets];
  for (int a = 0; a < kAssociativity; a++) {
    Entry* e = &bucket->entry[a];
    if (e->depth == depth) {
      bool match = true;
      for (int i = 0; i < depth; i++) {
        if (e->stack[i] != reinterpret_cast<Slot>(stack[i])) {
          match = false;
          break;
        }
      }
      if (match) {
        e->count++;
        done = true;
        break;
      }
    }
  }

  if (!done) {
    // Evict entry with smallest count
    Entry* e = &bucket->entry[0];
    for (int a = 1; a < kAssociativity; a++) {
      if (bucket->entry[a].count < e->count) {
        e = &bucket->entry[a];
      }
    }
    if (e->count > 0) {
      evictions_++;
      Evict(*e);
    }

    // Use the newly evicted entry
    e->depth = depth;
    e->count = 1;
    for (int i = 0; i < depth; i++) {
      e->stack[i] = reinterpret_cast<Slot>(stack[i]);
    }
  }
}

// This function is safe to call from asynchronous signals (but is not
// re-entrant).  However, that's not part of its public interface.
void ProfileData::FlushEvicted() {
  if (num_evicted_ > 0) {
    const char* buf = reinterpret_cast<char*>(evict_);
    size_t bytes = sizeof(evict_[0]) * num_evicted_;
    total_bytes_ += bytes;
    FDWrite(out_, buf, bytes);
  }
  num_evicted_ = 0;
}
