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
// Allow dynamic symbol lookup in an in-memory Elf image.
//

#include "base/elf_mem_image.h"

#ifdef HAVE_ELF_MEM_IMAGE  // defined in elf_mem_image.h

#include <stddef.h>   // for size_t, ptrdiff_t
#include "base/logging.h"

// From binutils/include/elf/common.h (this doesn't appear to be documented
// anywhere else).
//
//   /* This flag appears in a Versym structure.  It means that the symbol
//      is hidden, and is only visible with an explicit version number.
//      This is a GNU extension.  */
//   #define VERSYM_HIDDEN           0x8000
//
//   /* This is the mask for the rest of the Versym information.  */
//   #define VERSYM_VERSION          0x7fff

#define VERSYM_VERSION 0x7fff

namespace base {

namespace {
template <int N> class ElfClass {
 public:
  static const int kElfClass = -1;
  static int ElfBind(const ElfW(Sym) *) {
    CHECK(false); // << "Unexpected word size";
    return 0;
  }
  static int ElfType(const ElfW(Sym) *) {
    CHECK(false); // << "Unexpected word size";
    return 0;
  }
};

template <> class ElfClass<32> {
 public:
  static const int kElfClass = ELFCLASS32;
  static int ElfBind(const ElfW(Sym) *symbol) {
    return ELF32_ST_BIND(symbol->st_info);
  }
  static int ElfType(const ElfW(Sym) *symbol) {
    return ELF32_ST_TYPE(symbol->st_info);
  }
};

template <> class ElfClass<64> {
 public:
  static const int kElfClass = ELFCLASS64;
  static int ElfBind(const ElfW(Sym) *symbol) {
    return ELF64_ST_BIND(symbol->st_info);
  }
  static int ElfType(const ElfW(Sym) *symbol) {
    return ELF64_ST_TYPE(symbol->st_info);
  }
};

typedef ElfClass<__WORDSIZE> CurrentElfClass;

// Extract an element from one of the ELF tables, cast it to desired type.
// This is just a simple arithmetic and a glorified cast.
// Callers are responsible for bounds checking.
template <class T>
const T* GetTableElement(const ElfW(Ehdr) *ehdr,
                         ElfW(Off) table_offset,
                         ElfW(Word) element_size,
                         size_t index) {
  return reinterpret_cast<const T*>(reinterpret_cast<const char *>(ehdr)
                                    + table_offset
                                    + index * element_size);
}
}  // namespace

const void *const ElfMemImage::kInvalidBase =
    reinterpret_cast<const void *>(~0L);

ElfMemImage::ElfMemImage(const void *base) {
  CHECK(base != kInvalidBase);
  Init(base);
}

int ElfMemImage::GetNumSymbols() const {
  if (!hash_) {
    return 0;
  }
  // See http://www.caldera.com/developers/gabi/latest/ch5.dynamic.html#hash
  return hash_[1];
}

const ElfW(Sym) *ElfMemImage::GetDynsym(int index) const {
  CHECK_LT(index, GetNumSymbols());
  return dynsym_ + index;
}

const ElfW(Versym) *ElfMemImage::GetVersym(int index) const {
  CHECK_LT(index, GetNumSymbols());
  return versym_ + index;
}

const ElfW(Phdr) *ElfMemImage::GetPhdr(int index) const {
  CHECK_LT(index, ehdr_->e_phnum);
  return GetTableElement<ElfW(Phdr)>(ehdr_,
                                     ehdr_->e_phoff,
                                     ehdr_->e_phentsize,
                                     index);
}

const char *ElfMemImage::GetDynstr(ElfW(Word) offset) const {
  CHECK_LT(offset, strsize_);
  return dynstr_ + offset;
}

const void *ElfMemImage::GetSymAddr(const ElfW(Sym) *sym) const {
  if (sym->st_shndx == SHN_UNDEF || sym->st_shndx >= SHN_LORESERVE) {
    // Symbol corresponds to "special" (e.g. SHN_ABS) section.
    return reinterpret_cast<const void *>(sym->st_value);
  }
  CHECK_LT(link_base_, sym->st_value);
  return GetTableElement<char>(ehdr_, 0, 1, sym->st_value) - link_base_;
}

const ElfW(Verdef) *ElfMemImage::GetVerdef(int index) const {
  CHECK_LE(index, verdefnum_);
  const ElfW(Verdef) *version_definition = verdef_;
  while (version_definition->vd_ndx < index && version_definition->vd_next) {
    const char *const version_definition_as_char =
        reinterpret_cast<const char *>(version_definition);
    version_definition =
        reinterpret_cast<const ElfW(Verdef) *>(version_definition_as_char +
                                               version_definition->vd_next);
  }
  return version_definition->vd_ndx == index ? version_definition : NULL;
}

const ElfW(Verdaux) *ElfMemImage::GetVerdefAux(
    const ElfW(Verdef) *verdef) const {
  return reinterpret_cast<const ElfW(Verdaux) *>(verdef+1);
}

const char *ElfMemImage::GetVerstr(ElfW(Word) offset) const {
  CHECK_LT(offset, strsize_);
  return dynstr_ + offset;
}

void ElfMemImage::Init(const void *base) {
  ehdr_      = NULL;
  dynsym_    = NULL;
  dynstr_    = NULL;
  versym_    = NULL;
  verdef_    = NULL;
  hash_      = NULL;
  strsize_   = 0;
  verdefnum_ = 0;
  link_base_ = ~0L;  // Sentinel: PT_LOAD .p_vaddr can't possibly be this.
  if (!base) {
    return;
  }
  const intptr_t base_as_uintptr_t = reinterpret_cast<uintptr_t>(base);
  // Fake VDSO has low bit set.
  const bool fake_vdso = ((base_as_uintptr_t & 1) != 0);
  base = reinterpret_cast<const void *>(base_as_uintptr_t & ~1);
  const char *const base_as_char = reinterpret_cast<const char *>(base);
  if (base_as_char[EI_MAG0] != ELFMAG0 || base_as_char[EI_MAG1] != ELFMAG1 ||
      base_as_char[EI_MAG2] != ELFMAG2 || base_as_char[EI_MAG3] != ELFMAG3) {
    RAW_DCHECK(false, "no ELF magic"); // at %p", base);
    return;
  }
  int elf_class = base_as_char[EI_CLASS];
  if (elf_class != CurrentElfClass::kElfClass) {
    DCHECK_EQ(elf_class, CurrentElfClass::kElfClass);
    return;
  }
  switch (base_as_char[EI_DATA]) {
    case ELFDATA2LSB: {
      if (__LITTLE_ENDIAN != __BYTE_ORDER) {
        DCHECK_EQ(__LITTLE_ENDIAN, __BYTE_ORDER); // << ": wrong byte order";
        return;
      }
      break;
    }
    case ELFDATA2MSB: {
      if (__BIG_ENDIAN != __BYTE_ORDER) {
        DCHECK_EQ(__BIG_ENDIAN, __BYTE_ORDER); // << ": wrong byte order";
        return;
      }
      break;
    }
    default: {
      RAW_DCHECK(false, "unexpected data encoding"); // << base_as_char[EI_DATA];
      return;
    }
  }

  ehdr_ = reinterpret_cast<const ElfW(Ehdr) *>(base);
  const ElfW(Phdr) *dynamic_program_header = NULL;
  for (int i = 0; i < ehdr_->e_phnum; ++i) {
    const ElfW(Phdr) *const program_header = GetPhdr(i);
    switch (program_header->p_type) {
      case PT_LOAD:
        if (link_base_ == ~0L) {
          link_base_ = program_header->p_vaddr;
        }
        break;
      case PT_DYNAMIC:
        dynamic_program_header = program_header;
        break;
    }
  }
  if (link_base_ == ~0L || !dynamic_program_header) {
    RAW_DCHECK(~0L != link_base_, "no PT_LOADs in VDSO");
    RAW_DCHECK(dynamic_program_header, "no PT_DYNAMIC in VDSO");
    // Mark this image as not present. Can not recur infinitely.
    Init(0);
    return;
  }
  ptrdiff_t relocation =
      base_as_char - reinterpret_cast<const char *>(link_base_);
  ElfW(Dyn) *dynamic_entry =
      reinterpret_cast<ElfW(Dyn) *>(dynamic_program_header->p_vaddr +
                                    relocation);
  for (; dynamic_entry->d_tag != DT_NULL; ++dynamic_entry) {
    ElfW(Xword) value = dynamic_entry->d_un.d_val;
    if (fake_vdso) {
      // A complication: in the real VDSO, dynamic entries are not relocated
      // (it wasn't loaded by a dynamic loader). But when testing with a
      // "fake" dlopen()ed vdso library, the loader relocates some (but
      // not all!) of them before we get here.
      if (dynamic_entry->d_tag == DT_VERDEF) {
        // The only dynamic entry (of the ones we care about) libc-2.3.6
        // loader doesn't relocate.
        value += relocation;
      }
    } else {
      // Real VDSO. Everything needs to be relocated.
      value += relocation;
    }
    switch (dynamic_entry->d_tag) {
      case DT_HASH:
        hash_ = reinterpret_cast<ElfW(Word) *>(value);
        break;
      case DT_SYMTAB:
        dynsym_ = reinterpret_cast<ElfW(Sym) *>(value);
        break;
      case DT_STRTAB:
        dynstr_ = reinterpret_cast<const char *>(value);
        break;
      case DT_VERSYM:
        versym_ = reinterpret_cast<ElfW(Versym) *>(value);
        break;
      case DT_VERDEF:
        verdef_ = reinterpret_cast<ElfW(Verdef) *>(value);
        break;
      case DT_VERDEFNUM:
        verdefnum_ = dynamic_entry->d_un.d_val;
        break;
      case DT_STRSZ:
        strsize_ = dynamic_entry->d_un.d_val;
        break;
      default:
        // Unrecognized entries explicitly ignored.
        break;
    }
  }
  if (!hash_ || !dynsym_ || !dynstr_ || !versym_ ||
      !verdef_ || !verdefnum_ || !strsize_) {
    RAW_DCHECK(hash_, "invalid VDSO (no DT_HASH)");
    RAW_DCHECK(dynsym_, "invalid VDSO (no DT_SYMTAB)");
    RAW_DCHECK(dynstr_, "invalid VDSO (no DT_STRTAB)");
    RAW_DCHECK(versym_, "invalid VDSO (no DT_VERSYM)");
    RAW_DCHECK(verdef_, "invalid VDSO (no DT_VERDEF)");
    RAW_DCHECK(verdefnum_, "invalid VDSO (no DT_VERDEFNUM)");
    RAW_DCHECK(strsize_, "invalid VDSO (no DT_STRSZ)");
    // Mark this image as not present. Can not recur infinitely.
    Init(0);
    return;
  }
}

bool ElfMemImage::LookupSymbol(const char *name,
                               const char *version,
                               int type,
                               SymbolInfo *info) const {
  for (SymbolIterator it = begin(); it != end(); ++it) {
    if (strcmp(it->name, name) == 0 && strcmp(it->version, version) == 0 &&
        CurrentElfClass::ElfType(it->symbol) == type) {
      if (info) {
        *info = *it;
      }
      return true;
    }
  }
  return false;
}

bool ElfMemImage::LookupSymbolByAddress(const void *address,
                                        SymbolInfo *info_out) const {
  for (SymbolIterator it = begin(); it != end(); ++it) {
    const char *const symbol_start =
        reinterpret_cast<const char *>(it->address);
    const char *const symbol_end = symbol_start + it->symbol->st_size;
    if (symbol_start <= address && address < symbol_end) {
      if (info_out) {
        // Client wants to know details for that symbol (the usual case).
        if (CurrentElfClass::ElfBind(it->symbol) == STB_GLOBAL) {
          // Strong symbol; just return it.
          *info_out = *it;
          return true;
        } else {
          // Weak or local. Record it, but keep looking for a strong one.
          *info_out = *it;
        }
      } else {
        // Client only cares if there is an overlapping symbol.
        return true;
      }
    }
  }
  return false;
}

ElfMemImage::SymbolIterator::SymbolIterator(const void *const image, int index)
    : index_(index), image_(image) {
}

const ElfMemImage::SymbolInfo *ElfMemImage::SymbolIterator::operator->() const {
  return &info_;
}

const ElfMemImage::SymbolInfo& ElfMemImage::SymbolIterator::operator*() const {
  return info_;
}

bool ElfMemImage::SymbolIterator::operator==(const SymbolIterator &rhs) const {
  return this->image_ == rhs.image_ && this->index_ == rhs.index_;
}

bool ElfMemImage::SymbolIterator::operator!=(const SymbolIterator &rhs) const {
  return !(*this == rhs);
}

ElfMemImage::SymbolIterator &ElfMemImage::SymbolIterator::operator++() {
  this->Update(1);
  return *this;
}

ElfMemImage::SymbolIterator ElfMemImage::begin() const {
  SymbolIterator it(this, 0);
  it.Update(0);
  return it;
}

ElfMemImage::SymbolIterator ElfMemImage::end() const {
  return SymbolIterator(this, GetNumSymbols());
}

void ElfMemImage::SymbolIterator::Update(int increment) {
  const ElfMemImage *image = reinterpret_cast<const ElfMemImage *>(image_);
  CHECK(image->IsPresent() || increment == 0);
  if (!image->IsPresent()) {
    return;
  }
  index_ += increment;
  if (index_ >= image->GetNumSymbols()) {
    index_ = image->GetNumSymbols();
    return;
  }
  const ElfW(Sym)    *symbol = image->GetDynsym(index_);
  const ElfW(Versym) *version_symbol = image->GetVersym(index_);
  CHECK(symbol && version_symbol);
  const char *const symbol_name = image->GetDynstr(symbol->st_name);
  const ElfW(Versym) version_index = version_symbol[0] & VERSYM_VERSION;
  const ElfW(Verdef) *version_definition = NULL;
  const char *version_name = "";
  if (symbol->st_shndx == SHN_UNDEF) {
    // Undefined symbols reference DT_VERNEED, not DT_VERDEF, and
    // version_index could well be greater than verdefnum_, so calling
    // GetVerdef(version_index) may trigger assertion.
  } else {
    version_definition = image->GetVerdef(version_index);
  }
  if (version_definition) {
    // I am expecting 1 or 2 auxiliary entries: 1 for the version itself,
    // optional 2nd if the version has a parent.
    CHECK_LE(1, version_definition->vd_cnt);
    CHECK_LE(version_definition->vd_cnt, 2);
    const ElfW(Verdaux) *version_aux = image->GetVerdefAux(version_definition);
    version_name = image->GetVerstr(version_aux->vda_name);
  }
  info_.name    = symbol_name;
  info_.version = version_name;
  info_.address = image->GetSymAddr(symbol);
  info_.symbol  = symbol;
}

}  // namespace base

#endif  // HAVE_ELF_MEM_IMAGE
