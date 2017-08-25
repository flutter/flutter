# Hyb (hyphenation pattern binary) file format

The hyb file format is how hyphenation patterns are stored in the system image.

Goals include:

* Concise (system image space is at a premium)
* Usable when mmap'ed, so it doesn't take significant physical RAM
* Fast to compute
* Simple

It is _not_ intended as an interchange format, so there is no attempt to make the format
extensible or facilitate backward and forward compatibility.

Further, at some point we will probably pack patterns for multiple languages into a single
physical file, to reduce number of open mmap'ed files. This document doesn't cover that.

## Theoretical basis

At heart, the file contains packed tries with suffix compression, actually quite similar
to the implementation in TeX.

The file contains three sections. The first section represents the "alphabet," including
case folding. It is effectively a map from Unicode code point to a small integer.

The second section contains the trie in packed form. It is an array of 3-tuples, packed
into a 32 bit integer. Each (suffix-compressed) trie node has a unique index within this
array, and the pattern field in the tuple is the pattern for that node. Further, each edge
in the trie has an entry in the array, and the character and link fields in the tuple
represent the label and destination of the edge. The packing strategy is as in
[Word Hy-phen-a-tion by Com-put-er](http://www.tug.org/docs/liang/liang-thesis.pdf) by
Franklin Mark Liang.

The trie representation is similar but not identical to the "double-array trie".
The fundamental operation of lookup of the edge from `s` to `t` with label `c` is
to compare `c == character[s + c]`, and if so, `t = link[s + c]`.

The third section contains the pattern strings. This section is in two parts: first,
an array with a 3-tuple for each pattern (length, number of trailing 0's, and offset
into the string pool); and second, the string pool. Each pattern is encoded as a byte
(packing 2 per byte would be possible but the space savings would not be signficant).

As much as possible of the file is represented as 32 bit integers, as that is especially
efficent to access. All are little-endian (this could be revised if the code ever needs
to be ported to big-endian systems).

## Header

```
uint32_t magic == 0x62ad7968
uint32_t version = 0
uint32_t alphabet_offset (in bytes)
uint32_t trie_offset (in bytes)
uint32_t pattern_offset (in bytes)
uint32_t file_size (in bytes)
```

Offsets are from the front of the file, and in bytes.

## Alphabet

The alphabet table comes in two versions. The first is well suited to dense Unicode
ranges and is limited to 256. The second is more general, but lookups will be slower.

### Alphabet, direct version

```
uint32_t version = 0
uint32_t min_codepoint
uint32_t max_codepoint (exclusive)
uint8_t[] data
```

The size of the data array is max_codepoint - min_codepoint. 0 represents an unmapped
character. Note that, in the current implementation, automatic hyphenation is disabled
for any word containing an unmapped character.

In general, pad bytes follow this table, aligning the next table to a 4-byte boundary.

### Alphabet, general version

```
uint32_t version = 1
uint32_t n_entries
uint32_t[n_entries] data
```

Each element in the data table is `(codepoint << 11) | value`. Note that this is
restricted to 11 bits (2048 possible values). The largest known current value is 483
(for Sanskrit).

The entries are sorted by codepoint, to facilitate binary search. Another reasonable
implementation for consumers of the data would be to build a hash table at load time.

## Trie

```
uint32_t version = 0
uint32_t char_mask
uint32_t link_shift
uint32_t link_mask
uint32_t pattern_shift
uint32_t n_entries
uint32_t[n_entries] data
```

Each element in the data table is `(pattern << pattern_shift) | (link << link_shift) | char`.

All known pattern tables fit in 32 bits total. If this is exceeded, there is a fairly
straightforward tweak, where each node occupies a slot by itself (as opposed to sharing
it with edge slots), which would require very minimal changes to the implementation (TODO
present in more detail).

## Pattern

```
uint32_t version = 0
uint32_t n_entries
uint32_t pattern_offset (in bytes)
uint32_t pattern_size (in bytes)
uint32_t[n_entries] data
uint8_t[] pattern_buf
```

Each element in data table is `(len << 26) | (shift << 20) | offset`, where an offset of 0
points to the first byte of pattern_buf.

Generally pattern_offset is `16 + 4 * n_entries`.

For example, 'a4m5ato' would be represented as `[4, 5, 0, 0, 0]`, then len = 2, shift = 3, and
offset points to [4, 5] in the pattern buffer.

Future extension: additional data representing nonstandard hyphenation. See
[Automatic non-standard hyphenation in OpenOffice.org](https://www.tug.org/TUGboat/tb27-1/tb86nemeth.pdf)
for more information about that issue.
