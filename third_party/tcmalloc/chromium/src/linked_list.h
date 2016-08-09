// Copyright (c) 2008, Google Inc.
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

// ---
// Author: Sanjay Ghemawat <opensource@google.com>
//
// Some very basic linked list functions for dealing with using void * as
// storage.

#ifndef TCMALLOC_LINKED_LIST_H_
#define TCMALLOC_LINKED_LIST_H_

#include <stddef.h>

namespace tcmalloc {

inline void *SLL_Next(void *t) {
  return *(reinterpret_cast<void**>(t));
}

inline void SLL_SetNext(void *t, void *n) {
  *(reinterpret_cast<void**>(t)) = n;
}

inline void SLL_Push(void **list, void *element) {
  SLL_SetNext(element, *list);
  *list = element;
}

inline void *SLL_Pop(void **list) {
  void *result = *list;
  *list = SLL_Next(*list);
  return result;
}

// Remove N elements from a linked list to which head points.  head will be
// modified to point to the new head.  start and end will point to the first
// and last nodes of the range.  Note that end will point to NULL after this
// function is called.
inline void SLL_PopRange(void **head, int N, void **start, void **end) {
  if (N == 0) {
    *start = NULL;
    *end = NULL;
    return;
  }

  void *tmp = *head;
  for (int i = 1; i < N; ++i) {
    tmp = SLL_Next(tmp);
  }

  *start = *head;
  *end = tmp;
  *head = SLL_Next(tmp);
  // Unlink range from list.
  SLL_SetNext(tmp, NULL);
}

inline void SLL_PushRange(void **head, void *start, void *end) {
  if (!start) return;
  SLL_SetNext(end, *head);
  *head = start;
}

inline size_t SLL_Size(void *head) {
  int count = 0;
  while (head) {
    count++;
    head = SLL_Next(head);
  }
  return count;
}

}  // namespace tcmalloc

#endif  // TCMALLOC_LINKED_LIST_H_
