// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Target-specific ELF type traits.

#ifndef TOOLS_RELOCATION_PACKER_SRC_ELF_TRAITS_H_
#define TOOLS_RELOCATION_PACKER_SRC_ELF_TRAITS_H_

#include "elf.h"
#include "libelf.h"

#if !defined(DT_MIPS_RLD_MAP2)
#define DT_MIPS_RLD_MAP2 0x70000035
#endif

// ELF is a traits structure used to provide convenient aliases for
// 32/64 bit Elf types and functions, depending on the target file.

struct ELF32_traits {
  typedef Elf32_Addr Addr;
  typedef Elf32_Dyn Dyn;
  typedef Elf32_Ehdr Ehdr;
  typedef Elf32_Off Off;
  typedef Elf32_Phdr Phdr;
  typedef Elf32_Rel Rel;
  typedef Elf32_Rela Rela;
  typedef Elf32_Shdr Shdr;
  typedef Elf32_Sword Sword;
  typedef Elf32_Sxword Sxword;
  typedef Elf32_Sym Sym;
  typedef Elf32_Word Word;
  typedef Elf32_Xword Xword;
  typedef Elf32_Half Half;

  static inline Ehdr* getehdr(Elf* elf) { return elf32_getehdr(elf); }
  static inline Phdr* getphdr(Elf* elf) { return elf32_getphdr(elf); }
  static inline Shdr* getshdr(Elf_Scn* scn) { return elf32_getshdr(scn); }
  static inline Word elf_r_type(Word info) { return ELF32_R_TYPE(info); }
  static inline int elf_st_type(uint8_t info) { return ELF32_ST_TYPE(info); }
  static inline Word elf_r_sym(Word info) { return ELF32_R_SYM(info); }
};

struct ELF64_traits {
  typedef Elf64_Addr Addr;
  typedef Elf64_Dyn Dyn;
  typedef Elf64_Ehdr Ehdr;
  typedef Elf64_Off Off;
  typedef Elf64_Phdr Phdr;
  typedef Elf64_Rel Rel;
  typedef Elf64_Rela Rela;
  typedef Elf64_Shdr Shdr;
  typedef Elf64_Sword Sword;
  typedef Elf64_Sxword Sxword;
  typedef Elf64_Sym Sym;
  typedef Elf64_Word Word;
  typedef Elf64_Xword Xword;
  typedef Elf64_Half Half;

  static inline Ehdr* getehdr(Elf* elf) { return elf64_getehdr(elf); }
  static inline Phdr* getphdr(Elf* elf) { return elf64_getphdr(elf); }
  static inline Shdr* getshdr(Elf_Scn* scn) { return elf64_getshdr(scn); }
  static inline Xword elf_r_type(Xword info) { return ELF64_R_TYPE(info); }
  static inline int elf_st_type(uint8_t info) { return ELF64_ST_TYPE(info); }
  static inline Word elf_r_sym(Xword info) { return ELF64_R_SYM(info); }
};

#endif  // TOOLS_RELOCATION_PACKER_SRC_ELF_TRAITS_H_
