// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/view_manager/public/cpp/view.h"

#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "mojo/services/view_manager/public/cpp/lib/view_private.h"
#include "mojo/services/view_manager/public/cpp/util.h"
#include "mojo/services/view_manager/public/cpp/view_observer.h"
#include "mojo/services/view_manager/public/cpp/view_property.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {

// View ------------------------------------------------------------------------

typedef testing::Test ViewTest;

// Subclass with public ctor/dtor.
class TestView : public View {
 public:
  TestView() {
    ViewPrivate(this).set_id(1);
  }
  ~TestView() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(TestView);
};

TEST_F(ViewTest, AddChild) {
  TestView v1;
  TestView v11;
  v1.AddChild(&v11);
  EXPECT_EQ(1U, v1.children().size());
}

TEST_F(ViewTest, RemoveChild) {
  TestView v1;
  TestView v11;
  v1.AddChild(&v11);
  EXPECT_EQ(1U, v1.children().size());
  v1.RemoveChild(&v11);
  EXPECT_EQ(0U, v1.children().size());
}

TEST_F(ViewTest, Reparent) {
  TestView v1;
  TestView v2;
  TestView v11;
  v1.AddChild(&v11);
  EXPECT_EQ(1U, v1.children().size());
  v2.AddChild(&v11);
  EXPECT_EQ(1U, v2.children().size());
  EXPECT_EQ(0U, v1.children().size());
}

TEST_F(ViewTest, Contains) {
  TestView v1;

  // Direct descendant.
  TestView v11;
  v1.AddChild(&v11);
  EXPECT_TRUE(v1.Contains(&v11));

  // Indirect descendant.
  TestView v111;
  v11.AddChild(&v111);
  EXPECT_TRUE(v1.Contains(&v111));
}

TEST_F(ViewTest, GetChildById) {
  TestView v1;
  ViewPrivate(&v1).set_id(1);
  TestView v11;
  ViewPrivate(&v11).set_id(11);
  v1.AddChild(&v11);
  TestView v111;
  ViewPrivate(&v111).set_id(111);
  v11.AddChild(&v111);

  // Find direct & indirect descendents.
  EXPECT_EQ(&v11, v1.GetChildById(v11.id()));
  EXPECT_EQ(&v111, v1.GetChildById(v111.id()));
}

TEST_F(ViewTest, DrawnAndVisible) {
  TestView v1;
  EXPECT_TRUE(v1.visible());
  EXPECT_FALSE(v1.IsDrawn());

  ViewPrivate(&v1).set_drawn(true);

  TestView v11;
  v1.AddChild(&v11);
  EXPECT_TRUE(v11.visible());
  EXPECT_TRUE(v11.IsDrawn());

  v1.RemoveChild(&v11);
  EXPECT_TRUE(v11.visible());
  EXPECT_FALSE(v11.IsDrawn());
}

namespace {
DEFINE_VIEW_PROPERTY_KEY(int, kIntKey, -2);
DEFINE_VIEW_PROPERTY_KEY(const char*, kStringKey, "squeamish");
}

TEST_F(ViewTest, Property) {
  TestView v;

  // Non-existent properties should return the default values.
  EXPECT_EQ(-2, v.GetLocalProperty(kIntKey));
  EXPECT_EQ(std::string("squeamish"), v.GetLocalProperty(kStringKey));

  // A set property value should be returned again (even if it's the default
  // value).
  v.SetLocalProperty(kIntKey, INT_MAX);
  EXPECT_EQ(INT_MAX, v.GetLocalProperty(kIntKey));
  v.SetLocalProperty(kIntKey, -2);
  EXPECT_EQ(-2, v.GetLocalProperty(kIntKey));
  v.SetLocalProperty(kIntKey, INT_MIN);
  EXPECT_EQ(INT_MIN, v.GetLocalProperty(kIntKey));

  v.SetLocalProperty(kStringKey, static_cast<const char*>(NULL));
  EXPECT_EQ(NULL, v.GetLocalProperty(kStringKey));
  v.SetLocalProperty(kStringKey, "squeamish");
  EXPECT_EQ(std::string("squeamish"), v.GetLocalProperty(kStringKey));
  v.SetLocalProperty(kStringKey, "ossifrage");
  EXPECT_EQ(std::string("ossifrage"), v.GetLocalProperty(kStringKey));

  // ClearProperty should restore the default value.
  v.ClearLocalProperty(kIntKey);
  EXPECT_EQ(-2, v.GetLocalProperty(kIntKey));
  v.ClearLocalProperty(kStringKey);
  EXPECT_EQ(std::string("squeamish"), v.GetLocalProperty(kStringKey));
}

