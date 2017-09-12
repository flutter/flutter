/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008 Apple Inc.  All right reserved.
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

#ifndef SKY_ENGINE_PLATFORM_TEXT_BIDICHARACTERRUN_H_
#define SKY_ENGINE_PLATFORM_TEXT_BIDICHARACTERRUN_H_

#include "flutter/sky/engine/platform/text/BidiContext.h"
#include "flutter/sky/engine/platform/text/TextDirection.h"

namespace blink {

struct BidiCharacterRun {
  BidiCharacterRun(int start,
                   int stop,
                   BidiContext* context,
                   WTF::Unicode::Direction dir)
      : m_override(context->override()),
        m_next(0),
        m_start(start),
        m_stop(stop) {
    ASSERT(m_start <= m_stop);
    if (dir == WTF::Unicode::OtherNeutral)
      dir = context->dir();

    m_level = context->level();

    // add level of run (cases I1 & I2)
    if (m_level % 2) {
      if (dir == WTF::Unicode::LeftToRight ||
          dir == WTF::Unicode::ArabicNumber ||
          dir == WTF::Unicode::EuropeanNumber)
        m_level++;
    } else {
      if (dir == WTF::Unicode::RightToLeft)
        m_level++;
      else if (dir == WTF::Unicode::ArabicNumber ||
               dir == WTF::Unicode::EuropeanNumber)
        m_level += 2;
    }
  }

  // BidiCharacterRun are allocated out of the rendering partition.
  PLATFORM_EXPORT void* operator new(size_t);
  PLATFORM_EXPORT void operator delete(void*);

  int start() const { return m_start; }
  int stop() const { return m_stop; }
  unsigned char level() const { return m_level; }
  bool reversed() const { return m_level % 2; }
  bool dirOverride() { return m_override; }
  TextDirection direction() const { return reversed() ? RTL : LTR; }

  BidiCharacterRun* next() const { return m_next; }
  void setNext(BidiCharacterRun* next) { m_next = next; }

  // Do not add anything apart from bitfields until after m_next. See
  // https://bugs.webkit.org/show_bug.cgi?id=100173
  bool m_override : 1;
  bool m_hasHyphen : 1;  // Used by BidiRun subclass which is a layering
                         // violation but enables us to save 8 bytes per object
                         // on 64-bit.
  bool m_hasAddedEllipsis : 1;
  unsigned char m_level;
  BidiCharacterRun* m_next;
  int m_start;
  int m_stop;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_TEXT_BIDICHARACTERRUN_H_
