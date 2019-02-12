// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Binary diff algorithm based on bsdiff 4.3 (http://www.daemonology.net/bsdiff/).
// It shrinks differential VM snapshots more than 10 times better than plain zip.
//
// Example for flutter_gallery AOT with a single data change and a single code change:
// - isolate_snapshot_data: original 5.4MB, zip 1.9MB (3x), bsdiff+zip 106kB (50x)
// - isolate_snapshot_instr: original 6.7MB, zip 1.3MB (5x), bsdiff+zip 600B (9800x)
//
// Example for flutter_gallery JIT with a single data change and a single code change:
// - isolate_snapshot_data: original 14.1MB, zip 5.8MB (2x), bsdiff+zip 500kB (28x)
//
// This implementation has the following differences from the original algorithm,
// to make it easier to read and apply patches in Java and Objective C:
//
// - Using gzip instead of bzip2 since gzip is included in JDK by default
// - Using big- instead of little-endian serialization to simplify Java code
// - Using two's complement instead of high-bit for negatives to simplify code
//
// The original code's license and copyright is already included in Flutter engine:
//
// Copyright 2003-2005 Colin Percival. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted providing that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
// IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

import 'dart:math';
import 'dart:typed_data';

import '../convert.dart';
import 'io.dart';

void _split(List<int> idata, List<int> vdata, int start, int len, int h) {
  if (len < 16) {
    for (int j, k = start; k < start + len; k += j) {
      j = 1;
      int x = vdata[idata[k] + h];
      for (int i = 1; k + i < start + len; i++) {
        if (vdata[idata[k + i] + h] < x) {
          x = vdata[idata[k + i] + h];
          j = 0;
        }
        if (vdata[idata[k + i] + h] == x) {
          final int tmp = idata[k + j];
          idata[k + j] = idata[k + i];
          idata[k + i] = tmp;
          j++;
        }
      }
      for (int i = 0; i < j; i++) {
        vdata[idata[k + i]] = k + j - 1;
      }
      if (j == 1) {
        idata[k] = -1;
      }
    }
    return;
  }

  final int x = vdata[idata[start + len ~/ 2] + h];
  int jj = 0;
  int kk = 0;
  for (int i = start; i < start + len; i++) {
    if (vdata[idata[i] + h] < x) {
      jj++;
    }
    if (vdata[idata[i] + h] == x) {
      kk++;
    }
  }
  jj += start;
  kk += jj;

  int i = start;
  int j = 0;
  int k = 0;
  while (i < jj) {
    if (vdata[idata[i] + h] < x) {
      i++;
    } else if (vdata[idata[i] + h] == x) {
      final int tmp = idata[i];
      idata[i] = idata[jj + j];
      idata[jj + j] = tmp;
      j++;
    } else {
      final int tmp = idata[i];
      idata[i] = idata[kk + k];
      idata[kk + k] = tmp;
      k++;
    }
  }

  while (jj + j < kk) {
    if (vdata[idata[jj + j] + h] == x) {
      j++;
    } else {
      final int tmp = idata[jj + j];
      idata[jj + j] = idata[kk + k];
      idata[kk + k] = tmp;
      k++;
    }
  }

  if (jj > start) {
    _split(idata, vdata, start, jj - start, h);
  }

  for (i = 0; i < kk - jj; i++) {
    vdata[idata[jj + i]] = kk - 1;
  }
  if (jj == kk - 1) {
    idata[jj] = -1;
  }

  if (start + len > kk) {
    _split(idata, vdata, kk, start + len - kk, h);
  }
}

void _qsufsort(List<int> idata, List<int> vdata, Uint8List olddata) {
  final int oldsize = olddata.length;
  final List<int> buckets = List<int>(256);

  for (int i = 0; i < 256; i++) {
    buckets[i] = 0;
  }
  for (int i = 0; i < oldsize; i++) {
    buckets[olddata[i]]++;
  }
  for (int i = 1; i < 256; i++) {
    buckets[i] += buckets[i - 1];
  }

  for (int i = 255; i > 0; i--) {
    buckets[i] = buckets[i - 1];
  }
  buckets[0] = 0;

  for (int i = 0; i < oldsize; i++) {
    idata[++buckets[olddata[i]]] = i;
  }
  idata[0] = oldsize;

  for (int i = 0; i < oldsize; i++) {
    vdata[i] = buckets[olddata[i]];
  }
  vdata[oldsize] = 0;

  for (int i = 1; i < 256; i++) {
    if (buckets[i] == buckets[i - 1] + 1) {
      idata[buckets[i]] = -1;
    }
  }
  idata[0] = -1;

  for (int h = 1; idata[0] != -(oldsize + 1); h += h) {
    int len = 0;
    int i;
    for (i = 0; i < oldsize + 1;) {
      if (idata[i] < 0) {
        len -= idata[i];
        i -= idata[i];
      } else {
        if (len != 0) {
          idata[i - len] = -len;
        }
        len = vdata[idata[i]] + 1 - i;
        _split(idata, vdata, i, len, h);
        i += len;
        len = 0;
      }
    }
    if (len != 0) {
      idata[i - len] = -len;
    }
  }

  for (int i = 0; i < oldsize + 1; i++) {
    idata[vdata[i]] = i;
  }
}

