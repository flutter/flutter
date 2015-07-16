// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Implementation notes:
//
// We need to remove a piece from the ELF shared library.  However, we also
// want to ensure that code and data loads at the same addresses as before
// packing, so that tools like breakpad can still match up addresses found
// in any crash dumps with data extracted from the pre-packed version of
// the shared library.
//
// Arranging this means that we have to split one of the LOAD segments into
// two.  Unfortunately, the program headers are located at the very start
// of the shared library file, so expanding the program header section
// would cause a lot of consequent changes to files offsets that we don't
// really want to have to handle.
//
// Luckily, though, there is a segment that is always present and always
// unused on Android; the GNU_STACK segment.  What we do is to steal that
// and repurpose it to be one of the split LOAD segments.  We then have to
// sort LOAD segments by offset to keep the crazy linker happy.
//
// All of this takes place in SplitProgramHeadersForHole(), used on packing,
// and is unraveled on unpacking in CoalesceProgramHeadersForHole().  See
// commentary on those functions for an example of this segment stealing
// in action.

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

// Stub identifier written to 'null out' packed data, "NULL".
static const uint32_t kStubIdentifier = 0x4c4c554eu;

// Out-of-band dynamic tags used to indicate the offset and size of the
// android packed relocations section.
static const ELF::Sword DT_ANDROID_REL_OFFSET = DT_LOOS;
static const ELF::Sword DT_ANDROID_REL_SIZE = DT_LOOS + 1;

// Alignment to preserve, in bytes.  This must be at least as large as the
// largest d_align and sh_addralign values found in the loaded file.
// Out of caution for RELRO page alignment, we preserve to a complete target
// page.  See http://www.airs.com/blog/archives/189.
static const size_t kPreserveAlignment = 4096;

// Alignment values used by ld and gold for the GNU_STACK segment.  Different
// linkers write different values; the actual value is immaterial on Android
// because it ignores GNU_STACK segments.  However, it is useful for binary
// comparison and unit test purposes if packing and unpacking can preserve
// them through a round-trip.
static const size_t kLdGnuStackSegmentAlignment = 16;
static const size_t kGoldGnuStackSegmentAlignment = 0;

