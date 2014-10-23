/*
 * Copyright (C) 2005, 2006, 2007, 2008, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2011, Benjamin Poulain <ikipou@gmail.com>
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

#ifndef WTF_LinkedHashSet_h
#define WTF_LinkedHashSet_h

#include "wtf/DefaultAllocator.h"
#include "wtf/HashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace WTF {

// LinkedHashSet: Just like HashSet, this class provides a Set
// interface - a collection of unique objects with O(1) insertion,
// removal and test for containership. However, it also has an
// order - iterating it will always give back values in the order
// in which they are added.

// Unlike ListHashSet, but like most WTF collections, iteration is NOT safe
// against mutation of the LinkedHashSet.

template<typename Value, typename HashFunctions, typename HashTraits, typename Allocator> class LinkedHashSet;

template<typename LinkedHashSet> class LinkedHashSetIterator;
template<typename LinkedHashSet> class LinkedHashSetConstIterator;
template<typename LinkedHashSet> class LinkedHashSetReverseIterator;
template<typename LinkedHashSet> class LinkedHashSetConstReverseIterator;

template<typename Value, typename HashFunctions, typename Allocator> struct LinkedHashSetTranslator;
template<typename Value, typename Allocator> struct LinkedHashSetExtractor;
template<typename Value, typename ValueTraits, typename Allocator> struct LinkedHashSetTraits;

class LinkedHashSetNodeBase {
public:
    LinkedHashSetNodeBase() : m_prev(this), m_next(this) { }

    void unlink()
    {
        if (!m_next)
            return;
        ASSERT(m_prev);
        ASSERT(m_next->m_prev == this);
        ASSERT(m_prev->m_next == this);
        m_next->m_prev = m_prev;
        m_prev->m_next = m_next;
    }

    ~LinkedHashSetNodeBase()
    {
        unlink();
    }

    void insertBefore(LinkedHashSetNodeBase& other)
    {
        other.m_next = this;
        other.m_prev = m_prev;
        m_prev->m_next = &other;
        m_prev = &other;
        ASSERT(other.m_next);
        ASSERT(other.m_prev);
        ASSERT(m_next);
        ASSERT(m_prev);
    }

    void insertAfter(LinkedHashSetNodeBase& other)
    {
        other.m_prev = this;
        other.m_next = m_next;
        m_next->m_prev = &other;
        m_next = &other;
        ASSERT(other.m_next);
        ASSERT(other.m_prev);
        ASSERT(m_next);
        ASSERT(m_prev);
    }

    LinkedHashSetNodeBase(LinkedHashSetNodeBase* prev, LinkedHashSetNodeBase* next)
        : m_prev(prev)
        , m_next(next)
    {
        ASSERT((prev && next) || (!prev && !next));
    }

    LinkedHashSetNodeBase* m_prev;
    LinkedHashSetNodeBase* m_next;

protected:
    // If we take a copy of a node we can't copy the next and prev pointers,
    // since they point to something that does not point at us. This is used
    // inside the shouldExpand() "if" in HashTable::add.
    LinkedHashSetNodeBase(const LinkedHashSetNodeBase& other)
        : m_prev(0)
        , m_next(0) { }

private:
    // Should not be used.
    LinkedHashSetNodeBase& operator=(const LinkedHashSetNodeBase& other);
};

template<typename ValueArg, typename Allocator>
class LinkedHashSetNode : public LinkedHashSetNodeBase {
public:
    LinkedHashSetNode(const ValueArg& value, LinkedHashSetNodeBase* prev, LinkedHashSetNodeBase* next)
        : LinkedHashSetNodeBase(prev, next)
        , m_value(value)
    {
    }

    ValueArg m_value;

private:
    // Not used.
    LinkedHashSetNode(const LinkedHashSetNode&);
};

template<
    typename ValueArg,
    typename HashFunctions = typename DefaultHash<ValueArg>::Hash,
    typename TraitsArg = HashTraits<ValueArg>,
    typename Allocator = DefaultAllocator>
class LinkedHashSet {
    WTF_USE_ALLOCATOR(LinkedHashSet, Allocator);
private:
    typedef ValueArg Value;
    typedef TraitsArg Traits;
    typedef LinkedHashSetNode<Value, Allocator> Node;
    typedef LinkedHashSetNodeBase NodeBase;
    typedef LinkedHashSetTranslator<Value, HashFunctions, Allocator> NodeHashFunctions;
    typedef LinkedHashSetTraits<Value, Traits, Allocator> NodeHashTraits;

    typedef HashTable<Node, Node, IdentityExtractor,
        NodeHashFunctions, NodeHashTraits, NodeHashTraits, Allocator> ImplType;

public:
    typedef LinkedHashSetIterator<LinkedHashSet> iterator;
    friend class LinkedHashSetIterator<LinkedHashSet>;
    typedef LinkedHashSetConstIterator<LinkedHashSet> const_iterator;
    friend class LinkedHashSetConstIterator<LinkedHashSet>;

    typedef LinkedHashSetReverseIterator<LinkedHashSet> reverse_iterator;
    friend class LinkedHashSetReverseIterator<LinkedHashSet>;
    typedef LinkedHashSetConstReverseIterator<LinkedHashSet> const_reverse_iterator;
    friend class LinkedHashSetConstReverseIterator<LinkedHashSet>;

    struct AddResult {
        AddResult(const typename ImplType::AddResult& hashTableAddResult)
            : storedValue(&hashTableAddResult.storedValue->m_value)
            , isNewEntry(hashTableAddResult.isNewEntry)
        {
        }

        Value* storedValue;
        bool isNewEntry;
    };

    typedef typename HashTraits<Value>::PeekInType ValuePeekInType;

    LinkedHashSet();
    LinkedHashSet(const LinkedHashSet&);
    LinkedHashSet& operator=(const LinkedHashSet&);

    // Needs finalization. The anchor needs to unlink itself from the chain.
    ~LinkedHashSet();

    static void finalize(void* pointer) { reinterpret_cast<LinkedHashSet*>(pointer)->~LinkedHashSet(); }

    void swap(LinkedHashSet&);

    unsigned size() const { return m_impl.size(); }
    unsigned capacity() const { return m_impl.capacity(); }
    bool isEmpty() const { return m_impl.isEmpty(); }

    iterator begin() { return makeIterator(firstNode()); }
    iterator end() { return makeIterator(anchor()); }
    const_iterator begin() const { return makeConstIterator(firstNode()); }
    const_iterator end() const { return makeConstIterator(anchor()); }

    reverse_iterator rbegin() { return makeReverseIterator(lastNode()); }
    reverse_iterator rend() { return makeReverseIterator(anchor()); }
    const_reverse_iterator rbegin() const { return makeConstReverseIterator(lastNode()); }
    const_reverse_iterator rend() const { return makeConstReverseIterator(anchor()); }

    Value& first();
    const Value& first() const;
    void removeFirst();

    Value& last();
    const Value& last() const;
    void removeLast();

    iterator find(ValuePeekInType);
    const_iterator find(ValuePeekInType) const;
    bool contains(ValuePeekInType) const;

    // An alternate version of find() that finds the object by hashing and comparing
    // with some other type, to avoid the cost of type conversion.
    // The HashTranslator interface is defined in HashSet.
    template<typename HashTranslator, typename T> iterator find(const T&);
    template<typename HashTranslator, typename T> const_iterator find(const T&) const;
    template<typename HashTranslator, typename T> bool contains(const T&) const;

    // The return value of add is a pair of a pointer to the stored value,
    // and a bool that is true if an new entry was added.
    AddResult add(ValuePeekInType);

    // Same as add() except that the return value is an
    // iterator. Useful in cases where it's needed to have the
    // same return value as find() and where it's not possible to
    // use a pointer to the storedValue.
    iterator addReturnIterator(ValuePeekInType);

    // Add the value to the end of the collection. If the value was already in
    // the list, it is moved to the end.
    AddResult appendOrMoveToLast(ValuePeekInType);

    // Add the value to the beginning of the collection. If the value was already in
    // the list, it is moved to the beginning.
    AddResult prependOrMoveToFirst(ValuePeekInType);

    AddResult insertBefore(ValuePeekInType beforeValue, ValuePeekInType newValue);
    AddResult insertBefore(iterator it, ValuePeekInType newValue) { return m_impl.template add<NodeHashFunctions>(newValue, it.node()); }

    void remove(ValuePeekInType);
    void remove(iterator);
    void clear() { m_impl.clear(); }
    template<typename Collection>
    void removeAll(const Collection& other) { WTF::removeAll(*this, other); }

    void trace(typename Allocator::Visitor* visitor) { m_impl.trace(visitor); }

    int64_t modifications() const { return m_impl.modifications(); }
    void checkModifications(int64_t mods) const { m_impl.checkModifications(mods); }

private:
    Node* anchor() { return reinterpret_cast<Node*>(&m_anchor); }
    const Node* anchor() const { return reinterpret_cast<const Node*>(&m_anchor); }
    Node* firstNode() { return reinterpret_cast<Node*>(m_anchor.m_next); }
    const Node* firstNode() const { return reinterpret_cast<const Node*>(m_anchor.m_next); }
    Node* lastNode() { return reinterpret_cast<Node*>(m_anchor.m_prev); }
    const Node* lastNode() const { return reinterpret_cast<const Node*>(m_anchor.m_prev); }

    iterator makeIterator(const Node* position) { return iterator(position, this); }
    const_iterator makeConstIterator(const Node* position) const { return const_iterator(position, this); }
    reverse_iterator makeReverseIterator(const Node* position) { return reverse_iterator(position, this); }
    const_reverse_iterator makeConstReverseIterator(const Node* position) const { return const_reverse_iterator(position, this); }

    ImplType m_impl;
    NodeBase m_anchor;
};

template<typename Value, typename HashFunctions, typename Allocator>
struct LinkedHashSetTranslator {
    typedef LinkedHashSetNode<Value, Allocator> Node;
    typedef LinkedHashSetNodeBase NodeBase;
    typedef typename HashTraits<Value>::PeekInType ValuePeekInType;
    static unsigned hash(const Node& node) { return HashFunctions::hash(node.m_value); }
    static unsigned hash(const ValuePeekInType& key) { return HashFunctions::hash(key); }
    static bool equal(const Node& a, const ValuePeekInType& b) { return HashFunctions::equal(a.m_value, b); }
    static bool equal(const Node& a, const Node& b) { return HashFunctions::equal(a.m_value, b.m_value); }
    static void translate(Node& location, ValuePeekInType key, NodeBase* anchor)
    {
        anchor->insertBefore(location);
        location.m_value = key;
    }

    // Empty (or deleted) slots have the m_next pointer set to null, but we
    // don't do anything to the other fields, which may contain junk.
    // Therefore you can't compare a newly constructed empty value with a
    // slot and get the right answer.
    static const bool safeToCompareToEmptyOrDeleted = false;
};

template<typename Value, typename Allocator>
struct LinkedHashSetExtractor {
    static const Value& extract(const LinkedHashSetNode<Value, Allocator>& node) { return node.m_value; }
};

template<typename Value, typename ValueTraitsArg, typename Allocator>
struct LinkedHashSetTraits : public SimpleClassHashTraits<LinkedHashSetNode<Value, Allocator> > {
    typedef LinkedHashSetNode<Value, Allocator> Node;
    typedef ValueTraitsArg ValueTraits;

    // The slot is empty when the m_next field is zero so it's safe to zero
    // the backing.
    static const bool emptyValueIsZero = true;

    static const bool hasIsEmptyValueFunction = true;
    static bool isEmptyValue(const Node& node) { return !node.m_next; }

    static const int deletedValue = -1;

    static void constructDeletedValue(Node& slot, bool) { slot.m_next = reinterpret_cast<Node*>(deletedValue); }
    static bool isDeletedValue(const Node& slot) { return slot.m_next == reinterpret_cast<Node*>(deletedValue); }

    // We always need to call destructors, that's how we get linked and
    // unlinked from the chain.
    static const bool needsDestruction = true;

    // Whether we need to trace and do weak processing depends on the traits of
    // the type inside the node.
    template<typename U = void>
    struct NeedsTracingLazily {
        static const bool value = ValueTraits::template NeedsTracingLazily<>::value;
    };
    static const WeakHandlingFlag weakHandlingFlag = ValueTraits::weakHandlingFlag;
};

template<typename LinkedHashSetType>
class LinkedHashSetIterator {
private:
    typedef typename LinkedHashSetType::Node Node;
    typedef typename LinkedHashSetType::Traits Traits;

    typedef typename LinkedHashSetType::Value& ReferenceType;
    typedef typename LinkedHashSetType::Value* PointerType;

    typedef LinkedHashSetConstIterator<LinkedHashSetType> const_iterator;

    Node* node() { return const_cast<Node*>(m_iterator.node()); }

protected:
    LinkedHashSetIterator(const Node* position, LinkedHashSetType* m_container)
        : m_iterator(position , m_container)
    {
    }

public:
    // Default copy, assignment and destructor are OK.

    PointerType get() const { return const_cast<PointerType>(m_iterator.get()); }
    ReferenceType operator*() const { return *get(); }
    PointerType operator->() const { return get(); }

    LinkedHashSetIterator& operator++() { ++m_iterator; return *this; }
    LinkedHashSetIterator& operator--() { --m_iterator; return *this; }

    // Postfix ++ and -- intentionally omitted.

    // Comparison.
    bool operator==(const LinkedHashSetIterator& other) const { return m_iterator == other.m_iterator; }
    bool operator!=(const LinkedHashSetIterator& other) const { return m_iterator != other.m_iterator; }

    operator const_iterator() const { return m_iterator; }

protected:
    const_iterator m_iterator;
    template<typename T, typename U, typename V, typename W> friend class LinkedHashSet;
};

template<typename LinkedHashSetType>
class LinkedHashSetConstIterator {
private:
    typedef typename LinkedHashSetType::Node Node;
    typedef typename LinkedHashSetType::Traits Traits;

    typedef const typename LinkedHashSetType::Value& ReferenceType;
    typedef const typename LinkedHashSetType::Value* PointerType;

    const Node* node() const { return static_cast<const Node*>(m_position); }

protected:
    LinkedHashSetConstIterator(const LinkedHashSetNodeBase* position, const LinkedHashSetType* container)
        : m_position(position)
#if ENABLE(ASSERT)
        , m_container(container)
        , m_containerModifications(container->modifications())
#endif
    {
    }

public:
    PointerType get() const
    {
        checkModifications();
        return &static_cast<const Node*>(m_position)->m_value;
    }
    ReferenceType operator*() const { return *get(); }
    PointerType operator->() const { return get(); }

    LinkedHashSetConstIterator& operator++()
    {
        ASSERT(m_position);
        checkModifications();
        m_position = m_position->m_next;
        return *this;
    }

    LinkedHashSetConstIterator& operator--()
    {
        ASSERT(m_position);
        checkModifications();
        m_position = m_position->m_prev;
        return *this;
    }

    // Postfix ++ and -- intentionally omitted.

    // Comparison.
    bool operator==(const LinkedHashSetConstIterator& other) const
    {
        return m_position == other.m_position;
    }
    bool operator!=(const LinkedHashSetConstIterator& other) const
    {
        return m_position != other.m_position;
    }

private:
    const LinkedHashSetNodeBase* m_position;
#if ENABLE(ASSERT)
    void checkModifications() const { m_container->checkModifications(m_containerModifications); }
    const LinkedHashSetType* m_container;
    int64_t m_containerModifications;
#else
    void checkModifications() const { }
#endif
    template<typename T, typename U, typename V, typename W> friend class LinkedHashSet;
    friend class LinkedHashSetIterator<LinkedHashSetType>;
};

template<typename LinkedHashSetType>
class LinkedHashSetReverseIterator : public LinkedHashSetIterator<LinkedHashSetType> {
    typedef LinkedHashSetIterator<LinkedHashSetType> Superclass;
    typedef LinkedHashSetConstReverseIterator<LinkedHashSetType> const_reverse_iterator;
    typedef typename LinkedHashSetType::Node Node;

protected:
    LinkedHashSetReverseIterator(const Node* position, LinkedHashSetType* container)
        : Superclass(position, container) { }

public:
    LinkedHashSetReverseIterator& operator++() { Superclass::operator--(); return *this; }
    LinkedHashSetReverseIterator& operator--() { Superclass::operator++(); return *this; }

    // Postfix ++ and -- intentionally omitted.

    operator const_reverse_iterator() const { return *reinterpret_cast<const_reverse_iterator*>(this); }

    template<typename T, typename U, typename V, typename W> friend class LinkedHashSet;
};

template<typename LinkedHashSetType>
class LinkedHashSetConstReverseIterator : public LinkedHashSetConstIterator<LinkedHashSetType> {
    typedef LinkedHashSetConstIterator<LinkedHashSetType> Superclass;
    typedef typename LinkedHashSetType::Node Node;

public:
    LinkedHashSetConstReverseIterator(const Node* position, const LinkedHashSetType* container)
        : Superclass(position, container) { }

    LinkedHashSetConstReverseIterator& operator++() { Superclass::operator--(); return *this; }
    LinkedHashSetConstReverseIterator& operator--() { Superclass::operator++(); return *this; }

    // Postfix ++ and -- intentionally omitted.

    template<typename T, typename U, typename V, typename W> friend class LinkedHashSet;
};

template<typename T, typename U, typename V, typename W>
inline LinkedHashSet<T, U, V, W>::LinkedHashSet() { }

template<typename T, typename U, typename V, typename W>
inline LinkedHashSet<T, U, V, W>::LinkedHashSet(const LinkedHashSet& other)
    : m_anchor()
{
    const_iterator end = other.end();
    for (const_iterator it = other.begin(); it != end; ++it)
        add(*it);
}

template<typename T, typename U, typename V, typename W>
inline LinkedHashSet<T, U, V, W>& LinkedHashSet<T, U, V, W>::operator=(const LinkedHashSet& other)
{
    LinkedHashSet tmp(other);
    swap(tmp);
    return *this;
}

template<typename T, typename U, typename V, typename W>
inline void LinkedHashSet<T, U, V, W>::swap(LinkedHashSet& other)
{
    m_impl.swap(other.m_impl);
    swapAnchor(m_anchor, other.m_anchor);
}

template<typename T, typename U, typename V, typename Allocator>
inline LinkedHashSet<T, U, V, Allocator>::~LinkedHashSet()
{
    // The destructor of m_anchor will implicitly be called here, which will
    // unlink the anchor from the collection.
}

template<typename T, typename U, typename V, typename W>
inline T& LinkedHashSet<T, U, V, W>::first()
{
    ASSERT(!isEmpty());
    return firstNode()->m_value;
}

template<typename T, typename U, typename V, typename W>
inline const T& LinkedHashSet<T, U, V, W>::first() const
{
    ASSERT(!isEmpty());
    return firstNode()->m_value;
}

template<typename T, typename U, typename V, typename W>
inline void LinkedHashSet<T, U, V, W>::removeFirst()
{
    ASSERT(!isEmpty());
    m_impl.remove(static_cast<Node*>(m_anchor.m_next));
}

template<typename T, typename U, typename V, typename W>
inline T& LinkedHashSet<T, U, V, W>::last()
{
    ASSERT(!isEmpty());
    return lastNode()->m_value;
}

template<typename T, typename U, typename V, typename W>
inline const T& LinkedHashSet<T, U, V, W>::last() const
{
    ASSERT(!isEmpty());
    return lastNode()->m_value;
}

template<typename T, typename U, typename V, typename W>
inline void LinkedHashSet<T, U, V, W>::removeLast()
{
    ASSERT(!isEmpty());
    m_impl.remove(static_cast<Node*>(m_anchor.m_prev));
}

template<typename T, typename U, typename V, typename W>
inline typename LinkedHashSet<T, U, V, W>::iterator LinkedHashSet<T, U, V, W>::find(ValuePeekInType value)
{
    LinkedHashSet::Node* node = m_impl.template lookup<LinkedHashSet::NodeHashFunctions, ValuePeekInType>(value);
    if (!node)
        return end();
    return makeIterator(node);
}

template<typename T, typename U, typename V, typename W>
inline typename LinkedHashSet<T, U, V, W>::const_iterator LinkedHashSet<T, U, V, W>::find(ValuePeekInType value) const
{
    const LinkedHashSet::Node* node = m_impl.template lookup<LinkedHashSet::NodeHashFunctions, ValuePeekInType>(value);
    if (!node)
        return end();
    return makeConstIterator(node);
}

template<typename Translator>
struct LinkedHashSetTranslatorAdapter {
    template<typename T> static unsigned hash(const T& key) { return Translator::hash(key); }
    template<typename T, typename U> static bool equal(const T& a, const U& b) { return Translator::equal(a.m_value, b); }
};

template<typename Value, typename U, typename V, typename W>
template<typename HashTranslator, typename T>
inline typename LinkedHashSet<Value, U, V, W>::iterator LinkedHashSet<Value, U, V, W>::find(const T& value)
{
    typedef LinkedHashSetTranslatorAdapter<HashTranslator> TranslatedFunctions;
    const LinkedHashSet::Node* node = m_impl.template lookup<TranslatedFunctions, const T&>(value);
    if (!node)
        return end();
    return makeIterator(node);
}

template<typename Value, typename U, typename V, typename W>
template<typename HashTranslator, typename T>
inline typename LinkedHashSet<Value, U, V, W>::const_iterator LinkedHashSet<Value, U, V, W>::find(const T& value) const
{
    typedef LinkedHashSetTranslatorAdapter<HashTranslator> TranslatedFunctions;
    const LinkedHashSet::Node* node = m_impl.template lookup<TranslatedFunctions, const T&>(value);
    if (!node)
        return end();
    return makeConstIterator(node);
}

template<typename Value, typename U, typename V, typename W>
template<typename HashTranslator, typename T>
inline bool LinkedHashSet<Value, U, V, W>::contains(const T& value) const
{
    return m_impl.template contains<LinkedHashSetTranslatorAdapter<HashTranslator> >(value);
}

template<typename T, typename U, typename V, typename W>
inline bool LinkedHashSet<T, U, V, W>::contains(ValuePeekInType value) const
{
    return m_impl.template contains<NodeHashFunctions>(value);
}

template<typename Value, typename HashFunctions, typename Traits, typename Allocator>
typename LinkedHashSet<Value, HashFunctions, Traits, Allocator>::AddResult LinkedHashSet<Value, HashFunctions, Traits, Allocator>::add(ValuePeekInType value)
{
    return m_impl.template add<NodeHashFunctions>(value, &m_anchor);
}

template<typename T, typename U, typename V, typename W>
typename LinkedHashSet<T, U, V, W>::iterator LinkedHashSet<T, U, V, W>::addReturnIterator(ValuePeekInType value)
{
    typename ImplType::AddResult result = m_impl.template add<NodeHashFunctions>(value, &m_anchor);
    return makeIterator(result.storedValue);
}

template<typename T, typename U, typename V, typename W>
typename LinkedHashSet<T, U, V, W>::AddResult LinkedHashSet<T, U, V, W>::appendOrMoveToLast(ValuePeekInType value)
{
    typename ImplType::AddResult result = m_impl.template add<NodeHashFunctions>(value, &m_anchor);
    Node* node = result.storedValue;
    if (!result.isNewEntry) {
        node->unlink();
        m_anchor.insertBefore(*node);
    }
    return result;
}

template<typename T, typename U, typename V, typename W>
typename LinkedHashSet<T, U, V, W>::AddResult LinkedHashSet<T, U, V, W>::prependOrMoveToFirst(ValuePeekInType value)
{
    typename ImplType::AddResult result = m_impl.template add<NodeHashFunctions>(value, m_anchor.m_next);
    Node* node = result.storedValue;
    if (!result.isNewEntry) {
        node->unlink();
        m_anchor.insertAfter(*node);
    }
    return result;
}

template<typename T, typename U, typename V, typename W>
typename LinkedHashSet<T, U, V, W>::AddResult LinkedHashSet<T, U, V, W>::insertBefore(ValuePeekInType beforeValue, ValuePeekInType newValue)
{
    return insertBefore(find(beforeValue), newValue);
}

template<typename T, typename U, typename V, typename W>
inline void LinkedHashSet<T, U, V, W>::remove(iterator it)
{
    if (it == end())
        return;
    m_impl.remove(it.node());
}

template<typename T, typename U, typename V, typename W>
inline void LinkedHashSet<T, U, V, W>::remove(ValuePeekInType value)
{
    remove(find(value));
}

inline void swapAnchor(LinkedHashSetNodeBase& a, LinkedHashSetNodeBase& b)
{
    ASSERT(a.m_prev && a.m_next && b.m_prev && b.m_next);
    swap(a.m_prev, b.m_prev);
    swap(a.m_next, b.m_next);
    if (b.m_next == &a) {
        ASSERT(b.m_prev == &a);
        b.m_next = &b;
        b.m_prev = &b;
    } else {
        b.m_next->m_prev = &b;
        b.m_prev->m_next = &b;
    }
    if (a.m_next == &b) {
        ASSERT(a.m_prev == &b);
        a.m_next = &a;
        a.m_prev = &a;
    } else {
        a.m_next->m_prev = &a;
        a.m_prev->m_next = &a;
    }
}

inline void swap(LinkedHashSetNodeBase& a, LinkedHashSetNodeBase& b)
{
    ASSERT(a.m_next != &a && b.m_next != &b);
    swap(a.m_prev, b.m_prev);
    swap(a.m_next, b.m_next);
    if (b.m_next) {
        b.m_next->m_prev = &b;
        b.m_prev->m_next = &b;
    }
    if (a.m_next) {
        a.m_next->m_prev = &a;
        a.m_prev->m_next = &a;
    }
}

template<typename T, typename Allocator>
inline void swap(LinkedHashSetNode<T, Allocator>& a, LinkedHashSetNode<T, Allocator>& b)
{
    typedef LinkedHashSetNodeBase Base;
    Allocator::enterNoAllocationScope();
    swap(static_cast<Base&>(a), static_cast<Base&>(b));
    swap(a.m_value, b.m_value);
    Allocator::leaveNoAllocationScope();
}

// Warning: After and while calling this you have a collection with deleted
// pointers. Consider using a smart pointer like OwnPtr and calling clear()
// instead.
template<typename ValueType, typename T, typename U>
void deleteAllValues(const LinkedHashSet<ValueType, T, U>& set)
{
    typedef typename LinkedHashSet<ValueType, T, U>::const_iterator iterator;
    iterator end = set.end();
    for (iterator it = set.begin(); it != end; ++it)
        delete *it;
}

#if !ENABLE(OILPAN)
template<typename T, typename U, typename V>
struct NeedsTracing<LinkedHashSet<T, U, V> > {
    static const bool value = false;
};
#endif

}

using WTF::LinkedHashSet;

#endif /* WTF_LinkedHashSet_h */
