// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Implementation notes:
//
// We need to remove a piece from the ELF shared library.  However, we also
// want to avoid fixing DWARF cfi data and relative relocation addresses.
// So after packing we shift offets and starting address of the RX segment
// while preserving code/data vaddrs location.
// This requires some fixups for symtab/hash/gnu_hash dynamic section addresses.

#include "elf_file.h"

#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <algorithm>
#include <string>
#include <vector>

#include "debug.h"
#include "elf_traits.h"
#include "libelf.h"
#include "packer.h"

namespace relocation_packer {

// Out-of-band dynamic tags used to indicate the offset and size of the
// android packed relocations section.
static constexpr int32_t DT_ANDROID_REL = DT_LOOS + 2;
static constexpr int32_t DT_ANDROID_RELSZ = DT_LOOS + 3;

static constexpr int32_t DT_ANDROID_RELA = DT_LOOS + 4;
static constexpr int32_t DT_ANDROID_RELASZ = DT_LOOS + 5;

static constexpr uint32_t SHT_ANDROID_REL = SHT_LOOS + 1;
static constexpr uint32_t SHT_ANDROID_RELA = SHT_LOOS + 2;

static const size_t kPageSize = 4096;

// Alignment to preserve, in bytes.  This must be at least as large as the
// largest d_align and sh_addralign values found in the loaded file.
// Out of caution for RELRO page alignment, we preserve to a complete target
// page.  See http://www.airs.com/blog/archives/189.
static const size_t kPreserveAlignment = kPageSize;

// Get section data.  Checks that the section has exactly one data entry,
// so that the section size and the data size are the same.  True in
// practice for all sections we resize when packing or unpacking.  Done
// by ensuring that a call to elf_getdata(section, data) returns NULL as
// the next data entry.
static Elf_Data* GetSectionData(Elf_Scn* section) {
  Elf_Data* data = elf_getdata(section, NULL);
  CHECK(data && elf_getdata(section, data) == NULL);
  return data;
}

// Rewrite section data.  Allocates new data and makes it the data element's
// buffer.  Relies on program exit to free allocated data.
static void RewriteSectionData(Elf_Scn* section,
                               const void* section_data,
                               size_t size) {
  Elf_Data* data = GetSectionData(section);
  CHECK(size == data->d_size);
  uint8_t* area = new uint8_t[size];
  memcpy(area, section_data, size);
  data->d_buf = area;
}

// Verbose ELF header logging.
template <typename Ehdr>
static void VerboseLogElfHeader(const Ehdr* elf_header) {
  VLOG(1) << "e_phoff = " << elf_header->e_phoff;
  VLOG(1) << "e_shoff = " << elf_header->e_shoff;
  VLOG(1) << "e_ehsize = " << elf_header->e_ehsize;
  VLOG(1) << "e_phentsize = " << elf_header->e_phentsize;
  VLOG(1) << "e_phnum = " << elf_header->e_phnum;
  VLOG(1) << "e_shnum = " << elf_header->e_shnum;
  VLOG(1) << "e_shstrndx = " << elf_header->e_shstrndx;
}

// Verbose ELF program header logging.
template <typename Phdr>
static void VerboseLogProgramHeader(size_t program_header_index,
                             const Phdr* program_header) {
  std::string type;
  switch (program_header->p_type) {
    case PT_NULL: type = "NULL"; break;
    case PT_LOAD: type = "LOAD"; break;
    case PT_DYNAMIC: type = "DYNAMIC"; break;
    case PT_INTERP: type = "INTERP"; break;
    case PT_PHDR: type = "PHDR"; break;
    case PT_GNU_RELRO: type = "GNU_RELRO"; break;
    case PT_GNU_STACK: type = "GNU_STACK"; break;
    case PT_ARM_EXIDX: type = "EXIDX"; break;
    default: type = "(OTHER)"; break;
  }
  VLOG(1) << "phdr[" << program_header_index << "] : " << type;
  VLOG(1) << "  p_offset = " << program_header->p_offset;
  VLOG(1) << "  p_vaddr = " << program_header->p_vaddr;
  VLOG(1) << "  p_paddr = " << program_header->p_paddr;
  VLOG(1) << "  p_filesz = " << program_header->p_filesz;
  VLOG(1) << "  p_memsz = " << program_header->p_memsz;
  VLOG(1) << "  p_flags = " << program_header->p_flags;
  VLOG(1) << "  p_align = " << program_header->p_align;
}

// Verbose ELF section header logging.
template <typename Shdr>
static void VerboseLogSectionHeader(const std::string& section_name,
                             const Shdr* section_header) {
  VLOG(1) << "section " << section_name;
  VLOG(1) << "  sh_addr = " << section_header->sh_addr;
  VLOG(1) << "  sh_offset = " << section_header->sh_offset;
  VLOG(1) << "  sh_size = " << section_header->sh_size;
  VLOG(1) << "  sh_entsize = " << section_header->sh_entsize;
  VLOG(1) << "  sh_addralign = " << section_header->sh_addralign;
}

// Verbose ELF section data logging.
static void VerboseLogSectionData(const Elf_Data* data) {
  VLOG(1) << "  data";
  VLOG(1) << "    d_buf = " << data->d_buf;
  VLOG(1) << "    d_off = " << data->d_off;
  VLOG(1) << "    d_size = " << data->d_size;
  VLOG(1) << "    d_align = " << data->d_align;
}

// Load the complete ELF file into a memory image in libelf, and identify
// the .rel.dyn or .rela.dyn, .dynamic, and .android.rel.dyn or
// .android.rela.dyn sections.  No-op if the ELF file has already been loaded.
template <typename ELF>
bool ElfFile<ELF>::Load() {
  if (elf_)
    return true;

  Elf* elf = elf_begin(fd_, ELF_C_RDWR, NULL);
  CHECK(elf);

  if (elf_kind(elf) != ELF_K_ELF) {
    LOG(ERROR) << "File not in ELF format";
    return false;
  }

  auto elf_header = ELF::getehdr(elf);
  if (!elf_header) {
    LOG(ERROR) << "Failed to load ELF header: " << elf_errmsg(elf_errno());
    return false;
  }

  if (elf_header->e_type != ET_DYN) {
    LOG(ERROR) << "ELF file is not a shared object";
    return false;
  }

  // Require that our endianness matches that of the target, and that both
  // are little-endian.  Safe for all current build/target combinations.
  const int endian = elf_header->e_ident[EI_DATA];
  CHECK(endian == ELFDATA2LSB);
  CHECK(__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__);

  const int file_class = elf_header->e_ident[EI_CLASS];
  VLOG(1) << "endian = " << endian << ", file class = " << file_class;
  VerboseLogElfHeader(elf_header);

  auto elf_program_header = ELF::getphdr(elf);
  CHECK(elf_program_header != nullptr);

  const typename ELF::Phdr* dynamic_program_header = NULL;
  for (size_t i = 0; i < elf_header->e_phnum; ++i) {
    auto program_header = &elf_program_header[i];
    VerboseLogProgramHeader(i, program_header);

    if (program_header->p_type == PT_DYNAMIC) {
      CHECK(dynamic_program_header == NULL);
      dynamic_program_header = program_header;
    }
  }
  CHECK(dynamic_program_header != nullptr);

  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);

