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
import 'mst_content_hint.dart';
import 'webcryptoapi.dart';
import 'webidl.dart';
import 'webrtc_encoded_transform.dart';
import 'webrtc_ice.dart';
import 'webrtc_identity.dart';
import 'webrtc_priority.dart';
import 'webrtc_stats.dart';
import 'websockets.dart';

typedef RTCPeerConnectionErrorCallback = JSFunction;
typedef RTCSessionDescriptionCallback = JSFunction;
typedef RTCIceTransportPolicy = String;
typedef RTCBundlePolicy = String;
typedef RTCRtcpMuxPolicy = String;
typedef RTCSignalingState = String;
typedef RTCIceGatheringState = String;
typedef RTCPeerConnectionState = String;
typedef RTCIceConnectionState = String;
typedef RTCSdpType = String;
typedef RTCIceProtocol = String;
typedef RTCIceTcpCandidateType = String;
typedef RTCIceCandidateType = String;
typedef RTCIceServerTransportProtocol = String;
typedef RTCRtpTransceiverDirection = String;
typedef RTCDtlsTransportState = String;
typedef RTCIceGathererState = String;
typedef RTCIceTransportState = String;
typedef RTCIceRole = String;
typedef RTCIceComponent = String;
typedef RTCSctpTransportState = String;
typedef RTCDataChannelState = String;
typedef RTCErrorDetailType = String;

@JS()
@staticInterop
@anonymous
class RTCConfiguration {
  external factory RTCConfiguration({
    String peerIdentity,
    JSArray iceServers,
    RTCIceTransportPolicy iceTransportPolicy,
    RTCBundlePolicy bundlePolicy,
    RTCRtcpMuxPolicy rtcpMuxPolicy,
    JSArray certificates,
    int iceCandidatePoolSize,
  });
}

extension RTCConfigurationExtension on RTCConfiguration {
  external set peerIdentity(String value);
  external String get peerIdentity;
  external set iceServers(JSArray value);
  external JSArray get iceServers;
  external set iceTransportPolicy(RTCIceTransportPolicy value);
  external RTCIceTransportPolicy get iceTransportPolicy;
  external set bundlePolicy(RTCBundlePolicy value);
  external RTCBundlePolicy get bundlePolicy;
  external set rtcpMuxPolicy(RTCRtcpMuxPolicy value);
  external RTCRtcpMuxPolicy get rtcpMuxPolicy;
  external set certificates(JSArray value);
  external JSArray get certificates;
  external set iceCandidatePoolSize(int value);
  external int get iceCandidatePoolSize;
}

@JS()
@staticInterop
@anonymous
class RTCIceServer {
  external factory RTCIceServer({
    required JSAny urls,
    String username,
    String credential,
  });
}

extension RTCIceServerExtension on RTCIceServer {
  external set urls(JSAny value);
  external JSAny get urls;
  external set username(String value);
  external String get username;
  external set credential(String value);
  external String get credential;
}

@JS()
@staticInterop
@anonymous
class RTCOfferAnswerOptions {
  external factory RTCOfferAnswerOptions();
}

@JS()
@staticInterop
@anonymous
class RTCOfferOptions implements RTCOfferAnswerOptions {
  external factory RTCOfferOptions({
    bool iceRestart,
    bool offerToReceiveAudio,
    bool offerToReceiveVideo,
  });
}

extension RTCOfferOptionsExtension on RTCOfferOptions {
  external set iceRestart(bool value);
  external bool get iceRestart;
  external set offerToReceiveAudio(bool value);
  external bool get offerToReceiveAudio;
  external set offerToReceiveVideo(bool value);
  external bool get offerToReceiveVideo;
}

@JS()
@staticInterop
@anonymous
class RTCAnswerOptions implements RTCOfferAnswerOptions {
  external factory RTCAnswerOptions();
}

@JS('RTCPeerConnection')
@staticInterop
class RTCPeerConnection implements EventTarget {
  external factory RTCPeerConnection([RTCConfiguration configuration]);

