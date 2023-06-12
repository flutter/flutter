// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

import '../devtools_api.dart';
import 'file_system.dart';
import 'usage.dart';

/// The DevTools server API.
///
/// This defines endpoints that serve all requests that come in over api/.
class ServerApi {
  static const errorNoActiveSurvey = 'ERROR: setActiveSurvey not called.';

  /// Determines whether or not [request] is an API call.
  static bool canHandle(shelf.Request request) {
    return request.url.path.startsWith(apiPrefix);
  }

  /// Handles all requests.
  ///
  /// To override an API call, pass in a subclass of [ServerApi].
  static FutureOr<shelf.Response> handle(
    shelf.Request request, [
    ServerApi? api,
  ]) {
    api ??= ServerApi();
    switch (request.url.path) {
      // ----- Flutter Tool GA store. -----
      case apiGetFlutterGAEnabled:
        // Is Analytics collection enabled?
        return api.getCompleted(
          request,
          json.encode(FlutterUsage.doesStoreExist ? _usage!.enabled : ''),
        );
      case apiGetFlutterGAClientId:
        // Flutter Tool GA clientId - ONLY get Flutter's clientId if enabled is
        // true.
        return (FlutterUsage.doesStoreExist)
            ? api.getCompleted(
                request,
                json.encode(_usage!.enabled ? _usage!.clientId : ''),
              )
            : api.getCompleted(
                request,
                json.encode(''),
              );

      // ----- DevTools GA store. -----

      case apiResetDevTools:
        _devToolsUsage.reset();
        return api.getCompleted(request, json.encode(true));
      case apiGetDevToolsFirstRun:
        // Has DevTools been run first time? To bring up analytics dialog.
        return api.getCompleted(
          request,
          json.encode(_devToolsUsage.isFirstRun),
        );
      case apiGetDevToolsEnabled:
        // Is DevTools Analytics collection enabled?
        return api.getCompleted(
          request,
          json.encode(_devToolsUsage.analyticsEnabled),
        );
      case apiSetDevToolsEnabled:
        // Enable or disable DevTools analytics collection.
        final queryParams = request.requestedUri.queryParameters;
        if (queryParams.containsKey(devToolsEnabledPropertyName)) {
          _devToolsUsage.analyticsEnabled =
              json.decode(queryParams[devToolsEnabledPropertyName]!);
        }
        return api.setCompleted(
          request,
          json.encode(_devToolsUsage.analyticsEnabled),
        );

      // ----- DevTools survey store. -----

      case apiSetActiveSurvey:
        // Assume failure.
        bool result = false;

        // Set the active survey used to store subsequent apiGetSurveyActionTaken,
        // apiSetSurveyActionTaken, apiGetSurveyShownCount, and
        // apiIncrementSurveyShownCount calls.
        final queryParams = request.requestedUri.queryParameters;
        if (queryParams.keys.length == 1 &&
            queryParams.containsKey(activeSurveyName)) {
          final String theSurveyName = queryParams[activeSurveyName]!;

          // Set the current activeSurvey.
          _devToolsUsage.activeSurvey = theSurveyName;
          result = true;
        }

        return api.getCompleted(request, json.encode(result));
      case apiGetSurveyActionTaken:
        // Request setActiveSurvey has not been requested.
        if (_devToolsUsage.activeSurvey == null) {
          return api.badRequest(
            '$errorNoActiveSurvey '
            '- $apiGetSurveyActionTaken',
          );
        }
        // SurveyActionTaken has the survey been acted upon (taken or dismissed)
        return api.getCompleted(
          request,
          json.encode(_devToolsUsage.surveyActionTaken),
        );
      // TODO(terry): remove the query param logic for this request.
      // setSurveyActionTaken should only be called with the value of true, so
      // we can remove the extra complexity.
      case apiSetSurveyActionTaken:
        // Request setActiveSurvey has not been requested.
        if (_devToolsUsage.activeSurvey == null) {
          return api.badRequest(
            '$errorNoActiveSurvey '
            '- $apiSetSurveyActionTaken',
          );
        }
        // Set the SurveyActionTaken.
        // Has the survey been taken or dismissed..
        final queryParams = request.requestedUri.queryParameters;
        if (queryParams.containsKey(surveyActionTakenPropertyName)) {
          _devToolsUsage.surveyActionTaken =
              json.decode(queryParams[surveyActionTakenPropertyName]!);
        }
        return api.setCompleted(
          request,
          json.encode(_devToolsUsage.surveyActionTaken),
        );
      case apiGetSurveyShownCount:
        // Request setActiveSurvey has not been requested.
        if (_devToolsUsage.activeSurvey == null) {
          return api.badRequest(
            '$errorNoActiveSurvey '
            '- $apiGetSurveyShownCount',
          );
        }
        // SurveyShownCount how many times have we asked to take survey.
        return api.getCompleted(
          request,
          json.encode(_devToolsUsage.surveyShownCount),
        );
      case apiIncrementSurveyShownCount:
        // Request setActiveSurvey has not been requested.
        if (_devToolsUsage.activeSurvey == null) {
          return api.badRequest(
            '$errorNoActiveSurvey '
            '- $apiIncrementSurveyShownCount',
          );
        }
        // Increment the SurveyShownCount, we've asked about the survey.
        _devToolsUsage.incrementSurveyShownCount();
        return api.getCompleted(
          request,
          json.encode(_devToolsUsage.surveyShownCount),
        );
      case apiGetLastReleaseNotesVersion:
        return api.getCompleted(
          request,
          json.encode(_devToolsUsage.lastReleaseNotesVersion),
        );
      case apiSetLastReleaseNotesVersion:
        final queryParams = request.requestedUri.queryParameters;
        if (queryParams.containsKey(lastReleaseNotesVersionPropertyName)) {
          _devToolsUsage.lastReleaseNotesVersion =
              queryParams[lastReleaseNotesVersionPropertyName]!;
        }
        return api.getCompleted(
          request,
          json.encode(_devToolsUsage.lastReleaseNotesVersion),
        );
      case apiGetBaseAppSizeFile:
        final queryParams = request.requestedUri.queryParameters;
        if (queryParams.containsKey(baseAppSizeFilePropertyName)) {
          final filePath = queryParams[baseAppSizeFilePropertyName]!;
          final fileJson = LocalFileSystem.devToolsFileAsJson(filePath);
          if (fileJson == null) {
            return api.badRequest('No JSON file available at $filePath.');
          }
          return api.getCompleted(request, fileJson);
        }
        return api.badRequest(
          'Request for base app size file does not '
          'contain a query parameter with the expected key: '
          '$baseAppSizeFilePropertyName',
        );
      case apiGetTestAppSizeFile:
        final queryParams = request.requestedUri.queryParameters;
        if (queryParams.containsKey(testAppSizeFilePropertyName)) {
          final filePath = queryParams[testAppSizeFilePropertyName]!;
          final fileJson = LocalFileSystem.devToolsFileAsJson(filePath);
          if (fileJson == null) {
            return api.badRequest('No JSON file available at $filePath.');
          }
          return api.getCompleted(request, fileJson);
        }
        return api.badRequest(
          'Request for test app size file does not '
          'contain a query parameter with the expected key: '
          '$testAppSizeFilePropertyName',
        );
      default:
        return api.notImplemented(request);
    }
  }

