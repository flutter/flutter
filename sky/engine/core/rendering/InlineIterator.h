/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010 Apple Inc.
 * All right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_CORE_RENDERING_INLINEITERATOR_H_
#define SKY_ENGINE_CORE_RENDERING_INLINEITERATOR_H_

#include "flutter/sky/engine/core/rendering/BidiRun.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RenderText.h"
#include "flutter/sky/engine/core/rendering/line/TrailingObjects.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"

namespace blink {

// This class is used to RenderInline subtrees, stepping by character within the
// text children. InlineIterator will use bidiNext to find the next RenderText
// optionally notifying a BidiResolver every time it steps into/out of a
// RenderInline.
class InlineIterator {
 public:
  enum IncrementRule {
    FastIncrementInIsolatedRenderer,
    FastIncrementInTextNode
  };

  InlineIterator()
      : m_root(0), m_obj(0), m_nextBreakablePosition(-1), m_pos(0) {}

  InlineIterator(RenderObject* root, RenderObject* o, unsigned p)
      : m_root(root), m_obj(o), m_nextBreakablePosition(-1), m_pos(p) {}

  void clear() { moveTo(0, 0); }

  void moveToStartOf(RenderObject* object) { moveTo(object, 0); }

  void moveTo(RenderObject* object, unsigned offset, int nextBreak = -1) {
    m_obj = object;
    m_pos = offset;
    m_nextBreakablePosition = nextBreak;
  }

  RenderObject* object() const { return m_obj; }
  void setObject(RenderObject* object) { m_obj = object; }

  int nextBreakablePosition() const { return m_nextBreakablePosition; }
  void setNextBreakablePosition(int position) {
    m_nextBreakablePosition = position;
  }

  unsigned offset() const { return m_pos; }
  void setOffset(unsigned position) { m_pos = position; }
  RenderObject* root() const { return m_root; }

  void fastIncrementInTextNode();
  void increment(InlineBidiResolver* = 0,
                 IncrementRule = FastIncrementInTextNode);
  bool atEnd() const;

  inline bool atTextParagraphSeparator() const {
    return m_obj && m_obj->preservesNewline() && m_obj->isText() &&
           toRenderText(m_obj)->textLength() &&
           toRenderText(m_obj)->characterAt(m_pos) == '\n';
  }

  inline bool atParagraphSeparator() const {
    return atTextParagraphSeparator();
  }

  UChar characterAt(unsigned) const;
  UChar current() const;
  UChar previousInSameNode() const;
  ALWAYS_INLINE WTF::Unicode::Direction direction() const;

 private:
  RenderObject* m_root;
  RenderObject* m_obj;

