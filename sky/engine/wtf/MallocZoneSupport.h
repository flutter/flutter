/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_MALLOCZONESUPPORT_H_
#define SKY_ENGINE_WTF_MALLOCZONESUPPORT_H_

#include <malloc/malloc.h>

namespace WTF {

class RemoteMemoryReader {
  task_t m_task;
  memory_reader_t* m_reader;

 public:
  RemoteMemoryReader(task_t task, memory_reader_t* reader)
      : m_task(task), m_reader(reader) {}

  void* operator()(vm_address_t address, size_t size) const {
    void* output;
    kern_return_t err =
        (*m_reader)(m_task, address, size, static_cast<void**>(&output));
    if (err)
      output = 0;
    return output;
  }

  template <typename T>
  T* operator()(T* address, size_t size = sizeof(T)) const {
    return static_cast<T*>(
        (*this)(reinterpret_cast<vm_address_t>(address), size));
  }

  template <typename T>
  T* nextEntryInHardenedLinkedList(T** address, uintptr_t entropy) const;
};

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_MALLOCZONESUPPORT_H_
