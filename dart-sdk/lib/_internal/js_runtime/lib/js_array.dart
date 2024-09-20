// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

class _Growable {
  const _Growable();
}

const _ListConstructorSentinel = _Growable();

/// The interceptor class for [List]. The compiler recognizes this
/// class as an interceptor, and changes references to [:this:] to
/// actually use the receiver of the method, which is generated as an extra
/// argument added to each member.
class JSArray<E> extends JavaScriptObject implements List<E>, JSIndexable<E> {
  const JSArray();

  /// Returns a fresh JavaScript Array, marked as fixed-length. The holes in the
  /// array yield `undefined`, making the Dart List appear to be filled with
  /// `null` values.
  ///
  /// [length] must be a non-negative integer.
  factory JSArray.fixed(int length) {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode, and against `new Array(null)` which creates a single
    // element Array containing `null`.
    if (length is! int) {
      throw ArgumentError.value(length, 'length', 'is not an integer');
    }
    // The JavaScript Array constructor with one argument throws if the value is
    // not a UInt32 but the error message does not contain the bad value. Give a
    // better error message.
    int maxJSArrayLength = 0xFFFFFFFF;
    if (length < 0 || length > maxJSArrayLength) {
      throw RangeError.range(length, 0, maxJSArrayLength, 'length');
    }
    return JSArray<E>.markFixed(JS('', 'new Array(#)', length));
  }

  /// Returns a fresh JavaScript Array, marked as fixed-length.  The Array is
  /// allocated but no elements are assigned.
  ///
  /// All elements of the array must be assigned before the array is valid. This
  /// is essentially the same as `JSArray.fixed` except that global type
  /// inference starts with bottom for the element type.
  ///
  /// [length] must be a non-negative integer.
  factory JSArray.allocateFixed(int length) {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode, and against `new Array(null)` which creates a single
    // element Array containing `null`.
    if (length is! int) {
      throw ArgumentError.value(length, 'length', 'is not an integer');
    }
    // The JavaScript Array constructor with one argument throws if the value is
    // not a UInt32 but the error message does not contain the bad value. Give a
    // better error message.
    int maxJSArrayLength = 0xFFFFFFFF;
    if (length < 0 || length > maxJSArrayLength) {
      throw RangeError.range(length, 0, maxJSArrayLength, 'length');
    }
    return JSArray<E>.markFixed(JS('', 'new Array(#)', length));
  }

  /// Returns a fresh growable JavaScript Array of zero length length.
  factory JSArray.emptyGrowable() => JSArray<E>.markGrowable(JS('', '[]'));

  /// Returns a fresh growable JavaScript Array with initial length. The holes
  /// in the array yield `undefined`, making the Dart List appear to be filled
  /// with `null` values.
  ///
  /// [length] must be a non-negative integer.
  factory JSArray.growable(int length) {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode.
    if ((length is! int) || (length < 0)) {
      throw ArgumentError('Length must be a non-negative integer: $length');
    }
    return JSArray<E>.markGrowable(JS('', 'new Array(#)', length));
  }

  /// Returns a fresh growable JavaScript Array with initial length. The Array
  /// is allocated but no elements are assigned.
  ///
  /// All elements of the array must be assigned before the array is valid. This
  /// is essentially the same as `JSArray.growable` except that global type
  /// inference starts with bottom for the element type.
  ///
  /// [length] must be a non-negative integer.
  factory JSArray.allocateGrowable(int length) {
    // Explicit type test is necessary to guard against JavaScript conversions
    // in unchecked mode.
    if ((length is! int) || (length < 0)) {
      throw ArgumentError('Length must be a non-negative integer: $length');
    }
    return JSArray<E>.markGrowable(JS('', 'new Array(#)', length));
  }

  /// Constructor for adding type parameters to an existing JavaScript Array.
  /// The compiler specially recognizes this constructor.
  ///
  ///     var a = new JSArray<int>.typed(JS('JSExtendableArray', '[]'));
  ///     a is List<int>    --> true
  ///     a is List<String> --> false
  ///
  /// Usually either the [JSArray.markFixed] or [JSArray.markGrowable]
  /// constructors is used instead.
  ///
  /// The input must be a JavaScript Array.  The JS form is just a re-assertion
  /// to help type analysis when the input type is sloppy.
  factory JSArray.typed(allocation) => JS('JSArray', '#', allocation);