  int m_nextBreakablePosition;
  unsigned m_pos;
};

inline bool operator==(const InlineIterator& it1, const InlineIterator& it2) {
  return it1.offset() == it2.offset() && it1.object() == it2.object();
}

inline bool operator!=(const InlineIterator& it1, const InlineIterator& it2) {
  return it1.offset() != it2.offset() || it1.object() != it2.object();
}

static inline WTF::Unicode::Direction embedCharFromDirection(
    TextDirection dir,
    EUnicodeBidi unicodeBidi) {
  using namespace WTF::Unicode;
  if (unicodeBidi == Embed)
    return dir == RTL ? RightToLeftEmbedding : LeftToRightEmbedding;
  return dir == RTL ? RightToLeftOverride : LeftToRightOverride;
}

template <class Observer>
static inline void notifyObserverEnteredObject(Observer* observer,
                                               RenderObject* object) {
  if (!observer || !object || !object->isRenderInline())
    return;

  RenderStyle* style = object->style();
  EUnicodeBidi unicodeBidi = style->unicodeBidi();
  if (unicodeBidi == UBNormal) {
    // http://dev.w3.org/csswg/css3-writing-modes/#unicode-bidi
    // "The element does not open an additional level of embedding with respect
    // to the bidirectional algorithm." Thus we ignore any possible dir=
    // attribute on the span.
    return;
  }
  if (isIsolated(unicodeBidi)) {
    // Make sure that explicit embeddings are committed before we enter the
    // isolated content.
    observer->commitExplicitEmbedding(observer->runs());
    observer->enterIsolate();
    // Embedding/Override characters implied by dir= will be handled when
    // we process the isolated span, not when laying out the "parent" run.
    return;
  }

  if (!observer->inIsolate())
    observer->embed(embedCharFromDirection(style->direction(), unicodeBidi),
                    FromStyleOrDOM);
}

template <class Observer>
static inline void notifyObserverWillExitObject(Observer* observer,
                                                RenderObject* object) {
  if (!observer || !object || !object->isRenderInline())
    return;

  EUnicodeBidi unicodeBidi = object->style()->unicodeBidi();
  if (unicodeBidi == UBNormal)
    return;  // Nothing to do for unicode-bidi: normal
  if (isIsolated(unicodeBidi)) {
    observer->exitIsolate();
    return;
  }

  // Otherwise we pop any embed/override character we added when we opened this
  // tag.
  if (!observer->inIsolate())
    observer->embed(WTF::Unicode::PopDirectionalFormat, FromStyleOrDOM);
}

static inline bool isIteratorTarget(RenderObject* object) {
  ASSERT(object);  // The iterator will of course return 0, but its not an
                   // expected argument to this function.
  return object->isText() || object->isOutOfFlowPositioned() ||
         object->isReplaced();
}

// This enum is only used for bidiNextShared()
enum EmptyInlineBehavior {
  SkipEmptyInlines,
  IncludeEmptyInlines,
};

static bool isEmptyInline(RenderObject* object) {
  if (!object->isRenderInline())
    return false;

  for (RenderObject* curr = toRenderInline(object)->firstChild(); curr;
       curr = curr->nextSibling()) {
    if (curr->isFloatingOrOutOfFlowPositioned())
      continue;
    if (curr->isText() && toRenderText(curr)->isAllCollapsibleWhitespace())
      continue;

    if (!isEmptyInline(curr))
      return false;
  }
  return true;
}

// FIXME: This function is misleadingly named. It has little to do with bidi.
// This function will iterate over inlines within a block, optionally notifying
// a bidi resolver as it enters/exits inlines (so it can push/pop embedding
// levels).
template <class Observer>
static inline RenderObject* bidiNextShared(
    RenderObject* root,
    RenderObject* current,
    Observer* observer = 0,
    EmptyInlineBehavior emptyInlineBehavior = SkipEmptyInlines,
    bool* endOfInlinePtr = 0) {
  RenderObject* next = 0;
  // oldEndOfInline denotes if when we last stopped iterating if we were at the
  // end of an inline.
  bool oldEndOfInline = endOfInlinePtr ? *endOfInlinePtr : false;
  bool endOfInline = false;

  while (current) {
    next = 0;
    if (!oldEndOfInline && !isIteratorTarget(current)) {
      next = current->slowFirstChild();
      notifyObserverEnteredObject(observer, next);
    }

    // We hit this when either current has no children, or when current is not a
    // renderer we care about.
    if (!next) {
      // If it is a renderer we care about, and we're doing our inline-walk,
      // return it.
      if (emptyInlineBehavior == IncludeEmptyInlines && !oldEndOfInline &&
          current->isRenderInline()) {
        next = current;
        endOfInline = true;
        break;
      }

      while (current && current != root) {
        notifyObserverWillExitObject(observer, current);

        next = current->nextSibling();
        if (next) {
          notifyObserverEnteredObject(observer, next);
          break;
        }

        current = current->parent();
        if (emptyInlineBehavior == IncludeEmptyInlines && current &&
            current != root && current->isRenderInline()) {
          next = current;
          endOfInline = true;
          break;
        }
      }
    }

    if (!next)
      break;

    if (isIteratorTarget(next) ||
        ((emptyInlineBehavior == IncludeEmptyInlines ||
          isEmptyInline(next))  // Always return EMPTY inlines.
         && next->isRenderInline()))
      break;
    current = next;
  }

  if (endOfInlinePtr)
    *endOfInlinePtr = endOfInline;

  return next;
}

template <class Observer>
static inline RenderObject* bidiNextSkippingEmptyInlines(RenderObject* root,
                                                         RenderObject* current,
                                                         Observer* observer) {
  // The SkipEmptyInlines callers never care about endOfInlinePtr.
  return bidiNextShared(root, current, observer, SkipEmptyInlines);
}

// This makes callers cleaner as they don't have to specify a type for the
// observer when not providing one.
static inline RenderObject* bidiNextSkippingEmptyInlines(
    RenderObject* root,
    RenderObject* current) {
  InlineBidiResolver* observer = 0;
  return bidiNextSkippingEmptyInlines(root, current, observer);
}

static inline RenderObject* bidiNextIncludingEmptyInlines(
    RenderObject* root,
    RenderObject* current,
    bool* endOfInlinePtr = 0) {
  InlineBidiResolver* observer =
      0;  // Callers who include empty inlines, never use an observer.
  return bidiNextShared(root, current, observer, IncludeEmptyInlines,
                        endOfInlinePtr);
}

static inline RenderObject* bidiFirstSkippingEmptyInlines(
    RenderParagraph* root,
    BidiRunList<BidiRun>& runs,
    InlineBidiResolver* resolver = 0) {
  RenderObject* o = root->firstChild();
  if (!o)
    return 0;

  if (o->isRenderInline()) {
    notifyObserverEnteredObject(resolver, o);
    if (!isEmptyInline(o))
      o = bidiNextSkippingEmptyInlines(root, o, resolver);
    else {
      // Never skip empty inlines.
      if (resolver)
        resolver->commitExplicitEmbedding(runs);
      return o;
    }
  }

  // FIXME: Unify this with the bidiNext call above.
  if (o && !isIteratorTarget(o))
    o = bidiNextSkippingEmptyInlines(root, o, resolver);

  if (resolver)
    resolver->commitExplicitEmbedding(runs);
  return o;
}

// FIXME: This method needs to be renamed when bidiNext finds a good name.
static inline RenderObject* bidiFirstIncludingEmptyInlines(RenderBlock* root) {
  RenderObject* o = root->firstChild();
  // If either there are no children to walk, or the first one is correct
  // then just return it.
  if (!o || o->isRenderInline() || isIteratorTarget(o))
    return o;

  return bidiNextIncludingEmptyInlines(root, o);
}

inline void InlineIterator::fastIncrementInTextNode() {
  ASSERT(m_obj);
  ASSERT(m_obj->isText());
  ASSERT(m_pos <= toRenderText(m_obj)->textLength());
  if (m_pos < INT_MAX)
    m_pos++;
}

// FIXME: This is used by RenderParagraph for simplified layout, and has nothing
// to do with bidi it shouldn't use functions called bidiFirst and bidiNext.
class InlineWalker {
 public:
  InlineWalker(RenderBlock* root)
      : m_root(root), m_current(0), m_atEndOfInline(false) {
    // FIXME: This class should be taught how to do the SkipEmptyInlines
    // codepath as well.
    m_current = bidiFirstIncludingEmptyInlines(m_root);
  }

