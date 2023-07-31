import 'dart:typed_data';
import 'bzip2/bzip2.dart';
import 'bzip2/bz2_bit_writer.dart';
import 'util/archive_exception.dart';
import 'util/byte_order.dart';
import 'util/input_stream.dart';
import 'util/output_stream.dart';

/// Compress data using the BZip2 format.
/// Derived from libbzip2 (http://www.bzip.org).
class BZip2Encoder {
  List<int> encode(List<int> data) {
    input = InputStream(data, byteOrder: BIG_ENDIAN);
    final output = OutputStream(byteOrder: BIG_ENDIAN);

    bw = Bz2BitWriter(output);

    final blockSize100k = 9;

    bw.writeBytes(BZip2.bzhSignature);
    bw.writeByte(BZip2.hdr0 + blockSize100k);

    _nblockMax = 100000 * blockSize100k - 19;
    _workFactor = 30;
    var combinedCRC = 0;

    var n = 100000 * blockSize100k;
    _arr1 = Uint32List(n);
    _arr2 = Uint32List(n + _bzNOvershoot);
    _ftab = Uint32List(65537);
    _block = Uint8List.view(_arr2.buffer);
    _mtfv = Uint16List.view(_arr1.buffer);
    _unseqToSeq = Uint8List(256);
    _blockNo = 0;
    _origPtr = 0;

    _selector = Uint8List(_bzMaxSelectors);
    _selectorMtf = Uint8List(_bzMaxSelectors);
    _len = List<Uint8List>.filled(_bzNGroups, BZip2.emptyUint8List);
    _code = List<Int32List>.filled(_bzNGroups, BZip2.emptyInt32List);
    _rfreq = List<Int32List>.filled(_bzNGroups, BZip2.emptyInt32List);

    for (var i = 0; i < _bzNGroups; ++i) {
      _len[i] = Uint8List(_bzMaxAlphaSize);
      _code[i] = Int32List(_bzMaxAlphaSize);
      _rfreq[i] = Int32List(_bzMaxAlphaSize);
    }

    _lenPack =
        List<Uint32List>.filled(_bzMaxAlphaSize, BZip2.emptyUint32List);
    for (var i = 0; i < _bzMaxAlphaSize; ++i) {
      _lenPack[i] = Uint32List(4);
    }

    // Write blocks
    while (!input.isEOS) {
      var blockCRC = _writeBlock();
      combinedCRC = ((combinedCRC << 1) | (combinedCRC >> 31)) & 0xffffffff;
      combinedCRC ^= blockCRC;
      _blockNo++;
    }

    bw.writeBytes(BZip2.eosMagic);
    bw.writeUint32(combinedCRC);
    bw.flush();

    return output.getBytes();
  }

  int _writeBlock() {
    _inUse = Uint8List(256);

    _nblock = 0;
    _blockCRC = BZip2.initialCrc;

    // copy_input_until_stop
    _stateInCh = 256;
    _stateInLen = 0;
    while (_nblock < _nblockMax && !input.isEOS) {
      _addCharToBlock(input.readByte());
    }

    if (_stateInCh < 256) {
      _addPairToBlock();
    }

    _stateInCh = 256;
    _stateInLen = 0;

    _blockCRC = BZip2.finalizeCrc(_blockCRC);

    _compressBlock();

    return _blockCRC;
  }

  void _compressBlock() {
    if (_nblock > 0) {
      _blockSort();
    }

    if (_nblock > 0) {
      bw.writeBytes(BZip2.compressedMagic);
      bw.writeUint32(_blockCRC);

      bw.writeBits(1, 0); // set randomize to 'no'

      bw.writeBits(24, _origPtr);

      _generateMTFValues();

      _sendMTFValues();
    }
  }

  void _generateMTFValues() {
    final yy = Uint8List(256);

    // After sorting (eg, here),
    // s->arr1 [ 0 .. s->nblock-1 ] holds sorted order,
    // and
    //         ((UChar*)s->arr2) [ 0 .. s->nblock-1 ]
    //         holds the original block data.
    //
    //      The first thing to do is generate the MTF values,
    //      and put them in
    //         ((UInt16*)s->arr1) [ 0 .. s->nblock-1 ].
    //      Because there are strictly fewer or equal MTF values
    //      than block values, ptr values in this area are overwritten
    //      with MTF values only when they are no longer needed.
    //
    //      The final compressed bitstream is generated into the
    //      area starting at
    //         (UChar*) (&((UChar*)s->arr2)[s->nblock])
    _nInUse = 0;
    for (var i = 0; i < 256; i++) {
      if (_inUse[i] != 0) {
        _unseqToSeq[i] = _nInUse;
        _nInUse++;
      }
    }

    final eob = _nInUse + 1;

    _mtfFreq = Int32List(_bzMaxAlphaSize);

    var wr = 0;
    var zPend = 0;
    for (var i = 0; i < _nInUse; i++) {
      yy[i] = i;
    }

    for (var i = 0; i < _nblock; i++) {
      _assert(wr <= i);
      var j = _arr1[i] - 1;
      if (j < 0) {
        j += _nblock;
      }

      var lli = _unseqToSeq[_block[j]];
      _assert(lli < _nInUse);

      if (yy[0] == lli) {
        zPend++;
      } else {
        if (zPend > 0) {
          zPend--;
          while (true) {
            if (zPend & 1 != 0) {
              _mtfv[wr] = _bzRunB;
              wr++;
              _mtfFreq[_bzRunB]++;
            } else {
              _mtfv[wr] = _bzRunA;
              wr++;
              _mtfFreq[_bzRunA]++;
            }

            if (zPend < 2) {
              break;
            }

            zPend = (zPend - 2) ~/ 2;
          }

          zPend = 0;
        }

        var rtmp = yy[1];
        yy[1] = yy[0];
        var ryyj = 1;
        var rlli = lli;
        while (rlli != rtmp) {
          ryyj++;
          var rtmp2 = rtmp;
          rtmp = yy[ryyj];
          yy[ryyj] = rtmp2;
        }

        yy[0] = rtmp;
        j = ryyj;

        _mtfv[wr] = j + 1;
        wr++;
        _mtfFreq[j + 1]++;
      }
    }

    if (zPend > 0) {
      zPend--;
      while (true) {
        if (zPend & 1 != 0) {
          _mtfv[wr] = _bzRunB;
          wr++;
          _mtfFreq[_bzRunB]++;
        } else {
          _mtfv[wr] = _bzRunA;
          wr++;
          _mtfFreq[_bzRunA]++;
        }
        if (zPend < 2) {
          break;
        }

        zPend = (zPend - 2) ~/ 2;
      }

      zPend = 0;
    }

    _mtfv[wr] = eob;
    wr++;
    _mtfFreq[eob]++;

    _nMTF = wr;
  }

