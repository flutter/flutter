/*
 * Copyright (C) 2007 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Google Inc.
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
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 */

#include "config.h"
#include "platform/text/TextBreakIteratorInternalICU.h"

#include "platform/Language.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

namespace blink {

static const char* UILanguage()
{
    // Chrome's UI language can be different from the OS UI language on Windows.
    // We want to return Chrome's UI language here.
    DEFINE_STATIC_LOCAL(const CString, locale, (defaultLanguage().latin1()));
    return locale.data();
}

const char* currentSearchLocaleID()
{
    return UILanguage();
}

const char* currentTextBreakLocaleID()
{
    return UILanguage();
}

} // namespace blink
