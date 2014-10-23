/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#include "config.h"
#include "public/web/WebPerformance.h"

namespace blink {

void WebPerformance::reset()
{
}

void WebPerformance::assign(const WebPerformance& other)
{
}

WebNavigationType WebPerformance::navigationType() const
{
    return WebNavigationTypeOther;
}

double WebPerformance::navigationStart() const
{
    return 0;
}

double WebPerformance::unloadEventEnd() const
{
    return 0;
}

double WebPerformance::redirectStart() const
{
    return 0;
}

double WebPerformance::redirectEnd() const
{
    return 0;
}

unsigned short WebPerformance::redirectCount() const
{
    return 0;
}

double WebPerformance::fetchStart() const
{
    return 0;
}

double WebPerformance::domainLookupStart() const
{
    return 0;
}

double WebPerformance::domainLookupEnd() const
{
    return 0;
}

double WebPerformance::connectStart() const
{
    return 0;
}

double WebPerformance::connectEnd() const
{
    return 0;
}

double WebPerformance::requestStart() const
{
    return 0;
}

double WebPerformance::responseStart() const
{
    return 0;
}

double WebPerformance::responseEnd() const
{
    return 0;
}

double WebPerformance::domLoading() const
{
    return 0;
}

double WebPerformance::domInteractive() const
{
    return 0;
}

double WebPerformance::domContentLoadedEventStart() const
{
    return 0;
}

double WebPerformance::domContentLoadedEventEnd() const
{
    return 0;
}

double WebPerformance::domComplete() const
{
    return 0;
}

double WebPerformance::loadEventStart() const
{
    return 0;
}

double WebPerformance::loadEventEnd() const
{
    return 0;
}

} // namespace blink
