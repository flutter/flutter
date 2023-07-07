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

import 'package:googleapis/youtube/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.AbuseType> buildUnnamed2941() {
  var o = <api.AbuseType>[];
  o.add(buildAbuseType());
  o.add(buildAbuseType());
  return o;
}

void checkUnnamed2941(core.List<api.AbuseType> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAbuseType(o[0] as api.AbuseType);
  checkAbuseType(o[1] as api.AbuseType);
}

core.List<api.RelatedEntity> buildUnnamed2942() {
  var o = <api.RelatedEntity>[];
  o.add(buildRelatedEntity());
  o.add(buildRelatedEntity());
  return o;
}

void checkUnnamed2942(core.List<api.RelatedEntity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRelatedEntity(o[0] as api.RelatedEntity);
  checkRelatedEntity(o[1] as api.RelatedEntity);
}

core.int buildCounterAbuseReport = 0;
api.AbuseReport buildAbuseReport() {
  var o = api.AbuseReport();
  buildCounterAbuseReport++;
  if (buildCounterAbuseReport < 3) {
    o.abuseTypes = buildUnnamed2941();
    o.description = 'foo';
    o.relatedEntities = buildUnnamed2942();
    o.subject = buildEntity();
  }
  buildCounterAbuseReport--;
  return o;
}

