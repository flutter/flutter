// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CALLBACK_LIST_H_
#define BASE_CALLBACK_LIST_H_

#include <list>

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/callback_internal.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"

// OVERVIEW:
//
// A container for a list of callbacks.  Unlike a normal STL vector or list,
// this container can be modified during iteration without invalidating the
// iterator. It safely handles the case of a callback removing itself
// or another callback from the list while callbacks are being run.
//
// TYPICAL USAGE:
//
// class MyWidget {
//  public:
//   ...
//
//   typedef base::Callback<void(const Foo&)> OnFooCallback;
//
//   scoped_ptr<base::CallbackList<void(const Foo&)>::Subscription>
//   RegisterCallback(const OnFooCallback& cb) {
//     return callback_list_.Add(cb);
//   }
//
//  private:
//   void NotifyFoo(const Foo& foo) {
//      callback_list_.Notify(foo);
//   }
//
//   base::CallbackList<void(const Foo&)> callback_list_;
//
//   DISALLOW_COPY_AND_ASSIGN(MyWidget);
// };
//
//
// class MyWidgetListener {
//  public:
//   MyWidgetListener::MyWidgetListener() {
//     foo_subscription_ = MyWidget::GetCurrent()->RegisterCallback(
//             base::Bind(&MyWidgetListener::OnFoo, this)));
//   }
//
//   MyWidgetListener::~MyWidgetListener() {
//      // Subscription gets deleted automatically and will deregister
//      // the callback in the process.
//   }
//
//  private:
//   void OnFoo(const Foo& foo) {
//     // Do something.
//   }
//
//   scoped_ptr<base::CallbackList<void(const Foo&)>::Subscription>
//       foo_subscription_;
//
//   DISALLOW_COPY_AND_ASSIGN(MyWidgetListener);
// };

namespace base {

namespace internal {

template <typename CallbackType>
class CallbackListBase {
 public:
  class Subscription {
   public:
    Subscription(CallbackListBase<CallbackType>* list,
                 typename std::list<CallbackType>::iterator iter)
        : list_(list),
          iter_(iter) {
    }

    ~Subscription() {
      if (list_->active_iterator_count_) {
        iter_->Reset();
      } else {
        list_->callbacks_.erase(iter_);
        if (!list_->removal_callback_.is_null())
          list_->removal_callback_.Run();
      }
    }

   private:
    CallbackListBase<CallbackType>* list_;
    typename std::list<CallbackType>::iterator iter_;

    DISALLOW_COPY_AND_ASSIGN(Subscription);
  };

  // Add a callback to the list. The callback will remain registered until the
  // returned Subscription is destroyed, which must occur before the
  // CallbackList is destroyed.
  scoped_ptr<Subscription> Add(const CallbackType& cb) WARN_UNUSED_RESULT {
    DCHECK(!cb.is_null());
    return scoped_ptr<Subscription>(
        new Subscription(this, callbacks_.insert(callbacks_.end(), cb)));
  }

  // Sets a callback which will be run when a subscription list is changed.
  void set_removal_callback(const Closure& callback) {
    removal_callback_ = callback;
  }

  // Returns true if there are no subscriptions. This is only valid to call when
  // not looping through the list.
  bool empty() {
    DCHECK_EQ(0, active_iterator_count_);
    return callbacks_.empty();
  }

 protected:
  // An iterator class that can be used to access the list of callbacks.
  class Iterator {
   public:
    explicit Iterator(CallbackListBase<CallbackType>* list)
        : list_(list),
          list_iter_(list_->callbacks_.begin()) {
      ++list_->active_iterator_count_;
    }

    Iterator(const Iterator& iter)
        : list_(iter.list_),
          list_iter_(iter.list_iter_) {
      ++list_->active_iterator_count_;
    }

    ~Iterator() {
      if (list_ && --list_->active_iterator_count_ == 0) {
        list_->Compact();
      }
    }

    CallbackType* GetNext() {
      while ((list_iter_ != list_->callbacks_.end()) && list_iter_->is_null())
        ++list_iter_;

      CallbackType* cb = NULL;
      if (list_iter_ != list_->callbacks_.end()) {
        cb = &(*list_iter_);
        ++list_iter_;
      }
      return cb;
    }

   private:
    CallbackListBase<CallbackType>* list_;
    typename std::list<CallbackType>::iterator list_iter_;
  };

  CallbackListBase() : active_iterator_count_(0) {}

  ~CallbackListBase() {
    DCHECK_EQ(0, active_iterator_count_);
    DCHECK_EQ(0U, callbacks_.size());
  }

  // Returns an instance of a CallbackListBase::Iterator which can be used
  // to run callbacks.
  Iterator GetIterator() {
    return Iterator(this);
  }

  // Compact the list: remove any entries which were NULLed out during
  // iteration.
  void Compact() {
    typename std::list<CallbackType>::iterator it = callbacks_.begin();
    bool updated = false;
    while (it != callbacks_.end()) {
      if ((*it).is_null()) {
        updated = true;
        it = callbacks_.erase(it);
      } else {
        ++it;
      }

      if (updated && !removal_callback_.is_null())
        removal_callback_.Run();
    }
  }

 private:
  std::list<CallbackType> callbacks_;
  int active_iterator_count_;
  Closure removal_callback_;

  DISALLOW_COPY_AND_ASSIGN(CallbackListBase);
};

}  // namespace internal

template <typename Sig> class CallbackList;

template <typename... Args>
class CallbackList<void(Args...)>
    : public internal::CallbackListBase<Callback<void(Args...)> > {
 public:
  typedef Callback<void(Args...)> CallbackType;

  CallbackList() {}

  void Notify(
      typename internal::CallbackParamTraits<Args>::ForwardType... args) {
    typename internal::CallbackListBase<CallbackType>::Iterator it =
        this->GetIterator();
    CallbackType* cb;
    while ((cb = it.GetNext()) != NULL) {
      cb->Run(args...);
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(CallbackList);
};

}  // namespace base

#endif  // BASE_CALLBACK_LIST_H_