namespace {

class TestProperty {
 public:
  TestProperty() {}
  virtual ~TestProperty() { last_deleted_ = this; }
  static TestProperty* last_deleted() { return last_deleted_; }

 private:
  static TestProperty* last_deleted_;
  MOJO_DISALLOW_COPY_AND_ASSIGN(TestProperty);
};

TestProperty* TestProperty::last_deleted_ = NULL;

DEFINE_OWNED_VIEW_PROPERTY_KEY(TestProperty, kOwnedKey, NULL);

}  // namespace

TEST_F(ViewTest, OwnedProperty) {
  TestProperty* p3 = NULL;
  {
    TestView v;
    EXPECT_EQ(NULL, v.GetLocalProperty(kOwnedKey));
    TestProperty* p1 = new TestProperty();
    v.SetLocalProperty(kOwnedKey, p1);
    EXPECT_EQ(p1, v.GetLocalProperty(kOwnedKey));
    EXPECT_EQ(NULL, TestProperty::last_deleted());

    TestProperty* p2 = new TestProperty();
    v.SetLocalProperty(kOwnedKey, p2);
    EXPECT_EQ(p2, v.GetLocalProperty(kOwnedKey));
    EXPECT_EQ(p1, TestProperty::last_deleted());

    v.ClearLocalProperty(kOwnedKey);
    EXPECT_EQ(NULL, v.GetLocalProperty(kOwnedKey));
    EXPECT_EQ(p2, TestProperty::last_deleted());

    p3 = new TestProperty();
    v.SetLocalProperty(kOwnedKey, p3);
    EXPECT_EQ(p3, v.GetLocalProperty(kOwnedKey));
    EXPECT_EQ(p2, TestProperty::last_deleted());
  }

  EXPECT_EQ(p3, TestProperty::last_deleted());
}

// ViewObserver --------------------------------------------------------

typedef testing::Test ViewObserverTest;

bool TreeChangeParamsMatch(const ViewObserver::TreeChangeParams& lhs,
                           const ViewObserver::TreeChangeParams& rhs) {
  return lhs.target == rhs.target &&  lhs.old_parent == rhs.old_parent &&
      lhs.new_parent == rhs.new_parent && lhs.receiver == rhs.receiver;
}

class TreeChangeObserver : public ViewObserver {
 public:
  explicit TreeChangeObserver(View* observee) : observee_(observee) {
    observee_->AddObserver(this);
  }
  ~TreeChangeObserver() override { observee_->RemoveObserver(this); }

  void Reset() {
    received_params_.clear();
  }

  const std::vector<TreeChangeParams>& received_params() {
    return received_params_;
  }

 private:
  // Overridden from ViewObserver:
  void OnTreeChanging(const TreeChangeParams& params) override {
     received_params_.push_back(params);
   }
   void OnTreeChanged(const TreeChangeParams& params) override {
    received_params_.push_back(params);
  }

  View* observee_;
  std::vector<TreeChangeParams> received_params_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TreeChangeObserver);
};