  RenderBlock* root() { return m_root; }
  RenderObject* current() { return m_current; }

  bool atEndOfInline() { return m_atEndOfInline; }
  bool atEnd() const { return !m_current; }

  RenderObject* advance() {
    // FIXME: Support SkipEmptyInlines and observer parameters.
    m_current =
        bidiNextIncludingEmptyInlines(m_root, m_current, &m_atEndOfInline);
    return m_current;
  }

 private:
  RenderBlock* m_root;
  RenderObject* m_current;
  bool m_atEndOfInline;
};

static inline bool endOfLineHasIsolatedObjectAncestor(
    const InlineIterator& isolatedIterator,
    const InlineIterator& ancestorItertor) {
  if (!isolatedIterator.object() ||
      !isIsolated(isolatedIterator.object()->style()->unicodeBidi()))
    return false;

  RenderObject* innerIsolatedObject = isolatedIterator.object();
  while (innerIsolatedObject &&
         innerIsolatedObject != isolatedIterator.root()) {
    if (innerIsolatedObject == ancestorItertor.object())
      return true;
    innerIsolatedObject = innerIsolatedObject->parent();
  }
  return false;
}

inline void InlineIterator::increment(InlineBidiResolver* resolver,
                                      IncrementRule rule) {
  if (!m_obj)
    return;

  if (rule == FastIncrementInIsolatedRenderer && resolver &&
      resolver->inIsolate() &&
      !endOfLineHasIsolatedObjectAncestor(resolver->endOfLine(),
                                          resolver->position())) {
    moveTo(bidiNextSkippingEmptyInlines(m_root, m_obj, resolver), 0);
    return;
  }

  if (m_obj->isText()) {
    fastIncrementInTextNode();
    if (m_pos < toRenderText(m_obj)->textLength())
      return;
  }
  // bidiNext can return 0, so use moveTo instead of moveToStartOf
  moveTo(bidiNextSkippingEmptyInlines(m_root, m_obj, resolver), 0);
}

inline bool InlineIterator::atEnd() const {
  return !m_obj;
}

inline UChar InlineIterator::characterAt(unsigned index) const {
  if (!m_obj || !m_obj->isText())
    return 0;

  return toRenderText(m_obj)->characterAt(index);
}

inline UChar InlineIterator::current() const {
  return characterAt(m_pos);
}

inline UChar InlineIterator::previousInSameNode() const {
  if (!m_pos)
    return 0;

  return characterAt(m_pos - 1);
}

ALWAYS_INLINE WTF::Unicode::Direction InlineIterator::direction() const {
  if (UChar c = current())
    return WTF::Unicode::direction(c);

  return WTF::Unicode::OtherNeutral;
}

template <>
inline void InlineBidiResolver::increment() {
  m_current.increment(this, InlineIterator::FastIncrementInIsolatedRenderer);
}

template <>
inline bool InlineBidiResolver::isEndOfLine(const InlineIterator& end) {
  bool inEndOfLine = m_current == end || m_current.atEnd() ||
                     (inIsolate() && m_current.object() == end.object());
  if (inIsolate() && inEndOfLine) {
    m_current.moveTo(m_current.object(), end.offset(),
                     m_current.nextBreakablePosition());
    m_last = m_current;
    updateStatusLastFromCurrentDirection(WTF::Unicode::OtherNeutral);
  }
  return inEndOfLine;
}

static inline bool isCollapsibleSpace(UChar character, RenderText* renderer) {
  if (character == ' ' || character == '\t' || character == softHyphen)
    return true;
  if (character == '\n')
    return !renderer->style()->preserveNewline();
  return false;
}

template <typename CharacterType>
static inline int findFirstTrailingSpace(RenderText* lastText,
                                         const CharacterType* characters,
                                         int start,
                                         int stop) {
  int firstSpace = stop;
  while (firstSpace > start) {
    UChar current = characters[firstSpace - 1];
    if (!isCollapsibleSpace(current, lastText))
      break;
    firstSpace--;
  }

  return firstSpace;
}

template <>
inline int InlineBidiResolver::findFirstTrailingSpaceAtRun(BidiRun* run) {
  ASSERT(run);
  RenderObject* lastObject = run->m_object;
  if (!lastObject->isText())
    return run->m_stop;

  RenderText* lastText = toRenderText(lastObject);
  int firstSpace;
  if (lastText->is8Bit())
    firstSpace = findFirstTrailingSpace(lastText, lastText->characters8(),
                                        run->start(), run->stop());
  else
    firstSpace = findFirstTrailingSpace(lastText, lastText->characters16(),
                                        run->start(), run->stop());
  return firstSpace;
}

template <>
inline BidiRun* InlineBidiResolver::addTrailingRun(
    BidiRunList<BidiRun>& runs,
    int start,
    int stop,
    BidiRun* run,
    BidiContext* context,
    TextDirection direction) const {
  BidiRun* newTrailingRun = new BidiRun(start, stop, run->m_object, context,
                                        WTF::Unicode::OtherNeutral);
  if (direction == LTR)
    runs.addRun(newTrailingRun);
  else
    runs.prependRun(newTrailingRun);

  return newTrailingRun;
}

template <>
inline bool InlineBidiResolver::needsToApplyL1Rule(BidiRunList<BidiRun>& runs) {
  if (!runs.logicallyLastRun()->m_object->style()->breakOnlyAfterWhiteSpace() ||
      !runs.logicallyLastRun()->m_object->style()->autoWrap())
    return false;
  return true;
}

static inline bool isIsolatedInline(RenderObject* object) {
  ASSERT(object);
  return object->isRenderInline() && isIsolated(object->style()->unicodeBidi());
}

static inline RenderObject* highestContainingIsolateWithinRoot(
    RenderObject* object,
    RenderObject* root) {
  ASSERT(object);
  RenderObject* containingIsolateObj = 0;
  while (object && object != root) {
    if (isIsolatedInline(object))
      containingIsolateObj = object;

    object = object->parent();
  }
  return containingIsolateObj;
}

static inline unsigned numberOfIsolateAncestors(const InlineIterator& iter) {
  RenderObject* object = iter.object();
  if (!object)
    return 0;
  unsigned count = 0;
  while (object && object != iter.root()) {
    if (isIsolatedInline(object))
      count++;
    object = object->parent();
  }
  return count;
}

// FIXME: This belongs on InlineBidiResolver, except it's a template
// specialization of BidiResolver which knows nothing about RenderObjects.
static inline BidiRun* addPlaceholderRunForIsolatedInline(
    InlineBidiResolver& resolver,
    RenderObject* obj,
    unsigned pos) {
  ASSERT(obj);
  BidiRun* isolatedRun =
      new BidiRun(pos, pos, obj, resolver.context(), resolver.dir());
  resolver.runs().addRun(isolatedRun);
  // FIXME: isolatedRuns() could be a hash of object->run and then we could
  // cheaply ASSERT here that we didn't create multiple objects for the same
  // inline.
  resolver.isolatedRuns().append(isolatedRun);
  return isolatedRun;
}

static inline BidiRun* createRun(int start,
                                 int end,
                                 RenderObject* obj,
                                 InlineBidiResolver& resolver) {
  return new BidiRun(start, end, obj, resolver.context(), resolver.dir());
}

enum AppendRunBehavior { AppendingFakeRun, AppendingRunsForObject };

class IsolateTracker {
 public:
  explicit IsolateTracker(BidiRunList<BidiRun>& runs,
                          unsigned nestedIsolateCount)
      : m_nestedIsolateCount(nestedIsolateCount),
        m_haveAddedFakeRunForRootIsolate(false),
        m_runs(runs) {}

