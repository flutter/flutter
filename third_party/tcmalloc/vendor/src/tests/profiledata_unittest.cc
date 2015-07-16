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
// Author: Chris Demetriou
//
// This file contains the unit tests for the ProfileData class.

#if defined HAVE_STDINT_H
#include <stdint.h>             // to get uintptr_t
#elif defined HAVE_INTTYPES_H
#include <inttypes.h>           // another place uintptr_t might be defined
#endif
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <string>

#include "profiledata.h"

#include "base/commandlineflags.h"
#include "base/logging.h"

using std::string;

// Some helpful macros for the test class
#define TEST_F(cls, fn)    void cls :: fn()

namespace {

template<typename T> class scoped_array {
 public:
  scoped_array(T* data) : data_(data) { }
  ~scoped_array() { delete[] data_; }
  T* get() { return data_; }
  T& operator[](int i) { return data_[i]; }
 private:
  T* const data_;
};

// Re-runs fn until it doesn't cause EINTR.
#define NO_INTR(fn)   do {} while ((fn) < 0 && errno == EINTR)

// Read up to "count" bytes from file descriptor "fd" into the buffer
// starting at "buf" while handling short reads and EINTR.  On
// success, return the number of bytes read.  Otherwise, return -1.
static ssize_t ReadPersistent(const int fd, void *buf, const size_t count) {
  CHECK_GE(fd, 0);
  char *buf0 = reinterpret_cast<char *>(buf);
  ssize_t num_bytes = 0;
  while (num_bytes < count) {
    ssize_t len;
    NO_INTR(len = read(fd, buf0 + num_bytes, count - num_bytes));
    if (len < 0) {  // There was an error other than EINTR.
      return -1;
    }
    if (len == 0) {  // Reached EOF.
      break;
    }
    num_bytes += len;
  }
  CHECK(num_bytes <= count);
  return num_bytes;
}

// Thin wrapper around a file descriptor so that the file descriptor
// gets closed for sure.
struct FileDescriptor {
  const int fd_;
  explicit FileDescriptor(int fd) : fd_(fd) {}
  ~FileDescriptor() {
    if (fd_ >= 0) {
      NO_INTR(close(fd_));
    }
  }
  int get() { return fd_; }
};

// must be the same as with ProfileData::Slot.
typedef uintptr_t ProfileDataSlot;

// Quick and dirty function to make a number into a void* for use in a
// sample.
inline void* V(intptr_t x) { return reinterpret_cast<void*>(x); }

// String returned by ProfileDataChecker helper functions to indicate success.
const char kNoError[] = "";

class ProfileDataChecker {
 public:
  ProfileDataChecker() {
    const char* tmpdir = getenv("TMPDIR");
    if (tmpdir == NULL)
      tmpdir = "/tmp";
    mkdir(tmpdir, 0755);     // if necessary
    filename_ = string(tmpdir) + "/profiledata_unittest.tmp";
  }

  string filename() const { return filename_; }

  // Checks the first 'num_slots' profile data slots in the file
  // against the data pointed to by 'slots'.  Returns kNoError if the
  // data matched, otherwise returns an indication of the cause of the
  // mismatch.
  string Check(const ProfileDataSlot* slots, int num_slots) {
    return CheckWithSkips(slots, num_slots, NULL, 0);
  }

  // Checks the first 'num_slots' profile data slots in the file
  // against the data pointed to by 'slots', skipping over entries
  // described by 'skips' and 'num_skips'.
  //
  // 'skips' must be a sorted list of (0-based) slot numbers to be
  // skipped, of length 'num_skips'.  Note that 'num_slots' includes
  // any skipped slots, i.e., the first 'num_slots' profile data slots
  // will be considered, but some may be skipped.
  //
  // Returns kNoError if the data matched, otherwise returns an
  // indication of the cause of the mismatch.
  string CheckWithSkips(const ProfileDataSlot* slots, int num_slots,
                        const int* skips, int num_skips);

  // Validate that a profile is correctly formed.  The profile is
  // assumed to have been created by the same kind of binary (e.g.,
  // same slot size, same endian, etc.) as is validating the profile.
  //
  // Returns kNoError if the profile appears valid, otherwise returns
  // an indication of the problem with the profile.
  string ValidateProfile();

