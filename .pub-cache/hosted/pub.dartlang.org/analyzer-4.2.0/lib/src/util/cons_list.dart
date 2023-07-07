void f(List<int> a) {
  a.reduce((value, element) => 0);
}

class ConsList<E> {
  final E head;
  final ConsList<E>? tail;

  ConsList({required this.head, this.tail});

  E reduce(E Function(E value, E element) combine) {
    final tail = this.tail;
    if (tail != null) {
      return combine(head, tail.reduce(combine));
    }
    return head;
  }
}