// Adds/Removes v11 to v1.
TEST_F(ViewObserverTest, TreeChange_SimpleAddRemove) {
  TestView v1;
  TreeChangeObserver o1(&v1);
  EXPECT_TRUE(o1.received_params().empty());

  TestView v11;
  TreeChangeObserver o11(&v11);
  EXPECT_TRUE(o11.received_params().empty());

  // Add.

  v1.AddChild(&v11);

  EXPECT_EQ(2U, o1.received_params().size());
  ViewObserver::TreeChangeParams p1;
  p1.target = &v11;
  p1.receiver = &v1;
  p1.old_parent = NULL;
  p1.new_parent = &v1;
  EXPECT_TRUE(TreeChangeParamsMatch(p1, o1.received_params().back()));

  EXPECT_EQ(2U, o11.received_params().size());
  ViewObserver::TreeChangeParams p11 = p1;
  p11.receiver = &v11;
  EXPECT_TRUE(TreeChangeParamsMatch(p11, o11.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p11, o11.received_params().back()));

  o1.Reset();
  o11.Reset();
  EXPECT_TRUE(o1.received_params().empty());
  EXPECT_TRUE(o11.received_params().empty());

  // Remove.

  v1.RemoveChild(&v11);

  EXPECT_EQ(2U, o1.received_params().size());
  p1.target = &v11;
  p1.receiver = &v1;
  p1.old_parent = &v1;
  p1.new_parent = NULL;
  EXPECT_TRUE(TreeChangeParamsMatch(p1, o1.received_params().front()));

  EXPECT_EQ(2U, o11.received_params().size());
  p11 = p1;
  p11.receiver = &v11;
  EXPECT_TRUE(TreeChangeParamsMatch(p11, o11.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p11, o11.received_params().back()));
}

// Creates these two trees:
// v1
//  +- v11
// v111
//  +- v1111
//  +- v1112
// Then adds/removes v111 from v11.
TEST_F(ViewObserverTest, TreeChange_NestedAddRemove) {
  TestView v1, v11, v111, v1111, v1112;

  // Root tree.
  v1.AddChild(&v11);

  // Tree to be attached.
  v111.AddChild(&v1111);
  v111.AddChild(&v1112);

  TreeChangeObserver o1(&v1), o11(&v11), o111(&v111), o1111(&v1111),
      o1112(&v1112);
  ViewObserver::TreeChangeParams p1, p11, p111, p1111, p1112;

  // Add.

  v11.AddChild(&v111);

  EXPECT_EQ(2U, o1.received_params().size());
  p1.target = &v111;
  p1.receiver = &v1;
  p1.old_parent = NULL;
  p1.new_parent = &v11;
  EXPECT_TRUE(TreeChangeParamsMatch(p1, o1.received_params().back()));

  EXPECT_EQ(2U, o11.received_params().size());
  p11 = p1;
  p11.receiver = &v11;
  EXPECT_TRUE(TreeChangeParamsMatch(p11, o11.received_params().back()));

  EXPECT_EQ(2U, o111.received_params().size());
  p111 = p11;
  p111.receiver = &v111;
  EXPECT_TRUE(TreeChangeParamsMatch(p111, o111.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p111, o111.received_params().back()));

  EXPECT_EQ(2U, o1111.received_params().size());
  p1111 = p111;
  p1111.receiver = &v1111;
  EXPECT_TRUE(TreeChangeParamsMatch(p1111, o1111.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p1111, o1111.received_params().back()));

  EXPECT_EQ(2U, o1112.received_params().size());
  p1112 = p111;
  p1112.receiver = &v1112;
  EXPECT_TRUE(TreeChangeParamsMatch(p1112, o1112.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p1112, o1112.received_params().back()));

  // Remove.
  o1.Reset();
  o11.Reset();
  o111.Reset();
  o1111.Reset();
  o1112.Reset();
  EXPECT_TRUE(o1.received_params().empty());
  EXPECT_TRUE(o11.received_params().empty());
  EXPECT_TRUE(o111.received_params().empty());
  EXPECT_TRUE(o1111.received_params().empty());
  EXPECT_TRUE(o1112.received_params().empty());

  v11.RemoveChild(&v111);

  EXPECT_EQ(2U, o1.received_params().size());
  p1.target = &v111;
  p1.receiver = &v1;
  p1.old_parent = &v11;
  p1.new_parent = NULL;
  EXPECT_TRUE(TreeChangeParamsMatch(p1, o1.received_params().front()));

  EXPECT_EQ(2U, o11.received_params().size());
  p11 = p1;
  p11.receiver = &v11;
  EXPECT_TRUE(TreeChangeParamsMatch(p11, o11.received_params().front()));

  EXPECT_EQ(2U, o111.received_params().size());
  p111 = p11;
  p111.receiver = &v111;
  EXPECT_TRUE(TreeChangeParamsMatch(p111, o111.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p111, o111.received_params().back()));

  EXPECT_EQ(2U, o1111.received_params().size());
  p1111 = p111;
  p1111.receiver = &v1111;
  EXPECT_TRUE(TreeChangeParamsMatch(p1111, o1111.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p1111, o1111.received_params().back()));

  EXPECT_EQ(2U, o1112.received_params().size());
  p1112 = p111;
  p1112.receiver = &v1112;
  EXPECT_TRUE(TreeChangeParamsMatch(p1112, o1112.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p1112, o1112.received_params().back()));
}

