#!/usr/bin/env python
# Copyright (C) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from itertools import groupby, islice
import sys

import in_generator
import template_expander

PARAMETER_NAME = 'data'


def _trie(tags, index):
    """Make a trie from list of tags, starting at index.

    Resulting trie is partly space-optimized (semi-radix tree): once have only
    one string left, compact the entire branch to one leaf node.
    However, does not compact branch nodes with a single child. (FIXME)

    Returns:
        (char, subtrie, tag, conditions): (char, trie, str, list)
            code generation differs between branch nodes and leaf nodes,
            hence need different data for each.

    Arguments:
        tags: sorted list
            (sorted needed by groupby, list needed by len)
        index: index at which to branch
            (assumes prior to this index strings have a common prefix)
    """
    def trie_node(char, subtags_iter):
        # Pass in |char| so we can include in same tuple without unpacking
        subtags = list(subtags_iter)  # need list for len
        if len(subtags) == 1:  # terminal node, no subtrie
            subtrie = None
            tag = subtags[0]
            conditions = _conditions(tag, index + 1)
        else:
            subtrie = _trie(subtags, index + 1)
            tag = None
            conditions = None
        return char, subtrie, tag, conditions

    # Group by char at index
    def char_at_index(tag):
        return tag[index].lower()

    char_subtags = ((k, g) for k, g in groupby(tags, char_at_index))

    # FIXME: if all subtags have a common prefix, merge with child
    # and skip the switch in the generated code

    return (trie_node(char, subtags) for char, subtags in char_subtags)


def _conditions(tag, index):
    # boolean conditions to check suffix; corresponds to compacting branch
    # with a single leaf
    return ["%s[%d] == '%c'" % (PARAMETER_NAME, i, c.lower())
            for i, c in islice(enumerate(tag), index, None)]


class ElementLookupTrieWriter(in_generator.Writer):
    # FIXME: Inherit all these from somewhere.
    defaults = {
        'JSInterfaceName': None,
        'constructorNeedsCreatedByParser': None,
        'interfaceName': None,
        'noConstructor': None,
        'runtimeEnabled': None,
    }
    default_parameters = {
        'namespace': '',
        'fallbackInterfaceName': '',
        'fallbackJSInterfaceName': '',
    }

    def __init__(self, in_file_paths):
        super(ElementLookupTrieWriter, self).__init__(in_file_paths)
        self._tags = [entry['name'] for entry in self.in_file.name_dictionaries]
        self._namespace = self.in_file.parameters['namespace'].strip('"')
        self._outputs = {
            (self._namespace + 'ElementLookupTrie.h'): self.generate_header,
            (self._namespace + 'ElementLookupTrie.cpp'): self.generate_implementation,
        }

    @template_expander.use_jinja('ElementLookupTrie.h.tmpl')
    def generate_header(self):
        return {
            'namespace': self._namespace,
        }

    @template_expander.use_jinja('ElementLookupTrie.cpp.tmpl')
    def generate_implementation(self):
        # First sort, so groupby works
        self._tags.sort(key=lambda tag: (len(tag), tag))
        # Group tags by length
        length_tags = ((k, g) for k, g in groupby(self._tags, len))

        return {
            'namespace': self._namespace,
            'length_tries': ((length, _trie(tags, 0))
                             for length, tags in length_tags),
        }


if __name__ == '__main__':
    in_generator.Maker(ElementLookupTrieWriter).main(sys.argv)