  void setMidpointStateForRootIsolate(const LineMidpointState& midpointState) {
    m_midpointStateForRootIsolate = midpointState;
  }

  void enterIsolate() { m_nestedIsolateCount++; }
  void exitIsolate() {
    ASSERT(m_nestedIsolateCount >= 1);
    m_nestedIsolateCount--;
    if (!inIsolate())
      m_haveAddedFakeRunForRootIsolate = false;
  }
  bool inIsolate() const { return m_nestedIsolateCount; }

  // We don't care if we encounter bidi directional overrides.
  void embed(WTF::Unicode::Direction, BidiEmbeddingSource) {}
  void commitExplicitEmbedding(BidiRunList<BidiRun>&) {}
  BidiRunList<BidiRun>& runs() { return m_runs; }

  void addFakeRunIfNecessary(RenderObject* obj,
                             unsigned pos,
                             unsigned end,
                             InlineBidiResolver& resolver) {
    // We only need to add a fake run for a given isolated span once during each
    // call to createBidiRunsForLine. We'll be called for every span inside the
    // isolated span so we just ignore subsequent calls. We also avoid creating
    // a fake run until we hit a child that warrants one, e.g. we skip floats.
    if (RenderParagraph::shouldSkipCreatingRunsForObject(obj))
      return;
    if (!m_haveAddedFakeRunForRootIsolate) {
      BidiRun* run = addPlaceholderRunForIsolatedInline(resolver, obj, pos);
      resolver.setMidpointStateForIsolatedRun(run,
                                              m_midpointStateForRootIsolate);
      m_haveAddedFakeRunForRootIsolate = true;
    }
    // obj and pos together denote a single position in the inline, from which
    // the parsing of the isolate will start. We don't need to mark the end of
    // the run because this is implicit: it is either endOfLine or the end of
    // the isolate, when we call createBidiRunsForLine it will stop at whichever
    // comes first.
  }

