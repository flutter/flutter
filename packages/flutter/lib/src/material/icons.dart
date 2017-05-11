// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A description of a material design icon.
///
/// See [Icons] for a number of predefined icons.
@immutable
class IconData {
  /// Creates icon data.
  ///
  /// Rarely used directly. Instead, consider using one of the predefined icons
  /// from the [Icons] collection.
  const IconData(this.codePoint, {
    this.fontFamily: 'MaterialIcons'
  });

  /// The unicode code point at which this icon is stored in the icon font.
  final int codePoint;

  /// The font family from which the glyph for the [codePoint] will be selected.
  final String fontFamily;

  @override
  bool operator ==(dynamic other) {
    if (other is! IconData)
      return false;
    final IconData typedOther = other;
    return codePoint == typedOther.codePoint;
  }

  @override
  int get hashCode => codePoint.hashCode;

  @override
  String toString() => 'IconData(U+${codePoint.toRadixString(16).toUpperCase().padLeft(5, '0')})';
}

/// Identifiers for the supported material design icons.
///
/// Use with with the [Icon] class to show specific icons.
///
/// See also:
///
///  * [Icon]
///  * [IconButton]
///  * [design.google.com/icons](https://design.google.com/icons/)
class Icons {
  Icons._();

  // Generated code: do not hand-edit.
  // See https://github.com/flutter/flutter/wiki/Updating-Material-Design-Fonts
  // BEGIN GENERATED

  /// <p><i class="material-icons md-36">360</i> &#x2014; material icon named "360".</p>
  static const IconData threesixty = const IconData(0xe577);

  /// <p><i class="material-icons md-36">3d_rotation</i> &#x2014; material icon named "3d rotation".</p>
  static const IconData threed_rotation = const IconData(0xe84d);

  /// <p><i class="material-icons md-36">4k</i> &#x2014; material icon named "4k".</p>
  static const IconData four_k = const IconData(0xe072);

  /// <p><i class="material-icons md-36">ac_unit</i> &#x2014; material icon named "ac unit".</p>
  static const IconData ac_unit = const IconData(0xeb3b);

  /// <p><i class="material-icons md-36">access_alarm</i> &#x2014; material icon named "access alarm".</p>
  static const IconData access_alarm = const IconData(0xe190);

  /// <p><i class="material-icons md-36">access_alarms</i> &#x2014; material icon named "access alarms".</p>
  static const IconData access_alarms = const IconData(0xe191);

  /// <p><i class="material-icons md-36">access_time</i> &#x2014; material icon named "access time".</p>
  static const IconData access_time = const IconData(0xe192);

  /// <p><i class="material-icons md-36">accessibility</i> &#x2014; material icon named "accessibility".</p>
  static const IconData accessibility = const IconData(0xe84e);

  /// <p><i class="material-icons md-36">accessibility_new</i> &#x2014; material icon named "accessibility new".</p>
  static const IconData accessibility_new = const IconData(0xe92c);

  /// <p><i class="material-icons md-36">accessible</i> &#x2014; material icon named "accessible".</p>
  static const IconData accessible = const IconData(0xe914);

  /// <p><i class="material-icons md-36">accessible_forward</i> &#x2014; material icon named "accessible forward".</p>
  static const IconData accessible_forward = const IconData(0xe934);

  /// <p><i class="material-icons md-36">account_balance</i> &#x2014; material icon named "account balance".</p>
  static const IconData account_balance = const IconData(0xe84f);

  /// <p><i class="material-icons md-36">account_balance_wallet</i> &#x2014; material icon named "account balance wallet".</p>
  static const IconData account_balance_wallet = const IconData(0xe850);

  /// <p><i class="material-icons md-36">account_box</i> &#x2014; material icon named "account box".</p>
  static const IconData account_box = const IconData(0xe851);

  /// <p><i class="material-icons md-36">account_circle</i> &#x2014; material icon named "account circle".</p>
  static const IconData account_circle = const IconData(0xe853);

  /// <p><i class="material-icons md-36">adb</i> &#x2014; material icon named "adb".</p>
  static const IconData adb = const IconData(0xe60e);

  /// <p><i class="material-icons md-36">add</i> &#x2014; material icon named "add".</p>
  static const IconData add = const IconData(0xe145);

  /// <p><i class="material-icons md-36">add_a_photo</i> &#x2014; material icon named "add a photo".</p>
  static const IconData add_a_photo = const IconData(0xe439);

  /// <p><i class="material-icons md-36">add_alarm</i> &#x2014; material icon named "add alarm".</p>
  static const IconData add_alarm = const IconData(0xe193);

  /// <p><i class="material-icons md-36">add_alert</i> &#x2014; material icon named "add alert".</p>
  static const IconData add_alert = const IconData(0xe003);

  /// <p><i class="material-icons md-36">add_box</i> &#x2014; material icon named "add box".</p>
  static const IconData add_box = const IconData(0xe146);

  /// <p><i class="material-icons md-36">add_call</i> &#x2014; material icon named "add call".</p>
  static const IconData add_call = const IconData(0xe0e8);

  /// <p><i class="material-icons md-36">add_circle</i> &#x2014; material icon named "add circle".</p>
  static const IconData add_circle = const IconData(0xe147);

  /// <p><i class="material-icons md-36">add_circle_outline</i> &#x2014; material icon named "add circle outline".</p>
  static const IconData add_circle_outline = const IconData(0xe148);

  /// <p><i class="material-icons md-36">add_comment</i> &#x2014; material icon named "add comment".</p>
  static const IconData add_comment = const IconData(0xe266);

  /// <p><i class="material-icons md-36">add_location</i> &#x2014; material icon named "add location".</p>
  static const IconData add_location = const IconData(0xe567);

  /// <p><i class="material-icons md-36">add_photo_alternate</i> &#x2014; material icon named "add photo alternate".</p>
  static const IconData add_photo_alternate = const IconData(0xe43e);

  /// <p><i class="material-icons md-36">add_shopping_cart</i> &#x2014; material icon named "add shopping cart".</p>
  static const IconData add_shopping_cart = const IconData(0xe854);

  /// <p><i class="material-icons md-36">add_to_home_screen</i> &#x2014; material icon named "add to home screen".</p>
  static const IconData add_to_home_screen = const IconData(0xe1fe);

  /// <p><i class="material-icons md-36">add_to_photos</i> &#x2014; material icon named "add to photos".</p>
  static const IconData add_to_photos = const IconData(0xe39d);

  /// <p><i class="material-icons md-36">add_to_queue</i> &#x2014; material icon named "add to queue".</p>
  static const IconData add_to_queue = const IconData(0xe05c);

  /// <p><i class="material-icons md-36">adjust</i> &#x2014; material icon named "adjust".</p>
  static const IconData adjust = const IconData(0xe39e);

  /// <p><i class="material-icons md-36">airline_seat_flat</i> &#x2014; material icon named "airline seat flat".</p>
  static const IconData airline_seat_flat = const IconData(0xe630);

  /// <p><i class="material-icons md-36">airline_seat_flat_angled</i> &#x2014; material icon named "airline seat flat angled".</p>
  static const IconData airline_seat_flat_angled = const IconData(0xe631);

  /// <p><i class="material-icons md-36">airline_seat_individual_suite</i> &#x2014; material icon named "airline seat individual suite".</p>
  static const IconData airline_seat_individual_suite = const IconData(0xe632);

  /// <p><i class="material-icons md-36">airline_seat_legroom_extra</i> &#x2014; material icon named "airline seat legroom extra".</p>
  static const IconData airline_seat_legroom_extra = const IconData(0xe633);

  /// <p><i class="material-icons md-36">airline_seat_legroom_normal</i> &#x2014; material icon named "airline seat legroom normal".</p>
  static const IconData airline_seat_legroom_normal = const IconData(0xe634);

  /// <p><i class="material-icons md-36">airline_seat_legroom_reduced</i> &#x2014; material icon named "airline seat legroom reduced".</p>
  static const IconData airline_seat_legroom_reduced = const IconData(0xe635);

  /// <p><i class="material-icons md-36">airline_seat_recline_extra</i> &#x2014; material icon named "airline seat recline extra".</p>
  static const IconData airline_seat_recline_extra = const IconData(0xe636);

  /// <p><i class="material-icons md-36">airline_seat_recline_normal</i> &#x2014; material icon named "airline seat recline normal".</p>
  static const IconData airline_seat_recline_normal = const IconData(0xe637);

  /// <p><i class="material-icons md-36">airplanemode_active</i> &#x2014; material icon named "airplanemode active".</p>
  static const IconData airplanemode_active = const IconData(0xe195);

  /// <p><i class="material-icons md-36">airplanemode_inactive</i> &#x2014; material icon named "airplanemode inactive".</p>
  static const IconData airplanemode_inactive = const IconData(0xe194);

  /// <p><i class="material-icons md-36">airplay</i> &#x2014; material icon named "airplay".</p>
  static const IconData airplay = const IconData(0xe055);

  /// <p><i class="material-icons md-36">airport_shuttle</i> &#x2014; material icon named "airport shuttle".</p>
  static const IconData airport_shuttle = const IconData(0xeb3c);

  /// <p><i class="material-icons md-36">alarm</i> &#x2014; material icon named "alarm".</p>
  static const IconData alarm = const IconData(0xe855);

  /// <p><i class="material-icons md-36">alarm_add</i> &#x2014; material icon named "alarm add".</p>
  static const IconData alarm_add = const IconData(0xe856);

  /// <p><i class="material-icons md-36">alarm_off</i> &#x2014; material icon named "alarm off".</p>
  static const IconData alarm_off = const IconData(0xe857);

  /// <p><i class="material-icons md-36">alarm_on</i> &#x2014; material icon named "alarm on".</p>
  static const IconData alarm_on = const IconData(0xe858);

  /// <p><i class="material-icons md-36">album</i> &#x2014; material icon named "album".</p>
  static const IconData album = const IconData(0xe019);

  /// <p><i class="material-icons md-36">all_inclusive</i> &#x2014; material icon named "all inclusive".</p>
  static const IconData all_inclusive = const IconData(0xeb3d);

  /// <p><i class="material-icons md-36">all_out</i> &#x2014; material icon named "all out".</p>
  static const IconData all_out = const IconData(0xe90b);

  /// <p><i class="material-icons md-36">alternate_email</i> &#x2014; material icon named "alternate email".</p>
  static const IconData alternate_email = const IconData(0xe0e6);

  /// <p><i class="material-icons md-36">android</i> &#x2014; material icon named "android".</p>
  static const IconData android = const IconData(0xe859);

  /// <p><i class="material-icons md-36">announcement</i> &#x2014; material icon named "announcement".</p>
  static const IconData announcement = const IconData(0xe85a);

  /// <p><i class="material-icons md-36">apps</i> &#x2014; material icon named "apps".</p>
  static const IconData apps = const IconData(0xe5c3);

  /// <p><i class="material-icons md-36">archive</i> &#x2014; material icon named "archive".</p>
  static const IconData archive = const IconData(0xe149);

  /// <p><i class="material-icons md-36">arrow_back</i> &#x2014; material icon named "arrow back".</p>
  static const IconData arrow_back = const IconData(0xe5c4);

  /// <p><i class="material-icons md-36">arrow_back_ios</i> &#x2014; material icon named "arrow back ios".</p>
  static const IconData arrow_back_ios = const IconData(0xe5e0);

  /// <p><i class="material-icons md-36">arrow_downward</i> &#x2014; material icon named "arrow downward".</p>
  static const IconData arrow_downward = const IconData(0xe5db);

  /// <p><i class="material-icons md-36">arrow_drop_down</i> &#x2014; material icon named "arrow drop down".</p>
  static const IconData arrow_drop_down = const IconData(0xe5c5);

  /// <p><i class="material-icons md-36">arrow_drop_down_circle</i> &#x2014; material icon named "arrow drop down circle".</p>
  static const IconData arrow_drop_down_circle = const IconData(0xe5c6);

  /// <p><i class="material-icons md-36">arrow_drop_up</i> &#x2014; material icon named "arrow drop up".</p>
  static const IconData arrow_drop_up = const IconData(0xe5c7);

  /// <p><i class="material-icons md-36">arrow_forward</i> &#x2014; material icon named "arrow forward".</p>
  static const IconData arrow_forward = const IconData(0xe5c8);

  /// <p><i class="material-icons md-36">arrow_forward_ios</i> &#x2014; material icon named "arrow forward ios".</p>
  static const IconData arrow_forward_ios = const IconData(0xe5e1);

  /// <p><i class="material-icons md-36">arrow_left</i> &#x2014; material icon named "arrow left".</p>
  static const IconData arrow_left = const IconData(0xe5de);

  /// <p><i class="material-icons md-36">arrow_right</i> &#x2014; material icon named "arrow right".</p>
  static const IconData arrow_right = const IconData(0xe5df);

  /// <p><i class="material-icons md-36">arrow_upward</i> &#x2014; material icon named "arrow upward".</p>
  static const IconData arrow_upward = const IconData(0xe5d8);

  /// <p><i class="material-icons md-36">art_track</i> &#x2014; material icon named "art track".</p>
  static const IconData art_track = const IconData(0xe060);

  /// <p><i class="material-icons md-36">aspect_ratio</i> &#x2014; material icon named "aspect ratio".</p>
  static const IconData aspect_ratio = const IconData(0xe85b);

  /// <p><i class="material-icons md-36">assessment</i> &#x2014; material icon named "assessment".</p>
  static const IconData assessment = const IconData(0xe85c);

  /// <p><i class="material-icons md-36">assignment</i> &#x2014; material icon named "assignment".</p>
  static const IconData assignment = const IconData(0xe85d);

  /// <p><i class="material-icons md-36">assignment_ind</i> &#x2014; material icon named "assignment ind".</p>
  static const IconData assignment_ind = const IconData(0xe85e);

  /// <p><i class="material-icons md-36">assignment_late</i> &#x2014; material icon named "assignment late".</p>
  static const IconData assignment_late = const IconData(0xe85f);

  /// <p><i class="material-icons md-36">assignment_return</i> &#x2014; material icon named "assignment return".</p>
  static const IconData assignment_return = const IconData(0xe860);

  /// <p><i class="material-icons md-36">assignment_returned</i> &#x2014; material icon named "assignment returned".</p>
  static const IconData assignment_returned = const IconData(0xe861);

  /// <p><i class="material-icons md-36">assignment_turned_in</i> &#x2014; material icon named "assignment turned in".</p>
  static const IconData assignment_turned_in = const IconData(0xe862);

  /// <p><i class="material-icons md-36">assistant</i> &#x2014; material icon named "assistant".</p>
  static const IconData assistant = const IconData(0xe39f);

  /// <p><i class="material-icons md-36">assistant_photo</i> &#x2014; material icon named "assistant photo".</p>
  static const IconData assistant_photo = const IconData(0xe3a0);

  /// <p><i class="material-icons md-36">atm</i> &#x2014; material icon named "atm".</p>
  static const IconData atm = const IconData(0xe573);

  /// <p><i class="material-icons md-36">attach_file</i> &#x2014; material icon named "attach file".</p>
  static const IconData attach_file = const IconData(0xe226);

  /// <p><i class="material-icons md-36">attach_money</i> &#x2014; material icon named "attach money".</p>
  static const IconData attach_money = const IconData(0xe227);

  /// <p><i class="material-icons md-36">attachment</i> &#x2014; material icon named "attachment".</p>
  static const IconData attachment = const IconData(0xe2bc);

  /// <p><i class="material-icons md-36">audiotrack</i> &#x2014; material icon named "audiotrack".</p>
  static const IconData audiotrack = const IconData(0xe3a1);

  /// <p><i class="material-icons md-36">autorenew</i> &#x2014; material icon named "autorenew".</p>
  static const IconData autorenew = const IconData(0xe863);

  /// <p><i class="material-icons md-36">av_timer</i> &#x2014; material icon named "av timer".</p>
  static const IconData av_timer = const IconData(0xe01b);

  /// <p><i class="material-icons md-36">backspace</i> &#x2014; material icon named "backspace".</p>
  static const IconData backspace = const IconData(0xe14a);

  /// <p><i class="material-icons md-36">backup</i> &#x2014; material icon named "backup".</p>
  static const IconData backup = const IconData(0xe864);

  /// <p><i class="material-icons md-36">battery_alert</i> &#x2014; material icon named "battery alert".</p>
  static const IconData battery_alert = const IconData(0xe19c);

  /// <p><i class="material-icons md-36">battery_charging_full</i> &#x2014; material icon named "battery charging full".</p>
  static const IconData battery_charging_full = const IconData(0xe1a3);

  /// <p><i class="material-icons md-36">battery_full</i> &#x2014; material icon named "battery full".</p>
  static const IconData battery_full = const IconData(0xe1a4);

  /// <p><i class="material-icons md-36">battery_std</i> &#x2014; material icon named "battery std".</p>
  static const IconData battery_std = const IconData(0xe1a5);

  /// <p><i class="material-icons md-36">battery_unknown</i> &#x2014; material icon named "battery unknown".</p>
  static const IconData battery_unknown = const IconData(0xe1a6);

  /// <p><i class="material-icons md-36">beach_access</i> &#x2014; material icon named "beach access".</p>
  static const IconData beach_access = const IconData(0xeb3e);

  /// <p><i class="material-icons md-36">beenhere</i> &#x2014; material icon named "beenhere".</p>
  static const IconData beenhere = const IconData(0xe52d);

  /// <p><i class="material-icons md-36">block</i> &#x2014; material icon named "block".</p>
  static const IconData block = const IconData(0xe14b);

  /// <p><i class="material-icons md-36">bluetooth</i> &#x2014; material icon named "bluetooth".</p>
  static const IconData bluetooth = const IconData(0xe1a7);

  /// <p><i class="material-icons md-36">bluetooth_audio</i> &#x2014; material icon named "bluetooth audio".</p>
  static const IconData bluetooth_audio = const IconData(0xe60f);

  /// <p><i class="material-icons md-36">bluetooth_connected</i> &#x2014; material icon named "bluetooth connected".</p>
  static const IconData bluetooth_connected = const IconData(0xe1a8);

  /// <p><i class="material-icons md-36">bluetooth_disabled</i> &#x2014; material icon named "bluetooth disabled".</p>
  static const IconData bluetooth_disabled = const IconData(0xe1a9);

  /// <p><i class="material-icons md-36">bluetooth_searching</i> &#x2014; material icon named "bluetooth searching".</p>
  static const IconData bluetooth_searching = const IconData(0xe1aa);

  /// <p><i class="material-icons md-36">blur_circular</i> &#x2014; material icon named "blur circular".</p>
  static const IconData blur_circular = const IconData(0xe3a2);

  /// <p><i class="material-icons md-36">blur_linear</i> &#x2014; material icon named "blur linear".</p>
  static const IconData blur_linear = const IconData(0xe3a3);

  /// <p><i class="material-icons md-36">blur_off</i> &#x2014; material icon named "blur off".</p>
  static const IconData blur_off = const IconData(0xe3a4);

  /// <p><i class="material-icons md-36">blur_on</i> &#x2014; material icon named "blur on".</p>
  static const IconData blur_on = const IconData(0xe3a5);

  /// <p><i class="material-icons md-36">book</i> &#x2014; material icon named "book".</p>
  static const IconData book = const IconData(0xe865);

  /// <p><i class="material-icons md-36">bookmark</i> &#x2014; material icon named "bookmark".</p>
  static const IconData bookmark = const IconData(0xe866);

  /// <p><i class="material-icons md-36">bookmark_border</i> &#x2014; material icon named "bookmark border".</p>
  static const IconData bookmark_border = const IconData(0xe867);

  /// <p><i class="material-icons md-36">border_all</i> &#x2014; material icon named "border all".</p>
  static const IconData border_all = const IconData(0xe228);

  /// <p><i class="material-icons md-36">border_bottom</i> &#x2014; material icon named "border bottom".</p>
  static const IconData border_bottom = const IconData(0xe229);

  /// <p><i class="material-icons md-36">border_clear</i> &#x2014; material icon named "border clear".</p>
  static const IconData border_clear = const IconData(0xe22a);

  /// <p><i class="material-icons md-36">border_color</i> &#x2014; material icon named "border color".</p>
  static const IconData border_color = const IconData(0xe22b);

  /// <p><i class="material-icons md-36">border_horizontal</i> &#x2014; material icon named "border horizontal".</p>
  static const IconData border_horizontal = const IconData(0xe22c);

  /// <p><i class="material-icons md-36">border_inner</i> &#x2014; material icon named "border inner".</p>
  static const IconData border_inner = const IconData(0xe22d);

  /// <p><i class="material-icons md-36">border_left</i> &#x2014; material icon named "border left".</p>
  static const IconData border_left = const IconData(0xe22e);

