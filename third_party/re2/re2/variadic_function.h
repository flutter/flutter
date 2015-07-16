// Copyright 2010 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef RE2_VARIADIC_FUNCTION_H_
#define RE2_VARIADIC_FUNCTION_H_

namespace re2 {

template <typename Result, typename Param0, typename Param1, typename Arg,
          Result (*Func)(Param0, Param1, const Arg* const [], int count)>
class VariadicFunction2 {
 public:
  Result operator()(Param0 p0, Param1 p1) const {
    return Func(p0, p1, 0, 0);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0) const {
    const Arg* const args[] = { &a0 };
    return Func(p0, p1, args, 1);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1) const {
    const Arg* const args[] = { &a0, &a1 };
    return Func(p0, p1, args, 2);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2) const {
    const Arg* const args[] = { &a0, &a1, &a2 };
    return Func(p0, p1, args, 3);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3 };
    return Func(p0, p1, args, 4);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4 };
    return Func(p0, p1, args, 5);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5 };
    return Func(p0, p1, args, 6);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6 };
    return Func(p0, p1, args, 7);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7 };
    return Func(p0, p1, args, 8);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8 };
    return Func(p0, p1, args, 9);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9 };
    return Func(p0, p1, args, 10);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10 };
    return Func(p0, p1, args, 11);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11 };
    return Func(p0, p1, args, 12);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12 };
    return Func(p0, p1, args, 13);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13 };
    return Func(p0, p1, args, 14);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14 };
    return Func(p0, p1, args, 15);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15 };
    return Func(p0, p1, args, 16);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16 };
    return Func(p0, p1, args, 17);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17 };
    return Func(p0, p1, args, 18);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18 };
    return Func(p0, p1, args, 19);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19 };
    return Func(p0, p1, args, 20);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19,
        &a20 };
    return Func(p0, p1, args, 21);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21 };
    return Func(p0, p1, args, 22);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22 };
    return Func(p0, p1, args, 23);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23 };
    return Func(p0, p1, args, 24);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24 };
    return Func(p0, p1, args, 25);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24, const Arg& a25) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24, &a25 };
    return Func(p0, p1, args, 26);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24, const Arg& a25,
      const Arg& a26) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24, &a25, &a26 };
    return Func(p0, p1, args, 27);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24, const Arg& a25,
      const Arg& a26, const Arg& a27) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24, &a25, &a26, &a27 };
    return Func(p0, p1, args, 28);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24, const Arg& a25,
      const Arg& a26, const Arg& a27, const Arg& a28) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24, &a25, &a26, &a27, &a28 };
    return Func(p0, p1, args, 29);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24, const Arg& a25,
      const Arg& a26, const Arg& a27, const Arg& a28, const Arg& a29) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24, &a25, &a26, &a27, &a28, &a29 };
    return Func(p0, p1, args, 30);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24, const Arg& a25,
      const Arg& a26, const Arg& a27, const Arg& a28, const Arg& a29,
      const Arg& a30) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24, &a25, &a26, &a27, &a28, &a29, &a30 };
    return Func(p0, p1, args, 31);
  }

  Result operator()(Param0 p0, Param1 p1, const Arg& a0, const Arg& a1,
      const Arg& a2, const Arg& a3, const Arg& a4, const Arg& a5,
      const Arg& a6, const Arg& a7, const Arg& a8, const Arg& a9,
      const Arg& a10, const Arg& a11, const Arg& a12, const Arg& a13,
      const Arg& a14, const Arg& a15, const Arg& a16, const Arg& a17,
      const Arg& a18, const Arg& a19, const Arg& a20, const Arg& a21,
      const Arg& a22, const Arg& a23, const Arg& a24, const Arg& a25,
      const Arg& a26, const Arg& a27, const Arg& a28, const Arg& a29,
      const Arg& a30, const Arg& a31) const {
    const Arg* const args[] = { &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8,
        &a9, &a10, &a11, &a12, &a13, &a14, &a15, &a16, &a17, &a18, &a19, &a20,
        &a21, &a22, &a23, &a24, &a25, &a26, &a27, &a28, &a29, &a30, &a31 };
    return Func(p0, p1, args, 32);
  }
};

}  // namespace re2

#endif  // RE2_VARIADIC_FUNCTION_H_