  void _sendMTFValues() {
    final cost = Uint16List(_bzNGroups);
    final fave = Int32List(_bzNGroups);
    var nSelectors = 0;

    var alphaSize = _nInUse + 2;
    for (var t = 0; t < _bzNGroups; t++) {
      for (var v = 0; v < alphaSize; v++) {
        _len[t][v] = _bzGreaterICost;
      }
    }

    // Decide how many coding tables to use
    int nGroups;
    _assert(_nMTF > 0);
    if (_nMTF < 200) {
      nGroups = 2;
    } else if (_nMTF < 600) {
      nGroups = 3;
    } else if (_nMTF < 1200) {
      nGroups = 4;
    } else if (_nMTF < 2400) {
      nGroups = 5;
    } else {
      nGroups = 6;
    }

    // Generate an initial set of coding tables
    var nPart = nGroups;
    var remF = _nMTF;
    var gs = 0;
    var ge = 0;

    while (nPart > 0) {
      var tFreq = remF ~/ nPart;
      var aFreq = 0;
      ge = gs - 1;

      while (aFreq < tFreq && ge < alphaSize - 1) {
        ge++;
        aFreq += _mtfFreq[ge];
      }

      if (ge > gs &&
          nPart != nGroups &&
          nPart != 1 &&
          ((nGroups - nPart) % 2 == 1)) {
        aFreq -= _mtfFreq[ge];
        ge--;
      }

      for (var v = 0; v < alphaSize; v++) {
        if (v >= gs && v <= ge) {
          _len[nPart - 1][v] = _bzLesserICost;
        } else {
          _len[nPart - 1][v] = _bzGreaterICost;
        }
      }

      nPart--;
      gs = ge + 1;
      remF -= aFreq;
    }

    // Iterate up to BZ_N_ITERS times to improve the tables.
    for (var iter = 0; iter < _bzNIters; iter++) {
      for (var t = 0; t < nGroups; t++) {
        fave[t] = 0;
      }
      for (var t = 0; t < nGroups; t++) {
        for (var v = 0; v < alphaSize; v++) {
          _rfreq[t][v] = 0;
        }
      }

      // Set up an auxiliary length table which is used to fast-track
      // the common case (nGroups == 6).
      if (nGroups == 6) {
        for (var v = 0; v < alphaSize; v++) {
          _lenPack[v][0] = (_len[1][v] << 16) | _len[0][v];
          _lenPack[v][1] = (_len[3][v] << 16) | _len[2][v];
          _lenPack[v][2] = (_len[5][v] << 16) | _len[4][v];
        }
      }

      nSelectors = 0;
      var totc = 0; // ignore: unused_local_variable
      gs = 0;
      while (true) {
        // Set group start & end marks.
        if (gs >= _nMTF) {
          break;
        }

        var ge = gs + _bzGSize - 1;
        if (ge >= _nMTF) {
          ge = _nMTF - 1;
        }

        // Calculate the cost of this group as coded
        // by each of the coding tables.
        for (var t = 0; t < nGroups; t++) {
          cost[t] = 0;
        }

        if (nGroups == 6 && 50 == ge - gs + 1) {
          // fast track the common case
          var cost01 = 0;
          var cost23 = 0;
          var cost45 = 0;

          void bzIter(int nn) {
            var icv = _mtfv[gs + nn];
            cost01 += _lenPack[icv][0];
            cost23 += _lenPack[icv][1];
            cost45 += _lenPack[icv][2];
          }

          bzIter(0);
          bzIter(1);
          bzIter(2);
          bzIter(3);
          bzIter(4);
          bzIter(5);
          bzIter(6);
          bzIter(7);
          bzIter(8);
          bzIter(9);
          bzIter(10);
          bzIter(11);
          bzIter(12);
          bzIter(13);
          bzIter(14);
          bzIter(15);
          bzIter(16);
          bzIter(17);
          bzIter(18);
          bzIter(19);
          bzIter(20);
          bzIter(21);
          bzIter(22);
          bzIter(23);
          bzIter(24);
          bzIter(25);
          bzIter(26);
          bzIter(27);
          bzIter(28);
          bzIter(29);
          bzIter(30);
          bzIter(31);
          bzIter(32);
          bzIter(33);
          bzIter(34);
          bzIter(35);
          bzIter(36);
          bzIter(37);
          bzIter(38);
          bzIter(39);
          bzIter(40);
          bzIter(41);
          bzIter(42);
          bzIter(43);
          bzIter(44);
          bzIter(45);
          bzIter(46);
          bzIter(47);
          bzIter(48);
          bzIter(49);

          cost[0] = cost01 & 0xffff;
          cost[1] = cost01 >> 16;
          cost[2] = cost23 & 0xffff;
          cost[3] = cost23 >> 16;
          cost[4] = cost45 & 0xffff;
          cost[5] = cost45 >> 16;
        } else {
          // slow version which correctly handles all situations
          for (var i = gs; i <= ge; i++) {
            var icv = _mtfv[i];
            for (var t = 0; t < nGroups; t++) {
              cost[t] += _len[t][icv];
            }
          }
        }

        // Find the coding table which is best for this group,
        // and record its identity in the selector table.
        var bc = 999999999;
        var bt = -1;
        for (var t = 0; t < nGroups; t++) {
          if (cost[t] < bc) {
            bc = cost[t];
            bt = t;
          }
        }

        totc += bc;
        fave[bt]++;
        _selector[nSelectors] = bt;
        nSelectors++;

        // Increment the symbol frequencies for the selected table.
        if (nGroups == 6 && 50 == ge - gs + 1) {
          // fast track the common case
          void bzItur(int nn) {
            _rfreq[bt][_mtfv[gs + nn]]++;
          }

          bzItur(0);
          bzItur(1);
          bzItur(2);
          bzItur(3);
          bzItur(4);
          bzItur(5);
          bzItur(6);
          bzItur(7);
          bzItur(8);
          bzItur(9);
          bzItur(10);
          bzItur(11);
          bzItur(12);
          bzItur(13);
          bzItur(14);
          bzItur(15);
          bzItur(16);
          bzItur(17);
          bzItur(18);
          bzItur(19);
          bzItur(20);
          bzItur(21);
          bzItur(22);
          bzItur(23);
          bzItur(24);
          bzItur(25);
          bzItur(26);
          bzItur(27);
          bzItur(28);
          bzItur(29);
          bzItur(30);
          bzItur(31);
          bzItur(32);
          bzItur(33);
          bzItur(34);
          bzItur(35);
          bzItur(36);
          bzItur(37);
          bzItur(38);
          bzItur(39);
          bzItur(40);
          bzItur(41);
          bzItur(42);
          bzItur(43);
          bzItur(44);
          bzItur(45);
          bzItur(46);
          bzItur(47);
          bzItur(48);
          bzItur(49);
        } else {
          // slow version which correctly handles all situations
          for (var i = gs; i <= ge; i++) {
            _rfreq[bt][_mtfv[i]]++;
          }
        }

        gs = ge + 1;
      }

      // Recompute the tables based on the accumulated frequencies.
      for (var t = 0; t < nGroups; t++) {
        _hbMakeCodeLengths(_len[t], _rfreq[t], alphaSize, 17);
      }
    }

    _assert(nGroups < 8);
    _assert(nSelectors < 32768 && nSelectors <= (2 + (900000 ~/ _bzGSize)));

    // Compute MTF values for the selectors.
    final pos = Uint8List(_bzNGroups);
    for (var i = 0; i < nGroups; i++) {
      pos[i] = i;
    }

    for (var i = 0; i < nSelectors; i++) {
      var lli = _selector[i];
      var j = 0;
      var tmp = pos[j];
      while (lli != tmp) {
        j++;
        var tmp2 = tmp;
        tmp = pos[j];
        pos[j] = tmp2;
      }
      pos[0] = tmp;
      _selectorMtf[i] = j;
    }

    // Assign actual codes for the tables.
    for (var t = 0; t < nGroups; t++) {
      var minLen = 32;
      var maxLen = 0;
      for (var i = 0; i < alphaSize; i++) {
        if (_len[t][i] > maxLen) {
          maxLen = _len[t][i];
        }
        if (_len[t][i] < minLen) {
          minLen = _len[t][i];
        }
      }
      _assert(!(maxLen > 17));
      _assert(!(minLen < 1));
      _hbAssignCodes(_code[t], _len[t], minLen, maxLen, alphaSize);
    }

    // Transmit the mapping table.
    final inUse16 = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      inUse16[i] = 0;
      for (var j = 0; j < 16; j++) {
        if (_inUse[i * 16 + j] != 0) {
          inUse16[i] = 1;
        }
      }
    }

