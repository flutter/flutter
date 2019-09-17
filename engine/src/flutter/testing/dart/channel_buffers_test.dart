import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';

import 'package:test/test.dart';

void main() {

  ByteData _makeByteData(String str) {
    var list = utf8.encode(str);
    var buffer = list is Uint8List ? list.buffer : new Uint8List.fromList(list).buffer;
    return ByteData.view(buffer);
  }

  String _getString(ByteData data) {
    final buffer = data.buffer;
    var list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return utf8.decode(list);
  }

  test('push drain', () async {
    String channel = "foo";
    ByteData data = _makeByteData('bar');
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    buffers.push(channel, data, callback);
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      expect(drainedData, equals(data));
      expect(drainedCallback, equals(callback));
    });
  });

  test('push drain zero', () async {
    String channel = "foo";
    ByteData data = _makeByteData('bar');
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    buffers.resize(channel, 0);
    buffers.push(channel, data, callback);
    bool didCall = false;
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      didCall = true;
    });
    expect(didCall, equals(false));
  });

  test('empty', () async {
    String channel = "foo";
    ByteData data = _makeByteData('bar');
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    bool didCall = false;
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      didCall = true;
    });
    expect(didCall, equals(false));
  });

  test('overflow', () async {
    String channel = "foo";
    ByteData one = _makeByteData('one');
    ByteData two = _makeByteData('two');
    ByteData three = _makeByteData('three');
    ByteData four = _makeByteData('four');
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    buffers.resize(channel, 3);
    expect(buffers.push(channel, one, callback), equals(false));
    expect(buffers.push(channel, two, callback), equals(false));
    expect(buffers.push(channel, three, callback), equals(false));
    expect(buffers.push(channel, four, callback), equals(true));
    int counter = 0;
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      if (counter++ == 0) {
        expect(drainedData, equals(two));
        expect(drainedCallback, equals(callback));
      }
    });
    expect(counter, equals(3));
  });

  test('resize drop', () async {
    String channel = "foo";
    ByteData one = _makeByteData('one');
    ByteData two = _makeByteData('two');
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    buffers.resize(channel, 100);
    ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    expect(buffers.push(channel, one, callback), equals(false));
    expect(buffers.push(channel, two, callback), equals(false));
    buffers.resize(channel, 1);
    int counter = 0;
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      if (counter++ == 0) {
        expect(drainedData, equals(two));
        expect(drainedCallback, equals(callback));
      }
    });
    expect(counter, equals(1));
  });

  test('resize dropping calls callback', () async {
    String channel = "foo";
    ByteData one = _makeByteData('one');
    ByteData two = _makeByteData('two');
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    bool didCallCallback = false;
    ui.PlatformMessageResponseCallback oneCallback = (ByteData responseData) {
      didCallCallback = true;
    };
    ui.PlatformMessageResponseCallback twoCallback = (ByteData responseData) {};
    buffers.resize(channel, 100);
    expect(buffers.push(channel, one, oneCallback), equals(false));
    expect(buffers.push(channel, two, twoCallback), equals(false));
    buffers.resize(channel, 1);
    expect(didCallCallback, equals(true));
  });

  test('overflow calls callback', () async {
    String channel = "foo";
    ByteData one = _makeByteData('one');
    ByteData two = _makeByteData('two');
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    bool didCallCallback = false;
    ui.PlatformMessageResponseCallback oneCallback = (ByteData responseData) {
      didCallCallback = true;
    };
    ui.PlatformMessageResponseCallback twoCallback = (ByteData responseData) {};
    buffers.resize(channel, 1);
    expect(buffers.push(channel, one, oneCallback), equals(false));
    expect(buffers.push(channel, two, twoCallback), equals(true));
    expect(didCallCallback, equals(true));
  });
}
