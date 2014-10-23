/*
 * Copyright (C) 2005, 2006, 2007, 2008, 2011, 2012 Apple Inc. All rights reserved.
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

#ifndef WTF_HashTraits_h
#define WTF_HashTraits_h

#include "wtf/HashFunctions.h"
#include "wtf/HashTableDeletedValueType.h"
#include "wtf/StdLibExtras.h"
#include "wtf/TypeTraits.h"
#include <limits>
#include <string.h> // For memset.
#include <utility>

namespace WTF {

    class String;

    template<typename T> class OwnPtr;
    template<typename T> class PassOwnPtr;

    template<typename T> struct HashTraits;

    template<bool isInteger, typename T> struct GenericHashTraitsBase;

    enum ShouldWeakPointersBeMarkedStrongly {
        WeakPointersActStrong,
        WeakPointersActWeak
    };

    template<typename T> struct GenericHashTraitsBase<false, T> {
        // The emptyValueIsZero flag is used to optimize allocation of empty hash tables with zeroed memory.
        static const bool emptyValueIsZero = false;

        // The hasIsEmptyValueFunction flag allows the hash table to automatically generate code to check
        // for the empty value when it can be done with the equality operator, but allows custom functions
        // for cases like String that need them.
        static const bool hasIsEmptyValueFunction = false;

        // The needsDestruction flag is used to optimize destruction and rehashing.
        static const bool needsDestruction = true;

        // The starting table size. Can be overridden when we know beforehand that
        // a hash table will have at least N entries.
#if defined(MEMORY_SANITIZER_INITIAL_SIZE)
        static const unsigned minimumTableSize = 1;
#else
        static const unsigned minimumTableSize = 8;
#endif

        template<typename U = void>
        struct NeedsTracingLazily {
            static const bool value = NeedsTracing<T>::value;
        };
        static const WeakHandlingFlag weakHandlingFlag = IsWeak<T>::value ? WeakHandlingInCollections : NoWeakHandlingInCollections;
    };

    // Default integer traits disallow both 0 and -1 as keys (max value instead of -1 for unsigned).
    template<typename T> struct GenericHashTraitsBase<true, T> : GenericHashTraitsBase<false, T> {
        static const bool emptyValueIsZero = true;
        static const bool needsDestruction = false;
        static void constructDeletedValue(T& slot, bool) { slot = static_cast<T>(-1); }
        static bool isDeletedValue(T value) { return value == static_cast<T>(-1); }
    };

    template<typename T> struct GenericHashTraits : GenericHashTraitsBase<IsInteger<T>::value, T> {
        typedef T TraitType;
        typedef T EmptyValueType;

        static T emptyValue() { return T(); }

        // Type for functions that do not take ownership, such as contains.
        typedef const T& PeekInType;
        typedef T* IteratorGetType;
        typedef const T* IteratorConstGetType;
        typedef T& IteratorReferenceType;
        typedef const T& IteratorConstReferenceType;
        static IteratorReferenceType getToReferenceConversion(IteratorGetType x) { return *x; }
        static IteratorConstReferenceType getToReferenceConstConversion(IteratorConstGetType x) { return *x; }
        // Type for functions that take ownership, such as add.
        // The store function either not be called or called once to store something passed in.
        // The value passed to the store function will be PassInType.
        typedef const T& PassInType;
        static void store(const T& value, T& storage) { storage = value; }

        // Type for return value of functions that transfer ownership, such as take.
        typedef T PassOutType;
        static const T& passOut(const T& value) { return value; }

        // Type for return value of functions that do not transfer ownership, such as get.
        // FIXME: We could change this type to const T& for better performance if we figured out
        // a way to handle the return value from emptyValue, which is a temporary.
        typedef T PeekOutType;
        static const T& peek(const T& value) { return value; }
    };

    template<typename T> struct HashTraits : GenericHashTraits<T> { };

    template<typename T> struct FloatHashTraits : GenericHashTraits<T> {
        static const bool needsDestruction = false;
        static T emptyValue() { return std::numeric_limits<T>::infinity(); }
        static void constructDeletedValue(T& slot, bool) { slot = -std::numeric_limits<T>::infinity(); }
        static bool isDeletedValue(T value) { return value == -std::numeric_limits<T>::infinity(); }
    };

    template<> struct HashTraits<float> : FloatHashTraits<float> { };
    template<> struct HashTraits<double> : FloatHashTraits<double> { };

    // Default unsigned traits disallow both 0 and max as keys -- use these traits to allow zero and disallow max - 1.
    template<typename T> struct UnsignedWithZeroKeyHashTraits : GenericHashTraits<T> {
        static const bool emptyValueIsZero = false;
        static const bool needsDestruction = false;
        static T emptyValue() { return std::numeric_limits<T>::max(); }
        static void constructDeletedValue(T& slot, bool) { slot = std::numeric_limits<T>::max() - 1; }
        static bool isDeletedValue(T value) { return value == std::numeric_limits<T>::max() - 1; }
    };

    template<typename P> struct HashTraits<P*> : GenericHashTraits<P*> {
        static const bool emptyValueIsZero = true;
        static const bool needsDestruction = false;
        static void constructDeletedValue(P*& slot, bool) { slot = reinterpret_cast<P*>(-1); }
        static bool isDeletedValue(P* value) { return value == reinterpret_cast<P*>(-1); }
    };

    template<typename T> struct SimpleClassHashTraits : GenericHashTraits<T> {
        static const bool emptyValueIsZero = true;
        static void constructDeletedValue(T& slot, bool) { new (NotNull, &slot) T(HashTableDeletedValue); }
        static bool isDeletedValue(const T& value) { return value.isHashTableDeletedValue(); }
    };

    template<typename P> struct HashTraits<OwnPtr<P> > : SimpleClassHashTraits<OwnPtr<P> > {
        typedef std::nullptr_t EmptyValueType;

        static EmptyValueType emptyValue() { return nullptr; }

        static const bool hasIsEmptyValueFunction = true;
        static bool isEmptyValue(const OwnPtr<P>& value) { return !value; }

        typedef typename OwnPtr<P>::PtrType PeekInType;

        typedef PassOwnPtr<P> PassInType;
        static void store(PassOwnPtr<P> value, OwnPtr<P>& storage) { storage = value; }

        typedef PassOwnPtr<P> PassOutType;
        static PassOwnPtr<P> passOut(OwnPtr<P>& value) { return value.release(); }
        static PassOwnPtr<P> passOut(std::nullptr_t) { return nullptr; }

        typedef typename OwnPtr<P>::PtrType PeekOutType;
        static PeekOutType peek(const OwnPtr<P>& value) { return value.get(); }
        static PeekOutType peek(std::nullptr_t) { return 0; }
    };

    template<typename P> struct HashTraits<RefPtr<P> > : SimpleClassHashTraits<RefPtr<P> > {
        typedef std::nullptr_t EmptyValueType;
        static EmptyValueType emptyValue() { return nullptr; }

        static const bool hasIsEmptyValueFunction = true;
        static bool isEmptyValue(const RefPtr<P>& value) { return !value; }

        typedef RefPtrValuePeeker<P> PeekInType;
        typedef RefPtr<P>* IteratorGetType;
        typedef const RefPtr<P>* IteratorConstGetType;
        typedef RefPtr<P>& IteratorReferenceType;
        typedef const RefPtr<P>& IteratorConstReferenceType;
        static IteratorReferenceType getToReferenceConversion(IteratorGetType x) { return *x; }
        static IteratorConstReferenceType getToReferenceConstConversion(IteratorConstGetType x) { return *x; }

        typedef PassRefPtr<P> PassInType;
        static void store(PassRefPtr<P> value, RefPtr<P>& storage) { storage = value; }

        typedef PassRefPtr<P> PassOutType;
        static PassOutType passOut(RefPtr<P>& value) { return value.release(); }
        static PassOutType passOut(std::nullptr_t) { return nullptr; }

        typedef P* PeekOutType;
        static PeekOutType peek(const RefPtr<P>& value) { return value.get(); }
        static PeekOutType peek(std::nullptr_t) { return 0; }
    };

    template<typename T> struct HashTraits<RawPtr<T> > : HashTraits<T*> { };

    template<> struct HashTraits<String> : SimpleClassHashTraits<String> {
        static const bool hasIsEmptyValueFunction = true;
        static bool isEmptyValue(const String&);
    };

    // This struct template is an implementation detail of the isHashTraitsEmptyValue function,
    // which selects either the emptyValue function or the isEmptyValue function to check for empty values.
    template<typename Traits, bool hasEmptyValueFunction> struct HashTraitsEmptyValueChecker;
    template<typename Traits> struct HashTraitsEmptyValueChecker<Traits, true> {
        template<typename T> static bool isEmptyValue(const T& value) { return Traits::isEmptyValue(value); }
    };
    template<typename Traits> struct HashTraitsEmptyValueChecker<Traits, false> {
        template<typename T> static bool isEmptyValue(const T& value) { return value == Traits::emptyValue(); }
    };
    template<typename Traits, typename T> inline bool isHashTraitsEmptyValue(const T& value)
    {
        return HashTraitsEmptyValueChecker<Traits, Traits::hasIsEmptyValueFunction>::isEmptyValue(value);
    }

    template<typename FirstTraitsArg, typename SecondTraitsArg>
    struct PairHashTraits : GenericHashTraits<std::pair<typename FirstTraitsArg::TraitType, typename SecondTraitsArg::TraitType> > {
        typedef FirstTraitsArg FirstTraits;
        typedef SecondTraitsArg SecondTraits;
        typedef std::pair<typename FirstTraits::TraitType, typename SecondTraits::TraitType> TraitType;
        typedef std::pair<typename FirstTraits::EmptyValueType, typename SecondTraits::EmptyValueType> EmptyValueType;

        static const bool emptyValueIsZero = FirstTraits::emptyValueIsZero && SecondTraits::emptyValueIsZero;
        static EmptyValueType emptyValue() { return std::make_pair(FirstTraits::emptyValue(), SecondTraits::emptyValue()); }

        static const bool needsDestruction = FirstTraits::needsDestruction || SecondTraits::needsDestruction;

        static const unsigned minimumTableSize = FirstTraits::minimumTableSize;

        static void constructDeletedValue(TraitType& slot, bool zeroValue)
        {
            FirstTraits::constructDeletedValue(slot.first, zeroValue);
            // For GC collections the memory for the backing is zeroed when it
            // is allocated, and the constructors may take advantage of that,
            // especially if a GC occurs during insertion of an entry into the
            // table. This slot is being marked deleted, but If the slot is
            // reused at a later point, the same assumptions around memory
            // zeroing must hold as they did at the initial allocation.
            // Therefore we zero the value part of the slot here for GC
            // collections.
            if (zeroValue)
                memset(reinterpret_cast<void*>(&slot.second), 0, sizeof(slot.second));
        }
        static bool isDeletedValue(const TraitType& value) { return FirstTraits::isDeletedValue(value.first); }
    };

    template<typename First, typename Second>
    struct HashTraits<std::pair<First, Second> > : public PairHashTraits<HashTraits<First>, HashTraits<Second> > { };

    template<typename KeyTypeArg, typename ValueTypeArg>
    struct KeyValuePair {
        typedef KeyTypeArg KeyType;

        KeyValuePair()
        {
        }

        KeyValuePair(const KeyTypeArg& _key, const ValueTypeArg& _value)
            : key(_key)
            , value(_value)
        {
        }

        template <typename OtherKeyType, typename OtherValueType>
        KeyValuePair(const KeyValuePair<OtherKeyType, OtherValueType>& other)
            : key(other.key)
            , value(other.value)
        {
        }

        KeyTypeArg key;
        ValueTypeArg value;
    };

    template<typename KeyTraitsArg, typename ValueTraitsArg>
    struct KeyValuePairHashTraits : GenericHashTraits<KeyValuePair<typename KeyTraitsArg::TraitType, typename ValueTraitsArg::TraitType> > {
        typedef KeyTraitsArg KeyTraits;
        typedef ValueTraitsArg ValueTraits;
        typedef KeyValuePair<typename KeyTraits::TraitType, typename ValueTraits::TraitType> TraitType;
        typedef KeyValuePair<typename KeyTraits::EmptyValueType, typename ValueTraits::EmptyValueType> EmptyValueType;

        static const bool emptyValueIsZero = KeyTraits::emptyValueIsZero && ValueTraits::emptyValueIsZero;
        static EmptyValueType emptyValue() { return KeyValuePair<typename KeyTraits::EmptyValueType, typename ValueTraits::EmptyValueType>(KeyTraits::emptyValue(), ValueTraits::emptyValue()); }

        static const bool needsDestruction = KeyTraits::needsDestruction || ValueTraits::needsDestruction;
        template<typename U = void>
        struct NeedsTracingLazily {
            static const bool value = ShouldBeTraced<KeyTraits>::value || ShouldBeTraced<ValueTraits>::value;
        };
        static const WeakHandlingFlag weakHandlingFlag = (KeyTraits::weakHandlingFlag == WeakHandlingInCollections || ValueTraits::weakHandlingFlag == WeakHandlingInCollections) ? WeakHandlingInCollections : NoWeakHandlingInCollections;

        static const unsigned minimumTableSize = KeyTraits::minimumTableSize;

        static void constructDeletedValue(TraitType& slot, bool zeroValue)
        {
            KeyTraits::constructDeletedValue(slot.key, zeroValue);
            // See similar code in this file for why we need to do this.
            if (zeroValue)
                memset(reinterpret_cast<void*>(&slot.value), 0, sizeof(slot.value));
        }
        static bool isDeletedValue(const TraitType& value) { return KeyTraits::isDeletedValue(value.key); }
    };

    template<typename Key, typename Value>
    struct HashTraits<KeyValuePair<Key, Value> > : public KeyValuePairHashTraits<HashTraits<Key>, HashTraits<Value> > { };

    template<typename T>
    struct NullableHashTraits : public HashTraits<T> {
        static const bool emptyValueIsZero = false;
        static T emptyValue() { return reinterpret_cast<T>(1); }
    };

    // This is for tracing inside collections that have special support for weak
    // pointers. The trait has a trace method which returns true if there are weak
    // pointers to things that have not (yet) been marked live. Returning true
    // indicates that the entry in the collection may yet be removed by weak
    // handling. Default implementation for non-weak types is to use the regular
    // non-weak TraceTrait. Default implementation for types with weakness is to
    // call traceInCollection on the type's trait.
    template<WeakHandlingFlag weakHandlingFlag, ShouldWeakPointersBeMarkedStrongly strongify, typename T, typename Traits>
    struct TraceInCollectionTrait;

} // namespace WTF

using WTF::HashTraits;
using WTF::PairHashTraits;
using WTF::NullableHashTraits;
using WTF::SimpleClassHashTraits;

#endif // WTF_HashTraits_h
