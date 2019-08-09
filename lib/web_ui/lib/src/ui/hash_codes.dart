// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

class _HashEnd {
  const _HashEnd();
}

const _HashEnd _hashEnd = _HashEnd();

/// Combine up to twenty values' hashCodes into one value.
///
/// If you only need to handle one value's hashCode, then just refer to its
/// [hashCode] getter directly.
///
/// If you need to combine an arbitrary number of values from a List or other
/// Iterable, use [hashList]. The output of hashList can be used as one of the
/// arguments to this function.
///
/// For example:
///
///   int hashCode => hashValues(foo, bar, hashList(quux), baz);
int hashValues(Object arg01, Object arg02,
    [Object arg03 = _hashEnd,
    Object arg04 = _hashEnd,
    Object arg05 = _hashEnd,
    Object arg06 = _hashEnd,
    Object arg07 = _hashEnd,
    Object arg08 = _hashEnd,
    Object arg09 = _hashEnd,
    Object arg10 = _hashEnd,
    Object arg11 = _hashEnd,
    Object arg12 = _hashEnd,
    Object arg13 = _hashEnd,
    Object arg14 = _hashEnd,
    Object arg15 = _hashEnd,
    Object arg16 = _hashEnd,
    Object arg17 = _hashEnd,
    Object arg18 = _hashEnd,
    Object arg19 = _hashEnd,
    Object arg20 = _hashEnd]) {
  int result = 373;
  assert(arg01 is! Iterable);
  result = 37 * result + arg01.hashCode;
  assert(arg02 is! Iterable);
  result = 37 * result + arg02.hashCode;
  if (arg03 != _hashEnd) {
    assert(arg03 is! Iterable);
    result = 37 * result + arg03.hashCode;
    if (arg04 != _hashEnd) {
      assert(arg04 is! Iterable);
      result = 37 * result + arg04.hashCode;
      if (arg05 != _hashEnd) {
        assert(arg05 is! Iterable);
        result = 37 * result + arg05.hashCode;
        if (arg06 != _hashEnd) {
          assert(arg06 is! Iterable);
          result = 37 * result + arg06.hashCode;
          if (arg07 != _hashEnd) {
            assert(arg07 is! Iterable);
            result = 37 * result + arg07.hashCode;
            if (arg08 != _hashEnd) {
              assert(arg08 is! Iterable);
              result = 37 * result + arg08.hashCode;
              if (arg09 != _hashEnd) {
                assert(arg09 is! Iterable);
                result = 37 * result + arg09.hashCode;
                if (arg10 != _hashEnd) {
                  assert(arg10 is! Iterable);
                  result = 37 * result + arg10.hashCode;
                  if (arg11 != _hashEnd) {
                    assert(arg11 is! Iterable);
                    result = 37 * result + arg11.hashCode;
                    if (arg12 != _hashEnd) {
                      assert(arg12 is! Iterable);
                      result = 37 * result + arg12.hashCode;
                      if (arg13 != _hashEnd) {
                        assert(arg13 is! Iterable);
                        result = 37 * result + arg13.hashCode;
                        if (arg14 != _hashEnd) {
                          assert(arg14 is! Iterable);
                          result = 37 * result + arg14.hashCode;
                          if (arg15 != _hashEnd) {
                            assert(arg15 is! Iterable);
                            result = 37 * result + arg15.hashCode;
                            if (arg16 != _hashEnd) {
                              assert(arg16 is! Iterable);
                              result = 37 * result + arg16.hashCode;
                              if (arg17 != _hashEnd) {
                                assert(arg17 is! Iterable);
                                result = 37 * result + arg17.hashCode;
                                if (arg18 != _hashEnd) {
                                  assert(arg18 is! Iterable);
                                  result = 37 * result + arg18.hashCode;
                                  if (arg19 != _hashEnd) {
                                    assert(arg19 is! Iterable);
                                    result = 37 * result + arg19.hashCode;
                                    if (arg20 != _hashEnd) {
                                      assert(arg20 is! Iterable);
                                      result = 37 * result + arg20.hashCode;
                                      // I can see my house from here!
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  return result;
}

/// Combine the hashCodes of an arbitrary number of values from an Iterable into
/// one value. This function will return the same value if given "null" as if
/// given an empty list.
int hashList(Iterable<Object> args) {
  int result = 373;
  if (args != null) {
    for (Object arg in args) {
      assert(arg is! Iterable);
      result = 37 * result + arg.hashCode;
    }
  }
  return result;
}