  external static JSPromise generateCertificate(
      AlgorithmIdentifier keygenAlgorithm);
}

extension RTCPeerConnectionExtension on RTCPeerConnection {
  external void setIdentityProvider(
    String provider, [
    RTCIdentityProviderOptions options,
  ]);
  external JSPromise getIdentityAssertion();
  external JSPromise createOffer([
    JSObject optionsOrSuccessCallback,
    RTCPeerConnectionErrorCallback failureCallback,
    RTCOfferOptions options,
  ]);
  external JSPromise createAnswer([
    JSObject optionsOrSuccessCallback,
    RTCPeerConnectionErrorCallback failureCallback,
  ]);
  external JSPromise setLocalDescription([
    RTCLocalSessionDescriptionInit description,
    VoidFunction successCallback,
    RTCPeerConnectionErrorCallback failureCallback,
  ]);
  external JSPromise setRemoteDescription(
    RTCSessionDescriptionInit description, [
    VoidFunction successCallback,
    RTCPeerConnectionErrorCallback failureCallback,
  ]);
  external JSPromise addIceCandidate([
    RTCIceCandidateInit candidate,
    VoidFunction successCallback,
    RTCPeerConnectionErrorCallback failureCallback,
  ]);
  external void restartIce();
  external RTCConfiguration getConfiguration();
  external void setConfiguration([RTCConfiguration configuration]);
  external void close();
  external JSArray getSenders();
  external JSArray getReceivers();
  external JSArray getTransceivers();
  external RTCRtpSender addTrack(
    MediaStreamTrack track,
    MediaStream streams,
  );
  external void removeTrack(RTCRtpSender sender);
  external RTCRtpTransceiver addTransceiver(
    JSAny trackOrKind, [
    RTCRtpTransceiverInit init,
  ]);
  external RTCDataChannel createDataChannel(
    String label, [
    RTCDataChannelInit dataChannelDict,
  ]);
  external JSPromise getStats([MediaStreamTrack? selector]);
  external JSPromise get peerIdentity;
  external String? get idpLoginUrl;
  external String? get idpErrorInfo;
  external RTCSessionDescription? get localDescription;
  external RTCSessionDescription? get currentLocalDescription;
  external RTCSessionDescription? get pendingLocalDescription;
  external RTCSessionDescription? get remoteDescription;
  external RTCSessionDescription? get currentRemoteDescription;
  external RTCSessionDescription? get pendingRemoteDescription;
  external RTCSignalingState get signalingState;
  external RTCIceGatheringState get iceGatheringState;
  external RTCIceConnectionState get iceConnectionState;
  external RTCPeerConnectionState get connectionState;
  external bool? get canTrickleIceCandidates;
  external set onnegotiationneeded(EventHandler value);
  external EventHandler get onnegotiationneeded;
  external set onicecandidate(EventHandler value);
  external EventHandler get onicecandidate;
  external set onicecandidateerror(EventHandler value);
  external EventHandler get onicecandidateerror;
  external set onsignalingstatechange(EventHandler value);
  external EventHandler get onsignalingstatechange;
  external set oniceconnectionstatechange(EventHandler value);
  external EventHandler get oniceconnectionstatechange;
  external set onicegatheringstatechange(EventHandler value);
  external EventHandler get onicegatheringstatechange;
  external set onconnectionstatechange(EventHandler value);
  external EventHandler get onconnectionstatechange;
  external set ontrack(EventHandler value);
  external EventHandler get ontrack;
  external RTCSctpTransport? get sctp;
  external set ondatachannel(EventHandler value);
  external EventHandler get ondatachannel;
}

@JS('RTCSessionDescription')
@staticInterop
class RTCSessionDescription {
  external factory RTCSessionDescription(
      RTCSessionDescriptionInit descriptionInitDict);
}

extension RTCSessionDescriptionExtension on RTCSessionDescription {
  external JSObject toJSON();
  external RTCSdpType get type;
  external String get sdp;
}