int _matchlen(Uint8List olddata, int oldskip, Uint8List newdata, int newskip) {
  final int n = min(olddata.length - oldskip, newdata.length - newskip);
  for (int i = 0; i < n; i++) {
    if (olddata[oldskip + i] != newdata[newskip + i]) {
      return i;
    }
  }
  return n;
}

int _memcmp(Uint8List data1, int skip1, Uint8List data2, int skip2) {
  final int n = min(data1.length - skip1, data2.length - skip2);
  for (int i = 0; i < n; i++) {
    if (data1[i + skip1] != data2[i + skip2]) {
      return data1[i + skip1] < data2[i + skip2] ? -1 : 1;
    }
  }
  return 0;
}

class _Ref<T> {
  T value;
}

int _search(List<int> idata, Uint8List olddata, Uint8List newdata, int newskip,
    int start, int end, _Ref<int> pos) {

  if (end - start < 2) {
    final int x = _matchlen(olddata, idata[start], newdata, newskip);
    final int y = _matchlen(olddata, idata[end], newdata, newskip);

    if (x > y) {
      pos.value = idata[start];
      return x;
    } else {
      pos.value = idata[end];
      return y;
    }
  }

  final int x = start + (end - start) ~/ 2;
  if (_memcmp(olddata, idata[x], newdata, newskip) < 0) {
    return _search(idata, olddata, newdata, newskip, x, end, pos);
  } else {
    return _search(idata, olddata, newdata, newskip, start, x, pos);
  }
}

List<int> _int64bytes(int i) => (ByteData(8)..setInt64(0, i)).buffer.asUint8List();

