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

import 'package:googleapis/chat/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterActionParameter = 0;
api.ActionParameter buildActionParameter() {
  var o = api.ActionParameter();
  buildCounterActionParameter++;
  if (buildCounterActionParameter < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterActionParameter--;
  return o;
}

void checkActionParameter(api.ActionParameter o) {
  buildCounterActionParameter++;
  if (buildCounterActionParameter < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterActionParameter--;
}

core.int buildCounterActionResponse = 0;
api.ActionResponse buildActionResponse() {
  var o = api.ActionResponse();
  buildCounterActionResponse++;
  if (buildCounterActionResponse < 3) {
    o.type = 'foo';
    o.url = 'foo';
  }
  buildCounterActionResponse--;
  return o;
}

void checkActionResponse(api.ActionResponse o) {
  buildCounterActionResponse++;
  if (buildCounterActionResponse < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterActionResponse--;
}

core.int buildCounterAnnotation = 0;
api.Annotation buildAnnotation() {
  var o = api.Annotation();
  buildCounterAnnotation++;
  if (buildCounterAnnotation < 3) {
    o.length = 42;
    o.slashCommand = buildSlashCommandMetadata();
    o.startIndex = 42;
    o.type = 'foo';
    o.userMention = buildUserMentionMetadata();
  }
  buildCounterAnnotation--;
  return o;
}

void checkAnnotation(api.Annotation o) {
  buildCounterAnnotation++;
  if (buildCounterAnnotation < 3) {
    unittest.expect(
      o.length!,
      unittest.equals(42),
    );
    checkSlashCommandMetadata(o.slashCommand! as api.SlashCommandMetadata);
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkUserMentionMetadata(o.userMention! as api.UserMentionMetadata);
  }
  buildCounterAnnotation--;
}

core.int buildCounterAttachment = 0;
api.Attachment buildAttachment() {
  var o = api.Attachment();
  buildCounterAttachment++;
  if (buildCounterAttachment < 3) {
    o.attachmentDataRef = buildAttachmentDataRef();
    o.contentName = 'foo';
    o.contentType = 'foo';
    o.downloadUri = 'foo';
    o.driveDataRef = buildDriveDataRef();
    o.name = 'foo';
    o.source = 'foo';
    o.thumbnailUri = 'foo';
  }
  buildCounterAttachment--;
  return o;
}

void checkAttachment(api.Attachment o) {
  buildCounterAttachment++;
  if (buildCounterAttachment < 3) {
    checkAttachmentDataRef(o.attachmentDataRef! as api.AttachmentDataRef);
    unittest.expect(
      o.contentName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.downloadUri!,
      unittest.equals('foo'),
    );
    checkDriveDataRef(o.driveDataRef! as api.DriveDataRef);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.source!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterAttachment--;
}

core.int buildCounterAttachmentDataRef = 0;
api.AttachmentDataRef buildAttachmentDataRef() {
  var o = api.AttachmentDataRef();
  buildCounterAttachmentDataRef++;
  if (buildCounterAttachmentDataRef < 3) {
    o.resourceName = 'foo';
  }
  buildCounterAttachmentDataRef--;
  return o;
}

void checkAttachmentDataRef(api.AttachmentDataRef o) {
  buildCounterAttachmentDataRef++;
  if (buildCounterAttachmentDataRef < 3) {
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterAttachmentDataRef--;
}

core.int buildCounterButton = 0;
api.Button buildButton() {
  var o = api.Button();
  buildCounterButton++;
  if (buildCounterButton < 3) {
    o.imageButton = buildImageButton();
    o.textButton = buildTextButton();
  }
  buildCounterButton--;
  return o;
}

void checkButton(api.Button o) {
  buildCounterButton++;
  if (buildCounterButton < 3) {
    checkImageButton(o.imageButton! as api.ImageButton);
    checkTextButton(o.textButton! as api.TextButton);
  }
  buildCounterButton--;
}

core.List<api.CardAction> buildUnnamed3725() {
  var o = <api.CardAction>[];
  o.add(buildCardAction());
  o.add(buildCardAction());
  return o;
}

void checkUnnamed3725(core.List<api.CardAction> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCardAction(o[0] as api.CardAction);
  checkCardAction(o[1] as api.CardAction);
}

core.List<api.Section> buildUnnamed3726() {
  var o = <api.Section>[];
  o.add(buildSection());
  o.add(buildSection());
  return o;
}

void checkUnnamed3726(core.List<api.Section> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSection(o[0] as api.Section);
  checkSection(o[1] as api.Section);
}

core.int buildCounterCard = 0;
api.Card buildCard() {
  var o = api.Card();
  buildCounterCard++;
  if (buildCounterCard < 3) {
    o.cardActions = buildUnnamed3725();
    o.header = buildCardHeader();
    o.name = 'foo';
    o.sections = buildUnnamed3726();
  }
  buildCounterCard--;
  return o;
}

void checkCard(api.Card o) {
  buildCounterCard++;
  if (buildCounterCard < 3) {
    checkUnnamed3725(o.cardActions!);
    checkCardHeader(o.header! as api.CardHeader);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3726(o.sections!);
  }
  buildCounterCard--;
}

core.int buildCounterCardAction = 0;
api.CardAction buildCardAction() {
  var o = api.CardAction();
  buildCounterCardAction++;
  if (buildCounterCardAction < 3) {
    o.actionLabel = 'foo';
    o.onClick = buildOnClick();
  }
  buildCounterCardAction--;
  return o;
}

void checkCardAction(api.CardAction o) {
  buildCounterCardAction++;
  if (buildCounterCardAction < 3) {
    unittest.expect(
      o.actionLabel!,
      unittest.equals('foo'),
    );
    checkOnClick(o.onClick! as api.OnClick);
  }
  buildCounterCardAction--;
}

core.int buildCounterCardHeader = 0;
api.CardHeader buildCardHeader() {
  var o = api.CardHeader();
  buildCounterCardHeader++;
  if (buildCounterCardHeader < 3) {
    o.imageStyle = 'foo';
    o.imageUrl = 'foo';
    o.subtitle = 'foo';
    o.title = 'foo';
  }
  buildCounterCardHeader--;
  return o;
}

void checkCardHeader(api.CardHeader o) {
  buildCounterCardHeader++;
  if (buildCounterCardHeader < 3) {
    unittest.expect(
      o.imageStyle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.imageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subtitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterCardHeader--;
}

core.int buildCounterDeprecatedEvent = 0;
api.DeprecatedEvent buildDeprecatedEvent() {
  var o = api.DeprecatedEvent();
  buildCounterDeprecatedEvent++;
  if (buildCounterDeprecatedEvent < 3) {
    o.action = buildFormAction();
    o.configCompleteRedirectUrl = 'foo';
    o.eventTime = 'foo';
    o.message = buildMessage();
    o.space = buildSpace();
    o.threadKey = 'foo';
    o.token = 'foo';
    o.type = 'foo';
    o.user = buildUser();
  }
  buildCounterDeprecatedEvent--;
  return o;
}

void checkDeprecatedEvent(api.DeprecatedEvent o) {
  buildCounterDeprecatedEvent++;
  if (buildCounterDeprecatedEvent < 3) {
    checkFormAction(o.action! as api.FormAction);
    unittest.expect(
      o.configCompleteRedirectUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventTime!,
      unittest.equals('foo'),
    );
    checkMessage(o.message! as api.Message);
    checkSpace(o.space! as api.Space);
    unittest.expect(
      o.threadKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkUser(o.user! as api.User);
  }
  buildCounterDeprecatedEvent--;
}

core.int buildCounterDriveDataRef = 0;
api.DriveDataRef buildDriveDataRef() {
  var o = api.DriveDataRef();
  buildCounterDriveDataRef++;
  if (buildCounterDriveDataRef < 3) {
    o.driveFileId = 'foo';
  }
  buildCounterDriveDataRef--;
  return o;
}

void checkDriveDataRef(api.DriveDataRef o) {
  buildCounterDriveDataRef++;
  if (buildCounterDriveDataRef < 3) {
    unittest.expect(
      o.driveFileId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveDataRef--;
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

core.List<api.ActionParameter> buildUnnamed3727() {
  var o = <api.ActionParameter>[];
  o.add(buildActionParameter());
  o.add(buildActionParameter());
  return o;
}

void checkUnnamed3727(core.List<api.ActionParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActionParameter(o[0] as api.ActionParameter);
  checkActionParameter(o[1] as api.ActionParameter);
}

core.int buildCounterFormAction = 0;
api.FormAction buildFormAction() {
  var o = api.FormAction();
  buildCounterFormAction++;
  if (buildCounterFormAction < 3) {
    o.actionMethodName = 'foo';
    o.parameters = buildUnnamed3727();
  }
  buildCounterFormAction--;
  return o;
}

void checkFormAction(api.FormAction o) {
  buildCounterFormAction++;
  if (buildCounterFormAction < 3) {
    unittest.expect(
      o.actionMethodName!,
      unittest.equals('foo'),
    );
    checkUnnamed3727(o.parameters!);
  }
  buildCounterFormAction--;
}

core.int buildCounterImage = 0;
api.Image buildImage() {
  var o = api.Image();
  buildCounterImage++;
  if (buildCounterImage < 3) {
    o.aspectRatio = 42.0;
    o.imageUrl = 'foo';
    o.onClick = buildOnClick();
  }
  buildCounterImage--;
  return o;
}

void checkImage(api.Image o) {
  buildCounterImage++;
  if (buildCounterImage < 3) {
    unittest.expect(
      o.aspectRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.imageUrl!,
      unittest.equals('foo'),
    );
    checkOnClick(o.onClick! as api.OnClick);
  }
  buildCounterImage--;
}

core.int buildCounterImageButton = 0;
api.ImageButton buildImageButton() {
  var o = api.ImageButton();
  buildCounterImageButton++;
  if (buildCounterImageButton < 3) {
    o.icon = 'foo';
    o.iconUrl = 'foo';
    o.name = 'foo';
    o.onClick = buildOnClick();
  }
  buildCounterImageButton--;
  return o;
}

void checkImageButton(api.ImageButton o) {
  buildCounterImageButton++;
  if (buildCounterImageButton < 3) {
    unittest.expect(
      o.icon!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iconUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOnClick(o.onClick! as api.OnClick);
  }
  buildCounterImageButton--;
}

core.int buildCounterKeyValue = 0;
api.KeyValue buildKeyValue() {
  var o = api.KeyValue();
  buildCounterKeyValue++;
  if (buildCounterKeyValue < 3) {
    o.bottomLabel = 'foo';
    o.button = buildButton();
    o.content = 'foo';
    o.contentMultiline = true;
    o.icon = 'foo';
    o.iconUrl = 'foo';
    o.onClick = buildOnClick();
    o.topLabel = 'foo';
  }
  buildCounterKeyValue--;
  return o;
}

void checkKeyValue(api.KeyValue o) {
  buildCounterKeyValue++;
  if (buildCounterKeyValue < 3) {
    unittest.expect(
      o.bottomLabel!,
      unittest.equals('foo'),
    );
    checkButton(o.button! as api.Button);
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    unittest.expect(o.contentMultiline!, unittest.isTrue);
    unittest.expect(
      o.icon!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iconUrl!,
      unittest.equals('foo'),
    );
    checkOnClick(o.onClick! as api.OnClick);
    unittest.expect(
      o.topLabel!,
      unittest.equals('foo'),
    );
  }
  buildCounterKeyValue--;
}

core.List<api.Membership> buildUnnamed3728() {
  var o = <api.Membership>[];
  o.add(buildMembership());
  o.add(buildMembership());
  return o;
}

void checkUnnamed3728(core.List<api.Membership> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMembership(o[0] as api.Membership);
  checkMembership(o[1] as api.Membership);
}

core.int buildCounterListMembershipsResponse = 0;
api.ListMembershipsResponse buildListMembershipsResponse() {
  var o = api.ListMembershipsResponse();
  buildCounterListMembershipsResponse++;
  if (buildCounterListMembershipsResponse < 3) {
    o.memberships = buildUnnamed3728();
    o.nextPageToken = 'foo';
  }
  buildCounterListMembershipsResponse--;
  return o;
}

void checkListMembershipsResponse(api.ListMembershipsResponse o) {
  buildCounterListMembershipsResponse++;
  if (buildCounterListMembershipsResponse < 3) {
    checkUnnamed3728(o.memberships!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListMembershipsResponse--;
}

core.List<api.Space> buildUnnamed3729() {
  var o = <api.Space>[];
  o.add(buildSpace());
  o.add(buildSpace());
  return o;
}

void checkUnnamed3729(core.List<api.Space> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSpace(o[0] as api.Space);
  checkSpace(o[1] as api.Space);
}

core.int buildCounterListSpacesResponse = 0;
api.ListSpacesResponse buildListSpacesResponse() {
  var o = api.ListSpacesResponse();
  buildCounterListSpacesResponse++;
  if (buildCounterListSpacesResponse < 3) {
    o.nextPageToken = 'foo';
    o.spaces = buildUnnamed3729();
  }
  buildCounterListSpacesResponse--;
  return o;
}

void checkListSpacesResponse(api.ListSpacesResponse o) {
  buildCounterListSpacesResponse++;
  if (buildCounterListSpacesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3729(o.spaces!);
  }
  buildCounterListSpacesResponse--;
}

core.int buildCounterMedia = 0;
api.Media buildMedia() {
  var o = api.Media();
  buildCounterMedia++;
  if (buildCounterMedia < 3) {
    o.resourceName = 'foo';
  }
  buildCounterMedia--;
  return o;
}

void checkMedia(api.Media o) {
  buildCounterMedia++;
  if (buildCounterMedia < 3) {
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterMedia--;
}

core.int buildCounterMembership = 0;
api.Membership buildMembership() {
  var o = api.Membership();
  buildCounterMembership++;
  if (buildCounterMembership < 3) {
    o.createTime = 'foo';
    o.member = buildUser();
    o.name = 'foo';
    o.state = 'foo';
  }
  buildCounterMembership--;
  return o;
}

void checkMembership(api.Membership o) {
  buildCounterMembership++;
  if (buildCounterMembership < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkUser(o.member! as api.User);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterMembership--;
}

core.List<api.Annotation> buildUnnamed3730() {
  var o = <api.Annotation>[];
  o.add(buildAnnotation());
  o.add(buildAnnotation());
  return o;
}

void checkUnnamed3730(core.List<api.Annotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAnnotation(o[0] as api.Annotation);
  checkAnnotation(o[1] as api.Annotation);
}

core.List<api.Attachment> buildUnnamed3731() {
  var o = <api.Attachment>[];
  o.add(buildAttachment());
  o.add(buildAttachment());
  return o;
}

void checkUnnamed3731(core.List<api.Attachment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttachment(o[0] as api.Attachment);
  checkAttachment(o[1] as api.Attachment);
}

core.List<api.Card> buildUnnamed3732() {
  var o = <api.Card>[];
  o.add(buildCard());
  o.add(buildCard());
  return o;
}

void checkUnnamed3732(core.List<api.Card> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCard(o[0] as api.Card);
  checkCard(o[1] as api.Card);
}

core.int buildCounterMessage = 0;
api.Message buildMessage() {
  var o = api.Message();
  buildCounterMessage++;
  if (buildCounterMessage < 3) {
    o.actionResponse = buildActionResponse();
    o.annotations = buildUnnamed3730();
    o.argumentText = 'foo';
    o.attachment = buildUnnamed3731();
    o.cards = buildUnnamed3732();
    o.createTime = 'foo';
    o.fallbackText = 'foo';
    o.name = 'foo';
    o.previewText = 'foo';
    o.sender = buildUser();
    o.slashCommand = buildSlashCommand();
    o.space = buildSpace();
    o.text = 'foo';
    o.thread = buildThread();
  }
  buildCounterMessage--;
  return o;
}

void checkMessage(api.Message o) {
  buildCounterMessage++;
  if (buildCounterMessage < 3) {
    checkActionResponse(o.actionResponse! as api.ActionResponse);
    checkUnnamed3730(o.annotations!);
    unittest.expect(
      o.argumentText!,
      unittest.equals('foo'),
    );
    checkUnnamed3731(o.attachment!);
    checkUnnamed3732(o.cards!);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fallbackText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previewText!,
      unittest.equals('foo'),
    );
    checkUser(o.sender! as api.User);
    checkSlashCommand(o.slashCommand! as api.SlashCommand);
    checkSpace(o.space! as api.Space);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    checkThread(o.thread! as api.Thread);
  }
  buildCounterMessage--;
}

core.int buildCounterOnClick = 0;
api.OnClick buildOnClick() {
  var o = api.OnClick();
  buildCounterOnClick++;
  if (buildCounterOnClick < 3) {
    o.action = buildFormAction();
    o.openLink = buildOpenLink();
  }
  buildCounterOnClick--;
  return o;
}

void checkOnClick(api.OnClick o) {
  buildCounterOnClick++;
  if (buildCounterOnClick < 3) {
    checkFormAction(o.action! as api.FormAction);
    checkOpenLink(o.openLink! as api.OpenLink);
  }
  buildCounterOnClick--;
}

core.int buildCounterOpenLink = 0;
api.OpenLink buildOpenLink() {
  var o = api.OpenLink();
  buildCounterOpenLink++;
  if (buildCounterOpenLink < 3) {
    o.url = 'foo';
  }
  buildCounterOpenLink--;
  return o;
}

void checkOpenLink(api.OpenLink o) {
  buildCounterOpenLink++;
  if (buildCounterOpenLink < 3) {
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterOpenLink--;
}

core.List<api.WidgetMarkup> buildUnnamed3733() {
  var o = <api.WidgetMarkup>[];
  o.add(buildWidgetMarkup());
  o.add(buildWidgetMarkup());
  return o;
}

void checkUnnamed3733(core.List<api.WidgetMarkup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWidgetMarkup(o[0] as api.WidgetMarkup);
  checkWidgetMarkup(o[1] as api.WidgetMarkup);
}

core.int buildCounterSection = 0;
api.Section buildSection() {
  var o = api.Section();
  buildCounterSection++;
  if (buildCounterSection < 3) {
    o.header = 'foo';
    o.widgets = buildUnnamed3733();
  }
  buildCounterSection--;
  return o;
}

void checkSection(api.Section o) {
  buildCounterSection++;
  if (buildCounterSection < 3) {
    unittest.expect(
      o.header!,
      unittest.equals('foo'),
    );
    checkUnnamed3733(o.widgets!);
  }
  buildCounterSection--;
}

core.int buildCounterSlashCommand = 0;
api.SlashCommand buildSlashCommand() {
  var o = api.SlashCommand();
  buildCounterSlashCommand++;
  if (buildCounterSlashCommand < 3) {
    o.commandId = 'foo';
  }
  buildCounterSlashCommand--;
  return o;
}

void checkSlashCommand(api.SlashCommand o) {
  buildCounterSlashCommand++;
  if (buildCounterSlashCommand < 3) {
    unittest.expect(
      o.commandId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSlashCommand--;
}

core.int buildCounterSlashCommandMetadata = 0;
api.SlashCommandMetadata buildSlashCommandMetadata() {
  var o = api.SlashCommandMetadata();
  buildCounterSlashCommandMetadata++;
  if (buildCounterSlashCommandMetadata < 3) {
    o.bot = buildUser();
    o.commandId = 'foo';
    o.commandName = 'foo';
    o.triggersDialog = true;
    o.type = 'foo';
  }
  buildCounterSlashCommandMetadata--;
  return o;
}

void checkSlashCommandMetadata(api.SlashCommandMetadata o) {
  buildCounterSlashCommandMetadata++;
  if (buildCounterSlashCommandMetadata < 3) {
    checkUser(o.bot! as api.User);
    unittest.expect(
      o.commandId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.commandName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.triggersDialog!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSlashCommandMetadata--;
}

core.int buildCounterSpace = 0;
api.Space buildSpace() {
  var o = api.Space();
  buildCounterSpace++;
  if (buildCounterSpace < 3) {
    o.displayName = 'foo';
    o.name = 'foo';
    o.singleUserBotDm = true;
    o.threaded = true;
    o.type = 'foo';
  }
  buildCounterSpace--;
  return o;
}

void checkSpace(api.Space o) {
  buildCounterSpace++;
  if (buildCounterSpace < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.singleUserBotDm!, unittest.isTrue);
    unittest.expect(o.threaded!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSpace--;
}

core.int buildCounterTextButton = 0;
api.TextButton buildTextButton() {
  var o = api.TextButton();
  buildCounterTextButton++;
  if (buildCounterTextButton < 3) {
    o.onClick = buildOnClick();
    o.text = 'foo';
  }
  buildCounterTextButton--;
  return o;
}

void checkTextButton(api.TextButton o) {
  buildCounterTextButton++;
  if (buildCounterTextButton < 3) {
    checkOnClick(o.onClick! as api.OnClick);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterTextButton--;
}

core.int buildCounterTextParagraph = 0;
api.TextParagraph buildTextParagraph() {
  var o = api.TextParagraph();
  buildCounterTextParagraph++;
  if (buildCounterTextParagraph < 3) {
    o.text = 'foo';
  }
  buildCounterTextParagraph--;
  return o;
}

void checkTextParagraph(api.TextParagraph o) {
  buildCounterTextParagraph++;
  if (buildCounterTextParagraph < 3) {
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterTextParagraph--;
}

core.int buildCounterThread = 0;
api.Thread buildThread() {
  var o = api.Thread();
  buildCounterThread++;
  if (buildCounterThread < 3) {
    o.name = 'foo';
  }
  buildCounterThread--;
  return o;
}

void checkThread(api.Thread o) {
  buildCounterThread++;
  if (buildCounterThread < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterThread--;
}

core.int buildCounterUser = 0;
api.User buildUser() {
  var o = api.User();
  buildCounterUser++;
  if (buildCounterUser < 3) {
    o.displayName = 'foo';
    o.domainId = 'foo';
    o.isAnonymous = true;
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterUser--;
  return o;
}

void checkUser(api.User o) {
  buildCounterUser++;
  if (buildCounterUser < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.domainId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isAnonymous!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterUser--;
}

core.int buildCounterUserMentionMetadata = 0;
api.UserMentionMetadata buildUserMentionMetadata() {
  var o = api.UserMentionMetadata();
  buildCounterUserMentionMetadata++;
  if (buildCounterUserMentionMetadata < 3) {
    o.type = 'foo';
    o.user = buildUser();
  }
  buildCounterUserMentionMetadata--;
  return o;
}

void checkUserMentionMetadata(api.UserMentionMetadata o) {
  buildCounterUserMentionMetadata++;
  if (buildCounterUserMentionMetadata < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkUser(o.user! as api.User);
  }
  buildCounterUserMentionMetadata--;
}

core.List<api.Button> buildUnnamed3734() {
  var o = <api.Button>[];
  o.add(buildButton());
  o.add(buildButton());
  return o;
}

void checkUnnamed3734(core.List<api.Button> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkButton(o[0] as api.Button);
  checkButton(o[1] as api.Button);
}

core.int buildCounterWidgetMarkup = 0;
api.WidgetMarkup buildWidgetMarkup() {
  var o = api.WidgetMarkup();
  buildCounterWidgetMarkup++;
  if (buildCounterWidgetMarkup < 3) {
    o.buttons = buildUnnamed3734();
    o.image = buildImage();
    o.keyValue = buildKeyValue();
    o.textParagraph = buildTextParagraph();
  }
  buildCounterWidgetMarkup--;
  return o;
}

void checkWidgetMarkup(api.WidgetMarkup o) {
  buildCounterWidgetMarkup++;
  if (buildCounterWidgetMarkup < 3) {
    checkUnnamed3734(o.buttons!);
    checkImage(o.image! as api.Image);
    checkKeyValue(o.keyValue! as api.KeyValue);
    checkTextParagraph(o.textParagraph! as api.TextParagraph);
  }
  buildCounterWidgetMarkup--;
}

void main() {
  unittest.group('obj-schema-ActionParameter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActionParameter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActionParameter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActionParameter(od as api.ActionParameter);
    });
  });

  unittest.group('obj-schema-ActionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActionResponse(od as api.ActionResponse);
    });
  });

  unittest.group('obj-schema-Annotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Annotation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAnnotation(od as api.Annotation);
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

  unittest.group('obj-schema-AttachmentDataRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttachmentDataRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AttachmentDataRef.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAttachmentDataRef(od as api.AttachmentDataRef);
    });
  });

  unittest.group('obj-schema-Button', () {
    unittest.test('to-json--from-json', () async {
      var o = buildButton();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Button.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkButton(od as api.Button);
    });
  });

  unittest.group('obj-schema-Card', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCard();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Card.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCard(od as api.Card);
    });
  });

  unittest.group('obj-schema-CardAction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCardAction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CardAction.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCardAction(od as api.CardAction);
    });
  });

  unittest.group('obj-schema-CardHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCardHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CardHeader.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCardHeader(od as api.CardHeader);
    });
  });

  unittest.group('obj-schema-DeprecatedEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeprecatedEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeprecatedEvent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeprecatedEvent(od as api.DeprecatedEvent);
    });
  });

  unittest.group('obj-schema-DriveDataRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveDataRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveDataRef.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveDataRef(od as api.DriveDataRef);
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

  unittest.group('obj-schema-FormAction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFormAction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FormAction.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFormAction(od as api.FormAction);
    });
  });

  unittest.group('obj-schema-Image', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Image.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImage(od as api.Image);
    });
  });

  unittest.group('obj-schema-ImageButton', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageButton();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImageButton.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImageButton(od as api.ImageButton);
    });
  });

  unittest.group('obj-schema-KeyValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKeyValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.KeyValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkKeyValue(od as api.KeyValue);
    });
  });

  unittest.group('obj-schema-ListMembershipsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListMembershipsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListMembershipsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListMembershipsResponse(od as api.ListMembershipsResponse);
    });
  });

  unittest.group('obj-schema-ListSpacesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSpacesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSpacesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSpacesResponse(od as api.ListSpacesResponse);
    });
  });

  unittest.group('obj-schema-Media', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMedia();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Media.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMedia(od as api.Media);
    });
  });

  unittest.group('obj-schema-Membership', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembership();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Membership.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMembership(od as api.Membership);
    });
  });

  unittest.group('obj-schema-Message', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Message.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMessage(od as api.Message);
    });
  });

  unittest.group('obj-schema-OnClick', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOnClick();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OnClick.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOnClick(od as api.OnClick);
    });
  });

  unittest.group('obj-schema-OpenLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOpenLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OpenLink.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOpenLink(od as api.OpenLink);
    });
  });

  unittest.group('obj-schema-Section', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Section.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSection(od as api.Section);
    });
  });

  unittest.group('obj-schema-SlashCommand', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSlashCommand();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SlashCommand.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSlashCommand(od as api.SlashCommand);
    });
  });

  unittest.group('obj-schema-SlashCommandMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSlashCommandMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SlashCommandMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSlashCommandMetadata(od as api.SlashCommandMetadata);
    });
  });

  unittest.group('obj-schema-Space', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Space.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSpace(od as api.Space);
    });
  });

  unittest.group('obj-schema-TextButton', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextButton();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TextButton.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTextButton(od as api.TextButton);
    });
  });

  unittest.group('obj-schema-TextParagraph', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextParagraph();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextParagraph.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextParagraph(od as api.TextParagraph);
    });
  });

  unittest.group('obj-schema-Thread', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThread();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Thread.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkThread(od as api.Thread);
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

  unittest.group('obj-schema-UserMentionMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserMentionMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserMentionMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserMentionMetadata(od as api.UserMentionMetadata);
    });
  });

  unittest.group('obj-schema-WidgetMarkup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWidgetMarkup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WidgetMarkup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWidgetMarkup(od as api.WidgetMarkup);
    });
  });

  unittest.group('resource-DmsResource', () {
    unittest.test('method--messages', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).dms;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.messages(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--webhooks', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).dms;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.webhooks(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-DmsConversationsResource', () {
    unittest.test('method--messages', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).dms.conversations;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.messages(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-MediaResource', () {
    unittest.test('method--download', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).media;
      var arg_resourceName = 'foo';
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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/media/"),
        );
        pathOffset += 9;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildMedia());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.download(arg_resourceName, $fields: arg_$fields);
      checkMedia(response as api.Media);
    });
  });

  unittest.group('resource-RoomsResource', () {
    unittest.test('method--messages', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).rooms;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.messages(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--webhooks', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).rooms;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.webhooks(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-RoomsConversationsResource', () {
    unittest.test('method--messages', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).rooms.conversations;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.messages(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-SpacesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildSpace());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSpace(response as api.Space);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces;
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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/spaces"),
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
        var resp = convert.json.encode(buildListSpacesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSpacesResponse(response as api.ListSpacesResponse);
    });

    unittest.test('method--webhooks', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.webhooks(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-SpacesMembersResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces.members;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildMembership());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkMembership(response as api.Membership);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces.members;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildListMembershipsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListMembershipsResponse(response as api.ListMembershipsResponse);
    });
  });

  unittest.group('resource-SpacesMessagesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces.messages;
      var arg_request = buildMessage();
      var arg_parent = 'foo';
      var arg_threadKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
          queryMap["threadKey"]!.first,
          unittest.equals(arg_threadKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          threadKey: arg_threadKey, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces.messages;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces.messages;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces.messages;
      var arg_request = buildMessage();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-SpacesMessagesAttachmentsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.HangoutsChatApi(mock).spaces.messages.attachments;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

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
        var resp = convert.json.encode(buildAttachment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkAttachment(response as api.Attachment);
    });
  });
}
