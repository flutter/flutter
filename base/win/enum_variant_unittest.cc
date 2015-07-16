// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/enum_variant.h"

#include "base/win/scoped_com_initializer.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace win {

TEST(EnumVariantTest, EmptyEnumVariant) {
  ScopedCOMInitializer com_initializer;

  EnumVariant* ev = new EnumVariant(0);
  ev->AddRef();

  IUnknown* iunknown;
  EXPECT_TRUE(SUCCEEDED(
      ev->QueryInterface(IID_IUnknown, reinterpret_cast<void**>(&iunknown))));
  iunknown->Release();

  IEnumVARIANT* ienumvariant;
  EXPECT_TRUE(SUCCEEDED(
      ev->QueryInterface(IID_IEnumVARIANT,
                         reinterpret_cast<void**>(&ienumvariant))));
  EXPECT_EQ(ev, ienumvariant);
  ienumvariant->Release();

  VARIANT out_element;
  ULONG out_received = 0;
  EXPECT_EQ(S_FALSE, ev->Next(1, &out_element, &out_received));
  EXPECT_EQ(0, out_received);

  EXPECT_EQ(S_FALSE, ev->Skip(1));

  EXPECT_EQ(S_OK, ev->Reset());

  IEnumVARIANT* ev2 = NULL;
  EXPECT_EQ(S_OK, ev->Clone(&ev2));

  EXPECT_NE(static_cast<IEnumVARIANT*>(NULL), ev2);
  EXPECT_NE(ev, ev2);
  EXPECT_EQ(S_FALSE, ev2->Skip(1));
  EXPECT_EQ(S_OK, ev2->Reset());

  ULONG ev2_finalrefcount = ev2->Release();
  EXPECT_EQ(0, ev2_finalrefcount);

  ULONG ev_finalrefcount = ev->Release();
  EXPECT_EQ(0, ev_finalrefcount);
}

TEST(EnumVariantTest, SimpleEnumVariant) {
  ScopedCOMInitializer com_initializer;

  EnumVariant* ev = new EnumVariant(3);
  ev->AddRef();
  ev->ItemAt(0)->vt = VT_I4;
  ev->ItemAt(0)->lVal = 10;
  ev->ItemAt(1)->vt = VT_I4;
  ev->ItemAt(1)->lVal = 20;
  ev->ItemAt(2)->vt = VT_I4;
  ev->ItemAt(2)->lVal = 30;

  // Get elements one at a time.
  VARIANT out_element;
  ULONG out_received = 0;
  EXPECT_EQ(S_OK, ev->Next(1, &out_element, &out_received));
  EXPECT_EQ(1, out_received);
  EXPECT_EQ(VT_I4, out_element.vt);
  EXPECT_EQ(10, out_element.lVal);
  EXPECT_EQ(S_OK, ev->Skip(1));
  EXPECT_EQ(S_OK, ev->Next(1, &out_element, &out_received));
  EXPECT_EQ(1, out_received);
  EXPECT_EQ(VT_I4, out_element.vt);
  EXPECT_EQ(30, out_element.lVal);
  EXPECT_EQ(S_FALSE, ev->Next(1, &out_element, &out_received));

  // Reset and get all elements at once.
  VARIANT out_elements[3];
  EXPECT_EQ(S_OK, ev->Reset());
  EXPECT_EQ(S_OK, ev->Next(3, out_elements, &out_received));
  EXPECT_EQ(3, out_received);
  EXPECT_EQ(VT_I4, out_elements[0].vt);
  EXPECT_EQ(10, out_elements[0].lVal);
  EXPECT_EQ(VT_I4, out_elements[1].vt);
  EXPECT_EQ(20, out_elements[1].lVal);
  EXPECT_EQ(VT_I4, out_elements[2].vt);
  EXPECT_EQ(30, out_elements[2].lVal);
  EXPECT_EQ(S_FALSE, ev->Next(1, &out_element, &out_received));

  // Clone it.
  IEnumVARIANT* ev2 = NULL;
  EXPECT_EQ(S_OK, ev->Clone(&ev2));
  EXPECT_TRUE(ev2 != NULL);
  EXPECT_EQ(S_FALSE, ev->Next(1, &out_element, &out_received));
  EXPECT_EQ(S_OK, ev2->Reset());
  EXPECT_EQ(S_OK, ev2->Next(3, out_elements, &out_received));
  EXPECT_EQ(3, out_received);
  EXPECT_EQ(VT_I4, out_elements[0].vt);
  EXPECT_EQ(10, out_elements[0].lVal);
  EXPECT_EQ(VT_I4, out_elements[1].vt);
  EXPECT_EQ(20, out_elements[1].lVal);
  EXPECT_EQ(VT_I4, out_elements[2].vt);
  EXPECT_EQ(30, out_elements[2].lVal);
  EXPECT_EQ(S_FALSE, ev2->Next(1, &out_element, &out_received));

  ULONG ev2_finalrefcount = ev2->Release();
  EXPECT_EQ(0, ev2_finalrefcount);

  ULONG ev_finalrefcount = ev->Release();
  EXPECT_EQ(0, ev_finalrefcount);
}

}  // namespace win
}  // namespace base
