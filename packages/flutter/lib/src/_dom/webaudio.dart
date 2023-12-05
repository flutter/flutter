// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'hr_time.dart';
import 'html.dart';
import 'mediacapture_streams.dart';

typedef DecodeErrorCallback = JSFunction;
typedef DecodeSuccessCallback = JSFunction;
typedef AudioWorkletProcessorConstructor = JSFunction;
typedef AudioWorkletProcessCallback = JSFunction;
typedef AudioContextState = String;
typedef AudioContextRenderSizeCategory = String;
typedef AudioContextLatencyCategory = String;
typedef AudioSinkType = String;
typedef ChannelCountMode = String;
typedef ChannelInterpretation = String;
typedef AutomationRate = String;
typedef BiquadFilterType = String;
typedef OscillatorType = String;
typedef PanningModelType = String;
typedef DistanceModelType = String;
typedef OverSampleType = String;

@JS('BaseAudioContext')
@staticInterop
class BaseAudioContext implements EventTarget {}

extension BaseAudioContextExtension on BaseAudioContext {
  external AnalyserNode createAnalyser();
  external BiquadFilterNode createBiquadFilter();
  external AudioBuffer createBuffer(
    int numberOfChannels,
    int length,
    num sampleRate,
  );
  external AudioBufferSourceNode createBufferSource();
  external ChannelMergerNode createChannelMerger([int numberOfInputs]);
  external ChannelSplitterNode createChannelSplitter([int numberOfOutputs]);
  external ConstantSourceNode createConstantSource();
  external ConvolverNode createConvolver();
  external DelayNode createDelay([num maxDelayTime]);
  external DynamicsCompressorNode createDynamicsCompressor();
  external GainNode createGain();
  external IIRFilterNode createIIRFilter(
    JSArray feedforward,
    JSArray feedback,
  );
  external OscillatorNode createOscillator();
  external PannerNode createPanner();
  external PeriodicWave createPeriodicWave(
    JSArray real,
    JSArray imag, [
    PeriodicWaveConstraints constraints,
  ]);
  external ScriptProcessorNode createScriptProcessor([
    int bufferSize,
    int numberOfInputChannels,
    int numberOfOutputChannels,
  ]);
  external StereoPannerNode createStereoPanner();
  external WaveShaperNode createWaveShaper();
  external JSPromise decodeAudioData(
    JSArrayBuffer audioData, [
    DecodeSuccessCallback? successCallback,
    DecodeErrorCallback? errorCallback,
  ]);
  external AudioDestinationNode get destination;
  external num get sampleRate;
  external num get currentTime;
  external AudioListener get listener;
  external AudioContextState get state;
  external int get renderQuantumSize;
  external AudioWorklet get audioWorklet;
  external set onstatechange(EventHandler value);
  external EventHandler get onstatechange;
}

@JS('AudioContext')
@staticInterop
class AudioContext implements BaseAudioContext {
  external factory AudioContext([AudioContextOptions contextOptions]);
}

extension AudioContextExtension on AudioContext {
  external AudioTimestamp getOutputTimestamp();
  external JSPromise resume();
  external JSPromise suspend();
  external JSPromise close();
  external JSPromise setSinkId(JSAny sinkId);
  external MediaElementAudioSourceNode createMediaElementSource(
      HTMLMediaElement mediaElement);
  external MediaStreamAudioSourceNode createMediaStreamSource(
      MediaStream mediaStream);
  external MediaStreamTrackAudioSourceNode createMediaStreamTrackSource(
      MediaStreamTrack mediaStreamTrack);
  external MediaStreamAudioDestinationNode createMediaStreamDestination();
  external num get baseLatency;
  external num get outputLatency;
  external JSAny get sinkId;
  external AudioRenderCapacity get renderCapacity;
  external set onsinkchange(EventHandler value);
  external EventHandler get onsinkchange;
}

@JS()
@staticInterop
@anonymous
class AudioContextOptions {
  external factory AudioContextOptions({
    JSAny latencyHint,
    num sampleRate,
    JSAny sinkId,
    JSAny renderSizeHint,
  });
}

extension AudioContextOptionsExtension on AudioContextOptions {
  external set latencyHint(JSAny value);
  external JSAny get latencyHint;
  external set sampleRate(num value);
  external num get sampleRate;
  external set sinkId(JSAny value);
  external JSAny get sinkId;
  external set renderSizeHint(JSAny value);
  external JSAny get renderSizeHint;
}

