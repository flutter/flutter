/*
 * Copyright (C) 2010 Adam Barth. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SuffixTree_h
#define SuffixTree_h

#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class UnicodeCodebook {
public:
    static int codeWord(UChar c) { return c; }
    enum { codeSize = 1 << 8 * sizeof(UChar) };
};

class ASCIICodebook {
public:
    static int codeWord(UChar c) { return c & (codeSize - 1); }
    enum { codeSize = 1 << (8 * sizeof(char) - 1) };
};

template<typename Codebook>
class SuffixTree {
public:
    SuffixTree(const String& text, unsigned depth)
        : m_depth(depth)
        , m_leaf(true)
    {
        build(text);
    }

    bool mightContain(const String& query)
    {
        Node* current = &m_root;
        int limit = std::min(m_depth, query.length());
        for (int i = 0; i < limit; ++i) {
            current = current->at(Codebook::codeWord(query[i]));
            if (!current)
                return false;
        }
        return true;
    }

private:
    class Node {
    public:
        Node(bool isLeaf = false)
        {
            m_children.resize(Codebook::codeSize);
            m_children.fill(0);
            m_isLeaf = isLeaf;
        }

        ~Node()
        {
            for (unsigned i = 0; i < m_children.size(); ++i) {
                Node* child = m_children.at(i);
                if (child && !child->m_isLeaf)
                    delete child;
            }
        }

        Node*& at(int codeWord) { return m_children.at(codeWord); }

    private:
        typedef Vector<Node*, Codebook::codeSize> ChildrenVector;

        ChildrenVector m_children;
        bool m_isLeaf;
    };

    void build(const String& text)
    {
        for (unsigned base = 0; base < text.length(); ++base) {
            Node* current = &m_root;
            unsigned limit = std::min(base + m_depth, text.length());
            for (unsigned offset = 0; base + offset < limit; ++offset) {
                ASSERT(current != &m_leaf);
                Node*& child = current->at(Codebook::codeWord(text[base + offset]));
                if (!child)
                    child = base + offset + 1 == limit ? &m_leaf : new Node();
                current = child;
            }
        }
    }

    Node m_root;
    unsigned m_depth;

    // Instead of allocating a fresh empty leaf node for ever leaf in the tree
    // (there can be a lot of these), we alias all the leaves to this "static"
    // leaf node.
    Node m_leaf;
};

} // namespace blink

#endif // SuffixTree_h
