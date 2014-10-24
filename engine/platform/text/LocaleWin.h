/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef LocaleWin_h
#define LocaleWin_h

#include <windows.h>
#include "platform/text/PlatformLocale.h"
#include "wtf/Forward.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink {

class PLATFORM_EXPORT LocaleWin : public Locale {
public:
    static PassOwnPtr<LocaleWin> create(LCID, bool defaultsForLocale);
    ~LocaleWin();
    virtual const Vector<String>& weekDayShortLabels() override;
    virtual unsigned firstDayOfWeek() override;
    virtual bool isRTL() override;
    virtual String dateFormat() override;
    virtual String monthFormat() override;
    virtual String shortMonthFormat() override;
    virtual String timeFormat() override;
    virtual String shortTimeFormat() override;
    virtual String dateTimeFormatWithSeconds() override;
    virtual String dateTimeFormatWithoutSeconds() override;
    virtual const Vector<String>& monthLabels() override;
    virtual const Vector<String>& shortMonthLabels() override;
    virtual const Vector<String>& standAloneMonthLabels() override;
    virtual const Vector<String>& shortStandAloneMonthLabels() override;
    virtual const Vector<String>& timeAMPMLabels() override;

    static String dateFormat(const String&);

private:
    explicit LocaleWin(LCID, bool defaultsForLocale);
    String getLocaleInfoString(LCTYPE);
    void getLocaleInfo(LCTYPE, DWORD&);
    void ensureShortMonthLabels();
    void ensureMonthLabels();
    void ensureWeekDayShortLabels();
    // Locale function:
    virtual void initializeLocaleData() override;

    LCID m_lcid;
    Vector<String> m_shortMonthLabels;
    Vector<String> m_monthLabels;
    String m_dateFormat;
    String m_monthFormat;
    String m_shortMonthFormat;
    String m_timeFormatWithSeconds;
    String m_timeFormatWithoutSeconds;
    String m_dateTimeFormatWithSeconds;
    String m_dateTimeFormatWithoutSeconds;
    Vector<String> m_timeAMPMLabels;
    Vector<String> m_weekDayShortLabels;
    unsigned m_firstDayOfWeek;
    bool m_didInitializeNumberData;
    bool m_defaultsForLocale;
};

} // namespace blink
#endif
