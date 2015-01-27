// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "config.h"
#include "bindings/core/dart/DartDOMStringMap.h"

namespace blink {

namespace DartDOMStringMapInternal {

static void containsKeyCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        DOMStringMap* receiver = DartDOMWrapper::receiver<DOMStringMap>(args);

        DartStringAdapter key = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        Dart_SetReturnValue(args, DartUtilities::boolToDart(receiver->contains(key)));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void itemCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        DOMStringMap* receiver = DartDOMWrapper::receiver<DOMStringMap>(args);

        DartStringAdapter key = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        Dart_SetReturnValue(args, DartUtilities::stringToDart(receiver->item(key)));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void setItemCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        DOMStringMap* receiver = DartDOMWrapper::receiver<DOMStringMap>(args);

        DartStringAdapter key = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        DartStringAdapter value = DartUtilities::dartToString(args, 2, exception);
        if (exception)
            goto fail;

        DartExceptionState es;
        receiver->setItem(key, value, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void removeCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        DOMStringMap* receiver = DartDOMWrapper::receiver<DOMStringMap>(args);

        DartStringAdapter key = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        String value = receiver->item(key);

        // FIXMEDART: is the signature for removeCallback now incorrect? Should
        // we instead just return the boolean return value of
        // receiver->deleteItem(key)?
        receiver->deleteItem(key);
        Dart_SetReturnValue(args, DartUtilities::stringToDartWithNullCheck(value));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void getKeysCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        DOMStringMap* receiver = DartDOMWrapper::receiver<DOMStringMap>(args);

        Vector<String> names;
        receiver->getNames(names);

        Dart_Handle result = Dart_NewList(names.size());
        if (!DartUtilities::checkResult(result, exception))
            goto fail;

        for (size_t i = 0; i < names.size(); ++i)
            Dart_ListSetAt(result, i, DartUtilities::stringToDartString(names[i]));

        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

static DartNativeEntry nativeEntries[] = {
    { DartDOMStringMapInternal::containsKeyCallback, 2, "DOMStringMap_containsKey_Callback" },
    { DartDOMStringMapInternal::itemCallback, 2, "DOMStringMap_item_Callback" },
    { DartDOMStringMapInternal::setItemCallback, 3, "DOMStringMap_setItem_Callback" },
    { DartDOMStringMapInternal::removeCallback, 2, "DOMStringMap_remove_Callback" },
    { DartDOMStringMapInternal::getKeysCallback, 1, "DOMStringMap_getKeys_Callback" },
    { 0, 0, 0 }
};

Dart_NativeFunction customDartDOMStringMapResolver(Dart_Handle nameHandle, int argumentCount, bool* autoSetupScope)
{
    ASSERT(autoSetupScope);
    *autoSetupScope = true;
    String name = DartUtilities::toString(nameHandle);

    for (intptr_t i = 0; nativeEntries[i].nativeFunction != 0; i++) {
        if (argumentCount == nativeEntries[i].argumentCount && name == nativeEntries[i].name) {
            return nativeEntries[i].nativeFunction;
        }
    }

    return 0;
}

const uint8_t* customDartDOMStringMapSymbolizer(Dart_NativeFunction nf)
{
    for (intptr_t i = 0; nativeEntries[i].nativeFunction != 0; i++) {
        if (nf == nativeEntries[i].nativeFunction) {
            return reinterpret_cast<const uint8_t*>(nativeEntries[i].name);
        }
    }

    return 0;
}

}
