// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_POSIX_GLOBAL_DESCRIPTORS_H_
#define BASE_POSIX_GLOBAL_DESCRIPTORS_H_

#include "build/build_config.h"

#include <vector>
#include <utility>

#include <stdint.h>

#include "base/files/memory_mapped_file.h"
#include "base/memory/singleton.h"

namespace base {

// It's common practice to install file descriptors into well known slot
// numbers before execing a child; stdin, stdout and stderr are ubiqutous
// examples.
//
// However, when using a zygote model, this becomes troublesome. Since the
// descriptors which need to be in these slots generally aren't known, any code
// could open a resource and take one of the reserved descriptors. Simply
// overwriting the slot isn't a viable solution.
//
// We could try to fill the reserved slots as soon as possible, but this is a
// fragile solution since global constructors etc are able to open files.
//
// Instead, we retreat from the idea of installing descriptors in specific
// slots and add a layer of indirection in the form of this singleton object.
// It maps from an abstract key to a descriptor. If independent modules each
// need to define keys, then values should be chosen randomly so as not to
// collide.
class BASE_EXPORT GlobalDescriptors {
 public:
  typedef uint32_t Key;
  struct Descriptor {
    Descriptor(Key key, int fd);
    Descriptor(Key key, int fd, base::MemoryMappedFile::Region region);

    // Globally unique key.
    Key key;
    // Actual FD.
    int fd;
    // Optional region, defaults to kWholeFile.
    base::MemoryMappedFile::Region region;
  };
  typedef std::vector<Descriptor> Mapping;

  // Often we want a canonical descriptor for a given Key. In this case, we add
  // the following constant to the key value:
#if !defined(OS_ANDROID)
  static const int kBaseDescriptor = 3;  // 0, 1, 2 are already taken.
#else
  static const int kBaseDescriptor = 4;  // 3 used by __android_log_write().
#endif

  // Return the singleton instance of GlobalDescriptors.
  static GlobalDescriptors* GetInstance();

  // Get a descriptor given a key. It is a fatal error if the key is not known.
  int Get(Key key) const;

  // Get a descriptor given a key. Returns -1 on error.
  int MaybeGet(Key key) const;

  // Get a region given a key. It is a fatal error if the key is not known.
  base::MemoryMappedFile::Region GetRegion(Key key) const;

  // Set the descriptor for the given |key|. This sets the region associated
  // with |key| to kWholeFile.
  void Set(Key key, int fd);

  // Set the descriptor and |region| for the given |key|.
  void Set(Key key, int fd, base::MemoryMappedFile::Region region);

  void Reset(const Mapping& mapping);

 private:
  friend struct DefaultSingletonTraits<GlobalDescriptors>;
  GlobalDescriptors();
  ~GlobalDescriptors();

  Mapping descriptors_;
};

}  // namespace base

#endif  // BASE_POSIX_GLOBAL_DESCRIPTORS_H_
