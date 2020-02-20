// @dart = 2.6
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:test/test.dart';

void main() {

  ByteData _makeByteData(String str) {
    final Uint8List list = utf8.encode(str) as Uint8List;
    final ByteBuffer buffer = list is Uint8List ? list.buffer : Uint8List.fromList(list).buffer;
    return ByteData.view(buffer);
  }

  void _resize(ui.ChannelBuffers buffers, String name, int newSize) {
    buffers.handleMessage(_makeByteData('resize\r$name\r$newSize'));
  }

  test('push drain', () async {
    const String channel = 'foo';
    final ByteData data = _makeByteData('bar');
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    final ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    buffers.push(channel, data, callback);
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      expect(drainedData, equals(data));
      expect(drainedCallback, equals(callback));
      return;
    });
  });

  test('push drain zero', () async {
    const String channel = 'foo';
    final ByteData data = _makeByteData('bar');
    final
    ui.ChannelBuffers buffers = ui.ChannelBuffers();
    final ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    _resize(buffers, channel, 0);
    buffers.push(channel, data, callback);
    bool didCall = false;
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      didCall = true;
      return;
    });
    expect(didCall, equals(false));
  });

  test('empty', () async {
    const String channel = 'foo';
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    bool didCall = false;
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      didCall = true;
      return;
    });
    expect(didCall, equals(false));
  });

  test('overflow', () async {
    const String channel = 'foo';
    final ByteData one = _makeByteData('one');
    final ByteData two = _makeByteData('two');
    final ByteData three = _makeByteData('three');
    final ByteData four = _makeByteData('four');
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    final ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    _resize(buffers, channel, 3);
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
      return;
    });
    expect(counter, equals(3));
  });

  test('resize drop', () async {
    const String channel = 'foo';
    final ByteData one = _makeByteData('one');
    final ByteData two = _makeByteData('two');
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    _resize(buffers, channel, 100);
    final ui.PlatformMessageResponseCallback callback = (ByteData responseData) {};
    expect(buffers.push(channel, one, callback), equals(false));
    expect(buffers.push(channel, two, callback), equals(false));
    _resize(buffers, channel, 1);
    int counter = 0;
    await buffers.drain(channel, (ByteData drainedData, ui.PlatformMessageResponseCallback drainedCallback) {
      if (counter++ == 0) {
        expect(drainedData, equals(two));
        expect(drainedCallback, equals(callback));
      }
      return;
    });
    expect(counter, equals(1));
  });

  test('resize dropping calls callback', () async {
    const String channel = 'foo';
    final ByteData one = _makeByteData('one');
    final ByteData two = _makeByteData('two');
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    bool didCallCallback = false;
    final ui.PlatformMessageResponseCallback oneCallback = (ByteData responseData) {
      didCallCallback = true;
    };
    final ui.PlatformMessageResponseCallback twoCallback = (ByteData responseData) {};
    _resize(buffers, channel, 100);
    expect(buffers.push(channel, one, oneCallback), equals(false));
    expect(buffers.push(channel, two, twoCallback), equals(false));
    _resize(buffers, channel, 1);
    expect(didCallCallback, equals(true));
  });

  test('overflow calls callback', () async {
    const String channel = 'foo';
    final ByteData one = _makeByteData('one');
    final ByteData two = _makeByteData('two');
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    bool didCallCallback = false;
    final ui.PlatformMessageResponseCallback oneCallback = (ByteData responseData) {
      didCallCallback = true;
    };
    final ui.PlatformMessageResponseCallback twoCallback = (ByteData responseData) {};
    _resize(buffers, channel, 1);
    expect(buffers.push(channel, one, oneCallback), equals(false));
    expect(buffers.push(channel, two, twoCallback), equals(true));
    expect(didCallCallback, equals(true));
  });

  test('handle garbage', () async {
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    expect(() => buffers.handleMessage(_makeByteData('asdfasdf')),
           throwsException);
  });

  test('handle resize garbage', () async {
    final ui.ChannelBuffers buffers = ui.ChannelBuffers();
    expect(() => buffers.handleMessage(_makeByteData('resize\rfoo\rbar')),
           throwsException);
  });
}