  /// <p><i class="material-icons md-36">border_outer</i> &#x2014; material icon named "border outer".</p>
  static const IconData border_outer = const IconData(0xe22f);

  /// <p><i class="material-icons md-36">border_right</i> &#x2014; material icon named "border right".</p>
  static const IconData border_right = const IconData(0xe230);

  /// <p><i class="material-icons md-36">border_style</i> &#x2014; material icon named "border style".</p>
  static const IconData border_style = const IconData(0xe231);

  /// <p><i class="material-icons md-36">border_top</i> &#x2014; material icon named "border top".</p>
  static const IconData border_top = const IconData(0xe232);

  /// <p><i class="material-icons md-36">border_vertical</i> &#x2014; material icon named "border vertical".</p>
  static const IconData border_vertical = const IconData(0xe233);

  /// <p><i class="material-icons md-36">branding_watermark</i> &#x2014; material icon named "branding watermark".</p>
  static const IconData branding_watermark = const IconData(0xe06b);

  /// <p><i class="material-icons md-36">brightness_1</i> &#x2014; material icon named "brightness 1".</p>
  static const IconData brightness_1 = const IconData(0xe3a6);

  /// <p><i class="material-icons md-36">brightness_2</i> &#x2014; material icon named "brightness 2".</p>
  static const IconData brightness_2 = const IconData(0xe3a7);

  /// <p><i class="material-icons md-36">brightness_3</i> &#x2014; material icon named "brightness 3".</p>
  static const IconData brightness_3 = const IconData(0xe3a8);

  /// <p><i class="material-icons md-36">brightness_4</i> &#x2014; material icon named "brightness 4".</p>
  static const IconData brightness_4 = const IconData(0xe3a9);

  /// <p><i class="material-icons md-36">brightness_5</i> &#x2014; material icon named "brightness 5".</p>
  static const IconData brightness_5 = const IconData(0xe3aa);

  /// <p><i class="material-icons md-36">brightness_6</i> &#x2014; material icon named "brightness 6".</p>
  static const IconData brightness_6 = const IconData(0xe3ab);

  /// <p><i class="material-icons md-36">brightness_7</i> &#x2014; material icon named "brightness 7".</p>
  static const IconData brightness_7 = const IconData(0xe3ac);

  /// <p><i class="material-icons md-36">brightness_auto</i> &#x2014; material icon named "brightness auto".</p>
  static const IconData brightness_auto = const IconData(0xe1ab);

  /// <p><i class="material-icons md-36">brightness_high</i> &#x2014; material icon named "brightness high".</p>
  static const IconData brightness_high = const IconData(0xe1ac);

  /// <p><i class="material-icons md-36">brightness_low</i> &#x2014; material icon named "brightness low".</p>
  static const IconData brightness_low = const IconData(0xe1ad);

  /// <p><i class="material-icons md-36">brightness_medium</i> &#x2014; material icon named "brightness medium".</p>
  static const IconData brightness_medium = const IconData(0xe1ae);

  /// <p><i class="material-icons md-36">broken_image</i> &#x2014; material icon named "broken image".</p>
  static const IconData broken_image = const IconData(0xe3ad);

  /// <p><i class="material-icons md-36">brush</i> &#x2014; material icon named "brush".</p>
  static const IconData brush = const IconData(0xe3ae);

  /// <p><i class="material-icons md-36">bubble_chart</i> &#x2014; material icon named "bubble chart".</p>
  static const IconData bubble_chart = const IconData(0xe6dd);

  /// <p><i class="material-icons md-36">bug_report</i> &#x2014; material icon named "bug report".</p>
  static const IconData bug_report = const IconData(0xe868);

  /// <p><i class="material-icons md-36">build</i> &#x2014; material icon named "build".</p>
  static const IconData build = const IconData(0xe869);

  /// <p><i class="material-icons md-36">burst_mode</i> &#x2014; material icon named "burst mode".</p>
  static const IconData burst_mode = const IconData(0xe43c);

  /// <p><i class="material-icons md-36">business</i> &#x2014; material icon named "business".</p>
  static const IconData business = const IconData(0xe0af);

  /// <p><i class="material-icons md-36">business_center</i> &#x2014; material icon named "business center".</p>
  static const IconData business_center = const IconData(0xeb3f);

  /// <p><i class="material-icons md-36">cached</i> &#x2014; material icon named "cached".</p>
  static const IconData cached = const IconData(0xe86a);

  /// <p><i class="material-icons md-36">cake</i> &#x2014; material icon named "cake".</p>
  static const IconData cake = const IconData(0xe7e9);

  /// <p><i class="material-icons md-36">calendar_today</i> &#x2014; material icon named "calendar today".</p>
  static const IconData calendar_today = const IconData(0xe935);

  /// <p><i class="material-icons md-36">calendar_view_day</i> &#x2014; material icon named "calendar view day".</p>
  static const IconData calendar_view_day = const IconData(0xe936);

  /// <p><i class="material-icons md-36">call</i> &#x2014; material icon named "call".</p>
  static const IconData call = const IconData(0xe0b0);

  /// <p><i class="material-icons md-36">call_end</i> &#x2014; material icon named "call end".</p>
  static const IconData call_end = const IconData(0xe0b1);

  /// <p><i class="material-icons md-36">call_made</i> &#x2014; material icon named "call made".</p>
  static const IconData call_made = const IconData(0xe0b2);

  /// <p><i class="material-icons md-36">call_merge</i> &#x2014; material icon named "call merge".</p>
  static const IconData call_merge = const IconData(0xe0b3);

  /// <p><i class="material-icons md-36">call_missed</i> &#x2014; material icon named "call missed".</p>
  static const IconData call_missed = const IconData(0xe0b4);

  /// <p><i class="material-icons md-36">call_missed_outgoing</i> &#x2014; material icon named "call missed outgoing".</p>
  static const IconData call_missed_outgoing = const IconData(0xe0e4);

  /// <p><i class="material-icons md-36">call_received</i> &#x2014; material icon named "call received".</p>
  static const IconData call_received = const IconData(0xe0b5);

  /// <p><i class="material-icons md-36">call_split</i> &#x2014; material icon named "call split".</p>
  static const IconData call_split = const IconData(0xe0b6);

  /// <p><i class="material-icons md-36">call_to_action</i> &#x2014; material icon named "call to action".</p>
  static const IconData call_to_action = const IconData(0xe06c);

  /// <p><i class="material-icons md-36">camera</i> &#x2014; material icon named "camera".</p>
  static const IconData camera = const IconData(0xe3af);

  /// <p><i class="material-icons md-36">camera_alt</i> &#x2014; material icon named "camera alt".</p>
  static const IconData camera_alt = const IconData(0xe3b0);

  /// <p><i class="material-icons md-36">camera_enhance</i> &#x2014; material icon named "camera enhance".</p>
  static const IconData camera_enhance = const IconData(0xe8fc);

  /// <p><i class="material-icons md-36">camera_front</i> &#x2014; material icon named "camera front".</p>
  static const IconData camera_front = const IconData(0xe3b1);

  /// <p><i class="material-icons md-36">camera_rear</i> &#x2014; material icon named "camera rear".</p>
  static const IconData camera_rear = const IconData(0xe3b2);

  /// <p><i class="material-icons md-36">camera_roll</i> &#x2014; material icon named "camera roll".</p>
  static const IconData camera_roll = const IconData(0xe3b3);

  /// <p><i class="material-icons md-36">cancel</i> &#x2014; material icon named "cancel".</p>
  static const IconData cancel = const IconData(0xe5c9);

  /// <p><i class="material-icons md-36">card_giftcard</i> &#x2014; material icon named "card giftcard".</p>
  static const IconData card_giftcard = const IconData(0xe8f6);

  /// <p><i class="material-icons md-36">card_membership</i> &#x2014; material icon named "card membership".</p>
  static const IconData card_membership = const IconData(0xe8f7);

  /// <p><i class="material-icons md-36">card_travel</i> &#x2014; material icon named "card travel".</p>
  static const IconData card_travel = const IconData(0xe8f8);

  /// <p><i class="material-icons md-36">casino</i> &#x2014; material icon named "casino".</p>
  static const IconData casino = const IconData(0xeb40);

  /// <p><i class="material-icons md-36">cast</i> &#x2014; material icon named "cast".</p>
  static const IconData cast = const IconData(0xe307);

  /// <p><i class="material-icons md-36">cast_connected</i> &#x2014; material icon named "cast connected".</p>
  static const IconData cast_connected = const IconData(0xe308);

  /// <p><i class="material-icons md-36">category</i> &#x2014; material icon named "category".</p>
  static const IconData category = const IconData(0xe574);

  /// <p><i class="material-icons md-36">center_focus_strong</i> &#x2014; material icon named "center focus strong".</p>
  static const IconData center_focus_strong = const IconData(0xe3b4);

  /// <p><i class="material-icons md-36">center_focus_weak</i> &#x2014; material icon named "center focus weak".</p>
  static const IconData center_focus_weak = const IconData(0xe3b5);

  /// <p><i class="material-icons md-36">change_history</i> &#x2014; material icon named "change history".</p>
  static const IconData change_history = const IconData(0xe86b);

  /// <p><i class="material-icons md-36">chat</i> &#x2014; material icon named "chat".</p>
  static const IconData chat = const IconData(0xe0b7);

  /// <p><i class="material-icons md-36">chat_bubble</i> &#x2014; material icon named "chat bubble".</p>
  static const IconData chat_bubble = const IconData(0xe0ca);

  /// <p><i class="material-icons md-36">chat_bubble_outline</i> &#x2014; material icon named "chat bubble outline".</p>
  static const IconData chat_bubble_outline = const IconData(0xe0cb);

  /// <p><i class="material-icons md-36">check</i> &#x2014; material icon named "check".</p>
  static const IconData check = const IconData(0xe5ca);

  /// <p><i class="material-icons md-36">check_box</i> &#x2014; material icon named "check box".</p>
  static const IconData check_box = const IconData(0xe834);

  /// <p><i class="material-icons md-36">check_box_outline_blank</i> &#x2014; material icon named "check box outline blank".</p>
  static const IconData check_box_outline_blank = const IconData(0xe835);

  /// <p><i class="material-icons md-36">check_circle</i> &#x2014; material icon named "check circle".</p>
  static const IconData check_circle = const IconData(0xe86c);

  /// <p><i class="material-icons md-36">check_circle_outline</i> &#x2014; material icon named "check circle outline".</p>
  static const IconData check_circle_outline = const IconData(0xe92d);

  /// <p><i class="material-icons md-36">chevron_left</i> &#x2014; material icon named "chevron left".</p>
  static const IconData chevron_left = const IconData(0xe5cb);

  /// <p><i class="material-icons md-36">chevron_right</i> &#x2014; material icon named "chevron right".</p>
  static const IconData chevron_right = const IconData(0xe5cc);

  /// <p><i class="material-icons md-36">child_care</i> &#x2014; material icon named "child care".</p>
  static const IconData child_care = const IconData(0xeb41);

  /// <p><i class="material-icons md-36">child_friendly</i> &#x2014; material icon named "child friendly".</p>
  static const IconData child_friendly = const IconData(0xeb42);

  /// <p><i class="material-icons md-36">chrome_reader_mode</i> &#x2014; material icon named "chrome reader mode".</p>
  static const IconData chrome_reader_mode = const IconData(0xe86d);

  /// <p><i class="material-icons md-36">class</i> &#x2014; material icon named "class".</p>
  static const IconData class_ = const IconData(0xe86e);

  /// <p><i class="material-icons md-36">clear</i> &#x2014; material icon named "clear".</p>
  static const IconData clear = const IconData(0xe14c);

  /// <p><i class="material-icons md-36">clear_all</i> &#x2014; material icon named "clear all".</p>
  static const IconData clear_all = const IconData(0xe0b8);

  /// <p><i class="material-icons md-36">close</i> &#x2014; material icon named "close".</p>
  static const IconData close = const IconData(0xe5cd);

  /// <p><i class="material-icons md-36">closed_caption</i> &#x2014; material icon named "closed caption".</p>
  static const IconData closed_caption = const IconData(0xe01c);

  /// <p><i class="material-icons md-36">cloud</i> &#x2014; material icon named "cloud".</p>
  static const IconData cloud = const IconData(0xe2bd);

  /// <p><i class="material-icons md-36">cloud_circle</i> &#x2014; material icon named "cloud circle".</p>
  static const IconData cloud_circle = const IconData(0xe2be);

  /// <p><i class="material-icons md-36">cloud_done</i> &#x2014; material icon named "cloud done".</p>
  static const IconData cloud_done = const IconData(0xe2bf);

  /// <p><i class="material-icons md-36">cloud_download</i> &#x2014; material icon named "cloud download".</p>
  static const IconData cloud_download = const IconData(0xe2c0);

  /// <p><i class="material-icons md-36">cloud_off</i> &#x2014; material icon named "cloud off".</p>
  static const IconData cloud_off = const IconData(0xe2c1);

  /// <p><i class="material-icons md-36">cloud_queue</i> &#x2014; material icon named "cloud queue".</p>
  static const IconData cloud_queue = const IconData(0xe2c2);

  /// <p><i class="material-icons md-36">cloud_upload</i> &#x2014; material icon named "cloud upload".</p>
  static const IconData cloud_upload = const IconData(0xe2c3);

  /// <p><i class="material-icons md-36">code</i> &#x2014; material icon named "code".</p>
  static const IconData code = const IconData(0xe86f);

  /// <p><i class="material-icons md-36">collections</i> &#x2014; material icon named "collections".</p>
  static const IconData collections = const IconData(0xe3b6);

  /// <p><i class="material-icons md-36">collections_bookmark</i> &#x2014; material icon named "collections bookmark".</p>
  static const IconData collections_bookmark = const IconData(0xe431);

  /// <p><i class="material-icons md-36">color_lens</i> &#x2014; material icon named "color lens".</p>
  static const IconData color_lens = const IconData(0xe3b7);

  /// <p><i class="material-icons md-36">colorize</i> &#x2014; material icon named "colorize".</p>
  static const IconData colorize = const IconData(0xe3b8);

  /// <p><i class="material-icons md-36">comment</i> &#x2014; material icon named "comment".</p>
  static const IconData comment = const IconData(0xe0b9);

  /// <p><i class="material-icons md-36">compare</i> &#x2014; material icon named "compare".</p>
  static const IconData compare = const IconData(0xe3b9);

  /// <p><i class="material-icons md-36">compare_arrows</i> &#x2014; material icon named "compare arrows".</p>
  static const IconData compare_arrows = const IconData(0xe915);

  /// <p><i class="material-icons md-36">computer</i> &#x2014; material icon named "computer".</p>
  static const IconData computer = const IconData(0xe30a);

  /// <p><i class="material-icons md-36">confirmation_number</i> &#x2014; material icon named "confirmation number".</p>
  static const IconData confirmation_number = const IconData(0xe638);

  /// <p><i class="material-icons md-36">contact_mail</i> &#x2014; material icon named "contact mail".</p>
  static const IconData contact_mail = const IconData(0xe0d0);

  /// <p><i class="material-icons md-36">contact_phone</i> &#x2014; material icon named "contact phone".</p>
  static const IconData contact_phone = const IconData(0xe0cf);

  /// <p><i class="material-icons md-36">contacts</i> &#x2014; material icon named "contacts".</p>
  static const IconData contacts = const IconData(0xe0ba);

  /// <p><i class="material-icons md-36">content_copy</i> &#x2014; material icon named "content copy".</p>
  static const IconData content_copy = const IconData(0xe14d);

  /// <p><i class="material-icons md-36">content_cut</i> &#x2014; material icon named "content cut".</p>
  static const IconData content_cut = const IconData(0xe14e);

  /// <p><i class="material-icons md-36">content_paste</i> &#x2014; material icon named "content paste".</p>
  static const IconData content_paste = const IconData(0xe14f);

  /// <p><i class="material-icons md-36">control_point</i> &#x2014; material icon named "control point".</p>
  static const IconData control_point = const IconData(0xe3ba);

  /// <p><i class="material-icons md-36">control_point_duplicate</i> &#x2014; material icon named "control point duplicate".</p>
  static const IconData control_point_duplicate = const IconData(0xe3bb);

  /// <p><i class="material-icons md-36">copyright</i> &#x2014; material icon named "copyright".</p>
  static const IconData copyright = const IconData(0xe90c);

  /// <p><i class="material-icons md-36">create</i> &#x2014; material icon named "create".</p>
  static const IconData create = const IconData(0xe150);

  /// <p><i class="material-icons md-36">create_new_folder</i> &#x2014; material icon named "create new folder".</p>
  static const IconData create_new_folder = const IconData(0xe2cc);

  /// <p><i class="material-icons md-36">credit_card</i> &#x2014; material icon named "credit card".</p>
  static const IconData credit_card = const IconData(0xe870);

  /// <p><i class="material-icons md-36">crop</i> &#x2014; material icon named "crop".</p>
  static const IconData crop = const IconData(0xe3be);

  /// <p><i class="material-icons md-36">crop_16_9</i> &#x2014; material icon named "crop 16 9".</p>
  static const IconData crop_16_9 = const IconData(0xe3bc);

  /// <p><i class="material-icons md-36">crop_3_2</i> &#x2014; material icon named "crop 3 2".</p>
  static const IconData crop_3_2 = const IconData(0xe3bd);

  /// <p><i class="material-icons md-36">crop_5_4</i> &#x2014; material icon named "crop 5 4".</p>
  static const IconData crop_5_4 = const IconData(0xe3bf);

  /// <p><i class="material-icons md-36">crop_7_5</i> &#x2014; material icon named "crop 7 5".</p>
  static const IconData crop_7_5 = const IconData(0xe3c0);

  /// <p><i class="material-icons md-36">crop_din</i> &#x2014; material icon named "crop din".</p>
  static const IconData crop_din = const IconData(0xe3c1);

  /// <p><i class="material-icons md-36">crop_free</i> &#x2014; material icon named "crop free".</p>
  static const IconData crop_free = const IconData(0xe3c2);

  /// <p><i class="material-icons md-36">crop_landscape</i> &#x2014; material icon named "crop landscape".</p>
  static const IconData crop_landscape = const IconData(0xe3c3);

  /// <p><i class="material-icons md-36">crop_original</i> &#x2014; material icon named "crop original".</p>
  static const IconData crop_original = const IconData(0xe3c4);

  /// <p><i class="material-icons md-36">crop_portrait</i> &#x2014; material icon named "crop portrait".</p>
  static const IconData crop_portrait = const IconData(0xe3c5);

  /// <p><i class="material-icons md-36">crop_rotate</i> &#x2014; material icon named "crop rotate".</p>
  static const IconData crop_rotate = const IconData(0xe437);

  /// <p><i class="material-icons md-36">crop_square</i> &#x2014; material icon named "crop square".</p>
  static const IconData crop_square = const IconData(0xe3c6);

  /// <p><i class="material-icons md-36">dashboard</i> &#x2014; material icon named "dashboard".</p>
  static const IconData dashboard = const IconData(0xe871);

  /// <p><i class="material-icons md-36">data_usage</i> &#x2014; material icon named "data usage".</p>
  static const IconData data_usage = const IconData(0xe1af);

  /// <p><i class="material-icons md-36">date_range</i> &#x2014; material icon named "date range".</p>
  static const IconData date_range = const IconData(0xe916);

  /// <p><i class="material-icons md-36">dehaze</i> &#x2014; material icon named "dehaze".</p>
  static const IconData dehaze = const IconData(0xe3c7);

  /// <p><i class="material-icons md-36">delete</i> &#x2014; material icon named "delete".</p>
  static const IconData delete = const IconData(0xe872);

  /// <p><i class="material-icons md-36">delete_forever</i> &#x2014; material icon named "delete forever".</p>
  static const IconData delete_forever = const IconData(0xe92b);

  /// <p><i class="material-icons md-36">delete_outline</i> &#x2014; material icon named "delete outline".</p>
  static const IconData delete_outline = const IconData(0xe92e);

  /// <p><i class="material-icons md-36">delete_sweep</i> &#x2014; material icon named "delete sweep".</p>
  static const IconData delete_sweep = const IconData(0xe16c);

  /// <p><i class="material-icons md-36">departure_board</i> &#x2014; material icon named "departure board".</p>
  static const IconData departure_board = const IconData(0xe576);

  /// <p><i class="material-icons md-36">description</i> &#x2014; material icon named "description".</p>
  static const IconData description = const IconData(0xe873);

  /// <p><i class="material-icons md-36">desktop_mac</i> &#x2014; material icon named "desktop mac".</p>
  static const IconData desktop_mac = const IconData(0xe30b);