@JS()
@staticInterop
@anonymous
class RTCSessionDescriptionInit {
  external factory RTCSessionDescriptionInit({
    required RTCSdpType type,
    String sdp,
  });
}

extension RTCSessionDescriptionInitExtension on RTCSessionDescriptionInit {
  external set type(RTCSdpType value);
  external RTCSdpType get type;
  external set sdp(String value);
  external String get sdp;
}

@JS()
@staticInterop
@anonymous
class RTCLocalSessionDescriptionInit {
  external factory RTCLocalSessionDescriptionInit({
    RTCSdpType type,
    String sdp,
  });
}

extension RTCLocalSessionDescriptionInitExtension
    on RTCLocalSessionDescriptionInit {
  external set type(RTCSdpType value);
  external RTCSdpType get type;
  external set sdp(String value);
  external String get sdp;
}

@JS('RTCIceCandidate')
@staticInterop
class RTCIceCandidate {
  external factory RTCIceCandidate([RTCIceCandidateInit candidateInitDict]);
}

extension RTCIceCandidateExtension on RTCIceCandidate {
  external RTCIceCandidateInit toJSON();
  external String get candidate;
  external String? get sdpMid;
  external int? get sdpMLineIndex;
  external String? get foundation;
  external RTCIceComponent? get component;
  external int? get priority;
  external String? get address;
  external RTCIceProtocol? get protocol;
  external int? get port;
  external RTCIceCandidateType? get type;
  external RTCIceTcpCandidateType? get tcpType;
  external String? get relatedAddress;
  external int? get relatedPort;
  external String? get usernameFragment;
  external RTCIceServerTransportProtocol? get relayProtocol;
  external String? get url;
}

@JS()
@staticInterop
@anonymous
class RTCIceCandidateInit {
  external factory RTCIceCandidateInit({
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
    String? usernameFragment,
  });
}

extension RTCIceCandidateInitExtension on RTCIceCandidateInit {
  external set candidate(String value);
  external String get candidate;
  external set sdpMid(String? value);
  external String? get sdpMid;
  external set sdpMLineIndex(int? value);
  external int? get sdpMLineIndex;
  external set usernameFragment(String? value);
  external String? get usernameFragment;
}

@JS('RTCPeerConnectionIceEvent')
@staticInterop
class RTCPeerConnectionIceEvent implements Event {
  external factory RTCPeerConnectionIceEvent(
    String type, [
    RTCPeerConnectionIceEventInit eventInitDict,
  ]);
}

extension RTCPeerConnectionIceEventExtension on RTCPeerConnectionIceEvent {
  external RTCIceCandidate? get candidate;
  external String? get url;
}

@JS()
@staticInterop
@anonymous
class RTCPeerConnectionIceEventInit implements EventInit {
  external factory RTCPeerConnectionIceEventInit({
    RTCIceCandidate? candidate,
    String? url,
  });
}

extension RTCPeerConnectionIceEventInitExtension
    on RTCPeerConnectionIceEventInit {
  external set candidate(RTCIceCandidate? value);
  external RTCIceCandidate? get candidate;
  external set url(String? value);
  external String? get url;
}

@JS('RTCPeerConnectionIceErrorEvent')
@staticInterop
class RTCPeerConnectionIceErrorEvent implements Event {
  external factory RTCPeerConnectionIceErrorEvent(
    String type,
    RTCPeerConnectionIceErrorEventInit eventInitDict,
  );
}

extension RTCPeerConnectionIceErrorEventExtension
    on RTCPeerConnectionIceErrorEvent {
  external String? get address;
  external int? get port;
  external String get url;
  external int get errorCode;
  external String get errorText;
}

@JS()
@staticInterop
@anonymous
class RTCPeerConnectionIceErrorEventInit implements EventInit {
  external factory RTCPeerConnectionIceErrorEventInit({
    String? address,
    int? port,
    String url,
    required int errorCode,
    String errorText,
  });
}