 private:
  string filename_;
};

string ProfileDataChecker::CheckWithSkips(const ProfileDataSlot* slots,
                                          int num_slots, const int* skips,
                                          int num_skips) {
  FileDescriptor fd(open(filename_.c_str(), O_RDONLY));
  if (fd.get() < 0)
    return "file open error";

  scoped_array<ProfileDataSlot> filedata(new ProfileDataSlot[num_slots]);
  size_t expected_bytes = num_slots * sizeof filedata[0];
  ssize_t bytes_read = ReadPersistent(fd.get(), filedata.get(), expected_bytes);
  if (expected_bytes != bytes_read)
    return "file too small";

  for (int i = 0; i < num_slots; i++) {
    if (num_skips > 0 && *skips == i) {
      num_skips--;
      skips++;
      continue;
    }
    if (slots[i] != filedata[i])
      return "data mismatch";
  }
  return kNoError;
}

string ProfileDataChecker::ValidateProfile() {
  FileDescriptor fd(open(filename_.c_str(), O_RDONLY));
  if (fd.get() < 0)
    return "file open error";

  struct stat statbuf;
  if (fstat(fd.get(), &statbuf) != 0)
    return "fstat error";
  if (statbuf.st_size != static_cast<ssize_t>(statbuf.st_size))
    return "file impossibly large";
  ssize_t filesize = statbuf.st_size;

  scoped_array<char> filedata(new char[filesize]);
  if (ReadPersistent(fd.get(), filedata.get(), filesize) != filesize)
    return "read of whole file failed";

  // Must have enough data for the header and the trailer.
  if (filesize < (5 + 3) * sizeof(ProfileDataSlot))
    return "not enough data in profile for header + trailer";

  // Check the header
  if (reinterpret_cast<ProfileDataSlot*>(filedata.get())[0] != 0)
    return "error in header: non-zero count";
  if (reinterpret_cast<ProfileDataSlot*>(filedata.get())[1] != 3)
    return "error in header: num_slots != 3";
  if (reinterpret_cast<ProfileDataSlot*>(filedata.get())[2] != 0)
    return "error in header: non-zero format version";
  // Period (slot 3) can have any value.
  if (reinterpret_cast<ProfileDataSlot*>(filedata.get())[4] != 0)
    return "error in header: non-zero padding value";
  ssize_t cur_offset = 5 * sizeof(ProfileDataSlot);

  // While there are samples, skip them.  Each sample consists of
  // at least three slots.
  bool seen_trailer = false;
  while (!seen_trailer) {
    if (cur_offset > filesize - 3 * sizeof(ProfileDataSlot))
      return "truncated sample header";
    ProfileDataSlot* sample =
        reinterpret_cast<ProfileDataSlot*>(filedata.get() + cur_offset);
    ProfileDataSlot slots_this_sample = 2 + sample[1];
    ssize_t size_this_sample = slots_this_sample * sizeof(ProfileDataSlot);
    if (cur_offset > filesize - size_this_sample)
      return "truncated sample";

    if (sample[0] == 0 && sample[1] == 1 && sample[2] == 0) {
      seen_trailer = true;
    } else {
      if (sample[0] < 1)
        return "error in sample: sample count < 1";
      if (sample[1] < 1)
        return "error in sample: num_pcs < 1";
      for (int i = 2; i < slots_this_sample; i++) {
        if (sample[i] == 0)
          return "error in sample: NULL PC";
      }
    }
    cur_offset += size_this_sample;
  }

  // There must be at least one line in the (text) list of mapped objects,
  // and it must be terminated by a newline.  Note, the use of newline
  // here and below Might not be reasonable on non-UNIX systems.
  if (cur_offset >= filesize)
    return "no list of mapped objects";
  if (filedata[filesize - 1] != '\n')
    return "profile did not end with a complete line";

  while (cur_offset < filesize) {
    char* line_start = filedata.get() + cur_offset;

    // Find the end of the line, and replace it with a NUL for easier
    // scanning.
    char* line_end = strchr(line_start, '\n');
    *line_end = '\0';

    // Advance past any leading space.  It's allowed in some lines,
    // but not in others.
    bool has_leading_space = false;
    char* line_cur = line_start;
    while (*line_cur == ' ') {
      has_leading_space = true;
      line_cur++;
    }

    bool found_match = false;

    // Check for build lines.
    if (!found_match) {
      found_match = (strncmp(line_cur, "build=", 6) == 0);
      // Anything may follow "build=", and leading space is allowed.
    }

    // A line from ProcMapsIterator::FormatLine, of the form:
    //
    // 40000000-40015000 r-xp 00000000 03:01 12845071   /lib/ld-2.3.2.so
    //
    // Leading space is not allowed.  The filename may be omitted or
    // may consist of multiple words, so we scan only up to the
    // space before the filename.
    if (!found_match) {
      int chars_scanned = -1;
      sscanf(line_cur, "%*x-%*x %*c%*c%*c%*c %*x %*x:%*x %*d %n",
             &chars_scanned);
      found_match = (chars_scanned > 0 && !has_leading_space);
    }

    // A line from DumpAddressMap, of the form:
    //
    // 40000000-40015000: /lib/ld-2.3.2.so
    //
    // Leading space is allowed.  The filename may be omitted or may
    // consist of multiple words, so we scan only up to the space
    // before the filename.
    if (!found_match) {
      int chars_scanned = -1;
      sscanf(line_cur, "%*x-%*x: %n", &chars_scanned);
      found_match = (chars_scanned > 0);
    }

    if (!found_match)
      return "unrecognized line in text section";

    cur_offset += (line_end - line_start) + 1;
  }

  return kNoError;
}

class ProfileDataTest {
 protected:
  void ExpectStopped() {
    EXPECT_FALSE(collector_.enabled());
  }