 private:
  unsigned m_nestedIsolateCount;
  bool m_haveAddedFakeRunForRootIsolate;
  LineMidpointState m_midpointStateForRootIsolate;
  BidiRunList<BidiRun>& m_runs;
};

static void inline appendRunObjectIfNecessary(RenderObject* obj,
                                              unsigned start,
                                              unsigned end,
                                              InlineBidiResolver& resolver,
                                              AppendRunBehavior behavior,
                                              IsolateTracker& tracker) {
  if (behavior == AppendingFakeRun)
    tracker.addFakeRunIfNecessary(obj, start, end, resolver);
  else
    resolver.runs().addRun(createRun(start, end, obj, resolver));
}

static void adjustMidpointsAndAppendRunsForObjectIfNeeded(
    RenderObject* obj,
    unsigned start,
    unsigned end,
    InlineBidiResolver& resolver,
    AppendRunBehavior behavior,
    IsolateTracker& tracker) {
  if (start > end || RenderParagraph::shouldSkipCreatingRunsForObject(obj))
    return;

  LineMidpointState& lineMidpointState = resolver.midpointState();
  bool haveNextMidpoint =
      (lineMidpointState.currentMidpoint() < lineMidpointState.numMidpoints());
  InlineIterator nextMidpoint;
  if (haveNextMidpoint)
    nextMidpoint =
        lineMidpointState.midpoints()[lineMidpointState.currentMidpoint()];
  if (lineMidpointState.betweenMidpoints()) {
    if (!(haveNextMidpoint && nextMidpoint.object() == obj))
      return;
    // This is a new start point. Stop ignoring objects and
    // adjust our start.
    lineMidpointState.setBetweenMidpoints(false);
    start = nextMidpoint.offset();
    lineMidpointState.incrementCurrentMidpoint();
    if (start < end)
      return adjustMidpointsAndAppendRunsForObjectIfNeeded(
          obj, start, end, resolver, behavior, tracker);
  } else {
    if (!haveNextMidpoint || (obj != nextMidpoint.object())) {
      appendRunObjectIfNecessary(obj, start, end, resolver, behavior, tracker);
      return;
    }

    // An end midpoint has been encountered within our object. We
    // need to go ahead and append a run with our endpoint.
    if (nextMidpoint.offset() + 1 <= end) {
      lineMidpointState.setBetweenMidpoints(true);
      lineMidpointState.incrementCurrentMidpoint();
      if (nextMidpoint.offset() != UINT_MAX) {  // UINT_MAX means stop at the
                                                // object and don't nclude any
                                                // of it.
        if (nextMidpoint.offset() + 1 > start)
          appendRunObjectIfNecessary(obj, start, nextMidpoint.offset() + 1,
                                     resolver, behavior, tracker);
        return adjustMidpointsAndAppendRunsForObjectIfNeeded(
            obj, nextMidpoint.offset() + 1, end, resolver, behavior, tracker);
      }
    } else {
      appendRunObjectIfNecessary(obj, start, end, resolver, behavior, tracker);
    }
  }
}

static inline void addFakeRunIfNecessary(RenderObject* obj,
                                         unsigned start,
                                         unsigned end,
                                         InlineBidiResolver& resolver,
                                         IsolateTracker& tracker) {
  tracker.setMidpointStateForRootIsolate(resolver.midpointState());
  adjustMidpointsAndAppendRunsForObjectIfNeeded(
      obj, start, obj->length(), resolver, AppendingFakeRun, tracker);
}

template <>
inline void InlineBidiResolver::appendRun(BidiRunList<BidiRun>& runs) {
  if (!m_emptyRun && !m_eor.atEnd() && !m_reachedEndOfLine) {
    // Keep track of when we enter/leave "unicode-bidi: isolate" inlines.
    // Initialize our state depending on if we're starting in the middle of such
    // an inline.
    // FIXME: Could this initialize from this->inIsolate() instead of walking up
    // the render tree?
    IsolateTracker isolateTracker(runs, numberOfIsolateAncestors(m_sor));
    int start = m_sor.offset();
    RenderObject* obj = m_sor.object();
    while (obj && obj != m_eor.object() &&
           obj != m_endOfRunAtEndOfLine.object()) {
      if (isolateTracker.inIsolate())
        addFakeRunIfNecessary(obj, start, obj->length(), *this, isolateTracker);
      else
        adjustMidpointsAndAppendRunsForObjectIfNeeded(
            obj, start, obj->length(), *this, AppendingRunsForObject,
            isolateTracker);
      // FIXME: start/obj should be an InlineIterator instead of two separate
      // variables.
      start = 0;
      obj = bidiNextSkippingEmptyInlines(m_sor.root(), obj, &isolateTracker);
    }
    bool isEndOfLine = obj == m_endOfLine.object() && !m_endOfLine.offset();
    if (obj && !isEndOfLine) {
      unsigned pos = obj == m_eor.object() ? m_eor.offset() : INT_MAX;
      if (obj == m_endOfRunAtEndOfLine.object() &&
          m_endOfRunAtEndOfLine.offset() <= pos) {
        m_reachedEndOfLine = true;
        pos = m_endOfRunAtEndOfLine.offset();
      }
      // It's OK to add runs for zero-length RenderObjects, just don't make the
      // run larger than it should be
      int end = obj->length() ? pos + 1 : 0;
      if (isolateTracker.inIsolate())
        addFakeRunIfNecessary(obj, start, end, *this, isolateTracker);
      else
        adjustMidpointsAndAppendRunsForObjectIfNeeded(
            obj, start, end, *this, AppendingRunsForObject, isolateTracker);
    }

    if (isEndOfLine)
      m_reachedEndOfLine = true;
    // If isolateTrack is inIsolate, the next |start of run| can not be the
    // current isolated renderer.
    if (isolateTracker.inIsolate())
      m_eor.moveTo(bidiNextSkippingEmptyInlines(m_eor.root(), m_eor.object()),
                   0);
    else
      m_eor.increment();
    m_sor = m_eor;
  }

  m_direction = WTF::Unicode::OtherNeutral;
  m_status.eor = WTF::Unicode::OtherNeutral;
}

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_INLINEITERATOR_H_