TEST_F(ViewObserverTest, TreeChange_Reparent) {
  TestView v1, v11, v12, v111;
  v1.AddChild(&v11);
  v1.AddChild(&v12);
  v11.AddChild(&v111);

  TreeChangeObserver o1(&v1), o11(&v11), o12(&v12), o111(&v111);

  // Reparent.
  v12.AddChild(&v111);

  // v1 (root) should see both changing and changed notifications.
  EXPECT_EQ(4U, o1.received_params().size());
  ViewObserver::TreeChangeParams p1;
  p1.target = &v111;
  p1.receiver = &v1;
  p1.old_parent = &v11;
  p1.new_parent = &v12;
  EXPECT_TRUE(TreeChangeParamsMatch(p1, o1.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p1, o1.received_params().back()));

  // v11 should see changing notifications.
  EXPECT_EQ(2U, o11.received_params().size());
  ViewObserver::TreeChangeParams p11;
  p11 = p1;
  p11.receiver = &v11;
  EXPECT_TRUE(TreeChangeParamsMatch(p11, o11.received_params().front()));

  // v12 should see changed notifications.
  EXPECT_EQ(2U, o12.received_params().size());
  ViewObserver::TreeChangeParams p12;
  p12 = p1;
  p12.receiver = &v12;
  EXPECT_TRUE(TreeChangeParamsMatch(p12, o12.received_params().back()));

  // v111 should see both changing and changed notifications.
  EXPECT_EQ(2U, o111.received_params().size());
  ViewObserver::TreeChangeParams p111;
  p111 = p1;
  p111.receiver = &v111;
  EXPECT_TRUE(TreeChangeParamsMatch(p111, o111.received_params().front()));
  EXPECT_TRUE(TreeChangeParamsMatch(p111, o111.received_params().back()));
}

namespace {

class OrderChangeObserver : public ViewObserver {
 public:
  struct Change {
    View* view;
    View* relative_view;
    OrderDirection direction;
  };
  typedef std::vector<Change> Changes;

  explicit OrderChangeObserver(View* observee) : observee_(observee) {
    observee_->AddObserver(this);
  }
  ~OrderChangeObserver() override { observee_->RemoveObserver(this); }

  Changes GetAndClearChanges() {
    Changes changes;
    changes_.swap(changes);
    return changes;
  }

 private:
  // Overridden from ViewObserver:
  void OnViewReordering(View* view,
                        View* relative_view,
                        OrderDirection direction) override {
    OnViewReordered(view, relative_view, direction);
  }

  void OnViewReordered(View* view,
                       View* relative_view,
                       OrderDirection direction) override {
    Change change;
    change.view = view;
    change.relative_view = relative_view;
    change.direction = direction;
    changes_.push_back(change);
  }

  View* observee_;
  Changes changes_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(OrderChangeObserver);
};

}  // namespace

