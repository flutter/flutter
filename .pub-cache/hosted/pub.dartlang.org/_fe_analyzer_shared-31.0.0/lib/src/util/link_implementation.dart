// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.util.link_implementation;

import 'dart:collection' show IterableBase;

import 'link.dart' show Link, LinkBuilder;

class LinkIterator<T> implements Iterator<T> {
  T? _current;
  Link<T> _link;

  LinkIterator(this._link);

  T get current => _current!;

  bool moveNext() {
    if (_link.isEmpty) {
      _current = null;
      return false;
    }
    _current = _link.head;
    _link = _link.tail!;
    return true;
  }
}

typedef T Transformation<S, T>(S input);

class MappedLinkIterator<S, T> extends Iterator<T> {
  Transformation<S, T> _transformation;
  Link<S> _link;
  T? _current;

  MappedLinkIterator(this._link, this._transformation);

  T get current => _current!;

  bool moveNext() {
    if (_link.isEmpty) {
      _current = null;
      return false;
    }
    _current = _transformation(_link.head);
    _link = _link.tail!;
    return true;
  }
}

class MappedLinkIterable<S, T> extends IterableBase<T> {
  Transformation<S, T> _transformation;
  Link<S> _link;

  MappedLinkIterable(this._link, this._transformation);

  Iterator<T> get iterator {
    return new MappedLinkIterator<S, T>(_link, _transformation);
  }
}

class LinkEntry<T> extends Link<T> {
  final T head;
  Link<T> tail;

  LinkEntry(this.head, [Link<T>? tail]) : tail = tail ?? const Link<Never>();

  Link<T> prepend(T element) {
    // TODO(ahe): Use new Link<T>, but this cost 8% performance on VM.
    return new LinkEntry<T>(element, this);
  }

  void printOn(StringBuffer buffer, [separatedBy]) {
    buffer.write(head);
    if (separatedBy == null) separatedBy = '';
    for (Link<T> link = tail; link.isNotEmpty; link = link.tail!) {
      buffer.write(separatedBy);
      buffer.write(link.head);
    }
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('[ ');
    printOn(buffer, ', ');
    buffer.write(' ]');
    return buffer.toString();
  }

  @override
  Link<T> reverse(Link<T> tail) {
    Link<T> result = tail;
    for (Link<T> link = this; link.isNotEmpty; link = link.tail!) {
      result = result.prepend(link.head);
    }
    return result;
  }

  Link<T> reversePrependAll(Link<T> from) {
    Link<T> result;
    for (result = this; from.isNotEmpty; from = from.tail!) {
      result = result.prepend(from.head);
    }
    return result;
  }

  Link<T> skip(int n) {
    Link<T> link = this;
    for (int i = 0; i < n; i++) {
      if (link.isEmpty) {
        throw new RangeError('Index $n out of range');
      }
      link = link.tail!;
    }
    return link;
  }

  bool get isEmpty => false;
  bool get isNotEmpty => true;

  void forEach(void f(T element)) {
    for (Link<T> link = this; link.isNotEmpty; link = link.tail!) {
      f(link.head);
    }
  }

  bool operator ==(other) {
    if (other is! Link<T>) return false;
    Link<T> myElements = this;
    Link<T> otherElements = other;
    while (myElements.isNotEmpty && otherElements.isNotEmpty) {
      if (myElements.head != otherElements.head) {
        return false;
      }
      myElements = myElements.tail!;
      otherElements = otherElements.tail!;
    }
    return myElements.isEmpty && otherElements.isEmpty;
  }

  int get hashCode => throw new UnsupportedError('LinkEntry.hashCode');

  int slowLength() {
    int length = 0;
    for (Link<T> current = this; current.isNotEmpty; current = current.tail!) {
      ++length;
    }
    return length;
  }
}

class LinkBuilderImplementation<T> implements LinkBuilder<T> {
  LinkEntry<T>? head = null;
  LinkEntry<T>? lastLink = null;
  int length = 0;

  LinkBuilderImplementation();

  @override
  Link<T> toLink(Link<T> tail) {
    if (head == null) return tail;
    lastLink!.tail = tail;
    Link<T> link = head!;
    lastLink = null;
    head = null;
    length = 0;
    return link;
  }

  List<T> toList() {
    if (length == 0) return <T>[];

    List<T> list = <T>[];
    Link<T> link = head!;
    while (link.isNotEmpty) {
      list.add(link.head);
      link = link.tail!;
    }
    lastLink = null;
    head = null;
    length = 0;
    return list;
  }

  Link<T> addLast(T t) {
    length++;
    LinkEntry<T> entry = new LinkEntry<T>(t, null);
    if (head == null) {
      head = entry;
    } else {
      lastLink!.tail = entry;
    }
    lastLink = entry;
    return entry;
  }

  bool get isEmpty => length == 0;

  T get first {
    if (head != null) {
      return head!.head;
    }
    throw new StateError("no elements");
  }

  void clear() {
    head = null;
    lastLink = null;
    length = 0;
  }
}
