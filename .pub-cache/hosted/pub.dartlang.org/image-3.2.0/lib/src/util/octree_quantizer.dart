import '../color.dart';
import '../image.dart';
import 'quantizer.dart';

// Color quantization using octree,
// from https://rosettacode.org/wiki/Color_quantization/C
class OctreeQuantizer extends Quantizer {
  final _OctreeNode _root;

  OctreeQuantizer(Image image, {int numberOfColors = 256})
      : _root = _OctreeNode(0, 0, null) {
    final heap = _HeapNode();
    for (var si = 0; si < image.length; ++si) {
      final c = image[si];
      final r = getRed(c);
      final g = getGreen(c);
      final b = getBlue(c);
      _heapAdd(heap, _nodeInsert(_root, r, g, b));
    }

    final nc = numberOfColors + 1;
    while (heap.n > nc) {
      _heapAdd(heap, _nodeFold(_popHeap(heap)!)!);
    }

    for (var i = 1; i < heap.n; i++) {
      final got = heap.buf[i]!;
      final c = got.count;
      got.r = (got.r / c).round();
      got.g = (got.g / c).round();
      got.b = (got.b / c).round();
    }
  }

  /// Find the index of the closest color to [c] in the [colorMap].
  @override
  int getQuantizedColor(int c) {
    var r = getRed(c);
    var g = getGreen(c);
    var b = getBlue(c);
    _OctreeNode? root = _root;

    for (var bit = 1 << 7; bit != 0; bit >>= 1) {
      final i = ((g & bit) != 0 ? 1 : 0) * 4 +
          ((r & bit) != 0 ? 1 : 0) * 2 +
          ((b & bit) != 0 ? 1 : 0);
      if (root!.children[i] == null) {
        break;
      }
      root = root.children[i];
    }

    r = root!.r;
    g = root.g;
    b = root.b;
    return getColor(r, g, b);
  }

  int _compareNode(_OctreeNode a, _OctreeNode b) {
    if (a.childCount < b.childCount) {
      return -1;
    }
    if (a.childCount > b.childCount) {
      return 1;
    }

    final ac = a.count >> a.depth;
    final bc = b.count >> b.depth;
    return (ac < bc)
        ? -1
        : (ac > bc)
            ? 1
            : 0;
  }

  _OctreeNode _nodeInsert(_OctreeNode root, int r, int g, int b) {
    var depth = 0;
    for (var bit = 1 << 7; ++depth < 8; bit >>= 1) {
      final i = ((g & bit) != 0 ? 1 : 0) * 4 +
          ((r & bit) != 0 ? 1 : 0) * 2 +
          ((b & bit) != 0 ? 1 : 0);
      if (root.children[i] == null) {
        root.children[i] = _OctreeNode(i, depth, root);
      }

      root = root.children[i]!;
    }

    root.r += r;
    root.g += g;
    root.b += b;
    root.count++;
    return root;
  }

  _OctreeNode? _nodeFold(_OctreeNode p) {
    if (p.childCount > 0) {
      return null;
    }
    final q = p.parent!;
    q.count += p.count;

    q.r += p.r;
    q.g += p.g;
    q.b += p.b;
    q.childCount--;
    q.children[p.childIndex] = null;
    return q;
  }

  static const _ON_INHEAP = 1;

  _OctreeNode? _popHeap(_HeapNode h) {
    if (h.n <= 1) {
      return null;
    }

    final ret = h.buf[1];
    h.buf[1] = h.buf.removeLast();
    h.buf[1]!.heap_idx = 1;
    _downHeap(h, h.buf[1]!);

    return ret;
  }

  void _heapAdd(_HeapNode h, _OctreeNode p) {
    if ((p.flags & _ON_INHEAP) != 0) {
      _downHeap(h, p);
      _upHeap(h, p);
      return;
    }

    p.flags |= _ON_INHEAP;
    p.heap_idx = h.n;
    h.buf.add(p);
    _upHeap(h, p);
  }

  void _downHeap(_HeapNode h, _OctreeNode p) {
    var n = p.heap_idx;
    while (true) {
      var m = n * 2;
      if (m >= h.n) {
        break;
      }
      if ((m + 1) < h.n && _compareNode(h.buf[m]!, h.buf[m + 1]!) > 0) {
        m++;
      }

      if (_compareNode(p, h.buf[m]!) <= 0) {
        break;
      }

      h.buf[n] = h.buf[m];
      h.buf[n]!.heap_idx = n;
      n = m;
    }

    h.buf[n] = p;
    p.heap_idx = n;
  }

  void _upHeap(_HeapNode h, _OctreeNode p) {
    var n = p.heap_idx;
    _OctreeNode? prev;

    while (n > 1) {
      prev = h.buf[n ~/ 2];
      if (_compareNode(p, prev!) >= 0) {
        break;
      }

      h.buf[n] = prev;
      prev.heap_idx = n;
      n ~/= 2;
    }
    h.buf[n] = p;
    p.heap_idx = n;
  }
}

class _OctreeNode {
  // sum of all colors represented by this node.
  int r = 0;
  int g = 0;
  int b = 0;
  int count = 0;
  int heap_idx = 0;
  List<_OctreeNode?> children = List<_OctreeNode?>.filled(8, null);
  _OctreeNode? parent;
  int childCount = 0;
  int childIndex = 0;
  int flags = 0;
  int depth = 0;

  _OctreeNode(this.childIndex, this.depth, this.parent) {
    if (parent != null) {
      parent!.childCount++;
    }
  }
}

class _HeapNode {
  List<_OctreeNode?> buf = [null];
  int get n => buf.length;
}
