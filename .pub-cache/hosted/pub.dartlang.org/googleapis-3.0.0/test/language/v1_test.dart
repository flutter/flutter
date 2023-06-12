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

import 'package:googleapis/language/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAnalyzeEntitiesRequest = 0;
api.AnalyzeEntitiesRequest buildAnalyzeEntitiesRequest() {
  var o = api.AnalyzeEntitiesRequest();
  buildCounterAnalyzeEntitiesRequest++;
  if (buildCounterAnalyzeEntitiesRequest < 3) {
    o.document = buildDocument();
    o.encodingType = 'foo';
  }
  buildCounterAnalyzeEntitiesRequest--;
  return o;
}

void checkAnalyzeEntitiesRequest(api.AnalyzeEntitiesRequest o) {
  buildCounterAnalyzeEntitiesRequest++;
  if (buildCounterAnalyzeEntitiesRequest < 3) {
    checkDocument(o.document! as api.Document);
    unittest.expect(
      o.encodingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzeEntitiesRequest--;
}

core.List<api.Entity> buildUnnamed2912() {
  var o = <api.Entity>[];
  o.add(buildEntity());
  o.add(buildEntity());
  return o;
}

void checkUnnamed2912(core.List<api.Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntity(o[0] as api.Entity);
  checkEntity(o[1] as api.Entity);
}

core.int buildCounterAnalyzeEntitiesResponse = 0;
api.AnalyzeEntitiesResponse buildAnalyzeEntitiesResponse() {
  var o = api.AnalyzeEntitiesResponse();
  buildCounterAnalyzeEntitiesResponse++;
  if (buildCounterAnalyzeEntitiesResponse < 3) {
    o.entities = buildUnnamed2912();
    o.language = 'foo';
  }
  buildCounterAnalyzeEntitiesResponse--;
  return o;
}

void checkAnalyzeEntitiesResponse(api.AnalyzeEntitiesResponse o) {
  buildCounterAnalyzeEntitiesResponse++;
  if (buildCounterAnalyzeEntitiesResponse < 3) {
    checkUnnamed2912(o.entities!);
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzeEntitiesResponse--;
}

core.int buildCounterAnalyzeEntitySentimentRequest = 0;
api.AnalyzeEntitySentimentRequest buildAnalyzeEntitySentimentRequest() {
  var o = api.AnalyzeEntitySentimentRequest();
  buildCounterAnalyzeEntitySentimentRequest++;
  if (buildCounterAnalyzeEntitySentimentRequest < 3) {
    o.document = buildDocument();
    o.encodingType = 'foo';
  }
  buildCounterAnalyzeEntitySentimentRequest--;
  return o;
}

void checkAnalyzeEntitySentimentRequest(api.AnalyzeEntitySentimentRequest o) {
  buildCounterAnalyzeEntitySentimentRequest++;
  if (buildCounterAnalyzeEntitySentimentRequest < 3) {
    checkDocument(o.document! as api.Document);
    unittest.expect(
      o.encodingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzeEntitySentimentRequest--;
}

core.List<api.Entity> buildUnnamed2913() {
  var o = <api.Entity>[];
  o.add(buildEntity());
  o.add(buildEntity());
  return o;
}

void checkUnnamed2913(core.List<api.Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntity(o[0] as api.Entity);
  checkEntity(o[1] as api.Entity);
}

core.int buildCounterAnalyzeEntitySentimentResponse = 0;
api.AnalyzeEntitySentimentResponse buildAnalyzeEntitySentimentResponse() {
  var o = api.AnalyzeEntitySentimentResponse();
  buildCounterAnalyzeEntitySentimentResponse++;
  if (buildCounterAnalyzeEntitySentimentResponse < 3) {
    o.entities = buildUnnamed2913();
    o.language = 'foo';
  }
  buildCounterAnalyzeEntitySentimentResponse--;
  return o;
}

void checkAnalyzeEntitySentimentResponse(api.AnalyzeEntitySentimentResponse o) {
  buildCounterAnalyzeEntitySentimentResponse++;
  if (buildCounterAnalyzeEntitySentimentResponse < 3) {
    checkUnnamed2913(o.entities!);
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzeEntitySentimentResponse--;
}

core.int buildCounterAnalyzeSentimentRequest = 0;
api.AnalyzeSentimentRequest buildAnalyzeSentimentRequest() {
  var o = api.AnalyzeSentimentRequest();
  buildCounterAnalyzeSentimentRequest++;
  if (buildCounterAnalyzeSentimentRequest < 3) {
    o.document = buildDocument();
    o.encodingType = 'foo';
  }
  buildCounterAnalyzeSentimentRequest--;
  return o;
}

void checkAnalyzeSentimentRequest(api.AnalyzeSentimentRequest o) {
  buildCounterAnalyzeSentimentRequest++;
  if (buildCounterAnalyzeSentimentRequest < 3) {
    checkDocument(o.document! as api.Document);
    unittest.expect(
      o.encodingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzeSentimentRequest--;
}

core.List<api.Sentence> buildUnnamed2914() {
  var o = <api.Sentence>[];
  o.add(buildSentence());
  o.add(buildSentence());
  return o;
}

void checkUnnamed2914(core.List<api.Sentence> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSentence(o[0] as api.Sentence);
  checkSentence(o[1] as api.Sentence);
}

core.int buildCounterAnalyzeSentimentResponse = 0;
api.AnalyzeSentimentResponse buildAnalyzeSentimentResponse() {
  var o = api.AnalyzeSentimentResponse();
  buildCounterAnalyzeSentimentResponse++;
  if (buildCounterAnalyzeSentimentResponse < 3) {
    o.documentSentiment = buildSentiment();
    o.language = 'foo';
    o.sentences = buildUnnamed2914();
  }
  buildCounterAnalyzeSentimentResponse--;
  return o;
}

void checkAnalyzeSentimentResponse(api.AnalyzeSentimentResponse o) {
  buildCounterAnalyzeSentimentResponse++;
  if (buildCounterAnalyzeSentimentResponse < 3) {
    checkSentiment(o.documentSentiment! as api.Sentiment);
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    checkUnnamed2914(o.sentences!);
  }
  buildCounterAnalyzeSentimentResponse--;
}

core.int buildCounterAnalyzeSyntaxRequest = 0;
api.AnalyzeSyntaxRequest buildAnalyzeSyntaxRequest() {
  var o = api.AnalyzeSyntaxRequest();
  buildCounterAnalyzeSyntaxRequest++;
  if (buildCounterAnalyzeSyntaxRequest < 3) {
    o.document = buildDocument();
    o.encodingType = 'foo';
  }
  buildCounterAnalyzeSyntaxRequest--;
  return o;
}

void checkAnalyzeSyntaxRequest(api.AnalyzeSyntaxRequest o) {
  buildCounterAnalyzeSyntaxRequest++;
  if (buildCounterAnalyzeSyntaxRequest < 3) {
    checkDocument(o.document! as api.Document);
    unittest.expect(
      o.encodingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnalyzeSyntaxRequest--;
}

core.List<api.Sentence> buildUnnamed2915() {
  var o = <api.Sentence>[];
  o.add(buildSentence());
  o.add(buildSentence());
  return o;
}

void checkUnnamed2915(core.List<api.Sentence> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSentence(o[0] as api.Sentence);
  checkSentence(o[1] as api.Sentence);
}

core.List<api.Token> buildUnnamed2916() {
  var o = <api.Token>[];
  o.add(buildToken());
  o.add(buildToken());
  return o;
}

void checkUnnamed2916(core.List<api.Token> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkToken(o[0] as api.Token);
  checkToken(o[1] as api.Token);
}

core.int buildCounterAnalyzeSyntaxResponse = 0;
api.AnalyzeSyntaxResponse buildAnalyzeSyntaxResponse() {
  var o = api.AnalyzeSyntaxResponse();
  buildCounterAnalyzeSyntaxResponse++;
  if (buildCounterAnalyzeSyntaxResponse < 3) {
    o.language = 'foo';
    o.sentences = buildUnnamed2915();
    o.tokens = buildUnnamed2916();
  }
  buildCounterAnalyzeSyntaxResponse--;
  return o;
}

void checkAnalyzeSyntaxResponse(api.AnalyzeSyntaxResponse o) {
  buildCounterAnalyzeSyntaxResponse++;
  if (buildCounterAnalyzeSyntaxResponse < 3) {
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    checkUnnamed2915(o.sentences!);
    checkUnnamed2916(o.tokens!);
  }
  buildCounterAnalyzeSyntaxResponse--;
}

core.int buildCounterAnnotateTextRequest = 0;
api.AnnotateTextRequest buildAnnotateTextRequest() {
  var o = api.AnnotateTextRequest();
  buildCounterAnnotateTextRequest++;
  if (buildCounterAnnotateTextRequest < 3) {
    o.document = buildDocument();
    o.encodingType = 'foo';
    o.features = buildFeatures();
  }
  buildCounterAnnotateTextRequest--;
  return o;
}

void checkAnnotateTextRequest(api.AnnotateTextRequest o) {
  buildCounterAnnotateTextRequest++;
  if (buildCounterAnnotateTextRequest < 3) {
    checkDocument(o.document! as api.Document);
    unittest.expect(
      o.encodingType!,
      unittest.equals('foo'),
    );
    checkFeatures(o.features! as api.Features);
  }
  buildCounterAnnotateTextRequest--;
}

core.List<api.ClassificationCategory> buildUnnamed2917() {
  var o = <api.ClassificationCategory>[];
  o.add(buildClassificationCategory());
  o.add(buildClassificationCategory());
  return o;
}

void checkUnnamed2917(core.List<api.ClassificationCategory> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkClassificationCategory(o[0] as api.ClassificationCategory);
  checkClassificationCategory(o[1] as api.ClassificationCategory);
}

core.List<api.Entity> buildUnnamed2918() {
  var o = <api.Entity>[];
  o.add(buildEntity());
  o.add(buildEntity());
  return o;
}

void checkUnnamed2918(core.List<api.Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntity(o[0] as api.Entity);
  checkEntity(o[1] as api.Entity);
}

core.List<api.Sentence> buildUnnamed2919() {
  var o = <api.Sentence>[];
  o.add(buildSentence());
  o.add(buildSentence());
  return o;
}

void checkUnnamed2919(core.List<api.Sentence> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSentence(o[0] as api.Sentence);
  checkSentence(o[1] as api.Sentence);
}

core.List<api.Token> buildUnnamed2920() {
  var o = <api.Token>[];
  o.add(buildToken());
  o.add(buildToken());
  return o;
}

void checkUnnamed2920(core.List<api.Token> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkToken(o[0] as api.Token);
  checkToken(o[1] as api.Token);
}

core.int buildCounterAnnotateTextResponse = 0;
api.AnnotateTextResponse buildAnnotateTextResponse() {
  var o = api.AnnotateTextResponse();
  buildCounterAnnotateTextResponse++;
  if (buildCounterAnnotateTextResponse < 3) {
    o.categories = buildUnnamed2917();
    o.documentSentiment = buildSentiment();
    o.entities = buildUnnamed2918();
    o.language = 'foo';
    o.sentences = buildUnnamed2919();
    o.tokens = buildUnnamed2920();
  }
  buildCounterAnnotateTextResponse--;
  return o;
}

void checkAnnotateTextResponse(api.AnnotateTextResponse o) {
  buildCounterAnnotateTextResponse++;
  if (buildCounterAnnotateTextResponse < 3) {
    checkUnnamed2917(o.categories!);
    checkSentiment(o.documentSentiment! as api.Sentiment);
    checkUnnamed2918(o.entities!);
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    checkUnnamed2919(o.sentences!);
    checkUnnamed2920(o.tokens!);
  }
  buildCounterAnnotateTextResponse--;
}

core.int buildCounterClassificationCategory = 0;
api.ClassificationCategory buildClassificationCategory() {
  var o = api.ClassificationCategory();
  buildCounterClassificationCategory++;
  if (buildCounterClassificationCategory < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
  }
  buildCounterClassificationCategory--;
  return o;
}

void checkClassificationCategory(api.ClassificationCategory o) {
  buildCounterClassificationCategory++;
  if (buildCounterClassificationCategory < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterClassificationCategory--;
}

core.int buildCounterClassifyTextRequest = 0;
api.ClassifyTextRequest buildClassifyTextRequest() {
  var o = api.ClassifyTextRequest();
  buildCounterClassifyTextRequest++;
  if (buildCounterClassifyTextRequest < 3) {
    o.document = buildDocument();
  }
  buildCounterClassifyTextRequest--;
  return o;
}

void checkClassifyTextRequest(api.ClassifyTextRequest o) {
  buildCounterClassifyTextRequest++;
  if (buildCounterClassifyTextRequest < 3) {
    checkDocument(o.document! as api.Document);
  }
  buildCounterClassifyTextRequest--;
}

core.List<api.ClassificationCategory> buildUnnamed2921() {
  var o = <api.ClassificationCategory>[];
  o.add(buildClassificationCategory());
  o.add(buildClassificationCategory());
  return o;
}

void checkUnnamed2921(core.List<api.ClassificationCategory> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkClassificationCategory(o[0] as api.ClassificationCategory);
  checkClassificationCategory(o[1] as api.ClassificationCategory);
}

core.int buildCounterClassifyTextResponse = 0;
api.ClassifyTextResponse buildClassifyTextResponse() {
  var o = api.ClassifyTextResponse();
  buildCounterClassifyTextResponse++;
  if (buildCounterClassifyTextResponse < 3) {
    o.categories = buildUnnamed2921();
  }
  buildCounterClassifyTextResponse--;
  return o;
}

void checkClassifyTextResponse(api.ClassifyTextResponse o) {
  buildCounterClassifyTextResponse++;
  if (buildCounterClassifyTextResponse < 3) {
    checkUnnamed2921(o.categories!);
  }
  buildCounterClassifyTextResponse--;
}

core.int buildCounterDependencyEdge = 0;
api.DependencyEdge buildDependencyEdge() {
  var o = api.DependencyEdge();
  buildCounterDependencyEdge++;
  if (buildCounterDependencyEdge < 3) {
    o.headTokenIndex = 42;
    o.label = 'foo';
  }
  buildCounterDependencyEdge--;
  return o;
}

void checkDependencyEdge(api.DependencyEdge o) {
  buildCounterDependencyEdge++;
  if (buildCounterDependencyEdge < 3) {
    unittest.expect(
      o.headTokenIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
  }
  buildCounterDependencyEdge--;
}

core.int buildCounterDocument = 0;
api.Document buildDocument() {
  var o = api.Document();
  buildCounterDocument++;
  if (buildCounterDocument < 3) {
    o.content = 'foo';
    o.gcsContentUri = 'foo';
    o.language = 'foo';
    o.type = 'foo';
  }
  buildCounterDocument--;
  return o;
}

void checkDocument(api.Document o) {
  buildCounterDocument++;
  if (buildCounterDocument < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gcsContentUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDocument--;
}

core.List<api.EntityMention> buildUnnamed2922() {
  var o = <api.EntityMention>[];
  o.add(buildEntityMention());
  o.add(buildEntityMention());
  return o;
}

void checkUnnamed2922(core.List<api.EntityMention> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntityMention(o[0] as api.EntityMention);
  checkEntityMention(o[1] as api.EntityMention);
}

core.Map<core.String, core.String> buildUnnamed2923() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2923(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterEntity = 0;
api.Entity buildEntity() {
  var o = api.Entity();
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    o.mentions = buildUnnamed2922();
    o.metadata = buildUnnamed2923();
    o.name = 'foo';
    o.salience = 42.0;
    o.sentiment = buildSentiment();
    o.type = 'foo';
  }
  buildCounterEntity--;
  return o;
}

void checkEntity(api.Entity o) {
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    checkUnnamed2922(o.mentions!);
    checkUnnamed2923(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.salience!,
      unittest.equals(42.0),
    );
    checkSentiment(o.sentiment! as api.Sentiment);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterEntity--;
}

core.int buildCounterEntityMention = 0;
api.EntityMention buildEntityMention() {
  var o = api.EntityMention();
  buildCounterEntityMention++;
  if (buildCounterEntityMention < 3) {
    o.sentiment = buildSentiment();
    o.text = buildTextSpan();
    o.type = 'foo';
  }
  buildCounterEntityMention--;
  return o;
}

void checkEntityMention(api.EntityMention o) {
  buildCounterEntityMention++;
  if (buildCounterEntityMention < 3) {
    checkSentiment(o.sentiment! as api.Sentiment);
    checkTextSpan(o.text! as api.TextSpan);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterEntityMention--;
}

core.int buildCounterFeatures = 0;
api.Features buildFeatures() {
  var o = api.Features();
  buildCounterFeatures++;
  if (buildCounterFeatures < 3) {
    o.classifyText = true;
    o.extractDocumentSentiment = true;
    o.extractEntities = true;
    o.extractEntitySentiment = true;
    o.extractSyntax = true;
  }
  buildCounterFeatures--;
  return o;
}

void checkFeatures(api.Features o) {
  buildCounterFeatures++;
  if (buildCounterFeatures < 3) {
    unittest.expect(o.classifyText!, unittest.isTrue);
    unittest.expect(o.extractDocumentSentiment!, unittest.isTrue);
    unittest.expect(o.extractEntities!, unittest.isTrue);
    unittest.expect(o.extractEntitySentiment!, unittest.isTrue);
    unittest.expect(o.extractSyntax!, unittest.isTrue);
  }
  buildCounterFeatures--;
}

core.int buildCounterPartOfSpeech = 0;
api.PartOfSpeech buildPartOfSpeech() {
  var o = api.PartOfSpeech();
  buildCounterPartOfSpeech++;
  if (buildCounterPartOfSpeech < 3) {
    o.aspect = 'foo';
    o.case_ = 'foo';
    o.form = 'foo';
    o.gender = 'foo';
    o.mood = 'foo';
    o.number = 'foo';
    o.person = 'foo';
    o.proper = 'foo';
    o.reciprocity = 'foo';
    o.tag = 'foo';
    o.tense = 'foo';
    o.voice = 'foo';
  }
  buildCounterPartOfSpeech--;
  return o;
}

void checkPartOfSpeech(api.PartOfSpeech o) {
  buildCounterPartOfSpeech++;
  if (buildCounterPartOfSpeech < 3) {
    unittest.expect(
      o.aspect!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.case_!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.form!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gender!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mood!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.number!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.person!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proper!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reciprocity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tense!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.voice!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartOfSpeech--;
}

core.int buildCounterSentence = 0;
api.Sentence buildSentence() {
  var o = api.Sentence();
  buildCounterSentence++;
  if (buildCounterSentence < 3) {
    o.sentiment = buildSentiment();
    o.text = buildTextSpan();
  }
  buildCounterSentence--;
  return o;
}

void checkSentence(api.Sentence o) {
  buildCounterSentence++;
  if (buildCounterSentence < 3) {
    checkSentiment(o.sentiment! as api.Sentiment);
    checkTextSpan(o.text! as api.TextSpan);
  }
  buildCounterSentence--;
}

core.int buildCounterSentiment = 0;
api.Sentiment buildSentiment() {
  var o = api.Sentiment();
  buildCounterSentiment++;
  if (buildCounterSentiment < 3) {
    o.magnitude = 42.0;
    o.score = 42.0;
  }
  buildCounterSentiment--;
  return o;
}

void checkSentiment(api.Sentiment o) {
  buildCounterSentiment++;
  if (buildCounterSentiment < 3) {
    unittest.expect(
      o.magnitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.score!,
      unittest.equals(42.0),
    );
  }
  buildCounterSentiment--;
}

core.Map<core.String, core.Object> buildUnnamed2924() {
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

void checkUnnamed2924(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed2925() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2924());
  o.add(buildUnnamed2924());
  return o;
}

void checkUnnamed2925(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2924(o[0]);
  checkUnnamed2924(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed2925();
    o.message = 'foo';
  }
  buildCounterStatus--;
  return o;
}

void checkStatus(api.Status o) {
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    unittest.expect(
      o.code!,
      unittest.equals(42),
    );
    checkUnnamed2925(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTextSpan = 0;
api.TextSpan buildTextSpan() {
  var o = api.TextSpan();
  buildCounterTextSpan++;
  if (buildCounterTextSpan < 3) {
    o.beginOffset = 42;
    o.content = 'foo';
  }
  buildCounterTextSpan--;
  return o;
}

void checkTextSpan(api.TextSpan o) {
  buildCounterTextSpan++;
  if (buildCounterTextSpan < 3) {
    unittest.expect(
      o.beginOffset!,
      unittest.equals(42),
    );
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
  }
  buildCounterTextSpan--;
}

core.int buildCounterToken = 0;
api.Token buildToken() {
  var o = api.Token();
  buildCounterToken++;
  if (buildCounterToken < 3) {
    o.dependencyEdge = buildDependencyEdge();
    o.lemma = 'foo';
    o.partOfSpeech = buildPartOfSpeech();
    o.text = buildTextSpan();
  }
  buildCounterToken--;
  return o;
}

void checkToken(api.Token o) {
  buildCounterToken++;
  if (buildCounterToken < 3) {
    checkDependencyEdge(o.dependencyEdge! as api.DependencyEdge);
    unittest.expect(
      o.lemma!,
      unittest.equals('foo'),
    );
    checkPartOfSpeech(o.partOfSpeech! as api.PartOfSpeech);
    checkTextSpan(o.text! as api.TextSpan);
  }
  buildCounterToken--;
}

void main() {
  unittest.group('obj-schema-AnalyzeEntitiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeEntitiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeEntitiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeEntitiesRequest(od as api.AnalyzeEntitiesRequest);
    });
  });

  unittest.group('obj-schema-AnalyzeEntitiesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeEntitiesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeEntitiesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeEntitiesResponse(od as api.AnalyzeEntitiesResponse);
    });
  });

  unittest.group('obj-schema-AnalyzeEntitySentimentRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeEntitySentimentRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeEntitySentimentRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeEntitySentimentRequest(
          od as api.AnalyzeEntitySentimentRequest);
    });
  });

  unittest.group('obj-schema-AnalyzeEntitySentimentResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeEntitySentimentResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeEntitySentimentResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeEntitySentimentResponse(
          od as api.AnalyzeEntitySentimentResponse);
    });
  });

  unittest.group('obj-schema-AnalyzeSentimentRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeSentimentRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeSentimentRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeSentimentRequest(od as api.AnalyzeSentimentRequest);
    });
  });

  unittest.group('obj-schema-AnalyzeSentimentResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeSentimentResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeSentimentResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeSentimentResponse(od as api.AnalyzeSentimentResponse);
    });
  });

  unittest.group('obj-schema-AnalyzeSyntaxRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeSyntaxRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeSyntaxRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeSyntaxRequest(od as api.AnalyzeSyntaxRequest);
    });
  });

  unittest.group('obj-schema-AnalyzeSyntaxResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeSyntaxResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeSyntaxResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeSyntaxResponse(od as api.AnalyzeSyntaxResponse);
    });
  });

  unittest.group('obj-schema-AnnotateTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnnotateTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnnotateTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnnotateTextRequest(od as api.AnnotateTextRequest);
    });
  });

  unittest.group('obj-schema-AnnotateTextResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnnotateTextResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnnotateTextResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnnotateTextResponse(od as api.AnnotateTextResponse);
    });
  });

  unittest.group('obj-schema-ClassificationCategory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClassificationCategory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClassificationCategory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClassificationCategory(od as api.ClassificationCategory);
    });
  });

  unittest.group('obj-schema-ClassifyTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClassifyTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClassifyTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClassifyTextRequest(od as api.ClassifyTextRequest);
    });
  });

  unittest.group('obj-schema-ClassifyTextResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClassifyTextResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClassifyTextResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClassifyTextResponse(od as api.ClassifyTextResponse);
    });
  });

  unittest.group('obj-schema-DependencyEdge', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDependencyEdge();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DependencyEdge.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDependencyEdge(od as api.DependencyEdge);
    });
  });

  unittest.group('obj-schema-Document', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocument();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Document.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDocument(od as api.Document);
    });
  });

  unittest.group('obj-schema-Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Entity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEntity(od as api.Entity);
    });
  });

  unittest.group('obj-schema-EntityMention', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityMention();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityMention.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityMention(od as api.EntityMention);
    });
  });

  unittest.group('obj-schema-Features', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatures();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Features.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFeatures(od as api.Features);
    });
  });

  unittest.group('obj-schema-PartOfSpeech', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartOfSpeech();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartOfSpeech.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartOfSpeech(od as api.PartOfSpeech);
    });
  });

  unittest.group('obj-schema-Sentence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSentence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Sentence.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSentence(od as api.Sentence);
    });
  });

  unittest.group('obj-schema-Sentiment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSentiment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Sentiment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSentiment(od as api.Sentiment);
    });
  });

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-TextSpan', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextSpan();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TextSpan.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTextSpan(od as api.TextSpan);
    });
  });

  unittest.group('obj-schema-Token', () {
    unittest.test('to-json--from-json', () async {
      var o = buildToken();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Token.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkToken(od as api.Token);
    });
  });

  unittest.group('resource-DocumentsResource', () {
    unittest.test('method--analyzeEntities', () async {
      var mock = HttpServerMock();
      var res = api.CloudNaturalLanguageApi(mock).documents;
      var arg_request = buildAnalyzeEntitiesRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnalyzeEntitiesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnalyzeEntitiesRequest(obj as api.AnalyzeEntitiesRequest);

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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("v1/documents:analyzeEntities"),
        );
        pathOffset += 28;

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
        var resp = convert.json.encode(buildAnalyzeEntitiesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.analyzeEntities(arg_request, $fields: arg_$fields);
      checkAnalyzeEntitiesResponse(response as api.AnalyzeEntitiesResponse);
    });

    unittest.test('method--analyzeEntitySentiment', () async {
      var mock = HttpServerMock();
      var res = api.CloudNaturalLanguageApi(mock).documents;
      var arg_request = buildAnalyzeEntitySentimentRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnalyzeEntitySentimentRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnalyzeEntitySentimentRequest(
            obj as api.AnalyzeEntitySentimentRequest);

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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("v1/documents:analyzeEntitySentiment"),
        );
        pathOffset += 35;

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
        var resp = convert.json.encode(buildAnalyzeEntitySentimentResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.analyzeEntitySentiment(arg_request, $fields: arg_$fields);
      checkAnalyzeEntitySentimentResponse(
          response as api.AnalyzeEntitySentimentResponse);
    });

    unittest.test('method--analyzeSentiment', () async {
      var mock = HttpServerMock();
      var res = api.CloudNaturalLanguageApi(mock).documents;
      var arg_request = buildAnalyzeSentimentRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnalyzeSentimentRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnalyzeSentimentRequest(obj as api.AnalyzeSentimentRequest);

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
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("v1/documents:analyzeSentiment"),
        );
        pathOffset += 29;

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
        var resp = convert.json.encode(buildAnalyzeSentimentResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.analyzeSentiment(arg_request, $fields: arg_$fields);
      checkAnalyzeSentimentResponse(response as api.AnalyzeSentimentResponse);
    });

    unittest.test('method--analyzeSyntax', () async {
      var mock = HttpServerMock();
      var res = api.CloudNaturalLanguageApi(mock).documents;
      var arg_request = buildAnalyzeSyntaxRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnalyzeSyntaxRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnalyzeSyntaxRequest(obj as api.AnalyzeSyntaxRequest);

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
          unittest.equals("v1/documents:analyzeSyntax"),
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
        var resp = convert.json.encode(buildAnalyzeSyntaxResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.analyzeSyntax(arg_request, $fields: arg_$fields);
      checkAnalyzeSyntaxResponse(response as api.AnalyzeSyntaxResponse);
    });

    unittest.test('method--annotateText', () async {
      var mock = HttpServerMock();
      var res = api.CloudNaturalLanguageApi(mock).documents;
      var arg_request = buildAnnotateTextRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnnotateTextRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnnotateTextRequest(obj as api.AnnotateTextRequest);

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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("v1/documents:annotateText"),
        );
        pathOffset += 25;

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
        var resp = convert.json.encode(buildAnnotateTextResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.annotateText(arg_request, $fields: arg_$fields);
      checkAnnotateTextResponse(response as api.AnnotateTextResponse);
    });

    unittest.test('method--classifyText', () async {
      var mock = HttpServerMock();
      var res = api.CloudNaturalLanguageApi(mock).documents;
      var arg_request = buildClassifyTextRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClassifyTextRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClassifyTextRequest(obj as api.ClassifyTextRequest);

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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("v1/documents:classifyText"),
        );
        pathOffset += 25;

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
        var resp = convert.json.encode(buildClassifyTextResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.classifyText(arg_request, $fields: arg_$fields);
      checkClassifyTextResponse(response as api.ClassifyTextResponse);
    });
  });
}
