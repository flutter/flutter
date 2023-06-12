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

import 'package:googleapis/classroom/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Material> buildUnnamed5543() {
  var o = <api.Material>[];
  o.add(buildMaterial());
  o.add(buildMaterial());
  return o;
}

void checkUnnamed5543(core.List<api.Material> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMaterial(o[0] as api.Material);
  checkMaterial(o[1] as api.Material);
}

core.int buildCounterAnnouncement = 0;
api.Announcement buildAnnouncement() {
  var o = api.Announcement();
  buildCounterAnnouncement++;
  if (buildCounterAnnouncement < 3) {
    o.alternateLink = 'foo';
    o.assigneeMode = 'foo';
    o.courseId = 'foo';
    o.creationTime = 'foo';
    o.creatorUserId = 'foo';
    o.id = 'foo';
    o.individualStudentsOptions = buildIndividualStudentsOptions();
    o.materials = buildUnnamed5543();
    o.scheduledTime = 'foo';
    o.state = 'foo';
    o.text = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterAnnouncement--;
  return o;
}

void checkAnnouncement(api.Announcement o) {
  buildCounterAnnouncement++;
  if (buildCounterAnnouncement < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.assigneeMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creatorUserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkIndividualStudentsOptions(
        o.individualStudentsOptions! as api.IndividualStudentsOptions);
    checkUnnamed5543(o.materials!);
    unittest.expect(
      o.scheduledTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterAnnouncement--;
}

core.int buildCounterAssignment = 0;
api.Assignment buildAssignment() {
  var o = api.Assignment();
  buildCounterAssignment++;
  if (buildCounterAssignment < 3) {
    o.studentWorkFolder = buildDriveFolder();
  }
  buildCounterAssignment--;
  return o;
}

void checkAssignment(api.Assignment o) {
  buildCounterAssignment++;
  if (buildCounterAssignment < 3) {
    checkDriveFolder(o.studentWorkFolder! as api.DriveFolder);
  }
  buildCounterAssignment--;
}

core.List<api.Attachment> buildUnnamed5544() {
  var o = <api.Attachment>[];
  o.add(buildAttachment());
  o.add(buildAttachment());
  return o;
}

void checkUnnamed5544(core.List<api.Attachment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttachment(o[0] as api.Attachment);
  checkAttachment(o[1] as api.Attachment);
}

core.int buildCounterAssignmentSubmission = 0;
api.AssignmentSubmission buildAssignmentSubmission() {
  var o = api.AssignmentSubmission();
  buildCounterAssignmentSubmission++;
  if (buildCounterAssignmentSubmission < 3) {
    o.attachments = buildUnnamed5544();
  }
  buildCounterAssignmentSubmission--;
  return o;
}

void checkAssignmentSubmission(api.AssignmentSubmission o) {
  buildCounterAssignmentSubmission++;
  if (buildCounterAssignmentSubmission < 3) {
    checkUnnamed5544(o.attachments!);
  }
  buildCounterAssignmentSubmission--;
}

core.int buildCounterAttachment = 0;
api.Attachment buildAttachment() {
  var o = api.Attachment();
  buildCounterAttachment++;
  if (buildCounterAttachment < 3) {
    o.driveFile = buildDriveFile();
    o.form = buildForm();
    o.link = buildLink();
    o.youTubeVideo = buildYouTubeVideo();
  }
  buildCounterAttachment--;
  return o;
}

void checkAttachment(api.Attachment o) {
  buildCounterAttachment++;
  if (buildCounterAttachment < 3) {
    checkDriveFile(o.driveFile! as api.DriveFile);
    checkForm(o.form! as api.Form);
    checkLink(o.link! as api.Link);
    checkYouTubeVideo(o.youTubeVideo! as api.YouTubeVideo);
  }
  buildCounterAttachment--;
}

core.int buildCounterCloudPubsubTopic = 0;
api.CloudPubsubTopic buildCloudPubsubTopic() {
  var o = api.CloudPubsubTopic();
  buildCounterCloudPubsubTopic++;
  if (buildCounterCloudPubsubTopic < 3) {
    o.topicName = 'foo';
  }
  buildCounterCloudPubsubTopic--;
  return o;
}

void checkCloudPubsubTopic(api.CloudPubsubTopic o) {
  buildCounterCloudPubsubTopic++;
  if (buildCounterCloudPubsubTopic < 3) {
    unittest.expect(
      o.topicName!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudPubsubTopic--;
}

core.List<api.CourseMaterialSet> buildUnnamed5545() {
  var o = <api.CourseMaterialSet>[];
  o.add(buildCourseMaterialSet());
  o.add(buildCourseMaterialSet());
  return o;
}

void checkUnnamed5545(core.List<api.CourseMaterialSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCourseMaterialSet(o[0] as api.CourseMaterialSet);
  checkCourseMaterialSet(o[1] as api.CourseMaterialSet);
}

core.int buildCounterCourse = 0;
api.Course buildCourse() {
  var o = api.Course();
  buildCounterCourse++;
  if (buildCounterCourse < 3) {
    o.alternateLink = 'foo';
    o.calendarId = 'foo';
    o.courseGroupEmail = 'foo';
    o.courseMaterialSets = buildUnnamed5545();
    o.courseState = 'foo';
    o.creationTime = 'foo';
    o.description = 'foo';
    o.descriptionHeading = 'foo';
    o.enrollmentCode = 'foo';
    o.guardiansEnabled = true;
    o.id = 'foo';
    o.name = 'foo';
    o.ownerId = 'foo';
    o.room = 'foo';
    o.section = 'foo';
    o.teacherFolder = buildDriveFolder();
    o.teacherGroupEmail = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterCourse--;
  return o;
}

void checkCourse(api.Course o) {
  buildCounterCourse++;
  if (buildCounterCourse < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.calendarId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.courseGroupEmail!,
      unittest.equals('foo'),
    );
    checkUnnamed5545(o.courseMaterialSets!);
    unittest.expect(
      o.courseState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.descriptionHeading!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.enrollmentCode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.guardiansEnabled!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ownerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.room!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.section!,
      unittest.equals('foo'),
    );
    checkDriveFolder(o.teacherFolder! as api.DriveFolder);
    unittest.expect(
      o.teacherGroupEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterCourse--;
}

core.int buildCounterCourseAlias = 0;
api.CourseAlias buildCourseAlias() {
  var o = api.CourseAlias();
  buildCounterCourseAlias++;
  if (buildCounterCourseAlias < 3) {
    o.alias = 'foo';
  }
  buildCounterCourseAlias--;
  return o;
}

void checkCourseAlias(api.CourseAlias o) {
  buildCounterCourseAlias++;
  if (buildCounterCourseAlias < 3) {
    unittest.expect(
      o.alias!,
      unittest.equals('foo'),
    );
  }
  buildCounterCourseAlias--;
}

core.int buildCounterCourseMaterial = 0;
api.CourseMaterial buildCourseMaterial() {
  var o = api.CourseMaterial();
  buildCounterCourseMaterial++;
  if (buildCounterCourseMaterial < 3) {
    o.driveFile = buildDriveFile();
    o.form = buildForm();
    o.link = buildLink();
    o.youTubeVideo = buildYouTubeVideo();
  }
  buildCounterCourseMaterial--;
  return o;
}

void checkCourseMaterial(api.CourseMaterial o) {
  buildCounterCourseMaterial++;
  if (buildCounterCourseMaterial < 3) {
    checkDriveFile(o.driveFile! as api.DriveFile);
    checkForm(o.form! as api.Form);
    checkLink(o.link! as api.Link);
    checkYouTubeVideo(o.youTubeVideo! as api.YouTubeVideo);
  }
  buildCounterCourseMaterial--;
}

core.List<api.CourseMaterial> buildUnnamed5546() {
  var o = <api.CourseMaterial>[];
  o.add(buildCourseMaterial());
  o.add(buildCourseMaterial());
  return o;
}

void checkUnnamed5546(core.List<api.CourseMaterial> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCourseMaterial(o[0] as api.CourseMaterial);
  checkCourseMaterial(o[1] as api.CourseMaterial);
}

core.int buildCounterCourseMaterialSet = 0;
api.CourseMaterialSet buildCourseMaterialSet() {
  var o = api.CourseMaterialSet();
  buildCounterCourseMaterialSet++;
  if (buildCounterCourseMaterialSet < 3) {
    o.materials = buildUnnamed5546();
    o.title = 'foo';
  }
  buildCounterCourseMaterialSet--;
  return o;
}

void checkCourseMaterialSet(api.CourseMaterialSet o) {
  buildCounterCourseMaterialSet++;
  if (buildCounterCourseMaterialSet < 3) {
    checkUnnamed5546(o.materials!);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterCourseMaterialSet--;
}

core.int buildCounterCourseRosterChangesInfo = 0;
api.CourseRosterChangesInfo buildCourseRosterChangesInfo() {
  var o = api.CourseRosterChangesInfo();
  buildCounterCourseRosterChangesInfo++;
  if (buildCounterCourseRosterChangesInfo < 3) {
    o.courseId = 'foo';
  }
  buildCounterCourseRosterChangesInfo--;
  return o;
}

void checkCourseRosterChangesInfo(api.CourseRosterChangesInfo o) {
  buildCounterCourseRosterChangesInfo++;
  if (buildCounterCourseRosterChangesInfo < 3) {
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCourseRosterChangesInfo--;
}

core.List<api.Material> buildUnnamed5547() {
  var o = <api.Material>[];
  o.add(buildMaterial());
  o.add(buildMaterial());
  return o;
}

void checkUnnamed5547(core.List<api.Material> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMaterial(o[0] as api.Material);
  checkMaterial(o[1] as api.Material);
}

core.int buildCounterCourseWork = 0;
api.CourseWork buildCourseWork() {
  var o = api.CourseWork();
  buildCounterCourseWork++;
  if (buildCounterCourseWork < 3) {
    o.alternateLink = 'foo';
    o.assigneeMode = 'foo';
    o.assignment = buildAssignment();
    o.associatedWithDeveloper = true;
    o.courseId = 'foo';
    o.creationTime = 'foo';
    o.creatorUserId = 'foo';
    o.description = 'foo';
    o.dueDate = buildDate();
    o.dueTime = buildTimeOfDay();
    o.id = 'foo';
    o.individualStudentsOptions = buildIndividualStudentsOptions();
    o.materials = buildUnnamed5547();
    o.maxPoints = 42.0;
    o.multipleChoiceQuestion = buildMultipleChoiceQuestion();
    o.scheduledTime = 'foo';
    o.state = 'foo';
    o.submissionModificationMode = 'foo';
    o.title = 'foo';
    o.topicId = 'foo';
    o.updateTime = 'foo';
    o.workType = 'foo';
  }
  buildCounterCourseWork--;
  return o;
}

void checkCourseWork(api.CourseWork o) {
  buildCounterCourseWork++;
  if (buildCounterCourseWork < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.assigneeMode!,
      unittest.equals('foo'),
    );
    checkAssignment(o.assignment! as api.Assignment);
    unittest.expect(o.associatedWithDeveloper!, unittest.isTrue);
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creatorUserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkDate(o.dueDate! as api.Date);
    checkTimeOfDay(o.dueTime! as api.TimeOfDay);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkIndividualStudentsOptions(
        o.individualStudentsOptions! as api.IndividualStudentsOptions);
    checkUnnamed5547(o.materials!);
    unittest.expect(
      o.maxPoints!,
      unittest.equals(42.0),
    );
    checkMultipleChoiceQuestion(
        o.multipleChoiceQuestion! as api.MultipleChoiceQuestion);
    unittest.expect(
      o.scheduledTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.submissionModificationMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.topicId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workType!,
      unittest.equals('foo'),
    );
  }
  buildCounterCourseWork--;
}

core.int buildCounterCourseWorkChangesInfo = 0;
api.CourseWorkChangesInfo buildCourseWorkChangesInfo() {
  var o = api.CourseWorkChangesInfo();
  buildCounterCourseWorkChangesInfo++;
  if (buildCounterCourseWorkChangesInfo < 3) {
    o.courseId = 'foo';
  }
  buildCounterCourseWorkChangesInfo--;
  return o;
}

void checkCourseWorkChangesInfo(api.CourseWorkChangesInfo o) {
  buildCounterCourseWorkChangesInfo++;
  if (buildCounterCourseWorkChangesInfo < 3) {
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCourseWorkChangesInfo--;
}

core.List<api.Material> buildUnnamed5548() {
  var o = <api.Material>[];
  o.add(buildMaterial());
  o.add(buildMaterial());
  return o;
}

void checkUnnamed5548(core.List<api.Material> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMaterial(o[0] as api.Material);
  checkMaterial(o[1] as api.Material);
}

core.int buildCounterCourseWorkMaterial = 0;
api.CourseWorkMaterial buildCourseWorkMaterial() {
  var o = api.CourseWorkMaterial();
  buildCounterCourseWorkMaterial++;
  if (buildCounterCourseWorkMaterial < 3) {
    o.alternateLink = 'foo';
    o.assigneeMode = 'foo';
    o.courseId = 'foo';
    o.creationTime = 'foo';
    o.creatorUserId = 'foo';
    o.description = 'foo';
    o.id = 'foo';
    o.individualStudentsOptions = buildIndividualStudentsOptions();
    o.materials = buildUnnamed5548();
    o.scheduledTime = 'foo';
    o.state = 'foo';
    o.title = 'foo';
    o.topicId = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterCourseWorkMaterial--;
  return o;
}

void checkCourseWorkMaterial(api.CourseWorkMaterial o) {
  buildCounterCourseWorkMaterial++;
  if (buildCounterCourseWorkMaterial < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.assigneeMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creatorUserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkIndividualStudentsOptions(
        o.individualStudentsOptions! as api.IndividualStudentsOptions);
    checkUnnamed5548(o.materials!);
    unittest.expect(
      o.scheduledTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.topicId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterCourseWorkMaterial--;
}

core.int buildCounterDate = 0;
api.Date buildDate() {
  var o = api.Date();
  buildCounterDate++;
  if (buildCounterDate < 3) {
    o.day = 42;
    o.month = 42;
    o.year = 42;
  }
  buildCounterDate--;
  return o;
}

void checkDate(api.Date o) {
  buildCounterDate++;
  if (buildCounterDate < 3) {
    unittest.expect(
      o.day!,
      unittest.equals(42),
    );
    unittest.expect(
      o.month!,
      unittest.equals(42),
    );
    unittest.expect(
      o.year!,
      unittest.equals(42),
    );
  }
  buildCounterDate--;
}

core.int buildCounterDriveFile = 0;
api.DriveFile buildDriveFile() {
  var o = api.DriveFile();
  buildCounterDriveFile++;
  if (buildCounterDriveFile < 3) {
    o.alternateLink = 'foo';
    o.id = 'foo';
    o.thumbnailUrl = 'foo';
    o.title = 'foo';
  }
  buildCounterDriveFile--;
  return o;
}

void checkDriveFile(api.DriveFile o) {
  buildCounterDriveFile++;
  if (buildCounterDriveFile < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveFile--;
}

core.int buildCounterDriveFolder = 0;
api.DriveFolder buildDriveFolder() {
  var o = api.DriveFolder();
  buildCounterDriveFolder++;
  if (buildCounterDriveFolder < 3) {
    o.alternateLink = 'foo';
    o.id = 'foo';
    o.title = 'foo';
  }
  buildCounterDriveFolder--;
  return o;
}

void checkDriveFolder(api.DriveFolder o) {
  buildCounterDriveFolder++;
  if (buildCounterDriveFolder < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveFolder--;
}

core.int buildCounterEmpty = 0;
api.Empty buildEmpty() {
  var o = api.Empty();
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
  return o;
}

void checkEmpty(api.Empty o) {
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
}

core.int buildCounterFeed = 0;
api.Feed buildFeed() {
  var o = api.Feed();
  buildCounterFeed++;
  if (buildCounterFeed < 3) {
    o.courseRosterChangesInfo = buildCourseRosterChangesInfo();
    o.courseWorkChangesInfo = buildCourseWorkChangesInfo();
    o.feedType = 'foo';
  }
  buildCounterFeed--;
  return o;
}

void checkFeed(api.Feed o) {
  buildCounterFeed++;
  if (buildCounterFeed < 3) {
    checkCourseRosterChangesInfo(
        o.courseRosterChangesInfo! as api.CourseRosterChangesInfo);
    checkCourseWorkChangesInfo(
        o.courseWorkChangesInfo! as api.CourseWorkChangesInfo);
    unittest.expect(
      o.feedType!,
      unittest.equals('foo'),
    );
  }
  buildCounterFeed--;
}

core.int buildCounterForm = 0;
api.Form buildForm() {
  var o = api.Form();
  buildCounterForm++;
  if (buildCounterForm < 3) {
    o.formUrl = 'foo';
    o.responseUrl = 'foo';
    o.thumbnailUrl = 'foo';
    o.title = 'foo';
  }
  buildCounterForm--;
  return o;
}

void checkForm(api.Form o) {
  buildCounterForm++;
  if (buildCounterForm < 3) {
    unittest.expect(
      o.formUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responseUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterForm--;
}

core.int buildCounterGlobalPermission = 0;
api.GlobalPermission buildGlobalPermission() {
  var o = api.GlobalPermission();
  buildCounterGlobalPermission++;
  if (buildCounterGlobalPermission < 3) {
    o.permission = 'foo';
  }
  buildCounterGlobalPermission--;
  return o;
}

void checkGlobalPermission(api.GlobalPermission o) {
  buildCounterGlobalPermission++;
  if (buildCounterGlobalPermission < 3) {
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
  }
  buildCounterGlobalPermission--;
}

core.int buildCounterGradeHistory = 0;
api.GradeHistory buildGradeHistory() {
  var o = api.GradeHistory();
  buildCounterGradeHistory++;
  if (buildCounterGradeHistory < 3) {
    o.actorUserId = 'foo';
    o.gradeChangeType = 'foo';
    o.gradeTimestamp = 'foo';
    o.maxPoints = 42.0;
    o.pointsEarned = 42.0;
  }
  buildCounterGradeHistory--;
  return o;
}

void checkGradeHistory(api.GradeHistory o) {
  buildCounterGradeHistory++;
  if (buildCounterGradeHistory < 3) {
    unittest.expect(
      o.actorUserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gradeChangeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gradeTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxPoints!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.pointsEarned!,
      unittest.equals(42.0),
    );
  }
  buildCounterGradeHistory--;
}

core.int buildCounterGuardian = 0;
api.Guardian buildGuardian() {
  var o = api.Guardian();
  buildCounterGuardian++;
  if (buildCounterGuardian < 3) {
    o.guardianId = 'foo';
    o.guardianProfile = buildUserProfile();
    o.invitedEmailAddress = 'foo';
    o.studentId = 'foo';
  }
  buildCounterGuardian--;
  return o;
}

void checkGuardian(api.Guardian o) {
  buildCounterGuardian++;
  if (buildCounterGuardian < 3) {
    unittest.expect(
      o.guardianId!,
      unittest.equals('foo'),
    );
    checkUserProfile(o.guardianProfile! as api.UserProfile);
    unittest.expect(
      o.invitedEmailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.studentId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGuardian--;
}

core.int buildCounterGuardianInvitation = 0;
api.GuardianInvitation buildGuardianInvitation() {
  var o = api.GuardianInvitation();
  buildCounterGuardianInvitation++;
  if (buildCounterGuardianInvitation < 3) {
    o.creationTime = 'foo';
    o.invitationId = 'foo';
    o.invitedEmailAddress = 'foo';
    o.state = 'foo';
    o.studentId = 'foo';
  }
  buildCounterGuardianInvitation--;
  return o;
}

void checkGuardianInvitation(api.GuardianInvitation o) {
  buildCounterGuardianInvitation++;
  if (buildCounterGuardianInvitation < 3) {
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invitationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invitedEmailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.studentId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGuardianInvitation--;
}

core.List<core.String> buildUnnamed5549() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5549(core.List<core.String> o) {
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

core.int buildCounterIndividualStudentsOptions = 0;
api.IndividualStudentsOptions buildIndividualStudentsOptions() {
  var o = api.IndividualStudentsOptions();
  buildCounterIndividualStudentsOptions++;
  if (buildCounterIndividualStudentsOptions < 3) {
    o.studentIds = buildUnnamed5549();
  }
  buildCounterIndividualStudentsOptions--;
  return o;
}

void checkIndividualStudentsOptions(api.IndividualStudentsOptions o) {
  buildCounterIndividualStudentsOptions++;
  if (buildCounterIndividualStudentsOptions < 3) {
    checkUnnamed5549(o.studentIds!);
  }
  buildCounterIndividualStudentsOptions--;
}

core.int buildCounterInvitation = 0;
api.Invitation buildInvitation() {
  var o = api.Invitation();
  buildCounterInvitation++;
  if (buildCounterInvitation < 3) {
    o.courseId = 'foo';
    o.id = 'foo';
    o.role = 'foo';
    o.userId = 'foo';
  }
  buildCounterInvitation--;
  return o;
}

void checkInvitation(api.Invitation o) {
  buildCounterInvitation++;
  if (buildCounterInvitation < 3) {
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterInvitation--;
}

core.int buildCounterLink = 0;
api.Link buildLink() {
  var o = api.Link();
  buildCounterLink++;
  if (buildCounterLink < 3) {
    o.thumbnailUrl = 'foo';
    o.title = 'foo';
    o.url = 'foo';
  }
  buildCounterLink--;
  return o;
}

void checkLink(api.Link o) {
  buildCounterLink++;
  if (buildCounterLink < 3) {
    unittest.expect(
      o.thumbnailUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterLink--;
}

core.List<api.Announcement> buildUnnamed5550() {
  var o = <api.Announcement>[];
  o.add(buildAnnouncement());
  o.add(buildAnnouncement());
  return o;
}

void checkUnnamed5550(core.List<api.Announcement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAnnouncement(o[0] as api.Announcement);
  checkAnnouncement(o[1] as api.Announcement);
}

core.int buildCounterListAnnouncementsResponse = 0;
api.ListAnnouncementsResponse buildListAnnouncementsResponse() {
  var o = api.ListAnnouncementsResponse();
  buildCounterListAnnouncementsResponse++;
  if (buildCounterListAnnouncementsResponse < 3) {
    o.announcements = buildUnnamed5550();
    o.nextPageToken = 'foo';
  }
  buildCounterListAnnouncementsResponse--;
  return o;
}

void checkListAnnouncementsResponse(api.ListAnnouncementsResponse o) {
  buildCounterListAnnouncementsResponse++;
  if (buildCounterListAnnouncementsResponse < 3) {
    checkUnnamed5550(o.announcements!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAnnouncementsResponse--;
}

core.List<api.CourseAlias> buildUnnamed5551() {
  var o = <api.CourseAlias>[];
  o.add(buildCourseAlias());
  o.add(buildCourseAlias());
  return o;
}

void checkUnnamed5551(core.List<api.CourseAlias> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCourseAlias(o[0] as api.CourseAlias);
  checkCourseAlias(o[1] as api.CourseAlias);
}

core.int buildCounterListCourseAliasesResponse = 0;
api.ListCourseAliasesResponse buildListCourseAliasesResponse() {
  var o = api.ListCourseAliasesResponse();
  buildCounterListCourseAliasesResponse++;
  if (buildCounterListCourseAliasesResponse < 3) {
    o.aliases = buildUnnamed5551();
    o.nextPageToken = 'foo';
  }
  buildCounterListCourseAliasesResponse--;
  return o;
}

void checkListCourseAliasesResponse(api.ListCourseAliasesResponse o) {
  buildCounterListCourseAliasesResponse++;
  if (buildCounterListCourseAliasesResponse < 3) {
    checkUnnamed5551(o.aliases!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCourseAliasesResponse--;
}

core.List<api.CourseWorkMaterial> buildUnnamed5552() {
  var o = <api.CourseWorkMaterial>[];
  o.add(buildCourseWorkMaterial());
  o.add(buildCourseWorkMaterial());
  return o;
}

void checkUnnamed5552(core.List<api.CourseWorkMaterial> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCourseWorkMaterial(o[0] as api.CourseWorkMaterial);
  checkCourseWorkMaterial(o[1] as api.CourseWorkMaterial);
}

core.int buildCounterListCourseWorkMaterialResponse = 0;
api.ListCourseWorkMaterialResponse buildListCourseWorkMaterialResponse() {
  var o = api.ListCourseWorkMaterialResponse();
  buildCounterListCourseWorkMaterialResponse++;
  if (buildCounterListCourseWorkMaterialResponse < 3) {
    o.courseWorkMaterial = buildUnnamed5552();
    o.nextPageToken = 'foo';
  }
  buildCounterListCourseWorkMaterialResponse--;
  return o;
}

void checkListCourseWorkMaterialResponse(api.ListCourseWorkMaterialResponse o) {
  buildCounterListCourseWorkMaterialResponse++;
  if (buildCounterListCourseWorkMaterialResponse < 3) {
    checkUnnamed5552(o.courseWorkMaterial!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCourseWorkMaterialResponse--;
}

core.List<api.CourseWork> buildUnnamed5553() {
  var o = <api.CourseWork>[];
  o.add(buildCourseWork());
  o.add(buildCourseWork());
  return o;
}

void checkUnnamed5553(core.List<api.CourseWork> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCourseWork(o[0] as api.CourseWork);
  checkCourseWork(o[1] as api.CourseWork);
}

core.int buildCounterListCourseWorkResponse = 0;
api.ListCourseWorkResponse buildListCourseWorkResponse() {
  var o = api.ListCourseWorkResponse();
  buildCounterListCourseWorkResponse++;
  if (buildCounterListCourseWorkResponse < 3) {
    o.courseWork = buildUnnamed5553();
    o.nextPageToken = 'foo';
  }
  buildCounterListCourseWorkResponse--;
  return o;
}

void checkListCourseWorkResponse(api.ListCourseWorkResponse o) {
  buildCounterListCourseWorkResponse++;
  if (buildCounterListCourseWorkResponse < 3) {
    checkUnnamed5553(o.courseWork!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCourseWorkResponse--;
}

core.List<api.Course> buildUnnamed5554() {
  var o = <api.Course>[];
  o.add(buildCourse());
  o.add(buildCourse());
  return o;
}

void checkUnnamed5554(core.List<api.Course> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCourse(o[0] as api.Course);
  checkCourse(o[1] as api.Course);
}

core.int buildCounterListCoursesResponse = 0;
api.ListCoursesResponse buildListCoursesResponse() {
  var o = api.ListCoursesResponse();
  buildCounterListCoursesResponse++;
  if (buildCounterListCoursesResponse < 3) {
    o.courses = buildUnnamed5554();
    o.nextPageToken = 'foo';
  }
  buildCounterListCoursesResponse--;
  return o;
}

void checkListCoursesResponse(api.ListCoursesResponse o) {
  buildCounterListCoursesResponse++;
  if (buildCounterListCoursesResponse < 3) {
    checkUnnamed5554(o.courses!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCoursesResponse--;
}

core.List<api.GuardianInvitation> buildUnnamed5555() {
  var o = <api.GuardianInvitation>[];
  o.add(buildGuardianInvitation());
  o.add(buildGuardianInvitation());
  return o;
}

void checkUnnamed5555(core.List<api.GuardianInvitation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGuardianInvitation(o[0] as api.GuardianInvitation);
  checkGuardianInvitation(o[1] as api.GuardianInvitation);
}

core.int buildCounterListGuardianInvitationsResponse = 0;
api.ListGuardianInvitationsResponse buildListGuardianInvitationsResponse() {
  var o = api.ListGuardianInvitationsResponse();
  buildCounterListGuardianInvitationsResponse++;
  if (buildCounterListGuardianInvitationsResponse < 3) {
    o.guardianInvitations = buildUnnamed5555();
    o.nextPageToken = 'foo';
  }
  buildCounterListGuardianInvitationsResponse--;
  return o;
}

void checkListGuardianInvitationsResponse(
    api.ListGuardianInvitationsResponse o) {
  buildCounterListGuardianInvitationsResponse++;
  if (buildCounterListGuardianInvitationsResponse < 3) {
    checkUnnamed5555(o.guardianInvitations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListGuardianInvitationsResponse--;
}

core.List<api.Guardian> buildUnnamed5556() {
  var o = <api.Guardian>[];
  o.add(buildGuardian());
  o.add(buildGuardian());
  return o;
}

void checkUnnamed5556(core.List<api.Guardian> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGuardian(o[0] as api.Guardian);
  checkGuardian(o[1] as api.Guardian);
}

core.int buildCounterListGuardiansResponse = 0;
api.ListGuardiansResponse buildListGuardiansResponse() {
  var o = api.ListGuardiansResponse();
  buildCounterListGuardiansResponse++;
  if (buildCounterListGuardiansResponse < 3) {
    o.guardians = buildUnnamed5556();
    o.nextPageToken = 'foo';
  }
  buildCounterListGuardiansResponse--;
  return o;
}

void checkListGuardiansResponse(api.ListGuardiansResponse o) {
  buildCounterListGuardiansResponse++;
  if (buildCounterListGuardiansResponse < 3) {
    checkUnnamed5556(o.guardians!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListGuardiansResponse--;
}

core.List<api.Invitation> buildUnnamed5557() {
  var o = <api.Invitation>[];
  o.add(buildInvitation());
  o.add(buildInvitation());
  return o;
}

void checkUnnamed5557(core.List<api.Invitation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInvitation(o[0] as api.Invitation);
  checkInvitation(o[1] as api.Invitation);
}

core.int buildCounterListInvitationsResponse = 0;
api.ListInvitationsResponse buildListInvitationsResponse() {
  var o = api.ListInvitationsResponse();
  buildCounterListInvitationsResponse++;
  if (buildCounterListInvitationsResponse < 3) {
    o.invitations = buildUnnamed5557();
    o.nextPageToken = 'foo';
  }
  buildCounterListInvitationsResponse--;
  return o;
}

void checkListInvitationsResponse(api.ListInvitationsResponse o) {
  buildCounterListInvitationsResponse++;
  if (buildCounterListInvitationsResponse < 3) {
    checkUnnamed5557(o.invitations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInvitationsResponse--;
}

core.List<api.StudentSubmission> buildUnnamed5558() {
  var o = <api.StudentSubmission>[];
  o.add(buildStudentSubmission());
  o.add(buildStudentSubmission());
  return o;
}

void checkUnnamed5558(core.List<api.StudentSubmission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStudentSubmission(o[0] as api.StudentSubmission);
  checkStudentSubmission(o[1] as api.StudentSubmission);
}

core.int buildCounterListStudentSubmissionsResponse = 0;
api.ListStudentSubmissionsResponse buildListStudentSubmissionsResponse() {
  var o = api.ListStudentSubmissionsResponse();
  buildCounterListStudentSubmissionsResponse++;
  if (buildCounterListStudentSubmissionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.studentSubmissions = buildUnnamed5558();
  }
  buildCounterListStudentSubmissionsResponse--;
  return o;
}

void checkListStudentSubmissionsResponse(api.ListStudentSubmissionsResponse o) {
  buildCounterListStudentSubmissionsResponse++;
  if (buildCounterListStudentSubmissionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5558(o.studentSubmissions!);
  }
  buildCounterListStudentSubmissionsResponse--;
}

core.List<api.Student> buildUnnamed5559() {
  var o = <api.Student>[];
  o.add(buildStudent());
  o.add(buildStudent());
  return o;
}

void checkUnnamed5559(core.List<api.Student> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStudent(o[0] as api.Student);
  checkStudent(o[1] as api.Student);
}

core.int buildCounterListStudentsResponse = 0;
api.ListStudentsResponse buildListStudentsResponse() {
  var o = api.ListStudentsResponse();
  buildCounterListStudentsResponse++;
  if (buildCounterListStudentsResponse < 3) {
    o.nextPageToken = 'foo';
    o.students = buildUnnamed5559();
  }
  buildCounterListStudentsResponse--;
  return o;
}

void checkListStudentsResponse(api.ListStudentsResponse o) {
  buildCounterListStudentsResponse++;
  if (buildCounterListStudentsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5559(o.students!);
  }
  buildCounterListStudentsResponse--;
}

core.List<api.Teacher> buildUnnamed5560() {
  var o = <api.Teacher>[];
  o.add(buildTeacher());
  o.add(buildTeacher());
  return o;
}

void checkUnnamed5560(core.List<api.Teacher> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTeacher(o[0] as api.Teacher);
  checkTeacher(o[1] as api.Teacher);
}

core.int buildCounterListTeachersResponse = 0;
api.ListTeachersResponse buildListTeachersResponse() {
  var o = api.ListTeachersResponse();
  buildCounterListTeachersResponse++;
  if (buildCounterListTeachersResponse < 3) {
    o.nextPageToken = 'foo';
    o.teachers = buildUnnamed5560();
  }
  buildCounterListTeachersResponse--;
  return o;
}

void checkListTeachersResponse(api.ListTeachersResponse o) {
  buildCounterListTeachersResponse++;
  if (buildCounterListTeachersResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5560(o.teachers!);
  }
  buildCounterListTeachersResponse--;
}

core.List<api.Topic> buildUnnamed5561() {
  var o = <api.Topic>[];
  o.add(buildTopic());
  o.add(buildTopic());
  return o;
}

void checkUnnamed5561(core.List<api.Topic> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTopic(o[0] as api.Topic);
  checkTopic(o[1] as api.Topic);
}

core.int buildCounterListTopicResponse = 0;
api.ListTopicResponse buildListTopicResponse() {
  var o = api.ListTopicResponse();
  buildCounterListTopicResponse++;
  if (buildCounterListTopicResponse < 3) {
    o.nextPageToken = 'foo';
    o.topic = buildUnnamed5561();
  }
  buildCounterListTopicResponse--;
  return o;
}

void checkListTopicResponse(api.ListTopicResponse o) {
  buildCounterListTopicResponse++;
  if (buildCounterListTopicResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5561(o.topic!);
  }
  buildCounterListTopicResponse--;
}

core.int buildCounterMaterial = 0;
api.Material buildMaterial() {
  var o = api.Material();
  buildCounterMaterial++;
  if (buildCounterMaterial < 3) {
    o.driveFile = buildSharedDriveFile();
    o.form = buildForm();
    o.link = buildLink();
    o.youtubeVideo = buildYouTubeVideo();
  }
  buildCounterMaterial--;
  return o;
}

void checkMaterial(api.Material o) {
  buildCounterMaterial++;
  if (buildCounterMaterial < 3) {
    checkSharedDriveFile(o.driveFile! as api.SharedDriveFile);
    checkForm(o.form! as api.Form);
    checkLink(o.link! as api.Link);
    checkYouTubeVideo(o.youtubeVideo! as api.YouTubeVideo);
  }
  buildCounterMaterial--;
}

core.int buildCounterModifyAnnouncementAssigneesRequest = 0;
api.ModifyAnnouncementAssigneesRequest
    buildModifyAnnouncementAssigneesRequest() {
  var o = api.ModifyAnnouncementAssigneesRequest();
  buildCounterModifyAnnouncementAssigneesRequest++;
  if (buildCounterModifyAnnouncementAssigneesRequest < 3) {
    o.assigneeMode = 'foo';
    o.modifyIndividualStudentsOptions = buildModifyIndividualStudentsOptions();
  }
  buildCounterModifyAnnouncementAssigneesRequest--;
  return o;
}

void checkModifyAnnouncementAssigneesRequest(
    api.ModifyAnnouncementAssigneesRequest o) {
  buildCounterModifyAnnouncementAssigneesRequest++;
  if (buildCounterModifyAnnouncementAssigneesRequest < 3) {
    unittest.expect(
      o.assigneeMode!,
      unittest.equals('foo'),
    );
    checkModifyIndividualStudentsOptions(o.modifyIndividualStudentsOptions!
        as api.ModifyIndividualStudentsOptions);
  }
  buildCounterModifyAnnouncementAssigneesRequest--;
}

core.List<api.Attachment> buildUnnamed5562() {
  var o = <api.Attachment>[];
  o.add(buildAttachment());
  o.add(buildAttachment());
  return o;
}

void checkUnnamed5562(core.List<api.Attachment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttachment(o[0] as api.Attachment);
  checkAttachment(o[1] as api.Attachment);
}

core.int buildCounterModifyAttachmentsRequest = 0;
api.ModifyAttachmentsRequest buildModifyAttachmentsRequest() {
  var o = api.ModifyAttachmentsRequest();
  buildCounterModifyAttachmentsRequest++;
  if (buildCounterModifyAttachmentsRequest < 3) {
    o.addAttachments = buildUnnamed5562();
  }
  buildCounterModifyAttachmentsRequest--;
  return o;
}

void checkModifyAttachmentsRequest(api.ModifyAttachmentsRequest o) {
  buildCounterModifyAttachmentsRequest++;
  if (buildCounterModifyAttachmentsRequest < 3) {
    checkUnnamed5562(o.addAttachments!);
  }
  buildCounterModifyAttachmentsRequest--;
}

core.int buildCounterModifyCourseWorkAssigneesRequest = 0;
api.ModifyCourseWorkAssigneesRequest buildModifyCourseWorkAssigneesRequest() {
  var o = api.ModifyCourseWorkAssigneesRequest();
  buildCounterModifyCourseWorkAssigneesRequest++;
  if (buildCounterModifyCourseWorkAssigneesRequest < 3) {
    o.assigneeMode = 'foo';
    o.modifyIndividualStudentsOptions = buildModifyIndividualStudentsOptions();
  }
  buildCounterModifyCourseWorkAssigneesRequest--;
  return o;
}

void checkModifyCourseWorkAssigneesRequest(
    api.ModifyCourseWorkAssigneesRequest o) {
  buildCounterModifyCourseWorkAssigneesRequest++;
  if (buildCounterModifyCourseWorkAssigneesRequest < 3) {
    unittest.expect(
      o.assigneeMode!,
      unittest.equals('foo'),
    );
    checkModifyIndividualStudentsOptions(o.modifyIndividualStudentsOptions!
        as api.ModifyIndividualStudentsOptions);
  }
  buildCounterModifyCourseWorkAssigneesRequest--;
}

core.List<core.String> buildUnnamed5563() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5563(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5564() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5564(core.List<core.String> o) {
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

core.int buildCounterModifyIndividualStudentsOptions = 0;
api.ModifyIndividualStudentsOptions buildModifyIndividualStudentsOptions() {
  var o = api.ModifyIndividualStudentsOptions();
  buildCounterModifyIndividualStudentsOptions++;
  if (buildCounterModifyIndividualStudentsOptions < 3) {
    o.addStudentIds = buildUnnamed5563();
    o.removeStudentIds = buildUnnamed5564();
  }
  buildCounterModifyIndividualStudentsOptions--;
  return o;
}

void checkModifyIndividualStudentsOptions(
    api.ModifyIndividualStudentsOptions o) {
  buildCounterModifyIndividualStudentsOptions++;
  if (buildCounterModifyIndividualStudentsOptions < 3) {
    checkUnnamed5563(o.addStudentIds!);
    checkUnnamed5564(o.removeStudentIds!);
  }
  buildCounterModifyIndividualStudentsOptions--;
}

core.List<core.String> buildUnnamed5565() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5565(core.List<core.String> o) {
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

core.int buildCounterMultipleChoiceQuestion = 0;
api.MultipleChoiceQuestion buildMultipleChoiceQuestion() {
  var o = api.MultipleChoiceQuestion();
  buildCounterMultipleChoiceQuestion++;
  if (buildCounterMultipleChoiceQuestion < 3) {
    o.choices = buildUnnamed5565();
  }
  buildCounterMultipleChoiceQuestion--;
  return o;
}

void checkMultipleChoiceQuestion(api.MultipleChoiceQuestion o) {
  buildCounterMultipleChoiceQuestion++;
  if (buildCounterMultipleChoiceQuestion < 3) {
    checkUnnamed5565(o.choices!);
  }
  buildCounterMultipleChoiceQuestion--;
}

core.int buildCounterMultipleChoiceSubmission = 0;
api.MultipleChoiceSubmission buildMultipleChoiceSubmission() {
  var o = api.MultipleChoiceSubmission();
  buildCounterMultipleChoiceSubmission++;
  if (buildCounterMultipleChoiceSubmission < 3) {
    o.answer = 'foo';
  }
  buildCounterMultipleChoiceSubmission--;
  return o;
}

void checkMultipleChoiceSubmission(api.MultipleChoiceSubmission o) {
  buildCounterMultipleChoiceSubmission++;
  if (buildCounterMultipleChoiceSubmission < 3) {
    unittest.expect(
      o.answer!,
      unittest.equals('foo'),
    );
  }
  buildCounterMultipleChoiceSubmission--;
}

core.int buildCounterName = 0;
api.Name buildName() {
  var o = api.Name();
  buildCounterName++;
  if (buildCounterName < 3) {
    o.familyName = 'foo';
    o.fullName = 'foo';
    o.givenName = 'foo';
  }
  buildCounterName--;
  return o;
}

void checkName(api.Name o) {
  buildCounterName++;
  if (buildCounterName < 3) {
    unittest.expect(
      o.familyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fullName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.givenName!,
      unittest.equals('foo'),
    );
  }
  buildCounterName--;
}

core.int buildCounterReclaimStudentSubmissionRequest = 0;
api.ReclaimStudentSubmissionRequest buildReclaimStudentSubmissionRequest() {
  var o = api.ReclaimStudentSubmissionRequest();
  buildCounterReclaimStudentSubmissionRequest++;
  if (buildCounterReclaimStudentSubmissionRequest < 3) {}
  buildCounterReclaimStudentSubmissionRequest--;
  return o;
}

void checkReclaimStudentSubmissionRequest(
    api.ReclaimStudentSubmissionRequest o) {
  buildCounterReclaimStudentSubmissionRequest++;
  if (buildCounterReclaimStudentSubmissionRequest < 3) {}
  buildCounterReclaimStudentSubmissionRequest--;
}

core.int buildCounterRegistration = 0;
api.Registration buildRegistration() {
  var o = api.Registration();
  buildCounterRegistration++;
  if (buildCounterRegistration < 3) {
    o.cloudPubsubTopic = buildCloudPubsubTopic();
    o.expiryTime = 'foo';
    o.feed = buildFeed();
    o.registrationId = 'foo';
  }
  buildCounterRegistration--;
  return o;
}

void checkRegistration(api.Registration o) {
  buildCounterRegistration++;
  if (buildCounterRegistration < 3) {
    checkCloudPubsubTopic(o.cloudPubsubTopic! as api.CloudPubsubTopic);
    unittest.expect(
      o.expiryTime!,
      unittest.equals('foo'),
    );
    checkFeed(o.feed! as api.Feed);
    unittest.expect(
      o.registrationId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRegistration--;
}

core.int buildCounterReturnStudentSubmissionRequest = 0;
api.ReturnStudentSubmissionRequest buildReturnStudentSubmissionRequest() {
  var o = api.ReturnStudentSubmissionRequest();
  buildCounterReturnStudentSubmissionRequest++;
  if (buildCounterReturnStudentSubmissionRequest < 3) {}
  buildCounterReturnStudentSubmissionRequest--;
  return o;
}

void checkReturnStudentSubmissionRequest(api.ReturnStudentSubmissionRequest o) {
  buildCounterReturnStudentSubmissionRequest++;
  if (buildCounterReturnStudentSubmissionRequest < 3) {}
  buildCounterReturnStudentSubmissionRequest--;
}

core.int buildCounterSharedDriveFile = 0;
api.SharedDriveFile buildSharedDriveFile() {
  var o = api.SharedDriveFile();
  buildCounterSharedDriveFile++;
  if (buildCounterSharedDriveFile < 3) {
    o.driveFile = buildDriveFile();
    o.shareMode = 'foo';
  }
  buildCounterSharedDriveFile--;
  return o;
}

void checkSharedDriveFile(api.SharedDriveFile o) {
  buildCounterSharedDriveFile++;
  if (buildCounterSharedDriveFile < 3) {
    checkDriveFile(o.driveFile! as api.DriveFile);
    unittest.expect(
      o.shareMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterSharedDriveFile--;
}

core.int buildCounterShortAnswerSubmission = 0;
api.ShortAnswerSubmission buildShortAnswerSubmission() {
  var o = api.ShortAnswerSubmission();
  buildCounterShortAnswerSubmission++;
  if (buildCounterShortAnswerSubmission < 3) {
    o.answer = 'foo';
  }
  buildCounterShortAnswerSubmission--;
  return o;
}

void checkShortAnswerSubmission(api.ShortAnswerSubmission o) {
  buildCounterShortAnswerSubmission++;
  if (buildCounterShortAnswerSubmission < 3) {
    unittest.expect(
      o.answer!,
      unittest.equals('foo'),
    );
  }
  buildCounterShortAnswerSubmission--;
}

core.int buildCounterStateHistory = 0;
api.StateHistory buildStateHistory() {
  var o = api.StateHistory();
  buildCounterStateHistory++;
  if (buildCounterStateHistory < 3) {
    o.actorUserId = 'foo';
    o.state = 'foo';
    o.stateTimestamp = 'foo';
  }
  buildCounterStateHistory--;
  return o;
}

void checkStateHistory(api.StateHistory o) {
  buildCounterStateHistory++;
  if (buildCounterStateHistory < 3) {
    unittest.expect(
      o.actorUserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stateTimestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterStateHistory--;
}

core.int buildCounterStudent = 0;
api.Student buildStudent() {
  var o = api.Student();
  buildCounterStudent++;
  if (buildCounterStudent < 3) {
    o.courseId = 'foo';
    o.profile = buildUserProfile();
    o.studentWorkFolder = buildDriveFolder();
    o.userId = 'foo';
  }
  buildCounterStudent--;
  return o;
}

void checkStudent(api.Student o) {
  buildCounterStudent++;
  if (buildCounterStudent < 3) {
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    checkUserProfile(o.profile! as api.UserProfile);
    checkDriveFolder(o.studentWorkFolder! as api.DriveFolder);
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterStudent--;
}

core.List<api.SubmissionHistory> buildUnnamed5566() {
  var o = <api.SubmissionHistory>[];
  o.add(buildSubmissionHistory());
  o.add(buildSubmissionHistory());
  return o;
}

void checkUnnamed5566(core.List<api.SubmissionHistory> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSubmissionHistory(o[0] as api.SubmissionHistory);
  checkSubmissionHistory(o[1] as api.SubmissionHistory);
}

core.int buildCounterStudentSubmission = 0;
api.StudentSubmission buildStudentSubmission() {
  var o = api.StudentSubmission();
  buildCounterStudentSubmission++;
  if (buildCounterStudentSubmission < 3) {
    o.alternateLink = 'foo';
    o.assignedGrade = 42.0;
    o.assignmentSubmission = buildAssignmentSubmission();
    o.associatedWithDeveloper = true;
    o.courseId = 'foo';
    o.courseWorkId = 'foo';
    o.courseWorkType = 'foo';
    o.creationTime = 'foo';
    o.draftGrade = 42.0;
    o.id = 'foo';
    o.late = true;
    o.multipleChoiceSubmission = buildMultipleChoiceSubmission();
    o.shortAnswerSubmission = buildShortAnswerSubmission();
    o.state = 'foo';
    o.submissionHistory = buildUnnamed5566();
    o.updateTime = 'foo';
    o.userId = 'foo';
  }
  buildCounterStudentSubmission--;
  return o;
}

void checkStudentSubmission(api.StudentSubmission o) {
  buildCounterStudentSubmission++;
  if (buildCounterStudentSubmission < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.assignedGrade!,
      unittest.equals(42.0),
    );
    checkAssignmentSubmission(
        o.assignmentSubmission! as api.AssignmentSubmission);
    unittest.expect(o.associatedWithDeveloper!, unittest.isTrue);
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.courseWorkId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.courseWorkType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.draftGrade!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.late!, unittest.isTrue);
    checkMultipleChoiceSubmission(
        o.multipleChoiceSubmission! as api.MultipleChoiceSubmission);
    checkShortAnswerSubmission(
        o.shortAnswerSubmission! as api.ShortAnswerSubmission);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkUnnamed5566(o.submissionHistory!);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterStudentSubmission--;
}

core.int buildCounterSubmissionHistory = 0;
api.SubmissionHistory buildSubmissionHistory() {
  var o = api.SubmissionHistory();
  buildCounterSubmissionHistory++;
  if (buildCounterSubmissionHistory < 3) {
    o.gradeHistory = buildGradeHistory();
    o.stateHistory = buildStateHistory();
  }
  buildCounterSubmissionHistory--;
  return o;
}

void checkSubmissionHistory(api.SubmissionHistory o) {
  buildCounterSubmissionHistory++;
  if (buildCounterSubmissionHistory < 3) {
    checkGradeHistory(o.gradeHistory! as api.GradeHistory);
    checkStateHistory(o.stateHistory! as api.StateHistory);
  }
  buildCounterSubmissionHistory--;
}

core.int buildCounterTeacher = 0;
api.Teacher buildTeacher() {
  var o = api.Teacher();
  buildCounterTeacher++;
  if (buildCounterTeacher < 3) {
    o.courseId = 'foo';
    o.profile = buildUserProfile();
    o.userId = 'foo';
  }
  buildCounterTeacher--;
  return o;
}

void checkTeacher(api.Teacher o) {
  buildCounterTeacher++;
  if (buildCounterTeacher < 3) {
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    checkUserProfile(o.profile! as api.UserProfile);
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterTeacher--;
}

core.int buildCounterTimeOfDay = 0;
api.TimeOfDay buildTimeOfDay() {
  var o = api.TimeOfDay();
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    o.hours = 42;
    o.minutes = 42;
    o.nanos = 42;
    o.seconds = 42;
  }
  buildCounterTimeOfDay--;
  return o;
}

void checkTimeOfDay(api.TimeOfDay o) {
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    unittest.expect(
      o.hours!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minutes!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.seconds!,
      unittest.equals(42),
    );
  }
  buildCounterTimeOfDay--;
}

core.int buildCounterTopic = 0;
api.Topic buildTopic() {
  var o = api.Topic();
  buildCounterTopic++;
  if (buildCounterTopic < 3) {
    o.courseId = 'foo';
    o.name = 'foo';
    o.topicId = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterTopic--;
  return o;
}

void checkTopic(api.Topic o) {
  buildCounterTopic++;
  if (buildCounterTopic < 3) {
    unittest.expect(
      o.courseId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.topicId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTopic--;
}

core.int buildCounterTurnInStudentSubmissionRequest = 0;
api.TurnInStudentSubmissionRequest buildTurnInStudentSubmissionRequest() {
  var o = api.TurnInStudentSubmissionRequest();
  buildCounterTurnInStudentSubmissionRequest++;
  if (buildCounterTurnInStudentSubmissionRequest < 3) {}
  buildCounterTurnInStudentSubmissionRequest--;
  return o;
}

void checkTurnInStudentSubmissionRequest(api.TurnInStudentSubmissionRequest o) {
  buildCounterTurnInStudentSubmissionRequest++;
  if (buildCounterTurnInStudentSubmissionRequest < 3) {}
  buildCounterTurnInStudentSubmissionRequest--;
}

core.List<api.GlobalPermission> buildUnnamed5567() {
  var o = <api.GlobalPermission>[];
  o.add(buildGlobalPermission());
  o.add(buildGlobalPermission());
  return o;
}

void checkUnnamed5567(core.List<api.GlobalPermission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGlobalPermission(o[0] as api.GlobalPermission);
  checkGlobalPermission(o[1] as api.GlobalPermission);
}

core.int buildCounterUserProfile = 0;
api.UserProfile buildUserProfile() {
  var o = api.UserProfile();
  buildCounterUserProfile++;
  if (buildCounterUserProfile < 3) {
    o.emailAddress = 'foo';
    o.id = 'foo';
    o.name = buildName();
    o.permissions = buildUnnamed5567();
    o.photoUrl = 'foo';
    o.verifiedTeacher = true;
  }
  buildCounterUserProfile--;
  return o;
}

void checkUserProfile(api.UserProfile o) {
  buildCounterUserProfile++;
  if (buildCounterUserProfile < 3) {
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkName(o.name! as api.Name);
    checkUnnamed5567(o.permissions!);
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.verifiedTeacher!, unittest.isTrue);
  }
  buildCounterUserProfile--;
}

core.int buildCounterYouTubeVideo = 0;
api.YouTubeVideo buildYouTubeVideo() {
  var o = api.YouTubeVideo();
  buildCounterYouTubeVideo++;
  if (buildCounterYouTubeVideo < 3) {
    o.alternateLink = 'foo';
    o.id = 'foo';
    o.thumbnailUrl = 'foo';
    o.title = 'foo';
  }
  buildCounterYouTubeVideo--;
  return o;
}

void checkYouTubeVideo(api.YouTubeVideo o) {
  buildCounterYouTubeVideo++;
  if (buildCounterYouTubeVideo < 3) {
    unittest.expect(
      o.alternateLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterYouTubeVideo--;
}

core.List<core.String> buildUnnamed5568() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5568(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5569() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5569(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5570() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5570(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5571() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5571(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5572() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5572(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5573() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5573(core.List<core.String> o) {
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

void main() {
  unittest.group('obj-schema-Announcement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnnouncement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Announcement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnnouncement(od as api.Announcement);
    });
  });

  unittest.group('obj-schema-Assignment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssignment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Assignment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAssignment(od as api.Assignment);
    });
  });

  unittest.group('obj-schema-AssignmentSubmission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssignmentSubmission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AssignmentSubmission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAssignmentSubmission(od as api.AssignmentSubmission);
    });
  });

  unittest.group('obj-schema-Attachment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttachment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Attachment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAttachment(od as api.Attachment);
    });
  });

  unittest.group('obj-schema-CloudPubsubTopic', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudPubsubTopic();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudPubsubTopic.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudPubsubTopic(od as api.CloudPubsubTopic);
    });
  });

  unittest.group('obj-schema-Course', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Course.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCourse(od as api.Course);
    });
  });

  unittest.group('obj-schema-CourseAlias', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourseAlias();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CourseAlias.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCourseAlias(od as api.CourseAlias);
    });
  });

  unittest.group('obj-schema-CourseMaterial', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourseMaterial();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CourseMaterial.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCourseMaterial(od as api.CourseMaterial);
    });
  });

  unittest.group('obj-schema-CourseMaterialSet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourseMaterialSet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CourseMaterialSet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCourseMaterialSet(od as api.CourseMaterialSet);
    });
  });

  unittest.group('obj-schema-CourseRosterChangesInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourseRosterChangesInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CourseRosterChangesInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCourseRosterChangesInfo(od as api.CourseRosterChangesInfo);
    });
  });

  unittest.group('obj-schema-CourseWork', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourseWork();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CourseWork.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCourseWork(od as api.CourseWork);
    });
  });

  unittest.group('obj-schema-CourseWorkChangesInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourseWorkChangesInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CourseWorkChangesInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCourseWorkChangesInfo(od as api.CourseWorkChangesInfo);
    });
  });

  unittest.group('obj-schema-CourseWorkMaterial', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCourseWorkMaterial();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CourseWorkMaterial.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCourseWorkMaterial(od as api.CourseWorkMaterial);
    });
  });

  unittest.group('obj-schema-Date', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Date.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDate(od as api.Date);
    });
  });

  unittest.group('obj-schema-DriveFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DriveFile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDriveFile(od as api.DriveFile);
    });
  });

  unittest.group('obj-schema-DriveFolder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveFolder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveFolder.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveFolder(od as api.DriveFolder);
    });
  });

  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-Feed', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeed();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Feed.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFeed(od as api.Feed);
    });
  });

  unittest.group('obj-schema-Form', () {
    unittest.test('to-json--from-json', () async {
      var o = buildForm();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Form.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkForm(od as api.Form);
    });
  });

  unittest.group('obj-schema-GlobalPermission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGlobalPermission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GlobalPermission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGlobalPermission(od as api.GlobalPermission);
    });
  });

  unittest.group('obj-schema-GradeHistory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGradeHistory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GradeHistory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGradeHistory(od as api.GradeHistory);
    });
  });

  unittest.group('obj-schema-Guardian', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGuardian();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Guardian.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGuardian(od as api.Guardian);
    });
  });

  unittest.group('obj-schema-GuardianInvitation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGuardianInvitation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GuardianInvitation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGuardianInvitation(od as api.GuardianInvitation);
    });
  });

  unittest.group('obj-schema-IndividualStudentsOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIndividualStudentsOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IndividualStudentsOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIndividualStudentsOptions(od as api.IndividualStudentsOptions);
    });
  });

  unittest.group('obj-schema-Invitation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInvitation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Invitation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInvitation(od as api.Invitation);
    });
  });

  unittest.group('obj-schema-Link', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Link.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLink(od as api.Link);
    });
  });

  unittest.group('obj-schema-ListAnnouncementsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAnnouncementsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAnnouncementsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAnnouncementsResponse(od as api.ListAnnouncementsResponse);
    });
  });

  unittest.group('obj-schema-ListCourseAliasesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCourseAliasesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCourseAliasesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCourseAliasesResponse(od as api.ListCourseAliasesResponse);
    });
  });

  unittest.group('obj-schema-ListCourseWorkMaterialResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCourseWorkMaterialResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCourseWorkMaterialResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCourseWorkMaterialResponse(
          od as api.ListCourseWorkMaterialResponse);
    });
  });

  unittest.group('obj-schema-ListCourseWorkResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCourseWorkResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCourseWorkResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCourseWorkResponse(od as api.ListCourseWorkResponse);
    });
  });

  unittest.group('obj-schema-ListCoursesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCoursesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCoursesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCoursesResponse(od as api.ListCoursesResponse);
    });
  });

  unittest.group('obj-schema-ListGuardianInvitationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListGuardianInvitationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListGuardianInvitationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListGuardianInvitationsResponse(
          od as api.ListGuardianInvitationsResponse);
    });
  });

  unittest.group('obj-schema-ListGuardiansResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListGuardiansResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListGuardiansResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListGuardiansResponse(od as api.ListGuardiansResponse);
    });
  });

  unittest.group('obj-schema-ListInvitationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInvitationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInvitationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInvitationsResponse(od as api.ListInvitationsResponse);
    });
  });

  unittest.group('obj-schema-ListStudentSubmissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListStudentSubmissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListStudentSubmissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListStudentSubmissionsResponse(
          od as api.ListStudentSubmissionsResponse);
    });
  });

  unittest.group('obj-schema-ListStudentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListStudentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListStudentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListStudentsResponse(od as api.ListStudentsResponse);
    });
  });

  unittest.group('obj-schema-ListTeachersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTeachersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTeachersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTeachersResponse(od as api.ListTeachersResponse);
    });
  });

  unittest.group('obj-schema-ListTopicResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTopicResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTopicResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTopicResponse(od as api.ListTopicResponse);
    });
  });

  unittest.group('obj-schema-Material', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMaterial();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Material.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMaterial(od as api.Material);
    });
  });

  unittest.group('obj-schema-ModifyAnnouncementAssigneesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyAnnouncementAssigneesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyAnnouncementAssigneesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyAnnouncementAssigneesRequest(
          od as api.ModifyAnnouncementAssigneesRequest);
    });
  });

  unittest.group('obj-schema-ModifyAttachmentsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyAttachmentsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyAttachmentsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyAttachmentsRequest(od as api.ModifyAttachmentsRequest);
    });
  });

  unittest.group('obj-schema-ModifyCourseWorkAssigneesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyCourseWorkAssigneesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyCourseWorkAssigneesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyCourseWorkAssigneesRequest(
          od as api.ModifyCourseWorkAssigneesRequest);
    });
  });

  unittest.group('obj-schema-ModifyIndividualStudentsOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyIndividualStudentsOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyIndividualStudentsOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyIndividualStudentsOptions(
          od as api.ModifyIndividualStudentsOptions);
    });
  });

  unittest.group('obj-schema-MultipleChoiceQuestion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMultipleChoiceQuestion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MultipleChoiceQuestion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMultipleChoiceQuestion(od as api.MultipleChoiceQuestion);
    });
  });

  unittest.group('obj-schema-MultipleChoiceSubmission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMultipleChoiceSubmission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MultipleChoiceSubmission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMultipleChoiceSubmission(od as api.MultipleChoiceSubmission);
    });
  });

  unittest.group('obj-schema-Name', () {
    unittest.test('to-json--from-json', () async {
      var o = buildName();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Name.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkName(od as api.Name);
    });
  });

  unittest.group('obj-schema-ReclaimStudentSubmissionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReclaimStudentSubmissionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReclaimStudentSubmissionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReclaimStudentSubmissionRequest(
          od as api.ReclaimStudentSubmissionRequest);
    });
  });

  unittest.group('obj-schema-Registration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegistration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Registration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegistration(od as api.Registration);
    });
  });

  unittest.group('obj-schema-ReturnStudentSubmissionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReturnStudentSubmissionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReturnStudentSubmissionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReturnStudentSubmissionRequest(
          od as api.ReturnStudentSubmissionRequest);
    });
  });

  unittest.group('obj-schema-SharedDriveFile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSharedDriveFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SharedDriveFile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSharedDriveFile(od as api.SharedDriveFile);
    });
  });

  unittest.group('obj-schema-ShortAnswerSubmission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShortAnswerSubmission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ShortAnswerSubmission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkShortAnswerSubmission(od as api.ShortAnswerSubmission);
    });
  });

  unittest.group('obj-schema-StateHistory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStateHistory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StateHistory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStateHistory(od as api.StateHistory);
    });
  });

  unittest.group('obj-schema-Student', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStudent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Student.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStudent(od as api.Student);
    });
  });

  unittest.group('obj-schema-StudentSubmission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStudentSubmission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StudentSubmission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStudentSubmission(od as api.StudentSubmission);
    });
  });

  unittest.group('obj-schema-SubmissionHistory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubmissionHistory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubmissionHistory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubmissionHistory(od as api.SubmissionHistory);
    });
  });

  unittest.group('obj-schema-Teacher', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTeacher();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Teacher.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTeacher(od as api.Teacher);
    });
  });

  unittest.group('obj-schema-TimeOfDay', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeOfDay();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeOfDay.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeOfDay(od as api.TimeOfDay);
    });
  });

  unittest.group('obj-schema-Topic', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTopic();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Topic.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTopic(od as api.Topic);
    });
  });

  unittest.group('obj-schema-TurnInStudentSubmissionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTurnInStudentSubmissionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TurnInStudentSubmissionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTurnInStudentSubmissionRequest(
          od as api.TurnInStudentSubmissionRequest);
    });
  });

  unittest.group('obj-schema-UserProfile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserProfile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserProfile(od as api.UserProfile);
    });
  });

  unittest.group('obj-schema-YouTubeVideo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildYouTubeVideo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.YouTubeVideo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkYouTubeVideo(od as api.YouTubeVideo);
    });
  });

  unittest.group('resource-CoursesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses;
      var arg_request = buildCourse();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Course.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCourse(obj as api.Course);

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
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v1/courses"),
        );
        pathOffset += 10;

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
        var resp = convert.json.encode(buildCourse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkCourse(response as api.Course);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses;
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_id, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses;
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildCourse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_id, $fields: arg_$fields);
      checkCourse(response as api.Course);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses;
      var arg_courseStates = buildUnnamed5568();
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_studentId = 'foo';
      var arg_teacherId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v1/courses"),
        );
        pathOffset += 10;

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
          queryMap["courseStates"]!,
          unittest.equals(arg_courseStates),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["studentId"]!.first,
          unittest.equals(arg_studentId),
        );
        unittest.expect(
          queryMap["teacherId"]!.first,
          unittest.equals(arg_teacherId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListCoursesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          courseStates: arg_courseStates,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          studentId: arg_studentId,
          teacherId: arg_teacherId,
          $fields: arg_$fields);
      checkListCoursesResponse(response as api.ListCoursesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses;
      var arg_request = buildCourse();
      var arg_id = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Course.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCourse(obj as api.Course);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCourse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_id,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkCourse(response as api.Course);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses;
      var arg_request = buildCourse();
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Course.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCourse(obj as api.Course);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildCourse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_id, $fields: arg_$fields);
      checkCourse(response as api.Course);
    });
  });

  unittest.group('resource-CoursesAliasesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.aliases;
      var arg_request = buildCourseAlias();
      var arg_courseId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CourseAlias.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCourseAlias(obj as api.CourseAlias);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/aliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/aliases"),
        );
        pathOffset += 8;

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
        var resp = convert.json.encode(buildCourseAlias());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_courseId, $fields: arg_$fields);
      checkCourseAlias(response as api.CourseAlias);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.aliases;
      var arg_courseId = 'foo';
      var arg_alias = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/aliases/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/aliases/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_alias'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_courseId, arg_alias, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.aliases;
      var arg_courseId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/aliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/aliases"),
        );
        pathOffset += 8;

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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListCourseAliasesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCourseAliasesResponse(response as api.ListCourseAliasesResponse);
    });
  });

  unittest.group('resource-CoursesAnnouncementsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.announcements;
      var arg_request = buildAnnouncement();
      var arg_courseId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Announcement.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnnouncement(obj as api.Announcement);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/announcements', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/announcements"),
        );
        pathOffset += 14;

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
        var resp = convert.json.encode(buildAnnouncement());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_courseId, $fields: arg_$fields);
      checkAnnouncement(response as api.Announcement);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.announcements;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/announcements/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/announcements/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_courseId, arg_id, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.announcements;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/announcements/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/announcements/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildAnnouncement());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_courseId, arg_id, $fields: arg_$fields);
      checkAnnouncement(response as api.Announcement);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.announcements;
      var arg_courseId = 'foo';
      var arg_announcementStates = buildUnnamed5569();
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/announcements', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/announcements"),
        );
        pathOffset += 14;

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
          queryMap["announcementStates"]!,
          unittest.equals(arg_announcementStates),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListAnnouncementsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId,
          announcementStates: arg_announcementStates,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAnnouncementsResponse(response as api.ListAnnouncementsResponse);
    });

    unittest.test('method--modifyAssignees', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.announcements;
      var arg_request = buildModifyAnnouncementAssigneesRequest();
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyAnnouncementAssigneesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyAnnouncementAssigneesRequest(
            obj as api.ModifyAnnouncementAssigneesRequest);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/announcements/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/announcements/"),
        );
        pathOffset += 15;
        index = path.indexOf(':modifyAssignees', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals(":modifyAssignees"),
        );
        pathOffset += 16;

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
        var resp = convert.json.encode(buildAnnouncement());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.modifyAssignees(
          arg_request, arg_courseId, arg_id,
          $fields: arg_$fields);
      checkAnnouncement(response as api.Announcement);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.announcements;
      var arg_request = buildAnnouncement();
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Announcement.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnnouncement(obj as api.Announcement);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/announcements/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/announcements/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAnnouncement());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_courseId, arg_id,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAnnouncement(response as api.Announcement);
    });
  });

  unittest.group('resource-CoursesCourseWorkResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork;
      var arg_request = buildCourseWork();
      var arg_courseId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CourseWork.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCourseWork(obj as api.CourseWork);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/courseWork"),
        );
        pathOffset += 11;

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
        var resp = convert.json.encode(buildCourseWork());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_courseId, $fields: arg_$fields);
      checkCourseWork(response as api.CourseWork);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_courseId, arg_id, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildCourseWork());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_courseId, arg_id, $fields: arg_$fields);
      checkCourseWork(response as api.CourseWork);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork;
      var arg_courseId = 'foo';
      var arg_courseWorkStates = buildUnnamed5570();
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/courseWork"),
        );
        pathOffset += 11;

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
          queryMap["courseWorkStates"]!,
          unittest.equals(arg_courseWorkStates),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListCourseWorkResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId,
          courseWorkStates: arg_courseWorkStates,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCourseWorkResponse(response as api.ListCourseWorkResponse);
    });

    unittest.test('method--modifyAssignees', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork;
      var arg_request = buildModifyCourseWorkAssigneesRequest();
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyCourseWorkAssigneesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyCourseWorkAssigneesRequest(
            obj as api.ModifyCourseWorkAssigneesRequest);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf(':modifyAssignees', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals(":modifyAssignees"),
        );
        pathOffset += 16;

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
        var resp = convert.json.encode(buildCourseWork());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.modifyAssignees(
          arg_request, arg_courseId, arg_id,
          $fields: arg_$fields);
      checkCourseWork(response as api.CourseWork);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork;
      var arg_request = buildCourseWork();
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CourseWork.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCourseWork(obj as api.CourseWork);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCourseWork());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_courseId, arg_id,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkCourseWork(response as api.CourseWork);
    });
  });

  unittest.group('resource-CoursesCourseWorkStudentSubmissionsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork.studentSubmissions;
      var arg_courseId = 'foo';
      var arg_courseWorkId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf('/studentSubmissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseWorkId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/studentSubmissions/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildStudentSubmission());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_courseId, arg_courseWorkId, arg_id,
          $fields: arg_$fields);
      checkStudentSubmission(response as api.StudentSubmission);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork.studentSubmissions;
      var arg_courseId = 'foo';
      var arg_courseWorkId = 'foo';
      var arg_late = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_states = buildUnnamed5571();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf('/studentSubmissions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseWorkId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/studentSubmissions"),
        );
        pathOffset += 19;

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
          queryMap["late"]!.first,
          unittest.equals(arg_late),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["states"]!,
          unittest.equals(arg_states),
        );
        unittest.expect(
          queryMap["userId"]!.first,
          unittest.equals(arg_userId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListStudentSubmissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId, arg_courseWorkId,
          late: arg_late,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          states: arg_states,
          userId: arg_userId,
          $fields: arg_$fields);
      checkListStudentSubmissionsResponse(
          response as api.ListStudentSubmissionsResponse);
    });

    unittest.test('method--modifyAttachments', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork.studentSubmissions;
      var arg_request = buildModifyAttachmentsRequest();
      var arg_courseId = 'foo';
      var arg_courseWorkId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyAttachmentsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyAttachmentsRequest(obj as api.ModifyAttachmentsRequest);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf('/studentSubmissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseWorkId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/studentSubmissions/"),
        );
        pathOffset += 20;
        index = path.indexOf(':modifyAttachments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals(":modifyAttachments"),
        );
        pathOffset += 18;

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
        var resp = convert.json.encode(buildStudentSubmission());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.modifyAttachments(
          arg_request, arg_courseId, arg_courseWorkId, arg_id,
          $fields: arg_$fields);
      checkStudentSubmission(response as api.StudentSubmission);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork.studentSubmissions;
      var arg_request = buildStudentSubmission();
      var arg_courseId = 'foo';
      var arg_courseWorkId = 'foo';
      var arg_id = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StudentSubmission.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStudentSubmission(obj as api.StudentSubmission);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf('/studentSubmissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseWorkId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/studentSubmissions/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildStudentSubmission());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_courseId, arg_courseWorkId, arg_id,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkStudentSubmission(response as api.StudentSubmission);
    });

    unittest.test('method--reclaim', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork.studentSubmissions;
      var arg_request = buildReclaimStudentSubmissionRequest();
      var arg_courseId = 'foo';
      var arg_courseWorkId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReclaimStudentSubmissionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReclaimStudentSubmissionRequest(
            obj as api.ReclaimStudentSubmissionRequest);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf('/studentSubmissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseWorkId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/studentSubmissions/"),
        );
        pathOffset += 20;
        index = path.indexOf(':reclaim', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals(":reclaim"),
        );
        pathOffset += 8;

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.reclaim(
          arg_request, arg_courseId, arg_courseWorkId, arg_id,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--return_', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork.studentSubmissions;
      var arg_request = buildReturnStudentSubmissionRequest();
      var arg_courseId = 'foo';
      var arg_courseWorkId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReturnStudentSubmissionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReturnStudentSubmissionRequest(
            obj as api.ReturnStudentSubmissionRequest);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf('/studentSubmissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseWorkId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/studentSubmissions/"),
        );
        pathOffset += 20;
        index = path.indexOf(':return', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":return"),
        );
        pathOffset += 7;

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.return_(
          arg_request, arg_courseId, arg_courseWorkId, arg_id,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--turnIn', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWork.studentSubmissions;
      var arg_request = buildTurnInStudentSubmissionRequest();
      var arg_courseId = 'foo';
      var arg_courseWorkId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TurnInStudentSubmissionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTurnInStudentSubmissionRequest(
            obj as api.TurnInStudentSubmissionRequest);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWork/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/courseWork/"),
        );
        pathOffset += 12;
        index = path.indexOf('/studentSubmissions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseWorkId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/studentSubmissions/"),
        );
        pathOffset += 20;
        index = path.indexOf(':turnIn', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":turnIn"),
        );
        pathOffset += 7;

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.turnIn(
          arg_request, arg_courseId, arg_courseWorkId, arg_id,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });
  });

  unittest.group('resource-CoursesCourseWorkMaterialsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWorkMaterials;
      var arg_request = buildCourseWorkMaterial();
      var arg_courseId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CourseWorkMaterial.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCourseWorkMaterial(obj as api.CourseWorkMaterial);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWorkMaterials', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/courseWorkMaterials"),
        );
        pathOffset += 20;

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
        var resp = convert.json.encode(buildCourseWorkMaterial());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_courseId, $fields: arg_$fields);
      checkCourseWorkMaterial(response as api.CourseWorkMaterial);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWorkMaterials;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWorkMaterials/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/courseWorkMaterials/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_courseId, arg_id, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWorkMaterials;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWorkMaterials/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/courseWorkMaterials/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildCourseWorkMaterial());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_courseId, arg_id, $fields: arg_$fields);
      checkCourseWorkMaterial(response as api.CourseWorkMaterial);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWorkMaterials;
      var arg_courseId = 'foo';
      var arg_courseWorkMaterialStates = buildUnnamed5572();
      var arg_materialDriveId = 'foo';
      var arg_materialLink = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWorkMaterials', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/courseWorkMaterials"),
        );
        pathOffset += 20;

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
          queryMap["courseWorkMaterialStates"]!,
          unittest.equals(arg_courseWorkMaterialStates),
        );
        unittest.expect(
          queryMap["materialDriveId"]!.first,
          unittest.equals(arg_materialDriveId),
        );
        unittest.expect(
          queryMap["materialLink"]!.first,
          unittest.equals(arg_materialLink),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListCourseWorkMaterialResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId,
          courseWorkMaterialStates: arg_courseWorkMaterialStates,
          materialDriveId: arg_materialDriveId,
          materialLink: arg_materialLink,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCourseWorkMaterialResponse(
          response as api.ListCourseWorkMaterialResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.courseWorkMaterials;
      var arg_request = buildCourseWorkMaterial();
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CourseWorkMaterial.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCourseWorkMaterial(obj as api.CourseWorkMaterial);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/courseWorkMaterials/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/courseWorkMaterials/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCourseWorkMaterial());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_courseId, arg_id,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkCourseWorkMaterial(response as api.CourseWorkMaterial);
    });
  });

  unittest.group('resource-CoursesStudentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.students;
      var arg_request = buildStudent();
      var arg_courseId = 'foo';
      var arg_enrollmentCode = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Student.fromJson(json as core.Map<core.String, core.dynamic>);
        checkStudent(obj as api.Student);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/students', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/students"),
        );
        pathOffset += 9;

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
          queryMap["enrollmentCode"]!.first,
          unittest.equals(arg_enrollmentCode),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildStudent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_courseId,
          enrollmentCode: arg_enrollmentCode, $fields: arg_$fields);
      checkStudent(response as api.Student);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.students;
      var arg_courseId = 'foo';
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/students/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/students/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_courseId, arg_userId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.students;
      var arg_courseId = 'foo';
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/students/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/students/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );

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
        var resp = convert.json.encode(buildStudent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_courseId, arg_userId, $fields: arg_$fields);
      checkStudent(response as api.Student);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.students;
      var arg_courseId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/students', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/students"),
        );
        pathOffset += 9;

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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListStudentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListStudentsResponse(response as api.ListStudentsResponse);
    });
  });

  unittest.group('resource-CoursesTeachersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.teachers;
      var arg_request = buildTeacher();
      var arg_courseId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Teacher.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTeacher(obj as api.Teacher);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/teachers', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/teachers"),
        );
        pathOffset += 9;

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
        var resp = convert.json.encode(buildTeacher());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_courseId, $fields: arg_$fields);
      checkTeacher(response as api.Teacher);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.teachers;
      var arg_courseId = 'foo';
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/teachers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/teachers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_courseId, arg_userId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.teachers;
      var arg_courseId = 'foo';
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/teachers/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/teachers/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );

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
        var resp = convert.json.encode(buildTeacher());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_courseId, arg_userId, $fields: arg_$fields);
      checkTeacher(response as api.Teacher);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.teachers;
      var arg_courseId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/teachers', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/teachers"),
        );
        pathOffset += 9;

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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListTeachersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListTeachersResponse(response as api.ListTeachersResponse);
    });
  });

  unittest.group('resource-CoursesTopicsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.topics;
      var arg_request = buildTopic();
      var arg_courseId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Topic.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTopic(obj as api.Topic);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/topics', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/topics"),
        );
        pathOffset += 7;

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
        var resp = convert.json.encode(buildTopic());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_courseId, $fields: arg_$fields);
      checkTopic(response as api.Topic);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.topics;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/topics/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/topics/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_courseId, arg_id, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.topics;
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/topics/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/topics/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildTopic());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_courseId, arg_id, $fields: arg_$fields);
      checkTopic(response as api.Topic);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.topics;
      var arg_courseId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/topics', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/topics"),
        );
        pathOffset += 7;

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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListTopicResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_courseId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListTopicResponse(response as api.ListTopicResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).courses.topics;
      var arg_request = buildTopic();
      var arg_courseId = 'foo';
      var arg_id = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Topic.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTopic(obj as api.Topic);

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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/courses/"),
        );
        pathOffset += 11;
        index = path.indexOf('/topics/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_courseId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/topics/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTopic());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_courseId, arg_id,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkTopic(response as api.Topic);
    });
  });

  unittest.group('resource-InvitationsResource', () {
    unittest.test('method--accept', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).invitations;
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/invitations/"),
        );
        pathOffset += 15;
        index = path.indexOf(':accept', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":accept"),
        );
        pathOffset += 7;

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.accept(arg_id, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).invitations;
      var arg_request = buildInvitation();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Invitation.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInvitation(obj as api.Invitation);

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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/invitations"),
        );
        pathOffset += 14;

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
        var resp = convert.json.encode(buildInvitation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkInvitation(response as api.Invitation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).invitations;
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/invitations/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_id, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).invitations;
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/invitations/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );

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
        var resp = convert.json.encode(buildInvitation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_id, $fields: arg_$fields);
      checkInvitation(response as api.Invitation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).invitations;
      var arg_courseId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/invitations"),
        );
        pathOffset += 14;

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
          queryMap["courseId"]!.first,
          unittest.equals(arg_courseId),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["userId"]!.first,
          unittest.equals(arg_userId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListInvitationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          courseId: arg_courseId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          userId: arg_userId,
          $fields: arg_$fields);
      checkListInvitationsResponse(response as api.ListInvitationsResponse);
    });
  });

  unittest.group('resource-RegistrationsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).registrations;
      var arg_request = buildRegistration();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Registration.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRegistration(obj as api.Registration);

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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/registrations"),
        );
        pathOffset += 16;

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
        var resp = convert.json.encode(buildRegistration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkRegistration(response as api.Registration);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).registrations;
      var arg_registrationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v1/registrations/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_registrationId'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_registrationId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });
  });

  unittest.group('resource-UserProfilesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles;
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );

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
        var resp = convert.json.encode(buildUserProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, $fields: arg_$fields);
      checkUserProfile(response as api.UserProfile);
    });
  });

  unittest.group('resource-UserProfilesGuardianInvitationsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles.guardianInvitations;
      var arg_request = buildGuardianInvitation();
      var arg_studentId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GuardianInvitation.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGuardianInvitation(obj as api.GuardianInvitation);

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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        index = path.indexOf('/guardianInvitations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_studentId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/guardianInvitations"),
        );
        pathOffset += 20;

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
        var resp = convert.json.encode(buildGuardianInvitation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_studentId, $fields: arg_$fields);
      checkGuardianInvitation(response as api.GuardianInvitation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles.guardianInvitations;
      var arg_studentId = 'foo';
      var arg_invitationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        index = path.indexOf('/guardianInvitations/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_studentId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/guardianInvitations/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_invitationId'),
        );

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
        var resp = convert.json.encode(buildGuardianInvitation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_studentId, arg_invitationId, $fields: arg_$fields);
      checkGuardianInvitation(response as api.GuardianInvitation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles.guardianInvitations;
      var arg_studentId = 'foo';
      var arg_invitedEmailAddress = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_states = buildUnnamed5573();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        index = path.indexOf('/guardianInvitations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_studentId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/guardianInvitations"),
        );
        pathOffset += 20;

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
          queryMap["invitedEmailAddress"]!.first,
          unittest.equals(arg_invitedEmailAddress),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["states"]!,
          unittest.equals(arg_states),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListGuardianInvitationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_studentId,
          invitedEmailAddress: arg_invitedEmailAddress,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          states: arg_states,
          $fields: arg_$fields);
      checkListGuardianInvitationsResponse(
          response as api.ListGuardianInvitationsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles.guardianInvitations;
      var arg_request = buildGuardianInvitation();
      var arg_studentId = 'foo';
      var arg_invitationId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GuardianInvitation.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGuardianInvitation(obj as api.GuardianInvitation);

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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        index = path.indexOf('/guardianInvitations/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_studentId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/guardianInvitations/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_invitationId'),
        );

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGuardianInvitation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_studentId, arg_invitationId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGuardianInvitation(response as api.GuardianInvitation);
    });
  });

  unittest.group('resource-UserProfilesGuardiansResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles.guardians;
      var arg_studentId = 'foo';
      var arg_guardianId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        index = path.indexOf('/guardians/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_studentId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/guardians/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_guardianId'),
        );

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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_studentId, arg_guardianId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles.guardians;
      var arg_studentId = 'foo';
      var arg_guardianId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        index = path.indexOf('/guardians/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_studentId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/guardians/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_guardianId'),
        );

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
        var resp = convert.json.encode(buildGuardian());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_studentId, arg_guardianId, $fields: arg_$fields);
      checkGuardian(response as api.Guardian);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ClassroomApi(mock).userProfiles.guardians;
      var arg_studentId = 'foo';
      var arg_invitedEmailAddress = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("v1/userProfiles/"),
        );
        pathOffset += 16;
        index = path.indexOf('/guardians', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_studentId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/guardians"),
        );
        pathOffset += 10;

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
          queryMap["invitedEmailAddress"]!.first,
          unittest.equals(arg_invitedEmailAddress),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListGuardiansResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_studentId,
          invitedEmailAddress: arg_invitedEmailAddress,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListGuardiansResponse(response as api.ListGuardiansResponse);
    });
  });
}
