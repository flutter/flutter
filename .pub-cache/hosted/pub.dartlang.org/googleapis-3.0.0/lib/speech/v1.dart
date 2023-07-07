// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Cloud Speech-to-Text API - v1
///
/// Converts audio to text by applying powerful neural network models.
///
/// For more information, see
/// <https://cloud.google.com/speech-to-text/docs/quickstart-protocol>
///
/// Create an instance of [SpeechApi] to access these resources:
///
/// - [OperationsResource]
/// - [SpeechResource]
library speech.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Converts audio to text by applying powerful neural network models.
class SpeechApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  OperationsResource get operations => OperationsResource(_requester);
  SpeechResource get speech => SpeechResource(_requester);

  SpeechApi(http.Client client,
      {core.String rootUrl = 'https://speech.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern `^.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/operations/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists operations that match the specified filter in the request.
  ///
  /// If the server doesn't support this method, it returns `UNIMPLEMENTED`.
  /// NOTE: the `name` binding allows API services to override the binding to
  /// use different resource name schemes, such as `users / * /operations`. To
  /// override the binding, API services can add a binding such as
  /// `"/v1/{name=users / * }/operations"` to their service configuration. For
  /// backwards compatibility, the default name includes the operations
  /// collection id, however overriding users must ensure the name binding is
  /// the parent resource, without the operations collection id.
  ///
  /// Request parameters:
  ///
  /// [filter] - The standard list filter.
  ///
  /// [name] - The name of the operation's parent resource.
  ///
  /// [pageSize] - The standard list page size.
  ///
  /// [pageToken] - The standard list page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListOperationsResponse> list({
    core.String? filter,
    core.String? name,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (name != null) 'name': [name],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SpeechResource {
  final commons.ApiRequester _requester;

  SpeechResource(commons.ApiRequester client) : _requester = client;

  /// Performs asynchronous speech recognition: receive results via the
  /// google.longrunning.Operations interface.
  ///
  /// Returns either an `Operation.error` or an `Operation.response` which
  /// contains a `LongRunningRecognizeResponse` message. For more information on
  /// asynchronous speech recognition, see the
  /// \[how-to\](https://cloud.google.com/speech-to-text/docs/async-recognize).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> longrunningrecognize(
    LongRunningRecognizeRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/speech:longrunningrecognize';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Performs synchronous speech recognition: receive results after all audio
  /// has been sent and processed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RecognizeResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RecognizeResponse> recognize(
    RecognizeRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/speech:recognize';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RecognizeResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// The response message for Operations.ListOperations.
class ListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<Operation>? operations;

  ListOperationsResponse();

  ListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<Operation>((value) =>
              Operation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// Describes the progress of a long-running `LongRunningRecognize` call.
///
/// It is included in the `metadata` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class LongRunningRecognizeMetadata {
  /// Time of the most recent processing update.
  core.String? lastUpdateTime;

  /// Approximate percentage of audio processed thus far.
  ///
  /// Guaranteed to be 100 when the audio is fully processed and the results are
  /// available.
  core.int? progressPercent;

  /// Time when the request was received.
  core.String? startTime;

  /// The URI of the audio file being transcribed.
  ///
  /// Empty if the audio was sent as byte content.
  ///
  /// Output only.
  core.String? uri;

  LongRunningRecognizeMetadata();

  LongRunningRecognizeMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdateTime')) {
      lastUpdateTime = _json['lastUpdateTime'] as core.String;
    }
    if (_json.containsKey('progressPercent')) {
      progressPercent = _json['progressPercent'] as core.int;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime!,
        if (progressPercent != null) 'progressPercent': progressPercent!,
        if (startTime != null) 'startTime': startTime!,
        if (uri != null) 'uri': uri!,
      };
}

/// The top-level message sent by the client for the `LongRunningRecognize`
/// method.
class LongRunningRecognizeRequest {
  /// The audio data to be recognized.
  ///
  /// Required.
  RecognitionAudio? audio;

  /// Provides information to the recognizer that specifies how to process the
  /// request.
  ///
  /// Required.
  RecognitionConfig? config;

  LongRunningRecognizeRequest();

  LongRunningRecognizeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('audio')) {
      audio = RecognitionAudio.fromJson(
          _json['audio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('config')) {
      config = RecognitionConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audio != null) 'audio': audio!.toJson(),
        if (config != null) 'config': config!.toJson(),
      };
}

/// The only message returned to the client by the `LongRunningRecognize`
/// method.
///
/// It contains the result as zero or more sequential `SpeechRecognitionResult`
/// messages. It is included in the `result.response` field of the `Operation`
/// returned by the `GetOperation` call of the `google::longrunning::Operations`
/// service.
class LongRunningRecognizeResponse {
  /// Sequential list of transcription results corresponding to sequential
  /// portions of audio.
  core.List<SpeechRecognitionResult>? results;

  LongRunningRecognizeResponse();

  LongRunningRecognizeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<SpeechRecognitionResult>((value) =>
              SpeechRecognitionResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class Operation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  Status? error;

  /// Service-specific metadata associated with the operation.
  ///
  /// It typically contains progress information and common metadata such as
  /// create time. Some services might not provide such metadata. Any method
  /// that returns a long-running operation should document the metadata type,
  /// if any.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// The server-assigned name, which is only unique within the same service
  /// that originally returns it.
  ///
  /// If you use the default HTTP mapping, the `name` should be a resource name
  /// ending with `operations/{unique_id}`.
  core.String? name;

  /// The normal response of the operation in case of success.
  ///
  /// If the original method returns no data on success, such as `Delete`, the
  /// response is `google.protobuf.Empty`. If the original method is standard
  /// `Get`/`Create`/`Update`, the response should be the resource. For other
  /// methods, the response should have the type `XxxResponse`, where `Xxx` is
  /// the original method name. For example, if the original method name is
  /// `TakeSnapshot()`, the inferred response type is `TakeSnapshotResponse`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? response;

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('response')) {
      response = (_json['response'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (done != null) 'done': done!,
        if (error != null) 'error': error!.toJson(),
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
        if (response != null) 'response': response!,
      };
}

/// Contains audio data in the encoding specified in the `RecognitionConfig`.
///
/// Either `content` or `uri` must be supplied. Supplying both or neither
/// returns google.rpc.Code.INVALID_ARGUMENT. See
/// [content limits](https://cloud.google.com/speech-to-text/quotas#content).
class RecognitionAudio {
  /// The audio data bytes encoded as specified in `RecognitionConfig`.
  ///
  /// Note: as with all bytes fields, proto buffers use a pure binary
  /// representation, whereas JSON representations use base64.
  core.String? content;
  core.List<core.int> get contentAsBytes => convert.base64.decode(content!);

  set contentAsBytes(core.List<core.int> _bytes) {
    content =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// URI that points to a file that contains audio data bytes as specified in
  /// `RecognitionConfig`.
  ///
  /// The file must not be compressed (for example, gzip). Currently, only
  /// Google Cloud Storage URIs are supported, which must be specified in the
  /// following format: `gs://bucket_name/object_name` (other URI formats return
  /// google.rpc.Code.INVALID_ARGUMENT). For more information, see
  /// [Request URIs](https://cloud.google.com/storage/docs/reference-uris).
  core.String? uri;

  RecognitionAudio();

  RecognitionAudio.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (uri != null) 'uri': uri!,
      };
}

/// Provides information to the recognizer that specifies how to process the
/// request.
class RecognitionConfig {
  /// The number of channels in the input audio data.
  ///
  /// ONLY set this for MULTI-CHANNEL recognition. Valid values for LINEAR16 and
  /// FLAC are `1`-`8`. Valid values for OGG_OPUS are '1'-'254'. Valid value for
  /// MULAW, AMR, AMR_WB and SPEEX_WITH_HEADER_BYTE is only `1`. If `0` or
  /// omitted, defaults to one channel (mono). Note: We only recognize the first
  /// channel by default. To perform independent recognition on each channel set
  /// `enable_separate_recognition_per_channel` to 'true'.
  core.int? audioChannelCount;

  /// Config to enable speaker diarization and set additional parameters to make
  /// diarization better suited for your application.
  ///
  /// Note: When this is enabled, we send all the words from the beginning of
  /// the audio for the top alternative in every consecutive STREAMING
  /// responses. This is done in order to improve our speaker tags as our models
  /// learn to identify the speakers in the conversation over time. For
  /// non-streaming requests, the diarization results will be provided only in
  /// the top alternative of the FINAL SpeechRecognitionResult.
  SpeakerDiarizationConfig? diarizationConfig;

  /// If 'true', adds punctuation to recognition result hypotheses.
  ///
  /// This feature is only available in select languages. Setting this for
  /// requests in other languages has no effect at all. The default 'false'
  /// value does not add punctuation to result hypotheses.
  core.bool? enableAutomaticPunctuation;

  /// This needs to be set to `true` explicitly and `audio_channel_count` > 1 to
  /// get each channel recognized separately.
  ///
  /// The recognition result will contain a `channel_tag` field to state which
  /// channel that result belongs to. If this is not true, we will only
  /// recognize the first channel. The request is billed cumulatively for all
  /// channels recognized: `audio_channel_count` multiplied by the length of the
  /// audio.
  core.bool? enableSeparateRecognitionPerChannel;

  /// If `true`, the top result includes a list of words and the start and end
  /// time offsets (timestamps) for those words.
  ///
  /// If `false`, no word-level time offset information is returned. The default
  /// is `false`.
  core.bool? enableWordTimeOffsets;

  /// Encoding of audio data sent in all `RecognitionAudio` messages.
  ///
  /// This field is optional for `FLAC` and `WAV` audio files and required for
  /// all other audio formats. For details, see AudioEncoding.
  /// Possible string values are:
  /// - "ENCODING_UNSPECIFIED" : Not specified.
  /// - "LINEAR16" : Uncompressed 16-bit signed little-endian samples (Linear
  /// PCM).
  /// - "FLAC" : `FLAC` (Free Lossless Audio Codec) is the recommended encoding
  /// because it is lossless--therefore recognition is not compromised--and
  /// requires only about half the bandwidth of `LINEAR16`. `FLAC` stream
  /// encoding supports 16-bit and 24-bit samples, however, not all fields in
  /// `STREAMINFO` are supported.
  /// - "MULAW" : 8-bit samples that compand 14-bit audio samples using G.711
  /// PCMU/mu-law.
  /// - "AMR" : Adaptive Multi-Rate Narrowband codec. `sample_rate_hertz` must
  /// be 8000.
  /// - "AMR_WB" : Adaptive Multi-Rate Wideband codec. `sample_rate_hertz` must
  /// be 16000.
  /// - "OGG_OPUS" : Opus encoded audio frames in Ogg container
  /// ([OggOpus](https://wiki.xiph.org/OggOpus)). `sample_rate_hertz` must be
  /// one of 8000, 12000, 16000, 24000, or 48000.
  /// - "SPEEX_WITH_HEADER_BYTE" : Although the use of lossy encodings is not
  /// recommended, if a very low bitrate encoding is required, `OGG_OPUS` is
  /// highly preferred over Speex encoding. The [Speex](https://speex.org/)
  /// encoding supported by Cloud Speech API has a header byte in each block, as
  /// in MIME type `audio/x-speex-with-header-byte`. It is a variant of the RTP
  /// Speex encoding defined in [RFC 5574](https://tools.ietf.org/html/rfc5574).
  /// The stream is a sequence of blocks, one block per RTP packet. Each block
  /// starts with a byte containing the length of the block, in bytes, followed
  /// by one or more frames of Speex data, padded to an integral number of bytes
  /// (octets) as specified in RFC 5574. In other words, each RTP header is
  /// replaced with a single byte containing the block length. Only Speex
  /// wideband is supported. `sample_rate_hertz` must be 16000.
  core.String? encoding;

  /// The language of the supplied audio as a
  /// \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) language tag.
  ///
  /// Example: "en-US". See
  /// [Language Support](https://cloud.google.com/speech-to-text/docs/languages)
  /// for a list of the currently supported language codes.
  ///
  /// Required.
  core.String? languageCode;

  /// Maximum number of recognition hypotheses to be returned.
  ///
  /// Specifically, the maximum number of `SpeechRecognitionAlternative`
  /// messages within each `SpeechRecognitionResult`. The server may return
  /// fewer than `max_alternatives`. Valid values are `0`-`30`. A value of `0`
  /// or `1` will return a maximum of one. If omitted, will return a maximum of
  /// one.
  core.int? maxAlternatives;

  /// Metadata regarding this request.
  RecognitionMetadata? metadata;

  /// Which model to select for the given request.
  ///
  /// Select the model best suited to your domain to get best results. If a
  /// model is not explicitly specified, then we auto-select a model based on
  /// the parameters in the RecognitionConfig. *Model* *Description*
  /// command_and_search Best for short queries such as voice commands or voice
  /// search. phone_call Best for audio that originated from a phone call
  /// (typically recorded at an 8khz sampling rate). video Best for audio that
  /// originated from video or includes multiple speakers. Ideally the audio is
  /// recorded at a 16khz or greater sampling rate. This is a premium model that
  /// costs more than the standard rate. default Best for audio that is not one
  /// of the specific audio models. For example, long-form audio. Ideally the
  /// audio is high-fidelity, recorded at a 16khz or greater sampling rate.
  core.String? model;

  /// If set to `true`, the server will attempt to filter out profanities,
  /// replacing all but the initial character in each filtered word with
  /// asterisks, e.g. "f***".
  ///
  /// If set to `false` or omitted, profanities won't be filtered out.
  core.bool? profanityFilter;

  /// Sample rate in Hertz of the audio data sent in all `RecognitionAudio`
  /// messages.
  ///
  /// Valid values are: 8000-48000. 16000 is optimal. For best results, set the
  /// sampling rate of the audio source to 16000 Hz. If that's not possible, use
  /// the native sample rate of the audio source (instead of re-sampling). This
  /// field is optional for FLAC and WAV audio files, but is required for all
  /// other audio formats. For details, see AudioEncoding.
  core.int? sampleRateHertz;

  /// Array of SpeechContext.
  ///
  /// A means to provide context to assist the speech recognition. For more
  /// information, see
  /// [speech adaptation](https://cloud.google.com/speech-to-text/docs/adaptation).
  core.List<SpeechContext>? speechContexts;

  /// Set to true to use an enhanced model for speech recognition.
  ///
  /// If `use_enhanced` is set to true and the `model` field is not set, then an
  /// appropriate enhanced model is chosen if an enhanced model exists for the
  /// audio. If `use_enhanced` is true and an enhanced version of the specified
  /// model does not exist, then the speech is recognized using the standard
  /// version of the specified model.
  core.bool? useEnhanced;

  RecognitionConfig();

  RecognitionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('audioChannelCount')) {
      audioChannelCount = _json['audioChannelCount'] as core.int;
    }
    if (_json.containsKey('diarizationConfig')) {
      diarizationConfig = SpeakerDiarizationConfig.fromJson(
          _json['diarizationConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enableAutomaticPunctuation')) {
      enableAutomaticPunctuation =
          _json['enableAutomaticPunctuation'] as core.bool;
    }
    if (_json.containsKey('enableSeparateRecognitionPerChannel')) {
      enableSeparateRecognitionPerChannel =
          _json['enableSeparateRecognitionPerChannel'] as core.bool;
    }
    if (_json.containsKey('enableWordTimeOffsets')) {
      enableWordTimeOffsets = _json['enableWordTimeOffsets'] as core.bool;
    }
    if (_json.containsKey('encoding')) {
      encoding = _json['encoding'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('maxAlternatives')) {
      maxAlternatives = _json['maxAlternatives'] as core.int;
    }
    if (_json.containsKey('metadata')) {
      metadata = RecognitionMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('profanityFilter')) {
      profanityFilter = _json['profanityFilter'] as core.bool;
    }
    if (_json.containsKey('sampleRateHertz')) {
      sampleRateHertz = _json['sampleRateHertz'] as core.int;
    }
    if (_json.containsKey('speechContexts')) {
      speechContexts = (_json['speechContexts'] as core.List)
          .map<SpeechContext>((value) => SpeechContext.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('useEnhanced')) {
      useEnhanced = _json['useEnhanced'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioChannelCount != null) 'audioChannelCount': audioChannelCount!,
        if (diarizationConfig != null)
          'diarizationConfig': diarizationConfig!.toJson(),
        if (enableAutomaticPunctuation != null)
          'enableAutomaticPunctuation': enableAutomaticPunctuation!,
        if (enableSeparateRecognitionPerChannel != null)
          'enableSeparateRecognitionPerChannel':
              enableSeparateRecognitionPerChannel!,
        if (enableWordTimeOffsets != null)
          'enableWordTimeOffsets': enableWordTimeOffsets!,
        if (encoding != null) 'encoding': encoding!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (maxAlternatives != null) 'maxAlternatives': maxAlternatives!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (model != null) 'model': model!,
        if (profanityFilter != null) 'profanityFilter': profanityFilter!,
        if (sampleRateHertz != null) 'sampleRateHertz': sampleRateHertz!,
        if (speechContexts != null)
          'speechContexts':
              speechContexts!.map((value) => value.toJson()).toList(),
        if (useEnhanced != null) 'useEnhanced': useEnhanced!,
      };
}

/// Description of audio data to be recognized.
class RecognitionMetadata {
  /// Description of the content.
  ///
  /// Eg. "Recordings of federal supreme court hearings from 2012".
  core.String? audioTopic;

  /// The industry vertical to which this speech recognition request most
  /// closely applies.
  ///
  /// This is most indicative of the topics contained in the audio. Use the
  /// 6-digit NAICS code to identify the industry vertical - see
  /// https://www.naics.com/search/.
  core.int? industryNaicsCodeOfAudio;

  /// The use case most closely describing the audio content to be recognized.
  /// Possible string values are:
  /// - "INTERACTION_TYPE_UNSPECIFIED" : Use case is either unknown or is
  /// something other than one of the other values below.
  /// - "DISCUSSION" : Multiple people in a conversation or discussion. For
  /// example in a meeting with two or more people actively participating.
  /// Typically all the primary people speaking would be in the same room (if
  /// not, see PHONE_CALL)
  /// - "PRESENTATION" : One or more persons lecturing or presenting to others,
  /// mostly uninterrupted.
  /// - "PHONE_CALL" : A phone-call or video-conference in which two or more
  /// people, who are not in the same room, are actively participating.
  /// - "VOICEMAIL" : A recorded message intended for another person to listen
  /// to.
  /// - "PROFESSIONALLY_PRODUCED" : Professionally produced audio (eg. TV Show,
  /// Podcast).
  /// - "VOICE_SEARCH" : Transcribe spoken questions and queries into text.
  /// - "VOICE_COMMAND" : Transcribe voice commands, such as for controlling a
  /// device.
  /// - "DICTATION" : Transcribe speech to text to create a written document,
  /// such as a text-message, email or report.
  core.String? interactionType;

  /// The audio type that most closely describes the audio being recognized.
  /// Possible string values are:
  /// - "MICROPHONE_DISTANCE_UNSPECIFIED" : Audio type is not known.
  /// - "NEARFIELD" : The audio was captured from a closely placed microphone.
  /// Eg. phone, dictaphone, or handheld microphone. Generally if there speaker
  /// is within 1 meter of the microphone.
  /// - "MIDFIELD" : The speaker if within 3 meters of the microphone.
  /// - "FARFIELD" : The speaker is more than 3 meters away from the microphone.
  core.String? microphoneDistance;

  /// The original media the speech was recorded on.
  /// Possible string values are:
  /// - "ORIGINAL_MEDIA_TYPE_UNSPECIFIED" : Unknown original media type.
  /// - "AUDIO" : The speech data is an audio recording.
  /// - "VIDEO" : The speech data originally recorded on a video.
  core.String? originalMediaType;

  /// Mime type of the original audio file.
  ///
  /// For example `audio/m4a`, `audio/x-alaw-basic`, `audio/mp3`, `audio/3gpp`.
  /// A list of possible audio mime types is maintained at
  /// http://www.iana.org/assignments/media-types/media-types.xhtml#audio
  core.String? originalMimeType;

  /// The device used to make the recording.
  ///
  /// Examples 'Nexus 5X' or 'Polycom SoundStation IP 6000' or 'POTS' or 'VoIP'
  /// or 'Cardioid Microphone'.
  core.String? recordingDeviceName;

  /// The type of device the speech was recorded with.
  /// Possible string values are:
  /// - "RECORDING_DEVICE_TYPE_UNSPECIFIED" : The recording device is unknown.
  /// - "SMARTPHONE" : Speech was recorded on a smartphone.
  /// - "PC" : Speech was recorded using a personal computer or tablet.
  /// - "PHONE_LINE" : Speech was recorded over a phone line.
  /// - "VEHICLE" : Speech was recorded in a vehicle.
  /// - "OTHER_OUTDOOR_DEVICE" : Speech was recorded outdoors.
  /// - "OTHER_INDOOR_DEVICE" : Speech was recorded indoors.
  core.String? recordingDeviceType;

  RecognitionMetadata();

  RecognitionMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('audioTopic')) {
      audioTopic = _json['audioTopic'] as core.String;
    }
    if (_json.containsKey('industryNaicsCodeOfAudio')) {
      industryNaicsCodeOfAudio = _json['industryNaicsCodeOfAudio'] as core.int;
    }
    if (_json.containsKey('interactionType')) {
      interactionType = _json['interactionType'] as core.String;
    }
    if (_json.containsKey('microphoneDistance')) {
      microphoneDistance = _json['microphoneDistance'] as core.String;
    }
    if (_json.containsKey('originalMediaType')) {
      originalMediaType = _json['originalMediaType'] as core.String;
    }
    if (_json.containsKey('originalMimeType')) {
      originalMimeType = _json['originalMimeType'] as core.String;
    }
    if (_json.containsKey('recordingDeviceName')) {
      recordingDeviceName = _json['recordingDeviceName'] as core.String;
    }
    if (_json.containsKey('recordingDeviceType')) {
      recordingDeviceType = _json['recordingDeviceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioTopic != null) 'audioTopic': audioTopic!,
        if (industryNaicsCodeOfAudio != null)
          'industryNaicsCodeOfAudio': industryNaicsCodeOfAudio!,
        if (interactionType != null) 'interactionType': interactionType!,
        if (microphoneDistance != null)
          'microphoneDistance': microphoneDistance!,
        if (originalMediaType != null) 'originalMediaType': originalMediaType!,
        if (originalMimeType != null) 'originalMimeType': originalMimeType!,
        if (recordingDeviceName != null)
          'recordingDeviceName': recordingDeviceName!,
        if (recordingDeviceType != null)
          'recordingDeviceType': recordingDeviceType!,
      };
}

/// The top-level message sent by the client for the `Recognize` method.
class RecognizeRequest {
  /// The audio data to be recognized.
  ///
  /// Required.
  RecognitionAudio? audio;

  /// Provides information to the recognizer that specifies how to process the
  /// request.
  ///
  /// Required.
  RecognitionConfig? config;

  RecognizeRequest();

  RecognizeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('audio')) {
      audio = RecognitionAudio.fromJson(
          _json['audio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('config')) {
      config = RecognitionConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audio != null) 'audio': audio!.toJson(),
        if (config != null) 'config': config!.toJson(),
      };
}

/// The only message returned to the client by the `Recognize` method.
///
/// It contains the result as zero or more sequential `SpeechRecognitionResult`
/// messages.
class RecognizeResponse {
  /// Sequential list of transcription results corresponding to sequential
  /// portions of audio.
  core.List<SpeechRecognitionResult>? results;

  RecognizeResponse();

  RecognizeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<SpeechRecognitionResult>((value) =>
              SpeechRecognitionResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// Config to enable speaker diarization.
class SpeakerDiarizationConfig {
  /// If 'true', enables speaker detection for each recognized word in the top
  /// alternative of the recognition result using a speaker_tag provided in the
  /// WordInfo.
  core.bool? enableSpeakerDiarization;

  /// Maximum number of speakers in the conversation.
  ///
  /// This range gives you more flexibility by allowing the system to
  /// automatically determine the correct number of speakers. If not set, the
  /// default value is 6.
  core.int? maxSpeakerCount;

  /// Minimum number of speakers in the conversation.
  ///
  /// This range gives you more flexibility by allowing the system to
  /// automatically determine the correct number of speakers. If not set, the
  /// default value is 2.
  core.int? minSpeakerCount;

  /// Unused.
  ///
  /// Output only.
  core.int? speakerTag;

  SpeakerDiarizationConfig();

  SpeakerDiarizationConfig.fromJson(core.Map _json) {
    if (_json.containsKey('enableSpeakerDiarization')) {
      enableSpeakerDiarization = _json['enableSpeakerDiarization'] as core.bool;
    }
    if (_json.containsKey('maxSpeakerCount')) {
      maxSpeakerCount = _json['maxSpeakerCount'] as core.int;
    }
    if (_json.containsKey('minSpeakerCount')) {
      minSpeakerCount = _json['minSpeakerCount'] as core.int;
    }
    if (_json.containsKey('speakerTag')) {
      speakerTag = _json['speakerTag'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableSpeakerDiarization != null)
          'enableSpeakerDiarization': enableSpeakerDiarization!,
        if (maxSpeakerCount != null) 'maxSpeakerCount': maxSpeakerCount!,
        if (minSpeakerCount != null) 'minSpeakerCount': minSpeakerCount!,
        if (speakerTag != null) 'speakerTag': speakerTag!,
      };
}

/// Provides "hints" to the speech recognizer to favor specific words and
/// phrases in the results.
class SpeechContext {
  /// A list of strings containing words and phrases "hints" so that the speech
  /// recognition is more likely to recognize them.
  ///
  /// This can be used to improve the accuracy for specific words and phrases,
  /// for example, if specific commands are typically spoken by the user. This
  /// can also be used to add additional words to the vocabulary of the
  /// recognizer. See
  /// [usage limits](https://cloud.google.com/speech-to-text/quotas#content).
  /// List items can also be set to classes for groups of words that represent
  /// common concepts that occur in natural language. For example, rather than
  /// providing phrase hints for every month of the year, using the $MONTH class
  /// improves the likelihood of correctly transcribing audio that includes
  /// months.
  core.List<core.String>? phrases;

  SpeechContext();

  SpeechContext.fromJson(core.Map _json) {
    if (_json.containsKey('phrases')) {
      phrases = (_json['phrases'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (phrases != null) 'phrases': phrases!,
      };
}

/// Alternative hypotheses (a.k.a. n-best list).
class SpeechRecognitionAlternative {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative of a non-streaming result or, of a streaming result where
  /// `is_final=true`. This field is not guaranteed to be accurate and users
  /// should not rely on it to be always provided. The default of 0.0 is a
  /// sentinel value indicating `confidence` was not set.
  core.double? confidence;

  /// Transcript text representing the words that the user spoke.
  core.String? transcript;

  /// A list of word-specific information for each recognized word.
  ///
  /// Note: When `enable_speaker_diarization` is true, you will see all the
  /// words from the beginning of the audio.
  core.List<WordInfo>? words;

  SpeechRecognitionAlternative();

  SpeechRecognitionAlternative.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('words')) {
      words = (_json['words'] as core.List)
          .map<WordInfo>((value) =>
              WordInfo.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (transcript != null) 'transcript': transcript!,
        if (words != null)
          'words': words!.map((value) => value.toJson()).toList(),
      };
}

/// A speech recognition result corresponding to a portion of the audio.
class SpeechRecognitionResult {
  /// May contain one or more recognition hypotheses (up to the maximum
  /// specified in `max_alternatives`).
  ///
  /// These alternatives are ordered in terms of accuracy, with the top (first)
  /// alternative being the most probable, as ranked by the recognizer.
  core.List<SpeechRecognitionAlternative>? alternatives;

  /// For multi-channel audio, this is the channel number corresponding to the
  /// recognized result for the audio from that channel.
  ///
  /// For audio_channel_count = N, its output values can range from '1' to 'N'.
  core.int? channelTag;

  SpeechRecognitionResult();

  SpeechRecognitionResult.fromJson(core.Map _json) {
    if (_json.containsKey('alternatives')) {
      alternatives = (_json['alternatives'] as core.List)
          .map<SpeechRecognitionAlternative>((value) =>
              SpeechRecognitionAlternative.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('channelTag')) {
      channelTag = _json['channelTag'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternatives != null)
          'alternatives': alternatives!.map((value) => value.toJson()).toList(),
        if (channelTag != null) 'channelTag': channelTag!,
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
  /// The status code, which should be an enum value of google.rpc.Code.
  core.int? code;

  /// A list of messages that carry the error details.
  ///
  /// There is a common set of message types for APIs to use.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? details;

  /// A developer-facing error message, which should be in English.
  ///
  /// Any user-facing error message should be localized and sent in the
  /// google.rpc.Status.details field, or localized by the client.
  core.String? message;

  Status();

  Status.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.int;
    }
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (details != null) 'details': details!,
        if (message != null) 'message': message!,
      };
}

/// Word-specific information for recognized words.
class WordInfo {
  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the end of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? endTime;

  /// A distinct integer value is assigned for every speaker within the audio.
  ///
  /// This field specifies which one of those speakers was detected to have
  /// spoken this word. Value ranges from '1' to diarization_speaker_count.
  /// speaker_tag is set if enable_speaker_diarization = 'true' and only in the
  /// top alternative.
  ///
  /// Output only.
  core.int? speakerTag;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the start of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? startTime;

  /// The word corresponding to this set of information.
  core.String? word;

  WordInfo();

  WordInfo.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('speakerTag')) {
      speakerTag = _json['speakerTag'] as core.int;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('word')) {
      word = _json['word'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (speakerTag != null) 'speakerTag': speakerTag!,
        if (startTime != null) 'startTime': startTime!,
        if (word != null) 'word': word!,
      };
}
