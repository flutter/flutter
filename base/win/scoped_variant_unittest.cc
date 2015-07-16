// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/scoped_variant.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace win {

namespace {

static const wchar_t kTestString1[] = L"Used to create BSTRs";
static const wchar_t kTestString2[] = L"Also used to create BSTRs";

void GiveMeAVariant(VARIANT* ret) {
  EXPECT_TRUE(ret != NULL);
  ret->vt = VT_BSTR;
  V_BSTR(ret) = ::SysAllocString(kTestString1);
}

// A dummy IDispatch implementation (if you can call it that).
// The class does nothing intelligent really.  Only increments a counter
// when AddRef is called and decrements it when Release is called.
class FakeComObject : public IDispatch {
 public:
  FakeComObject() : ref_(0) {
  }

  STDMETHOD_(DWORD, AddRef)() override {
    ref_++;
    return ref_;
  }

  STDMETHOD_(DWORD, Release)() override {
    ref_--;
    return ref_;
  }

  STDMETHOD(QueryInterface)(REFIID, void**) override { return E_NOTIMPL; }

  STDMETHOD(GetTypeInfoCount)(UINT*) override { return E_NOTIMPL; }

  STDMETHOD(GetTypeInfo)(UINT, LCID, ITypeInfo**) override { return E_NOTIMPL; }

  STDMETHOD(GetIDsOfNames)(REFIID, LPOLESTR*, UINT, LCID, DISPID*) override {
    return E_NOTIMPL;
  }

  STDMETHOD(Invoke)(DISPID,
                    REFIID,
                    LCID,
                    WORD,
                    DISPPARAMS*,
                    VARIANT*,
                    EXCEPINFO*,
                    UINT*) override {
    return E_NOTIMPL;
  }

  // A way to check the internal reference count of the class.
  int ref_count() const {
    return ref_;
  }

 protected:
  int ref_;
};

}  // namespace

