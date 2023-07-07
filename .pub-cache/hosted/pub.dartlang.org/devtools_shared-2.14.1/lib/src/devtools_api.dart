// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// All server APIs prefix:
const String apiPrefix = 'api/';

/// Flutter GA properties APIs:
const String apiGetFlutterGAEnabled = '${apiPrefix}getFlutterGAEnabled';
const String apiGetFlutterGAClientId = '${apiPrefix}getFlutterGAClientId';

/// DevTools GA properties APIs:
const String apiResetDevTools = '${apiPrefix}resetDevTools';
const String apiGetDevToolsFirstRun = '${apiPrefix}getDevToolsFirstRun';
const String apiGetDevToolsEnabled = '${apiPrefix}getDevToolsEnabled';
const String apiSetDevToolsEnabled = '${apiPrefix}setDevToolsEnabled';

/// Property name to apiSetDevToolsEnabled the DevToolsEnabled is the name used
/// in queryParameter:
const String devToolsEnabledPropertyName = 'enabled';

/// Survey properties APIs:
/// setActiveSurvey sets the survey property to fetch and save JSON values e.g., Q1-2020
const String apiSetActiveSurvey = '${apiPrefix}setActiveSurvey';

/// Survey name passed in apiSetActiveSurvey, the activeSurveyName is the property name
/// passed as a queryParameter and is the property in ~/.devtools too.
const String activeSurveyName = 'activeSurveyName';

/// Returns the surveyActionTaken of the activeSurvey (apiSetActiveSurvey).
const String apiGetSurveyActionTaken = '${apiPrefix}getSurveyActionTaken';

/// Sets the surveyActionTaken of the of the activeSurvey (apiSetActiveSurvey).
const String apiSetSurveyActionTaken = '${apiPrefix}setSurveyActionTaken';

/// Property name to apiSetSurveyActionTaken the surveyActionTaken is the name
/// passed in queryParameter:
const String surveyActionTakenPropertyName = 'surveyActionTaken';

/// Returns the surveyShownCount of the of the activeSurvey (apiSetActiveSurvey).
const String apiGetSurveyShownCount = '${apiPrefix}getSurveyShownCount';

/// Increments the surveyShownCount of the of the activeSurvey (apiSetActiveSurvey).
const String apiIncrementSurveyShownCount =
    '${apiPrefix}incrementSurveyShownCount';

const String lastReleaseNotesVersionPropertyName = 'lastReleaseNotesVersion';

/// Returns the last DevTools version for which we have shown release notes.
const String apiGetLastReleaseNotesVersion = '${apiPrefix}getLastReleaseNotesVersion';

/// Sets the last DevTools version for which we have shown release notes.
const String apiSetLastReleaseNotesVersion = '${apiPrefix}setLastReleaseNotesVersion';

/// Returns the base app size file, if present.
const String apiGetBaseAppSizeFile = '${apiPrefix}getBaseAppSizeFile';

/// Returns the test app size file used for comparing two files in a diff, if
/// present.
const String apiGetTestAppSizeFile = '${apiPrefix}getTestAppSizeFile';

const String baseAppSizeFilePropertyName = 'appSizeBase';

const String testAppSizeFilePropertyName = 'appSizeTest';