extension RTCPeerConnectionIceErrorEventInitExtension
    on RTCPeerConnectionIceErrorEventInit {
  external set address(String? value);
  external String? get address;
  external set port(int? value);
  external int? get port;
  external set url(String value);
  external String get url;
  external set errorCode(int value);
  external int get errorCode;
  external set errorText(String value);
  external String get errorText;
}

@JS()
@staticInterop
@anonymous
class RTCCertificateExpiration {
  external factory RTCCertificateExpiration({int expires});
}

extension RTCCertificateExpirationExtension on RTCCertificateExpiration {
  external set expires(int value);
  external int get expires;
}

@JS('RTCCertificate')
@staticInterop
class RTCCertificate {}

extension RTCCertificateExtension on RTCCertificate {
  external JSArray getFingerprints();
  external EpochTimeStamp get expires;
}

@JS()
@staticInterop
@anonymous
class RTCRtpTransceiverInit {
  external factory RTCRtpTransceiverInit({
    RTCRtpTransceiverDirection direction,
    JSArray streams,
    JSArray sendEncodings,
  });
}

extension RTCRtpTransceiverInitExtension on RTCRtpTransceiverInit {
  external set direction(RTCRtpTransceiverDirection value);
  external RTCRtpTransceiverDirection get direction;
  external set streams(JSArray value);
  external JSArray get streams;
  external set sendEncodings(JSArray value);
  external JSArray get sendEncodings;
}

@JS('RTCRtpSender')
@staticInterop
class RTCRtpSender {
  external static RTCRtpCapabilities? getCapabilities(String kind);
}

extension RTCRtpSenderExtension on RTCRtpSender {
  external JSPromise generateKeyFrame([JSArray rids]);
  external JSPromise setParameters(
    RTCRtpSendParameters parameters, [
    RTCSetParameterOptions setParameterOptions,
  ]);
  external RTCRtpSendParameters getParameters();
  external JSPromise replaceTrack(MediaStreamTrack? withTrack);
  external void setStreams(MediaStream streams);
  external JSPromise getStats();
  external set transform(RTCRtpTransform? value);
  external RTCRtpTransform? get transform;
  external MediaStreamTrack? get track;
  external RTCDtlsTransport? get transport;
  external RTCDTMFSender? get dtmf;
}

@JS()
@staticInterop
@anonymous
class RTCRtpParameters {
  external factory RTCRtpParameters({
    required JSArray headerExtensions,
    required RTCRtcpParameters rtcp,
    required JSArray codecs,
  });
}

extension RTCRtpParametersExtension on RTCRtpParameters {
  external set headerExtensions(JSArray value);
  external JSArray get headerExtensions;
  external set rtcp(RTCRtcpParameters value);
  external RTCRtcpParameters get rtcp;
  external set codecs(JSArray value);
  external JSArray get codecs;
}

@JS()
@staticInterop
@anonymous
class RTCRtpSendParameters implements RTCRtpParameters {
  external factory RTCRtpSendParameters({
    RTCDegradationPreference degradationPreference,
    required String transactionId,
    required JSArray encodings,
  });
}

extension RTCRtpSendParametersExtension on RTCRtpSendParameters {
  external set degradationPreference(RTCDegradationPreference value);
  external RTCDegradationPreference get degradationPreference;
  external set transactionId(String value);
  external String get transactionId;
  external set encodings(JSArray value);
  external JSArray get encodings;
}

@JS()
@staticInterop
@anonymous
class RTCRtpReceiveParameters implements RTCRtpParameters {
  external factory RTCRtpReceiveParameters();
}

@JS()
@staticInterop
@anonymous
class RTCRtpCodingParameters {
  external factory RTCRtpCodingParameters({String rid});
}

extension RTCRtpCodingParametersExtension on RTCRtpCodingParameters {
  external set rid(String value);
  external String get rid;
}

@JS()
@staticInterop
@anonymous
class RTCRtpEncodingParameters implements RTCRtpCodingParameters {
  external factory RTCRtpEncodingParameters({
    RTCPriorityType priority,
    RTCPriorityType networkPriority,
    String scalabilityMode,
    bool active,
    int maxBitrate,
    num maxFramerate,
    num scaleResolutionDownBy,
  });
}