namespace {

// Get section data.  Checks that the section has exactly one data entry,
// so that the section size and the data size are the same.  True in
// practice for all sections we resize when packing or unpacking.  Done
// by ensuring that a call to elf_getdata(section, data) returns NULL as
// the next data entry.
Elf_Data* GetSectionData(Elf_Scn* section) {
  Elf_Data* data = elf_getdata(section, NULL);
  CHECK(data && elf_getdata(section, data) == NULL);
  return data;
}

// Rewrite section data.  Allocates new data and makes it the data element's
// buffer.  Relies on program exit to free allocated data.
void RewriteSectionData(Elf_Scn* section,
                        const void* section_data,
                        size_t size) {
  Elf_Data* data = GetSectionData(section);
  CHECK(size == data->d_size);
  uint8_t* area = new uint8_t[size];
  memcpy(area, section_data, size);
  data->d_buf = area;
}

// Verbose ELF header logging.
void VerboseLogElfHeader(const ELF::Ehdr* elf_header) {
  VLOG(1) << "e_phoff = " << elf_header->e_phoff;
  VLOG(1) << "e_shoff = " << elf_header->e_shoff;
  VLOG(1) << "e_ehsize = " << elf_header->e_ehsize;
  VLOG(1) << "e_phentsize = " << elf_header->e_phentsize;
  VLOG(1) << "e_phnum = " << elf_header->e_phnum;
  VLOG(1) << "e_shnum = " << elf_header->e_shnum;
  VLOG(1) << "e_shstrndx = " << elf_header->e_shstrndx;
}

// Verbose ELF program header logging.
void VerboseLogProgramHeader(size_t program_header_index,
                             const ELF::Phdr* program_header) {
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
void VerboseLogSectionHeader(const std::string& section_name,
                             const ELF::Shdr* section_header) {
  VLOG(1) << "section " << section_name;
  VLOG(1) << "  sh_addr = " << section_header->sh_addr;
  VLOG(1) << "  sh_offset = " << section_header->sh_offset;
  VLOG(1) << "  sh_size = " << section_header->sh_size;
  VLOG(1) << "  sh_addralign = " << section_header->sh_addralign;
}

// Verbose ELF section data logging.
void VerboseLogSectionData(const Elf_Data* data) {
  VLOG(1) << "  data";
  VLOG(1) << "    d_buf = " << data->d_buf;
  VLOG(1) << "    d_off = " << data->d_off;
  VLOG(1) << "    d_size = " << data->d_size;
  VLOG(1) << "    d_align = " << data->d_align;
}

}  // namespace

// Load the complete ELF file into a memory image in libelf, and identify
// the .rel.dyn or .rela.dyn, .dynamic, and .android.rel.dyn or
// .android.rela.dyn sections.  No-op if the ELF file has already been loaded.
bool ElfFile::Load() {
  if (elf_)
    return true;

  Elf* elf = elf_begin(fd_, ELF_C_RDWR, NULL);
  CHECK(elf);

  if (elf_kind(elf) != ELF_K_ELF) {
    LOG(ERROR) << "File not in ELF format";
    return false;
  }

  ELF::Ehdr* elf_header = ELF::getehdr(elf);
  if (!elf_header) {
    LOG(ERROR) << "Failed to load ELF header: " << elf_errmsg(elf_errno());
    return false;
  }
  if (elf_header->e_machine != ELF::kMachine) {
    LOG(ERROR) << "ELF file architecture is not " << ELF::Machine();
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

  // Also require that the file class is as expected.
  const int file_class = elf_header->e_ident[EI_CLASS];
  CHECK(file_class == ELF::kFileClass);

  VLOG(1) << "endian = " << endian << ", file class = " << file_class;
  VerboseLogElfHeader(elf_header);

  const ELF::Phdr* elf_program_header = ELF::getphdr(elf);
  CHECK(elf_program_header);

  const ELF::Phdr* dynamic_program_header = NULL;
  for (size_t i = 0; i < elf_header->e_phnum; ++i) {
    const ELF::Phdr* program_header = &elf_program_header[i];
    VerboseLogProgramHeader(i, program_header);

    if (program_header->p_type == PT_DYNAMIC) {
      CHECK(dynamic_program_header == NULL);
      dynamic_program_header = program_header;
    }
  }
  CHECK(dynamic_program_header != NULL);

  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);

  // Notes of the dynamic relocations, packed relocations, and .dynamic
  // sections.  Found while iterating sections, and later stored in class
  // attributes.
  Elf_Scn* found_relocations_section = NULL;
  Elf_Scn* found_android_relocations_section = NULL;
  Elf_Scn* found_dynamic_section = NULL;

  // Notes of relocation section types seen.  We require one or the other of
  // these; both is unsupported.
  bool has_rel_relocations = false;
  bool has_rela_relocations = false;

  Elf_Scn* section = NULL;
  while ((section = elf_nextscn(elf, section)) != NULL) {
    const ELF::Shdr* section_header = ELF::getshdr(section);
    std::string name = elf_strptr(elf, string_index, section_header->sh_name);
    VerboseLogSectionHeader(name, section_header);

    // Note relocation section types.
    if (section_header->sh_type == SHT_REL) {
      has_rel_relocations = true;
    }
    if (section_header->sh_type == SHT_RELA) {
      has_rela_relocations = true;
    }

    // Note special sections as we encounter them.
    if ((name == ".rel.dyn" || name == ".rela.dyn") &&
        section_header->sh_size > 0) {
      found_relocations_section = section;
    }
    if ((name == ".android.rel.dyn" || name == ".android.rela.dyn") &&
        section_header->sh_size > 0) {
      found_android_relocations_section = section;
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
  if (!found_android_relocations_section) {
    LOG(ERROR) << "Missing or empty .android.rel.dyn or .android.rela.dyn "
               << "section (to fix, run with --help and follow the "
               << "pre-packing instructions)";
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
  android_relocations_section_ = found_android_relocations_section;
  relocations_type_ = has_rel_relocations ? REL : RELA;
  return true;
}

namespace {

// Helper for ResizeSection().  Adjust the main ELF header for the hole.
void AdjustElfHeaderForHole(ELF::Ehdr* elf_header,
                            ELF::Off hole_start,
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
void AdjustSectionHeadersForHole(Elf* elf,
                                 ELF::Off hole_start,
                                 ssize_t hole_size) {
  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);

  Elf_Scn* section = NULL;
  while ((section = elf_nextscn(elf, section)) != NULL) {
    ELF::Shdr* section_header = ELF::getshdr(section);
    std::string name = elf_strptr(elf, string_index, section_header->sh_name);

    if (section_header->sh_offset > hole_start) {
      section_header->sh_offset += hole_size;
      VLOG(1) << "section " << name
              << " sh_offset adjusted to " << section_header->sh_offset;
    }
  }
}

// Helper for ResizeSection().  Adjust the offsets of any program headers
// that have offsets currently beyond the hole start.
void AdjustProgramHeaderOffsets(ELF::Phdr* program_headers,
                                size_t count,
                                ELF::Phdr* ignored_1,
                                ELF::Phdr* ignored_2,
                                ELF::Off hole_start,
                                ssize_t hole_size) {
  for (size_t i = 0; i < count; ++i) {
    ELF::Phdr* program_header = &program_headers[i];

    if (program_header == ignored_1 || program_header == ignored_2)
      continue;

    if (program_header->p_offset > hole_start) {
      // The hole start is past this segment, so adjust offset.
      program_header->p_offset += hole_size;
      VLOG(1) << "phdr[" << i
              << "] p_offset adjusted to "<< program_header->p_offset;
    }
  }
}

// Helper for ResizeSection().  Find the first loadable segment in the
// file.  We expect it to map from file offset zero.
ELF::Phdr* FindFirstLoadSegment(ELF::Phdr* program_headers,
                                size_t count) {
  ELF::Phdr* first_loadable_segment = NULL;

  for (size_t i = 0; i < count; ++i) {
    ELF::Phdr* program_header = &program_headers[i];

    if (program_header->p_type == PT_LOAD &&
        program_header->p_offset == 0 &&
        program_header->p_vaddr == 0 &&
        program_header->p_paddr == 0) {
      first_loadable_segment = program_header;
    }
  }
  LOG_IF(FATAL, !first_loadable_segment)
      << "Cannot locate a LOAD segment with address and offset zero";

  return first_loadable_segment;
}

// Helper for ResizeSection().  Deduce the alignment that the PT_GNU_STACK
// segment will use.  Determined by sensing the linker that was used to
// create the shared library.
size_t DeduceGnuStackSegmentAlignment(Elf* elf) {
  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);

  Elf_Scn* section = NULL;
  size_t gnu_stack_segment_alignment = kLdGnuStackSegmentAlignment;

  while ((section = elf_nextscn(elf, section)) != NULL) {
    const ELF::Shdr* section_header = ELF::getshdr(section);
    std::string name = elf_strptr(elf, string_index, section_header->sh_name);

    if (name == ".note.gnu.gold-version") {
      gnu_stack_segment_alignment = kGoldGnuStackSegmentAlignment;
      break;
    }
  }

  return gnu_stack_segment_alignment;
}

// Helper for ResizeSection().  Find the PT_GNU_STACK segment, and check
// that it contains what we expect so we can restore it on unpack if needed.
ELF::Phdr* FindUnusedGnuStackSegment(Elf* elf,
                                     ELF::Phdr* program_headers,
                                     size_t count) {
  ELF::Phdr* unused_segment = NULL;
  const size_t stack_alignment = DeduceGnuStackSegmentAlignment(elf);

  for (size_t i = 0; i < count; ++i) {
    ELF::Phdr* program_header = &program_headers[i];

    if (program_header->p_type == PT_GNU_STACK &&
        program_header->p_offset == 0 &&
        program_header->p_vaddr == 0 &&
        program_header->p_paddr == 0 &&
        program_header->p_filesz == 0 &&
        program_header->p_memsz == 0 &&
        program_header->p_flags == (PF_R | PF_W) &&
        program_header->p_align == stack_alignment) {
      unused_segment = program_header;
    }
  }
  LOG_IF(FATAL, !unused_segment)
      << "Cannot locate the expected GNU_STACK segment";

  return unused_segment;
}

// Helper for ResizeSection().  Find the segment that was the first loadable
// one before we split it into two.  This is the one into which we coalesce
// the split segments on unpacking.
ELF::Phdr* FindOriginalFirstLoadSegment(ELF::Phdr* program_headers,
                                        size_t count) {
  const ELF::Phdr* first_loadable_segment =
      FindFirstLoadSegment(program_headers, count);

  ELF::Phdr* original_first_loadable_segment = NULL;

  for (size_t i = 0; i < count; ++i) {
    ELF::Phdr* program_header = &program_headers[i];

    // The original first loadable segment is the one that follows on from
    // the one we wrote on split to be the current first loadable segment.
    if (program_header->p_type == PT_LOAD &&
        program_header->p_offset == first_loadable_segment->p_filesz) {
      original_first_loadable_segment = program_header;
    }
  }
  LOG_IF(FATAL, !original_first_loadable_segment)
      << "Cannot locate the LOAD segment that follows a LOAD at offset zero";

  return original_first_loadable_segment;
}

// Helper for ResizeSection().  Find the segment that contains the hole.
Elf_Scn* FindSectionContainingHole(Elf* elf,
                                   ELF::Off hole_start,
                                   ssize_t hole_size) {
  Elf_Scn* section = NULL;
  Elf_Scn* last_unholed_section = NULL;

  while ((section = elf_nextscn(elf, section)) != NULL) {
    const ELF::Shdr* section_header = ELF::getshdr(section);

    // Because we get here after section headers have been adjusted for the
    // hole, we need to 'undo' that adjustment to give a view of the original
    // sections layout.
    ELF::Off offset = section_header->sh_offset;
    if (section_header->sh_offset >= hole_start) {
      offset -= hole_size;
    }

    if (offset <= hole_start) {
      last_unholed_section = section;
    }
  }
  LOG_IF(FATAL, !last_unholed_section)
      << "Cannot identify the section before the one containing the hole";

  // The section containing the hole is the one after the last one found
  // by the loop above.
  Elf_Scn* holed_section = elf_nextscn(elf, last_unholed_section);
  LOG_IF(FATAL, !holed_section)
      << "Cannot identify the section containing the hole";

  return holed_section;
}

// Helper for ResizeSection().  Find the last section contained in a segment.
Elf_Scn* FindLastSectionInSegment(Elf* elf,
                                  ELF::Phdr* program_header,
                                  ELF::Off hole_start,
                                  ssize_t hole_size) {
  const ELF::Off segment_end =
      program_header->p_offset + program_header->p_filesz;

  Elf_Scn* section = NULL;
  Elf_Scn* last_section = NULL;

  while ((section = elf_nextscn(elf, section)) != NULL) {
    const ELF::Shdr* section_header = ELF::getshdr(section);

    // As above, 'undo' any section offset adjustment to give a view of the
    // original sections layout.
    ELF::Off offset = section_header->sh_offset;
    if (section_header->sh_offset >= hole_start) {
      offset -= hole_size;
    }

    if (offset < segment_end) {
      last_section = section;
    }
  }
  LOG_IF(FATAL, !last_section)
      << "Cannot identify the last section in the given segment";

  return last_section;
}

// Helper for ResizeSection().  Order loadable segments by their offsets.
// The crazy linker contains assumptions about loadable segment ordering,
// and it is better if we do not break them.
void SortOrderSensitiveProgramHeaders(ELF::Phdr* program_headers,
                                      size_t count) {
  std::vector<ELF::Phdr*> orderable;

  // Collect together orderable program headers.  These are all the LOAD
  // segments, and any GNU_STACK that may be present (removed on packing,
  // but replaced on unpacking).
  for (size_t i = 0; i < count; ++i) {
    ELF::Phdr* program_header = &program_headers[i];

    if (program_header->p_type == PT_LOAD ||
        program_header->p_type == PT_GNU_STACK) {
      orderable.push_back(program_header);
    }
  }

  // Order these program headers so that any PT_GNU_STACK is last, and
  // the LOAD segments that precede it appear in offset order.  Uses
  // insertion sort.
  for (size_t i = 1; i < orderable.size(); ++i) {
    for (size_t j = i; j > 0; --j) {
      ELF::Phdr* first = orderable[j - 1];
      ELF::Phdr* second = orderable[j];

      if (!(first->p_type == PT_GNU_STACK ||
            first->p_offset > second->p_offset)) {
        break;
      }
      std::swap(*first, *second);
    }
  }
}

// Helper for ResizeSection().  The GNU_STACK program header is unused in
// Android, so we can repurpose it here.  Before packing, the program header
// table contains something like:
//
//   Type      Offset    VirtAddr   PhysAddr   FileSiz   MemSiz    Flg Align
//   LOAD      0x000000  0x00000000 0x00000000 0x1efc818 0x1efc818 R E 0x1000
//   LOAD      0x1efd008 0x01efe008 0x01efe008 0x17ec3c  0x1a0324  RW  0x1000
//   DYNAMIC   0x205ec50 0x0205fc50 0x0205fc50 0x00108   0x00108   RW  0x4
//   GNU_STACK 0x000000  0x00000000 0x00000000 0x00000   0x00000   RW  0
//
// The hole in the file is in the first of these.  In order to preserve all
// load addresses, what we do is to turn the GNU_STACK into a new LOAD entry
// that maps segments up to where we created the hole, adjust the first LOAD
// entry so that it maps segments after that, adjust any other program
// headers whose offset is after the hole start, and finally order the LOAD
// segments by offset, to give:
//
//   Type      Offset    VirtAddr   PhysAddr   FileSiz   MemSiz    Flg Align
//   LOAD      0x000000  0x00000000 0x00000000 0x14ea4   0x14ea4   R E 0x1000
//   LOAD      0x014ea4  0x00212ea4 0x00212ea4 0x1cea164 0x1cea164 R E 0x1000
//   DYNAMIC   0x1e60c50 0x0205fc50 0x0205fc50 0x00108   0x00108   RW  0x4
//   LOAD      0x1cff008 0x01efe008 0x01efe008 0x17ec3c  0x1a0324  RW  0x1000
//
// We work out the split points by finding the .rel.dyn or .rela.dyn section
// that contains the hole, and by finding the last section in a given segment.
//
// To unpack, we reverse the above to leave the file as it was originally.
void SplitProgramHeadersForHole(Elf* elf,
                                ELF::Off hole_start,
                                ssize_t hole_size) {
  CHECK(hole_size < 0);
  const ELF::Ehdr* elf_header = ELF::getehdr(elf);
  CHECK(elf_header);

  ELF::Phdr* elf_program_header = ELF::getphdr(elf);
  CHECK(elf_program_header);

  const size_t program_header_count = elf_header->e_phnum;

  // Locate the segment that we can overwrite to form the new LOAD entry,
  // and the segment that we are going to split into two parts.
  ELF::Phdr* spliced_header =
      FindUnusedGnuStackSegment(elf, elf_program_header, program_header_count);
  ELF::Phdr* split_header =
      FindFirstLoadSegment(elf_program_header, program_header_count);

  VLOG(1) << "phdr[" << split_header - elf_program_header << "] split";
  VLOG(1) << "phdr[" << spliced_header - elf_program_header << "] new LOAD";

  // Find the section that contains the hole.  We split on the section that
  // follows it.
  Elf_Scn* holed_section =
      FindSectionContainingHole(elf, hole_start, hole_size);

  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);

  ELF::Shdr* section_header = ELF::getshdr(holed_section);
  std::string name = elf_strptr(elf, string_index, section_header->sh_name);
  VLOG(1) << "section " << name << " split after";

  // Find the last section in the segment we are splitting.
  Elf_Scn* last_section =
      FindLastSectionInSegment(elf, split_header, hole_start, hole_size);

  section_header = ELF::getshdr(last_section);
  name = elf_strptr(elf, string_index, section_header->sh_name);
  VLOG(1) << "section " << name << " split end";

  // Split on the section following the holed one, and up to (but not
  // including) the section following the last one in the split segment.
  Elf_Scn* split_section = elf_nextscn(elf, holed_section);
  LOG_IF(FATAL, !split_section)
      << "No section follows the section that contains the hole";
  Elf_Scn* end_section = elf_nextscn(elf, last_section);
  LOG_IF(FATAL, !end_section)
      << "No section follows the last section in the segment being split";

  // Split the first portion of split_header into spliced_header.
  const ELF::Shdr* split_section_header = ELF::getshdr(split_section);
  spliced_header->p_type = split_header->p_type;
  spliced_header->p_offset = split_header->p_offset;
  spliced_header->p_vaddr = split_header->p_vaddr;
  spliced_header->p_paddr = split_header->p_paddr;
  CHECK(split_header->p_filesz == split_header->p_memsz);
  spliced_header->p_filesz = split_section_header->sh_offset;
  spliced_header->p_memsz = split_section_header->sh_offset;
  spliced_header->p_flags = split_header->p_flags;
  spliced_header->p_align = split_header->p_align;

  // Now rewrite split_header to remove the part we spliced from it.
  const ELF::Shdr* end_section_header = ELF::getshdr(end_section);
  split_header->p_offset = spliced_header->p_filesz;
  CHECK(split_header->p_vaddr == split_header->p_paddr);
  split_header->p_vaddr = split_section_header->sh_addr;
  split_header->p_paddr = split_section_header->sh_addr;
  CHECK(split_header->p_filesz == split_header->p_memsz);
  split_header->p_filesz =
      end_section_header->sh_offset - spliced_header->p_filesz;
  split_header->p_memsz =
      end_section_header->sh_offset - spliced_header->p_filesz;

  // Adjust the offsets of all program headers that are not one of the pair
  // we just created by splitting.
  AdjustProgramHeaderOffsets(elf_program_header,
                             program_header_count,
                             spliced_header,
                             split_header,
                             hole_start,
                             hole_size);

  // Finally, order loadable segments by offset/address.  The crazy linker
  // contains assumptions about loadable segment ordering.
  SortOrderSensitiveProgramHeaders(elf_program_header,
                                   program_header_count);
}

// Helper for ResizeSection().  Undo the work of SplitProgramHeadersForHole().
void CoalesceProgramHeadersForHole(Elf* elf,
                                   ELF::Off hole_start,
                                   ssize_t hole_size) {
  CHECK(hole_size > 0);
  const ELF::Ehdr* elf_header = ELF::getehdr(elf);
  CHECK(elf_header);

  ELF::Phdr* elf_program_header = ELF::getphdr(elf);
  CHECK(elf_program_header);

  const size_t program_header_count = elf_header->e_phnum;

  // Locate the segment that we overwrote to form the new LOAD entry, and
  // the segment that we split into two parts on packing.
  ELF::Phdr* spliced_header =
      FindFirstLoadSegment(elf_program_header, program_header_count);
  ELF::Phdr* split_header =
      FindOriginalFirstLoadSegment(elf_program_header, program_header_count);

  VLOG(1) << "phdr[" << spliced_header - elf_program_header << "] stack";
  VLOG(1) << "phdr[" << split_header - elf_program_header << "] coalesce";

  // Find the last section in the second segment we are coalescing.
  Elf_Scn* last_section =
      FindLastSectionInSegment(elf, split_header, hole_start, hole_size);

  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);

  const ELF::Shdr* section_header = ELF::getshdr(last_section);
  std::string name = elf_strptr(elf, string_index, section_header->sh_name);
  VLOG(1) << "section " << name << " coalesced";

  // Rewrite the coalesced segment into split_header.
  const ELF::Shdr* last_section_header = ELF::getshdr(last_section);
  split_header->p_offset = spliced_header->p_offset;
  CHECK(split_header->p_vaddr == split_header->p_paddr);
  split_header->p_vaddr = spliced_header->p_vaddr;
  split_header->p_paddr = spliced_header->p_vaddr;
  CHECK(split_header->p_filesz == split_header->p_memsz);
  split_header->p_filesz =
      last_section_header->sh_offset + last_section_header->sh_size;
  split_header->p_memsz =
      last_section_header->sh_offset + last_section_header->sh_size;

  // Reconstruct the original GNU_STACK segment into spliced_header.
  const size_t stack_alignment = DeduceGnuStackSegmentAlignment(elf);
  spliced_header->p_type = PT_GNU_STACK;
  spliced_header->p_offset = 0;
  spliced_header->p_vaddr = 0;
  spliced_header->p_paddr = 0;
  spliced_header->p_filesz = 0;
  spliced_header->p_memsz = 0;
  spliced_header->p_flags = PF_R | PF_W;
  spliced_header->p_align = stack_alignment;

  // Adjust the offsets of all program headers that are not one of the pair
  // we just coalesced.
  AdjustProgramHeaderOffsets(elf_program_header,
                             program_header_count,
                             spliced_header,
                             split_header,
                             hole_start,
                             hole_size);

  // Finally, order loadable segments by offset/address.  The crazy linker
  // contains assumptions about loadable segment ordering.
  SortOrderSensitiveProgramHeaders(elf_program_header,
                                   program_header_count);
}

// Helper for ResizeSection().  Rewrite program headers.
void RewriteProgramHeadersForHole(Elf* elf,
                                  ELF::Off hole_start,
                                  ssize_t hole_size) {
  // If hole_size is negative then we are removing a piece of the file, and
  // we want to split program headers so that we keep the same addresses
  // for text and data.  If positive, then we are putting that piece of the
  // file back in, so we coalesce the previously split program headers.
  if (hole_size < 0)
    SplitProgramHeadersForHole(elf, hole_start, hole_size);
  else if (hole_size > 0)
    CoalesceProgramHeadersForHole(elf, hole_start, hole_size);
}

// Helper for ResizeSection().  Locate and return the dynamic section.
Elf_Scn* GetDynamicSection(Elf* elf) {
  const ELF::Ehdr* elf_header = ELF::getehdr(elf);
  CHECK(elf_header);

  const ELF::Phdr* elf_program_header = ELF::getphdr(elf);
  CHECK(elf_program_header);

  // Find the program header that describes the dynamic section.
  const ELF::Phdr* dynamic_program_header = NULL;
  for (size_t i = 0; i < elf_header->e_phnum; ++i) {
    const ELF::Phdr* program_header = &elf_program_header[i];

    if (program_header->p_type == PT_DYNAMIC) {
      dynamic_program_header = program_header;
    }
  }
  CHECK(dynamic_program_header);

  // Now find the section with the same offset as this program header.
  Elf_Scn* dynamic_section = NULL;
  Elf_Scn* section = NULL;
  while ((section = elf_nextscn(elf, section)) != NULL) {
    ELF::Shdr* section_header = ELF::getshdr(section);

    if (section_header->sh_offset == dynamic_program_header->p_offset) {
      dynamic_section = section;
    }
  }
  CHECK(dynamic_section != NULL);

  return dynamic_section;
}

// Helper for ResizeSection().  Adjust the .dynamic section for the hole.
template <typename Rel>
void AdjustDynamicSectionForHole(Elf_Scn* dynamic_section,
                                 ELF::Off hole_start,
                                 ssize_t hole_size) {
  Elf_Data* data = GetSectionData(dynamic_section);

  const ELF::Dyn* dynamic_base = reinterpret_cast<ELF::Dyn*>(data->d_buf);
  std::vector<ELF::Dyn> dynamics(
      dynamic_base,
      dynamic_base + data->d_size / sizeof(dynamics[0]));

  for (size_t i = 0; i < dynamics.size(); ++i) {
    ELF::Dyn* dynamic = &dynamics[i];
    const ELF::Sword tag = dynamic->d_tag;

    // DT_RELSZ or DT_RELASZ indicate the overall size of relocations.
    // Only one will be present.  Adjust by hole size.
    if (tag == DT_RELSZ || tag == DT_RELASZ) {
      dynamic->d_un.d_val += hole_size;
      VLOG(1) << "dynamic[" << i << "] " << dynamic->d_tag
              << " d_val adjusted to " << dynamic->d_un.d_val;
    }

    // DT_RELCOUNT or DT_RELACOUNT hold the count of relative relocations.
    // Only one will be present.  Packing reduces it to the alignment
    // padding, if any; unpacking restores it to its former value.  The
    // crazy linker does not use it, but we update it anyway.
    if (tag == DT_RELCOUNT || tag == DT_RELACOUNT) {
      // Cast sizeof to a signed type to avoid the division result being
      // promoted into an unsigned size_t.
      const ssize_t sizeof_rel = static_cast<ssize_t>(sizeof(Rel));
      dynamic->d_un.d_val += hole_size / sizeof_rel;
      VLOG(1) << "dynamic[" << i << "] " << dynamic->d_tag
              << " d_val adjusted to " << dynamic->d_un.d_val;
    }

    // DT_RELENT and DT_RELAENT do not change, but make sure they are what
    // we expect.  Only one will be present.
    if (tag == DT_RELENT || tag == DT_RELAENT) {
      CHECK(dynamic->d_un.d_val == sizeof(Rel));
    }
  }

  void* section_data = &dynamics[0];
  size_t bytes = dynamics.size() * sizeof(dynamics[0]);
  RewriteSectionData(dynamic_section, section_data, bytes);
}

// Resize a section.  If the new size is larger than the current size, open
// up a hole by increasing file offsets that come after the hole.  If smaller
// than the current size, remove the hole by decreasing those offsets.
template <typename Rel>
void ResizeSection(Elf* elf, Elf_Scn* section, size_t new_size) {
  ELF::Shdr* section_header = ELF::getshdr(section);
  if (section_header->sh_size == new_size)
    return;

  // Note if we are resizing the real dyn relocations.
  size_t string_index;
  elf_getshdrstrndx(elf, &string_index);
  const std::string section_name =
      elf_strptr(elf, string_index, section_header->sh_name);
  const bool is_relocations_resize =
      (section_name == ".rel.dyn" || section_name == ".rela.dyn");

  // Require that the section size and the data size are the same.  True
  // in practice for all sections we resize when packing or unpacking.
  Elf_Data* data = GetSectionData(section);
  CHECK(data->d_off == 0 && data->d_size == section_header->sh_size);

  // Require that the section is not zero-length (that is, has allocated
  // data that we can validly expand).
  CHECK(data->d_size && data->d_buf);

  const ELF::Off hole_start = section_header->sh_offset;
  const ssize_t hole_size = new_size - data->d_size;

  VLOG_IF(1, (hole_size > 0)) << "expand section size = " << data->d_size;
  VLOG_IF(1, (hole_size < 0)) << "shrink section size = " << data->d_size;

  // Resize the data and the section header.
  data->d_size += hole_size;
  section_header->sh_size += hole_size;

  // Add the hole size to all offsets in the ELF file that are after the
  // start of the hole.  If the hole size is positive we are expanding the
  // section to create a new hole; if negative, we are closing up a hole.

  // Start with the main ELF header.
  ELF::Ehdr* elf_header = ELF::getehdr(elf);
  AdjustElfHeaderForHole(elf_header, hole_start, hole_size);

  // Adjust all section headers.
  AdjustSectionHeadersForHole(elf, hole_start, hole_size);

  // If resizing the dynamic relocations, rewrite the program headers to
  // either split or coalesce segments, and adjust dynamic entries to match.
  if (is_relocations_resize) {
    RewriteProgramHeadersForHole(elf, hole_start, hole_size);

    Elf_Scn* dynamic_section = GetDynamicSection(elf);
    AdjustDynamicSectionForHole<Rel>(dynamic_section, hole_start, hole_size);
  }
}

// Find the first slot in a dynamics array with the given tag.  The array
// always ends with a free (unused) element, and which we exclude from the
// search.  Returns dynamics->size() if not found.
size_t FindDynamicEntry(ELF::Sword tag,
                        std::vector<ELF::Dyn>* dynamics) {
  // Loop until the penultimate entry.  We exclude the end sentinel.
  for (size_t i = 0; i < dynamics->size() - 1; ++i) {
    if (dynamics->at(i).d_tag == tag)
      return i;
  }

  // The tag was not found.
  return dynamics->size();
}

// Replace the first free (unused) slot in a dynamics vector with the given
// value.  The vector always ends with a free (unused) element, so the slot
// found cannot be the last one in the vector.
void AddDynamicEntry(const ELF::Dyn& dyn,
                     std::vector<ELF::Dyn>* dynamics) {
  const size_t slot = FindDynamicEntry(DT_NULL, dynamics);
  if (slot == dynamics->size()) {
    LOG(FATAL) << "No spare dynamic array slots found "
               << "(to fix, increase gold's --spare-dynamic-tags value)";
  }

  // Replace this entry with the one supplied.
  dynamics->at(slot) = dyn;
  VLOG(1) << "dynamic[" << slot << "] overwritten with " << dyn.d_tag;
}

// Remove the element in the dynamics vector that matches the given tag with
// unused slot data.  Shuffle the following elements up, and ensure that the
// last is the null sentinel.
void RemoveDynamicEntry(ELF::Sword tag,
                        std::vector<ELF::Dyn>* dynamics) {
  const size_t slot = FindDynamicEntry(tag, dynamics);
  CHECK(slot != dynamics->size());

  // Remove this entry by shuffling up everything that follows.
  for (size_t i = slot; i < dynamics->size() - 1; ++i) {
    dynamics->at(i) = dynamics->at(i + 1);
    VLOG(1) << "dynamic[" << i
            << "] overwritten with dynamic[" << i + 1 << "]";
  }

  // Ensure that the end sentinel is still present.
  CHECK(dynamics->at(dynamics->size() - 1).d_tag == DT_NULL);
}

// Construct a null relocation without addend.
void NullRelocation(ELF::Rel* relocation) {
  relocation->r_offset = 0;
  relocation->r_info = ELF_R_INFO(0, ELF::kNoRelocationCode);
}

// Construct a null relocation with addend.
void NullRelocation(ELF::Rela* relocation) {
  relocation->r_offset = 0;
  relocation->r_info = ELF_R_INFO(0, ELF::kNoRelocationCode);
  relocation->r_addend = 0;
}

// Pad relocations with the given number of null entries.  Generates its
// null entry with the appropriate NullRelocation() invocation.
template <typename Rel>
void PadRelocations(size_t count, std::vector<Rel>* relocations) {
  Rel null_relocation;
  NullRelocation(&null_relocation);
  std::vector<Rel> padding(count, null_relocation);
  relocations->insert(relocations->end(), padding.begin(), padding.end());
}

}  // namespace

// Remove relative entries from dynamic relocations and write as packed
// data into android packed relocations.
bool ElfFile::PackRelocations() {
  // Load the ELF file into libelf.
  if (!Load()) {
    LOG(ERROR) << "Failed to load as ELF";
    return false;
  }

  // Retrieve the current dynamic relocations section data.
  Elf_Data* data = GetSectionData(relocations_section_);

  if (relocations_type_ == REL) {
    // Convert data to a vector of relocations.
    const ELF::Rel* relocations_base = reinterpret_cast<ELF::Rel*>(data->d_buf);
    std::vector<ELF::Rel> relocations(
        relocations_base,
        relocations_base + data->d_size / sizeof(relocations[0]));

    LOG(INFO) << "Relocations   : REL";
    return PackTypedRelocations<ELF::Rel>(relocations);
  }

  if (relocations_type_ == RELA) {
    // Convert data to a vector of relocations with addends.
    const ELF::Rela* relocations_base =
        reinterpret_cast<ELF::Rela*>(data->d_buf);
    std::vector<ELF::Rela> relocations(
        relocations_base,
        relocations_base + data->d_size / sizeof(relocations[0]));

    LOG(INFO) << "Relocations   : RELA";
    return PackTypedRelocations<ELF::Rela>(relocations);
  }

  NOTREACHED();
  return false;
}

// Helper for PackRelocations().  Rel type is one of ELF::Rel or ELF::Rela.
template <typename Rel>
bool ElfFile::PackTypedRelocations(const std::vector<Rel>& relocations) {
  // Filter relocations into those that are relative and others.
  std::vector<Rel> relative_relocations;
  std::vector<Rel> other_relocations;

  for (size_t i = 0; i < relocations.size(); ++i) {
    const Rel& relocation = relocations[i];
    if (ELF_R_TYPE(relocation.r_info) == ELF::kRelativeRelocationCode) {
      CHECK(ELF_R_SYM(relocation.r_info) == 0);
      relative_relocations.push_back(relocation);
    } else {
      other_relocations.push_back(relocation);
    }
  }
  LOG(INFO) << "Relative      : " << relative_relocations.size() << " entries";
  LOG(INFO) << "Other         : " << other_relocations.size() << " entries";
  LOG(INFO) << "Total         : " << relocations.size() << " entries";

  // If no relative relocations then we have nothing packable.  Perhaps
  // the shared object has already been packed?
  if (relative_relocations.empty()) {
    LOG(ERROR) << "No relative relocations found (already packed?)";
    return false;
  }

  // If not padding fully, apply only enough padding to preserve alignment.
  // Otherwise, pad so that we do not shrink the relocations section at all.
  if (!is_padding_relocations_) {
    // Calculate the size of the hole we will close up when we rewrite
    // dynamic relocations.
    ssize_t hole_size =
        relative_relocations.size() * sizeof(relative_relocations[0]);
    const ssize_t unaligned_hole_size = hole_size;

    // Adjust the actual hole size to preserve alignment.  We always adjust
    // by a whole number of NONE-type relocations.
    while (hole_size % kPreserveAlignment)
      hole_size -= sizeof(relative_relocations[0]);
    LOG(INFO) << "Compaction    : " << hole_size << " bytes";

    // Adjusting for alignment may have removed any packing benefit.
    if (hole_size == 0) {
      LOG(INFO) << "Too few relative relocations to pack after alignment";
      return false;
    }

    // Find the padding needed in other_relocations to preserve alignment.
    // Ensure that we never completely empty the real relocations section.
    size_t padding_bytes = unaligned_hole_size - hole_size;
    if (padding_bytes == 0 && other_relocations.size() == 0) {
      do {
        padding_bytes += sizeof(relative_relocations[0]);
      } while (padding_bytes % kPreserveAlignment);
    }
    CHECK(padding_bytes % sizeof(other_relocations[0]) == 0);
    const size_t padding = padding_bytes / sizeof(other_relocations[0]);

    // Padding may have removed any packing benefit.
    if (padding >= relative_relocations.size()) {
      LOG(INFO) << "Too few relative relocations to pack after padding";
      return false;
    }

    // Add null relocations to other_relocations to preserve alignment.
    PadRelocations<Rel>(padding, &other_relocations);
    LOG(INFO) << "Alignment pad : " << padding << " relocations";
  } else {
    // If padding, add NONE-type relocations to other_relocations to make it
    // the same size as the the original relocations we read in.  This makes
    // the ResizeSection() below a no-op.
    const size_t padding = relocations.size() - other_relocations.size();
    PadRelocations<Rel>(padding, &other_relocations);
  }

  // Pack relative relocations.
  const size_t initial_bytes =
      relative_relocations.size() * sizeof(relative_relocations[0]);
  LOG(INFO) << "Unpacked relative: " << initial_bytes << " bytes";
  std::vector<uint8_t> packed;
  RelocationPacker packer;
  packer.PackRelativeRelocations(relative_relocations, &packed);
  const void* packed_data = &packed[0];
  const size_t packed_bytes = packed.size() * sizeof(packed[0]);
  LOG(INFO) << "Packed   relative: " << packed_bytes << " bytes";

  // If we have insufficient relative relocations to form a run then
  // packing fails.
  if (packed.empty()) {
    LOG(INFO) << "Too few relative relocations to pack";
    return false;
  }

  // Run a loopback self-test as a check that packing is lossless.
  std::vector<Rel> unpacked;
  packer.UnpackRelativeRelocations(packed, &unpacked);
  CHECK(unpacked.size() == relative_relocations.size());
  CHECK(!memcmp(&unpacked[0],
                &relative_relocations[0],
                unpacked.size() * sizeof(unpacked[0])));

  // Make sure packing saved some space.
  if (packed_bytes >= initial_bytes) {
    LOG(INFO) << "Packing relative relocations saves no space";
    return false;
  }

  // Rewrite the current dynamic relocations section to be only the ARM
  // non-relative relocations, then shrink it to size.
  const void* section_data = &other_relocations[0];
  const size_t bytes = other_relocations.size() * sizeof(other_relocations[0]);
  ResizeSection<Rel>(elf_, relocations_section_, bytes);
  RewriteSectionData(relocations_section_, section_data, bytes);

  // Rewrite the current packed android relocations section to hold the packed
  // relative relocations.
  ResizeSection<Rel>(elf_, android_relocations_section_, packed_bytes);
  RewriteSectionData(android_relocations_section_, packed_data, packed_bytes);

  // Rewrite .dynamic to include two new tags describing the packed android
  // relocations.
  Elf_Data* data = GetSectionData(dynamic_section_);
  const ELF::Dyn* dynamic_base = reinterpret_cast<ELF::Dyn*>(data->d_buf);
  std::vector<ELF::Dyn> dynamics(
      dynamic_base,
      dynamic_base + data->d_size / sizeof(dynamics[0]));
  // Use two of the spare slots to describe the packed section.
  ELF::Shdr* section_header = ELF::getshdr(android_relocations_section_);
  {
    ELF::Dyn dyn;
    dyn.d_tag = DT_ANDROID_REL_OFFSET;
    dyn.d_un.d_ptr = section_header->sh_offset;
    AddDynamicEntry(dyn, &dynamics);
  }
  {
    ELF::Dyn dyn;
    dyn.d_tag = DT_ANDROID_REL_SIZE;
    dyn.d_un.d_val = section_header->sh_size;
    AddDynamicEntry(dyn, &dynamics);
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
bool ElfFile::UnpackRelocations() {
  // Load the ELF file into libelf.
  if (!Load()) {
    LOG(ERROR) << "Failed to load as ELF";
    return false;
  }

  // Retrieve the current packed android relocations section data.
  Elf_Data* data = GetSectionData(android_relocations_section_);

  // Convert data to a vector of bytes.
  const uint8_t* packed_base = reinterpret_cast<uint8_t*>(data->d_buf);
  std::vector<uint8_t> packed(
      packed_base,
      packed_base + data->d_size / sizeof(packed[0]));

  if (packed.size() > 3 &&
      packed[0] == 'A' &&
      packed[1] == 'P' &&
      packed[2] == 'R' &&
      packed[3] == '1') {
    // Signature is APR1, unpack relocations.
    CHECK(relocations_type_ == REL);
    LOG(INFO) << "Relocations   : REL";
    return UnpackTypedRelocations<ELF::Rel>(packed);
  }

  if (packed.size() > 3 &&
      packed[0] == 'A' &&
      packed[1] == 'P' &&
      packed[2] == 'A' &&
      packed[3] == '1') {
    // Signature is APA1, unpack relocations with addends.
    CHECK(relocations_type_ == RELA);
    LOG(INFO) << "Relocations   : RELA";
    return UnpackTypedRelocations<ELF::Rela>(packed);
  }

  LOG(ERROR) << "Packed relative relocations not found (not packed?)";
  return false;
}

// Helper for UnpackRelocations().  Rel type is one of ELF::Rel or ELF::Rela.
template <typename Rel>
bool ElfFile::UnpackTypedRelocations(const std::vector<uint8_t>& packed) {
  // Unpack the data to re-materialize the relative relocations.
  const size_t packed_bytes = packed.size() * sizeof(packed[0]);
  LOG(INFO) << "Packed   relative: " << packed_bytes << " bytes";
  std::vector<Rel> relative_relocations;
  RelocationPacker packer;
  packer.UnpackRelativeRelocations(packed, &relative_relocations);
  const size_t unpacked_bytes =
      relative_relocations.size() * sizeof(relative_relocations[0]);
  LOG(INFO) << "Unpacked relative: " << unpacked_bytes << " bytes";

  // Retrieve the current dynamic relocations section data.
  Elf_Data* data = GetSectionData(relocations_section_);

  // Interpret data as relocations.
  const Rel* relocations_base = reinterpret_cast<Rel*>(data->d_buf);
  std::vector<Rel> relocations(
      relocations_base,
      relocations_base + data->d_size / sizeof(relocations[0]));

  std::vector<Rel> other_relocations;
  size_t padding = 0;

  // Filter relocations to locate any that are NONE-type.  These will occur
  // if padding was turned on for packing.
  for (size_t i = 0; i < relocations.size(); ++i) {
    const Rel& relocation = relocations[i];
    if (ELF_R_TYPE(relocation.r_info) != ELF::kNoRelocationCode) {
      other_relocations.push_back(relocation);
    } else {
      ++padding;
    }
  }
  LOG(INFO) << "Relative      : " << relative_relocations.size() << " entries";
  LOG(INFO) << "Other         : " << other_relocations.size() << " entries";

  // If we found the same number of null relocation entries in the dynamic
  // relocations section as we hold as unpacked relative relocations, then
  // this is a padded file.
  const bool is_padded = padding == relative_relocations.size();

  // Unless padded, report by how much we expand the file.
  if (!is_padded) {
    // Calculate the size of the hole we will open up when we rewrite
    // dynamic relocations.
    ssize_t hole_size =
        relative_relocations.size() * sizeof(relative_relocations[0]);

    // Adjust the hole size for the padding added to preserve alignment.
    hole_size -= padding * sizeof(other_relocations[0]);
    LOG(INFO) << "Expansion     : " << hole_size << " bytes";
  }

  // Rewrite the current dynamic relocations section to be the relative
  // relocations followed by other relocations.  This is the usual order in
  // which we find them after linking, so this action will normally put the
  // entire dynamic relocations section back to its pre-split-and-packed state.
  relocations.assign(relative_relocations.begin(), relative_relocations.end());
  relocations.insert(relocations.end(),
                     other_relocations.begin(), other_relocations.end());
  const void* section_data = &relocations[0];
  const size_t bytes = relocations.size() * sizeof(relocations[0]);
  LOG(INFO) << "Total         : " << relocations.size() << " entries";
  ResizeSection<Rel>(elf_, relocations_section_, bytes);
  RewriteSectionData(relocations_section_, section_data, bytes);

  // Nearly empty the current packed android relocations section.  Leaves a
  // four-byte stub so that some data remains allocated to the section.
  // This is a convenience which allows us to re-pack this file again without
  // having to remove the section and then add a new small one with objcopy.
  // The way we resize sections relies on there being some data in a section.
  ResizeSection<Rel>(
      elf_, android_relocations_section_, sizeof(kStubIdentifier));
  RewriteSectionData(
      android_relocations_section_, &kStubIdentifier, sizeof(kStubIdentifier));

  // Rewrite .dynamic to remove two tags describing packed android relocations.
  data = GetSectionData(dynamic_section_);
  const ELF::Dyn* dynamic_base = reinterpret_cast<ELF::Dyn*>(data->d_buf);
  std::vector<ELF::Dyn> dynamics(
      dynamic_base,
      dynamic_base + data->d_size / sizeof(dynamics[0]));
  RemoveDynamicEntry(DT_ANDROID_REL_OFFSET, &dynamics);
  RemoveDynamicEntry(DT_ANDROID_REL_SIZE, &dynamics);
  const void* dynamics_data = &dynamics[0];
  const size_t dynamics_bytes = dynamics.size() * sizeof(dynamics[0]);
  RewriteSectionData(dynamic_section_, dynamics_data, dynamics_bytes);

  Flush();
  return true;
}

// Flush rewritten shared object file data.
void ElfFile::Flush() {
  // Flag all ELF data held in memory as needing to be written back to the
  // file, and tell libelf that we have controlled the file layout.
  elf_flagelf(elf_, ELF_C_SET, ELF_F_DIRTY);
  elf_flagelf(elf_, ELF_C_SET, ELF_F_LAYOUT);

  // Write ELF data back to disk.
  const off_t file_bytes = elf_update(elf_, ELF_C_WRITE);
  CHECK(file_bytes > 0);
  VLOG(1) << "elf_update returned: " << file_bytes;

  // Clean up libelf, and truncate the output file to the number of bytes
  // written by elf_update().
  elf_end(elf_);
  elf_ = NULL;
  const int truncate = ftruncate(fd_, file_bytes);
  CHECK(truncate == 0);
}

}  // namespace relocation_packer
