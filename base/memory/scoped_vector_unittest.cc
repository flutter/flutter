// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/scoped_vector.h"

#include "base/bind.h"
#include "base/callback.h"
#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

// The LifeCycleObject notifies its Observer upon construction & destruction.
class LifeCycleObject {
 public:
  class Observer {
   public:
    virtual void OnLifeCycleConstruct(LifeCycleObject* o) = 0;
    virtual void OnLifeCycleDestroy(LifeCycleObject* o) = 0;

   protected:
    virtual ~Observer() {}
  };

  ~LifeCycleObject() {
    observer_->OnLifeCycleDestroy(this);
  }

 private:
  friend class LifeCycleWatcher;

  explicit LifeCycleObject(Observer* observer)
      : observer_(observer) {
    observer_->OnLifeCycleConstruct(this);
  }

  Observer* observer_;

  DISALLOW_COPY_AND_ASSIGN(LifeCycleObject);
};

// The life cycle states we care about for the purposes of testing ScopedVector
// against objects.
enum LifeCycleState {
  LC_INITIAL,
  LC_CONSTRUCTED,
  LC_DESTROYED,
};

// Because we wish to watch the life cycle of an object being constructed and
// destroyed, and further wish to test expectations against the state of that
// object, we cannot save state in that object itself. Instead, we use this
// pairing of the watcher, which observes the object and notifies of
// construction & destruction. Since we also may be testing assumptions about
// things not getting freed, this class also acts like a scoping object and
// deletes the |constructed_life_cycle_object_|, if any when the
// LifeCycleWatcher is destroyed. To keep this simple, the only expected state
// changes are:
//   INITIAL -> CONSTRUCTED -> DESTROYED.
// Anything more complicated than that should start another test.
class LifeCycleWatcher : public LifeCycleObject::Observer {
 public:
  LifeCycleWatcher() : life_cycle_state_(LC_INITIAL) {}
  ~LifeCycleWatcher() override {}

  // Assert INITIAL -> CONSTRUCTED and no LifeCycleObject associated with this
  // LifeCycleWatcher.
  void OnLifeCycleConstruct(LifeCycleObject* object) override {
    ASSERT_EQ(LC_INITIAL, life_cycle_state_);
    ASSERT_EQ(NULL, constructed_life_cycle_object_.get());
    life_cycle_state_ = LC_CONSTRUCTED;
    constructed_life_cycle_object_.reset(object);
  }

  // Assert CONSTRUCTED -> DESTROYED and the |object| being destroyed is the
  // same one we saw constructed.
  void OnLifeCycleDestroy(LifeCycleObject* object) override {
    ASSERT_EQ(LC_CONSTRUCTED, life_cycle_state_);
    LifeCycleObject* constructed_life_cycle_object =
        constructed_life_cycle_object_.release();
    ASSERT_EQ(constructed_life_cycle_object, object);
    life_cycle_state_ = LC_DESTROYED;
  }

  LifeCycleState life_cycle_state() const { return life_cycle_state_; }

  // Factory method for creating a new LifeCycleObject tied to this
  // LifeCycleWatcher.
  LifeCycleObject* NewLifeCycleObject() {
    return new LifeCycleObject(this);
  }

  // Returns true iff |object| is the same object that this watcher is tracking.
  bool IsWatching(LifeCycleObject* object) const {
    return object == constructed_life_cycle_object_.get();
  }

 private:
  LifeCycleState life_cycle_state_;
  scoped_ptr<LifeCycleObject> constructed_life_cycle_object_;

  DISALLOW_COPY_AND_ASSIGN(LifeCycleWatcher);
};

TEST(ScopedVectorTest, LifeCycleWatcher) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  LifeCycleObject* object = watcher.NewLifeCycleObject();
  EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  delete object;
  EXPECT_EQ(LC_DESTROYED, watcher.life_cycle_state());
}

TEST(ScopedVectorTest, PopBack) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  ScopedVector<LifeCycleObject> scoped_vector;
  scoped_vector.push_back(watcher.NewLifeCycleObject());
  EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  EXPECT_TRUE(watcher.IsWatching(scoped_vector.back()));
  scoped_vector.pop_back();
  EXPECT_EQ(LC_DESTROYED, watcher.life_cycle_state());
  EXPECT_TRUE(scoped_vector.empty());
}