extension RTCRtpEncodingParametersExtension on RTCRtpEncodingParameters {
  external set priority(RTCPriorityType value);
  external RTCPriorityType get priority;
  external set networkPriority(RTCPriorityType value);
  external RTCPriorityType get networkPriority;
  external set scalabilityMode(String value);
  external String get scalabilityMode;
  external set active(bool value);
  external bool get active;
  external set maxBitrate(int value);
  external int get maxBitrate;
  external set maxFramerate(num value);
  external num get maxFramerate;
  external set scaleResolutionDownBy(num value);
  external num get scaleResolutionDownBy;
}

@JS()
@staticInterop
@anonymous
class RTCRtcpParameters {
  external factory RTCRtcpParameters({
    String cname,
    bool reducedSize,
  });
}

extension RTCRtcpParametersExtension on RTCRtcpParameters {
  external set cname(String value);
  external String get cname;
  external set reducedSize(bool value);
  external bool get reducedSize;
}

@JS()
@staticInterop
@anonymous
class RTCRtpHeaderExtensionParameters {
  external factory RTCRtpHeaderExtensionParameters({
    required String uri,
    required int id,
    bool encrypted,
  });
}

extension RTCRtpHeaderExtensionParametersExtension
    on RTCRtpHeaderExtensionParameters {
  external set uri(String value);
  external String get uri;
  external set id(int value);
  external int get id;
  external set encrypted(bool value);
  external bool get encrypted;
}

@JS()
@staticInterop
@anonymous
class RTCRtpCodec {
  external factory RTCRtpCodec({
    required String mimeType,
    required int clockRate,
    int channels,
    String sdpFmtpLine,
  });
}

extension RTCRtpCodecExtension on RTCRtpCodec {
  external set mimeType(String value);
  external String get mimeType;
  external set clockRate(int value);
  external int get clockRate;
  external set channels(int value);
  external int get channels;
  external set sdpFmtpLine(String value);
  external String get sdpFmtpLine;
}

@JS()
@staticInterop
@anonymous
class RTCRtpCodecParameters implements RTCRtpCodec {
  external factory RTCRtpCodecParameters({required int payloadType});
}

extension RTCRtpCodecParametersExtension on RTCRtpCodecParameters {
  external set payloadType(int value);
  external int get payloadType;
}

@JS()
@staticInterop
@anonymous
class RTCRtpCapabilities {
  external factory RTCRtpCapabilities({
    required JSArray codecs,
    required JSArray headerExtensions,
  });
}

extension RTCRtpCapabilitiesExtension on RTCRtpCapabilities {
  external set codecs(JSArray value);
  external JSArray get codecs;
  external set headerExtensions(JSArray value);
  external JSArray get headerExtensions;
}

@JS()
@staticInterop
@anonymous
class RTCRtpCodecCapability implements RTCRtpCodec {
  external factory RTCRtpCodecCapability();
}

@JS()
@staticInterop
@anonymous
class RTCRtpHeaderExtensionCapability {
  external factory RTCRtpHeaderExtensionCapability({required String uri});
}

extension RTCRtpHeaderExtensionCapabilityExtension
    on RTCRtpHeaderExtensionCapability {
  external set uri(String value);
  external String get uri;
}

@JS()
@staticInterop
@anonymous
class RTCSetParameterOptions {
  external factory RTCSetParameterOptions();
}

@JS('RTCRtpReceiver')
@staticInterop
class RTCRtpReceiver {
  external static RTCRtpCapabilities? getCapabilities(String kind);
}

extension RTCRtpReceiverExtension on RTCRtpReceiver {
  external RTCRtpReceiveParameters getParameters();
  external JSArray getContributingSources();
  external JSArray getSynchronizationSources();
  external JSPromise getStats();
  external set transform(RTCRtpTransform? value);
  external RTCRtpTransform? get transform;
  external MediaStreamTrack get track;
  external RTCDtlsTransport? get transport;
}

