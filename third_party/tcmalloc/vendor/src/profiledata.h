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
//
// The profile data file format is documented in
// doc/cpuprofile-fileformat.html


#ifndef BASE_PROFILEDATA_H_
#define BASE_PROFILEDATA_H_

#include <config.h>
#include <time.h>   // for time_t
#include <stdint.h>
#include "base/basictypes.h"

// A class that accumulates profile samples and writes them to a file.
//
// Each sample contains a stack trace and a count.  Memory usage is
// reduced by combining profile samples that have the same stack trace
// by adding up the associated counts.
//
// Profile data is accumulated in a bounded amount of memory, and will
// flushed to a file as necessary to stay within the memory limit.
//
// Use of this class assumes external synchronization.  The exact
// requirements of that synchronization are that:
//
//  - 'Add' may be called from asynchronous signals, but is not
//    re-entrant.
//
//  - None of 'Start', 'Stop', 'Reset', 'Flush', and 'Add' may be
//    called at the same time.
//
//  - 'Start', 'Stop', or 'Reset' should not be called while 'Enabled'
//     or 'GetCurrent' are running, and vice versa.
//
// A profiler which uses asyncronous signals to add samples will
// typically use two locks to protect this data structure:
//
//  - A SpinLock which is held over all calls except for the 'Add'
//    call made from the signal handler.
//
//  - A SpinLock which is held over calls to 'Start', 'Stop', 'Reset',
//    'Flush', and 'Add'.  (This SpinLock should be acquired after
//    the first SpinLock in all cases where both are needed.)
class ProfileData {
 public:
  struct State {
    bool     enabled;             // Is profiling currently enabled?
    time_t   start_time;          // If enabled, when was profiling started?
    char     profile_name[1024];  // Name of file being written, or '\0'
    int      samples_gathered;    // Number of samples gathered to far (or 0)
  };

  class Options {
   public:
    Options();

    // Get and set the sample frequency.
    int frequency() const {
      return frequency_;
    }
    void set_frequency(int frequency) {
      frequency_ = frequency;
    }

   private:
    int      frequency_;                  // Sample frequency.
  };

  static const int kMaxStackDepth = 64;  // Max stack depth stored in profile

  ProfileData();
  ~ProfileData();

  // If data collection is not already enabled start to collect data
  // into fname.  Parameters related to this profiling run are specified
  // by 'options'.
  //
  // Returns true if data collection could be started, otherwise (if an
  // error occurred or if data collection was already enabled) returns
  // false.
  bool Start(const char *fname, const Options& options);

  // If data collection is enabled, stop data collection and write the
  // data to disk.
  void Stop();

  // Stop data collection without writing anything else to disk, and
  // discard any collected data.
  void Reset();

  // If data collection is enabled, record a sample with 'depth'
  // entries from 'stack'.  (depth must be > 0.)  At most
  // kMaxStackDepth stack entries will be recorded, starting with
  // stack[0].
  //
  // This function is safe to call from asynchronous signals (but is
  // not re-entrant).
  void Add(int depth, const void* const* stack);

  // If data collection is enabled, write the data to disk (and leave
  // the collector enabled).
  void FlushTable();

  // Is data collection currently enabled?
  bool enabled() const { return out_ >= 0; }

  // Get the current state of the data collector.
  void GetCurrentState(State* state) const;

 private:
  static const int kAssociativity = 4;          // For hashtable
  static const int kBuckets = 1 << 10;          // For hashtable
  static const int kBufferLength = 1 << 18;     // For eviction buffer

  // Type of slots: each slot can be either a count, or a PC value
  typedef uintptr_t Slot;

  // Hash-table/eviction-buffer entry (a.k.a. a sample)
  struct Entry {
    Slot count;                  // Number of hits
    Slot depth;                  // Stack depth
    Slot stack[kMaxStackDepth];  // Stack contents
  };

  // Hash table bucket
  struct Bucket {
    Entry entry[kAssociativity];
  };

  Bucket*       hash_;          // hash table
  Slot*         evict_;         // evicted entries
  int           num_evicted_;   // how many evicted entries?
  int           out_;           // fd for output file.
  int           count_;         // How many samples recorded
  int           evictions_;     // How many evictions
  size_t        total_bytes_;   // How much output
  char*         fname_;         // Profile file name
  time_t        start_time_;    // Start time, or 0

  // Move 'entry' to the eviction buffer.
  void Evict(const Entry& entry);

  // Write contents of eviction buffer to disk.
  void FlushEvicted();

  DISALLOW_COPY_AND_ASSIGN(ProfileData);
};

#endif  // BASE_PROFILEDATA_H_