@JS()
@staticInterop
@anonymous
class AudioSinkOptions {
  external factory AudioSinkOptions({required AudioSinkType type});
}

extension AudioSinkOptionsExtension on AudioSinkOptions {
  external set type(AudioSinkType value);
  external AudioSinkType get type;
}

@JS('AudioSinkInfo')
@staticInterop
class AudioSinkInfo {}

extension AudioSinkInfoExtension on AudioSinkInfo {
  external AudioSinkType get type;
}

@JS()
@staticInterop
@anonymous
class AudioTimestamp {
  external factory AudioTimestamp({
    num contextTime,
    DOMHighResTimeStamp performanceTime,
  });
}

extension AudioTimestampExtension on AudioTimestamp {
  external set contextTime(num value);
  external num get contextTime;
  external set performanceTime(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get performanceTime;
}

@JS('AudioRenderCapacity')
@staticInterop
class AudioRenderCapacity implements EventTarget {}

extension AudioRenderCapacityExtension on AudioRenderCapacity {
  external void start([AudioRenderCapacityOptions options]);
  external void stop();
  external set onupdate(EventHandler value);
  external EventHandler get onupdate;
}

@JS()
@staticInterop
@anonymous
class AudioRenderCapacityOptions {
  external factory AudioRenderCapacityOptions({num updateInterval});
}

extension AudioRenderCapacityOptionsExtension on AudioRenderCapacityOptions {
  external set updateInterval(num value);
  external num get updateInterval;
}

@JS('AudioRenderCapacityEvent')
@staticInterop
class AudioRenderCapacityEvent implements Event {
  external factory AudioRenderCapacityEvent(
    String type, [
    AudioRenderCapacityEventInit eventInitDict,
  ]);
}

extension AudioRenderCapacityEventExtension on AudioRenderCapacityEvent {
  external num get timestamp;
  external num get averageLoad;
  external num get peakLoad;
  external num get underrunRatio;
}

@JS()
@staticInterop
@anonymous
class AudioRenderCapacityEventInit implements EventInit {
  external factory AudioRenderCapacityEventInit({
    num timestamp,
    num averageLoad,
    num peakLoad,
    num underrunRatio,
  });
}

extension AudioRenderCapacityEventInitExtension
    on AudioRenderCapacityEventInit {
  external set timestamp(num value);
  external num get timestamp;
  external set averageLoad(num value);
  external num get averageLoad;
  external set peakLoad(num value);
  external num get peakLoad;
  external set underrunRatio(num value);
  external num get underrunRatio;
}

@JS('OfflineAudioContext')
@staticInterop
class OfflineAudioContext implements BaseAudioContext {
  external factory OfflineAudioContext(
    JSAny contextOptionsOrNumberOfChannels, [
    int length,
    num sampleRate,
  ]);
}

extension OfflineAudioContextExtension on OfflineAudioContext {
  external JSPromise startRendering();
  external JSPromise resume();
  external JSPromise suspend(num suspendTime);
  external int get length;
  external set oncomplete(EventHandler value);
  external EventHandler get oncomplete;
}

@JS()
@staticInterop
@anonymous
class OfflineAudioContextOptions {
  external factory OfflineAudioContextOptions({
    int numberOfChannels,
    required int length,
    required num sampleRate,
    JSAny renderSizeHint,
  });
}

extension OfflineAudioContextOptionsExtension on OfflineAudioContextOptions {
  external set numberOfChannels(int value);
  external int get numberOfChannels;
  external set length(int value);
  external int get length;
  external set sampleRate(num value);
  external num get sampleRate;
  external set renderSizeHint(JSAny value);
  external JSAny get renderSizeHint;
}

@JS('OfflineAudioCompletionEvent')
@staticInterop
class OfflineAudioCompletionEvent implements Event {
  external factory OfflineAudioCompletionEvent(
    String type,
    OfflineAudioCompletionEventInit eventInitDict,
  );
}

extension OfflineAudioCompletionEventExtension on OfflineAudioCompletionEvent {
  external AudioBuffer get renderedBuffer;
}

@JS()
@staticInterop
@anonymous
class OfflineAudioCompletionEventInit implements EventInit {
  external factory OfflineAudioCompletionEventInit(
      {required AudioBuffer renderedBuffer});
}

extension OfflineAudioCompletionEventInitExtension
    on OfflineAudioCompletionEventInit {
  external set renderedBuffer(AudioBuffer value);
  external AudioBuffer get renderedBuffer;
}

@JS('AudioBuffer')
@staticInterop
class AudioBuffer {
  external factory AudioBuffer(AudioBufferOptions options);
}

extension AudioBufferExtension on AudioBuffer {
  external JSFloat32Array getChannelData(int channel);
  external void copyFromChannel(
    JSFloat32Array destination,
    int channelNumber, [
    int bufferOffset,
  ]);
  external void copyToChannel(
    JSFloat32Array source,
    int channelNumber, [
    int bufferOffset,
  ]);
  external num get sampleRate;
  external int get length;
  external num get duration;
  external int get numberOfChannels;
}

@JS()
@staticInterop
@anonymous
class AudioBufferOptions {
  external factory AudioBufferOptions({
    int numberOfChannels,
    required int length,
    required num sampleRate,
  });
}

extension AudioBufferOptionsExtension on AudioBufferOptions {
  external set numberOfChannels(int value);
  external int get numberOfChannels;
  external set length(int value);
  external int get length;
  external set sampleRate(num value);
  external num get sampleRate;
}

@JS('AudioNode')
@staticInterop
class AudioNode implements EventTarget {}

extension AudioNodeExtension on AudioNode {
  external AudioNode? connect(
    JSObject destinationNodeOrDestinationParam, [
    int output,
    int input,
  ]);
  external void disconnect([
    JSAny destinationNodeOrDestinationParamOrOutput,
    int output,
    int input,
  ]);
  external BaseAudioContext get context;
  external int get numberOfInputs;
  external int get numberOfOutputs;
  external set channelCount(int value);
  external int get channelCount;
  external set channelCountMode(ChannelCountMode value);
  external ChannelCountMode get channelCountMode;
  external set channelInterpretation(ChannelInterpretation value);
  external ChannelInterpretation get channelInterpretation;
}

@JS()
@staticInterop
@anonymous
class AudioNodeOptions {
  external factory AudioNodeOptions({
    int channelCount,
    ChannelCountMode channelCountMode,
    ChannelInterpretation channelInterpretation,
  });
}

extension AudioNodeOptionsExtension on AudioNodeOptions {
  external set channelCount(int value);
  external int get channelCount;
  external set channelCountMode(ChannelCountMode value);
  external ChannelCountMode get channelCountMode;
  external set channelInterpretation(ChannelInterpretation value);
  external ChannelInterpretation get channelInterpretation;
}

@JS('AudioParam')
@staticInterop
class AudioParam {}

extension AudioParamExtension on AudioParam {
  external AudioParam setValueAtTime(
    num value,
    num startTime,
  );
  external AudioParam linearRampToValueAtTime(
    num value,
    num endTime,
  );
  external AudioParam exponentialRampToValueAtTime(
    num value,
    num endTime,
  );
  external AudioParam setTargetAtTime(
    num target,
    num startTime,
    num timeConstant,
  );
  external AudioParam setValueCurveAtTime(
    JSArray values,
    num startTime,
    num duration,
  );
  external AudioParam cancelScheduledValues(num cancelTime);
  external AudioParam cancelAndHoldAtTime(num cancelTime);
  external set value(num value);
  external num get value;
  external set automationRate(AutomationRate value);
  external AutomationRate get automationRate;
  external num get defaultValue;
  external num get minValue;
  external num get maxValue;
}

@JS('AudioScheduledSourceNode')
@staticInterop
class AudioScheduledSourceNode implements AudioNode {}

extension AudioScheduledSourceNodeExtension on AudioScheduledSourceNode {
  external void start([num when]);
  external void stop([num when]);
  external set onended(EventHandler value);
  external EventHandler get onended;
}

@JS('AnalyserNode')
@staticInterop
class AnalyserNode implements AudioNode {
  external factory AnalyserNode(
    BaseAudioContext context, [
    AnalyserOptions options,
  ]);
}

extension AnalyserNodeExtension on AnalyserNode {
  external void getFloatFrequencyData(JSFloat32Array array);
  external void getByteFrequencyData(JSUint8Array array);
  external void getFloatTimeDomainData(JSFloat32Array array);
  external void getByteTimeDomainData(JSUint8Array array);
  external set fftSize(int value);
  external int get fftSize;
  external int get frequencyBinCount;
  external set minDecibels(num value);
  external num get minDecibels;
  external set maxDecibels(num value);
  external num get maxDecibels;
  external set smoothingTimeConstant(num value);
  external num get smoothingTimeConstant;
}

@JS()
@staticInterop
@anonymous
class AnalyserOptions implements AudioNodeOptions {
  external factory AnalyserOptions({
    int fftSize,
    num maxDecibels,
    num minDecibels,
    num smoothingTimeConstant,
  });
}

extension AnalyserOptionsExtension on AnalyserOptions {
  external set fftSize(int value);
  external int get fftSize;
  external set maxDecibels(num value);
  external num get maxDecibels;
  external set minDecibels(num value);
  external num get minDecibels;
  external set smoothingTimeConstant(num value);
  external num get smoothingTimeConstant;
}

@JS('AudioBufferSourceNode')
@staticInterop
class AudioBufferSourceNode implements AudioScheduledSourceNode {
  external factory AudioBufferSourceNode(
    BaseAudioContext context, [
    AudioBufferSourceOptions options,
  ]);
}

extension AudioBufferSourceNodeExtension on AudioBufferSourceNode {
  external void start([
    num when,
    num offset,
    num duration,
  ]);
  external set buffer(AudioBuffer? value);
  external AudioBuffer? get buffer;
  external AudioParam get playbackRate;
  external AudioParam get detune;
  external set loop(bool value);
  external bool get loop;
  external set loopStart(num value);
  external num get loopStart;
  external set loopEnd(num value);
  external num get loopEnd;
}

@JS()
@staticInterop
@anonymous
class AudioBufferSourceOptions {
  external factory AudioBufferSourceOptions({
    AudioBuffer? buffer,
    num detune,
    bool loop,
    num loopEnd,
    num loopStart,
    num playbackRate,
  });
}

extension AudioBufferSourceOptionsExtension on AudioBufferSourceOptions {
  external set buffer(AudioBuffer? value);
  external AudioBuffer? get buffer;
  external set detune(num value);
  external num get detune;
  external set loop(bool value);
  external bool get loop;
  external set loopEnd(num value);
  external num get loopEnd;
  external set loopStart(num value);
  external num get loopStart;
  external set playbackRate(num value);
  external num get playbackRate;
}

@JS('AudioDestinationNode')
@staticInterop
class AudioDestinationNode implements AudioNode {}

extension AudioDestinationNodeExtension on AudioDestinationNode {
  external int get maxChannelCount;
}

@JS('AudioListener')
@staticInterop
class AudioListener {}

extension AudioListenerExtension on AudioListener {
  external void setPosition(
    num x,
    num y,
    num z,
  );
  external void setOrientation(
    num x,
    num y,
    num z,
    num xUp,
    num yUp,
    num zUp,
  );
  external AudioParam get positionX;
  external AudioParam get positionY;
  external AudioParam get positionZ;
  external AudioParam get forwardX;
  external AudioParam get forwardY;
  external AudioParam get forwardZ;
  external AudioParam get upX;
  external AudioParam get upY;
  external AudioParam get upZ;
}

@JS('AudioProcessingEvent')
@staticInterop
class AudioProcessingEvent implements Event {
  external factory AudioProcessingEvent(
    String type,
    AudioProcessingEventInit eventInitDict,
  );
}

extension AudioProcessingEventExtension on AudioProcessingEvent {
  external num get playbackTime;
  external AudioBuffer get inputBuffer;
  external AudioBuffer get outputBuffer;
}

@JS()
@staticInterop
@anonymous
class AudioProcessingEventInit implements EventInit {
  external factory AudioProcessingEventInit({
    required num playbackTime,
    required AudioBuffer inputBuffer,
    required AudioBuffer outputBuffer,
  });
}

extension AudioProcessingEventInitExtension on AudioProcessingEventInit {
  external set playbackTime(num value);
  external num get playbackTime;
  external set inputBuffer(AudioBuffer value);
  external AudioBuffer get inputBuffer;
  external set outputBuffer(AudioBuffer value);
  external AudioBuffer get outputBuffer;
}

@JS('BiquadFilterNode')
@staticInterop
class BiquadFilterNode implements AudioNode {
  external factory BiquadFilterNode(
    BaseAudioContext context, [
    BiquadFilterOptions options,
  ]);
}

extension BiquadFilterNodeExtension on BiquadFilterNode {
  external void getFrequencyResponse(
    JSFloat32Array frequencyHz,
    JSFloat32Array magResponse,
    JSFloat32Array phaseResponse,
  );
  external set type(BiquadFilterType value);
  external BiquadFilterType get type;
  external AudioParam get frequency;
  external AudioParam get detune;
  external AudioParam get Q;
  external AudioParam get gain;
}

@JS()
@staticInterop
@anonymous
class BiquadFilterOptions implements AudioNodeOptions {
  external factory BiquadFilterOptions({
    BiquadFilterType type,
    num Q,
    num detune,
    num frequency,
    num gain,
  });
}

extension BiquadFilterOptionsExtension on BiquadFilterOptions {
  external set type(BiquadFilterType value);
  external BiquadFilterType get type;
  external set Q(num value);
  external num get Q;
  external set detune(num value);
  external num get detune;
  external set frequency(num value);
  external num get frequency;
  external set gain(num value);
  external num get gain;
}

@JS('ChannelMergerNode')
@staticInterop
class ChannelMergerNode implements AudioNode {
  external factory ChannelMergerNode(
    BaseAudioContext context, [
    ChannelMergerOptions options,
  ]);
}

@JS()
@staticInterop
@anonymous
class ChannelMergerOptions implements AudioNodeOptions {
  external factory ChannelMergerOptions({int numberOfInputs});
}

extension ChannelMergerOptionsExtension on ChannelMergerOptions {
  external set numberOfInputs(int value);
  external int get numberOfInputs;
}

@JS('ChannelSplitterNode')
@staticInterop
class ChannelSplitterNode implements AudioNode {
  external factory ChannelSplitterNode(
    BaseAudioContext context, [
    ChannelSplitterOptions options,
  ]);
}

@JS()
@staticInterop
@anonymous
class ChannelSplitterOptions implements AudioNodeOptions {
  external factory ChannelSplitterOptions({int numberOfOutputs});
}

extension ChannelSplitterOptionsExtension on ChannelSplitterOptions {
  external set numberOfOutputs(int value);
  external int get numberOfOutputs;
}

@JS('ConstantSourceNode')
@staticInterop
class ConstantSourceNode implements AudioScheduledSourceNode {
  external factory ConstantSourceNode(
    BaseAudioContext context, [
    ConstantSourceOptions options,
  ]);
}

extension ConstantSourceNodeExtension on ConstantSourceNode {
  external AudioParam get offset;
}

@JS()
@staticInterop
@anonymous
class ConstantSourceOptions {
  external factory ConstantSourceOptions({num offset});
}

extension ConstantSourceOptionsExtension on ConstantSourceOptions {
  external set offset(num value);
  external num get offset;
}

@JS('ConvolverNode')
@staticInterop
class ConvolverNode implements AudioNode {
  external factory ConvolverNode(
    BaseAudioContext context, [
    ConvolverOptions options,
  ]);
}

extension ConvolverNodeExtension on ConvolverNode {
  external set buffer(AudioBuffer? value);
  external AudioBuffer? get buffer;
  external set normalize(bool value);
  external bool get normalize;
}

@JS()
@staticInterop
@anonymous
class ConvolverOptions implements AudioNodeOptions {
  external factory ConvolverOptions({
    AudioBuffer? buffer,
    bool disableNormalization,
  });
}

extension ConvolverOptionsExtension on ConvolverOptions {
  external set buffer(AudioBuffer? value);
  external AudioBuffer? get buffer;
  external set disableNormalization(bool value);
  external bool get disableNormalization;
}

@JS('DelayNode')
@staticInterop
class DelayNode implements AudioNode {
  external factory DelayNode(
    BaseAudioContext context, [
    DelayOptions options,
  ]);
}

extension DelayNodeExtension on DelayNode {
  external AudioParam get delayTime;
}

@JS()
@staticInterop
@anonymous
class DelayOptions implements AudioNodeOptions {
  external factory DelayOptions({
    num maxDelayTime,
    num delayTime,
  });
}

extension DelayOptionsExtension on DelayOptions {
  external set maxDelayTime(num value);
  external num get maxDelayTime;
  external set delayTime(num value);
  external num get delayTime;
}

@JS('DynamicsCompressorNode')
@staticInterop
class DynamicsCompressorNode implements AudioNode {
  external factory DynamicsCompressorNode(
    BaseAudioContext context, [
    DynamicsCompressorOptions options,
  ]);
}

extension DynamicsCompressorNodeExtension on DynamicsCompressorNode {
  external AudioParam get threshold;
  external AudioParam get knee;
  external AudioParam get ratio;
  external num get reduction;
  external AudioParam get attack;
  external AudioParam get release;
}

@JS()
@staticInterop
@anonymous
class DynamicsCompressorOptions implements AudioNodeOptions {
  external factory DynamicsCompressorOptions({
    num attack,
    num knee,
    num ratio,
    num release,
    num threshold,
  });
}

extension DynamicsCompressorOptionsExtension on DynamicsCompressorOptions {
  external set attack(num value);
  external num get attack;
  external set knee(num value);
  external num get knee;
  external set ratio(num value);
  external num get ratio;
  external set release(num value);
  external num get release;
  external set threshold(num value);
  external num get threshold;
}

@JS('GainNode')
@staticInterop
class GainNode implements AudioNode {
  external factory GainNode(
    BaseAudioContext context, [
    GainOptions options,
  ]);
}

extension GainNodeExtension on GainNode {
  external AudioParam get gain;
}

@JS()
@staticInterop
@anonymous
class GainOptions implements AudioNodeOptions {
  external factory GainOptions({num gain});
}

extension GainOptionsExtension on GainOptions {
  external set gain(num value);
  external num get gain;
}

@JS('IIRFilterNode')
@staticInterop
class IIRFilterNode implements AudioNode {
  external factory IIRFilterNode(
    BaseAudioContext context,
    IIRFilterOptions options,
  );
}

extension IIRFilterNodeExtension on IIRFilterNode {
  external void getFrequencyResponse(
    JSFloat32Array frequencyHz,
    JSFloat32Array magResponse,
    JSFloat32Array phaseResponse,
  );
}

@JS()
@staticInterop
@anonymous
class IIRFilterOptions implements AudioNodeOptions {
  external factory IIRFilterOptions({
    required JSArray feedforward,
    required JSArray feedback,
  });
}

extension IIRFilterOptionsExtension on IIRFilterOptions {
  external set feedforward(JSArray value);
  external JSArray get feedforward;
  external set feedback(JSArray value);
  external JSArray get feedback;
}

@JS('MediaElementAudioSourceNode')
@staticInterop
class MediaElementAudioSourceNode implements AudioNode {
  external factory MediaElementAudioSourceNode(
    AudioContext context,
    MediaElementAudioSourceOptions options,
  );
}

extension MediaElementAudioSourceNodeExtension on MediaElementAudioSourceNode {
  external HTMLMediaElement get mediaElement;
}

@JS()
@staticInterop
@anonymous
class MediaElementAudioSourceOptions {
  external factory MediaElementAudioSourceOptions(
      {required HTMLMediaElement mediaElement});
}

extension MediaElementAudioSourceOptionsExtension
    on MediaElementAudioSourceOptions {
  external set mediaElement(HTMLMediaElement value);
  external HTMLMediaElement get mediaElement;
}

@JS('MediaStreamAudioDestinationNode')
@staticInterop
class MediaStreamAudioDestinationNode implements AudioNode {
  external factory MediaStreamAudioDestinationNode(
    AudioContext context, [
    AudioNodeOptions options,
  ]);
}

extension MediaStreamAudioDestinationNodeExtension
    on MediaStreamAudioDestinationNode {
  external MediaStream get stream;
}

@JS('MediaStreamAudioSourceNode')
@staticInterop
class MediaStreamAudioSourceNode implements AudioNode {
  external factory MediaStreamAudioSourceNode(
    AudioContext context,
    MediaStreamAudioSourceOptions options,
  );
}

extension MediaStreamAudioSourceNodeExtension on MediaStreamAudioSourceNode {
  external MediaStream get mediaStream;
}

@JS()
@staticInterop
@anonymous
class MediaStreamAudioSourceOptions {
  external factory MediaStreamAudioSourceOptions(
      {required MediaStream mediaStream});
}

extension MediaStreamAudioSourceOptionsExtension
    on MediaStreamAudioSourceOptions {
  external set mediaStream(MediaStream value);
  external MediaStream get mediaStream;
}

@JS('MediaStreamTrackAudioSourceNode')
@staticInterop
class MediaStreamTrackAudioSourceNode implements AudioNode {
  external factory MediaStreamTrackAudioSourceNode(
    AudioContext context,
    MediaStreamTrackAudioSourceOptions options,
  );
}

@JS()
@staticInterop
@anonymous
class MediaStreamTrackAudioSourceOptions {
  external factory MediaStreamTrackAudioSourceOptions(
      {required MediaStreamTrack mediaStreamTrack});
}

extension MediaStreamTrackAudioSourceOptionsExtension
    on MediaStreamTrackAudioSourceOptions {
  external set mediaStreamTrack(MediaStreamTrack value);
  external MediaStreamTrack get mediaStreamTrack;
}

@JS('OscillatorNode')
@staticInterop
class OscillatorNode implements AudioScheduledSourceNode {
  external factory OscillatorNode(
    BaseAudioContext context, [
    OscillatorOptions options,
  ]);
}

extension OscillatorNodeExtension on OscillatorNode {
  external void setPeriodicWave(PeriodicWave periodicWave);
  external set type(OscillatorType value);
  external OscillatorType get type;
  external AudioParam get frequency;
  external AudioParam get detune;
}

@JS()
@staticInterop
@anonymous
class OscillatorOptions implements AudioNodeOptions {
  external factory OscillatorOptions({
    OscillatorType type,
    num frequency,
    num detune,
    PeriodicWave periodicWave,
  });
}

extension OscillatorOptionsExtension on OscillatorOptions {
  external set type(OscillatorType value);
  external OscillatorType get type;
  external set frequency(num value);
  external num get frequency;
  external set detune(num value);
  external num get detune;
  external set periodicWave(PeriodicWave value);
  external PeriodicWave get periodicWave;
}

@JS('PannerNode')
@staticInterop
class PannerNode implements AudioNode {
  external factory PannerNode(
    BaseAudioContext context, [
    PannerOptions options,
  ]);
}

extension PannerNodeExtension on PannerNode {
  external void setPosition(
    num x,
    num y,
    num z,
  );
  external void setOrientation(
    num x,
    num y,
    num z,
  );
  external set panningModel(PanningModelType value);
  external PanningModelType get panningModel;
  external AudioParam get positionX;
  external AudioParam get positionY;
  external AudioParam get positionZ;
  external AudioParam get orientationX;
  external AudioParam get orientationY;
  external AudioParam get orientationZ;
  external set distanceModel(DistanceModelType value);
  external DistanceModelType get distanceModel;
  external set refDistance(num value);
  external num get refDistance;
  external set maxDistance(num value);
  external num get maxDistance;
  external set rolloffFactor(num value);
  external num get rolloffFactor;
  external set coneInnerAngle(num value);
  external num get coneInnerAngle;
  external set coneOuterAngle(num value);
  external num get coneOuterAngle;
  external set coneOuterGain(num value);
  external num get coneOuterGain;
}

@JS()
@staticInterop
@anonymous
class PannerOptions implements AudioNodeOptions {
  external factory PannerOptions({
    PanningModelType panningModel,
    DistanceModelType distanceModel,
    num positionX,
    num positionY,
    num positionZ,
    num orientationX,
    num orientationY,
    num orientationZ,
    num refDistance,
    num maxDistance,
    num rolloffFactor,
    num coneInnerAngle,
    num coneOuterAngle,
    num coneOuterGain,
  });
}

extension PannerOptionsExtension on PannerOptions {
  external set panningModel(PanningModelType value);
  external PanningModelType get panningModel;
  external set distanceModel(DistanceModelType value);
  external DistanceModelType get distanceModel;
  external set positionX(num value);
  external num get positionX;
  external set positionY(num value);
  external num get positionY;
  external set positionZ(num value);
  external num get positionZ;
  external set orientationX(num value);
  external num get orientationX;
  external set orientationY(num value);
  external num get orientationY;
  external set orientationZ(num value);
  external num get orientationZ;
  external set refDistance(num value);
  external num get refDistance;
  external set maxDistance(num value);
  external num get maxDistance;
  external set rolloffFactor(num value);
  external num get rolloffFactor;
  external set coneInnerAngle(num value);
  external num get coneInnerAngle;
  external set coneOuterAngle(num value);
  external num get coneOuterAngle;
  external set coneOuterGain(num value);
  external num get coneOuterGain;
}

@JS('PeriodicWave')
@staticInterop
class PeriodicWave {
  external factory PeriodicWave(
    BaseAudioContext context, [
    PeriodicWaveOptions options,
  ]);
}

@JS()
@staticInterop
@anonymous
class PeriodicWaveConstraints {
  external factory PeriodicWaveConstraints({bool disableNormalization});
}

extension PeriodicWaveConstraintsExtension on PeriodicWaveConstraints {
  external set disableNormalization(bool value);
  external bool get disableNormalization;
}

@JS()
@staticInterop
@anonymous
class PeriodicWaveOptions implements PeriodicWaveConstraints {
  external factory PeriodicWaveOptions({
    JSArray real,
    JSArray imag,
  });
}

extension PeriodicWaveOptionsExtension on PeriodicWaveOptions {
  external set real(JSArray value);
  external JSArray get real;
  external set imag(JSArray value);
  external JSArray get imag;
}

@JS('ScriptProcessorNode')
@staticInterop
class ScriptProcessorNode implements AudioNode {}

extension ScriptProcessorNodeExtension on ScriptProcessorNode {
  external set onaudioprocess(EventHandler value);
  external EventHandler get onaudioprocess;
  external int get bufferSize;
}

@JS('StereoPannerNode')
@staticInterop
class StereoPannerNode implements AudioNode {
  external factory StereoPannerNode(
    BaseAudioContext context, [
    StereoPannerOptions options,
  ]);
}

extension StereoPannerNodeExtension on StereoPannerNode {
  external AudioParam get pan;
}

@JS()
@staticInterop
@anonymous
class StereoPannerOptions implements AudioNodeOptions {
  external factory StereoPannerOptions({num pan});
}

extension StereoPannerOptionsExtension on StereoPannerOptions {
  external set pan(num value);
  external num get pan;
}

@JS('WaveShaperNode')
@staticInterop
class WaveShaperNode implements AudioNode {
  external factory WaveShaperNode(
    BaseAudioContext context, [
    WaveShaperOptions options,
  ]);
}

extension WaveShaperNodeExtension on WaveShaperNode {
  external set curve(JSFloat32Array? value);
  external JSFloat32Array? get curve;
  external set oversample(OverSampleType value);
  external OverSampleType get oversample;
}

@JS()
@staticInterop
@anonymous
class WaveShaperOptions implements AudioNodeOptions {
  external factory WaveShaperOptions({
    JSArray curve,
    OverSampleType oversample,
  });
}

extension WaveShaperOptionsExtension on WaveShaperOptions {
  external set curve(JSArray value);
  external JSArray get curve;
  external set oversample(OverSampleType value);
  external OverSampleType get oversample;
}

@JS('AudioWorklet')
@staticInterop
class AudioWorklet implements Worklet {}

extension AudioWorkletExtension on AudioWorklet {
  external MessagePort get port;
}

@JS('AudioWorkletGlobalScope')
@staticInterop
class AudioWorkletGlobalScope implements WorkletGlobalScope {}

extension AudioWorkletGlobalScopeExtension on AudioWorkletGlobalScope {
  external void registerProcessor(
    String name,
    AudioWorkletProcessorConstructor processorCtor,
  );
  external int get currentFrame;
  external num get currentTime;
  external num get sampleRate;
  external int get renderQuantumSize;
  external MessagePort get port;
}

@JS('AudioParamMap')
@staticInterop
class AudioParamMap {}

extension AudioParamMapExtension on AudioParamMap {}

@JS('AudioWorkletNode')
@staticInterop
class AudioWorkletNode implements AudioNode {
  external factory AudioWorkletNode(
    BaseAudioContext context,
    String name, [
    AudioWorkletNodeOptions options,
  ]);
}

extension AudioWorkletNodeExtension on AudioWorkletNode {
  external AudioParamMap get parameters;
  external MessagePort get port;
  external set onprocessorerror(EventHandler value);
  external EventHandler get onprocessorerror;
}

@JS()
@staticInterop
@anonymous
class AudioWorkletNodeOptions implements AudioNodeOptions {
  external factory AudioWorkletNodeOptions({
    int numberOfInputs,
    int numberOfOutputs,
    JSArray outputChannelCount,
    JSAny parameterData,
    JSObject processorOptions,
  });
}

extension AudioWorkletNodeOptionsExtension on AudioWorkletNodeOptions {
  external set numberOfInputs(int value);
  external int get numberOfInputs;
  external set numberOfOutputs(int value);
  external int get numberOfOutputs;
  external set outputChannelCount(JSArray value);
  external JSArray get outputChannelCount;
  external set parameterData(JSAny value);
  external JSAny get parameterData;
  external set processorOptions(JSObject value);
  external JSObject get processorOptions;
}

@JS('AudioWorkletProcessor')
@staticInterop
class AudioWorkletProcessor {
  external factory AudioWorkletProcessor();
}

extension AudioWorkletProcessorExtension on AudioWorkletProcessor {
  external MessagePort get port;
}

@JS()
@staticInterop
@anonymous
class AudioParamDescriptor {
  external factory AudioParamDescriptor({
    required String name,
    num defaultValue,
    num minValue,
    num maxValue,
    AutomationRate automationRate,
  });
}

extension AudioParamDescriptorExtension on AudioParamDescriptor {
  external set name(String value);
  external String get name;
  external set defaultValue(num value);
  external num get defaultValue;
  external set minValue(num value);
  external num get minValue;
  external set maxValue(num value);
  external num get maxValue;
  external set automationRate(AutomationRate value);
  external AutomationRate get automationRate;
}