TEST_F(ViewObserverTest, Order) {
  TestView v1, v11, v12, v13;
  v1.AddChild(&v11);
  v1.AddChild(&v12);
  v1.AddChild(&v13);

  // Order: v11, v12, v13
  EXPECT_EQ(3U, v1.children().size());
  EXPECT_EQ(&v11, v1.children().front());
  EXPECT_EQ(&v13, v1.children().back());

  {
    OrderChangeObserver observer(&v11);

    // Move v11 to front.
    // Resulting order: v12, v13, v11
    v11.MoveToFront();
    EXPECT_EQ(&v12, v1.children().front());
    EXPECT_EQ(&v11, v1.children().back());

    OrderChangeObserver::Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(2U, changes.size());
    EXPECT_EQ(&v11, changes[0].view);
    EXPECT_EQ(&v13, changes[0].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_ABOVE, changes[0].direction);

    EXPECT_EQ(&v11, changes[1].view);
    EXPECT_EQ(&v13, changes[1].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_ABOVE, changes[1].direction);
  }

  {
    OrderChangeObserver observer(&v11);

    // Move v11 to back.
    // Resulting order: v11, v12, v13
    v11.MoveToBack();
    EXPECT_EQ(&v11, v1.children().front());
    EXPECT_EQ(&v13, v1.children().back());

    OrderChangeObserver::Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(2U, changes.size());
    EXPECT_EQ(&v11, changes[0].view);
    EXPECT_EQ(&v12, changes[0].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_BELOW, changes[0].direction);

    EXPECT_EQ(&v11, changes[1].view);
    EXPECT_EQ(&v12, changes[1].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_BELOW, changes[1].direction);
  }

  {
    OrderChangeObserver observer(&v11);

    // Move v11 above v12.
    // Resulting order: v12. v11, v13
    v11.Reorder(&v12, ORDER_DIRECTION_ABOVE);
    EXPECT_EQ(&v12, v1.children().front());
    EXPECT_EQ(&v13, v1.children().back());

    OrderChangeObserver::Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(2U, changes.size());
    EXPECT_EQ(&v11, changes[0].view);
    EXPECT_EQ(&v12, changes[0].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_ABOVE, changes[0].direction);

    EXPECT_EQ(&v11, changes[1].view);
    EXPECT_EQ(&v12, changes[1].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_ABOVE, changes[1].direction);
  }

  {
    OrderChangeObserver observer(&v11);

    // Move v11 below v12.
    // Resulting order: v11, v12, v13
    v11.Reorder(&v12, ORDER_DIRECTION_BELOW);
    EXPECT_EQ(&v11, v1.children().front());
    EXPECT_EQ(&v13, v1.children().back());

    OrderChangeObserver::Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(2U, changes.size());
    EXPECT_EQ(&v11, changes[0].view);
    EXPECT_EQ(&v12, changes[0].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_BELOW, changes[0].direction);

    EXPECT_EQ(&v11, changes[1].view);
    EXPECT_EQ(&v12, changes[1].relative_view);
    EXPECT_EQ(ORDER_DIRECTION_BELOW, changes[1].direction);
  }
}

namespace {

typedef std::vector<std::string> Changes;

std::string ViewIdToString(Id id) {
  return (id == 0) ? "null" :
      base::StringPrintf("%d,%d", HiWord(id), LoWord(id));
}

std::string RectToString(const Rect& rect) {
  return base::StringPrintf("%d,%d %dx%d",
                            rect.x, rect.y, rect.width, rect.height);
}

class BoundsChangeObserver : public ViewObserver {
 public:
  explicit BoundsChangeObserver(View* view) : view_(view) {
    view_->AddObserver(this);
  }
  ~BoundsChangeObserver() override { view_->RemoveObserver(this); }

  Changes GetAndClearChanges() {
    Changes changes;
    changes.swap(changes_);
    return changes;
  }

 private:
  // Overridden from ViewObserver:
  void OnViewBoundsChanging(View* view,
                            const Rect& old_bounds,
                            const Rect& new_bounds) override {
    changes_.push_back(
        base::StringPrintf(
            "view=%s old_bounds=%s new_bounds=%s phase=changing",
            ViewIdToString(view->id()).c_str(),
            RectToString(old_bounds).c_str(),
            RectToString(new_bounds).c_str()));
  }
  void OnViewBoundsChanged(View* view,
                           const Rect& old_bounds,
                           const Rect& new_bounds) override {
    changes_.push_back(
        base::StringPrintf(
            "view=%s old_bounds=%s new_bounds=%s phase=changed",
            ViewIdToString(view->id()).c_str(),
            RectToString(old_bounds).c_str(),
            RectToString(new_bounds).c_str()));
  }

  View* view_;
  Changes changes_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(BoundsChangeObserver);
};

}  // namespace