  /// <p><i class="material-icons md-36">desktop_windows</i> &#x2014; material icon named "desktop windows".</p>
  static const IconData desktop_windows = const IconData(0xe30c);

  /// <p><i class="material-icons md-36">details</i> &#x2014; material icon named "details".</p>
  static const IconData details = const IconData(0xe3c8);

  /// <p><i class="material-icons md-36">developer_board</i> &#x2014; material icon named "developer board".</p>
  static const IconData developer_board = const IconData(0xe30d);

  /// <p><i class="material-icons md-36">developer_mode</i> &#x2014; material icon named "developer mode".</p>
  static const IconData developer_mode = const IconData(0xe1b0);

  /// <p><i class="material-icons md-36">device_hub</i> &#x2014; material icon named "device hub".</p>
  static const IconData device_hub = const IconData(0xe335);

  /// <p><i class="material-icons md-36">device_unknown</i> &#x2014; material icon named "device unknown".</p>
  static const IconData device_unknown = const IconData(0xe339);

  /// <p><i class="material-icons md-36">devices</i> &#x2014; material icon named "devices".</p>
  static const IconData devices = const IconData(0xe1b1);

  /// <p><i class="material-icons md-36">devices_other</i> &#x2014; material icon named "devices other".</p>
  static const IconData devices_other = const IconData(0xe337);

  /// <p><i class="material-icons md-36">dialer_sip</i> &#x2014; material icon named "dialer sip".</p>
  static const IconData dialer_sip = const IconData(0xe0bb);

  /// <p><i class="material-icons md-36">dialpad</i> &#x2014; material icon named "dialpad".</p>
  static const IconData dialpad = const IconData(0xe0bc);

  /// <p><i class="material-icons md-36">directions</i> &#x2014; material icon named "directions".</p>
  static const IconData directions = const IconData(0xe52e);

  /// <p><i class="material-icons md-36">directions_bike</i> &#x2014; material icon named "directions bike".</p>
  static const IconData directions_bike = const IconData(0xe52f);

  /// <p><i class="material-icons md-36">directions_boat</i> &#x2014; material icon named "directions boat".</p>
  static const IconData directions_boat = const IconData(0xe532);

  /// <p><i class="material-icons md-36">directions_bus</i> &#x2014; material icon named "directions bus".</p>
  static const IconData directions_bus = const IconData(0xe530);

  /// <p><i class="material-icons md-36">directions_car</i> &#x2014; material icon named "directions car".</p>
  static const IconData directions_car = const IconData(0xe531);

  /// <p><i class="material-icons md-36">directions_railway</i> &#x2014; material icon named "directions railway".</p>
  static const IconData directions_railway = const IconData(0xe534);

  /// <p><i class="material-icons md-36">directions_run</i> &#x2014; material icon named "directions run".</p>
  static const IconData directions_run = const IconData(0xe566);

  /// <p><i class="material-icons md-36">directions_subway</i> &#x2014; material icon named "directions subway".</p>
  static const IconData directions_subway = const IconData(0xe533);

  /// <p><i class="material-icons md-36">directions_transit</i> &#x2014; material icon named "directions transit".</p>
  static const IconData directions_transit = const IconData(0xe535);

  /// <p><i class="material-icons md-36">directions_walk</i> &#x2014; material icon named "directions walk".</p>
  static const IconData directions_walk = const IconData(0xe536);

  /// <p><i class="material-icons md-36">disc_full</i> &#x2014; material icon named "disc full".</p>
  static const IconData disc_full = const IconData(0xe610);

  /// <p><i class="material-icons md-36">dns</i> &#x2014; material icon named "dns".</p>
  static const IconData dns = const IconData(0xe875);

  /// <p><i class="material-icons md-36">do_not_disturb</i> &#x2014; material icon named "do not disturb".</p>
  static const IconData do_not_disturb = const IconData(0xe612);

  /// <p><i class="material-icons md-36">do_not_disturb_alt</i> &#x2014; material icon named "do not disturb alt".</p>
  static const IconData do_not_disturb_alt = const IconData(0xe611);

  /// <p><i class="material-icons md-36">do_not_disturb_off</i> &#x2014; material icon named "do not disturb off".</p>
  static const IconData do_not_disturb_off = const IconData(0xe643);

  /// <p><i class="material-icons md-36">do_not_disturb_on</i> &#x2014; material icon named "do not disturb on".</p>
  static const IconData do_not_disturb_on = const IconData(0xe644);

  /// <p><i class="material-icons md-36">dock</i> &#x2014; material icon named "dock".</p>
  static const IconData dock = const IconData(0xe30e);

  /// <p><i class="material-icons md-36">domain</i> &#x2014; material icon named "domain".</p>
  static const IconData domain = const IconData(0xe7ee);

  /// <p><i class="material-icons md-36">done</i> &#x2014; material icon named "done".</p>
  static const IconData done = const IconData(0xe876);

  /// <p><i class="material-icons md-36">done_all</i> &#x2014; material icon named "done all".</p>
  static const IconData done_all = const IconData(0xe877);

  /// <p><i class="material-icons md-36">done_outline</i> &#x2014; material icon named "done outline".</p>
  static const IconData done_outline = const IconData(0xe92f);

  /// <p><i class="material-icons md-36">donut_large</i> &#x2014; material icon named "donut large".</p>
  static const IconData donut_large = const IconData(0xe917);

  /// <p><i class="material-icons md-36">donut_small</i> &#x2014; material icon named "donut small".</p>
  static const IconData donut_small = const IconData(0xe918);

  /// <p><i class="material-icons md-36">drafts</i> &#x2014; material icon named "drafts".</p>
  static const IconData drafts = const IconData(0xe151);

  /// <p><i class="material-icons md-36">drag_handle</i> &#x2014; material icon named "drag handle".</p>
  static const IconData drag_handle = const IconData(0xe25d);

  /// <p><i class="material-icons md-36">drive_eta</i> &#x2014; material icon named "drive eta".</p>
  static const IconData drive_eta = const IconData(0xe613);

  /// <p><i class="material-icons md-36">dvr</i> &#x2014; material icon named "dvr".</p>
  static const IconData dvr = const IconData(0xe1b2);

  /// <p><i class="material-icons md-36">edit</i> &#x2014; material icon named "edit".</p>
  static const IconData edit = const IconData(0xe3c9);

  /// <p><i class="material-icons md-36">edit_attributes</i> &#x2014; material icon named "edit attributes".</p>
  static const IconData edit_attributes = const IconData(0xe578);

  /// <p><i class="material-icons md-36">edit_location</i> &#x2014; material icon named "edit location".</p>
  static const IconData edit_location = const IconData(0xe568);

  /// <p><i class="material-icons md-36">eject</i> &#x2014; material icon named "eject".</p>
  static const IconData eject = const IconData(0xe8fb);

  /// <p><i class="material-icons md-36">email</i> &#x2014; material icon named "email".</p>
  static const IconData email = const IconData(0xe0be);

  /// <p><i class="material-icons md-36">enhanced_encryption</i> &#x2014; material icon named "enhanced encryption".</p>
  static const IconData enhanced_encryption = const IconData(0xe63f);

  /// <p><i class="material-icons md-36">equalizer</i> &#x2014; material icon named "equalizer".</p>
  static const IconData equalizer = const IconData(0xe01d);

  /// <p><i class="material-icons md-36">error</i> &#x2014; material icon named "error".</p>
  static const IconData error = const IconData(0xe000);

  /// <p><i class="material-icons md-36">error_outline</i> &#x2014; material icon named "error outline".</p>
  static const IconData error_outline = const IconData(0xe001);

  /// <p><i class="material-icons md-36">euro_symbol</i> &#x2014; material icon named "euro symbol".</p>
  static const IconData euro_symbol = const IconData(0xe926);

  /// <p><i class="material-icons md-36">ev_station</i> &#x2014; material icon named "ev station".</p>
  static const IconData ev_station = const IconData(0xe56d);

  /// <p><i class="material-icons md-36">event</i> &#x2014; material icon named "event".</p>
  static const IconData event = const IconData(0xe878);

  /// <p><i class="material-icons md-36">event_available</i> &#x2014; material icon named "event available".</p>
  static const IconData event_available = const IconData(0xe614);

  /// <p><i class="material-icons md-36">event_busy</i> &#x2014; material icon named "event busy".</p>
  static const IconData event_busy = const IconData(0xe615);

  /// <p><i class="material-icons md-36">event_note</i> &#x2014; material icon named "event note".</p>
  static const IconData event_note = const IconData(0xe616);

  /// <p><i class="material-icons md-36">event_seat</i> &#x2014; material icon named "event seat".</p>
  static const IconData event_seat = const IconData(0xe903);

  /// <p><i class="material-icons md-36">exit_to_app</i> &#x2014; material icon named "exit to app".</p>
  static const IconData exit_to_app = const IconData(0xe879);

  /// <p><i class="material-icons md-36">expand_less</i> &#x2014; material icon named "expand less".</p>
  static const IconData expand_less = const IconData(0xe5ce);

  /// <p><i class="material-icons md-36">expand_more</i> &#x2014; material icon named "expand more".</p>
  static const IconData expand_more = const IconData(0xe5cf);

  /// <p><i class="material-icons md-36">explicit</i> &#x2014; material icon named "explicit".</p>
  static const IconData explicit = const IconData(0xe01e);

  /// <p><i class="material-icons md-36">explore</i> &#x2014; material icon named "explore".</p>
  static const IconData explore = const IconData(0xe87a);

  /// <p><i class="material-icons md-36">exposure</i> &#x2014; material icon named "exposure".</p>
  static const IconData exposure = const IconData(0xe3ca);

  /// <p><i class="material-icons md-36">exposure_neg_1</i> &#x2014; material icon named "exposure neg 1".</p>
  static const IconData exposure_neg_1 = const IconData(0xe3cb);

  /// <p><i class="material-icons md-36">exposure_neg_2</i> &#x2014; material icon named "exposure neg 2".</p>
  static const IconData exposure_neg_2 = const IconData(0xe3cc);

  /// <p><i class="material-icons md-36">exposure_plus_1</i> &#x2014; material icon named "exposure plus 1".</p>
  static const IconData exposure_plus_1 = const IconData(0xe3cd);

  /// <p><i class="material-icons md-36">exposure_plus_2</i> &#x2014; material icon named "exposure plus 2".</p>
  static const IconData exposure_plus_2 = const IconData(0xe3ce);

  /// <p><i class="material-icons md-36">exposure_zero</i> &#x2014; material icon named "exposure zero".</p>
  static const IconData exposure_zero = const IconData(0xe3cf);

  /// <p><i class="material-icons md-36">extension</i> &#x2014; material icon named "extension".</p>
  static const IconData extension = const IconData(0xe87b);

  /// <p><i class="material-icons md-36">face</i> &#x2014; material icon named "face".</p>
  static const IconData face = const IconData(0xe87c);

  /// <p><i class="material-icons md-36">fast_forward</i> &#x2014; material icon named "fast forward".</p>
  static const IconData fast_forward = const IconData(0xe01f);

  /// <p><i class="material-icons md-36">fast_rewind</i> &#x2014; material icon named "fast rewind".</p>
  static const IconData fast_rewind = const IconData(0xe020);

  /// <p><i class="material-icons md-36">fastfood</i> &#x2014; material icon named "fastfood".</p>
  static const IconData fastfood = const IconData(0xe57a);

  /// <p><i class="material-icons md-36">favorite</i> &#x2014; material icon named "favorite".</p>
  static const IconData favorite = const IconData(0xe87d);

  /// <p><i class="material-icons md-36">favorite_border</i> &#x2014; material icon named "favorite border".</p>
  static const IconData favorite_border = const IconData(0xe87e);

  /// <p><i class="material-icons md-36">featured_play_list</i> &#x2014; material icon named "featured play list".</p>
  static const IconData featured_play_list = const IconData(0xe06d);

  /// <p><i class="material-icons md-36">featured_video</i> &#x2014; material icon named "featured video".</p>
  static const IconData featured_video = const IconData(0xe06e);

  /// <p><i class="material-icons md-36">feedback</i> &#x2014; material icon named "feedback".</p>
  static const IconData feedback = const IconData(0xe87f);

  /// <p><i class="material-icons md-36">fiber_dvr</i> &#x2014; material icon named "fiber dvr".</p>
  static const IconData fiber_dvr = const IconData(0xe05d);

  /// <p><i class="material-icons md-36">fiber_manual_record</i> &#x2014; material icon named "fiber manual record".</p>
  static const IconData fiber_manual_record = const IconData(0xe061);

  /// <p><i class="material-icons md-36">fiber_new</i> &#x2014; material icon named "fiber new".</p>
  static const IconData fiber_new = const IconData(0xe05e);

  /// <p><i class="material-icons md-36">fiber_pin</i> &#x2014; material icon named "fiber pin".</p>
  static const IconData fiber_pin = const IconData(0xe06a);

  /// <p><i class="material-icons md-36">fiber_smart_record</i> &#x2014; material icon named "fiber smart record".</p>
  static const IconData fiber_smart_record = const IconData(0xe062);

  /// <p><i class="material-icons md-36">file_download</i> &#x2014; material icon named "file download".</p>
  static const IconData file_download = const IconData(0xe2c4);

  /// <p><i class="material-icons md-36">file_upload</i> &#x2014; material icon named "file upload".</p>
  static const IconData file_upload = const IconData(0xe2c6);

  /// <p><i class="material-icons md-36">filter</i> &#x2014; material icon named "filter".</p>
  static const IconData filter = const IconData(0xe3d3);

  /// <p><i class="material-icons md-36">filter_1</i> &#x2014; material icon named "filter 1".</p>
  static const IconData filter_1 = const IconData(0xe3d0);

  /// <p><i class="material-icons md-36">filter_2</i> &#x2014; material icon named "filter 2".</p>
  static const IconData filter_2 = const IconData(0xe3d1);

  /// <p><i class="material-icons md-36">filter_3</i> &#x2014; material icon named "filter 3".</p>
  static const IconData filter_3 = const IconData(0xe3d2);

  /// <p><i class="material-icons md-36">filter_4</i> &#x2014; material icon named "filter 4".</p>
  static const IconData filter_4 = const IconData(0xe3d4);

  /// <p><i class="material-icons md-36">filter_5</i> &#x2014; material icon named "filter 5".</p>
  static const IconData filter_5 = const IconData(0xe3d5);

  /// <p><i class="material-icons md-36">filter_6</i> &#x2014; material icon named "filter 6".</p>
  static const IconData filter_6 = const IconData(0xe3d6);

  /// <p><i class="material-icons md-36">filter_7</i> &#x2014; material icon named "filter 7".</p>
  static const IconData filter_7 = const IconData(0xe3d7);

  /// <p><i class="material-icons md-36">filter_8</i> &#x2014; material icon named "filter 8".</p>
  static const IconData filter_8 = const IconData(0xe3d8);

  /// <p><i class="material-icons md-36">filter_9</i> &#x2014; material icon named "filter 9".</p>
  static const IconData filter_9 = const IconData(0xe3d9);

  /// <p><i class="material-icons md-36">filter_9_plus</i> &#x2014; material icon named "filter 9 plus".</p>
  static const IconData filter_9_plus = const IconData(0xe3da);

  /// <p><i class="material-icons md-36">filter_b_and_w</i> &#x2014; material icon named "filter b and w".</p>
  static const IconData filter_b_and_w = const IconData(0xe3db);

  /// <p><i class="material-icons md-36">filter_center_focus</i> &#x2014; material icon named "filter center focus".</p>
  static const IconData filter_center_focus = const IconData(0xe3dc);

  /// <p><i class="material-icons md-36">filter_drama</i> &#x2014; material icon named "filter drama".</p>
  static const IconData filter_drama = const IconData(0xe3dd);

  /// <p><i class="material-icons md-36">filter_frames</i> &#x2014; material icon named "filter frames".</p>
  static const IconData filter_frames = const IconData(0xe3de);

  /// <p><i class="material-icons md-36">filter_hdr</i> &#x2014; material icon named "filter hdr".</p>
  static const IconData filter_hdr = const IconData(0xe3df);

  /// <p><i class="material-icons md-36">filter_list</i> &#x2014; material icon named "filter list".</p>
  static const IconData filter_list = const IconData(0xe152);

  /// <p><i class="material-icons md-36">filter_none</i> &#x2014; material icon named "filter none".</p>
  static const IconData filter_none = const IconData(0xe3e0);

  /// <p><i class="material-icons md-36">filter_tilt_shift</i> &#x2014; material icon named "filter tilt shift".</p>
  static const IconData filter_tilt_shift = const IconData(0xe3e2);

  /// <p><i class="material-icons md-36">filter_vintage</i> &#x2014; material icon named "filter vintage".</p>
  static const IconData filter_vintage = const IconData(0xe3e3);

  /// <p><i class="material-icons md-36">find_in_page</i> &#x2014; material icon named "find in page".</p>
  static const IconData find_in_page = const IconData(0xe880);

  /// <p><i class="material-icons md-36">find_replace</i> &#x2014; material icon named "find replace".</p>
  static const IconData find_replace = const IconData(0xe881);

  /// <p><i class="material-icons md-36">fingerprint</i> &#x2014; material icon named "fingerprint".</p>
  static const IconData fingerprint = const IconData(0xe90d);

  /// <p><i class="material-icons md-36">first_page</i> &#x2014; material icon named "first page".</p>
  static const IconData first_page = const IconData(0xe5dc);

  /// <p><i class="material-icons md-36">fitness_center</i> &#x2014; material icon named "fitness center".</p>
  static const IconData fitness_center = const IconData(0xeb43);

  /// <p><i class="material-icons md-36">flag</i> &#x2014; material icon named "flag".</p>
  static const IconData flag = const IconData(0xe153);

  /// <p><i class="material-icons md-36">flare</i> &#x2014; material icon named "flare".</p>
  static const IconData flare = const IconData(0xe3e4);

  /// <p><i class="material-icons md-36">flash_auto</i> &#x2014; material icon named "flash auto".</p>
  static const IconData flash_auto = const IconData(0xe3e5);

  /// <p><i class="material-icons md-36">flash_off</i> &#x2014; material icon named "flash off".</p>
  static const IconData flash_off = const IconData(0xe3e6);

  /// <p><i class="material-icons md-36">flash_on</i> &#x2014; material icon named "flash on".</p>
  static const IconData flash_on = const IconData(0xe3e7);

  /// <p><i class="material-icons md-36">flight</i> &#x2014; material icon named "flight".</p>
  static const IconData flight = const IconData(0xe539);

  /// <p><i class="material-icons md-36">flight_land</i> &#x2014; material icon named "flight land".</p>
  static const IconData flight_land = const IconData(0xe904);

  /// <p><i class="material-icons md-36">flight_takeoff</i> &#x2014; material icon named "flight takeoff".</p>
  static const IconData flight_takeoff = const IconData(0xe905);

  /// <p><i class="material-icons md-36">flip</i> &#x2014; material icon named "flip".</p>
  static const IconData flip = const IconData(0xe3e8);

  /// <p><i class="material-icons md-36">flip_to_back</i> &#x2014; material icon named "flip to back".</p>
  static const IconData flip_to_back = const IconData(0xe882);

  /// <p><i class="material-icons md-36">flip_to_front</i> &#x2014; material icon named "flip to front".</p>
  static const IconData flip_to_front = const IconData(0xe883);

  /// <p><i class="material-icons md-36">folder</i> &#x2014; material icon named "folder".</p>
  static const IconData folder = const IconData(0xe2c7);

  /// <p><i class="material-icons md-36">folder_open</i> &#x2014; material icon named "folder open".</p>
  static const IconData folder_open = const IconData(0xe2c8);

  /// <p><i class="material-icons md-36">folder_shared</i> &#x2014; material icon named "folder shared".</p>
  static const IconData folder_shared = const IconData(0xe2c9);

  /// <p><i class="material-icons md-36">folder_special</i> &#x2014; material icon named "folder special".</p>
  static const IconData folder_special = const IconData(0xe617);

  /// <p><i class="material-icons md-36">font_download</i> &#x2014; material icon named "font download".</p>
  static const IconData font_download = const IconData(0xe167);

  /// <p><i class="material-icons md-36">format_align_center</i> &#x2014; material icon named "format align center".</p>
  static const IconData format_align_center = const IconData(0xe234);

  /// <p><i class="material-icons md-36">format_align_justify</i> &#x2014; material icon named "format align justify".</p>
  static const IconData format_align_justify = const IconData(0xe235);

  /// <p><i class="material-icons md-36">format_align_left</i> &#x2014; material icon named "format align left".</p>
  static const IconData format_align_left = const IconData(0xe236);