  // Notes of the dynamic relocations, packed relocations, and .dynamic
  // sections.  Found while iterating sections, and later stored in class
  // attributes.
  Elf_Scn* found_relocations_section = nullptr;
  Elf_Scn* found_dynamic_section = nullptr;

  // Notes of relocation section types seen.  We require one or the other of
  // these; both is unsupported.
  bool has_rel_relocations = false;
  bool has_rela_relocations = false;
  bool has_android_relocations = false;

  Elf_Scn* section = NULL;
  while ((section = elf_nextscn(elf, section)) != nullptr) {
    auto section_header = ELF::getshdr(section);
    std::string name = elf_strptr(elf, string_index, section_header->sh_name);
    VerboseLogSectionHeader(name, section_header);

    // Note relocation section types.
    if (section_header->sh_type == SHT_REL || section_header->sh_type == SHT_ANDROID_REL) {
      has_rel_relocations = true;
    }
    if (section_header->sh_type == SHT_RELA || section_header->sh_type == SHT_ANDROID_RELA) {
      has_rela_relocations = true;
    }

    // Note special sections as we encounter them.
    if ((name == ".rel.dyn" || name == ".rela.dyn") &&
        section_header->sh_size > 0) {
      found_relocations_section = section;

      // Note if relocation section is already packed
      has_android_relocations =
          section_header->sh_type == SHT_ANDROID_REL ||
          section_header->sh_type == SHT_ANDROID_RELA;
    }

    if (section_header->sh_offset == dynamic_program_header->p_offset) {
      found_dynamic_section = section;
    }

    // Ensure we preserve alignment, repeated later for the data block(s).
    CHECK(section_header->sh_addralign <= kPreserveAlignment);

    Elf_Data* data = NULL;
    while ((data = elf_getdata(section, data)) != NULL) {
      CHECK(data->d_align <= kPreserveAlignment);
      VerboseLogSectionData(data);
    }
  }

  // Loading failed if we did not find the required special sections.
  if (!found_relocations_section) {
    LOG(ERROR) << "Missing or empty .rel.dyn or .rela.dyn section";
    return false;
  }
  if (!found_dynamic_section) {
    LOG(ERROR) << "Missing .dynamic section";
    return false;
  }

  // Loading failed if we could not identify the relocations type.
  if (!has_rel_relocations && !has_rela_relocations) {
    LOG(ERROR) << "No relocations sections found";
    return false;
  }
  if (has_rel_relocations && has_rela_relocations) {
    LOG(ERROR) << "Multiple relocations sections with different types found, "
               << "not currently supported";
    return false;
  }

  elf_ = elf;
  relocations_section_ = found_relocations_section;
  dynamic_section_ = found_dynamic_section;
  relocations_type_ = has_rel_relocations ? REL : RELA;
  has_android_relocations_ = has_android_relocations;
  return true;
}

