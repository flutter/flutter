// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Target-specific ELF type traits.

#ifndef TOOLS_RELOCATION_PACKER_SRC_ELF_TRAITS_H_
#define TOOLS_RELOCATION_PACKER_SRC_ELF_TRAITS_H_

#include "elf.h"
#include "libelf.h"

// The TARGET_ macro controls which Elf types we expect and handle.
// Either TARGET_ARM or TARGET_ARM64 must be defined, but not both.

#if !defined(TARGET_ARM) && !defined(TARGET_ARM64)
# error "Unsupported target, define one of TARGET_ARM or TARGET_ARM64"
#elif defined(TARGET_ARM) && defined(TARGET_ARM64)
# error "Define one of TARGET_ARM or TARGET_ARM64, but not both"
#endif

// TODO(simonb): Eliminate these once AARCH64 appears reliably in elf.h.
#ifndef EM_AARCH64
#define EM_AARCH64 183
#endif
#ifndef R_AARCH64_RELATIVE
#define R_AARCH64_RELATIVE 1027
#endif
#ifndef R_AARCH64_NONE
#define R_AARCH64_NONE 0
#endif

// ELF is a traits structure used to provide convenient aliases for
// 32/64 bit Elf types and functions, depending on the target specified.

#if defined(TARGET_ARM)
struct ELF {
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

  static inline Ehdr* getehdr(Elf* elf) { return elf32_getehdr(elf); }
  static inline Phdr* getphdr(Elf* elf) { return elf32_getphdr(elf); }
  static inline Shdr* getshdr(Elf_Scn* scn) { return elf32_getshdr(scn); }

  enum { kMachine = EM_ARM };
  enum { kFileClass = ELFCLASS32 };
  enum { kRelativeRelocationCode = R_ARM_RELATIVE };
  enum { kNoRelocationCode = R_ARM_NONE };

  static inline const char* Machine() { return "ARM"; }

# define ELF_R_SYM(val) ELF32_R_SYM(val)
# define ELF_R_TYPE(val) ELF32_R_TYPE(val)
# define ELF_R_INFO(sym, type) ELF32_R_INFO(sym, type)
# define ELF_ST_TYPE(val) ELF32_ST_TYPE(val)
};

#elif defined(TARGET_ARM64)
struct ELF {
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

  static inline Ehdr* getehdr(Elf* elf) { return elf64_getehdr(elf); }
  static inline Phdr* getphdr(Elf* elf) { return elf64_getphdr(elf); }
  static inline Shdr* getshdr(Elf_Scn* scn) { return elf64_getshdr(scn); }

  enum { kMachine = EM_AARCH64 };
  enum { kFileClass = ELFCLASS64 };
  enum { kRelativeRelocationCode = R_AARCH64_RELATIVE };
  enum { kNoRelocationCode = R_AARCH64_NONE };

  static inline const char* Machine() { return "ARM64"; }

# define ELF_R_SYM(val) ELF64_R_SYM(val)
# define ELF_R_TYPE(val) ELF64_R_TYPE(val)
# define ELF_R_INFO(sym, type) ELF64_R_INFO(sym, type)
# define ELF_ST_TYPE(val) ELF64_ST_TYPE(val)
};
#endif

#endif  // TOOLS_RELOCATION_PACKER_SRC_ELF_TRAITS_H_