TEST(ScopedVariantTest, ScopedVariant) {
  ScopedVariant var;
  EXPECT_TRUE(var.type() == VT_EMPTY);
  // V_BSTR(var.ptr()) = NULL;  <- NOTE: Assignment like that is not supported.

  ScopedVariant var_bstr(L"VT_BSTR");
  EXPECT_EQ(VT_BSTR, V_VT(var_bstr.ptr()));
  EXPECT_TRUE(V_BSTR(var_bstr.ptr()) != NULL);  // can't use EXPECT_NE for BSTR
  var_bstr.Reset();
  EXPECT_NE(VT_BSTR, V_VT(var_bstr.ptr()));
  var_bstr.Set(kTestString2);
  EXPECT_EQ(VT_BSTR, V_VT(var_bstr.ptr()));

  VARIANT tmp = var_bstr.Release();
  EXPECT_EQ(VT_EMPTY, V_VT(var_bstr.ptr()));
  EXPECT_EQ(VT_BSTR, V_VT(&tmp));
  EXPECT_EQ(0, lstrcmp(V_BSTR(&tmp), kTestString2));

  var.Reset(tmp);
  EXPECT_EQ(VT_BSTR, V_VT(var.ptr()));
  EXPECT_EQ(0, lstrcmpW(V_BSTR(var.ptr()), kTestString2));

  var_bstr.Swap(var);
  EXPECT_EQ(VT_EMPTY, V_VT(var.ptr()));
  EXPECT_EQ(VT_BSTR, V_VT(var_bstr.ptr()));
  EXPECT_EQ(0, lstrcmpW(V_BSTR(var_bstr.ptr()), kTestString2));
  var_bstr.Reset();

  // Test the Compare and Copy routines.
  GiveMeAVariant(var_bstr.Receive());
  ScopedVariant var_bstr2(V_BSTR(var_bstr.ptr()));
  EXPECT_EQ(0, var_bstr.Compare(var_bstr2));
  var_bstr2.Reset();
  EXPECT_NE(0, var_bstr.Compare(var_bstr2));
  var_bstr2.Reset(var_bstr.Copy());
  EXPECT_EQ(0, var_bstr.Compare(var_bstr2));
  var_bstr2.Reset();
  var_bstr2.Set(V_BSTR(var_bstr.ptr()));
  EXPECT_EQ(0, var_bstr.Compare(var_bstr2));
  var_bstr2.Reset();
  var_bstr.Reset();

  // Test for the SetDate setter.
  SYSTEMTIME sys_time;
  ::GetSystemTime(&sys_time);
  DATE date;
  ::SystemTimeToVariantTime(&sys_time, &date);
  var.Reset();
  var.SetDate(date);
  EXPECT_EQ(VT_DATE, var.type());
  EXPECT_EQ(date, V_DATE(var.ptr()));

  // Simple setter tests.  These do not require resetting the variant
  // after each test since the variant type is not "leakable" (i.e. doesn't
  // need to be freed explicitly).

  // We need static cast here since char defaults to int (!?).
  var.Set(static_cast<int8>('v'));
  EXPECT_EQ(VT_I1, var.type());
  EXPECT_EQ('v', V_I1(var.ptr()));

  var.Set(static_cast<short>(123));
  EXPECT_EQ(VT_I2, var.type());
  EXPECT_EQ(123, V_I2(var.ptr()));

  var.Set(static_cast<int32>(123));
  EXPECT_EQ(VT_I4, var.type());
  EXPECT_EQ(123, V_I4(var.ptr()));

  var.Set(static_cast<int64>(123));
  EXPECT_EQ(VT_I8, var.type());
  EXPECT_EQ(123, V_I8(var.ptr()));

  var.Set(static_cast<uint8>(123));
  EXPECT_EQ(VT_UI1, var.type());
  EXPECT_EQ(123, V_UI1(var.ptr()));

  var.Set(static_cast<unsigned short>(123));
  EXPECT_EQ(VT_UI2, var.type());
  EXPECT_EQ(123, V_UI2(var.ptr()));

  var.Set(static_cast<uint32>(123));
  EXPECT_EQ(VT_UI4, var.type());
  EXPECT_EQ(123, V_UI4(var.ptr()));

  var.Set(static_cast<uint64>(123));
  EXPECT_EQ(VT_UI8, var.type());
  EXPECT_EQ(123, V_UI8(var.ptr()));

  var.Set(123.123f);
  EXPECT_EQ(VT_R4, var.type());
  EXPECT_EQ(123.123f, V_R4(var.ptr()));

  var.Set(static_cast<double>(123.123));
  EXPECT_EQ(VT_R8, var.type());
  EXPECT_EQ(123.123, V_R8(var.ptr()));

  var.Set(true);
  EXPECT_EQ(VT_BOOL, var.type());
  EXPECT_EQ(VARIANT_TRUE, V_BOOL(var.ptr()));
  var.Set(false);
  EXPECT_EQ(VT_BOOL, var.type());
  EXPECT_EQ(VARIANT_FALSE, V_BOOL(var.ptr()));

  // Com interface tests

  var.Set(static_cast<IDispatch*>(NULL));
  EXPECT_EQ(VT_DISPATCH, var.type());
  EXPECT_EQ(NULL, V_DISPATCH(var.ptr()));
  var.Reset();

  var.Set(static_cast<IUnknown*>(NULL));
  EXPECT_EQ(VT_UNKNOWN, var.type());
  EXPECT_EQ(NULL, V_UNKNOWN(var.ptr()));
  var.Reset();

  FakeComObject faker;
  EXPECT_EQ(0, faker.ref_count());
  var.Set(static_cast<IDispatch*>(&faker));
  EXPECT_EQ(VT_DISPATCH, var.type());
  EXPECT_EQ(&faker, V_DISPATCH(var.ptr()));
  EXPECT_EQ(1, faker.ref_count());
  var.Reset();
  EXPECT_EQ(0, faker.ref_count());

  var.Set(static_cast<IUnknown*>(&faker));
  EXPECT_EQ(VT_UNKNOWN, var.type());
  EXPECT_EQ(&faker, V_UNKNOWN(var.ptr()));
  EXPECT_EQ(1, faker.ref_count());
  var.Reset();
  EXPECT_EQ(0, faker.ref_count());

  {
    ScopedVariant disp_var(&faker);
    EXPECT_EQ(VT_DISPATCH, disp_var.type());
    EXPECT_EQ(&faker, V_DISPATCH(disp_var.ptr()));
    EXPECT_EQ(1, faker.ref_count());
  }
  EXPECT_EQ(0, faker.ref_count());

  {
    ScopedVariant ref1(&faker);
    EXPECT_EQ(1, faker.ref_count());
    ScopedVariant ref2(static_cast<const VARIANT&>(ref1));
    EXPECT_EQ(2, faker.ref_count());
    ScopedVariant ref3;
    ref3 = static_cast<const VARIANT&>(ref2);
    EXPECT_EQ(3, faker.ref_count());
  }
  EXPECT_EQ(0, faker.ref_count());

  {
    ScopedVariant unk_var(static_cast<IUnknown*>(&faker));
    EXPECT_EQ(VT_UNKNOWN, unk_var.type());
    EXPECT_EQ(&faker, V_UNKNOWN(unk_var.ptr()));
    EXPECT_EQ(1, faker.ref_count());
  }
  EXPECT_EQ(0, faker.ref_count());

  VARIANT raw;
  raw.vt = VT_UNKNOWN;
  raw.punkVal = &faker;
  EXPECT_EQ(0, faker.ref_count());
  var.Set(raw);
  EXPECT_EQ(1, faker.ref_count());
  var.Reset();
  EXPECT_EQ(0, faker.ref_count());

  {
    ScopedVariant number(123);
    EXPECT_EQ(VT_I4, number.type());
    EXPECT_EQ(123, V_I4(number.ptr()));
  }

  // SAFEARRAY tests
  var.Set(static_cast<SAFEARRAY*>(NULL));
  EXPECT_EQ(VT_EMPTY, var.type());

  SAFEARRAY* sa = ::SafeArrayCreateVector(VT_UI1, 0, 100);
  ASSERT_TRUE(sa != NULL);

  var.Set(sa);
  EXPECT_TRUE(ScopedVariant::IsLeakableVarType(var.type()));
  EXPECT_EQ(VT_ARRAY | VT_UI1, var.type());
  EXPECT_EQ(sa, V_ARRAY(var.ptr()));
  // The array is destroyed in the destructor of var.
}

}  // namespace win
}  // namespace base