// Helper for ResizeSection().  Adjust the main ELF header for the hole.
template <typename ELF>
static void AdjustElfHeaderForHole(typename ELF::Ehdr* elf_header,
                                   typename ELF::Off hole_start,
                                   ssize_t hole_size) {
  if (elf_header->e_phoff > hole_start) {
    elf_header->e_phoff += hole_size;
    VLOG(1) << "e_phoff adjusted to " << elf_header->e_phoff;
  }
  if (elf_header->e_shoff > hole_start) {
    elf_header->e_shoff += hole_size;
    VLOG(1) << "e_shoff adjusted to " << elf_header->e_shoff;
  }
}

// Helper for ResizeSection().  Adjust all section headers for the hole.
template <typename ELF>
static void AdjustSectionHeadersForHole(Elf* elf,
                                        typename ELF::Off hole_start,
                                        ssize_t hole_size) {
  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);

  Elf_Scn* section = NULL;
  while ((section = elf_nextscn(elf, section)) != NULL) {
    auto section_header = ELF::getshdr(section);
    std::string name = elf_strptr(elf, string_index, section_header->sh_name);

    if (section_header->sh_offset > hole_start) {
      section_header->sh_offset += hole_size;
      VLOG(1) << "section " << name
              << " sh_offset adjusted to " << section_header->sh_offset;
    } else {
      section_header->sh_addr -= hole_size;
      VLOG(1) << "section " << name
              << " sh_addr adjusted to " << section_header->sh_addr;
    }
  }
}

// Helpers for ResizeSection().  On packing, reduce p_align for LOAD segments
// to 4kb if larger.  On unpacking, restore p_align for LOAD segments if
// packing reduced it to 4kb.  Return true if p_align was changed.
template <typename ELF>
static bool ClampLoadSegmentAlignment(typename ELF::Phdr* program_header) {
  CHECK(program_header->p_type == PT_LOAD);

  // If large, reduce p_align for a LOAD segment to page size on packing.
  if (program_header->p_align > kPageSize) {
    program_header->p_align = kPageSize;
    return true;
  }
  return false;
}

template <typename ELF>
static bool RestoreLoadSegmentAlignment(typename ELF::Phdr* program_headers,
                                        size_t count,
                                        typename ELF::Phdr* program_header) {
  CHECK(program_header->p_type == PT_LOAD);

  // If p_align was reduced on packing, restore it to its previous value
  // on unpacking.  We do this by searching for a different LOAD segment
  // and setting p_align to that of the other LOAD segment found.
  //
  // Relies on the following observations:
  //   - a packable ELF executable has more than one LOAD segment;
  //   - before packing all LOAD segments have the same p_align;
  //   - on packing we reduce only one LOAD segment's p_align.
  if (program_header->p_align == kPageSize) {
    for (size_t i = 0; i < count; ++i) {
      typename ELF::Phdr* other_header = &program_headers[i];
      if (other_header->p_type == PT_LOAD && other_header != program_header) {
        program_header->p_align = other_header->p_align;
        return true;
      }
    }
    LOG(WARNING) << "Cannot find a LOAD segment from which to restore p_align";
  }
  return false;
}

template <typename ELF>
static bool AdjustLoadSegmentAlignment(typename ELF::Phdr* program_headers,
                                       size_t count,
                                       typename ELF::Phdr* program_header,
                                       ssize_t hole_size) {
  CHECK(program_header->p_type == PT_LOAD);

  bool status = false;
  if (hole_size < 0) {
    status = ClampLoadSegmentAlignment<ELF>(program_header);
  } else if (hole_size > 0) {
    status = RestoreLoadSegmentAlignment<ELF>(program_headers,
                                              count,
                                              program_header);
  }
  return status;
}

// Helper for ResizeSection().  Adjust the offsets of any program headers
// that have offsets currently beyond the hole start, and adjust the
// virtual and physical addrs (and perhaps alignment) of the others.
template <typename ELF>
static void AdjustProgramHeaderFields(typename ELF::Phdr* program_headers,
                                      size_t count,
                                      typename ELF::Off hole_start,
                                      ssize_t hole_size) {
  int alignment_changes = 0;
  for (size_t i = 0; i < count; ++i) {
    typename ELF::Phdr* program_header = &program_headers[i];

    // Do not adjust PT_GNU_STACK - it confuses gdb and results
    // in incorrect unwinding if the executable is stripped after
    // packing.
    if (program_header->p_type == PT_GNU_STACK) {
      continue;
    }

    if (program_header->p_offset > hole_start) {
      // The hole start is past this segment, so adjust offset.
      program_header->p_offset += hole_size;
      VLOG(1) << "phdr[" << i
              << "] p_offset adjusted to "<< program_header->p_offset;
    } else {
      program_header->p_vaddr -= hole_size;
      program_header->p_paddr -= hole_size;

      // If packing, clamp LOAD segment alignment to 4kb to prevent strip
      // from adjusting it unnecessarily if run on a packed file.  If
      // unpacking, attempt to restore a reduced alignment to its previous
      // value.  Ensure that we do this on at most one LOAD segment.
      if (program_header->p_type == PT_LOAD) {
        alignment_changes += AdjustLoadSegmentAlignment<ELF>(program_headers,
                                                             count,
                                                             program_header,
                                                             hole_size);
        LOG_IF(FATAL, alignment_changes > 1)
            << "Changed p_align on more than one LOAD segment";
      }

      VLOG(1) << "phdr[" << i
              << "] p_vaddr adjusted to "<< program_header->p_vaddr
              << "; p_paddr adjusted to "<< program_header->p_paddr
              << "; p_align adjusted to "<< program_header->p_align;
    }
  }
}