void checkAbuseReport(api.AbuseReport o) {
  buildCounterAbuseReport++;
  if (buildCounterAbuseReport < 3) {
    checkUnnamed2941(o.abuseTypes!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed2942(o.relatedEntities!);
    checkEntity(o.subject! as api.Entity);
  }
  buildCounterAbuseReport--;
}

core.int buildCounterAbuseType = 0;
api.AbuseType buildAbuseType() {
  var o = api.AbuseType();
  buildCounterAbuseType++;
  if (buildCounterAbuseType < 3) {
    o.id = 'foo';
  }
  buildCounterAbuseType--;
  return o;
}

void checkAbuseType(api.AbuseType o) {
  buildCounterAbuseType++;
  if (buildCounterAbuseType < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
  }
  buildCounterAbuseType--;
}

core.List<core.String> buildUnnamed2943() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2943(core.List<core.String> o) {
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

core.int buildCounterAccessPolicy = 0;
api.AccessPolicy buildAccessPolicy() {
  var o = api.AccessPolicy();
  buildCounterAccessPolicy++;
  if (buildCounterAccessPolicy < 3) {
    o.allowed = true;
    o.exception = buildUnnamed2943();
  }
  buildCounterAccessPolicy--;
  return o;
}

void checkAccessPolicy(api.AccessPolicy o) {
  buildCounterAccessPolicy++;
  if (buildCounterAccessPolicy < 3) {
    unittest.expect(o.allowed!, unittest.isTrue);
    checkUnnamed2943(o.exception!);
  }
  buildCounterAccessPolicy--;
}

core.int buildCounterActivity = 0;
api.Activity buildActivity() {
  var o = api.Activity();
  buildCounterActivity++;
  if (buildCounterActivity < 3) {
    o.contentDetails = buildActivityContentDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildActivitySnippet();
  }
  buildCounterActivity--;
  return o;
}

void checkActivity(api.Activity o) {
  buildCounterActivity++;
  if (buildCounterActivity < 3) {
    checkActivityContentDetails(
        o.contentDetails! as api.ActivityContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkActivitySnippet(o.snippet! as api.ActivitySnippet);
  }
  buildCounterActivity--;
}

core.int buildCounterActivityContentDetails = 0;
api.ActivityContentDetails buildActivityContentDetails() {
  var o = api.ActivityContentDetails();
  buildCounterActivityContentDetails++;
  if (buildCounterActivityContentDetails < 3) {
    o.bulletin = buildActivityContentDetailsBulletin();
    o.channelItem = buildActivityContentDetailsChannelItem();
    o.comment = buildActivityContentDetailsComment();
    o.favorite = buildActivityContentDetailsFavorite();
    o.like = buildActivityContentDetailsLike();
    o.playlistItem = buildActivityContentDetailsPlaylistItem();
    o.promotedItem = buildActivityContentDetailsPromotedItem();
    o.recommendation = buildActivityContentDetailsRecommendation();
    o.social = buildActivityContentDetailsSocial();
    o.subscription = buildActivityContentDetailsSubscription();
    o.upload = buildActivityContentDetailsUpload();
  }
  buildCounterActivityContentDetails--;
  return o;
}

void checkActivityContentDetails(api.ActivityContentDetails o) {
  buildCounterActivityContentDetails++;
  if (buildCounterActivityContentDetails < 3) {
    checkActivityContentDetailsBulletin(
        o.bulletin! as api.ActivityContentDetailsBulletin);
    checkActivityContentDetailsChannelItem(
        o.channelItem! as api.ActivityContentDetailsChannelItem);
    checkActivityContentDetailsComment(
        o.comment! as api.ActivityContentDetailsComment);
    checkActivityContentDetailsFavorite(
        o.favorite! as api.ActivityContentDetailsFavorite);
    checkActivityContentDetailsLike(o.like! as api.ActivityContentDetailsLike);
    checkActivityContentDetailsPlaylistItem(
        o.playlistItem! as api.ActivityContentDetailsPlaylistItem);
    checkActivityContentDetailsPromotedItem(
        o.promotedItem! as api.ActivityContentDetailsPromotedItem);
    checkActivityContentDetailsRecommendation(
        o.recommendation! as api.ActivityContentDetailsRecommendation);
    checkActivityContentDetailsSocial(
        o.social! as api.ActivityContentDetailsSocial);
    checkActivityContentDetailsSubscription(
        o.subscription! as api.ActivityContentDetailsSubscription);
    checkActivityContentDetailsUpload(
        o.upload! as api.ActivityContentDetailsUpload);
  }
  buildCounterActivityContentDetails--;
}

core.int buildCounterActivityContentDetailsBulletin = 0;
api.ActivityContentDetailsBulletin buildActivityContentDetailsBulletin() {
  var o = api.ActivityContentDetailsBulletin();
  buildCounterActivityContentDetailsBulletin++;
  if (buildCounterActivityContentDetailsBulletin < 3) {
    o.resourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsBulletin--;
  return o;
}

void checkActivityContentDetailsBulletin(api.ActivityContentDetailsBulletin o) {
  buildCounterActivityContentDetailsBulletin++;
  if (buildCounterActivityContentDetailsBulletin < 3) {
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsBulletin--;
}

core.int buildCounterActivityContentDetailsChannelItem = 0;
api.ActivityContentDetailsChannelItem buildActivityContentDetailsChannelItem() {
  var o = api.ActivityContentDetailsChannelItem();
  buildCounterActivityContentDetailsChannelItem++;
  if (buildCounterActivityContentDetailsChannelItem < 3) {
    o.resourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsChannelItem--;
  return o;
}

void checkActivityContentDetailsChannelItem(
    api.ActivityContentDetailsChannelItem o) {
  buildCounterActivityContentDetailsChannelItem++;
  if (buildCounterActivityContentDetailsChannelItem < 3) {
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsChannelItem--;
}

core.int buildCounterActivityContentDetailsComment = 0;
api.ActivityContentDetailsComment buildActivityContentDetailsComment() {
  var o = api.ActivityContentDetailsComment();
  buildCounterActivityContentDetailsComment++;
  if (buildCounterActivityContentDetailsComment < 3) {
    o.resourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsComment--;
  return o;
}

void checkActivityContentDetailsComment(api.ActivityContentDetailsComment o) {
  buildCounterActivityContentDetailsComment++;
  if (buildCounterActivityContentDetailsComment < 3) {
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsComment--;
}

core.int buildCounterActivityContentDetailsFavorite = 0;
api.ActivityContentDetailsFavorite buildActivityContentDetailsFavorite() {
  var o = api.ActivityContentDetailsFavorite();
  buildCounterActivityContentDetailsFavorite++;
  if (buildCounterActivityContentDetailsFavorite < 3) {
    o.resourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsFavorite--;
  return o;
}

void checkActivityContentDetailsFavorite(api.ActivityContentDetailsFavorite o) {
  buildCounterActivityContentDetailsFavorite++;
  if (buildCounterActivityContentDetailsFavorite < 3) {
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsFavorite--;
}

core.int buildCounterActivityContentDetailsLike = 0;
api.ActivityContentDetailsLike buildActivityContentDetailsLike() {
  var o = api.ActivityContentDetailsLike();
  buildCounterActivityContentDetailsLike++;
  if (buildCounterActivityContentDetailsLike < 3) {
    o.resourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsLike--;
  return o;
}

void checkActivityContentDetailsLike(api.ActivityContentDetailsLike o) {
  buildCounterActivityContentDetailsLike++;
  if (buildCounterActivityContentDetailsLike < 3) {
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsLike--;
}

core.int buildCounterActivityContentDetailsPlaylistItem = 0;
api.ActivityContentDetailsPlaylistItem
    buildActivityContentDetailsPlaylistItem() {
  var o = api.ActivityContentDetailsPlaylistItem();
  buildCounterActivityContentDetailsPlaylistItem++;
  if (buildCounterActivityContentDetailsPlaylistItem < 3) {
    o.playlistId = 'foo';
    o.playlistItemId = 'foo';
    o.resourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsPlaylistItem--;
  return o;
}

void checkActivityContentDetailsPlaylistItem(
    api.ActivityContentDetailsPlaylistItem o) {
  buildCounterActivityContentDetailsPlaylistItem++;
  if (buildCounterActivityContentDetailsPlaylistItem < 3) {
    unittest.expect(
      o.playlistId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.playlistItemId!,
      unittest.equals('foo'),
    );
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsPlaylistItem--;
}

core.List<core.String> buildUnnamed2944() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2944(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2945() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2945(core.List<core.String> o) {
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

core.int buildCounterActivityContentDetailsPromotedItem = 0;
api.ActivityContentDetailsPromotedItem
    buildActivityContentDetailsPromotedItem() {
  var o = api.ActivityContentDetailsPromotedItem();
  buildCounterActivityContentDetailsPromotedItem++;
  if (buildCounterActivityContentDetailsPromotedItem < 3) {
    o.adTag = 'foo';
    o.clickTrackingUrl = 'foo';
    o.creativeViewUrl = 'foo';
    o.ctaType = 'foo';
    o.customCtaButtonText = 'foo';
    o.descriptionText = 'foo';
    o.destinationUrl = 'foo';
    o.forecastingUrl = buildUnnamed2944();
    o.impressionUrl = buildUnnamed2945();
    o.videoId = 'foo';
  }
  buildCounterActivityContentDetailsPromotedItem--;
  return o;
}

void checkActivityContentDetailsPromotedItem(
    api.ActivityContentDetailsPromotedItem o) {
  buildCounterActivityContentDetailsPromotedItem++;
  if (buildCounterActivityContentDetailsPromotedItem < 3) {
    unittest.expect(
      o.adTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clickTrackingUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creativeViewUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ctaType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customCtaButtonText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.descriptionText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destinationUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed2944(o.forecastingUrl!);
    checkUnnamed2945(o.impressionUrl!);
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityContentDetailsPromotedItem--;
}

core.int buildCounterActivityContentDetailsRecommendation = 0;
api.ActivityContentDetailsRecommendation
    buildActivityContentDetailsRecommendation() {
  var o = api.ActivityContentDetailsRecommendation();
  buildCounterActivityContentDetailsRecommendation++;
  if (buildCounterActivityContentDetailsRecommendation < 3) {
    o.reason = 'foo';
    o.resourceId = buildResourceId();
    o.seedResourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsRecommendation--;
  return o;
}

void checkActivityContentDetailsRecommendation(
    api.ActivityContentDetailsRecommendation o) {
  buildCounterActivityContentDetailsRecommendation++;
  if (buildCounterActivityContentDetailsRecommendation < 3) {
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
    checkResourceId(o.resourceId! as api.ResourceId);
    checkResourceId(o.seedResourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsRecommendation--;
}

core.int buildCounterActivityContentDetailsSocial = 0;
api.ActivityContentDetailsSocial buildActivityContentDetailsSocial() {
  var o = api.ActivityContentDetailsSocial();
  buildCounterActivityContentDetailsSocial++;
  if (buildCounterActivityContentDetailsSocial < 3) {
    o.author = 'foo';
    o.imageUrl = 'foo';
    o.referenceUrl = 'foo';
    o.resourceId = buildResourceId();
    o.type = 'foo';
  }
  buildCounterActivityContentDetailsSocial--;
  return o;
}

void checkActivityContentDetailsSocial(api.ActivityContentDetailsSocial o) {
  buildCounterActivityContentDetailsSocial++;
  if (buildCounterActivityContentDetailsSocial < 3) {
    unittest.expect(
      o.author!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.imageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referenceUrl!,
      unittest.equals('foo'),
    );
    checkResourceId(o.resourceId! as api.ResourceId);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityContentDetailsSocial--;
}

core.int buildCounterActivityContentDetailsSubscription = 0;
api.ActivityContentDetailsSubscription
    buildActivityContentDetailsSubscription() {
  var o = api.ActivityContentDetailsSubscription();
  buildCounterActivityContentDetailsSubscription++;
  if (buildCounterActivityContentDetailsSubscription < 3) {
    o.resourceId = buildResourceId();
  }
  buildCounterActivityContentDetailsSubscription--;
  return o;
}

void checkActivityContentDetailsSubscription(
    api.ActivityContentDetailsSubscription o) {
  buildCounterActivityContentDetailsSubscription++;
  if (buildCounterActivityContentDetailsSubscription < 3) {
    checkResourceId(o.resourceId! as api.ResourceId);
  }
  buildCounterActivityContentDetailsSubscription--;
}

core.int buildCounterActivityContentDetailsUpload = 0;
api.ActivityContentDetailsUpload buildActivityContentDetailsUpload() {
  var o = api.ActivityContentDetailsUpload();
  buildCounterActivityContentDetailsUpload++;
  if (buildCounterActivityContentDetailsUpload < 3) {
    o.videoId = 'foo';
  }
  buildCounterActivityContentDetailsUpload--;
  return o;
}

void checkActivityContentDetailsUpload(api.ActivityContentDetailsUpload o) {
  buildCounterActivityContentDetailsUpload++;
  if (buildCounterActivityContentDetailsUpload < 3) {
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityContentDetailsUpload--;
}

core.List<api.Activity> buildUnnamed2946() {
  var o = <api.Activity>[];
  o.add(buildActivity());
  o.add(buildActivity());
  return o;
}

void checkUnnamed2946(core.List<api.Activity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActivity(o[0] as api.Activity);
  checkActivity(o[1] as api.Activity);
}

core.int buildCounterActivityListResponse = 0;
api.ActivityListResponse buildActivityListResponse() {
  var o = api.ActivityListResponse();
  buildCounterActivityListResponse++;
  if (buildCounterActivityListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2946();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterActivityListResponse--;
  return o;
}

void checkActivityListResponse(api.ActivityListResponse o) {
  buildCounterActivityListResponse++;
  if (buildCounterActivityListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2946(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityListResponse--;
}

core.int buildCounterActivitySnippet = 0;
api.ActivitySnippet buildActivitySnippet() {
  var o = api.ActivitySnippet();
  buildCounterActivitySnippet++;
  if (buildCounterActivitySnippet < 3) {
    o.channelId = 'foo';
    o.channelTitle = 'foo';
    o.description = 'foo';
    o.groupId = 'foo';
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
    o.type = 'foo';
  }
  buildCounterActivitySnippet--;
  return o;
}

void checkActivitySnippet(api.ActivitySnippet o) {
  buildCounterActivitySnippet++;
  if (buildCounterActivitySnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.groupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivitySnippet--;
}

core.int buildCounterCaption = 0;
api.Caption buildCaption() {
  var o = api.Caption();
  buildCounterCaption++;
  if (buildCounterCaption < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildCaptionSnippet();
  }
  buildCounterCaption--;
  return o;
}

void checkCaption(api.Caption o) {
  buildCounterCaption++;
  if (buildCounterCaption < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkCaptionSnippet(o.snippet! as api.CaptionSnippet);
  }
  buildCounterCaption--;
}

core.List<api.Caption> buildUnnamed2947() {
  var o = <api.Caption>[];
  o.add(buildCaption());
  o.add(buildCaption());
  return o;
}

void checkUnnamed2947(core.List<api.Caption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCaption(o[0] as api.Caption);
  checkCaption(o[1] as api.Caption);
}

core.int buildCounterCaptionListResponse = 0;
api.CaptionListResponse buildCaptionListResponse() {
  var o = api.CaptionListResponse();
  buildCounterCaptionListResponse++;
  if (buildCounterCaptionListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2947();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterCaptionListResponse--;
  return o;
}

void checkCaptionListResponse(api.CaptionListResponse o) {
  buildCounterCaptionListResponse++;
  if (buildCounterCaptionListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2947(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCaptionListResponse--;
}

core.int buildCounterCaptionSnippet = 0;
api.CaptionSnippet buildCaptionSnippet() {
  var o = api.CaptionSnippet();
  buildCounterCaptionSnippet++;
  if (buildCounterCaptionSnippet < 3) {
    o.audioTrackType = 'foo';
    o.failureReason = 'foo';
    o.isAutoSynced = true;
    o.isCC = true;
    o.isDraft = true;
    o.isEasyReader = true;
    o.isLarge = true;
    o.language = 'foo';
    o.lastUpdated = core.DateTime.parse("2002-02-27T14:01:02");
    o.name = 'foo';
    o.status = 'foo';
    o.trackKind = 'foo';
    o.videoId = 'foo';
  }
  buildCounterCaptionSnippet--;
  return o;
}

void checkCaptionSnippet(api.CaptionSnippet o) {
  buildCounterCaptionSnippet++;
  if (buildCounterCaptionSnippet < 3) {
    unittest.expect(
      o.audioTrackType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.failureReason!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isAutoSynced!, unittest.isTrue);
    unittest.expect(o.isCC!, unittest.isTrue);
    unittest.expect(o.isDraft!, unittest.isTrue);
    unittest.expect(o.isEasyReader!, unittest.isTrue);
    unittest.expect(o.isLarge!, unittest.isTrue);
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastUpdated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.trackKind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCaptionSnippet--;
}

core.int buildCounterCdnSettings = 0;
api.CdnSettings buildCdnSettings() {
  var o = api.CdnSettings();
  buildCounterCdnSettings++;
  if (buildCounterCdnSettings < 3) {
    o.format = 'foo';
    o.frameRate = 'foo';
    o.ingestionInfo = buildIngestionInfo();
    o.ingestionType = 'foo';
    o.resolution = 'foo';
  }
  buildCounterCdnSettings--;
  return o;
}

void checkCdnSettings(api.CdnSettings o) {
  buildCounterCdnSettings++;
  if (buildCounterCdnSettings < 3) {
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.frameRate!,
      unittest.equals('foo'),
    );
    checkIngestionInfo(o.ingestionInfo! as api.IngestionInfo);
    unittest.expect(
      o.ingestionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resolution!,
      unittest.equals('foo'),
    );
  }
  buildCounterCdnSettings--;
}

core.Map<core.String, api.ChannelLocalization> buildUnnamed2948() {
  var o = <core.String, api.ChannelLocalization>{};
  o['x'] = buildChannelLocalization();
  o['y'] = buildChannelLocalization();
  return o;
}

void checkUnnamed2948(core.Map<core.String, api.ChannelLocalization> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannelLocalization(o['x']! as api.ChannelLocalization);
  checkChannelLocalization(o['y']! as api.ChannelLocalization);
}

core.int buildCounterChannel = 0;
api.Channel buildChannel() {
  var o = api.Channel();
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    o.auditDetails = buildChannelAuditDetails();
    o.brandingSettings = buildChannelBrandingSettings();
    o.contentDetails = buildChannelContentDetails();
    o.contentOwnerDetails = buildChannelContentOwnerDetails();
    o.conversionPings = buildChannelConversionPings();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.localizations = buildUnnamed2948();
    o.snippet = buildChannelSnippet();
    o.statistics = buildChannelStatistics();
    o.status = buildChannelStatus();
    o.topicDetails = buildChannelTopicDetails();
  }
  buildCounterChannel--;
  return o;
}

void checkChannel(api.Channel o) {
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    checkChannelAuditDetails(o.auditDetails! as api.ChannelAuditDetails);
    checkChannelBrandingSettings(
        o.brandingSettings! as api.ChannelBrandingSettings);
    checkChannelContentDetails(o.contentDetails! as api.ChannelContentDetails);
    checkChannelContentOwnerDetails(
        o.contentOwnerDetails! as api.ChannelContentOwnerDetails);
    checkChannelConversionPings(
        o.conversionPings! as api.ChannelConversionPings);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2948(o.localizations!);
    checkChannelSnippet(o.snippet! as api.ChannelSnippet);
    checkChannelStatistics(o.statistics! as api.ChannelStatistics);
    checkChannelStatus(o.status! as api.ChannelStatus);
    checkChannelTopicDetails(o.topicDetails! as api.ChannelTopicDetails);
  }
  buildCounterChannel--;
}

core.int buildCounterChannelAuditDetails = 0;
api.ChannelAuditDetails buildChannelAuditDetails() {
  var o = api.ChannelAuditDetails();
  buildCounterChannelAuditDetails++;
  if (buildCounterChannelAuditDetails < 3) {
    o.communityGuidelinesGoodStanding = true;
    o.contentIdClaimsGoodStanding = true;
    o.copyrightStrikesGoodStanding = true;
  }
  buildCounterChannelAuditDetails--;
  return o;
}

void checkChannelAuditDetails(api.ChannelAuditDetails o) {
  buildCounterChannelAuditDetails++;
  if (buildCounterChannelAuditDetails < 3) {
    unittest.expect(o.communityGuidelinesGoodStanding!, unittest.isTrue);
    unittest.expect(o.contentIdClaimsGoodStanding!, unittest.isTrue);
    unittest.expect(o.copyrightStrikesGoodStanding!, unittest.isTrue);
  }
  buildCounterChannelAuditDetails--;
}

core.int buildCounterChannelBannerResource = 0;
api.ChannelBannerResource buildChannelBannerResource() {
  var o = api.ChannelBannerResource();
  buildCounterChannelBannerResource++;
  if (buildCounterChannelBannerResource < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.url = 'foo';
  }
  buildCounterChannelBannerResource--;
  return o;
}

void checkChannelBannerResource(api.ChannelBannerResource o) {
  buildCounterChannelBannerResource++;
  if (buildCounterChannelBannerResource < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelBannerResource--;
}

core.List<api.PropertyValue> buildUnnamed2949() {
  var o = <api.PropertyValue>[];
  o.add(buildPropertyValue());
  o.add(buildPropertyValue());
  return o;
}

void checkUnnamed2949(core.List<api.PropertyValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPropertyValue(o[0] as api.PropertyValue);
  checkPropertyValue(o[1] as api.PropertyValue);
}

core.int buildCounterChannelBrandingSettings = 0;
api.ChannelBrandingSettings buildChannelBrandingSettings() {
  var o = api.ChannelBrandingSettings();
  buildCounterChannelBrandingSettings++;
  if (buildCounterChannelBrandingSettings < 3) {
    o.channel = buildChannelSettings();
    o.hints = buildUnnamed2949();
    o.image = buildImageSettings();
    o.watch = buildWatchSettings();
  }
  buildCounterChannelBrandingSettings--;
  return o;
}

void checkChannelBrandingSettings(api.ChannelBrandingSettings o) {
  buildCounterChannelBrandingSettings++;
  if (buildCounterChannelBrandingSettings < 3) {
    checkChannelSettings(o.channel! as api.ChannelSettings);
    checkUnnamed2949(o.hints!);
    checkImageSettings(o.image! as api.ImageSettings);
    checkWatchSettings(o.watch! as api.WatchSettings);
  }
  buildCounterChannelBrandingSettings--;
}

core.int buildCounterChannelContentDetailsRelatedPlaylists = 0;
api.ChannelContentDetailsRelatedPlaylists
    buildChannelContentDetailsRelatedPlaylists() {
  var o = api.ChannelContentDetailsRelatedPlaylists();
  buildCounterChannelContentDetailsRelatedPlaylists++;
  if (buildCounterChannelContentDetailsRelatedPlaylists < 3) {
    o.favorites = 'foo';
    o.likes = 'foo';
    o.uploads = 'foo';
    o.watchHistory = 'foo';
    o.watchLater = 'foo';
  }
  buildCounterChannelContentDetailsRelatedPlaylists--;
  return o;
}

void checkChannelContentDetailsRelatedPlaylists(
    api.ChannelContentDetailsRelatedPlaylists o) {
  buildCounterChannelContentDetailsRelatedPlaylists++;
  if (buildCounterChannelContentDetailsRelatedPlaylists < 3) {
    unittest.expect(
      o.favorites!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.likes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uploads!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.watchHistory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.watchLater!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelContentDetailsRelatedPlaylists--;
}

core.int buildCounterChannelContentDetails = 0;
api.ChannelContentDetails buildChannelContentDetails() {
  var o = api.ChannelContentDetails();
  buildCounterChannelContentDetails++;
  if (buildCounterChannelContentDetails < 3) {
    o.relatedPlaylists = buildChannelContentDetailsRelatedPlaylists();
  }
  buildCounterChannelContentDetails--;
  return o;
}

void checkChannelContentDetails(api.ChannelContentDetails o) {
  buildCounterChannelContentDetails++;
  if (buildCounterChannelContentDetails < 3) {
    checkChannelContentDetailsRelatedPlaylists(
        o.relatedPlaylists! as api.ChannelContentDetailsRelatedPlaylists);
  }
  buildCounterChannelContentDetails--;
}

core.int buildCounterChannelContentOwnerDetails = 0;
api.ChannelContentOwnerDetails buildChannelContentOwnerDetails() {
  var o = api.ChannelContentOwnerDetails();
  buildCounterChannelContentOwnerDetails++;
  if (buildCounterChannelContentOwnerDetails < 3) {
    o.contentOwner = 'foo';
    o.timeLinked = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterChannelContentOwnerDetails--;
  return o;
}

void checkChannelContentOwnerDetails(api.ChannelContentOwnerDetails o) {
  buildCounterChannelContentOwnerDetails++;
  if (buildCounterChannelContentOwnerDetails < 3) {
    unittest.expect(
      o.contentOwner!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeLinked!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterChannelContentOwnerDetails--;
}

core.int buildCounterChannelConversionPing = 0;
api.ChannelConversionPing buildChannelConversionPing() {
  var o = api.ChannelConversionPing();
  buildCounterChannelConversionPing++;
  if (buildCounterChannelConversionPing < 3) {
    o.context = 'foo';
    o.conversionUrl = 'foo';
  }
  buildCounterChannelConversionPing--;
  return o;
}

void checkChannelConversionPing(api.ChannelConversionPing o) {
  buildCounterChannelConversionPing++;
  if (buildCounterChannelConversionPing < 3) {
    unittest.expect(
      o.context!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.conversionUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelConversionPing--;
}

core.List<api.ChannelConversionPing> buildUnnamed2950() {
  var o = <api.ChannelConversionPing>[];
  o.add(buildChannelConversionPing());
  o.add(buildChannelConversionPing());
  return o;
}

void checkUnnamed2950(core.List<api.ChannelConversionPing> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannelConversionPing(o[0] as api.ChannelConversionPing);
  checkChannelConversionPing(o[1] as api.ChannelConversionPing);
}

core.int buildCounterChannelConversionPings = 0;
api.ChannelConversionPings buildChannelConversionPings() {
  var o = api.ChannelConversionPings();
  buildCounterChannelConversionPings++;
  if (buildCounterChannelConversionPings < 3) {
    o.pings = buildUnnamed2950();
  }
  buildCounterChannelConversionPings--;
  return o;
}

void checkChannelConversionPings(api.ChannelConversionPings o) {
  buildCounterChannelConversionPings++;
  if (buildCounterChannelConversionPings < 3) {
    checkUnnamed2950(o.pings!);
  }
  buildCounterChannelConversionPings--;
}

core.List<api.Channel> buildUnnamed2951() {
  var o = <api.Channel>[];
  o.add(buildChannel());
  o.add(buildChannel());
  return o;
}

void checkUnnamed2951(core.List<api.Channel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannel(o[0] as api.Channel);
  checkChannel(o[1] as api.Channel);
}

core.int buildCounterChannelListResponse = 0;
api.ChannelListResponse buildChannelListResponse() {
  var o = api.ChannelListResponse();
  buildCounterChannelListResponse++;
  if (buildCounterChannelListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2951();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterChannelListResponse--;
  return o;
}

void checkChannelListResponse(api.ChannelListResponse o) {
  buildCounterChannelListResponse++;
  if (buildCounterChannelListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2951(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelListResponse--;
}

core.int buildCounterChannelLocalization = 0;
api.ChannelLocalization buildChannelLocalization() {
  var o = api.ChannelLocalization();
  buildCounterChannelLocalization++;
  if (buildCounterChannelLocalization < 3) {
    o.description = 'foo';
    o.title = 'foo';
  }
  buildCounterChannelLocalization--;
  return o;
}

void checkChannelLocalization(api.ChannelLocalization o) {
  buildCounterChannelLocalization++;
  if (buildCounterChannelLocalization < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelLocalization--;
}

core.int buildCounterChannelProfileDetails = 0;
api.ChannelProfileDetails buildChannelProfileDetails() {
  var o = api.ChannelProfileDetails();
  buildCounterChannelProfileDetails++;
  if (buildCounterChannelProfileDetails < 3) {
    o.channelId = 'foo';
    o.channelUrl = 'foo';
    o.displayName = 'foo';
    o.profileImageUrl = 'foo';
  }
  buildCounterChannelProfileDetails--;
  return o;
}

void checkChannelProfileDetails(api.ChannelProfileDetails o) {
  buildCounterChannelProfileDetails++;
  if (buildCounterChannelProfileDetails < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileImageUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelProfileDetails--;
}

core.Map<core.String, api.ChannelSectionLocalization> buildUnnamed2952() {
  var o = <core.String, api.ChannelSectionLocalization>{};
  o['x'] = buildChannelSectionLocalization();
  o['y'] = buildChannelSectionLocalization();
  return o;
}

void checkUnnamed2952(core.Map<core.String, api.ChannelSectionLocalization> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannelSectionLocalization(o['x']! as api.ChannelSectionLocalization);
  checkChannelSectionLocalization(o['y']! as api.ChannelSectionLocalization);
}

core.int buildCounterChannelSection = 0;
api.ChannelSection buildChannelSection() {
  var o = api.ChannelSection();
  buildCounterChannelSection++;
  if (buildCounterChannelSection < 3) {
    o.contentDetails = buildChannelSectionContentDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.localizations = buildUnnamed2952();
    o.snippet = buildChannelSectionSnippet();
    o.targeting = buildChannelSectionTargeting();
  }
  buildCounterChannelSection--;
  return o;
}

void checkChannelSection(api.ChannelSection o) {
  buildCounterChannelSection++;
  if (buildCounterChannelSection < 3) {
    checkChannelSectionContentDetails(
        o.contentDetails! as api.ChannelSectionContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2952(o.localizations!);
    checkChannelSectionSnippet(o.snippet! as api.ChannelSectionSnippet);
    checkChannelSectionTargeting(o.targeting! as api.ChannelSectionTargeting);
  }
  buildCounterChannelSection--;
}

core.List<core.String> buildUnnamed2953() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2953(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2954() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2954(core.List<core.String> o) {
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

core.int buildCounterChannelSectionContentDetails = 0;
api.ChannelSectionContentDetails buildChannelSectionContentDetails() {
  var o = api.ChannelSectionContentDetails();
  buildCounterChannelSectionContentDetails++;
  if (buildCounterChannelSectionContentDetails < 3) {
    o.channels = buildUnnamed2953();
    o.playlists = buildUnnamed2954();
  }
  buildCounterChannelSectionContentDetails--;
  return o;
}

void checkChannelSectionContentDetails(api.ChannelSectionContentDetails o) {
  buildCounterChannelSectionContentDetails++;
  if (buildCounterChannelSectionContentDetails < 3) {
    checkUnnamed2953(o.channels!);
    checkUnnamed2954(o.playlists!);
  }
  buildCounterChannelSectionContentDetails--;
}

core.List<api.ChannelSection> buildUnnamed2955() {
  var o = <api.ChannelSection>[];
  o.add(buildChannelSection());
  o.add(buildChannelSection());
  return o;
}

void checkUnnamed2955(core.List<api.ChannelSection> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannelSection(o[0] as api.ChannelSection);
  checkChannelSection(o[1] as api.ChannelSection);
}

core.int buildCounterChannelSectionListResponse = 0;
api.ChannelSectionListResponse buildChannelSectionListResponse() {
  var o = api.ChannelSectionListResponse();
  buildCounterChannelSectionListResponse++;
  if (buildCounterChannelSectionListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2955();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterChannelSectionListResponse--;
  return o;
}

void checkChannelSectionListResponse(api.ChannelSectionListResponse o) {
  buildCounterChannelSectionListResponse++;
  if (buildCounterChannelSectionListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2955(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelSectionListResponse--;
}

core.int buildCounterChannelSectionLocalization = 0;
api.ChannelSectionLocalization buildChannelSectionLocalization() {
  var o = api.ChannelSectionLocalization();
  buildCounterChannelSectionLocalization++;
  if (buildCounterChannelSectionLocalization < 3) {
    o.title = 'foo';
  }
  buildCounterChannelSectionLocalization--;
  return o;
}

void checkChannelSectionLocalization(api.ChannelSectionLocalization o) {
  buildCounterChannelSectionLocalization++;
  if (buildCounterChannelSectionLocalization < 3) {
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelSectionLocalization--;
}

core.int buildCounterChannelSectionSnippet = 0;
api.ChannelSectionSnippet buildChannelSectionSnippet() {
  var o = api.ChannelSectionSnippet();
  buildCounterChannelSectionSnippet++;
  if (buildCounterChannelSectionSnippet < 3) {
    o.channelId = 'foo';
    o.defaultLanguage = 'foo';
    o.localized = buildChannelSectionLocalization();
    o.position = 42;
    o.style = 'foo';
    o.title = 'foo';
    o.type = 'foo';
  }
  buildCounterChannelSectionSnippet--;
  return o;
}

void checkChannelSectionSnippet(api.ChannelSectionSnippet o) {
  buildCounterChannelSectionSnippet++;
  if (buildCounterChannelSectionSnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
    checkChannelSectionLocalization(
        o.localized! as api.ChannelSectionLocalization);
    unittest.expect(
      o.position!,
      unittest.equals(42),
    );
    unittest.expect(
      o.style!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelSectionSnippet--;
}

core.List<core.String> buildUnnamed2956() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2956(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2957() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2957(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2958() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2958(core.List<core.String> o) {
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

core.int buildCounterChannelSectionTargeting = 0;
api.ChannelSectionTargeting buildChannelSectionTargeting() {
  var o = api.ChannelSectionTargeting();
  buildCounterChannelSectionTargeting++;
  if (buildCounterChannelSectionTargeting < 3) {
    o.countries = buildUnnamed2956();
    o.languages = buildUnnamed2957();
    o.regions = buildUnnamed2958();
  }
  buildCounterChannelSectionTargeting--;
  return o;
}

void checkChannelSectionTargeting(api.ChannelSectionTargeting o) {
  buildCounterChannelSectionTargeting++;
  if (buildCounterChannelSectionTargeting < 3) {
    checkUnnamed2956(o.countries!);
    checkUnnamed2957(o.languages!);
    checkUnnamed2958(o.regions!);
  }
  buildCounterChannelSectionTargeting--;
}

core.List<core.String> buildUnnamed2959() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2959(core.List<core.String> o) {
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

core.int buildCounterChannelSettings = 0;
api.ChannelSettings buildChannelSettings() {
  var o = api.ChannelSettings();
  buildCounterChannelSettings++;
  if (buildCounterChannelSettings < 3) {
    o.country = 'foo';
    o.defaultLanguage = 'foo';
    o.defaultTab = 'foo';
    o.description = 'foo';
    o.featuredChannelsTitle = 'foo';
    o.featuredChannelsUrls = buildUnnamed2959();
    o.keywords = 'foo';
    o.moderateComments = true;
    o.profileColor = 'foo';
    o.showBrowseView = true;
    o.showRelatedChannels = true;
    o.title = 'foo';
    o.trackingAnalyticsAccountId = 'foo';
    o.unsubscribedTrailer = 'foo';
  }
  buildCounterChannelSettings--;
  return o;
}

void checkChannelSettings(api.ChannelSettings o) {
  buildCounterChannelSettings++;
  if (buildCounterChannelSettings < 3) {
    unittest.expect(
      o.country!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultTab!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.featuredChannelsTitle!,
      unittest.equals('foo'),
    );
    checkUnnamed2959(o.featuredChannelsUrls!);
    unittest.expect(
      o.keywords!,
      unittest.equals('foo'),
    );
    unittest.expect(o.moderateComments!, unittest.isTrue);
    unittest.expect(
      o.profileColor!,
      unittest.equals('foo'),
    );
    unittest.expect(o.showBrowseView!, unittest.isTrue);
    unittest.expect(o.showRelatedChannels!, unittest.isTrue);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.trackingAnalyticsAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.unsubscribedTrailer!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelSettings--;
}

core.int buildCounterChannelSnippet = 0;
api.ChannelSnippet buildChannelSnippet() {
  var o = api.ChannelSnippet();
  buildCounterChannelSnippet++;
  if (buildCounterChannelSnippet < 3) {
    o.country = 'foo';
    o.customUrl = 'foo';
    o.defaultLanguage = 'foo';
    o.description = 'foo';
    o.localized = buildChannelLocalization();
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
  }
  buildCounterChannelSnippet--;
  return o;
}

void checkChannelSnippet(api.ChannelSnippet o) {
  buildCounterChannelSnippet++;
  if (buildCounterChannelSnippet < 3) {
    unittest.expect(
      o.country!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkChannelLocalization(o.localized! as api.ChannelLocalization);
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelSnippet--;
}

core.int buildCounterChannelStatistics = 0;
api.ChannelStatistics buildChannelStatistics() {
  var o = api.ChannelStatistics();
  buildCounterChannelStatistics++;
  if (buildCounterChannelStatistics < 3) {
    o.commentCount = 'foo';
    o.hiddenSubscriberCount = true;
    o.subscriberCount = 'foo';
    o.videoCount = 'foo';
    o.viewCount = 'foo';
  }
  buildCounterChannelStatistics--;
  return o;
}

void checkChannelStatistics(api.ChannelStatistics o) {
  buildCounterChannelStatistics++;
  if (buildCounterChannelStatistics < 3) {
    unittest.expect(
      o.commentCount!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hiddenSubscriberCount!, unittest.isTrue);
    unittest.expect(
      o.subscriberCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.viewCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelStatistics--;
}

core.int buildCounterChannelStatus = 0;
api.ChannelStatus buildChannelStatus() {
  var o = api.ChannelStatus();
  buildCounterChannelStatus++;
  if (buildCounterChannelStatus < 3) {
    o.isLinked = true;
    o.longUploadsStatus = 'foo';
    o.madeForKids = true;
    o.privacyStatus = 'foo';
    o.selfDeclaredMadeForKids = true;
  }
  buildCounterChannelStatus--;
  return o;
}

void checkChannelStatus(api.ChannelStatus o) {
  buildCounterChannelStatus++;
  if (buildCounterChannelStatus < 3) {
    unittest.expect(o.isLinked!, unittest.isTrue);
    unittest.expect(
      o.longUploadsStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(o.madeForKids!, unittest.isTrue);
    unittest.expect(
      o.privacyStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(o.selfDeclaredMadeForKids!, unittest.isTrue);
  }
  buildCounterChannelStatus--;
}

core.int buildCounterChannelToStoreLinkDetails = 0;
api.ChannelToStoreLinkDetails buildChannelToStoreLinkDetails() {
  var o = api.ChannelToStoreLinkDetails();
  buildCounterChannelToStoreLinkDetails++;
  if (buildCounterChannelToStoreLinkDetails < 3) {
    o.storeName = 'foo';
    o.storeUrl = 'foo';
  }
  buildCounterChannelToStoreLinkDetails--;
  return o;
}

void checkChannelToStoreLinkDetails(api.ChannelToStoreLinkDetails o) {
  buildCounterChannelToStoreLinkDetails++;
  if (buildCounterChannelToStoreLinkDetails < 3) {
    unittest.expect(
      o.storeName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.storeUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannelToStoreLinkDetails--;
}

core.List<core.String> buildUnnamed2960() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2960(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2961() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2961(core.List<core.String> o) {
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

core.int buildCounterChannelTopicDetails = 0;
api.ChannelTopicDetails buildChannelTopicDetails() {
  var o = api.ChannelTopicDetails();
  buildCounterChannelTopicDetails++;
  if (buildCounterChannelTopicDetails < 3) {
    o.topicCategories = buildUnnamed2960();
    o.topicIds = buildUnnamed2961();
  }
  buildCounterChannelTopicDetails--;
  return o;
}

void checkChannelTopicDetails(api.ChannelTopicDetails o) {
  buildCounterChannelTopicDetails++;
  if (buildCounterChannelTopicDetails < 3) {
    checkUnnamed2960(o.topicCategories!);
    checkUnnamed2961(o.topicIds!);
  }
  buildCounterChannelTopicDetails--;
}

core.int buildCounterComment = 0;
api.Comment buildComment() {
  var o = api.Comment();
  buildCounterComment++;
  if (buildCounterComment < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildCommentSnippet();
  }
  buildCounterComment--;
  return o;
}

void checkComment(api.Comment o) {
  buildCounterComment++;
  if (buildCounterComment < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkCommentSnippet(o.snippet! as api.CommentSnippet);
  }
  buildCounterComment--;
}

core.List<api.Comment> buildUnnamed2962() {
  var o = <api.Comment>[];
  o.add(buildComment());
  o.add(buildComment());
  return o;
}

void checkUnnamed2962(core.List<api.Comment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkComment(o[0] as api.Comment);
  checkComment(o[1] as api.Comment);
}

core.int buildCounterCommentListResponse = 0;
api.CommentListResponse buildCommentListResponse() {
  var o = api.CommentListResponse();
  buildCounterCommentListResponse++;
  if (buildCounterCommentListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2962();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterCommentListResponse--;
  return o;
}

void checkCommentListResponse(api.CommentListResponse o) {
  buildCounterCommentListResponse++;
  if (buildCounterCommentListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2962(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommentListResponse--;
}

core.int buildCounterCommentSnippet = 0;
api.CommentSnippet buildCommentSnippet() {
  var o = api.CommentSnippet();
  buildCounterCommentSnippet++;
  if (buildCounterCommentSnippet < 3) {
    o.authorChannelId = buildCommentSnippetAuthorChannelId();
    o.authorChannelUrl = 'foo';
    o.authorDisplayName = 'foo';
    o.authorProfileImageUrl = 'foo';
    o.canRate = true;
    o.channelId = 'foo';
    o.likeCount = 42;
    o.moderationStatus = 'foo';
    o.parentId = 'foo';
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.textDisplay = 'foo';
    o.textOriginal = 'foo';
    o.updatedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.videoId = 'foo';
    o.viewerRating = 'foo';
  }
  buildCounterCommentSnippet--;
  return o;
}

void checkCommentSnippet(api.CommentSnippet o) {
  buildCounterCommentSnippet++;
  if (buildCounterCommentSnippet < 3) {
    checkCommentSnippetAuthorChannelId(
        o.authorChannelId! as api.CommentSnippetAuthorChannelId);
    unittest.expect(
      o.authorChannelUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.authorDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.authorProfileImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.canRate!, unittest.isTrue);
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.likeCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.moderationStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.textDisplay!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.textOriginal!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updatedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.viewerRating!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommentSnippet--;
}

core.int buildCounterCommentSnippetAuthorChannelId = 0;
api.CommentSnippetAuthorChannelId buildCommentSnippetAuthorChannelId() {
  var o = api.CommentSnippetAuthorChannelId();
  buildCounterCommentSnippetAuthorChannelId++;
  if (buildCounterCommentSnippetAuthorChannelId < 3) {
    o.value = 'foo';
  }
  buildCounterCommentSnippetAuthorChannelId--;
  return o;
}

void checkCommentSnippetAuthorChannelId(api.CommentSnippetAuthorChannelId o) {
  buildCounterCommentSnippetAuthorChannelId++;
  if (buildCounterCommentSnippetAuthorChannelId < 3) {
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommentSnippetAuthorChannelId--;
}

core.int buildCounterCommentThread = 0;
api.CommentThread buildCommentThread() {
  var o = api.CommentThread();
  buildCounterCommentThread++;
  if (buildCounterCommentThread < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.replies = buildCommentThreadReplies();
    o.snippet = buildCommentThreadSnippet();
  }
  buildCounterCommentThread--;
  return o;
}

void checkCommentThread(api.CommentThread o) {
  buildCounterCommentThread++;
  if (buildCounterCommentThread < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkCommentThreadReplies(o.replies! as api.CommentThreadReplies);
    checkCommentThreadSnippet(o.snippet! as api.CommentThreadSnippet);
  }
  buildCounterCommentThread--;
}

core.List<api.CommentThread> buildUnnamed2963() {
  var o = <api.CommentThread>[];
  o.add(buildCommentThread());
  o.add(buildCommentThread());
  return o;
}

void checkUnnamed2963(core.List<api.CommentThread> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCommentThread(o[0] as api.CommentThread);
  checkCommentThread(o[1] as api.CommentThread);
}

core.int buildCounterCommentThreadListResponse = 0;
api.CommentThreadListResponse buildCommentThreadListResponse() {
  var o = api.CommentThreadListResponse();
  buildCounterCommentThreadListResponse++;
  if (buildCounterCommentThreadListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2963();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterCommentThreadListResponse--;
  return o;
}

void checkCommentThreadListResponse(api.CommentThreadListResponse o) {
  buildCounterCommentThreadListResponse++;
  if (buildCounterCommentThreadListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2963(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommentThreadListResponse--;
}

core.List<api.Comment> buildUnnamed2964() {
  var o = <api.Comment>[];
  o.add(buildComment());
  o.add(buildComment());
  return o;
}

void checkUnnamed2964(core.List<api.Comment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkComment(o[0] as api.Comment);
  checkComment(o[1] as api.Comment);
}

core.int buildCounterCommentThreadReplies = 0;
api.CommentThreadReplies buildCommentThreadReplies() {
  var o = api.CommentThreadReplies();
  buildCounterCommentThreadReplies++;
  if (buildCounterCommentThreadReplies < 3) {
    o.comments = buildUnnamed2964();
  }
  buildCounterCommentThreadReplies--;
  return o;
}

void checkCommentThreadReplies(api.CommentThreadReplies o) {
  buildCounterCommentThreadReplies++;
  if (buildCounterCommentThreadReplies < 3) {
    checkUnnamed2964(o.comments!);
  }
  buildCounterCommentThreadReplies--;
}

core.int buildCounterCommentThreadSnippet = 0;
api.CommentThreadSnippet buildCommentThreadSnippet() {
  var o = api.CommentThreadSnippet();
  buildCounterCommentThreadSnippet++;
  if (buildCounterCommentThreadSnippet < 3) {
    o.canReply = true;
    o.channelId = 'foo';
    o.isPublic = true;
    o.topLevelComment = buildComment();
    o.totalReplyCount = 42;
    o.videoId = 'foo';
  }
  buildCounterCommentThreadSnippet--;
  return o;
}

void checkCommentThreadSnippet(api.CommentThreadSnippet o) {
  buildCounterCommentThreadSnippet++;
  if (buildCounterCommentThreadSnippet < 3) {
    unittest.expect(o.canReply!, unittest.isTrue);
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isPublic!, unittest.isTrue);
    checkComment(o.topLevelComment! as api.Comment);
    unittest.expect(
      o.totalReplyCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommentThreadSnippet--;
}

core.List<core.String> buildUnnamed2965() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2965(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2966() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2966(core.List<core.String> o) {
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

core.int buildCounterContentRating = 0;
api.ContentRating buildContentRating() {
  var o = api.ContentRating();
  buildCounterContentRating++;
  if (buildCounterContentRating < 3) {
    o.acbRating = 'foo';
    o.agcomRating = 'foo';
    o.anatelRating = 'foo';
    o.bbfcRating = 'foo';
    o.bfvcRating = 'foo';
    o.bmukkRating = 'foo';
    o.catvRating = 'foo';
    o.catvfrRating = 'foo';
    o.cbfcRating = 'foo';
    o.cccRating = 'foo';
    o.cceRating = 'foo';
    o.chfilmRating = 'foo';
    o.chvrsRating = 'foo';
    o.cicfRating = 'foo';
    o.cnaRating = 'foo';
    o.cncRating = 'foo';
    o.csaRating = 'foo';
    o.cscfRating = 'foo';
    o.czfilmRating = 'foo';
    o.djctqRating = 'foo';
    o.djctqRatingReasons = buildUnnamed2965();
    o.ecbmctRating = 'foo';
    o.eefilmRating = 'foo';
    o.egfilmRating = 'foo';
    o.eirinRating = 'foo';
    o.fcbmRating = 'foo';
    o.fcoRating = 'foo';
    o.fmocRating = 'foo';
    o.fpbRating = 'foo';
    o.fpbRatingReasons = buildUnnamed2966();
    o.fskRating = 'foo';
    o.grfilmRating = 'foo';
    o.icaaRating = 'foo';
    o.ifcoRating = 'foo';
    o.ilfilmRating = 'foo';
    o.incaaRating = 'foo';
    o.kfcbRating = 'foo';
    o.kijkwijzerRating = 'foo';
    o.kmrbRating = 'foo';
    o.lsfRating = 'foo';
    o.mccaaRating = 'foo';
    o.mccypRating = 'foo';
    o.mcstRating = 'foo';
    o.mdaRating = 'foo';
    o.medietilsynetRating = 'foo';
    o.mekuRating = 'foo';
    o.menaMpaaRating = 'foo';
    o.mibacRating = 'foo';
    o.mocRating = 'foo';
    o.moctwRating = 'foo';
    o.mpaaRating = 'foo';
    o.mpaatRating = 'foo';
    o.mtrcbRating = 'foo';
    o.nbcRating = 'foo';
    o.nbcplRating = 'foo';
    o.nfrcRating = 'foo';
    o.nfvcbRating = 'foo';
    o.nkclvRating = 'foo';
    o.nmcRating = 'foo';
    o.oflcRating = 'foo';
    o.pefilmRating = 'foo';
    o.rcnofRating = 'foo';
    o.resorteviolenciaRating = 'foo';
    o.rtcRating = 'foo';
    o.rteRating = 'foo';
    o.russiaRating = 'foo';
    o.skfilmRating = 'foo';
    o.smaisRating = 'foo';
    o.smsaRating = 'foo';
    o.tvpgRating = 'foo';
    o.ytRating = 'foo';
  }
  buildCounterContentRating--;
  return o;
}

void checkContentRating(api.ContentRating o) {
  buildCounterContentRating++;
  if (buildCounterContentRating < 3) {
    unittest.expect(
      o.acbRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.agcomRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.anatelRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bbfcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bfvcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bmukkRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.catvRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.catvfrRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cbfcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cccRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cceRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.chfilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.chvrsRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cicfRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cnaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cncRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.csaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cscfRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.czfilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.djctqRating!,
      unittest.equals('foo'),
    );
    checkUnnamed2965(o.djctqRatingReasons!);
    unittest.expect(
      o.ecbmctRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eefilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.egfilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eirinRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fcbmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fcoRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fmocRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fpbRating!,
      unittest.equals('foo'),
    );
    checkUnnamed2966(o.fpbRatingReasons!);
    unittest.expect(
      o.fskRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.grfilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.icaaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ifcoRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ilfilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.incaaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kfcbRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kijkwijzerRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kmrbRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lsfRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mccaaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mccypRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mcstRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mdaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.medietilsynetRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mekuRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.menaMpaaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mibacRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mocRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.moctwRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mpaaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mpaatRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mtrcbRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nbcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nbcplRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nfrcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nfvcbRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nkclvRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nmcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oflcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pefilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rcnofRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resorteviolenciaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rtcRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rteRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.russiaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.skfilmRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.smaisRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.smsaRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tvpgRating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ytRating!,
      unittest.equals('foo'),
    );
  }
  buildCounterContentRating--;
}

core.int buildCounterEntity = 0;
api.Entity buildEntity() {
  var o = api.Entity();
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    o.id = 'foo';
    o.typeId = 'foo';
    o.url = 'foo';
  }
  buildCounterEntity--;
  return o;
}

void checkEntity(api.Entity o) {
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.typeId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterEntity--;
}

core.int buildCounterGeoPoint = 0;
api.GeoPoint buildGeoPoint() {
  var o = api.GeoPoint();
  buildCounterGeoPoint++;
  if (buildCounterGeoPoint < 3) {
    o.altitude = 42.0;
    o.latitude = 42.0;
    o.longitude = 42.0;
  }
  buildCounterGeoPoint--;
  return o;
}

void checkGeoPoint(api.GeoPoint o) {
  buildCounterGeoPoint++;
  if (buildCounterGeoPoint < 3) {
    unittest.expect(
      o.altitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.latitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.longitude!,
      unittest.equals(42.0),
    );
  }
  buildCounterGeoPoint--;
}

core.int buildCounterI18nLanguage = 0;
api.I18nLanguage buildI18nLanguage() {
  var o = api.I18nLanguage();
  buildCounterI18nLanguage++;
  if (buildCounterI18nLanguage < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildI18nLanguageSnippet();
  }
  buildCounterI18nLanguage--;
  return o;
}

void checkI18nLanguage(api.I18nLanguage o) {
  buildCounterI18nLanguage++;
  if (buildCounterI18nLanguage < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkI18nLanguageSnippet(o.snippet! as api.I18nLanguageSnippet);
  }
  buildCounterI18nLanguage--;
}

core.List<api.I18nLanguage> buildUnnamed2967() {
  var o = <api.I18nLanguage>[];
  o.add(buildI18nLanguage());
  o.add(buildI18nLanguage());
  return o;
}

void checkUnnamed2967(core.List<api.I18nLanguage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkI18nLanguage(o[0] as api.I18nLanguage);
  checkI18nLanguage(o[1] as api.I18nLanguage);
}

core.int buildCounterI18nLanguageListResponse = 0;
api.I18nLanguageListResponse buildI18nLanguageListResponse() {
  var o = api.I18nLanguageListResponse();
  buildCounterI18nLanguageListResponse++;
  if (buildCounterI18nLanguageListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2967();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterI18nLanguageListResponse--;
  return o;
}

void checkI18nLanguageListResponse(api.I18nLanguageListResponse o) {
  buildCounterI18nLanguageListResponse++;
  if (buildCounterI18nLanguageListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2967(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterI18nLanguageListResponse--;
}

core.int buildCounterI18nLanguageSnippet = 0;
api.I18nLanguageSnippet buildI18nLanguageSnippet() {
  var o = api.I18nLanguageSnippet();
  buildCounterI18nLanguageSnippet++;
  if (buildCounterI18nLanguageSnippet < 3) {
    o.hl = 'foo';
    o.name = 'foo';
  }
  buildCounterI18nLanguageSnippet--;
  return o;
}

void checkI18nLanguageSnippet(api.I18nLanguageSnippet o) {
  buildCounterI18nLanguageSnippet++;
  if (buildCounterI18nLanguageSnippet < 3) {
    unittest.expect(
      o.hl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterI18nLanguageSnippet--;
}

core.int buildCounterI18nRegion = 0;
api.I18nRegion buildI18nRegion() {
  var o = api.I18nRegion();
  buildCounterI18nRegion++;
  if (buildCounterI18nRegion < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildI18nRegionSnippet();
  }
  buildCounterI18nRegion--;
  return o;
}

void checkI18nRegion(api.I18nRegion o) {
  buildCounterI18nRegion++;
  if (buildCounterI18nRegion < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkI18nRegionSnippet(o.snippet! as api.I18nRegionSnippet);
  }
  buildCounterI18nRegion--;
}

core.List<api.I18nRegion> buildUnnamed2968() {
  var o = <api.I18nRegion>[];
  o.add(buildI18nRegion());
  o.add(buildI18nRegion());
  return o;
}

void checkUnnamed2968(core.List<api.I18nRegion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkI18nRegion(o[0] as api.I18nRegion);
  checkI18nRegion(o[1] as api.I18nRegion);
}

core.int buildCounterI18nRegionListResponse = 0;
api.I18nRegionListResponse buildI18nRegionListResponse() {
  var o = api.I18nRegionListResponse();
  buildCounterI18nRegionListResponse++;
  if (buildCounterI18nRegionListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2968();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterI18nRegionListResponse--;
  return o;
}

void checkI18nRegionListResponse(api.I18nRegionListResponse o) {
  buildCounterI18nRegionListResponse++;
  if (buildCounterI18nRegionListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2968(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterI18nRegionListResponse--;
}

core.int buildCounterI18nRegionSnippet = 0;
api.I18nRegionSnippet buildI18nRegionSnippet() {
  var o = api.I18nRegionSnippet();
  buildCounterI18nRegionSnippet++;
  if (buildCounterI18nRegionSnippet < 3) {
    o.gl = 'foo';
    o.name = 'foo';
  }
  buildCounterI18nRegionSnippet--;
  return o;
}

void checkI18nRegionSnippet(api.I18nRegionSnippet o) {
  buildCounterI18nRegionSnippet++;
  if (buildCounterI18nRegionSnippet < 3) {
    unittest.expect(
      o.gl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterI18nRegionSnippet--;
}

core.int buildCounterImageSettings = 0;
api.ImageSettings buildImageSettings() {
  var o = api.ImageSettings();
  buildCounterImageSettings++;
  if (buildCounterImageSettings < 3) {
    o.backgroundImageUrl = buildLocalizedProperty();
    o.bannerExternalUrl = 'foo';
    o.bannerImageUrl = 'foo';
    o.bannerMobileExtraHdImageUrl = 'foo';
    o.bannerMobileHdImageUrl = 'foo';
    o.bannerMobileImageUrl = 'foo';
    o.bannerMobileLowImageUrl = 'foo';
    o.bannerMobileMediumHdImageUrl = 'foo';
    o.bannerTabletExtraHdImageUrl = 'foo';
    o.bannerTabletHdImageUrl = 'foo';
    o.bannerTabletImageUrl = 'foo';
    o.bannerTabletLowImageUrl = 'foo';
    o.bannerTvHighImageUrl = 'foo';
    o.bannerTvImageUrl = 'foo';
    o.bannerTvLowImageUrl = 'foo';
    o.bannerTvMediumImageUrl = 'foo';
    o.largeBrandedBannerImageImapScript = buildLocalizedProperty();
    o.largeBrandedBannerImageUrl = buildLocalizedProperty();
    o.smallBrandedBannerImageImapScript = buildLocalizedProperty();
    o.smallBrandedBannerImageUrl = buildLocalizedProperty();
    o.trackingImageUrl = 'foo';
    o.watchIconImageUrl = 'foo';
  }
  buildCounterImageSettings--;
  return o;
}

void checkImageSettings(api.ImageSettings o) {
  buildCounterImageSettings++;
  if (buildCounterImageSettings < 3) {
    checkLocalizedProperty(o.backgroundImageUrl! as api.LocalizedProperty);
    unittest.expect(
      o.bannerExternalUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerMobileExtraHdImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerMobileHdImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerMobileImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerMobileLowImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerMobileMediumHdImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTabletExtraHdImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTabletHdImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTabletImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTabletLowImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTvHighImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTvImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTvLowImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerTvMediumImageUrl!,
      unittest.equals('foo'),
    );
    checkLocalizedProperty(
        o.largeBrandedBannerImageImapScript! as api.LocalizedProperty);
    checkLocalizedProperty(
        o.largeBrandedBannerImageUrl! as api.LocalizedProperty);
    checkLocalizedProperty(
        o.smallBrandedBannerImageImapScript! as api.LocalizedProperty);
    checkLocalizedProperty(
        o.smallBrandedBannerImageUrl! as api.LocalizedProperty);
    unittest.expect(
      o.trackingImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.watchIconImageUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterImageSettings--;
}

core.int buildCounterIngestionInfo = 0;
api.IngestionInfo buildIngestionInfo() {
  var o = api.IngestionInfo();
  buildCounterIngestionInfo++;
  if (buildCounterIngestionInfo < 3) {
    o.backupIngestionAddress = 'foo';
    o.ingestionAddress = 'foo';
    o.rtmpsBackupIngestionAddress = 'foo';
    o.rtmpsIngestionAddress = 'foo';
    o.streamName = 'foo';
  }
  buildCounterIngestionInfo--;
  return o;
}

void checkIngestionInfo(api.IngestionInfo o) {
  buildCounterIngestionInfo++;
  if (buildCounterIngestionInfo < 3) {
    unittest.expect(
      o.backupIngestionAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ingestionAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rtmpsBackupIngestionAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rtmpsIngestionAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.streamName!,
      unittest.equals('foo'),
    );
  }
  buildCounterIngestionInfo--;
}

core.int buildCounterInvideoBranding = 0;
api.InvideoBranding buildInvideoBranding() {
  var o = api.InvideoBranding();
  buildCounterInvideoBranding++;
  if (buildCounterInvideoBranding < 3) {
    o.imageBytes = 'foo';
    o.imageUrl = 'foo';
    o.position = buildInvideoPosition();
    o.targetChannelId = 'foo';
    o.timing = buildInvideoTiming();
  }
  buildCounterInvideoBranding--;
  return o;
}

void checkInvideoBranding(api.InvideoBranding o) {
  buildCounterInvideoBranding++;
  if (buildCounterInvideoBranding < 3) {
    unittest.expect(
      o.imageBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.imageUrl!,
      unittest.equals('foo'),
    );
    checkInvideoPosition(o.position! as api.InvideoPosition);
    unittest.expect(
      o.targetChannelId!,
      unittest.equals('foo'),
    );
    checkInvideoTiming(o.timing! as api.InvideoTiming);
  }
  buildCounterInvideoBranding--;
}

core.int buildCounterInvideoPosition = 0;
api.InvideoPosition buildInvideoPosition() {
  var o = api.InvideoPosition();
  buildCounterInvideoPosition++;
  if (buildCounterInvideoPosition < 3) {
    o.cornerPosition = 'foo';
    o.type = 'foo';
  }
  buildCounterInvideoPosition--;
  return o;
}

void checkInvideoPosition(api.InvideoPosition o) {
  buildCounterInvideoPosition++;
  if (buildCounterInvideoPosition < 3) {
    unittest.expect(
      o.cornerPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterInvideoPosition--;
}

core.int buildCounterInvideoTiming = 0;
api.InvideoTiming buildInvideoTiming() {
  var o = api.InvideoTiming();
  buildCounterInvideoTiming++;
  if (buildCounterInvideoTiming < 3) {
    o.durationMs = 'foo';
    o.offsetMs = 'foo';
    o.type = 'foo';
  }
  buildCounterInvideoTiming--;
  return o;
}

void checkInvideoTiming(api.InvideoTiming o) {
  buildCounterInvideoTiming++;
  if (buildCounterInvideoTiming < 3) {
    unittest.expect(
      o.durationMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.offsetMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterInvideoTiming--;
}

core.int buildCounterLanguageTag = 0;
api.LanguageTag buildLanguageTag() {
  var o = api.LanguageTag();
  buildCounterLanguageTag++;
  if (buildCounterLanguageTag < 3) {
    o.value = 'foo';
  }
  buildCounterLanguageTag--;
  return o;
}

void checkLanguageTag(api.LanguageTag o) {
  buildCounterLanguageTag++;
  if (buildCounterLanguageTag < 3) {
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterLanguageTag--;
}

core.int buildCounterLevelDetails = 0;
api.LevelDetails buildLevelDetails() {
  var o = api.LevelDetails();
  buildCounterLevelDetails++;
  if (buildCounterLevelDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterLevelDetails--;
  return o;
}

void checkLevelDetails(api.LevelDetails o) {
  buildCounterLevelDetails++;
  if (buildCounterLevelDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterLevelDetails--;
}

core.int buildCounterLiveBroadcast = 0;
api.LiveBroadcast buildLiveBroadcast() {
  var o = api.LiveBroadcast();
  buildCounterLiveBroadcast++;
  if (buildCounterLiveBroadcast < 3) {
    o.contentDetails = buildLiveBroadcastContentDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildLiveBroadcastSnippet();
    o.statistics = buildLiveBroadcastStatistics();
    o.status = buildLiveBroadcastStatus();
  }
  buildCounterLiveBroadcast--;
  return o;
}

void checkLiveBroadcast(api.LiveBroadcast o) {
  buildCounterLiveBroadcast++;
  if (buildCounterLiveBroadcast < 3) {
    checkLiveBroadcastContentDetails(
        o.contentDetails! as api.LiveBroadcastContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLiveBroadcastSnippet(o.snippet! as api.LiveBroadcastSnippet);
    checkLiveBroadcastStatistics(o.statistics! as api.LiveBroadcastStatistics);
    checkLiveBroadcastStatus(o.status! as api.LiveBroadcastStatus);
  }
  buildCounterLiveBroadcast--;
}

core.int buildCounterLiveBroadcastContentDetails = 0;
api.LiveBroadcastContentDetails buildLiveBroadcastContentDetails() {
  var o = api.LiveBroadcastContentDetails();
  buildCounterLiveBroadcastContentDetails++;
  if (buildCounterLiveBroadcastContentDetails < 3) {
    o.boundStreamId = 'foo';
    o.boundStreamLastUpdateTimeMs = core.DateTime.parse("2002-02-27T14:01:02");
    o.closedCaptionsType = 'foo';
    o.enableAutoStart = true;
    o.enableAutoStop = true;
    o.enableClosedCaptions = true;
    o.enableContentEncryption = true;
    o.enableDvr = true;
    o.enableEmbed = true;
    o.enableLowLatency = true;
    o.latencyPreference = 'foo';
    o.mesh = 'foo';
    o.monitorStream = buildMonitorStreamInfo();
    o.projection = 'foo';
    o.recordFromStart = true;
    o.startWithSlate = true;
    o.stereoLayout = 'foo';
  }
  buildCounterLiveBroadcastContentDetails--;
  return o;
}

void checkLiveBroadcastContentDetails(api.LiveBroadcastContentDetails o) {
  buildCounterLiveBroadcastContentDetails++;
  if (buildCounterLiveBroadcastContentDetails < 3) {
    unittest.expect(
      o.boundStreamId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.boundStreamLastUpdateTimeMs!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.closedCaptionsType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableAutoStart!, unittest.isTrue);
    unittest.expect(o.enableAutoStop!, unittest.isTrue);
    unittest.expect(o.enableClosedCaptions!, unittest.isTrue);
    unittest.expect(o.enableContentEncryption!, unittest.isTrue);
    unittest.expect(o.enableDvr!, unittest.isTrue);
    unittest.expect(o.enableEmbed!, unittest.isTrue);
    unittest.expect(o.enableLowLatency!, unittest.isTrue);
    unittest.expect(
      o.latencyPreference!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mesh!,
      unittest.equals('foo'),
    );
    checkMonitorStreamInfo(o.monitorStream! as api.MonitorStreamInfo);
    unittest.expect(
      o.projection!,
      unittest.equals('foo'),
    );
    unittest.expect(o.recordFromStart!, unittest.isTrue);
    unittest.expect(o.startWithSlate!, unittest.isTrue);
    unittest.expect(
      o.stereoLayout!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveBroadcastContentDetails--;
}

core.List<api.LiveBroadcast> buildUnnamed2969() {
  var o = <api.LiveBroadcast>[];
  o.add(buildLiveBroadcast());
  o.add(buildLiveBroadcast());
  return o;
}

void checkUnnamed2969(core.List<api.LiveBroadcast> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLiveBroadcast(o[0] as api.LiveBroadcast);
  checkLiveBroadcast(o[1] as api.LiveBroadcast);
}

core.int buildCounterLiveBroadcastListResponse = 0;
api.LiveBroadcastListResponse buildLiveBroadcastListResponse() {
  var o = api.LiveBroadcastListResponse();
  buildCounterLiveBroadcastListResponse++;
  if (buildCounterLiveBroadcastListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2969();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterLiveBroadcastListResponse--;
  return o;
}

void checkLiveBroadcastListResponse(api.LiveBroadcastListResponse o) {
  buildCounterLiveBroadcastListResponse++;
  if (buildCounterLiveBroadcastListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2969(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveBroadcastListResponse--;
}

core.int buildCounterLiveBroadcastSnippet = 0;
api.LiveBroadcastSnippet buildLiveBroadcastSnippet() {
  var o = api.LiveBroadcastSnippet();
  buildCounterLiveBroadcastSnippet++;
  if (buildCounterLiveBroadcastSnippet < 3) {
    o.actualEndTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.actualStartTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.channelId = 'foo';
    o.description = 'foo';
    o.isDefaultBroadcast = true;
    o.liveChatId = 'foo';
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.scheduledEndTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.scheduledStartTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
  }
  buildCounterLiveBroadcastSnippet--;
  return o;
}

void checkLiveBroadcastSnippet(api.LiveBroadcastSnippet o) {
  buildCounterLiveBroadcastSnippet++;
  if (buildCounterLiveBroadcastSnippet < 3) {
    unittest.expect(
      o.actualEndTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.actualStartTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDefaultBroadcast!, unittest.isTrue);
    unittest.expect(
      o.liveChatId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.scheduledEndTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.scheduledStartTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveBroadcastSnippet--;
}

core.int buildCounterLiveBroadcastStatistics = 0;
api.LiveBroadcastStatistics buildLiveBroadcastStatistics() {
  var o = api.LiveBroadcastStatistics();
  buildCounterLiveBroadcastStatistics++;
  if (buildCounterLiveBroadcastStatistics < 3) {
    o.totalChatCount = 'foo';
  }
  buildCounterLiveBroadcastStatistics--;
  return o;
}

void checkLiveBroadcastStatistics(api.LiveBroadcastStatistics o) {
  buildCounterLiveBroadcastStatistics++;
  if (buildCounterLiveBroadcastStatistics < 3) {
    unittest.expect(
      o.totalChatCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveBroadcastStatistics--;
}

core.int buildCounterLiveBroadcastStatus = 0;
api.LiveBroadcastStatus buildLiveBroadcastStatus() {
  var o = api.LiveBroadcastStatus();
  buildCounterLiveBroadcastStatus++;
  if (buildCounterLiveBroadcastStatus < 3) {
    o.lifeCycleStatus = 'foo';
    o.liveBroadcastPriority = 'foo';
    o.madeForKids = true;
    o.privacyStatus = 'foo';
    o.recordingStatus = 'foo';
    o.selfDeclaredMadeForKids = true;
  }
  buildCounterLiveBroadcastStatus--;
  return o;
}

void checkLiveBroadcastStatus(api.LiveBroadcastStatus o) {
  buildCounterLiveBroadcastStatus++;
  if (buildCounterLiveBroadcastStatus < 3) {
    unittest.expect(
      o.lifeCycleStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.liveBroadcastPriority!,
      unittest.equals('foo'),
    );
    unittest.expect(o.madeForKids!, unittest.isTrue);
    unittest.expect(
      o.privacyStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recordingStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(o.selfDeclaredMadeForKids!, unittest.isTrue);
  }
  buildCounterLiveBroadcastStatus--;
}

core.int buildCounterLiveChatBan = 0;
api.LiveChatBan buildLiveChatBan() {
  var o = api.LiveChatBan();
  buildCounterLiveChatBan++;
  if (buildCounterLiveChatBan < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildLiveChatBanSnippet();
  }
  buildCounterLiveChatBan--;
  return o;
}

void checkLiveChatBan(api.LiveChatBan o) {
  buildCounterLiveChatBan++;
  if (buildCounterLiveChatBan < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLiveChatBanSnippet(o.snippet! as api.LiveChatBanSnippet);
  }
  buildCounterLiveChatBan--;
}

core.int buildCounterLiveChatBanSnippet = 0;
api.LiveChatBanSnippet buildLiveChatBanSnippet() {
  var o = api.LiveChatBanSnippet();
  buildCounterLiveChatBanSnippet++;
  if (buildCounterLiveChatBanSnippet < 3) {
    o.banDurationSeconds = 'foo';
    o.bannedUserDetails = buildChannelProfileDetails();
    o.liveChatId = 'foo';
    o.type = 'foo';
  }
  buildCounterLiveChatBanSnippet--;
  return o;
}

void checkLiveChatBanSnippet(api.LiveChatBanSnippet o) {
  buildCounterLiveChatBanSnippet++;
  if (buildCounterLiveChatBanSnippet < 3) {
    unittest.expect(
      o.banDurationSeconds!,
      unittest.equals('foo'),
    );
    checkChannelProfileDetails(
        o.bannedUserDetails! as api.ChannelProfileDetails);
    unittest.expect(
      o.liveChatId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatBanSnippet--;
}

core.int buildCounterLiveChatFanFundingEventDetails = 0;
api.LiveChatFanFundingEventDetails buildLiveChatFanFundingEventDetails() {
  var o = api.LiveChatFanFundingEventDetails();
  buildCounterLiveChatFanFundingEventDetails++;
  if (buildCounterLiveChatFanFundingEventDetails < 3) {
    o.amountDisplayString = 'foo';
    o.amountMicros = 'foo';
    o.currency = 'foo';
    o.userComment = 'foo';
  }
  buildCounterLiveChatFanFundingEventDetails--;
  return o;
}

void checkLiveChatFanFundingEventDetails(api.LiveChatFanFundingEventDetails o) {
  buildCounterLiveChatFanFundingEventDetails++;
  if (buildCounterLiveChatFanFundingEventDetails < 3) {
    unittest.expect(
      o.amountDisplayString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.amountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userComment!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatFanFundingEventDetails--;
}

core.int buildCounterLiveChatMessage = 0;
api.LiveChatMessage buildLiveChatMessage() {
  var o = api.LiveChatMessage();
  buildCounterLiveChatMessage++;
  if (buildCounterLiveChatMessage < 3) {
    o.authorDetails = buildLiveChatMessageAuthorDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildLiveChatMessageSnippet();
  }
  buildCounterLiveChatMessage--;
  return o;
}

void checkLiveChatMessage(api.LiveChatMessage o) {
  buildCounterLiveChatMessage++;
  if (buildCounterLiveChatMessage < 3) {
    checkLiveChatMessageAuthorDetails(
        o.authorDetails! as api.LiveChatMessageAuthorDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLiveChatMessageSnippet(o.snippet! as api.LiveChatMessageSnippet);
  }
  buildCounterLiveChatMessage--;
}

core.int buildCounterLiveChatMessageAuthorDetails = 0;
api.LiveChatMessageAuthorDetails buildLiveChatMessageAuthorDetails() {
  var o = api.LiveChatMessageAuthorDetails();
  buildCounterLiveChatMessageAuthorDetails++;
  if (buildCounterLiveChatMessageAuthorDetails < 3) {
    o.channelId = 'foo';
    o.channelUrl = 'foo';
    o.displayName = 'foo';
    o.isChatModerator = true;
    o.isChatOwner = true;
    o.isChatSponsor = true;
    o.isVerified = true;
    o.profileImageUrl = 'foo';
  }
  buildCounterLiveChatMessageAuthorDetails--;
  return o;
}

void checkLiveChatMessageAuthorDetails(api.LiveChatMessageAuthorDetails o) {
  buildCounterLiveChatMessageAuthorDetails++;
  if (buildCounterLiveChatMessageAuthorDetails < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isChatModerator!, unittest.isTrue);
    unittest.expect(o.isChatOwner!, unittest.isTrue);
    unittest.expect(o.isChatSponsor!, unittest.isTrue);
    unittest.expect(o.isVerified!, unittest.isTrue);
    unittest.expect(
      o.profileImageUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatMessageAuthorDetails--;
}

core.int buildCounterLiveChatMessageDeletedDetails = 0;
api.LiveChatMessageDeletedDetails buildLiveChatMessageDeletedDetails() {
  var o = api.LiveChatMessageDeletedDetails();
  buildCounterLiveChatMessageDeletedDetails++;
  if (buildCounterLiveChatMessageDeletedDetails < 3) {
    o.deletedMessageId = 'foo';
  }
  buildCounterLiveChatMessageDeletedDetails--;
  return o;
}

void checkLiveChatMessageDeletedDetails(api.LiveChatMessageDeletedDetails o) {
  buildCounterLiveChatMessageDeletedDetails++;
  if (buildCounterLiveChatMessageDeletedDetails < 3) {
    unittest.expect(
      o.deletedMessageId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatMessageDeletedDetails--;
}

core.List<api.LiveChatMessage> buildUnnamed2970() {
  var o = <api.LiveChatMessage>[];
  o.add(buildLiveChatMessage());
  o.add(buildLiveChatMessage());
  return o;
}

void checkUnnamed2970(core.List<api.LiveChatMessage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLiveChatMessage(o[0] as api.LiveChatMessage);
  checkLiveChatMessage(o[1] as api.LiveChatMessage);
}

core.int buildCounterLiveChatMessageListResponse = 0;
api.LiveChatMessageListResponse buildLiveChatMessageListResponse() {
  var o = api.LiveChatMessageListResponse();
  buildCounterLiveChatMessageListResponse++;
  if (buildCounterLiveChatMessageListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2970();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.offlineAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.pageInfo = buildPageInfo();
    o.pollingIntervalMillis = 42;
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterLiveChatMessageListResponse--;
  return o;
}

void checkLiveChatMessageListResponse(api.LiveChatMessageListResponse o) {
  buildCounterLiveChatMessageListResponse++;
  if (buildCounterLiveChatMessageListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2970(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.offlineAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.pollingIntervalMillis!,
      unittest.equals(42),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatMessageListResponse--;
}

core.int buildCounterLiveChatMessageRetractedDetails = 0;
api.LiveChatMessageRetractedDetails buildLiveChatMessageRetractedDetails() {
  var o = api.LiveChatMessageRetractedDetails();
  buildCounterLiveChatMessageRetractedDetails++;
  if (buildCounterLiveChatMessageRetractedDetails < 3) {
    o.retractedMessageId = 'foo';
  }
  buildCounterLiveChatMessageRetractedDetails--;
  return o;
}

void checkLiveChatMessageRetractedDetails(
    api.LiveChatMessageRetractedDetails o) {
  buildCounterLiveChatMessageRetractedDetails++;
  if (buildCounterLiveChatMessageRetractedDetails < 3) {
    unittest.expect(
      o.retractedMessageId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatMessageRetractedDetails--;
}

core.int buildCounterLiveChatMessageSnippet = 0;
api.LiveChatMessageSnippet buildLiveChatMessageSnippet() {
  var o = api.LiveChatMessageSnippet();
  buildCounterLiveChatMessageSnippet++;
  if (buildCounterLiveChatMessageSnippet < 3) {
    o.authorChannelId = 'foo';
    o.displayMessage = 'foo';
    o.fanFundingEventDetails = buildLiveChatFanFundingEventDetails();
    o.hasDisplayContent = true;
    o.liveChatId = 'foo';
    o.messageDeletedDetails = buildLiveChatMessageDeletedDetails();
    o.messageRetractedDetails = buildLiveChatMessageRetractedDetails();
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.superChatDetails = buildLiveChatSuperChatDetails();
    o.superStickerDetails = buildLiveChatSuperStickerDetails();
    o.textMessageDetails = buildLiveChatTextMessageDetails();
    o.type = 'foo';
    o.userBannedDetails = buildLiveChatUserBannedMessageDetails();
  }
  buildCounterLiveChatMessageSnippet--;
  return o;
}

void checkLiveChatMessageSnippet(api.LiveChatMessageSnippet o) {
  buildCounterLiveChatMessageSnippet++;
  if (buildCounterLiveChatMessageSnippet < 3) {
    unittest.expect(
      o.authorChannelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayMessage!,
      unittest.equals('foo'),
    );
    checkLiveChatFanFundingEventDetails(
        o.fanFundingEventDetails! as api.LiveChatFanFundingEventDetails);
    unittest.expect(o.hasDisplayContent!, unittest.isTrue);
    unittest.expect(
      o.liveChatId!,
      unittest.equals('foo'),
    );
    checkLiveChatMessageDeletedDetails(
        o.messageDeletedDetails! as api.LiveChatMessageDeletedDetails);
    checkLiveChatMessageRetractedDetails(
        o.messageRetractedDetails! as api.LiveChatMessageRetractedDetails);
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkLiveChatSuperChatDetails(
        o.superChatDetails! as api.LiveChatSuperChatDetails);
    checkLiveChatSuperStickerDetails(
        o.superStickerDetails! as api.LiveChatSuperStickerDetails);
    checkLiveChatTextMessageDetails(
        o.textMessageDetails! as api.LiveChatTextMessageDetails);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkLiveChatUserBannedMessageDetails(
        o.userBannedDetails! as api.LiveChatUserBannedMessageDetails);
  }
  buildCounterLiveChatMessageSnippet--;
}

core.int buildCounterLiveChatModerator = 0;
api.LiveChatModerator buildLiveChatModerator() {
  var o = api.LiveChatModerator();
  buildCounterLiveChatModerator++;
  if (buildCounterLiveChatModerator < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildLiveChatModeratorSnippet();
  }
  buildCounterLiveChatModerator--;
  return o;
}

void checkLiveChatModerator(api.LiveChatModerator o) {
  buildCounterLiveChatModerator++;
  if (buildCounterLiveChatModerator < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLiveChatModeratorSnippet(o.snippet! as api.LiveChatModeratorSnippet);
  }
  buildCounterLiveChatModerator--;
}

core.List<api.LiveChatModerator> buildUnnamed2971() {
  var o = <api.LiveChatModerator>[];
  o.add(buildLiveChatModerator());
  o.add(buildLiveChatModerator());
  return o;
}

void checkUnnamed2971(core.List<api.LiveChatModerator> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLiveChatModerator(o[0] as api.LiveChatModerator);
  checkLiveChatModerator(o[1] as api.LiveChatModerator);
}

core.int buildCounterLiveChatModeratorListResponse = 0;
api.LiveChatModeratorListResponse buildLiveChatModeratorListResponse() {
  var o = api.LiveChatModeratorListResponse();
  buildCounterLiveChatModeratorListResponse++;
  if (buildCounterLiveChatModeratorListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2971();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterLiveChatModeratorListResponse--;
  return o;
}

void checkLiveChatModeratorListResponse(api.LiveChatModeratorListResponse o) {
  buildCounterLiveChatModeratorListResponse++;
  if (buildCounterLiveChatModeratorListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2971(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatModeratorListResponse--;
}

core.int buildCounterLiveChatModeratorSnippet = 0;
api.LiveChatModeratorSnippet buildLiveChatModeratorSnippet() {
  var o = api.LiveChatModeratorSnippet();
  buildCounterLiveChatModeratorSnippet++;
  if (buildCounterLiveChatModeratorSnippet < 3) {
    o.liveChatId = 'foo';
    o.moderatorDetails = buildChannelProfileDetails();
  }
  buildCounterLiveChatModeratorSnippet--;
  return o;
}

void checkLiveChatModeratorSnippet(api.LiveChatModeratorSnippet o) {
  buildCounterLiveChatModeratorSnippet++;
  if (buildCounterLiveChatModeratorSnippet < 3) {
    unittest.expect(
      o.liveChatId!,
      unittest.equals('foo'),
    );
    checkChannelProfileDetails(
        o.moderatorDetails! as api.ChannelProfileDetails);
  }
  buildCounterLiveChatModeratorSnippet--;
}

core.int buildCounterLiveChatSuperChatDetails = 0;
api.LiveChatSuperChatDetails buildLiveChatSuperChatDetails() {
  var o = api.LiveChatSuperChatDetails();
  buildCounterLiveChatSuperChatDetails++;
  if (buildCounterLiveChatSuperChatDetails < 3) {
    o.amountDisplayString = 'foo';
    o.amountMicros = 'foo';
    o.currency = 'foo';
    o.tier = 42;
    o.userComment = 'foo';
  }
  buildCounterLiveChatSuperChatDetails--;
  return o;
}

void checkLiveChatSuperChatDetails(api.LiveChatSuperChatDetails o) {
  buildCounterLiveChatSuperChatDetails++;
  if (buildCounterLiveChatSuperChatDetails < 3) {
    unittest.expect(
      o.amountDisplayString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.amountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tier!,
      unittest.equals(42),
    );
    unittest.expect(
      o.userComment!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatSuperChatDetails--;
}

core.int buildCounterLiveChatSuperStickerDetails = 0;
api.LiveChatSuperStickerDetails buildLiveChatSuperStickerDetails() {
  var o = api.LiveChatSuperStickerDetails();
  buildCounterLiveChatSuperStickerDetails++;
  if (buildCounterLiveChatSuperStickerDetails < 3) {
    o.amountDisplayString = 'foo';
    o.amountMicros = 'foo';
    o.currency = 'foo';
    o.superStickerMetadata = buildSuperStickerMetadata();
    o.tier = 42;
  }
  buildCounterLiveChatSuperStickerDetails--;
  return o;
}

void checkLiveChatSuperStickerDetails(api.LiveChatSuperStickerDetails o) {
  buildCounterLiveChatSuperStickerDetails++;
  if (buildCounterLiveChatSuperStickerDetails < 3) {
    unittest.expect(
      o.amountDisplayString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.amountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currency!,
      unittest.equals('foo'),
    );
    checkSuperStickerMetadata(
        o.superStickerMetadata! as api.SuperStickerMetadata);
    unittest.expect(
      o.tier!,
      unittest.equals(42),
    );
  }
  buildCounterLiveChatSuperStickerDetails--;
}

core.int buildCounterLiveChatTextMessageDetails = 0;
api.LiveChatTextMessageDetails buildLiveChatTextMessageDetails() {
  var o = api.LiveChatTextMessageDetails();
  buildCounterLiveChatTextMessageDetails++;
  if (buildCounterLiveChatTextMessageDetails < 3) {
    o.messageText = 'foo';
  }
  buildCounterLiveChatTextMessageDetails--;
  return o;
}

void checkLiveChatTextMessageDetails(api.LiveChatTextMessageDetails o) {
  buildCounterLiveChatTextMessageDetails++;
  if (buildCounterLiveChatTextMessageDetails < 3) {
    unittest.expect(
      o.messageText!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveChatTextMessageDetails--;
}

core.int buildCounterLiveChatUserBannedMessageDetails = 0;
api.LiveChatUserBannedMessageDetails buildLiveChatUserBannedMessageDetails() {
  var o = api.LiveChatUserBannedMessageDetails();
  buildCounterLiveChatUserBannedMessageDetails++;
  if (buildCounterLiveChatUserBannedMessageDetails < 3) {
    o.banDurationSeconds = 'foo';
    o.banType = 'foo';
    o.bannedUserDetails = buildChannelProfileDetails();
  }
  buildCounterLiveChatUserBannedMessageDetails--;
  return o;
}

void checkLiveChatUserBannedMessageDetails(
    api.LiveChatUserBannedMessageDetails o) {
  buildCounterLiveChatUserBannedMessageDetails++;
  if (buildCounterLiveChatUserBannedMessageDetails < 3) {
    unittest.expect(
      o.banDurationSeconds!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.banType!,
      unittest.equals('foo'),
    );
    checkChannelProfileDetails(
        o.bannedUserDetails! as api.ChannelProfileDetails);
  }
  buildCounterLiveChatUserBannedMessageDetails--;
}

core.int buildCounterLiveStream = 0;
api.LiveStream buildLiveStream() {
  var o = api.LiveStream();
  buildCounterLiveStream++;
  if (buildCounterLiveStream < 3) {
    o.cdn = buildCdnSettings();
    o.contentDetails = buildLiveStreamContentDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildLiveStreamSnippet();
    o.status = buildLiveStreamStatus();
  }
  buildCounterLiveStream--;
  return o;
}

void checkLiveStream(api.LiveStream o) {
  buildCounterLiveStream++;
  if (buildCounterLiveStream < 3) {
    checkCdnSettings(o.cdn! as api.CdnSettings);
    checkLiveStreamContentDetails(
        o.contentDetails! as api.LiveStreamContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLiveStreamSnippet(o.snippet! as api.LiveStreamSnippet);
    checkLiveStreamStatus(o.status! as api.LiveStreamStatus);
  }
  buildCounterLiveStream--;
}

core.int buildCounterLiveStreamConfigurationIssue = 0;
api.LiveStreamConfigurationIssue buildLiveStreamConfigurationIssue() {
  var o = api.LiveStreamConfigurationIssue();
  buildCounterLiveStreamConfigurationIssue++;
  if (buildCounterLiveStreamConfigurationIssue < 3) {
    o.description = 'foo';
    o.reason = 'foo';
    o.severity = 'foo';
    o.type = 'foo';
  }
  buildCounterLiveStreamConfigurationIssue--;
  return o;
}

void checkLiveStreamConfigurationIssue(api.LiveStreamConfigurationIssue o) {
  buildCounterLiveStreamConfigurationIssue++;
  if (buildCounterLiveStreamConfigurationIssue < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveStreamConfigurationIssue--;
}

core.int buildCounterLiveStreamContentDetails = 0;
api.LiveStreamContentDetails buildLiveStreamContentDetails() {
  var o = api.LiveStreamContentDetails();
  buildCounterLiveStreamContentDetails++;
  if (buildCounterLiveStreamContentDetails < 3) {
    o.closedCaptionsIngestionUrl = 'foo';
    o.isReusable = true;
  }
  buildCounterLiveStreamContentDetails--;
  return o;
}

void checkLiveStreamContentDetails(api.LiveStreamContentDetails o) {
  buildCounterLiveStreamContentDetails++;
  if (buildCounterLiveStreamContentDetails < 3) {
    unittest.expect(
      o.closedCaptionsIngestionUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isReusable!, unittest.isTrue);
  }
  buildCounterLiveStreamContentDetails--;
}

core.List<api.LiveStreamConfigurationIssue> buildUnnamed2972() {
  var o = <api.LiveStreamConfigurationIssue>[];
  o.add(buildLiveStreamConfigurationIssue());
  o.add(buildLiveStreamConfigurationIssue());
  return o;
}

void checkUnnamed2972(core.List<api.LiveStreamConfigurationIssue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLiveStreamConfigurationIssue(o[0] as api.LiveStreamConfigurationIssue);
  checkLiveStreamConfigurationIssue(o[1] as api.LiveStreamConfigurationIssue);
}

core.int buildCounterLiveStreamHealthStatus = 0;
api.LiveStreamHealthStatus buildLiveStreamHealthStatus() {
  var o = api.LiveStreamHealthStatus();
  buildCounterLiveStreamHealthStatus++;
  if (buildCounterLiveStreamHealthStatus < 3) {
    o.configurationIssues = buildUnnamed2972();
    o.lastUpdateTimeSeconds = 'foo';
    o.status = 'foo';
  }
  buildCounterLiveStreamHealthStatus--;
  return o;
}

void checkLiveStreamHealthStatus(api.LiveStreamHealthStatus o) {
  buildCounterLiveStreamHealthStatus++;
  if (buildCounterLiveStreamHealthStatus < 3) {
    checkUnnamed2972(o.configurationIssues!);
    unittest.expect(
      o.lastUpdateTimeSeconds!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveStreamHealthStatus--;
}

core.List<api.LiveStream> buildUnnamed2973() {
  var o = <api.LiveStream>[];
  o.add(buildLiveStream());
  o.add(buildLiveStream());
  return o;
}

void checkUnnamed2973(core.List<api.LiveStream> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLiveStream(o[0] as api.LiveStream);
  checkLiveStream(o[1] as api.LiveStream);
}

core.int buildCounterLiveStreamListResponse = 0;
api.LiveStreamListResponse buildLiveStreamListResponse() {
  var o = api.LiveStreamListResponse();
  buildCounterLiveStreamListResponse++;
  if (buildCounterLiveStreamListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2973();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterLiveStreamListResponse--;
  return o;
}

void checkLiveStreamListResponse(api.LiveStreamListResponse o) {
  buildCounterLiveStreamListResponse++;
  if (buildCounterLiveStreamListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2973(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveStreamListResponse--;
}

core.int buildCounterLiveStreamSnippet = 0;
api.LiveStreamSnippet buildLiveStreamSnippet() {
  var o = api.LiveStreamSnippet();
  buildCounterLiveStreamSnippet++;
  if (buildCounterLiveStreamSnippet < 3) {
    o.channelId = 'foo';
    o.description = 'foo';
    o.isDefaultStream = true;
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.title = 'foo';
  }
  buildCounterLiveStreamSnippet--;
  return o;
}

void checkLiveStreamSnippet(api.LiveStreamSnippet o) {
  buildCounterLiveStreamSnippet++;
  if (buildCounterLiveStreamSnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDefaultStream!, unittest.isTrue);
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveStreamSnippet--;
}

core.int buildCounterLiveStreamStatus = 0;
api.LiveStreamStatus buildLiveStreamStatus() {
  var o = api.LiveStreamStatus();
  buildCounterLiveStreamStatus++;
  if (buildCounterLiveStreamStatus < 3) {
    o.healthStatus = buildLiveStreamHealthStatus();
    o.streamStatus = 'foo';
  }
  buildCounterLiveStreamStatus--;
  return o;
}

void checkLiveStreamStatus(api.LiveStreamStatus o) {
  buildCounterLiveStreamStatus++;
  if (buildCounterLiveStreamStatus < 3) {
    checkLiveStreamHealthStatus(o.healthStatus! as api.LiveStreamHealthStatus);
    unittest.expect(
      o.streamStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterLiveStreamStatus--;
}

core.List<api.LocalizedString> buildUnnamed2974() {
  var o = <api.LocalizedString>[];
  o.add(buildLocalizedString());
  o.add(buildLocalizedString());
  return o;
}

void checkUnnamed2974(core.List<api.LocalizedString> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocalizedString(o[0] as api.LocalizedString);
  checkLocalizedString(o[1] as api.LocalizedString);
}

core.int buildCounterLocalizedProperty = 0;
api.LocalizedProperty buildLocalizedProperty() {
  var o = api.LocalizedProperty();
  buildCounterLocalizedProperty++;
  if (buildCounterLocalizedProperty < 3) {
    o.default_ = 'foo';
    o.defaultLanguage = buildLanguageTag();
    o.localized = buildUnnamed2974();
  }
  buildCounterLocalizedProperty--;
  return o;
}

void checkLocalizedProperty(api.LocalizedProperty o) {
  buildCounterLocalizedProperty++;
  if (buildCounterLocalizedProperty < 3) {
    unittest.expect(
      o.default_!,
      unittest.equals('foo'),
    );
    checkLanguageTag(o.defaultLanguage! as api.LanguageTag);
    checkUnnamed2974(o.localized!);
  }
  buildCounterLocalizedProperty--;
}

core.int buildCounterLocalizedString = 0;
api.LocalizedString buildLocalizedString() {
  var o = api.LocalizedString();
  buildCounterLocalizedString++;
  if (buildCounterLocalizedString < 3) {
    o.language = 'foo';
    o.value = 'foo';
  }
  buildCounterLocalizedString--;
  return o;
}

void checkLocalizedString(api.LocalizedString o) {
  buildCounterLocalizedString++;
  if (buildCounterLocalizedString < 3) {
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocalizedString--;
}

core.int buildCounterMember = 0;
api.Member buildMember() {
  var o = api.Member();
  buildCounterMember++;
  if (buildCounterMember < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.snippet = buildMemberSnippet();
  }
  buildCounterMember--;
  return o;
}

void checkMember(api.Member o) {
  buildCounterMember++;
  if (buildCounterMember < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkMemberSnippet(o.snippet! as api.MemberSnippet);
  }
  buildCounterMember--;
}

core.List<api.Member> buildUnnamed2975() {
  var o = <api.Member>[];
  o.add(buildMember());
  o.add(buildMember());
  return o;
}

void checkUnnamed2975(core.List<api.Member> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMember(o[0] as api.Member);
  checkMember(o[1] as api.Member);
}

core.int buildCounterMemberListResponse = 0;
api.MemberListResponse buildMemberListResponse() {
  var o = api.MemberListResponse();
  buildCounterMemberListResponse++;
  if (buildCounterMemberListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2975();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterMemberListResponse--;
  return o;
}

void checkMemberListResponse(api.MemberListResponse o) {
  buildCounterMemberListResponse++;
  if (buildCounterMemberListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2975(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterMemberListResponse--;
}

core.int buildCounterMemberSnippet = 0;
api.MemberSnippet buildMemberSnippet() {
  var o = api.MemberSnippet();
  buildCounterMemberSnippet++;
  if (buildCounterMemberSnippet < 3) {
    o.creatorChannelId = 'foo';
    o.memberDetails = buildChannelProfileDetails();
    o.membershipsDetails = buildMembershipsDetails();
  }
  buildCounterMemberSnippet--;
  return o;
}

void checkMemberSnippet(api.MemberSnippet o) {
  buildCounterMemberSnippet++;
  if (buildCounterMemberSnippet < 3) {
    unittest.expect(
      o.creatorChannelId!,
      unittest.equals('foo'),
    );
    checkChannelProfileDetails(o.memberDetails! as api.ChannelProfileDetails);
    checkMembershipsDetails(o.membershipsDetails! as api.MembershipsDetails);
  }
  buildCounterMemberSnippet--;
}

core.List<core.String> buildUnnamed2976() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2976(core.List<core.String> o) {
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

core.List<api.MembershipsDurationAtLevel> buildUnnamed2977() {
  var o = <api.MembershipsDurationAtLevel>[];
  o.add(buildMembershipsDurationAtLevel());
  o.add(buildMembershipsDurationAtLevel());
  return o;
}

void checkUnnamed2977(core.List<api.MembershipsDurationAtLevel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMembershipsDurationAtLevel(o[0] as api.MembershipsDurationAtLevel);
  checkMembershipsDurationAtLevel(o[1] as api.MembershipsDurationAtLevel);
}

core.int buildCounterMembershipsDetails = 0;
api.MembershipsDetails buildMembershipsDetails() {
  var o = api.MembershipsDetails();
  buildCounterMembershipsDetails++;
  if (buildCounterMembershipsDetails < 3) {
    o.accessibleLevels = buildUnnamed2976();
    o.highestAccessibleLevel = 'foo';
    o.highestAccessibleLevelDisplayName = 'foo';
    o.membershipsDuration = buildMembershipsDuration();
    o.membershipsDurationAtLevels = buildUnnamed2977();
  }
  buildCounterMembershipsDetails--;
  return o;
}

void checkMembershipsDetails(api.MembershipsDetails o) {
  buildCounterMembershipsDetails++;
  if (buildCounterMembershipsDetails < 3) {
    checkUnnamed2976(o.accessibleLevels!);
    unittest.expect(
      o.highestAccessibleLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.highestAccessibleLevelDisplayName!,
      unittest.equals('foo'),
    );
    checkMembershipsDuration(o.membershipsDuration! as api.MembershipsDuration);
    checkUnnamed2977(o.membershipsDurationAtLevels!);
  }
  buildCounterMembershipsDetails--;
}

core.int buildCounterMembershipsDuration = 0;
api.MembershipsDuration buildMembershipsDuration() {
  var o = api.MembershipsDuration();
  buildCounterMembershipsDuration++;
  if (buildCounterMembershipsDuration < 3) {
    o.memberSince = 'foo';
    o.memberTotalDurationMonths = 42;
  }
  buildCounterMembershipsDuration--;
  return o;
}

void checkMembershipsDuration(api.MembershipsDuration o) {
  buildCounterMembershipsDuration++;
  if (buildCounterMembershipsDuration < 3) {
    unittest.expect(
      o.memberSince!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memberTotalDurationMonths!,
      unittest.equals(42),
    );
  }
  buildCounterMembershipsDuration--;
}

core.int buildCounterMembershipsDurationAtLevel = 0;
api.MembershipsDurationAtLevel buildMembershipsDurationAtLevel() {
  var o = api.MembershipsDurationAtLevel();
  buildCounterMembershipsDurationAtLevel++;
  if (buildCounterMembershipsDurationAtLevel < 3) {
    o.level = 'foo';
    o.memberSince = 'foo';
    o.memberTotalDurationMonths = 42;
  }
  buildCounterMembershipsDurationAtLevel--;
  return o;
}

void checkMembershipsDurationAtLevel(api.MembershipsDurationAtLevel o) {
  buildCounterMembershipsDurationAtLevel++;
  if (buildCounterMembershipsDurationAtLevel < 3) {
    unittest.expect(
      o.level!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memberSince!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memberTotalDurationMonths!,
      unittest.equals(42),
    );
  }
  buildCounterMembershipsDurationAtLevel--;
}

core.int buildCounterMembershipsLevel = 0;
api.MembershipsLevel buildMembershipsLevel() {
  var o = api.MembershipsLevel();
  buildCounterMembershipsLevel++;
  if (buildCounterMembershipsLevel < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildMembershipsLevelSnippet();
  }
  buildCounterMembershipsLevel--;
  return o;
}

void checkMembershipsLevel(api.MembershipsLevel o) {
  buildCounterMembershipsLevel++;
  if (buildCounterMembershipsLevel < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkMembershipsLevelSnippet(o.snippet! as api.MembershipsLevelSnippet);
  }
  buildCounterMembershipsLevel--;
}

core.List<api.MembershipsLevel> buildUnnamed2978() {
  var o = <api.MembershipsLevel>[];
  o.add(buildMembershipsLevel());
  o.add(buildMembershipsLevel());
  return o;
}

void checkUnnamed2978(core.List<api.MembershipsLevel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMembershipsLevel(o[0] as api.MembershipsLevel);
  checkMembershipsLevel(o[1] as api.MembershipsLevel);
}

core.int buildCounterMembershipsLevelListResponse = 0;
api.MembershipsLevelListResponse buildMembershipsLevelListResponse() {
  var o = api.MembershipsLevelListResponse();
  buildCounterMembershipsLevelListResponse++;
  if (buildCounterMembershipsLevelListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2978();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterMembershipsLevelListResponse--;
  return o;
}

void checkMembershipsLevelListResponse(api.MembershipsLevelListResponse o) {
  buildCounterMembershipsLevelListResponse++;
  if (buildCounterMembershipsLevelListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2978(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterMembershipsLevelListResponse--;
}

core.int buildCounterMembershipsLevelSnippet = 0;
api.MembershipsLevelSnippet buildMembershipsLevelSnippet() {
  var o = api.MembershipsLevelSnippet();
  buildCounterMembershipsLevelSnippet++;
  if (buildCounterMembershipsLevelSnippet < 3) {
    o.creatorChannelId = 'foo';
    o.levelDetails = buildLevelDetails();
  }
  buildCounterMembershipsLevelSnippet--;
  return o;
}

void checkMembershipsLevelSnippet(api.MembershipsLevelSnippet o) {
  buildCounterMembershipsLevelSnippet++;
  if (buildCounterMembershipsLevelSnippet < 3) {
    unittest.expect(
      o.creatorChannelId!,
      unittest.equals('foo'),
    );
    checkLevelDetails(o.levelDetails! as api.LevelDetails);
  }
  buildCounterMembershipsLevelSnippet--;
}

core.int buildCounterMonitorStreamInfo = 0;
api.MonitorStreamInfo buildMonitorStreamInfo() {
  var o = api.MonitorStreamInfo();
  buildCounterMonitorStreamInfo++;
  if (buildCounterMonitorStreamInfo < 3) {
    o.broadcastStreamDelayMs = 42;
    o.embedHtml = 'foo';
    o.enableMonitorStream = true;
  }
  buildCounterMonitorStreamInfo--;
  return o;
}

void checkMonitorStreamInfo(api.MonitorStreamInfo o) {
  buildCounterMonitorStreamInfo++;
  if (buildCounterMonitorStreamInfo < 3) {
    unittest.expect(
      o.broadcastStreamDelayMs!,
      unittest.equals(42),
    );
    unittest.expect(
      o.embedHtml!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableMonitorStream!, unittest.isTrue);
  }
  buildCounterMonitorStreamInfo--;
}

core.int buildCounterPageInfo = 0;
api.PageInfo buildPageInfo() {
  var o = api.PageInfo();
  buildCounterPageInfo++;
  if (buildCounterPageInfo < 3) {
    o.resultsPerPage = 42;
    o.totalResults = 42;
  }
  buildCounterPageInfo--;
  return o;
}

void checkPageInfo(api.PageInfo o) {
  buildCounterPageInfo++;
  if (buildCounterPageInfo < 3) {
    unittest.expect(
      o.resultsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
  }
  buildCounterPageInfo--;
}

core.Map<core.String, api.PlaylistLocalization> buildUnnamed2979() {
  var o = <core.String, api.PlaylistLocalization>{};
  o['x'] = buildPlaylistLocalization();
  o['y'] = buildPlaylistLocalization();
  return o;
}

void checkUnnamed2979(core.Map<core.String, api.PlaylistLocalization> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlaylistLocalization(o['x']! as api.PlaylistLocalization);
  checkPlaylistLocalization(o['y']! as api.PlaylistLocalization);
}

core.int buildCounterPlaylist = 0;
api.Playlist buildPlaylist() {
  var o = api.Playlist();
  buildCounterPlaylist++;
  if (buildCounterPlaylist < 3) {
    o.contentDetails = buildPlaylistContentDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.localizations = buildUnnamed2979();
    o.player = buildPlaylistPlayer();
    o.snippet = buildPlaylistSnippet();
    o.status = buildPlaylistStatus();
  }
  buildCounterPlaylist--;
  return o;
}

void checkPlaylist(api.Playlist o) {
  buildCounterPlaylist++;
  if (buildCounterPlaylist < 3) {
    checkPlaylistContentDetails(
        o.contentDetails! as api.PlaylistContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2979(o.localizations!);
    checkPlaylistPlayer(o.player! as api.PlaylistPlayer);
    checkPlaylistSnippet(o.snippet! as api.PlaylistSnippet);
    checkPlaylistStatus(o.status! as api.PlaylistStatus);
  }
  buildCounterPlaylist--;
}

core.int buildCounterPlaylistContentDetails = 0;
api.PlaylistContentDetails buildPlaylistContentDetails() {
  var o = api.PlaylistContentDetails();
  buildCounterPlaylistContentDetails++;
  if (buildCounterPlaylistContentDetails < 3) {
    o.itemCount = 42;
  }
  buildCounterPlaylistContentDetails--;
  return o;
}

void checkPlaylistContentDetails(api.PlaylistContentDetails o) {
  buildCounterPlaylistContentDetails++;
  if (buildCounterPlaylistContentDetails < 3) {
    unittest.expect(
      o.itemCount!,
      unittest.equals(42),
    );
  }
  buildCounterPlaylistContentDetails--;
}

core.int buildCounterPlaylistItem = 0;
api.PlaylistItem buildPlaylistItem() {
  var o = api.PlaylistItem();
  buildCounterPlaylistItem++;
  if (buildCounterPlaylistItem < 3) {
    o.contentDetails = buildPlaylistItemContentDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildPlaylistItemSnippet();
    o.status = buildPlaylistItemStatus();
  }
  buildCounterPlaylistItem--;
  return o;
}

void checkPlaylistItem(api.PlaylistItem o) {
  buildCounterPlaylistItem++;
  if (buildCounterPlaylistItem < 3) {
    checkPlaylistItemContentDetails(
        o.contentDetails! as api.PlaylistItemContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkPlaylistItemSnippet(o.snippet! as api.PlaylistItemSnippet);
    checkPlaylistItemStatus(o.status! as api.PlaylistItemStatus);
  }
  buildCounterPlaylistItem--;
}

core.int buildCounterPlaylistItemContentDetails = 0;
api.PlaylistItemContentDetails buildPlaylistItemContentDetails() {
  var o = api.PlaylistItemContentDetails();
  buildCounterPlaylistItemContentDetails++;
  if (buildCounterPlaylistItemContentDetails < 3) {
    o.endAt = 'foo';
    o.note = 'foo';
    o.startAt = 'foo';
    o.videoId = 'foo';
    o.videoPublishedAt = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterPlaylistItemContentDetails--;
  return o;
}

void checkPlaylistItemContentDetails(api.PlaylistItemContentDetails o) {
  buildCounterPlaylistItemContentDetails++;
  if (buildCounterPlaylistItemContentDetails < 3) {
    unittest.expect(
      o.endAt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.note!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startAt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoPublishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterPlaylistItemContentDetails--;
}

core.List<api.PlaylistItem> buildUnnamed2980() {
  var o = <api.PlaylistItem>[];
  o.add(buildPlaylistItem());
  o.add(buildPlaylistItem());
  return o;
}

void checkUnnamed2980(core.List<api.PlaylistItem> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlaylistItem(o[0] as api.PlaylistItem);
  checkPlaylistItem(o[1] as api.PlaylistItem);
}

core.int buildCounterPlaylistItemListResponse = 0;
api.PlaylistItemListResponse buildPlaylistItemListResponse() {
  var o = api.PlaylistItemListResponse();
  buildCounterPlaylistItemListResponse++;
  if (buildCounterPlaylistItemListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2980();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterPlaylistItemListResponse--;
  return o;
}

void checkPlaylistItemListResponse(api.PlaylistItemListResponse o) {
  buildCounterPlaylistItemListResponse++;
  if (buildCounterPlaylistItemListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2980(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistItemListResponse--;
}

core.int buildCounterPlaylistItemSnippet = 0;
api.PlaylistItemSnippet buildPlaylistItemSnippet() {
  var o = api.PlaylistItemSnippet();
  buildCounterPlaylistItemSnippet++;
  if (buildCounterPlaylistItemSnippet < 3) {
    o.channelId = 'foo';
    o.channelTitle = 'foo';
    o.description = 'foo';
    o.playlistId = 'foo';
    o.position = 42;
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.resourceId = buildResourceId();
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
    o.videoOwnerChannelId = 'foo';
    o.videoOwnerChannelTitle = 'foo';
  }
  buildCounterPlaylistItemSnippet--;
  return o;
}

void checkPlaylistItemSnippet(api.PlaylistItemSnippet o) {
  buildCounterPlaylistItemSnippet++;
  if (buildCounterPlaylistItemSnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.playlistId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.position!,
      unittest.equals(42),
    );
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkResourceId(o.resourceId! as api.ResourceId);
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoOwnerChannelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoOwnerChannelTitle!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistItemSnippet--;
}

core.int buildCounterPlaylistItemStatus = 0;
api.PlaylistItemStatus buildPlaylistItemStatus() {
  var o = api.PlaylistItemStatus();
  buildCounterPlaylistItemStatus++;
  if (buildCounterPlaylistItemStatus < 3) {
    o.privacyStatus = 'foo';
  }
  buildCounterPlaylistItemStatus--;
  return o;
}

void checkPlaylistItemStatus(api.PlaylistItemStatus o) {
  buildCounterPlaylistItemStatus++;
  if (buildCounterPlaylistItemStatus < 3) {
    unittest.expect(
      o.privacyStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistItemStatus--;
}

core.List<api.Playlist> buildUnnamed2981() {
  var o = <api.Playlist>[];
  o.add(buildPlaylist());
  o.add(buildPlaylist());
  return o;
}

void checkUnnamed2981(core.List<api.Playlist> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlaylist(o[0] as api.Playlist);
  checkPlaylist(o[1] as api.Playlist);
}

core.int buildCounterPlaylistListResponse = 0;
api.PlaylistListResponse buildPlaylistListResponse() {
  var o = api.PlaylistListResponse();
  buildCounterPlaylistListResponse++;
  if (buildCounterPlaylistListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2981();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterPlaylistListResponse--;
  return o;
}

void checkPlaylistListResponse(api.PlaylistListResponse o) {
  buildCounterPlaylistListResponse++;
  if (buildCounterPlaylistListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2981(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistListResponse--;
}

core.int buildCounterPlaylistLocalization = 0;
api.PlaylistLocalization buildPlaylistLocalization() {
  var o = api.PlaylistLocalization();
  buildCounterPlaylistLocalization++;
  if (buildCounterPlaylistLocalization < 3) {
    o.description = 'foo';
    o.title = 'foo';
  }
  buildCounterPlaylistLocalization--;
  return o;
}

void checkPlaylistLocalization(api.PlaylistLocalization o) {
  buildCounterPlaylistLocalization++;
  if (buildCounterPlaylistLocalization < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistLocalization--;
}

core.int buildCounterPlaylistPlayer = 0;
api.PlaylistPlayer buildPlaylistPlayer() {
  var o = api.PlaylistPlayer();
  buildCounterPlaylistPlayer++;
  if (buildCounterPlaylistPlayer < 3) {
    o.embedHtml = 'foo';
  }
  buildCounterPlaylistPlayer--;
  return o;
}

void checkPlaylistPlayer(api.PlaylistPlayer o) {
  buildCounterPlaylistPlayer++;
  if (buildCounterPlaylistPlayer < 3) {
    unittest.expect(
      o.embedHtml!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistPlayer--;
}

core.List<core.String> buildUnnamed2982() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2982(core.List<core.String> o) {
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

core.int buildCounterPlaylistSnippet = 0;
api.PlaylistSnippet buildPlaylistSnippet() {
  var o = api.PlaylistSnippet();
  buildCounterPlaylistSnippet++;
  if (buildCounterPlaylistSnippet < 3) {
    o.channelId = 'foo';
    o.channelTitle = 'foo';
    o.defaultLanguage = 'foo';
    o.description = 'foo';
    o.localized = buildPlaylistLocalization();
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.tags = buildUnnamed2982();
    o.thumbnailVideoId = 'foo';
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
  }
  buildCounterPlaylistSnippet--;
  return o;
}

void checkPlaylistSnippet(api.PlaylistSnippet o) {
  buildCounterPlaylistSnippet++;
  if (buildCounterPlaylistSnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkPlaylistLocalization(o.localized! as api.PlaylistLocalization);
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed2982(o.tags!);
    unittest.expect(
      o.thumbnailVideoId!,
      unittest.equals('foo'),
    );
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistSnippet--;
}

core.int buildCounterPlaylistStatus = 0;
api.PlaylistStatus buildPlaylistStatus() {
  var o = api.PlaylistStatus();
  buildCounterPlaylistStatus++;
  if (buildCounterPlaylistStatus < 3) {
    o.privacyStatus = 'foo';
  }
  buildCounterPlaylistStatus--;
  return o;
}

void checkPlaylistStatus(api.PlaylistStatus o) {
  buildCounterPlaylistStatus++;
  if (buildCounterPlaylistStatus < 3) {
    unittest.expect(
      o.privacyStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlaylistStatus--;
}

core.int buildCounterPropertyValue = 0;
api.PropertyValue buildPropertyValue() {
  var o = api.PropertyValue();
  buildCounterPropertyValue++;
  if (buildCounterPropertyValue < 3) {
    o.property = 'foo';
    o.value = 'foo';
  }
  buildCounterPropertyValue--;
  return o;
}

void checkPropertyValue(api.PropertyValue o) {
  buildCounterPropertyValue++;
  if (buildCounterPropertyValue < 3) {
    unittest.expect(
      o.property!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterPropertyValue--;
}

core.int buildCounterRelatedEntity = 0;
api.RelatedEntity buildRelatedEntity() {
  var o = api.RelatedEntity();
  buildCounterRelatedEntity++;
  if (buildCounterRelatedEntity < 3) {
    o.entity = buildEntity();
  }
  buildCounterRelatedEntity--;
  return o;
}

void checkRelatedEntity(api.RelatedEntity o) {
  buildCounterRelatedEntity++;
  if (buildCounterRelatedEntity < 3) {
    checkEntity(o.entity! as api.Entity);
  }
  buildCounterRelatedEntity--;
}

core.int buildCounterResourceId = 0;
api.ResourceId buildResourceId() {
  var o = api.ResourceId();
  buildCounterResourceId++;
  if (buildCounterResourceId < 3) {
    o.channelId = 'foo';
    o.kind = 'foo';
    o.playlistId = 'foo';
    o.videoId = 'foo';
  }
  buildCounterResourceId--;
  return o;
}

void checkResourceId(api.ResourceId o) {
  buildCounterResourceId++;
  if (buildCounterResourceId < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.playlistId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceId--;
}

core.List<api.SearchResult> buildUnnamed2983() {
  var o = <api.SearchResult>[];
  o.add(buildSearchResult());
  o.add(buildSearchResult());
  return o;
}

void checkUnnamed2983(core.List<api.SearchResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchResult(o[0] as api.SearchResult);
  checkSearchResult(o[1] as api.SearchResult);
}

core.int buildCounterSearchListResponse = 0;
api.SearchListResponse buildSearchListResponse() {
  var o = api.SearchListResponse();
  buildCounterSearchListResponse++;
  if (buildCounterSearchListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2983();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.regionCode = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterSearchListResponse--;
  return o;
}

void checkSearchListResponse(api.SearchListResponse o) {
  buildCounterSearchListResponse++;
  if (buildCounterSearchListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2983(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.regionCode!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchListResponse--;
}

core.int buildCounterSearchResult = 0;
api.SearchResult buildSearchResult() {
  var o = api.SearchResult();
  buildCounterSearchResult++;
  if (buildCounterSearchResult < 3) {
    o.etag = 'foo';
    o.id = buildResourceId();
    o.kind = 'foo';
    o.snippet = buildSearchResultSnippet();
  }
  buildCounterSearchResult--;
  return o;
}

void checkSearchResult(api.SearchResult o) {
  buildCounterSearchResult++;
  if (buildCounterSearchResult < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkResourceId(o.id! as api.ResourceId);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkSearchResultSnippet(o.snippet! as api.SearchResultSnippet);
  }
  buildCounterSearchResult--;
}

core.int buildCounterSearchResultSnippet = 0;
api.SearchResultSnippet buildSearchResultSnippet() {
  var o = api.SearchResultSnippet();
  buildCounterSearchResultSnippet++;
  if (buildCounterSearchResultSnippet < 3) {
    o.channelId = 'foo';
    o.channelTitle = 'foo';
    o.description = 'foo';
    o.liveBroadcastContent = 'foo';
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
  }
  buildCounterSearchResultSnippet--;
  return o;
}

void checkSearchResultSnippet(api.SearchResultSnippet o) {
  buildCounterSearchResultSnippet++;
  if (buildCounterSearchResultSnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.liveBroadcastContent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchResultSnippet--;
}

core.int buildCounterSubscription = 0;
api.Subscription buildSubscription() {
  var o = api.Subscription();
  buildCounterSubscription++;
  if (buildCounterSubscription < 3) {
    o.contentDetails = buildSubscriptionContentDetails();
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildSubscriptionSnippet();
    o.subscriberSnippet = buildSubscriptionSubscriberSnippet();
  }
  buildCounterSubscription--;
  return o;
}

void checkSubscription(api.Subscription o) {
  buildCounterSubscription++;
  if (buildCounterSubscription < 3) {
    checkSubscriptionContentDetails(
        o.contentDetails! as api.SubscriptionContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkSubscriptionSnippet(o.snippet! as api.SubscriptionSnippet);
    checkSubscriptionSubscriberSnippet(
        o.subscriberSnippet! as api.SubscriptionSubscriberSnippet);
  }
  buildCounterSubscription--;
}

core.int buildCounterSubscriptionContentDetails = 0;
api.SubscriptionContentDetails buildSubscriptionContentDetails() {
  var o = api.SubscriptionContentDetails();
  buildCounterSubscriptionContentDetails++;
  if (buildCounterSubscriptionContentDetails < 3) {
    o.activityType = 'foo';
    o.newItemCount = 42;
    o.totalItemCount = 42;
  }
  buildCounterSubscriptionContentDetails--;
  return o;
}

void checkSubscriptionContentDetails(api.SubscriptionContentDetails o) {
  buildCounterSubscriptionContentDetails++;
  if (buildCounterSubscriptionContentDetails < 3) {
    unittest.expect(
      o.activityType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.newItemCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalItemCount!,
      unittest.equals(42),
    );
  }
  buildCounterSubscriptionContentDetails--;
}

core.List<api.Subscription> buildUnnamed2984() {
  var o = <api.Subscription>[];
  o.add(buildSubscription());
  o.add(buildSubscription());
  return o;
}

void checkUnnamed2984(core.List<api.Subscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSubscription(o[0] as api.Subscription);
  checkSubscription(o[1] as api.Subscription);
}

core.int buildCounterSubscriptionListResponse = 0;
api.SubscriptionListResponse buildSubscriptionListResponse() {
  var o = api.SubscriptionListResponse();
  buildCounterSubscriptionListResponse++;
  if (buildCounterSubscriptionListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2984();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterSubscriptionListResponse--;
  return o;
}

void checkSubscriptionListResponse(api.SubscriptionListResponse o) {
  buildCounterSubscriptionListResponse++;
  if (buildCounterSubscriptionListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2984(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionListResponse--;
}

core.int buildCounterSubscriptionSnippet = 0;
api.SubscriptionSnippet buildSubscriptionSnippet() {
  var o = api.SubscriptionSnippet();
  buildCounterSubscriptionSnippet++;
  if (buildCounterSubscriptionSnippet < 3) {
    o.channelId = 'foo';
    o.channelTitle = 'foo';
    o.description = 'foo';
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.resourceId = buildResourceId();
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
  }
  buildCounterSubscriptionSnippet--;
  return o;
}

void checkSubscriptionSnippet(api.SubscriptionSnippet o) {
  buildCounterSubscriptionSnippet++;
  if (buildCounterSubscriptionSnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkResourceId(o.resourceId! as api.ResourceId);
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionSnippet--;
}

core.int buildCounterSubscriptionSubscriberSnippet = 0;
api.SubscriptionSubscriberSnippet buildSubscriptionSubscriberSnippet() {
  var o = api.SubscriptionSubscriberSnippet();
  buildCounterSubscriptionSubscriberSnippet++;
  if (buildCounterSubscriptionSubscriberSnippet < 3) {
    o.channelId = 'foo';
    o.description = 'foo';
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
  }
  buildCounterSubscriptionSubscriberSnippet--;
  return o;
}

void checkSubscriptionSubscriberSnippet(api.SubscriptionSubscriberSnippet o) {
  buildCounterSubscriptionSubscriberSnippet++;
  if (buildCounterSubscriptionSubscriberSnippet < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionSubscriberSnippet--;
}

core.int buildCounterSuperChatEvent = 0;
api.SuperChatEvent buildSuperChatEvent() {
  var o = api.SuperChatEvent();
  buildCounterSuperChatEvent++;
  if (buildCounterSuperChatEvent < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildSuperChatEventSnippet();
  }
  buildCounterSuperChatEvent--;
  return o;
}

void checkSuperChatEvent(api.SuperChatEvent o) {
  buildCounterSuperChatEvent++;
  if (buildCounterSuperChatEvent < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkSuperChatEventSnippet(o.snippet! as api.SuperChatEventSnippet);
  }
  buildCounterSuperChatEvent--;
}

core.List<api.SuperChatEvent> buildUnnamed2985() {
  var o = <api.SuperChatEvent>[];
  o.add(buildSuperChatEvent());
  o.add(buildSuperChatEvent());
  return o;
}

void checkUnnamed2985(core.List<api.SuperChatEvent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSuperChatEvent(o[0] as api.SuperChatEvent);
  checkSuperChatEvent(o[1] as api.SuperChatEvent);
}

core.int buildCounterSuperChatEventListResponse = 0;
api.SuperChatEventListResponse buildSuperChatEventListResponse() {
  var o = api.SuperChatEventListResponse();
  buildCounterSuperChatEventListResponse++;
  if (buildCounterSuperChatEventListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2985();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterSuperChatEventListResponse--;
  return o;
}

void checkSuperChatEventListResponse(api.SuperChatEventListResponse o) {
  buildCounterSuperChatEventListResponse++;
  if (buildCounterSuperChatEventListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2985(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSuperChatEventListResponse--;
}

core.int buildCounterSuperChatEventSnippet = 0;
api.SuperChatEventSnippet buildSuperChatEventSnippet() {
  var o = api.SuperChatEventSnippet();
  buildCounterSuperChatEventSnippet++;
  if (buildCounterSuperChatEventSnippet < 3) {
    o.amountMicros = 'foo';
    o.channelId = 'foo';
    o.commentText = 'foo';
    o.createdAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.currency = 'foo';
    o.displayString = 'foo';
    o.isSuperStickerEvent = true;
    o.messageType = 42;
    o.superStickerMetadata = buildSuperStickerMetadata();
    o.supporterDetails = buildChannelProfileDetails();
  }
  buildCounterSuperChatEventSnippet--;
  return o;
}

void checkSuperChatEventSnippet(api.SuperChatEventSnippet o) {
  buildCounterSuperChatEventSnippet++;
  if (buildCounterSuperChatEventSnippet < 3) {
    unittest.expect(
      o.amountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.commentText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createdAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.currency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayString!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isSuperStickerEvent!, unittest.isTrue);
    unittest.expect(
      o.messageType!,
      unittest.equals(42),
    );
    checkSuperStickerMetadata(
        o.superStickerMetadata! as api.SuperStickerMetadata);
    checkChannelProfileDetails(
        o.supporterDetails! as api.ChannelProfileDetails);
  }
  buildCounterSuperChatEventSnippet--;
}

core.int buildCounterSuperStickerMetadata = 0;
api.SuperStickerMetadata buildSuperStickerMetadata() {
  var o = api.SuperStickerMetadata();
  buildCounterSuperStickerMetadata++;
  if (buildCounterSuperStickerMetadata < 3) {
    o.altText = 'foo';
    o.altTextLanguage = 'foo';
    o.stickerId = 'foo';
  }
  buildCounterSuperStickerMetadata--;
  return o;
}

void checkSuperStickerMetadata(api.SuperStickerMetadata o) {
  buildCounterSuperStickerMetadata++;
  if (buildCounterSuperStickerMetadata < 3) {
    unittest.expect(
      o.altText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.altTextLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stickerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSuperStickerMetadata--;
}

core.int buildCounterTestItem = 0;
api.TestItem buildTestItem() {
  var o = api.TestItem();
  buildCounterTestItem++;
  if (buildCounterTestItem < 3) {
    o.gaia = 'foo';
    o.id = 'foo';
    o.snippet = buildTestItemTestItemSnippet();
  }
  buildCounterTestItem--;
  return o;
}

void checkTestItem(api.TestItem o) {
  buildCounterTestItem++;
  if (buildCounterTestItem < 3) {
    unittest.expect(
      o.gaia!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkTestItemTestItemSnippet(o.snippet! as api.TestItemTestItemSnippet);
  }
  buildCounterTestItem--;
}

core.int buildCounterTestItemTestItemSnippet = 0;
api.TestItemTestItemSnippet buildTestItemTestItemSnippet() {
  var o = api.TestItemTestItemSnippet();
  buildCounterTestItemTestItemSnippet++;
  if (buildCounterTestItemTestItemSnippet < 3) {}
  buildCounterTestItemTestItemSnippet--;
  return o;
}

void checkTestItemTestItemSnippet(api.TestItemTestItemSnippet o) {
  buildCounterTestItemTestItemSnippet++;
  if (buildCounterTestItemTestItemSnippet < 3) {}
  buildCounterTestItemTestItemSnippet--;
}

core.int buildCounterThirdPartyLink = 0;
api.ThirdPartyLink buildThirdPartyLink() {
  var o = api.ThirdPartyLink();
  buildCounterThirdPartyLink++;
  if (buildCounterThirdPartyLink < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.linkingToken = 'foo';
    o.snippet = buildThirdPartyLinkSnippet();
    o.status = buildThirdPartyLinkStatus();
  }
  buildCounterThirdPartyLink--;
  return o;
}

void checkThirdPartyLink(api.ThirdPartyLink o) {
  buildCounterThirdPartyLink++;
  if (buildCounterThirdPartyLink < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.linkingToken!,
      unittest.equals('foo'),
    );
    checkThirdPartyLinkSnippet(o.snippet! as api.ThirdPartyLinkSnippet);
    checkThirdPartyLinkStatus(o.status! as api.ThirdPartyLinkStatus);
  }
  buildCounterThirdPartyLink--;
}

core.int buildCounterThirdPartyLinkSnippet = 0;
api.ThirdPartyLinkSnippet buildThirdPartyLinkSnippet() {
  var o = api.ThirdPartyLinkSnippet();
  buildCounterThirdPartyLinkSnippet++;
  if (buildCounterThirdPartyLinkSnippet < 3) {
    o.channelToStoreLink = buildChannelToStoreLinkDetails();
    o.type = 'foo';
  }
  buildCounterThirdPartyLinkSnippet--;
  return o;
}

void checkThirdPartyLinkSnippet(api.ThirdPartyLinkSnippet o) {
  buildCounterThirdPartyLinkSnippet++;
  if (buildCounterThirdPartyLinkSnippet < 3) {
    checkChannelToStoreLinkDetails(
        o.channelToStoreLink! as api.ChannelToStoreLinkDetails);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterThirdPartyLinkSnippet--;
}

core.int buildCounterThirdPartyLinkStatus = 0;
api.ThirdPartyLinkStatus buildThirdPartyLinkStatus() {
  var o = api.ThirdPartyLinkStatus();
  buildCounterThirdPartyLinkStatus++;
  if (buildCounterThirdPartyLinkStatus < 3) {
    o.linkStatus = 'foo';
  }
  buildCounterThirdPartyLinkStatus--;
  return o;
}

void checkThirdPartyLinkStatus(api.ThirdPartyLinkStatus o) {
  buildCounterThirdPartyLinkStatus++;
  if (buildCounterThirdPartyLinkStatus < 3) {
    unittest.expect(
      o.linkStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterThirdPartyLinkStatus--;
}

core.int buildCounterThumbnail = 0;
api.Thumbnail buildThumbnail() {
  var o = api.Thumbnail();
  buildCounterThumbnail++;
  if (buildCounterThumbnail < 3) {
    o.height = 42;
    o.url = 'foo';
    o.width = 42;
  }
  buildCounterThumbnail--;
  return o;
}

void checkThumbnail(api.Thumbnail o) {
  buildCounterThumbnail++;
  if (buildCounterThumbnail < 3) {
    unittest.expect(
      o.height!,
      unittest.equals(42),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterThumbnail--;
}

core.int buildCounterThumbnailDetails = 0;
api.ThumbnailDetails buildThumbnailDetails() {
  var o = api.ThumbnailDetails();
  buildCounterThumbnailDetails++;
  if (buildCounterThumbnailDetails < 3) {
    o.default_ = buildThumbnail();
    o.high = buildThumbnail();
    o.maxres = buildThumbnail();
    o.medium = buildThumbnail();
    o.standard = buildThumbnail();
  }
  buildCounterThumbnailDetails--;
  return o;
}

void checkThumbnailDetails(api.ThumbnailDetails o) {
  buildCounterThumbnailDetails++;
  if (buildCounterThumbnailDetails < 3) {
    checkThumbnail(o.default_! as api.Thumbnail);
    checkThumbnail(o.high! as api.Thumbnail);
    checkThumbnail(o.maxres! as api.Thumbnail);
    checkThumbnail(o.medium! as api.Thumbnail);
    checkThumbnail(o.standard! as api.Thumbnail);
  }
  buildCounterThumbnailDetails--;
}

core.List<api.ThumbnailDetails> buildUnnamed2986() {
  var o = <api.ThumbnailDetails>[];
  o.add(buildThumbnailDetails());
  o.add(buildThumbnailDetails());
  return o;
}

void checkUnnamed2986(core.List<api.ThumbnailDetails> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkThumbnailDetails(o[0] as api.ThumbnailDetails);
  checkThumbnailDetails(o[1] as api.ThumbnailDetails);
}

core.int buildCounterThumbnailSetResponse = 0;
api.ThumbnailSetResponse buildThumbnailSetResponse() {
  var o = api.ThumbnailSetResponse();
  buildCounterThumbnailSetResponse++;
  if (buildCounterThumbnailSetResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2986();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterThumbnailSetResponse--;
  return o;
}

void checkThumbnailSetResponse(api.ThumbnailSetResponse o) {
  buildCounterThumbnailSetResponse++;
  if (buildCounterThumbnailSetResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2986(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterThumbnailSetResponse--;
}

core.int buildCounterTokenPagination = 0;
api.TokenPagination buildTokenPagination() {
  var o = api.TokenPagination();
  buildCounterTokenPagination++;
  if (buildCounterTokenPagination < 3) {}
  buildCounterTokenPagination--;
  return o;
}

void checkTokenPagination(api.TokenPagination o) {
  buildCounterTokenPagination++;
  if (buildCounterTokenPagination < 3) {}
  buildCounterTokenPagination--;
}

core.Map<core.String, api.VideoLocalization> buildUnnamed2987() {
  var o = <core.String, api.VideoLocalization>{};
  o['x'] = buildVideoLocalization();
  o['y'] = buildVideoLocalization();
  return o;
}

void checkUnnamed2987(core.Map<core.String, api.VideoLocalization> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoLocalization(o['x']! as api.VideoLocalization);
  checkVideoLocalization(o['y']! as api.VideoLocalization);
}

core.int buildCounterVideo = 0;
api.Video buildVideo() {
  var o = api.Video();
  buildCounterVideo++;
  if (buildCounterVideo < 3) {
    o.ageGating = buildVideoAgeGating();
    o.contentDetails = buildVideoContentDetails();
    o.etag = 'foo';
    o.fileDetails = buildVideoFileDetails();
    o.id = 'foo';
    o.kind = 'foo';
    o.liveStreamingDetails = buildVideoLiveStreamingDetails();
    o.localizations = buildUnnamed2987();
    o.monetizationDetails = buildVideoMonetizationDetails();
    o.player = buildVideoPlayer();
    o.processingDetails = buildVideoProcessingDetails();
    o.projectDetails = buildVideoProjectDetails();
    o.recordingDetails = buildVideoRecordingDetails();
    o.snippet = buildVideoSnippet();
    o.statistics = buildVideoStatistics();
    o.status = buildVideoStatus();
    o.suggestions = buildVideoSuggestions();
    o.topicDetails = buildVideoTopicDetails();
  }
  buildCounterVideo--;
  return o;
}

void checkVideo(api.Video o) {
  buildCounterVideo++;
  if (buildCounterVideo < 3) {
    checkVideoAgeGating(o.ageGating! as api.VideoAgeGating);
    checkVideoContentDetails(o.contentDetails! as api.VideoContentDetails);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkVideoFileDetails(o.fileDetails! as api.VideoFileDetails);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkVideoLiveStreamingDetails(
        o.liveStreamingDetails! as api.VideoLiveStreamingDetails);
    checkUnnamed2987(o.localizations!);
    checkVideoMonetizationDetails(
        o.monetizationDetails! as api.VideoMonetizationDetails);
    checkVideoPlayer(o.player! as api.VideoPlayer);
    checkVideoProcessingDetails(
        o.processingDetails! as api.VideoProcessingDetails);
    checkVideoProjectDetails(o.projectDetails! as api.VideoProjectDetails);
    checkVideoRecordingDetails(
        o.recordingDetails! as api.VideoRecordingDetails);
    checkVideoSnippet(o.snippet! as api.VideoSnippet);
    checkVideoStatistics(o.statistics! as api.VideoStatistics);
    checkVideoStatus(o.status! as api.VideoStatus);
    checkVideoSuggestions(o.suggestions! as api.VideoSuggestions);
    checkVideoTopicDetails(o.topicDetails! as api.VideoTopicDetails);
  }
  buildCounterVideo--;
}

core.int buildCounterVideoAbuseReport = 0;
api.VideoAbuseReport buildVideoAbuseReport() {
  var o = api.VideoAbuseReport();
  buildCounterVideoAbuseReport++;
  if (buildCounterVideoAbuseReport < 3) {
    o.comments = 'foo';
    o.language = 'foo';
    o.reasonId = 'foo';
    o.secondaryReasonId = 'foo';
    o.videoId = 'foo';
  }
  buildCounterVideoAbuseReport--;
  return o;
}

void checkVideoAbuseReport(api.VideoAbuseReport o) {
  buildCounterVideoAbuseReport++;
  if (buildCounterVideoAbuseReport < 3) {
    unittest.expect(
      o.comments!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reasonId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.secondaryReasonId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoAbuseReport--;
}

core.int buildCounterVideoAbuseReportReason = 0;
api.VideoAbuseReportReason buildVideoAbuseReportReason() {
  var o = api.VideoAbuseReportReason();
  buildCounterVideoAbuseReportReason++;
  if (buildCounterVideoAbuseReportReason < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildVideoAbuseReportReasonSnippet();
  }
  buildCounterVideoAbuseReportReason--;
  return o;
}

void checkVideoAbuseReportReason(api.VideoAbuseReportReason o) {
  buildCounterVideoAbuseReportReason++;
  if (buildCounterVideoAbuseReportReason < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkVideoAbuseReportReasonSnippet(
        o.snippet! as api.VideoAbuseReportReasonSnippet);
  }
  buildCounterVideoAbuseReportReason--;
}

core.List<api.VideoAbuseReportReason> buildUnnamed2988() {
  var o = <api.VideoAbuseReportReason>[];
  o.add(buildVideoAbuseReportReason());
  o.add(buildVideoAbuseReportReason());
  return o;
}

void checkUnnamed2988(core.List<api.VideoAbuseReportReason> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoAbuseReportReason(o[0] as api.VideoAbuseReportReason);
  checkVideoAbuseReportReason(o[1] as api.VideoAbuseReportReason);
}

core.int buildCounterVideoAbuseReportReasonListResponse = 0;
api.VideoAbuseReportReasonListResponse
    buildVideoAbuseReportReasonListResponse() {
  var o = api.VideoAbuseReportReasonListResponse();
  buildCounterVideoAbuseReportReasonListResponse++;
  if (buildCounterVideoAbuseReportReasonListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2988();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterVideoAbuseReportReasonListResponse--;
  return o;
}

void checkVideoAbuseReportReasonListResponse(
    api.VideoAbuseReportReasonListResponse o) {
  buildCounterVideoAbuseReportReasonListResponse++;
  if (buildCounterVideoAbuseReportReasonListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2988(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoAbuseReportReasonListResponse--;
}

core.List<api.VideoAbuseReportSecondaryReason> buildUnnamed2989() {
  var o = <api.VideoAbuseReportSecondaryReason>[];
  o.add(buildVideoAbuseReportSecondaryReason());
  o.add(buildVideoAbuseReportSecondaryReason());
  return o;
}

void checkUnnamed2989(core.List<api.VideoAbuseReportSecondaryReason> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoAbuseReportSecondaryReason(
      o[0] as api.VideoAbuseReportSecondaryReason);
  checkVideoAbuseReportSecondaryReason(
      o[1] as api.VideoAbuseReportSecondaryReason);
}

core.int buildCounterVideoAbuseReportReasonSnippet = 0;
api.VideoAbuseReportReasonSnippet buildVideoAbuseReportReasonSnippet() {
  var o = api.VideoAbuseReportReasonSnippet();
  buildCounterVideoAbuseReportReasonSnippet++;
  if (buildCounterVideoAbuseReportReasonSnippet < 3) {
    o.label = 'foo';
    o.secondaryReasons = buildUnnamed2989();
  }
  buildCounterVideoAbuseReportReasonSnippet--;
  return o;
}

void checkVideoAbuseReportReasonSnippet(api.VideoAbuseReportReasonSnippet o) {
  buildCounterVideoAbuseReportReasonSnippet++;
  if (buildCounterVideoAbuseReportReasonSnippet < 3) {
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    checkUnnamed2989(o.secondaryReasons!);
  }
  buildCounterVideoAbuseReportReasonSnippet--;
}

core.int buildCounterVideoAbuseReportSecondaryReason = 0;
api.VideoAbuseReportSecondaryReason buildVideoAbuseReportSecondaryReason() {
  var o = api.VideoAbuseReportSecondaryReason();
  buildCounterVideoAbuseReportSecondaryReason++;
  if (buildCounterVideoAbuseReportSecondaryReason < 3) {
    o.id = 'foo';
    o.label = 'foo';
  }
  buildCounterVideoAbuseReportSecondaryReason--;
  return o;
}

void checkVideoAbuseReportSecondaryReason(
    api.VideoAbuseReportSecondaryReason o) {
  buildCounterVideoAbuseReportSecondaryReason++;
  if (buildCounterVideoAbuseReportSecondaryReason < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoAbuseReportSecondaryReason--;
}

core.int buildCounterVideoAgeGating = 0;
api.VideoAgeGating buildVideoAgeGating() {
  var o = api.VideoAgeGating();
  buildCounterVideoAgeGating++;
  if (buildCounterVideoAgeGating < 3) {
    o.alcoholContent = true;
    o.restricted = true;
    o.videoGameRating = 'foo';
  }
  buildCounterVideoAgeGating--;
  return o;
}

void checkVideoAgeGating(api.VideoAgeGating o) {
  buildCounterVideoAgeGating++;
  if (buildCounterVideoAgeGating < 3) {
    unittest.expect(o.alcoholContent!, unittest.isTrue);
    unittest.expect(o.restricted!, unittest.isTrue);
    unittest.expect(
      o.videoGameRating!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoAgeGating--;
}

core.int buildCounterVideoCategory = 0;
api.VideoCategory buildVideoCategory() {
  var o = api.VideoCategory();
  buildCounterVideoCategory++;
  if (buildCounterVideoCategory < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.snippet = buildVideoCategorySnippet();
  }
  buildCounterVideoCategory--;
  return o;
}

void checkVideoCategory(api.VideoCategory o) {
  buildCounterVideoCategory++;
  if (buildCounterVideoCategory < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkVideoCategorySnippet(o.snippet! as api.VideoCategorySnippet);
  }
  buildCounterVideoCategory--;
}

core.List<api.VideoCategory> buildUnnamed2990() {
  var o = <api.VideoCategory>[];
  o.add(buildVideoCategory());
  o.add(buildVideoCategory());
  return o;
}

void checkUnnamed2990(core.List<api.VideoCategory> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoCategory(o[0] as api.VideoCategory);
  checkVideoCategory(o[1] as api.VideoCategory);
}

core.int buildCounterVideoCategoryListResponse = 0;
api.VideoCategoryListResponse buildVideoCategoryListResponse() {
  var o = api.VideoCategoryListResponse();
  buildCounterVideoCategoryListResponse++;
  if (buildCounterVideoCategoryListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2990();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterVideoCategoryListResponse--;
  return o;
}

void checkVideoCategoryListResponse(api.VideoCategoryListResponse o) {
  buildCounterVideoCategoryListResponse++;
  if (buildCounterVideoCategoryListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2990(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoCategoryListResponse--;
}

core.int buildCounterVideoCategorySnippet = 0;
api.VideoCategorySnippet buildVideoCategorySnippet() {
  var o = api.VideoCategorySnippet();
  buildCounterVideoCategorySnippet++;
  if (buildCounterVideoCategorySnippet < 3) {
    o.assignable = true;
    o.channelId = 'foo';
    o.title = 'foo';
  }
  buildCounterVideoCategorySnippet--;
  return o;
}

void checkVideoCategorySnippet(api.VideoCategorySnippet o) {
  buildCounterVideoCategorySnippet++;
  if (buildCounterVideoCategorySnippet < 3) {
    unittest.expect(o.assignable!, unittest.isTrue);
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoCategorySnippet--;
}

core.int buildCounterVideoContentDetails = 0;
api.VideoContentDetails buildVideoContentDetails() {
  var o = api.VideoContentDetails();
  buildCounterVideoContentDetails++;
  if (buildCounterVideoContentDetails < 3) {
    o.caption = 'foo';
    o.contentRating = buildContentRating();
    o.countryRestriction = buildAccessPolicy();
    o.definition = 'foo';
    o.dimension = 'foo';
    o.duration = 'foo';
    o.hasCustomThumbnail = true;
    o.licensedContent = true;
    o.projection = 'foo';
    o.regionRestriction = buildVideoContentDetailsRegionRestriction();
  }
  buildCounterVideoContentDetails--;
  return o;
}

void checkVideoContentDetails(api.VideoContentDetails o) {
  buildCounterVideoContentDetails++;
  if (buildCounterVideoContentDetails < 3) {
    unittest.expect(
      o.caption!,
      unittest.equals('foo'),
    );
    checkContentRating(o.contentRating! as api.ContentRating);
    checkAccessPolicy(o.countryRestriction! as api.AccessPolicy);
    unittest.expect(
      o.definition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dimension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hasCustomThumbnail!, unittest.isTrue);
    unittest.expect(o.licensedContent!, unittest.isTrue);
    unittest.expect(
      o.projection!,
      unittest.equals('foo'),
    );
    checkVideoContentDetailsRegionRestriction(
        o.regionRestriction! as api.VideoContentDetailsRegionRestriction);
  }
  buildCounterVideoContentDetails--;
}

core.List<core.String> buildUnnamed2991() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2991(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2992() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2992(core.List<core.String> o) {
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

core.int buildCounterVideoContentDetailsRegionRestriction = 0;
api.VideoContentDetailsRegionRestriction
    buildVideoContentDetailsRegionRestriction() {
  var o = api.VideoContentDetailsRegionRestriction();
  buildCounterVideoContentDetailsRegionRestriction++;
  if (buildCounterVideoContentDetailsRegionRestriction < 3) {
    o.allowed = buildUnnamed2991();
    o.blocked = buildUnnamed2992();
  }
  buildCounterVideoContentDetailsRegionRestriction--;
  return o;
}

void checkVideoContentDetailsRegionRestriction(
    api.VideoContentDetailsRegionRestriction o) {
  buildCounterVideoContentDetailsRegionRestriction++;
  if (buildCounterVideoContentDetailsRegionRestriction < 3) {
    checkUnnamed2991(o.allowed!);
    checkUnnamed2992(o.blocked!);
  }
  buildCounterVideoContentDetailsRegionRestriction--;
}

core.List<api.VideoFileDetailsAudioStream> buildUnnamed2993() {
  var o = <api.VideoFileDetailsAudioStream>[];
  o.add(buildVideoFileDetailsAudioStream());
  o.add(buildVideoFileDetailsAudioStream());
  return o;
}

void checkUnnamed2993(core.List<api.VideoFileDetailsAudioStream> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoFileDetailsAudioStream(o[0] as api.VideoFileDetailsAudioStream);
  checkVideoFileDetailsAudioStream(o[1] as api.VideoFileDetailsAudioStream);
}

core.List<api.VideoFileDetailsVideoStream> buildUnnamed2994() {
  var o = <api.VideoFileDetailsVideoStream>[];
  o.add(buildVideoFileDetailsVideoStream());
  o.add(buildVideoFileDetailsVideoStream());
  return o;
}

void checkUnnamed2994(core.List<api.VideoFileDetailsVideoStream> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoFileDetailsVideoStream(o[0] as api.VideoFileDetailsVideoStream);
  checkVideoFileDetailsVideoStream(o[1] as api.VideoFileDetailsVideoStream);
}

core.int buildCounterVideoFileDetails = 0;
api.VideoFileDetails buildVideoFileDetails() {
  var o = api.VideoFileDetails();
  buildCounterVideoFileDetails++;
  if (buildCounterVideoFileDetails < 3) {
    o.audioStreams = buildUnnamed2993();
    o.bitrateBps = 'foo';
    o.container = 'foo';
    o.creationTime = 'foo';
    o.durationMs = 'foo';
    o.fileName = 'foo';
    o.fileSize = 'foo';
    o.fileType = 'foo';
    o.videoStreams = buildUnnamed2994();
  }
  buildCounterVideoFileDetails--;
  return o;
}

void checkVideoFileDetails(api.VideoFileDetails o) {
  buildCounterVideoFileDetails++;
  if (buildCounterVideoFileDetails < 3) {
    checkUnnamed2993(o.audioStreams!);
    unittest.expect(
      o.bitrateBps!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.container!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.durationMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fileSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fileType!,
      unittest.equals('foo'),
    );
    checkUnnamed2994(o.videoStreams!);
  }
  buildCounterVideoFileDetails--;
}

core.int buildCounterVideoFileDetailsAudioStream = 0;
api.VideoFileDetailsAudioStream buildVideoFileDetailsAudioStream() {
  var o = api.VideoFileDetailsAudioStream();
  buildCounterVideoFileDetailsAudioStream++;
  if (buildCounterVideoFileDetailsAudioStream < 3) {
    o.bitrateBps = 'foo';
    o.channelCount = 42;
    o.codec = 'foo';
    o.vendor = 'foo';
  }
  buildCounterVideoFileDetailsAudioStream--;
  return o;
}

void checkVideoFileDetailsAudioStream(api.VideoFileDetailsAudioStream o) {
  buildCounterVideoFileDetailsAudioStream++;
  if (buildCounterVideoFileDetailsAudioStream < 3) {
    unittest.expect(
      o.bitrateBps!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.codec!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vendor!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoFileDetailsAudioStream--;
}

core.int buildCounterVideoFileDetailsVideoStream = 0;
api.VideoFileDetailsVideoStream buildVideoFileDetailsVideoStream() {
  var o = api.VideoFileDetailsVideoStream();
  buildCounterVideoFileDetailsVideoStream++;
  if (buildCounterVideoFileDetailsVideoStream < 3) {
    o.aspectRatio = 42.0;
    o.bitrateBps = 'foo';
    o.codec = 'foo';
    o.frameRateFps = 42.0;
    o.heightPixels = 42;
    o.rotation = 'foo';
    o.vendor = 'foo';
    o.widthPixels = 42;
  }
  buildCounterVideoFileDetailsVideoStream--;
  return o;
}

void checkVideoFileDetailsVideoStream(api.VideoFileDetailsVideoStream o) {
  buildCounterVideoFileDetailsVideoStream++;
  if (buildCounterVideoFileDetailsVideoStream < 3) {
    unittest.expect(
      o.aspectRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.bitrateBps!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.codec!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.frameRateFps!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.heightPixels!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rotation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vendor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.widthPixels!,
      unittest.equals(42),
    );
  }
  buildCounterVideoFileDetailsVideoStream--;
}

core.List<api.VideoRating> buildUnnamed2995() {
  var o = <api.VideoRating>[];
  o.add(buildVideoRating());
  o.add(buildVideoRating());
  return o;
}

void checkUnnamed2995(core.List<api.VideoRating> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoRating(o[0] as api.VideoRating);
  checkVideoRating(o[1] as api.VideoRating);
}

core.int buildCounterVideoGetRatingResponse = 0;
api.VideoGetRatingResponse buildVideoGetRatingResponse() {
  var o = api.VideoGetRatingResponse();
  buildCounterVideoGetRatingResponse++;
  if (buildCounterVideoGetRatingResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2995();
    o.kind = 'foo';
    o.visitorId = 'foo';
  }
  buildCounterVideoGetRatingResponse--;
  return o;
}

void checkVideoGetRatingResponse(api.VideoGetRatingResponse o) {
  buildCounterVideoGetRatingResponse++;
  if (buildCounterVideoGetRatingResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2995(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoGetRatingResponse--;
}

core.List<api.Video> buildUnnamed2996() {
  var o = <api.Video>[];
  o.add(buildVideo());
  o.add(buildVideo());
  return o;
}

void checkUnnamed2996(core.List<api.Video> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideo(o[0] as api.Video);
  checkVideo(o[1] as api.Video);
}

core.int buildCounterVideoListResponse = 0;
api.VideoListResponse buildVideoListResponse() {
  var o = api.VideoListResponse();
  buildCounterVideoListResponse++;
  if (buildCounterVideoListResponse < 3) {
    o.etag = 'foo';
    o.eventId = 'foo';
    o.items = buildUnnamed2996();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.pageInfo = buildPageInfo();
    o.prevPageToken = 'foo';
    o.tokenPagination = buildTokenPagination();
    o.visitorId = 'foo';
  }
  buildCounterVideoListResponse--;
  return o;
}

void checkVideoListResponse(api.VideoListResponse o) {
  buildCounterVideoListResponse++;
  if (buildCounterVideoListResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed2996(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPageInfo(o.pageInfo! as api.PageInfo);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
    checkTokenPagination(o.tokenPagination! as api.TokenPagination);
    unittest.expect(
      o.visitorId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoListResponse--;
}

core.int buildCounterVideoLiveStreamingDetails = 0;
api.VideoLiveStreamingDetails buildVideoLiveStreamingDetails() {
  var o = api.VideoLiveStreamingDetails();
  buildCounterVideoLiveStreamingDetails++;
  if (buildCounterVideoLiveStreamingDetails < 3) {
    o.activeLiveChatId = 'foo';
    o.actualEndTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.actualStartTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.concurrentViewers = 'foo';
    o.scheduledEndTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.scheduledStartTime = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterVideoLiveStreamingDetails--;
  return o;
}

void checkVideoLiveStreamingDetails(api.VideoLiveStreamingDetails o) {
  buildCounterVideoLiveStreamingDetails++;
  if (buildCounterVideoLiveStreamingDetails < 3) {
    unittest.expect(
      o.activeLiveChatId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.actualEndTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.actualStartTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.concurrentViewers!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scheduledEndTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.scheduledStartTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterVideoLiveStreamingDetails--;
}

core.int buildCounterVideoLocalization = 0;
api.VideoLocalization buildVideoLocalization() {
  var o = api.VideoLocalization();
  buildCounterVideoLocalization++;
  if (buildCounterVideoLocalization < 3) {
    o.description = 'foo';
    o.title = 'foo';
  }
  buildCounterVideoLocalization--;
  return o;
}

void checkVideoLocalization(api.VideoLocalization o) {
  buildCounterVideoLocalization++;
  if (buildCounterVideoLocalization < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoLocalization--;
}

core.int buildCounterVideoMonetizationDetails = 0;
api.VideoMonetizationDetails buildVideoMonetizationDetails() {
  var o = api.VideoMonetizationDetails();
  buildCounterVideoMonetizationDetails++;
  if (buildCounterVideoMonetizationDetails < 3) {
    o.access = buildAccessPolicy();
  }
  buildCounterVideoMonetizationDetails--;
  return o;
}

void checkVideoMonetizationDetails(api.VideoMonetizationDetails o) {
  buildCounterVideoMonetizationDetails++;
  if (buildCounterVideoMonetizationDetails < 3) {
    checkAccessPolicy(o.access! as api.AccessPolicy);
  }
  buildCounterVideoMonetizationDetails--;
}

core.int buildCounterVideoPlayer = 0;
api.VideoPlayer buildVideoPlayer() {
  var o = api.VideoPlayer();
  buildCounterVideoPlayer++;
  if (buildCounterVideoPlayer < 3) {
    o.embedHeight = 'foo';
    o.embedHtml = 'foo';
    o.embedWidth = 'foo';
  }
  buildCounterVideoPlayer--;
  return o;
}

void checkVideoPlayer(api.VideoPlayer o) {
  buildCounterVideoPlayer++;
  if (buildCounterVideoPlayer < 3) {
    unittest.expect(
      o.embedHeight!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.embedHtml!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.embedWidth!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoPlayer--;
}

core.int buildCounterVideoProcessingDetails = 0;
api.VideoProcessingDetails buildVideoProcessingDetails() {
  var o = api.VideoProcessingDetails();
  buildCounterVideoProcessingDetails++;
  if (buildCounterVideoProcessingDetails < 3) {
    o.editorSuggestionsAvailability = 'foo';
    o.fileDetailsAvailability = 'foo';
    o.processingFailureReason = 'foo';
    o.processingIssuesAvailability = 'foo';
    o.processingProgress = buildVideoProcessingDetailsProcessingProgress();
    o.processingStatus = 'foo';
    o.tagSuggestionsAvailability = 'foo';
    o.thumbnailsAvailability = 'foo';
  }
  buildCounterVideoProcessingDetails--;
  return o;
}

void checkVideoProcessingDetails(api.VideoProcessingDetails o) {
  buildCounterVideoProcessingDetails++;
  if (buildCounterVideoProcessingDetails < 3) {
    unittest.expect(
      o.editorSuggestionsAvailability!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fileDetailsAvailability!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.processingFailureReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.processingIssuesAvailability!,
      unittest.equals('foo'),
    );
    checkVideoProcessingDetailsProcessingProgress(
        o.processingProgress! as api.VideoProcessingDetailsProcessingProgress);
    unittest.expect(
      o.processingStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tagSuggestionsAvailability!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailsAvailability!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoProcessingDetails--;
}

core.int buildCounterVideoProcessingDetailsProcessingProgress = 0;
api.VideoProcessingDetailsProcessingProgress
    buildVideoProcessingDetailsProcessingProgress() {
  var o = api.VideoProcessingDetailsProcessingProgress();
  buildCounterVideoProcessingDetailsProcessingProgress++;
  if (buildCounterVideoProcessingDetailsProcessingProgress < 3) {
    o.partsProcessed = 'foo';
    o.partsTotal = 'foo';
    o.timeLeftMs = 'foo';
  }
  buildCounterVideoProcessingDetailsProcessingProgress--;
  return o;
}

void checkVideoProcessingDetailsProcessingProgress(
    api.VideoProcessingDetailsProcessingProgress o) {
  buildCounterVideoProcessingDetailsProcessingProgress++;
  if (buildCounterVideoProcessingDetailsProcessingProgress < 3) {
    unittest.expect(
      o.partsProcessed!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partsTotal!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeLeftMs!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoProcessingDetailsProcessingProgress--;
}

core.int buildCounterVideoProjectDetails = 0;
api.VideoProjectDetails buildVideoProjectDetails() {
  var o = api.VideoProjectDetails();
  buildCounterVideoProjectDetails++;
  if (buildCounterVideoProjectDetails < 3) {}
  buildCounterVideoProjectDetails--;
  return o;
}

void checkVideoProjectDetails(api.VideoProjectDetails o) {
  buildCounterVideoProjectDetails++;
  if (buildCounterVideoProjectDetails < 3) {}
  buildCounterVideoProjectDetails--;
}

core.int buildCounterVideoRating = 0;
api.VideoRating buildVideoRating() {
  var o = api.VideoRating();
  buildCounterVideoRating++;
  if (buildCounterVideoRating < 3) {
    o.rating = 'foo';
    o.videoId = 'foo';
  }
  buildCounterVideoRating--;
  return o;
}

void checkVideoRating(api.VideoRating o) {
  buildCounterVideoRating++;
  if (buildCounterVideoRating < 3) {
    unittest.expect(
      o.rating!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoId!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoRating--;
}

core.int buildCounterVideoRecordingDetails = 0;
api.VideoRecordingDetails buildVideoRecordingDetails() {
  var o = api.VideoRecordingDetails();
  buildCounterVideoRecordingDetails++;
  if (buildCounterVideoRecordingDetails < 3) {
    o.location = buildGeoPoint();
    o.locationDescription = 'foo';
    o.recordingDate = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterVideoRecordingDetails--;
  return o;
}

void checkVideoRecordingDetails(api.VideoRecordingDetails o) {
  buildCounterVideoRecordingDetails++;
  if (buildCounterVideoRecordingDetails < 3) {
    checkGeoPoint(o.location! as api.GeoPoint);
    unittest.expect(
      o.locationDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recordingDate!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterVideoRecordingDetails--;
}

core.List<core.String> buildUnnamed2997() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2997(core.List<core.String> o) {
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

core.int buildCounterVideoSnippet = 0;
api.VideoSnippet buildVideoSnippet() {
  var o = api.VideoSnippet();
  buildCounterVideoSnippet++;
  if (buildCounterVideoSnippet < 3) {
    o.categoryId = 'foo';
    o.channelId = 'foo';
    o.channelTitle = 'foo';
    o.defaultAudioLanguage = 'foo';
    o.defaultLanguage = 'foo';
    o.description = 'foo';
    o.liveBroadcastContent = 'foo';
    o.localized = buildVideoLocalization();
    o.publishedAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.tags = buildUnnamed2997();
    o.thumbnails = buildThumbnailDetails();
    o.title = 'foo';
  }
  buildCounterVideoSnippet--;
  return o;
}

void checkVideoSnippet(api.VideoSnippet o) {
  buildCounterVideoSnippet++;
  if (buildCounterVideoSnippet < 3) {
    unittest.expect(
      o.categoryId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultAudioLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.liveBroadcastContent!,
      unittest.equals('foo'),
    );
    checkVideoLocalization(o.localized! as api.VideoLocalization);
    unittest.expect(
      o.publishedAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed2997(o.tags!);
    checkThumbnailDetails(o.thumbnails! as api.ThumbnailDetails);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoSnippet--;
}

core.int buildCounterVideoStatistics = 0;
api.VideoStatistics buildVideoStatistics() {
  var o = api.VideoStatistics();
  buildCounterVideoStatistics++;
  if (buildCounterVideoStatistics < 3) {
    o.commentCount = 'foo';
    o.dislikeCount = 'foo';
    o.favoriteCount = 'foo';
    o.likeCount = 'foo';
    o.viewCount = 'foo';
  }
  buildCounterVideoStatistics--;
  return o;
}

void checkVideoStatistics(api.VideoStatistics o) {
  buildCounterVideoStatistics++;
  if (buildCounterVideoStatistics < 3) {
    unittest.expect(
      o.commentCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dislikeCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.favoriteCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.likeCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.viewCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoStatistics--;
}

core.int buildCounterVideoStatus = 0;
api.VideoStatus buildVideoStatus() {
  var o = api.VideoStatus();
  buildCounterVideoStatus++;
  if (buildCounterVideoStatus < 3) {
    o.embeddable = true;
    o.failureReason = 'foo';
    o.license = 'foo';
    o.madeForKids = true;
    o.privacyStatus = 'foo';
    o.publicStatsViewable = true;
    o.publishAt = core.DateTime.parse("2002-02-27T14:01:02");
    o.rejectionReason = 'foo';
    o.selfDeclaredMadeForKids = true;
    o.uploadStatus = 'foo';
  }
  buildCounterVideoStatus--;
  return o;
}

void checkVideoStatus(api.VideoStatus o) {
  buildCounterVideoStatus++;
  if (buildCounterVideoStatus < 3) {
    unittest.expect(o.embeddable!, unittest.isTrue);
    unittest.expect(
      o.failureReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.license!,
      unittest.equals('foo'),
    );
    unittest.expect(o.madeForKids!, unittest.isTrue);
    unittest.expect(
      o.privacyStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(o.publicStatsViewable!, unittest.isTrue);
    unittest.expect(
      o.publishAt!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.rejectionReason!,
      unittest.equals('foo'),
    );
    unittest.expect(o.selfDeclaredMadeForKids!, unittest.isTrue);
    unittest.expect(
      o.uploadStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoStatus--;
}

core.List<core.String> buildUnnamed2998() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2998(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2999() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2999(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3000() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3000(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3001() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3001(core.List<core.String> o) {
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

core.List<api.VideoSuggestionsTagSuggestion> buildUnnamed3002() {
  var o = <api.VideoSuggestionsTagSuggestion>[];
  o.add(buildVideoSuggestionsTagSuggestion());
  o.add(buildVideoSuggestionsTagSuggestion());
  return o;
}

void checkUnnamed3002(core.List<api.VideoSuggestionsTagSuggestion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVideoSuggestionsTagSuggestion(o[0] as api.VideoSuggestionsTagSuggestion);
  checkVideoSuggestionsTagSuggestion(o[1] as api.VideoSuggestionsTagSuggestion);
}

core.int buildCounterVideoSuggestions = 0;
api.VideoSuggestions buildVideoSuggestions() {
  var o = api.VideoSuggestions();
  buildCounterVideoSuggestions++;
  if (buildCounterVideoSuggestions < 3) {
    o.editorSuggestions = buildUnnamed2998();
    o.processingErrors = buildUnnamed2999();
    o.processingHints = buildUnnamed3000();
    o.processingWarnings = buildUnnamed3001();
    o.tagSuggestions = buildUnnamed3002();
  }
  buildCounterVideoSuggestions--;
  return o;
}

void checkVideoSuggestions(api.VideoSuggestions o) {
  buildCounterVideoSuggestions++;
  if (buildCounterVideoSuggestions < 3) {
    checkUnnamed2998(o.editorSuggestions!);
    checkUnnamed2999(o.processingErrors!);
    checkUnnamed3000(o.processingHints!);
    checkUnnamed3001(o.processingWarnings!);
    checkUnnamed3002(o.tagSuggestions!);
  }
  buildCounterVideoSuggestions--;
}

core.List<core.String> buildUnnamed3003() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3003(core.List<core.String> o) {
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

core.int buildCounterVideoSuggestionsTagSuggestion = 0;
api.VideoSuggestionsTagSuggestion buildVideoSuggestionsTagSuggestion() {
  var o = api.VideoSuggestionsTagSuggestion();
  buildCounterVideoSuggestionsTagSuggestion++;
  if (buildCounterVideoSuggestionsTagSuggestion < 3) {
    o.categoryRestricts = buildUnnamed3003();
    o.tag = 'foo';
  }
  buildCounterVideoSuggestionsTagSuggestion--;
  return o;
}

void checkVideoSuggestionsTagSuggestion(api.VideoSuggestionsTagSuggestion o) {
  buildCounterVideoSuggestionsTagSuggestion++;
  if (buildCounterVideoSuggestionsTagSuggestion < 3) {
    checkUnnamed3003(o.categoryRestricts!);
    unittest.expect(
      o.tag!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoSuggestionsTagSuggestion--;
}

core.List<core.String> buildUnnamed3004() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3004(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3005() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3005(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3006() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3006(core.List<core.String> o) {
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

core.int buildCounterVideoTopicDetails = 0;
api.VideoTopicDetails buildVideoTopicDetails() {
  var o = api.VideoTopicDetails();
  buildCounterVideoTopicDetails++;
  if (buildCounterVideoTopicDetails < 3) {
    o.relevantTopicIds = buildUnnamed3004();
    o.topicCategories = buildUnnamed3005();
    o.topicIds = buildUnnamed3006();
  }
  buildCounterVideoTopicDetails--;
  return o;
}

void checkVideoTopicDetails(api.VideoTopicDetails o) {
  buildCounterVideoTopicDetails++;
  if (buildCounterVideoTopicDetails < 3) {
    checkUnnamed3004(o.relevantTopicIds!);
    checkUnnamed3005(o.topicCategories!);
    checkUnnamed3006(o.topicIds!);
  }
  buildCounterVideoTopicDetails--;
}

core.int buildCounterWatchSettings = 0;
api.WatchSettings buildWatchSettings() {
  var o = api.WatchSettings();
  buildCounterWatchSettings++;
  if (buildCounterWatchSettings < 3) {
    o.backgroundColor = 'foo';
    o.featuredPlaylistId = 'foo';
    o.textColor = 'foo';
  }
  buildCounterWatchSettings--;
  return o;
}

void checkWatchSettings(api.WatchSettings o) {
  buildCounterWatchSettings++;
  if (buildCounterWatchSettings < 3) {
    unittest.expect(
      o.backgroundColor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.featuredPlaylistId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.textColor!,
      unittest.equals('foo'),
    );
  }
  buildCounterWatchSettings--;
}

core.List<core.String> buildUnnamed3007() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3007(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3008() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3008(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3009() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3009(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3010() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3010(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3011() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3011(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3012() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3012(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3013() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3013(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3014() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3014(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3015() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3015(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3016() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3016(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3017() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3017(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3018() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3018(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3019() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3019(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3020() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3020(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3021() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3021(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3022() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3022(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3023() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3023(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3024() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3024(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3025() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3025(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3026() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3026(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3027() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3027(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3028() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3028(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3029() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3029(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3030() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3030(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3031() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3031(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3032() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3032(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3033() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3033(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3034() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3034(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3035() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3035(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3036() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3036(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3037() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3037(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3038() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3038(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3039() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3039(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3040() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3040(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3041() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3041(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3042() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3042(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3043() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3043(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3044() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3044(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3045() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3045(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3046() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3046(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3047() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3047(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3048() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3048(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3049() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3049(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3050() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3050(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3051() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3051(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3052() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3052(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3053() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3053(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3054() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3054(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3055() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3055(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3056() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3056(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3057() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3057(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3058() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3058(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3059() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3059(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3060() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3060(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3061() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3061(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3062() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3062(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3063() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3063(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3064() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3064(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3065() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3065(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3066() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3066(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3067() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3067(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3068() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3068(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3069() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3069(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3070() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3070(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3071() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3071(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3072() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3072(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3073() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3073(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3074() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3074(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3075() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3075(core.List<core.String> o) {
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
  unittest.group('obj-schema-AbuseReport', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAbuseReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AbuseReport.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAbuseReport(od as api.AbuseReport);
    });
  });

  unittest.group('obj-schema-AbuseType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAbuseType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AbuseType.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAbuseType(od as api.AbuseType);
    });
  });

  unittest.group('obj-schema-AccessPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessPolicy(od as api.AccessPolicy);
    });
  });

  unittest.group('obj-schema-Activity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Activity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkActivity(od as api.Activity);
    });
  });

  unittest.group('obj-schema-ActivityContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetails(od as api.ActivityContentDetails);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsBulletin', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsBulletin();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsBulletin.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsBulletin(
          od as api.ActivityContentDetailsBulletin);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsChannelItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsChannelItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsChannelItem.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsChannelItem(
          od as api.ActivityContentDetailsChannelItem);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsComment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsComment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsComment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsComment(
          od as api.ActivityContentDetailsComment);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsFavorite', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsFavorite();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsFavorite.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsFavorite(
          od as api.ActivityContentDetailsFavorite);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsLike', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsLike();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsLike.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsLike(od as api.ActivityContentDetailsLike);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsPlaylistItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsPlaylistItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsPlaylistItem.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsPlaylistItem(
          od as api.ActivityContentDetailsPlaylistItem);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsPromotedItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsPromotedItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsPromotedItem.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsPromotedItem(
          od as api.ActivityContentDetailsPromotedItem);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsRecommendation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsRecommendation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsRecommendation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsRecommendation(
          od as api.ActivityContentDetailsRecommendation);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsSocial', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsSocial();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsSocial.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsSocial(od as api.ActivityContentDetailsSocial);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsSubscription', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsSubscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsSubscription.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsSubscription(
          od as api.ActivityContentDetailsSubscription);
    });
  });

  unittest.group('obj-schema-ActivityContentDetailsUpload', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityContentDetailsUpload();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityContentDetailsUpload.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityContentDetailsUpload(od as api.ActivityContentDetailsUpload);
    });
  });

  unittest.group('obj-schema-ActivityListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityListResponse(od as api.ActivityListResponse);
    });
  });

  unittest.group('obj-schema-ActivitySnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivitySnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivitySnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivitySnippet(od as api.ActivitySnippet);
    });
  });

  unittest.group('obj-schema-Caption', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCaption();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Caption.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCaption(od as api.Caption);
    });
  });

  unittest.group('obj-schema-CaptionListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCaptionListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CaptionListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCaptionListResponse(od as api.CaptionListResponse);
    });
  });

  unittest.group('obj-schema-CaptionSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCaptionSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CaptionSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCaptionSnippet(od as api.CaptionSnippet);
    });
  });

  unittest.group('obj-schema-CdnSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCdnSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CdnSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCdnSettings(od as api.CdnSettings);
    });
  });

  unittest.group('obj-schema-Channel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Channel.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChannel(od as api.Channel);
    });
  });

  unittest.group('obj-schema-ChannelAuditDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelAuditDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelAuditDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelAuditDetails(od as api.ChannelAuditDetails);
    });
  });

  unittest.group('obj-schema-ChannelBannerResource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelBannerResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelBannerResource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelBannerResource(od as api.ChannelBannerResource);
    });
  });

  unittest.group('obj-schema-ChannelBrandingSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelBrandingSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelBrandingSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelBrandingSettings(od as api.ChannelBrandingSettings);
    });
  });

  unittest.group('obj-schema-ChannelContentDetailsRelatedPlaylists', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelContentDetailsRelatedPlaylists();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelContentDetailsRelatedPlaylists.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelContentDetailsRelatedPlaylists(
          od as api.ChannelContentDetailsRelatedPlaylists);
    });
  });

  unittest.group('obj-schema-ChannelContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelContentDetails(od as api.ChannelContentDetails);
    });
  });

  unittest.group('obj-schema-ChannelContentOwnerDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelContentOwnerDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelContentOwnerDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelContentOwnerDetails(od as api.ChannelContentOwnerDetails);
    });
  });

  unittest.group('obj-schema-ChannelConversionPing', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelConversionPing();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelConversionPing.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelConversionPing(od as api.ChannelConversionPing);
    });
  });

  unittest.group('obj-schema-ChannelConversionPings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelConversionPings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelConversionPings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelConversionPings(od as api.ChannelConversionPings);
    });
  });

  unittest.group('obj-schema-ChannelListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelListResponse(od as api.ChannelListResponse);
    });
  });

  unittest.group('obj-schema-ChannelLocalization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelLocalization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelLocalization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelLocalization(od as api.ChannelLocalization);
    });
  });

  unittest.group('obj-schema-ChannelProfileDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelProfileDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelProfileDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelProfileDetails(od as api.ChannelProfileDetails);
    });
  });

  unittest.group('obj-schema-ChannelSection', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSection.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSection(od as api.ChannelSection);
    });
  });

  unittest.group('obj-schema-ChannelSectionContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSectionContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSectionContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSectionContentDetails(od as api.ChannelSectionContentDetails);
    });
  });

  unittest.group('obj-schema-ChannelSectionListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSectionListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSectionListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSectionListResponse(od as api.ChannelSectionListResponse);
    });
  });

  unittest.group('obj-schema-ChannelSectionLocalization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSectionLocalization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSectionLocalization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSectionLocalization(od as api.ChannelSectionLocalization);
    });
  });

  unittest.group('obj-schema-ChannelSectionSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSectionSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSectionSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSectionSnippet(od as api.ChannelSectionSnippet);
    });
  });

  unittest.group('obj-schema-ChannelSectionTargeting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSectionTargeting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSectionTargeting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSectionTargeting(od as api.ChannelSectionTargeting);
    });
  });

  unittest.group('obj-schema-ChannelSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSettings(od as api.ChannelSettings);
    });
  });

  unittest.group('obj-schema-ChannelSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelSnippet(od as api.ChannelSnippet);
    });
  });

  unittest.group('obj-schema-ChannelStatistics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelStatistics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelStatistics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelStatistics(od as api.ChannelStatistics);
    });
  });

  unittest.group('obj-schema-ChannelStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelStatus(od as api.ChannelStatus);
    });
  });

  unittest.group('obj-schema-ChannelToStoreLinkDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelToStoreLinkDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelToStoreLinkDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelToStoreLinkDetails(od as api.ChannelToStoreLinkDetails);
    });
  });

  unittest.group('obj-schema-ChannelTopicDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelTopicDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelTopicDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelTopicDetails(od as api.ChannelTopicDetails);
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

  unittest.group('obj-schema-CommentListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommentListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommentListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommentListResponse(od as api.CommentListResponse);
    });
  });

  unittest.group('obj-schema-CommentSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommentSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommentSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommentSnippet(od as api.CommentSnippet);
    });
  });

  unittest.group('obj-schema-CommentSnippetAuthorChannelId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommentSnippetAuthorChannelId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommentSnippetAuthorChannelId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommentSnippetAuthorChannelId(
          od as api.CommentSnippetAuthorChannelId);
    });
  });

  unittest.group('obj-schema-CommentThread', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommentThread();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommentThread.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommentThread(od as api.CommentThread);
    });
  });

  unittest.group('obj-schema-CommentThreadListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommentThreadListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommentThreadListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommentThreadListResponse(od as api.CommentThreadListResponse);
    });
  });

  unittest.group('obj-schema-CommentThreadReplies', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommentThreadReplies();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommentThreadReplies.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommentThreadReplies(od as api.CommentThreadReplies);
    });
  });

  unittest.group('obj-schema-CommentThreadSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommentThreadSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommentThreadSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommentThreadSnippet(od as api.CommentThreadSnippet);
    });
  });

  unittest.group('obj-schema-ContentRating', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContentRating();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContentRating.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContentRating(od as api.ContentRating);
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

  unittest.group('obj-schema-GeoPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGeoPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GeoPoint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGeoPoint(od as api.GeoPoint);
    });
  });

  unittest.group('obj-schema-I18nLanguage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildI18nLanguage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.I18nLanguage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkI18nLanguage(od as api.I18nLanguage);
    });
  });

  unittest.group('obj-schema-I18nLanguageListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildI18nLanguageListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.I18nLanguageListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkI18nLanguageListResponse(od as api.I18nLanguageListResponse);
    });
  });

  unittest.group('obj-schema-I18nLanguageSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildI18nLanguageSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.I18nLanguageSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkI18nLanguageSnippet(od as api.I18nLanguageSnippet);
    });
  });

  unittest.group('obj-schema-I18nRegion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildI18nRegion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.I18nRegion.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkI18nRegion(od as api.I18nRegion);
    });
  });

  unittest.group('obj-schema-I18nRegionListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildI18nRegionListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.I18nRegionListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkI18nRegionListResponse(od as api.I18nRegionListResponse);
    });
  });

  unittest.group('obj-schema-I18nRegionSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildI18nRegionSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.I18nRegionSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkI18nRegionSnippet(od as api.I18nRegionSnippet);
    });
  });

  unittest.group('obj-schema-ImageSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImageSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImageSettings(od as api.ImageSettings);
    });
  });

  unittest.group('obj-schema-IngestionInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIngestionInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IngestionInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIngestionInfo(od as api.IngestionInfo);
    });
  });

  unittest.group('obj-schema-InvideoBranding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInvideoBranding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InvideoBranding.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInvideoBranding(od as api.InvideoBranding);
    });
  });

  unittest.group('obj-schema-InvideoPosition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInvideoPosition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InvideoPosition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInvideoPosition(od as api.InvideoPosition);
    });
  });

  unittest.group('obj-schema-InvideoTiming', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInvideoTiming();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InvideoTiming.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInvideoTiming(od as api.InvideoTiming);
    });
  });

  unittest.group('obj-schema-LanguageTag', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLanguageTag();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LanguageTag.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLanguageTag(od as api.LanguageTag);
    });
  });

  unittest.group('obj-schema-LevelDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLevelDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LevelDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLevelDetails(od as api.LevelDetails);
    });
  });

  unittest.group('obj-schema-LiveBroadcast', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveBroadcast();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveBroadcast.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveBroadcast(od as api.LiveBroadcast);
    });
  });

  unittest.group('obj-schema-LiveBroadcastContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveBroadcastContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveBroadcastContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveBroadcastContentDetails(od as api.LiveBroadcastContentDetails);
    });
  });

  unittest.group('obj-schema-LiveBroadcastListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveBroadcastListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveBroadcastListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveBroadcastListResponse(od as api.LiveBroadcastListResponse);
    });
  });

  unittest.group('obj-schema-LiveBroadcastSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveBroadcastSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveBroadcastSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveBroadcastSnippet(od as api.LiveBroadcastSnippet);
    });
  });

  unittest.group('obj-schema-LiveBroadcastStatistics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveBroadcastStatistics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveBroadcastStatistics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveBroadcastStatistics(od as api.LiveBroadcastStatistics);
    });
  });

  unittest.group('obj-schema-LiveBroadcastStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveBroadcastStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveBroadcastStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveBroadcastStatus(od as api.LiveBroadcastStatus);
    });
  });

  unittest.group('obj-schema-LiveChatBan', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatBan();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatBan.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatBan(od as api.LiveChatBan);
    });
  });

  unittest.group('obj-schema-LiveChatBanSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatBanSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatBanSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatBanSnippet(od as api.LiveChatBanSnippet);
    });
  });

  unittest.group('obj-schema-LiveChatFanFundingEventDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatFanFundingEventDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatFanFundingEventDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatFanFundingEventDetails(
          od as api.LiveChatFanFundingEventDetails);
    });
  });

  unittest.group('obj-schema-LiveChatMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatMessage(od as api.LiveChatMessage);
    });
  });

  unittest.group('obj-schema-LiveChatMessageAuthorDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatMessageAuthorDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatMessageAuthorDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatMessageAuthorDetails(od as api.LiveChatMessageAuthorDetails);
    });
  });

  unittest.group('obj-schema-LiveChatMessageDeletedDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatMessageDeletedDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatMessageDeletedDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatMessageDeletedDetails(
          od as api.LiveChatMessageDeletedDetails);
    });
  });

  unittest.group('obj-schema-LiveChatMessageListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatMessageListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatMessageListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatMessageListResponse(od as api.LiveChatMessageListResponse);
    });
  });

  unittest.group('obj-schema-LiveChatMessageRetractedDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatMessageRetractedDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatMessageRetractedDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatMessageRetractedDetails(
          od as api.LiveChatMessageRetractedDetails);
    });
  });

  unittest.group('obj-schema-LiveChatMessageSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatMessageSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatMessageSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatMessageSnippet(od as api.LiveChatMessageSnippet);
    });
  });

  unittest.group('obj-schema-LiveChatModerator', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatModerator();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatModerator.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatModerator(od as api.LiveChatModerator);
    });
  });

  unittest.group('obj-schema-LiveChatModeratorListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatModeratorListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatModeratorListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatModeratorListResponse(
          od as api.LiveChatModeratorListResponse);
    });
  });

  unittest.group('obj-schema-LiveChatModeratorSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatModeratorSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatModeratorSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatModeratorSnippet(od as api.LiveChatModeratorSnippet);
    });
  });

  unittest.group('obj-schema-LiveChatSuperChatDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatSuperChatDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatSuperChatDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatSuperChatDetails(od as api.LiveChatSuperChatDetails);
    });
  });

  unittest.group('obj-schema-LiveChatSuperStickerDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatSuperStickerDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatSuperStickerDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatSuperStickerDetails(od as api.LiveChatSuperStickerDetails);
    });
  });

  unittest.group('obj-schema-LiveChatTextMessageDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatTextMessageDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatTextMessageDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatTextMessageDetails(od as api.LiveChatTextMessageDetails);
    });
  });

  unittest.group('obj-schema-LiveChatUserBannedMessageDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveChatUserBannedMessageDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveChatUserBannedMessageDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveChatUserBannedMessageDetails(
          od as api.LiveChatUserBannedMessageDetails);
    });
  });

  unittest.group('obj-schema-LiveStream', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveStream();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LiveStream.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLiveStream(od as api.LiveStream);
    });
  });

  unittest.group('obj-schema-LiveStreamConfigurationIssue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveStreamConfigurationIssue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveStreamConfigurationIssue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveStreamConfigurationIssue(od as api.LiveStreamConfigurationIssue);
    });
  });

  unittest.group('obj-schema-LiveStreamContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveStreamContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveStreamContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveStreamContentDetails(od as api.LiveStreamContentDetails);
    });
  });

  unittest.group('obj-schema-LiveStreamHealthStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveStreamHealthStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveStreamHealthStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveStreamHealthStatus(od as api.LiveStreamHealthStatus);
    });
  });

  unittest.group('obj-schema-LiveStreamListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveStreamListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveStreamListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveStreamListResponse(od as api.LiveStreamListResponse);
    });
  });

  unittest.group('obj-schema-LiveStreamSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveStreamSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveStreamSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveStreamSnippet(od as api.LiveStreamSnippet);
    });
  });

  unittest.group('obj-schema-LiveStreamStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLiveStreamStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LiveStreamStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLiveStreamStatus(od as api.LiveStreamStatus);
    });
  });

  unittest.group('obj-schema-LocalizedProperty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalizedProperty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocalizedProperty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocalizedProperty(od as api.LocalizedProperty);
    });
  });

  unittest.group('obj-schema-LocalizedString', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalizedString();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocalizedString.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocalizedString(od as api.LocalizedString);
    });
  });

  unittest.group('obj-schema-Member', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMember();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Member.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMember(od as api.Member);
    });
  });

  unittest.group('obj-schema-MemberListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMemberListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MemberListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMemberListResponse(od as api.MemberListResponse);
    });
  });

  unittest.group('obj-schema-MemberSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMemberSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MemberSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMemberSnippet(od as api.MemberSnippet);
    });
  });

  unittest.group('obj-schema-MembershipsDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembershipsDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MembershipsDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMembershipsDetails(od as api.MembershipsDetails);
    });
  });

  unittest.group('obj-schema-MembershipsDuration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembershipsDuration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MembershipsDuration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMembershipsDuration(od as api.MembershipsDuration);
    });
  });

  unittest.group('obj-schema-MembershipsDurationAtLevel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembershipsDurationAtLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MembershipsDurationAtLevel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMembershipsDurationAtLevel(od as api.MembershipsDurationAtLevel);
    });
  });

  unittest.group('obj-schema-MembershipsLevel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembershipsLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MembershipsLevel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMembershipsLevel(od as api.MembershipsLevel);
    });
  });

  unittest.group('obj-schema-MembershipsLevelListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembershipsLevelListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MembershipsLevelListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMembershipsLevelListResponse(od as api.MembershipsLevelListResponse);
    });
  });

  unittest.group('obj-schema-MembershipsLevelSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembershipsLevelSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MembershipsLevelSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMembershipsLevelSnippet(od as api.MembershipsLevelSnippet);
    });
  });

  unittest.group('obj-schema-MonitorStreamInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMonitorStreamInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MonitorStreamInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMonitorStreamInfo(od as api.MonitorStreamInfo);
    });
  });

  unittest.group('obj-schema-PageInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPageInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PageInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPageInfo(od as api.PageInfo);
    });
  });

  unittest.group('obj-schema-Playlist', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylist();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Playlist.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPlaylist(od as api.Playlist);
    });
  });

  unittest.group('obj-schema-PlaylistContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistContentDetails(od as api.PlaylistContentDetails);
    });
  });

  unittest.group('obj-schema-PlaylistItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistItem.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistItem(od as api.PlaylistItem);
    });
  });

  unittest.group('obj-schema-PlaylistItemContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistItemContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistItemContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistItemContentDetails(od as api.PlaylistItemContentDetails);
    });
  });

  unittest.group('obj-schema-PlaylistItemListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistItemListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistItemListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistItemListResponse(od as api.PlaylistItemListResponse);
    });
  });

  unittest.group('obj-schema-PlaylistItemSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistItemSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistItemSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistItemSnippet(od as api.PlaylistItemSnippet);
    });
  });

  unittest.group('obj-schema-PlaylistItemStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistItemStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistItemStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistItemStatus(od as api.PlaylistItemStatus);
    });
  });

  unittest.group('obj-schema-PlaylistListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistListResponse(od as api.PlaylistListResponse);
    });
  });

  unittest.group('obj-schema-PlaylistLocalization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistLocalization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistLocalization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistLocalization(od as api.PlaylistLocalization);
    });
  });

  unittest.group('obj-schema-PlaylistPlayer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistPlayer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistPlayer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistPlayer(od as api.PlaylistPlayer);
    });
  });

  unittest.group('obj-schema-PlaylistSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistSnippet(od as api.PlaylistSnippet);
    });
  });

  unittest.group('obj-schema-PlaylistStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlaylistStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlaylistStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlaylistStatus(od as api.PlaylistStatus);
    });
  });

  unittest.group('obj-schema-PropertyValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPropertyValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PropertyValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPropertyValue(od as api.PropertyValue);
    });
  });

  unittest.group('obj-schema-RelatedEntity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRelatedEntity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RelatedEntity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRelatedEntity(od as api.RelatedEntity);
    });
  });

  unittest.group('obj-schema-ResourceId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ResourceId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResourceId(od as api.ResourceId);
    });
  });

  unittest.group('obj-schema-SearchListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchListResponse(od as api.SearchListResponse);
    });
  });

  unittest.group('obj-schema-SearchResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchResult(od as api.SearchResult);
    });
  });

  unittest.group('obj-schema-SearchResultSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchResultSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchResultSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchResultSnippet(od as api.SearchResultSnippet);
    });
  });

  unittest.group('obj-schema-Subscription', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Subscription.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscription(od as api.Subscription);
    });
  });

  unittest.group('obj-schema-SubscriptionContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionContentDetails(od as api.SubscriptionContentDetails);
    });
  });

  unittest.group('obj-schema-SubscriptionListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionListResponse(od as api.SubscriptionListResponse);
    });
  });

  unittest.group('obj-schema-SubscriptionSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionSnippet(od as api.SubscriptionSnippet);
    });
  });

  unittest.group('obj-schema-SubscriptionSubscriberSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionSubscriberSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionSubscriberSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionSubscriberSnippet(
          od as api.SubscriptionSubscriberSnippet);
    });
  });

  unittest.group('obj-schema-SuperChatEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuperChatEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SuperChatEvent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSuperChatEvent(od as api.SuperChatEvent);
    });
  });

  unittest.group('obj-schema-SuperChatEventListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuperChatEventListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SuperChatEventListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSuperChatEventListResponse(od as api.SuperChatEventListResponse);
    });
  });

  unittest.group('obj-schema-SuperChatEventSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuperChatEventSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SuperChatEventSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSuperChatEventSnippet(od as api.SuperChatEventSnippet);
    });
  });

  unittest.group('obj-schema-SuperStickerMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuperStickerMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SuperStickerMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSuperStickerMetadata(od as api.SuperStickerMetadata);
    });
  });

  unittest.group('obj-schema-TestItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TestItem.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTestItem(od as api.TestItem);
    });
  });

  unittest.group('obj-schema-TestItemTestItemSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestItemTestItemSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestItemTestItemSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestItemTestItemSnippet(od as api.TestItemTestItemSnippet);
    });
  });

  unittest.group('obj-schema-ThirdPartyLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThirdPartyLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThirdPartyLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThirdPartyLink(od as api.ThirdPartyLink);
    });
  });

  unittest.group('obj-schema-ThirdPartyLinkSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThirdPartyLinkSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThirdPartyLinkSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThirdPartyLinkSnippet(od as api.ThirdPartyLinkSnippet);
    });
  });

  unittest.group('obj-schema-ThirdPartyLinkStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThirdPartyLinkStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThirdPartyLinkStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThirdPartyLinkStatus(od as api.ThirdPartyLinkStatus);
    });
  });

  unittest.group('obj-schema-Thumbnail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThumbnail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Thumbnail.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkThumbnail(od as api.Thumbnail);
    });
  });

  unittest.group('obj-schema-ThumbnailDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThumbnailDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThumbnailDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThumbnailDetails(od as api.ThumbnailDetails);
    });
  });

  unittest.group('obj-schema-ThumbnailSetResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThumbnailSetResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThumbnailSetResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThumbnailSetResponse(od as api.ThumbnailSetResponse);
    });
  });

  unittest.group('obj-schema-TokenPagination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTokenPagination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TokenPagination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTokenPagination(od as api.TokenPagination);
    });
  });

  unittest.group('obj-schema-Video', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Video.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVideo(od as api.Video);
    });
  });

  unittest.group('obj-schema-VideoAbuseReport', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoAbuseReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoAbuseReport.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoAbuseReport(od as api.VideoAbuseReport);
    });
  });

  unittest.group('obj-schema-VideoAbuseReportReason', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoAbuseReportReason();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoAbuseReportReason.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoAbuseReportReason(od as api.VideoAbuseReportReason);
    });
  });

  unittest.group('obj-schema-VideoAbuseReportReasonListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoAbuseReportReasonListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoAbuseReportReasonListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoAbuseReportReasonListResponse(
          od as api.VideoAbuseReportReasonListResponse);
    });
  });

  unittest.group('obj-schema-VideoAbuseReportReasonSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoAbuseReportReasonSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoAbuseReportReasonSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoAbuseReportReasonSnippet(
          od as api.VideoAbuseReportReasonSnippet);
    });
  });

  unittest.group('obj-schema-VideoAbuseReportSecondaryReason', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoAbuseReportSecondaryReason();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoAbuseReportSecondaryReason.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoAbuseReportSecondaryReason(
          od as api.VideoAbuseReportSecondaryReason);
    });
  });

  unittest.group('obj-schema-VideoAgeGating', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoAgeGating();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoAgeGating.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoAgeGating(od as api.VideoAgeGating);
    });
  });

  unittest.group('obj-schema-VideoCategory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoCategory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoCategory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoCategory(od as api.VideoCategory);
    });
  });

  unittest.group('obj-schema-VideoCategoryListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoCategoryListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoCategoryListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoCategoryListResponse(od as api.VideoCategoryListResponse);
    });
  });

  unittest.group('obj-schema-VideoCategorySnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoCategorySnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoCategorySnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoCategorySnippet(od as api.VideoCategorySnippet);
    });
  });

  unittest.group('obj-schema-VideoContentDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoContentDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoContentDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoContentDetails(od as api.VideoContentDetails);
    });
  });

  unittest.group('obj-schema-VideoContentDetailsRegionRestriction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoContentDetailsRegionRestriction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoContentDetailsRegionRestriction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoContentDetailsRegionRestriction(
          od as api.VideoContentDetailsRegionRestriction);
    });
  });

  unittest.group('obj-schema-VideoFileDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoFileDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoFileDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoFileDetails(od as api.VideoFileDetails);
    });
  });

  unittest.group('obj-schema-VideoFileDetailsAudioStream', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoFileDetailsAudioStream();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoFileDetailsAudioStream.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoFileDetailsAudioStream(od as api.VideoFileDetailsAudioStream);
    });
  });

  unittest.group('obj-schema-VideoFileDetailsVideoStream', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoFileDetailsVideoStream();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoFileDetailsVideoStream.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoFileDetailsVideoStream(od as api.VideoFileDetailsVideoStream);
    });
  });

  unittest.group('obj-schema-VideoGetRatingResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoGetRatingResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoGetRatingResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoGetRatingResponse(od as api.VideoGetRatingResponse);
    });
  });

  unittest.group('obj-schema-VideoListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoListResponse(od as api.VideoListResponse);
    });
  });

  unittest.group('obj-schema-VideoLiveStreamingDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoLiveStreamingDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoLiveStreamingDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoLiveStreamingDetails(od as api.VideoLiveStreamingDetails);
    });
  });

  unittest.group('obj-schema-VideoLocalization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoLocalization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoLocalization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoLocalization(od as api.VideoLocalization);
    });
  });

  unittest.group('obj-schema-VideoMonetizationDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoMonetizationDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoMonetizationDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoMonetizationDetails(od as api.VideoMonetizationDetails);
    });
  });

  unittest.group('obj-schema-VideoPlayer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoPlayer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoPlayer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoPlayer(od as api.VideoPlayer);
    });
  });

  unittest.group('obj-schema-VideoProcessingDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoProcessingDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoProcessingDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoProcessingDetails(od as api.VideoProcessingDetails);
    });
  });

  unittest.group('obj-schema-VideoProcessingDetailsProcessingProgress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoProcessingDetailsProcessingProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoProcessingDetailsProcessingProgress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoProcessingDetailsProcessingProgress(
          od as api.VideoProcessingDetailsProcessingProgress);
    });
  });

  unittest.group('obj-schema-VideoProjectDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoProjectDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoProjectDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoProjectDetails(od as api.VideoProjectDetails);
    });
  });

  unittest.group('obj-schema-VideoRating', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoRating();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoRating.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoRating(od as api.VideoRating);
    });
  });

  unittest.group('obj-schema-VideoRecordingDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoRecordingDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoRecordingDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoRecordingDetails(od as api.VideoRecordingDetails);
    });
  });

  unittest.group('obj-schema-VideoSnippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoSnippet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoSnippet(od as api.VideoSnippet);
    });
  });

  unittest.group('obj-schema-VideoStatistics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoStatistics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoStatistics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoStatistics(od as api.VideoStatistics);
    });
  });

  unittest.group('obj-schema-VideoStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoStatus(od as api.VideoStatus);
    });
  });

  unittest.group('obj-schema-VideoSuggestions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoSuggestions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoSuggestions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoSuggestions(od as api.VideoSuggestions);
    });
  });

  unittest.group('obj-schema-VideoSuggestionsTagSuggestion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoSuggestionsTagSuggestion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoSuggestionsTagSuggestion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoSuggestionsTagSuggestion(
          od as api.VideoSuggestionsTagSuggestion);
    });
  });

  unittest.group('obj-schema-VideoTopicDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoTopicDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoTopicDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoTopicDetails(od as api.VideoTopicDetails);
    });
  });

  unittest.group('obj-schema-WatchSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWatchSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WatchSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWatchSettings(od as api.WatchSettings);
    });
  });

  unittest.group('resource-AbuseReportsResource', () {
    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).abuseReports;
      var arg_request = buildAbuseReport();
      var arg_part = buildUnnamed3007();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AbuseReport.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAbuseReport(obj as api.AbuseReport);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("youtube/v3/abuseReports"),
        );
        pathOffset += 23;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAbuseReport());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkAbuseReport(response as api.AbuseReport);
    });
  });

  unittest.group('resource-ActivitiesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).activities;
      var arg_part = buildUnnamed3008();
      var arg_channelId = 'foo';
      var arg_home = true;
      var arg_maxResults = 42;
      var arg_mine = true;
      var arg_pageToken = 'foo';
      var arg_publishedAfter = 'foo';
      var arg_publishedBefore = 'foo';
      var arg_regionCode = 'foo';
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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("youtube/v3/activities"),
        );
        pathOffset += 21;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["home"]!.first,
          unittest.equals("$arg_home"),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["mine"]!.first,
          unittest.equals("$arg_mine"),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["publishedAfter"]!.first,
          unittest.equals(arg_publishedAfter),
        );
        unittest.expect(
          queryMap["publishedBefore"]!.first,
          unittest.equals(arg_publishedBefore),
        );
        unittest.expect(
          queryMap["regionCode"]!.first,
          unittest.equals(arg_regionCode),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildActivityListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          channelId: arg_channelId,
          home: arg_home,
          maxResults: arg_maxResults,
          mine: arg_mine,
          pageToken: arg_pageToken,
          publishedAfter: arg_publishedAfter,
          publishedBefore: arg_publishedBefore,
          regionCode: arg_regionCode,
          $fields: arg_$fields);
      checkActivityListResponse(response as api.ActivityListResponse);
    });
  });

  unittest.group('resource-CaptionsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).captions;
      var arg_id = 'foo';
      var arg_onBehalfOf = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/captions"),
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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOf"]!.first,
          unittest.equals(arg_onBehalfOf),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id,
          onBehalfOf: arg_onBehalfOf,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });

    unittest.test('method--download', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).captions;
      var arg_id = 'foo';
      var arg_onBehalfOf = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_tfmt = 'foo';
      var arg_tlang = 'foo';
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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("youtube/v3/captions/"),
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
          queryMap["onBehalfOf"]!.first,
          unittest.equals(arg_onBehalfOf),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["tfmt"]!.first,
          unittest.equals(arg_tfmt),
        );
        unittest.expect(
          queryMap["tlang"]!.first,
          unittest.equals(arg_tlang),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.download(arg_id,
          onBehalfOf: arg_onBehalfOf,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          tfmt: arg_tfmt,
          tlang: arg_tlang,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).captions;
      var arg_request = buildCaption();
      var arg_part = buildUnnamed3009();
      var arg_onBehalfOf = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_sync = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Caption.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCaption(obj as api.Caption);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/captions"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOf"]!.first,
          unittest.equals(arg_onBehalfOf),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["sync"]!.first,
          unittest.equals("$arg_sync"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCaption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_part,
          onBehalfOf: arg_onBehalfOf,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          sync: arg_sync,
          $fields: arg_$fields);
      checkCaption(response as api.Caption);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).captions;
      var arg_part = buildUnnamed3010();
      var arg_videoId = 'foo';
      var arg_id = buildUnnamed3011();
      var arg_onBehalfOf = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/captions"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["videoId"]!.first,
          unittest.equals(arg_videoId),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOf"]!.first,
          unittest.equals(arg_onBehalfOf),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCaptionListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part, arg_videoId,
          id: arg_id,
          onBehalfOf: arg_onBehalfOf,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkCaptionListResponse(response as api.CaptionListResponse);
    });

    unittest.test('method--update', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).captions;
      var arg_request = buildCaption();
      var arg_part = buildUnnamed3012();
      var arg_onBehalfOf = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_sync = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Caption.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCaption(obj as api.Caption);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/captions"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOf"]!.first,
          unittest.equals(arg_onBehalfOf),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["sync"]!.first,
          unittest.equals("$arg_sync"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCaption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOf: arg_onBehalfOf,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          sync: arg_sync,
          $fields: arg_$fields);
      checkCaption(response as api.Caption);
    });
  });

  unittest.group('resource-ChannelBannersResource', () {
    unittest.test('method--insert', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).channelBanners;
      var arg_request = buildChannelBannerResource();
      var arg_channelId = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChannelBannerResource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChannelBannerResource(obj as api.ChannelBannerResource);

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
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("youtube/v3/channelBanners/insert"),
        );
        pathOffset += 32;

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
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannelBannerResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request,
          channelId: arg_channelId,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkChannelBannerResource(response as api.ChannelBannerResource);
    });
  });

  unittest.group('resource-ChannelSectionsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).channelSections;
      var arg_id = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("youtube/v3/channelSections"),
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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).channelSections;
      var arg_request = buildChannelSection();
      var arg_part = buildUnnamed3013();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChannelSection.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChannelSection(obj as api.ChannelSection);

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
          unittest.equals("youtube/v3/channelSections"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannelSection());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkChannelSection(response as api.ChannelSection);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).channelSections;
      var arg_part = buildUnnamed3014();
      var arg_channelId = 'foo';
      var arg_hl = 'foo';
      var arg_id = buildUnnamed3015();
      var arg_mine = true;
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("youtube/v3/channelSections"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["mine"]!.first,
          unittest.equals("$arg_mine"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannelSectionListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          channelId: arg_channelId,
          hl: arg_hl,
          id: arg_id,
          mine: arg_mine,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkChannelSectionListResponse(
          response as api.ChannelSectionListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).channelSections;
      var arg_request = buildChannelSection();
      var arg_part = buildUnnamed3016();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChannelSection.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChannelSection(obj as api.ChannelSection);

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
          unittest.equals("youtube/v3/channelSections"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannelSection());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkChannelSection(response as api.ChannelSection);
    });
  });

  unittest.group('resource-ChannelsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).channels;
      var arg_part = buildUnnamed3017();
      var arg_categoryId = 'foo';
      var arg_forUsername = 'foo';
      var arg_hl = 'foo';
      var arg_id = buildUnnamed3018();
      var arg_managedByMe = true;
      var arg_maxResults = 42;
      var arg_mine = true;
      var arg_mySubscribers = true;
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/channels"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["categoryId"]!.first,
          unittest.equals(arg_categoryId),
        );
        unittest.expect(
          queryMap["forUsername"]!.first,
          unittest.equals(arg_forUsername),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["managedByMe"]!.first,
          unittest.equals("$arg_managedByMe"),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["mine"]!.first,
          unittest.equals("$arg_mine"),
        );
        unittest.expect(
          queryMap["mySubscribers"]!.first,
          unittest.equals("$arg_mySubscribers"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
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
        var resp = convert.json.encode(buildChannelListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          categoryId: arg_categoryId,
          forUsername: arg_forUsername,
          hl: arg_hl,
          id: arg_id,
          managedByMe: arg_managedByMe,
          maxResults: arg_maxResults,
          mine: arg_mine,
          mySubscribers: arg_mySubscribers,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkChannelListResponse(response as api.ChannelListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).channels;
      var arg_request = buildChannel();
      var arg_part = buildUnnamed3019();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Channel.fromJson(json as core.Map<core.String, core.dynamic>);
        checkChannel(obj as api.Channel);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/channels"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });
  });

  unittest.group('resource-CommentThreadsResource', () {
    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).commentThreads;
      var arg_request = buildCommentThread();
      var arg_part = buildUnnamed3020();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CommentThread.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCommentThread(obj as api.CommentThread);

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
          unittest.equals("youtube/v3/commentThreads"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCommentThread());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkCommentThread(response as api.CommentThread);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).commentThreads;
      var arg_part = buildUnnamed3021();
      var arg_allThreadsRelatedToChannelId = 'foo';
      var arg_channelId = 'foo';
      var arg_id = buildUnnamed3022();
      var arg_maxResults = 42;
      var arg_moderationStatus = 'foo';
      var arg_order = 'foo';
      var arg_pageToken = 'foo';
      var arg_searchTerms = 'foo';
      var arg_textFormat = 'foo';
      var arg_videoId = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("youtube/v3/commentThreads"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["allThreadsRelatedToChannelId"]!.first,
          unittest.equals(arg_allThreadsRelatedToChannelId),
        );
        unittest.expect(
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["moderationStatus"]!.first,
          unittest.equals(arg_moderationStatus),
        );
        unittest.expect(
          queryMap["order"]!.first,
          unittest.equals(arg_order),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["searchTerms"]!.first,
          unittest.equals(arg_searchTerms),
        );
        unittest.expect(
          queryMap["textFormat"]!.first,
          unittest.equals(arg_textFormat),
        );
        unittest.expect(
          queryMap["videoId"]!.first,
          unittest.equals(arg_videoId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCommentThreadListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          allThreadsRelatedToChannelId: arg_allThreadsRelatedToChannelId,
          channelId: arg_channelId,
          id: arg_id,
          maxResults: arg_maxResults,
          moderationStatus: arg_moderationStatus,
          order: arg_order,
          pageToken: arg_pageToken,
          searchTerms: arg_searchTerms,
          textFormat: arg_textFormat,
          videoId: arg_videoId,
          $fields: arg_$fields);
      checkCommentThreadListResponse(response as api.CommentThreadListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).commentThreads;
      var arg_request = buildCommentThread();
      var arg_part = buildUnnamed3023();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CommentThread.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCommentThread(obj as api.CommentThread);

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
          unittest.equals("youtube/v3/commentThreads"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCommentThread());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_part, $fields: arg_$fields);
      checkCommentThread(response as api.CommentThread);
    });
  });

  unittest.group('resource-CommentsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).comments;
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/comments"),
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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).comments;
      var arg_request = buildComment();
      var arg_part = buildUnnamed3024();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Comment.fromJson(json as core.Map<core.String, core.dynamic>);
        checkComment(obj as api.Comment);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/comments"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildComment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkComment(response as api.Comment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).comments;
      var arg_part = buildUnnamed3025();
      var arg_id = buildUnnamed3026();
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_parentId = 'foo';
      var arg_textFormat = 'foo';
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/comments"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parentId"]!.first,
          unittest.equals(arg_parentId),
        );
        unittest.expect(
          queryMap["textFormat"]!.first,
          unittest.equals(arg_textFormat),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCommentListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          id: arg_id,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          parentId: arg_parentId,
          textFormat: arg_textFormat,
          $fields: arg_$fields);
      checkCommentListResponse(response as api.CommentListResponse);
    });

    unittest.test('method--markAsSpam', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).comments;
      var arg_id = buildUnnamed3027();
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("youtube/v3/comments/markAsSpam"),
        );
        pathOffset += 30;

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
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.markAsSpam(arg_id, $fields: arg_$fields);
    });

    unittest.test('method--setModerationStatus', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).comments;
      var arg_id = buildUnnamed3028();
      var arg_moderationStatus = 'foo';
      var arg_banAuthor = true;
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
          path.substring(pathOffset, pathOffset + 39),
          unittest.equals("youtube/v3/comments/setModerationStatus"),
        );
        pathOffset += 39;

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
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["moderationStatus"]!.first,
          unittest.equals(arg_moderationStatus),
        );
        unittest.expect(
          queryMap["banAuthor"]!.first,
          unittest.equals("$arg_banAuthor"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.setModerationStatus(arg_id, arg_moderationStatus,
          banAuthor: arg_banAuthor, $fields: arg_$fields);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).comments;
      var arg_request = buildComment();
      var arg_part = buildUnnamed3029();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Comment.fromJson(json as core.Map<core.String, core.dynamic>);
        checkComment(obj as api.Comment);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("youtube/v3/comments"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildComment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_part, $fields: arg_$fields);
      checkComment(response as api.Comment);
    });
  });

  unittest.group('resource-I18nLanguagesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).i18nLanguages;
      var arg_part = buildUnnamed3030();
      var arg_hl = 'foo';
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/i18nLanguages"),
        );
        pathOffset += 24;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildI18nLanguageListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_part, hl: arg_hl, $fields: arg_$fields);
      checkI18nLanguageListResponse(response as api.I18nLanguageListResponse);
    });
  });

  unittest.group('resource-I18nRegionsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).i18nRegions;
      var arg_part = buildUnnamed3031();
      var arg_hl = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("youtube/v3/i18nRegions"),
        );
        pathOffset += 22;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildI18nRegionListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_part, hl: arg_hl, $fields: arg_$fields);
      checkI18nRegionListResponse(response as api.I18nRegionListResponse);
    });
  });

  unittest.group('resource-LiveBroadcastsResource', () {
    unittest.test('method--bind', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveBroadcasts;
      var arg_id = 'foo';
      var arg_part = buildUnnamed3032();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_streamId = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("youtube/v3/liveBroadcasts/bind"),
        );
        pathOffset += 30;

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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["streamId"]!.first,
          unittest.equals(arg_streamId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveBroadcast());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bind(arg_id, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          streamId: arg_streamId,
          $fields: arg_$fields);
      checkLiveBroadcast(response as api.LiveBroadcast);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveBroadcasts;
      var arg_id = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("youtube/v3/liveBroadcasts"),
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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveBroadcasts;
      var arg_request = buildLiveBroadcast();
      var arg_part = buildUnnamed3033();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LiveBroadcast.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLiveBroadcast(obj as api.LiveBroadcast);

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
          unittest.equals("youtube/v3/liveBroadcasts"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveBroadcast());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkLiveBroadcast(response as api.LiveBroadcast);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveBroadcasts;
      var arg_part = buildUnnamed3034();
      var arg_broadcastStatus = 'foo';
      var arg_broadcastType = 'foo';
      var arg_id = buildUnnamed3035();
      var arg_maxResults = 42;
      var arg_mine = true;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("youtube/v3/liveBroadcasts"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["broadcastStatus"]!.first,
          unittest.equals(arg_broadcastStatus),
        );
        unittest.expect(
          queryMap["broadcastType"]!.first,
          unittest.equals(arg_broadcastType),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["mine"]!.first,
          unittest.equals("$arg_mine"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
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
        var resp = convert.json.encode(buildLiveBroadcastListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          broadcastStatus: arg_broadcastStatus,
          broadcastType: arg_broadcastType,
          id: arg_id,
          maxResults: arg_maxResults,
          mine: arg_mine,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkLiveBroadcastListResponse(response as api.LiveBroadcastListResponse);
    });

    unittest.test('method--transition', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveBroadcasts;
      var arg_broadcastStatus = 'foo';
      var arg_id = 'foo';
      var arg_part = buildUnnamed3036();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
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
          path.substring(pathOffset, pathOffset + 36),
          unittest.equals("youtube/v3/liveBroadcasts/transition"),
        );
        pathOffset += 36;

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
          queryMap["broadcastStatus"]!.first,
          unittest.equals(arg_broadcastStatus),
        );
        unittest.expect(
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveBroadcast());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.transition(
          arg_broadcastStatus, arg_id, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkLiveBroadcast(response as api.LiveBroadcast);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveBroadcasts;
      var arg_request = buildLiveBroadcast();
      var arg_part = buildUnnamed3037();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LiveBroadcast.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLiveBroadcast(obj as api.LiveBroadcast);

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
          unittest.equals("youtube/v3/liveBroadcasts"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveBroadcast());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkLiveBroadcast(response as api.LiveBroadcast);
    });
  });

  unittest.group('resource-LiveChatBansResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatBans;
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/liveChat/bans"),
        );
        pathOffset += 24;

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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatBans;
      var arg_request = buildLiveChatBan();
      var arg_part = buildUnnamed3038();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LiveChatBan.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLiveChatBan(obj as api.LiveChatBan);

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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/liveChat/bans"),
        );
        pathOffset += 24;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveChatBan());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkLiveChatBan(response as api.LiveChatBan);
    });
  });

  unittest.group('resource-LiveChatMessagesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatMessages;
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("youtube/v3/liveChat/messages"),
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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatMessages;
      var arg_request = buildLiveChatMessage();
      var arg_part = buildUnnamed3039();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LiveChatMessage.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLiveChatMessage(obj as api.LiveChatMessage);

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
          unittest.equals("youtube/v3/liveChat/messages"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveChatMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkLiveChatMessage(response as api.LiveChatMessage);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatMessages;
      var arg_liveChatId = 'foo';
      var arg_part = buildUnnamed3040();
      var arg_hl = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_profileImageSize = 42;
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("youtube/v3/liveChat/messages"),
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
          queryMap["liveChatId"]!.first,
          unittest.equals(arg_liveChatId),
        );
        unittest.expect(
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          core.int.parse(queryMap["profileImageSize"]!.first),
          unittest.equals(arg_profileImageSize),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveChatMessageListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_liveChatId, arg_part,
          hl: arg_hl,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          profileImageSize: arg_profileImageSize,
          $fields: arg_$fields);
      checkLiveChatMessageListResponse(
          response as api.LiveChatMessageListResponse);
    });
  });

  unittest.group('resource-LiveChatModeratorsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatModerators;
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("youtube/v3/liveChat/moderators"),
        );
        pathOffset += 30;

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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatModerators;
      var arg_request = buildLiveChatModerator();
      var arg_part = buildUnnamed3041();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LiveChatModerator.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLiveChatModerator(obj as api.LiveChatModerator);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("youtube/v3/liveChat/moderators"),
        );
        pathOffset += 30;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveChatModerator());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkLiveChatModerator(response as api.LiveChatModerator);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveChatModerators;
      var arg_liveChatId = 'foo';
      var arg_part = buildUnnamed3042();
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("youtube/v3/liveChat/moderators"),
        );
        pathOffset += 30;

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
          queryMap["liveChatId"]!.first,
          unittest.equals(arg_liveChatId),
        );
        unittest.expect(
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildLiveChatModeratorListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_liveChatId, arg_part,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkLiveChatModeratorListResponse(
          response as api.LiveChatModeratorListResponse);
    });
  });

  unittest.group('resource-LiveStreamsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveStreams;
      var arg_id = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("youtube/v3/liveStreams"),
        );
        pathOffset += 22;

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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveStreams;
      var arg_request = buildLiveStream();
      var arg_part = buildUnnamed3043();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LiveStream.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLiveStream(obj as api.LiveStream);

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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("youtube/v3/liveStreams"),
        );
        pathOffset += 22;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveStream());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkLiveStream(response as api.LiveStream);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveStreams;
      var arg_part = buildUnnamed3044();
      var arg_id = buildUnnamed3045();
      var arg_maxResults = 42;
      var arg_mine = true;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("youtube/v3/liveStreams"),
        );
        pathOffset += 22;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["mine"]!.first,
          unittest.equals("$arg_mine"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
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
        var resp = convert.json.encode(buildLiveStreamListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          id: arg_id,
          maxResults: arg_maxResults,
          mine: arg_mine,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkLiveStreamListResponse(response as api.LiveStreamListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).liveStreams;
      var arg_request = buildLiveStream();
      var arg_part = buildUnnamed3046();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LiveStream.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLiveStream(obj as api.LiveStream);

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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("youtube/v3/liveStreams"),
        );
        pathOffset += 22;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLiveStream());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkLiveStream(response as api.LiveStream);
    });
  });

  unittest.group('resource-MembersResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).members;
      var arg_part = buildUnnamed3047();
      var arg_filterByMemberChannelId = 'foo';
      var arg_hasAccessToLevel = 'foo';
      var arg_maxResults = 42;
      var arg_mode = 'foo';
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
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("youtube/v3/members"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["filterByMemberChannelId"]!.first,
          unittest.equals(arg_filterByMemberChannelId),
        );
        unittest.expect(
          queryMap["hasAccessToLevel"]!.first,
          unittest.equals(arg_hasAccessToLevel),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["mode"]!.first,
          unittest.equals(arg_mode),
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
        var resp = convert.json.encode(buildMemberListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          filterByMemberChannelId: arg_filterByMemberChannelId,
          hasAccessToLevel: arg_hasAccessToLevel,
          maxResults: arg_maxResults,
          mode: arg_mode,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkMemberListResponse(response as api.MemberListResponse);
    });
  });

  unittest.group('resource-MembershipsLevelsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).membershipsLevels;
      var arg_part = buildUnnamed3048();
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("youtube/v3/membershipsLevels"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMembershipsLevelListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part, $fields: arg_$fields);
      checkMembershipsLevelListResponse(
          response as api.MembershipsLevelListResponse);
    });
  });

  unittest.group('resource-PlaylistItemsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlistItems;
      var arg_id = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/playlistItems"),
        );
        pathOffset += 24;

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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlistItems;
      var arg_request = buildPlaylistItem();
      var arg_part = buildUnnamed3049();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PlaylistItem.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPlaylistItem(obj as api.PlaylistItem);

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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/playlistItems"),
        );
        pathOffset += 24;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlaylistItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkPlaylistItem(response as api.PlaylistItem);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlistItems;
      var arg_part = buildUnnamed3050();
      var arg_id = buildUnnamed3051();
      var arg_maxResults = 42;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_pageToken = 'foo';
      var arg_playlistId = 'foo';
      var arg_videoId = 'foo';
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/playlistItems"),
        );
        pathOffset += 24;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["playlistId"]!.first,
          unittest.equals(arg_playlistId),
        );
        unittest.expect(
          queryMap["videoId"]!.first,
          unittest.equals(arg_videoId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlaylistItemListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          id: arg_id,
          maxResults: arg_maxResults,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          pageToken: arg_pageToken,
          playlistId: arg_playlistId,
          videoId: arg_videoId,
          $fields: arg_$fields);
      checkPlaylistItemListResponse(response as api.PlaylistItemListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlistItems;
      var arg_request = buildPlaylistItem();
      var arg_part = buildUnnamed3052();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PlaylistItem.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPlaylistItem(obj as api.PlaylistItem);

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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/playlistItems"),
        );
        pathOffset += 24;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlaylistItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkPlaylistItem(response as api.PlaylistItem);
    });
  });

  unittest.group('resource-PlaylistsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlists;
      var arg_id = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("youtube/v3/playlists"),
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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlists;
      var arg_request = buildPlaylist();
      var arg_part = buildUnnamed3053();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Playlist.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPlaylist(obj as api.Playlist);

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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("youtube/v3/playlists"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlaylist());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          $fields: arg_$fields);
      checkPlaylist(response as api.Playlist);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlists;
      var arg_part = buildUnnamed3054();
      var arg_channelId = 'foo';
      var arg_hl = 'foo';
      var arg_id = buildUnnamed3055();
      var arg_maxResults = 42;
      var arg_mine = true;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("youtube/v3/playlists"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["mine"]!.first,
          unittest.equals("$arg_mine"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
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
        var resp = convert.json.encode(buildPlaylistListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          channelId: arg_channelId,
          hl: arg_hl,
          id: arg_id,
          maxResults: arg_maxResults,
          mine: arg_mine,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkPlaylistListResponse(response as api.PlaylistListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).playlists;
      var arg_request = buildPlaylist();
      var arg_part = buildUnnamed3056();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Playlist.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPlaylist(obj as api.Playlist);

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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("youtube/v3/playlists"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlaylist());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkPlaylist(response as api.Playlist);
    });
  });

  unittest.group('resource-SearchResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).search;
      var arg_part = buildUnnamed3057();
      var arg_channelId = 'foo';
      var arg_channelType = 'foo';
      var arg_eventType = 'foo';
      var arg_forContentOwner = true;
      var arg_forDeveloper = true;
      var arg_forMine = true;
      var arg_location = 'foo';
      var arg_locationRadius = 'foo';
      var arg_maxResults = 42;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_order = 'foo';
      var arg_pageToken = 'foo';
      var arg_publishedAfter = 'foo';
      var arg_publishedBefore = 'foo';
      var arg_q = 'foo';
      var arg_regionCode = 'foo';
      var arg_relatedToVideoId = 'foo';
      var arg_relevanceLanguage = 'foo';
      var arg_safeSearch = 'foo';
      var arg_topicId = 'foo';
      var arg_type = buildUnnamed3058();
      var arg_videoCaption = 'foo';
      var arg_videoCategoryId = 'foo';
      var arg_videoDefinition = 'foo';
      var arg_videoDimension = 'foo';
      var arg_videoDuration = 'foo';
      var arg_videoEmbeddable = 'foo';
      var arg_videoLicense = 'foo';
      var arg_videoSyndicated = 'foo';
      var arg_videoType = 'foo';
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
          unittest.equals("youtube/v3/search"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["channelType"]!.first,
          unittest.equals(arg_channelType),
        );
        unittest.expect(
          queryMap["eventType"]!.first,
          unittest.equals(arg_eventType),
        );
        unittest.expect(
          queryMap["forContentOwner"]!.first,
          unittest.equals("$arg_forContentOwner"),
        );
        unittest.expect(
          queryMap["forDeveloper"]!.first,
          unittest.equals("$arg_forDeveloper"),
        );
        unittest.expect(
          queryMap["forMine"]!.first,
          unittest.equals("$arg_forMine"),
        );
        unittest.expect(
          queryMap["location"]!.first,
          unittest.equals(arg_location),
        );
        unittest.expect(
          queryMap["locationRadius"]!.first,
          unittest.equals(arg_locationRadius),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["order"]!.first,
          unittest.equals(arg_order),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["publishedAfter"]!.first,
          unittest.equals(arg_publishedAfter),
        );
        unittest.expect(
          queryMap["publishedBefore"]!.first,
          unittest.equals(arg_publishedBefore),
        );
        unittest.expect(
          queryMap["q"]!.first,
          unittest.equals(arg_q),
        );
        unittest.expect(
          queryMap["regionCode"]!.first,
          unittest.equals(arg_regionCode),
        );
        unittest.expect(
          queryMap["relatedToVideoId"]!.first,
          unittest.equals(arg_relatedToVideoId),
        );
        unittest.expect(
          queryMap["relevanceLanguage"]!.first,
          unittest.equals(arg_relevanceLanguage),
        );
        unittest.expect(
          queryMap["safeSearch"]!.first,
          unittest.equals(arg_safeSearch),
        );
        unittest.expect(
          queryMap["topicId"]!.first,
          unittest.equals(arg_topicId),
        );
        unittest.expect(
          queryMap["type"]!,
          unittest.equals(arg_type),
        );
        unittest.expect(
          queryMap["videoCaption"]!.first,
          unittest.equals(arg_videoCaption),
        );
        unittest.expect(
          queryMap["videoCategoryId"]!.first,
          unittest.equals(arg_videoCategoryId),
        );
        unittest.expect(
          queryMap["videoDefinition"]!.first,
          unittest.equals(arg_videoDefinition),
        );
        unittest.expect(
          queryMap["videoDimension"]!.first,
          unittest.equals(arg_videoDimension),
        );
        unittest.expect(
          queryMap["videoDuration"]!.first,
          unittest.equals(arg_videoDuration),
        );
        unittest.expect(
          queryMap["videoEmbeddable"]!.first,
          unittest.equals(arg_videoEmbeddable),
        );
        unittest.expect(
          queryMap["videoLicense"]!.first,
          unittest.equals(arg_videoLicense),
        );
        unittest.expect(
          queryMap["videoSyndicated"]!.first,
          unittest.equals(arg_videoSyndicated),
        );
        unittest.expect(
          queryMap["videoType"]!.first,
          unittest.equals(arg_videoType),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          channelId: arg_channelId,
          channelType: arg_channelType,
          eventType: arg_eventType,
          forContentOwner: arg_forContentOwner,
          forDeveloper: arg_forDeveloper,
          forMine: arg_forMine,
          location: arg_location,
          locationRadius: arg_locationRadius,
          maxResults: arg_maxResults,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          order: arg_order,
          pageToken: arg_pageToken,
          publishedAfter: arg_publishedAfter,
          publishedBefore: arg_publishedBefore,
          q: arg_q,
          regionCode: arg_regionCode,
          relatedToVideoId: arg_relatedToVideoId,
          relevanceLanguage: arg_relevanceLanguage,
          safeSearch: arg_safeSearch,
          topicId: arg_topicId,
          type: arg_type,
          videoCaption: arg_videoCaption,
          videoCategoryId: arg_videoCategoryId,
          videoDefinition: arg_videoDefinition,
          videoDimension: arg_videoDimension,
          videoDuration: arg_videoDuration,
          videoEmbeddable: arg_videoEmbeddable,
          videoLicense: arg_videoLicense,
          videoSyndicated: arg_videoSyndicated,
          videoType: arg_videoType,
          $fields: arg_$fields);
      checkSearchListResponse(response as api.SearchListResponse);
    });
  });

  unittest.group('resource-SubscriptionsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).subscriptions;
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/subscriptions"),
        );
        pathOffset += 24;

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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).subscriptions;
      var arg_request = buildSubscription();
      var arg_part = buildUnnamed3059();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Subscription.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSubscription(obj as api.Subscription);

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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/subscriptions"),
        );
        pathOffset += 24;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).subscriptions;
      var arg_part = buildUnnamed3060();
      var arg_channelId = 'foo';
      var arg_forChannelId = 'foo';
      var arg_id = buildUnnamed3061();
      var arg_maxResults = 42;
      var arg_mine = true;
      var arg_myRecentSubscribers = true;
      var arg_mySubscribers = true;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_order = 'foo';
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("youtube/v3/subscriptions"),
        );
        pathOffset += 24;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["forChannelId"]!.first,
          unittest.equals(arg_forChannelId),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["mine"]!.first,
          unittest.equals("$arg_mine"),
        );
        unittest.expect(
          queryMap["myRecentSubscribers"]!.first,
          unittest.equals("$arg_myRecentSubscribers"),
        );
        unittest.expect(
          queryMap["mySubscribers"]!.first,
          unittest.equals("$arg_mySubscribers"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["order"]!.first,
          unittest.equals(arg_order),
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
        var resp = convert.json.encode(buildSubscriptionListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          channelId: arg_channelId,
          forChannelId: arg_forChannelId,
          id: arg_id,
          maxResults: arg_maxResults,
          mine: arg_mine,
          myRecentSubscribers: arg_myRecentSubscribers,
          mySubscribers: arg_mySubscribers,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          order: arg_order,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSubscriptionListResponse(response as api.SubscriptionListResponse);
    });
  });

  unittest.group('resource-SuperChatEventsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).superChatEvents;
      var arg_part = buildUnnamed3062();
      var arg_hl = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("youtube/v3/superChatEvents"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildSuperChatEventListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          hl: arg_hl,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSuperChatEventListResponse(
          response as api.SuperChatEventListResponse);
    });
  });

  unittest.group('resource-TestsResource', () {
    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).tests;
      var arg_request = buildTestItem();
      var arg_part = buildUnnamed3063();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.TestItem.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTestItem(obj as api.TestItem);

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
          unittest.equals("youtube/v3/tests"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTestItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkTestItem(response as api.TestItem);
    });
  });

  unittest.group('resource-ThirdPartyLinksResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).thirdPartyLinks;
      var arg_linkingToken = 'foo';
      var arg_type = 'foo';
      var arg_part = buildUnnamed3064();
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("youtube/v3/thirdPartyLinks"),
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
          queryMap["linkingToken"]!.first,
          unittest.equals(arg_linkingToken),
        );
        unittest.expect(
          queryMap["type"]!.first,
          unittest.equals(arg_type),
        );
        unittest.expect(
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_linkingToken, arg_type,
          part: arg_part, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).thirdPartyLinks;
      var arg_request = buildThirdPartyLink();
      var arg_part = buildUnnamed3065();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ThirdPartyLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkThirdPartyLink(obj as api.ThirdPartyLink);

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
          unittest.equals("youtube/v3/thirdPartyLinks"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildThirdPartyLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_part, $fields: arg_$fields);
      checkThirdPartyLink(response as api.ThirdPartyLink);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).thirdPartyLinks;
      var arg_part = buildUnnamed3066();
      var arg_linkingToken = 'foo';
      var arg_type = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("youtube/v3/thirdPartyLinks"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["linkingToken"]!.first,
          unittest.equals(arg_linkingToken),
        );
        unittest.expect(
          queryMap["type"]!.first,
          unittest.equals(arg_type),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildThirdPartyLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          linkingToken: arg_linkingToken, type: arg_type, $fields: arg_$fields);
      checkThirdPartyLink(response as api.ThirdPartyLink);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).thirdPartyLinks;
      var arg_request = buildThirdPartyLink();
      var arg_part = buildUnnamed3067();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ThirdPartyLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkThirdPartyLink(obj as api.ThirdPartyLink);

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
          unittest.equals("youtube/v3/thirdPartyLinks"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildThirdPartyLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_part, $fields: arg_$fields);
      checkThirdPartyLink(response as api.ThirdPartyLink);
    });
  });

  unittest.group('resource-ThumbnailsResource', () {
    unittest.test('method--set', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).thumbnails;
      var arg_videoId = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("youtube/v3/thumbnails/set"),
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
          queryMap["videoId"]!.first,
          unittest.equals(arg_videoId),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildThumbnailSetResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.set(arg_videoId,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkThumbnailSetResponse(response as api.ThumbnailSetResponse);
    });
  });

  unittest.group('resource-VideoAbuseReportReasonsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videoAbuseReportReasons;
      var arg_part = buildUnnamed3068();
      var arg_hl = 'foo';
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
          path.substring(pathOffset, pathOffset + 34),
          unittest.equals("youtube/v3/videoAbuseReportReasons"),
        );
        pathOffset += 34;

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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildVideoAbuseReportReasonListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_part, hl: arg_hl, $fields: arg_$fields);
      checkVideoAbuseReportReasonListResponse(
          response as api.VideoAbuseReportReasonListResponse);
    });
  });

  unittest.group('resource-VideoCategoriesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videoCategories;
      var arg_part = buildUnnamed3069();
      var arg_hl = 'foo';
      var arg_id = buildUnnamed3070();
      var arg_regionCode = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("youtube/v3/videoCategories"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["regionCode"]!.first,
          unittest.equals(arg_regionCode),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVideoCategoryListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          hl: arg_hl,
          id: arg_id,
          regionCode: arg_regionCode,
          $fields: arg_$fields);
      checkVideoCategoryListResponse(response as api.VideoCategoryListResponse);
    });
  });

  unittest.group('resource-VideosResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videos;
      var arg_id = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          unittest.equals("youtube/v3/videos"),
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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_id,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });

    unittest.test('method--getRating', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videos;
      var arg_id = buildUnnamed3071();
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("youtube/v3/videos/getRating"),
        );
        pathOffset += 27;

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
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVideoGetRatingResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getRating(arg_id,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkVideoGetRatingResponse(response as api.VideoGetRatingResponse);
    });

    unittest.test('method--insert', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videos;
      var arg_request = buildVideo();
      var arg_part = buildUnnamed3072();
      var arg_autoLevels = true;
      var arg_notifySubscribers = true;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_onBehalfOfContentOwnerChannel = 'foo';
      var arg_stabilize = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Video.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVideo(obj as api.Video);

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
          unittest.equals("youtube/v3/videos"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["autoLevels"]!.first,
          unittest.equals("$arg_autoLevels"),
        );
        unittest.expect(
          queryMap["notifySubscribers"]!.first,
          unittest.equals("$arg_notifySubscribers"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwnerChannel"]!.first,
          unittest.equals(arg_onBehalfOfContentOwnerChannel),
        );
        unittest.expect(
          queryMap["stabilize"]!.first,
          unittest.equals("$arg_stabilize"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVideo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_part,
          autoLevels: arg_autoLevels,
          notifySubscribers: arg_notifySubscribers,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          onBehalfOfContentOwnerChannel: arg_onBehalfOfContentOwnerChannel,
          stabilize: arg_stabilize,
          $fields: arg_$fields);
      checkVideo(response as api.Video);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videos;
      var arg_part = buildUnnamed3073();
      var arg_chart = 'foo';
      var arg_hl = 'foo';
      var arg_id = buildUnnamed3074();
      var arg_locale = 'foo';
      var arg_maxHeight = 42;
      var arg_maxResults = 42;
      var arg_maxWidth = 42;
      var arg_myRating = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_pageToken = 'foo';
      var arg_regionCode = 'foo';
      var arg_videoCategoryId = 'foo';
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
          unittest.equals("youtube/v3/videos"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["chart"]!.first,
          unittest.equals(arg_chart),
        );
        unittest.expect(
          queryMap["hl"]!.first,
          unittest.equals(arg_hl),
        );
        unittest.expect(
          queryMap["id"]!,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          core.int.parse(queryMap["maxHeight"]!.first),
          unittest.equals(arg_maxHeight),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["maxWidth"]!.first),
          unittest.equals(arg_maxWidth),
        );
        unittest.expect(
          queryMap["myRating"]!.first,
          unittest.equals(arg_myRating),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["regionCode"]!.first,
          unittest.equals(arg_regionCode),
        );
        unittest.expect(
          queryMap["videoCategoryId"]!.first,
          unittest.equals(arg_videoCategoryId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVideoListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_part,
          chart: arg_chart,
          hl: arg_hl,
          id: arg_id,
          locale: arg_locale,
          maxHeight: arg_maxHeight,
          maxResults: arg_maxResults,
          maxWidth: arg_maxWidth,
          myRating: arg_myRating,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          pageToken: arg_pageToken,
          regionCode: arg_regionCode,
          videoCategoryId: arg_videoCategoryId,
          $fields: arg_$fields);
      checkVideoListResponse(response as api.VideoListResponse);
    });

    unittest.test('method--rate', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videos;
      var arg_id = 'foo';
      var arg_rating = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("youtube/v3/videos/rate"),
        );
        pathOffset += 22;

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
          queryMap["id"]!.first,
          unittest.equals(arg_id),
        );
        unittest.expect(
          queryMap["rating"]!.first,
          unittest.equals(arg_rating),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.rate(arg_id, arg_rating, $fields: arg_$fields);
    });

    unittest.test('method--reportAbuse', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videos;
      var arg_request = buildVideoAbuseReport();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.VideoAbuseReport.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkVideoAbuseReport(obj as api.VideoAbuseReport);

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
          unittest.equals("youtube/v3/videos/reportAbuse"),
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
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.reportAbuse(arg_request,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).videos;
      var arg_request = buildVideo();
      var arg_part = buildUnnamed3075();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Video.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVideo(obj as api.Video);

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
          unittest.equals("youtube/v3/videos"),
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
          queryMap["part"]!,
          unittest.equals(arg_part),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVideo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_part,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkVideo(response as api.Video);
    });
  });

  unittest.group('resource-WatermarksResource', () {
    unittest.test('method--set', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).watermarks;
      var arg_request = buildInvideoBranding();
      var arg_channelId = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InvideoBranding.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInvideoBranding(obj as api.InvideoBranding);

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
          unittest.equals("youtube/v3/watermarks/set"),
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
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.set(arg_request, arg_channelId,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });

    unittest.test('method--unset', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeApi(mock).watermarks;
      var arg_channelId = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("youtube/v3/watermarks/unset"),
        );
        pathOffset += 27;

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
          queryMap["channelId"]!.first,
          unittest.equals(arg_channelId),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.unset(arg_channelId,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
    });
  });
}
