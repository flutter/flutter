Introduction:
-------------

Relative relocations are the bulk of dynamic relocations (the .rel.dyn
or .rela.dyn sections) in libchrome.<version>.so.  The ELF standard
representation of them is wasteful.

Packing uses a combination of run length encoding, delta encoding, and LEB128
encoding to store them more efficiently.  Packed relocations are placed in
a new .android.rel.dyn or .android.rela.dyn section.  Packing reduces
the footprint of libchrome.<version>.so in the filesystem, in APK downloads,
and in memory when loaded on the device.

A packed libchrome.<version>.so is designed so that it can be loaded directly
on Android, but requires the explicit support of a crazy linker that has been
extended to understand packed relocations.  Packed relocations are currently
only supported on ARM.

A packed libchrome.<version>.so cannot currently be used with the standard
Android runtime linker.

See src/*.h for design and implementation notes.


Notes:
------

Packing does not adjust debug data.  An unstripped libchrome.<version>.so
can be packed and will run, but may no longer be useful for debugging.

Unpacking on the device requires the explicit support of an extended crazy
linker.  Adds the following new .dynamic tags, used by the crazy linker to
find the packed .android.rel.dyn or .android.rela.dyn section data:

  DT_ANDROID_REL_OFFSET = DT_LOOS    (Operating System specific: 0x6000000d)
    - The offset of packed relocation data in libchrome.<version>.so
  DT_ANDROID_REL_SIZE = DT_LOOS + 1  (Operating System Specific: 0x6000000e)
    - The size of packed relocation data in bytes

32 bit ARM libraries use relocations without addends.  64 bit ARM libraries
use relocations with addends.  The packing strategy necessarily differs for
the two relocation types.

Where libchrome.<version>.so contains relocations without addends, the format
of .android.rel.dyn data is:

  "APR1" identifier
  N: the number of count-delta pairs in the encoding
  A: the initial offset
  N * C,D: N count-delta pairs

Where libchrome.<version>.so contains relocations with addends, the format
of .android.rela.dyn data is:

  "APA1" identifier
  N: the number of addr-addend delta pairs in the encoding
  N * A,V: N addr-addend delta pairs

All numbers in the encoding stream are stored as LEB128 values.  For details
see http://en.wikipedia.org/wiki/LEB128.

The streaming unpacking algorithm for 32 bit ARM is:

  skip over "APR1"
  pairs, addr = next leb128 value, next leb128 value
  emit R_ARM_RELATIVE relocation with r_offset = addr
  while pairs:
    count, delta = next leb128 value, next leb128 value
    while count:
      addr += delta
      emit R_ARM_RELATIVE relocation with r_offset = addr
      count--
    pairs--

The streaming unpacking algorithm for 64 bit ARM is:

  skip over "APA1"
  pairs = next signed leb128 value
  addr, addend = 0, 0
  while pairs:
    addr += next signed leb128 value
    addend += next signed leb128 value
    emit R_AARCH64_RELATIVE relocation with r_offset = addr, r_addend = addend
    pairs--


Usage instructions:
-------------------

To pack relocations, add an empty .android.rel.dyn or .android.rela.dyn and
then run the tool:

    echo -n 'NULL' >/tmp/small
    if file libchrome.<version>.so | grep -q 'ELF 32'; then
      arm-linux-androideabi-objcopy
          --add-section .android.rel.dyn=/tmp/small
          libchrome.<version>.so libchrome.<version>.so.packed
    else
      aarch64-linux-android-objcopy
          --add-section .android.rela.dyn=/tmp/small
          libchrome.<version>.so libchrome.<version>.so.packed
    fi
    rm /tmp/small
    relocation_packer libchrome.<version>.so.packed

To unpack and restore the shared library to its original state:

    cp libchrome.<version>.so.packed unpackable
    relocation_packer -u unpackable
    if file libchrome.<version>.so | grep -q 'ELF 32'; then
      arm-linux-androideabi-objcopy \
          --remove-section=.android.rel.dyn unpackable libchrome.<version>.so
    else
      aarch64-linux-android-objcopy \
          --remove-section=.android.rela.dyn unpackable libchrome.<version>.so
    endif
    rm unpackable


Bugs & TODOs:
-------------

Requires two free slots in the .dynamic section.  Uses these to add data that
tells the crazy linker where to find the packed relocation data.  Fails
if insufficient free slots exist (use gold --spare-dynamic-slots to increase
the allocation).

Requires libelf 0.158 or later.  Earlier libelf releases may be buggy in
ways that prevent the packer from working correctly.


Testing:
--------

Unittests run under gtest, on the host system.
