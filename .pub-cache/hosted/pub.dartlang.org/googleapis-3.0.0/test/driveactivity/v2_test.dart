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

import 'package:googleapis/driveactivity/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAction = 0;
api.Action buildAction() {
  var o = api.Action();
  buildCounterAction++;
  if (buildCounterAction < 3) {
    o.actor = buildActor();
    o.detail = buildActionDetail();
    o.target = buildTarget();
    o.timeRange = buildTimeRange();
    o.timestamp = 'foo';
  }
  buildCounterAction--;
  return o;
}

void checkAction(api.Action o) {
  buildCounterAction++;
  if (buildCounterAction < 3) {
    checkActor(o.actor! as api.Actor);
    checkActionDetail(o.detail! as api.ActionDetail);
    checkTarget(o.target! as api.Target);
    checkTimeRange(o.timeRange! as api.TimeRange);
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterAction--;
}

core.int buildCounterActionDetail = 0;
api.ActionDetail buildActionDetail() {
  var o = api.ActionDetail();
  buildCounterActionDetail++;
  if (buildCounterActionDetail < 3) {
    o.comment = buildComment();
    o.create = buildCreate();
    o.delete = buildDelete();
    o.dlpChange = buildDataLeakPreventionChange();
    o.edit = buildEdit();
    o.move = buildMove();
    o.permissionChange = buildPermissionChange();
    o.reference = buildApplicationReference();
    o.rename = buildRename();
    o.restore = buildRestore();
    o.settingsChange = buildSettingsChange();
  }
  buildCounterActionDetail--;
  return o;
}

void checkActionDetail(api.ActionDetail o) {
  buildCounterActionDetail++;
  if (buildCounterActionDetail < 3) {
    checkComment(o.comment! as api.Comment);
    checkCreate(o.create! as api.Create);
    checkDelete(o.delete! as api.Delete);
    checkDataLeakPreventionChange(o.dlpChange! as api.DataLeakPreventionChange);
    checkEdit(o.edit! as api.Edit);
    checkMove(o.move! as api.Move);
    checkPermissionChange(o.permissionChange! as api.PermissionChange);
    checkApplicationReference(o.reference! as api.ApplicationReference);
    checkRename(o.rename! as api.Rename);
    checkRestore(o.restore! as api.Restore);
    checkSettingsChange(o.settingsChange! as api.SettingsChange);
  }
  buildCounterActionDetail--;
}

core.int buildCounterActor = 0;
api.Actor buildActor() {
  var o = api.Actor();
  buildCounterActor++;
  if (buildCounterActor < 3) {
    o.administrator = buildAdministrator();
    o.anonymous = buildAnonymousUser();
    o.impersonation = buildImpersonation();
    o.system = buildSystemEvent();
    o.user = buildUser();
  }
  buildCounterActor--;
  return o;
}

void checkActor(api.Actor o) {
  buildCounterActor++;
  if (buildCounterActor < 3) {
    checkAdministrator(o.administrator! as api.Administrator);
    checkAnonymousUser(o.anonymous! as api.AnonymousUser);
    checkImpersonation(o.impersonation! as api.Impersonation);
    checkSystemEvent(o.system! as api.SystemEvent);
    checkUser(o.user! as api.User);
  }
  buildCounterActor--;
}

core.int buildCounterAdministrator = 0;
api.Administrator buildAdministrator() {
  var o = api.Administrator();
  buildCounterAdministrator++;
  if (buildCounterAdministrator < 3) {}
  buildCounterAdministrator--;
  return o;
}

void checkAdministrator(api.Administrator o) {
  buildCounterAdministrator++;
  if (buildCounterAdministrator < 3) {}
  buildCounterAdministrator--;
}

core.int buildCounterAnonymousUser = 0;
api.AnonymousUser buildAnonymousUser() {
  var o = api.AnonymousUser();
  buildCounterAnonymousUser++;
  if (buildCounterAnonymousUser < 3) {}
  buildCounterAnonymousUser--;
  return o;
}

void checkAnonymousUser(api.AnonymousUser o) {
  buildCounterAnonymousUser++;
  if (buildCounterAnonymousUser < 3) {}
  buildCounterAnonymousUser--;
}

core.int buildCounterAnyone = 0;
api.Anyone buildAnyone() {
  var o = api.Anyone();
  buildCounterAnyone++;
  if (buildCounterAnyone < 3) {}
  buildCounterAnyone--;
  return o;
}

void checkAnyone(api.Anyone o) {
  buildCounterAnyone++;
  if (buildCounterAnyone < 3) {}
  buildCounterAnyone--;
}

core.int buildCounterApplicationReference = 0;
api.ApplicationReference buildApplicationReference() {
  var o = api.ApplicationReference();
  buildCounterApplicationReference++;
  if (buildCounterApplicationReference < 3) {
    o.type = 'foo';
  }
  buildCounterApplicationReference--;
  return o;
}

void checkApplicationReference(api.ApplicationReference o) {
  buildCounterApplicationReference++;
  if (buildCounterApplicationReference < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplicationReference--;
}

core.int buildCounterAssignment = 0;
api.Assignment buildAssignment() {
  var o = api.Assignment();
  buildCounterAssignment++;
  if (buildCounterAssignment < 3) {
    o.assignedUser = buildUser();
    o.subtype = 'foo';
  }
  buildCounterAssignment--;
  return o;
}

void checkAssignment(api.Assignment o) {
  buildCounterAssignment++;
  if (buildCounterAssignment < 3) {
    checkUser(o.assignedUser! as api.User);
    unittest.expect(
      o.subtype!,
      unittest.equals('foo'),
    );
  }
  buildCounterAssignment--;
}

core.List<api.User> buildUnnamed4791() {
  var o = <api.User>[];
  o.add(buildUser());
  o.add(buildUser());
  return o;
}

void checkUnnamed4791(core.List<api.User> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUser(o[0] as api.User);
  checkUser(o[1] as api.User);
}

core.int buildCounterComment = 0;
api.Comment buildComment() {
  var o = api.Comment();
  buildCounterComment++;
  if (buildCounterComment < 3) {
    o.assignment = buildAssignment();
    o.mentionedUsers = buildUnnamed4791();
    o.post = buildPost();
    o.suggestion = buildSuggestion();
  }
  buildCounterComment--;
  return o;
}

void checkComment(api.Comment o) {
  buildCounterComment++;
  if (buildCounterComment < 3) {
    checkAssignment(o.assignment! as api.Assignment);
    checkUnnamed4791(o.mentionedUsers!);
    checkPost(o.post! as api.Post);
    checkSuggestion(o.suggestion! as api.Suggestion);
  }
  buildCounterComment--;
}

core.int buildCounterConsolidationStrategy = 0;
api.ConsolidationStrategy buildConsolidationStrategy() {
  var o = api.ConsolidationStrategy();
  buildCounterConsolidationStrategy++;
  if (buildCounterConsolidationStrategy < 3) {
    o.legacy = buildLegacy();
    o.none = buildNoConsolidation();
  }
  buildCounterConsolidationStrategy--;
  return o;
}

void checkConsolidationStrategy(api.ConsolidationStrategy o) {
  buildCounterConsolidationStrategy++;
  if (buildCounterConsolidationStrategy < 3) {
    checkLegacy(o.legacy! as api.Legacy);
    checkNoConsolidation(o.none! as api.NoConsolidation);
  }
  buildCounterConsolidationStrategy--;
}

core.int buildCounterCopy = 0;
api.Copy buildCopy() {
  var o = api.Copy();
  buildCounterCopy++;
  if (buildCounterCopy < 3) {
    o.originalObject = buildTargetReference();
  }
  buildCounterCopy--;
  return o;
}

void checkCopy(api.Copy o) {
  buildCounterCopy++;
  if (buildCounterCopy < 3) {
    checkTargetReference(o.originalObject! as api.TargetReference);
  }
  buildCounterCopy--;
}

core.int buildCounterCreate = 0;
api.Create buildCreate() {
  var o = api.Create();
  buildCounterCreate++;
  if (buildCounterCreate < 3) {
    o.copy = buildCopy();
    o.new_ = buildNew();
    o.upload = buildUpload();
  }
  buildCounterCreate--;
  return o;
}

void checkCreate(api.Create o) {
  buildCounterCreate++;
  if (buildCounterCreate < 3) {
    checkCopy(o.copy! as api.Copy);
    checkNew(o.new_! as api.New);
    checkUpload(o.upload! as api.Upload);
  }
  buildCounterCreate--;
}

core.int buildCounterDataLeakPreventionChange = 0;
api.DataLeakPreventionChange buildDataLeakPreventionChange() {
  var o = api.DataLeakPreventionChange();
  buildCounterDataLeakPreventionChange++;
  if (buildCounterDataLeakPreventionChange < 3) {
    o.type = 'foo';
  }
  buildCounterDataLeakPreventionChange--;
  return o;
}

void checkDataLeakPreventionChange(api.DataLeakPreventionChange o) {
  buildCounterDataLeakPreventionChange++;
  if (buildCounterDataLeakPreventionChange < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataLeakPreventionChange--;
}

core.int buildCounterDelete = 0;
api.Delete buildDelete() {
  var o = api.Delete();
  buildCounterDelete++;
  if (buildCounterDelete < 3) {
    o.type = 'foo';
  }
  buildCounterDelete--;
  return o;
}

void checkDelete(api.Delete o) {
  buildCounterDelete++;
  if (buildCounterDelete < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDelete--;
}

core.int buildCounterDeletedUser = 0;
api.DeletedUser buildDeletedUser() {
  var o = api.DeletedUser();
  buildCounterDeletedUser++;
  if (buildCounterDeletedUser < 3) {}
  buildCounterDeletedUser--;
  return o;
}

void checkDeletedUser(api.DeletedUser o) {
  buildCounterDeletedUser++;
  if (buildCounterDeletedUser < 3) {}
  buildCounterDeletedUser--;
}

core.int buildCounterDomain = 0;
api.Domain buildDomain() {
  var o = api.Domain();
  buildCounterDomain++;
  if (buildCounterDomain < 3) {
    o.legacyId = 'foo';
    o.name = 'foo';
  }
  buildCounterDomain--;
  return o;
}

void checkDomain(api.Domain o) {
  buildCounterDomain++;
  if (buildCounterDomain < 3) {
    unittest.expect(
      o.legacyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterDomain--;
}

core.int buildCounterDrive = 0;
api.Drive buildDrive() {
  var o = api.Drive();
  buildCounterDrive++;
  if (buildCounterDrive < 3) {
    o.name = 'foo';
    o.root = buildDriveItem();
    o.title = 'foo';
  }
  buildCounterDrive--;
  return o;
}

void checkDrive(api.Drive o) {
  buildCounterDrive++;
  if (buildCounterDrive < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkDriveItem(o.root! as api.DriveItem);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterDrive--;
}

core.List<api.Action> buildUnnamed4792() {
  var o = <api.Action>[];
  o.add(buildAction());
  o.add(buildAction());
  return o;
}

void checkUnnamed4792(core.List<api.Action> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAction(o[0] as api.Action);
  checkAction(o[1] as api.Action);
}

core.List<api.Actor> buildUnnamed4793() {
  var o = <api.Actor>[];
  o.add(buildActor());
  o.add(buildActor());
  return o;
}

void checkUnnamed4793(core.List<api.Actor> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActor(o[0] as api.Actor);
  checkActor(o[1] as api.Actor);
}

core.List<api.Target> buildUnnamed4794() {
  var o = <api.Target>[];
  o.add(buildTarget());
  o.add(buildTarget());
  return o;
}

void checkUnnamed4794(core.List<api.Target> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTarget(o[0] as api.Target);
  checkTarget(o[1] as api.Target);
}

core.int buildCounterDriveActivity = 0;
api.DriveActivity buildDriveActivity() {
  var o = api.DriveActivity();
  buildCounterDriveActivity++;
  if (buildCounterDriveActivity < 3) {
    o.actions = buildUnnamed4792();
    o.actors = buildUnnamed4793();
    o.primaryActionDetail = buildActionDetail();
    o.targets = buildUnnamed4794();
    o.timeRange = buildTimeRange();
    o.timestamp = 'foo';
  }
  buildCounterDriveActivity--;
  return o;
}

void checkDriveActivity(api.DriveActivity o) {
  buildCounterDriveActivity++;
  if (buildCounterDriveActivity < 3) {
    checkUnnamed4792(o.actions!);
    checkUnnamed4793(o.actors!);
    checkActionDetail(o.primaryActionDetail! as api.ActionDetail);
    checkUnnamed4794(o.targets!);
    checkTimeRange(o.timeRange! as api.TimeRange);
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveActivity--;
}

core.int buildCounterDriveFile = 0;
api.DriveFile buildDriveFile() {
  var o = api.DriveFile();
  buildCounterDriveFile++;
  if (buildCounterDriveFile < 3) {}
  buildCounterDriveFile--;
  return o;
}

void checkDriveFile(api.DriveFile o) {
  buildCounterDriveFile++;
  if (buildCounterDriveFile < 3) {}
  buildCounterDriveFile--;
}

core.int buildCounterDriveFolder = 0;
api.DriveFolder buildDriveFolder() {
  var o = api.DriveFolder();
  buildCounterDriveFolder++;
  if (buildCounterDriveFolder < 3) {
    o.type = 'foo';
  }
  buildCounterDriveFolder--;
  return o;
}

void checkDriveFolder(api.DriveFolder o) {
  buildCounterDriveFolder++;
  if (buildCounterDriveFolder < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveFolder--;
}

core.int buildCounterDriveItem = 0;
api.DriveItem buildDriveItem() {
  var o = api.DriveItem();
  buildCounterDriveItem++;
  if (buildCounterDriveItem < 3) {
    o.driveFile = buildDriveFile();
    o.driveFolder = buildDriveFolder();
    o.file = buildFile();
    o.folder = buildFolder();
    o.mimeType = 'foo';
    o.name = 'foo';
    o.owner = buildOwner();
    o.title = 'foo';
  }
  buildCounterDriveItem--;
  return o;
}

void checkDriveItem(api.DriveItem o) {
  buildCounterDriveItem++;
  if (buildCounterDriveItem < 3) {
    checkDriveFile(o.driveFile! as api.DriveFile);
    checkDriveFolder(o.driveFolder! as api.DriveFolder);
    checkFile(o.file! as api.File);
    checkFolder(o.folder! as api.Folder);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOwner(o.owner! as api.Owner);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveItem--;
}

core.int buildCounterDriveItemReference = 0;
api.DriveItemReference buildDriveItemReference() {
  var o = api.DriveItemReference();
  buildCounterDriveItemReference++;
  if (buildCounterDriveItemReference < 3) {
    o.driveFile = buildDriveFile();
    o.driveFolder = buildDriveFolder();
    o.file = buildFile();
    o.folder = buildFolder();
    o.name = 'foo';
    o.title = 'foo';
  }
  buildCounterDriveItemReference--;
  return o;
}

void checkDriveItemReference(api.DriveItemReference o) {
  buildCounterDriveItemReference++;
  if (buildCounterDriveItemReference < 3) {
    checkDriveFile(o.driveFile! as api.DriveFile);
    checkDriveFolder(o.driveFolder! as api.DriveFolder);
    checkFile(o.file! as api.File);
    checkFolder(o.folder! as api.Folder);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveItemReference--;
}

core.int buildCounterDriveReference = 0;
api.DriveReference buildDriveReference() {
  var o = api.DriveReference();
  buildCounterDriveReference++;
  if (buildCounterDriveReference < 3) {
    o.name = 'foo';
    o.title = 'foo';
  }
  buildCounterDriveReference--;
  return o;
}

void checkDriveReference(api.DriveReference o) {
  buildCounterDriveReference++;
  if (buildCounterDriveReference < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveReference--;
}

core.int buildCounterEdit = 0;
api.Edit buildEdit() {
  var o = api.Edit();
  buildCounterEdit++;
  if (buildCounterEdit < 3) {}
  buildCounterEdit--;
  return o;
}

void checkEdit(api.Edit o) {
  buildCounterEdit++;
  if (buildCounterEdit < 3) {}
  buildCounterEdit--;
}

core.int buildCounterFile = 0;
api.File buildFile() {
  var o = api.File();
  buildCounterFile++;
  if (buildCounterFile < 3) {}
  buildCounterFile--;
  return o;
}

void checkFile(api.File o) {
  buildCounterFile++;
  if (buildCounterFile < 3) {}
  buildCounterFile--;
}

core.int buildCounterFileComment = 0;
api.FileComment buildFileComment() {
  var o = api.FileComment();
  buildCounterFileComment++;
  if (buildCounterFileComment < 3) {
    o.legacyCommentId = 'foo';
    o.legacyDiscussionId = 'foo';
    o.linkToDiscussion = 'foo';
    o.parent = buildDriveItem();
  }
  buildCounterFileComment--;
  return o;
}

void checkFileComment(api.FileComment o) {
  buildCounterFileComment++;
  if (buildCounterFileComment < 3) {
    unittest.expect(
      o.legacyCommentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.legacyDiscussionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.linkToDiscussion!,
      unittest.equals('foo'),
    );
    checkDriveItem(o.parent! as api.DriveItem);
  }
  buildCounterFileComment--;
}

core.int buildCounterFolder = 0;
api.Folder buildFolder() {
  var o = api.Folder();
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    o.type = 'foo';
  }
  buildCounterFolder--;
  return o;
}

void checkFolder(api.Folder o) {
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterFolder--;
}

core.int buildCounterGroup = 0;
api.Group buildGroup() {
  var o = api.Group();
  buildCounterGroup++;
  if (buildCounterGroup < 3) {
    o.email = 'foo';
    o.title = 'foo';
  }
  buildCounterGroup--;
  return o;
}

void checkGroup(api.Group o) {
  buildCounterGroup++;
  if (buildCounterGroup < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroup--;
}

core.int buildCounterImpersonation = 0;
api.Impersonation buildImpersonation() {
  var o = api.Impersonation();
  buildCounterImpersonation++;
  if (buildCounterImpersonation < 3) {
    o.impersonatedUser = buildUser();
  }
  buildCounterImpersonation--;
  return o;
}

void checkImpersonation(api.Impersonation o) {
  buildCounterImpersonation++;
  if (buildCounterImpersonation < 3) {
    checkUser(o.impersonatedUser! as api.User);
  }
  buildCounterImpersonation--;
}

core.int buildCounterKnownUser = 0;
api.KnownUser buildKnownUser() {
  var o = api.KnownUser();
  buildCounterKnownUser++;
  if (buildCounterKnownUser < 3) {
    o.isCurrentUser = true;
    o.personName = 'foo';
  }
  buildCounterKnownUser--;
  return o;
}

void checkKnownUser(api.KnownUser o) {
  buildCounterKnownUser++;
  if (buildCounterKnownUser < 3) {
    unittest.expect(o.isCurrentUser!, unittest.isTrue);
    unittest.expect(
      o.personName!,
      unittest.equals('foo'),
    );
  }
  buildCounterKnownUser--;
}

core.int buildCounterLegacy = 0;
api.Legacy buildLegacy() {
  var o = api.Legacy();
  buildCounterLegacy++;
  if (buildCounterLegacy < 3) {}
  buildCounterLegacy--;
  return o;
}

void checkLegacy(api.Legacy o) {
  buildCounterLegacy++;
  if (buildCounterLegacy < 3) {}
  buildCounterLegacy--;
}

core.List<api.TargetReference> buildUnnamed4795() {
  var o = <api.TargetReference>[];
  o.add(buildTargetReference());
  o.add(buildTargetReference());
  return o;
}

void checkUnnamed4795(core.List<api.TargetReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetReference(o[0] as api.TargetReference);
  checkTargetReference(o[1] as api.TargetReference);
}

core.List<api.TargetReference> buildUnnamed4796() {
  var o = <api.TargetReference>[];
  o.add(buildTargetReference());
  o.add(buildTargetReference());
  return o;
}

void checkUnnamed4796(core.List<api.TargetReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetReference(o[0] as api.TargetReference);
  checkTargetReference(o[1] as api.TargetReference);
}

core.int buildCounterMove = 0;
api.Move buildMove() {
  var o = api.Move();
  buildCounterMove++;
  if (buildCounterMove < 3) {
    o.addedParents = buildUnnamed4795();
    o.removedParents = buildUnnamed4796();
  }
  buildCounterMove--;
  return o;
}

void checkMove(api.Move o) {
  buildCounterMove++;
  if (buildCounterMove < 3) {
    checkUnnamed4795(o.addedParents!);
    checkUnnamed4796(o.removedParents!);
  }
  buildCounterMove--;
}

core.int buildCounterNew = 0;
api.New buildNew() {
  var o = api.New();
  buildCounterNew++;
  if (buildCounterNew < 3) {}
  buildCounterNew--;
  return o;
}

void checkNew(api.New o) {
  buildCounterNew++;
  if (buildCounterNew < 3) {}
  buildCounterNew--;
}

core.int buildCounterNoConsolidation = 0;
api.NoConsolidation buildNoConsolidation() {
  var o = api.NoConsolidation();
  buildCounterNoConsolidation++;
  if (buildCounterNoConsolidation < 3) {}
  buildCounterNoConsolidation--;
  return o;
}

void checkNoConsolidation(api.NoConsolidation o) {
  buildCounterNoConsolidation++;
  if (buildCounterNoConsolidation < 3) {}
  buildCounterNoConsolidation--;
}

core.int buildCounterOwner = 0;
api.Owner buildOwner() {
  var o = api.Owner();
  buildCounterOwner++;
  if (buildCounterOwner < 3) {
    o.domain = buildDomain();
    o.drive = buildDriveReference();
    o.teamDrive = buildTeamDriveReference();
    o.user = buildUser();
  }
  buildCounterOwner--;
  return o;
}

void checkOwner(api.Owner o) {
  buildCounterOwner++;
  if (buildCounterOwner < 3) {
    checkDomain(o.domain! as api.Domain);
    checkDriveReference(o.drive! as api.DriveReference);
    checkTeamDriveReference(o.teamDrive! as api.TeamDriveReference);
    checkUser(o.user! as api.User);
  }
  buildCounterOwner--;
}

core.int buildCounterPermission = 0;
api.Permission buildPermission() {
  var o = api.Permission();
  buildCounterPermission++;
  if (buildCounterPermission < 3) {
    o.allowDiscovery = true;
    o.anyone = buildAnyone();
    o.domain = buildDomain();
    o.group = buildGroup();
    o.role = 'foo';
    o.user = buildUser();
  }
  buildCounterPermission--;
  return o;
}

void checkPermission(api.Permission o) {
  buildCounterPermission++;
  if (buildCounterPermission < 3) {
    unittest.expect(o.allowDiscovery!, unittest.isTrue);
    checkAnyone(o.anyone! as api.Anyone);
    checkDomain(o.domain! as api.Domain);
    checkGroup(o.group! as api.Group);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
    checkUser(o.user! as api.User);
  }
  buildCounterPermission--;
}

core.List<api.Permission> buildUnnamed4797() {
  var o = <api.Permission>[];
  o.add(buildPermission());
  o.add(buildPermission());
  return o;
}

void checkUnnamed4797(core.List<api.Permission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPermission(o[0] as api.Permission);
  checkPermission(o[1] as api.Permission);
}

core.List<api.Permission> buildUnnamed4798() {
  var o = <api.Permission>[];
  o.add(buildPermission());
  o.add(buildPermission());
  return o;
}

void checkUnnamed4798(core.List<api.Permission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPermission(o[0] as api.Permission);
  checkPermission(o[1] as api.Permission);
}

core.int buildCounterPermissionChange = 0;
api.PermissionChange buildPermissionChange() {
  var o = api.PermissionChange();
  buildCounterPermissionChange++;
  if (buildCounterPermissionChange < 3) {
    o.addedPermissions = buildUnnamed4797();
    o.removedPermissions = buildUnnamed4798();
  }
  buildCounterPermissionChange--;
  return o;
}

void checkPermissionChange(api.PermissionChange o) {
  buildCounterPermissionChange++;
  if (buildCounterPermissionChange < 3) {
    checkUnnamed4797(o.addedPermissions!);
    checkUnnamed4798(o.removedPermissions!);
  }
  buildCounterPermissionChange--;
}

core.int buildCounterPost = 0;
api.Post buildPost() {
  var o = api.Post();
  buildCounterPost++;
  if (buildCounterPost < 3) {
    o.subtype = 'foo';
  }
  buildCounterPost--;
  return o;
}

void checkPost(api.Post o) {
  buildCounterPost++;
  if (buildCounterPost < 3) {
    unittest.expect(
      o.subtype!,
      unittest.equals('foo'),
    );
  }
  buildCounterPost--;
}

core.int buildCounterQueryDriveActivityRequest = 0;
api.QueryDriveActivityRequest buildQueryDriveActivityRequest() {
  var o = api.QueryDriveActivityRequest();
  buildCounterQueryDriveActivityRequest++;
  if (buildCounterQueryDriveActivityRequest < 3) {
    o.ancestorName = 'foo';
    o.consolidationStrategy = buildConsolidationStrategy();
    o.filter = 'foo';
    o.itemName = 'foo';
    o.pageSize = 42;
    o.pageToken = 'foo';
  }
  buildCounterQueryDriveActivityRequest--;
  return o;
}

void checkQueryDriveActivityRequest(api.QueryDriveActivityRequest o) {
  buildCounterQueryDriveActivityRequest++;
  if (buildCounterQueryDriveActivityRequest < 3) {
    unittest.expect(
      o.ancestorName!,
      unittest.equals('foo'),
    );
    checkConsolidationStrategy(
        o.consolidationStrategy! as api.ConsolidationStrategy);
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.itemName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryDriveActivityRequest--;
}

core.List<api.DriveActivity> buildUnnamed4799() {
  var o = <api.DriveActivity>[];
  o.add(buildDriveActivity());
  o.add(buildDriveActivity());
  return o;
}

void checkUnnamed4799(core.List<api.DriveActivity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDriveActivity(o[0] as api.DriveActivity);
  checkDriveActivity(o[1] as api.DriveActivity);
}

core.int buildCounterQueryDriveActivityResponse = 0;
api.QueryDriveActivityResponse buildQueryDriveActivityResponse() {
  var o = api.QueryDriveActivityResponse();
  buildCounterQueryDriveActivityResponse++;
  if (buildCounterQueryDriveActivityResponse < 3) {
    o.activities = buildUnnamed4799();
    o.nextPageToken = 'foo';
  }
  buildCounterQueryDriveActivityResponse--;
  return o;
}

void checkQueryDriveActivityResponse(api.QueryDriveActivityResponse o) {
  buildCounterQueryDriveActivityResponse++;
  if (buildCounterQueryDriveActivityResponse < 3) {
    checkUnnamed4799(o.activities!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryDriveActivityResponse--;
}

core.int buildCounterRename = 0;
api.Rename buildRename() {
  var o = api.Rename();
  buildCounterRename++;
  if (buildCounterRename < 3) {
    o.newTitle = 'foo';
    o.oldTitle = 'foo';
  }
  buildCounterRename--;
  return o;
}

void checkRename(api.Rename o) {
  buildCounterRename++;
  if (buildCounterRename < 3) {
    unittest.expect(
      o.newTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oldTitle!,
      unittest.equals('foo'),
    );
  }
  buildCounterRename--;
}

core.int buildCounterRestore = 0;
api.Restore buildRestore() {
  var o = api.Restore();
  buildCounterRestore++;
  if (buildCounterRestore < 3) {
    o.type = 'foo';
  }
  buildCounterRestore--;
  return o;
}

void checkRestore(api.Restore o) {
  buildCounterRestore++;
  if (buildCounterRestore < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterRestore--;
}

core.int buildCounterRestrictionChange = 0;
api.RestrictionChange buildRestrictionChange() {
  var o = api.RestrictionChange();
  buildCounterRestrictionChange++;
  if (buildCounterRestrictionChange < 3) {
    o.feature = 'foo';
    o.newRestriction = 'foo';
  }
  buildCounterRestrictionChange--;
  return o;
}

void checkRestrictionChange(api.RestrictionChange o) {
  buildCounterRestrictionChange++;
  if (buildCounterRestrictionChange < 3) {
    unittest.expect(
      o.feature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.newRestriction!,
      unittest.equals('foo'),
    );
  }
  buildCounterRestrictionChange--;
}

core.List<api.RestrictionChange> buildUnnamed4800() {
  var o = <api.RestrictionChange>[];
  o.add(buildRestrictionChange());
  o.add(buildRestrictionChange());
  return o;
}

void checkUnnamed4800(core.List<api.RestrictionChange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRestrictionChange(o[0] as api.RestrictionChange);
  checkRestrictionChange(o[1] as api.RestrictionChange);
}

core.int buildCounterSettingsChange = 0;
api.SettingsChange buildSettingsChange() {
  var o = api.SettingsChange();
  buildCounterSettingsChange++;
  if (buildCounterSettingsChange < 3) {
    o.restrictionChanges = buildUnnamed4800();
  }
  buildCounterSettingsChange--;
  return o;
}

void checkSettingsChange(api.SettingsChange o) {
  buildCounterSettingsChange++;
  if (buildCounterSettingsChange < 3) {
    checkUnnamed4800(o.restrictionChanges!);
  }
  buildCounterSettingsChange--;
}

core.int buildCounterSuggestion = 0;
api.Suggestion buildSuggestion() {
  var o = api.Suggestion();
  buildCounterSuggestion++;
  if (buildCounterSuggestion < 3) {
    o.subtype = 'foo';
  }
  buildCounterSuggestion--;
  return o;
}

void checkSuggestion(api.Suggestion o) {
  buildCounterSuggestion++;
  if (buildCounterSuggestion < 3) {
    unittest.expect(
      o.subtype!,
      unittest.equals('foo'),
    );
  }
  buildCounterSuggestion--;
}

core.int buildCounterSystemEvent = 0;
api.SystemEvent buildSystemEvent() {
  var o = api.SystemEvent();
  buildCounterSystemEvent++;
  if (buildCounterSystemEvent < 3) {
    o.type = 'foo';
  }
  buildCounterSystemEvent--;
  return o;
}

void checkSystemEvent(api.SystemEvent o) {
  buildCounterSystemEvent++;
  if (buildCounterSystemEvent < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSystemEvent--;
}

core.int buildCounterTarget = 0;
api.Target buildTarget() {
  var o = api.Target();
  buildCounterTarget++;
  if (buildCounterTarget < 3) {
    o.drive = buildDrive();
    o.driveItem = buildDriveItem();
    o.fileComment = buildFileComment();
    o.teamDrive = buildTeamDrive();
  }
  buildCounterTarget--;
  return o;
}

void checkTarget(api.Target o) {
  buildCounterTarget++;
  if (buildCounterTarget < 3) {
    checkDrive(o.drive! as api.Drive);
    checkDriveItem(o.driveItem! as api.DriveItem);
    checkFileComment(o.fileComment! as api.FileComment);
    checkTeamDrive(o.teamDrive! as api.TeamDrive);
  }
  buildCounterTarget--;
}

core.int buildCounterTargetReference = 0;
api.TargetReference buildTargetReference() {
  var o = api.TargetReference();
  buildCounterTargetReference++;
  if (buildCounterTargetReference < 3) {
    o.drive = buildDriveReference();
    o.driveItem = buildDriveItemReference();
    o.teamDrive = buildTeamDriveReference();
  }
  buildCounterTargetReference--;
  return o;
}

void checkTargetReference(api.TargetReference o) {
  buildCounterTargetReference++;
  if (buildCounterTargetReference < 3) {
    checkDriveReference(o.drive! as api.DriveReference);
    checkDriveItemReference(o.driveItem! as api.DriveItemReference);
    checkTeamDriveReference(o.teamDrive! as api.TeamDriveReference);
  }
  buildCounterTargetReference--;
}

core.int buildCounterTeamDrive = 0;
api.TeamDrive buildTeamDrive() {
  var o = api.TeamDrive();
  buildCounterTeamDrive++;
  if (buildCounterTeamDrive < 3) {
    o.name = 'foo';
    o.root = buildDriveItem();
    o.title = 'foo';
  }
  buildCounterTeamDrive--;
  return o;
}

void checkTeamDrive(api.TeamDrive o) {
  buildCounterTeamDrive++;
  if (buildCounterTeamDrive < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkDriveItem(o.root! as api.DriveItem);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterTeamDrive--;
}

core.int buildCounterTeamDriveReference = 0;
api.TeamDriveReference buildTeamDriveReference() {
  var o = api.TeamDriveReference();
  buildCounterTeamDriveReference++;
  if (buildCounterTeamDriveReference < 3) {
    o.name = 'foo';
    o.title = 'foo';
  }
  buildCounterTeamDriveReference--;
  return o;
}

void checkTeamDriveReference(api.TeamDriveReference o) {
  buildCounterTeamDriveReference++;
  if (buildCounterTeamDriveReference < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterTeamDriveReference--;
}

core.int buildCounterTimeRange = 0;
api.TimeRange buildTimeRange() {
  var o = api.TimeRange();
  buildCounterTimeRange++;
  if (buildCounterTimeRange < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterTimeRange--;
  return o;
}

void checkTimeRange(api.TimeRange o) {
  buildCounterTimeRange++;
  if (buildCounterTimeRange < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimeRange--;
}

core.int buildCounterUnknownUser = 0;
api.UnknownUser buildUnknownUser() {
  var o = api.UnknownUser();
  buildCounterUnknownUser++;
  if (buildCounterUnknownUser < 3) {}
  buildCounterUnknownUser--;
  return o;
}

void checkUnknownUser(api.UnknownUser o) {
  buildCounterUnknownUser++;
  if (buildCounterUnknownUser < 3) {}
  buildCounterUnknownUser--;
}

core.int buildCounterUpload = 0;
api.Upload buildUpload() {
  var o = api.Upload();
  buildCounterUpload++;
  if (buildCounterUpload < 3) {}
  buildCounterUpload--;
  return o;
}

void checkUpload(api.Upload o) {
  buildCounterUpload++;
  if (buildCounterUpload < 3) {}
  buildCounterUpload--;
}

core.int buildCounterUser = 0;
api.User buildUser() {
  var o = api.User();
  buildCounterUser++;
  if (buildCounterUser < 3) {
    o.deletedUser = buildDeletedUser();
    o.knownUser = buildKnownUser();
    o.unknownUser = buildUnknownUser();
  }
  buildCounterUser--;
  return o;
}

void checkUser(api.User o) {
  buildCounterUser++;
  if (buildCounterUser < 3) {
    checkDeletedUser(o.deletedUser! as api.DeletedUser);
    checkKnownUser(o.knownUser! as api.KnownUser);
    checkUnknownUser(o.unknownUser! as api.UnknownUser);
  }
  buildCounterUser--;
}

void main() {
  unittest.group('obj-schema-Action', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Action.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAction(od as api.Action);
    });
  });

  unittest.group('obj-schema-ActionDetail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActionDetail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActionDetail.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActionDetail(od as api.ActionDetail);
    });
  });

  unittest.group('obj-schema-Actor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Actor.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkActor(od as api.Actor);
    });
  });

  unittest.group('obj-schema-Administrator', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdministrator();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Administrator.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdministrator(od as api.Administrator);
    });
  });

  unittest.group('obj-schema-AnonymousUser', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnonymousUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnonymousUser.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnonymousUser(od as api.AnonymousUser);
    });
  });

  unittest.group('obj-schema-Anyone', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnyone();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Anyone.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAnyone(od as api.Anyone);
    });
  });

  unittest.group('obj-schema-ApplicationReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationReference(od as api.ApplicationReference);
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

  unittest.group('obj-schema-Comment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildComment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Comment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkComment(od as api.Comment);
    });
  });

  unittest.group('obj-schema-ConsolidationStrategy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConsolidationStrategy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConsolidationStrategy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConsolidationStrategy(od as api.ConsolidationStrategy);
    });
  });

  unittest.group('obj-schema-Copy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCopy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Copy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCopy(od as api.Copy);
    });
  });

  unittest.group('obj-schema-Create', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Create.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCreate(od as api.Create);
    });
  });

  unittest.group('obj-schema-DataLeakPreventionChange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataLeakPreventionChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataLeakPreventionChange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataLeakPreventionChange(od as api.DataLeakPreventionChange);
    });
  });

  unittest.group('obj-schema-Delete', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDelete();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Delete.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDelete(od as api.Delete);
    });
  });

  unittest.group('obj-schema-DeletedUser', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeletedUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeletedUser.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeletedUser(od as api.DeletedUser);
    });
  });

  unittest.group('obj-schema-Domain', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomain();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Domain.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDomain(od as api.Domain);
    });
  });

  unittest.group('obj-schema-Drive', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDrive();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Drive.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDrive(od as api.Drive);
    });
  });

  unittest.group('obj-schema-DriveActivity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveActivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveActivity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveActivity(od as api.DriveActivity);
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

  unittest.group('obj-schema-DriveItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DriveItem.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDriveItem(od as api.DriveItem);
    });
  });

  unittest.group('obj-schema-DriveItemReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveItemReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveItemReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveItemReference(od as api.DriveItemReference);
    });
  });

  unittest.group('obj-schema-DriveReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveReference(od as api.DriveReference);
    });
  });

  unittest.group('obj-schema-Edit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEdit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Edit.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEdit(od as api.Edit);
    });
  });

  unittest.group('obj-schema-File', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.File.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFile(od as api.File);
    });
  });

  unittest.group('obj-schema-FileComment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFileComment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FileComment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFileComment(od as api.FileComment);
    });
  });

  unittest.group('obj-schema-Folder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFolder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Folder.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFolder(od as api.Folder);
    });
  });

  unittest.group('obj-schema-Group', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Group.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGroup(od as api.Group);
    });
  });

  unittest.group('obj-schema-Impersonation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImpersonation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Impersonation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImpersonation(od as api.Impersonation);
    });
  });

  unittest.group('obj-schema-KnownUser', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKnownUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.KnownUser.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkKnownUser(od as api.KnownUser);
    });
  });

  unittest.group('obj-schema-Legacy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLegacy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Legacy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLegacy(od as api.Legacy);
    });
  });

  unittest.group('obj-schema-Move', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMove();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Move.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMove(od as api.Move);
    });
  });

  unittest.group('obj-schema-New', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNew();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.New.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkNew(od as api.New);
    });
  });

  unittest.group('obj-schema-NoConsolidation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNoConsolidation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NoConsolidation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNoConsolidation(od as api.NoConsolidation);
    });
  });

  unittest.group('obj-schema-Owner', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOwner();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Owner.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOwner(od as api.Owner);
    });
  });

  unittest.group('obj-schema-Permission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPermission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Permission.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPermission(od as api.Permission);
    });
  });

  unittest.group('obj-schema-PermissionChange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPermissionChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PermissionChange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPermissionChange(od as api.PermissionChange);
    });
  });

  unittest.group('obj-schema-Post', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPost();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Post.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPost(od as api.Post);
    });
  });

  unittest.group('obj-schema-QueryDriveActivityRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryDriveActivityRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryDriveActivityRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryDriveActivityRequest(od as api.QueryDriveActivityRequest);
    });
  });

  unittest.group('obj-schema-QueryDriveActivityResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryDriveActivityResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryDriveActivityResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryDriveActivityResponse(od as api.QueryDriveActivityResponse);
    });
  });

  unittest.group('obj-schema-Rename', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRename();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Rename.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRename(od as api.Rename);
    });
  });

  unittest.group('obj-schema-Restore', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestore();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Restore.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRestore(od as api.Restore);
    });
  });

  unittest.group('obj-schema-RestrictionChange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestrictionChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestrictionChange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestrictionChange(od as api.RestrictionChange);
    });
  });

  unittest.group('obj-schema-SettingsChange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSettingsChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SettingsChange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSettingsChange(od as api.SettingsChange);
    });
  });

  unittest.group('obj-schema-Suggestion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuggestion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Suggestion.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSuggestion(od as api.Suggestion);
    });
  });

  unittest.group('obj-schema-SystemEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSystemEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SystemEvent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSystemEvent(od as api.SystemEvent);
    });
  });

  unittest.group('obj-schema-Target', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Target.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTarget(od as api.Target);
    });
  });

  unittest.group('obj-schema-TargetReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetReference(od as api.TargetReference);
    });
  });

  unittest.group('obj-schema-TeamDrive', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTeamDrive();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TeamDrive.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTeamDrive(od as api.TeamDrive);
    });
  });

  unittest.group('obj-schema-TeamDriveReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTeamDriveReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TeamDriveReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTeamDriveReference(od as api.TeamDriveReference);
    });
  });

  unittest.group('obj-schema-TimeRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeRange(od as api.TimeRange);
    });
  });

  unittest.group('obj-schema-UnknownUser', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnknownUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnknownUser.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnknownUser(od as api.UnknownUser);
    });
  });

  unittest.group('obj-schema-Upload', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpload();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Upload.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUpload(od as api.Upload);
    });
  });

  unittest.group('obj-schema-User', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.User.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUser(od as api.User);
    });
  });

  unittest.group('resource-ActivityResource', () {
    unittest.test('method--query', () async {
      var mock = HttpServerMock();
      var res = api.DriveActivityApi(mock).activity;
      var arg_request = buildQueryDriveActivityRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.QueryDriveActivityRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkQueryDriveActivityRequest(obj as api.QueryDriveActivityRequest);

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
          unittest.equals("v2/activity:query"),
        );
        pathOffset += 17;

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
        var resp = convert.json.encode(buildQueryDriveActivityResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.query(arg_request, $fields: arg_$fields);
      checkQueryDriveActivityResponse(
          response as api.QueryDriveActivityResponse);
    });
  });
}