  factory JSArray.markFixed(allocation) =>
      JS('JSFixedArray', '#', markFixedList(JSArray<E>.typed(allocation)));

  factory JSArray.markGrowable(allocation) =>
      JS('JSExtendableArray', '#', JSArray<E>.typed(allocation));

  static List<T> markFixedList<T>(List<T> list) {
    // Functions are stored in the hidden class and not as properties in
    // the object. We never actually look at the value, but only want
    // to know if the property exists.
    JS('void', r'#.fixed$length = Array', list);
    return JS('JSFixedArray', '#', list);
  }

  static List<T> markUnmodifiableList<T>(List list) {
    // Functions are stored in the hidden class and not as properties in
    // the object. We never actually look at the value, but only want
    // to know if the property exists.
    JS('void', r'#.fixed$length = Array', list);
    JS('void', r'#.immutable$list = Array', list);
    return JS('JSUnmodifiableArray', '#', list);
  }

  static bool isFixedLength(JSArray a) {
    return !JS('bool', r'!#.fixed$length', a);
  }

  static bool isUnmodifiable(JSArray a) {
    return !JS('bool', r'!#.immutable$list', a);
  }

  static bool isGrowable(JSArray a) {
    return !isFixedLength(a);
  }

  static bool isMutable(JSArray a) {
    return !isUnmodifiable(a);
  }

  checkMutable(String reason) {
    if (!isMutable(this)) {
      throw UnsupportedError(reason);
    }
  }

  checkGrowable(String reason) {
    if (!isGrowable(this)) {
      throw UnsupportedError(reason);
    }
  }

  List<R> cast<R>() => List.castFrom<E, R>(this);
  void add(E value) {
    checkGrowable('add');
    JS('void', r'#.push(#)', this, value);
  }

  E removeAt(int index) {
    checkGrowable('removeAt');
    if (index is! int) throw argumentErrorValue(index);
    if (index < 0 || index >= length) {
      throw RangeError.value(index);
    }
    return JS('', r'#.splice(#, 1)[0]', this, index);
  }

  void insert(int index, E value) {
    checkGrowable('insert');
    if (index is! int) throw argumentErrorValue(index);
    if (index < 0 || index > length) {
      throw RangeError.value(index);
    }
    JS('void', r'#.splice(#, 0, #)', this, index, value);
  }

  void insertAll(int index, Iterable<E> iterable) {
    checkGrowable('insertAll');
    RangeError.checkValueInInterval(index, 0, this.length, 'index');
    if (iterable is! EfficientLengthIterable) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    this._setLengthUnsafe(this.length + insertionLength);
    int end = index + insertionLength;
    this.setRange(end, this.length, this, index);
    this.setRange(index, end, iterable);
  }

  void setAll(int index, Iterable<E> iterable) {
    checkMutable('setAll');
    RangeError.checkValueInInterval(index, 0, this.length, 'index');
    for (var element in iterable) {
      this[index++] = element;
    }
  }

  E removeLast() {
    checkGrowable('removeLast');
    if (length == 0) throw diagnoseIndexError(this, -1);
    return JS('', r'#.pop()', this);
  }