TEST_F(ViewObserverTest, SetBounds) {
  TestView v1;
  {
    BoundsChangeObserver observer(&v1);
    Rect rect;
    rect.width = rect.height = 100;
    v1.SetBounds(rect);

    Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(2U, changes.size());
    EXPECT_EQ(
        "view=0,1 old_bounds=0,0 0x0 new_bounds=0,0 100x100 phase=changing",
        changes[0]);
    EXPECT_EQ(
        "view=0,1 old_bounds=0,0 0x0 new_bounds=0,0 100x100 phase=changed",
        changes[1]);
  }
}

namespace {

class VisibilityChangeObserver : public ViewObserver {
 public:
  explicit VisibilityChangeObserver(View* view) : view_(view) {
    view_->AddObserver(this);
  }
  ~VisibilityChangeObserver() override { view_->RemoveObserver(this); }

  Changes GetAndClearChanges() {
    Changes changes;
    changes.swap(changes_);
    return changes;
  }

 private:
  // Overridden from ViewObserver:
  void OnViewVisibilityChanging(View* view) override {
    changes_.push_back(
        base::StringPrintf("view=%s phase=changing visibility=%s",
                           ViewIdToString(view->id()).c_str(),
                           view->visible() ? "true" : "false"));
  }
  void OnViewVisibilityChanged(View* view) override {
    changes_.push_back(base::StringPrintf("view=%s phase=changed visibility=%s",
                                          ViewIdToString(view->id()).c_str(),
                                          view->visible() ? "true" : "false"));
  }

  View* view_;
  Changes changes_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(VisibilityChangeObserver);
};

}  // namespace

TEST_F(ViewObserverTest, SetVisible) {
  TestView v1;
  EXPECT_TRUE(v1.visible());
  {
    // Change visibility from true to false and make sure we get notifications.
    VisibilityChangeObserver observer(&v1);
    v1.SetVisible(false);

    Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(2U, changes.size());
    EXPECT_EQ("view=0,1 phase=changing visibility=true", changes[0]);
    EXPECT_EQ("view=0,1 phase=changed visibility=false", changes[1]);
  }
  {
    // Set visible to existing value and verify no notifications.
    VisibilityChangeObserver observer(&v1);
    v1.SetVisible(false);
    EXPECT_TRUE(observer.GetAndClearChanges().empty());
  }
}

TEST_F(ViewObserverTest, SetVisibleParent) {
  TestView parent;
  ViewPrivate(&parent).set_id(1);
  TestView child;
  ViewPrivate(&child).set_id(2);
  parent.AddChild(&child);
  EXPECT_TRUE(parent.visible());
  EXPECT_TRUE(child.visible());
  {
    // Change visibility from true to false and make sure we get notifications
    // on the parent.
    VisibilityChangeObserver observer(&parent);
    child.SetVisible(false);

    Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(1U, changes.size());
    EXPECT_EQ("view=0,2 phase=changed visibility=false", changes[0]);
  }
}

TEST_F(ViewObserverTest, SetVisibleChild) {
  TestView parent;
  ViewPrivate(&parent).set_id(1);
  TestView child;
  ViewPrivate(&child).set_id(2);
  parent.AddChild(&child);
  EXPECT_TRUE(parent.visible());
  EXPECT_TRUE(child.visible());
  {
    // Change visibility from true to false and make sure we get notifications
    // on the child.
    VisibilityChangeObserver observer(&child);
    parent.SetVisible(false);

    Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(1U, changes.size());
    EXPECT_EQ("view=0,1 phase=changed visibility=false", changes[0]);
  }
}

namespace {

class SharedPropertyChangeObserver : public ViewObserver {
 public:
  explicit SharedPropertyChangeObserver(View* view) : view_(view) {
    view_->AddObserver(this);
  }
  ~SharedPropertyChangeObserver() override { view_->RemoveObserver(this); }

  Changes GetAndClearChanges() {
    Changes changes;
    changes.swap(changes_);
    return changes;
  }

 private:
  // Overridden from ViewObserver:
  void OnViewSharedPropertyChanged(
      View* view,
      const std::string& name,
      const std::vector<uint8_t>* old_data,
      const std::vector<uint8_t>* new_data) override {
    changes_.push_back(base::StringPrintf(
        "view=%s shared property changed key=%s old_value=%s new_value=%s",
        ViewIdToString(view->id()).c_str(), name.c_str(),
        VectorToString(old_data).c_str(), VectorToString(new_data).c_str()));
  }

