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
// Author: Paul Pluzhnikov
//
// Allow dynamic symbol lookup for in-memory Elf images.

#ifndef BASE_ELF_MEM_IMAGE_H_
#define BASE_ELF_MEM_IMAGE_H_

#include <config.h>
#ifdef HAVE_FEATURES_H
#include <features.h>   // for __GLIBC__
#endif

// Maybe one day we can rewrite this file not to require the elf
// symbol extensions in glibc, but for right now we need them.
#if defined(__ELF__) && defined(__GLIBC__) && !defined(__native_client__)

#define HAVE_ELF_MEM_IMAGE 1

#include <stdlib.h>
#include <link.h>  // for ElfW

namespace base {

// An in-memory ELF image (may not exist on disk).
class ElfMemImage {
 public:
  // Sentinel: there could never be an elf image at this address.
  static const void *const kInvalidBase;

  // Information about a single vdso symbol.
  // All pointers are into .dynsym, .dynstr, or .text of the VDSO.
  // Do not free() them or modify through them.
  struct SymbolInfo {
    const char      *name;      // E.g. "__vdso_getcpu"
    const char      *version;   // E.g. "LINUX_2.6", could be ""
                                // for unversioned symbol.
    const void      *address;   // Relocated symbol address.
    const ElfW(Sym) *symbol;    // Symbol in the dynamic symbol table.
  };

  // Supports iteration over all dynamic symbols.
  class SymbolIterator {
   public:
    friend class ElfMemImage;
    const SymbolInfo *operator->() const;
    const SymbolInfo &operator*() const;
    SymbolIterator& operator++();
    bool operator!=(const SymbolIterator &rhs) const;
    bool operator==(const SymbolIterator &rhs) const;
   private:
    SymbolIterator(const void *const image, int index);
    void Update(int incr);
    SymbolInfo info_;
    int index_;
    const void *const image_;
  };


  explicit ElfMemImage(const void *base);
  void                 Init(const void *base);
  bool                 IsPresent() const { return ehdr_ != NULL; }
  const ElfW(Phdr)*    GetPhdr(int index) const;
  const ElfW(Sym)*     GetDynsym(int index) const;
  const ElfW(Versym)*  GetVersym(int index) const;
  const ElfW(Verdef)*  GetVerdef(int index) const;
  const ElfW(Verdaux)* GetVerdefAux(const ElfW(Verdef) *verdef) const;
  const char*          GetDynstr(ElfW(Word) offset) const;
  const void*          GetSymAddr(const ElfW(Sym) *sym) const;
  const char*          GetVerstr(ElfW(Word) offset) const;
  int                  GetNumSymbols() const;

  SymbolIterator begin() const;
  SymbolIterator end() const;

  // Look up versioned dynamic symbol in the image.
  // Returns false if image is not present, or doesn't contain given
  // symbol/version/type combination.
  // If info_out != NULL, additional details are filled in.
  bool LookupSymbol(const char *name, const char *version,
                    int symbol_type, SymbolInfo *info_out) const;

  // Find info about symbol (if any) which overlaps given address.
  // Returns true if symbol was found; false if image isn't present
  // or doesn't have a symbol overlapping given address.
  // If info_out != NULL, additional details are filled in.
  bool LookupSymbolByAddress(const void *address, SymbolInfo *info_out) const;

 private:
  const ElfW(Ehdr) *ehdr_;
  const ElfW(Sym) *dynsym_;
  const ElfW(Versym) *versym_;
  const ElfW(Verdef) *verdef_;
  const ElfW(Word) *hash_;
  const char *dynstr_;
  size_t strsize_;
  size_t verdefnum_;
  ElfW(Addr) link_base_;     // Link-time base (p_vaddr of first PT_LOAD).
};

}  // namespace base

#endif  // __ELF__ and __GLIBC__ and !__native_client__

#endif  // BASE_ELF_MEM_IMAGE_H_
