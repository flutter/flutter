/*
 * Copyright (c) 2013, Opera Software ASA. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Opera Software ASA nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef DOMWindowEventHandlers_h
#define DOMWindowEventHandlers_h

#include "core/events/EventTarget.h"

namespace blink {

namespace DOMWindowEventHandlers {
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(beforeunload);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(hashchange);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(languagechange);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(message);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(offline);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(online);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(pagehide);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(pageshow);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(popstate);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(storage);
DEFINE_STATIC_WINDOW_ATTRIBUTE_EVENT_LISTENER(unload);
}

} // namespace

#endif