  /// <p><i class="material-icons md-36">format_align_right</i> &#x2014; material icon named "format align right".</p>
  static const IconData format_align_right = const IconData(0xe237);

  /// <p><i class="material-icons md-36">format_bold</i> &#x2014; material icon named "format bold".</p>
  static const IconData format_bold = const IconData(0xe238);

  /// <p><i class="material-icons md-36">format_clear</i> &#x2014; material icon named "format clear".</p>
  static const IconData format_clear = const IconData(0xe239);

  /// <p><i class="material-icons md-36">format_color_fill</i> &#x2014; material icon named "format color fill".</p>
  static const IconData format_color_fill = const IconData(0xe23a);

  /// <p><i class="material-icons md-36">format_color_reset</i> &#x2014; material icon named "format color reset".</p>
  static const IconData format_color_reset = const IconData(0xe23b);

  /// <p><i class="material-icons md-36">format_color_text</i> &#x2014; material icon named "format color text".</p>
  static const IconData format_color_text = const IconData(0xe23c);

  /// <p><i class="material-icons md-36">format_indent_decrease</i> &#x2014; material icon named "format indent decrease".</p>
  static const IconData format_indent_decrease = const IconData(0xe23d);

  /// <p><i class="material-icons md-36">format_indent_increase</i> &#x2014; material icon named "format indent increase".</p>
  static const IconData format_indent_increase = const IconData(0xe23e);

  /// <p><i class="material-icons md-36">format_italic</i> &#x2014; material icon named "format italic".</p>
  static const IconData format_italic = const IconData(0xe23f);

  /// <p><i class="material-icons md-36">format_line_spacing</i> &#x2014; material icon named "format line spacing".</p>
  static const IconData format_line_spacing = const IconData(0xe240);

  /// <p><i class="material-icons md-36">format_list_bulleted</i> &#x2014; material icon named "format list bulleted".</p>
  static const IconData format_list_bulleted = const IconData(0xe241);

  /// <p><i class="material-icons md-36">format_list_numbered</i> &#x2014; material icon named "format list numbered".</p>
  static const IconData format_list_numbered = const IconData(0xe242);

  /// <p><i class="material-icons md-36">format_list_numbered_rtl</i> &#x2014; material icon named "format list numbered rtl".</p>
  static const IconData format_list_numbered_rtl = const IconData(0xe267);

  /// <p><i class="material-icons md-36">format_paint</i> &#x2014; material icon named "format paint".</p>
  static const IconData format_paint = const IconData(0xe243);

  /// <p><i class="material-icons md-36">format_quote</i> &#x2014; material icon named "format quote".</p>
  static const IconData format_quote = const IconData(0xe244);

  /// <p><i class="material-icons md-36">format_shapes</i> &#x2014; material icon named "format shapes".</p>
  static const IconData format_shapes = const IconData(0xe25e);

  /// <p><i class="material-icons md-36">format_size</i> &#x2014; material icon named "format size".</p>
  static const IconData format_size = const IconData(0xe245);

  /// <p><i class="material-icons md-36">format_strikethrough</i> &#x2014; material icon named "format strikethrough".</p>
  static const IconData format_strikethrough = const IconData(0xe246);

  /// <p><i class="material-icons md-36">format_textdirection_l_to_r</i> &#x2014; material icon named "format textdirection l to r".</p>
  static const IconData format_textdirection_l_to_r = const IconData(0xe247);

  /// <p><i class="material-icons md-36">format_textdirection_r_to_l</i> &#x2014; material icon named "format textdirection r to l".</p>
  static const IconData format_textdirection_r_to_l = const IconData(0xe248);

  /// <p><i class="material-icons md-36">format_underlined</i> &#x2014; material icon named "format underlined".</p>
  static const IconData format_underlined = const IconData(0xe249);

  /// <p><i class="material-icons md-36">forum</i> &#x2014; material icon named "forum".</p>
  static const IconData forum = const IconData(0xe0bf);

  /// <p><i class="material-icons md-36">forward</i> &#x2014; material icon named "forward".</p>
  static const IconData forward = const IconData(0xe154);

  /// <p><i class="material-icons md-36">forward_10</i> &#x2014; material icon named "forward 10".</p>
  static const IconData forward_10 = const IconData(0xe056);

  /// <p><i class="material-icons md-36">forward_30</i> &#x2014; material icon named "forward 30".</p>
  static const IconData forward_30 = const IconData(0xe057);

  /// <p><i class="material-icons md-36">forward_5</i> &#x2014; material icon named "forward 5".</p>
  static const IconData forward_5 = const IconData(0xe058);

  /// <p><i class="material-icons md-36">free_breakfast</i> &#x2014; material icon named "free breakfast".</p>
  static const IconData free_breakfast = const IconData(0xeb44);

  /// <p><i class="material-icons md-36">fullscreen</i> &#x2014; material icon named "fullscreen".</p>
  static const IconData fullscreen = const IconData(0xe5d0);

  /// <p><i class="material-icons md-36">fullscreen_exit</i> &#x2014; material icon named "fullscreen exit".</p>
  static const IconData fullscreen_exit = const IconData(0xe5d1);

  /// <p><i class="material-icons md-36">functions</i> &#x2014; material icon named "functions".</p>
  static const IconData functions = const IconData(0xe24a);

  /// <p><i class="material-icons md-36">g_translate</i> &#x2014; material icon named "g translate".</p>
  static const IconData g_translate = const IconData(0xe927);

  /// <p><i class="material-icons md-36">gamepad</i> &#x2014; material icon named "gamepad".</p>
  static const IconData gamepad = const IconData(0xe30f);

  /// <p><i class="material-icons md-36">games</i> &#x2014; material icon named "games".</p>
  static const IconData games = const IconData(0xe021);

  /// <p><i class="material-icons md-36">gavel</i> &#x2014; material icon named "gavel".</p>
  static const IconData gavel = const IconData(0xe90e);

  /// <p><i class="material-icons md-36">gesture</i> &#x2014; material icon named "gesture".</p>
  static const IconData gesture = const IconData(0xe155);

  /// <p><i class="material-icons md-36">get_app</i> &#x2014; material icon named "get app".</p>
  static const IconData get_app = const IconData(0xe884);

  /// <p><i class="material-icons md-36">gif</i> &#x2014; material icon named "gif".</p>
  static const IconData gif = const IconData(0xe908);

  /// <p><i class="material-icons md-36">golf_course</i> &#x2014; material icon named "golf course".</p>
  static const IconData golf_course = const IconData(0xeb45);

  /// <p><i class="material-icons md-36">gps_fixed</i> &#x2014; material icon named "gps fixed".</p>
  static const IconData gps_fixed = const IconData(0xe1b3);

  /// <p><i class="material-icons md-36">gps_not_fixed</i> &#x2014; material icon named "gps not fixed".</p>
  static const IconData gps_not_fixed = const IconData(0xe1b4);

  /// <p><i class="material-icons md-36">gps_off</i> &#x2014; material icon named "gps off".</p>
  static const IconData gps_off = const IconData(0xe1b5);

  /// <p><i class="material-icons md-36">grade</i> &#x2014; material icon named "grade".</p>
  static const IconData grade = const IconData(0xe885);

  /// <p><i class="material-icons md-36">gradient</i> &#x2014; material icon named "gradient".</p>
  static const IconData gradient = const IconData(0xe3e9);

  /// <p><i class="material-icons md-36">grain</i> &#x2014; material icon named "grain".</p>
  static const IconData grain = const IconData(0xe3ea);

  /// <p><i class="material-icons md-36">graphic_eq</i> &#x2014; material icon named "graphic eq".</p>
  static const IconData graphic_eq = const IconData(0xe1b8);

  /// <p><i class="material-icons md-36">grid_off</i> &#x2014; material icon named "grid off".</p>
  static const IconData grid_off = const IconData(0xe3eb);

  /// <p><i class="material-icons md-36">grid_on</i> &#x2014; material icon named "grid on".</p>
  static const IconData grid_on = const IconData(0xe3ec);

  /// <p><i class="material-icons md-36">group</i> &#x2014; material icon named "group".</p>
  static const IconData group = const IconData(0xe7ef);

  /// <p><i class="material-icons md-36">group_add</i> &#x2014; material icon named "group add".</p>
  static const IconData group_add = const IconData(0xe7f0);

  /// <p><i class="material-icons md-36">group_work</i> &#x2014; material icon named "group work".</p>
  static const IconData group_work = const IconData(0xe886);

  /// <p><i class="material-icons md-36">hd</i> &#x2014; material icon named "hd".</p>
  static const IconData hd = const IconData(0xe052);

  /// <p><i class="material-icons md-36">hdr_off</i> &#x2014; material icon named "hdr off".</p>
  static const IconData hdr_off = const IconData(0xe3ed);

  /// <p><i class="material-icons md-36">hdr_on</i> &#x2014; material icon named "hdr on".</p>
  static const IconData hdr_on = const IconData(0xe3ee);

  /// <p><i class="material-icons md-36">hdr_strong</i> &#x2014; material icon named "hdr strong".</p>
  static const IconData hdr_strong = const IconData(0xe3f1);

  /// <p><i class="material-icons md-36">hdr_weak</i> &#x2014; material icon named "hdr weak".</p>
  static const IconData hdr_weak = const IconData(0xe3f2);

  /// <p><i class="material-icons md-36">headset</i> &#x2014; material icon named "headset".</p>
  static const IconData headset = const IconData(0xe310);

  /// <p><i class="material-icons md-36">headset_mic</i> &#x2014; material icon named "headset mic".</p>
  static const IconData headset_mic = const IconData(0xe311);

  /// <p><i class="material-icons md-36">headset_off</i> &#x2014; material icon named "headset off".</p>
  static const IconData headset_off = const IconData(0xe33a);

  /// <p><i class="material-icons md-36">healing</i> &#x2014; material icon named "healing".</p>
  static const IconData healing = const IconData(0xe3f3);

  /// <p><i class="material-icons md-36">hearing</i> &#x2014; material icon named "hearing".</p>
  static const IconData hearing = const IconData(0xe023);

  /// <p><i class="material-icons md-36">help</i> &#x2014; material icon named "help".</p>
  static const IconData help = const IconData(0xe887);

  /// <p><i class="material-icons md-36">help_outline</i> &#x2014; material icon named "help outline".</p>
  static const IconData help_outline = const IconData(0xe8fd);

  /// <p><i class="material-icons md-36">high_quality</i> &#x2014; material icon named "high quality".</p>
  static const IconData high_quality = const IconData(0xe024);

  /// <p><i class="material-icons md-36">highlight</i> &#x2014; material icon named "highlight".</p>
  static const IconData highlight = const IconData(0xe25f);

  /// <p><i class="material-icons md-36">highlight_off</i> &#x2014; material icon named "highlight off".</p>
  static const IconData highlight_off = const IconData(0xe888);

  /// <p><i class="material-icons md-36">history</i> &#x2014; material icon named "history".</p>
  static const IconData history = const IconData(0xe889);

  /// <p><i class="material-icons md-36">home</i> &#x2014; material icon named "home".</p>
  static const IconData home = const IconData(0xe88a);

  /// <p><i class="material-icons md-36">hot_tub</i> &#x2014; material icon named "hot tub".</p>
  static const IconData hot_tub = const IconData(0xeb46);

  /// <p><i class="material-icons md-36">hotel</i> &#x2014; material icon named "hotel".</p>
  static const IconData hotel = const IconData(0xe53a);

  /// <p><i class="material-icons md-36">hourglass_empty</i> &#x2014; material icon named "hourglass empty".</p>
  static const IconData hourglass_empty = const IconData(0xe88b);

  /// <p><i class="material-icons md-36">hourglass_full</i> &#x2014; material icon named "hourglass full".</p>
  static const IconData hourglass_full = const IconData(0xe88c);

  /// <p><i class="material-icons md-36">http</i> &#x2014; material icon named "http".</p>
  static const IconData http = const IconData(0xe902);

  /// <p><i class="material-icons md-36">https</i> &#x2014; material icon named "https".</p>
  static const IconData https = const IconData(0xe88d);

  /// <p><i class="material-icons md-36">image</i> &#x2014; material icon named "image".</p>
  static const IconData image = const IconData(0xe3f4);

  /// <p><i class="material-icons md-36">image_aspect_ratio</i> &#x2014; material icon named "image aspect ratio".</p>
  static const IconData image_aspect_ratio = const IconData(0xe3f5);

  /// <p><i class="material-icons md-36">import_contacts</i> &#x2014; material icon named "import contacts".</p>
  static const IconData import_contacts = const IconData(0xe0e0);

  /// <p><i class="material-icons md-36">import_export</i> &#x2014; material icon named "import export".</p>
  static const IconData import_export = const IconData(0xe0c3);

  /// <p><i class="material-icons md-36">important_devices</i> &#x2014; material icon named "important devices".</p>
  static const IconData important_devices = const IconData(0xe912);

  /// <p><i class="material-icons md-36">inbox</i> &#x2014; material icon named "inbox".</p>
  static const IconData inbox = const IconData(0xe156);

  /// <p><i class="material-icons md-36">indeterminate_check_box</i> &#x2014; material icon named "indeterminate check box".</p>
  static const IconData indeterminate_check_box = const IconData(0xe909);

  /// <p><i class="material-icons md-36">info</i> &#x2014; material icon named "info".</p>
  static const IconData info = const IconData(0xe88e);

  /// <p><i class="material-icons md-36">info_outline</i> &#x2014; material icon named "info outline".</p>
  static const IconData info_outline = const IconData(0xe88f);

  /// <p><i class="material-icons md-36">input</i> &#x2014; material icon named "input".</p>
  static const IconData input = const IconData(0xe890);

  /// <p><i class="material-icons md-36">insert_chart</i> &#x2014; material icon named "insert chart".</p>
  static const IconData insert_chart = const IconData(0xe24b);

  /// <p><i class="material-icons md-36">insert_comment</i> &#x2014; material icon named "insert comment".</p>
  static const IconData insert_comment = const IconData(0xe24c);

  /// <p><i class="material-icons md-36">insert_drive_file</i> &#x2014; material icon named "insert drive file".</p>
  static const IconData insert_drive_file = const IconData(0xe24d);

  /// <p><i class="material-icons md-36">insert_emoticon</i> &#x2014; material icon named "insert emoticon".</p>
  static const IconData insert_emoticon = const IconData(0xe24e);

  /// <p><i class="material-icons md-36">insert_invitation</i> &#x2014; material icon named "insert invitation".</p>
  static const IconData insert_invitation = const IconData(0xe24f);

  /// <p><i class="material-icons md-36">insert_link</i> &#x2014; material icon named "insert link".</p>
  static const IconData insert_link = const IconData(0xe250);

  /// <p><i class="material-icons md-36">insert_photo</i> &#x2014; material icon named "insert photo".</p>
  static const IconData insert_photo = const IconData(0xe251);

  /// <p><i class="material-icons md-36">invert_colors</i> &#x2014; material icon named "invert colors".</p>
  static const IconData invert_colors = const IconData(0xe891);

  /// <p><i class="material-icons md-36">invert_colors_off</i> &#x2014; material icon named "invert colors off".</p>
  static const IconData invert_colors_off = const IconData(0xe0c4);

  /// <p><i class="material-icons md-36">iso</i> &#x2014; material icon named "iso".</p>
  static const IconData iso = const IconData(0xe3f6);

  /// <p><i class="material-icons md-36">keyboard</i> &#x2014; material icon named "keyboard".</p>
  static const IconData keyboard = const IconData(0xe312);

  /// <p><i class="material-icons md-36">keyboard_arrow_down</i> &#x2014; material icon named "keyboard arrow down".</p>
  static const IconData keyboard_arrow_down = const IconData(0xe313);

  /// <p><i class="material-icons md-36">keyboard_arrow_left</i> &#x2014; material icon named "keyboard arrow left".</p>
  static const IconData keyboard_arrow_left = const IconData(0xe314);

  /// <p><i class="material-icons md-36">keyboard_arrow_right</i> &#x2014; material icon named "keyboard arrow right".</p>
  static const IconData keyboard_arrow_right = const IconData(0xe315);

  /// <p><i class="material-icons md-36">keyboard_arrow_up</i> &#x2014; material icon named "keyboard arrow up".</p>
  static const IconData keyboard_arrow_up = const IconData(0xe316);

  /// <p><i class="material-icons md-36">keyboard_backspace</i> &#x2014; material icon named "keyboard backspace".</p>
  static const IconData keyboard_backspace = const IconData(0xe317);

  /// <p><i class="material-icons md-36">keyboard_capslock</i> &#x2014; material icon named "keyboard capslock".</p>
  static const IconData keyboard_capslock = const IconData(0xe318);

  /// <p><i class="material-icons md-36">keyboard_hide</i> &#x2014; material icon named "keyboard hide".</p>
  static const IconData keyboard_hide = const IconData(0xe31a);

  /// <p><i class="material-icons md-36">keyboard_return</i> &#x2014; material icon named "keyboard return".</p>
  static const IconData keyboard_return = const IconData(0xe31b);

  /// <p><i class="material-icons md-36">keyboard_tab</i> &#x2014; material icon named "keyboard tab".</p>
  static const IconData keyboard_tab = const IconData(0xe31c);

  /// <p><i class="material-icons md-36">keyboard_voice</i> &#x2014; material icon named "keyboard voice".</p>
  static const IconData keyboard_voice = const IconData(0xe31d);

  /// <p><i class="material-icons md-36">kitchen</i> &#x2014; material icon named "kitchen".</p>
  static const IconData kitchen = const IconData(0xeb47);

  /// <p><i class="material-icons md-36">label</i> &#x2014; material icon named "label".</p>
  static const IconData label = const IconData(0xe892);

  /// <p><i class="material-icons md-36">label_important</i> &#x2014; material icon named "label important".</p>
  static const IconData label_important = const IconData(0xe937);

  /// <p><i class="material-icons md-36">label_outline</i> &#x2014; material icon named "label outline".</p>
  static const IconData label_outline = const IconData(0xe893);

  /// <p><i class="material-icons md-36">landscape</i> &#x2014; material icon named "landscape".</p>
  static const IconData landscape = const IconData(0xe3f7);

  /// <p><i class="material-icons md-36">language</i> &#x2014; material icon named "language".</p>
  static const IconData language = const IconData(0xe894);

  /// <p><i class="material-icons md-36">laptop</i> &#x2014; material icon named "laptop".</p>
  static const IconData laptop = const IconData(0xe31e);

  /// <p><i class="material-icons md-36">laptop_chromebook</i> &#x2014; material icon named "laptop chromebook".</p>
  static const IconData laptop_chromebook = const IconData(0xe31f);

  /// <p><i class="material-icons md-36">laptop_mac</i> &#x2014; material icon named "laptop mac".</p>
  static const IconData laptop_mac = const IconData(0xe320);

  /// <p><i class="material-icons md-36">laptop_windows</i> &#x2014; material icon named "laptop windows".</p>
  static const IconData laptop_windows = const IconData(0xe321);

  /// <p><i class="material-icons md-36">last_page</i> &#x2014; material icon named "last page".</p>
  static const IconData last_page = const IconData(0xe5dd);

  /// <p><i class="material-icons md-36">launch</i> &#x2014; material icon named "launch".</p>
  static const IconData launch = const IconData(0xe895);

  /// <p><i class="material-icons md-36">layers</i> &#x2014; material icon named "layers".</p>
  static const IconData layers = const IconData(0xe53b);

  /// <p><i class="material-icons md-36">layers_clear</i> &#x2014; material icon named "layers clear".</p>
  static const IconData layers_clear = const IconData(0xe53c);

  /// <p><i class="material-icons md-36">leak_add</i> &#x2014; material icon named "leak add".</p>
  static const IconData leak_add = const IconData(0xe3f8);

  /// <p><i class="material-icons md-36">leak_remove</i> &#x2014; material icon named "leak remove".</p>
  static const IconData leak_remove = const IconData(0xe3f9);

  /// <p><i class="material-icons md-36">lens</i> &#x2014; material icon named "lens".</p>
  static const IconData lens = const IconData(0xe3fa);

  /// <p><i class="material-icons md-36">library_add</i> &#x2014; material icon named "library add".</p>
  static const IconData library_add = const IconData(0xe02e);

  /// <p><i class="material-icons md-36">library_books</i> &#x2014; material icon named "library books".</p>
  static const IconData library_books = const IconData(0xe02f);

  /// <p><i class="material-icons md-36">library_music</i> &#x2014; material icon named "library music".</p>
  static const IconData library_music = const IconData(0xe030);

  /// <p><i class="material-icons md-36">lightbulb_outline</i> &#x2014; material icon named "lightbulb outline".</p>
  static const IconData lightbulb_outline = const IconData(0xe90f);