  void ExpectRunningSamples(int samples) {
    ProfileData::State state;
    collector_.GetCurrentState(&state);
    EXPECT_TRUE(state.enabled);
    EXPECT_EQ(samples, state.samples_gathered);
  }

  void ExpectSameState(const ProfileData::State& before,
                       const ProfileData::State& after) {
    EXPECT_EQ(before.enabled, after.enabled);
    EXPECT_EQ(before.samples_gathered, after.samples_gathered);
    EXPECT_EQ(before.start_time, after.start_time);
    EXPECT_STREQ(before.profile_name, after.profile_name);
  }

  ProfileData        collector_;
  ProfileDataChecker checker_;

 private:
  // The tests to run
  void OpsWhenStopped();
  void StartStopEmpty();
  void StartStopNoOptionsEmpty();
  void StartWhenStarted();
  void StartStopEmpty2();
  void CollectOne();
  void CollectTwoMatching();
  void CollectTwoFlush();
  void StartResetRestart();

 public:
#define RUN(test)  do {                         \
    printf("Running %s\n", #test);              \
    ProfileDataTest pdt;                        \
    pdt.test();                                 \
} while (0)

  static int RUN_ALL_TESTS() {
    RUN(OpsWhenStopped);
    RUN(StartStopEmpty);
    RUN(StartWhenStarted);
    RUN(StartStopEmpty2);
    RUN(CollectOne);
    RUN(CollectTwoMatching);
    RUN(CollectTwoFlush);
    RUN(StartResetRestart);
    return 0;
  }
};

// Check that various operations are safe when stopped.
TEST_F(ProfileDataTest, OpsWhenStopped) {
  ExpectStopped();
  EXPECT_FALSE(collector_.enabled());

  // Verify that state is disabled, all-empty/all-0
  ProfileData::State state_before;
  collector_.GetCurrentState(&state_before);
  EXPECT_FALSE(state_before.enabled);
  EXPECT_EQ(0, state_before.samples_gathered);
  EXPECT_EQ(0, state_before.start_time);
  EXPECT_STREQ("", state_before.profile_name);

  // Safe to call stop again.
  collector_.Stop();

  // Safe to call FlushTable.
  collector_.FlushTable();

  // Safe to call Add.
  const void *trace[] = { V(100), V(101), V(102), V(103), V(104) };
  collector_.Add(arraysize(trace), trace);

  ProfileData::State state_after;
  collector_.GetCurrentState(&state_after);

  ExpectSameState(state_before, state_after);
}

// Start and Stop, collecting no samples.  Verify output contents.
TEST_F(ProfileDataTest, StartStopEmpty) {
  const int frequency = 1;
  ProfileDataSlot slots[] = {
    0, 3, 0, 1000000 / frequency, 0,    // binary header
    0, 1, 0                             // binary trailer
  };

  ExpectStopped();
  ProfileData::Options options;
  options.set_frequency(frequency);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));
  ExpectRunningSamples(0);
  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.Check(slots, arraysize(slots)));
}

// Start and Stop with no options, collecting no samples.  Verify
// output contents.
TEST_F(ProfileDataTest, StartStopNoOptionsEmpty) {
  // We're not requesting a specific period, implementation can do
  // whatever it likes.
  ProfileDataSlot slots[] = {
    0, 3, 0, 0 /* skipped */, 0,        // binary header
    0, 1, 0                             // binary trailer
  };
  int slots_to_skip[] = { 3 };

  ExpectStopped();
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(),
                               ProfileData::Options()));
  ExpectRunningSamples(0);
  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.CheckWithSkips(slots, arraysize(slots),
                                              slots_to_skip,
                                              arraysize(slots_to_skip)));
}

