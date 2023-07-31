// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';

Map<Uri, List<Annotation>> computeAnnotationsPerUri<T>(
    Map<Uri, AnnotatedCode> annotatedCode,
    Map<String, MemberAnnotations<IdValue>> expectedMaps,
    Uri mainUri,
    Map<String, Map<Uri, Map<Id, ActualData<T>>>> actualData,
    DataInterpreter<T> dataInterpreter,
    {Annotation? Function(Annotation? expected, Annotation? actual)? createDiff,
    bool forceUpdate = false}) {
  Set<Uri> uriSet = {};
  Set<String> actualMarkers = actualData.keys.toSet();
  Map<Uri, Map<Id, Map<String, IdValue>>> idValuePerUri = {};
  Map<Uri, Map<Id, Map<String, ActualData<T>>>> actualDataPerUri = {};

  void addData(String marker, Uri? uri, Map<Id, IdValue> data) {
    if (uri == null) {
      // TODO(johnniwinther): Avoid `null` URIs.
      assert(data.isEmpty, "Non-empty data without uri: $data");
      return;
    }
    uriSet.add(uri);
    Map<Id, Map<String, IdValue>> idValuePerId = idValuePerUri[uri] ??= {};
    data.forEach((Id id, IdValue value) {
      Map<String, IdValue> idValuePerMarker = idValuePerId[id] ??= {};
      idValuePerMarker[marker] = value;
    });
  }

  expectedMaps.forEach((String marker, MemberAnnotations<IdValue> annotations) {
    annotations.forEach((Uri uri, Map<Id, IdValue> data) {
      addData(marker, uri, data);
    });
    addData(marker, mainUri, annotations.globalData);
  });

  actualData
      .forEach((String marker, Map<Uri, Map<Id, ActualData<T>>> dataPerUri) {
    dataPerUri.forEach((Uri uri, Map<Id, ActualData<T>> dataMap) {
      // ignore: unnecessary_null_comparison
      if (uri == null) {
        // TODO(johnniwinther): Avoid `null` URIs.
        assert(dataMap.isEmpty, "Non-empty data for `null` uri: $dataMap");
        return;
      }
      uriSet.add(uri);
      dataMap.forEach((Id id, ActualData<T> data) {
        Map<Id, Map<String, ActualData<T>>> actualDataPerId =
            actualDataPerUri[uri] ??= {};
        Map<String, ActualData<T>> actualDataPerMarker =
            actualDataPerId[id] ??= {};
        actualDataPerMarker[marker] = data;
      });
    });
  });

  Map<Uri, List<Annotation>> result = {};
  for (Uri uri in uriSet) {
    Map<Id, Map<String, IdValue>> idValuePerId = idValuePerUri[uri] ?? {};
    Map<Id, Map<String, ActualData<T>>> actualDataPerId =
        actualDataPerUri[uri] ?? {};
    AnnotatedCode? code = annotatedCode[uri];
    if (code != null) {
      // Annotations are not computed from synthesized code.
      result[uri] = _computeAnnotations(code, expectedMaps.keys, actualMarkers,
          idValuePerId, actualDataPerId, dataInterpreter,
          sortMarkers: false, createDiff: createDiff, forceUpdate: forceUpdate);
    }
  }
  return result;
}