// Helper for ResizeSection().  Find the first loadable segment in the
// file.  We expect it to map from file offset zero.
template <typename ELF>
static typename ELF::Phdr* FindLoadSegmentForHole(typename ELF::Phdr* program_headers,
                                                  size_t count,
                                                  typename ELF::Off hole_start) {
  for (size_t i = 0; i < count; ++i) {
    typename ELF::Phdr* program_header = &program_headers[i];

    if (program_header->p_type == PT_LOAD &&
        program_header->p_offset <= hole_start &&
        (program_header->p_offset + program_header->p_filesz) >= hole_start ) {
      return program_header;
    }
  }
  LOG(FATAL) << "Cannot locate a LOAD segment with hole_start=0x" << std::hex << hole_start;
  NOTREACHED();

  return nullptr;
}

// Helper for ResizeSection().  Rewrite program headers.
template <typename ELF>
static void RewriteProgramHeadersForHole(Elf* elf,
                                         typename ELF::Off hole_start,
                                         ssize_t hole_size) {
  const typename ELF::Ehdr* elf_header = ELF::getehdr(elf);
  CHECK(elf_header);

  typename ELF::Phdr* elf_program_header = ELF::getphdr(elf);
  CHECK(elf_program_header);

  const size_t program_header_count = elf_header->e_phnum;

  // Locate the segment that we can overwrite to form the new LOAD entry,
  // and the segment that we are going to split into two parts.
  typename ELF::Phdr* target_load_header =
      FindLoadSegmentForHole<ELF>(elf_program_header, program_header_count, hole_start);

  VLOG(1) << "phdr[" << target_load_header - elf_program_header << "] adjust";
  // Adjust PT_LOAD program header memsz and filesz
  target_load_header->p_filesz += hole_size;
  target_load_header->p_memsz += hole_size;

  // Adjust the offsets and p_vaddrs
  AdjustProgramHeaderFields<ELF>(elf_program_header,
                                 program_header_count,
                                 hole_start,
                                 hole_size);
}

// Helper for ResizeSection().  Locate and return the dynamic section.
template <typename ELF>
static Elf_Scn* GetDynamicSection(Elf* elf) {
  const typename ELF::Ehdr* elf_header = ELF::getehdr(elf);
  CHECK(elf_header);

  const typename ELF::Phdr* elf_program_header = ELF::getphdr(elf);
  CHECK(elf_program_header);

  // Find the program header that describes the dynamic section.
  const typename ELF::Phdr* dynamic_program_header = NULL;
  for (size_t i = 0; i < elf_header->e_phnum; ++i) {
    const typename ELF::Phdr* program_header = &elf_program_header[i];

    if (program_header->p_type == PT_DYNAMIC) {
      dynamic_program_header = program_header;
    }
  }
  CHECK(dynamic_program_header);

  // Now find the section with the same offset as this program header.
  Elf_Scn* dynamic_section = NULL;
  Elf_Scn* section = NULL;
  while ((section = elf_nextscn(elf, section)) != NULL) {
    typename ELF::Shdr* section_header = ELF::getshdr(section);

    if (section_header->sh_offset == dynamic_program_header->p_offset) {
      dynamic_section = section;
    }
  }
  CHECK(dynamic_section != NULL);

  return dynamic_section;
}

