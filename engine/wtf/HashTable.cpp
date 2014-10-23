/*
    Copyright (C) 2005 Apple Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#include "config.h"
#include "HashTable.h"
#include "DataLog.h"

namespace WTF {

#if DUMP_HASHTABLE_STATS

int HashTableStats::numAccesses;
int HashTableStats::numCollisions;
int HashTableStats::collisionGraph[4096];
int HashTableStats::maxCollisions;
int HashTableStats::numRehashes;
int HashTableStats::numRemoves;
int HashTableStats::numReinserts;

static Mutex& hashTableStatsMutex()
{
    AtomicallyInitializedStatic(Mutex&, mutex = *new Mutex);
    return mutex;
}

void HashTableStats::recordCollisionAtCount(int count)
{
    MutexLocker lock(hashTableStatsMutex());
    if (count > maxCollisions)
        maxCollisions = count;
    numCollisions++;
    collisionGraph[count]++;
}

void HashTableStats::dumpStats()
{
    MutexLocker lock(hashTableStatsMutex());

    dataLogF("\nWTF::HashTable statistics\n\n");
    dataLogF("%d accesses\n", numAccesses);
    dataLogF("%d total collisions, average %.2f probes per access\n", numCollisions, 1.0 * (numAccesses + numCollisions) / numAccesses);
    dataLogF("longest collision chain: %d\n", maxCollisions);
    for (int i = 1; i <= maxCollisions; i++) {
        dataLogF("  %d lookups with exactly %d collisions (%.2f%% , %.2f%% with this many or more)\n", collisionGraph[i], i, 100.0 * (collisionGraph[i] - collisionGraph[i+1]) / numAccesses, 100.0 * collisionGraph[i] / numAccesses);
    }
    dataLogF("%d rehashes\n", numRehashes);
    dataLogF("%d reinserts\n", numReinserts);
}

#endif

} // namespace WTF