@JS()
@staticInterop
@anonymous
class RTCRtpContributingSource {
  external factory RTCRtpContributingSource({
    required DOMHighResTimeStamp timestamp,
    required int source,
    num audioLevel,
    required int rtpTimestamp,
  });
}

extension RTCRtpContributingSourceExtension on RTCRtpContributingSource {
  external set timestamp(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get timestamp;
  external set source(int value);
  external int get source;
  external set audioLevel(num value);
  external num get audioLevel;
  external set rtpTimestamp(int value);
  external int get rtpTimestamp;
}

@JS()
@staticInterop
@anonymous
class RTCRtpSynchronizationSource implements RTCRtpContributingSource {
  external factory RTCRtpSynchronizationSource();
}

@JS('RTCRtpTransceiver')
@staticInterop
class RTCRtpTransceiver {}

extension RTCRtpTransceiverExtension on RTCRtpTransceiver {
  external void stop();
  external void setCodecPreferences(JSArray codecs);
  external String? get mid;
  external RTCRtpSender get sender;
  external RTCRtpReceiver get receiver;
  external set direction(RTCRtpTransceiverDirection value);
  external RTCRtpTransceiverDirection get direction;
  external RTCRtpTransceiverDirection? get currentDirection;
}

@JS('RTCDtlsTransport')
@staticInterop
class RTCDtlsTransport implements EventTarget {}

extension RTCDtlsTransportExtension on RTCDtlsTransport {
  external JSArray getRemoteCertificates();
  external RTCIceTransport get iceTransport;
  external RTCDtlsTransportState get state;
  external set onstatechange(EventHandler value);
  external EventHandler get onstatechange;
  external set onerror(EventHandler value);
  external EventHandler get onerror;
}

@JS()
@staticInterop
@anonymous
class RTCDtlsFingerprint {
  external factory RTCDtlsFingerprint({
    String algorithm,
    String value,
  });
}

extension RTCDtlsFingerprintExtension on RTCDtlsFingerprint {
  external set algorithm(String value);
  external String get algorithm;
  external set value(String value);
  external String get value;
}

@JS('RTCIceTransport')
@staticInterop
class RTCIceTransport implements EventTarget {
  external factory RTCIceTransport();
}

extension RTCIceTransportExtension on RTCIceTransport {
  external void gather([RTCIceGatherOptions options]);
  external void start([
    RTCIceParameters remoteParameters,
    RTCIceRole role,
  ]);
  external void stop();
  external void addRemoteCandidate([RTCIceCandidateInit remoteCandidate]);
  external JSArray getLocalCandidates();
  external JSArray getRemoteCandidates();
  external RTCIceCandidatePair? getSelectedCandidatePair();
  external RTCIceParameters? getLocalParameters();
  external RTCIceParameters? getRemoteParameters();
  external set onerror(EventHandler value);
  external EventHandler get onerror;
  external set onicecandidate(EventHandler value);
  external EventHandler get onicecandidate;
  external RTCIceRole get role;
  external RTCIceComponent get component;
  external RTCIceTransportState get state;
  external RTCIceGathererState get gatheringState;
  external set onstatechange(EventHandler value);
  external EventHandler get onstatechange;
  external set ongatheringstatechange(EventHandler value);
  external EventHandler get ongatheringstatechange;
  external set onselectedcandidatepairchange(EventHandler value);
  external EventHandler get onselectedcandidatepairchange;
}

@JS()
@staticInterop
@anonymous
class RTCIceParameters {
  external factory RTCIceParameters({
    bool iceLite,
    String usernameFragment,
    String password,
  });
}

extension RTCIceParametersExtension on RTCIceParameters {
  external set iceLite(bool value);
  external bool get iceLite;
  external set usernameFragment(String value);
  external String get usernameFragment;
  external set password(String value);
  external String get password;
}

@JS()
@staticInterop
@anonymous
class RTCIceCandidatePair {
  external factory RTCIceCandidatePair({
    RTCIceCandidate local,
    RTCIceCandidate remote,
  });
}

extension RTCIceCandidatePairExtension on RTCIceCandidatePair {
  external set local(RTCIceCandidate value);
  external RTCIceCandidate get local;
  external set remote(RTCIceCandidate value);
  external RTCIceCandidate get remote;
}

@JS('RTCTrackEvent')
@staticInterop
class RTCTrackEvent implements Event {
  external factory RTCTrackEvent(
    String type,
    RTCTrackEventInit eventInitDict,
  );
}

extension RTCTrackEventExtension on RTCTrackEvent {
  external RTCRtpReceiver get receiver;
  external MediaStreamTrack get track;
  external JSArray get streams;
  external RTCRtpTransceiver get transceiver;
}

@JS()
@staticInterop
@anonymous
class RTCTrackEventInit implements EventInit {
  external factory RTCTrackEventInit({
    required RTCRtpReceiver receiver,
    required MediaStreamTrack track,
    JSArray streams,
    required RTCRtpTransceiver transceiver,
  });
}

extension RTCTrackEventInitExtension on RTCTrackEventInit {
  external set receiver(RTCRtpReceiver value);
  external RTCRtpReceiver get receiver;
  external set track(MediaStreamTrack value);
  external MediaStreamTrack get track;
  external set streams(JSArray value);
  external JSArray get streams;
  external set transceiver(RTCRtpTransceiver value);
  external RTCRtpTransceiver get transceiver;
}

@JS('RTCSctpTransport')
@staticInterop
class RTCSctpTransport implements EventTarget {}

extension RTCSctpTransportExtension on RTCSctpTransport {
  external RTCDtlsTransport get transport;
  external RTCSctpTransportState get state;
  external num get maxMessageSize;
  external int? get maxChannels;
  external set onstatechange(EventHandler value);
  external EventHandler get onstatechange;
}

@JS('RTCDataChannel')
@staticInterop
class RTCDataChannel implements EventTarget {}

extension RTCDataChannelExtension on RTCDataChannel {
  external void close();
  external void send(JSAny data);
  external RTCPriorityType get priority;
  external String get label;
  external bool get ordered;
  external int? get maxPacketLifeTime;
  external int? get maxRetransmits;
  external String get protocol;
  external bool get negotiated;
  external int? get id;
  external RTCDataChannelState get readyState;
  external int get bufferedAmount;
  external set bufferedAmountLowThreshold(int value);
  external int get bufferedAmountLowThreshold;
  external set onopen(EventHandler value);
  external EventHandler get onopen;
  external set onbufferedamountlow(EventHandler value);
  external EventHandler get onbufferedamountlow;
  external set onerror(EventHandler value);
  external EventHandler get onerror;
  external set onclosing(EventHandler value);
  external EventHandler get onclosing;
  external set onclose(EventHandler value);
  external EventHandler get onclose;
  external set onmessage(EventHandler value);
  external EventHandler get onmessage;
  external set binaryType(BinaryType value);
  external BinaryType get binaryType;
}

@JS()
@staticInterop
@anonymous
class RTCDataChannelInit {
  external factory RTCDataChannelInit({
    RTCPriorityType priority,
    bool ordered,
    int maxPacketLifeTime,
    int maxRetransmits,
    String protocol,
    bool negotiated,
    int id,
  });
}

extension RTCDataChannelInitExtension on RTCDataChannelInit {
  external set priority(RTCPriorityType value);
  external RTCPriorityType get priority;
  external set ordered(bool value);
  external bool get ordered;
  external set maxPacketLifeTime(int value);
  external int get maxPacketLifeTime;
  external set maxRetransmits(int value);
  external int get maxRetransmits;
  external set protocol(String value);
  external String get protocol;
  external set negotiated(bool value);
  external bool get negotiated;
  external set id(int value);
  external int get id;
}

@JS('RTCDataChannelEvent')
@staticInterop
class RTCDataChannelEvent implements Event {
  external factory RTCDataChannelEvent(
    String type,
    RTCDataChannelEventInit eventInitDict,
  );
}

extension RTCDataChannelEventExtension on RTCDataChannelEvent {
  external RTCDataChannel get channel;
}

@JS()
@staticInterop
@anonymous
class RTCDataChannelEventInit implements EventInit {
  external factory RTCDataChannelEventInit({required RTCDataChannel channel});
}

extension RTCDataChannelEventInitExtension on RTCDataChannelEventInit {
  external set channel(RTCDataChannel value);
  external RTCDataChannel get channel;
}

@JS('RTCDTMFSender')
@staticInterop
class RTCDTMFSender implements EventTarget {}

extension RTCDTMFSenderExtension on RTCDTMFSender {
  external void insertDTMF(
    String tones, [
    int duration,
    int interToneGap,
  ]);
  external set ontonechange(EventHandler value);
  external EventHandler get ontonechange;
  external bool get canInsertDTMF;
  external String get toneBuffer;
}

@JS('RTCDTMFToneChangeEvent')
@staticInterop
class RTCDTMFToneChangeEvent implements Event {
  external factory RTCDTMFToneChangeEvent(
    String type, [
    RTCDTMFToneChangeEventInit eventInitDict,
  ]);
}

extension RTCDTMFToneChangeEventExtension on RTCDTMFToneChangeEvent {
  external String get tone;
}

@JS()
@staticInterop
@anonymous
class RTCDTMFToneChangeEventInit implements EventInit {
  external factory RTCDTMFToneChangeEventInit({String tone});
}

extension RTCDTMFToneChangeEventInitExtension on RTCDTMFToneChangeEventInit {
  external set tone(String value);
  external String get tone;
}

@JS('RTCStatsReport')
@staticInterop
class RTCStatsReport {}

extension RTCStatsReportExtension on RTCStatsReport {}

@JS()
@staticInterop
@anonymous
class RTCStats {
  external factory RTCStats({
    required DOMHighResTimeStamp timestamp,
    required RTCStatsType type,
    required String id,
  });
}

extension RTCStatsExtension on RTCStats {
  external set timestamp(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get timestamp;
  external set type(RTCStatsType value);
  external RTCStatsType get type;
  external set id(String value);
  external String get id;
}

@JS('RTCError')
@staticInterop
class RTCError implements DOMException {
  external factory RTCError(
    RTCErrorInit init, [
    String message,
  ]);
}

extension RTCErrorExtension on RTCError {
  external int? get httpRequestStatusCode;
  external RTCErrorDetailType get errorDetail;
  external int? get sdpLineNumber;
  external int? get sctpCauseCode;
  external int? get receivedAlert;
  external int? get sentAlert;
}

@JS()
@staticInterop
@anonymous
class RTCErrorInit {
  external factory RTCErrorInit({
    int httpRequestStatusCode,
    required RTCErrorDetailType errorDetail,
    int sdpLineNumber,
    int sctpCauseCode,
    int receivedAlert,
    int sentAlert,
  });
}

extension RTCErrorInitExtension on RTCErrorInit {
  external set httpRequestStatusCode(int value);
  external int get httpRequestStatusCode;
  external set errorDetail(RTCErrorDetailType value);
  external RTCErrorDetailType get errorDetail;
  external set sdpLineNumber(int value);
  external int get sdpLineNumber;
  external set sctpCauseCode(int value);
  external int get sctpCauseCode;
  external set receivedAlert(int value);
  external int get receivedAlert;
  external set sentAlert(int value);
  external int get sentAlert;
}

@JS('RTCErrorEvent')
@staticInterop
class RTCErrorEvent implements Event {
  external factory RTCErrorEvent(
    String type,
    RTCErrorEventInit eventInitDict,
  );
}

extension RTCErrorEventExtension on RTCErrorEvent {
  external RTCError get error;
}

@JS()
@staticInterop
@anonymous
class RTCErrorEventInit implements EventInit {
  external factory RTCErrorEventInit({required RTCError error});
}

extension RTCErrorEventInitExtension on RTCErrorEventInit {
  external set error(RTCError value);
  external RTCError get error;
}