  bool remove(Object? element) {
    checkGrowable('remove');
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        JS('', r'#.splice(#, 1)', this, i);
        return true;
      }
    }
    return false;
  }

  /// Removes elements matching [test] from this [JSArray].
  void removeWhere(bool test(E element)) {
    checkGrowable('removeWhere');
    _removeWhere(test, true);
  }

  void retainWhere(bool test(E element)) {
    checkGrowable('retainWhere');
    _removeWhere(test, false);
  }

  void _removeWhere(bool test(E element), bool removeMatching) {
    // Performed in two steps, to avoid exposing an inconsistent state
    // to the [test] function. First the elements to retain are found, and then
    // the original list is updated to contain those elements.

    // TODO(sra): Replace this algorithm with one that retains a list of ranges
    // to be removed.  Most real uses remove 0, 1 or a few clustered elements.

    List retained = [];
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      // !test() ensures bool conversion in checked mode.
      if (!test(element) == removeMatching) {
        retained.add(element);
      }
      if (this.length != end) throw ConcurrentModificationError(this);
    }
    if (retained.length == end) return;
    this.length = retained.length;
    for (int i = 0; i < retained.length; i++) {
      // We don't need a bounds check or an element type check.
      JS('', '#[#] = #', this, i, retained[i]);
    }
  }

  Iterable<E> where(bool f(E element)) {
    return WhereIterable<E>(this, f);
  }

  Iterable<T> expand<T>(Iterable<T> f(E element)) {
    return ExpandIterable<E, T>(this, f);
  }

  void addAll(Iterable<E> collection) {
    checkGrowable('addAll');
    if (collection is JSArray) {
      _addAllFromArray(JS('', '#', collection));
      return;
    }
    int i = this.length;
    for (E e in collection) {
      assert(i++ == this.length || (throw ConcurrentModificationError(this)));
      JS('void', r'#.push(#)', this, e);
    }
  }

  void _addAllFromArray(JSArray array) {
    int len = array.length;
    if (len == 0) return;
    if (identical(this, array)) throw ConcurrentModificationError(this);
    for (int i = 0; i < len; i++) {
      JS('', '#.push(#[#])', this, array, i);
    }
  }

  @pragma('dart2js:noInline')
  void clear() {
    checkGrowable('clear');
    _clear();
  }

  void _clear() {
    _setLengthUnsafe(0);
  }

  void forEach(void f(E element)) {
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      f(element);
      if (this.length != end) throw ConcurrentModificationError(this);
    }
  }

  Iterable<T> map<T>(T f(E element)) {
    return MappedListIterable<E, T>(this, f);
  }

  String join([String separator = '']) {
    var list = List.filled(this.length, "");
    for (int i = 0; i < this.length; i++) {
      list[i] = '${this[i]}';
    }
    return JS('String', '#.join(#)', list, separator);
  }

  Iterable<E> take(int n) {
    return SubListIterable<E>(this, 0, checkNotNullable(n, "count"));
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int n) {
    return SubListIterable<E>(this, n, null);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return SkipWhileIterable<E>(this, test);
  }

  E reduce(E combine(E previousValue, E element)) {
    int length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    E value = this[0];
    for (int i = 1; i < length; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      value = combine(value, element);
      if (length != this.length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      value = combine(value, element);
      if (this.length != length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  E firstWhere(bool Function(E) test, {E Function()? orElse}) {
    var end = this.length;
    for (int i = 0; i < end; ++i) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) return element;
      if (this.length != end) throw ConcurrentModificationError(this);
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool Function(E) test, {E Function()? orElse}) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) return element;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool Function(E) test, {E Function()? orElse}) {
    int length = this.length;
    E? match = null;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match as E;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E elementAt(int index) {
    return this[index];
  }

  List<E> sublist(int start, [int? end]) {
    checkNull(start); // TODO(ahe): This is not specified but co19 tests it.
    if (start is! int) throw argumentErrorValue(start);
    if (start < 0 || start > length) {
      throw RangeError.range(start, 0, length, 'start');
    }
    if (end == null) {
      end = length;
    } else {
      if (end is! int) throw argumentErrorValue(end);
      if (end < start || end > length) {
        throw RangeError.range(end, start, length, 'end');
      }
    }
    if (start == end) return <E>[];
    return JSArray<E>.markGrowable(JS('', r'#.slice(#, #)', this, start, end));
  }

  Iterable<E> getRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    return SubListIterable<E>(this, start, end);
  }

  E get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void removeRange(int start, int end) {
    checkGrowable('removeRange');
    RangeError.checkValidRange(start, end, this.length);
    int deleteCount = end - start;
    JS('', '#.splice(#, #)', this, start, deleteCount);
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    checkMutable('setRange');

    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, 'skipCount');

    List<E> otherList;
    int otherStart;
    // TODO(floitsch): Make this accept more.
    if (iterable is List) {
      otherList = JS<List<E>>('', '#', iterable);
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + length > otherList.length) {
      throw IterableElementError.tooFew();
    }
    if (otherStart < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      // TODO(sra): If [from] is the same Array as [this], we can copy without
      // type annotation checks on the stores.
      for (int i = length - 1; i >= 0; i--) {
        // Use JS to avoid bounds check (the bounds check elimination
        // optimization is too weak). The 'E' type annotation is a store type
        // check - we can't rely on iterable, it could be List<dynamic>.
        E element = otherList[otherStart + i];
        JS('', '#[#] = #', this, start + i, element);
      }
    } else {
      for (int i = 0; i < length; i++) {
        E element = otherList[otherStart + i];
        JS('', '#[#] = #', this, start + i, element);
      }
    }
  }

  void fillRange(int start, int end, [E? fillValue]) {
    checkMutable('fill range');
    RangeError.checkValidRange(start, end, this.length);
    E checkedFillValue = fillValue as E;
    for (int i = start; i < end; i++) {
      // Store is safe since [checkedFillValue] type has been checked as
      // parameter and for null.
      JS('', '#[#] = #', this, i, checkedFillValue);
    }
  }

  void replaceRange(int start, int end, Iterable<E> replacement) {
    checkGrowable('replaceRange');
    RangeError.checkValidRange(start, end, this.length);
    if (replacement is! EfficientLengthIterable) {
      replacement = replacement.toList();
    }
    int removeLength = end - start;
    int insertLength = replacement.length;
    if (removeLength >= insertLength) {
      int delta = removeLength - insertLength;
      int insertEnd = start + insertLength;
      int newLength = this.length - delta;
      this.setRange(start, insertEnd, replacement);
      if (delta != 0) {
        this.setRange(insertEnd, newLength, this, end);
        this.length = newLength;
      }
    } else {
      int delta = insertLength - removeLength;
      int newLength = this.length + delta;
      int insertEnd = start + insertLength; // aka. end + delta.
      this._setLengthUnsafe(newLength);
      this.setRange(insertEnd, newLength, this, end);
      this.setRange(start, insertEnd, replacement);
    }
  }

  bool any(bool test(E element)) {
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) return true;
      if (this.length != end) throw ConcurrentModificationError(this);
    }
    return false;
  }

  bool every(bool test(E element)) {
    int end = this.length;
    for (int i = 0; i < end; i++) {
      // TODO(22407): Improve bounds check elimination to allow this JS code to
      // be replaced by indexing.
      var element = JS<E>('', '#[#]', this, i);
      if (!test(element)) return false;
      if (this.length != end) throw ConcurrentModificationError(this);
    }
    return true;
  }

  Iterable<E> get reversed => ReversedListIterable<E>(this);

  void sort([int Function(E, E)? compare]) {
    checkMutable('sort');
    final len = length;
    if (len < 2) return;
    compare ??= _compareAny;
    if (len == 2) {
      final a = this[0];
      final b = this[1];
      if (compare(a, b) > 0) {
        // Hand-coded because the compiler does not understand the array is
        // mutable at this point.
        JS('', '#[#] = #', this, 0, b); // this[0] = b;
        JS('', '#[#] = #', this, 1, a); // this[1] = a;
      }
      return;
    }

    // Use JavaScript's sort. This requires some pre- and post- processing.
    //
    // Arrays have three kinds of element that represent Dart `null`:
    //
    //  - `null` values, which are passed to the compare function.
    //
    //  - `undefined` values, which are not passed to the comparator and follow
    //    the sorted values in the resulting order.
    //
    //  - Empty slots or holes in the array, which look like `undefined`, are
    //    also not passed to the comparator, and are moved to the end of the
    //    array to follow the `undefined` values.
    //
    // Example
    //
    //     [null, /*empty*/, undefined, 'z', /*empty*/, 'a', undefined].sort()
    //
    // --->
    //
    //     ['a', null, 'z', undefined, undefined, /*empty*/, /*empty*/]
    //
    // (null goes between 'a' and 'z' because JavaScript's default comparator
    // works on `ToString` of the element).
    //
    // In order to have the undefined and empty elements behave as `null`, they
    // are overwritten with `null` before sorting, and reinstated as an
    // `undefined` value after. Since all the `null` values are
    // indistinguishable, a count is sufficient.
    //
    // The reason we bother with reinstating `undefined` values is so that
    // sorting does not change the contents of an array that has `undefined`
    // values from js-interop. Empty slots are not preserved and become
    // non-empty slots holding the `undefined` value (which would happen anyway
    // with an assignment like `a[i] = a[j]`.

    int undefineds = 0;
    // The element type might exclude the possibility of there being `null`s,
    // but only in sound null safety mode.
    if (JS_GET_FLAG('LEGACY') || null is E) {
      for (int i = 0; i < length; i++) {
        final E element = JS('', '#[#]', this, i);
        if (JS('', '# === void 0', element)) {
          // Hand-coded write since `this[i] = null;` is a compile-time error
          // due to `E` not being nullable.
          JS('', '#[#] = #', this, i, null);
          undefineds++;
        }
      }
    }
    JS('', '#.sort(#)', this, convertDartClosureToJS(compare, 2));

    if (undefineds > 0) _replaceSomeNullsWithUndefined(undefineds);
  }

  static int _compareAny(a, b) {
    return Comparable.compare(a, b);
  }

  // This is separate function since in many programs sorting an array with
  // nulls or undefined values is rare. Keeping the code separate reduces
  // potential JIT deoptimizations.
  @pragma('dart2js:never-inline')
  void _replaceSomeNullsWithUndefined(int count) {
    assert(count > 0);
    int i = length;
    // Scan backwards for `null`s and replace one-by-one. They are not
    // necessarily adjacent if the compare function places Dart `null` in the
    // same equivalence class as some non-null value.
    while (i-- > 0) {
      final E element = JS('', '#[#]', this, i);
      if (JS('', '# === null', element)) {
        JS('', '#[#] = void 0', this, i);
        if (--count == 0) break;
      }
    }
  }

  void shuffle([Random? random]) {
    checkMutable('shuffle');
    if (random == null) random = Random();
    int length = this.length;
    while (length > 1) {
      int pos = random.nextInt(length);
      length -= 1;
      var tmp = this[length];
      this[length] = this[pos];
      this[pos] = tmp;
    }
  }

  int indexOf(Object? element, [int start = 0]) {
    int length = this.length;
    if (start >= length) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (int i = start; i < length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  int lastIndexOf(Object? element, [int? startIndex]) {
    int start = startIndex ?? this.length - 1;
    if (start < 0) {
      return -1;
    }
    if (start >= this.length) {
      start = this.length - 1;
    }
    for (int i = start; i >= 0; i--) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  bool contains(Object? other) {
    for (int i = 0; i < length; i++) {
      E element = JS('', '#[#]', this, i);
      if (element == other) return true;
    }
    return false;
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  String toString() => ListBase.listToString(this);

  List<E> toList({bool growable = true}) =>
      growable ? _toListGrowable() : _toListFixed();

  List<E> _toListGrowable() =>
      // slice(0) is slightly faster than slice()
      JSArray<E>.markGrowable(JS('', '#.slice(0)', this));

  List<E> _toListFixed() => JSArray<E>.markFixed(JS('', '#.slice(0)', this));

  Set<E> toSet() => Set<E>.from(this);

  Iterator<E> get iterator => ArrayIterator<E>(this);

  int get hashCode => Primitives.objectHashCode(this);

  int get length => JS('JSUInt32', r'#.length', this);

  set length(int newLength) {
    checkGrowable('set length');
    if (newLength is! int) {
      throw ArgumentError.value(newLength, 'newLength');
    }
    // TODO(sra): Remove this test and let JavaScript throw an error.
    if (newLength < 0) {
      throw RangeError.range(newLength, 0, null, 'newLength');
    }

    // Verify that element type is nullable.
    if (newLength > length) null as E;

    // JavaScript with throw a RangeError for numbers that are too big. The
    // message does not contain the value.
    JS('void', r'#.length = #', this, newLength);
  }

  /// Unsafe alternative to the [length] setter that skips the check and will
  /// not fail when increasing the size of a list of non-nullable elements.
  ///
  /// To ensure null safe soundness this should only be called when every new
  /// index will be filled before returning.
  ///
  /// Should only be called when the list is already known to be growable.
  void _setLengthUnsafe(int newLength) {
    assert(newLength is int, throw ArgumentError.value(newLength, 'newLength'));

    assert(newLength >= 0,
        throw RangeError.range(newLength, 0, null, 'newLength'));

    // JavaScript with throw a RangeError for numbers that are too big. The
    // message does not contain the value.
    JS('void', r'#.length = #', this, newLength);
  }

  E operator [](int index) {
    if (index is! int) throw diagnoseIndexError(this, index);
    // This form of the range test correctly rejects NaN.
    if (!(index >= 0 && index < length)) throw diagnoseIndexError(this, index);
    return JS('', '#[#]', this, index);
  }

  void operator []=(int index, E value) {
    checkMutable('indexed set');
    if (index is! int) throw diagnoseIndexError(this, index);
    // This form of the range test correctly rejects NaN.
    if (!(index >= 0 && index < length)) throw diagnoseIndexError(this, index);
    JS('void', r'#[#] = #', this, index, value);
  }

  Map<int, E> asMap() {
    return ListMapView<E>(this);
  }

  Iterable<E> followedBy(Iterable<E> other) =>
      FollowedByIterable<E>.firstEfficient(this, other);

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  List<E> operator +(List<E> other) => [...this, ...other];

  int indexWhere(bool test(E element), [int start = 0]) {
    if (start >= this.length) return -1;
    if (start < 0) start = 0;
    for (int i = start; i < this.length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(E element), [int? start]) {
    if (start == null) start = this.length - 1;
    if (start < 0) return -1;
    for (int i = start; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  void set first(E element) {
    if (this.isEmpty) throw IterableElementError.noElement();
    this[0] = element;
  }

  void set last(E element) {
    if (this.isEmpty) throw IterableElementError.noElement();
    this[this.length - 1] = element;
  }

  // Specialized version of `get runtimeType` is needed here so that
  // `Interceptor.runtimeType` can avoid testing for `JSArray`.
  Type get runtimeType => getRuntimeTypeOfArray(this);
}

/// Dummy subclasses that allow the backend to track more precise
/// information about arrays through their type. The CPA type inference
/// relies on the fact that these classes do not override [] nor []=.
///
/// These classes are really a fiction, and can have no methods, since
/// getInterceptor always returns JSArray.  We should consider pushing the
/// 'isGrowable' and 'isMutable' checks into the getInterceptor implementation
/// so these classes can have specialized implementations. Doing so will
/// challenge many assumptions in the JS backend.
class JSMutableArray<E> extends JSArray<E> implements JSMutableIndexable<E> {}

class JSFixedArray<E> extends JSMutableArray<E> {}

class JSExtendableArray<E> extends JSMutableArray<E> {}

class JSUnmodifiableArray<E> extends JSArray<E> {} // Already is JSIndexable.

/// An [Iterator] that iterates a JSArray.
///
class ArrayIterator<E> implements Iterator<E> {
  final JSArray<E> _iterable;
  final int _length;
  int _index;
  E? _current;

  ArrayIterator(JSArray<E> iterable)
      : _iterable = iterable,
        _length = iterable.length,
        _index = 0;

  E get current => _current as E;

  bool moveNext() {
    int length = _iterable.length;

    // We have to do the length check even on fixed length Arrays.  If we can
    // inline moveNext() we might be able to GVN the length and eliminate this
    // check on known fixed length JSArray.
    if (_length != length) {
      throw throwConcurrentModificationError(_iterable);
    }

    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable[_index];
    _index++;
    return true;
  }
}
