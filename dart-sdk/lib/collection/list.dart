// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// Abstract implementation of a list.
///
/// `ListBase` can be used as a base class for implementing the `List`
/// interface.
///
/// This class implements all read operations using only the `length` and
/// `operator[]` and members. It implements write operations using those and
/// `add`, `length=` and `operator[]=`
/// Classes using this base class should implement those five operations.
///
/// **NOTICE**: For backwards compatibility reasons,
/// there is a default implementation of `add`
/// which only works for lists with a nullable element type.
/// For list with a non-nullable element type,
/// the `add` method must be implemented.
///
/// **NOTICE**: Forwarding just the four `length` and `[]` read/write operations
/// to a normal growable [List] (as created by a `[]` literal)
/// will give very bad performance for `add` and `addAll` operations
/// of `ListBase`.
/// These operations are implemented by
/// increasing the length of the list by one for each `add` operation,
/// and repeatedly increasing the length of a growable list is not efficient.
/// To avoid this, override 'add' and 'addAll' to also forward directly
/// to the growable list, or, if possible, use `DelegatingList` from
/// "package:collection/collection.dart" instead of a `ListMixin`.
// TODO: @Deprecated("Use List instead")
abstract mixin class ListBase<E> implements List<E> {
  const ListBase();

  // Iterable interface.
  // TODO(lrn): When we get composable mixins, reuse IterableMixin instead
  // of redeclaring everything.
  @pragma('vm:prefer-inline')
  Iterator<E> get iterator => ListIterator<E>(this);

  E elementAt(int index) => this[index];

  Iterable<E> followedBy(Iterable<E> other) =>
      FollowedByIterable<E>.firstEfficient(this, other);

  void forEach(void action(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      action(this[i]);
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
  }

  @pragma("vm:prefer-inline")
  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  E get first {
    if (length == 0) throw IterableElementError.noElement();
    return this[0];
  }

  void set first(E value) {
    if (length == 0) throw IterableElementError.noElement();
    this[0] = value;
  }

  E get last {
    if (length == 0) throw IterableElementError.noElement();
    return this[length - 1];
  }

  void set last(E value) {
    if (length == 0) throw IterableElementError.noElement();
    this[length - 1] = value;
  }

  E get single {
    if (length == 0) throw IterableElementError.noElement();
    if (length > 1) throw IterableElementError.tooMany();
    return this[0];
  }

  bool contains(Object? element) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (this[i] == element) return true;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return false;
  }

  bool every(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (!test(this[i])) return false;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return true;
  }

  bool any(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return true;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return false;
  }

  E firstWhere(bool test(E element), {E Function()? orElse}) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      E element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E element), {E Function()? orElse}) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      E element = this[i];
      if (test(element)) return element;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E element), {E Function()? orElse}) {
    int length = this.length;
    late E match;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      E element = this[i];
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
    if (matchFound) return match;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  String join([String separator = ""]) {
    if (length == 0) return "";
    StringBuffer buffer = StringBuffer()..writeAll(this, separator);
    return buffer.toString();
  }

  Iterable<E> where(bool test(E element)) => WhereIterable<E>(this, test);

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<T> map<T>(T f(E element)) => MappedListIterable<E, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(E element)) =>
      ExpandIterable<E, T>(this, f);

  E reduce(E combine(E previousValue, E element)) {
    int length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    E value = this[0];
    for (int i = 1; i < length; i++) {
      value = combine(value, this[i]);
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      value = combine(value, this[i]);
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return value;
  }

  Iterable<E> skip(int count) => SubListIterable<E>(this, count, null);

  Iterable<E> skipWhile(bool test(E element)) {
    return SkipWhileIterable<E>(this, test);
  }

  Iterable<E> take(int count) =>
      SubListIterable<E>(this, 0, checkNotNullable(count, "count"));

  Iterable<E> takeWhile(bool test(E element)) {
    return TakeWhileIterable<E>(this, test);
  }

  List<E> toList({bool growable = true}) {
    if (this.isEmpty) return List<E>.empty(growable: growable);
    var first = this[0];
    var result = List<E>.filled(this.length, first, growable: growable);
    for (int i = 1; i < this.length; i++) {
      result[i] = this[i];
    }
    return result;
  }

  Set<E> toSet() {
    Set<E> result = Set<E>();
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
    }
    return result;
  }

  // List interface.
  void add(E element) {
    // This implementation only works for lists which allow `null` as element.
    this[this.length++] = element;
  }

  void addAll(Iterable<E> iterable) {
    int i = this.length;
    for (E element in iterable) {
      assert(this.length == i || (throw ConcurrentModificationError(this)));
      add(element);
      i++;
    }
  }

  bool remove(Object? element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        this._closeGap(i, i + 1);
        return true;
      }
    }
    return false;
  }

  /// Removes elements from the list starting at [start] up to but not including
  /// [end].  Arguments are pre-validated.
  void _closeGap(int start, int end) {
    int length = this.length;
    assert(0 <= start);
    assert(start < end);
    assert(end <= length);
    int size = end - start;
    for (int i = end; i < length; i++) {
      this[i - size] = this[i];
    }
    this.length = length - size;
  }

  void removeWhere(bool test(E element)) {
    _filter(test, false);
  }

  void retainWhere(bool test(E element)) {
    _filter(test, true);
  }

  void _filter(bool test(E element), bool retainMatching) {
    List<E> retained = <E>[];
    int length = this.length;
    for (int i = 0; i < length; i++) {
      var element = this[i];
      if (test(element) == retainMatching) {
        retained.add(element);
      }
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (retained.length != this.length) {
      this.setRange(0, retained.length, retained);
      this.length = retained.length;
    }
  }

  void clear() {
    this.length = 0;
  }

  List<R> cast<R>() => List.castFrom<E, R>(this);
  E removeLast() {
    if (length == 0) {
      throw IterableElementError.noElement();
    }
    E result = this[length - 1];
    length--;
    return result;
  }

  void sort([int Function(E a, E b)? compare]) {
    Sort.sort(this, compare ?? _compareAny);
  }

  static int _compareAny(dynamic a, dynamic b) {
    return Comparable.compare(a as Comparable, b as Comparable);
  }

  void shuffle([Random? random]) {
    random ??= Random();

    int length = this.length;
    while (length > 1) {
      int pos = random.nextInt(length);
      length -= 1;
      var tmp = this[length];
      this[length] = this[pos];
      this[pos] = tmp;
    }
  }

  Map<int, E> asMap() {
    return ListMapView<E>(this);
  }

  List<E> operator +(List<E> other) => [...this, ...other];

  List<E> sublist(int start, [int? end]) {
    int listLength = this.length;
    end ??= listLength;

    RangeError.checkValidRange(start, end, listLength);
    return List.from(getRange(start, end));
  }

  Iterable<E> getRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    return SubListIterable<E>(this, start, end);
  }

  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    if (end > start) {
      _closeGap(start, end);
    }
  }

  void fillRange(int start, int end, [E? fill]) {
    // Hoist the case to fail eagerly if the user provides an invalid `null`
    // value (or omits it) when E is a non-nullable type.
    E value = fill as E;
    RangeError.checkValidRange(start, end, this.length);
    for (int i = start; i < end; i++) {
      this[i] = value;
    }
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");

    List<E> otherList;
    int otherStart;
    // TODO(floitsch): Make this accept more.
    if (iterable is List<E>) {
      otherList = iterable;
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
      for (int i = length - 1; i >= 0; i--) {
        this[start + i] = otherList[otherStart + i];
      }
    } else {
      for (int i = 0; i < length; i++) {
        this[start + i] = otherList[otherStart + i];
      }
    }
  }

  void replaceRange(int start, int end, Iterable<E> newContents) {
    RangeError.checkValidRange(start, end, this.length);
    if (start == this.length) {
      addAll(newContents);
      return;
    }
    if (newContents is! EfficientLengthIterable) {
      newContents = newContents.toList();
    }
    int removeLength = end - start;
    int insertLength = newContents.length;
    if (removeLength >= insertLength) {
      int insertEnd = start + insertLength;
      this.setRange(start, insertEnd, newContents);
      if (removeLength > insertLength) {
        _closeGap(insertEnd, end);
      }
    } else if (end == this.length) {
      int i = start;
      for (E element in newContents) {
        if (i < end) {
          this[i] = element;
        } else {
          add(element);
        }
        i++;
      }
    } else {
      int delta = insertLength - removeLength;
      int oldLength = this.length;
      int insertEnd = start + insertLength; // aka. end + delta.
      for (int i = oldLength - delta; i < oldLength; ++i) {
        add(this[i > 0 ? i : 0]);
      }
      if (insertEnd < oldLength) {
        this.setRange(insertEnd, oldLength, this, end);
      }
      this.setRange(start, insertEnd, newContents);
    }
  }

  int indexOf(Object? element, [int start = 0]) {
    if (start < 0) start = 0;
    for (int i = start; i < this.length; i++) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int indexWhere(bool test(E element), [int start = 0]) {
    if (start < 0) start = 0;
    for (int i = start; i < this.length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  int lastIndexOf(Object? element, [int? start]) {
    if (start == null || start >= this.length) start = this.length - 1;

    for (int i = start; i >= 0; i--) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(E element), [int? start]) {
    if (start == null || start >= this.length) start = this.length - 1;

    for (int i = start; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  void insert(int index, E element) {
    checkNotNullable(index, "index");
    var length = this.length;
    RangeError.checkValueInInterval(index, 0, length, "index");
    add(element);
    if (index != length) {
      setRange(index + 1, length + 1, this, index);
      this[index] = element;
    }
  }

  E removeAt(int index) {
    E result = this[index];
    _closeGap(index, index + 1);
    return result;
  }

  void insertAll(int index, Iterable<E> iterable) {
    RangeError.checkValueInInterval(index, 0, length, "index");
    if (index == length) {
      addAll(iterable);
      return;
    }
    if (iterable is! EfficientLengthIterable || identical(iterable, this)) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    if (insertionLength == 0) {
      return;
    }
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
    int oldLength = length;
    for (int i = oldLength - insertionLength; i < oldLength; ++i) {
      add(this[i > 0 ? i : 0]);
    }
    if (iterable.length != insertionLength) {
      // If the iterable's length is linked to this list's length somehow,
      // we can't insert one in the other.
      this.length -= insertionLength;
      throw ConcurrentModificationError(iterable);
    }
    int oldCopyStart = index + insertionLength;
    if (oldCopyStart < oldLength) {
      setRange(oldCopyStart, oldLength, this, index);
    }
    setAll(index, iterable);
  }

  void setAll(int index, Iterable<E> iterable) {
    if (iterable is List) {
      setRange(index, index + iterable.length, iterable);
    } else {
      for (E element in iterable) {
        this[index++] = element;
      }
    }
  }

  Iterable<E> get reversed => ReversedListIterable<E>(this);

  String toString() => listToString(this);

  /// Converts a [List] to a [String].
  ///
  /// Converts [list] to a string by converting each element to a string (by
  /// calling [Object.toString]), joining them with ", ", and wrapping the
  /// result in `[` and `]`.
  ///
  /// Handles circular references where converting one of the elements
  /// to a string ends up converting [list] to a string again.
  static String listToString(List<Object?> list) =>
      IterableBase.iterableToFullString(list, '[', ']');
}

/// Base mixin implementation of a [List] class.
///
/// `ListMixin` can be used as a mixin to make a class implement
/// the `List` interface.
///
/// This mixin implements all read operations using only the `length` and
/// `operator[]` and members. It implements write operations using those and
/// `add`, `length=` and `operator[]=`.
/// Classes using this mixin should implement those five operations.
///
/// **NOTICE**: For backwards compatibility reasons,
/// there is a default implementation of `add`
/// which only works for lists with a nullable element type.
/// For lists with a non-nullable element type,
/// the `add` method must be implemented.
///
/// **NOTICE**: Forwarding just the four `length` and `[]` read/write operations
/// to a normal growable [List] (as created by a `[]` literal)
/// will give very bad performance for `add` and `addAll` operations
/// of `ListMixin`.
/// These operations are implemented by
/// increasing the length of the list by one for each `add` operation,
/// and repeatedly increasing the length of a growable list is not efficient.
/// To avoid this, override 'add' and 'addAll' to also forward directly
/// to the growable list, or, if possible, use `DelegatingList` from
/// "package:collection/collection.dart" instead of a `ListMixin`.
// TODO: @Deprecated("Use List instead")
typedef ListMixin<E> = ListBase<E>;