    for (var i = 0; i < 16; i++) {
      if (inUse16[i] != 0) {
        bw.writeBits(1, 1);
      } else {
        bw.writeBits(1, 0);
      }
    }

    for (var i = 0; i < 16; i++) {
      if (inUse16[i] != 0) {
        for (var j = 0; j < 16; j++) {
          if (_inUse[i * 16 + j] != 0) {
            bw.writeBits(1, 1);
          } else {
            bw.writeBits(1, 0);
          }
        }
      }
    }

    // Now the selectors.
    bw.writeBits(3, nGroups);
    bw.writeBits(15, nSelectors);
    for (var i = 0; i < nSelectors; i++) {
      for (var j = 0; j < _selectorMtf[i]; j++) {
        bw.writeBits(1, 1);
      }
      bw.writeBits(1, 0);
    }

    // Now the coding tables.
    for (var t = 0; t < nGroups; t++) {
      var curr = _len[t][0];
      bw.writeBits(5, curr);
      for (var i = 0; i < alphaSize; i++) {
        while (curr < _len[t][i]) {
          bw.writeBits(2, 2);
          curr++; // 10
        }

        while (curr > _len[t][i]) {
          bw.writeBits(2, 3);
          curr--; // 11
        }

        bw.writeBits(1, 0);
      }
    }

    // And finally, the block data proper
    var selCtr = 0;
    gs = 0;
    while (true) {
      if (gs >= _nMTF) {
        break;
      }

      var ge = gs + _bzGSize - 1;
      if (ge >= _nMTF) {
        ge = _nMTF - 1;
      }

      _assert(_selector[selCtr] < nGroups);

      if (nGroups == 6 && 50 == ge - gs + 1) {
        // fast track the common case
        int mtfvi;
        final sLenSelSelCtr = _len[_selector[selCtr]];
        final sCodeSelSelCtr = _code[_selector[selCtr]];

        void bzItah(int nn) {
          mtfvi = _mtfv[gs + nn];
          bw.writeBits(sLenSelSelCtr[mtfvi], sCodeSelSelCtr[mtfvi]);
        }

        bzItah(0);
        bzItah(1);
        bzItah(2);
        bzItah(3);
        bzItah(4);
        bzItah(5);
        bzItah(6);
        bzItah(7);
        bzItah(8);
        bzItah(9);
        bzItah(10);
        bzItah(11);
        bzItah(12);
        bzItah(13);
        bzItah(14);
        bzItah(15);
        bzItah(16);
        bzItah(17);
        bzItah(18);
        bzItah(19);
        bzItah(20);
        bzItah(21);
        bzItah(22);
        bzItah(23);
        bzItah(24);
        bzItah(25);
        bzItah(26);
        bzItah(27);
        bzItah(28);
        bzItah(29);
        bzItah(30);
        bzItah(31);
        bzItah(32);
        bzItah(33);
        bzItah(34);
        bzItah(35);
        bzItah(36);
        bzItah(37);
        bzItah(38);
        bzItah(39);
        bzItah(40);
        bzItah(41);
        bzItah(42);
        bzItah(43);
        bzItah(44);
        bzItah(45);
        bzItah(46);
        bzItah(47);
        bzItah(48);
        bzItah(49);
      } else {
        // slow version which correctly handles all situations
        for (var i = gs; i <= ge; i++) {
          bw.writeBits(_len[_selector[selCtr]][_mtfv[i]],
              _code[_selector[selCtr]][_mtfv[i]]);
        }
      }

      gs = ge + 1;
      selCtr++;
    }