  /// <p><i class="material-icons md-36">line_style</i> &#x2014; material icon named "line style".</p>
  static const IconData line_style = const IconData(0xe919);

  /// <p><i class="material-icons md-36">line_weight</i> &#x2014; material icon named "line weight".</p>
  static const IconData line_weight = const IconData(0xe91a);

  /// <p><i class="material-icons md-36">linear_scale</i> &#x2014; material icon named "linear scale".</p>
  static const IconData linear_scale = const IconData(0xe260);

  /// <p><i class="material-icons md-36">link</i> &#x2014; material icon named "link".</p>
  static const IconData link = const IconData(0xe157);

  /// <p><i class="material-icons md-36">link_off</i> &#x2014; material icon named "link off".</p>
  static const IconData link_off = const IconData(0xe16f);

  /// <p><i class="material-icons md-36">linked_camera</i> &#x2014; material icon named "linked camera".</p>
  static const IconData linked_camera = const IconData(0xe438);

  /// <p><i class="material-icons md-36">list</i> &#x2014; material icon named "list".</p>
  static const IconData list = const IconData(0xe896);

  /// <p><i class="material-icons md-36">live_help</i> &#x2014; material icon named "live help".</p>
  static const IconData live_help = const IconData(0xe0c6);

  /// <p><i class="material-icons md-36">live_tv</i> &#x2014; material icon named "live tv".</p>
  static const IconData live_tv = const IconData(0xe639);

  /// <p><i class="material-icons md-36">local_activity</i> &#x2014; material icon named "local activity".</p>
  static const IconData local_activity = const IconData(0xe53f);

  /// <p><i class="material-icons md-36">local_airport</i> &#x2014; material icon named "local airport".</p>
  static const IconData local_airport = const IconData(0xe53d);

  /// <p><i class="material-icons md-36">local_atm</i> &#x2014; material icon named "local atm".</p>
  static const IconData local_atm = const IconData(0xe53e);

  /// <p><i class="material-icons md-36">local_bar</i> &#x2014; material icon named "local bar".</p>
  static const IconData local_bar = const IconData(0xe540);

  /// <p><i class="material-icons md-36">local_cafe</i> &#x2014; material icon named "local cafe".</p>
  static const IconData local_cafe = const IconData(0xe541);

  /// <p><i class="material-icons md-36">local_car_wash</i> &#x2014; material icon named "local car wash".</p>
  static const IconData local_car_wash = const IconData(0xe542);

  /// <p><i class="material-icons md-36">local_convenience_store</i> &#x2014; material icon named "local convenience store".</p>
  static const IconData local_convenience_store = const IconData(0xe543);

  /// <p><i class="material-icons md-36">local_dining</i> &#x2014; material icon named "local dining".</p>
  static const IconData local_dining = const IconData(0xe556);

  /// <p><i class="material-icons md-36">local_drink</i> &#x2014; material icon named "local drink".</p>
  static const IconData local_drink = const IconData(0xe544);

  /// <p><i class="material-icons md-36">local_florist</i> &#x2014; material icon named "local florist".</p>
  static const IconData local_florist = const IconData(0xe545);

  /// <p><i class="material-icons md-36">local_gas_station</i> &#x2014; material icon named "local gas station".</p>
  static const IconData local_gas_station = const IconData(0xe546);

  /// <p><i class="material-icons md-36">local_grocery_store</i> &#x2014; material icon named "local grocery store".</p>
  static const IconData local_grocery_store = const IconData(0xe547);

  /// <p><i class="material-icons md-36">local_hospital</i> &#x2014; material icon named "local hospital".</p>
  static const IconData local_hospital = const IconData(0xe548);

  /// <p><i class="material-icons md-36">local_hotel</i> &#x2014; material icon named "local hotel".</p>
  static const IconData local_hotel = const IconData(0xe549);

  /// <p><i class="material-icons md-36">local_laundry_service</i> &#x2014; material icon named "local laundry service".</p>
  static const IconData local_laundry_service = const IconData(0xe54a);

  /// <p><i class="material-icons md-36">local_library</i> &#x2014; material icon named "local library".</p>
  static const IconData local_library = const IconData(0xe54b);

  /// <p><i class="material-icons md-36">local_mall</i> &#x2014; material icon named "local mall".</p>
  static const IconData local_mall = const IconData(0xe54c);

  /// <p><i class="material-icons md-36">local_movies</i> &#x2014; material icon named "local movies".</p>
  static const IconData local_movies = const IconData(0xe54d);

  /// <p><i class="material-icons md-36">local_offer</i> &#x2014; material icon named "local offer".</p>
  static const IconData local_offer = const IconData(0xe54e);

  /// <p><i class="material-icons md-36">local_parking</i> &#x2014; material icon named "local parking".</p>
  static const IconData local_parking = const IconData(0xe54f);

  /// <p><i class="material-icons md-36">local_pharmacy</i> &#x2014; material icon named "local pharmacy".</p>
  static const IconData local_pharmacy = const IconData(0xe550);

  /// <p><i class="material-icons md-36">local_phone</i> &#x2014; material icon named "local phone".</p>
  static const IconData local_phone = const IconData(0xe551);

  /// <p><i class="material-icons md-36">local_pizza</i> &#x2014; material icon named "local pizza".</p>
  static const IconData local_pizza = const IconData(0xe552);

  /// <p><i class="material-icons md-36">local_play</i> &#x2014; material icon named "local play".</p>
  static const IconData local_play = const IconData(0xe553);

  /// <p><i class="material-icons md-36">local_post_office</i> &#x2014; material icon named "local post office".</p>
  static const IconData local_post_office = const IconData(0xe554);

  /// <p><i class="material-icons md-36">local_printshop</i> &#x2014; material icon named "local printshop".</p>
  static const IconData local_printshop = const IconData(0xe555);

  /// <p><i class="material-icons md-36">local_see</i> &#x2014; material icon named "local see".</p>
  static const IconData local_see = const IconData(0xe557);

  /// <p><i class="material-icons md-36">local_shipping</i> &#x2014; material icon named "local shipping".</p>
  static const IconData local_shipping = const IconData(0xe558);

  /// <p><i class="material-icons md-36">local_taxi</i> &#x2014; material icon named "local taxi".</p>
  static const IconData local_taxi = const IconData(0xe559);

  /// <p><i class="material-icons md-36">location_city</i> &#x2014; material icon named "location city".</p>
  static const IconData location_city = const IconData(0xe7f1);

  /// <p><i class="material-icons md-36">location_disabled</i> &#x2014; material icon named "location disabled".</p>
  static const IconData location_disabled = const IconData(0xe1b6);

  /// <p><i class="material-icons md-36">location_off</i> &#x2014; material icon named "location off".</p>
  static const IconData location_off = const IconData(0xe0c7);

  /// <p><i class="material-icons md-36">location_on</i> &#x2014; material icon named "location on".</p>
  static const IconData location_on = const IconData(0xe0c8);

  /// <p><i class="material-icons md-36">location_searching</i> &#x2014; material icon named "location searching".</p>
  static const IconData location_searching = const IconData(0xe1b7);

  /// <p><i class="material-icons md-36">lock</i> &#x2014; material icon named "lock".</p>
  static const IconData lock = const IconData(0xe897);

  /// <p><i class="material-icons md-36">lock_open</i> &#x2014; material icon named "lock open".</p>
  static const IconData lock_open = const IconData(0xe898);

  /// <p><i class="material-icons md-36">lock_outline</i> &#x2014; material icon named "lock outline".</p>
  static const IconData lock_outline = const IconData(0xe899);

  /// <p><i class="material-icons md-36">looks</i> &#x2014; material icon named "looks".</p>
  static const IconData looks = const IconData(0xe3fc);

  /// <p><i class="material-icons md-36">looks_3</i> &#x2014; material icon named "looks 3".</p>
  static const IconData looks_3 = const IconData(0xe3fb);

  /// <p><i class="material-icons md-36">looks_4</i> &#x2014; material icon named "looks 4".</p>
  static const IconData looks_4 = const IconData(0xe3fd);

  /// <p><i class="material-icons md-36">looks_5</i> &#x2014; material icon named "looks 5".</p>
  static const IconData looks_5 = const IconData(0xe3fe);

  /// <p><i class="material-icons md-36">looks_6</i> &#x2014; material icon named "looks 6".</p>
  static const IconData looks_6 = const IconData(0xe3ff);

  /// <p><i class="material-icons md-36">looks_one</i> &#x2014; material icon named "looks one".</p>
  static const IconData looks_one = const IconData(0xe400);

  /// <p><i class="material-icons md-36">looks_two</i> &#x2014; material icon named "looks two".</p>
  static const IconData looks_two = const IconData(0xe401);

  /// <p><i class="material-icons md-36">loop</i> &#x2014; material icon named "loop".</p>
  static const IconData loop = const IconData(0xe028);

  /// <p><i class="material-icons md-36">loupe</i> &#x2014; material icon named "loupe".</p>
  static const IconData loupe = const IconData(0xe402);

  /// <p><i class="material-icons md-36">low_priority</i> &#x2014; material icon named "low priority".</p>
  static const IconData low_priority = const IconData(0xe16d);

  /// <p><i class="material-icons md-36">loyalty</i> &#x2014; material icon named "loyalty".</p>
  static const IconData loyalty = const IconData(0xe89a);

  /// <p><i class="material-icons md-36">mail</i> &#x2014; material icon named "mail".</p>
  static const IconData mail = const IconData(0xe158);

  /// <p><i class="material-icons md-36">mail_outline</i> &#x2014; material icon named "mail outline".</p>
  static const IconData mail_outline = const IconData(0xe0e1);

  /// <p><i class="material-icons md-36">map</i> &#x2014; material icon named "map".</p>
  static const IconData map = const IconData(0xe55b);

  /// <p><i class="material-icons md-36">markunread</i> &#x2014; material icon named "markunread".</p>
  static const IconData markunread = const IconData(0xe159);

  /// <p><i class="material-icons md-36">markunread_mailbox</i> &#x2014; material icon named "markunread mailbox".</p>
  static const IconData markunread_mailbox = const IconData(0xe89b);

  /// <p><i class="material-icons md-36">maximize</i> &#x2014; material icon named "maximize".</p>
  static const IconData maximize = const IconData(0xe930);

  /// <p><i class="material-icons md-36">memory</i> &#x2014; material icon named "memory".</p>
  static const IconData memory = const IconData(0xe322);

  /// <p><i class="material-icons md-36">menu</i> &#x2014; material icon named "menu".</p>
  static const IconData menu = const IconData(0xe5d2);

  /// <p><i class="material-icons md-36">merge_type</i> &#x2014; material icon named "merge type".</p>
  static const IconData merge_type = const IconData(0xe252);

  /// <p><i class="material-icons md-36">message</i> &#x2014; material icon named "message".</p>
  static const IconData message = const IconData(0xe0c9);

  /// <p><i class="material-icons md-36">mic</i> &#x2014; material icon named "mic".</p>
  static const IconData mic = const IconData(0xe029);

  /// <p><i class="material-icons md-36">mic_none</i> &#x2014; material icon named "mic none".</p>
  static const IconData mic_none = const IconData(0xe02a);

  /// <p><i class="material-icons md-36">mic_off</i> &#x2014; material icon named "mic off".</p>
  static const IconData mic_off = const IconData(0xe02b);

  /// <p><i class="material-icons md-36">minimize</i> &#x2014; material icon named "minimize".</p>
  static const IconData minimize = const IconData(0xe931);

  /// <p><i class="material-icons md-36">missed_video_call</i> &#x2014; material icon named "missed video call".</p>
  static const IconData missed_video_call = const IconData(0xe073);

  /// <p><i class="material-icons md-36">mms</i> &#x2014; material icon named "mms".</p>
  static const IconData mms = const IconData(0xe618);

  /// <p><i class="material-icons md-36">mobile_screen_share</i> &#x2014; material icon named "mobile screen share".</p>
  static const IconData mobile_screen_share = const IconData(0xe0e7);

  /// <p><i class="material-icons md-36">mode_comment</i> &#x2014; material icon named "mode comment".</p>
  static const IconData mode_comment = const IconData(0xe253);

  /// <p><i class="material-icons md-36">mode_edit</i> &#x2014; material icon named "mode edit".</p>
  static const IconData mode_edit = const IconData(0xe254);

  /// <p><i class="material-icons md-36">monetization_on</i> &#x2014; material icon named "monetization on".</p>
  static const IconData monetization_on = const IconData(0xe263);

  /// <p><i class="material-icons md-36">money_off</i> &#x2014; material icon named "money off".</p>
  static const IconData money_off = const IconData(0xe25c);

  /// <p><i class="material-icons md-36">monochrome_photos</i> &#x2014; material icon named "monochrome photos".</p>
  static const IconData monochrome_photos = const IconData(0xe403);

  /// <p><i class="material-icons md-36">mood</i> &#x2014; material icon named "mood".</p>
  static const IconData mood = const IconData(0xe7f2);

  /// <p><i class="material-icons md-36">mood_bad</i> &#x2014; material icon named "mood bad".</p>
  static const IconData mood_bad = const IconData(0xe7f3);

  /// <p><i class="material-icons md-36">more</i> &#x2014; material icon named "more".</p>
  static const IconData more = const IconData(0xe619);

  /// <p><i class="material-icons md-36">more_horiz</i> &#x2014; material icon named "more horiz".</p>
  static const IconData more_horiz = const IconData(0xe5d3);

  /// <p><i class="material-icons md-36">more_vert</i> &#x2014; material icon named "more vert".</p>
  static const IconData more_vert = const IconData(0xe5d4);

  /// <p><i class="material-icons md-36">motorcycle</i> &#x2014; material icon named "motorcycle".</p>
  static const IconData motorcycle = const IconData(0xe91b);

  /// <p><i class="material-icons md-36">mouse</i> &#x2014; material icon named "mouse".</p>
  static const IconData mouse = const IconData(0xe323);

  /// <p><i class="material-icons md-36">move_to_inbox</i> &#x2014; material icon named "move to inbox".</p>
  static const IconData move_to_inbox = const IconData(0xe168);

  /// <p><i class="material-icons md-36">movie</i> &#x2014; material icon named "movie".</p>
  static const IconData movie = const IconData(0xe02c);

  /// <p><i class="material-icons md-36">movie_creation</i> &#x2014; material icon named "movie creation".</p>
  static const IconData movie_creation = const IconData(0xe404);

  /// <p><i class="material-icons md-36">movie_filter</i> &#x2014; material icon named "movie filter".</p>
  static const IconData movie_filter = const IconData(0xe43a);

  /// <p><i class="material-icons md-36">multiline_chart</i> &#x2014; material icon named "multiline chart".</p>
  static const IconData multiline_chart = const IconData(0xe6df);

  /// <p><i class="material-icons md-36">music_note</i> &#x2014; material icon named "music note".</p>
  static const IconData music_note = const IconData(0xe405);

  /// <p><i class="material-icons md-36">music_video</i> &#x2014; material icon named "music video".</p>
  static const IconData music_video = const IconData(0xe063);

  /// <p><i class="material-icons md-36">my_location</i> &#x2014; material icon named "my location".</p>
  static const IconData my_location = const IconData(0xe55c);

  /// <p><i class="material-icons md-36">nature</i> &#x2014; material icon named "nature".</p>
  static const IconData nature = const IconData(0xe406);

  /// <p><i class="material-icons md-36">nature_people</i> &#x2014; material icon named "nature people".</p>
  static const IconData nature_people = const IconData(0xe407);

  /// <p><i class="material-icons md-36">navigate_before</i> &#x2014; material icon named "navigate before".</p>
  static const IconData navigate_before = const IconData(0xe408);

  /// <p><i class="material-icons md-36">navigate_next</i> &#x2014; material icon named "navigate next".</p>
  static const IconData navigate_next = const IconData(0xe409);

  /// <p><i class="material-icons md-36">navigation</i> &#x2014; material icon named "navigation".</p>
  static const IconData navigation = const IconData(0xe55d);

  /// <p><i class="material-icons md-36">near_me</i> &#x2014; material icon named "near me".</p>
  static const IconData near_me = const IconData(0xe569);

  /// <p><i class="material-icons md-36">network_cell</i> &#x2014; material icon named "network cell".</p>
  static const IconData network_cell = const IconData(0xe1b9);

  /// <p><i class="material-icons md-36">network_check</i> &#x2014; material icon named "network check".</p>
  static const IconData network_check = const IconData(0xe640);

  /// <p><i class="material-icons md-36">network_locked</i> &#x2014; material icon named "network locked".</p>
  static const IconData network_locked = const IconData(0xe61a);

  /// <p><i class="material-icons md-36">network_wifi</i> &#x2014; material icon named "network wifi".</p>
  static const IconData network_wifi = const IconData(0xe1ba);

  /// <p><i class="material-icons md-36">new_releases</i> &#x2014; material icon named "new releases".</p>
  static const IconData new_releases = const IconData(0xe031);

  /// <p><i class="material-icons md-36">next_week</i> &#x2014; material icon named "next week".</p>
  static const IconData next_week = const IconData(0xe16a);

  /// <p><i class="material-icons md-36">nfc</i> &#x2014; material icon named "nfc".</p>
  static const IconData nfc = const IconData(0xe1bb);

  /// <p><i class="material-icons md-36">no_encryption</i> &#x2014; material icon named "no encryption".</p>
  static const IconData no_encryption = const IconData(0xe641);

  /// <p><i class="material-icons md-36">no_sim</i> &#x2014; material icon named "no sim".</p>
  static const IconData no_sim = const IconData(0xe0cc);

  /// <p><i class="material-icons md-36">not_interested</i> &#x2014; material icon named "not interested".</p>
  static const IconData not_interested = const IconData(0xe033);

  /// <p><i class="material-icons md-36">not_listed_location</i> &#x2014; material icon named "not listed location".</p>
  static const IconData not_listed_location = const IconData(0xe575);

  /// <p><i class="material-icons md-36">note</i> &#x2014; material icon named "note".</p>
  static const IconData note = const IconData(0xe06f);

  /// <p><i class="material-icons md-36">note_add</i> &#x2014; material icon named "note add".</p>
  static const IconData note_add = const IconData(0xe89c);

  /// <p><i class="material-icons md-36">notification_important</i> &#x2014; material icon named "notification important".</p>
  static const IconData notification_important = const IconData(0xe004);

  /// <p><i class="material-icons md-36">notifications</i> &#x2014; material icon named "notifications".</p>
  static const IconData notifications = const IconData(0xe7f4);

  /// <p><i class="material-icons md-36">notifications_active</i> &#x2014; material icon named "notifications active".</p>
  static const IconData notifications_active = const IconData(0xe7f7);

  /// <p><i class="material-icons md-36">notifications_none</i> &#x2014; material icon named "notifications none".</p>
  static const IconData notifications_none = const IconData(0xe7f5);

  /// <p><i class="material-icons md-36">notifications_off</i> &#x2014; material icon named "notifications off".</p>
  static const IconData notifications_off = const IconData(0xe7f6);

  /// <p><i class="material-icons md-36">notifications_paused</i> &#x2014; material icon named "notifications paused".</p>
  static const IconData notifications_paused = const IconData(0xe7f8);

  /// <p><i class="material-icons md-36">offline_bolt</i> &#x2014; material icon named "offline bolt".</p>
  static const IconData offline_bolt = const IconData(0xe932);

  /// <p><i class="material-icons md-36">offline_pin</i> &#x2014; material icon named "offline pin".</p>
  static const IconData offline_pin = const IconData(0xe90a);

  /// <p><i class="material-icons md-36">ondemand_video</i> &#x2014; material icon named "ondemand video".</p>
  static const IconData ondemand_video = const IconData(0xe63a);

  /// <p><i class="material-icons md-36">opacity</i> &#x2014; material icon named "opacity".</p>
  static const IconData opacity = const IconData(0xe91c);

  /// <p><i class="material-icons md-36">open_in_browser</i> &#x2014; material icon named "open in browser".</p>
  static const IconData open_in_browser = const IconData(0xe89d);

  /// <p><i class="material-icons md-36">open_in_new</i> &#x2014; material icon named "open in new".</p>
  static const IconData open_in_new = const IconData(0xe89e);

  /// <p><i class="material-icons md-36">open_with</i> &#x2014; material icon named "open with".</p>
  static const IconData open_with = const IconData(0xe89f);

  /// <p><i class="material-icons md-36">outlined_flag</i> &#x2014; material icon named "outlined flag".</p>
  static const IconData outlined_flag = const IconData(0xe16e);

  /// <p><i class="material-icons md-36">pages</i> &#x2014; material icon named "pages".</p>
  static const IconData pages = const IconData(0xe7f9);

