import 'dart:typed_data';

import '../../internal/internal.dart';
import 'vp8l.dart';
import 'vp8l_bit_reader.dart';

// Huffman Tree.
@internal
class HuffmanTree {
  static const HUFF_LUT_BITS = 7;
  static const HUFF_LUT = (1 << HUFF_LUT_BITS);
  // Fast lookup for short bit lengths.
  Uint8List lutBits = Uint8List(HUFF_LUT);
  Int16List lutSymbol = Int16List(HUFF_LUT);
  Int16List lutJump = Int16List(HUFF_LUT);

  // all the nodes, starting at root, stored as a single int array, where
  // each node occupies two ints as [symbol, children].
  late Int32List tree;

  // max number of nodes
  int maxNodes = 0;

  // number of currently occupied nodes
  int numNodes = 0;

  HuffmanTree([int numLeaves = 0]) {
    _init(numLeaves);
  }

  bool _init(int numLeaves) {
    if (numLeaves == 0) {
      return false;
    }

    maxNodes = (numLeaves << 1) - 1;
    tree = Int32List(maxNodes << 1);
    tree[1] = -1;
    numNodes = 1;
    lutBits.fillRange(0, lutBits.length, 255);

    return true;
  }

  bool buildImplicit(List<int> codeLengths, int codeLengthsSize) {
    var numSymbols = 0;
    var rootSymbol = 0;

    // Find out number of symbols and the root symbol.
    for (var symbol = 0; symbol < codeLengthsSize; ++symbol) {
      if (codeLengths[symbol] > 0) {
        // Note: code length = 0 indicates non-existent symbol.
        ++numSymbols;
        rootSymbol = symbol;
      }
    }

    // Initialize the tree. Will fail for num_symbols = 0
    if (!_init(numSymbols)) {
      return false;
    }

    // Build tree.
    if (numSymbols == 1) {
      // Trivial case.
      final maxSymbol = codeLengthsSize;
      if (rootSymbol < 0 || rootSymbol >= maxSymbol) {
        return false;
      }

      return _addSymbol(rootSymbol, 0, 0);
    }

    // Normal case.

    // Get Huffman codes from the code lengths.
    final codes = Int32List(codeLengthsSize);

    if (!_huffmanCodeLengthsToCodes(codeLengths, codeLengthsSize, codes)) {
      return false;
    }

    // Add symbols one-by-one.
    for (var symbol = 0; symbol < codeLengthsSize; ++symbol) {
      if (codeLengths[symbol] > 0) {
        if (!_addSymbol(symbol, codes[symbol], codeLengths[symbol])) {
          return false;
        }
      }
    }

    return _isFull();
  }

  bool buildExplicit(List<int> codeLengths, List<int> codes, List<int> symbols,
      int maxSymbol, int numSymbols) {
    // Initialize the tree. Will fail if num_symbols = 0.
    if (!_init(numSymbols)) {
      return false;
    }

    // Add symbols one-by-one.
    for (var i = 0; i < numSymbols; ++i) {
      if (codes[i] != -1) {
        if (symbols[i] < 0 || symbols[i] >= maxSymbol) {
          return _isFull();
        }

        if (!_addSymbol(symbols[i], codes[i], codeLengths[i])) {
          return _isFull();
        }
      }
    }

    return _isFull();
  }

  // Decodes the next Huffman code from bit-stream.
  // input.fillBitWindow() needs to be called at minimum every second call
  // to ReadSymbol, in order to pre-fetch enough bits.
  int readSymbol(VP8LBitReader br) {
    var node = 0;
    var bits = br.prefetchBits();
    var newBitPos = br.bitPos;
    // Check if we find the bit combination from the Huffman lookup table.
    final lut_ix = bits & (HUFF_LUT - 1);
    final lut_bits = lutBits[lut_ix];

    if (lut_bits <= HUFF_LUT_BITS) {
      br.bitPos = br.bitPos + lut_bits;
      return lutSymbol[lut_ix];
    }

    node += lutJump[lut_ix];
    newBitPos += HUFF_LUT_BITS;
    bits >>= HUFF_LUT_BITS;

    // Decode the value from a binary tree.
    do {
      node = _nextNode(node, bits & 1);
      bits >>= 1;
      ++newBitPos;
    } while (_nodeIsNotLeaf(node));

    br.bitPos = newBitPos;

    return _nodeSymbol(node);
  }

