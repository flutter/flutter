// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Produces a two second sine wave using the Windows Audio Session API
// interface.

import 'dart:ffi';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const refTimesPerSecond = 5000000;
const refTimesPerMillisecond = refTimesPerSecond / 1000;
const frequency = 440; // 440Hz (concert pitch)
const sampleCount = 96000 * 2;

late Float32List pcmAudio;

int bufferSize = 0;
int pcmPos = 0;
int bufferPos = 0;

/// Initialize data values.
void initData(WAVEFORMATEX waveFormat, int totalFrames) {
  final sampleRate = waveFormat.nSamplesPerSec.toDouble();
  pcmAudio = Float32List(sampleCount);
  final radsPerSec = 2 * math.pi * frequency / sampleRate;
  for (var i = 0; i < sampleCount; i++) {
    final sampleValue = math.sin(radsPerSec * i);
    pcmAudio[i] = sampleValue;
  }
  bufferSize = totalFrames * waveFormat.nChannels;
  print("bufferSize = $bufferSize");
  print("sampsPerChan = ${totalFrames / waveFormat.nChannels}");
}

/// Loads data into the memory buffer.
///
/// Returns true if there is data, else returns false (indicating silence).
bool fillMemoryBuffer(
    int totalFrames, Pointer<BYTE> dataOut, WAVEFORMATEX waveFormat) {
  final fData = dataOut.cast<FLOAT>();
  final totalSamples = totalFrames * waveFormat.nChannels;
  print("Frames to Fill = $totalFrames");
  print("Samples to Fill = $totalSamples");
  print("bufferPos = $bufferPos");

  if (pcmPos < sampleCount) {
    for (var i = 0; i < totalSamples; i += waveFormat.nChannels) {
      for (var chan = 0; chan < waveFormat.nChannels; chan++) {
        fData[i + chan] = (pcmPos < sampleCount) ? pcmAudio[pcmPos] : 0.0;
      }
      pcmPos++;
    }
    bufferPos += totalSamples;
    bufferPos %= bufferSize;
  } else {
    // no more data
    return false;
  }
  return true;
}

/// Retrieve the number of frames that the audio buffer can hold.
int getBufferFrameCount(IAudioClient pAudioClient) {
  final pBufferFrameCount = calloc<UINT32>();
  check(pAudioClient.getBufferSize(pBufferFrameCount));
  final bufferFrameCount = pBufferFrameCount.value;
  free(pBufferFrameCount);

  return bufferFrameCount;
}

/// Fail COM calls that don't complete successfully.
void check(int hr) {
  if (FAILED(hr)) throw WindowsException(hr);
}

void main() {
  // Initialize COM
  check(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED));

  // Retrieve the default audio output device.
  final pDeviceEnumerator = MMDeviceEnumerator.createInstance();
  final ppDevice = calloc<Pointer<COMObject>>();
  check(pDeviceEnumerator.getDefaultAudioEndpoint(
      0, // dataflow: rendering device
      0, // role: system notification sound
      ppDevice));
  pDeviceEnumerator.release();
  free(pDeviceEnumerator.ptr);

  // Activate an IAudioClient interface for the output device.
  final pDevice = IMMDevice(ppDevice.cast());
  final iidAudioClient = convertToIID(IID_IAudioClient);
  final ppAudioClient = calloc<Pointer<COMObject>>();
  check(pDevice.activate(iidAudioClient, CLSCTX_ALL, nullptr, ppAudioClient));
  free(iidAudioClient);
  final pAudioClient = IAudioClient(ppAudioClient.cast());

  // Initialize the audio stream.
  final ppFormat = calloc<Pointer<WAVEFORMATEX>>();
  check(pAudioClient.getMixFormat(ppFormat));
  final pWaveFormat = ppFormat.value;
  final sampleRate = pWaveFormat.ref.nSamplesPerSec;
  check(pAudioClient.initialize(
      AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_SHARED,
      0,
      30000, // buffer capacity of 3s (30,000 * 100ns)
      0,
      ppFormat.value,
      nullptr));

  // Activate an IAudioRenderClient interface.
  final iidAudioRenderClient = convertToIID(IID_IAudioRenderClient);
  final ppAudioRenderClient = calloc<Pointer<COMObject>>();
  check(pAudioClient.getService(iidAudioRenderClient, ppAudioRenderClient));
  free(iidAudioRenderClient);
  final pAudioRenderClient = IAudioRenderClient(ppAudioRenderClient.cast());

  // Grab the entire buffer for the initial fill operation.
  final bufferFrameCount = getBufferFrameCount(pAudioClient);
  print("Buffer Size = $bufferFrameCount frames");
  final pData = calloc<Pointer<BYTE>>();
  check(pAudioRenderClient.getBuffer(bufferFrameCount, pData));

  // Load the initial data into the shared buffer.
  initData(pWaveFormat.ref, bufferFrameCount);
  var dataLoaded =
      fillMemoryBuffer(bufferFrameCount, pData.value, pWaveFormat.ref);
  check(pAudioRenderClient.releaseBuffer(bufferFrameCount,
      dataLoaded ? 0 : AUDCLNT_BUFFERFLAGS.AUDCLNT_BUFFERFLAGS_SILENT));

  // Calculate the actual duration of the allocated buffer.
  final hnsActualDuration = refTimesPerSecond * bufferFrameCount / sampleRate;

  check(pAudioClient.start()); // Start playing.

  final pNumFramesPadding = calloc<UINT32>();
  while (dataLoaded) {
    // Sleep for half the buffer duration.
    Sleep(hnsActualDuration / refTimesPerMillisecond ~/ 2);
    // See how much buffer space is available.
    check(pAudioClient.getCurrentPadding(pNumFramesPadding));
    final numFramesAvailable = bufferFrameCount - pNumFramesPadding.value;
    // Grab all the available space in the shared buffer.
    check(pAudioRenderClient.getBuffer(numFramesAvailable, pData));
    // Get next half second of data from the audio source.
    dataLoaded =
        fillMemoryBuffer(numFramesAvailable, pData.value, pWaveFormat.ref);
    check(pAudioRenderClient.releaseBuffer(numFramesAvailable,
        dataLoaded ? 0 : AUDCLNT_BUFFERFLAGS.AUDCLNT_BUFFERFLAGS_SILENT));
  }
  free(pNumFramesPadding);

  // Wait for last data in buffer to play before stopping.
  Sleep(hnsActualDuration / refTimesPerMillisecond ~/ 2);
  check(pAudioClient.stop()); // Stop playing.

  // Clear up
  free(pData);

  pDevice.release();
  free(ppDevice);

  pAudioClient.release();
  free(ppAudioClient);

  pAudioRenderClient.release();
  free(ppAudioRenderClient);

  free(ppFormat);

  // Uninitialize COM now that we're done with it.
  CoUninitialize();
  print('All done!');
}