  // Accessing Flutter usage file e.g., ~/.flutter.
  // NOTE: Only access the file if it exists otherwise Flutter Tool hasn't yet
  //       been run.
  static final FlutterUsage? _usage =
      FlutterUsage.doesStoreExist ? FlutterUsage() : null;

  // Accessing DevTools usage file e.g., ~/.flutter-devtools/.devtools
  static final DevToolsUsage _devToolsUsage = DevToolsUsage();

  static DevToolsUsage get devToolsPreferences => _devToolsUsage;

  /// Logs a page view in the DevTools server.
  ///
  /// In the open-source version of DevTools, Google Analytics handles this
  /// without any need to involve the server.
  FutureOr<shelf.Response> logScreenView(shelf.Request request) =>
      notImplemented(request);

  /// Return the value of the property.
  FutureOr<shelf.Response> getCompleted(shelf.Request request, String value) =>
      shelf.Response.ok('$value');

  /// Return the value of the property after the property value has been set.
  FutureOr<shelf.Response> setCompleted(shelf.Request request, String value) =>
      shelf.Response.ok('$value');

  /// A [shelf.Response] for API calls that encountered a request problem e.g.,
  /// setActiveSurvey not called.
  ///
  /// This is a 400 Bad Request response.
  FutureOr<shelf.Response> badRequest([String? logError]) {
    if (logError != null) print(logError);
    return shelf.Response(HttpStatus.badRequest);
  }

  /// A [shelf.Response] for API calls that have not been implemented in this
  /// server.
  ///
  /// This is a no-op 204 No Content response because returning 404 Not Found
  /// creates unnecessary noise in the console.
  FutureOr<shelf.Response> notImplemented(shelf.Request request) =>
      shelf.Response(HttpStatus.noContent);
}
