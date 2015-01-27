// Copyright 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartHTMLAllCollection.h"

#include "bindings/core/dart/DartElement.h"
#include "bindings/core/dart/DartNodeList.h"
#include "core/dom/StaticNodeList.h"

namespace blink {

namespace DartHTMLAllCollectionInternal {

void itemCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        HTMLAllCollection* collection = DartDOMWrapper::receiver<HTMLAllCollection>(args);
        unsigned index = DartUtilities::dartToUnsigned(args, 1, exception);
        if (exception)
            goto fail;
        // FIXME: This code will return a null object if index is out of bounds. We may prefer
        // to check the index and throw an exception in this case.
        RefPtr<Element> node = collection->item(index);
        Dart_SetReturnValue(args, toDartNoInline(node.get(), 0));
        return;
    }
fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void namedItemCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        HTMLAllCollection* collection = DartDOMWrapper::receiver<HTMLAllCollection>(args);
        DartStringAdapter name = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;
        {
            Vector<RefPtr<Element> > namedItems;
            collection->namedItems(name, namedItems);

            if (!namedItems.size())
                return;

            if (namedItems.size() == 1) {
                Dart_SetReturnValue(args, DartElement::toDart(namedItems.at(0).release()));
                return;
            }

            // FIXME: HTML5 specification says this should be a HTMLCollection.
            // http://www.whatwg.org/specs/web-apps/current-work/multipage/common-dom-interfaces.html#htmlallcollection
            // See http://dartbug.com/17538
            Dart_SetReturnValue(args, DartNodeList::toDart(StaticElementList::adopt(namedItems)));
            return;
        }
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

}
