#!/usr/bin/env python

# Copyright (C) 2015 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Convert hyphen files in standard TeX format (a trio of pat, chr, and hyp)
into binary format. See doc/hyb_file_format.md for more information.

Usage: mk_hyb_file.py [-v] hyph-foo.pat.txt hyph-foo.hyb

Optional -v parameter turns on verbose debugging.

"""

from __future__ import print_function

import io
import sys
import struct
import math
import getopt


VERBOSE = False

# U+00DF is LATIN SMALL LETTER SHARP S
# U+1E9E is LATIN CAPITAL LETTER SHARP S
SHARP_S_TO_DOUBLE = u'\u00dfSS'
SHARP_S_TO_CAPITAL = u'\u00df\u1e9e'

if sys.version_info[0] >= 3:
    def unichr(x):
        return chr(x)


# number of bits required to represent numbers up to n inclusive
def num_bits(n):
    return 1 + int(math.log(n, 2)) if n > 0 else 0


class Node:

    def __init__(self):
        self.succ = {}
        self.res = None
        self.fsm_pat = None
        self.fail = None


# List of free slots, implemented as doubly linked list
class Freelist:

    def __init__(self):
        self.first = None
        self.last = None
        self.pred = []
        self.succ = []

    def grow(self):
        this = len(self.pred)
        self.pred.append(self.last)
        self.succ.append(None)
        if self.last is None:
            self.first = this
        else:
            self.succ[self.last] = this
        self.last = this

    def next(self, cursor):
        if cursor == 0:
            cursor = self.first
        if cursor is None:
            self.grow()
            result = self.last
        else:
            result = cursor
        return result, self.succ[result]

    def is_free(self, ix):
        while ix >= len(self.pred):
            self.grow()
        return self.pred[ix] != -1

    def use(self, ix):
        if self.pred[ix] is None:
            self.first = self.succ[ix]
        else:
            self.succ[self.pred[ix]] = self.succ[ix]
        if self.succ[ix] is None:
            self.last = self.pred[ix]
        else:
            self.pred[self.succ[ix]] = self.pred[ix]
        if self.pred[ix] == -1:
            assert self.pred[ix] != -1, 'double free!'
        self.pred[ix] = -1


def combine(a, b):
    if a is None: return b
    if b is None: return a
    if len(b) < len(a): a, b = b, a
    res = b[:len(b) - len(a)]
    for i in range(len(a)):
        res.append(max(a[i], b[i + len(b) - len(a)]))
    return res


def trim(pattern):
    for ix in range(len(pattern)):
        if pattern[ix] != 0:
            return pattern[ix:]


def pat_to_binary(pattern):
    return b''.join(struct.pack('B', x) for x in pattern)


class Hyph:

    def __init__(self):
        self.root = Node()
        self.root.str = '<root>'
        self.node_list = [self.root]

    # Add a pattern (word fragment with numeric codes, such as ".ad4der")
    def add_pat(self, pat):
        lastWasLetter = False
        haveSeenNumber = False
        result = []
        word = ''
        for c in pat:
            if c.isdigit():
                result.append(int(c))
                lastWasLetter = False
                haveSeenNumber = True
            else:
                word += c
                if lastWasLetter and haveSeenNumber:
                    result.append(0)
                lastWasLetter = True
        if lastWasLetter:
            result.append(0)

        self.add_word_res(word, result)

    # Add an exception (word with hyphens, such as "ta-ble")
    def add_exception(self, hyph_word):
        res = []
        word = ['.']
        need_10 = False
        for c in hyph_word:
            if c == '-':
                res.append(11)
                need_10 = False
            else:
                if need_10:
                    res.append(10)
                word.append(c)
                need_10 = True
        word.append('.')
        res.append(0)
        res.append(0)
        if VERBOSE:
            print(word, res)
        self.add_word_res(''.join(word), res)

    def add_word_res(self, word, result):
        if VERBOSE:
            print(word, result)

        t = self.root
        s = ''
        for c in word:
            s += c
            if c not in t.succ:
                new_node = Node()
                new_node.str = s
                self.node_list.append(new_node)
                t.succ[c] = new_node
            t = t.succ[c]
        t.res = result

    def pack(self, node_list, ch_map, use_node=False):
        size = 0
        self.node_map = {}
        nodes = Freelist()
        edges = Freelist()
        edge_start = 1 if use_node else 0
        for node in node_list:
            succ = sorted([ch_map[c] + edge_start for c in node.succ.keys()])
            if len(succ):
                cursor = 0
                while True:
                    edge_ix, cursor = edges.next(cursor)
                    ix = edge_ix - succ[0]
                    if (ix >= 0 and nodes.is_free(ix) and
                            all(edges.is_free(ix + s) for s in succ) and
                            ((not use_node) or edges.is_free(ix))):
                        break
            elif use_node:
                ix, _ = edges.next(0)
                nodes.is_free(ix)  # actually don't need nodes at all when use_node,
                # but keep it happy
            else:
                ix, _ = nodes.next(0)
            node.ix = ix
            self.node_map[ix] = node
            nodes.use(ix)
            size = max(size, ix)
            if use_node:
                edges.use(ix)
            for s in succ:
                edges.use(ix + s)
        size += max(ch_map.values()) + 1
        return size

    # return list of nodes in bfs order
    def bfs(self, ch_map):
        result = [self.root]
        ix = 0
        while ix < len(result):
            node = result[ix]
            node.bfs_ix = ix
            mapped = {}
            for c, next in node.succ.items():
                assert ch_map[c] not in mapped, 'duplicate edge ' + node.str + ' ' + hex(ord(c))
                mapped[ch_map[c]] = next
            for i in sorted(mapped.keys()):
                result.append(mapped[i])
            ix += 1
        self.bfs_order = result
        return result

    # suffix compression - convert the trie into an acyclic digraph, merging nodes when
    # the subtries are identical
    def dedup(self):
        uniques = []
        dupmap = {}
        dedup_ix = [0] * len(self.bfs_order)
        for ix in reversed(range(len(self.bfs_order))):
            # construct string representation of node
            node = self.bfs_order[ix]
            if node.res is None:
                s = ''
            else:
                s = ''.join(str(c) for c in node.res)
            for c in sorted(node.succ.keys()):
                succ = node.succ[c]
                s += ' ' + c + str(dedup_ix[succ.bfs_ix])
            if s in dupmap:
                dedup_ix[ix] = dupmap[s]
            else:
                uniques.append(node)
                dedup_ix[ix] = ix
            dupmap[s] = dedup_ix[ix]
        uniques.reverse()
        print(len(uniques), 'unique nodes,', len(self.bfs_order), 'total')
        return dedup_ix, uniques


# load the ".pat" file, which contains patterns such as a1b2c3
def load(fn):
    hyph = Hyph()
    with io.open(fn, encoding='UTF-8') as f:
        for l in f:
            pat = l.strip()
            hyph.add_pat(pat)
    return hyph


# load the ".chr" file, which contains the alphabet and case pairs, eg "aA", "bB" etc.
def load_chr(fn):
    ch_map = {'.': 0}
    with io.open(fn, encoding='UTF-8') as f:
        for i, l in enumerate(f):
            l = l.strip()
            if len(l) > 2:
                if l == SHARP_S_TO_DOUBLE:
                    # replace with lowercasing from capital letter sharp s
                    l = SHARP_S_TO_CAPITAL
                else:
                    # lowercase maps to multi-character uppercase sequence, ignore uppercase for now
                    l = l[:1]
            else:
                assert len(l) == 2, 'expected 2 chars in chr'
            for c in l:
                ch_map[c] = i + 1
    return ch_map


# load exceptions with explicit hyphens
def load_hyp(hyph, fn):
    with io.open(fn, encoding='UTF-8') as f:
        for l in f:
            hyph.add_exception(l.strip())


def generate_header(alphabet, trie, pattern):
    alphabet_off = 6 * 4
    trie_off = alphabet_off + len(alphabet)
    pattern_off = trie_off + len(trie)
    file_size = pattern_off + len(pattern)
    data = [0x62ad7968, 0, alphabet_off, trie_off, pattern_off, file_size]
    return struct.pack('<6I', *data)


def generate_alphabet(ch_map):
    ch_map = ch_map.copy()
    del ch_map['.']
    min_ch = ord(min(ch_map))
    max_ch = ord(max(ch_map))
    if max_ch - min_ch < 1024 and max(ch_map.values()) < 256:
        # generate format 0
        data = [0] * (max_ch - min_ch + 1)
        for c, val in ch_map.items():
            data[ord(c) - min_ch] = val
        result = [struct.pack('<3I', 0, min_ch, max_ch + 1)]
        for b in data:
            result.append(struct.pack('<B', b))
    else:
        # generate format 1
        assert max(ch_map.values()) < 2048, 'max number of unique characters exceeded'
        result = [struct.pack('<2I', 1, len(ch_map))]
        for c, val in sorted(ch_map.items()):
            data = (ord(c) << 11) | val
            result.append(struct.pack('<I', data))
    binary = b''.join(result)
    if len(binary) % 4 != 0:
        binary += b'\x00' * (4 - len(binary) % 4)
    return binary


# assumes hyph structure has been packed, ie node.ix values have been set
def generate_trie(hyph, ch_map, n_trie, dedup_ix, dedup_nodes, patmap):
    ch_array = [0] * n_trie
    link_array = [0] * n_trie
    pat_array = [0] * n_trie
    link_shift = num_bits(max(ch_map.values()))
    char_mask = (1 << link_shift) - 1
    pattern_shift = link_shift + num_bits(n_trie - 1)
    link_mask = (1 << pattern_shift) - (1 << link_shift)
    result = [struct.pack('<6I', 0, char_mask, link_shift, link_mask, pattern_shift, n_trie)]

    for node in dedup_nodes:
        ix = node.ix
        if node.res is not None:
            pat_array[ix] = patmap[pat_to_binary(node.res)]
        for c, next in node.succ.items():
            c_num = ch_map[c]
            link_ix = ix + c_num
            ch_array[link_ix] = c_num
            if dedup_ix is None:
                dedup_next = next
            else:
                dedup_next = hyph.bfs_order[dedup_ix[next.bfs_ix]]
            link_array[link_ix] = dedup_next.ix

    for i in range(n_trie):
        #print((pat_array[i], link_array[i], ch_array[i]))
        packed = (pat_array[i] << pattern_shift) | (link_array[i] << link_shift) | ch_array[i]
        result.append(struct.pack('<I', packed))
    return b''.join(result)


def generate_pattern(pats):
    pat_array = [0]
    patmap = {b'': 0}

    raw_pat_array = []
    raw_pat_size = 0
    raw_patmap = {}

    for pat in pats:
        if pat is None:
            continue
        pat_str = pat_to_binary(pat)
        if pat_str not in patmap:
            shift = 0
            while shift < len(pat) and pat[len(pat) - shift - 1] == 0:
                shift += 1
            rawpat = pat_str[:len(pat) - shift]
            if rawpat not in raw_patmap:
                raw_patmap[rawpat] = raw_pat_size
                raw_pat_array.append(rawpat)
                raw_pat_size += len(rawpat)
            data = (len(rawpat) << 26) | (shift << 20) | raw_patmap[rawpat]
            patmap[pat_str] = len(pat_array)
            pat_array.append(data)
    data = [0, len(pat_array), 16 + 4 * len(pat_array), raw_pat_size]
    result = [struct.pack('<4I', *data)]
    for x in pat_array:
        result.append(struct.pack('<I', x))
    result.extend(raw_pat_array)
    return patmap, b''.join(result)


def generate_hyb_file(hyph, ch_map, hyb_fn):
    bfs = hyph.bfs(ch_map)
    dedup_ix, dedup_nodes = hyph.dedup()
    n_trie = hyph.pack(dedup_nodes, ch_map)
    alphabet = generate_alphabet(ch_map)
    patmap, pattern = generate_pattern([n.res for n in hyph.node_list])
    trie = generate_trie(hyph, ch_map, n_trie, dedup_ix, dedup_nodes, patmap)
    header = generate_header(alphabet, trie, pattern)

    with open(hyb_fn, 'wb') as f:
        f.write(header)
        f.write(alphabet)
        f.write(trie)
        f.write(pattern)


# Verify that the file contains the same lines as the lines argument, in arbitrary order
def verify_file_sorted(lines, fn):
    file_lines = [l.strip() for l in io.open(fn, encoding='UTF-8')]
    line_set = set(lines)
    file_set = set(file_lines)
    if SHARP_S_TO_DOUBLE in file_set:
        # ignore difference of double capital letter s and capital letter sharp s
        file_set.symmetric_difference_update([SHARP_S_TO_DOUBLE, SHARP_S_TO_CAPITAL])
    if line_set == file_set:
        return True
    for line in line_set - file_set:
        print(repr(line) + ' in reconstruction, not in file')
    for line in file_set - line_set:
        print(repr(line) + ' in file, not in reconstruction')
    return False


def map_to_chr(alphabet_map):
    result = []
    ch_map = {}
    for val in alphabet_map.values():
        chs = [ch for ch in alphabet_map if alphabet_map[ch] == val]
        # non-cased characters (like Ethopic) are in both, matching chr file
        lowercase = [ch for ch in chs if not ch.isupper()]
        uppercase = [ch for ch in chs if not ch.islower()]
        # print(val, `lowercase`, `uppercase`)
        assert len(lowercase) == 1, 'expected 1 lowercase character'
        assert 0 <= len(uppercase) <= 1, 'expected 0 or 1 uppercase character'
        ch_map[val] = lowercase[0]
        result.append(''.join(lowercase + uppercase))
    ch_map[0] = '.'
    return (ch_map, result)


def get_pattern(pattern_data, ix):
    pattern_offset = struct.unpack('<I', pattern_data[8:12])[0]
    entry = struct.unpack('<I', pattern_data[16 + ix * 4: 16 + ix * 4 + 4])[0]
    pat_len = entry >> 26
    pat_shift = (entry >> 20) & 0x1f
    offset = pattern_offset + (entry & 0xfffff)
    return pattern_data[offset: offset + pat_len] + b'\0' * pat_shift


def traverse_trie(ix, s, trie_data, ch_map, pattern_data, patterns, exceptions):
    (char_mask, link_shift, link_mask, pattern_shift) = struct.unpack('<4I', trie_data[4:20])
    node_entry = struct.unpack('<I', trie_data[24 + ix * 4: 24 + ix * 4 + 4])[0]
    pattern = node_entry >> pattern_shift
    if pattern:
        result = []
        is_exception = False
        pat = get_pattern(pattern_data, pattern)
        for i in range(len(s) + 1):
            pat_off = i - 1 + len(pat) - len(s)
            if pat_off < 0:
                code = 0
            else:
                code = struct.unpack('B', pat[pat_off : pat_off + 1])[0]
            if 1 <= code <= 9:
                result.append('%d' % code)
            elif code == 10:
                is_exception = True
            elif code == 11:
                result.append('-')
                is_exception = True
            else:
                assert code == 0, 'unexpected code'
            if i < len(s):
                result.append(s[i])
        pat_str = ''.join(result)
        #print(`pat_str`, `pat`)
        if is_exception:
            assert pat_str[0] == '.', "expected leading '.'"
            assert pat_str[-1] == '.', "expected trailing '.'"
            exceptions.append(pat_str[1:-1])  # strip leading and trailing '.'
        else:
            patterns.append(pat_str)
    for ch in ch_map:
        edge_entry = struct.unpack('<I', trie_data[24 + (ix + ch) * 4: 24 + (ix + ch) * 4 + 4])[0]
        link = (edge_entry & link_mask) >> link_shift
        if link != 0 and ch == (edge_entry & char_mask):
            sch = s + ch_map[ch]
            traverse_trie(link, sch, trie_data, ch_map, pattern_data, patterns, exceptions)


# Verify the generated binary file by reconstructing the textual representations
# from the binary hyb file, then checking that they're identical (mod the order of
# lines within the file, which is irrelevant). This function makes assumptions that
# are stronger than absolutely necessary (in particular, that the patterns are in
# lowercase as defined by python islower).
def verify_hyb_file(hyb_fn, pat_fn, chr_fn, hyp_fn):
    with open(hyb_fn, 'rb') as f:
        hyb_data = f.read()
    header = hyb_data[0: 6 * 4]
    (magic, version, alphabet_off, trie_off, pattern_off, file_size) = struct.unpack('<6I', header)
    alphabet_data = hyb_data[alphabet_off:trie_off]
    trie_data = hyb_data[trie_off:pattern_off]
    pattern_data = hyb_data[pattern_off:file_size]

    # reconstruct alphabet table
    alphabet_version = struct.unpack('<I', alphabet_data[:4])[0]
    alphabet_map = {}
    if alphabet_version == 0:
        (min_ch, max_ch) = struct.unpack('<2I', alphabet_data[4:12])
        for ch in range(min_ch, max_ch):
            offset = 12 + ch - min_ch
            b = struct.unpack('B', alphabet_data[offset : offset + 1])[0]
            if b != 0:
                alphabet_map[unichr(ch)] = b
    else:
        assert alphabet_version == 1
        n_entries = struct.unpack('<I', alphabet_data[4:8])[0]
        for i in range(n_entries):
            entry = struct.unpack('<I', alphabet_data[8 + 4 * i: 8 + 4 * i + 4])[0]
            alphabet_map[unichr(entry >> 11)] = entry & 0x7ff

    ch_map, reconstructed_chr = map_to_chr(alphabet_map)

    # EXCEPTION for Armenian (hy), we don't really deal with the uppercase form of U+0587
    if u'\u0587' in reconstructed_chr:
        reconstructed_chr.remove(u'\u0587')
        reconstructed_chr.append(u'\u0587\u0535\u0552')

    assert verify_file_sorted(reconstructed_chr, chr_fn), 'alphabet table not verified'

    # reconstruct trie
    patterns = []
    exceptions = []
    traverse_trie(0, '', trie_data, ch_map, pattern_data, patterns, exceptions)

    # EXCEPTION for Bulgarian (bg), which contains an ineffectual line of <0, U+044C, 0>
    if u'\u044c' in patterns:
        patterns.remove(u'\u044c')
        patterns.append(u'0\u044c0')

    assert verify_file_sorted(patterns, pat_fn), 'pattern table not verified'
    assert verify_file_sorted(exceptions, hyp_fn), 'exception table not verified'


def main():
    global VERBOSE
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'v')
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(1)
    for o, _ in opts:
        if o == '-v':
            VERBOSE = True
    pat_fn, out_fn = args
    hyph = load(pat_fn)
    if pat_fn.endswith('.pat.txt'):
        chr_fn = pat_fn[:-8] + '.chr.txt'
        ch_map = load_chr(chr_fn)
        hyp_fn = pat_fn[:-8] + '.hyp.txt'
        load_hyp(hyph, hyp_fn)
        generate_hyb_file(hyph, ch_map, out_fn)
        verify_hyb_file(out_fn, pat_fn, chr_fn, hyp_fn)

if __name__ == '__main__':
    main()