TEST(ScopedVectorTest, Clear) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  ScopedVector<LifeCycleObject> scoped_vector;
  scoped_vector.push_back(watcher.NewLifeCycleObject());
  EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  EXPECT_TRUE(watcher.IsWatching(scoped_vector.back()));
  scoped_vector.clear();
  EXPECT_EQ(LC_DESTROYED, watcher.life_cycle_state());
  EXPECT_TRUE(scoped_vector.empty());
}

TEST(ScopedVectorTest, WeakClear) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  ScopedVector<LifeCycleObject> scoped_vector;
  scoped_vector.push_back(watcher.NewLifeCycleObject());
  EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  EXPECT_TRUE(watcher.IsWatching(scoped_vector.back()));
  scoped_vector.weak_clear();
  EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  EXPECT_TRUE(scoped_vector.empty());
}

TEST(ScopedVectorTest, ResizeShrink) {
  LifeCycleWatcher first_watcher;
  EXPECT_EQ(LC_INITIAL, first_watcher.life_cycle_state());
  LifeCycleWatcher second_watcher;
  EXPECT_EQ(LC_INITIAL, second_watcher.life_cycle_state());
  ScopedVector<LifeCycleObject> scoped_vector;

  scoped_vector.push_back(first_watcher.NewLifeCycleObject());
  EXPECT_EQ(LC_CONSTRUCTED, first_watcher.life_cycle_state());
  EXPECT_EQ(LC_INITIAL, second_watcher.life_cycle_state());
  EXPECT_TRUE(first_watcher.IsWatching(scoped_vector[0]));
  EXPECT_FALSE(second_watcher.IsWatching(scoped_vector[0]));

  scoped_vector.push_back(second_watcher.NewLifeCycleObject());
  EXPECT_EQ(LC_CONSTRUCTED, first_watcher.life_cycle_state());
  EXPECT_EQ(LC_CONSTRUCTED, second_watcher.life_cycle_state());
  EXPECT_FALSE(first_watcher.IsWatching(scoped_vector[1]));
  EXPECT_TRUE(second_watcher.IsWatching(scoped_vector[1]));

  // Test that shrinking a vector deletes elements in the disappearing range.
  scoped_vector.resize(1);
  EXPECT_EQ(LC_CONSTRUCTED, first_watcher.life_cycle_state());
  EXPECT_EQ(LC_DESTROYED, second_watcher.life_cycle_state());
  EXPECT_EQ(1u, scoped_vector.size());
  EXPECT_TRUE(first_watcher.IsWatching(scoped_vector[0]));
}

TEST(ScopedVectorTest, ResizeGrow) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  ScopedVector<LifeCycleObject> scoped_vector;
  scoped_vector.push_back(watcher.NewLifeCycleObject());
  EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  EXPECT_TRUE(watcher.IsWatching(scoped_vector.back()));

  scoped_vector.resize(5);
  EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  ASSERT_EQ(5u, scoped_vector.size());
  EXPECT_TRUE(watcher.IsWatching(scoped_vector[0]));
  EXPECT_FALSE(watcher.IsWatching(scoped_vector[1]));
  EXPECT_FALSE(watcher.IsWatching(scoped_vector[2]));
  EXPECT_FALSE(watcher.IsWatching(scoped_vector[3]));
  EXPECT_FALSE(watcher.IsWatching(scoped_vector[4]));
}

TEST(ScopedVectorTest, Scope) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  {
    ScopedVector<LifeCycleObject> scoped_vector;
    scoped_vector.push_back(watcher.NewLifeCycleObject());
    EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
    EXPECT_TRUE(watcher.IsWatching(scoped_vector.back()));
  }
  EXPECT_EQ(LC_DESTROYED, watcher.life_cycle_state());
}

TEST(ScopedVectorTest, MoveConstruct) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  {
    ScopedVector<LifeCycleObject> scoped_vector;
    scoped_vector.push_back(watcher.NewLifeCycleObject());
    EXPECT_FALSE(scoped_vector.empty());
    EXPECT_TRUE(watcher.IsWatching(scoped_vector.back()));

    ScopedVector<LifeCycleObject> scoped_vector_copy(scoped_vector.Pass());
    EXPECT_TRUE(scoped_vector.empty());
    EXPECT_FALSE(scoped_vector_copy.empty());
    EXPECT_TRUE(watcher.IsWatching(scoped_vector_copy.back()));

    EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  }
  EXPECT_EQ(LC_DESTROYED, watcher.life_cycle_state());
}