// Helper for ResizeSection().  Adjust the .dynamic section for the hole.
template <typename ELF>
void ElfFile<ELF>::AdjustDynamicSectionForHole(Elf_Scn* dynamic_section,
                                               typename ELF::Off hole_start,
                                               ssize_t hole_size,
                                               relocations_type_t relocations_type) {
  CHECK(relocations_type != NONE);
  Elf_Data* data = GetSectionData(dynamic_section);

  auto dynamic_base = reinterpret_cast<typename ELF::Dyn*>(data->d_buf);
  std::vector<typename ELF::Dyn> dynamics(
      dynamic_base,
      dynamic_base + data->d_size / sizeof(dynamics[0]));

  if (hole_size > 0) { // expanding
    hole_start += hole_size;
  }

  for (size_t i = 0; i < dynamics.size(); ++i) {
    typename ELF::Dyn* dynamic = &dynamics[i];
    const typename ELF::Sword tag = dynamic->d_tag;

    // Any tags that hold offsets are adjustment candidates.
    const bool is_adjustable = (tag == DT_PLTGOT ||
                                tag == DT_HASH ||
                                tag == DT_GNU_HASH ||
                                tag == DT_STRTAB ||
                                tag == DT_SYMTAB ||
                                tag == DT_RELA ||
                                tag == DT_INIT ||
                                tag == DT_FINI ||
                                tag == DT_REL ||
                                tag == DT_JMPREL ||
                                tag == DT_INIT_ARRAY ||
                                tag == DT_FINI_ARRAY ||
                                tag == DT_VERSYM ||
                                tag == DT_VERNEED ||
                                tag == DT_VERDEF ||
                                tag == DT_ANDROID_REL||
                                tag == DT_ANDROID_RELA);

    if (is_adjustable && dynamic->d_un.d_ptr <= hole_start) {
      dynamic->d_un.d_ptr -= hole_size;
      VLOG(1) << "dynamic[" << i << "] " << dynamic->d_tag
              << " d_ptr adjusted to " << dynamic->d_un.d_ptr;
    }

    // DT_RELSZ or DT_RELASZ indicate the overall size of relocations.
    // Only one will be present.  Adjust by hole size.
    if (tag == DT_RELSZ || tag == DT_RELASZ || tag == DT_ANDROID_RELSZ || tag == DT_ANDROID_RELASZ) {
      dynamic->d_un.d_val += hole_size;
      VLOG(1) << "dynamic[" << i << "] " << dynamic->d_tag
              << " d_val adjusted to " << dynamic->d_un.d_val;
    }

    // Special case: DT_MIPS_RLD_MAP2 stores the difference between dynamic
    // entry address and the address of the _r_debug (used by GDB)
    // since the dynamic section and target address are on the
    // different sides of the hole it needs to be adjusted accordingly
    if (tag == DT_MIPS_RLD_MAP2) {
      dynamic->d_un.d_val += hole_size;
      VLOG(1) << "dynamic[" << i << "] " << dynamic->d_tag
              << " d_val adjusted to " << dynamic->d_un.d_val;
    }

    // Ignore DT_RELCOUNT and DT_RELACOUNT: (1) nobody uses them and
    // technically (2) the relative relocation count is not changed.

    // DT_RELENT and DT_RELAENT don't change, ignore them as well.
  }

  void* section_data = &dynamics[0];
  size_t bytes = dynamics.size() * sizeof(dynamics[0]);
  RewriteSectionData(dynamic_section, section_data, bytes);
}

// Resize a section.  If the new size is larger than the current size, open
// up a hole by increasing file offsets that come after the hole.  If smaller
// than the current size, remove the hole by decreasing those offsets.
template <typename ELF>
void ElfFile<ELF>::ResizeSection(Elf* elf, Elf_Scn* section, size_t new_size,
                                 typename ELF::Word new_sh_type,
                                 relocations_type_t relocations_type) {

  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);
  auto section_header = ELF::getshdr(section);
  std::string name = elf_strptr(elf, string_index, section_header->sh_name);

  if (section_header->sh_size == new_size) {
    return;
  }

  // Require that the section size and the data size are the same.  True
  // in practice for all sections we resize when packing or unpacking.
  Elf_Data* data = GetSectionData(section);
  CHECK(data->d_off == 0 && data->d_size == section_header->sh_size);

  // Require that the section is not zero-length (that is, has allocated
  // data that we can validly expand).
  CHECK(data->d_size && data->d_buf);

  const auto hole_start = section_header->sh_offset;
  const ssize_t hole_size = new_size - data->d_size;

  VLOG_IF(1, (hole_size > 0)) << "expand section (" << name << ") size: " <<
      data->d_size << " -> " << (data->d_size + hole_size);
  VLOG_IF(1, (hole_size < 0)) << "shrink section (" << name << ") size: " <<
      data->d_size << " -> " << (data->d_size + hole_size);

  // libelf overrides sh_entsize for known sh_types, so it does not matter what we set
  // for SHT_REL/SHT_RELA.
  typename ELF::Xword new_entsize =
      (new_sh_type == SHT_ANDROID_REL || new_sh_type == SHT_ANDROID_RELA) ? 1 : 0;

  VLOG(1) << "Update section (" << name << ") entry size: " <<
      section_header->sh_entsize << " -> " << new_entsize;

  // Resize the data and the section header.
  data->d_size += hole_size;
  section_header->sh_size += hole_size;
  section_header->sh_entsize = new_entsize;
  section_header->sh_type = new_sh_type;

  // Add the hole size to all offsets in the ELF file that are after the
  // start of the hole.  If the hole size is positive we are expanding the
  // section to create a new hole; if negative, we are closing up a hole.

  // Start with the main ELF header.
  typename ELF::Ehdr* elf_header = ELF::getehdr(elf);
  AdjustElfHeaderForHole<ELF>(elf_header, hole_start, hole_size);

  // Adjust all section headers.
  AdjustSectionHeadersForHole<ELF>(elf, hole_start, hole_size);

  // Rewrite the program headers to either split or coalesce segments,
  // and adjust dynamic entries to match.
  RewriteProgramHeadersForHole<ELF>(elf, hole_start, hole_size);

  Elf_Scn* dynamic_section = GetDynamicSection<ELF>(elf);
  AdjustDynamicSectionForHole(dynamic_section, hole_start, hole_size, relocations_type);
}

