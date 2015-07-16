// Copyright 2000 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Sometimes it is necessary to allocate a large number of small
// objects.  Doing this the usual way (malloc, new) is slow,
// especially for multithreaded programs.  An UnsafeArena provides a
// mark/release method of memory management: it asks for a large chunk
// from the operating system and doles it out bit by bit as required.
// Then you free all the memory at once by calling UnsafeArena::Reset().
// The "Unsafe" refers to the fact that UnsafeArena is not safe to
// call from multiple threads.
//
// The global operator new that can be used as follows:
//
//   #include "lib/arena-inl.h"
//
//   UnsafeArena arena(1000);
//   Foo* foo = new (AllocateInArena, &arena) Foo;
//

#ifndef RE2_UTIL_ARENA_H_
#define RE2_UTIL_ARENA_H_

namespace re2 {

// This class is thread-compatible.
class UnsafeArena {
 public:
  UnsafeArena(const size_t block_size);
  virtual ~UnsafeArena();

  void Reset();

  // This should be the worst-case alignment for any type.  This is
  // good for IA-32, SPARC version 7 (the last one I know), and
  // supposedly Alpha.  i386 would be more time-efficient with a
  // default alignment of 8, but ::operator new() uses alignment of 4,
  // and an assertion will fail below after the call to MakeNewBlock()
  // if you try to use a larger alignment.
#ifdef __i386__
  static const int kDefaultAlignment = 4;
#else
  static const int kDefaultAlignment = 8;
#endif

 private:
  void* GetMemoryFallback(const size_t size, const int align);

 public:
  void* GetMemory(const size_t size, const int align) {
    if ( size > 0 && size < remaining_ && align == 1 ) {       // common case
      last_alloc_ = freestart_;
      freestart_ += size;
      remaining_ -= size;
      return reinterpret_cast<void*>(last_alloc_);
    }
    return GetMemoryFallback(size, align);
  }

 private:
  struct AllocatedBlock {
    char *mem;
    size_t size;
  };

  // The returned AllocatedBlock* is valid until the next call to AllocNewBlock
  // or Reset (i.e. anything that might affect overflow_blocks_).
  AllocatedBlock *AllocNewBlock(const size_t block_size);

  const AllocatedBlock *IndexToBlock(int index) const;

  const size_t block_size_;
  char* freestart_;         // beginning of the free space in most recent block
  char* freestart_when_empty_;  // beginning of the free space when we're empty
  char* last_alloc_;         // used to make sure ReturnBytes() is safe
  size_t remaining_;
  // STL vector isn't as efficient as it could be, so we use an array at first
  int blocks_alloced_;       // how many of the first_blocks_ have been alloced
  AllocatedBlock first_blocks_[16];   // the length of this array is arbitrary
  // if the first_blocks_ aren't enough, expand into overflow_blocks_.
  vector<AllocatedBlock>* overflow_blocks_;

  void FreeBlocks();         // Frees all except first block

  DISALLOW_EVIL_CONSTRUCTORS(UnsafeArena);
};

// Operators for allocation on the arena
// Syntax: new (AllocateInArena, arena) MyClass;
// STL containers, etc.
enum AllocateInArenaType { AllocateInArena };

}  // namespace re2

inline void* operator new(size_t size,
                          re2::AllocateInArenaType /* unused */,
                          re2::UnsafeArena *arena) {
  return reinterpret_cast<char*>(arena->GetMemory(size, 1));
}

#endif  // RE2_UTIL_ARENA_H_

