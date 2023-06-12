// ignore_for_file: avoid_returning_null
// ignore_for_file: camel_case_types
// ignore_for_file: cascade_invocations
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: unnecessary_string_interpolations
// ignore_for_file: unused_local_variable

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:googleapis/trafficdirector/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAddress = 0;
api.Address buildAddress() {
  var o = api.Address();
  buildCounterAddress++;
  if (buildCounterAddress < 3) {
    o.pipe = buildPipe();
    o.socketAddress = buildSocketAddress();
  }
  buildCounterAddress--;
  return o;
}

void checkAddress(api.Address o) {
  buildCounterAddress++;
  if (buildCounterAddress < 3) {
    checkPipe(o.pipe! as api.Pipe);
    checkSocketAddress(o.socketAddress! as api.SocketAddress);
  }
  buildCounterAddress--;
}

core.Map<core.String, core.Object> buildUnnamed2477() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2477(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o['x']!) as core.Map;
  unittest.expect(casted1, unittest.hasLength(3));
  unittest.expect(
    casted1['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted1['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted1['string'],
    unittest.equals('foo'),
  );
  var casted2 = (o['y']!) as core.Map;
  unittest.expect(casted2, unittest.hasLength(3));
  unittest.expect(
    casted2['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted2['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted2['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterBuildVersion = 0;
api.BuildVersion buildBuildVersion() {
  var o = api.BuildVersion();
  buildCounterBuildVersion++;
  if (buildCounterBuildVersion < 3) {
    o.metadata = buildUnnamed2477();
    o.version = buildSemanticVersion();
  }
  buildCounterBuildVersion--;
  return o;
}

void checkBuildVersion(api.BuildVersion o) {
  buildCounterBuildVersion++;
  if (buildCounterBuildVersion < 3) {
    checkUnnamed2477(o.metadata!);
    checkSemanticVersion(o.version! as api.SemanticVersion);
  }
  buildCounterBuildVersion--;
}

core.List<api.PerXdsConfig> buildUnnamed2478() {
  var o = <api.PerXdsConfig>[];
  o.add(buildPerXdsConfig());
  o.add(buildPerXdsConfig());
  return o;
}

void checkUnnamed2478(core.List<api.PerXdsConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPerXdsConfig(o[0] as api.PerXdsConfig);
  checkPerXdsConfig(o[1] as api.PerXdsConfig);
}

core.int buildCounterClientConfig = 0;
api.ClientConfig buildClientConfig() {
  var o = api.ClientConfig();
  buildCounterClientConfig++;
  if (buildCounterClientConfig < 3) {
    o.node = buildNode();
    o.xdsConfig = buildUnnamed2478();
  }
  buildCounterClientConfig--;
  return o;
}

void checkClientConfig(api.ClientConfig o) {
  buildCounterClientConfig++;
  if (buildCounterClientConfig < 3) {
    checkNode(o.node! as api.Node);
    checkUnnamed2478(o.xdsConfig!);
  }
  buildCounterClientConfig--;
}

core.List<api.NodeMatcher> buildUnnamed2479() {
  var o = <api.NodeMatcher>[];
  o.add(buildNodeMatcher());
  o.add(buildNodeMatcher());
  return o;
}

void checkUnnamed2479(core.List<api.NodeMatcher> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNodeMatcher(o[0] as api.NodeMatcher);
  checkNodeMatcher(o[1] as api.NodeMatcher);
}

core.int buildCounterClientStatusRequest = 0;
api.ClientStatusRequest buildClientStatusRequest() {
  var o = api.ClientStatusRequest();
  buildCounterClientStatusRequest++;
  if (buildCounterClientStatusRequest < 3) {
    o.nodeMatchers = buildUnnamed2479();
  }
  buildCounterClientStatusRequest--;
  return o;
}

void checkClientStatusRequest(api.ClientStatusRequest o) {
  buildCounterClientStatusRequest++;
  if (buildCounterClientStatusRequest < 3) {
    checkUnnamed2479(o.nodeMatchers!);
  }
  buildCounterClientStatusRequest--;
}

core.List<api.ClientConfig> buildUnnamed2480() {
  var o = <api.ClientConfig>[];
  o.add(buildClientConfig());
  o.add(buildClientConfig());
  return o;
}

void checkUnnamed2480(core.List<api.ClientConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkClientConfig(o[0] as api.ClientConfig);
  checkClientConfig(o[1] as api.ClientConfig);
}

core.int buildCounterClientStatusResponse = 0;
api.ClientStatusResponse buildClientStatusResponse() {
  var o = api.ClientStatusResponse();
  buildCounterClientStatusResponse++;
  if (buildCounterClientStatusResponse < 3) {
    o.config = buildUnnamed2480();
  }
  buildCounterClientStatusResponse--;
  return o;
}

void checkClientStatusResponse(api.ClientStatusResponse o) {
  buildCounterClientStatusResponse++;
  if (buildCounterClientStatusResponse < 3) {
    checkUnnamed2480(o.config!);
  }
  buildCounterClientStatusResponse--;
}

core.List<api.DynamicCluster> buildUnnamed2481() {
  var o = <api.DynamicCluster>[];
  o.add(buildDynamicCluster());
  o.add(buildDynamicCluster());
  return o;
}

void checkUnnamed2481(core.List<api.DynamicCluster> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicCluster(o[0] as api.DynamicCluster);
  checkDynamicCluster(o[1] as api.DynamicCluster);
}

core.List<api.DynamicCluster> buildUnnamed2482() {
  var o = <api.DynamicCluster>[];
  o.add(buildDynamicCluster());
  o.add(buildDynamicCluster());
  return o;
}

void checkUnnamed2482(core.List<api.DynamicCluster> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicCluster(o[0] as api.DynamicCluster);
  checkDynamicCluster(o[1] as api.DynamicCluster);
}

core.List<api.StaticCluster> buildUnnamed2483() {
  var o = <api.StaticCluster>[];
  o.add(buildStaticCluster());
  o.add(buildStaticCluster());
  return o;
}

void checkUnnamed2483(core.List<api.StaticCluster> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStaticCluster(o[0] as api.StaticCluster);
  checkStaticCluster(o[1] as api.StaticCluster);
}

core.int buildCounterClustersConfigDump = 0;
api.ClustersConfigDump buildClustersConfigDump() {
  var o = api.ClustersConfigDump();
  buildCounterClustersConfigDump++;
  if (buildCounterClustersConfigDump < 3) {
    o.dynamicActiveClusters = buildUnnamed2481();
    o.dynamicWarmingClusters = buildUnnamed2482();
    o.staticClusters = buildUnnamed2483();
    o.versionInfo = 'foo';
  }
  buildCounterClustersConfigDump--;
  return o;
}

void checkClustersConfigDump(api.ClustersConfigDump o) {
  buildCounterClustersConfigDump++;
  if (buildCounterClustersConfigDump < 3) {
    checkUnnamed2481(o.dynamicActiveClusters!);
    checkUnnamed2482(o.dynamicWarmingClusters!);
    checkUnnamed2483(o.staticClusters!);
    unittest.expect(
      o.versionInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterClustersConfigDump--;
}

core.int buildCounterDoubleMatcher = 0;
api.DoubleMatcher buildDoubleMatcher() {
  var o = api.DoubleMatcher();
  buildCounterDoubleMatcher++;
  if (buildCounterDoubleMatcher < 3) {
    o.exact = 42.0;
    o.range = buildDoubleRange();
  }
  buildCounterDoubleMatcher--;
  return o;
}

void checkDoubleMatcher(api.DoubleMatcher o) {
  buildCounterDoubleMatcher++;
  if (buildCounterDoubleMatcher < 3) {
    unittest.expect(
      o.exact!,
      unittest.equals(42.0),
    );
    checkDoubleRange(o.range! as api.DoubleRange);
  }
  buildCounterDoubleMatcher--;
}

core.int buildCounterDoubleRange = 0;
api.DoubleRange buildDoubleRange() {
  var o = api.DoubleRange();
  buildCounterDoubleRange++;
  if (buildCounterDoubleRange < 3) {
    o.end = 42.0;
    o.start = 42.0;
  }
  buildCounterDoubleRange--;
  return o;
}

void checkDoubleRange(api.DoubleRange o) {
  buildCounterDoubleRange++;
  if (buildCounterDoubleRange < 3) {
    unittest.expect(
      o.end!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.start!,
      unittest.equals(42.0),
    );
  }
  buildCounterDoubleRange--;
}

core.Map<core.String, core.Object> buildUnnamed2484() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2484(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o['x']!) as core.Map;
  unittest.expect(casted3, unittest.hasLength(3));
  unittest.expect(
    casted3['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted3['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted3['string'],
    unittest.equals('foo'),
  );
  var casted4 = (o['y']!) as core.Map;
  unittest.expect(casted4, unittest.hasLength(3));
  unittest.expect(
    casted4['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted4['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted4['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterDynamicCluster = 0;
api.DynamicCluster buildDynamicCluster() {
  var o = api.DynamicCluster();
  buildCounterDynamicCluster++;
  if (buildCounterDynamicCluster < 3) {
    o.cluster = buildUnnamed2484();
    o.lastUpdated = 'foo';
    o.versionInfo = 'foo';
  }
  buildCounterDynamicCluster--;
  return o;
}

void checkDynamicCluster(api.DynamicCluster o) {
  buildCounterDynamicCluster++;
  if (buildCounterDynamicCluster < 3) {
    checkUnnamed2484(o.cluster!);
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterDynamicCluster--;
}

core.int buildCounterDynamicListener = 0;
api.DynamicListener buildDynamicListener() {
  var o = api.DynamicListener();
  buildCounterDynamicListener++;
  if (buildCounterDynamicListener < 3) {
    o.activeState = buildDynamicListenerState();
    o.drainingState = buildDynamicListenerState();
    o.errorState = buildUpdateFailureState();
    o.name = 'foo';
    o.warmingState = buildDynamicListenerState();
  }
  buildCounterDynamicListener--;
  return o;
}

void checkDynamicListener(api.DynamicListener o) {
  buildCounterDynamicListener++;
  if (buildCounterDynamicListener < 3) {
    checkDynamicListenerState(o.activeState! as api.DynamicListenerState);
    checkDynamicListenerState(o.drainingState! as api.DynamicListenerState);
    checkUpdateFailureState(o.errorState! as api.UpdateFailureState);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkDynamicListenerState(o.warmingState! as api.DynamicListenerState);
  }
  buildCounterDynamicListener--;
}

core.Map<core.String, core.Object> buildUnnamed2485() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2485(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted5 = (o['x']!) as core.Map;
  unittest.expect(casted5, unittest.hasLength(3));
  unittest.expect(
    casted5['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted5['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted5['string'],
    unittest.equals('foo'),
  );
  var casted6 = (o['y']!) as core.Map;
  unittest.expect(casted6, unittest.hasLength(3));
  unittest.expect(
    casted6['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted6['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted6['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterDynamicListenerState = 0;
api.DynamicListenerState buildDynamicListenerState() {
  var o = api.DynamicListenerState();
  buildCounterDynamicListenerState++;
  if (buildCounterDynamicListenerState < 3) {
    o.lastUpdated = 'foo';
    o.listener = buildUnnamed2485();
    o.versionInfo = 'foo';
  }
  buildCounterDynamicListenerState--;
  return o;
}

void checkDynamicListenerState(api.DynamicListenerState o) {
  buildCounterDynamicListenerState++;
  if (buildCounterDynamicListenerState < 3) {
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
    checkUnnamed2485(o.listener!);
    unittest.expect(
      o.versionInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterDynamicListenerState--;
}

core.Map<core.String, core.Object> buildUnnamed2486() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2486(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted7 = (o['x']!) as core.Map;
  unittest.expect(casted7, unittest.hasLength(3));
  unittest.expect(
    casted7['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted7['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted7['string'],
    unittest.equals('foo'),
  );
  var casted8 = (o['y']!) as core.Map;
  unittest.expect(casted8, unittest.hasLength(3));
  unittest.expect(
    casted8['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted8['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted8['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterDynamicRouteConfig = 0;
api.DynamicRouteConfig buildDynamicRouteConfig() {
  var o = api.DynamicRouteConfig();
  buildCounterDynamicRouteConfig++;
  if (buildCounterDynamicRouteConfig < 3) {
    o.lastUpdated = 'foo';
    o.routeConfig = buildUnnamed2486();
    o.versionInfo = 'foo';
  }
  buildCounterDynamicRouteConfig--;
  return o;
}

void checkDynamicRouteConfig(api.DynamicRouteConfig o) {
  buildCounterDynamicRouteConfig++;
  if (buildCounterDynamicRouteConfig < 3) {
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
    checkUnnamed2486(o.routeConfig!);
    unittest.expect(
      o.versionInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterDynamicRouteConfig--;
}

core.Map<core.String, core.Object> buildUnnamed2487() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2487(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted9 = (o['x']!) as core.Map;
  unittest.expect(casted9, unittest.hasLength(3));
  unittest.expect(
    casted9['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted9['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted9['string'],
    unittest.equals('foo'),
  );
  var casted10 = (o['y']!) as core.Map;
  unittest.expect(casted10, unittest.hasLength(3));
  unittest.expect(
    casted10['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted10['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted10['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed2488() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2487());
  o.add(buildUnnamed2487());
  return o;
}

void checkUnnamed2488(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2487(o[0]);
  checkUnnamed2487(o[1]);
}

core.int buildCounterDynamicScopedRouteConfigs = 0;
api.DynamicScopedRouteConfigs buildDynamicScopedRouteConfigs() {
  var o = api.DynamicScopedRouteConfigs();
  buildCounterDynamicScopedRouteConfigs++;
  if (buildCounterDynamicScopedRouteConfigs < 3) {
    o.lastUpdated = 'foo';
    o.name = 'foo';
    o.scopedRouteConfigs = buildUnnamed2488();
    o.versionInfo = 'foo';
  }
  buildCounterDynamicScopedRouteConfigs--;
  return o;
}

void checkDynamicScopedRouteConfigs(api.DynamicScopedRouteConfigs o) {
  buildCounterDynamicScopedRouteConfigs++;
  if (buildCounterDynamicScopedRouteConfigs < 3) {
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2488(o.scopedRouteConfigs!);
    unittest.expect(
      o.versionInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterDynamicScopedRouteConfigs--;
}

core.int buildCounterExtension = 0;
api.Extension buildExtension() {
  var o = api.Extension();
  buildCounterExtension++;
  if (buildCounterExtension < 3) {
    o.category = 'foo';
    o.disabled = true;
    o.name = 'foo';
    o.typeDescriptor = 'foo';
    o.version = buildBuildVersion();
  }
  buildCounterExtension--;
  return o;
}

void checkExtension(api.Extension o) {
  buildCounterExtension++;
  if (buildCounterExtension < 3) {
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.typeDescriptor!,
      unittest.equals('foo'),
    );
    checkBuildVersion(o.version! as api.BuildVersion);
  }
  buildCounterExtension--;
}

core.int buildCounterGoogleRE2 = 0;
api.GoogleRE2 buildGoogleRE2() {
  var o = api.GoogleRE2();
  buildCounterGoogleRE2++;
  if (buildCounterGoogleRE2 < 3) {
    o.maxProgramSize = 42;
  }
  buildCounterGoogleRE2--;
  return o;
}

void checkGoogleRE2(api.GoogleRE2 o) {
  buildCounterGoogleRE2++;
  if (buildCounterGoogleRE2 < 3) {
    unittest.expect(
      o.maxProgramSize!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleRE2--;
}

core.Map<core.String, core.Object> buildUnnamed2489() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2489(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted11 = (o['x']!) as core.Map;
  unittest.expect(casted11, unittest.hasLength(3));
  unittest.expect(
    casted11['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted11['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted11['string'],
    unittest.equals('foo'),
  );
  var casted12 = (o['y']!) as core.Map;
  unittest.expect(casted12, unittest.hasLength(3));
  unittest.expect(
    casted12['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted12['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted12['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed2490() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2489());
  o.add(buildUnnamed2489());
  return o;
}

void checkUnnamed2490(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2489(o[0]);
  checkUnnamed2489(o[1]);
}

core.int buildCounterInlineScopedRouteConfigs = 0;
api.InlineScopedRouteConfigs buildInlineScopedRouteConfigs() {
  var o = api.InlineScopedRouteConfigs();
  buildCounterInlineScopedRouteConfigs++;
  if (buildCounterInlineScopedRouteConfigs < 3) {
    o.lastUpdated = 'foo';
    o.name = 'foo';
    o.scopedRouteConfigs = buildUnnamed2490();
  }
  buildCounterInlineScopedRouteConfigs--;
  return o;
}

void checkInlineScopedRouteConfigs(api.InlineScopedRouteConfigs o) {
  buildCounterInlineScopedRouteConfigs++;
  if (buildCounterInlineScopedRouteConfigs < 3) {
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2490(o.scopedRouteConfigs!);
  }
  buildCounterInlineScopedRouteConfigs--;
}

core.int buildCounterListMatcher = 0;
api.ListMatcher buildListMatcher() {
  var o = api.ListMatcher();
  buildCounterListMatcher++;
  if (buildCounterListMatcher < 3) {
    o.oneOf = buildValueMatcher();
  }
  buildCounterListMatcher--;
  return o;
}

void checkListMatcher(api.ListMatcher o) {
  buildCounterListMatcher++;
  if (buildCounterListMatcher < 3) {
    checkValueMatcher(o.oneOf! as api.ValueMatcher);
  }
  buildCounterListMatcher--;
}

core.List<api.DynamicListener> buildUnnamed2491() {
  var o = <api.DynamicListener>[];
  o.add(buildDynamicListener());
  o.add(buildDynamicListener());
  return o;
}

void checkUnnamed2491(core.List<api.DynamicListener> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicListener(o[0] as api.DynamicListener);
  checkDynamicListener(o[1] as api.DynamicListener);
}

core.List<api.StaticListener> buildUnnamed2492() {
  var o = <api.StaticListener>[];
  o.add(buildStaticListener());
  o.add(buildStaticListener());
  return o;
}

void checkUnnamed2492(core.List<api.StaticListener> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStaticListener(o[0] as api.StaticListener);
  checkStaticListener(o[1] as api.StaticListener);
}

core.int buildCounterListenersConfigDump = 0;
api.ListenersConfigDump buildListenersConfigDump() {
  var o = api.ListenersConfigDump();
  buildCounterListenersConfigDump++;
  if (buildCounterListenersConfigDump < 3) {
    o.dynamicListeners = buildUnnamed2491();
    o.staticListeners = buildUnnamed2492();
    o.versionInfo = 'foo';
  }
  buildCounterListenersConfigDump--;
  return o;
}

void checkListenersConfigDump(api.ListenersConfigDump o) {
  buildCounterListenersConfigDump++;
  if (buildCounterListenersConfigDump < 3) {
    checkUnnamed2491(o.dynamicListeners!);
    checkUnnamed2492(o.staticListeners!);
    unittest.expect(
      o.versionInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterListenersConfigDump--;
}

core.int buildCounterLocality = 0;
api.Locality buildLocality() {
  var o = api.Locality();
  buildCounterLocality++;
  if (buildCounterLocality < 3) {
    o.region = 'foo';
    o.subZone = 'foo';
    o.zone = 'foo';
  }
  buildCounterLocality--;
  return o;
}

void checkLocality(api.Locality o) {
  buildCounterLocality++;
  if (buildCounterLocality < 3) {
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subZone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.zone!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocality--;
}

core.List<core.String> buildUnnamed2493() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2493(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<api.Extension> buildUnnamed2494() {
  var o = <api.Extension>[];
  o.add(buildExtension());
  o.add(buildExtension());
  return o;
}

void checkUnnamed2494(core.List<api.Extension> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExtension(o[0] as api.Extension);
  checkExtension(o[1] as api.Extension);
}

core.List<api.Address> buildUnnamed2495() {
  var o = <api.Address>[];
  o.add(buildAddress());
  o.add(buildAddress());
  return o;
}

void checkUnnamed2495(core.List<api.Address> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAddress(o[0] as api.Address);
  checkAddress(o[1] as api.Address);
}

core.Map<core.String, core.Object> buildUnnamed2496() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2496(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted13 = (o['x']!) as core.Map;
  unittest.expect(casted13, unittest.hasLength(3));
  unittest.expect(
    casted13['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted13['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted13['string'],
    unittest.equals('foo'),
  );
  var casted14 = (o['y']!) as core.Map;
  unittest.expect(casted14, unittest.hasLength(3));
  unittest.expect(
    casted14['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted14['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted14['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterNode = 0;
api.Node buildNode() {
  var o = api.Node();
  buildCounterNode++;
  if (buildCounterNode < 3) {
    o.buildVersion = 'foo';
    o.clientFeatures = buildUnnamed2493();
    o.cluster = 'foo';
    o.extensions = buildUnnamed2494();
    o.id = 'foo';
    o.listeningAddresses = buildUnnamed2495();
    o.locality = buildLocality();
    o.metadata = buildUnnamed2496();
    o.userAgentBuildVersion = buildBuildVersion();
    o.userAgentName = 'foo';
    o.userAgentVersion = 'foo';
  }
  buildCounterNode--;
  return o;
}

void checkNode(api.Node o) {
  buildCounterNode++;
  if (buildCounterNode < 3) {
    unittest.expect(
      o.buildVersion!,
      unittest.equals('foo'),
    );
    checkUnnamed2493(o.clientFeatures!);
    unittest.expect(
      o.cluster!,
      unittest.equals('foo'),
    );
    checkUnnamed2494(o.extensions!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed2495(o.listeningAddresses!);
    checkLocality(o.locality! as api.Locality);
    checkUnnamed2496(o.metadata!);
    checkBuildVersion(o.userAgentBuildVersion! as api.BuildVersion);
    unittest.expect(
      o.userAgentName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userAgentVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterNode--;
}

core.List<api.StructMatcher> buildUnnamed2497() {
  var o = <api.StructMatcher>[];
  o.add(buildStructMatcher());
  o.add(buildStructMatcher());
  return o;
}

void checkUnnamed2497(core.List<api.StructMatcher> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStructMatcher(o[0] as api.StructMatcher);
  checkStructMatcher(o[1] as api.StructMatcher);
}

core.int buildCounterNodeMatcher = 0;
api.NodeMatcher buildNodeMatcher() {
  var o = api.NodeMatcher();
  buildCounterNodeMatcher++;
  if (buildCounterNodeMatcher < 3) {
    o.nodeId = buildStringMatcher();
    o.nodeMetadatas = buildUnnamed2497();
  }
  buildCounterNodeMatcher--;
  return o;
}

void checkNodeMatcher(api.NodeMatcher o) {
  buildCounterNodeMatcher++;
  if (buildCounterNodeMatcher < 3) {
    checkStringMatcher(o.nodeId! as api.StringMatcher);
    checkUnnamed2497(o.nodeMetadatas!);
  }
  buildCounterNodeMatcher--;
}

core.int buildCounterNullMatch = 0;
api.NullMatch buildNullMatch() {
  var o = api.NullMatch();
  buildCounterNullMatch++;
  if (buildCounterNullMatch < 3) {}
  buildCounterNullMatch--;
  return o;
}

void checkNullMatch(api.NullMatch o) {
  buildCounterNullMatch++;
  if (buildCounterNullMatch < 3) {}
  buildCounterNullMatch--;
}

core.int buildCounterPathSegment = 0;
api.PathSegment buildPathSegment() {
  var o = api.PathSegment();
  buildCounterPathSegment++;
  if (buildCounterPathSegment < 3) {
    o.key = 'foo';
  }
  buildCounterPathSegment--;
  return o;
}

void checkPathSegment(api.PathSegment o) {
  buildCounterPathSegment++;
  if (buildCounterPathSegment < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
  }
  buildCounterPathSegment--;
}

core.int buildCounterPerXdsConfig = 0;
api.PerXdsConfig buildPerXdsConfig() {
  var o = api.PerXdsConfig();
  buildCounterPerXdsConfig++;
  if (buildCounterPerXdsConfig < 3) {
    o.clusterConfig = buildClustersConfigDump();
    o.listenerConfig = buildListenersConfigDump();
    o.routeConfig = buildRoutesConfigDump();
    o.scopedRouteConfig = buildScopedRoutesConfigDump();
    o.status = 'foo';
  }
  buildCounterPerXdsConfig--;
  return o;
}

void checkPerXdsConfig(api.PerXdsConfig o) {
  buildCounterPerXdsConfig++;
  if (buildCounterPerXdsConfig < 3) {
    checkClustersConfigDump(o.clusterConfig! as api.ClustersConfigDump);
    checkListenersConfigDump(o.listenerConfig! as api.ListenersConfigDump);
    checkRoutesConfigDump(o.routeConfig! as api.RoutesConfigDump);
    checkScopedRoutesConfigDump(
        o.scopedRouteConfig! as api.ScopedRoutesConfigDump);
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterPerXdsConfig--;
}

core.int buildCounterPipe = 0;
api.Pipe buildPipe() {
  var o = api.Pipe();
  buildCounterPipe++;
  if (buildCounterPipe < 3) {
    o.mode = 42;
    o.path = 'foo';
  }
  buildCounterPipe--;
  return o;
}

void checkPipe(api.Pipe o) {
  buildCounterPipe++;
  if (buildCounterPipe < 3) {
    unittest.expect(
      o.mode!,
      unittest.equals(42),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
  }
  buildCounterPipe--;
}

core.int buildCounterRegexMatcher = 0;
api.RegexMatcher buildRegexMatcher() {
  var o = api.RegexMatcher();
  buildCounterRegexMatcher++;
  if (buildCounterRegexMatcher < 3) {
    o.googleRe2 = buildGoogleRE2();
    o.regex = 'foo';
  }
  buildCounterRegexMatcher--;
  return o;
}

void checkRegexMatcher(api.RegexMatcher o) {
  buildCounterRegexMatcher++;
  if (buildCounterRegexMatcher < 3) {
    checkGoogleRE2(o.googleRe2! as api.GoogleRE2);
    unittest.expect(
      o.regex!,
      unittest.equals('foo'),
    );
  }
  buildCounterRegexMatcher--;
}

core.List<api.DynamicRouteConfig> buildUnnamed2498() {
  var o = <api.DynamicRouteConfig>[];
  o.add(buildDynamicRouteConfig());
  o.add(buildDynamicRouteConfig());
  return o;
}

void checkUnnamed2498(core.List<api.DynamicRouteConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicRouteConfig(o[0] as api.DynamicRouteConfig);
  checkDynamicRouteConfig(o[1] as api.DynamicRouteConfig);
}

core.List<api.StaticRouteConfig> buildUnnamed2499() {
  var o = <api.StaticRouteConfig>[];
  o.add(buildStaticRouteConfig());
  o.add(buildStaticRouteConfig());
  return o;
}

void checkUnnamed2499(core.List<api.StaticRouteConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStaticRouteConfig(o[0] as api.StaticRouteConfig);
  checkStaticRouteConfig(o[1] as api.StaticRouteConfig);
}

core.int buildCounterRoutesConfigDump = 0;
api.RoutesConfigDump buildRoutesConfigDump() {
  var o = api.RoutesConfigDump();
  buildCounterRoutesConfigDump++;
  if (buildCounterRoutesConfigDump < 3) {
    o.dynamicRouteConfigs = buildUnnamed2498();
    o.staticRouteConfigs = buildUnnamed2499();
  }
  buildCounterRoutesConfigDump--;
  return o;
}

void checkRoutesConfigDump(api.RoutesConfigDump o) {
  buildCounterRoutesConfigDump++;
  if (buildCounterRoutesConfigDump < 3) {
    checkUnnamed2498(o.dynamicRouteConfigs!);
    checkUnnamed2499(o.staticRouteConfigs!);
  }
  buildCounterRoutesConfigDump--;
}

core.List<api.DynamicScopedRouteConfigs> buildUnnamed2500() {
  var o = <api.DynamicScopedRouteConfigs>[];
  o.add(buildDynamicScopedRouteConfigs());
  o.add(buildDynamicScopedRouteConfigs());
  return o;
}

void checkUnnamed2500(core.List<api.DynamicScopedRouteConfigs> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDynamicScopedRouteConfigs(o[0] as api.DynamicScopedRouteConfigs);
  checkDynamicScopedRouteConfigs(o[1] as api.DynamicScopedRouteConfigs);
}

core.List<api.InlineScopedRouteConfigs> buildUnnamed2501() {
  var o = <api.InlineScopedRouteConfigs>[];
  o.add(buildInlineScopedRouteConfigs());
  o.add(buildInlineScopedRouteConfigs());
  return o;
}

void checkUnnamed2501(core.List<api.InlineScopedRouteConfigs> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInlineScopedRouteConfigs(o[0] as api.InlineScopedRouteConfigs);
  checkInlineScopedRouteConfigs(o[1] as api.InlineScopedRouteConfigs);
}

core.int buildCounterScopedRoutesConfigDump = 0;
api.ScopedRoutesConfigDump buildScopedRoutesConfigDump() {
  var o = api.ScopedRoutesConfigDump();
  buildCounterScopedRoutesConfigDump++;
  if (buildCounterScopedRoutesConfigDump < 3) {
    o.dynamicScopedRouteConfigs = buildUnnamed2500();
    o.inlineScopedRouteConfigs = buildUnnamed2501();
  }
  buildCounterScopedRoutesConfigDump--;
  return o;
}

void checkScopedRoutesConfigDump(api.ScopedRoutesConfigDump o) {
  buildCounterScopedRoutesConfigDump++;
  if (buildCounterScopedRoutesConfigDump < 3) {
    checkUnnamed2500(o.dynamicScopedRouteConfigs!);
    checkUnnamed2501(o.inlineScopedRouteConfigs!);
  }
  buildCounterScopedRoutesConfigDump--;
}

core.int buildCounterSemanticVersion = 0;
api.SemanticVersion buildSemanticVersion() {
  var o = api.SemanticVersion();
  buildCounterSemanticVersion++;
  if (buildCounterSemanticVersion < 3) {
    o.majorNumber = 42;
    o.minorNumber = 42;
    o.patch = 42;
  }
  buildCounterSemanticVersion--;
  return o;
}

void checkSemanticVersion(api.SemanticVersion o) {
  buildCounterSemanticVersion++;
  if (buildCounterSemanticVersion < 3) {
    unittest.expect(
      o.majorNumber!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minorNumber!,
      unittest.equals(42),
    );
    unittest.expect(
      o.patch!,
      unittest.equals(42),
    );
  }
  buildCounterSemanticVersion--;
}

core.int buildCounterSocketAddress = 0;
api.SocketAddress buildSocketAddress() {
  var o = api.SocketAddress();
  buildCounterSocketAddress++;
  if (buildCounterSocketAddress < 3) {
    o.address = 'foo';
    o.ipv4Compat = true;
    o.namedPort = 'foo';
    o.portValue = 42;
    o.protocol = 'foo';
    o.resolverName = 'foo';
  }
  buildCounterSocketAddress--;
  return o;
}

void checkSocketAddress(api.SocketAddress o) {
  buildCounterSocketAddress++;
  if (buildCounterSocketAddress < 3) {
    unittest.expect(
      o.address!,
      unittest.equals('foo'),
    );
    unittest.expect(o.ipv4Compat!, unittest.isTrue);
    unittest.expect(
      o.namedPort!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.portValue!,
      unittest.equals(42),
    );
    unittest.expect(
      o.protocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resolverName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSocketAddress--;
}

core.Map<core.String, core.Object> buildUnnamed2502() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2502(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted15 = (o['x']!) as core.Map;
  unittest.expect(casted15, unittest.hasLength(3));
  unittest.expect(
    casted15['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted15['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted15['string'],
    unittest.equals('foo'),
  );
  var casted16 = (o['y']!) as core.Map;
  unittest.expect(casted16, unittest.hasLength(3));
  unittest.expect(
    casted16['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted16['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted16['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterStaticCluster = 0;
api.StaticCluster buildStaticCluster() {
  var o = api.StaticCluster();
  buildCounterStaticCluster++;
  if (buildCounterStaticCluster < 3) {
    o.cluster = buildUnnamed2502();
    o.lastUpdated = 'foo';
  }
  buildCounterStaticCluster--;
  return o;
}

void checkStaticCluster(api.StaticCluster o) {
  buildCounterStaticCluster++;
  if (buildCounterStaticCluster < 3) {
    checkUnnamed2502(o.cluster!);
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
  }
  buildCounterStaticCluster--;
}

core.Map<core.String, core.Object> buildUnnamed2503() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2503(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted17 = (o['x']!) as core.Map;
  unittest.expect(casted17, unittest.hasLength(3));
  unittest.expect(
    casted17['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted17['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted17['string'],
    unittest.equals('foo'),
  );
  var casted18 = (o['y']!) as core.Map;
  unittest.expect(casted18, unittest.hasLength(3));
  unittest.expect(
    casted18['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted18['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted18['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterStaticListener = 0;
api.StaticListener buildStaticListener() {
  var o = api.StaticListener();
  buildCounterStaticListener++;
  if (buildCounterStaticListener < 3) {
    o.lastUpdated = 'foo';
    o.listener = buildUnnamed2503();
  }
  buildCounterStaticListener--;
  return o;
}

void checkStaticListener(api.StaticListener o) {
  buildCounterStaticListener++;
  if (buildCounterStaticListener < 3) {
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
    checkUnnamed2503(o.listener!);
  }
  buildCounterStaticListener--;
}

core.Map<core.String, core.Object> buildUnnamed2504() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2504(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted19 = (o['x']!) as core.Map;
  unittest.expect(casted19, unittest.hasLength(3));
  unittest.expect(
    casted19['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted19['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted19['string'],
    unittest.equals('foo'),
  );
  var casted20 = (o['y']!) as core.Map;
  unittest.expect(casted20, unittest.hasLength(3));
  unittest.expect(
    casted20['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted20['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted20['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterStaticRouteConfig = 0;
api.StaticRouteConfig buildStaticRouteConfig() {
  var o = api.StaticRouteConfig();
  buildCounterStaticRouteConfig++;
  if (buildCounterStaticRouteConfig < 3) {
    o.lastUpdated = 'foo';
    o.routeConfig = buildUnnamed2504();
  }
  buildCounterStaticRouteConfig--;
  return o;
}

void checkStaticRouteConfig(api.StaticRouteConfig o) {
  buildCounterStaticRouteConfig++;
  if (buildCounterStaticRouteConfig < 3) {
    unittest.expect(
      o.lastUpdated!,
      unittest.equals('foo'),
    );
    checkUnnamed2504(o.routeConfig!);
  }
  buildCounterStaticRouteConfig--;
}

core.int buildCounterStringMatcher = 0;
api.StringMatcher buildStringMatcher() {
  var o = api.StringMatcher();
  buildCounterStringMatcher++;
  if (buildCounterStringMatcher < 3) {
    o.exact = 'foo';
    o.ignoreCase = true;
    o.prefix = 'foo';
    o.regex = 'foo';
    o.safeRegex = buildRegexMatcher();
    o.suffix = 'foo';
  }
  buildCounterStringMatcher--;
  return o;
}

void checkStringMatcher(api.StringMatcher o) {
  buildCounterStringMatcher++;
  if (buildCounterStringMatcher < 3) {
    unittest.expect(
      o.exact!,
      unittest.equals('foo'),
    );
    unittest.expect(o.ignoreCase!, unittest.isTrue);
    unittest.expect(
      o.prefix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.regex!,
      unittest.equals('foo'),
    );
    checkRegexMatcher(o.safeRegex! as api.RegexMatcher);
    unittest.expect(
      o.suffix!,
      unittest.equals('foo'),
    );
  }
  buildCounterStringMatcher--;
}

core.List<api.PathSegment> buildUnnamed2505() {
  var o = <api.PathSegment>[];
  o.add(buildPathSegment());
  o.add(buildPathSegment());
  return o;
}

void checkUnnamed2505(core.List<api.PathSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPathSegment(o[0] as api.PathSegment);
  checkPathSegment(o[1] as api.PathSegment);
}

core.int buildCounterStructMatcher = 0;
api.StructMatcher buildStructMatcher() {
  var o = api.StructMatcher();
  buildCounterStructMatcher++;
  if (buildCounterStructMatcher < 3) {
    o.path = buildUnnamed2505();
    o.value = buildValueMatcher();
  }
  buildCounterStructMatcher--;
  return o;
}

void checkStructMatcher(api.StructMatcher o) {
  buildCounterStructMatcher++;
  if (buildCounterStructMatcher < 3) {
    checkUnnamed2505(o.path!);
    checkValueMatcher(o.value! as api.ValueMatcher);
  }
  buildCounterStructMatcher--;
}

core.Map<core.String, core.Object> buildUnnamed2506() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed2506(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted21 = (o['x']!) as core.Map;
  unittest.expect(casted21, unittest.hasLength(3));
  unittest.expect(
    casted21['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted21['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted21['string'],
    unittest.equals('foo'),
  );
  var casted22 = (o['y']!) as core.Map;
  unittest.expect(casted22, unittest.hasLength(3));
  unittest.expect(
    casted22['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted22['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted22['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterUpdateFailureState = 0;
api.UpdateFailureState buildUpdateFailureState() {
  var o = api.UpdateFailureState();
  buildCounterUpdateFailureState++;
  if (buildCounterUpdateFailureState < 3) {
    o.details = 'foo';
    o.failedConfiguration = buildUnnamed2506();
    o.lastUpdateAttempt = 'foo';
  }
  buildCounterUpdateFailureState--;
  return o;
}

void checkUpdateFailureState(api.UpdateFailureState o) {
  buildCounterUpdateFailureState++;
  if (buildCounterUpdateFailureState < 3) {
    unittest.expect(
      o.details!,
      unittest.equals('foo'),
    );
    checkUnnamed2506(o.failedConfiguration!);
    unittest.expect(
      o.lastUpdateAttempt!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateFailureState--;
}

core.int buildCounterValueMatcher = 0;
api.ValueMatcher buildValueMatcher() {
  var o = api.ValueMatcher();
  buildCounterValueMatcher++;
  if (buildCounterValueMatcher < 3) {
    o.boolMatch = true;
    o.doubleMatch = buildDoubleMatcher();
    o.listMatch = buildListMatcher();
    o.nullMatch = buildNullMatch();
    o.presentMatch = true;
    o.stringMatch = buildStringMatcher();
  }
  buildCounterValueMatcher--;
  return o;
}

void checkValueMatcher(api.ValueMatcher o) {
  buildCounterValueMatcher++;
  if (buildCounterValueMatcher < 3) {
    unittest.expect(o.boolMatch!, unittest.isTrue);
    checkDoubleMatcher(o.doubleMatch! as api.DoubleMatcher);
    checkListMatcher(o.listMatch! as api.ListMatcher);
    checkNullMatch(o.nullMatch! as api.NullMatch);
    unittest.expect(o.presentMatch!, unittest.isTrue);
    checkStringMatcher(o.stringMatch! as api.StringMatcher);
  }
  buildCounterValueMatcher--;
}

void main() {
  unittest.group('obj-schema-Address', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Address.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAddress(od as api.Address);
    });
  });

  unittest.group('obj-schema-BuildVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildVersion(od as api.BuildVersion);
    });
  });

  unittest.group('obj-schema-ClientConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClientConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClientConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClientConfig(od as api.ClientConfig);
    });
  });

  unittest.group('obj-schema-ClientStatusRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClientStatusRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClientStatusRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClientStatusRequest(od as api.ClientStatusRequest);
    });
  });

  unittest.group('obj-schema-ClientStatusResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClientStatusResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClientStatusResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClientStatusResponse(od as api.ClientStatusResponse);
    });
  });

  unittest.group('obj-schema-ClustersConfigDump', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClustersConfigDump();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClustersConfigDump.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClustersConfigDump(od as api.ClustersConfigDump);
    });
  });

  unittest.group('obj-schema-DoubleMatcher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleMatcher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleMatcher.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleMatcher(od as api.DoubleMatcher);
    });
  });

  unittest.group('obj-schema-DoubleRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleRange(od as api.DoubleRange);
    });
  });

  unittest.group('obj-schema-DynamicCluster', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicCluster();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicCluster.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicCluster(od as api.DynamicCluster);
    });
  });

  unittest.group('obj-schema-DynamicListener', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicListener();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicListener.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicListener(od as api.DynamicListener);
    });
  });

  unittest.group('obj-schema-DynamicListenerState', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicListenerState();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicListenerState.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicListenerState(od as api.DynamicListenerState);
    });
  });

  unittest.group('obj-schema-DynamicRouteConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicRouteConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicRouteConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicRouteConfig(od as api.DynamicRouteConfig);
    });
  });

  unittest.group('obj-schema-DynamicScopedRouteConfigs', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDynamicScopedRouteConfigs();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DynamicScopedRouteConfigs.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDynamicScopedRouteConfigs(od as api.DynamicScopedRouteConfigs);
    });
  });

  unittest.group('obj-schema-Extension', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExtension();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Extension.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExtension(od as api.Extension);
    });
  });

  unittest.group('obj-schema-GoogleRE2', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleRE2();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleRE2.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleRE2(od as api.GoogleRE2);
    });
  });

  unittest.group('obj-schema-InlineScopedRouteConfigs', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInlineScopedRouteConfigs();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InlineScopedRouteConfigs.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInlineScopedRouteConfigs(od as api.InlineScopedRouteConfigs);
    });
  });

  unittest.group('obj-schema-ListMatcher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListMatcher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListMatcher.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListMatcher(od as api.ListMatcher);
    });
  });

  unittest.group('obj-schema-ListenersConfigDump', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListenersConfigDump();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListenersConfigDump.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListenersConfigDump(od as api.ListenersConfigDump);
    });
  });

  unittest.group('obj-schema-Locality', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocality();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Locality.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocality(od as api.Locality);
    });
  });

  unittest.group('obj-schema-Node', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Node.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkNode(od as api.Node);
    });
  });

  unittest.group('obj-schema-NodeMatcher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNodeMatcher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NodeMatcher.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNodeMatcher(od as api.NodeMatcher);
    });
  });

  unittest.group('obj-schema-NullMatch', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNullMatch();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.NullMatch.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkNullMatch(od as api.NullMatch);
    });
  });

  unittest.group('obj-schema-PathSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPathSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PathSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPathSegment(od as api.PathSegment);
    });
  });

  unittest.group('obj-schema-PerXdsConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPerXdsConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PerXdsConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPerXdsConfig(od as api.PerXdsConfig);
    });
  });

  unittest.group('obj-schema-Pipe', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPipe();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Pipe.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPipe(od as api.Pipe);
    });
  });

  unittest.group('obj-schema-RegexMatcher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegexMatcher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RegexMatcher.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegexMatcher(od as api.RegexMatcher);
    });
  });

  unittest.group('obj-schema-RoutesConfigDump', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoutesConfigDump();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RoutesConfigDump.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRoutesConfigDump(od as api.RoutesConfigDump);
    });
  });

  unittest.group('obj-schema-ScopedRoutesConfigDump', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScopedRoutesConfigDump();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScopedRoutesConfigDump.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScopedRoutesConfigDump(od as api.ScopedRoutesConfigDump);
    });
  });

  unittest.group('obj-schema-SemanticVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSemanticVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SemanticVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSemanticVersion(od as api.SemanticVersion);
    });
  });

  unittest.group('obj-schema-SocketAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSocketAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SocketAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSocketAddress(od as api.SocketAddress);
    });
  });

  unittest.group('obj-schema-StaticCluster', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStaticCluster();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StaticCluster.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStaticCluster(od as api.StaticCluster);
    });
  });

  unittest.group('obj-schema-StaticListener', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStaticListener();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StaticListener.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStaticListener(od as api.StaticListener);
    });
  });

  unittest.group('obj-schema-StaticRouteConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStaticRouteConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StaticRouteConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStaticRouteConfig(od as api.StaticRouteConfig);
    });
  });

  unittest.group('obj-schema-StringMatcher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStringMatcher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StringMatcher.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStringMatcher(od as api.StringMatcher);
    });
  });

  unittest.group('obj-schema-StructMatcher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStructMatcher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StructMatcher.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStructMatcher(od as api.StructMatcher);
    });
  });

  unittest.group('obj-schema-UpdateFailureState', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateFailureState();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateFailureState.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateFailureState(od as api.UpdateFailureState);
    });
  });

  unittest.group('obj-schema-ValueMatcher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValueMatcher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValueMatcher.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValueMatcher(od as api.ValueMatcher);
    });
  });

  unittest.group('resource-DiscoveryResource', () {
    unittest.test('method--clientStatus', () async {
      var mock = HttpServerMock();
      var res = api.TrafficDirectorServiceApi(mock).discovery;
      var arg_request = buildClientStatusRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClientStatusRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClientStatusRequest(obj as api.ClientStatusRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("v2/discovery:client_status"),
        );
        pathOffset += 26;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildClientStatusResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.clientStatus(arg_request, $fields: arg_$fields);
      checkClientStatusResponse(response as api.ClientStatusResponse);
    });
  });
}