// Find the first slot in a dynamics array with the given tag.  The array
// always ends with a free (unused) element, and which we exclude from the
// search.  Returns dynamics->size() if not found.
template <typename ELF>
static size_t FindDynamicEntry(typename ELF::Sword tag,
                               std::vector<typename ELF::Dyn>* dynamics) {
  // Loop until the penultimate entry.  We exclude the end sentinel.
  for (size_t i = 0; i < dynamics->size() - 1; ++i) {
    if (dynamics->at(i).d_tag == tag) {
      return i;
    }
  }

  // The tag was not found.
  return dynamics->size();
}

// Replace dynamic entry.
template <typename ELF>
static void ReplaceDynamicEntry(typename ELF::Sword tag,
                                const typename ELF::Dyn& dyn,
                                std::vector<typename ELF::Dyn>* dynamics) {
  const size_t slot = FindDynamicEntry<ELF>(tag, dynamics);
  if (slot == dynamics->size()) {
    LOG(FATAL) << "Dynamic slot is not found for tag=" << tag;
  }

  // Replace this entry with the one supplied.
  dynamics->at(slot) = dyn;
  VLOG(1) << "dynamic[" << slot << "] overwritten with " << dyn.d_tag;
}

// Remove relative entries from dynamic relocations and write as packed
// data into android packed relocations.
template <typename ELF>
bool ElfFile<ELF>::PackRelocations() {
  // Load the ELF file into libelf.
  if (!Load()) {
    LOG(ERROR) << "Failed to load as ELF";
    return false;
  }

  // Retrieve the current dynamic relocations section data.
  Elf_Data* data = GetSectionData(relocations_section_);
  // we always pack rela, because packed format is pretty much the same
  std::vector<typename ELF::Rela> relocations;

  if (relocations_type_ == REL) {
    // Convert data to a vector of relocations.
    const typename ELF::Rel* relocations_base = reinterpret_cast<typename ELF::Rel*>(data->d_buf);
    ConvertRelArrayToRelaVector(relocations_base,
        data->d_size / sizeof(typename ELF::Rel), &relocations);
    VLOG(1) << "Relocations   : REL";
  } else if (relocations_type_ == RELA) {
    // Convert data to a vector of relocations with addends.
    const typename ELF::Rela* relocations_base = reinterpret_cast<typename ELF::Rela*>(data->d_buf);
    relocations = std::vector<typename ELF::Rela>(
        relocations_base,
        relocations_base + data->d_size / sizeof(relocations[0]));

    VLOG(1) << "Relocations   : RELA";
  } else {
    NOTREACHED();
  }

  return PackTypedRelocations(&relocations);
}

