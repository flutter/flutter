/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef GlyphPageTreeNode_h
#define GlyphPageTreeNode_h

#include "platform/fonts/GlyphPage.h"
#include <string.h>
#include "wtf/HashMap.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/unicode/Unicode.h"

#ifndef NDEBUG
void PLATFORM_EXPORT showGlyphPageTrees();
void PLATFORM_EXPORT showGlyphPageTree(unsigned pageNumber);
#endif

namespace blink {

class FontData;
class SimpleFontData;

// The glyph page tree is a data structure that maps (FontData, glyph page number)
// to a GlyphPage.  Level 0 (the "root") is special. There is one root
// GlyphPageTreeNode for each glyph page number.  The roots do not have a
// GlyphPage associated with them, and their initializePage() function is never
// called to fill the glyphs.
//
// Each root node maps a FontData pointer to another GlyphPageTreeNode at
// level 1 (the "root child") that stores the actual glyphs for a specific font data.
// These nodes will only have a GlyphPage if they have glyphs for that range.
//
// Levels greater than one correspond to subsequent levels of the fallback list
// for that font. These levels override their parent's page of glyphs by
// filling in holes with the new font (thus making a more complete page).
//
// A NULL FontData pointer corresponds to the system fallback
// font. It is tracked separately from the regular pages and overrides so that
// the glyph pages do not get polluted with these last-resort glyphs. The
// system fallback page is not populated at construction like the other pages,
// but on demand for each glyph, because the system may need to use different
// fallback fonts for each. This lazy population is done by the Font.
class PLATFORM_EXPORT GlyphPageTreeNode {
    WTF_MAKE_FAST_ALLOCATED; WTF_MAKE_NONCOPYABLE(GlyphPageTreeNode);
public:
    static GlyphPageTreeNode* getRootChild(const FontData* fontData, unsigned pageNumber)
    {
        return getRoot(pageNumber)->getChild(fontData, pageNumber);
    }

    static void pruneTreeCustomFontData(const FontData*);
    static void pruneTreeFontData(const SimpleFontData*);

    void pruneCustomFontData(const FontData*);
    void pruneFontData(const SimpleFontData*, unsigned level = 0);

    GlyphPageTreeNode* parent() const { return m_parent; }
    GlyphPageTreeNode* getChild(const FontData*, unsigned pageNumber);

    // Returns a page of glyphs (or NULL if there are no glyphs in this page's character range).
    GlyphPage* page() const { return m_page.get(); }

    // Returns the level of this node. See class-level comment.
    unsigned level() const { return m_level; }

    // The system fallback font has special rules (see above).
    bool isSystemFallback() const { return m_isSystemFallback; }

    static size_t treeGlyphPageCount();
    size_t pageCount() const;

private:
    GlyphPageTreeNode()
        : m_parent(0)
        , m_level(0)
        , m_isSystemFallback(false)
        , m_customFontCount(0)
#if ENABLE(ASSERT)
        , m_pageNumber(0)
#endif
    {
    }

    static GlyphPageTreeNode* getRoot(unsigned pageNumber);
    void initializePage(const FontData*, unsigned pageNumber);

#ifndef NDEBUG
    void showSubtree();
#endif

    static HashMap<int, GlyphPageTreeNode*>* roots;
    static GlyphPageTreeNode* pageZeroRoot;

    typedef HashMap<const FontData*, OwnPtr<GlyphPageTreeNode> > GlyphPageTreeNodeMap;

    GlyphPageTreeNodeMap m_children;
    GlyphPageTreeNode* m_parent;
    RefPtr<GlyphPage> m_page;
    unsigned m_level : 31;
    bool m_isSystemFallback : 1;
    unsigned m_customFontCount;
    OwnPtr<GlyphPageTreeNode> m_systemFallbackChild;

#if ENABLE(ASSERT)
    unsigned m_pageNumber;
#endif
#ifndef NDEBUG
    friend void ::showGlyphPageTrees();
    friend void ::showGlyphPageTree(unsigned pageNumber);
#endif
};

} // namespace blink

#endif // GlyphPageTreeNode_h