// Start after already started.  Should return false and not impact
// collected data or state.
TEST_F(ProfileDataTest, StartWhenStarted) {
  const int frequency = 1;
  ProfileDataSlot slots[] = {
    0, 3, 0, 1000000 / frequency, 0,    // binary header
    0, 1, 0                             // binary trailer
  };

  ProfileData::Options options;
  options.set_frequency(frequency);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));

  ProfileData::State state_before;
  collector_.GetCurrentState(&state_before);

  options.set_frequency(frequency * 2);
  CHECK(!collector_.Start("foobar", options));

  ProfileData::State state_after;
  collector_.GetCurrentState(&state_after);
  ExpectSameState(state_before, state_after);

  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.Check(slots, arraysize(slots)));
}

// Like StartStopEmpty, but uses a different file name and frequency.
TEST_F(ProfileDataTest, StartStopEmpty2) {
  const int frequency = 2;
  ProfileDataSlot slots[] = {
    0, 3, 0, 1000000 / frequency, 0,    // binary header
    0, 1, 0                             // binary trailer
  };

  ExpectStopped();
  ProfileData::Options options;
  options.set_frequency(frequency);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));
  ExpectRunningSamples(0);
  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.Check(slots, arraysize(slots)));
}

TEST_F(ProfileDataTest, CollectOne) {
  const int frequency = 2;
  ProfileDataSlot slots[] = {
    0, 3, 0, 1000000 / frequency, 0,    // binary header
    1, 5, 100, 101, 102, 103, 104,      // our sample
    0, 1, 0                             // binary trailer
  };

  ExpectStopped();
  ProfileData::Options options;
  options.set_frequency(frequency);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));
  ExpectRunningSamples(0);

  const void *trace[] = { V(100), V(101), V(102), V(103), V(104) };
  collector_.Add(arraysize(trace), trace);
  ExpectRunningSamples(1);

  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.Check(slots, arraysize(slots)));
}

TEST_F(ProfileDataTest, CollectTwoMatching) {
  const int frequency = 2;
  ProfileDataSlot slots[] = {
    0, 3, 0, 1000000 / frequency, 0,    // binary header
    2, 5, 100, 201, 302, 403, 504,      // our two samples
    0, 1, 0                             // binary trailer
  };

  ExpectStopped();
  ProfileData::Options options;
  options.set_frequency(frequency);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));
  ExpectRunningSamples(0);

  for (int i = 0; i < 2; ++i) {
    const void *trace[] = { V(100), V(201), V(302), V(403), V(504) };
    collector_.Add(arraysize(trace), trace);
    ExpectRunningSamples(i + 1);
  }

  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.Check(slots, arraysize(slots)));
}

TEST_F(ProfileDataTest, CollectTwoFlush) {
  const int frequency = 2;
  ProfileDataSlot slots[] = {
    0, 3, 0, 1000000 / frequency, 0,    // binary header
    1, 5, 100, 201, 302, 403, 504,      // first sample (flushed)
    1, 5, 100, 201, 302, 403, 504,      // second identical sample
    0, 1, 0                             // binary trailer
  };

  ExpectStopped();
  ProfileData::Options options;
  options.set_frequency(frequency);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));
  ExpectRunningSamples(0);

  const void *trace[] = { V(100), V(201), V(302), V(403), V(504) };

  collector_.Add(arraysize(trace), trace);
  ExpectRunningSamples(1);
  collector_.FlushTable();

  collector_.Add(arraysize(trace), trace);
  ExpectRunningSamples(2);

  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.Check(slots, arraysize(slots)));
}

// Start then reset, verify that the result is *not* a valid profile.
// Then start again and make sure the result is OK.
TEST_F(ProfileDataTest, StartResetRestart) {
  ExpectStopped();
  ProfileData::Options options;
  options.set_frequency(1);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));
  ExpectRunningSamples(0);
  collector_.Reset();
  ExpectStopped();
  // We expect the resulting file to be empty.  This is a minimal test
  // of ValidateProfile.
  EXPECT_NE(kNoError, checker_.ValidateProfile());

  struct stat statbuf;
  EXPECT_EQ(0, stat(checker_.filename().c_str(), &statbuf));
  EXPECT_EQ(0, statbuf.st_size);

  const int frequency = 2;  // Different frequency than used above.
  ProfileDataSlot slots[] = {
    0, 3, 0, 1000000 / frequency, 0,    // binary header
    0, 1, 0                             // binary trailer
  };

  options.set_frequency(frequency);
  EXPECT_TRUE(collector_.Start(checker_.filename().c_str(), options));
  ExpectRunningSamples(0);
  collector_.Stop();
  ExpectStopped();
  EXPECT_EQ(kNoError, checker_.ValidateProfile());
  EXPECT_EQ(kNoError, checker_.Check(slots, arraysize(slots)));
}

}  // namespace

int main(int argc, char** argv) {
  int rc = ProfileDataTest::RUN_ALL_TESTS();
  printf("%s\n", rc == 0 ? "PASS" : "FAIL");
  return rc;
}