// Helper for PackRelocations().  Rel type is one of ELF::Rel or ELF::Rela.
template <typename ELF>
bool ElfFile<ELF>::PackTypedRelocations(std::vector<typename ELF::Rela>* relocations) {
  typedef typename ELF::Rela Rela;

  if (has_android_relocations_) {
    LOG(INFO) << "Relocation table is already packed";
    return true;
  }

  // If no relocations then we have nothing packable.  Perhaps
  // the shared object has already been packed?
  if (relocations->empty()) {
    LOG(ERROR) << "No relocations found";
    return false;
  }

  const size_t rel_size =
      relocations_type_ == RELA ? sizeof(typename ELF::Rela) : sizeof(typename ELF::Rel);
  const size_t initial_bytes = relocations->size() * rel_size;

  VLOG(1) << "Unpacked                   : " << initial_bytes << " bytes";
  std::vector<uint8_t> packed;
  RelocationPacker<ELF> packer;

  // Pack relocations: dry run to estimate memory savings.
  packer.PackRelocations(*relocations, &packed);
  const size_t packed_bytes_estimate = packed.size() * sizeof(packed[0]);
  VLOG(1) << "Packed         (no padding): " << packed_bytes_estimate << " bytes";

  if (packed.empty()) {
    LOG(INFO) << "Too few relocations to pack";
    return true;
  }

  // Pre-calculate the size of the hole we will close up when we rewrite
  // dynamic relocations.  We have to adjust relocation addresses to
  // account for this.
  typename ELF::Shdr* section_header = ELF::getshdr(relocations_section_);
  ssize_t hole_size = initial_bytes - packed_bytes_estimate;

  // hole_size needs to be page_aligned.
  hole_size -= hole_size % kPreserveAlignment;

  LOG(INFO) << "Compaction                 : " << hole_size << " bytes";

  // Adjusting for alignment may have removed any packing benefit.
  if (hole_size == 0) {
    LOG(INFO) << "Too few relocations to pack after alignment";
    return true;
  }

  if (hole_size <= 0) {
    LOG(INFO) << "Packing relocations saves no space";
    return true;
  }

  size_t data_padding_bytes = is_padding_relocations_ ?
      initial_bytes - packed_bytes_estimate :
      initial_bytes - hole_size - packed_bytes_estimate;

  // pad data
  std::vector<uint8_t> padding(data_padding_bytes, 0);
  packed.insert(packed.end(), padding.begin(), padding.end());

  const void* packed_data = &packed[0];

  // Run a loopback self-test as a check that packing is lossless.
  std::vector<Rela> unpacked;
  packer.UnpackRelocations(packed, &unpacked);
  CHECK(unpacked.size() == relocations->size());
  CHECK(!memcmp(&unpacked[0],
                &relocations->at(0),
                unpacked.size() * sizeof(unpacked[0])));

  // Rewrite the current dynamic relocations section with packed one then shrink it to size.
  const size_t bytes = packed.size() * sizeof(packed[0]);
  ResizeSection(elf_, relocations_section_, bytes,
      relocations_type_ == REL ? SHT_ANDROID_REL : SHT_ANDROID_RELA, relocations_type_);
  RewriteSectionData(relocations_section_, packed_data, bytes);

  // TODO (dimitry): fix string table and replace .rel.dyn/plt with .android.rel.dyn/plt

  // Rewrite .dynamic and rename relocation tags describing the packed android
  // relocations.
  Elf_Data* data = GetSectionData(dynamic_section_);
  const typename ELF::Dyn* dynamic_base = reinterpret_cast<typename ELF::Dyn*>(data->d_buf);
  std::vector<typename ELF::Dyn> dynamics(
      dynamic_base,
      dynamic_base + data->d_size / sizeof(dynamics[0]));
  section_header = ELF::getshdr(relocations_section_);
  {
    typename ELF::Dyn dyn;
    dyn.d_tag = relocations_type_ == REL ? DT_ANDROID_REL : DT_ANDROID_RELA;
    dyn.d_un.d_ptr = section_header->sh_addr;
    ReplaceDynamicEntry<ELF>(relocations_type_ == REL ? DT_REL : DT_RELA, dyn, &dynamics);
  }
  {
    typename ELF::Dyn dyn;
    dyn.d_tag = relocations_type_ == REL ? DT_ANDROID_RELSZ : DT_ANDROID_RELASZ;
    dyn.d_un.d_val = section_header->sh_size;
    ReplaceDynamicEntry<ELF>(relocations_type_ == REL ? DT_RELSZ : DT_RELASZ, dyn, &dynamics);
  }

  const void* dynamics_data = &dynamics[0];
  const size_t dynamics_bytes = dynamics.size() * sizeof(dynamics[0]);
  RewriteSectionData(dynamic_section_, dynamics_data, dynamics_bytes);

  Flush();
  return true;
}

// Find packed relative relocations in the packed android relocations
// section, unpack them, and rewrite the dynamic relocations section to
// contain unpacked data.
template <typename ELF>
bool ElfFile<ELF>::UnpackRelocations() {
  // Load the ELF file into libelf.
  if (!Load()) {
    LOG(ERROR) << "Failed to load as ELF";
    return false;
  }

  typename ELF::Shdr* section_header = ELF::getshdr(relocations_section_);
  // Retrieve the current packed android relocations section data.
  Elf_Data* data = GetSectionData(relocations_section_);

  // Convert data to a vector of bytes.
  const uint8_t* packed_base = reinterpret_cast<uint8_t*>(data->d_buf);
  std::vector<uint8_t> packed(
      packed_base,
      packed_base + data->d_size / sizeof(packed[0]));

  if ((section_header->sh_type == SHT_ANDROID_RELA || section_header->sh_type == SHT_ANDROID_REL) &&
      packed.size() > 3 &&
      packed[0] == 'A' &&
      packed[1] == 'P' &&
      packed[2] == 'S' &&
      packed[3] == '2') {
    LOG(INFO) << "Relocations   : " << (relocations_type_ == REL ? "REL" : "RELA");
  } else {
    LOG(ERROR) << "Packed relocations not found (not packed?)";
    return false;
  }

  return UnpackTypedRelocations(packed);
}