  bool _addSymbol(int symbol, int code, int codeLength) {
    var step = HUFF_LUT_BITS;
    int baseCode;
    var node = 0;

    if (codeLength <= HUFF_LUT_BITS) {
      baseCode = _reverseBitsShort(code, codeLength);
      for (var i = 0; i < (1 << (HUFF_LUT_BITS - codeLength)); ++i) {
        final idx = baseCode | (i << codeLength);
        lutSymbol[idx] = symbol;
        lutBits[idx] = codeLength;
      }
    } else {
      baseCode = _reverseBitsShort(
          (code >> (codeLength - HUFF_LUT_BITS)), HUFF_LUT_BITS);
    }

    while (codeLength-- > 0) {
      if (node >= maxNodes) {
        return false;
      }

      if (_nodeIsEmpty(node)) {
        if (_isFull()) {
          // error: too many symbols.
          return false;
        }

        _assignChildren(node);
      } else if (!_nodeIsNotLeaf(node)) {
        // leaf is already occupied.
        return false;
      }

      node += _nodeChildren(node) + ((code >> codeLength) & 1);

      if (--step == 0) {
        lutJump[baseCode] = node;
      }
    }

    if (_nodeIsEmpty(node)) {
      // turn newly created node into a leaf.
      _nodeSetChildren(node, 0);
    } else if (_nodeIsNotLeaf(node)) {
      // trying to assign a symbol to already used code.
      return false;
    }

    // Add symbol in this node.
    _nodeSetSymbol(node, symbol);

    return true;
  }

  // Pre-reversed 4-bit values.
  static const List<int> _REVERSED_BITS = [
    0x0,
    0x8,
    0x4,
    0xc,
    0x2,
    0xa,
    0x6,
    0xe,
    0x1,
    0x9,
    0x5,
    0xd,
    0x3,
    0xb,
    0x7,
    0xf
  ];

  int _reverseBitsShort(int bits, int numBits) {
    final v = (_REVERSED_BITS[bits & 0xf] << 4) | _REVERSED_BITS[bits >> 4];
    return v >> (8 - numBits);
  }

  bool _isFull() => (numNodes == maxNodes);

  int _nextNode(int node, int rightChild) =>
      node + _nodeChildren(node) + rightChild;

  int _nodeSymbol(int node) => tree[(node << 1)];

  void _nodeSetSymbol(int node, int symbol) {
    tree[(node << 1)] = symbol;
  }

  int _nodeChildren(int node) => tree[(node << 1) + 1];

  void _nodeSetChildren(int node, int children) {
    tree[(node << 1) + 1] = children;
  }

  bool _nodeIsNotLeaf(int node) => tree[(node << 1) + 1] != 0;

  bool _nodeIsEmpty(int node) => tree[(node << 1) + 1] < 0;

  void _assignChildren(int node) {
    final children = numNodes;
    _nodeSetChildren(node, children - node);

    numNodes += 2;

    _nodeSetChildren(children, -1);
    _nodeSetChildren(children + 1, -1);
  }

  bool _huffmanCodeLengthsToCodes(
      List<int> codeLengths, int codeLengthsSize, List<int> huffCodes) {
    int symbol;
    int codeLen;
    final codeLengthHist = Int32List(VP8L.MAX_ALLOWED_CODE_LENGTH + 1);
    int currCode;
    final nextCodes = Int32List(VP8L.MAX_ALLOWED_CODE_LENGTH + 1);
    var maxCodeLength = 0;

    // Calculate max code length.
    for (symbol = 0; symbol < codeLengthsSize; ++symbol) {
      if (codeLengths[symbol] > maxCodeLength) {
        maxCodeLength = codeLengths[symbol];
      }
    }

    if (maxCodeLength > VP8L.MAX_ALLOWED_CODE_LENGTH) {
      return false;
    }

    // Calculate code length histogram.
    for (symbol = 0; symbol < codeLengthsSize; ++symbol) {
      ++codeLengthHist[codeLengths[symbol]];
    }

    codeLengthHist[0] = 0;

    // Calculate the initial values of 'next_codes' for each code length.
    // next_codes[code_len] denotes the code to be assigned to the next symbol
    // of code length 'code_len'.
    currCode = 0;
    // Unused, as code length = 0 implies code doesn't exist.
    nextCodes[0] = -1;

    for (codeLen = 1; codeLen <= maxCodeLength; ++codeLen) {
      currCode = (currCode + codeLengthHist[codeLen - 1]) << 1;
      nextCodes[codeLen] = currCode;
    }

    // Get symbols.
    for (symbol = 0; symbol < codeLengthsSize; ++symbol) {
      if (codeLengths[symbol] > 0) {
        huffCodes[symbol] = nextCodes[codeLengths[symbol]]++;
      } else {
        huffCodes[symbol] = -1;
      }
    }

    return true;
  }
}

// A group of huffman trees.
@internal
class HTreeGroup {
  final List<HuffmanTree> htrees;

  HTreeGroup()
      : htrees = List<HuffmanTree>.generate(
            VP8L.HUFFMAN_CODES_PER_META_CODE, (_) => HuffmanTree(),
            growable: false);

  HuffmanTree operator [](int index) => htrees[index];
}