  /// <p><i class="material-icons md-36">pageview</i> &#x2014; material icon named "pageview".</p>
  static const IconData pageview = const IconData(0xe8a0);

  /// <p><i class="material-icons md-36">palette</i> &#x2014; material icon named "palette".</p>
  static const IconData palette = const IconData(0xe40a);

  /// <p><i class="material-icons md-36">pan_tool</i> &#x2014; material icon named "pan tool".</p>
  static const IconData pan_tool = const IconData(0xe925);

  /// <p><i class="material-icons md-36">panorama</i> &#x2014; material icon named "panorama".</p>
  static const IconData panorama = const IconData(0xe40b);

  /// <p><i class="material-icons md-36">panorama_fish_eye</i> &#x2014; material icon named "panorama fish eye".</p>
  static const IconData panorama_fish_eye = const IconData(0xe40c);

  /// <p><i class="material-icons md-36">panorama_horizontal</i> &#x2014; material icon named "panorama horizontal".</p>
  static const IconData panorama_horizontal = const IconData(0xe40d);

  /// <p><i class="material-icons md-36">panorama_vertical</i> &#x2014; material icon named "panorama vertical".</p>
  static const IconData panorama_vertical = const IconData(0xe40e);

  /// <p><i class="material-icons md-36">panorama_wide_angle</i> &#x2014; material icon named "panorama wide angle".</p>
  static const IconData panorama_wide_angle = const IconData(0xe40f);

  /// <p><i class="material-icons md-36">party_mode</i> &#x2014; material icon named "party mode".</p>
  static const IconData party_mode = const IconData(0xe7fa);

  /// <p><i class="material-icons md-36">pause</i> &#x2014; material icon named "pause".</p>
  static const IconData pause = const IconData(0xe034);

  /// <p><i class="material-icons md-36">pause_circle_filled</i> &#x2014; material icon named "pause circle filled".</p>
  static const IconData pause_circle_filled = const IconData(0xe035);

  /// <p><i class="material-icons md-36">pause_circle_outline</i> &#x2014; material icon named "pause circle outline".</p>
  static const IconData pause_circle_outline = const IconData(0xe036);

  /// <p><i class="material-icons md-36">payment</i> &#x2014; material icon named "payment".</p>
  static const IconData payment = const IconData(0xe8a1);

  /// <p><i class="material-icons md-36">people</i> &#x2014; material icon named "people".</p>
  static const IconData people = const IconData(0xe7fb);

  /// <p><i class="material-icons md-36">people_outline</i> &#x2014; material icon named "people outline".</p>
  static const IconData people_outline = const IconData(0xe7fc);

  /// <p><i class="material-icons md-36">perm_camera_mic</i> &#x2014; material icon named "perm camera mic".</p>
  static const IconData perm_camera_mic = const IconData(0xe8a2);

  /// <p><i class="material-icons md-36">perm_contact_calendar</i> &#x2014; material icon named "perm contact calendar".</p>
  static const IconData perm_contact_calendar = const IconData(0xe8a3);

  /// <p><i class="material-icons md-36">perm_data_setting</i> &#x2014; material icon named "perm data setting".</p>
  static const IconData perm_data_setting = const IconData(0xe8a4);

  /// <p><i class="material-icons md-36">perm_device_information</i> &#x2014; material icon named "perm device information".</p>
  static const IconData perm_device_information = const IconData(0xe8a5);

  /// <p><i class="material-icons md-36">perm_identity</i> &#x2014; material icon named "perm identity".</p>
  static const IconData perm_identity = const IconData(0xe8a6);

  /// <p><i class="material-icons md-36">perm_media</i> &#x2014; material icon named "perm media".</p>
  static const IconData perm_media = const IconData(0xe8a7);

  /// <p><i class="material-icons md-36">perm_phone_msg</i> &#x2014; material icon named "perm phone msg".</p>
  static const IconData perm_phone_msg = const IconData(0xe8a8);

  /// <p><i class="material-icons md-36">perm_scan_wifi</i> &#x2014; material icon named "perm scan wifi".</p>
  static const IconData perm_scan_wifi = const IconData(0xe8a9);

  /// <p><i class="material-icons md-36">person</i> &#x2014; material icon named "person".</p>
  static const IconData person = const IconData(0xe7fd);

  /// <p><i class="material-icons md-36">person_add</i> &#x2014; material icon named "person add".</p>
  static const IconData person_add = const IconData(0xe7fe);

  /// <p><i class="material-icons md-36">person_outline</i> &#x2014; material icon named "person outline".</p>
  static const IconData person_outline = const IconData(0xe7ff);

  /// <p><i class="material-icons md-36">person_pin</i> &#x2014; material icon named "person pin".</p>
  static const IconData person_pin = const IconData(0xe55a);

  /// <p><i class="material-icons md-36">person_pin_circle</i> &#x2014; material icon named "person pin circle".</p>
  static const IconData person_pin_circle = const IconData(0xe56a);

  /// <p><i class="material-icons md-36">personal_video</i> &#x2014; material icon named "personal video".</p>
  static const IconData personal_video = const IconData(0xe63b);

  /// <p><i class="material-icons md-36">pets</i> &#x2014; material icon named "pets".</p>
  static const IconData pets = const IconData(0xe91d);

  /// <p><i class="material-icons md-36">phone</i> &#x2014; material icon named "phone".</p>
  static const IconData phone = const IconData(0xe0cd);

  /// <p><i class="material-icons md-36">phone_android</i> &#x2014; material icon named "phone android".</p>
  static const IconData phone_android = const IconData(0xe324);

  /// <p><i class="material-icons md-36">phone_bluetooth_speaker</i> &#x2014; material icon named "phone bluetooth speaker".</p>
  static const IconData phone_bluetooth_speaker = const IconData(0xe61b);

  /// <p><i class="material-icons md-36">phone_forwarded</i> &#x2014; material icon named "phone forwarded".</p>
  static const IconData phone_forwarded = const IconData(0xe61c);

  /// <p><i class="material-icons md-36">phone_in_talk</i> &#x2014; material icon named "phone in talk".</p>
  static const IconData phone_in_talk = const IconData(0xe61d);

  /// <p><i class="material-icons md-36">phone_iphone</i> &#x2014; material icon named "phone iphone".</p>
  static const IconData phone_iphone = const IconData(0xe325);

  /// <p><i class="material-icons md-36">phone_locked</i> &#x2014; material icon named "phone locked".</p>
  static const IconData phone_locked = const IconData(0xe61e);

  /// <p><i class="material-icons md-36">phone_missed</i> &#x2014; material icon named "phone missed".</p>
  static const IconData phone_missed = const IconData(0xe61f);

  /// <p><i class="material-icons md-36">phone_paused</i> &#x2014; material icon named "phone paused".</p>
  static const IconData phone_paused = const IconData(0xe620);

  /// <p><i class="material-icons md-36">phonelink</i> &#x2014; material icon named "phonelink".</p>
  static const IconData phonelink = const IconData(0xe326);

  /// <p><i class="material-icons md-36">phonelink_erase</i> &#x2014; material icon named "phonelink erase".</p>
  static const IconData phonelink_erase = const IconData(0xe0db);

  /// <p><i class="material-icons md-36">phonelink_lock</i> &#x2014; material icon named "phonelink lock".</p>
  static const IconData phonelink_lock = const IconData(0xe0dc);

  /// <p><i class="material-icons md-36">phonelink_off</i> &#x2014; material icon named "phonelink off".</p>
  static const IconData phonelink_off = const IconData(0xe327);

  /// <p><i class="material-icons md-36">phonelink_ring</i> &#x2014; material icon named "phonelink ring".</p>
  static const IconData phonelink_ring = const IconData(0xe0dd);

  /// <p><i class="material-icons md-36">phonelink_setup</i> &#x2014; material icon named "phonelink setup".</p>
  static const IconData phonelink_setup = const IconData(0xe0de);

  /// <p><i class="material-icons md-36">photo</i> &#x2014; material icon named "photo".</p>
  static const IconData photo = const IconData(0xe410);

  /// <p><i class="material-icons md-36">photo_album</i> &#x2014; material icon named "photo album".</p>
  static const IconData photo_album = const IconData(0xe411);

  /// <p><i class="material-icons md-36">photo_camera</i> &#x2014; material icon named "photo camera".</p>
  static const IconData photo_camera = const IconData(0xe412);

  /// <p><i class="material-icons md-36">photo_filter</i> &#x2014; material icon named "photo filter".</p>
  static const IconData photo_filter = const IconData(0xe43b);

  /// <p><i class="material-icons md-36">photo_library</i> &#x2014; material icon named "photo library".</p>
  static const IconData photo_library = const IconData(0xe413);

  /// <p><i class="material-icons md-36">photo_size_select_actual</i> &#x2014; material icon named "photo size select actual".</p>
  static const IconData photo_size_select_actual = const IconData(0xe432);

  /// <p><i class="material-icons md-36">photo_size_select_large</i> &#x2014; material icon named "photo size select large".</p>
  static const IconData photo_size_select_large = const IconData(0xe433);

  /// <p><i class="material-icons md-36">photo_size_select_small</i> &#x2014; material icon named "photo size select small".</p>
  static const IconData photo_size_select_small = const IconData(0xe434);

  /// <p><i class="material-icons md-36">picture_as_pdf</i> &#x2014; material icon named "picture as pdf".</p>
  static const IconData picture_as_pdf = const IconData(0xe415);

  /// <p><i class="material-icons md-36">picture_in_picture</i> &#x2014; material icon named "picture in picture".</p>
  static const IconData picture_in_picture = const IconData(0xe8aa);

  /// <p><i class="material-icons md-36">picture_in_picture_alt</i> &#x2014; material icon named "picture in picture alt".</p>
  static const IconData picture_in_picture_alt = const IconData(0xe911);

  /// <p><i class="material-icons md-36">pie_chart</i> &#x2014; material icon named "pie chart".</p>
  static const IconData pie_chart = const IconData(0xe6c4);

  /// <p><i class="material-icons md-36">pie_chart_outlined</i> &#x2014; material icon named "pie chart outlined".</p>
  static const IconData pie_chart_outlined = const IconData(0xe6c5);

  /// <p><i class="material-icons md-36">pin_drop</i> &#x2014; material icon named "pin drop".</p>
  static const IconData pin_drop = const IconData(0xe55e);

  /// <p><i class="material-icons md-36">place</i> &#x2014; material icon named "place".</p>
  static const IconData place = const IconData(0xe55f);

  /// <p><i class="material-icons md-36">play_arrow</i> &#x2014; material icon named "play arrow".</p>
  static const IconData play_arrow = const IconData(0xe037);

  /// <p><i class="material-icons md-36">play_circle_filled</i> &#x2014; material icon named "play circle filled".</p>
  static const IconData play_circle_filled = const IconData(0xe038);

  /// <p><i class="material-icons md-36">play_circle_outline</i> &#x2014; material icon named "play circle outline".</p>
  static const IconData play_circle_outline = const IconData(0xe039);

  /// <p><i class="material-icons md-36">play_for_work</i> &#x2014; material icon named "play for work".</p>
  static const IconData play_for_work = const IconData(0xe906);

  /// <p><i class="material-icons md-36">playlist_add</i> &#x2014; material icon named "playlist add".</p>
  static const IconData playlist_add = const IconData(0xe03b);

  /// <p><i class="material-icons md-36">playlist_add_check</i> &#x2014; material icon named "playlist add check".</p>
  static const IconData playlist_add_check = const IconData(0xe065);

  /// <p><i class="material-icons md-36">playlist_play</i> &#x2014; material icon named "playlist play".</p>
  static const IconData playlist_play = const IconData(0xe05f);

  /// <p><i class="material-icons md-36">plus_one</i> &#x2014; material icon named "plus one".</p>
  static const IconData plus_one = const IconData(0xe800);

  /// <p><i class="material-icons md-36">poll</i> &#x2014; material icon named "poll".</p>
  static const IconData poll = const IconData(0xe801);

  /// <p><i class="material-icons md-36">polymer</i> &#x2014; material icon named "polymer".</p>
  static const IconData polymer = const IconData(0xe8ab);

  /// <p><i class="material-icons md-36">pool</i> &#x2014; material icon named "pool".</p>
  static const IconData pool = const IconData(0xeb48);

  /// <p><i class="material-icons md-36">portable_wifi_off</i> &#x2014; material icon named "portable wifi off".</p>
  static const IconData portable_wifi_off = const IconData(0xe0ce);

  /// <p><i class="material-icons md-36">portrait</i> &#x2014; material icon named "portrait".</p>
  static const IconData portrait = const IconData(0xe416);

  /// <p><i class="material-icons md-36">power</i> &#x2014; material icon named "power".</p>
  static const IconData power = const IconData(0xe63c);

  /// <p><i class="material-icons md-36">power_input</i> &#x2014; material icon named "power input".</p>
  static const IconData power_input = const IconData(0xe336);

  /// <p><i class="material-icons md-36">power_settings_new</i> &#x2014; material icon named "power settings new".</p>
  static const IconData power_settings_new = const IconData(0xe8ac);

  /// <p><i class="material-icons md-36">pregnant_woman</i> &#x2014; material icon named "pregnant woman".</p>
  static const IconData pregnant_woman = const IconData(0xe91e);

  /// <p><i class="material-icons md-36">present_to_all</i> &#x2014; material icon named "present to all".</p>
  static const IconData present_to_all = const IconData(0xe0df);

  /// <p><i class="material-icons md-36">print</i> &#x2014; material icon named "print".</p>
  static const IconData print = const IconData(0xe8ad);

  /// <p><i class="material-icons md-36">priority_high</i> &#x2014; material icon named "priority high".</p>
  static const IconData priority_high = const IconData(0xe645);

  /// <p><i class="material-icons md-36">public</i> &#x2014; material icon named "public".</p>
  static const IconData public = const IconData(0xe80b);

  /// <p><i class="material-icons md-36">publish</i> &#x2014; material icon named "publish".</p>
  static const IconData publish = const IconData(0xe255);

  /// <p><i class="material-icons md-36">query_builder</i> &#x2014; material icon named "query builder".</p>
  static const IconData query_builder = const IconData(0xe8ae);

  /// <p><i class="material-icons md-36">question_answer</i> &#x2014; material icon named "question answer".</p>
  static const IconData question_answer = const IconData(0xe8af);

  /// <p><i class="material-icons md-36">queue</i> &#x2014; material icon named "queue".</p>
  static const IconData queue = const IconData(0xe03c);

  /// <p><i class="material-icons md-36">queue_music</i> &#x2014; material icon named "queue music".</p>
  static const IconData queue_music = const IconData(0xe03d);

  /// <p><i class="material-icons md-36">queue_play_next</i> &#x2014; material icon named "queue play next".</p>
  static const IconData queue_play_next = const IconData(0xe066);

  /// <p><i class="material-icons md-36">radio</i> &#x2014; material icon named "radio".</p>
  static const IconData radio = const IconData(0xe03e);

  /// <p><i class="material-icons md-36">radio_button_checked</i> &#x2014; material icon named "radio button checked".</p>
  static const IconData radio_button_checked = const IconData(0xe837);

  /// <p><i class="material-icons md-36">radio_button_unchecked</i> &#x2014; material icon named "radio button unchecked".</p>
  static const IconData radio_button_unchecked = const IconData(0xe836);

  /// <p><i class="material-icons md-36">rate_review</i> &#x2014; material icon named "rate review".</p>
  static const IconData rate_review = const IconData(0xe560);

  /// <p><i class="material-icons md-36">receipt</i> &#x2014; material icon named "receipt".</p>
  static const IconData receipt = const IconData(0xe8b0);

  /// <p><i class="material-icons md-36">recent_actors</i> &#x2014; material icon named "recent actors".</p>
  static const IconData recent_actors = const IconData(0xe03f);

  /// <p><i class="material-icons md-36">record_voice_over</i> &#x2014; material icon named "record voice over".</p>
  static const IconData record_voice_over = const IconData(0xe91f);

  /// <p><i class="material-icons md-36">redeem</i> &#x2014; material icon named "redeem".</p>
  static const IconData redeem = const IconData(0xe8b1);

  /// <p><i class="material-icons md-36">redo</i> &#x2014; material icon named "redo".</p>
  static const IconData redo = const IconData(0xe15a);

  /// <p><i class="material-icons md-36">refresh</i> &#x2014; material icon named "refresh".</p>
  static const IconData refresh = const IconData(0xe5d5);

  /// <p><i class="material-icons md-36">remove</i> &#x2014; material icon named "remove".</p>
  static const IconData remove = const IconData(0xe15b);

  /// <p><i class="material-icons md-36">remove_circle</i> &#x2014; material icon named "remove circle".</p>
  static const IconData remove_circle = const IconData(0xe15c);

  /// <p><i class="material-icons md-36">remove_circle_outline</i> &#x2014; material icon named "remove circle outline".</p>
  static const IconData remove_circle_outline = const IconData(0xe15d);

  /// <p><i class="material-icons md-36">remove_from_queue</i> &#x2014; material icon named "remove from queue".</p>
  static const IconData remove_from_queue = const IconData(0xe067);

  /// <p><i class="material-icons md-36">remove_red_eye</i> &#x2014; material icon named "remove red eye".</p>
  static const IconData remove_red_eye = const IconData(0xe417);

  /// <p><i class="material-icons md-36">remove_shopping_cart</i> &#x2014; material icon named "remove shopping cart".</p>
  static const IconData remove_shopping_cart = const IconData(0xe928);

  /// <p><i class="material-icons md-36">reorder</i> &#x2014; material icon named "reorder".</p>
  static const IconData reorder = const IconData(0xe8fe);

  /// <p><i class="material-icons md-36">repeat</i> &#x2014; material icon named "repeat".</p>
  static const IconData repeat = const IconData(0xe040);

  /// <p><i class="material-icons md-36">repeat_one</i> &#x2014; material icon named "repeat one".</p>
  static const IconData repeat_one = const IconData(0xe041);

  /// <p><i class="material-icons md-36">replay</i> &#x2014; material icon named "replay".</p>
  static const IconData replay = const IconData(0xe042);

  /// <p><i class="material-icons md-36">replay_10</i> &#x2014; material icon named "replay 10".</p>
  static const IconData replay_10 = const IconData(0xe059);

  /// <p><i class="material-icons md-36">replay_30</i> &#x2014; material icon named "replay 30".</p>
  static const IconData replay_30 = const IconData(0xe05a);

  /// <p><i class="material-icons md-36">replay_5</i> &#x2014; material icon named "replay 5".</p>
  static const IconData replay_5 = const IconData(0xe05b);

  /// <p><i class="material-icons md-36">reply</i> &#x2014; material icon named "reply".</p>
  static const IconData reply = const IconData(0xe15e);

  /// <p><i class="material-icons md-36">reply_all</i> &#x2014; material icon named "reply all".</p>
  static const IconData reply_all = const IconData(0xe15f);

  /// <p><i class="material-icons md-36">report</i> &#x2014; material icon named "report".</p>
  static const IconData report = const IconData(0xe160);

  /// <p><i class="material-icons md-36">report_off</i> &#x2014; material icon named "report off".</p>
  static const IconData report_off = const IconData(0xe170);

  /// <p><i class="material-icons md-36">report_problem</i> &#x2014; material icon named "report problem".</p>
  static const IconData report_problem = const IconData(0xe8b2);

  /// <p><i class="material-icons md-36">restaurant</i> &#x2014; material icon named "restaurant".</p>
  static const IconData restaurant = const IconData(0xe56c);

  /// <p><i class="material-icons md-36">restaurant_menu</i> &#x2014; material icon named "restaurant menu".</p>
  static const IconData restaurant_menu = const IconData(0xe561);

  /// <p><i class="material-icons md-36">restore</i> &#x2014; material icon named "restore".</p>
  static const IconData restore = const IconData(0xe8b3);

  /// <p><i class="material-icons md-36">restore_from_trash</i> &#x2014; material icon named "restore from trash".</p>
  static const IconData restore_from_trash = const IconData(0xe938);

  /// <p><i class="material-icons md-36">restore_page</i> &#x2014; material icon named "restore page".</p>
  static const IconData restore_page = const IconData(0xe929);

  /// <p><i class="material-icons md-36">ring_volume</i> &#x2014; material icon named "ring volume".</p>
  static const IconData ring_volume = const IconData(0xe0d1);

  /// <p><i class="material-icons md-36">room</i> &#x2014; material icon named "room".</p>
  static const IconData room = const IconData(0xe8b4);

  /// <p><i class="material-icons md-36">room_service</i> &#x2014; material icon named "room service".</p>
  static const IconData room_service = const IconData(0xeb49);

