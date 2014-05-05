/*
 * Copyright (C) 2014 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Base class for reference counted objects in Minikin

#ifndef MINIKIN_REF_COUNTED_H
#define MINIKIN_REF_COUNTED_H

namespace android {

class MinikinRefCounted {
public:
    void RefLocked() { mRefcount_++; }
    void UnrefLocked() { if (--mRefcount_ == 0) { delete this; } }

    // These refcount operations take the global lock.
    void Ref();
    void Unref();

    MinikinRefCounted() : mRefcount_(1) { }

    virtual ~MinikinRefCounted() { };
private:
    int mRefcount_;
};

}

#endif   // MINIKIN_REF_COUNTED_H