/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name of Google Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
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
#include "core/dom/custom/CustomElementException.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/dom/ExceptionCode.h"

namespace blink {

String CustomElementException::preamble(const AtomicString& type)
{
    return "Registration failed for type '" + type + "'. ";
}

void CustomElementException::throwException(Reason reason, const AtomicString& type, ExceptionState& exceptionState)
{
    switch (reason) {
    case CannotRegisterFromExtension:
        exceptionState.throwDOMException(NotSupportedError, preamble(type) + "Elements cannot be registered from extensions.");
        return;

    case ConstructorPropertyNotConfigurable:
        exceptionState.throwDOMException(NotSupportedError, preamble(type) + "Prototype constructor property is not configurable.");
        return;

    case ContextDestroyedCheckingPrototype:
        exceptionState.throwDOMException(InvalidStateError, preamble(type) + "The context is no longer valid.");
        return;

    case ContextDestroyedCreatingCallbacks:
        exceptionState.throwDOMException(InvalidStateError, preamble(type) + "The context is no longer valid.");
        return;

    case ContextDestroyedRegisteringDefinition:
        exceptionState.throwDOMException(InvalidStateError, preamble(type) + "The context is no longer valid.");
        return;

    case ExtendsIsInvalidName:
        exceptionState.throwDOMException(NotSupportedError, preamble(type) + "The tag name specified in 'extends' is not a valid tag name.");
        return;

    case ExtendsIsCustomElementName:
        exceptionState.throwDOMException(NotSupportedError, preamble(type) + "The tag name specified in 'extends' is a custom element name. Use inheritance instead.");
        return;

    case InvalidName:
        exceptionState.throwDOMException(SyntaxError, preamble(type) + "The type name is invalid.");
        return;

    case PrototypeInUse:
        exceptionState.throwDOMException(NotSupportedError, preamble(type) + "The prototype is already in-use as an interface prototype object.");
        return;

    case PrototypeNotAnObject:
        exceptionState.throwDOMException(NotSupportedError, preamble(type) + "The prototype option is not an object.");
        return;

    case TypeAlreadyRegistered:
        exceptionState.throwDOMException(NotSupportedError, preamble(type) + "A type with that name is already registered.");
        return;
    }

    ASSERT_NOT_REACHED();
}

} // namespace blink