  std::string VectorToString(const std::vector<uint8_t>* data) {
    if (!data)
      return "NULL";
    std::string s;
    for (char c : *data)
      s += c;
    return s;
  }

  View* view_;
  Changes changes_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SharedPropertyChangeObserver);
};

}  // namespace

TEST_F(ViewObserverTest, SetLocalProperty) {
  TestView v1;
  std::vector<uint8_t> one(1, '1');

  {
    // Change visibility from true to false and make sure we get notifications.
    SharedPropertyChangeObserver observer(&v1);
    v1.SetSharedProperty("one", &one);
    Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(1U, changes.size());
    EXPECT_EQ(
        "view=0,1 shared property changed key=one old_value=NULL new_value=1",
        changes[0]);
    EXPECT_EQ(1U, v1.shared_properties().size());
  }
  {
    // Set visible to existing value and verify no notifications.
    SharedPropertyChangeObserver observer(&v1);
    v1.SetSharedProperty("one", &one);
    EXPECT_TRUE(observer.GetAndClearChanges().empty());
    EXPECT_EQ(1U, v1.shared_properties().size());
  }
  {
    // Set the value to NULL to delete it.
    // Change visibility from true to false and make sure we get notifications.
    SharedPropertyChangeObserver observer(&v1);
    v1.SetSharedProperty("one", NULL);
    Changes changes = observer.GetAndClearChanges();
    ASSERT_EQ(1U, changes.size());
    EXPECT_EQ(
        "view=0,1 shared property changed key=one old_value=1 new_value=NULL",
        changes[0]);
    EXPECT_EQ(0U, v1.shared_properties().size());
  }
  {
    // Setting a null property to null shouldn't update us.
    SharedPropertyChangeObserver observer(&v1);
    v1.SetSharedProperty("one", NULL);
    EXPECT_TRUE(observer.GetAndClearChanges().empty());
    EXPECT_EQ(0U, v1.shared_properties().size());
  }
}

namespace {

typedef std::pair<const void*, intptr_t> PropertyChangeInfo;

class LocalPropertyChangeObserver : public ViewObserver {
 public:
  explicit LocalPropertyChangeObserver(View* view)
      : view_(view),
        property_key_(nullptr),
        old_property_value_(-1) {
    view_->AddObserver(this);
  }
  ~LocalPropertyChangeObserver() override { view_->RemoveObserver(this); }

  PropertyChangeInfo PropertyChangeInfoAndClear() {
    PropertyChangeInfo result(property_key_, old_property_value_);
    property_key_ = NULL;
    old_property_value_ = -3;
    return result;
  }

 private:
  void OnViewLocalPropertyChanged(View* window,
                                  const void* key,
                                  intptr_t old) override {
    property_key_ = key;
    old_property_value_ = old;
  }

  View* view_;
  const void* property_key_;
  intptr_t old_property_value_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(LocalPropertyChangeObserver);
};

}  // namespace

TEST_F(ViewObserverTest, LocalPropertyChanged) {
  TestView v1;
  LocalPropertyChangeObserver o(&v1);

  static const ViewProperty<int> prop = {-2};

  v1.SetLocalProperty(&prop, 1);
  EXPECT_EQ(PropertyChangeInfo(&prop, -2), o.PropertyChangeInfoAndClear());
  v1.SetLocalProperty(&prop, -2);
  EXPECT_EQ(PropertyChangeInfo(&prop, 1), o.PropertyChangeInfoAndClear());
  v1.SetLocalProperty(&prop, 3);
  EXPECT_EQ(PropertyChangeInfo(&prop, -2), o.PropertyChangeInfoAndClear());
  v1.ClearLocalProperty(&prop);
  EXPECT_EQ(PropertyChangeInfo(&prop, 3), o.PropertyChangeInfoAndClear());

  // Sanity check to see if |PropertyChangeInfoAndClear| really clears.
  EXPECT_EQ(PropertyChangeInfo(
      reinterpret_cast<const void*>(NULL), -3), o.PropertyChangeInfoAndClear());
}

}  // namespace mojo
