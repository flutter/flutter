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

/// Cloud Testing API - v1
///
/// Allows developers to run automated tests for their mobile applications on
/// Google infrastructure.
///
/// For more information, see <https://developers.google.com/cloud-test-lab/>
///
/// Create an instance of [TestingApi] to access these resources:
///
/// - [ApplicationDetailServiceResource]
/// - [ProjectsResource]
///   - [ProjectsTestMatricesResource]
/// - [TestEnvironmentCatalogResource]
library testing.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Allows developers to run automated tests for their mobile applications on
/// Google infrastructure.
class TestingApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View your data across Google Cloud Platform services
  static const cloudPlatformReadOnlyScope =
      'https://www.googleapis.com/auth/cloud-platform.read-only';

  final commons.ApiRequester _requester;

  ApplicationDetailServiceResource get applicationDetailService =>
      ApplicationDetailServiceResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);
  TestEnvironmentCatalogResource get testEnvironmentCatalog =>
      TestEnvironmentCatalogResource(_requester);

  TestingApi(http.Client client,
      {core.String rootUrl = 'https://testing.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ApplicationDetailServiceResource {
  final commons.ApiRequester _requester;

  ApplicationDetailServiceResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the details of an Android application APK.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetApkDetailsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetApkDetailsResponse> getApkDetails(
    FileReference request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/applicationDetailService/getApkDetails';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GetApkDetailsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsTestMatricesResource get testMatrices =>
      ProjectsTestMatricesResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsTestMatricesResource {
  final commons.ApiRequester _requester;

  ProjectsTestMatricesResource(commons.ApiRequester client)
      : _requester = client;

  /// Cancels unfinished test executions in a test matrix.
  ///
  /// This call returns immediately and cancellation proceeds asynchronously. If
  /// the matrix is already final, this operation will have no effect. May
  /// return any of the following canonical error codes: - PERMISSION_DENIED -
  /// if the user is not authorized to read project - INVALID_ARGUMENT - if the
  /// request is malformed - NOT_FOUND - if the Test Matrix does not exist
  ///
  /// Request parameters:
  ///
  /// [projectId] - Cloud project that owns the test.
  ///
  /// [testMatrixId] - Test matrix that will be canceled.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CancelTestMatrixResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CancelTestMatrixResponse> cancel(
    core.String projectId,
    core.String testMatrixId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/testMatrices/' +
        commons.escapeVariable('$testMatrixId') +
        ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return CancelTestMatrixResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates and runs a matrix of tests according to the given specifications.
  ///
  /// Unsupported environments will be returned in the state UNSUPPORTED. A test
  /// matrix is limited to use at most 2000 devices in parallel. May return any
  /// of the following canonical error codes: - PERMISSION_DENIED - if the user
  /// is not authorized to write to project - INVALID_ARGUMENT - if the request
  /// is malformed or if the matrix tries to use too many simultaneous devices.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - The GCE project under which this job will run.
  ///
  /// [requestId] - A string id used to detect duplicated requests. Ids are
  /// automatically scoped to a project, so users should ensure the ID is unique
  /// per-project. A UUID is recommended. Optional, but strongly recommended.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestMatrix].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestMatrix> create(
    TestMatrix request,
    core.String projectId, {
    core.String? requestId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (requestId != null) 'requestId': [requestId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + '/testMatrices';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestMatrix.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Checks the status of a test matrix.
  ///
  /// May return any of the following canonical error codes: - PERMISSION_DENIED
  /// - if the user is not authorized to read project - INVALID_ARGUMENT - if
  /// the request is malformed - NOT_FOUND - if the Test Matrix does not exist
  ///
  /// Request parameters:
  ///
  /// [projectId] - Cloud project that owns the test matrix.
  ///
  /// [testMatrixId] - Unique test matrix id which was assigned by the service.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestMatrix].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestMatrix> get(
    core.String projectId,
    core.String testMatrixId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' +
        commons.escapeVariable('$projectId') +
        '/testMatrices/' +
        commons.escapeVariable('$testMatrixId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TestMatrix.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TestEnvironmentCatalogResource {
  final commons.ApiRequester _requester;

  TestEnvironmentCatalogResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the catalog of supported test environments.
  ///
  /// May return any of the following canonical error codes: - INVALID_ARGUMENT
  /// - if the request is malformed - NOT_FOUND - if the environment type does
  /// not exist - INTERNAL - if an internal error occurred
  ///
  /// Request parameters:
  ///
  /// [environmentType] - Required. The type of environment that should be
  /// listed.
  /// Possible string values are:
  /// - "ENVIRONMENT_TYPE_UNSPECIFIED" : Do not use. For proto versioning only.
  /// - "ANDROID" : A device running a version of the Android OS.
  /// - "IOS" : A device running a version of iOS.
  /// - "NETWORK_CONFIGURATION" : A network configuration to use when running a
  /// test.
  /// - "PROVIDED_SOFTWARE" : The software environment provided by
  /// TestExecutionService.
  /// - "DEVICE_IP_BLOCKS" : The IP blocks used by devices in the test
  /// environment.
  ///
  /// [projectId] - For authorization, the cloud project requesting the
  /// TestEnvironmentCatalog.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestEnvironmentCatalog].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestEnvironmentCatalog> get(
    core.String environmentType, {
    core.String? projectId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (projectId != null) 'projectId': [projectId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/testEnvironmentCatalog/' +
        commons.escapeVariable('$environmentType');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TestEnvironmentCatalog.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Identifies an account and how to log into it.
class Account {
  /// An automatic google login account.
  GoogleAuto? googleAuto;

  Account();

  Account.fromJson(core.Map _json) {
    if (_json.containsKey('googleAuto')) {
      googleAuto = GoogleAuto.fromJson(
          _json['googleAuto'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (googleAuto != null) 'googleAuto': googleAuto!.toJson(),
      };
}

/// A single Android device.
class AndroidDevice {
  /// The id of the Android device to be used.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? androidModelId;

  /// The id of the Android OS version to be used.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? androidVersionId;

  /// The locale the test device used for testing.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? locale;

  /// How the device is oriented during the test.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? orientation;

  AndroidDevice();

  AndroidDevice.fromJson(core.Map _json) {
    if (_json.containsKey('androidModelId')) {
      androidModelId = _json['androidModelId'] as core.String;
    }
    if (_json.containsKey('androidVersionId')) {
      androidVersionId = _json['androidVersionId'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('orientation')) {
      orientation = _json['orientation'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidModelId != null) 'androidModelId': androidModelId!,
        if (androidVersionId != null) 'androidVersionId': androidVersionId!,
        if (locale != null) 'locale': locale!,
        if (orientation != null) 'orientation': orientation!,
      };
}

/// The currently supported Android devices.
class AndroidDeviceCatalog {
  /// The set of supported Android device models.
  core.List<AndroidModel>? models;

  /// The set of supported runtime configurations.
  AndroidRuntimeConfiguration? runtimeConfiguration;

  /// The set of supported Android OS versions.
  core.List<AndroidVersion>? versions;

  AndroidDeviceCatalog();

  AndroidDeviceCatalog.fromJson(core.Map _json) {
    if (_json.containsKey('models')) {
      models = (_json['models'] as core.List)
          .map<AndroidModel>((value) => AndroidModel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('runtimeConfiguration')) {
      runtimeConfiguration = AndroidRuntimeConfiguration.fromJson(
          _json['runtimeConfiguration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('versions')) {
      versions = (_json['versions'] as core.List)
          .map<AndroidVersion>((value) => AndroidVersion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (models != null)
          'models': models!.map((value) => value.toJson()).toList(),
        if (runtimeConfiguration != null)
          'runtimeConfiguration': runtimeConfiguration!.toJson(),
        if (versions != null)
          'versions': versions!.map((value) => value.toJson()).toList(),
      };
}

/// A list of Android device configurations in which the test is to be executed.
class AndroidDeviceList {
  /// A list of Android devices.
  ///
  /// Required.
  core.List<AndroidDevice>? androidDevices;

  AndroidDeviceList();

  AndroidDeviceList.fromJson(core.Map _json) {
    if (_json.containsKey('androidDevices')) {
      androidDevices = (_json['androidDevices'] as core.List)
          .map<AndroidDevice>((value) => AndroidDevice.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidDevices != null)
          'androidDevices':
              androidDevices!.map((value) => value.toJson()).toList(),
      };
}

/// A test of an Android application that can control an Android component
/// independently of its normal lifecycle.
///
/// Android instrumentation tests run an application APK and test APK inside the
/// same process on a virtual or physical AndroidDevice. They also specify a
/// test runner class, such as com.google.GoogleTestRunner, which can vary on
/// the specific instrumentation framework chosen. See for more information on
/// types of Android tests.
class AndroidInstrumentationTest {
  /// The APK for the application under test.
  FileReference? appApk;

  /// A multi-apk app bundle for the application under test.
  AppBundle? appBundle;

  /// The java package for the application under test.
  ///
  /// The default value is determined by examining the application's manifest.
  core.String? appPackageId;

  /// The option of whether running each test within its own invocation of
  /// instrumentation with Android Test Orchestrator or not.
  ///
  /// ** Orchestrator is only compatible with AndroidJUnitRunner version 1.0 or
  /// higher! ** Orchestrator offers the following benefits: - No shared state -
  /// Crashes are isolated - Logs are scoped per test See for more information
  /// about Android Test Orchestrator. If not set, the test will be run without
  /// the orchestrator.
  /// Possible string values are:
  /// - "ORCHESTRATOR_OPTION_UNSPECIFIED" : Default value: the server will
  /// choose the mode. Currently implies that the test will run without the
  /// orchestrator. In the future, all instrumentation tests will be run with
  /// the orchestrator. Using the orchestrator is highly encouraged because of
  /// all the benefits it offers.
  /// - "USE_ORCHESTRATOR" : Run test using orchestrator. ** Only compatible
  /// with AndroidJUnitRunner version 1.0 or higher! ** Recommended.
  /// - "DO_NOT_USE_ORCHESTRATOR" : Run test without using orchestrator.
  core.String? orchestratorOption;

  /// The option to run tests in multiple shards in parallel.
  ShardingOption? shardingOption;

  /// The APK containing the test code to be executed.
  ///
  /// Required.
  FileReference? testApk;

  /// The java package for the test to be executed.
  ///
  /// The default value is determined by examining the application's manifest.
  core.String? testPackageId;

  /// The InstrumentationTestRunner class.
  ///
  /// The default value is determined by examining the application's manifest.
  core.String? testRunnerClass;

  /// Each target must be fully qualified with the package name or class name,
  /// in one of these formats: - "package package_name" - "class
  /// package_name.class_name" - "class package_name.class_name#method_name" If
  /// empty, all targets in the module will be run.
  core.List<core.String>? testTargets;

  AndroidInstrumentationTest();

  AndroidInstrumentationTest.fromJson(core.Map _json) {
    if (_json.containsKey('appApk')) {
      appApk = FileReference.fromJson(
          _json['appApk'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appBundle')) {
      appBundle = AppBundle.fromJson(
          _json['appBundle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appPackageId')) {
      appPackageId = _json['appPackageId'] as core.String;
    }
    if (_json.containsKey('orchestratorOption')) {
      orchestratorOption = _json['orchestratorOption'] as core.String;
    }
    if (_json.containsKey('shardingOption')) {
      shardingOption = ShardingOption.fromJson(
          _json['shardingOption'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testApk')) {
      testApk = FileReference.fromJson(
          _json['testApk'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testPackageId')) {
      testPackageId = _json['testPackageId'] as core.String;
    }
    if (_json.containsKey('testRunnerClass')) {
      testRunnerClass = _json['testRunnerClass'] as core.String;
    }
    if (_json.containsKey('testTargets')) {
      testTargets = (_json['testTargets'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appApk != null) 'appApk': appApk!.toJson(),
        if (appBundle != null) 'appBundle': appBundle!.toJson(),
        if (appPackageId != null) 'appPackageId': appPackageId!,
        if (orchestratorOption != null)
          'orchestratorOption': orchestratorOption!,
        if (shardingOption != null) 'shardingOption': shardingOption!.toJson(),
        if (testApk != null) 'testApk': testApk!.toJson(),
        if (testPackageId != null) 'testPackageId': testPackageId!,
        if (testRunnerClass != null) 'testRunnerClass': testRunnerClass!,
        if (testTargets != null) 'testTargets': testTargets!,
      };
}

/// A set of Android device configuration permutations is defined by the the
/// cross-product of the given axes.
///
/// Internally, the given AndroidMatrix will be expanded into a set of
/// AndroidDevices. Only supported permutations will be instantiated. Invalid
/// permutations (e.g., incompatible models/versions) are ignored.
class AndroidMatrix {
  /// The ids of the set of Android device to be used.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.List<core.String>? androidModelIds;

  /// The ids of the set of Android OS version to be used.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.List<core.String>? androidVersionIds;

  /// The set of locales the test device will enable for testing.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.List<core.String>? locales;

  /// The set of orientations to test with.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.List<core.String>? orientations;

  AndroidMatrix();

  AndroidMatrix.fromJson(core.Map _json) {
    if (_json.containsKey('androidModelIds')) {
      androidModelIds = (_json['androidModelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('androidVersionIds')) {
      androidVersionIds = (_json['androidVersionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('locales')) {
      locales = (_json['locales'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('orientations')) {
      orientations = (_json['orientations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidModelIds != null) 'androidModelIds': androidModelIds!,
        if (androidVersionIds != null) 'androidVersionIds': androidVersionIds!,
        if (locales != null) 'locales': locales!,
        if (orientations != null) 'orientations': orientations!,
      };
}

/// A description of an Android device tests may be run on.
class AndroidModel {
  /// The company that this device is branded with.
  ///
  /// Example: "Google", "Samsung".
  core.String? brand;

  /// The name of the industrial design.
  ///
  /// This corresponds to android.os.Build.DEVICE.
  core.String? codename;

  /// Whether this device is virtual or physical.
  /// Possible string values are:
  /// - "DEVICE_FORM_UNSPECIFIED" : Do not use. For proto versioning only.
  /// - "VIRTUAL" : Android virtual device using Compute Engine native
  /// virtualization. Firebase Test Lab only.
  /// - "PHYSICAL" : Actual hardware.
  /// - "EMULATOR" : Android virtual device using emulator in nested
  /// virtualization. Equivalent to Android Studio.
  core.String? form;

  /// Whether this device is a phone, tablet, wearable, etc.
  /// Possible string values are:
  /// - "DEVICE_FORM_FACTOR_UNSPECIFIED" : Do not use. For proto versioning
  /// only.
  /// - "PHONE" : This device has the shape of a phone.
  /// - "TABLET" : This device has the shape of a tablet.
  /// - "WEARABLE" : This device has the shape of a watch or other wearable.
  core.String? formFactor;

  /// The unique opaque id for this model.
  ///
  /// Use this for invoking the TestExecutionService.
  core.String? id;

  /// True if and only if tests with this model are recorded by stitching
  /// together screenshots.
  ///
  /// See use_low_spec_video_recording in device config.
  core.bool? lowFpsVideoRecording;

  /// The manufacturer of this device.
  core.String? manufacturer;

  /// The human-readable marketing name for this device model.
  ///
  /// Examples: "Nexus 5", "Galaxy S5".
  core.String? name;

  /// Screen density in DPI.
  ///
  /// This corresponds to ro.sf.lcd_density
  core.int? screenDensity;

  /// Screen size in the horizontal (X) dimension measured in pixels.
  core.int? screenX;

  /// Screen size in the vertical (Y) dimension measured in pixels.
  core.int? screenY;

  /// The list of supported ABIs for this device.
  ///
  /// This corresponds to either android.os.Build.SUPPORTED_ABIS (for API level
  /// 21 and above) or android.os.Build.CPU_ABI/CPU_ABI2. The most preferred ABI
  /// is the first element in the list. Elements are optionally prefixed by
  /// "version_id:" (where version_id is the id of an AndroidVersion), denoting
  /// an ABI that is supported only on a particular version.
  core.List<core.String>? supportedAbis;

  /// The set of Android versions this device supports.
  core.List<core.String>? supportedVersionIds;

  /// Tags for this dimension.
  ///
  /// Examples: "default", "preview", "deprecated".
  core.List<core.String>? tags;

  /// URL of a thumbnail image (photo) of the device.
  ///
  /// e.g.
  /// https://lh3.googleusercontent.com/90WcauuJiCYABEl8U0lcZeuS5STUbf2yW...
  core.String? thumbnailUrl;

  AndroidModel();

  AndroidModel.fromJson(core.Map _json) {
    if (_json.containsKey('brand')) {
      brand = _json['brand'] as core.String;
    }
    if (_json.containsKey('codename')) {
      codename = _json['codename'] as core.String;
    }
    if (_json.containsKey('form')) {
      form = _json['form'] as core.String;
    }
    if (_json.containsKey('formFactor')) {
      formFactor = _json['formFactor'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('lowFpsVideoRecording')) {
      lowFpsVideoRecording = _json['lowFpsVideoRecording'] as core.bool;
    }
    if (_json.containsKey('manufacturer')) {
      manufacturer = _json['manufacturer'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('screenDensity')) {
      screenDensity = _json['screenDensity'] as core.int;
    }
    if (_json.containsKey('screenX')) {
      screenX = _json['screenX'] as core.int;
    }
    if (_json.containsKey('screenY')) {
      screenY = _json['screenY'] as core.int;
    }
    if (_json.containsKey('supportedAbis')) {
      supportedAbis = (_json['supportedAbis'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('supportedVersionIds')) {
      supportedVersionIds = (_json['supportedVersionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('thumbnailUrl')) {
      thumbnailUrl = _json['thumbnailUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (brand != null) 'brand': brand!,
        if (codename != null) 'codename': codename!,
        if (form != null) 'form': form!,
        if (formFactor != null) 'formFactor': formFactor!,
        if (id != null) 'id': id!,
        if (lowFpsVideoRecording != null)
          'lowFpsVideoRecording': lowFpsVideoRecording!,
        if (manufacturer != null) 'manufacturer': manufacturer!,
        if (name != null) 'name': name!,
        if (screenDensity != null) 'screenDensity': screenDensity!,
        if (screenX != null) 'screenX': screenX!,
        if (screenY != null) 'screenY': screenY!,
        if (supportedAbis != null) 'supportedAbis': supportedAbis!,
        if (supportedVersionIds != null)
          'supportedVersionIds': supportedVersionIds!,
        if (tags != null) 'tags': tags!,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl!,
      };
}

/// A test of an android application that explores the application on a virtual
/// or physical Android Device, finding culprits and crashes as it goes.
///
/// Next tag: 30
class AndroidRoboTest {
  /// The APK for the application under test.
  FileReference? appApk;

  /// A multi-apk app bundle for the application under test.
  AppBundle? appBundle;

  /// The initial activity that should be used to start the app.
  core.String? appInitialActivity;

  /// The java package for the application under test.
  ///
  /// The default value is determined by examining the application's manifest.
  core.String? appPackageId;

  /// The max depth of the traversal stack Robo can explore.
  ///
  /// Needs to be at least 2 to make Robo explore the app beyond the first
  /// activity. Default is 50.
  core.int? maxDepth;

  /// The max number of steps Robo can execute.
  ///
  /// Default is no limit.
  core.int? maxSteps;

  /// A set of directives Robo should apply during the crawl.
  ///
  /// This allows users to customize the crawl. For example, the username and
  /// password for a test account can be provided.
  core.List<RoboDirective>? roboDirectives;

  /// A JSON file with a sequence of actions Robo should perform as a prologue
  /// for the crawl.
  FileReference? roboScript;

  /// The intents used to launch the app for the crawl.
  ///
  /// If none are provided, then the main launcher activity is launched. If some
  /// are provided, then only those provided are launched (the main launcher
  /// activity must be provided explicitly).
  core.List<RoboStartingIntent>? startingIntents;

  AndroidRoboTest();

  AndroidRoboTest.fromJson(core.Map _json) {
    if (_json.containsKey('appApk')) {
      appApk = FileReference.fromJson(
          _json['appApk'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appBundle')) {
      appBundle = AppBundle.fromJson(
          _json['appBundle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appInitialActivity')) {
      appInitialActivity = _json['appInitialActivity'] as core.String;
    }
    if (_json.containsKey('appPackageId')) {
      appPackageId = _json['appPackageId'] as core.String;
    }
    if (_json.containsKey('maxDepth')) {
      maxDepth = _json['maxDepth'] as core.int;
    }
    if (_json.containsKey('maxSteps')) {
      maxSteps = _json['maxSteps'] as core.int;
    }
    if (_json.containsKey('roboDirectives')) {
      roboDirectives = (_json['roboDirectives'] as core.List)
          .map<RoboDirective>((value) => RoboDirective.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('roboScript')) {
      roboScript = FileReference.fromJson(
          _json['roboScript'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startingIntents')) {
      startingIntents = (_json['startingIntents'] as core.List)
          .map<RoboStartingIntent>((value) => RoboStartingIntent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appApk != null) 'appApk': appApk!.toJson(),
        if (appBundle != null) 'appBundle': appBundle!.toJson(),
        if (appInitialActivity != null)
          'appInitialActivity': appInitialActivity!,
        if (appPackageId != null) 'appPackageId': appPackageId!,
        if (maxDepth != null) 'maxDepth': maxDepth!,
        if (maxSteps != null) 'maxSteps': maxSteps!,
        if (roboDirectives != null)
          'roboDirectives':
              roboDirectives!.map((value) => value.toJson()).toList(),
        if (roboScript != null) 'roboScript': roboScript!.toJson(),
        if (startingIntents != null)
          'startingIntents':
              startingIntents!.map((value) => value.toJson()).toList(),
      };
}

/// Android configuration that can be selected at the time a test is run.
class AndroidRuntimeConfiguration {
  /// The set of available locales.
  core.List<Locale>? locales;

  /// The set of available orientations.
  core.List<Orientation>? orientations;

  AndroidRuntimeConfiguration();

  AndroidRuntimeConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('locales')) {
      locales = (_json['locales'] as core.List)
          .map<Locale>((value) =>
              Locale.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('orientations')) {
      orientations = (_json['orientations'] as core.List)
          .map<Orientation>((value) => Orientation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locales != null)
          'locales': locales!.map((value) => value.toJson()).toList(),
        if (orientations != null)
          'orientations': orientations!.map((value) => value.toJson()).toList(),
      };
}

/// A test of an Android Application with a Test Loop.
///
/// The intent \ will be implicitly added, since Games is the only user of this
/// api, for the time being.
class AndroidTestLoop {
  /// The APK for the application under test.
  FileReference? appApk;

  /// A multi-apk app bundle for the application under test.
  AppBundle? appBundle;

  /// The java package for the application under test.
  ///
  /// The default is determined by examining the application's manifest.
  core.String? appPackageId;

  /// The list of scenario labels that should be run during the test.
  ///
  /// The scenario labels should map to labels defined in the application's
  /// manifest. For example, player_experience and
  /// com.google.test.loops.player_experience add all of the loops labeled in
  /// the manifest with the com.google.test.loops.player_experience name to the
  /// execution. Scenarios can also be specified in the scenarios field.
  core.List<core.String>? scenarioLabels;

  /// The list of scenarios that should be run during the test.
  ///
  /// The default is all test loops, derived from the application's manifest.
  core.List<core.int>? scenarios;

  AndroidTestLoop();

  AndroidTestLoop.fromJson(core.Map _json) {
    if (_json.containsKey('appApk')) {
      appApk = FileReference.fromJson(
          _json['appApk'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appBundle')) {
      appBundle = AppBundle.fromJson(
          _json['appBundle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appPackageId')) {
      appPackageId = _json['appPackageId'] as core.String;
    }
    if (_json.containsKey('scenarioLabels')) {
      scenarioLabels = (_json['scenarioLabels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('scenarios')) {
      scenarios = (_json['scenarios'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appApk != null) 'appApk': appApk!.toJson(),
        if (appBundle != null) 'appBundle': appBundle!.toJson(),
        if (appPackageId != null) 'appPackageId': appPackageId!,
        if (scenarioLabels != null) 'scenarioLabels': scenarioLabels!,
        if (scenarios != null) 'scenarios': scenarios!,
      };
}

/// A version of the Android OS.
class AndroidVersion {
  /// The API level for this Android version.
  ///
  /// Examples: 18, 19.
  core.int? apiLevel;

  /// The code name for this Android version.
  ///
  /// Examples: "JellyBean", "KitKat".
  core.String? codeName;

  /// Market share for this version.
  Distribution? distribution;

  /// An opaque id for this Android version.
  ///
  /// Use this id to invoke the TestExecutionService.
  core.String? id;

  /// The date this Android version became available in the market.
  Date? releaseDate;

  /// Tags for this dimension.
  ///
  /// Examples: "default", "preview", "deprecated".
  core.List<core.String>? tags;

  /// A string representing this version of the Android OS.
  ///
  /// Examples: "4.3", "4.4".
  core.String? versionString;

  AndroidVersion();

  AndroidVersion.fromJson(core.Map _json) {
    if (_json.containsKey('apiLevel')) {
      apiLevel = _json['apiLevel'] as core.int;
    }
    if (_json.containsKey('codeName')) {
      codeName = _json['codeName'] as core.String;
    }
    if (_json.containsKey('distribution')) {
      distribution = Distribution.fromJson(
          _json['distribution'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('releaseDate')) {
      releaseDate = Date.fromJson(
          _json['releaseDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('versionString')) {
      versionString = _json['versionString'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiLevel != null) 'apiLevel': apiLevel!,
        if (codeName != null) 'codeName': codeName!,
        if (distribution != null) 'distribution': distribution!.toJson(),
        if (id != null) 'id': id!,
        if (releaseDate != null) 'releaseDate': releaseDate!.toJson(),
        if (tags != null) 'tags': tags!,
        if (versionString != null) 'versionString': versionString!,
      };
}

/// An Android package file to install.
class Apk {
  /// The path to an APK to be installed on the device before the test begins.
  FileReference? location;

  /// The java package for the APK to be installed.
  ///
  /// Value is determined by examining the application's manifest.
  core.String? packageName;

  Apk();

  Apk.fromJson(core.Map _json) {
    if (_json.containsKey('location')) {
      location = FileReference.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (location != null) 'location': location!.toJson(),
        if (packageName != null) 'packageName': packageName!,
      };
}

/// Android application details based on application manifest and apk archive
/// contents.
class ApkDetail {
  ApkManifest? apkManifest;

  ApkDetail();

  ApkDetail.fromJson(core.Map _json) {
    if (_json.containsKey('apkManifest')) {
      apkManifest = ApkManifest.fromJson(
          _json['apkManifest'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apkManifest != null) 'apkManifest': apkManifest!.toJson(),
      };
}

/// An Android app manifest.
///
/// See http://developer.android.com/guide/topics/manifest/manifest-intro.html
class ApkManifest {
  /// User-readable name for the application.
  core.String? applicationLabel;
  core.List<IntentFilter>? intentFilters;

  /// Maximum API level on which the application is designed to run.
  core.int? maxSdkVersion;

  /// Minimum API level required for the application to run.
  core.int? minSdkVersion;

  /// Full Java-style package name for this application, e.g. "com.example.foo".
  core.String? packageName;

  /// Specifies the API Level on which the application is designed to run.
  core.int? targetSdkVersion;

  /// Permissions declared to be used by the application
  core.List<core.String>? usesPermission;

  ApkManifest();

  ApkManifest.fromJson(core.Map _json) {
    if (_json.containsKey('applicationLabel')) {
      applicationLabel = _json['applicationLabel'] as core.String;
    }
    if (_json.containsKey('intentFilters')) {
      intentFilters = (_json['intentFilters'] as core.List)
          .map<IntentFilter>((value) => IntentFilter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('maxSdkVersion')) {
      maxSdkVersion = _json['maxSdkVersion'] as core.int;
    }
    if (_json.containsKey('minSdkVersion')) {
      minSdkVersion = _json['minSdkVersion'] as core.int;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('targetSdkVersion')) {
      targetSdkVersion = _json['targetSdkVersion'] as core.int;
    }
    if (_json.containsKey('usesPermission')) {
      usesPermission = (_json['usesPermission'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationLabel != null) 'applicationLabel': applicationLabel!,
        if (intentFilters != null)
          'intentFilters':
              intentFilters!.map((value) => value.toJson()).toList(),
        if (maxSdkVersion != null) 'maxSdkVersion': maxSdkVersion!,
        if (minSdkVersion != null) 'minSdkVersion': minSdkVersion!,
        if (packageName != null) 'packageName': packageName!,
        if (targetSdkVersion != null) 'targetSdkVersion': targetSdkVersion!,
        if (usesPermission != null) 'usesPermission': usesPermission!,
      };
}

/// An Android App Bundle file format, containing a BundleConfig.pb file, a base
/// module directory, zero or more dynamic feature module directories.
///
/// See https://developer.android.com/guide/app-bundle/build for guidance on
/// building App Bundles.
class AppBundle {
  /// .aab file representing the app bundle under test.
  FileReference? bundleLocation;

  AppBundle();

  AppBundle.fromJson(core.Map _json) {
    if (_json.containsKey('bundleLocation')) {
      bundleLocation = FileReference.fromJson(
          _json['bundleLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bundleLocation != null) 'bundleLocation': bundleLocation!.toJson(),
      };
}

/// Response containing the current state of the specified test matrix.
class CancelTestMatrixResponse {
  /// The current rolled-up state of the test matrix.
  ///
  /// If this state is already final, then the cancelation request will have no
  /// effect.
  /// Possible string values are:
  /// - "TEST_STATE_UNSPECIFIED" : Do not use. For proto versioning only.
  /// - "VALIDATING" : The execution or matrix is being validated.
  /// - "PENDING" : The execution or matrix is waiting for resources to become
  /// available.
  /// - "RUNNING" : The execution is currently being processed. Can only be set
  /// on an execution.
  /// - "FINISHED" : The execution or matrix has terminated normally. On a
  /// matrix this means that the matrix level processing completed normally, but
  /// individual executions may be in an ERROR state.
  /// - "ERROR" : The execution or matrix has stopped because it encountered an
  /// infrastructure failure.
  /// - "UNSUPPORTED_ENVIRONMENT" : The execution was not run because it
  /// corresponds to a unsupported environment. Can only be set on an execution.
  /// - "INCOMPATIBLE_ENVIRONMENT" : The execution was not run because the
  /// provided inputs are incompatible with the requested environment. Example:
  /// requested AndroidVersion is lower than APK's minSdkVersion Can only be set
  /// on an execution.
  /// - "INCOMPATIBLE_ARCHITECTURE" : The execution was not run because the
  /// provided inputs are incompatible with the requested architecture. Example:
  /// requested device does not support running the native code in the supplied
  /// APK Can only be set on an execution.
  /// - "CANCELLED" : The user cancelled the execution. Can only be set on an
  /// execution.
  /// - "INVALID" : The execution or matrix was not run because the provided
  /// inputs are not valid. Examples: input file is not of the expected type, is
  /// malformed/corrupt, or was flagged as malware
  core.String? testState;

  CancelTestMatrixResponse();

  CancelTestMatrixResponse.fromJson(core.Map _json) {
    if (_json.containsKey('testState')) {
      testState = _json['testState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (testState != null) 'testState': testState!,
      };
}

/// Information about the client which invoked the test.
class ClientInfo {
  /// The list of detailed information about client.
  core.List<ClientInfoDetail>? clientInfoDetails;

  /// Client name, such as gcloud.
  ///
  /// Required.
  core.String? name;

  ClientInfo();

  ClientInfo.fromJson(core.Map _json) {
    if (_json.containsKey('clientInfoDetails')) {
      clientInfoDetails = (_json['clientInfoDetails'] as core.List)
          .map<ClientInfoDetail>((value) => ClientInfoDetail.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientInfoDetails != null)
          'clientInfoDetails':
              clientInfoDetails!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
      };
}

/// Key-value pair of detailed information about the client which invoked the
/// test.
///
/// Examples: {'Version', '1.0'}, {'Release Track', 'BETA'}.
class ClientInfoDetail {
  /// The key of detailed client information.
  ///
  /// Required.
  core.String? key;

  /// The value of detailed client information.
  ///
  /// Required.
  core.String? value;

  ClientInfoDetail();

  ClientInfoDetail.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

/// Represents a whole or partial calendar date, such as a birthday.
///
/// The time of day and time zone are either specified elsewhere or are
/// insignificant. The date is relative to the Gregorian Calendar. This can
/// represent one of the following: * A full date, with non-zero year, month,
/// and day values * A month and day value, with a zero year, such as an
/// anniversary * A year on its own, with zero month and day values * A year and
/// month value, with a zero day, such as a credit card expiration date Related
/// types are google.type.TimeOfDay and `google.protobuf.Timestamp`.
class Date {
  /// Day of a month.
  ///
  /// Must be from 1 to 31 and valid for the year and month, or 0 to specify a
  /// year by itself or a year and month where the day isn't significant.
  core.int? day;

  /// Month of a year.
  ///
  /// Must be from 1 to 12, or 0 to specify a year without a month and day.
  core.int? month;

  /// Year of the date.
  ///
  /// Must be from 1 to 9999, or 0 to specify a date without a year.
  core.int? year;

  Date();

  Date.fromJson(core.Map _json) {
    if (_json.containsKey('day')) {
      day = _json['day'] as core.int;
    }
    if (_json.containsKey('month')) {
      month = _json['month'] as core.int;
    }
    if (_json.containsKey('year')) {
      year = _json['year'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (day != null) 'day': day!,
        if (month != null) 'month': month!,
        if (year != null) 'year': year!,
      };
}

/// A single device file description.
class DeviceFile {
  /// A reference to an opaque binary blob file.
  ObbFile? obbFile;

  /// A reference to a regular file.
  RegularFile? regularFile;

  DeviceFile();

  DeviceFile.fromJson(core.Map _json) {
    if (_json.containsKey('obbFile')) {
      obbFile = ObbFile.fromJson(
          _json['obbFile'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('regularFile')) {
      regularFile = RegularFile.fromJson(
          _json['regularFile'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (obbFile != null) 'obbFile': obbFile!.toJson(),
        if (regularFile != null) 'regularFile': regularFile!.toJson(),
      };
}

/// A single device IP block
class DeviceIpBlock {
  /// The date this block was added to Firebase Test Lab
  Date? addedDate;

  /// An IP address block in CIDR notation eg: 34.68.194.64/29
  core.String? block;

  /// Whether this block is used by physical or virtual devices
  /// Possible string values are:
  /// - "DEVICE_FORM_UNSPECIFIED" : Do not use. For proto versioning only.
  /// - "VIRTUAL" : Android virtual device using Compute Engine native
  /// virtualization. Firebase Test Lab only.
  /// - "PHYSICAL" : Actual hardware.
  /// - "EMULATOR" : Android virtual device using emulator in nested
  /// virtualization. Equivalent to Android Studio.
  core.String? form;

  DeviceIpBlock();

  DeviceIpBlock.fromJson(core.Map _json) {
    if (_json.containsKey('addedDate')) {
      addedDate = Date.fromJson(
          _json['addedDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('block')) {
      block = _json['block'] as core.String;
    }
    if (_json.containsKey('form')) {
      form = _json['form'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addedDate != null) 'addedDate': addedDate!.toJson(),
        if (block != null) 'block': block!,
        if (form != null) 'form': form!,
      };
}

/// List of IP blocks used by the Firebase Test Lab
class DeviceIpBlockCatalog {
  /// The device IP blocks used by Firebase Test Lab
  core.List<DeviceIpBlock>? ipBlocks;

  DeviceIpBlockCatalog();

  DeviceIpBlockCatalog.fromJson(core.Map _json) {
    if (_json.containsKey('ipBlocks')) {
      ipBlocks = (_json['ipBlocks'] as core.List)
          .map<DeviceIpBlock>((value) => DeviceIpBlock.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ipBlocks != null)
          'ipBlocks': ipBlocks!.map((value) => value.toJson()).toList(),
      };
}

/// Data about the relative number of devices running a given configuration of
/// the Android platform.
class Distribution {
  /// The estimated fraction (0-1) of the total market with this configuration.
  ///
  /// Output only.
  core.double? marketShare;

  /// The time this distribution was measured.
  ///
  /// Output only.
  core.String? measurementTime;

  Distribution();

  Distribution.fromJson(core.Map _json) {
    if (_json.containsKey('marketShare')) {
      marketShare = (_json['marketShare'] as core.num).toDouble();
    }
    if (_json.containsKey('measurementTime')) {
      measurementTime = _json['measurementTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (marketShare != null) 'marketShare': marketShare!,
        if (measurementTime != null) 'measurementTime': measurementTime!,
      };
}

/// The environment in which the test is run.
class Environment {
  /// An Android device which must be used with an Android test.
  AndroidDevice? androidDevice;

  /// An iOS device which must be used with an iOS test.
  IosDevice? iosDevice;

  Environment();

  Environment.fromJson(core.Map _json) {
    if (_json.containsKey('androidDevice')) {
      androidDevice = AndroidDevice.fromJson(
          _json['androidDevice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iosDevice')) {
      iosDevice = IosDevice.fromJson(
          _json['iosDevice'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidDevice != null) 'androidDevice': androidDevice!.toJson(),
        if (iosDevice != null) 'iosDevice': iosDevice!.toJson(),
      };
}

/// The matrix of environments in which the test is to be executed.
class EnvironmentMatrix {
  /// A list of Android devices; the test will be run only on the specified
  /// devices.
  AndroidDeviceList? androidDeviceList;

  /// A matrix of Android devices.
  AndroidMatrix? androidMatrix;

  /// A list of iOS devices.
  IosDeviceList? iosDeviceList;

  EnvironmentMatrix();

  EnvironmentMatrix.fromJson(core.Map _json) {
    if (_json.containsKey('androidDeviceList')) {
      androidDeviceList = AndroidDeviceList.fromJson(
          _json['androidDeviceList'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('androidMatrix')) {
      androidMatrix = AndroidMatrix.fromJson(
          _json['androidMatrix'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iosDeviceList')) {
      iosDeviceList = IosDeviceList.fromJson(
          _json['iosDeviceList'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidDeviceList != null)
          'androidDeviceList': androidDeviceList!.toJson(),
        if (androidMatrix != null) 'androidMatrix': androidMatrix!.toJson(),
        if (iosDeviceList != null) 'iosDeviceList': iosDeviceList!.toJson(),
      };
}

/// A key-value pair passed as an environment variable to the test.
class EnvironmentVariable {
  /// Key for the environment variable.
  core.String? key;

  /// Value for the environment variable.
  core.String? value;

  EnvironmentVariable();

  EnvironmentVariable.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

/// A reference to a file, used for user inputs.
class FileReference {
  /// A path to a file in Google Cloud Storage.
  ///
  /// Example: gs://build-app-1414623860166/app%40debug-unaligned.apk These
  /// paths are expected to be url encoded (percent encoding)
  core.String? gcsPath;

  FileReference();

  FileReference.fromJson(core.Map _json) {
    if (_json.containsKey('gcsPath')) {
      gcsPath = _json['gcsPath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsPath != null) 'gcsPath': gcsPath!,
      };
}

/// Response containing the details of the specified Android application APK.
class GetApkDetailsResponse {
  /// Details of the Android APK.
  ApkDetail? apkDetail;

  GetApkDetailsResponse();

  GetApkDetailsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('apkDetail')) {
      apkDetail = ApkDetail.fromJson(
          _json['apkDetail'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apkDetail != null) 'apkDetail': apkDetail!.toJson(),
      };
}

/// Enables automatic Google account login.
///
/// If set, the service automatically generates a Google test account and adds
/// it to the device, before executing the test. Note that test accounts might
/// be reused. Many applications show their full set of functionalities when an
/// account is present on the device. Logging into the device with these
/// generated accounts allows testing more functionalities.
class GoogleAuto {
  GoogleAuto();

  GoogleAuto.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A storage location within Google cloud storage (GCS).
class GoogleCloudStorage {
  /// The path to a directory in GCS that will eventually contain the results
  /// for this test.
  ///
  /// The requesting user must have write access on the bucket in the supplied
  /// path.
  ///
  /// Required.
  core.String? gcsPath;

  GoogleCloudStorage();

  GoogleCloudStorage.fromJson(core.Map _json) {
    if (_json.containsKey('gcsPath')) {
      gcsPath = _json['gcsPath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gcsPath != null) 'gcsPath': gcsPath!,
      };
}

/// The section of an tag.
///
/// https://developer.android.com/guide/topics/manifest/intent-filter-element.html
class IntentFilter {
  /// The android:name value of the tag.
  core.List<core.String>? actionNames;

  /// The android:name value of the tag.
  core.List<core.String>? categoryNames;

  /// The android:mimeType value of the tag.
  core.String? mimeType;

  IntentFilter();

  IntentFilter.fromJson(core.Map _json) {
    if (_json.containsKey('actionNames')) {
      actionNames = (_json['actionNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('categoryNames')) {
      categoryNames = (_json['categoryNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actionNames != null) 'actionNames': actionNames!,
        if (categoryNames != null) 'categoryNames': categoryNames!,
        if (mimeType != null) 'mimeType': mimeType!,
      };
}

/// A single iOS device.
class IosDevice {
  /// The id of the iOS device to be used.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? iosModelId;

  /// The id of the iOS major software version to be used.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? iosVersionId;

  /// The locale the test device used for testing.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? locale;

  /// How the device is oriented during the test.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options.
  ///
  /// Required.
  core.String? orientation;

  IosDevice();

  IosDevice.fromJson(core.Map _json) {
    if (_json.containsKey('iosModelId')) {
      iosModelId = _json['iosModelId'] as core.String;
    }
    if (_json.containsKey('iosVersionId')) {
      iosVersionId = _json['iosVersionId'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('orientation')) {
      orientation = _json['orientation'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iosModelId != null) 'iosModelId': iosModelId!,
        if (iosVersionId != null) 'iosVersionId': iosVersionId!,
        if (locale != null) 'locale': locale!,
        if (orientation != null) 'orientation': orientation!,
      };
}

/// The currently supported iOS devices.
class IosDeviceCatalog {
  /// The set of supported iOS device models.
  core.List<IosModel>? models;

  /// The set of supported runtime configurations.
  IosRuntimeConfiguration? runtimeConfiguration;

  /// The set of supported iOS software versions.
  core.List<IosVersion>? versions;

  /// The set of supported Xcode versions.
  core.List<XcodeVersion>? xcodeVersions;

  IosDeviceCatalog();

  IosDeviceCatalog.fromJson(core.Map _json) {
    if (_json.containsKey('models')) {
      models = (_json['models'] as core.List)
          .map<IosModel>((value) =>
              IosModel.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('runtimeConfiguration')) {
      runtimeConfiguration = IosRuntimeConfiguration.fromJson(
          _json['runtimeConfiguration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('versions')) {
      versions = (_json['versions'] as core.List)
          .map<IosVersion>((value) =>
              IosVersion.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('xcodeVersions')) {
      xcodeVersions = (_json['xcodeVersions'] as core.List)
          .map<XcodeVersion>((value) => XcodeVersion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (models != null)
          'models': models!.map((value) => value.toJson()).toList(),
        if (runtimeConfiguration != null)
          'runtimeConfiguration': runtimeConfiguration!.toJson(),
        if (versions != null)
          'versions': versions!.map((value) => value.toJson()).toList(),
        if (xcodeVersions != null)
          'xcodeVersions':
              xcodeVersions!.map((value) => value.toJson()).toList(),
      };
}

/// A file or directory to install on the device before the test starts.
class IosDeviceFile {
  /// The bundle id of the app where this file lives.
  ///
  /// iOS apps sandbox their own filesystem, so app files must specify which app
  /// installed on the device.
  core.String? bundleId;

  /// The source file
  FileReference? content;

  /// Location of the file on the device, inside the app's sandboxed filesystem
  core.String? devicePath;

  IosDeviceFile();

  IosDeviceFile.fromJson(core.Map _json) {
    if (_json.containsKey('bundleId')) {
      bundleId = _json['bundleId'] as core.String;
    }
    if (_json.containsKey('content')) {
      content = FileReference.fromJson(
          _json['content'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('devicePath')) {
      devicePath = _json['devicePath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bundleId != null) 'bundleId': bundleId!,
        if (content != null) 'content': content!.toJson(),
        if (devicePath != null) 'devicePath': devicePath!,
      };
}

/// A list of iOS device configurations in which the test is to be executed.
class IosDeviceList {
  /// A list of iOS devices.
  ///
  /// Required.
  core.List<IosDevice>? iosDevices;

  IosDeviceList();

  IosDeviceList.fromJson(core.Map _json) {
    if (_json.containsKey('iosDevices')) {
      iosDevices = (_json['iosDevices'] as core.List)
          .map<IosDevice>((value) =>
              IosDevice.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iosDevices != null)
          'iosDevices': iosDevices!.map((value) => value.toJson()).toList(),
      };
}

/// A description of an iOS device tests may be run on.
class IosModel {
  /// Device capabilities.
  ///
  /// Copied from
  /// https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/DeviceCompatibilityMatrix/DeviceCompatibilityMatrix.html
  core.List<core.String>? deviceCapabilities;

  /// Whether this device is a phone, tablet, wearable, etc.
  /// Possible string values are:
  /// - "DEVICE_FORM_FACTOR_UNSPECIFIED" : Do not use. For proto versioning
  /// only.
  /// - "PHONE" : This device has the shape of a phone.
  /// - "TABLET" : This device has the shape of a tablet.
  /// - "WEARABLE" : This device has the shape of a watch or other wearable.
  core.String? formFactor;

  /// The unique opaque id for this model.
  ///
  /// Use this for invoking the TestExecutionService.
  core.String? id;

  /// The human-readable name for this device model.
  ///
  /// Examples: "iPhone 4s", "iPad Mini 2".
  core.String? name;

  /// Screen density in DPI.
  core.int? screenDensity;

  /// Screen size in the horizontal (X) dimension measured in pixels.
  core.int? screenX;

  /// Screen size in the vertical (Y) dimension measured in pixels.
  core.int? screenY;

  /// The set of iOS major software versions this device supports.
  core.List<core.String>? supportedVersionIds;

  /// Tags for this dimension.
  ///
  /// Examples: "default", "preview", "deprecated".
  core.List<core.String>? tags;

  IosModel();

  IosModel.fromJson(core.Map _json) {
    if (_json.containsKey('deviceCapabilities')) {
      deviceCapabilities = (_json['deviceCapabilities'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('formFactor')) {
      formFactor = _json['formFactor'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('screenDensity')) {
      screenDensity = _json['screenDensity'] as core.int;
    }
    if (_json.containsKey('screenX')) {
      screenX = _json['screenX'] as core.int;
    }
    if (_json.containsKey('screenY')) {
      screenY = _json['screenY'] as core.int;
    }
    if (_json.containsKey('supportedVersionIds')) {
      supportedVersionIds = (_json['supportedVersionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceCapabilities != null)
          'deviceCapabilities': deviceCapabilities!,
        if (formFactor != null) 'formFactor': formFactor!,
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (screenDensity != null) 'screenDensity': screenDensity!,
        if (screenX != null) 'screenX': screenX!,
        if (screenY != null) 'screenY': screenY!,
        if (supportedVersionIds != null)
          'supportedVersionIds': supportedVersionIds!,
        if (tags != null) 'tags': tags!,
      };
}

/// iOS configuration that can be selected at the time a test is run.
class IosRuntimeConfiguration {
  /// The set of available locales.
  core.List<Locale>? locales;

  /// The set of available orientations.
  core.List<Orientation>? orientations;

  IosRuntimeConfiguration();

  IosRuntimeConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('locales')) {
      locales = (_json['locales'] as core.List)
          .map<Locale>((value) =>
              Locale.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('orientations')) {
      orientations = (_json['orientations'] as core.List)
          .map<Orientation>((value) => Orientation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locales != null)
          'locales': locales!.map((value) => value.toJson()).toList(),
        if (orientations != null)
          'orientations': orientations!.map((value) => value.toJson()).toList(),
      };
}

/// A test of an iOS application that implements one or more game loop
/// scenarios.
///
/// This test type accepts an archived application (.ipa file) and a list of
/// integer scenarios that will be executed on the app sequentially.
class IosTestLoop {
  /// The bundle id for the application under test.
  ///
  /// Output only.
  core.String? appBundleId;

  /// The .ipa of the application to test.
  ///
  /// Required.
  FileReference? appIpa;

  /// The list of scenarios that should be run during the test.
  ///
  /// Defaults to the single scenario 0 if unspecified.
  core.List<core.int>? scenarios;

  IosTestLoop();

  IosTestLoop.fromJson(core.Map _json) {
    if (_json.containsKey('appBundleId')) {
      appBundleId = _json['appBundleId'] as core.String;
    }
    if (_json.containsKey('appIpa')) {
      appIpa = FileReference.fromJson(
          _json['appIpa'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scenarios')) {
      scenarios = (_json['scenarios'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appBundleId != null) 'appBundleId': appBundleId!,
        if (appIpa != null) 'appIpa': appIpa!.toJson(),
        if (scenarios != null) 'scenarios': scenarios!,
      };
}

/// A description of how to set up an iOS device prior to running the test.
class IosTestSetup {
  /// iOS apps to install in addition to those being directly tested.
  core.List<FileReference>? additionalIpas;

  /// The network traffic profile used for running the test.
  ///
  /// Available network profiles can be queried by using the
  /// NETWORK_CONFIGURATION environment type when calling
  /// TestEnvironmentDiscoveryService.GetTestEnvironmentCatalog.
  core.String? networkProfile;

  /// List of directories on the device to upload to Cloud Storage at the end of
  /// the test.
  ///
  /// Directories should either be in a shared directory (e.g.
  /// /private/var/mobile/Media) or within an accessible directory inside the
  /// app's filesystem (e.g. /Documents) by specifying the bundle id.
  core.List<IosDeviceFile>? pullDirectories;

  /// List of files to push to the device before starting the test.
  core.List<IosDeviceFile>? pushFiles;

  IosTestSetup();

  IosTestSetup.fromJson(core.Map _json) {
    if (_json.containsKey('additionalIpas')) {
      additionalIpas = (_json['additionalIpas'] as core.List)
          .map<FileReference>((value) => FileReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('networkProfile')) {
      networkProfile = _json['networkProfile'] as core.String;
    }
    if (_json.containsKey('pullDirectories')) {
      pullDirectories = (_json['pullDirectories'] as core.List)
          .map<IosDeviceFile>((value) => IosDeviceFile.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pushFiles')) {
      pushFiles = (_json['pushFiles'] as core.List)
          .map<IosDeviceFile>((value) => IosDeviceFile.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalIpas != null)
          'additionalIpas':
              additionalIpas!.map((value) => value.toJson()).toList(),
        if (networkProfile != null) 'networkProfile': networkProfile!,
        if (pullDirectories != null)
          'pullDirectories':
              pullDirectories!.map((value) => value.toJson()).toList(),
        if (pushFiles != null)
          'pushFiles': pushFiles!.map((value) => value.toJson()).toList(),
      };
}

/// An iOS version.
class IosVersion {
  /// An opaque id for this iOS version.
  ///
  /// Use this id to invoke the TestExecutionService.
  core.String? id;

  /// An integer representing the major iOS version.
  ///
  /// Examples: "8", "9".
  core.int? majorVersion;

  /// An integer representing the minor iOS version.
  ///
  /// Examples: "1", "2".
  core.int? minorVersion;

  /// The available Xcode versions for this version.
  core.List<core.String>? supportedXcodeVersionIds;

  /// Tags for this dimension.
  ///
  /// Examples: "default", "preview", "deprecated".
  core.List<core.String>? tags;

  IosVersion();

  IosVersion.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('majorVersion')) {
      majorVersion = _json['majorVersion'] as core.int;
    }
    if (_json.containsKey('minorVersion')) {
      minorVersion = _json['minorVersion'] as core.int;
    }
    if (_json.containsKey('supportedXcodeVersionIds')) {
      supportedXcodeVersionIds =
          (_json['supportedXcodeVersionIds'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (majorVersion != null) 'majorVersion': majorVersion!,
        if (minorVersion != null) 'minorVersion': minorVersion!,
        if (supportedXcodeVersionIds != null)
          'supportedXcodeVersionIds': supportedXcodeVersionIds!,
        if (tags != null) 'tags': tags!,
      };
}

/// A test of an iOS application that uses the XCTest framework.
///
/// Xcode supports the option to "build for testing", which generates an
/// .xctestrun file that contains a test specification (arguments, test methods,
/// etc). This test type accepts a zip file containing the .xctestrun file and
/// the corresponding contents of the Build/Products directory that contains all
/// the binaries needed to run the tests.
class IosXcTest {
  /// The bundle id for the application under test.
  ///
  /// Output only.
  core.String? appBundleId;

  /// The option to test special app entitlements.
  ///
  /// Setting this would re-sign the app having special entitlements with an
  /// explicit application-identifier. Currently supports testing
  /// aps-environment entitlement.
  core.bool? testSpecialEntitlements;

  /// The .zip containing the .xctestrun file and the contents of the
  /// DerivedData/Build/Products directory.
  ///
  /// The .xctestrun file in this zip is ignored if the xctestrun field is
  /// specified.
  ///
  /// Required.
  FileReference? testsZip;

  /// The Xcode version that should be used for the test.
  ///
  /// Use the TestEnvironmentDiscoveryService to get supported options. Defaults
  /// to the latest Xcode version Firebase Test Lab supports.
  core.String? xcodeVersion;

  /// An .xctestrun file that will override the .xctestrun file in the tests
  /// zip.
  ///
  /// Because the .xctestrun file contains environment variables along with test
  /// methods to run and/or ignore, this can be useful for sharding tests.
  /// Default is taken from the tests zip.
  FileReference? xctestrun;

  IosXcTest();

  IosXcTest.fromJson(core.Map _json) {
    if (_json.containsKey('appBundleId')) {
      appBundleId = _json['appBundleId'] as core.String;
    }
    if (_json.containsKey('testSpecialEntitlements')) {
      testSpecialEntitlements = _json['testSpecialEntitlements'] as core.bool;
    }
    if (_json.containsKey('testsZip')) {
      testsZip = FileReference.fromJson(
          _json['testsZip'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('xcodeVersion')) {
      xcodeVersion = _json['xcodeVersion'] as core.String;
    }
    if (_json.containsKey('xctestrun')) {
      xctestrun = FileReference.fromJson(
          _json['xctestrun'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appBundleId != null) 'appBundleId': appBundleId!,
        if (testSpecialEntitlements != null)
          'testSpecialEntitlements': testSpecialEntitlements!,
        if (testsZip != null) 'testsZip': testsZip!.toJson(),
        if (xcodeVersion != null) 'xcodeVersion': xcodeVersion!,
        if (xctestrun != null) 'xctestrun': xctestrun!.toJson(),
      };
}

/// Specifies an intent that starts the main launcher activity.
class LauncherActivityIntent {
  LauncherActivityIntent();

  LauncherActivityIntent.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A location/region designation for language.
class Locale {
  /// The id for this locale.
  ///
  /// Example: "en_US".
  core.String? id;

  /// A human-friendly name for this language/locale.
  ///
  /// Example: "English".
  core.String? name;

  /// A human-friendly string representing the region for this locale.
  ///
  /// Example: "United States". Not present for every locale.
  core.String? region;

  /// Tags for this dimension.
  ///
  /// Example: "default".
  core.List<core.String>? tags;

  Locale();

  Locale.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (region != null) 'region': region!,
        if (tags != null) 'tags': tags!,
      };
}

/// Shards test cases into the specified groups of packages, classes, and/or
/// methods.
///
/// With manual sharding enabled, specifying test targets via
/// environment_variables or in InstrumentationTest is invalid.
class ManualSharding {
  /// Group of packages, classes, and/or test methods to be run for each shard.
  ///
  /// When any physical devices are selected, the number of
  /// test_targets_for_shard must be >= 1 and <= 50. When no physical devices
  /// are selected, the number must be >= 1 and <= 500.
  ///
  /// Required.
  core.List<TestTargetsForShard>? testTargetsForShard;

  ManualSharding();

  ManualSharding.fromJson(core.Map _json) {
    if (_json.containsKey('testTargetsForShard')) {
      testTargetsForShard = (_json['testTargetsForShard'] as core.List)
          .map<TestTargetsForShard>((value) => TestTargetsForShard.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (testTargetsForShard != null)
          'testTargetsForShard':
              testTargetsForShard!.map((value) => value.toJson()).toList(),
      };
}

class NetworkConfiguration {
  /// The emulation rule applying to the download traffic.
  TrafficRule? downRule;

  /// The unique opaque id for this network traffic configuration.
  core.String? id;

  /// The emulation rule applying to the upload traffic.
  TrafficRule? upRule;

  NetworkConfiguration();

  NetworkConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('downRule')) {
      downRule = TrafficRule.fromJson(
          _json['downRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('upRule')) {
      upRule = TrafficRule.fromJson(
          _json['upRule'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (downRule != null) 'downRule': downRule!.toJson(),
        if (id != null) 'id': id!,
        if (upRule != null) 'upRule': upRule!.toJson(),
      };
}

class NetworkConfigurationCatalog {
  core.List<NetworkConfiguration>? configurations;

  NetworkConfigurationCatalog();

  NetworkConfigurationCatalog.fromJson(core.Map _json) {
    if (_json.containsKey('configurations')) {
      configurations = (_json['configurations'] as core.List)
          .map<NetworkConfiguration>((value) => NetworkConfiguration.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configurations != null)
          'configurations':
              configurations!.map((value) => value.toJson()).toList(),
      };
}

/// An opaque binary blob file to install on the device before the test starts.
class ObbFile {
  /// Opaque Binary Blob (OBB) file(s) to install on the device.
  ///
  /// Required.
  FileReference? obb;

  /// OBB file name which must conform to the format as specified by Android
  /// e.g. \[main|patch\].0300110.com.example.android.obb which will be
  /// installed into \/Android/obb/\/ on the device.
  ///
  /// Required.
  core.String? obbFileName;

  ObbFile();

  ObbFile.fromJson(core.Map _json) {
    if (_json.containsKey('obb')) {
      obb = FileReference.fromJson(
          _json['obb'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('obbFileName')) {
      obbFileName = _json['obbFileName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (obb != null) 'obb': obb!.toJson(),
        if (obbFileName != null) 'obbFileName': obbFileName!,
      };
}

/// Screen orientation of the device.
class Orientation {
  /// The id for this orientation.
  ///
  /// Example: "portrait".
  core.String? id;

  /// A human-friendly name for this orientation.
  ///
  /// Example: "portrait".
  core.String? name;

  /// Tags for this dimension.
  ///
  /// Example: "default".
  core.List<core.String>? tags;

  Orientation();

  Orientation.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (tags != null) 'tags': tags!,
      };
}

/// The currently provided software environment on the devices under test.
class ProvidedSoftwareCatalog {
  /// A string representing the current version of AndroidX Test Orchestrator
  /// that is used in the environment.
  ///
  /// The package is available at
  /// https://maven.google.com/web/index.html#androidx.test:orchestrator.
  core.String? androidxOrchestratorVersion;

  /// A string representing the current version of Android Test Orchestrator
  /// that is used in the environment.
  ///
  /// The package is available at
  /// https://maven.google.com/web/index.html#com.android.support.test:orchestrator.
  core.String? orchestratorVersion;

  ProvidedSoftwareCatalog();

  ProvidedSoftwareCatalog.fromJson(core.Map _json) {
    if (_json.containsKey('androidxOrchestratorVersion')) {
      androidxOrchestratorVersion =
          _json['androidxOrchestratorVersion'] as core.String;
    }
    if (_json.containsKey('orchestratorVersion')) {
      orchestratorVersion = _json['orchestratorVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidxOrchestratorVersion != null)
          'androidxOrchestratorVersion': androidxOrchestratorVersion!,
        if (orchestratorVersion != null)
          'orchestratorVersion': orchestratorVersion!,
      };
}

/// A file or directory to install on the device before the test starts.
class RegularFile {
  /// The source file.
  ///
  /// Required.
  FileReference? content;

  /// Where to put the content on the device.
  ///
  /// Must be an absolute, allowlisted path. If the file exists, it will be
  /// replaced. The following device-side directories and any of their
  /// subdirectories are allowlisted: ${EXTERNAL_STORAGE}, /sdcard, or /storage
  /// ${ANDROID_DATA}/local/tmp, or /data/local/tmp Specifying a path outside of
  /// these directory trees is invalid. The paths /sdcard and /data will be made
  /// available and treated as implicit path substitutions. E.g. if /sdcard on a
  /// particular device does not map to external storage, the system will
  /// replace it with the external storage path prefix for that device and copy
  /// the file there. It is strongly advised to use the Environment API in app
  /// and test code to access files on the device in a portable way.
  ///
  /// Required.
  core.String? devicePath;

  RegularFile();

  RegularFile.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = FileReference.fromJson(
          _json['content'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('devicePath')) {
      devicePath = _json['devicePath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!.toJson(),
        if (devicePath != null) 'devicePath': devicePath!,
      };
}

/// Locations where the results of running the test are stored.
class ResultStorage {
  /// Required.
  GoogleCloudStorage? googleCloudStorage;

  /// URL to the results in the Firebase Web Console.
  ///
  /// Output only.
  core.String? resultsUrl;

  /// The tool results execution that results are written to.
  ///
  /// Output only.
  ToolResultsExecution? toolResultsExecution;

  /// The tool results history that contains the tool results execution that
  /// results are written to.
  ///
  /// If not provided, the service will choose an appropriate value.
  ToolResultsHistory? toolResultsHistory;

  ResultStorage();

  ResultStorage.fromJson(core.Map _json) {
    if (_json.containsKey('googleCloudStorage')) {
      googleCloudStorage = GoogleCloudStorage.fromJson(
          _json['googleCloudStorage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resultsUrl')) {
      resultsUrl = _json['resultsUrl'] as core.String;
    }
    if (_json.containsKey('toolResultsExecution')) {
      toolResultsExecution = ToolResultsExecution.fromJson(
          _json['toolResultsExecution'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('toolResultsHistory')) {
      toolResultsHistory = ToolResultsHistory.fromJson(
          _json['toolResultsHistory'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (googleCloudStorage != null)
          'googleCloudStorage': googleCloudStorage!.toJson(),
        if (resultsUrl != null) 'resultsUrl': resultsUrl!,
        if (toolResultsExecution != null)
          'toolResultsExecution': toolResultsExecution!.toJson(),
        if (toolResultsHistory != null)
          'toolResultsHistory': toolResultsHistory!.toJson(),
      };
}

/// Directs Robo to interact with a specific UI element if it is encountered
/// during the crawl.
///
/// Currently, Robo can perform text entry or element click.
class RoboDirective {
  /// The type of action that Robo should perform on the specified element.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ACTION_TYPE_UNSPECIFIED" : DO NOT USE. For proto versioning only.
  /// - "SINGLE_CLICK" : Direct Robo to click on the specified element. No-op if
  /// specified element is not clickable.
  /// - "ENTER_TEXT" : Direct Robo to enter text on the specified element. No-op
  /// if specified element is not enabled or does not allow text entry.
  /// - "IGNORE" : Direct Robo to ignore interactions with a specific element.
  core.String? actionType;

  /// The text that Robo is directed to set.
  ///
  /// If left empty, the directive will be treated as a CLICK on the element
  /// matching the resource_name.
  core.String? inputText;

  /// The android resource name of the target UI element.
  ///
  /// For example, in Java: R.string.foo in xml: @string/foo Only the "foo" part
  /// is needed. Reference doc:
  /// https://developer.android.com/guide/topics/resources/accessing-resources.html
  ///
  /// Required.
  core.String? resourceName;

  RoboDirective();

  RoboDirective.fromJson(core.Map _json) {
    if (_json.containsKey('actionType')) {
      actionType = _json['actionType'] as core.String;
    }
    if (_json.containsKey('inputText')) {
      inputText = _json['inputText'] as core.String;
    }
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actionType != null) 'actionType': actionType!,
        if (inputText != null) 'inputText': inputText!,
        if (resourceName != null) 'resourceName': resourceName!,
      };
}

/// Message for specifying the start activities to crawl.
class RoboStartingIntent {
  /// An intent that starts the main launcher activity.
  LauncherActivityIntent? launcherActivity;

  /// An intent that starts an activity with specific details.
  StartActivityIntent? startActivity;

  /// Timeout in seconds for each intent.
  core.String? timeout;

  RoboStartingIntent();

  RoboStartingIntent.fromJson(core.Map _json) {
    if (_json.containsKey('launcherActivity')) {
      launcherActivity = LauncherActivityIntent.fromJson(
          _json['launcherActivity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startActivity')) {
      startActivity = StartActivityIntent.fromJson(
          _json['startActivity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeout')) {
      timeout = _json['timeout'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (launcherActivity != null)
          'launcherActivity': launcherActivity!.toJson(),
        if (startActivity != null) 'startActivity': startActivity!.toJson(),
        if (timeout != null) 'timeout': timeout!,
      };
}

/// Details about the shard.
///
/// Output only.
class Shard {
  /// The total number of shards.
  ///
  /// Output only.
  core.int? numShards;

  /// The index of the shard among all the shards.
  ///
  /// Output only.
  core.int? shardIndex;

  /// Test targets for each shard.
  ///
  /// Output only.
  TestTargetsForShard? testTargetsForShard;

  Shard();

  Shard.fromJson(core.Map _json) {
    if (_json.containsKey('numShards')) {
      numShards = _json['numShards'] as core.int;
    }
    if (_json.containsKey('shardIndex')) {
      shardIndex = _json['shardIndex'] as core.int;
    }
    if (_json.containsKey('testTargetsForShard')) {
      testTargetsForShard = TestTargetsForShard.fromJson(
          _json['testTargetsForShard'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (numShards != null) 'numShards': numShards!,
        if (shardIndex != null) 'shardIndex': shardIndex!,
        if (testTargetsForShard != null)
          'testTargetsForShard': testTargetsForShard!.toJson(),
      };
}

/// Options for enabling sharding.
class ShardingOption {
  /// Shards test cases into the specified groups of packages, classes, and/or
  /// methods.
  ManualSharding? manualSharding;

  /// Uniformly shards test cases given a total number of shards.
  UniformSharding? uniformSharding;

  ShardingOption();

  ShardingOption.fromJson(core.Map _json) {
    if (_json.containsKey('manualSharding')) {
      manualSharding = ManualSharding.fromJson(
          _json['manualSharding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('uniformSharding')) {
      uniformSharding = UniformSharding.fromJson(
          _json['uniformSharding'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (manualSharding != null) 'manualSharding': manualSharding!.toJson(),
        if (uniformSharding != null)
          'uniformSharding': uniformSharding!.toJson(),
      };
}

/// A starting intent specified by an action, uri, and categories.
class StartActivityIntent {
  /// Action name.
  ///
  /// Required for START_ACTIVITY.
  core.String? action;

  /// Intent categories to set on the intent.
  core.List<core.String>? categories;

  /// URI for the action.
  core.String? uri;

  StartActivityIntent();

  StartActivityIntent.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('categories')) {
      categories = (_json['categories'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (categories != null) 'categories': categories!,
        if (uri != null) 'uri': uri!,
      };
}

class SystraceSetup {
  /// Systrace duration in seconds.
  ///
  /// Should be between 1 and 30 seconds. 0 disables systrace.
  core.int? durationSeconds;

  SystraceSetup();

  SystraceSetup.fromJson(core.Map _json) {
    if (_json.containsKey('durationSeconds')) {
      durationSeconds = _json['durationSeconds'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (durationSeconds != null) 'durationSeconds': durationSeconds!,
      };
}

/// Additional details about the progress of the running test.
class TestDetails {
  /// If the TestState is ERROR, then this string will contain human-readable
  /// details about the error.
  ///
  /// Output only.
  core.String? errorMessage;

  /// Human-readable, detailed descriptions of the test's progress.
  ///
  /// For example: "Provisioning a device", "Starting Test". During the course
  /// of execution new data may be appended to the end of progress_messages.
  ///
  /// Output only.
  core.List<core.String>? progressMessages;

  TestDetails();

  TestDetails.fromJson(core.Map _json) {
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('progressMessages')) {
      progressMessages = (_json['progressMessages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (progressMessages != null) 'progressMessages': progressMessages!,
      };
}

/// A description of a test environment.
class TestEnvironmentCatalog {
  /// Supported Android devices.
  AndroidDeviceCatalog? androidDeviceCatalog;

  /// The IP blocks used by devices in the test environment.
  DeviceIpBlockCatalog? deviceIpBlockCatalog;

  /// Supported iOS devices.
  IosDeviceCatalog? iosDeviceCatalog;

  /// Supported network configurations.
  NetworkConfigurationCatalog? networkConfigurationCatalog;

  /// The software test environment provided by TestExecutionService.
  ProvidedSoftwareCatalog? softwareCatalog;

  TestEnvironmentCatalog();

  TestEnvironmentCatalog.fromJson(core.Map _json) {
    if (_json.containsKey('androidDeviceCatalog')) {
      androidDeviceCatalog = AndroidDeviceCatalog.fromJson(
          _json['androidDeviceCatalog'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deviceIpBlockCatalog')) {
      deviceIpBlockCatalog = DeviceIpBlockCatalog.fromJson(
          _json['deviceIpBlockCatalog'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iosDeviceCatalog')) {
      iosDeviceCatalog = IosDeviceCatalog.fromJson(
          _json['iosDeviceCatalog'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('networkConfigurationCatalog')) {
      networkConfigurationCatalog = NetworkConfigurationCatalog.fromJson(
          _json['networkConfigurationCatalog']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('softwareCatalog')) {
      softwareCatalog = ProvidedSoftwareCatalog.fromJson(
          _json['softwareCatalog'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidDeviceCatalog != null)
          'androidDeviceCatalog': androidDeviceCatalog!.toJson(),
        if (deviceIpBlockCatalog != null)
          'deviceIpBlockCatalog': deviceIpBlockCatalog!.toJson(),
        if (iosDeviceCatalog != null)
          'iosDeviceCatalog': iosDeviceCatalog!.toJson(),
        if (networkConfigurationCatalog != null)
          'networkConfigurationCatalog': networkConfigurationCatalog!.toJson(),
        if (softwareCatalog != null)
          'softwareCatalog': softwareCatalog!.toJson(),
      };
}

/// A single test executed in a single environment.
class TestExecution {
  /// How the host machine(s) are configured.
  ///
  /// Output only.
  Environment? environment;

  /// Unique id set by the service.
  ///
  /// Output only.
  core.String? id;

  /// Id of the containing TestMatrix.
  ///
  /// Output only.
  core.String? matrixId;

  /// The cloud project that owns the test execution.
  ///
  /// Output only.
  core.String? projectId;

  /// Details about the shard.
  ///
  /// Output only.
  Shard? shard;

  /// Indicates the current progress of the test execution (e.g., FINISHED).
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TEST_STATE_UNSPECIFIED" : Do not use. For proto versioning only.
  /// - "VALIDATING" : The execution or matrix is being validated.
  /// - "PENDING" : The execution or matrix is waiting for resources to become
  /// available.
  /// - "RUNNING" : The execution is currently being processed. Can only be set
  /// on an execution.
  /// - "FINISHED" : The execution or matrix has terminated normally. On a
  /// matrix this means that the matrix level processing completed normally, but
  /// individual executions may be in an ERROR state.
  /// - "ERROR" : The execution or matrix has stopped because it encountered an
  /// infrastructure failure.
  /// - "UNSUPPORTED_ENVIRONMENT" : The execution was not run because it
  /// corresponds to a unsupported environment. Can only be set on an execution.
  /// - "INCOMPATIBLE_ENVIRONMENT" : The execution was not run because the
  /// provided inputs are incompatible with the requested environment. Example:
  /// requested AndroidVersion is lower than APK's minSdkVersion Can only be set
  /// on an execution.
  /// - "INCOMPATIBLE_ARCHITECTURE" : The execution was not run because the
  /// provided inputs are incompatible with the requested architecture. Example:
  /// requested device does not support running the native code in the supplied
  /// APK Can only be set on an execution.
  /// - "CANCELLED" : The user cancelled the execution. Can only be set on an
  /// execution.
  /// - "INVALID" : The execution or matrix was not run because the provided
  /// inputs are not valid. Examples: input file is not of the expected type, is
  /// malformed/corrupt, or was flagged as malware
  core.String? state;

  /// Additional details about the running test.
  ///
  /// Output only.
  TestDetails? testDetails;

  /// How to run the test.
  ///
  /// Output only.
  TestSpecification? testSpecification;

  /// The time this test execution was initially created.
  ///
  /// Output only.
  core.String? timestamp;

  /// Where the results for this execution are written.
  ///
  /// Output only.
  ToolResultsStep? toolResultsStep;

  TestExecution();

  TestExecution.fromJson(core.Map _json) {
    if (_json.containsKey('environment')) {
      environment = Environment.fromJson(
          _json['environment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('matrixId')) {
      matrixId = _json['matrixId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('shard')) {
      shard =
          Shard.fromJson(_json['shard'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('testDetails')) {
      testDetails = TestDetails.fromJson(
          _json['testDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testSpecification')) {
      testSpecification = TestSpecification.fromJson(
          _json['testSpecification'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
    if (_json.containsKey('toolResultsStep')) {
      toolResultsStep = ToolResultsStep.fromJson(
          _json['toolResultsStep'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environment != null) 'environment': environment!.toJson(),
        if (id != null) 'id': id!,
        if (matrixId != null) 'matrixId': matrixId!,
        if (projectId != null) 'projectId': projectId!,
        if (shard != null) 'shard': shard!.toJson(),
        if (state != null) 'state': state!,
        if (testDetails != null) 'testDetails': testDetails!.toJson(),
        if (testSpecification != null)
          'testSpecification': testSpecification!.toJson(),
        if (timestamp != null) 'timestamp': timestamp!,
        if (toolResultsStep != null)
          'toolResultsStep': toolResultsStep!.toJson(),
      };
}

/// TestMatrix captures all details about a test.
///
/// It contains the environment configuration, test specification, test
/// executions and overall state and outcome.
class TestMatrix {
  /// Information about the client which invoked the test.
  ClientInfo? clientInfo;

  /// The devices the tests are being executed on.
  ///
  /// Required.
  EnvironmentMatrix? environmentMatrix;

  /// If true, only a single attempt at most will be made to run each
  /// execution/shard in the matrix.
  ///
  /// Flaky test attempts are not affected. Normally, 2 or more attempts are
  /// made if a potential infrastructure issue is detected. This feature is for
  /// latency sensitive workloads. The incidence of execution failures may be
  /// significantly greater for fail-fast matrices and support is more limited
  /// because of that expectation.
  core.bool? failFast;

  /// The number of times a TestExecution should be re-attempted if one or more
  /// of its test cases fail for any reason.
  ///
  /// The maximum number of reruns allowed is 10. Default is 0, which implies no
  /// reruns.
  core.int? flakyTestAttempts;

  /// Describes why the matrix is considered invalid.
  ///
  /// Only useful for matrices in the INVALID state.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "INVALID_MATRIX_DETAILS_UNSPECIFIED" : Do not use. For proto versioning
  /// only.
  /// - "DETAILS_UNAVAILABLE" : The matrix is INVALID, but there are no further
  /// details available.
  /// - "MALFORMED_APK" : The input app APK could not be parsed.
  /// - "MALFORMED_TEST_APK" : The input test APK could not be parsed.
  /// - "NO_MANIFEST" : The AndroidManifest.xml could not be found.
  /// - "NO_PACKAGE_NAME" : The APK manifest does not declare a package name.
  /// - "INVALID_PACKAGE_NAME" : The APK application ID (aka package name) is
  /// invalid. See also
  /// https://developer.android.com/studio/build/application-id
  /// - "TEST_SAME_AS_APP" : The test package and app package are the same.
  /// - "NO_INSTRUMENTATION" : The test apk does not declare an instrumentation.
  /// - "NO_SIGNATURE" : The input app apk does not have a signature.
  /// - "INSTRUMENTATION_ORCHESTRATOR_INCOMPATIBLE" : The test runner class
  /// specified by user or in the test APK's manifest file is not compatible
  /// with Android Test Orchestrator. Orchestrator is only compatible with
  /// AndroidJUnitRunner version 1.0 or higher. Orchestrator can be disabled by
  /// using DO_NOT_USE_ORCHESTRATOR OrchestratorOption.
  /// - "NO_TEST_RUNNER_CLASS" : The test APK does not contain the test runner
  /// class specified by user or in the manifest file. This can be caused by
  /// either of the following reasons: - the user provided a runner class name
  /// that's incorrect, or - the test runner isn't built into the test APK
  /// (might be in the app APK instead).
  /// - "NO_LAUNCHER_ACTIVITY" : A main launcher activity could not be found.
  /// - "FORBIDDEN_PERMISSIONS" : The app declares one or more permissions that
  /// are not allowed.
  /// - "INVALID_ROBO_DIRECTIVES" : There is a conflict in the provided
  /// robo_directives.
  /// - "INVALID_RESOURCE_NAME" : There is at least one invalid resource name in
  /// the provided robo directives
  /// - "INVALID_DIRECTIVE_ACTION" : Invalid definition of action in the robo
  /// directives (e.g. a click or ignore action includes an input text field)
  /// - "TEST_LOOP_INTENT_FILTER_NOT_FOUND" : There is no test loop intent
  /// filter, or the one that is given is not formatted correctly.
  /// - "SCENARIO_LABEL_NOT_DECLARED" : The request contains a scenario label
  /// that was not declared in the manifest.
  /// - "SCENARIO_LABEL_MALFORMED" : There was an error when parsing a label's
  /// value.
  /// - "SCENARIO_NOT_DECLARED" : The request contains a scenario number that
  /// was not declared in the manifest.
  /// - "DEVICE_ADMIN_RECEIVER" : Device administrator applications are not
  /// allowed.
  /// - "MALFORMED_XC_TEST_ZIP" : The zipped XCTest was malformed. The zip did
  /// not contain a single .xctestrun file and the contents of the
  /// DerivedData/Build/Products directory.
  /// - "BUILT_FOR_IOS_SIMULATOR" : The zipped XCTest was built for the iOS
  /// simulator rather than for a physical device.
  /// - "NO_TESTS_IN_XC_TEST_ZIP" : The .xctestrun file did not specify any test
  /// targets.
  /// - "USE_DESTINATION_ARTIFACTS" : One or more of the test targets defined in
  /// the .xctestrun file specifies "UseDestinationArtifacts", which is
  /// disallowed.
  /// - "TEST_NOT_APP_HOSTED" : XC tests which run on physical devices must have
  /// "IsAppHostedTestBundle" == "true" in the xctestrun file.
  /// - "PLIST_CANNOT_BE_PARSED" : An Info.plist file in the XCTest zip could
  /// not be parsed.
  /// - "TEST_ONLY_APK" : The APK is marked as "testOnly". Deprecated and not
  /// currently used.
  /// - "MALFORMED_IPA" : The input IPA could not be parsed.
  /// - "MISSING_URL_SCHEME" : The application doesn't register the game loop
  /// URL scheme.
  /// - "MALFORMED_APP_BUNDLE" : The iOS application bundle (.app) couldn't be
  /// processed.
  /// - "NO_CODE_APK" : APK contains no code. See also
  /// https://developer.android.com/guide/topics/manifest/application-element.html#code
  /// - "INVALID_INPUT_APK" : Either the provided input APK path was malformed,
  /// the APK file does not exist, or the user does not have permission to
  /// access the APK file.
  /// - "INVALID_APK_PREVIEW_SDK" : APK is built for a preview SDK which is
  /// unsupported
  core.String? invalidMatrixDetails;

  /// The overall outcome of the test.
  ///
  /// Only set when the test matrix state is FINISHED.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "OUTCOME_SUMMARY_UNSPECIFIED" : Do not use. For proto versioning only.
  /// - "SUCCESS" : The test matrix run was successful, for instance: - All the
  /// test cases passed. - Robo did not detect a crash of the application under
  /// test.
  /// - "FAILURE" : A run failed, for instance: - One or more test case failed.
  /// - A test timed out. - The application under test crashed.
  /// - "INCONCLUSIVE" : Something unexpected happened. The run should still be
  /// considered unsuccessful but this is likely a transient problem and
  /// re-running the test might be successful.
  /// - "SKIPPED" : All tests were skipped, for instance: - All device
  /// configurations were incompatible.
  core.String? outcomeSummary;

  /// The cloud project that owns the test matrix.
  core.String? projectId;

  /// Where the results for the matrix are written.
  ///
  /// Required.
  ResultStorage? resultStorage;

  /// Indicates the current progress of the test matrix.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TEST_STATE_UNSPECIFIED" : Do not use. For proto versioning only.
  /// - "VALIDATING" : The execution or matrix is being validated.
  /// - "PENDING" : The execution or matrix is waiting for resources to become
  /// available.
  /// - "RUNNING" : The execution is currently being processed. Can only be set
  /// on an execution.
  /// - "FINISHED" : The execution or matrix has terminated normally. On a
  /// matrix this means that the matrix level processing completed normally, but
  /// individual executions may be in an ERROR state.
  /// - "ERROR" : The execution or matrix has stopped because it encountered an
  /// infrastructure failure.
  /// - "UNSUPPORTED_ENVIRONMENT" : The execution was not run because it
  /// corresponds to a unsupported environment. Can only be set on an execution.
  /// - "INCOMPATIBLE_ENVIRONMENT" : The execution was not run because the
  /// provided inputs are incompatible with the requested environment. Example:
  /// requested AndroidVersion is lower than APK's minSdkVersion Can only be set
  /// on an execution.
  /// - "INCOMPATIBLE_ARCHITECTURE" : The execution was not run because the
  /// provided inputs are incompatible with the requested architecture. Example:
  /// requested device does not support running the native code in the supplied
  /// APK Can only be set on an execution.
  /// - "CANCELLED" : The user cancelled the execution. Can only be set on an
  /// execution.
  /// - "INVALID" : The execution or matrix was not run because the provided
  /// inputs are not valid. Examples: input file is not of the expected type, is
  /// malformed/corrupt, or was flagged as malware
  core.String? state;

  /// The list of test executions that the service creates for this matrix.
  ///
  /// Output only.
  core.List<TestExecution>? testExecutions;

  /// Unique id set by the service.
  ///
  /// Output only.
  core.String? testMatrixId;

  /// How to run the test.
  ///
  /// Required.
  TestSpecification? testSpecification;

  /// The time this test matrix was initially created.
  ///
  /// Output only.
  core.String? timestamp;

  TestMatrix();

  TestMatrix.fromJson(core.Map _json) {
    if (_json.containsKey('clientInfo')) {
      clientInfo = ClientInfo.fromJson(
          _json['clientInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('environmentMatrix')) {
      environmentMatrix = EnvironmentMatrix.fromJson(
          _json['environmentMatrix'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('failFast')) {
      failFast = _json['failFast'] as core.bool;
    }
    if (_json.containsKey('flakyTestAttempts')) {
      flakyTestAttempts = _json['flakyTestAttempts'] as core.int;
    }
    if (_json.containsKey('invalidMatrixDetails')) {
      invalidMatrixDetails = _json['invalidMatrixDetails'] as core.String;
    }
    if (_json.containsKey('outcomeSummary')) {
      outcomeSummary = _json['outcomeSummary'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('resultStorage')) {
      resultStorage = ResultStorage.fromJson(
          _json['resultStorage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('testExecutions')) {
      testExecutions = (_json['testExecutions'] as core.List)
          .map<TestExecution>((value) => TestExecution.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('testMatrixId')) {
      testMatrixId = _json['testMatrixId'] as core.String;
    }
    if (_json.containsKey('testSpecification')) {
      testSpecification = TestSpecification.fromJson(
          _json['testSpecification'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
        if (environmentMatrix != null)
          'environmentMatrix': environmentMatrix!.toJson(),
        if (failFast != null) 'failFast': failFast!,
        if (flakyTestAttempts != null) 'flakyTestAttempts': flakyTestAttempts!,
        if (invalidMatrixDetails != null)
          'invalidMatrixDetails': invalidMatrixDetails!,
        if (outcomeSummary != null) 'outcomeSummary': outcomeSummary!,
        if (projectId != null) 'projectId': projectId!,
        if (resultStorage != null) 'resultStorage': resultStorage!.toJson(),
        if (state != null) 'state': state!,
        if (testExecutions != null)
          'testExecutions':
              testExecutions!.map((value) => value.toJson()).toList(),
        if (testMatrixId != null) 'testMatrixId': testMatrixId!,
        if (testSpecification != null)
          'testSpecification': testSpecification!.toJson(),
        if (timestamp != null) 'timestamp': timestamp!,
      };
}

/// A description of how to set up the Android device prior to running the test.
class TestSetup {
  /// The device will be logged in on this account for the duration of the test.
  Account? account;

  /// APKs to install in addition to those being directly tested.
  ///
  /// Currently capped at 100.
  core.List<Apk>? additionalApks;

  /// List of directories on the device to upload to GCS at the end of the test;
  /// they must be absolute paths under /sdcard, /storage or /data/local/tmp.
  ///
  /// Path names are restricted to characters a-z A-Z 0-9 _ - . + and / Note:
  /// The paths /sdcard and /data will be made available and treated as implicit
  /// path substitutions. E.g. if /sdcard on a particular device does not map to
  /// external storage, the system will replace it with the external storage
  /// path prefix for that device.
  core.List<core.String>? directoriesToPull;

  /// Whether to prevent all runtime permissions to be granted at app install
  core.bool? dontAutograntPermissions;

  /// Environment variables to set for the test (only applicable for
  /// instrumentation tests).
  core.List<EnvironmentVariable>? environmentVariables;

  /// List of files to push to the device before starting the test.
  core.List<DeviceFile>? filesToPush;

  /// The network traffic profile used for running the test.
  ///
  /// Available network profiles can be queried by using the
  /// NETWORK_CONFIGURATION environment type when calling
  /// TestEnvironmentDiscoveryService.GetTestEnvironmentCatalog.
  core.String? networkProfile;

  /// Systrace configuration for the run.
  ///
  /// If set a systrace will be taken, starting on test start and lasting for
  /// the configured duration. The systrace file thus obtained is put in the
  /// results bucket together with the other artifacts from the run.
  SystraceSetup? systrace;

  TestSetup();

  TestSetup.fromJson(core.Map _json) {
    if (_json.containsKey('account')) {
      account = Account.fromJson(
          _json['account'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('additionalApks')) {
      additionalApks = (_json['additionalApks'] as core.List)
          .map<Apk>((value) =>
              Apk.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('directoriesToPull')) {
      directoriesToPull = (_json['directoriesToPull'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('dontAutograntPermissions')) {
      dontAutograntPermissions = _json['dontAutograntPermissions'] as core.bool;
    }
    if (_json.containsKey('environmentVariables')) {
      environmentVariables = (_json['environmentVariables'] as core.List)
          .map<EnvironmentVariable>((value) => EnvironmentVariable.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('filesToPush')) {
      filesToPush = (_json['filesToPush'] as core.List)
          .map<DeviceFile>((value) =>
              DeviceFile.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('networkProfile')) {
      networkProfile = _json['networkProfile'] as core.String;
    }
    if (_json.containsKey('systrace')) {
      systrace = SystraceSetup.fromJson(
          _json['systrace'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (account != null) 'account': account!.toJson(),
        if (additionalApks != null)
          'additionalApks':
              additionalApks!.map((value) => value.toJson()).toList(),
        if (directoriesToPull != null) 'directoriesToPull': directoriesToPull!,
        if (dontAutograntPermissions != null)
          'dontAutograntPermissions': dontAutograntPermissions!,
        if (environmentVariables != null)
          'environmentVariables':
              environmentVariables!.map((value) => value.toJson()).toList(),
        if (filesToPush != null)
          'filesToPush': filesToPush!.map((value) => value.toJson()).toList(),
        if (networkProfile != null) 'networkProfile': networkProfile!,
        if (systrace != null) 'systrace': systrace!.toJson(),
      };
}

/// A description of how to run the test.
class TestSpecification {
  /// An Android instrumentation test.
  AndroidInstrumentationTest? androidInstrumentationTest;

  /// An Android robo test.
  AndroidRoboTest? androidRoboTest;

  /// An Android Application with a Test Loop.
  AndroidTestLoop? androidTestLoop;

  /// Disables performance metrics recording.
  ///
  /// May reduce test latency.
  core.bool? disablePerformanceMetrics;

  /// Disables video recording.
  ///
  /// May reduce test latency.
  core.bool? disableVideoRecording;

  /// An iOS application with a test loop.
  IosTestLoop? iosTestLoop;

  /// Test setup requirements for iOS.
  IosTestSetup? iosTestSetup;

  /// An iOS XCTest, via an .xctestrun file.
  IosXcTest? iosXcTest;

  /// Test setup requirements for Android e.g. files to install, bootstrap
  /// scripts.
  TestSetup? testSetup;

  /// Max time a test execution is allowed to run before it is automatically
  /// cancelled.
  ///
  /// The default value is 5 min.
  core.String? testTimeout;

  TestSpecification();

  TestSpecification.fromJson(core.Map _json) {
    if (_json.containsKey('androidInstrumentationTest')) {
      androidInstrumentationTest = AndroidInstrumentationTest.fromJson(
          _json['androidInstrumentationTest']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('androidRoboTest')) {
      androidRoboTest = AndroidRoboTest.fromJson(
          _json['androidRoboTest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('androidTestLoop')) {
      androidTestLoop = AndroidTestLoop.fromJson(
          _json['androidTestLoop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('disablePerformanceMetrics')) {
      disablePerformanceMetrics =
          _json['disablePerformanceMetrics'] as core.bool;
    }
    if (_json.containsKey('disableVideoRecording')) {
      disableVideoRecording = _json['disableVideoRecording'] as core.bool;
    }
    if (_json.containsKey('iosTestLoop')) {
      iosTestLoop = IosTestLoop.fromJson(
          _json['iosTestLoop'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iosTestSetup')) {
      iosTestSetup = IosTestSetup.fromJson(
          _json['iosTestSetup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iosXcTest')) {
      iosXcTest = IosXcTest.fromJson(
          _json['iosXcTest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testSetup')) {
      testSetup = TestSetup.fromJson(
          _json['testSetup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testTimeout')) {
      testTimeout = _json['testTimeout'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidInstrumentationTest != null)
          'androidInstrumentationTest': androidInstrumentationTest!.toJson(),
        if (androidRoboTest != null)
          'androidRoboTest': androidRoboTest!.toJson(),
        if (androidTestLoop != null)
          'androidTestLoop': androidTestLoop!.toJson(),
        if (disablePerformanceMetrics != null)
          'disablePerformanceMetrics': disablePerformanceMetrics!,
        if (disableVideoRecording != null)
          'disableVideoRecording': disableVideoRecording!,
        if (iosTestLoop != null) 'iosTestLoop': iosTestLoop!.toJson(),
        if (iosTestSetup != null) 'iosTestSetup': iosTestSetup!.toJson(),
        if (iosXcTest != null) 'iosXcTest': iosXcTest!.toJson(),
        if (testSetup != null) 'testSetup': testSetup!.toJson(),
        if (testTimeout != null) 'testTimeout': testTimeout!,
      };
}

/// Test targets for a shard.
class TestTargetsForShard {
  /// Group of packages, classes, and/or test methods to be run for each shard.
  ///
  /// The targets need to be specified in AndroidJUnitRunner argument format.
  /// For example, "package com.my.packages" "class com.my.package.MyClass". The
  /// number of shard_test_targets must be greater than 0.
  core.List<core.String>? testTargets;

  TestTargetsForShard();

  TestTargetsForShard.fromJson(core.Map _json) {
    if (_json.containsKey('testTargets')) {
      testTargets = (_json['testTargets'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (testTargets != null) 'testTargets': testTargets!,
      };
}

/// Represents a tool results execution resource.
///
/// This has the results of a TestMatrix.
class ToolResultsExecution {
  /// A tool results execution ID.
  ///
  /// Output only.
  core.String? executionId;

  /// A tool results history ID.
  ///
  /// Output only.
  core.String? historyId;

  /// The cloud project that owns the tool results execution.
  ///
  /// Output only.
  core.String? projectId;

  ToolResultsExecution();

  ToolResultsExecution.fromJson(core.Map _json) {
    if (_json.containsKey('executionId')) {
      executionId = _json['executionId'] as core.String;
    }
    if (_json.containsKey('historyId')) {
      historyId = _json['historyId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionId != null) 'executionId': executionId!,
        if (historyId != null) 'historyId': historyId!,
        if (projectId != null) 'projectId': projectId!,
      };
}

/// Represents a tool results history resource.
class ToolResultsHistory {
  /// A tool results history ID.
  ///
  /// Required.
  core.String? historyId;

  /// The cloud project that owns the tool results history.
  ///
  /// Required.
  core.String? projectId;

  ToolResultsHistory();

  ToolResultsHistory.fromJson(core.Map _json) {
    if (_json.containsKey('historyId')) {
      historyId = _json['historyId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (historyId != null) 'historyId': historyId!,
        if (projectId != null) 'projectId': projectId!,
      };
}

/// Represents a tool results step resource.
///
/// This has the results of a TestExecution.
class ToolResultsStep {
  /// A tool results execution ID.
  ///
  /// Output only.
  core.String? executionId;

  /// A tool results history ID.
  ///
  /// Output only.
  core.String? historyId;

  /// The cloud project that owns the tool results step.
  ///
  /// Output only.
  core.String? projectId;

  /// A tool results step ID.
  ///
  /// Output only.
  core.String? stepId;

  ToolResultsStep();

  ToolResultsStep.fromJson(core.Map _json) {
    if (_json.containsKey('executionId')) {
      executionId = _json['executionId'] as core.String;
    }
    if (_json.containsKey('historyId')) {
      historyId = _json['historyId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('stepId')) {
      stepId = _json['stepId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionId != null) 'executionId': executionId!,
        if (historyId != null) 'historyId': historyId!,
        if (projectId != null) 'projectId': projectId!,
        if (stepId != null) 'stepId': stepId!,
      };
}

/// Network emulation parameters.
class TrafficRule {
  /// Bandwidth in kbits/second.
  core.double? bandwidth;

  /// Burst size in kbits.
  core.double? burst;

  /// Packet delay, must be >= 0.
  core.String? delay;

  /// Packet duplication ratio (0.0 - 1.0).
  core.double? packetDuplicationRatio;

  /// Packet loss ratio (0.0 - 1.0).
  core.double? packetLossRatio;

  TrafficRule();

  TrafficRule.fromJson(core.Map _json) {
    if (_json.containsKey('bandwidth')) {
      bandwidth = (_json['bandwidth'] as core.num).toDouble();
    }
    if (_json.containsKey('burst')) {
      burst = (_json['burst'] as core.num).toDouble();
    }
    if (_json.containsKey('delay')) {
      delay = _json['delay'] as core.String;
    }
    if (_json.containsKey('packetDuplicationRatio')) {
      packetDuplicationRatio =
          (_json['packetDuplicationRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('packetLossRatio')) {
      packetLossRatio = (_json['packetLossRatio'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bandwidth != null) 'bandwidth': bandwidth!,
        if (burst != null) 'burst': burst!,
        if (delay != null) 'delay': delay!,
        if (packetDuplicationRatio != null)
          'packetDuplicationRatio': packetDuplicationRatio!,
        if (packetLossRatio != null) 'packetLossRatio': packetLossRatio!,
      };
}

/// Uniformly shards test cases given a total number of shards.
///
/// For Instrumentation test, it will be translated to "-e numShard" "-e
/// shardIndex" AndroidJUnitRunner arguments. With uniform sharding enabled,
/// specifying these sharding arguments via environment_variables is invalid.
class UniformSharding {
  /// Total number of shards.
  ///
  /// When any physical devices are selected, the number must be >= 1 and <= 50.
  /// When no physical devices are selected, the number must be >= 1 and <= 500.
  ///
  /// Required.
  core.int? numShards;

  UniformSharding();

  UniformSharding.fromJson(core.Map _json) {
    if (_json.containsKey('numShards')) {
      numShards = _json['numShards'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (numShards != null) 'numShards': numShards!,
      };
}

/// An Xcode version that an iOS version is compatible with.
class XcodeVersion {
  /// Tags for this Xcode version.
  ///
  /// Example: "default".
  core.List<core.String>? tags;

  /// The id for this version.
  ///
  /// Example: "9.2".
  core.String? version;

  XcodeVersion();

  XcodeVersion.fromJson(core.Map _json) {
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tags != null) 'tags': tags!,
        if (version != null) 'version': version!,
      };
}