Uint8List bsdiff(List<int> olddata, List<int> newdata) {
  final int oldsize = olddata.length;
  final int newsize = newdata.length;

  final List<int> idata = List<int>(oldsize + 1);
  _qsufsort(idata, List<int>(oldsize + 1), olddata);

  final Uint8List db = Uint8List(newsize + 1);
  final Uint8List eb = Uint8List(newsize + 1);

  int dblen = 0;
  int eblen = 0;

  BytesBuilder buf = BytesBuilder();
  final _Ref<int> pos = _Ref<int>();

  for (int scan = 0, len = 0, lastscan = 0, lastpos = 0, lastoffset = 0; scan < newsize; ) {
    int oldscore = 0;

    for (int scsc = scan += len; scan < newsize; scan++) {
      len = _search(idata, olddata, newdata, scan, 0, oldsize, pos);

      for (; scsc < scan + len; scsc++) {
        if ((scsc + lastoffset < oldsize) && (olddata[scsc + lastoffset] == newdata[scsc])) {
          oldscore++;
        }
      }
      if (((len == oldscore) && (len != 0)) || (len > oldscore + 8)) {
        break;
      }
      if ((scan + lastoffset < oldsize) && (olddata[scan + lastoffset] == newdata[scan])) {
        oldscore--;
      }
    }

    if ((len != oldscore) || (scan == newsize)) {
      int lenf = 0;
      int lenb = 0;

      for (int sf = 0, s = 0, i = 0; (lastscan + i < scan) && (lastpos + i < oldsize); ) {
        if (olddata[lastpos + i] == newdata[lastscan + i]) {
          s++;
        }
        i++;
        if (s * 2 - i > sf * 2 - lenf) {
          sf = s;
          lenf = i;
        }
      }

      if (scan < newsize) {
        for (int sb = 0, s = 0, i = 1; (scan >= lastscan + i) && (pos.value >= i); i++) {
          if (olddata[pos.value - i] == newdata[scan - i]) {
            s++;
          }
          if (s * 2 - i > sb * 2 - lenb) {
            sb = s;
            lenb = i;
          }
        }
      }

      if (lastscan + lenf > scan - lenb) {
        final int overlap = (lastscan + lenf) - (scan - lenb);
        int lens = 0;
        for (int ss = 0, s = 0, i = 0; i < overlap; i++) {
          if (newdata[lastscan + lenf - overlap + i] == olddata[lastpos + lenf - overlap + i]) {
            s++;
          }
          if (newdata[scan - lenb + i] == olddata[pos.value - lenb + i]) {
            s--;
          }
          if (s > ss) {
            ss = s;
            lens = i + 1;
          }
        }

        lenf += lens - overlap;
        lenb -= lens;
      }

      for (int i = 0; i < lenf; i++) {
        db[dblen + i] = newdata[lastscan + i] - olddata[lastpos + i];
      }

      for (int i = 0; i < (scan - lenb) - (lastscan + lenf); i++) {
        eb[eblen + i] = newdata[lastscan + lenf + i];
      }

      dblen += lenf;
      eblen += (scan - lenb) - (lastscan + lenf);

      buf.add(_int64bytes(lenf));
      buf.add(_int64bytes((scan - lenb) - (lastscan + lenf)));
      buf.add(_int64bytes((pos.value - lenb) - (lastpos + lenf)));

      lastscan = scan - lenb;
      lastpos = pos.value - lenb;
      lastoffset = pos.value - scan;
    }
  }

  final BytesBuilder out = BytesBuilder();

  out.add(const AsciiCodec().encode('BZDIFF40').toList());
  out.add(_int64bytes(0));
  out.add(_int64bytes(0));
  out.add(_int64bytes(newsize));

  out.add(gzip.encoder.convert(buf.takeBytes()));

  final int len1 = out.length;

  buf = BytesBuilder();
  buf.add(db.sublist(0, dblen));
  out.add(gzip.encoder.convert(buf.takeBytes()));

  final int len2 = out.length;

  buf = BytesBuilder();
  buf.add(eb.sublist(0, eblen));
  out.add(gzip.encoder.convert(buf.takeBytes()));

  final Uint8List bytes = Uint8List.fromList(out.takeBytes());
  final ByteData data = ByteData.view(bytes.buffer);
  data.setUint64(8, len1 - 32);
  data.setUint64(16, len2 - len1);

  return bytes;
}

Uint8List bspatch(List<int> olddata, List<int> diffdata) {
  final List<int> magic = diffdata.sublist(0, 8);
  if (const AsciiCodec().decode(magic) != 'BZDIFF40') {
    throw Exception('Invalid magic');
  }

  final ByteData header = ByteData.view(Uint8List.fromList(diffdata.sublist(0, 32)).buffer);

  final int ctrllen = header.getInt64(8);
  final int datalen = header.getInt64(16);
  final int newsize = header.getInt64(24);

  final List<int> cpf = gzip.decoder.convert(diffdata.sublist(32, 32+ctrllen));
  final List<int> dpf = gzip.decoder.convert(diffdata.sublist(32+ctrllen, 32+ctrllen+datalen));
  final List<int> epf = gzip.decoder.convert(diffdata.sublist(32+ctrllen+datalen, diffdata.length));

  final ByteData cpfdata = ByteData.view(Uint8List.fromList(cpf).buffer);

  final Uint8List newdata = Uint8List(newsize);

  int cpfpos = 0;
  int dpfpos = 0;
  int epfpos = 0;
  int oldpos = 0;
  int newpos = 0;

  while (newpos < newsize) {
    final List<int> ctrl = List<int>(3);
    for (int i = 0; i <= 2; i++) {
      ctrl[i] = cpfdata.getInt64(8 * cpfpos++);
    }
    if (newpos + ctrl[0] > newsize) {
      throw Exception('Invalid ctrl[0]');
    }

    newdata.setRange(newpos, newpos + ctrl[0], dpf, dpfpos);

    for (int i = 0; i < ctrl[0]; i++) {
      if ((oldpos + i >= 0) && (oldpos + i < olddata.length)) {
        newdata[newpos + i] += olddata[oldpos + i];
      }
    }

    dpfpos += ctrl[0];
    newpos += ctrl[0];
    oldpos += ctrl[0];

    if (newpos + ctrl[1] > newsize) {
      throw Exception('Invalid ctrl[0]');
    }

    newdata.setRange(newpos, newpos + ctrl[1], epf, epfpos);

    epfpos += ctrl[1];
    newpos += ctrl[1];
    oldpos += ctrl[2];
  }

  return newdata;
}