    _assert(selCtr == nSelectors);
  }

  void _hbMakeCodeLengths(
      Uint8List len, Int32List freq, int alphaSize, int maxLen) {
    // Nodes and heap entries run from 1.  Entry 0
    // for both the heap and nodes is a sentinel.
    var heap = Int32List(_bzMaxAlphaSize + 2);
    var weight = Int32List(_bzMaxAlphaSize * 2);
    var parent = Int32List(_bzMaxAlphaSize * 2);
    var nHeap = 0;
    int nNodes;

    for (var i = 0; i < alphaSize; i++) {
      weight[i + 1] = (freq[i] == 0 ? 1 : freq[i]) << 8;
    }

    void upHeap(int z) {
      var zz = z;
      var tmp = heap[zz];
      while (weight[tmp] < weight[heap[zz >> 1]]) {
        heap[zz] = heap[zz >> 1];
        zz >>= 1;
      }
      heap[zz] = tmp;
    }

    void downHeap(int z) {
      var zz = z;
      var tmp = heap[zz];
      while (true) {
        var yy = zz << 1;
        if (yy > nHeap) {
          break;
        }
        if (yy < nHeap && weight[heap[yy + 1]] < weight[heap[yy]]) {
          yy++;
        }
        if (weight[tmp] < weight[heap[yy]]) {
          break;
        }
        heap[zz] = heap[yy];
        zz = yy;
      }
      heap[zz] = tmp;
    }

    int weightOf(int zz0) => ((zz0) & 0xffffff00);
    int depthOf(int zz1) => ((zz1) & 0x000000ff);
    int myMax(int zz2, int zz3) => ((zz2) > (zz3) ? (zz2) : (zz3));
    int addWeights(int zw1, int zw2) =>
        (weightOf(zw1) + weightOf(zw2)) |
        (1 + myMax(depthOf(zw1), depthOf(zw2)));

    while (true) {
      nNodes = alphaSize;
      nHeap = 0;

      heap[0] = 0;
      weight[0] = 0;
      parent[0] = -2;

      for (var i = 1; i <= alphaSize; i++) {
        parent[i] = -1;
        nHeap++;
        heap[nHeap] = i;
        upHeap(nHeap);
      }

      _assert(nHeap < (_bzMaxAlphaSize + 2));

      while (nHeap > 1) {
        var n1 = heap[1];
        heap[1] = heap[nHeap];
        nHeap--;
        downHeap(1);
        var n2 = heap[1];
        heap[1] = heap[nHeap];
        nHeap--;
        downHeap(1);
        nNodes++;
        parent[n1] = parent[n2] = nNodes;
        weight[nNodes] = addWeights(weight[n1], weight[n2]);
        parent[nNodes] = -1;
        nHeap++;
        heap[nHeap] = nNodes;
        upHeap(nHeap);
      }

      _assert(nNodes < (_bzMaxAlphaSize * 2));

      var tooLong = false;
      for (var i = 1; i <= alphaSize; i++) {
        var j = 0;
        var k = i;
        while (parent[k] >= 0) {
          k = parent[k];
          j++;
        }
        len[i - 1] = j;
        if (j > maxLen) {
          tooLong = true;
        }
      }

      if (!tooLong) {
        break;
      }

      for (var i = 1; i <= alphaSize; i++) {
        var j = weight[i] >> 8;
        j = 1 + (j ~/ 2);
        weight[i] = j << 8;
      }
    }
  }

  void _hbAssignCodes(Int32List codes, Uint8List length, int minLen, int maxLen,
      int alphaSize) {
    var vec = 0;
    for (var n = minLen; n <= maxLen; n++) {
      for (var i = 0; i < alphaSize; i++) {
        if (length[i] == n) {
          codes[i] = vec;
          vec++;
        }
      }
      vec <<= 1;
    }
  }

  void _blockSort() {
    if (_nblock < 10000) {
      _fallbackSort(_arr1, _arr2, _ftab, _nblock);
    } else {
      // Calculate the location for quadrant, remembering to get
      // the alignment right.  Assumes that &(block[0]) is at least
      // 2-byte aligned -- this should be ok since block is really
      // the first section of arr2.
      var i = _nblock + _bzNOvershoot;
      if (i & 1 != 0) {
        i++;
      }
      final quadrant = Uint16List.view(_block.buffer, i);

      var wfact = _workFactor;
      // (wfact-1) / 3 puts the default-factor-30
      // transition point at very roughly the same place as
      // with v0.1 and v0.9.0.
      // Not that it particularly matters any more, since the
      // resulting compressed stream is now the same regardless
      // of whether or not we use the main sort or fallback sort.
      if (wfact < 1) {
        wfact = 1;
      }
      if (wfact > 100) {
        wfact = 100;
      }

      var budgetInit = _nblock * ((wfact - 1) ~/ 3);
      _budget = budgetInit;

      _mainSort(_arr1, _block, quadrant, _ftab, _nblock);
      if (_budget < 0) {
        _fallbackSort(_arr1, _arr2, _ftab, _nblock);
      }
    }

    _origPtr = -1;
    for (var i = 0; i < _nblock; i++) {
      if (_arr1[i] == 0) {
        _origPtr = i;
        break;
      }
    }

    _assert(_origPtr != -1);
  }

  void _assert(bool cond) {
    if (!cond) {
      throw ArchiveException('Data error');
    }
  }

  void _fallbackSort(
      Uint32List fmap, Uint32List eclass, Uint32List bhtab, int nblock) {
    final ftab = Int32List(257);
    final ftabCopy = Int32List(256);
    final eclass8 = Uint8List.view(eclass.buffer);

    int setBh(int zz) => bhtab[zz >> 5] |= (1 << (zz & 31));
    int clearBh(int zz) => bhtab[zz >> 5] &= ~(1 << (zz & 31));
    bool isSetBh(int zz) => (bhtab[zz >> 5] & (1 << (zz & 31)) != 0);
    int wordBh(int zz) => bhtab[(zz) >> 5];
    bool unalignedBh(int zz) => ((zz) & 0x01f) != 0;

    // Initial 1-char radix sort to generate
    // initial fmap and initial BH bits.
    for (var i = 0; i < 257; i++) {
      ftab[i] = 0;
    }
    for (var i = 0; i < nblock; i++) {
      ftab[eclass8[i]]++;
    }
    for (var i = 0; i < 256; i++) {
      ftabCopy[i] = ftab[i];
    }
    for (var i = 1; i < 257; i++) {
      ftab[i] += ftab[i - 1];
    }

    for (var i = 0; i < nblock; i++) {
      final j = eclass8[i];
      final k = ftab[j] - 1;
      ftab[j] = k;
      fmap[k] = i;
    }

    final nBhtab = 2 + (nblock ~/ 32);
    for (var i = 0; i < nBhtab; i++) {
      bhtab[i] = 0;
    }

    for (var i = 0; i < 256; i++) {
      setBh(ftab[i]);
    }

    // Inductively refine the buckets.  Kind-of an
    // "exponential radix sort" (!), inspired by the
    // Manber-Myers suffix array construction algorithm.

    // set sentinel bits for block-end detection
    for (var i = 0; i < 32; i++) {
      setBh(nblock + 2 * i);
      clearBh(nblock + 2 * i + 1);
    }

    // the log(N) loop
    var H = 1;
    while (true) {
      var j = 0;
      for (var i = 0; i < nblock; i++) {
        if (isSetBh(i)) {
          j = i;
        }
        var k = fmap[i] - H;
        if (k < 0) {
          k += nblock;
        }
        eclass[k] = j;
      }

      var nNotDone = 0;
      var r = -1;
      while (true) {
        // find the next non-singleton bucket
        var k = r + 1;
        while (isSetBh(k) && unalignedBh(k)) {
          k++;
        }
        if (isSetBh(k)) {
          while (wordBh(k) == 0xffffffff) {
            k += 32;
          }
          while (isSetBh(k)) {
            k++;
          }
        }

        var l = k - 1;
        if (l >= nblock) {
          break;
        }
        while (!isSetBh(k) && unalignedBh(k)) {
          k++;
        }
        if (!isSetBh(k)) {
          while (wordBh(k) == 0x00000000) {
            k += 32;
          }
          while (!isSetBh(k)) {
            k++;
          }
        }

        r = k - 1;
        if (r >= nblock) {
          break;
        }

        // now [l, r] bracket current bucket
        if (r > l) {
          nNotDone += (r - l + 1);
          _fallbackQSort3(fmap, eclass, l, r);

          // scan bucket and generate header bits
          var cc = -1;
          for (var i = l; i <= r; i++) {
            var cc1 = eclass[fmap[i]];
            if (cc != cc1) {
              setBh(i);
              cc = cc1;
            }
          }
        }
      }

      H *= 2;
      if (H > nblock || nNotDone == 0) {
        break;
      }
    }

    // Reconstruct the original block in
    // eclass8 [0 .. nblock-1], since the
    // previous phase destroyed it.
    var j = 0;
    for (var i = 0; i < nblock; i++) {
      while (ftabCopy[j] == 0) {
        j++;
      }
      ftabCopy[j]--;
      eclass8[fmap[i]] = j;
    }
    _assert(j < 256);
  }

  void _fallbackQSort3(Uint32List fmap, Uint32List eclass, int loSt, int hiSt) {
    const fallbackQSortSmallThreshold = 10;
    const fallbackQSortStackSize = 100;

    final stackLo = Int32List(fallbackQSortStackSize);
    final stackHi = Int32List(fallbackQSortStackSize);
    var sp = 0;

    void fpush(int lz, int hz) {
      stackLo[sp] = lz;
      stackHi[sp] = hz;
      sp++;
    }

    int fmin(int a, int b) => ((a) < (b)) ? (a) : (b);

    void fvswap(int yyp1, int yyp2, int yyn) {
      while (yyn > 0) {
        final t = fmap[yyp1];
        fmap[yyp1] = fmap[yyp2];
        fmap[yyp2] = t;
        yyp1++;
        yyp2++;
        yyn--;
      }
    }

    var r = 0;

    fpush(loSt, hiSt);

    while (sp > 0) {
      _assert(sp < fallbackQSortStackSize - 1);

      sp--;
      final lo = stackLo[sp];
      final hi = stackHi[sp];

      if (hi - lo < fallbackQSortSmallThreshold) {
        _fallbackSimpleSort(fmap, eclass, lo, hi);
        continue;
      }

      // Random partitioning.  Median of 3 sometimes fails to
      // avoid bad cases.  Median of 9 seems to help but
      // looks rather expensive.  This too seems to work but
      // is cheaper.  Guidance for the magic constants
      // 7621 and 32768 is taken from Sedgewick's algorithms
      // book, chapter 35.
      r = ((r * 7621) + 1) % 32768;
      var r3 = r % 3;
      int med;
      if (r3 == 0) {
        med = eclass[fmap[lo]];
      } else if (r3 == 1) {
        med = eclass[fmap[(lo + hi) >> 1]];
      } else {
        med = eclass[fmap[hi]];
      }

      var unLo = lo;
      var ltLo = lo;
      var unHi = hi;
      var gtHi = hi;

      while (true) {
        while (true) {
          if (unLo > unHi) {
            break;
          }

          var n = eclass[fmap[unLo]] - med;
          if (n == 0) {
            var t = fmap[unLo];
            fmap[unLo] = fmap[ltLo];
            fmap[ltLo] = t;
            ltLo++;
            unLo++;
            continue;
          }
          if (n > 0) {
            break;
          }
          unLo++;
        }
        while (true) {
          if (unLo > unHi) {
            break;
          }
          var n = eclass[fmap[unHi]] - med;
          if (n == 0) {
            var t = fmap[unHi];
            fmap[unHi] = fmap[gtHi];
            fmap[gtHi] = t;
            gtHi--;
            unHi--;
            continue;
          }
          if (n < 0) {
            break;
          }
          unHi--;
        }
        if (unLo > unHi) {
          break;
        }

        var t = fmap[unLo];
        fmap[unLo] = fmap[unHi];
        fmap[unHi] = t;
        unLo++;
        unHi--;
      }

      _assert(unHi == unLo - 1);

      if (gtHi < ltLo) {
        continue;
      }

      var n = fmin(ltLo - lo, unLo - ltLo);
      fvswap(lo, unLo - n, n);
      var m = fmin(hi - gtHi, gtHi - unHi);
      fvswap(unLo, hi - m + 1, m);

      n = lo + unLo - ltLo - 1;
      m = hi - (gtHi - unHi) + 1;

      if (n - lo > hi - m) {
        fpush(lo, n);
        fpush(m, hi);
      } else {
        fpush(m, hi);
        fpush(lo, n);
      }
    }
  }

  void _fallbackSimpleSort(Uint32List fmap, Uint32List eclass, int lo, int hi) {
    if (lo == hi) {
      return;
    }

    if (hi - lo > 3) {
      for (var i = hi - 4; i >= lo; i--) {
        var tmp = fmap[i];
        var ecTmp = eclass[tmp];
        int j;
        for (j = i + 4; j <= hi && ecTmp > eclass[fmap[j]]; j += 4) {
          fmap[j - 4] = fmap[j];
        }
        fmap[j - 4] = tmp;
      }
    }

    for (var i = hi - 1; i >= lo; i--) {
      var tmp = fmap[i];
      var ecTmp = eclass[tmp];
      int j;
      for (j = i + 1; j <= hi && ecTmp > eclass[fmap[j]]; j++) {
        fmap[j - 1] = fmap[j];
      }
      fmap[j - 1] = tmp;
    }
  }

  void _mainSort(Uint32List ptr, Uint8List block, Uint16List quadrant,
      Uint32List ftab, int nblock) {
    final runningOrder = Int32List(256);
    final bigDone = Uint8List(256);
    final copyStart = Int32List(256);
    final copyEnd = Int32List(256);

    int bigFreq(int b) => (_ftab[((b) + 1) << 8] - _ftab[(b) << 8]);

    const setMask = 2097152;
    const clearMask = 4292870143;

    // set up the 2-byte frequency table
    for (var i = 65536; i >= 0; i--) {
      ftab[i] = 0;
    }

    var j = block[0] << 8;
    var i = nblock - 1;

    for (; i >= 3; i -= 4) {
      quadrant[i] = 0;
      j = (j >> 8) | ((block[i]) << 8);
      ftab[j]++;
      quadrant[i - 1] = 0;
      j = (j >> 8) | ((block[i - 1]) << 8);
      ftab[j]++;
      quadrant[i - 2] = 0;
      j = (j >> 8) | ((block[i - 2]) << 8);
      ftab[j]++;
      quadrant[i - 3] = 0;
      j = (j >> 8) | ((block[i - 3]) << 8);
      ftab[j]++;
    }

    for (; i >= 0; i--) {
      quadrant[i] = 0;
      j = (j >> 8) | ((block[i]) << 8);
      ftab[j]++;
    }

    // (emphasises close relationship of block & quadrant)
    for (i = 0; i < _bzNOvershoot; i++) {
      block[nblock + i] = block[i];
      quadrant[nblock + i] = 0;
    }

    // Complete the initial radix sort
    for (i = 1; i <= 65536; i++) {
      ftab[i] += ftab[i - 1];
    }

    var s = block[0] << 8;
    i = nblock - 1;
    for (; i >= 3; i -= 4) {
      s = (s >> 8) | (block[i] << 8);
      j = ftab[s] - 1;
      ftab[s] = j;
      ptr[j] = i;
      s = (s >> 8) | (block[i - 1] << 8);
      j = ftab[s] - 1;
      ftab[s] = j;
      ptr[j] = i - 1;
      s = (s >> 8) | (block[i - 2] << 8);
      j = ftab[s] - 1;
      ftab[s] = j;
      ptr[j] = i - 2;
      s = (s >> 8) | (block[i - 3] << 8);
      j = ftab[s] - 1;
      ftab[s] = j;
      ptr[j] = i - 3;
    }
    for (; i >= 0; i--) {
      s = (s >> 8) | (block[i] << 8);
      j = ftab[s] - 1;
      ftab[s] = j;
      ptr[j] = i;
    }

    // Now ftab contains the first loc of every small bucket.
    // Calculate the running order, from smallest to largest
    // big bucket.
    for (i = 0; i <= 255; i++) {
      bigDone[i] = 0;
      runningOrder[i] = i;
    }

    var h = 1;
    do {
      h = 3 * h + 1;
    } while (h <= 256);
    do {
      h = h ~/ 3;
      for (i = h; i <= 255; i++) {
        var vv = runningOrder[i];
        j = i;
        while (bigFreq(runningOrder[j - h]) > bigFreq(vv)) {
          runningOrder[j] = runningOrder[j - h];
          j = j - h;
          if (j <= (h - 1)) {
            break;
          }
        }
        runningOrder[j] = vv;
      }
    } while (h != 1);

    // The main sorting loop.

    var numQSorted = 0; // ignore: unused_local_variable

    for (i = 0; i <= 255; i++) {
      // Process big buckets, starting with the least full.
      // Basically this is a 3-step process in which we call
      // mainQSort3 to sort the small buckets [ss, j], but
      // also make a big effort to avoid the calls if we can.
      var ss = runningOrder[i];

      // Step 1:
      // Complete the big bucket [ss] by quicksorting
      // any unsorted small buckets [ss, j], for j != ss.
      // Hopefully previous pointer-scanning phases have already
      // completed many of the small buckets [ss, j], so
      // we don't have to sort them at all.
      for (j = 0; j <= 255; j++) {
        if (j != ss) {
          var sb = (ss << 8) + j;
          if ((_ftab[sb] & setMask) == 0) {
            var lo = _ftab[sb] & clearMask;
            var hi = (_ftab[sb + 1] & clearMask) - 1;
            if (hi > lo) {
              _mainQSort3(ptr, block, quadrant, nblock, lo, hi, _bzNRadix);
              numQSorted += (hi - lo + 1);
              if (_budget < 0) {
                return;
              }
            }
          }
          _ftab[sb] |= setMask;
        }
      }

      _assert(bigDone[ss] == 0);

      // Step 2:
      // Now scan this big bucket [ss] so as to synthesise the
      // sorted order for small buckets [t, ss] for all t,
      // including, magically, the bucket [ss,ss] too.
      // This will avoid doing Real Work in subsequent Step 1's.
      for (j = 0; j <= 255; j++) {
        copyStart[j] = _ftab[(j << 8) + ss] & clearMask;
        copyEnd[j] = (_ftab[(j << 8) + ss + 1] & clearMask) - 1;
      }

      for (j = _ftab[ss << 8] & clearMask; j < copyStart[ss]; j++) {
        var k = ptr[j] - 1;
        if (k < 0) k += nblock;
        var c1 = block[k];
        if (bigDone[c1] == 0) {
          ptr[copyStart[c1]++] = k;
        }
      }

      for (j = (_ftab[(ss + 1) << 8] & clearMask) - 1; j > copyEnd[ss]; j--) {
        var k = ptr[j] - 1;
        if (k < 0) {
          k += nblock;
        }
        var c1 = block[k];
        if (bigDone[c1] == 0) {
          ptr[copyEnd[c1]--] = k;
        }
      }

      _assert((copyStart[ss] - 1 == copyEnd[ss]) ||
          // Extremely rare case missing in bzip2-1.0.0 and 1.0.1.
          // Necessity for this case is demonstrated by compressing
          // a sequence of approximately 48.5 million of character
          // 251; 1.0.0/1.0.1 will then die here.
          (copyStart[ss] == 0 && copyEnd[ss] == nblock - 1));

      for (j = 0; j <= 255; j++) {
        _ftab[(j << 8) + ss] |= setMask;
      }

      // Step 3:
      // The [ss] big bucket is now done.  Record this fact,
      // and update the quadrant descriptors.  Remember to
      // update quadrants in the overshoot area too, if
      // necessary.  The "if (i < 255)" test merely skips
      // this updating for the last bucket processed, since
      // updating for the last bucket is pointless.
      //
      // The quadrant array provides a way to incrementally
      // cache sort orderings, as they appear, so as to
      // make subsequent comparisons in fullGtU() complete
      // faster.  For repetitive blocks this makes a big
      // difference (but not big enough to be able to avoid
      // the fallback sorting mechanism, exponential radix sort).
      //
      // The precise meaning is: at all times:
      //
      //          for 0 <= i < nblock and 0 <= j <= nblock
      //
      //          if block[i] != block[j],
      //
      //             then the relative values of quadrant[i] and
      //                  quadrant[j] are meaningless.
      //
      //             else {
      //                if quadrant[i] < quadrant[j]
      //                   then the string starting at i lexicographically
      //                   precedes the string starting at j
      //
      //                else if quadrant[i] > quadrant[j]
      //                   then the string starting at j lexicographically
      //                   precedes the string starting at i
      //
      //                else
      //                   the relative ordering of the strings starting
      //                   at i and j has not yet been determined.
      //             }
      bigDone[ss] = 1;

      if (i < 255) {
        var bbStart = _ftab[ss << 8] & clearMask;
        var bbSize = (_ftab[(ss + 1) << 8] & clearMask) - bbStart;
        var shifts = 0;

        if (bbSize > 0) {
          while ((bbSize >> shifts) > 65534) {
            shifts++;
          }

          for (j = bbSize - 1; j >= 0; j--) {
            var a2update = ptr[bbStart + j];
            var qVal = (j >> shifts) & 0xffff;
            quadrant[a2update] = qVal;
            if (a2update < _bzNOvershoot) {
              quadrant[a2update + nblock] = qVal;
            }
            _assert(((bbSize - 1) >> shifts) <= 65535);
          }
        }
      }
    }
  }

  void _mainQSort3(Uint32List ptr, Uint8List block, Uint16List quadrant,
      int nblock, int loSt, int hiSt, int dSt) {
    const mainQSortStackSize = 100;
    const mainQSortSmallThreshold = 20;
    const mainQSortDepthThreshold = (_bzNRadix + _bzNQSort);

    final stackLo = Int32List(mainQSortStackSize);
    final stackHi = Int32List(mainQSortStackSize);
    final stackD = Int32List(mainQSortStackSize);

    final nextLo = Int32List(3);
    final nextHi = Int32List(3);
    final nextD = Int32List(3);

    var sp = 0;
    void mpush(int lz, int hz, int dz) {
      stackLo[sp] = lz;
      stackHi[sp] = hz;
      stackD[sp] = dz;
      sp++;
    }

    int mmed3(int a, int b, int c) {
      if (a > b) {
        var t = a;
        a = b;
        b = t;
      }
      if (b > c) {
        b = c;
        if (a > b) {
          b = a;
        }
      }
      return b;
    }

    void mvswap(int yyp1, int yyp2, int yyn) {
      while (yyn > 0) {
        var t = ptr[yyp1];
        ptr[yyp1] = ptr[yyp2];
        ptr[yyp2] = t;
        yyp1++;
        yyp2++;
        yyn--;
      }
    }

    int mmin(int a, int b) => ((a) < (b)) ? (a) : (b);

    int mnextsize(int az) => (nextHi[az] - nextLo[az]);

    void mnextswap(int az, int bz) {
      var tz = nextLo[az];
      nextLo[az] = nextLo[bz];
      nextLo[bz] = tz;
      tz = nextHi[az];
      nextHi[az] = nextHi[bz];
      nextHi[bz] = tz;
      tz = nextD[az];
      nextD[az] = nextD[bz];
      nextD[bz] = tz;
    }

    mpush(loSt, hiSt, dSt);

    while (sp > 0) {
      _assert(sp < mainQSortStackSize - 2);

      sp--;
      var lo = stackLo[sp];
      var hi = stackHi[sp];
      var d = stackD[sp];

      if (hi - lo < mainQSortSmallThreshold || d > mainQSortDepthThreshold) {
        _mainSimpleSort(ptr, block, quadrant, nblock, lo, hi, d);
        if (_budget < 0) {
          return;
        }
        continue;
      }

      var med = mmed3(block[ptr[lo] + d], block[ptr[hi] + d],
          block[ptr[(lo + hi) >> 1] + d]);

      var unLo = lo;
      var ltLo = lo;
      var unHi = hi;
      var gtHi = hi;

      while (true) {
        while (true) {
          if (unLo > unHi) {
            break;
          }

          var n = (block[ptr[unLo] + d]) - med;
          if (n == 0) {
            var t = ptr[unLo];
            ptr[unLo] = ptr[ltLo];
            ptr[ltLo] = t;
            ltLo++;
            unLo++;
            continue;
          }
          if (n > 0) {
            break;
          }
          unLo++;
        }
        while (true) {
          if (unLo > unHi) {
            break;
          }

          var n = (block[ptr[unHi] + d]) - med;
          if (n == 0) {
            var t = ptr[unHi];
            ptr[unHi] = ptr[gtHi];
            ptr[gtHi] = t;
            gtHi--;
            unHi--;
            continue;
          }
          if (n < 0) {
            break;
          }
          unHi--;
        }
        if (unLo > unHi) {
          break;
        }

        var t = ptr[unLo];
        ptr[unLo] = ptr[unHi];
        ptr[unHi] = t;
        unLo++;
        unHi--;
      }

      _assert(unHi == unLo - 1);

      if (gtHi < ltLo) {
        mpush(lo, hi, d + 1);
        continue;
      }

      var n = mmin(ltLo - lo, unLo - ltLo);
      mvswap(lo, unLo - n, n);
      var m = mmin(hi - gtHi, gtHi - unHi);
      mvswap(unLo, hi - m + 1, m);

      n = lo + unLo - ltLo - 1;
      m = hi - (gtHi - unHi) + 1;

      nextLo[0] = lo;
      nextHi[0] = n;
      nextD[0] = d;
      nextLo[1] = m;
      nextHi[1] = hi;
      nextD[1] = d;
      nextLo[2] = n + 1;
      nextHi[2] = m - 1;
      nextD[2] = d + 1;

      if (mnextsize(0) < mnextsize(1)) {
        mnextswap(0, 1);
      }
      if (mnextsize(1) < mnextsize(2)) {
        mnextswap(1, 2);
      }
      if (mnextsize(0) < mnextsize(1)) {
        mnextswap(0, 1);
      }

      _assert(mnextsize(0) >= mnextsize(1));
      _assert(mnextsize(1) >= mnextsize(2));

      mpush(nextLo[0], nextHi[0], nextD[0]);
      mpush(nextLo[1], nextHi[1], nextD[1]);
      mpush(nextLo[2], nextHi[2], nextD[2]);
    }
  }

  void _mainSimpleSort(Uint32List ptr, Uint8List block, Uint16List quadrant,
      int nblock, int lo, int hi, int d) {
    var bigN = hi - lo + 1;
    if (bigN < 2) {
      return;
    }

    const incs = [
      1,
      4,
      13,
      40,
      121,
      364,
      1093,
      3280,
      9841,
      29524,
      88573,
      265720,
      797161,
      2391484
    ];

    var hp = 0;
    while (incs[hp] < bigN) {
      hp++;
    }
    hp--;

    for (; hp >= 0; hp--) {
      var h = incs[hp];

      var i = lo + h;
      while (true) {
        // copy 1
        if (i > hi) {
          break;
        }
        var v = ptr[i];
        var j = i;
        while (_mainGtU(ptr[j - h] + d, v + d, block, quadrant, nblock)) {
          ptr[j] = ptr[j - h];
          j = j - h;
          if (j <= (lo + h - 1)) {
            break;
          }
        }
        ptr[j] = v;
        i++;

        // copy 2
        if (i > hi) {
          break;
        }
        v = ptr[i];
        j = i;
        while (_mainGtU(ptr[j - h] + d, v + d, block, quadrant, nblock)) {
          ptr[j] = ptr[j - h];
          j = j - h;
          if (j <= (lo + h - 1)) {
            break;
          }
        }
        ptr[j] = v;
        i++;

        // copy 3
        if (i > hi) {
          break;
        }
        v = ptr[i];
        j = i;
        while (_mainGtU(ptr[j - h] + d, v + d, block, quadrant, nblock)) {
          ptr[j] = ptr[j - h];
          j = j - h;
          if (j <= (lo + h - 1)) {
            break;
          }
        }
        ptr[j] = v;
        i++;

        if (_budget < 0) {
          return;
        }
      }
    }
  }

  bool _mainGtU(
      int i1, int i2, Uint8List block, Uint16List quadrant, int nblock) {
    _assert(i1 != i2);
    // 1
    var c1 = block[i1];
    var c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 2
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 3
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 4
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 5
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 6
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 7
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 8
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 9
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 10
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 11
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;
    // 12
    c1 = block[i1];
    c2 = block[i2];
    if (c1 != c2) {
      return (c1 > c2);
    }
    i1++;
    i2++;

    var k = nblock + 8;

    do {
      // 1
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      var s1 = quadrant[i1];
      var s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 2
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 3
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 4
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 5
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 6
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 7
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;
      // 8
      c1 = block[i1];
      c2 = block[i2];
      if (c1 != c2) {
        return (c1 > c2);
      }
      s1 = quadrant[i1];
      s2 = quadrant[i2];
      if (s1 != s2) {
        return (s1 > s2);
      }
      i1++;
      i2++;

      if (i1 >= nblock) {
        i1 -= nblock;
      }
      if (i2 >= nblock) {
        i2 -= nblock;
      }

      k -= 8;
      _budget--;
    } while (k >= 0);

    return false;
  }

  void _addCharToBlock(int b) {
    if (b != _stateInCh && _stateInLen == 1) {
      _blockCRC = BZip2.updateCrc(_stateInCh, _blockCRC);
      _inUse[_stateInCh] = 1;
      _block[_nblock] = _stateInCh;
      _nblock++;
      _stateInCh = b;
    } else {
      if (b != _stateInCh || _stateInLen == 255) {
        if (_stateInCh < 256) {
          _addPairToBlock();
        }
        _stateInCh = b;
        _stateInLen = 1;
      } else {
        _stateInLen++;
      }
    }
  }

  void _addPairToBlock() {
    for (var i = 0; i < _stateInLen; i++) {
      _blockCRC = BZip2.updateCrc(_stateInCh, _blockCRC);
    }
    _inUse[_stateInCh] = 1;
    switch (_stateInLen) {
      case 1:
        _block[_nblock] = _stateInCh;
        _nblock++;
        break;
      case 2:
        _block[_nblock] = _stateInCh;
        _nblock++;
        _block[_nblock] = _stateInCh;
        _nblock++;
        break;
      case 3:
        _block[_nblock] = _stateInCh;
        _nblock++;
        _block[_nblock] = _stateInCh;
        _nblock++;
        _block[_nblock] = _stateInCh;
        _nblock++;
        break;
      default:
        _inUse[_stateInLen - 4] = 1;
        _block[_nblock] = _stateInCh;
        _nblock++;
        _block[_nblock] = _stateInCh;
        _nblock++;
        _block[_nblock] = _stateInCh;
        _nblock++;
        _block[_nblock] = _stateInCh;
        _nblock++;
        _block[_nblock] = _stateInLen - 4;
        _nblock++;
        break;
    }
  }

  late InputStream input;
  late Bz2BitWriter bw;
  late int _nblockMax;
  late int _stateInCh;
  late int _stateInLen;
  late int _nblock;
  late int _blockCRC;
  late int _blockNo; // ignore: unused_field
  late int _workFactor;
  late int _budget;
  late int _origPtr;

  late Uint32List _arr1;
  late Uint32List _arr2;
  late Uint32List _ftab;
  late Uint8List _block;
  late Uint8List _inUse;
  late Uint16List _mtfv;
  late int _nInUse;

  late int _nMTF;
  late Int32List _mtfFreq;
  late Uint8List _unseqToSeq;
  late List<Uint8List> _len;
  late List<Int32List> _code;
  late List<Int32List> _rfreq;
  late List<Uint32List> _lenPack;
  late Uint8List _selector;
  late Uint8List _selectorMtf;

  static const int _bzNRadix = 2;
  static const int _bzNQSort = 12;
  static const int _bzNShell = 18;
  static const int _bzNOvershoot = (_bzNRadix + _bzNQSort + _bzNShell + 2);
  static const int _bzMaxAlphaSize = 258;
  static const int _bzRunA = 0;
  static const int _bzRunB = 1;
  static const int _bzNGroups = 6;
  static const int _bzGSize = 50;
  static const int _bzNIters = 4;
  static const int _bzLesserICost = 0;
  static const int _bzGreaterICost = 15;
  static const int _bzMaxSelectors = (2 + (900000 ~/ _bzGSize));
}