// Helper for UnpackRelocations().  Rel type is one of ELF::Rel or ELF::Rela.
template <typename ELF>
bool ElfFile<ELF>::UnpackTypedRelocations(const std::vector<uint8_t>& packed) {
  // Unpack the data to re-materialize the relative relocations.
  const size_t packed_bytes = packed.size() * sizeof(packed[0]);
  LOG(INFO) << "Packed           : " << packed_bytes << " bytes";
  std::vector<typename ELF::Rela> unpacked_relocations;
  RelocationPacker<ELF> packer;
  packer.UnpackRelocations(packed, &unpacked_relocations);

  const size_t relocation_entry_size =
      relocations_type_ == REL ? sizeof(typename ELF::Rel) : sizeof(typename ELF::Rela);
  const size_t unpacked_bytes = unpacked_relocations.size() * relocation_entry_size;
  LOG(INFO) << "Unpacked         : " << unpacked_bytes << " bytes";

  // Retrieve the current dynamic relocations section data.
  Elf_Data* data = GetSectionData(relocations_section_);

  LOG(INFO) << "Relocations      : " << unpacked_relocations.size() << " entries";

  // If we found the same number of null relocation entries in the dynamic
  // relocations section as we hold as unpacked relative relocations, then
  // this is a padded file.

  const bool is_padded = packed_bytes == unpacked_bytes;

  // Unless padded, pre-apply relative relocations to account for the
  // hole, and pre-adjust all relocation offsets accordingly.
  typename ELF::Shdr* section_header = ELF::getshdr(relocations_section_);

  if (!is_padded) {
    LOG(INFO) << "Expansion     : " << unpacked_bytes - packed_bytes << " bytes";
  }

  // Rewrite the current dynamic relocations section with unpacked version of
  // relocations.
  const void* section_data = nullptr;
  std::vector<typename ELF::Rel> unpacked_rel_relocations;
  if (relocations_type_ == RELA) {
    section_data = &unpacked_relocations[0];
  } else if (relocations_type_ == REL) {
    ConvertRelaVectorToRelVector(unpacked_relocations, &unpacked_rel_relocations);
    section_data = &unpacked_rel_relocations[0];
  } else {
    NOTREACHED();
  }

  ResizeSection(elf_, relocations_section_, unpacked_bytes,
      relocations_type_ == REL ? SHT_REL : SHT_RELA, relocations_type_);
  RewriteSectionData(relocations_section_, section_data, unpacked_bytes);

  // Rewrite .dynamic to remove two tags describing packed android relocations.
  data = GetSectionData(dynamic_section_);
  const typename ELF::Dyn* dynamic_base = reinterpret_cast<typename ELF::Dyn*>(data->d_buf);
  std::vector<typename ELF::Dyn> dynamics(
      dynamic_base,
      dynamic_base + data->d_size / sizeof(dynamics[0]));
  {
    typename ELF::Dyn dyn;
    dyn.d_tag = relocations_type_ == REL ? DT_REL : DT_RELA;
    dyn.d_un.d_ptr = section_header->sh_addr;
    ReplaceDynamicEntry<ELF>(relocations_type_ == REL ? DT_ANDROID_REL : DT_ANDROID_RELA,
        dyn, &dynamics);
  }

  {
    typename ELF::Dyn dyn;
    dyn.d_tag = relocations_type_ == REL ? DT_RELSZ : DT_RELASZ;
    dyn.d_un.d_val = section_header->sh_size;
    ReplaceDynamicEntry<ELF>(relocations_type_ == REL ? DT_ANDROID_RELSZ : DT_ANDROID_RELASZ,
        dyn, &dynamics);
  }

  const void* dynamics_data = &dynamics[0];
  const size_t dynamics_bytes = dynamics.size() * sizeof(dynamics[0]);
  RewriteSectionData(dynamic_section_, dynamics_data, dynamics_bytes);

  Flush();
  return true;
}

// Flush rewritten shared object file data.
template <typename ELF>
void ElfFile<ELF>::Flush() {
  // Flag all ELF data held in memory as needing to be written back to the
  // file, and tell libelf that we have controlled the file layout.
  elf_flagelf(elf_, ELF_C_SET, ELF_F_DIRTY);
  elf_flagelf(elf_, ELF_C_SET, ELF_F_LAYOUT);

  // Write ELF data back to disk.
  const off_t file_bytes = elf_update(elf_, ELF_C_WRITE);
  if (file_bytes == -1) {
    LOG(ERROR) << "elf_update failed: " << elf_errmsg(elf_errno());
  }

  CHECK(file_bytes > 0);
  VLOG(1) << "elf_update returned: " << file_bytes;

  // Clean up libelf, and truncate the output file to the number of bytes
  // written by elf_update().
  elf_end(elf_);
  elf_ = NULL;
  const int truncate = ftruncate(fd_, file_bytes);
  CHECK(truncate == 0);
}

template <typename ELF>
void ElfFile<ELF>::ConvertRelArrayToRelaVector(const typename ELF::Rel* rel_array,
                                               size_t rel_array_size,
                                               std::vector<typename ELF::Rela>* rela_vector) {
  for (size_t i = 0; i<rel_array_size; ++i) {
    typename ELF::Rela rela;
    rela.r_offset = rel_array[i].r_offset;
    rela.r_info = rel_array[i].r_info;
    rela.r_addend = 0;
    rela_vector->push_back(rela);
  }
}

template <typename ELF>
void ElfFile<ELF>::ConvertRelaVectorToRelVector(const std::vector<typename ELF::Rela>& rela_vector,
                                                std::vector<typename ELF::Rel>* rel_vector) {
  for (auto rela : rela_vector) {
    typename ELF::Rel rel;
    rel.r_offset = rela.r_offset;
    rel.r_info = rela.r_info;
    CHECK(rela.r_addend == 0);
    rel_vector->push_back(rel);
  }
}

template class ElfFile<ELF32_traits>;
template class ElfFile<ELF64_traits>;

}  // namespace relocation_packer