TEST(ScopedVectorTest, MoveAssign) {
  LifeCycleWatcher watcher;
  EXPECT_EQ(LC_INITIAL, watcher.life_cycle_state());
  {
    ScopedVector<LifeCycleObject> scoped_vector;
    scoped_vector.push_back(watcher.NewLifeCycleObject());
    ScopedVector<LifeCycleObject> scoped_vector_assign;
    EXPECT_FALSE(scoped_vector.empty());
    EXPECT_TRUE(watcher.IsWatching(scoped_vector.back()));

    scoped_vector_assign = scoped_vector.Pass();
    EXPECT_TRUE(scoped_vector.empty());
    EXPECT_FALSE(scoped_vector_assign.empty());
    EXPECT_TRUE(watcher.IsWatching(scoped_vector_assign.back()));

    EXPECT_EQ(LC_CONSTRUCTED, watcher.life_cycle_state());
  }
  EXPECT_EQ(LC_DESTROYED, watcher.life_cycle_state());
}

class DeleteCounter {
 public:
  explicit DeleteCounter(int* deletes)
      : deletes_(deletes) {
  }

  ~DeleteCounter() {
    (*deletes_)++;
  }

  void VoidMethod0() {}

 private:
  int* const deletes_;

  DISALLOW_COPY_AND_ASSIGN(DeleteCounter);
};

template <typename T>
ScopedVector<T> PassThru(ScopedVector<T> scoper) {
  return scoper.Pass();
}

TEST(ScopedVectorTest, Passed) {
  int deletes = 0;
  ScopedVector<DeleteCounter> deleter_vector;
  deleter_vector.push_back(new DeleteCounter(&deletes));
  EXPECT_EQ(0, deletes);
  base::Callback<ScopedVector<DeleteCounter>(void)> callback =
      base::Bind(&PassThru<DeleteCounter>, base::Passed(&deleter_vector));
  EXPECT_EQ(0, deletes);
  ScopedVector<DeleteCounter> result = callback.Run();
  EXPECT_EQ(0, deletes);
  result.clear();
  EXPECT_EQ(1, deletes);
};

TEST(ScopedVectorTest, InsertRange) {
  LifeCycleWatcher watchers[5];

  std::vector<LifeCycleObject*> vec;
  for(LifeCycleWatcher* it = watchers; it != watchers + arraysize(watchers);
      ++it) {
    EXPECT_EQ(LC_INITIAL, it->life_cycle_state());
    vec.push_back(it->NewLifeCycleObject());
    EXPECT_EQ(LC_CONSTRUCTED, it->life_cycle_state());
  }
  // Start scope for ScopedVector.
  {
    ScopedVector<LifeCycleObject> scoped_vector;
    scoped_vector.insert(scoped_vector.end(), vec.begin() + 1, vec.begin() + 3);
    for(LifeCycleWatcher* it = watchers; it != watchers + arraysize(watchers);
        ++it)
      EXPECT_EQ(LC_CONSTRUCTED, it->life_cycle_state());
  }
  for(LifeCycleWatcher* it = watchers; it != watchers + 1; ++it)
    EXPECT_EQ(LC_CONSTRUCTED, it->life_cycle_state());
  for(LifeCycleWatcher* it = watchers + 1; it != watchers + 3; ++it)
    EXPECT_EQ(LC_DESTROYED, it->life_cycle_state());
  for(LifeCycleWatcher* it = watchers + 3; it != watchers + arraysize(watchers);
      ++it)
    EXPECT_EQ(LC_CONSTRUCTED, it->life_cycle_state());
}

// Assertions for push_back(scoped_ptr).
TEST(ScopedVectorTest, PushBackScopedPtr) {
  int delete_counter = 0;
  scoped_ptr<DeleteCounter> elem(new DeleteCounter(&delete_counter));
  EXPECT_EQ(0, delete_counter);
  {
    ScopedVector<DeleteCounter> v;
    v.push_back(elem.Pass());
    EXPECT_EQ(0, delete_counter);
  }
  EXPECT_EQ(1, delete_counter);
}

}  // namespace