  /// <p><i class="material-icons md-36">rotate_90_degrees_ccw</i> &#x2014; material icon named "rotate 90 degrees ccw".</p>
  static const IconData rotate_90_degrees_ccw = const IconData(0xe418);

  /// <p><i class="material-icons md-36">rotate_left</i> &#x2014; material icon named "rotate left".</p>
  static const IconData rotate_left = const IconData(0xe419);

  /// <p><i class="material-icons md-36">rotate_right</i> &#x2014; material icon named "rotate right".</p>
  static const IconData rotate_right = const IconData(0xe41a);

  /// <p><i class="material-icons md-36">rounded_corner</i> &#x2014; material icon named "rounded corner".</p>
  static const IconData rounded_corner = const IconData(0xe920);

  /// <p><i class="material-icons md-36">router</i> &#x2014; material icon named "router".</p>
  static const IconData router = const IconData(0xe328);

  /// <p><i class="material-icons md-36">rowing</i> &#x2014; material icon named "rowing".</p>
  static const IconData rowing = const IconData(0xe921);

  /// <p><i class="material-icons md-36">rss_feed</i> &#x2014; material icon named "rss feed".</p>
  static const IconData rss_feed = const IconData(0xe0e5);

  /// <p><i class="material-icons md-36">rv_hookup</i> &#x2014; material icon named "rv hookup".</p>
  static const IconData rv_hookup = const IconData(0xe642);

  /// <p><i class="material-icons md-36">satellite</i> &#x2014; material icon named "satellite".</p>
  static const IconData satellite = const IconData(0xe562);

  /// <p><i class="material-icons md-36">save</i> &#x2014; material icon named "save".</p>
  static const IconData save = const IconData(0xe161);

  /// <p><i class="material-icons md-36">save_alt</i> &#x2014; material icon named "save alt".</p>
  static const IconData save_alt = const IconData(0xe171);

  /// <p><i class="material-icons md-36">scanner</i> &#x2014; material icon named "scanner".</p>
  static const IconData scanner = const IconData(0xe329);

  /// <p><i class="material-icons md-36">scatter_plot</i> &#x2014; material icon named "scatter plot".</p>
  static const IconData scatter_plot = const IconData(0xe268);

  /// <p><i class="material-icons md-36">schedule</i> &#x2014; material icon named "schedule".</p>
  static const IconData schedule = const IconData(0xe8b5);

  /// <p><i class="material-icons md-36">school</i> &#x2014; material icon named "school".</p>
  static const IconData school = const IconData(0xe80c);

  /// <p><i class="material-icons md-36">score</i> &#x2014; material icon named "score".</p>
  static const IconData score = const IconData(0xe269);

  /// <p><i class="material-icons md-36">screen_lock_landscape</i> &#x2014; material icon named "screen lock landscape".</p>
  static const IconData screen_lock_landscape = const IconData(0xe1be);

  /// <p><i class="material-icons md-36">screen_lock_portrait</i> &#x2014; material icon named "screen lock portrait".</p>
  static const IconData screen_lock_portrait = const IconData(0xe1bf);

  /// <p><i class="material-icons md-36">screen_lock_rotation</i> &#x2014; material icon named "screen lock rotation".</p>
  static const IconData screen_lock_rotation = const IconData(0xe1c0);

  /// <p><i class="material-icons md-36">screen_rotation</i> &#x2014; material icon named "screen rotation".</p>
  static const IconData screen_rotation = const IconData(0xe1c1);

  /// <p><i class="material-icons md-36">screen_share</i> &#x2014; material icon named "screen share".</p>
  static const IconData screen_share = const IconData(0xe0e2);

  /// <p><i class="material-icons md-36">sd_card</i> &#x2014; material icon named "sd card".</p>
  static const IconData sd_card = const IconData(0xe623);

  /// <p><i class="material-icons md-36">sd_storage</i> &#x2014; material icon named "sd storage".</p>
  static const IconData sd_storage = const IconData(0xe1c2);

  /// <p><i class="material-icons md-36">search</i> &#x2014; material icon named "search".</p>
  static const IconData search = const IconData(0xe8b6);

  /// <p><i class="material-icons md-36">security</i> &#x2014; material icon named "security".</p>
  static const IconData security = const IconData(0xe32a);

  /// <p><i class="material-icons md-36">select_all</i> &#x2014; material icon named "select all".</p>
  static const IconData select_all = const IconData(0xe162);

  /// <p><i class="material-icons md-36">send</i> &#x2014; material icon named "send".</p>
  static const IconData send = const IconData(0xe163);

  /// <p><i class="material-icons md-36">sentiment_dissatisfied</i> &#x2014; material icon named "sentiment dissatisfied".</p>
  static const IconData sentiment_dissatisfied = const IconData(0xe811);

  /// <p><i class="material-icons md-36">sentiment_neutral</i> &#x2014; material icon named "sentiment neutral".</p>
  static const IconData sentiment_neutral = const IconData(0xe812);

  /// <p><i class="material-icons md-36">sentiment_satisfied</i> &#x2014; material icon named "sentiment satisfied".</p>
  static const IconData sentiment_satisfied = const IconData(0xe813);

  /// <p><i class="material-icons md-36">sentiment_very_dissatisfied</i> &#x2014; material icon named "sentiment very dissatisfied".</p>
  static const IconData sentiment_very_dissatisfied = const IconData(0xe814);

  /// <p><i class="material-icons md-36">sentiment_very_satisfied</i> &#x2014; material icon named "sentiment very satisfied".</p>
  static const IconData sentiment_very_satisfied = const IconData(0xe815);

  /// <p><i class="material-icons md-36">settings</i> &#x2014; material icon named "settings".</p>
  static const IconData settings = const IconData(0xe8b8);

  /// <p><i class="material-icons md-36">settings_applications</i> &#x2014; material icon named "settings applications".</p>
  static const IconData settings_applications = const IconData(0xe8b9);

  /// <p><i class="material-icons md-36">settings_backup_restore</i> &#x2014; material icon named "settings backup restore".</p>
  static const IconData settings_backup_restore = const IconData(0xe8ba);

  /// <p><i class="material-icons md-36">settings_bluetooth</i> &#x2014; material icon named "settings bluetooth".</p>
  static const IconData settings_bluetooth = const IconData(0xe8bb);

  /// <p><i class="material-icons md-36">settings_brightness</i> &#x2014; material icon named "settings brightness".</p>
  static const IconData settings_brightness = const IconData(0xe8bd);

  /// <p><i class="material-icons md-36">settings_cell</i> &#x2014; material icon named "settings cell".</p>
  static const IconData settings_cell = const IconData(0xe8bc);

  /// <p><i class="material-icons md-36">settings_ethernet</i> &#x2014; material icon named "settings ethernet".</p>
  static const IconData settings_ethernet = const IconData(0xe8be);

  /// <p><i class="material-icons md-36">settings_input_antenna</i> &#x2014; material icon named "settings input antenna".</p>
  static const IconData settings_input_antenna = const IconData(0xe8bf);

  /// <p><i class="material-icons md-36">settings_input_component</i> &#x2014; material icon named "settings input component".</p>
  static const IconData settings_input_component = const IconData(0xe8c0);

  /// <p><i class="material-icons md-36">settings_input_composite</i> &#x2014; material icon named "settings input composite".</p>
  static const IconData settings_input_composite = const IconData(0xe8c1);

  /// <p><i class="material-icons md-36">settings_input_hdmi</i> &#x2014; material icon named "settings input hdmi".</p>
  static const IconData settings_input_hdmi = const IconData(0xe8c2);

  /// <p><i class="material-icons md-36">settings_input_svideo</i> &#x2014; material icon named "settings input svideo".</p>
  static const IconData settings_input_svideo = const IconData(0xe8c3);

  /// <p><i class="material-icons md-36">settings_overscan</i> &#x2014; material icon named "settings overscan".</p>
  static const IconData settings_overscan = const IconData(0xe8c4);

  /// <p><i class="material-icons md-36">settings_phone</i> &#x2014; material icon named "settings phone".</p>
  static const IconData settings_phone = const IconData(0xe8c5);

  /// <p><i class="material-icons md-36">settings_power</i> &#x2014; material icon named "settings power".</p>
  static const IconData settings_power = const IconData(0xe8c6);

  /// <p><i class="material-icons md-36">settings_remote</i> &#x2014; material icon named "settings remote".</p>
  static const IconData settings_remote = const IconData(0xe8c7);

  /// <p><i class="material-icons md-36">settings_system_daydream</i> &#x2014; material icon named "settings system daydream".</p>
  static const IconData settings_system_daydream = const IconData(0xe1c3);

  /// <p><i class="material-icons md-36">settings_voice</i> &#x2014; material icon named "settings voice".</p>
  static const IconData settings_voice = const IconData(0xe8c8);

  /// <p><i class="material-icons md-36">share</i> &#x2014; material icon named "share".</p>
  static const IconData share = const IconData(0xe80d);

  /// <p><i class="material-icons md-36">shop</i> &#x2014; material icon named "shop".</p>
  static const IconData shop = const IconData(0xe8c9);

  /// <p><i class="material-icons md-36">shop_two</i> &#x2014; material icon named "shop two".</p>
  static const IconData shop_two = const IconData(0xe8ca);

  /// <p><i class="material-icons md-36">shopping_basket</i> &#x2014; material icon named "shopping basket".</p>
  static const IconData shopping_basket = const IconData(0xe8cb);

  /// <p><i class="material-icons md-36">shopping_cart</i> &#x2014; material icon named "shopping cart".</p>
  static const IconData shopping_cart = const IconData(0xe8cc);

  /// <p><i class="material-icons md-36">short_text</i> &#x2014; material icon named "short text".</p>
  static const IconData short_text = const IconData(0xe261);

  /// <p><i class="material-icons md-36">show_chart</i> &#x2014; material icon named "show chart".</p>
  static const IconData show_chart = const IconData(0xe6e1);

  /// <p><i class="material-icons md-36">shuffle</i> &#x2014; material icon named "shuffle".</p>
  static const IconData shuffle = const IconData(0xe043);

  /// <p><i class="material-icons md-36">shutter_speed</i> &#x2014; material icon named "shutter speed".</p>
  static const IconData shutter_speed = const IconData(0xe43d);

  /// <p><i class="material-icons md-36">signal_cellular_4_bar</i> &#x2014; material icon named "signal cellular 4 bar".</p>
  static const IconData signal_cellular_4_bar = const IconData(0xe1c8);

  /// <p><i class="material-icons md-36">signal_cellular_connected_no_internet_4_bar</i> &#x2014; material icon named "signal cellular connected no internet 4 bar".</p>
  static const IconData signal_cellular_connected_no_internet_4_bar = const IconData(0xe1cd);

  /// <p><i class="material-icons md-36">signal_cellular_no_sim</i> &#x2014; material icon named "signal cellular no sim".</p>
  static const IconData signal_cellular_no_sim = const IconData(0xe1ce);

  /// <p><i class="material-icons md-36">signal_cellular_null</i> &#x2014; material icon named "signal cellular null".</p>
  static const IconData signal_cellular_null = const IconData(0xe1cf);

  /// <p><i class="material-icons md-36">signal_cellular_off</i> &#x2014; material icon named "signal cellular off".</p>
  static const IconData signal_cellular_off = const IconData(0xe1d0);

  /// <p><i class="material-icons md-36">signal_wifi_4_bar</i> &#x2014; material icon named "signal wifi 4 bar".</p>
  static const IconData signal_wifi_4_bar = const IconData(0xe1d8);

  /// <p><i class="material-icons md-36">signal_wifi_4_bar_lock</i> &#x2014; material icon named "signal wifi 4 bar lock".</p>
  static const IconData signal_wifi_4_bar_lock = const IconData(0xe1d9);

  /// <p><i class="material-icons md-36">signal_wifi_off</i> &#x2014; material icon named "signal wifi off".</p>
  static const IconData signal_wifi_off = const IconData(0xe1da);

  /// <p><i class="material-icons md-36">sim_card</i> &#x2014; material icon named "sim card".</p>
  static const IconData sim_card = const IconData(0xe32b);

  /// <p><i class="material-icons md-36">sim_card_alert</i> &#x2014; material icon named "sim card alert".</p>
  static const IconData sim_card_alert = const IconData(0xe624);

  /// <p><i class="material-icons md-36">skip_next</i> &#x2014; material icon named "skip next".</p>
  static const IconData skip_next = const IconData(0xe044);

  /// <p><i class="material-icons md-36">skip_previous</i> &#x2014; material icon named "skip previous".</p>
  static const IconData skip_previous = const IconData(0xe045);

  /// <p><i class="material-icons md-36">slideshow</i> &#x2014; material icon named "slideshow".</p>
  static const IconData slideshow = const IconData(0xe41b);

  /// <p><i class="material-icons md-36">slow_motion_video</i> &#x2014; material icon named "slow motion video".</p>
  static const IconData slow_motion_video = const IconData(0xe068);

  /// <p><i class="material-icons md-36">smartphone</i> &#x2014; material icon named "smartphone".</p>
  static const IconData smartphone = const IconData(0xe32c);

  /// <p><i class="material-icons md-36">smoke_free</i> &#x2014; material icon named "smoke free".</p>
  static const IconData smoke_free = const IconData(0xeb4a);

  /// <p><i class="material-icons md-36">smoking_rooms</i> &#x2014; material icon named "smoking rooms".</p>
  static const IconData smoking_rooms = const IconData(0xeb4b);

  /// <p><i class="material-icons md-36">sms</i> &#x2014; material icon named "sms".</p>
  static const IconData sms = const IconData(0xe625);

  /// <p><i class="material-icons md-36">sms_failed</i> &#x2014; material icon named "sms failed".</p>
  static const IconData sms_failed = const IconData(0xe626);

  /// <p><i class="material-icons md-36">snooze</i> &#x2014; material icon named "snooze".</p>
  static const IconData snooze = const IconData(0xe046);

  /// <p><i class="material-icons md-36">sort</i> &#x2014; material icon named "sort".</p>
  static const IconData sort = const IconData(0xe164);

  /// <p><i class="material-icons md-36">sort_by_alpha</i> &#x2014; material icon named "sort by alpha".</p>
  static const IconData sort_by_alpha = const IconData(0xe053);

  /// <p><i class="material-icons md-36">spa</i> &#x2014; material icon named "spa".</p>
  static const IconData spa = const IconData(0xeb4c);

  /// <p><i class="material-icons md-36">space_bar</i> &#x2014; material icon named "space bar".</p>
  static const IconData space_bar = const IconData(0xe256);

  /// <p><i class="material-icons md-36">speaker</i> &#x2014; material icon named "speaker".</p>
  static const IconData speaker = const IconData(0xe32d);

  /// <p><i class="material-icons md-36">speaker_group</i> &#x2014; material icon named "speaker group".</p>
  static const IconData speaker_group = const IconData(0xe32e);

  /// <p><i class="material-icons md-36">speaker_notes</i> &#x2014; material icon named "speaker notes".</p>
  static const IconData speaker_notes = const IconData(0xe8cd);

  /// <p><i class="material-icons md-36">speaker_notes_off</i> &#x2014; material icon named "speaker notes off".</p>
  static const IconData speaker_notes_off = const IconData(0xe92a);

  /// <p><i class="material-icons md-36">speaker_phone</i> &#x2014; material icon named "speaker phone".</p>
  static const IconData speaker_phone = const IconData(0xe0d2);

  /// <p><i class="material-icons md-36">spellcheck</i> &#x2014; material icon named "spellcheck".</p>
  static const IconData spellcheck = const IconData(0xe8ce);

  /// <p><i class="material-icons md-36">star</i> &#x2014; material icon named "star".</p>
  static const IconData star = const IconData(0xe838);

  /// <p><i class="material-icons md-36">star_border</i> &#x2014; material icon named "star border".</p>
  static const IconData star_border = const IconData(0xe83a);

  /// <p><i class="material-icons md-36">star_half</i> &#x2014; material icon named "star half".</p>
  static const IconData star_half = const IconData(0xe839);

  /// <p><i class="material-icons md-36">stars</i> &#x2014; material icon named "stars".</p>
  static const IconData stars = const IconData(0xe8d0);

  /// <p><i class="material-icons md-36">stay_current_landscape</i> &#x2014; material icon named "stay current landscape".</p>
  static const IconData stay_current_landscape = const IconData(0xe0d3);

  /// <p><i class="material-icons md-36">stay_current_portrait</i> &#x2014; material icon named "stay current portrait".</p>
  static const IconData stay_current_portrait = const IconData(0xe0d4);

  /// <p><i class="material-icons md-36">stay_primary_landscape</i> &#x2014; material icon named "stay primary landscape".</p>
  static const IconData stay_primary_landscape = const IconData(0xe0d5);

  /// <p><i class="material-icons md-36">stay_primary_portrait</i> &#x2014; material icon named "stay primary portrait".</p>
  static const IconData stay_primary_portrait = const IconData(0xe0d6);

  /// <p><i class="material-icons md-36">stop</i> &#x2014; material icon named "stop".</p>
  static const IconData stop = const IconData(0xe047);

  /// <p><i class="material-icons md-36">stop_screen_share</i> &#x2014; material icon named "stop screen share".</p>
  static const IconData stop_screen_share = const IconData(0xe0e3);

  /// <p><i class="material-icons md-36">storage</i> &#x2014; material icon named "storage".</p>
  static const IconData storage = const IconData(0xe1db);

  /// <p><i class="material-icons md-36">store</i> &#x2014; material icon named "store".</p>
  static const IconData store = const IconData(0xe8d1);

  /// <p><i class="material-icons md-36">store_mall_directory</i> &#x2014; material icon named "store mall directory".</p>
  static const IconData store_mall_directory = const IconData(0xe563);

  /// <p><i class="material-icons md-36">straighten</i> &#x2014; material icon named "straighten".</p>
  static const IconData straighten = const IconData(0xe41c);

  /// <p><i class="material-icons md-36">streetview</i> &#x2014; material icon named "streetview".</p>
  static const IconData streetview = const IconData(0xe56e);

  /// <p><i class="material-icons md-36">strikethrough_s</i> &#x2014; material icon named "strikethrough s".</p>
  static const IconData strikethrough_s = const IconData(0xe257);

  /// <p><i class="material-icons md-36">style</i> &#x2014; material icon named "style".</p>
  static const IconData style = const IconData(0xe41d);

  /// <p><i class="material-icons md-36">subdirectory_arrow_left</i> &#x2014; material icon named "subdirectory arrow left".</p>
  static const IconData subdirectory_arrow_left = const IconData(0xe5d9);

  /// <p><i class="material-icons md-36">subdirectory_arrow_right</i> &#x2014; material icon named "subdirectory arrow right".</p>
  static const IconData subdirectory_arrow_right = const IconData(0xe5da);

  /// <p><i class="material-icons md-36">subject</i> &#x2014; material icon named "subject".</p>
  static const IconData subject = const IconData(0xe8d2);

  /// <p><i class="material-icons md-36">subscriptions</i> &#x2014; material icon named "subscriptions".</p>
  static const IconData subscriptions = const IconData(0xe064);

  /// <p><i class="material-icons md-36">subtitles</i> &#x2014; material icon named "subtitles".</p>
  static const IconData subtitles = const IconData(0xe048);

  /// <p><i class="material-icons md-36">subway</i> &#x2014; material icon named "subway".</p>
  static const IconData subway = const IconData(0xe56f);

  /// <p><i class="material-icons md-36">supervised_user_circle</i> &#x2014; material icon named "supervised user circle".</p>
  static const IconData supervised_user_circle = const IconData(0xe939);

  /// <p><i class="material-icons md-36">supervisor_account</i> &#x2014; material icon named "supervisor account".</p>
  static const IconData supervisor_account = const IconData(0xe8d3);

  /// <p><i class="material-icons md-36">surround_sound</i> &#x2014; material icon named "surround sound".</p>
  static const IconData surround_sound = const IconData(0xe049);

  /// <p><i class="material-icons md-36">swap_calls</i> &#x2014; material icon named "swap calls".</p>
  static const IconData swap_calls = const IconData(0xe0d7);

  /// <p><i class="material-icons md-36">swap_horiz</i> &#x2014; material icon named "swap horiz".</p>
  static const IconData swap_horiz = const IconData(0xe8d4);

  /// <p><i class="material-icons md-36">swap_horizontal_circle</i> &#x2014; material icon named "swap horizontal circle".</p>
  static const IconData swap_horizontal_circle = const IconData(0xe933);

  /// <p><i class="material-icons md-36">swap_vert</i> &#x2014; material icon named "swap vert".</p>
  static const IconData swap_vert = const IconData(0xe8d5);

