// Copyright (c) 2009, Google Inc.
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
// Author: Craig Silverstein

#ifndef TCMALLOC_SYMBOLIZE_H_
#define TCMALLOC_SYMBOLIZE_H_

#include "config.h"
#ifdef HAVE_STDINT_H
#include <stdint.h>  // for uintptr_t
#endif
#include <stddef.h>  // for NULL
#include <map>

using std::map;

// SymbolTable encapsulates the address operations necessary for stack trace
// symbolization. A common use-case is to Add() the addresses from one or
// several stack traces to a table, call Symbolize() once and use GetSymbol()
// to get the symbol names for pretty-printing the stack traces.
class SymbolTable {
 public:
  SymbolTable()
    : symbol_buffer_(NULL) {}
  ~SymbolTable() {
    delete[] symbol_buffer_;
  }

  // Adds an address to the table. This may overwrite a currently known symbol
  // name, so Add() should not generally be called after Symbolize().
  void Add(const void* addr);

  // Returns the symbol name for addr, if the given address was added before
  // the last successful call to Symbolize(). Otherwise may return an empty
  // c-string.
  const char* GetSymbol(const void* addr);

  // Obtains the symbol names for the addresses stored in the table and returns
  // the number of addresses actually symbolized.
  int Symbolize();

 private:
  typedef map<const void*, const char*> SymbolMap;

  // An average size of memory allocated for a stack trace symbol.
  static const int kSymbolSize = 1024;

  // Map from addresses to symbol names.
  SymbolMap symbolization_table_;

  // Pointer to the buffer that stores the symbol names.
  char *symbol_buffer_;
};

#endif  // TCMALLOC_SYMBOLIZE_H_
