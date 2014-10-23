/*
 * Copyright (C) 2005, 2006, 2007, 2008, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008 David Levin <levin@chromium.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef WTF_HashTable_h
#define WTF_HashTable_h

#include "wtf/Alignment.h"
#include "wtf/Assertions.h"
#include "wtf/DefaultAllocator.h"
#include "wtf/HashTraits.h"
#include "wtf/WTF.h"

#define DUMP_HASHTABLE_STATS 0
#define DUMP_HASHTABLE_STATS_PER_TABLE 0

#if DUMP_HASHTABLE_STATS_PER_TABLE
#include "wtf/DataLog.h"
#endif

#if DUMP_HASHTABLE_STATS
#if DUMP_HASHTABLE_STATS_PER_TABLE
#define UPDATE_PROBE_COUNTS()                            \
    ++probeCount;                                        \
    HashTableStats::recordCollisionAtCount(probeCount);  \
    ++perTableProbeCount;                                \
    m_stats->recordCollisionAtCount(perTableProbeCount)
#define UPDATE_ACCESS_COUNTS()                           \
    atomicIncrement(&HashTableStats::numAccesses);       \
    int probeCount = 0;                                  \
    ++m_stats->numAccesses;                              \
    int perTableProbeCount = 0
#else
#define UPDATE_PROBE_COUNTS()                            \
    ++probeCount;                                        \
    HashTableStats::recordCollisionAtCount(probeCount)
#define UPDATE_ACCESS_COUNTS()                           \
    atomicIncrement(&HashTableStats::numAccesses);       \
    int probeCount = 0
#endif
#else
#if DUMP_HASHTABLE_STATS_PER_TABLE
#define UPDATE_PROBE_COUNTS()                            \
    ++perTableProbeCount;                                \
    m_stats->recordCollisionAtCount(perTableProbeCount)
#define UPDATE_ACCESS_COUNTS()                           \
    ++m_stats->numAccesses;                              \
    int perTableProbeCount = 0
#else
#define UPDATE_PROBE_COUNTS() do { } while (0)
#define UPDATE_ACCESS_COUNTS() do { } while (0)
#endif
#endif

namespace WTF {

#if DUMP_HASHTABLE_STATS

    struct HashTableStats {
        // The following variables are all atomically incremented when modified.
        static int numAccesses;
        static int numRehashes;
        static int numRemoves;
        static int numReinserts;

        // The following variables are only modified in the recordCollisionAtCount method within a mutex.
        static int maxCollisions;
        static int numCollisions;
        static int collisionGraph[4096];

        static void recordCollisionAtCount(int count);
        static void dumpStats();
    };

#endif

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    class HashTable;
    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    class HashTableIterator;
    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    class HashTableConstIterator;
    template<typename Value, typename HashFunctions, typename HashTraits, typename Allocator>
    class LinkedHashSet;
    template<WeakHandlingFlag x, typename T, typename U, typename V, typename W, typename X, typename Y, typename Z>
    struct WeakProcessingHashTableHelper;

    typedef enum { HashItemKnownGood } HashItemKnownGoodTag;

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    class HashTableConstIterator {
    private:
        typedef HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> HashTableType;
        typedef HashTableIterator<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> iterator;
        typedef HashTableConstIterator<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> const_iterator;
        typedef Value ValueType;
        typedef typename Traits::IteratorConstGetType GetType;
        typedef const ValueType* PointerType;

        friend class HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>;
        friend class HashTableIterator<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>;

        void skipEmptyBuckets()
        {
            while (m_position != m_endPosition && HashTableType::isEmptyOrDeletedBucket(*m_position))
                ++m_position;
        }

        HashTableConstIterator(PointerType position, PointerType endPosition, const HashTableType* container)
            : m_position(position)
            , m_endPosition(endPosition)
#if ENABLE(ASSERT)
            , m_container(container)
            , m_containerModifications(container->modifications())
#endif
        {
            skipEmptyBuckets();
        }

        HashTableConstIterator(PointerType position, PointerType endPosition, const HashTableType* container, HashItemKnownGoodTag)
            : m_position(position)
            , m_endPosition(endPosition)
#if ENABLE(ASSERT)
            , m_container(container)
            , m_containerModifications(container->modifications())
#endif
        {
            ASSERT(m_containerModifications == m_container->modifications());
        }

        void checkModifications() const
        {
            // HashTable and collections that build on it do not support
            // modifications while there is an iterator in use. The exception
            // is ListHashSet, which has its own iterators that tolerate
            // modification of the underlying set.
            ASSERT(m_containerModifications == m_container->modifications());
        }

    public:
        HashTableConstIterator()
        {
        }

        GetType get() const
        {
            checkModifications();
            return m_position;
        }
        typename Traits::IteratorConstReferenceType operator*() const { return Traits::getToReferenceConstConversion(get()); }
        GetType operator->() const { return get(); }

        const_iterator& operator++()
        {
            ASSERT(m_position != m_endPosition);
            checkModifications();
            ++m_position;
            skipEmptyBuckets();
            return *this;
        }

        // postfix ++ intentionally omitted

        // Comparison.
        bool operator==(const const_iterator& other) const
        {
            return m_position == other.m_position;
        }
        bool operator!=(const const_iterator& other) const
        {
            return m_position != other.m_position;
        }
        bool operator==(const iterator& other) const
        {
            return *this == static_cast<const_iterator>(other);
        }
        bool operator!=(const iterator& other) const
        {
            return *this != static_cast<const_iterator>(other);
        }

    private:
        PointerType m_position;
        PointerType m_endPosition;
#if ENABLE(ASSERT)
        const HashTableType* m_container;
        int64_t m_containerModifications;
#endif
    };

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    class HashTableIterator {
    private:
        typedef HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> HashTableType;
        typedef HashTableIterator<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> iterator;
        typedef HashTableConstIterator<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> const_iterator;
        typedef Value ValueType;
        typedef typename Traits::IteratorGetType GetType;
        typedef ValueType* PointerType;

        friend class HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>;

        HashTableIterator(PointerType pos, PointerType end, const HashTableType* container) : m_iterator(pos, end, container) { }
        HashTableIterator(PointerType pos, PointerType end, const HashTableType* container, HashItemKnownGoodTag tag) : m_iterator(pos, end, container, tag) { }

    public:
        HashTableIterator() { }

        // default copy, assignment and destructor are OK

        GetType get() const { return const_cast<GetType>(m_iterator.get()); }
        typename Traits::IteratorReferenceType operator*() const { return Traits::getToReferenceConversion(get()); }
        GetType operator->() const { return get(); }

        iterator& operator++() { ++m_iterator; return *this; }

        // postfix ++ intentionally omitted

        // Comparison.
        bool operator==(const iterator& other) const { return m_iterator == other.m_iterator; }
        bool operator!=(const iterator& other) const { return m_iterator != other.m_iterator; }
        bool operator==(const const_iterator& other) const { return m_iterator == other; }
        bool operator!=(const const_iterator& other) const { return m_iterator != other; }

        operator const_iterator() const { return m_iterator; }

    private:
        const_iterator m_iterator;
    };

    using std::swap;

    // Work around MSVC's standard library, whose swap for pairs does not swap by component.
    template<typename T> inline void hashTableSwap(T& a, T& b)
    {
        swap(a, b);
    }

    template<typename T, typename U> inline void hashTableSwap(KeyValuePair<T, U>& a, KeyValuePair<T, U>& b)
    {
        swap(a.key, b.key);
        swap(a.value, b.value);
    }

    template<typename T, typename Allocator, bool useSwap> struct Mover;
    template<typename T, typename Allocator> struct Mover<T, Allocator, true> {
        static void move(T& from, T& to)
        {
            // A swap operation should not normally allocate, but it may do so
            // if it is falling back on some sort of triple assignment in the
            // style of t = a; a = b; b = t because there is no overloaded swap
            // operation. We can't allow allocation both because it is slower
            // than a true swap operation, but also because allocation implies
            // allowing GC: We cannot allow a GC after swapping only the key.
            // The value is only traced if the key is present and therefore the
            // GC will not see the value in the old backing if the key has been
            // moved to the new backing. Therefore, we cannot allow GC until
            // after both key and value have been moved.
            Allocator::enterNoAllocationScope();
            hashTableSwap(from, to);
            Allocator::leaveNoAllocationScope();
        }
    };
    template<typename T, typename Allocator> struct Mover<T, Allocator, false> {
        static void move(T& from, T& to) { to = from; }
    };

    template<typename HashFunctions> class IdentityHashTranslator {
    public:
        template<typename T> static unsigned hash(const T& key) { return HashFunctions::hash(key); }
        template<typename T, typename U> static bool equal(const T& a, const U& b) { return HashFunctions::equal(a, b); }
        template<typename T, typename U, typename V> static void translate(T& location, const U&, const V& value) { location = value; }
    };

    template<typename HashTableType, typename ValueType> struct HashTableAddResult {
        HashTableAddResult(const HashTableType* container, ValueType* storedValue, bool isNewEntry)
            : storedValue(storedValue)
            , isNewEntry(isNewEntry)
#if ENABLE(SECURITY_ASSERT)
            , m_container(container)
            , m_containerModifications(container->modifications())
#endif
        {
            ASSERT_UNUSED(container, container);
        }

        ~HashTableAddResult()
        {
            // If rehash happened before accessing storedValue, it's
            // use-after-free. Any modification may cause a rehash, so we check
            // for modifications here.
            // Rehash after accessing storedValue is harmless but will assert if
            // the AddResult destructor takes place after a modification. You
            // may need to limit the scope of the AddResult.
            ASSERT_WITH_SECURITY_IMPLICATION(m_containerModifications == m_container->modifications());
        }

        ValueType* storedValue;
        bool isNewEntry;

#if ENABLE(SECURITY_ASSERT)
    private:
        const HashTableType* m_container;
        const int64_t m_containerModifications;
#endif
    };

    template<typename Value, typename Extractor, typename KeyTraits>
    struct HashTableHelper {
        static bool isEmptyBucket(const Value& value) { return isHashTraitsEmptyValue<KeyTraits>(Extractor::extract(value)); }
        static bool isDeletedBucket(const Value& value) { return KeyTraits::isDeletedValue(Extractor::extract(value)); }
        static bool isEmptyOrDeletedBucket(const Value& value) { return isEmptyBucket(value) || isDeletedBucket(value); }
    };

    template<typename HashTranslator, typename KeyTraits, bool safeToCompareToEmptyOrDeleted>
    struct HashTableKeyChecker {
        // There's no simple generic way to make this check if safeToCompareToEmptyOrDeleted is false,
        // so the check always passes.
        template <typename T>
        static bool checkKey(const T&) { return true; }
    };

    template<typename HashTranslator, typename KeyTraits>
    struct HashTableKeyChecker<HashTranslator, KeyTraits, true> {
        template <typename T>
        static bool checkKey(const T& key)
        {
            // FIXME : Check also equality to the deleted value.
            return !HashTranslator::equal(KeyTraits::emptyValue(), key);
        }
    };

    // Don't declare a destructor for HeapAllocated hash tables.
    template<typename Derived, bool isGarbageCollected>
    class HashTableDestructorBase;

    template<typename Derived>
    class HashTableDestructorBase<Derived, true> { };

    template<typename Derived>
    class HashTableDestructorBase<Derived, false> {
    public:
        ~HashTableDestructorBase() { static_cast<Derived*>(this)->finalize(); }
    };

    // Note: empty or deleted key values are not allowed, using them may lead to undefined behavior.
    // For pointer keys this means that null pointers are not allowed unless you supply custom key traits.
    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    class HashTable : public HashTableDestructorBase<HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>, Allocator::isGarbageCollected> {
    public:
        typedef HashTableIterator<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> iterator;
        typedef HashTableConstIterator<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> const_iterator;
        typedef Traits ValueTraits;
        typedef Key KeyType;
        typedef typename KeyTraits::PeekInType KeyPeekInType;
        typedef typename KeyTraits::PassInType KeyPassInType;
        typedef Value ValueType;
        typedef Extractor ExtractorType;
        typedef KeyTraits KeyTraitsType;
        typedef typename Traits::PassInType ValuePassInType;
        typedef IdentityHashTranslator<HashFunctions> IdentityTranslatorType;
        typedef HashTableAddResult<HashTable, ValueType> AddResult;

#if DUMP_HASHTABLE_STATS_PER_TABLE
        struct Stats {
            Stats()
                : numAccesses(0)
                , numRehashes(0)
                , numRemoves(0)
                , numReinserts(0)
                , maxCollisions(0)
                , numCollisions(0)
                , collisionGraph()
            {
            }

            int numAccesses;
            int numRehashes;
            int numRemoves;
            int numReinserts;

            int maxCollisions;
            int numCollisions;
            int collisionGraph[4096];

            void recordCollisionAtCount(int count)
            {
                if (count > maxCollisions)
                    maxCollisions = count;
                numCollisions++;
                collisionGraph[count]++;
            }

            void dumpStats()
            {
                dataLogF("\nWTF::HashTable::Stats dump\n\n");
                dataLogF("%d accesses\n", numAccesses);
                dataLogF("%d total collisions, average %.2f probes per access\n", numCollisions, 1.0 * (numAccesses + numCollisions) / numAccesses);
                dataLogF("longest collision chain: %d\n", maxCollisions);
                for (int i = 1; i <= maxCollisions; i++) {
                    dataLogF("  %d lookups with exactly %d collisions (%.2f%% , %.2f%% with this many or more)\n", collisionGraph[i], i, 100.0 * (collisionGraph[i] - collisionGraph[i+1]) / numAccesses, 100.0 * collisionGraph[i] / numAccesses);
                }
                dataLogF("%d rehashes\n", numRehashes);
                dataLogF("%d reinserts\n", numReinserts);
            }
        };
#endif

        HashTable();
        void finalize()
        {
            ASSERT(!Allocator::isGarbageCollected);
            if (LIKELY(!m_table))
                return;
            deleteAllBucketsAndDeallocate(m_table, m_tableSize);
            m_table = 0;
        }

        HashTable(const HashTable&);
        void swap(HashTable&);
        HashTable& operator=(const HashTable&);

        // When the hash table is empty, just return the same iterator for end as for begin.
        // This is more efficient because we don't have to skip all the empty and deleted
        // buckets, and iterating an empty table is a common case that's worth optimizing.
        iterator begin() { return isEmpty() ? end() : makeIterator(m_table); }
        iterator end() { return makeKnownGoodIterator(m_table + m_tableSize); }
        const_iterator begin() const { return isEmpty() ? end() : makeConstIterator(m_table); }
        const_iterator end() const { return makeKnownGoodConstIterator(m_table + m_tableSize); }

        unsigned size() const { return m_keyCount; }
        unsigned capacity() const { return m_tableSize; }
        bool isEmpty() const { return !m_keyCount; }

        AddResult add(ValuePassInType value)
        {
            return add<IdentityTranslatorType>(Extractor::extract(value), value);
        }

        // A special version of add() that finds the object by hashing and comparing
        // with some other type, to avoid the cost of type conversion if the object is already
        // in the table.
        template<typename HashTranslator, typename T, typename Extra> AddResult add(const T& key, const Extra&);
        template<typename HashTranslator, typename T, typename Extra> AddResult addPassingHashCode(const T& key, const Extra&);

        iterator find(KeyPeekInType key) { return find<IdentityTranslatorType>(key); }
        const_iterator find(KeyPeekInType key) const { return find<IdentityTranslatorType>(key); }
        bool contains(KeyPeekInType key) const { return contains<IdentityTranslatorType>(key); }

        template<typename HashTranslator, typename T> iterator find(const T&);
        template<typename HashTranslator, typename T> const_iterator find(const T&) const;
        template<typename HashTranslator, typename T> bool contains(const T&) const;

        void remove(KeyPeekInType);
        void remove(iterator);
        void remove(const_iterator);
        void clear();

        static bool isEmptyBucket(const ValueType& value) { return isHashTraitsEmptyValue<KeyTraits>(Extractor::extract(value)); }
        static bool isDeletedBucket(const ValueType& value) { return KeyTraits::isDeletedValue(Extractor::extract(value)); }
        static bool isEmptyOrDeletedBucket(const ValueType& value) { return HashTableHelper<ValueType, Extractor, KeyTraits>:: isEmptyOrDeletedBucket(value); }

        ValueType* lookup(KeyPeekInType key) { return lookup<IdentityTranslatorType, KeyPeekInType>(key); }
        template<typename HashTranslator, typename T> ValueType* lookup(T);
        template<typename HashTranslator, typename T> const ValueType* lookup(T) const;

        void trace(typename Allocator::Visitor*);

#if ENABLE(ASSERT)
        int64_t modifications() const { return m_modifications; }
        void registerModification() { m_modifications++; }
        // HashTable and collections that build on it do not support
        // modifications while there is an iterator in use. The exception is
        // ListHashSet, which has its own iterators that tolerate modification
        // of the underlying set.
        void checkModifications(int64_t mods) const { ASSERT(mods == m_modifications); }
#else
        int64_t modifications() const { return 0; }
        void registerModification() { }
        void checkModifications(int64_t mods) const { }
#endif

    private:
        static ValueType* allocateTable(unsigned size);
        static void deleteAllBucketsAndDeallocate(ValueType* table, unsigned size);

        typedef std::pair<ValueType*, bool> LookupType;
        typedef std::pair<LookupType, unsigned> FullLookupType;

        LookupType lookupForWriting(const Key& key) { return lookupForWriting<IdentityTranslatorType>(key); };
        template<typename HashTranslator, typename T> FullLookupType fullLookupForWriting(const T&);
        template<typename HashTranslator, typename T> LookupType lookupForWriting(const T&);

        void remove(ValueType*);

        bool shouldExpand() const { return (m_keyCount + m_deletedCount) * m_maxLoad >= m_tableSize; }
        bool mustRehashInPlace() const { return m_keyCount * m_minLoad < m_tableSize * 2; }
        bool shouldShrink() const
        {
            // isAllocationAllowed check should be at the last because it's
            // expensive.
            return m_keyCount * m_minLoad < m_tableSize
                && m_tableSize > KeyTraits::minimumTableSize
                && Allocator::isAllocationAllowed();
        }
        ValueType* expand(ValueType* entry = 0);
        void shrink() { rehash(m_tableSize / 2, 0); }

        ValueType* rehash(unsigned newTableSize, ValueType* entry);
        ValueType* reinsert(ValueType&);

        static void initializeBucket(ValueType& bucket);
        static void deleteBucket(ValueType& bucket) { bucket.~ValueType(); Traits::constructDeletedValue(bucket, Allocator::isGarbageCollected); }

        FullLookupType makeLookupResult(ValueType* position, bool found, unsigned hash)
            { return FullLookupType(LookupType(position, found), hash); }

        iterator makeIterator(ValueType* pos) { return iterator(pos, m_table + m_tableSize, this); }
        const_iterator makeConstIterator(ValueType* pos) const { return const_iterator(pos, m_table + m_tableSize, this); }
        iterator makeKnownGoodIterator(ValueType* pos) { return iterator(pos, m_table + m_tableSize, this, HashItemKnownGood); }
        const_iterator makeKnownGoodConstIterator(ValueType* pos) const { return const_iterator(pos, m_table + m_tableSize, this, HashItemKnownGood); }

        static const unsigned m_maxLoad = 2;
        static const unsigned m_minLoad = 6;

        unsigned tableSizeMask() const
        {
            size_t mask = m_tableSize - 1;
            ASSERT((mask & m_tableSize) == 0);
            return mask;
        }

        void setEnqueued() { m_queueFlag = true; }
        void clearEnqueued() { m_queueFlag = false; }
        bool enqueued() { return m_queueFlag; }

        ValueType* m_table;
        unsigned m_tableSize;
        unsigned m_keyCount;
        unsigned m_deletedCount:31;
        bool m_queueFlag:1;
#if ENABLE(ASSERT)
        unsigned m_modifications;
#endif

#if DUMP_HASHTABLE_STATS_PER_TABLE
    public:
        mutable OwnPtr<Stats> m_stats;
#endif

        template<WeakHandlingFlag x, typename T, typename U, typename V, typename W, typename X, typename Y, typename Z> friend struct WeakProcessingHashTableHelper;
        template<typename T, typename U, typename V, typename W> friend class LinkedHashSet;
    };

    // Set all the bits to one after the most significant bit: 00110101010 -> 00111111111.
    template<unsigned size> struct OneifyLowBits;
    template<>
    struct OneifyLowBits<0> {
        static const unsigned value = 0;
    };
    template<unsigned number>
    struct OneifyLowBits {
        static const unsigned value = number | OneifyLowBits<(number >> 1)>::value;
    };
    // Compute the first power of two integer that is an upper bound of the parameter 'number'.
    template<unsigned number>
    struct UpperPowerOfTwoBound {
        static const unsigned value = (OneifyLowBits<number - 1>::value + 1) * 2;
    };

    // Because power of two numbers are the limit of maxLoad, their capacity is twice the
    // UpperPowerOfTwoBound, or 4 times their values.
    template<unsigned size, bool isPowerOfTwo> struct HashTableCapacityForSizeSplitter;
    template<unsigned size>
    struct HashTableCapacityForSizeSplitter<size, true> {
        static const unsigned value = size * 4;
    };
    template<unsigned size>
    struct HashTableCapacityForSizeSplitter<size, false> {
        static const unsigned value = UpperPowerOfTwoBound<size>::value;
    };

    // HashTableCapacityForSize computes the upper power of two capacity to hold the size parameter.
    // This is done at compile time to initialize the HashTraits.
    template<unsigned size>
    struct HashTableCapacityForSize {
        static const unsigned value = HashTableCapacityForSizeSplitter<size, !(size & (size - 1))>::value;
        COMPILE_ASSERT(size > 0, HashTableNonZeroMinimumCapacity);
        COMPILE_ASSERT(!static_cast<int>(value >> 31), HashTableNoCapacityOverflow);
        COMPILE_ASSERT(value > (2 * size), HashTableCapacityHoldsContentSize);
    };

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    inline HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::HashTable()
        : m_table(0)
        , m_tableSize(0)
        , m_keyCount(0)
        , m_deletedCount(0)
        , m_queueFlag(false)
#if ENABLE(ASSERT)
        , m_modifications(0)
#endif
#if DUMP_HASHTABLE_STATS_PER_TABLE
        , m_stats(adoptPtr(new Stats))
#endif
    {
    }

    inline unsigned doubleHash(unsigned key)
    {
        key = ~key + (key >> 23);
        key ^= (key << 12);
        key ^= (key >> 7);
        key ^= (key << 2);
        key ^= (key >> 20);
        return key;
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template<typename HashTranslator, typename T>
    inline Value* HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::lookup(T key)
    {
        return const_cast<Value*>(const_cast<const HashTable*>(this)->lookup<HashTranslator, T>(key));
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template<typename HashTranslator, typename T>
    inline const Value* HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::lookup(T key) const
    {
        ASSERT((HashTableKeyChecker<HashTranslator, KeyTraits, HashFunctions::safeToCompareToEmptyOrDeleted>::checkKey(key)));
        const ValueType* table = m_table;
        if (!table)
            return 0;

        size_t k = 0;
        size_t sizeMask = tableSizeMask();
        unsigned h = HashTranslator::hash(key);
        size_t i = h & sizeMask;

        UPDATE_ACCESS_COUNTS();

        while (1) {
            const ValueType* entry = table + i;

            if (HashFunctions::safeToCompareToEmptyOrDeleted) {
                if (HashTranslator::equal(Extractor::extract(*entry), key))
                    return entry;

                if (isEmptyBucket(*entry))
                    return 0;
            } else {
                if (isEmptyBucket(*entry))
                    return 0;

                if (!isDeletedBucket(*entry) && HashTranslator::equal(Extractor::extract(*entry), key))
                    return entry;
            }
            UPDATE_PROBE_COUNTS();
            if (!k)
                k = 1 | doubleHash(h);
            i = (i + k) & sizeMask;
        }
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template<typename HashTranslator, typename T>
    inline typename HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::LookupType HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::lookupForWriting(const T& key)
    {
        ASSERT(m_table);
        registerModification();

        ValueType* table = m_table;
        size_t k = 0;
        size_t sizeMask = tableSizeMask();
        unsigned h = HashTranslator::hash(key);
        size_t i = h & sizeMask;

        UPDATE_ACCESS_COUNTS();

        ValueType* deletedEntry = 0;

        while (1) {
            ValueType* entry = table + i;

            if (isEmptyBucket(*entry))
                return LookupType(deletedEntry ? deletedEntry : entry, false);

            if (HashFunctions::safeToCompareToEmptyOrDeleted) {
                if (HashTranslator::equal(Extractor::extract(*entry), key))
                    return LookupType(entry, true);

                if (isDeletedBucket(*entry))
                    deletedEntry = entry;
            } else {
                if (isDeletedBucket(*entry))
                    deletedEntry = entry;
                else if (HashTranslator::equal(Extractor::extract(*entry), key))
                    return LookupType(entry, true);
            }
            UPDATE_PROBE_COUNTS();
            if (!k)
                k = 1 | doubleHash(h);
            i = (i + k) & sizeMask;
        }
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template<typename HashTranslator, typename T>
    inline typename HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::FullLookupType HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::fullLookupForWriting(const T& key)
    {
        ASSERT(m_table);
        registerModification();

        ValueType* table = m_table;
        size_t k = 0;
        size_t sizeMask = tableSizeMask();
        unsigned h = HashTranslator::hash(key);
        size_t i = h & sizeMask;

        UPDATE_ACCESS_COUNTS();

        ValueType* deletedEntry = 0;

        while (1) {
            ValueType* entry = table + i;

            if (isEmptyBucket(*entry))
                return makeLookupResult(deletedEntry ? deletedEntry : entry, false, h);

            if (HashFunctions::safeToCompareToEmptyOrDeleted) {
                if (HashTranslator::equal(Extractor::extract(*entry), key))
                    return makeLookupResult(entry, true, h);

                if (isDeletedBucket(*entry))
                    deletedEntry = entry;
            } else {
                if (isDeletedBucket(*entry))
                    deletedEntry = entry;
                else if (HashTranslator::equal(Extractor::extract(*entry), key))
                    return makeLookupResult(entry, true, h);
            }
            UPDATE_PROBE_COUNTS();
            if (!k)
                k = 1 | doubleHash(h);
            i = (i + k) & sizeMask;
        }
    }

    template<bool emptyValueIsZero> struct HashTableBucketInitializer;

    template<> struct HashTableBucketInitializer<false> {
        template<typename Traits, typename Value> static void initialize(Value& bucket)
        {
            new (NotNull, &bucket) Value(Traits::emptyValue());
        }
    };

    template<> struct HashTableBucketInitializer<true> {
        template<typename Traits, typename Value> static void initialize(Value& bucket)
        {
            // This initializes the bucket without copying the empty value.
            // That makes it possible to use this with types that don't support copying.
            // The memset to 0 looks like a slow operation but is optimized by the compilers.
            memset(&bucket, 0, sizeof(bucket));
        }
    };

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    inline void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::initializeBucket(ValueType& bucket)
    {
        // For hash maps the key and value cannot be initialied simultaneously,
        // and it would be wrong to have a GC when only one was initialized and
        // the other still contained garbage (eg. from a previous use of the
        // same slot). Therefore we forbid allocation (and thus GC) while the
        // slot is initalized to an empty value.
        Allocator::enterNoAllocationScope();
        HashTableBucketInitializer<Traits::emptyValueIsZero>::template initialize<Traits>(bucket);
        Allocator::leaveNoAllocationScope();
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template<typename HashTranslator, typename T, typename Extra>
    typename HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::AddResult HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::add(const T& key, const Extra& extra)
    {
        ASSERT(Allocator::isAllocationAllowed());
        if (!m_table)
            expand();

        ASSERT(m_table);

        ValueType* table = m_table;
        size_t k = 0;
        size_t sizeMask = tableSizeMask();
        unsigned h = HashTranslator::hash(key);
        size_t i = h & sizeMask;

        UPDATE_ACCESS_COUNTS();

        ValueType* deletedEntry = 0;
        ValueType* entry;
        while (1) {
            entry = table + i;

            if (isEmptyBucket(*entry))
                break;

            if (HashFunctions::safeToCompareToEmptyOrDeleted) {
                if (HashTranslator::equal(Extractor::extract(*entry), key))
                    return AddResult(this, entry, false);

                if (isDeletedBucket(*entry))
                    deletedEntry = entry;
            } else {
                if (isDeletedBucket(*entry))
                    deletedEntry = entry;
                else if (HashTranslator::equal(Extractor::extract(*entry), key))
                    return AddResult(this, entry, false);
            }
            UPDATE_PROBE_COUNTS();
            if (!k)
                k = 1 | doubleHash(h);
            i = (i + k) & sizeMask;
        }

        registerModification();

        if (deletedEntry) {
            // Overwrite any data left over from last use, using placement new
            // or memset.
            initializeBucket(*deletedEntry);
            entry = deletedEntry;
            --m_deletedCount;
        }

        HashTranslator::translate(*entry, key, extra);
        ASSERT(!isEmptyOrDeletedBucket(*entry));

        ++m_keyCount;

        if (shouldExpand())
            entry = expand(entry);

        return AddResult(this, entry, true);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template<typename HashTranslator, typename T, typename Extra>
    typename HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::AddResult HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::addPassingHashCode(const T& key, const Extra& extra)
    {
        ASSERT(Allocator::isAllocationAllowed());
        if (!m_table)
            expand();

        FullLookupType lookupResult = fullLookupForWriting<HashTranslator>(key);

        ValueType* entry = lookupResult.first.first;
        bool found = lookupResult.first.second;
        unsigned h = lookupResult.second;

        if (found)
            return AddResult(this, entry, false);

        registerModification();

        if (isDeletedBucket(*entry)) {
            initializeBucket(*entry);
            --m_deletedCount;
        }

        HashTranslator::translate(*entry, key, extra, h);
        ASSERT(!isEmptyOrDeletedBucket(*entry));

        ++m_keyCount;
        if (shouldExpand())
            entry = expand(entry);

        return AddResult(this, entry, true);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    Value* HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::reinsert(ValueType& entry)
    {
        ASSERT(m_table);
        registerModification();
        ASSERT(!lookupForWriting(Extractor::extract(entry)).second);
        ASSERT(!isDeletedBucket(*(lookupForWriting(Extractor::extract(entry)).first)));
#if DUMP_HASHTABLE_STATS
        atomicIncrement(&HashTableStats::numReinserts);
#endif
#if DUMP_HASHTABLE_STATS_PER_TABLE
        ++m_stats->numReinserts;
#endif
        Value* newEntry = lookupForWriting(Extractor::extract(entry)).first;
        Mover<ValueType, Allocator, Traits::needsDestruction>::move(entry, *newEntry);

        return newEntry;
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template <typename HashTranslator, typename T>
    inline typename HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::iterator HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::find(const T& key)
    {
        ValueType* entry = lookup<HashTranslator>(key);
        if (!entry)
            return end();

        return makeKnownGoodIterator(entry);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template <typename HashTranslator, typename T>
    inline typename HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::const_iterator HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::find(const T& key) const
    {
        ValueType* entry = const_cast<HashTable*>(this)->lookup<HashTranslator>(key);
        if (!entry)
            return end();

        return makeKnownGoodConstIterator(entry);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    template <typename HashTranslator, typename T>
    bool HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::contains(const T& key) const
    {
        return const_cast<HashTable*>(this)->lookup<HashTranslator>(key);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::remove(ValueType* pos)
    {
        registerModification();
#if DUMP_HASHTABLE_STATS
        atomicIncrement(&HashTableStats::numRemoves);
#endif
#if DUMP_HASHTABLE_STATS_PER_TABLE
        ++m_stats->numRemoves;
#endif

        deleteBucket(*pos);
        ++m_deletedCount;
        --m_keyCount;

        if (shouldShrink())
            shrink();
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    inline void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::remove(iterator it)
    {
        if (it == end())
            return;

        remove(const_cast<ValueType*>(it.m_iterator.m_position));
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    inline void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::remove(const_iterator it)
    {
        if (it == end())
            return;

        remove(const_cast<ValueType*>(it.m_position));
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    inline void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::remove(KeyPeekInType key)
    {
        remove(find(key));
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    Value* HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::allocateTable(unsigned size)
    {
        typedef typename Allocator::template HashTableBackingHelper<HashTable>::Type HashTableBacking;

        size_t allocSize = size * sizeof(ValueType);
        ValueType* result;
        // Assert that we will not use memset on things with a vtable entry.
        // The compiler will also check this on some platforms. We would
        // like to check this on the whole value (key-value pair), but
        // IsPolymorphic will return false for a pair of two types, even if
        // one of the components is polymorphic.
        COMPILE_ASSERT(!Traits::emptyValueIsZero || !IsPolymorphic<KeyType>::value, EmptyValueCannotBeZeroForThingsWithAVtable);
        if (Traits::emptyValueIsZero) {
            result = Allocator::template zeroedBackingMalloc<ValueType*, HashTableBacking>(allocSize);
        } else {
            result = Allocator::template backingMalloc<ValueType*, HashTableBacking>(allocSize);
            for (unsigned i = 0; i < size; i++)
                initializeBucket(result[i]);
        }
        return result;
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::deleteAllBucketsAndDeallocate(ValueType* table, unsigned size)
    {
        if (Traits::needsDestruction) {
            for (unsigned i = 0; i < size; ++i) {
                // This code is called when the hash table is cleared or
                // resized. We have allocated a new backing store and we need
                // to run the destructors on the old backing store, as it is
                // being freed. If we are GCing we need to both call the
                // destructor and mark the bucket as deleted, otherwise the
                // destructor gets called again when the GC finds the backing
                // store. With the default allocator it's enough to call the
                // destructor, since we will free the memory explicitly and
                // we won't see the memory with the bucket again.
                if (!isEmptyOrDeletedBucket(table[i])) {
                    if (Allocator::isGarbageCollected)
                        deleteBucket(table[i]);
                    else
                        table[i].~ValueType();
                }
            }
        }
        Allocator::backingFree(table);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    Value* HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::expand(Value* entry)
    {
        unsigned newSize;
        if (!m_tableSize) {
            newSize = KeyTraits::minimumTableSize;
        } else if (mustRehashInPlace()) {
            newSize = m_tableSize;
        } else {
            newSize = m_tableSize * 2;
            RELEASE_ASSERT(newSize > m_tableSize);
        }

        return rehash(newSize, entry);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    Value* HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::rehash(unsigned newTableSize, Value* entry)
    {
        unsigned oldTableSize = m_tableSize;
        ValueType* oldTable = m_table;

#if DUMP_HASHTABLE_STATS
        if (oldTableSize != 0)
            atomicIncrement(&HashTableStats::numRehashes);
#endif

#if DUMP_HASHTABLE_STATS_PER_TABLE
        if (oldTableSize != 0)
            ++m_stats->numRehashes;
#endif

        m_table = allocateTable(newTableSize);
        m_tableSize = newTableSize;

        Value* newEntry = 0;
        for (unsigned i = 0; i != oldTableSize; ++i) {
            if (isEmptyOrDeletedBucket(oldTable[i])) {
                ASSERT(&oldTable[i] != entry);
                continue;
            }

            Value* reinsertedEntry = reinsert(oldTable[i]);
            if (&oldTable[i] == entry) {
                ASSERT(!newEntry);
                newEntry = reinsertedEntry;
            }
        }

        m_deletedCount = 0;

        deleteAllBucketsAndDeallocate(oldTable, oldTableSize);

        return newEntry;
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::clear()
    {
        registerModification();
        if (!m_table)
            return;

        deleteAllBucketsAndDeallocate(m_table, m_tableSize);
        m_table = 0;
        m_tableSize = 0;
        m_keyCount = 0;
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::HashTable(const HashTable& other)
        : m_table(0)
        , m_tableSize(0)
        , m_keyCount(0)
        , m_deletedCount(0)
        , m_queueFlag(false)
#if ENABLE(ASSERT)
        , m_modifications(0)
#endif
#if DUMP_HASHTABLE_STATS_PER_TABLE
        , m_stats(adoptPtr(new Stats(*other.m_stats)))
#endif
    {
        // Copy the hash table the dumb way, by adding each element to the new table.
        // It might be more efficient to copy the table slots, but it's not clear that efficiency is needed.
        const_iterator end = other.end();
        for (const_iterator it = other.begin(); it != end; ++it)
            add(*it);
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::swap(HashTable& other)
    {
        std::swap(m_table, other.m_table);
        std::swap(m_tableSize, other.m_tableSize);
        std::swap(m_keyCount, other.m_keyCount);
        // std::swap does not work for bit fields.
        unsigned deleted = m_deletedCount;
        m_deletedCount = other.m_deletedCount;
        other.m_deletedCount = deleted;
        ASSERT(!m_queueFlag);
        ASSERT(!other.m_queueFlag);

#if ENABLE(ASSERT)
        std::swap(m_modifications, other.m_modifications);
#endif

#if DUMP_HASHTABLE_STATS_PER_TABLE
        m_stats.swap(other.m_stats);
#endif
    }

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>& HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::operator=(const HashTable& other)
    {
        HashTable tmp(other);
        swap(tmp);
        return *this;
    }

    template<WeakHandlingFlag weakHandlingFlag, typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    struct WeakProcessingHashTableHelper;

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    struct WeakProcessingHashTableHelper<NoWeakHandlingInCollections, Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> {
        static void process(typename Allocator::Visitor* visitor, void* closure) { }
        static void ephemeronIteration(typename Allocator::Visitor* visitor, void* closure) { }
        static void ephemeronIterationDone(typename Allocator::Visitor* visitor, void* closure) { }
    };

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    struct WeakProcessingHashTableHelper<WeakHandlingInCollections, Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> {
        // Used for purely weak and for weak-and-strong tables (ephemerons).
        static void process(typename Allocator::Visitor* visitor, void* closure)
        {
            typedef HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> HashTableType;
            HashTableType* table = reinterpret_cast<HashTableType*>(closure);
            if (table->m_table) {
                // This is run as part of weak processing after full
                // marking. The backing store is therefore marked if
                // we get here.
                ASSERT(visitor->isAlive(table->m_table));
                // Now perform weak processing (this is a no-op if the backing
                // was accessible through an iterator and was already marked
                // strongly).
                typedef typename HashTableType::ValueType ValueType;
                for (ValueType* element = table->m_table + table->m_tableSize - 1; element >= table->m_table; element--) {
                    if (!HashTableType::isEmptyOrDeletedBucket(*element)) {
                        // At this stage calling trace can make no difference
                        // (everything is already traced), but we use the
                        // return value to remove things from the collection.
                        if (TraceInCollectionTrait<WeakHandlingInCollections, WeakPointersActWeak, ValueType, Traits>::trace(visitor, *element)) {
                            table->registerModification();
                            HashTableType::deleteBucket(*element); // Also calls the destructor.
                            table->m_deletedCount++;
                            table->m_keyCount--;
                            // We don't rehash the backing until the next add
                            // or delete, because that would cause allocation
                            // during GC.
                        }
                    }
                }
            }
        }

        // Called repeatedly for tables that have both weak and strong pointers.
        static void ephemeronIteration(typename Allocator::Visitor* visitor, void* closure)
        {
            typedef HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> HashTableType;
            HashTableType* table = reinterpret_cast<HashTableType*>(closure);
            if (table->m_table) {
                // Check the hash table for elements that we now know will not
                // be removed by weak processing. Those elements need to have
                // their strong pointers traced.
                typedef typename HashTableType::ValueType ValueType;
                for (ValueType* element = table->m_table + table->m_tableSize - 1; element >= table->m_table; element--) {
                    if (!HashTableType::isEmptyOrDeletedBucket(*element))
                        TraceInCollectionTrait<WeakHandlingInCollections, WeakPointersActWeak, ValueType, Traits>::trace(visitor, *element);
                }
            }
        }

        // Called when the ephemeron iteration is done and before running the per thread
        // weak processing. It is guaranteed to be called before any thread is resumed.
        static void ephemeronIterationDone(typename Allocator::Visitor* visitor, void* closure)
        {
            typedef HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator> HashTableType;
            HashTableType* table = reinterpret_cast<HashTableType*>(closure);
            ASSERT(Allocator::weakTableRegistered(visitor, table));
            table->clearEnqueued();
        }
    };

    template<typename Key, typename Value, typename Extractor, typename HashFunctions, typename Traits, typename KeyTraits, typename Allocator>
    void HashTable<Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::trace(typename Allocator::Visitor* visitor)
    {
        // If someone else already marked the backing and queued up the trace
        // and/or weak callback then we are done. This optimization does not
        // happen for ListHashSet since its iterator does not point at the
        // backing.
        if (!m_table || visitor->isAlive(m_table))
            return;
        // Normally, we mark the backing store without performing trace. This
        // means it is marked live, but the pointers inside it are not marked.
        // Instead we will mark the pointers below. However, for backing
        // stores that contain weak pointers the handling is rather different.
        // We don't mark the backing store here, so the marking GC will leave
        // the backing unmarked. If the backing is found in any other way than
        // through its HashTable (ie from an iterator) then the mark bit will
        // be set and the pointers will be marked strongly, avoiding problems
        // with iterating over things that disappear due to weak processing
        // while we are iterating over them. We register the backing store
        // pointer for delayed marking which will take place after we know if
        // the backing is reachable from elsewhere. We also register a
        // weakProcessing callback which will perform weak processing if needed.
        if (Traits::weakHandlingFlag == NoWeakHandlingInCollections) {
            Allocator::markNoTracing(visitor, m_table);
        } else {
            Allocator::registerDelayedMarkNoTracing(visitor, m_table);
            Allocator::registerWeakMembers(visitor, this, m_table, WeakProcessingHashTableHelper<Traits::weakHandlingFlag, Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::process);
        }
        if (ShouldBeTraced<Traits>::value) {
            if (Traits::weakHandlingFlag == WeakHandlingInCollections) {
                // If we have both strong and weak pointers in the collection
                // then we queue up the collection for fixed point iteration a
                // la Ephemerons:
                // http://dl.acm.org/citation.cfm?doid=263698.263733 - see also
                // http://www.jucs.org/jucs_14_21/eliminating_cycles_in_weak
                ASSERT(!enqueued() || Allocator::weakTableRegistered(visitor, this));
                if (!enqueued()) {
                    Allocator::registerWeakTable(visitor, this,
                        WeakProcessingHashTableHelper<Traits::weakHandlingFlag, Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::ephemeronIteration,
                        WeakProcessingHashTableHelper<Traits::weakHandlingFlag, Key, Value, Extractor, HashFunctions, Traits, KeyTraits, Allocator>::ephemeronIterationDone);
                    setEnqueued();
                }
                // We don't need to trace the elements here, since registering
                // as a weak table above will cause them to be traced (perhaps
                // several times). It's better to wait until everything else is
                // traced before tracing the elements for the first time; this
                // may reduce (by one) the number of iterations needed to get
                // to a fixed point.
                return;
            }
            for (ValueType* element = m_table + m_tableSize - 1; element >= m_table; element--) {
                if (!isEmptyOrDeletedBucket(*element))
                    Allocator::template trace<ValueType, Traits>(visitor, *element);
            }
        }
    }

    // iterator adapters

    template<typename HashTableType, typename Traits> struct HashTableConstIteratorAdapter {
        HashTableConstIteratorAdapter() {}
        HashTableConstIteratorAdapter(const typename HashTableType::const_iterator& impl) : m_impl(impl) {}
        typedef typename Traits::IteratorConstGetType GetType;
        typedef typename HashTableType::ValueTraits::IteratorConstGetType SourceGetType;

        GetType get() const { return const_cast<GetType>(SourceGetType(m_impl.get())); }
        typename Traits::IteratorConstReferenceType operator*() const { return Traits::getToReferenceConstConversion(get()); }
        GetType operator->() const { return get(); }

        HashTableConstIteratorAdapter& operator++() { ++m_impl; return *this; }
        // postfix ++ intentionally omitted

        typename HashTableType::const_iterator m_impl;
    };

    template<typename HashTableType, typename Traits> struct HashTableIteratorAdapter {
        typedef typename Traits::IteratorGetType GetType;
        typedef typename HashTableType::ValueTraits::IteratorGetType SourceGetType;

        HashTableIteratorAdapter() {}
        HashTableIteratorAdapter(const typename HashTableType::iterator& impl) : m_impl(impl) {}

        GetType get() const { return const_cast<GetType>(SourceGetType(m_impl.get())); }
        typename Traits::IteratorReferenceType operator*() const { return Traits::getToReferenceConversion(get()); }
        GetType operator->() const { return get(); }

        HashTableIteratorAdapter& operator++() { ++m_impl; return *this; }
        // postfix ++ intentionally omitted

        operator HashTableConstIteratorAdapter<HashTableType, Traits>()
        {
            typename HashTableType::const_iterator i = m_impl;
            return i;
        }

        typename HashTableType::iterator m_impl;
    };

    template<typename T, typename U>
    inline bool operator==(const HashTableConstIteratorAdapter<T, U>& a, const HashTableConstIteratorAdapter<T, U>& b)
    {
        return a.m_impl == b.m_impl;
    }

    template<typename T, typename U>
    inline bool operator!=(const HashTableConstIteratorAdapter<T, U>& a, const HashTableConstIteratorAdapter<T, U>& b)
    {
        return a.m_impl != b.m_impl;
    }

    template<typename T, typename U>
    inline bool operator==(const HashTableIteratorAdapter<T, U>& a, const HashTableIteratorAdapter<T, U>& b)
    {
        return a.m_impl == b.m_impl;
    }

    template<typename T, typename U>
    inline bool operator!=(const HashTableIteratorAdapter<T, U>& a, const HashTableIteratorAdapter<T, U>& b)
    {
        return a.m_impl != b.m_impl;
    }

    // All 4 combinations of ==, != and Const,non const.
    template<typename T, typename U>
    inline bool operator==(const HashTableConstIteratorAdapter<T, U>& a, const HashTableIteratorAdapter<T, U>& b)
    {
        return a.m_impl == b.m_impl;
    }

    template<typename T, typename U>
    inline bool operator!=(const HashTableConstIteratorAdapter<T, U>& a, const HashTableIteratorAdapter<T, U>& b)
    {
        return a.m_impl != b.m_impl;
    }

    template<typename T, typename U>
    inline bool operator==(const HashTableIteratorAdapter<T, U>& a, const HashTableConstIteratorAdapter<T, U>& b)
    {
        return a.m_impl == b.m_impl;
    }

    template<typename T, typename U>
    inline bool operator!=(const HashTableIteratorAdapter<T, U>& a, const HashTableConstIteratorAdapter<T, U>& b)
    {
        return a.m_impl != b.m_impl;
    }

    template<typename Collection1, typename Collection2>
    inline void removeAll(Collection1& collection, const Collection2& toBeRemoved)
    {
        if (collection.isEmpty() || toBeRemoved.isEmpty())
            return;
        typedef typename Collection2::const_iterator CollectionIterator;
        CollectionIterator end(toBeRemoved.end());
        for (CollectionIterator it(toBeRemoved.begin()); it != end; ++it)
            collection.remove(*it);
    }

} // namespace WTF

#include "wtf/HashIterators.h"

#endif // WTF_HashTable_h