  /// <p><i class="material-icons md-36">swap_vertical_circle</i> &#x2014; material icon named "swap vertical circle".</p>
  static const IconData swap_vertical_circle = const IconData(0xe8d6);

  /// <p><i class="material-icons md-36">switch_camera</i> &#x2014; material icon named "switch camera".</p>
  static const IconData switch_camera = const IconData(0xe41e);

  /// <p><i class="material-icons md-36">switch_video</i> &#x2014; material icon named "switch video".</p>
  static const IconData switch_video = const IconData(0xe41f);

  /// <p><i class="material-icons md-36">sync</i> &#x2014; material icon named "sync".</p>
  static const IconData sync = const IconData(0xe627);

  /// <p><i class="material-icons md-36">sync_disabled</i> &#x2014; material icon named "sync disabled".</p>
  static const IconData sync_disabled = const IconData(0xe628);

  /// <p><i class="material-icons md-36">sync_problem</i> &#x2014; material icon named "sync problem".</p>
  static const IconData sync_problem = const IconData(0xe629);

  /// <p><i class="material-icons md-36">system_update</i> &#x2014; material icon named "system update".</p>
  static const IconData system_update = const IconData(0xe62a);

  /// <p><i class="material-icons md-36">system_update_alt</i> &#x2014; material icon named "system update alt".</p>
  static const IconData system_update_alt = const IconData(0xe8d7);

  /// <p><i class="material-icons md-36">tab</i> &#x2014; material icon named "tab".</p>
  static const IconData tab = const IconData(0xe8d8);

  /// <p><i class="material-icons md-36">tab_unselected</i> &#x2014; material icon named "tab unselected".</p>
  static const IconData tab_unselected = const IconData(0xe8d9);

  /// <p><i class="material-icons md-36">table_chart</i> &#x2014; material icon named "table chart".</p>
  static const IconData table_chart = const IconData(0xe265);

  /// <p><i class="material-icons md-36">tablet</i> &#x2014; material icon named "tablet".</p>
  static const IconData tablet = const IconData(0xe32f);

  /// <p><i class="material-icons md-36">tablet_android</i> &#x2014; material icon named "tablet android".</p>
  static const IconData tablet_android = const IconData(0xe330);

  /// <p><i class="material-icons md-36">tablet_mac</i> &#x2014; material icon named "tablet mac".</p>
  static const IconData tablet_mac = const IconData(0xe331);

  /// <p><i class="material-icons md-36">tag_faces</i> &#x2014; material icon named "tag faces".</p>
  static const IconData tag_faces = const IconData(0xe420);

  /// <p><i class="material-icons md-36">tap_and_play</i> &#x2014; material icon named "tap and play".</p>
  static const IconData tap_and_play = const IconData(0xe62b);

  /// <p><i class="material-icons md-36">terrain</i> &#x2014; material icon named "terrain".</p>
  static const IconData terrain = const IconData(0xe564);

  /// <p><i class="material-icons md-36">text_fields</i> &#x2014; material icon named "text fields".</p>
  static const IconData text_fields = const IconData(0xe262);

  /// <p><i class="material-icons md-36">text_format</i> &#x2014; material icon named "text format".</p>
  static const IconData text_format = const IconData(0xe165);

  /// <p><i class="material-icons md-36">text_rotate_up</i> &#x2014; material icon named "text rotate up".</p>
  static const IconData text_rotate_up = const IconData(0xe93a);

  /// <p><i class="material-icons md-36">text_rotate_vertical</i> &#x2014; material icon named "text rotate vertical".</p>
  static const IconData text_rotate_vertical = const IconData(0xe93b);

  /// <p><i class="material-icons md-36">text_rotation_angledown</i> &#x2014; material icon named "text rotation angledown".</p>
  static const IconData text_rotation_angledown = const IconData(0xe93c);

  /// <p><i class="material-icons md-36">text_rotation_angleup</i> &#x2014; material icon named "text rotation angleup".</p>
  static const IconData text_rotation_angleup = const IconData(0xe93d);

  /// <p><i class="material-icons md-36">text_rotation_down</i> &#x2014; material icon named "text rotation down".</p>
  static const IconData text_rotation_down = const IconData(0xe93e);

  /// <p><i class="material-icons md-36">text_rotation_none</i> &#x2014; material icon named "text rotation none".</p>
  static const IconData text_rotation_none = const IconData(0xe93f);

  /// <p><i class="material-icons md-36">textsms</i> &#x2014; material icon named "textsms".</p>
  static const IconData textsms = const IconData(0xe0d8);

  /// <p><i class="material-icons md-36">texture</i> &#x2014; material icon named "texture".</p>
  static const IconData texture = const IconData(0xe421);

  /// <p><i class="material-icons md-36">theaters</i> &#x2014; material icon named "theaters".</p>
  static const IconData theaters = const IconData(0xe8da);

  /// <p><i class="material-icons md-36">thumb_down</i> &#x2014; material icon named "thumb down".</p>
  static const IconData thumb_down = const IconData(0xe8db);

  /// <p><i class="material-icons md-36">thumb_up</i> &#x2014; material icon named "thumb up".</p>
  static const IconData thumb_up = const IconData(0xe8dc);

  /// <p><i class="material-icons md-36">thumbs_up_down</i> &#x2014; material icon named "thumbs up down".</p>
  static const IconData thumbs_up_down = const IconData(0xe8dd);

  /// <p><i class="material-icons md-36">time_to_leave</i> &#x2014; material icon named "time to leave".</p>
  static const IconData time_to_leave = const IconData(0xe62c);

  /// <p><i class="material-icons md-36">timelapse</i> &#x2014; material icon named "timelapse".</p>
  static const IconData timelapse = const IconData(0xe422);

  /// <p><i class="material-icons md-36">timeline</i> &#x2014; material icon named "timeline".</p>
  static const IconData timeline = const IconData(0xe922);

  /// <p><i class="material-icons md-36">timer</i> &#x2014; material icon named "timer".</p>
  static const IconData timer = const IconData(0xe425);

  /// <p><i class="material-icons md-36">timer_10</i> &#x2014; material icon named "timer 10".</p>
  static const IconData timer_10 = const IconData(0xe423);

  /// <p><i class="material-icons md-36">timer_3</i> &#x2014; material icon named "timer 3".</p>
  static const IconData timer_3 = const IconData(0xe424);

  /// <p><i class="material-icons md-36">timer_off</i> &#x2014; material icon named "timer off".</p>
  static const IconData timer_off = const IconData(0xe426);

  /// <p><i class="material-icons md-36">title</i> &#x2014; material icon named "title".</p>
  static const IconData title = const IconData(0xe264);

  /// <p><i class="material-icons md-36">toc</i> &#x2014; material icon named "toc".</p>
  static const IconData toc = const IconData(0xe8de);

  /// <p><i class="material-icons md-36">today</i> &#x2014; material icon named "today".</p>
  static const IconData today = const IconData(0xe8df);

  /// <p><i class="material-icons md-36">toll</i> &#x2014; material icon named "toll".</p>
  static const IconData toll = const IconData(0xe8e0);

  /// <p><i class="material-icons md-36">tonality</i> &#x2014; material icon named "tonality".</p>
  static const IconData tonality = const IconData(0xe427);

  /// <p><i class="material-icons md-36">touch_app</i> &#x2014; material icon named "touch app".</p>
  static const IconData touch_app = const IconData(0xe913);

  /// <p><i class="material-icons md-36">toys</i> &#x2014; material icon named "toys".</p>
  static const IconData toys = const IconData(0xe332);

  /// <p><i class="material-icons md-36">track_changes</i> &#x2014; material icon named "track changes".</p>
  static const IconData track_changes = const IconData(0xe8e1);

  /// <p><i class="material-icons md-36">traffic</i> &#x2014; material icon named "traffic".</p>
  static const IconData traffic = const IconData(0xe565);

  /// <p><i class="material-icons md-36">train</i> &#x2014; material icon named "train".</p>
  static const IconData train = const IconData(0xe570);

  /// <p><i class="material-icons md-36">tram</i> &#x2014; material icon named "tram".</p>
  static const IconData tram = const IconData(0xe571);

  /// <p><i class="material-icons md-36">transfer_within_a_station</i> &#x2014; material icon named "transfer within a station".</p>
  static const IconData transfer_within_a_station = const IconData(0xe572);

  /// <p><i class="material-icons md-36">transform</i> &#x2014; material icon named "transform".</p>
  static const IconData transform = const IconData(0xe428);

  /// <p><i class="material-icons md-36">transit_enterexit</i> &#x2014; material icon named "transit enterexit".</p>
  static const IconData transit_enterexit = const IconData(0xe579);

  /// <p><i class="material-icons md-36">translate</i> &#x2014; material icon named "translate".</p>
  static const IconData translate = const IconData(0xe8e2);

  /// <p><i class="material-icons md-36">trending_down</i> &#x2014; material icon named "trending down".</p>
  static const IconData trending_down = const IconData(0xe8e3);

  /// <p><i class="material-icons md-36">trending_flat</i> &#x2014; material icon named "trending flat".</p>
  static const IconData trending_flat = const IconData(0xe8e4);

  /// <p><i class="material-icons md-36">trending_up</i> &#x2014; material icon named "trending up".</p>
  static const IconData trending_up = const IconData(0xe8e5);

  /// <p><i class="material-icons md-36">trip_origin</i> &#x2014; material icon named "trip origin".</p>
  static const IconData trip_origin = const IconData(0xe57b);

  /// <p><i class="material-icons md-36">tune</i> &#x2014; material icon named "tune".</p>
  static const IconData tune = const IconData(0xe429);

  /// <p><i class="material-icons md-36">turned_in</i> &#x2014; material icon named "turned in".</p>
  static const IconData turned_in = const IconData(0xe8e6);

  /// <p><i class="material-icons md-36">turned_in_not</i> &#x2014; material icon named "turned in not".</p>
  static const IconData turned_in_not = const IconData(0xe8e7);

  /// <p><i class="material-icons md-36">tv</i> &#x2014; material icon named "tv".</p>
  static const IconData tv = const IconData(0xe333);

  /// <p><i class="material-icons md-36">unarchive</i> &#x2014; material icon named "unarchive".</p>
  static const IconData unarchive = const IconData(0xe169);

  /// <p><i class="material-icons md-36">undo</i> &#x2014; material icon named "undo".</p>
  static const IconData undo = const IconData(0xe166);

  /// <p><i class="material-icons md-36">unfold_less</i> &#x2014; material icon named "unfold less".</p>
  static const IconData unfold_less = const IconData(0xe5d6);

  /// <p><i class="material-icons md-36">unfold_more</i> &#x2014; material icon named "unfold more".</p>
  static const IconData unfold_more = const IconData(0xe5d7);

  /// <p><i class="material-icons md-36">update</i> &#x2014; material icon named "update".</p>
  static const IconData update = const IconData(0xe923);

  /// <p><i class="material-icons md-36">usb</i> &#x2014; material icon named "usb".</p>
  static const IconData usb = const IconData(0xe1e0);

  /// <p><i class="material-icons md-36">verified_user</i> &#x2014; material icon named "verified user".</p>
  static const IconData verified_user = const IconData(0xe8e8);

  /// <p><i class="material-icons md-36">vertical_align_bottom</i> &#x2014; material icon named "vertical align bottom".</p>
  static const IconData vertical_align_bottom = const IconData(0xe258);

  /// <p><i class="material-icons md-36">vertical_align_center</i> &#x2014; material icon named "vertical align center".</p>
  static const IconData vertical_align_center = const IconData(0xe259);

  /// <p><i class="material-icons md-36">vertical_align_top</i> &#x2014; material icon named "vertical align top".</p>
  static const IconData vertical_align_top = const IconData(0xe25a);

  /// <p><i class="material-icons md-36">vibration</i> &#x2014; material icon named "vibration".</p>
  static const IconData vibration = const IconData(0xe62d);

  /// <p><i class="material-icons md-36">video_call</i> &#x2014; material icon named "video call".</p>
  static const IconData video_call = const IconData(0xe070);

  /// <p><i class="material-icons md-36">video_label</i> &#x2014; material icon named "video label".</p>
  static const IconData video_label = const IconData(0xe071);

  /// <p><i class="material-icons md-36">video_library</i> &#x2014; material icon named "video library".</p>
  static const IconData video_library = const IconData(0xe04a);

  /// <p><i class="material-icons md-36">videocam</i> &#x2014; material icon named "videocam".</p>
  static const IconData videocam = const IconData(0xe04b);

  /// <p><i class="material-icons md-36">videocam_off</i> &#x2014; material icon named "videocam off".</p>
  static const IconData videocam_off = const IconData(0xe04c);

  /// <p><i class="material-icons md-36">videogame_asset</i> &#x2014; material icon named "videogame asset".</p>
  static const IconData videogame_asset = const IconData(0xe338);

  /// <p><i class="material-icons md-36">view_agenda</i> &#x2014; material icon named "view agenda".</p>
  static const IconData view_agenda = const IconData(0xe8e9);

  /// <p><i class="material-icons md-36">view_array</i> &#x2014; material icon named "view array".</p>
  static const IconData view_array = const IconData(0xe8ea);

  /// <p><i class="material-icons md-36">view_carousel</i> &#x2014; material icon named "view carousel".</p>
  static const IconData view_carousel = const IconData(0xe8eb);

  /// <p><i class="material-icons md-36">view_column</i> &#x2014; material icon named "view column".</p>
  static const IconData view_column = const IconData(0xe8ec);

  /// <p><i class="material-icons md-36">view_comfy</i> &#x2014; material icon named "view comfy".</p>
  static const IconData view_comfy = const IconData(0xe42a);

  /// <p><i class="material-icons md-36">view_compact</i> &#x2014; material icon named "view compact".</p>
  static const IconData view_compact = const IconData(0xe42b);

  /// <p><i class="material-icons md-36">view_day</i> &#x2014; material icon named "view day".</p>
  static const IconData view_day = const IconData(0xe8ed);

  /// <p><i class="material-icons md-36">view_headline</i> &#x2014; material icon named "view headline".</p>
  static const IconData view_headline = const IconData(0xe8ee);

  /// <p><i class="material-icons md-36">view_list</i> &#x2014; material icon named "view list".</p>
  static const IconData view_list = const IconData(0xe8ef);

  /// <p><i class="material-icons md-36">view_module</i> &#x2014; material icon named "view module".</p>
  static const IconData view_module = const IconData(0xe8f0);

  /// <p><i class="material-icons md-36">view_quilt</i> &#x2014; material icon named "view quilt".</p>
  static const IconData view_quilt = const IconData(0xe8f1);

  /// <p><i class="material-icons md-36">view_stream</i> &#x2014; material icon named "view stream".</p>
  static const IconData view_stream = const IconData(0xe8f2);

  /// <p><i class="material-icons md-36">view_week</i> &#x2014; material icon named "view week".</p>
  static const IconData view_week = const IconData(0xe8f3);

  /// <p><i class="material-icons md-36">vignette</i> &#x2014; material icon named "vignette".</p>
  static const IconData vignette = const IconData(0xe435);

  /// <p><i class="material-icons md-36">visibility</i> &#x2014; material icon named "visibility".</p>
  static const IconData visibility = const IconData(0xe8f4);

  /// <p><i class="material-icons md-36">visibility_off</i> &#x2014; material icon named "visibility off".</p>
  static const IconData visibility_off = const IconData(0xe8f5);

  /// <p><i class="material-icons md-36">voice_chat</i> &#x2014; material icon named "voice chat".</p>
  static const IconData voice_chat = const IconData(0xe62e);

  /// <p><i class="material-icons md-36">voicemail</i> &#x2014; material icon named "voicemail".</p>
  static const IconData voicemail = const IconData(0xe0d9);

  /// <p><i class="material-icons md-36">volume_down</i> &#x2014; material icon named "volume down".</p>
  static const IconData volume_down = const IconData(0xe04d);

  /// <p><i class="material-icons md-36">volume_mute</i> &#x2014; material icon named "volume mute".</p>
  static const IconData volume_mute = const IconData(0xe04e);

  /// <p><i class="material-icons md-36">volume_off</i> &#x2014; material icon named "volume off".</p>
  static const IconData volume_off = const IconData(0xe04f);

  /// <p><i class="material-icons md-36">volume_up</i> &#x2014; material icon named "volume up".</p>
  static const IconData volume_up = const IconData(0xe050);

  /// <p><i class="material-icons md-36">vpn_key</i> &#x2014; material icon named "vpn key".</p>
  static const IconData vpn_key = const IconData(0xe0da);

  /// <p><i class="material-icons md-36">vpn_lock</i> &#x2014; material icon named "vpn lock".</p>
  static const IconData vpn_lock = const IconData(0xe62f);

  /// <p><i class="material-icons md-36">wallpaper</i> &#x2014; material icon named "wallpaper".</p>
  static const IconData wallpaper = const IconData(0xe1bc);

  /// <p><i class="material-icons md-36">warning</i> &#x2014; material icon named "warning".</p>
  static const IconData warning = const IconData(0xe002);

  /// <p><i class="material-icons md-36">watch</i> &#x2014; material icon named "watch".</p>
  static const IconData watch = const IconData(0xe334);

  /// <p><i class="material-icons md-36">watch_later</i> &#x2014; material icon named "watch later".</p>
  static const IconData watch_later = const IconData(0xe924);

  /// <p><i class="material-icons md-36">wb_auto</i> &#x2014; material icon named "wb auto".</p>
  static const IconData wb_auto = const IconData(0xe42c);

  /// <p><i class="material-icons md-36">wb_cloudy</i> &#x2014; material icon named "wb cloudy".</p>
  static const IconData wb_cloudy = const IconData(0xe42d);

  /// <p><i class="material-icons md-36">wb_incandescent</i> &#x2014; material icon named "wb incandescent".</p>
  static const IconData wb_incandescent = const IconData(0xe42e);

  /// <p><i class="material-icons md-36">wb_iridescent</i> &#x2014; material icon named "wb iridescent".</p>
  static const IconData wb_iridescent = const IconData(0xe436);

  /// <p><i class="material-icons md-36">wb_sunny</i> &#x2014; material icon named "wb sunny".</p>
  static const IconData wb_sunny = const IconData(0xe430);

  /// <p><i class="material-icons md-36">wc</i> &#x2014; material icon named "wc".</p>
  static const IconData wc = const IconData(0xe63d);

  /// <p><i class="material-icons md-36">web</i> &#x2014; material icon named "web".</p>
  static const IconData web = const IconData(0xe051);

  /// <p><i class="material-icons md-36">web_asset</i> &#x2014; material icon named "web asset".</p>
  static const IconData web_asset = const IconData(0xe069);

  /// <p><i class="material-icons md-36">weekend</i> &#x2014; material icon named "weekend".</p>
  static const IconData weekend = const IconData(0xe16b);

  /// <p><i class="material-icons md-36">whatshot</i> &#x2014; material icon named "whatshot".</p>
  static const IconData whatshot = const IconData(0xe80e);

  /// <p><i class="material-icons md-36">widgets</i> &#x2014; material icon named "widgets".</p>
  static const IconData widgets = const IconData(0xe1bd);

  /// <p><i class="material-icons md-36">wifi</i> &#x2014; material icon named "wifi".</p>
  static const IconData wifi = const IconData(0xe63e);

  /// <p><i class="material-icons md-36">wifi_lock</i> &#x2014; material icon named "wifi lock".</p>
  static const IconData wifi_lock = const IconData(0xe1e1);

  /// <p><i class="material-icons md-36">wifi_tethering</i> &#x2014; material icon named "wifi tethering".</p>
  static const IconData wifi_tethering = const IconData(0xe1e2);

  /// <p><i class="material-icons md-36">work</i> &#x2014; material icon named "work".</p>
  static const IconData work = const IconData(0xe8f9);

  /// <p><i class="material-icons md-36">wrap_text</i> &#x2014; material icon named "wrap text".</p>
  static const IconData wrap_text = const IconData(0xe25b);

  /// <p><i class="material-icons md-36">youtube_searched_for</i> &#x2014; material icon named "youtube searched for".</p>
  static const IconData youtube_searched_for = const IconData(0xe8fa);

  /// <p><i class="material-icons md-36">zoom_in</i> &#x2014; material icon named "zoom in".</p>
  static const IconData zoom_in = const IconData(0xe8ff);

  /// <p><i class="material-icons md-36">zoom_out</i> &#x2014; material icon named "zoom out".</p>
  static const IconData zoom_out = const IconData(0xe900);

  /// <p><i class="material-icons md-36">zoom_out_map</i> &#x2014; material icon named "zoom out map".</p>
  static const IconData zoom_out_map = const IconData(0xe56b);
  // END GENERATED
}
