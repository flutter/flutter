// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_SCOPED_MACH_VM_H_
#define BASE_MAC_SCOPED_MACH_VM_H_

#include <mach/mach.h>

#include <algorithm>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/logging.h"

// Use ScopedMachVM to supervise ownership of pages in the current process
// through the Mach VM subsystem. Pages allocated with vm_allocate can be
// released when exiting a scope with ScopedMachVM.
//
// The Mach VM subsystem operates on a page-by-page basis, and a single VM
// allocation managed by a ScopedMachVM object may span multiple pages. As far
// as Mach is concerned, allocated pages may be deallocated individually. This
// is in contrast to higher-level allocators such as malloc, where the base
// address of an allocation implies the size of an allocated block.
// Consequently, it is not sufficient to just pass the base address of an
// allocation to ScopedMachVM, it also needs to know the size of the
// allocation. To avoid any confusion, both the base address and size must
// be page-aligned.
//
// When dealing with Mach VM, base addresses will naturally be page-aligned,
// but user-specified sizes may not be. If there's a concern that a size is
// not page-aligned, use the mach_vm_round_page macro to correct it.
//
// Example:
//
//   vm_address_t address = 0;
//   vm_size_t size = 12345;  // This requested size is not page-aligned.
//   kern_return_t kr =
//       vm_allocate(mach_task_self(), &address, size, VM_FLAGS_ANYWHERE);
//   if (kr != KERN_SUCCESS) {
//     return false;
//   }
//   ScopedMachVM vm_owner(address, mach_vm_round_page(size));

namespace base {
namespace mac {

class BASE_EXPORT ScopedMachVM {
 public:
  explicit ScopedMachVM(vm_address_t address = 0, vm_size_t size = 0)
      : address_(address), size_(size) {
    DCHECK_EQ(address % PAGE_SIZE, 0u);
    DCHECK_EQ(size % PAGE_SIZE, 0u);
  }

  ~ScopedMachVM() {
    if (size_) {
      vm_deallocate(mach_task_self(), address_, size_);
    }
  }

  void reset(vm_address_t address = 0, vm_size_t size = 0);

  vm_address_t address() const {
    return address_;
  }

  vm_size_t size() const {
    return size_;
  }

  void swap(ScopedMachVM& that) {
    std::swap(address_, that.address_);
    std::swap(size_, that.size_);
  }

  void release() {
    address_ = 0;
    size_ = 0;
  }

 private:
  vm_address_t address_;
  vm_size_t size_;

  DISALLOW_COPY_AND_ASSIGN(ScopedMachVM);
};

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_SCOPED_MACH_VM_H_
