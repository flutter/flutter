// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef DartDOMStringMap_h
#define DartDOMStringMap_h

#include "bindings/core/dart/DartDOMWrapper.h"
#include "core/dom/DOMStringMap.h"

#include <dart_api.h>

namespace blink {

struct DartDOMStringMap {
    static const int dartClassId = DOMStringMapClassId;
    typedef DOMStringMap NativeType;
    const static bool isNode = false;
    const static bool isEventTarget = false;
    const static bool isActive = false;
    const static bool isGarbageCollected = false;

    static PassRefPtr<NativeType> toNative(Dart_Handle handle, Dart_Handle& exception)
    {
        DartDOMData* domData = DartDOMData::current();
        return DartDOMWrapper::unwrapDartWrapper<DartDOMStringMap>(domData, handle, exception);
    }

    static Dart_Handle toDart(DOMStringMap* value)
    {
        DartDOMData* domData = DartDOMData::current();
        Dart_WeakPersistentHandle result = DartDOMWrapper::lookupWrapper<DartDOMStringMap>(domData, value);
        if (result)
            return Dart_HandleFromWeakPersistent(result);
        return DartDOMWrapper::createWrapper<DartDOMStringMap>(domData, value);
    }
    static void returnToDart(Dart_NativeArguments args, DOMStringMap* value)
    {
        DartDOMWrapper::returnToDart<DartDOMStringMap>(args, value);
    }

    static Dart_Handle toDart(PassRefPtr< DOMStringMap > value)
    {
        return toDart(value.get());
    }

    static Dart_NativeFunction resolver(Dart_Handle name, int argumentCount, bool* autoSetupScope);
};

}

#endif // DartDOMStringMap_h