List<Annotation> _computeAnnotations<T>(
    AnnotatedCode annotatedCode,
    Iterable<String> supportedMarkers,
    Set<String> actualMarkers,
    Map<Id, Map<String, IdValue>> idValuePerId,
    Map<Id, Map<String, ActualData<T>>> actualDataPerId,
    DataInterpreter<T> dataInterpreter,
    {String defaultPrefix = '/*',
    String defaultSuffix = '*/',
    bool sortMarkers = true,
    Annotation? Function(Annotation? expected, Annotation? actual)? createDiff,
    bool forceUpdate = false}) {
  // ignore: unnecessary_null_comparison
  assert(annotatedCode != null);

  Annotation createAnnotationFromData(
      ActualData<T> actualData, Annotation? annotation) {
    String getIndentationFromOffset(int offset) {
      int lineIndex = annotatedCode.getLineIndex(offset);
      String line = annotatedCode.getLine(lineIndex);
      String trimmed = line.trimLeft();
      return line.substring(0, line.length - trimmed.length);
    }

    int offset;
    String prefix;
    String suffix;
    String indentation;
    if (annotation != null) {
      offset = annotation.offset;
      prefix = annotation.prefix;
      suffix = annotation.suffix;
      indentation = getIndentationFromOffset(offset);
    } else {
      Id id = actualData.id;
      if (id is NodeId) {
        offset = id.value;
        prefix = defaultPrefix;
        suffix = defaultSuffix;
        indentation = getIndentationFromOffset(offset);
      } else if (id is ClassId || id is MemberId) {
        // Place the annotation at the line above at the indentation level of
        // the class/member.
        int lineIndex = annotatedCode.getLineIndex(actualData.offset);
        String line = annotatedCode.getLine(lineIndex);
        String trimmed = line.trimLeft();
        indentation = line.substring(0, line.length - trimmed.length);
        offset = annotatedCode.getLineStart(lineIndex);
        prefix = '$indentation$defaultPrefix';
        suffix = '$defaultSuffix\n';
      } else if (id is LibraryId) {
        // Place the annotation on its own line after the copyright comments.
        int lineIndex = 0;
        while (lineIndex < annotatedCode.lineCount) {
          String line = annotatedCode.getLine(lineIndex);
          if (!line.startsWith('//')) {
            break;
          }
          lineIndex++;
        }
        offset = annotatedCode.getLineStart(lineIndex);
        prefix = '\n$defaultPrefix';
        suffix = '$defaultSuffix\n';
        indentation = '';
      } else {
        throw 'Unexpected id $id (${id.runtimeType})';
      }
    }

    return new Annotation(
        annotation?.index,
        annotation?.lineNo ?? -1,
        annotation?.columnNo ?? -1,
        offset,
        prefix,
        IdValue.idToString(actualData.id,
            dataInterpreter.getText(actualData.value, indentation)),
        suffix);
  }

  Set<Id> idSet = {}
    ..addAll(idValuePerId.keys)
    ..addAll(actualDataPerId.keys);
  List<Annotation> result = <Annotation>[];
  for (Id id in idSet) {
    Map<String, IdValue> idValuePerMarker = idValuePerId[id] ?? {};
    Map<String, ActualData<T>> actualDataPerMarker = actualDataPerId[id] ?? {};

    Map<String, Annotation> newAnnotationsPerMarker = {};
    for (String marker in supportedMarkers) {
      IdValue? idValue = idValuePerMarker[marker];
      ActualData<T>? actualData = actualDataPerMarker[marker];
      Annotation? expectedAnnotation;
      Annotation? actualAnnotation;
      if (idValue != null && actualData != null) {
        if (dataInterpreter.isAsExpected(actualData.value, idValue.value) ==
                null &&
            !forceUpdate) {
          // Use existing annotation.
          expectedAnnotation = actualAnnotation = idValue.annotation;
        } else {
          expectedAnnotation = idValue.annotation;
          actualAnnotation =
              createAnnotationFromData(actualData, idValue.annotation);
        }
      } else if (idValue != null && !actualMarkers.contains(marker)) {
        // Use existing annotation if no actual data is provided for this
        // marker.
        expectedAnnotation = actualAnnotation = idValue.annotation;
      } else if (actualData != null) {
        if (dataInterpreter.isAsExpected(actualData.value, null) != null) {
          // Insert annotation if the actual value is not equivalent to an
          // empty value.
          actualAnnotation = createAnnotationFromData(actualData, null);
        }
      }
      Annotation? annotation = createDiff != null
          ? createDiff(expectedAnnotation, actualAnnotation)
          : actualAnnotation;
      if (annotation != null) {
        newAnnotationsPerMarker[marker] = annotation;
      }
    }

    Map<String, Map<String, Annotation>> groupedByText = {};
    newAnnotationsPerMarker.forEach((String marker, Annotation annotation) {
      Map<String, Annotation> byText = groupedByText[annotation.text] ??= {};
      byText[marker] = annotation;
    });
    groupedByText.forEach((String text, Map<String, Annotation> annotations) {
      Set<String> markers = annotations.keys.toSet();
      if (markers.isNotEmpty) {
        String prefix;
        if (markers.length == supportedMarkers.length) {
          // Don't use prefix for annotations that match all markers.
          prefix = '';
        } else {
          Iterable<String> usedMarkers = markers;
          if (sortMarkers) {
            usedMarkers = usedMarkers.toList()..sort();
          }
          prefix = '${usedMarkers.join('|')}.';
        }
        Annotation firstAnnotation = annotations.values.first;
        result.add(new Annotation(
            firstAnnotation.index,
            firstAnnotation.lineNo,
            firstAnnotation.columnNo,
            firstAnnotation.offset,
            firstAnnotation.prefix,
            '$prefix$text',
            firstAnnotation.suffix));
      }
    });
  }
  return result;
}

bool setEquals<E>(Set<E> a, Set<E> b) {
  return a.length == b.length && a.containsAll(b);
}
