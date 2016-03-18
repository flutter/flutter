// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class IconData {
  const IconData(this.codePoint);
  final int codePoint;

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
  String toString() => 'IconData(codePoint: $codePoint)';
}

/// Identifiers for the supported material design icons.
///
/// Use with with the [Icon] class to show specific icons.
///
/// See also: <https://design.google.com/icons/>
class Icons {
  Icons._();

  /// <p>Material icon "3d rotation": <i class="material-icons md-48">3d_rotation</i></p>
  static const IconData threed_rotation = const IconData(0xe84d); // 3d_rotation isn't a valid identifier.

  /// <p>Material icon "ac unit": <i class="material-icons md-48">ac_unit</i></p>
  static const IconData ac_unit = const IconData(0xeb3b);

  /// <p>Material icon "access alarm": <i class="material-icons md-48">access_alarm</i></p>
  static const IconData access_alarm = const IconData(0xe190);

  /// <p>Material icon "access alarms": <i class="material-icons md-48">access_alarms</i></p>
  static const IconData access_alarms = const IconData(0xe191);

  /// <p>Material icon "access time": <i class="material-icons md-48">access_time</i></p>
  static const IconData access_time = const IconData(0xe192);

  /// <p>Material icon "accessibility": <i class="material-icons md-48">accessibility</i></p>
  static const IconData accessibility = const IconData(0xe84e);

  /// <p>Material icon "accessible": <i class="material-icons md-48">accessible</i></p>
  static const IconData accessible = const IconData(0xe914);

  /// <p>Material icon "account balance": <i class="material-icons md-48">account_balance</i></p>
  static const IconData account_balance = const IconData(0xe84f);

  /// <p>Material icon "account balance wallet": <i class="material-icons md-48">account_balance_wallet</i></p>
  static const IconData account_balance_wallet = const IconData(0xe850);

  /// <p>Material icon "account box": <i class="material-icons md-48">account_box</i></p>
  static const IconData account_box = const IconData(0xe851);

  /// <p>Material icon "account circle": <i class="material-icons md-48">account_circle</i></p>
  static const IconData account_circle = const IconData(0xe853);

  /// <p>Material icon "adb": <i class="material-icons md-48">adb</i></p>
  static const IconData adb = const IconData(0xe60e);

  /// <p>Material icon "add": <i class="material-icons md-48">add</i></p>
  static const IconData add = const IconData(0xe145);

  /// <p>Material icon "add a photo": <i class="material-icons md-48">add_a_photo</i></p>
  static const IconData add_a_photo = const IconData(0xe439);

  /// <p>Material icon "add alarm": <i class="material-icons md-48">add_alarm</i></p>
  static const IconData add_alarm = const IconData(0xe193);

  /// <p>Material icon "add alert": <i class="material-icons md-48">add_alert</i></p>
  static const IconData add_alert = const IconData(0xe003);

  /// <p>Material icon "add box": <i class="material-icons md-48">add_box</i></p>
  static const IconData add_box = const IconData(0xe146);

  /// <p>Material icon "add circle": <i class="material-icons md-48">add_circle</i></p>
  static const IconData add_circle = const IconData(0xe147);

  /// <p>Material icon "add circle outline": <i class="material-icons md-48">add_circle_outline</i></p>
  static const IconData add_circle_outline = const IconData(0xe148);

  /// <p>Material icon "add location": <i class="material-icons md-48">add_location</i></p>
  static const IconData add_location = const IconData(0xe567);

  /// <p>Material icon "add shopping cart": <i class="material-icons md-48">add_shopping_cart</i></p>
  static const IconData add_shopping_cart = const IconData(0xe854);

  /// <p>Material icon "add to photos": <i class="material-icons md-48">add_to_photos</i></p>
  static const IconData add_to_photos = const IconData(0xe39d);

  /// <p>Material icon "add to queue": <i class="material-icons md-48">add_to_queue</i></p>
  static const IconData add_to_queue = const IconData(0xe05c);

  /// <p>Material icon "adjust": <i class="material-icons md-48">adjust</i></p>
  static const IconData adjust = const IconData(0xe39e);

  /// <p>Material icon "airline seat flat": <i class="material-icons md-48">airline_seat_flat</i></p>
  static const IconData airline_seat_flat = const IconData(0xe630);

  /// <p>Material icon "airline seat flat angled": <i class="material-icons md-48">airline_seat_flat_angled</i></p>
  static const IconData airline_seat_flat_angled = const IconData(0xe631);

  /// <p>Material icon "airline seat individual suite": <i class="material-icons md-48">airline_seat_individual_suite</i></p>
  static const IconData airline_seat_individual_suite = const IconData(0xe632);

  /// <p>Material icon "airline seat legroom extra": <i class="material-icons md-48">airline_seat_legroom_extra</i></p>
  static const IconData airline_seat_legroom_extra = const IconData(0xe633);

  /// <p>Material icon "airline seat legroom normal": <i class="material-icons md-48">airline_seat_legroom_normal</i></p>
  static const IconData airline_seat_legroom_normal = const IconData(0xe634);

  /// <p>Material icon "airline seat legroom reduced": <i class="material-icons md-48">airline_seat_legroom_reduced</i></p>
  static const IconData airline_seat_legroom_reduced = const IconData(0xe635);

  /// <p>Material icon "airline seat recline extra": <i class="material-icons md-48">airline_seat_recline_extra</i></p>
  static const IconData airline_seat_recline_extra = const IconData(0xe636);

  /// <p>Material icon "airline seat recline normal": <i class="material-icons md-48">airline_seat_recline_normal</i></p>
  static const IconData airline_seat_recline_normal = const IconData(0xe637);

  /// <p>Material icon "airplanemode active": <i class="material-icons md-48">airplanemode_active</i></p>
  static const IconData airplanemode_active = const IconData(0xe195);

  /// <p>Material icon "airplanemode inactive": <i class="material-icons md-48">airplanemode_inactive</i></p>
  static const IconData airplanemode_inactive = const IconData(0xe194);

  /// <p>Material icon "airplay": <i class="material-icons md-48">airplay</i></p>
  static const IconData airplay = const IconData(0xe055);

  /// <p>Material icon "airport shuttle": <i class="material-icons md-48">airport_shuttle</i></p>
  static const IconData airport_shuttle = const IconData(0xeb3c);

  /// <p>Material icon "alarm": <i class="material-icons md-48">alarm</i></p>
  static const IconData alarm = const IconData(0xe855);

  /// <p>Material icon "alarm add": <i class="material-icons md-48">alarm_add</i></p>
  static const IconData alarm_add = const IconData(0xe856);

  /// <p>Material icon "alarm off": <i class="material-icons md-48">alarm_off</i></p>
  static const IconData alarm_off = const IconData(0xe857);

  /// <p>Material icon "alarm on": <i class="material-icons md-48">alarm_on</i></p>
  static const IconData alarm_on = const IconData(0xe858);

  /// <p>Material icon "album": <i class="material-icons md-48">album</i></p>
  static const IconData album = const IconData(0xe019);

  /// <p>Material icon "all inclusive": <i class="material-icons md-48">all_inclusive</i></p>
  static const IconData all_inclusive = const IconData(0xeb3d);

  /// <p>Material icon "all out": <i class="material-icons md-48">all_out</i></p>
  static const IconData all_out = const IconData(0xe90b);

  /// <p>Material icon "android": <i class="material-icons md-48">android</i></p>
  static const IconData android = const IconData(0xe859);

  /// <p>Material icon "announcement": <i class="material-icons md-48">announcement</i></p>
  static const IconData announcement = const IconData(0xe85a);

  /// <p>Material icon "apps": <i class="material-icons md-48">apps</i></p>
  static const IconData apps = const IconData(0xe5c3);

  /// <p>Material icon "archive": <i class="material-icons md-48">archive</i></p>
  static const IconData archive = const IconData(0xe149);

  /// <p>Material icon "arrow back": <i class="material-icons md-48">arrow_back</i></p>
  static const IconData arrow_back = const IconData(0xe5c4);

  /// <p>Material icon "arrow downward": <i class="material-icons md-48">arrow_downward</i></p>
  static const IconData arrow_downward = const IconData(0xe5db);

  /// <p>Material icon "arrow drop down": <i class="material-icons md-48">arrow_drop_down</i></p>
  static const IconData arrow_drop_down = const IconData(0xe5c5);

  /// <p>Material icon "arrow drop down circle": <i class="material-icons md-48">arrow_drop_down_circle</i></p>
  static const IconData arrow_drop_down_circle = const IconData(0xe5c6);

  /// <p>Material icon "arrow drop up": <i class="material-icons md-48">arrow_drop_up</i></p>
  static const IconData arrow_drop_up = const IconData(0xe5c7);

  /// <p>Material icon "arrow forward": <i class="material-icons md-48">arrow_forward</i></p>
  static const IconData arrow_forward = const IconData(0xe5c8);

  /// <p>Material icon "arrow upward": <i class="material-icons md-48">arrow_upward</i></p>
  static const IconData arrow_upward = const IconData(0xe5d8);

  /// <p>Material icon "art track": <i class="material-icons md-48">art_track</i></p>
  static const IconData art_track = const IconData(0xe060);

  /// <p>Material icon "aspect ratio": <i class="material-icons md-48">aspect_ratio</i></p>
  static const IconData aspect_ratio = const IconData(0xe85b);

  /// <p>Material icon "assessment": <i class="material-icons md-48">assessment</i></p>
  static const IconData assessment = const IconData(0xe85c);

  /// <p>Material icon "assignment": <i class="material-icons md-48">assignment</i></p>
  static const IconData assignment = const IconData(0xe85d);

  /// <p>Material icon "assignment ind": <i class="material-icons md-48">assignment_ind</i></p>
  static const IconData assignment_ind = const IconData(0xe85e);

  /// <p>Material icon "assignment late": <i class="material-icons md-48">assignment_late</i></p>
  static const IconData assignment_late = const IconData(0xe85f);

  /// <p>Material icon "assignment return": <i class="material-icons md-48">assignment_return</i></p>
  static const IconData assignment_return = const IconData(0xe860);

  /// <p>Material icon "assignment returned": <i class="material-icons md-48">assignment_returned</i></p>
  static const IconData assignment_returned = const IconData(0xe861);

  /// <p>Material icon "assignment turned in": <i class="material-icons md-48">assignment_turned_in</i></p>
  static const IconData assignment_turned_in = const IconData(0xe862);

  /// <p>Material icon "assistant": <i class="material-icons md-48">assistant</i></p>
  static const IconData assistant = const IconData(0xe39f);

  /// <p>Material icon "assistant photo": <i class="material-icons md-48">assistant_photo</i></p>
  static const IconData assistant_photo = const IconData(0xe3a0);

  /// <p>Material icon "attach file": <i class="material-icons md-48">attach_file</i></p>
  static const IconData attach_file = const IconData(0xe226);

  /// <p>Material icon "attach money": <i class="material-icons md-48">attach_money</i></p>
  static const IconData attach_money = const IconData(0xe227);

  /// <p>Material icon "attachment": <i class="material-icons md-48">attachment</i></p>
  static const IconData attachment = const IconData(0xe2bc);

  /// <p>Material icon "audiotrack": <i class="material-icons md-48">audiotrack</i></p>
  static const IconData audiotrack = const IconData(0xe3a1);

  /// <p>Material icon "autoreconst": <i class="material-icons md-48">autoreconst</i></p>
  static const IconData autoreconst = const IconData(0xe863);

  /// <p>Material icon "av timer": <i class="material-icons md-48">av_timer</i></p>
  static const IconData av_timer = const IconData(0xe01b);

  /// <p>Material icon "backspace": <i class="material-icons md-48">backspace</i></p>
  static const IconData backspace = const IconData(0xe14a);

  /// <p>Material icon "backup": <i class="material-icons md-48">backup</i></p>
  static const IconData backup = const IconData(0xe864);

  /// <p>Material icon "battery alert": <i class="material-icons md-48">battery_alert</i></p>
  static const IconData battery_alert = const IconData(0xe19c);

  /// <p>Material icon "battery charging full": <i class="material-icons md-48">battery_charging_full</i></p>
  static const IconData battery_charging_full = const IconData(0xe1a3);

  /// <p>Material icon "battery full": <i class="material-icons md-48">battery_full</i></p>
  static const IconData battery_full = const IconData(0xe1a4);

  /// <p>Material icon "battery std": <i class="material-icons md-48">battery_std</i></p>
  static const IconData battery_std = const IconData(0xe1a5);

  /// <p>Material icon "battery unknown": <i class="material-icons md-48">battery_unknown</i></p>
  static const IconData battery_unknown = const IconData(0xe1a6);

  /// <p>Material icon "beach access": <i class="material-icons md-48">beach_access</i></p>
  static const IconData beach_access = const IconData(0xeb3e);

  /// <p>Material icon "beenhere": <i class="material-icons md-48">beenhere</i></p>
  static const IconData beenhere = const IconData(0xe52d);

  /// <p>Material icon "block": <i class="material-icons md-48">block</i></p>
  static const IconData block = const IconData(0xe14b);

  /// <p>Material icon "bluetooth": <i class="material-icons md-48">bluetooth</i></p>
  static const IconData bluetooth = const IconData(0xe1a7);

  /// <p>Material icon "bluetooth audio": <i class="material-icons md-48">bluetooth_audio</i></p>
  static const IconData bluetooth_audio = const IconData(0xe60f);

  /// <p>Material icon "bluetooth connected": <i class="material-icons md-48">bluetooth_connected</i></p>
  static const IconData bluetooth_connected = const IconData(0xe1a8);

  /// <p>Material icon "bluetooth disabled": <i class="material-icons md-48">bluetooth_disabled</i></p>
  static const IconData bluetooth_disabled = const IconData(0xe1a9);

  /// <p>Material icon "bluetooth searching": <i class="material-icons md-48">bluetooth_searching</i></p>
  static const IconData bluetooth_searching = const IconData(0xe1aa);

  /// <p>Material icon "blur circular": <i class="material-icons md-48">blur_circular</i></p>
  static const IconData blur_circular = const IconData(0xe3a2);

  /// <p>Material icon "blur linear": <i class="material-icons md-48">blur_linear</i></p>
  static const IconData blur_linear = const IconData(0xe3a3);

  /// <p>Material icon "blur off": <i class="material-icons md-48">blur_off</i></p>
  static const IconData blur_off = const IconData(0xe3a4);

  /// <p>Material icon "blur on": <i class="material-icons md-48">blur_on</i></p>
  static const IconData blur_on = const IconData(0xe3a5);

  /// <p>Material icon "book": <i class="material-icons md-48">book</i></p>
  static const IconData book = const IconData(0xe865);

  /// <p>Material icon "bookmark": <i class="material-icons md-48">bookmark</i></p>
  static const IconData bookmark = const IconData(0xe866);

  /// <p>Material icon "bookmark border": <i class="material-icons md-48">bookmark_border</i></p>
  static const IconData bookmark_border = const IconData(0xe867);

  /// <p>Material icon "border all": <i class="material-icons md-48">border_all</i></p>
  static const IconData border_all = const IconData(0xe228);

  /// <p>Material icon "border bottom": <i class="material-icons md-48">border_bottom</i></p>
  static const IconData border_bottom = const IconData(0xe229);

  /// <p>Material icon "border clear": <i class="material-icons md-48">border_clear</i></p>
  static const IconData border_clear = const IconData(0xe22a);

  /// <p>Material icon "border color": <i class="material-icons md-48">border_color</i></p>
  static const IconData border_color = const IconData(0xe22b);

  /// <p>Material icon "border horizontal": <i class="material-icons md-48">border_horizontal</i></p>
  static const IconData border_horizontal = const IconData(0xe22c);

  /// <p>Material icon "border inner": <i class="material-icons md-48">border_inner</i></p>
  static const IconData border_inner = const IconData(0xe22d);

  /// <p>Material icon "border left": <i class="material-icons md-48">border_left</i></p>
  static const IconData border_left = const IconData(0xe22e);

  /// <p>Material icon "border outer": <i class="material-icons md-48">border_outer</i></p>
  static const IconData border_outer = const IconData(0xe22f);

  /// <p>Material icon "border right": <i class="material-icons md-48">border_right</i></p>
  static const IconData border_right = const IconData(0xe230);

  /// <p>Material icon "border style": <i class="material-icons md-48">border_style</i></p>
  static const IconData border_style = const IconData(0xe231);

  /// <p>Material icon "border top": <i class="material-icons md-48">border_top</i></p>
  static const IconData border_top = const IconData(0xe232);

  /// <p>Material icon "border vertical": <i class="material-icons md-48">border_vertical</i></p>
  static const IconData border_vertical = const IconData(0xe233);

  /// <p>Material icon "branding watermark": <i class="material-icons md-48">branding_watermark</i></p>
  static const IconData branding_watermark = const IconData(0xe06b);

  /// <p>Material icon "brightness 1": <i class="material-icons md-48">brightness_1</i></p>
  static const IconData brightness_1 = const IconData(0xe3a6);

  /// <p>Material icon "brightness 2": <i class="material-icons md-48">brightness_2</i></p>
  static const IconData brightness_2 = const IconData(0xe3a7);

  /// <p>Material icon "brightness 3": <i class="material-icons md-48">brightness_3</i></p>
  static const IconData brightness_3 = const IconData(0xe3a8);

  /// <p>Material icon "brightness 4": <i class="material-icons md-48">brightness_4</i></p>
  static const IconData brightness_4 = const IconData(0xe3a9);

  /// <p>Material icon "brightness 5": <i class="material-icons md-48">brightness_5</i></p>
  static const IconData brightness_5 = const IconData(0xe3aa);

  /// <p>Material icon "brightness 6": <i class="material-icons md-48">brightness_6</i></p>
  static const IconData brightness_6 = const IconData(0xe3ab);

  /// <p>Material icon "brightness 7": <i class="material-icons md-48">brightness_7</i></p>
  static const IconData brightness_7 = const IconData(0xe3ac);

  /// <p>Material icon "brightness auto": <i class="material-icons md-48">brightness_auto</i></p>
  static const IconData brightness_auto = const IconData(0xe1ab);

  /// <p>Material icon "brightness high": <i class="material-icons md-48">brightness_high</i></p>
  static const IconData brightness_high = const IconData(0xe1ac);

  /// <p>Material icon "brightness low": <i class="material-icons md-48">brightness_low</i></p>
  static const IconData brightness_low = const IconData(0xe1ad);

  /// <p>Material icon "brightness medium": <i class="material-icons md-48">brightness_medium</i></p>
  static const IconData brightness_medium = const IconData(0xe1ae);

  /// <p>Material icon "broken image": <i class="material-icons md-48">broken_image</i></p>
  static const IconData broken_image = const IconData(0xe3ad);

  /// <p>Material icon "brush": <i class="material-icons md-48">brush</i></p>
  static const IconData brush = const IconData(0xe3ae);

  /// <p>Material icon "bubble chart": <i class="material-icons md-48">bubble_chart</i></p>
  static const IconData bubble_chart = const IconData(0xe6dd);

  /// <p>Material icon "bug report": <i class="material-icons md-48">bug_report</i></p>
  static const IconData bug_report = const IconData(0xe868);

  /// <p>Material icon "build": <i class="material-icons md-48">build</i></p>
  static const IconData build = const IconData(0xe869);

  /// <p>Material icon "burst mode": <i class="material-icons md-48">burst_mode</i></p>
  static const IconData burst_mode = const IconData(0xe43c);

  /// <p>Material icon "business": <i class="material-icons md-48">business</i></p>
  static const IconData business = const IconData(0xe0af);

  /// <p>Material icon "business center": <i class="material-icons md-48">business_center</i></p>
  static const IconData business_center = const IconData(0xeb3f);

  /// <p>Material icon "cached": <i class="material-icons md-48">cached</i></p>
  static const IconData cached = const IconData(0xe86a);

  /// <p>Material icon "cake": <i class="material-icons md-48">cake</i></p>
  static const IconData cake = const IconData(0xe7e9);

  /// <p>Material icon "call": <i class="material-icons md-48">call</i></p>
  static const IconData call = const IconData(0xe0b0);

  /// <p>Material icon "call end": <i class="material-icons md-48">call_end</i></p>
  static const IconData call_end = const IconData(0xe0b1);

  /// <p>Material icon "call made": <i class="material-icons md-48">call_made</i></p>
  static const IconData call_made = const IconData(0xe0b2);

  /// <p>Material icon "call merge": <i class="material-icons md-48">call_merge</i></p>
  static const IconData call_merge = const IconData(0xe0b3);

  /// <p>Material icon "call missed": <i class="material-icons md-48">call_missed</i></p>
  static const IconData call_missed = const IconData(0xe0b4);

  /// <p>Material icon "call missed outgoing": <i class="material-icons md-48">call_missed_outgoing</i></p>
  static const IconData call_missed_outgoing = const IconData(0xe0e4);

  /// <p>Material icon "call received": <i class="material-icons md-48">call_received</i></p>
  static const IconData call_received = const IconData(0xe0b5);

  /// <p>Material icon "call split": <i class="material-icons md-48">call_split</i></p>
  static const IconData call_split = const IconData(0xe0b6);

  /// <p>Material icon "call to action": <i class="material-icons md-48">call_to_action</i></p>
  static const IconData call_to_action = const IconData(0xe06c);

  /// <p>Material icon "camera": <i class="material-icons md-48">camera</i></p>
  static const IconData camera = const IconData(0xe3af);

  /// <p>Material icon "camera alt": <i class="material-icons md-48">camera_alt</i></p>
  static const IconData camera_alt = const IconData(0xe3b0);

  /// <p>Material icon "camera enhance": <i class="material-icons md-48">camera_enhance</i></p>
  static const IconData camera_enhance = const IconData(0xe8fc);

  /// <p>Material icon "camera front": <i class="material-icons md-48">camera_front</i></p>
  static const IconData camera_front = const IconData(0xe3b1);

  /// <p>Material icon "camera rear": <i class="material-icons md-48">camera_rear</i></p>
  static const IconData camera_rear = const IconData(0xe3b2);

  /// <p>Material icon "camera roll": <i class="material-icons md-48">camera_roll</i></p>
  static const IconData camera_roll = const IconData(0xe3b3);

  /// <p>Material icon "cancel": <i class="material-icons md-48">cancel</i></p>
  static const IconData cancel = const IconData(0xe5c9);

  /// <p>Material icon "card giftcard": <i class="material-icons md-48">card_giftcard</i></p>
  static const IconData card_giftcard = const IconData(0xe8f6);

  /// <p>Material icon "card membership": <i class="material-icons md-48">card_membership</i></p>
  static const IconData card_membership = const IconData(0xe8f7);

  /// <p>Material icon "card travel": <i class="material-icons md-48">card_travel</i></p>
  static const IconData card_travel = const IconData(0xe8f8);

  /// <p>Material icon "casino": <i class="material-icons md-48">casino</i></p>
  static const IconData casino = const IconData(0xeb40);

  /// <p>Material icon "cast": <i class="material-icons md-48">cast</i></p>
  static const IconData cast = const IconData(0xe307);

  /// <p>Material icon "cast connected": <i class="material-icons md-48">cast_connected</i></p>
  static const IconData cast_connected = const IconData(0xe308);

  /// <p>Material icon "center focus strong": <i class="material-icons md-48">center_focus_strong</i></p>
  static const IconData center_focus_strong = const IconData(0xe3b4);

  /// <p>Material icon "center focus weak": <i class="material-icons md-48">center_focus_weak</i></p>
  static const IconData center_focus_weak = const IconData(0xe3b5);

  /// <p>Material icon "change history": <i class="material-icons md-48">change_history</i></p>
  static const IconData change_history = const IconData(0xe86b);

  /// <p>Material icon "chat": <i class="material-icons md-48">chat</i></p>
  static const IconData chat = const IconData(0xe0b7);

  /// <p>Material icon "chat bubble": <i class="material-icons md-48">chat_bubble</i></p>
  static const IconData chat_bubble = const IconData(0xe0ca);

  /// <p>Material icon "chat bubble outline": <i class="material-icons md-48">chat_bubble_outline</i></p>
  static const IconData chat_bubble_outline = const IconData(0xe0cb);

  /// <p>Material icon "check": <i class="material-icons md-48">check</i></p>
  static const IconData check = const IconData(0xe5ca);

  /// <p>Material icon "check box": <i class="material-icons md-48">check_box</i></p>
  static const IconData check_box = const IconData(0xe834);

  /// <p>Material icon "check box outline blank": <i class="material-icons md-48">check_box_outline_blank</i></p>
  static const IconData check_box_outline_blank = const IconData(0xe835);

  /// <p>Material icon "check circle": <i class="material-icons md-48">check_circle</i></p>
  static const IconData check_circle = const IconData(0xe86c);

  /// <p>Material icon "chevron left": <i class="material-icons md-48">chevron_left</i></p>
  static const IconData chevron_left = const IconData(0xe5cb);

  /// <p>Material icon "chevron right": <i class="material-icons md-48">chevron_right</i></p>
  static const IconData chevron_right = const IconData(0xe5cc);

  /// <p>Material icon "child care": <i class="material-icons md-48">child_care</i></p>
  static const IconData child_care = const IconData(0xeb41);

  /// <p>Material icon "child friendly": <i class="material-icons md-48">child_friendly</i></p>
  static const IconData child_friendly = const IconData(0xeb42);

  /// <p>Material icon "chrome reader mode": <i class="material-icons md-48">chrome_reader_mode</i></p>
  static const IconData chrome_reader_mode = const IconData(0xe86d);

  /// <p>Material icon "class": <i class="material-icons md-48">class</i></p>
  static const IconData class_ = const IconData(0xe86e); // class is a reserved word in Dart.

  /// <p>Material icon "clear": <i class="material-icons md-48">clear</i></p>
  static const IconData clear = const IconData(0xe14c);

  /// <p>Material icon "clear all": <i class="material-icons md-48">clear_all</i></p>
  static const IconData clear_all = const IconData(0xe0b8);

  /// <p>Material icon "close": <i class="material-icons md-48">close</i></p>
  static const IconData close = const IconData(0xe5cd);

  /// <p>Material icon "closed caption": <i class="material-icons md-48">closed_caption</i></p>
  static const IconData closed_caption = const IconData(0xe01c);

  /// <p>Material icon "cloud": <i class="material-icons md-48">cloud</i></p>
  static const IconData cloud = const IconData(0xe2bd);

  /// <p>Material icon "cloud circle": <i class="material-icons md-48">cloud_circle</i></p>
  static const IconData cloud_circle = const IconData(0xe2be);

  /// <p>Material icon "cloud done": <i class="material-icons md-48">cloud_done</i></p>
  static const IconData cloud_done = const IconData(0xe2bf);

  /// <p>Material icon "cloud download": <i class="material-icons md-48">cloud_download</i></p>
  static const IconData cloud_download = const IconData(0xe2c0);

  /// <p>Material icon "cloud off": <i class="material-icons md-48">cloud_off</i></p>
  static const IconData cloud_off = const IconData(0xe2c1);

  /// <p>Material icon "cloud queue": <i class="material-icons md-48">cloud_queue</i></p>
  static const IconData cloud_queue = const IconData(0xe2c2);

  /// <p>Material icon "cloud upload": <i class="material-icons md-48">cloud_upload</i></p>
  static const IconData cloud_upload = const IconData(0xe2c3);

  /// <p>Material icon "code": <i class="material-icons md-48">code</i></p>
  static const IconData code = const IconData(0xe86f);

  /// <p>Material icon "collections": <i class="material-icons md-48">collections</i></p>
  static const IconData collections = const IconData(0xe3b6);

  /// <p>Material icon "collections bookmark": <i class="material-icons md-48">collections_bookmark</i></p>
  static const IconData collections_bookmark = const IconData(0xe431);

  /// <p>Material icon "color lens": <i class="material-icons md-48">color_lens</i></p>
  static const IconData color_lens = const IconData(0xe3b7);

  /// <p>Material icon "colorize": <i class="material-icons md-48">colorize</i></p>
  static const IconData colorize = const IconData(0xe3b8);

  /// <p>Material icon "comment": <i class="material-icons md-48">comment</i></p>
  static const IconData comment = const IconData(0xe0b9);

  /// <p>Material icon "compare": <i class="material-icons md-48">compare</i></p>
  static const IconData compare = const IconData(0xe3b9);

  /// <p>Material icon "compare arrows": <i class="material-icons md-48">compare_arrows</i></p>
  static const IconData compare_arrows = const IconData(0xe915);

  /// <p>Material icon "computer": <i class="material-icons md-48">computer</i></p>
  static const IconData computer = const IconData(0xe30a);

  /// <p>Material icon "confirmation number": <i class="material-icons md-48">confirmation_number</i></p>
  static const IconData confirmation_number = const IconData(0xe638);

  /// <p>Material icon "contact mail": <i class="material-icons md-48">contact_mail</i></p>
  static const IconData contact_mail = const IconData(0xe0d0);

  /// <p>Material icon "contact phone": <i class="material-icons md-48">contact_phone</i></p>
  static const IconData contact_phone = const IconData(0xe0cf);

  /// <p>Material icon "contacts": <i class="material-icons md-48">contacts</i></p>
  static const IconData contacts = const IconData(0xe0ba);

  /// <p>Material icon "content copy": <i class="material-icons md-48">content_copy</i></p>
  static const IconData content_copy = const IconData(0xe14d);

  /// <p>Material icon "content cut": <i class="material-icons md-48">content_cut</i></p>
  static const IconData content_cut = const IconData(0xe14e);

  /// <p>Material icon "content paste": <i class="material-icons md-48">content_paste</i></p>
  static const IconData content_paste = const IconData(0xe14f);

  /// <p>Material icon "control point": <i class="material-icons md-48">control_point</i></p>
  static const IconData control_point = const IconData(0xe3ba);

  /// <p>Material icon "control point duplicate": <i class="material-icons md-48">control_point_duplicate</i></p>
  static const IconData control_point_duplicate = const IconData(0xe3bb);

  /// <p>Material icon "copyright": <i class="material-icons md-48">copyright</i></p>
  static const IconData copyright = const IconData(0xe90c);

  /// <p>Material icon "create": <i class="material-icons md-48">create</i></p>
  static const IconData create = const IconData(0xe150);

  /// <p>Material icon "create const folder": <i class="material-icons md-48">create_const_folder</i></p>
  static const IconData create_const_folder = const IconData(0xe2cc);

  /// <p>Material icon "credit card": <i class="material-icons md-48">credit_card</i></p>
  static const IconData credit_card = const IconData(0xe870);

  /// <p>Material icon "crop": <i class="material-icons md-48">crop</i></p>
  static const IconData crop = const IconData(0xe3be);

  /// <p>Material icon "crop 16 9": <i class="material-icons md-48">crop_16_9</i></p>
  static const IconData crop_16_9 = const IconData(0xe3bc);

  /// <p>Material icon "crop 3 2": <i class="material-icons md-48">crop_3_2</i></p>
  static const IconData crop_3_2 = const IconData(0xe3bd);

  /// <p>Material icon "crop 5 4": <i class="material-icons md-48">crop_5_4</i></p>
  static const IconData crop_5_4 = const IconData(0xe3bf);

  /// <p>Material icon "crop 7 5": <i class="material-icons md-48">crop_7_5</i></p>
  static const IconData crop_7_5 = const IconData(0xe3c0);

  /// <p>Material icon "crop din": <i class="material-icons md-48">crop_din</i></p>
  static const IconData crop_din = const IconData(0xe3c1);

  /// <p>Material icon "crop free": <i class="material-icons md-48">crop_free</i></p>
  static const IconData crop_free = const IconData(0xe3c2);

  /// <p>Material icon "crop landscape": <i class="material-icons md-48">crop_landscape</i></p>
  static const IconData crop_landscape = const IconData(0xe3c3);

  /// <p>Material icon "crop original": <i class="material-icons md-48">crop_original</i></p>
  static const IconData crop_original = const IconData(0xe3c4);

  /// <p>Material icon "crop portrait": <i class="material-icons md-48">crop_portrait</i></p>
  static const IconData crop_portrait = const IconData(0xe3c5);

  /// <p>Material icon "crop rotate": <i class="material-icons md-48">crop_rotate</i></p>
  static const IconData crop_rotate = const IconData(0xe437);

  /// <p>Material icon "crop square": <i class="material-icons md-48">crop_square</i></p>
  static const IconData crop_square = const IconData(0xe3c6);

  /// <p>Material icon "dashboard": <i class="material-icons md-48">dashboard</i></p>
  static const IconData dashboard = const IconData(0xe871);

  /// <p>Material icon "data usage": <i class="material-icons md-48">data_usage</i></p>
  static const IconData data_usage = const IconData(0xe1af);

  /// <p>Material icon "date range": <i class="material-icons md-48">date_range</i></p>
  static const IconData date_range = const IconData(0xe916);

  /// <p>Material icon "dehaze": <i class="material-icons md-48">dehaze</i></p>
  static const IconData dehaze = const IconData(0xe3c7);

  /// <p>Material icon "delete": <i class="material-icons md-48">delete</i></p>
  static const IconData delete = const IconData(0xe872);

  /// <p>Material icon "delete forever": <i class="material-icons md-48">delete_forever</i></p>
  static const IconData delete_forever = const IconData(0xe92b);

  /// <p>Material icon "delete sweep": <i class="material-icons md-48">delete_sweep</i></p>
  static const IconData delete_sweep = const IconData(0xe16c);

  /// <p>Material icon "description": <i class="material-icons md-48">description</i></p>
  static const IconData description = const IconData(0xe873);

  /// <p>Material icon "desktop mac": <i class="material-icons md-48">desktop_mac</i></p>
  static const IconData desktop_mac = const IconData(0xe30b);

  /// <p>Material icon "desktop windows": <i class="material-icons md-48">desktop_windows</i></p>
  static const IconData desktop_windows = const IconData(0xe30c);

  /// <p>Material icon "details": <i class="material-icons md-48">details</i></p>
  static const IconData details = const IconData(0xe3c8);

  /// <p>Material icon "developer board": <i class="material-icons md-48">developer_board</i></p>
  static const IconData developer_board = const IconData(0xe30d);

  /// <p>Material icon "developer mode": <i class="material-icons md-48">developer_mode</i></p>
  static const IconData developer_mode = const IconData(0xe1b0);

  /// <p>Material icon "device hub": <i class="material-icons md-48">device_hub</i></p>
  static const IconData device_hub = const IconData(0xe335);

  /// <p>Material icon "devices": <i class="material-icons md-48">devices</i></p>
  static const IconData devices = const IconData(0xe1b1);

  /// <p>Material icon "devices other": <i class="material-icons md-48">devices_other</i></p>
  static const IconData devices_other = const IconData(0xe337);

  /// <p>Material icon "dialer sip": <i class="material-icons md-48">dialer_sip</i></p>
  static const IconData dialer_sip = const IconData(0xe0bb);

  /// <p>Material icon "dialpad": <i class="material-icons md-48">dialpad</i></p>
  static const IconData dialpad = const IconData(0xe0bc);

  /// <p>Material icon "directions": <i class="material-icons md-48">directions</i></p>
  static const IconData directions = const IconData(0xe52e);

  /// <p>Material icon "directions bike": <i class="material-icons md-48">directions_bike</i></p>
  static const IconData directions_bike = const IconData(0xe52f);

  /// <p>Material icon "directions boat": <i class="material-icons md-48">directions_boat</i></p>
  static const IconData directions_boat = const IconData(0xe532);

  /// <p>Material icon "directions bus": <i class="material-icons md-48">directions_bus</i></p>
  static const IconData directions_bus = const IconData(0xe530);

  /// <p>Material icon "directions car": <i class="material-icons md-48">directions_car</i></p>
  static const IconData directions_car = const IconData(0xe531);

  /// <p>Material icon "directions railway": <i class="material-icons md-48">directions_railway</i></p>
  static const IconData directions_railway = const IconData(0xe534);

  /// <p>Material icon "directions run": <i class="material-icons md-48">directions_run</i></p>
  static const IconData directions_run = const IconData(0xe566);

  /// <p>Material icon "directions subway": <i class="material-icons md-48">directions_subway</i></p>
  static const IconData directions_subway = const IconData(0xe533);

  /// <p>Material icon "directions transit": <i class="material-icons md-48">directions_transit</i></p>
  static const IconData directions_transit = const IconData(0xe535);

  /// <p>Material icon "directions walk": <i class="material-icons md-48">directions_walk</i></p>
  static const IconData directions_walk = const IconData(0xe536);

  /// <p>Material icon "disc full": <i class="material-icons md-48">disc_full</i></p>
  static const IconData disc_full = const IconData(0xe610);

  /// <p>Material icon "dns": <i class="material-icons md-48">dns</i></p>
  static const IconData dns = const IconData(0xe875);

  /// <p>Material icon "do not disturb": <i class="material-icons md-48">do_not_disturb</i></p>
  static const IconData do_not_disturb = const IconData(0xe612);

  /// <p>Material icon "do not disturb alt": <i class="material-icons md-48">do_not_disturb_alt</i></p>
  static const IconData do_not_disturb_alt = const IconData(0xe611);

  /// <p>Material icon "do not disturb off": <i class="material-icons md-48">do_not_disturb_off</i></p>
  static const IconData do_not_disturb_off = const IconData(0xe643);

  /// <p>Material icon "do not disturb on": <i class="material-icons md-48">do_not_disturb_on</i></p>
  static const IconData do_not_disturb_on = const IconData(0xe644);

  /// <p>Material icon "dock": <i class="material-icons md-48">dock</i></p>
  static const IconData dock = const IconData(0xe30e);

  /// <p>Material icon "domain": <i class="material-icons md-48">domain</i></p>
  static const IconData domain = const IconData(0xe7ee);

  /// <p>Material icon "done": <i class="material-icons md-48">done</i></p>
  static const IconData done = const IconData(0xe876);

  /// <p>Material icon "done all": <i class="material-icons md-48">done_all</i></p>
  static const IconData done_all = const IconData(0xe877);

  /// <p>Material icon "donut large": <i class="material-icons md-48">donut_large</i></p>
  static const IconData donut_large = const IconData(0xe917);

  /// <p>Material icon "donut small": <i class="material-icons md-48">donut_small</i></p>
  static const IconData donut_small = const IconData(0xe918);

  /// <p>Material icon "drafts": <i class="material-icons md-48">drafts</i></p>
  static const IconData drafts = const IconData(0xe151);

  /// <p>Material icon "drag handle": <i class="material-icons md-48">drag_handle</i></p>
  static const IconData drag_handle = const IconData(0xe25d);

  /// <p>Material icon "drive eta": <i class="material-icons md-48">drive_eta</i></p>
  static const IconData drive_eta = const IconData(0xe613);

  /// <p>Material icon "dvr": <i class="material-icons md-48">dvr</i></p>
  static const IconData dvr = const IconData(0xe1b2);

  /// <p>Material icon "edit": <i class="material-icons md-48">edit</i></p>
  static const IconData edit = const IconData(0xe3c9);

  /// <p>Material icon "edit location": <i class="material-icons md-48">edit_location</i></p>
  static const IconData edit_location = const IconData(0xe568);

  /// <p>Material icon "eject": <i class="material-icons md-48">eject</i></p>
  static const IconData eject = const IconData(0xe8fb);

  /// <p>Material icon "email": <i class="material-icons md-48">email</i></p>
  static const IconData email = const IconData(0xe0be);

  /// <p>Material icon "enhanced encryption": <i class="material-icons md-48">enhanced_encryption</i></p>
  static const IconData enhanced_encryption = const IconData(0xe63f);

  /// <p>Material icon "equalizer": <i class="material-icons md-48">equalizer</i></p>
  static const IconData equalizer = const IconData(0xe01d);

  /// <p>Material icon "error": <i class="material-icons md-48">error</i></p>
  static const IconData error = const IconData(0xe000);

  /// <p>Material icon "error outline": <i class="material-icons md-48">error_outline</i></p>
  static const IconData error_outline = const IconData(0xe001);

  /// <p>Material icon "euro symbol": <i class="material-icons md-48">euro_symbol</i></p>
  static const IconData euro_symbol = const IconData(0xe926);

  /// <p>Material icon "ev station": <i class="material-icons md-48">ev_station</i></p>
  static const IconData ev_station = const IconData(0xe56d);

  /// <p>Material icon "event": <i class="material-icons md-48">event</i></p>
  static const IconData event = const IconData(0xe878);

  /// <p>Material icon "event available": <i class="material-icons md-48">event_available</i></p>
  static const IconData event_available = const IconData(0xe614);

  /// <p>Material icon "event busy": <i class="material-icons md-48">event_busy</i></p>
  static const IconData event_busy = const IconData(0xe615);

  /// <p>Material icon "event note": <i class="material-icons md-48">event_note</i></p>
  static const IconData event_note = const IconData(0xe616);

  /// <p>Material icon "event seat": <i class="material-icons md-48">event_seat</i></p>
  static const IconData event_seat = const IconData(0xe903);

  /// <p>Material icon "exit to app": <i class="material-icons md-48">exit_to_app</i></p>
  static const IconData exit_to_app = const IconData(0xe879);

  /// <p>Material icon "expand less": <i class="material-icons md-48">expand_less</i></p>
  static const IconData expand_less = const IconData(0xe5ce);

  /// <p>Material icon "expand more": <i class="material-icons md-48">expand_more</i></p>
  static const IconData expand_more = const IconData(0xe5cf);

  /// <p>Material icon "explicit": <i class="material-icons md-48">explicit</i></p>
  static const IconData explicit = const IconData(0xe01e);

  /// <p>Material icon "explore": <i class="material-icons md-48">explore</i></p>
  static const IconData explore = const IconData(0xe87a);

  /// <p>Material icon "exposure": <i class="material-icons md-48">exposure</i></p>
  static const IconData exposure = const IconData(0xe3ca);

  /// <p>Material icon "exposure neg 1": <i class="material-icons md-48">exposure_neg_1</i></p>
  static const IconData exposure_neg_1 = const IconData(0xe3cb);

  /// <p>Material icon "exposure neg 2": <i class="material-icons md-48">exposure_neg_2</i></p>
  static const IconData exposure_neg_2 = const IconData(0xe3cc);

  /// <p>Material icon "exposure plus 1": <i class="material-icons md-48">exposure_plus_1</i></p>
  static const IconData exposure_plus_1 = const IconData(0xe3cd);

  /// <p>Material icon "exposure plus 2": <i class="material-icons md-48">exposure_plus_2</i></p>
  static const IconData exposure_plus_2 = const IconData(0xe3ce);

  /// <p>Material icon "exposure zero": <i class="material-icons md-48">exposure_zero</i></p>
  static const IconData exposure_zero = const IconData(0xe3cf);

  /// <p>Material icon "extension": <i class="material-icons md-48">extension</i></p>
  static const IconData extension = const IconData(0xe87b);

  /// <p>Material icon "face": <i class="material-icons md-48">face</i></p>
  static const IconData face = const IconData(0xe87c);

  /// <p>Material icon "fast forward": <i class="material-icons md-48">fast_forward</i></p>
  static const IconData fast_forward = const IconData(0xe01f);

  /// <p>Material icon "fast rewind": <i class="material-icons md-48">fast_rewind</i></p>
  static const IconData fast_rewind = const IconData(0xe020);

  /// <p>Material icon "favorite": <i class="material-icons md-48">favorite</i></p>
  static const IconData favorite = const IconData(0xe87d);

  /// <p>Material icon "favorite border": <i class="material-icons md-48">favorite_border</i></p>
  static const IconData favorite_border = const IconData(0xe87e);

  /// <p>Material icon "featured play list": <i class="material-icons md-48">featured_play_list</i></p>
  static const IconData featured_play_list = const IconData(0xe06d);

  /// <p>Material icon "featured video": <i class="material-icons md-48">featured_video</i></p>
  static const IconData featured_video = const IconData(0xe06e);

  /// <p>Material icon "feedback": <i class="material-icons md-48">feedback</i></p>
  static const IconData feedback = const IconData(0xe87f);

  /// <p>Material icon "fiber dvr": <i class="material-icons md-48">fiber_dvr</i></p>
  static const IconData fiber_dvr = const IconData(0xe05d);

  /// <p>Material icon "fiber manual record": <i class="material-icons md-48">fiber_manual_record</i></p>
  static const IconData fiber_manual_record = const IconData(0xe061);

  /// <p>Material icon "fiber const": <i class="material-icons md-48">fiber_const</i></p>
  static const IconData fiber_const = const IconData(0xe05e);

  /// <p>Material icon "fiber pin": <i class="material-icons md-48">fiber_pin</i></p>
  static const IconData fiber_pin = const IconData(0xe06a);

  /// <p>Material icon "fiber smart record": <i class="material-icons md-48">fiber_smart_record</i></p>
  static const IconData fiber_smart_record = const IconData(0xe062);

  /// <p>Material icon "file download": <i class="material-icons md-48">file_download</i></p>
  static const IconData file_download = const IconData(0xe2c4);

  /// <p>Material icon "file upload": <i class="material-icons md-48">file_upload</i></p>
  static const IconData file_upload = const IconData(0xe2c6);

  /// <p>Material icon "filter": <i class="material-icons md-48">filter</i></p>
  static const IconData filter = const IconData(0xe3d3);

  /// <p>Material icon "filter 1": <i class="material-icons md-48">filter_1</i></p>
  static const IconData filter_1 = const IconData(0xe3d0);

  /// <p>Material icon "filter 2": <i class="material-icons md-48">filter_2</i></p>
  static const IconData filter_2 = const IconData(0xe3d1);

  /// <p>Material icon "filter 3": <i class="material-icons md-48">filter_3</i></p>
  static const IconData filter_3 = const IconData(0xe3d2);

  /// <p>Material icon "filter 4": <i class="material-icons md-48">filter_4</i></p>
  static const IconData filter_4 = const IconData(0xe3d4);

  /// <p>Material icon "filter 5": <i class="material-icons md-48">filter_5</i></p>
  static const IconData filter_5 = const IconData(0xe3d5);

  /// <p>Material icon "filter 6": <i class="material-icons md-48">filter_6</i></p>
  static const IconData filter_6 = const IconData(0xe3d6);

  /// <p>Material icon "filter 7": <i class="material-icons md-48">filter_7</i></p>
  static const IconData filter_7 = const IconData(0xe3d7);

  /// <p>Material icon "filter 8": <i class="material-icons md-48">filter_8</i></p>
  static const IconData filter_8 = const IconData(0xe3d8);

  /// <p>Material icon "filter 9": <i class="material-icons md-48">filter_9</i></p>
  static const IconData filter_9 = const IconData(0xe3d9);

  /// <p>Material icon "filter 9 plus": <i class="material-icons md-48">filter_9_plus</i></p>
  static const IconData filter_9_plus = const IconData(0xe3da);

  /// <p>Material icon "filter b and w": <i class="material-icons md-48">filter_b_and_w</i></p>
  static const IconData filter_b_and_w = const IconData(0xe3db);

  /// <p>Material icon "filter center focus": <i class="material-icons md-48">filter_center_focus</i></p>
  static const IconData filter_center_focus = const IconData(0xe3dc);

  /// <p>Material icon "filter drama": <i class="material-icons md-48">filter_drama</i></p>
  static const IconData filter_drama = const IconData(0xe3dd);

  /// <p>Material icon "filter frames": <i class="material-icons md-48">filter_frames</i></p>
  static const IconData filter_frames = const IconData(0xe3de);

  /// <p>Material icon "filter hdr": <i class="material-icons md-48">filter_hdr</i></p>
  static const IconData filter_hdr = const IconData(0xe3df);

  /// <p>Material icon "filter list": <i class="material-icons md-48">filter_list</i></p>
  static const IconData filter_list = const IconData(0xe152);

  /// <p>Material icon "filter none": <i class="material-icons md-48">filter_none</i></p>
  static const IconData filter_none = const IconData(0xe3e0);

  /// <p>Material icon "filter tilt shift": <i class="material-icons md-48">filter_tilt_shift</i></p>
  static const IconData filter_tilt_shift = const IconData(0xe3e2);

  /// <p>Material icon "filter vintage": <i class="material-icons md-48">filter_vintage</i></p>
  static const IconData filter_vintage = const IconData(0xe3e3);

  /// <p>Material icon "find in page": <i class="material-icons md-48">find_in_page</i></p>
  static const IconData find_in_page = const IconData(0xe880);

  /// <p>Material icon "find replace": <i class="material-icons md-48">find_replace</i></p>
  static const IconData find_replace = const IconData(0xe881);

  /// <p>Material icon "fingerprint": <i class="material-icons md-48">fingerprint</i></p>
  static const IconData fingerprint = const IconData(0xe90d);

  /// <p>Material icon "first page": <i class="material-icons md-48">first_page</i></p>
  static const IconData first_page = const IconData(0xe5dc);

  /// <p>Material icon "fitness center": <i class="material-icons md-48">fitness_center</i></p>
  static const IconData fitness_center = const IconData(0xeb43);

  /// <p>Material icon "flag": <i class="material-icons md-48">flag</i></p>
  static const IconData flag = const IconData(0xe153);

  /// <p>Material icon "flare": <i class="material-icons md-48">flare</i></p>
  static const IconData flare = const IconData(0xe3e4);

  /// <p>Material icon "flash auto": <i class="material-icons md-48">flash_auto</i></p>
  static const IconData flash_auto = const IconData(0xe3e5);

  /// <p>Material icon "flash off": <i class="material-icons md-48">flash_off</i></p>
  static const IconData flash_off = const IconData(0xe3e6);

  /// <p>Material icon "flash on": <i class="material-icons md-48">flash_on</i></p>
  static const IconData flash_on = const IconData(0xe3e7);

  /// <p>Material icon "flight": <i class="material-icons md-48">flight</i></p>
  static const IconData flight = const IconData(0xe539);

  /// <p>Material icon "flight land": <i class="material-icons md-48">flight_land</i></p>
  static const IconData flight_land = const IconData(0xe904);

  /// <p>Material icon "flight takeoff": <i class="material-icons md-48">flight_takeoff</i></p>
  static const IconData flight_takeoff = const IconData(0xe905);

  /// <p>Material icon "flip": <i class="material-icons md-48">flip</i></p>
  static const IconData flip = const IconData(0xe3e8);

  /// <p>Material icon "flip to back": <i class="material-icons md-48">flip_to_back</i></p>
  static const IconData flip_to_back = const IconData(0xe882);

  /// <p>Material icon "flip to front": <i class="material-icons md-48">flip_to_front</i></p>
  static const IconData flip_to_front = const IconData(0xe883);

  /// <p>Material icon "folder": <i class="material-icons md-48">folder</i></p>
  static const IconData folder = const IconData(0xe2c7);

  /// <p>Material icon "folder open": <i class="material-icons md-48">folder_open</i></p>
  static const IconData folder_open = const IconData(0xe2c8);

  /// <p>Material icon "folder shared": <i class="material-icons md-48">folder_shared</i></p>
  static const IconData folder_shared = const IconData(0xe2c9);

  /// <p>Material icon "folder special": <i class="material-icons md-48">folder_special</i></p>
  static const IconData folder_special = const IconData(0xe617);

  /// <p>Material icon "font download": <i class="material-icons md-48">font_download</i></p>
  static const IconData font_download = const IconData(0xe167);

  /// <p>Material icon "format align center": <i class="material-icons md-48">format_align_center</i></p>
  static const IconData format_align_center = const IconData(0xe234);

  /// <p>Material icon "format align justify": <i class="material-icons md-48">format_align_justify</i></p>
  static const IconData format_align_justify = const IconData(0xe235);

  /// <p>Material icon "format align left": <i class="material-icons md-48">format_align_left</i></p>
  static const IconData format_align_left = const IconData(0xe236);

  /// <p>Material icon "format align right": <i class="material-icons md-48">format_align_right</i></p>
  static const IconData format_align_right = const IconData(0xe237);

  /// <p>Material icon "format bold": <i class="material-icons md-48">format_bold</i></p>
  static const IconData format_bold = const IconData(0xe238);

  /// <p>Material icon "format clear": <i class="material-icons md-48">format_clear</i></p>
  static const IconData format_clear = const IconData(0xe239);

  /// <p>Material icon "format color fill": <i class="material-icons md-48">format_color_fill</i></p>
  static const IconData format_color_fill = const IconData(0xe23a);

  /// <p>Material icon "format color reset": <i class="material-icons md-48">format_color_reset</i></p>
  static const IconData format_color_reset = const IconData(0xe23b);

  /// <p>Material icon "format color text": <i class="material-icons md-48">format_color_text</i></p>
  static const IconData format_color_text = const IconData(0xe23c);

  /// <p>Material icon "format indent decrease": <i class="material-icons md-48">format_indent_decrease</i></p>
  static const IconData format_indent_decrease = const IconData(0xe23d);

  /// <p>Material icon "format indent increase": <i class="material-icons md-48">format_indent_increase</i></p>
  static const IconData format_indent_increase = const IconData(0xe23e);

  /// <p>Material icon "format italic": <i class="material-icons md-48">format_italic</i></p>
  static const IconData format_italic = const IconData(0xe23f);

  /// <p>Material icon "format line spacing": <i class="material-icons md-48">format_line_spacing</i></p>
  static const IconData format_line_spacing = const IconData(0xe240);

  /// <p>Material icon "format list bulleted": <i class="material-icons md-48">format_list_bulleted</i></p>
  static const IconData format_list_bulleted = const IconData(0xe241);

  /// <p>Material icon "format list numbered": <i class="material-icons md-48">format_list_numbered</i></p>
  static const IconData format_list_numbered = const IconData(0xe242);

  /// <p>Material icon "format paint": <i class="material-icons md-48">format_paint</i></p>
  static const IconData format_paint = const IconData(0xe243);

  /// <p>Material icon "format quote": <i class="material-icons md-48">format_quote</i></p>
  static const IconData format_quote = const IconData(0xe244);

  /// <p>Material icon "format shapes": <i class="material-icons md-48">format_shapes</i></p>
  static const IconData format_shapes = const IconData(0xe25e);

  /// <p>Material icon "format size": <i class="material-icons md-48">format_size</i></p>
  static const IconData format_size = const IconData(0xe245);

  /// <p>Material icon "format strikethrough": <i class="material-icons md-48">format_strikethrough</i></p>
  static const IconData format_strikethrough = const IconData(0xe246);

  /// <p>Material icon "format textdirection l to r": <i class="material-icons md-48">format_textdirection_l_to_r</i></p>
  static const IconData format_textdirection_l_to_r = const IconData(0xe247);

  /// <p>Material icon "format textdirection r to l": <i class="material-icons md-48">format_textdirection_r_to_l</i></p>
  static const IconData format_textdirection_r_to_l = const IconData(0xe248);

  /// <p>Material icon "format underlined": <i class="material-icons md-48">format_underlined</i></p>
  static const IconData format_underlined = const IconData(0xe249);

  /// <p>Material icon "forum": <i class="material-icons md-48">forum</i></p>
  static const IconData forum = const IconData(0xe0bf);

  /// <p>Material icon "forward": <i class="material-icons md-48">forward</i></p>
  static const IconData forward = const IconData(0xe154);

  /// <p>Material icon "forward 10": <i class="material-icons md-48">forward_10</i></p>
  static const IconData forward_10 = const IconData(0xe056);

  /// <p>Material icon "forward 30": <i class="material-icons md-48">forward_30</i></p>
  static const IconData forward_30 = const IconData(0xe057);

  /// <p>Material icon "forward 5": <i class="material-icons md-48">forward_5</i></p>
  static const IconData forward_5 = const IconData(0xe058);

  /// <p>Material icon "free breakfast": <i class="material-icons md-48">free_breakfast</i></p>
  static const IconData free_breakfast = const IconData(0xeb44);

  /// <p>Material icon "fullscreen": <i class="material-icons md-48">fullscreen</i></p>
  static const IconData fullscreen = const IconData(0xe5d0);

  /// <p>Material icon "fullscreen exit": <i class="material-icons md-48">fullscreen_exit</i></p>
  static const IconData fullscreen_exit = const IconData(0xe5d1);

  /// <p>Material icon "functions": <i class="material-icons md-48">functions</i></p>
  static const IconData functions = const IconData(0xe24a);

  /// <p>Material icon "g translate": <i class="material-icons md-48">g_translate</i></p>
  static const IconData g_translate = const IconData(0xe927);

  /// <p>Material icon "gamepad": <i class="material-icons md-48">gamepad</i></p>
  static const IconData gamepad = const IconData(0xe30f);

  /// <p>Material icon "games": <i class="material-icons md-48">games</i></p>
  static const IconData games = const IconData(0xe021);

  /// <p>Material icon "gavel": <i class="material-icons md-48">gavel</i></p>
  static const IconData gavel = const IconData(0xe90e);

  /// <p>Material icon "gesture": <i class="material-icons md-48">gesture</i></p>
  static const IconData gesture = const IconData(0xe155);

  /// <p>Material icon "get app": <i class="material-icons md-48">get_app</i></p>
  static const IconData get_app = const IconData(0xe884);

  /// <p>Material icon "gif": <i class="material-icons md-48">gif</i></p>
  static const IconData gif = const IconData(0xe908);

  /// <p>Material icon "golf course": <i class="material-icons md-48">golf_course</i></p>
  static const IconData golf_course = const IconData(0xeb45);

  /// <p>Material icon "gps fixed": <i class="material-icons md-48">gps_fixed</i></p>
  static const IconData gps_fixed = const IconData(0xe1b3);

  /// <p>Material icon "gps not fixed": <i class="material-icons md-48">gps_not_fixed</i></p>
  static const IconData gps_not_fixed = const IconData(0xe1b4);

  /// <p>Material icon "gps off": <i class="material-icons md-48">gps_off</i></p>
  static const IconData gps_off = const IconData(0xe1b5);

  /// <p>Material icon "grade": <i class="material-icons md-48">grade</i></p>
  static const IconData grade = const IconData(0xe885);

  /// <p>Material icon "gradient": <i class="material-icons md-48">gradient</i></p>
  static const IconData gradient = const IconData(0xe3e9);

  /// <p>Material icon "grain": <i class="material-icons md-48">grain</i></p>
  static const IconData grain = const IconData(0xe3ea);

  /// <p>Material icon "graphic eq": <i class="material-icons md-48">graphic_eq</i></p>
  static const IconData graphic_eq = const IconData(0xe1b8);

  /// <p>Material icon "grid off": <i class="material-icons md-48">grid_off</i></p>
  static const IconData grid_off = const IconData(0xe3eb);

  /// <p>Material icon "grid on": <i class="material-icons md-48">grid_on</i></p>
  static const IconData grid_on = const IconData(0xe3ec);

  /// <p>Material icon "group": <i class="material-icons md-48">group</i></p>
  static const IconData group = const IconData(0xe7ef);

  /// <p>Material icon "group add": <i class="material-icons md-48">group_add</i></p>
  static const IconData group_add = const IconData(0xe7f0);

  /// <p>Material icon "group work": <i class="material-icons md-48">group_work</i></p>
  static const IconData group_work = const IconData(0xe886);

  /// <p>Material icon "hd": <i class="material-icons md-48">hd</i></p>
  static const IconData hd = const IconData(0xe052);

  /// <p>Material icon "hdr off": <i class="material-icons md-48">hdr_off</i></p>
  static const IconData hdr_off = const IconData(0xe3ed);

  /// <p>Material icon "hdr on": <i class="material-icons md-48">hdr_on</i></p>
  static const IconData hdr_on = const IconData(0xe3ee);

  /// <p>Material icon "hdr strong": <i class="material-icons md-48">hdr_strong</i></p>
  static const IconData hdr_strong = const IconData(0xe3f1);

  /// <p>Material icon "hdr weak": <i class="material-icons md-48">hdr_weak</i></p>
  static const IconData hdr_weak = const IconData(0xe3f2);

  /// <p>Material icon "headset": <i class="material-icons md-48">headset</i></p>
  static const IconData headset = const IconData(0xe310);

  /// <p>Material icon "headset mic": <i class="material-icons md-48">headset_mic</i></p>
  static const IconData headset_mic = const IconData(0xe311);

  /// <p>Material icon "healing": <i class="material-icons md-48">healing</i></p>
  static const IconData healing = const IconData(0xe3f3);

  /// <p>Material icon "hearing": <i class="material-icons md-48">hearing</i></p>
  static const IconData hearing = const IconData(0xe023);

  /// <p>Material icon "help": <i class="material-icons md-48">help</i></p>
  static const IconData help = const IconData(0xe887);

  /// <p>Material icon "help outline": <i class="material-icons md-48">help_outline</i></p>
  static const IconData help_outline = const IconData(0xe8fd);

  /// <p>Material icon "high quality": <i class="material-icons md-48">high_quality</i></p>
  static const IconData high_quality = const IconData(0xe024);

  /// <p>Material icon "highlight": <i class="material-icons md-48">highlight</i></p>
  static const IconData highlight = const IconData(0xe25f);

  /// <p>Material icon "highlight off": <i class="material-icons md-48">highlight_off</i></p>
  static const IconData highlight_off = const IconData(0xe888);

  /// <p>Material icon "history": <i class="material-icons md-48">history</i></p>
  static const IconData history = const IconData(0xe889);

  /// <p>Material icon "home": <i class="material-icons md-48">home</i></p>
  static const IconData home = const IconData(0xe88a);

  /// <p>Material icon "hot tub": <i class="material-icons md-48">hot_tub</i></p>
  static const IconData hot_tub = const IconData(0xeb46);

  /// <p>Material icon "hotel": <i class="material-icons md-48">hotel</i></p>
  static const IconData hotel = const IconData(0xe53a);

  /// <p>Material icon "hourglass empty": <i class="material-icons md-48">hourglass_empty</i></p>
  static const IconData hourglass_empty = const IconData(0xe88b);

  /// <p>Material icon "hourglass full": <i class="material-icons md-48">hourglass_full</i></p>
  static const IconData hourglass_full = const IconData(0xe88c);

  /// <p>Material icon "http": <i class="material-icons md-48">http</i></p>
  static const IconData http = const IconData(0xe902);

  /// <p>Material icon "https": <i class="material-icons md-48">https</i></p>
  static const IconData https = const IconData(0xe88d);

  /// <p>Material icon "image": <i class="material-icons md-48">image</i></p>
  static const IconData image = const IconData(0xe3f4);

  /// <p>Material icon "image aspect ratio": <i class="material-icons md-48">image_aspect_ratio</i></p>
  static const IconData image_aspect_ratio = const IconData(0xe3f5);

  /// <p>Material icon "import contacts": <i class="material-icons md-48">import_contacts</i></p>
  static const IconData import_contacts = const IconData(0xe0e0);

  /// <p>Material icon "import export": <i class="material-icons md-48">import_export</i></p>
  static const IconData import_export = const IconData(0xe0c3);

  /// <p>Material icon "important devices": <i class="material-icons md-48">important_devices</i></p>
  static const IconData important_devices = const IconData(0xe912);

  /// <p>Material icon "inbox": <i class="material-icons md-48">inbox</i></p>
  static const IconData inbox = const IconData(0xe156);

  /// <p>Material icon "indeterminate check box": <i class="material-icons md-48">indeterminate_check_box</i></p>
  static const IconData indeterminate_check_box = const IconData(0xe909);

  /// <p>Material icon "info": <i class="material-icons md-48">info</i></p>
  static const IconData info = const IconData(0xe88e);

  /// <p>Material icon "info outline": <i class="material-icons md-48">info_outline</i></p>
  static const IconData info_outline = const IconData(0xe88f);

  /// <p>Material icon "input": <i class="material-icons md-48">input</i></p>
  static const IconData input = const IconData(0xe890);

  /// <p>Material icon "insert chart": <i class="material-icons md-48">insert_chart</i></p>
  static const IconData insert_chart = const IconData(0xe24b);

  /// <p>Material icon "insert comment": <i class="material-icons md-48">insert_comment</i></p>
  static const IconData insert_comment = const IconData(0xe24c);

  /// <p>Material icon "insert drive file": <i class="material-icons md-48">insert_drive_file</i></p>
  static const IconData insert_drive_file = const IconData(0xe24d);

  /// <p>Material icon "insert emoticon": <i class="material-icons md-48">insert_emoticon</i></p>
  static const IconData insert_emoticon = const IconData(0xe24e);

  /// <p>Material icon "insert invitation": <i class="material-icons md-48">insert_invitation</i></p>
  static const IconData insert_invitation = const IconData(0xe24f);

  /// <p>Material icon "insert link": <i class="material-icons md-48">insert_link</i></p>
  static const IconData insert_link = const IconData(0xe250);

  /// <p>Material icon "insert photo": <i class="material-icons md-48">insert_photo</i></p>
  static const IconData insert_photo = const IconData(0xe251);

  /// <p>Material icon "invert colors": <i class="material-icons md-48">invert_colors</i></p>
  static const IconData invert_colors = const IconData(0xe891);

  /// <p>Material icon "invert colors off": <i class="material-icons md-48">invert_colors_off</i></p>
  static const IconData invert_colors_off = const IconData(0xe0c4);

  /// <p>Material icon "iso": <i class="material-icons md-48">iso</i></p>
  static const IconData iso = const IconData(0xe3f6);

  /// <p>Material icon "keyboard": <i class="material-icons md-48">keyboard</i></p>
  static const IconData keyboard = const IconData(0xe312);

  /// <p>Material icon "keyboard arrow down": <i class="material-icons md-48">keyboard_arrow_down</i></p>
  static const IconData keyboard_arrow_down = const IconData(0xe313);

  /// <p>Material icon "keyboard arrow left": <i class="material-icons md-48">keyboard_arrow_left</i></p>
  static const IconData keyboard_arrow_left = const IconData(0xe314);

  /// <p>Material icon "keyboard arrow right": <i class="material-icons md-48">keyboard_arrow_right</i></p>
  static const IconData keyboard_arrow_right = const IconData(0xe315);

  /// <p>Material icon "keyboard arrow up": <i class="material-icons md-48">keyboard_arrow_up</i></p>
  static const IconData keyboard_arrow_up = const IconData(0xe316);

  /// <p>Material icon "keyboard backspace": <i class="material-icons md-48">keyboard_backspace</i></p>
  static const IconData keyboard_backspace = const IconData(0xe317);

  /// <p>Material icon "keyboard capslock": <i class="material-icons md-48">keyboard_capslock</i></p>
  static const IconData keyboard_capslock = const IconData(0xe318);

  /// <p>Material icon "keyboard hide": <i class="material-icons md-48">keyboard_hide</i></p>
  static const IconData keyboard_hide = const IconData(0xe31a);

  /// <p>Material icon "keyboard return": <i class="material-icons md-48">keyboard_return</i></p>
  static const IconData keyboard_return = const IconData(0xe31b);

  /// <p>Material icon "keyboard tab": <i class="material-icons md-48">keyboard_tab</i></p>
  static const IconData keyboard_tab = const IconData(0xe31c);

  /// <p>Material icon "keyboard voice": <i class="material-icons md-48">keyboard_voice</i></p>
  static const IconData keyboard_voice = const IconData(0xe31d);

  /// <p>Material icon "kitchen": <i class="material-icons md-48">kitchen</i></p>
  static const IconData kitchen = const IconData(0xeb47);

  /// <p>Material icon "label": <i class="material-icons md-48">label</i></p>
  static const IconData label = const IconData(0xe892);

  /// <p>Material icon "label outline": <i class="material-icons md-48">label_outline</i></p>
  static const IconData label_outline = const IconData(0xe893);

  /// <p>Material icon "landscape": <i class="material-icons md-48">landscape</i></p>
  static const IconData landscape = const IconData(0xe3f7);

  /// <p>Material icon "language": <i class="material-icons md-48">language</i></p>
  static const IconData language = const IconData(0xe894);

  /// <p>Material icon "laptop": <i class="material-icons md-48">laptop</i></p>
  static const IconData laptop = const IconData(0xe31e);

  /// <p>Material icon "laptop chromebook": <i class="material-icons md-48">laptop_chromebook</i></p>
  static const IconData laptop_chromebook = const IconData(0xe31f);

  /// <p>Material icon "laptop mac": <i class="material-icons md-48">laptop_mac</i></p>
  static const IconData laptop_mac = const IconData(0xe320);

  /// <p>Material icon "laptop windows": <i class="material-icons md-48">laptop_windows</i></p>
  static const IconData laptop_windows = const IconData(0xe321);

  /// <p>Material icon "last page": <i class="material-icons md-48">last_page</i></p>
  static const IconData last_page = const IconData(0xe5dd);

  /// <p>Material icon "launch": <i class="material-icons md-48">launch</i></p>
  static const IconData launch = const IconData(0xe895);

  /// <p>Material icon "layers": <i class="material-icons md-48">layers</i></p>
  static const IconData layers = const IconData(0xe53b);

  /// <p>Material icon "layers clear": <i class="material-icons md-48">layers_clear</i></p>
  static const IconData layers_clear = const IconData(0xe53c);

  /// <p>Material icon "leak add": <i class="material-icons md-48">leak_add</i></p>
  static const IconData leak_add = const IconData(0xe3f8);

  /// <p>Material icon "leak remove": <i class="material-icons md-48">leak_remove</i></p>
  static const IconData leak_remove = const IconData(0xe3f9);

  /// <p>Material icon "lens": <i class="material-icons md-48">lens</i></p>
  static const IconData lens = const IconData(0xe3fa);

  /// <p>Material icon "library add": <i class="material-icons md-48">library_add</i></p>
  static const IconData library_add = const IconData(0xe02e);

  /// <p>Material icon "library books": <i class="material-icons md-48">library_books</i></p>
  static const IconData library_books = const IconData(0xe02f);

  /// <p>Material icon "library music": <i class="material-icons md-48">library_music</i></p>
  static const IconData library_music = const IconData(0xe030);

  /// <p>Material icon "lightbulb outline": <i class="material-icons md-48">lightbulb_outline</i></p>
  static const IconData lightbulb_outline = const IconData(0xe90f);

  /// <p>Material icon "line style": <i class="material-icons md-48">line_style</i></p>
  static const IconData line_style = const IconData(0xe919);

  /// <p>Material icon "line weight": <i class="material-icons md-48">line_weight</i></p>
  static const IconData line_weight = const IconData(0xe91a);

  /// <p>Material icon "linear scale": <i class="material-icons md-48">linear_scale</i></p>
  static const IconData linear_scale = const IconData(0xe260);

  /// <p>Material icon "link": <i class="material-icons md-48">link</i></p>
  static const IconData link = const IconData(0xe157);

  /// <p>Material icon "linked camera": <i class="material-icons md-48">linked_camera</i></p>
  static const IconData linked_camera = const IconData(0xe438);

  /// <p>Material icon "list": <i class="material-icons md-48">list</i></p>
  static const IconData list = const IconData(0xe896);

  /// <p>Material icon "live help": <i class="material-icons md-48">live_help</i></p>
  static const IconData live_help = const IconData(0xe0c6);

  /// <p>Material icon "live tv": <i class="material-icons md-48">live_tv</i></p>
  static const IconData live_tv = const IconData(0xe639);

  /// <p>Material icon "local activity": <i class="material-icons md-48">local_activity</i></p>
  static const IconData local_activity = const IconData(0xe53f);

  /// <p>Material icon "local airport": <i class="material-icons md-48">local_airport</i></p>
  static const IconData local_airport = const IconData(0xe53d);

  /// <p>Material icon "local atm": <i class="material-icons md-48">local_atm</i></p>
  static const IconData local_atm = const IconData(0xe53e);

  /// <p>Material icon "local bar": <i class="material-icons md-48">local_bar</i></p>
  static const IconData local_bar = const IconData(0xe540);

  /// <p>Material icon "local cafe": <i class="material-icons md-48">local_cafe</i></p>
  static const IconData local_cafe = const IconData(0xe541);

  /// <p>Material icon "local car wash": <i class="material-icons md-48">local_car_wash</i></p>
  static const IconData local_car_wash = const IconData(0xe542);

  /// <p>Material icon "local convenience store": <i class="material-icons md-48">local_convenience_store</i></p>
  static const IconData local_convenience_store = const IconData(0xe543);

  /// <p>Material icon "local dining": <i class="material-icons md-48">local_dining</i></p>
  static const IconData local_dining = const IconData(0xe556);

  /// <p>Material icon "local drink": <i class="material-icons md-48">local_drink</i></p>
  static const IconData local_drink = const IconData(0xe544);

  /// <p>Material icon "local florist": <i class="material-icons md-48">local_florist</i></p>
  static const IconData local_florist = const IconData(0xe545);

  /// <p>Material icon "local gas station": <i class="material-icons md-48">local_gas_station</i></p>
  static const IconData local_gas_station = const IconData(0xe546);

  /// <p>Material icon "local grocery store": <i class="material-icons md-48">local_grocery_store</i></p>
  static const IconData local_grocery_store = const IconData(0xe547);

  /// <p>Material icon "local hospital": <i class="material-icons md-48">local_hospital</i></p>
  static const IconData local_hospital = const IconData(0xe548);

  /// <p>Material icon "local hotel": <i class="material-icons md-48">local_hotel</i></p>
  static const IconData local_hotel = const IconData(0xe549);

  /// <p>Material icon "local laundry service": <i class="material-icons md-48">local_laundry_service</i></p>
  static const IconData local_laundry_service = const IconData(0xe54a);

  /// <p>Material icon "local library": <i class="material-icons md-48">local_library</i></p>
  static const IconData local_library = const IconData(0xe54b);

  /// <p>Material icon "local mall": <i class="material-icons md-48">local_mall</i></p>
  static const IconData local_mall = const IconData(0xe54c);

  /// <p>Material icon "local movies": <i class="material-icons md-48">local_movies</i></p>
  static const IconData local_movies = const IconData(0xe54d);

  /// <p>Material icon "local offer": <i class="material-icons md-48">local_offer</i></p>
  static const IconData local_offer = const IconData(0xe54e);

  /// <p>Material icon "local parking": <i class="material-icons md-48">local_parking</i></p>
  static const IconData local_parking = const IconData(0xe54f);

  /// <p>Material icon "local pharmacy": <i class="material-icons md-48">local_pharmacy</i></p>
  static const IconData local_pharmacy = const IconData(0xe550);

  /// <p>Material icon "local phone": <i class="material-icons md-48">local_phone</i></p>
  static const IconData local_phone = const IconData(0xe551);

  /// <p>Material icon "local pizza": <i class="material-icons md-48">local_pizza</i></p>
  static const IconData local_pizza = const IconData(0xe552);

  /// <p>Material icon "local play": <i class="material-icons md-48">local_play</i></p>
  static const IconData local_play = const IconData(0xe553);

  /// <p>Material icon "local post office": <i class="material-icons md-48">local_post_office</i></p>
  static const IconData local_post_office = const IconData(0xe554);

  /// <p>Material icon "local printshop": <i class="material-icons md-48">local_printshop</i></p>
  static const IconData local_printshop = const IconData(0xe555);

  /// <p>Material icon "local see": <i class="material-icons md-48">local_see</i></p>
  static const IconData local_see = const IconData(0xe557);

  /// <p>Material icon "local shipping": <i class="material-icons md-48">local_shipping</i></p>
  static const IconData local_shipping = const IconData(0xe558);

  /// <p>Material icon "local taxi": <i class="material-icons md-48">local_taxi</i></p>
  static const IconData local_taxi = const IconData(0xe559);

  /// <p>Material icon "location city": <i class="material-icons md-48">location_city</i></p>
  static const IconData location_city = const IconData(0xe7f1);

  /// <p>Material icon "location disabled": <i class="material-icons md-48">location_disabled</i></p>
  static const IconData location_disabled = const IconData(0xe1b6);

  /// <p>Material icon "location off": <i class="material-icons md-48">location_off</i></p>
  static const IconData location_off = const IconData(0xe0c7);

  /// <p>Material icon "location on": <i class="material-icons md-48">location_on</i></p>
  static const IconData location_on = const IconData(0xe0c8);

  /// <p>Material icon "location searching": <i class="material-icons md-48">location_searching</i></p>
  static const IconData location_searching = const IconData(0xe1b7);

  /// <p>Material icon "lock": <i class="material-icons md-48">lock</i></p>
  static const IconData lock = const IconData(0xe897);

  /// <p>Material icon "lock open": <i class="material-icons md-48">lock_open</i></p>
  static const IconData lock_open = const IconData(0xe898);

  /// <p>Material icon "lock outline": <i class="material-icons md-48">lock_outline</i></p>
  static const IconData lock_outline = const IconData(0xe899);

  /// <p>Material icon "looks": <i class="material-icons md-48">looks</i></p>
  static const IconData looks = const IconData(0xe3fc);

  /// <p>Material icon "looks 3": <i class="material-icons md-48">looks_3</i></p>
  static const IconData looks_3 = const IconData(0xe3fb);

  /// <p>Material icon "looks 4": <i class="material-icons md-48">looks_4</i></p>
  static const IconData looks_4 = const IconData(0xe3fd);

  /// <p>Material icon "looks 5": <i class="material-icons md-48">looks_5</i></p>
  static const IconData looks_5 = const IconData(0xe3fe);

  /// <p>Material icon "looks 6": <i class="material-icons md-48">looks_6</i></p>
  static const IconData looks_6 = const IconData(0xe3ff);

  /// <p>Material icon "looks one": <i class="material-icons md-48">looks_one</i></p>
  static const IconData looks_one = const IconData(0xe400);

  /// <p>Material icon "looks two": <i class="material-icons md-48">looks_two</i></p>
  static const IconData looks_two = const IconData(0xe401);

  /// <p>Material icon "loop": <i class="material-icons md-48">loop</i></p>
  static const IconData loop = const IconData(0xe028);

  /// <p>Material icon "loupe": <i class="material-icons md-48">loupe</i></p>
  static const IconData loupe = const IconData(0xe402);

  /// <p>Material icon "low priority": <i class="material-icons md-48">low_priority</i></p>
  static const IconData low_priority = const IconData(0xe16d);

  /// <p>Material icon "loyalty": <i class="material-icons md-48">loyalty</i></p>
  static const IconData loyalty = const IconData(0xe89a);

  /// <p>Material icon "mail": <i class="material-icons md-48">mail</i></p>
  static const IconData mail = const IconData(0xe158);

  /// <p>Material icon "mail outline": <i class="material-icons md-48">mail_outline</i></p>
  static const IconData mail_outline = const IconData(0xe0e1);

  /// <p>Material icon "map": <i class="material-icons md-48">map</i></p>
  static const IconData map = const IconData(0xe55b);

  /// <p>Material icon "markunread": <i class="material-icons md-48">markunread</i></p>
  static const IconData markunread = const IconData(0xe159);

  /// <p>Material icon "markunread mailbox": <i class="material-icons md-48">markunread_mailbox</i></p>
  static const IconData markunread_mailbox = const IconData(0xe89b);

  /// <p>Material icon "memory": <i class="material-icons md-48">memory</i></p>
  static const IconData memory = const IconData(0xe322);

  /// <p>Material icon "menu": <i class="material-icons md-48">menu</i></p>
  static const IconData menu = const IconData(0xe5d2);

  /// <p>Material icon "merge type": <i class="material-icons md-48">merge_type</i></p>
  static const IconData merge_type = const IconData(0xe252);

  /// <p>Material icon "message": <i class="material-icons md-48">message</i></p>
  static const IconData message = const IconData(0xe0c9);

  /// <p>Material icon "mic": <i class="material-icons md-48">mic</i></p>
  static const IconData mic = const IconData(0xe029);

  /// <p>Material icon "mic none": <i class="material-icons md-48">mic_none</i></p>
  static const IconData mic_none = const IconData(0xe02a);

  /// <p>Material icon "mic off": <i class="material-icons md-48">mic_off</i></p>
  static const IconData mic_off = const IconData(0xe02b);

  /// <p>Material icon "mms": <i class="material-icons md-48">mms</i></p>
  static const IconData mms = const IconData(0xe618);

  /// <p>Material icon "mode comment": <i class="material-icons md-48">mode_comment</i></p>
  static const IconData mode_comment = const IconData(0xe253);

  /// <p>Material icon "mode edit": <i class="material-icons md-48">mode_edit</i></p>
  static const IconData mode_edit = const IconData(0xe254);

  /// <p>Material icon "monetization on": <i class="material-icons md-48">monetization_on</i></p>
  static const IconData monetization_on = const IconData(0xe263);

  /// <p>Material icon "money off": <i class="material-icons md-48">money_off</i></p>
  static const IconData money_off = const IconData(0xe25c);

  /// <p>Material icon "monochrome photos": <i class="material-icons md-48">monochrome_photos</i></p>
  static const IconData monochrome_photos = const IconData(0xe403);

  /// <p>Material icon "mood": <i class="material-icons md-48">mood</i></p>
  static const IconData mood = const IconData(0xe7f2);

  /// <p>Material icon "mood bad": <i class="material-icons md-48">mood_bad</i></p>
  static const IconData mood_bad = const IconData(0xe7f3);

  /// <p>Material icon "more": <i class="material-icons md-48">more</i></p>
  static const IconData more = const IconData(0xe619);

  /// <p>Material icon "more horiz": <i class="material-icons md-48">more_horiz</i></p>
  static const IconData more_horiz = const IconData(0xe5d3);

  /// <p>Material icon "more vert": <i class="material-icons md-48">more_vert</i></p>
  static const IconData more_vert = const IconData(0xe5d4);

  /// <p>Material icon "motorcycle": <i class="material-icons md-48">motorcycle</i></p>
  static const IconData motorcycle = const IconData(0xe91b);

  /// <p>Material icon "mouse": <i class="material-icons md-48">mouse</i></p>
  static const IconData mouse = const IconData(0xe323);

  /// <p>Material icon "move to inbox": <i class="material-icons md-48">move_to_inbox</i></p>
  static const IconData move_to_inbox = const IconData(0xe168);

  /// <p>Material icon "movie": <i class="material-icons md-48">movie</i></p>
  static const IconData movie = const IconData(0xe02c);

  /// <p>Material icon "movie creation": <i class="material-icons md-48">movie_creation</i></p>
  static const IconData movie_creation = const IconData(0xe404);

  /// <p>Material icon "movie filter": <i class="material-icons md-48">movie_filter</i></p>
  static const IconData movie_filter = const IconData(0xe43a);

  /// <p>Material icon "multiline chart": <i class="material-icons md-48">multiline_chart</i></p>
  static const IconData multiline_chart = const IconData(0xe6df);

  /// <p>Material icon "music note": <i class="material-icons md-48">music_note</i></p>
  static const IconData music_note = const IconData(0xe405);

  /// <p>Material icon "music video": <i class="material-icons md-48">music_video</i></p>
  static const IconData music_video = const IconData(0xe063);

  /// <p>Material icon "my location": <i class="material-icons md-48">my_location</i></p>
  static const IconData my_location = const IconData(0xe55c);

  /// <p>Material icon "nature": <i class="material-icons md-48">nature</i></p>
  static const IconData nature = const IconData(0xe406);

  /// <p>Material icon "nature people": <i class="material-icons md-48">nature_people</i></p>
  static const IconData nature_people = const IconData(0xe407);

  /// <p>Material icon "navigate before": <i class="material-icons md-48">navigate_before</i></p>
  static const IconData navigate_before = const IconData(0xe408);

  /// <p>Material icon "navigate next": <i class="material-icons md-48">navigate_next</i></p>
  static const IconData navigate_next = const IconData(0xe409);

  /// <p>Material icon "navigation": <i class="material-icons md-48">navigation</i></p>
  static const IconData navigation = const IconData(0xe55d);

  /// <p>Material icon "near me": <i class="material-icons md-48">near_me</i></p>
  static const IconData near_me = const IconData(0xe569);

  /// <p>Material icon "network cell": <i class="material-icons md-48">network_cell</i></p>
  static const IconData network_cell = const IconData(0xe1b9);

  /// <p>Material icon "network check": <i class="material-icons md-48">network_check</i></p>
  static const IconData network_check = const IconData(0xe640);

  /// <p>Material icon "network locked": <i class="material-icons md-48">network_locked</i></p>
  static const IconData network_locked = const IconData(0xe61a);

  /// <p>Material icon "network wifi": <i class="material-icons md-48">network_wifi</i></p>
  static const IconData network_wifi = const IconData(0xe1ba);

  /// <p>Material icon "const releases": <i class="material-icons md-48">const_releases</i></p>
  static const IconData const_releases = const IconData(0xe031);

  /// <p>Material icon "next week": <i class="material-icons md-48">next_week</i></p>
  static const IconData next_week = const IconData(0xe16a);

  /// <p>Material icon "nfc": <i class="material-icons md-48">nfc</i></p>
  static const IconData nfc = const IconData(0xe1bb);

  /// <p>Material icon "no encryption": <i class="material-icons md-48">no_encryption</i></p>
  static const IconData no_encryption = const IconData(0xe641);

  /// <p>Material icon "no sim": <i class="material-icons md-48">no_sim</i></p>
  static const IconData no_sim = const IconData(0xe0cc);

  /// <p>Material icon "not interested": <i class="material-icons md-48">not_interested</i></p>
  static const IconData not_interested = const IconData(0xe033);

  /// <p>Material icon "note": <i class="material-icons md-48">note</i></p>
  static const IconData note = const IconData(0xe06f);

  /// <p>Material icon "note add": <i class="material-icons md-48">note_add</i></p>
  static const IconData note_add = const IconData(0xe89c);

  /// <p>Material icon "notifications": <i class="material-icons md-48">notifications</i></p>
  static const IconData notifications = const IconData(0xe7f4);

  /// <p>Material icon "notifications active": <i class="material-icons md-48">notifications_active</i></p>
  static const IconData notifications_active = const IconData(0xe7f7);

  /// <p>Material icon "notifications none": <i class="material-icons md-48">notifications_none</i></p>
  static const IconData notifications_none = const IconData(0xe7f5);

  /// <p>Material icon "notifications off": <i class="material-icons md-48">notifications_off</i></p>
  static const IconData notifications_off = const IconData(0xe7f6);

  /// <p>Material icon "notifications paused": <i class="material-icons md-48">notifications_paused</i></p>
  static const IconData notifications_paused = const IconData(0xe7f8);

  /// <p>Material icon "offline pin": <i class="material-icons md-48">offline_pin</i></p>
  static const IconData offline_pin = const IconData(0xe90a);

  /// <p>Material icon "ondemand video": <i class="material-icons md-48">ondemand_video</i></p>
  static const IconData ondemand_video = const IconData(0xe63a);

  /// <p>Material icon "opacity": <i class="material-icons md-48">opacity</i></p>
  static const IconData opacity = const IconData(0xe91c);

  /// <p>Material icon "open in browser": <i class="material-icons md-48">open_in_browser</i></p>
  static const IconData open_in_browser = const IconData(0xe89d);

  /// <p>Material icon "open in const": <i class="material-icons md-48">open_in_const</i></p>
  static const IconData open_in_const = const IconData(0xe89e);

  /// <p>Material icon "open with": <i class="material-icons md-48">open_with</i></p>
  static const IconData open_with = const IconData(0xe89f);

  /// <p>Material icon "pages": <i class="material-icons md-48">pages</i></p>
  static const IconData pages = const IconData(0xe7f9);

  /// <p>Material icon "pageview": <i class="material-icons md-48">pageview</i></p>
  static const IconData pageview = const IconData(0xe8a0);

  /// <p>Material icon "palette": <i class="material-icons md-48">palette</i></p>
  static const IconData palette = const IconData(0xe40a);

  /// <p>Material icon "pan tool": <i class="material-icons md-48">pan_tool</i></p>
  static const IconData pan_tool = const IconData(0xe925);

  /// <p>Material icon "panorama": <i class="material-icons md-48">panorama</i></p>
  static const IconData panorama = const IconData(0xe40b);

  /// <p>Material icon "panorama fish eye": <i class="material-icons md-48">panorama_fish_eye</i></p>
  static const IconData panorama_fish_eye = const IconData(0xe40c);

  /// <p>Material icon "panorama horizontal": <i class="material-icons md-48">panorama_horizontal</i></p>
  static const IconData panorama_horizontal = const IconData(0xe40d);

  /// <p>Material icon "panorama vertical": <i class="material-icons md-48">panorama_vertical</i></p>
  static const IconData panorama_vertical = const IconData(0xe40e);

  /// <p>Material icon "panorama wide angle": <i class="material-icons md-48">panorama_wide_angle</i></p>
  static const IconData panorama_wide_angle = const IconData(0xe40f);

  /// <p>Material icon "party mode": <i class="material-icons md-48">party_mode</i></p>
  static const IconData party_mode = const IconData(0xe7fa);

  /// <p>Material icon "pause": <i class="material-icons md-48">pause</i></p>
  static const IconData pause = const IconData(0xe034);

  /// <p>Material icon "pause circle filled": <i class="material-icons md-48">pause_circle_filled</i></p>
  static const IconData pause_circle_filled = const IconData(0xe035);

  /// <p>Material icon "pause circle outline": <i class="material-icons md-48">pause_circle_outline</i></p>
  static const IconData pause_circle_outline = const IconData(0xe036);

  /// <p>Material icon "payment": <i class="material-icons md-48">payment</i></p>
  static const IconData payment = const IconData(0xe8a1);

  /// <p>Material icon "people": <i class="material-icons md-48">people</i></p>
  static const IconData people = const IconData(0xe7fb);

  /// <p>Material icon "people outline": <i class="material-icons md-48">people_outline</i></p>
  static const IconData people_outline = const IconData(0xe7fc);

  /// <p>Material icon "perm camera mic": <i class="material-icons md-48">perm_camera_mic</i></p>
  static const IconData perm_camera_mic = const IconData(0xe8a2);

  /// <p>Material icon "perm contact calendar": <i class="material-icons md-48">perm_contact_calendar</i></p>
  static const IconData perm_contact_calendar = const IconData(0xe8a3);

  /// <p>Material icon "perm data setting": <i class="material-icons md-48">perm_data_setting</i></p>
  static const IconData perm_data_setting = const IconData(0xe8a4);

  /// <p>Material icon "perm device information": <i class="material-icons md-48">perm_device_information</i></p>
  static const IconData perm_device_information = const IconData(0xe8a5);

  /// <p>Material icon "perm identity": <i class="material-icons md-48">perm_identity</i></p>
  static const IconData perm_identity = const IconData(0xe8a6);

  /// <p>Material icon "perm media": <i class="material-icons md-48">perm_media</i></p>
  static const IconData perm_media = const IconData(0xe8a7);

  /// <p>Material icon "perm phone msg": <i class="material-icons md-48">perm_phone_msg</i></p>
  static const IconData perm_phone_msg = const IconData(0xe8a8);

  /// <p>Material icon "perm scan wifi": <i class="material-icons md-48">perm_scan_wifi</i></p>
  static const IconData perm_scan_wifi = const IconData(0xe8a9);

  /// <p>Material icon "person": <i class="material-icons md-48">person</i></p>
  static const IconData person = const IconData(0xe7fd);

  /// <p>Material icon "person add": <i class="material-icons md-48">person_add</i></p>
  static const IconData person_add = const IconData(0xe7fe);

  /// <p>Material icon "person outline": <i class="material-icons md-48">person_outline</i></p>
  static const IconData person_outline = const IconData(0xe7ff);

  /// <p>Material icon "person pin": <i class="material-icons md-48">person_pin</i></p>
  static const IconData person_pin = const IconData(0xe55a);

  /// <p>Material icon "person pin circle": <i class="material-icons md-48">person_pin_circle</i></p>
  static const IconData person_pin_circle = const IconData(0xe56a);

  /// <p>Material icon "personal video": <i class="material-icons md-48">personal_video</i></p>
  static const IconData personal_video = const IconData(0xe63b);

  /// <p>Material icon "pets": <i class="material-icons md-48">pets</i></p>
  static const IconData pets = const IconData(0xe91d);

  /// <p>Material icon "phone": <i class="material-icons md-48">phone</i></p>
  static const IconData phone = const IconData(0xe0cd);

  /// <p>Material icon "phone android": <i class="material-icons md-48">phone_android</i></p>
  static const IconData phone_android = const IconData(0xe324);

  /// <p>Material icon "phone bluetooth speaker": <i class="material-icons md-48">phone_bluetooth_speaker</i></p>
  static const IconData phone_bluetooth_speaker = const IconData(0xe61b);

  /// <p>Material icon "phone forwarded": <i class="material-icons md-48">phone_forwarded</i></p>
  static const IconData phone_forwarded = const IconData(0xe61c);

  /// <p>Material icon "phone in talk": <i class="material-icons md-48">phone_in_talk</i></p>
  static const IconData phone_in_talk = const IconData(0xe61d);

  /// <p>Material icon "phone iphone": <i class="material-icons md-48">phone_iphone</i></p>
  static const IconData phone_iphone = const IconData(0xe325);

  /// <p>Material icon "phone locked": <i class="material-icons md-48">phone_locked</i></p>
  static const IconData phone_locked = const IconData(0xe61e);

  /// <p>Material icon "phone missed": <i class="material-icons md-48">phone_missed</i></p>
  static const IconData phone_missed = const IconData(0xe61f);

  /// <p>Material icon "phone paused": <i class="material-icons md-48">phone_paused</i></p>
  static const IconData phone_paused = const IconData(0xe620);

  /// <p>Material icon "phonelink": <i class="material-icons md-48">phonelink</i></p>
  static const IconData phonelink = const IconData(0xe326);

  /// <p>Material icon "phonelink erase": <i class="material-icons md-48">phonelink_erase</i></p>
  static const IconData phonelink_erase = const IconData(0xe0db);

  /// <p>Material icon "phonelink lock": <i class="material-icons md-48">phonelink_lock</i></p>
  static const IconData phonelink_lock = const IconData(0xe0dc);

  /// <p>Material icon "phonelink off": <i class="material-icons md-48">phonelink_off</i></p>
  static const IconData phonelink_off = const IconData(0xe327);

  /// <p>Material icon "phonelink ring": <i class="material-icons md-48">phonelink_ring</i></p>
  static const IconData phonelink_ring = const IconData(0xe0dd);

  /// <p>Material icon "phonelink setup": <i class="material-icons md-48">phonelink_setup</i></p>
  static const IconData phonelink_setup = const IconData(0xe0de);

  /// <p>Material icon "photo": <i class="material-icons md-48">photo</i></p>
  static const IconData photo = const IconData(0xe410);

  /// <p>Material icon "photo album": <i class="material-icons md-48">photo_album</i></p>
  static const IconData photo_album = const IconData(0xe411);

  /// <p>Material icon "photo camera": <i class="material-icons md-48">photo_camera</i></p>
  static const IconData photo_camera = const IconData(0xe412);

  /// <p>Material icon "photo filter": <i class="material-icons md-48">photo_filter</i></p>
  static const IconData photo_filter = const IconData(0xe43b);

  /// <p>Material icon "photo library": <i class="material-icons md-48">photo_library</i></p>
  static const IconData photo_library = const IconData(0xe413);

  /// <p>Material icon "photo size select actual": <i class="material-icons md-48">photo_size_select_actual</i></p>
  static const IconData photo_size_select_actual = const IconData(0xe432);

  /// <p>Material icon "photo size select large": <i class="material-icons md-48">photo_size_select_large</i></p>
  static const IconData photo_size_select_large = const IconData(0xe433);

  /// <p>Material icon "photo size select small": <i class="material-icons md-48">photo_size_select_small</i></p>
  static const IconData photo_size_select_small = const IconData(0xe434);

  /// <p>Material icon "picture as pdf": <i class="material-icons md-48">picture_as_pdf</i></p>
  static const IconData picture_as_pdf = const IconData(0xe415);

  /// <p>Material icon "picture in picture": <i class="material-icons md-48">picture_in_picture</i></p>
  static const IconData picture_in_picture = const IconData(0xe8aa);

  /// <p>Material icon "picture in picture alt": <i class="material-icons md-48">picture_in_picture_alt</i></p>
  static const IconData picture_in_picture_alt = const IconData(0xe911);

  /// <p>Material icon "pie chart": <i class="material-icons md-48">pie_chart</i></p>
  static const IconData pie_chart = const IconData(0xe6c4);

  /// <p>Material icon "pie chart outlined": <i class="material-icons md-48">pie_chart_outlined</i></p>
  static const IconData pie_chart_outlined = const IconData(0xe6c5);

  /// <p>Material icon "pin drop": <i class="material-icons md-48">pin_drop</i></p>
  static const IconData pin_drop = const IconData(0xe55e);

  /// <p>Material icon "place": <i class="material-icons md-48">place</i></p>
  static const IconData place = const IconData(0xe55f);

  /// <p>Material icon "play arrow": <i class="material-icons md-48">play_arrow</i></p>
  static const IconData play_arrow = const IconData(0xe037);

  /// <p>Material icon "play circle filled": <i class="material-icons md-48">play_circle_filled</i></p>
  static const IconData play_circle_filled = const IconData(0xe038);

  /// <p>Material icon "play circle outline": <i class="material-icons md-48">play_circle_outline</i></p>
  static const IconData play_circle_outline = const IconData(0xe039);

  /// <p>Material icon "play for work": <i class="material-icons md-48">play_for_work</i></p>
  static const IconData play_for_work = const IconData(0xe906);

  /// <p>Material icon "playlist add": <i class="material-icons md-48">playlist_add</i></p>
  static const IconData playlist_add = const IconData(0xe03b);

  /// <p>Material icon "playlist add check": <i class="material-icons md-48">playlist_add_check</i></p>
  static const IconData playlist_add_check = const IconData(0xe065);

  /// <p>Material icon "playlist play": <i class="material-icons md-48">playlist_play</i></p>
  static const IconData playlist_play = const IconData(0xe05f);

  /// <p>Material icon "plus one": <i class="material-icons md-48">plus_one</i></p>
  static const IconData plus_one = const IconData(0xe800);

  /// <p>Material icon "poll": <i class="material-icons md-48">poll</i></p>
  static const IconData poll = const IconData(0xe801);

  /// <p>Material icon "polymer": <i class="material-icons md-48">polymer</i></p>
  static const IconData polymer = const IconData(0xe8ab);

  /// <p>Material icon "pool": <i class="material-icons md-48">pool</i></p>
  static const IconData pool = const IconData(0xeb48);

  /// <p>Material icon "portable wifi off": <i class="material-icons md-48">portable_wifi_off</i></p>
  static const IconData portable_wifi_off = const IconData(0xe0ce);

  /// <p>Material icon "portrait": <i class="material-icons md-48">portrait</i></p>
  static const IconData portrait = const IconData(0xe416);

  /// <p>Material icon "power": <i class="material-icons md-48">power</i></p>
  static const IconData power = const IconData(0xe63c);

  /// <p>Material icon "power input": <i class="material-icons md-48">power_input</i></p>
  static const IconData power_input = const IconData(0xe336);

  /// <p>Material icon "power settings const": <i class="material-icons md-48">power_settings_const</i></p>
  static const IconData power_settings_const = const IconData(0xe8ac);

  /// <p>Material icon "pregnant woman": <i class="material-icons md-48">pregnant_woman</i></p>
  static const IconData pregnant_woman = const IconData(0xe91e);

  /// <p>Material icon "present to all": <i class="material-icons md-48">present_to_all</i></p>
  static const IconData present_to_all = const IconData(0xe0df);

  /// <p>Material icon "print": <i class="material-icons md-48">print</i></p>
  static const IconData print = const IconData(0xe8ad);

  /// <p>Material icon "priority high": <i class="material-icons md-48">priority_high</i></p>
  static const IconData priority_high = const IconData(0xe645);

  /// <p>Material icon "public": <i class="material-icons md-48">public</i></p>
  static const IconData public = const IconData(0xe80b);

  /// <p>Material icon "publish": <i class="material-icons md-48">publish</i></p>
  static const IconData publish = const IconData(0xe255);

  /// <p>Material icon "query builder": <i class="material-icons md-48">query_builder</i></p>
  static const IconData query_builder = const IconData(0xe8ae);

  /// <p>Material icon "question answer": <i class="material-icons md-48">question_answer</i></p>
  static const IconData question_answer = const IconData(0xe8af);

  /// <p>Material icon "queue": <i class="material-icons md-48">queue</i></p>
  static const IconData queue = const IconData(0xe03c);

  /// <p>Material icon "queue music": <i class="material-icons md-48">queue_music</i></p>
  static const IconData queue_music = const IconData(0xe03d);

  /// <p>Material icon "queue play next": <i class="material-icons md-48">queue_play_next</i></p>
  static const IconData queue_play_next = const IconData(0xe066);

  /// <p>Material icon "radio": <i class="material-icons md-48">radio</i></p>
  static const IconData radio = const IconData(0xe03e);

  /// <p>Material icon "radio button checked": <i class="material-icons md-48">radio_button_checked</i></p>
  static const IconData radio_button_checked = const IconData(0xe837);

  /// <p>Material icon "radio button unchecked": <i class="material-icons md-48">radio_button_unchecked</i></p>
  static const IconData radio_button_unchecked = const IconData(0xe836);

  /// <p>Material icon "rate review": <i class="material-icons md-48">rate_review</i></p>
  static const IconData rate_review = const IconData(0xe560);

  /// <p>Material icon "receipt": <i class="material-icons md-48">receipt</i></p>
  static const IconData receipt = const IconData(0xe8b0);

  /// <p>Material icon "recent actors": <i class="material-icons md-48">recent_actors</i></p>
  static const IconData recent_actors = const IconData(0xe03f);

  /// <p>Material icon "record voice over": <i class="material-icons md-48">record_voice_over</i></p>
  static const IconData record_voice_over = const IconData(0xe91f);

  /// <p>Material icon "redeem": <i class="material-icons md-48">redeem</i></p>
  static const IconData redeem = const IconData(0xe8b1);

  /// <p>Material icon "redo": <i class="material-icons md-48">redo</i></p>
  static const IconData redo = const IconData(0xe15a);

  /// <p>Material icon "refresh": <i class="material-icons md-48">refresh</i></p>
  static const IconData refresh = const IconData(0xe5d5);

  /// <p>Material icon "remove": <i class="material-icons md-48">remove</i></p>
  static const IconData remove = const IconData(0xe15b);

  /// <p>Material icon "remove circle": <i class="material-icons md-48">remove_circle</i></p>
  static const IconData remove_circle = const IconData(0xe15c);

  /// <p>Material icon "remove circle outline": <i class="material-icons md-48">remove_circle_outline</i></p>
  static const IconData remove_circle_outline = const IconData(0xe15d);

  /// <p>Material icon "remove from queue": <i class="material-icons md-48">remove_from_queue</i></p>
  static const IconData remove_from_queue = const IconData(0xe067);

  /// <p>Material icon "remove red eye": <i class="material-icons md-48">remove_red_eye</i></p>
  static const IconData remove_red_eye = const IconData(0xe417);

  /// <p>Material icon "remove shopping cart": <i class="material-icons md-48">remove_shopping_cart</i></p>
  static const IconData remove_shopping_cart = const IconData(0xe928);

  /// <p>Material icon "reorder": <i class="material-icons md-48">reorder</i></p>
  static const IconData reorder = const IconData(0xe8fe);

  /// <p>Material icon "repeat": <i class="material-icons md-48">repeat</i></p>
  static const IconData repeat = const IconData(0xe040);

  /// <p>Material icon "repeat one": <i class="material-icons md-48">repeat_one</i></p>
  static const IconData repeat_one = const IconData(0xe041);

  /// <p>Material icon "replay": <i class="material-icons md-48">replay</i></p>
  static const IconData replay = const IconData(0xe042);

  /// <p>Material icon "replay 10": <i class="material-icons md-48">replay_10</i></p>
  static const IconData replay_10 = const IconData(0xe059);

  /// <p>Material icon "replay 30": <i class="material-icons md-48">replay_30</i></p>
  static const IconData replay_30 = const IconData(0xe05a);

  /// <p>Material icon "replay 5": <i class="material-icons md-48">replay_5</i></p>
  static const IconData replay_5 = const IconData(0xe05b);

  /// <p>Material icon "reply": <i class="material-icons md-48">reply</i></p>
  static const IconData reply = const IconData(0xe15e);

  /// <p>Material icon "reply all": <i class="material-icons md-48">reply_all</i></p>
  static const IconData reply_all = const IconData(0xe15f);

  /// <p>Material icon "report": <i class="material-icons md-48">report</i></p>
  static const IconData report = const IconData(0xe160);

  /// <p>Material icon "report problem": <i class="material-icons md-48">report_problem</i></p>
  static const IconData report_problem = const IconData(0xe8b2);

  /// <p>Material icon "restaurant": <i class="material-icons md-48">restaurant</i></p>
  static const IconData restaurant = const IconData(0xe56c);

  /// <p>Material icon "restaurant menu": <i class="material-icons md-48">restaurant_menu</i></p>
  static const IconData restaurant_menu = const IconData(0xe561);

  /// <p>Material icon "restore": <i class="material-icons md-48">restore</i></p>
  static const IconData restore = const IconData(0xe8b3);

  /// <p>Material icon "restore page": <i class="material-icons md-48">restore_page</i></p>
  static const IconData restore_page = const IconData(0xe929);

  /// <p>Material icon "ring volume": <i class="material-icons md-48">ring_volume</i></p>
  static const IconData ring_volume = const IconData(0xe0d1);

  /// <p>Material icon "room": <i class="material-icons md-48">room</i></p>
  static const IconData room = const IconData(0xe8b4);

  /// <p>Material icon "room service": <i class="material-icons md-48">room_service</i></p>
  static const IconData room_service = const IconData(0xeb49);

  /// <p>Material icon "rotate 90 degrees ccw": <i class="material-icons md-48">rotate_90_degrees_ccw</i></p>
  static const IconData rotate_90_degrees_ccw = const IconData(0xe418);

  /// <p>Material icon "rotate left": <i class="material-icons md-48">rotate_left</i></p>
  static const IconData rotate_left = const IconData(0xe419);

  /// <p>Material icon "rotate right": <i class="material-icons md-48">rotate_right</i></p>
  static const IconData rotate_right = const IconData(0xe41a);

  /// <p>Material icon "rounded corner": <i class="material-icons md-48">rounded_corner</i></p>
  static const IconData rounded_corner = const IconData(0xe920);

  /// <p>Material icon "router": <i class="material-icons md-48">router</i></p>
  static const IconData router = const IconData(0xe328);

  /// <p>Material icon "rowing": <i class="material-icons md-48">rowing</i></p>
  static const IconData rowing = const IconData(0xe921);

  /// <p>Material icon "rss feed": <i class="material-icons md-48">rss_feed</i></p>
  static const IconData rss_feed = const IconData(0xe0e5);

  /// <p>Material icon "rv hookup": <i class="material-icons md-48">rv_hookup</i></p>
  static const IconData rv_hookup = const IconData(0xe642);

  /// <p>Material icon "satellite": <i class="material-icons md-48">satellite</i></p>
  static const IconData satellite = const IconData(0xe562);

  /// <p>Material icon "save": <i class="material-icons md-48">save</i></p>
  static const IconData save = const IconData(0xe161);

  /// <p>Material icon "scanner": <i class="material-icons md-48">scanner</i></p>
  static const IconData scanner = const IconData(0xe329);

  /// <p>Material icon "schedule": <i class="material-icons md-48">schedule</i></p>
  static const IconData schedule = const IconData(0xe8b5);

  /// <p>Material icon "school": <i class="material-icons md-48">school</i></p>
  static const IconData school = const IconData(0xe80c);

  /// <p>Material icon "screen lock landscape": <i class="material-icons md-48">screen_lock_landscape</i></p>
  static const IconData screen_lock_landscape = const IconData(0xe1be);

  /// <p>Material icon "screen lock portrait": <i class="material-icons md-48">screen_lock_portrait</i></p>
  static const IconData screen_lock_portrait = const IconData(0xe1bf);

  /// <p>Material icon "screen lock rotation": <i class="material-icons md-48">screen_lock_rotation</i></p>
  static const IconData screen_lock_rotation = const IconData(0xe1c0);

  /// <p>Material icon "screen rotation": <i class="material-icons md-48">screen_rotation</i></p>
  static const IconData screen_rotation = const IconData(0xe1c1);

  /// <p>Material icon "screen share": <i class="material-icons md-48">screen_share</i></p>
  static const IconData screen_share = const IconData(0xe0e2);

  /// <p>Material icon "sd card": <i class="material-icons md-48">sd_card</i></p>
  static const IconData sd_card = const IconData(0xe623);

  /// <p>Material icon "sd storage": <i class="material-icons md-48">sd_storage</i></p>
  static const IconData sd_storage = const IconData(0xe1c2);

  /// <p>Material icon "search": <i class="material-icons md-48">search</i></p>
  static const IconData search = const IconData(0xe8b6);

  /// <p>Material icon "security": <i class="material-icons md-48">security</i></p>
  static const IconData security = const IconData(0xe32a);

  /// <p>Material icon "select all": <i class="material-icons md-48">select_all</i></p>
  static const IconData select_all = const IconData(0xe162);

  /// <p>Material icon "send": <i class="material-icons md-48">send</i></p>
  static const IconData send = const IconData(0xe163);

  /// <p>Material icon "sentiment dissatisfied": <i class="material-icons md-48">sentiment_dissatisfied</i></p>
  static const IconData sentiment_dissatisfied = const IconData(0xe811);

  /// <p>Material icon "sentiment neutral": <i class="material-icons md-48">sentiment_neutral</i></p>
  static const IconData sentiment_neutral = const IconData(0xe812);

  /// <p>Material icon "sentiment satisfied": <i class="material-icons md-48">sentiment_satisfied</i></p>
  static const IconData sentiment_satisfied = const IconData(0xe813);

  /// <p>Material icon "sentiment very dissatisfied": <i class="material-icons md-48">sentiment_very_dissatisfied</i></p>
  static const IconData sentiment_very_dissatisfied = const IconData(0xe814);

  /// <p>Material icon "sentiment very satisfied": <i class="material-icons md-48">sentiment_very_satisfied</i></p>
  static const IconData sentiment_very_satisfied = const IconData(0xe815);

  /// <p>Material icon "settings": <i class="material-icons md-48">settings</i></p>
  static const IconData settings = const IconData(0xe8b8);

  /// <p>Material icon "settings applications": <i class="material-icons md-48">settings_applications</i></p>
  static const IconData settings_applications = const IconData(0xe8b9);

  /// <p>Material icon "settings backup restore": <i class="material-icons md-48">settings_backup_restore</i></p>
  static const IconData settings_backup_restore = const IconData(0xe8ba);

  /// <p>Material icon "settings bluetooth": <i class="material-icons md-48">settings_bluetooth</i></p>
  static const IconData settings_bluetooth = const IconData(0xe8bb);

  /// <p>Material icon "settings brightness": <i class="material-icons md-48">settings_brightness</i></p>
  static const IconData settings_brightness = const IconData(0xe8bd);

  /// <p>Material icon "settings cell": <i class="material-icons md-48">settings_cell</i></p>
  static const IconData settings_cell = const IconData(0xe8bc);

  /// <p>Material icon "settings ethernet": <i class="material-icons md-48">settings_ethernet</i></p>
  static const IconData settings_ethernet = const IconData(0xe8be);

  /// <p>Material icon "settings input antenna": <i class="material-icons md-48">settings_input_antenna</i></p>
  static const IconData settings_input_antenna = const IconData(0xe8bf);

  /// <p>Material icon "settings input component": <i class="material-icons md-48">settings_input_component</i></p>
  static const IconData settings_input_component = const IconData(0xe8c0);

  /// <p>Material icon "settings input composite": <i class="material-icons md-48">settings_input_composite</i></p>
  static const IconData settings_input_composite = const IconData(0xe8c1);

  /// <p>Material icon "settings input hdmi": <i class="material-icons md-48">settings_input_hdmi</i></p>
  static const IconData settings_input_hdmi = const IconData(0xe8c2);

  /// <p>Material icon "settings input svideo": <i class="material-icons md-48">settings_input_svideo</i></p>
  static const IconData settings_input_svideo = const IconData(0xe8c3);

  /// <p>Material icon "settings overscan": <i class="material-icons md-48">settings_overscan</i></p>
  static const IconData settings_overscan = const IconData(0xe8c4);

  /// <p>Material icon "settings phone": <i class="material-icons md-48">settings_phone</i></p>
  static const IconData settings_phone = const IconData(0xe8c5);

  /// <p>Material icon "settings power": <i class="material-icons md-48">settings_power</i></p>
  static const IconData settings_power = const IconData(0xe8c6);

  /// <p>Material icon "settings remote": <i class="material-icons md-48">settings_remote</i></p>
  static const IconData settings_remote = const IconData(0xe8c7);

  /// <p>Material icon "settings system daydream": <i class="material-icons md-48">settings_system_daydream</i></p>
  static const IconData settings_system_daydream = const IconData(0xe1c3);

  /// <p>Material icon "settings voice": <i class="material-icons md-48">settings_voice</i></p>
  static const IconData settings_voice = const IconData(0xe8c8);

  /// <p>Material icon "share": <i class="material-icons md-48">share</i></p>
  static const IconData share = const IconData(0xe80d);

  /// <p>Material icon "shop": <i class="material-icons md-48">shop</i></p>
  static const IconData shop = const IconData(0xe8c9);

  /// <p>Material icon "shop two": <i class="material-icons md-48">shop_two</i></p>
  static const IconData shop_two = const IconData(0xe8ca);

  /// <p>Material icon "shopping basket": <i class="material-icons md-48">shopping_basket</i></p>
  static const IconData shopping_basket = const IconData(0xe8cb);

  /// <p>Material icon "shopping cart": <i class="material-icons md-48">shopping_cart</i></p>
  static const IconData shopping_cart = const IconData(0xe8cc);

  /// <p>Material icon "short text": <i class="material-icons md-48">short_text</i></p>
  static const IconData short_text = const IconData(0xe261);

  /// <p>Material icon "show chart": <i class="material-icons md-48">show_chart</i></p>
  static const IconData show_chart = const IconData(0xe6e1);

  /// <p>Material icon "shuffle": <i class="material-icons md-48">shuffle</i></p>
  static const IconData shuffle = const IconData(0xe043);

  /// <p>Material icon "signal cellular 4 bar": <i class="material-icons md-48">signal_cellular_4_bar</i></p>
  static const IconData signal_cellular_4_bar = const IconData(0xe1c8);

  /// <p>Material icon "signal cellular connected no internet 4 bar": <i class="material-icons md-48">signal_cellular_connected_no_internet_4_bar</i></p>
  static const IconData signal_cellular_connected_no_internet_4_bar = const IconData(0xe1cd);

  /// <p>Material icon "signal cellular no sim": <i class="material-icons md-48">signal_cellular_no_sim</i></p>
  static const IconData signal_cellular_no_sim = const IconData(0xe1ce);

  /// <p>Material icon "signal cellular null": <i class="material-icons md-48">signal_cellular_null</i></p>
  static const IconData signal_cellular_null = const IconData(0xe1cf);

  /// <p>Material icon "signal cellular off": <i class="material-icons md-48">signal_cellular_off</i></p>
  static const IconData signal_cellular_off = const IconData(0xe1d0);

  /// <p>Material icon "signal wifi 4 bar": <i class="material-icons md-48">signal_wifi_4_bar</i></p>
  static const IconData signal_wifi_4_bar = const IconData(0xe1d8);

  /// <p>Material icon "signal wifi 4 bar lock": <i class="material-icons md-48">signal_wifi_4_bar_lock</i></p>
  static const IconData signal_wifi_4_bar_lock = const IconData(0xe1d9);

  /// <p>Material icon "signal wifi off": <i class="material-icons md-48">signal_wifi_off</i></p>
  static const IconData signal_wifi_off = const IconData(0xe1da);

  /// <p>Material icon "sim card": <i class="material-icons md-48">sim_card</i></p>
  static const IconData sim_card = const IconData(0xe32b);

  /// <p>Material icon "sim card alert": <i class="material-icons md-48">sim_card_alert</i></p>
  static const IconData sim_card_alert = const IconData(0xe624);

  /// <p>Material icon "skip next": <i class="material-icons md-48">skip_next</i></p>
  static const IconData skip_next = const IconData(0xe044);

  /// <p>Material icon "skip previous": <i class="material-icons md-48">skip_previous</i></p>
  static const IconData skip_previous = const IconData(0xe045);

  /// <p>Material icon "slideshow": <i class="material-icons md-48">slideshow</i></p>
  static const IconData slideshow = const IconData(0xe41b);

  /// <p>Material icon "slow motion video": <i class="material-icons md-48">slow_motion_video</i></p>
  static const IconData slow_motion_video = const IconData(0xe068);

  /// <p>Material icon "smartphone": <i class="material-icons md-48">smartphone</i></p>
  static const IconData smartphone = const IconData(0xe32c);

  /// <p>Material icon "smoke free": <i class="material-icons md-48">smoke_free</i></p>
  static const IconData smoke_free = const IconData(0xeb4a);

  /// <p>Material icon "smoking rooms": <i class="material-icons md-48">smoking_rooms</i></p>
  static const IconData smoking_rooms = const IconData(0xeb4b);

  /// <p>Material icon "sms": <i class="material-icons md-48">sms</i></p>
  static const IconData sms = const IconData(0xe625);

  /// <p>Material icon "sms failed": <i class="material-icons md-48">sms_failed</i></p>
  static const IconData sms_failed = const IconData(0xe626);

  /// <p>Material icon "snooze": <i class="material-icons md-48">snooze</i></p>
  static const IconData snooze = const IconData(0xe046);

  /// <p>Material icon "sort": <i class="material-icons md-48">sort</i></p>
  static const IconData sort = const IconData(0xe164);

  /// <p>Material icon "sort by alpha": <i class="material-icons md-48">sort_by_alpha</i></p>
  static const IconData sort_by_alpha = const IconData(0xe053);

  /// <p>Material icon "spa": <i class="material-icons md-48">spa</i></p>
  static const IconData spa = const IconData(0xeb4c);

  /// <p>Material icon "space bar": <i class="material-icons md-48">space_bar</i></p>
  static const IconData space_bar = const IconData(0xe256);

  /// <p>Material icon "speaker": <i class="material-icons md-48">speaker</i></p>
  static const IconData speaker = const IconData(0xe32d);

  /// <p>Material icon "speaker group": <i class="material-icons md-48">speaker_group</i></p>
  static const IconData speaker_group = const IconData(0xe32e);

  /// <p>Material icon "speaker notes": <i class="material-icons md-48">speaker_notes</i></p>
  static const IconData speaker_notes = const IconData(0xe8cd);

  /// <p>Material icon "speaker notes off": <i class="material-icons md-48">speaker_notes_off</i></p>
  static const IconData speaker_notes_off = const IconData(0xe92a);

  /// <p>Material icon "speaker phone": <i class="material-icons md-48">speaker_phone</i></p>
  static const IconData speaker_phone = const IconData(0xe0d2);

  /// <p>Material icon "spellcheck": <i class="material-icons md-48">spellcheck</i></p>
  static const IconData spellcheck = const IconData(0xe8ce);

  /// <p>Material icon "star": <i class="material-icons md-48">star</i></p>
  static const IconData star = const IconData(0xe838);

  /// <p>Material icon "star border": <i class="material-icons md-48">star_border</i></p>
  static const IconData star_border = const IconData(0xe83a);

  /// <p>Material icon "star half": <i class="material-icons md-48">star_half</i></p>
  static const IconData star_half = const IconData(0xe839);

  /// <p>Material icon "stars": <i class="material-icons md-48">stars</i></p>
  static const IconData stars = const IconData(0xe8d0);

  /// <p>Material icon "stay current landscape": <i class="material-icons md-48">stay_current_landscape</i></p>
  static const IconData stay_current_landscape = const IconData(0xe0d3);

  /// <p>Material icon "stay current portrait": <i class="material-icons md-48">stay_current_portrait</i></p>
  static const IconData stay_current_portrait = const IconData(0xe0d4);

  /// <p>Material icon "stay primary landscape": <i class="material-icons md-48">stay_primary_landscape</i></p>
  static const IconData stay_primary_landscape = const IconData(0xe0d5);

  /// <p>Material icon "stay primary portrait": <i class="material-icons md-48">stay_primary_portrait</i></p>
  static const IconData stay_primary_portrait = const IconData(0xe0d6);

  /// <p>Material icon "stop": <i class="material-icons md-48">stop</i></p>
  static const IconData stop = const IconData(0xe047);

  /// <p>Material icon "stop screen share": <i class="material-icons md-48">stop_screen_share</i></p>
  static const IconData stop_screen_share = const IconData(0xe0e3);

  /// <p>Material icon "storage": <i class="material-icons md-48">storage</i></p>
  static const IconData storage = const IconData(0xe1db);

  /// <p>Material icon "store": <i class="material-icons md-48">store</i></p>
  static const IconData store = const IconData(0xe8d1);

  /// <p>Material icon "store mall directory": <i class="material-icons md-48">store_mall_directory</i></p>
  static const IconData store_mall_directory = const IconData(0xe563);

  /// <p>Material icon "straighten": <i class="material-icons md-48">straighten</i></p>
  static const IconData straighten = const IconData(0xe41c);

  /// <p>Material icon "streetview": <i class="material-icons md-48">streetview</i></p>
  static const IconData streetview = const IconData(0xe56e);

  /// <p>Material icon "strikethrough s": <i class="material-icons md-48">strikethrough_s</i></p>
  static const IconData strikethrough_s = const IconData(0xe257);

  /// <p>Material icon "style": <i class="material-icons md-48">style</i></p>
  static const IconData style = const IconData(0xe41d);

  /// <p>Material icon "subdirectory arrow left": <i class="material-icons md-48">subdirectory_arrow_left</i></p>
  static const IconData subdirectory_arrow_left = const IconData(0xe5d9);

  /// <p>Material icon "subdirectory arrow right": <i class="material-icons md-48">subdirectory_arrow_right</i></p>
  static const IconData subdirectory_arrow_right = const IconData(0xe5da);

  /// <p>Material icon "subject": <i class="material-icons md-48">subject</i></p>
  static const IconData subject = const IconData(0xe8d2);

  /// <p>Material icon "subscriptions": <i class="material-icons md-48">subscriptions</i></p>
  static const IconData subscriptions = const IconData(0xe064);

  /// <p>Material icon "subtitles": <i class="material-icons md-48">subtitles</i></p>
  static const IconData subtitles = const IconData(0xe048);

  /// <p>Material icon "subway": <i class="material-icons md-48">subway</i></p>
  static const IconData subway = const IconData(0xe56f);

  /// <p>Material icon "supervisor account": <i class="material-icons md-48">supervisor_account</i></p>
  static const IconData supervisor_account = const IconData(0xe8d3);

  /// <p>Material icon "surround sound": <i class="material-icons md-48">surround_sound</i></p>
  static const IconData surround_sound = const IconData(0xe049);

  /// <p>Material icon "swap calls": <i class="material-icons md-48">swap_calls</i></p>
  static const IconData swap_calls = const IconData(0xe0d7);

  /// <p>Material icon "swap horiz": <i class="material-icons md-48">swap_horiz</i></p>
  static const IconData swap_horiz = const IconData(0xe8d4);

  /// <p>Material icon "swap vert": <i class="material-icons md-48">swap_vert</i></p>
  static const IconData swap_vert = const IconData(0xe8d5);

  /// <p>Material icon "swap vertical circle": <i class="material-icons md-48">swap_vertical_circle</i></p>
  static const IconData swap_vertical_circle = const IconData(0xe8d6);

  /// <p>Material icon "switch camera": <i class="material-icons md-48">switch_camera</i></p>
  static const IconData switch_camera = const IconData(0xe41e);

  /// <p>Material icon "switch video": <i class="material-icons md-48">switch_video</i></p>
  static const IconData switch_video = const IconData(0xe41f);

  /// <p>Material icon "sync": <i class="material-icons md-48">sync</i></p>
  static const IconData sync = const IconData(0xe627);

  /// <p>Material icon "sync disabled": <i class="material-icons md-48">sync_disabled</i></p>
  static const IconData sync_disabled = const IconData(0xe628);

  /// <p>Material icon "sync problem": <i class="material-icons md-48">sync_problem</i></p>
  static const IconData sync_problem = const IconData(0xe629);

  /// <p>Material icon "system update": <i class="material-icons md-48">system_update</i></p>
  static const IconData system_update = const IconData(0xe62a);

  /// <p>Material icon "system update alt": <i class="material-icons md-48">system_update_alt</i></p>
  static const IconData system_update_alt = const IconData(0xe8d7);

  /// <p>Material icon "tab": <i class="material-icons md-48">tab</i></p>
  static const IconData tab = const IconData(0xe8d8);

  /// <p>Material icon "tab unselected": <i class="material-icons md-48">tab_unselected</i></p>
  static const IconData tab_unselected = const IconData(0xe8d9);

  /// <p>Material icon "tablet": <i class="material-icons md-48">tablet</i></p>
  static const IconData tablet = const IconData(0xe32f);

  /// <p>Material icon "tablet android": <i class="material-icons md-48">tablet_android</i></p>
  static const IconData tablet_android = const IconData(0xe330);

  /// <p>Material icon "tablet mac": <i class="material-icons md-48">tablet_mac</i></p>
  static const IconData tablet_mac = const IconData(0xe331);

  /// <p>Material icon "tag faces": <i class="material-icons md-48">tag_faces</i></p>
  static const IconData tag_faces = const IconData(0xe420);

  /// <p>Material icon "tap and play": <i class="material-icons md-48">tap_and_play</i></p>
  static const IconData tap_and_play = const IconData(0xe62b);

  /// <p>Material icon "terrain": <i class="material-icons md-48">terrain</i></p>
  static const IconData terrain = const IconData(0xe564);

  /// <p>Material icon "text fields": <i class="material-icons md-48">text_fields</i></p>
  static const IconData text_fields = const IconData(0xe262);

  /// <p>Material icon "text format": <i class="material-icons md-48">text_format</i></p>
  static const IconData text_format = const IconData(0xe165);

  /// <p>Material icon "textsms": <i class="material-icons md-48">textsms</i></p>
  static const IconData textsms = const IconData(0xe0d8);

  /// <p>Material icon "texture": <i class="material-icons md-48">texture</i></p>
  static const IconData texture = const IconData(0xe421);

  /// <p>Material icon "theaters": <i class="material-icons md-48">theaters</i></p>
  static const IconData theaters = const IconData(0xe8da);

  /// <p>Material icon "thumb down": <i class="material-icons md-48">thumb_down</i></p>
  static const IconData thumb_down = const IconData(0xe8db);

  /// <p>Material icon "thumb up": <i class="material-icons md-48">thumb_up</i></p>
  static const IconData thumb_up = const IconData(0xe8dc);

  /// <p>Material icon "thumbs up down": <i class="material-icons md-48">thumbs_up_down</i></p>
  static const IconData thumbs_up_down = const IconData(0xe8dd);

  /// <p>Material icon "time to leave": <i class="material-icons md-48">time_to_leave</i></p>
  static const IconData time_to_leave = const IconData(0xe62c);

  /// <p>Material icon "timelapse": <i class="material-icons md-48">timelapse</i></p>
  static const IconData timelapse = const IconData(0xe422);

  /// <p>Material icon "timeline": <i class="material-icons md-48">timeline</i></p>
  static const IconData timeline = const IconData(0xe922);

  /// <p>Material icon "timer": <i class="material-icons md-48">timer</i></p>
  static const IconData timer = const IconData(0xe425);

  /// <p>Material icon "timer 10": <i class="material-icons md-48">timer_10</i></p>
  static const IconData timer_10 = const IconData(0xe423);

  /// <p>Material icon "timer 3": <i class="material-icons md-48">timer_3</i></p>
  static const IconData timer_3 = const IconData(0xe424);

  /// <p>Material icon "timer off": <i class="material-icons md-48">timer_off</i></p>
  static const IconData timer_off = const IconData(0xe426);

  /// <p>Material icon "title": <i class="material-icons md-48">title</i></p>
  static const IconData title = const IconData(0xe264);

  /// <p>Material icon "toc": <i class="material-icons md-48">toc</i></p>
  static const IconData toc = const IconData(0xe8de);

  /// <p>Material icon "today": <i class="material-icons md-48">today</i></p>
  static const IconData today = const IconData(0xe8df);

  /// <p>Material icon "toll": <i class="material-icons md-48">toll</i></p>
  static const IconData toll = const IconData(0xe8e0);

  /// <p>Material icon "tonality": <i class="material-icons md-48">tonality</i></p>
  static const IconData tonality = const IconData(0xe427);

  /// <p>Material icon "touch app": <i class="material-icons md-48">touch_app</i></p>
  static const IconData touch_app = const IconData(0xe913);

  /// <p>Material icon "toys": <i class="material-icons md-48">toys</i></p>
  static const IconData toys = const IconData(0xe332);

  /// <p>Material icon "track changes": <i class="material-icons md-48">track_changes</i></p>
  static const IconData track_changes = const IconData(0xe8e1);

  /// <p>Material icon "traffic": <i class="material-icons md-48">traffic</i></p>
  static const IconData traffic = const IconData(0xe565);

  /// <p>Material icon "train": <i class="material-icons md-48">train</i></p>
  static const IconData train = const IconData(0xe570);

  /// <p>Material icon "tram": <i class="material-icons md-48">tram</i></p>
  static const IconData tram = const IconData(0xe571);

  /// <p>Material icon "transfer within a station": <i class="material-icons md-48">transfer_within_a_station</i></p>
  static const IconData transfer_within_a_station = const IconData(0xe572);

  /// <p>Material icon "transform": <i class="material-icons md-48">transform</i></p>
  static const IconData transform = const IconData(0xe428);

  /// <p>Material icon "translate": <i class="material-icons md-48">translate</i></p>
  static const IconData translate = const IconData(0xe8e2);

  /// <p>Material icon "trending down": <i class="material-icons md-48">trending_down</i></p>
  static const IconData trending_down = const IconData(0xe8e3);

  /// <p>Material icon "trending flat": <i class="material-icons md-48">trending_flat</i></p>
  static const IconData trending_flat = const IconData(0xe8e4);

  /// <p>Material icon "trending up": <i class="material-icons md-48">trending_up</i></p>
  static const IconData trending_up = const IconData(0xe8e5);

  /// <p>Material icon "tune": <i class="material-icons md-48">tune</i></p>
  static const IconData tune = const IconData(0xe429);

  /// <p>Material icon "turned in": <i class="material-icons md-48">turned_in</i></p>
  static const IconData turned_in = const IconData(0xe8e6);

  /// <p>Material icon "turned in not": <i class="material-icons md-48">turned_in_not</i></p>
  static const IconData turned_in_not = const IconData(0xe8e7);

  /// <p>Material icon "tv": <i class="material-icons md-48">tv</i></p>
  static const IconData tv = const IconData(0xe333);

  /// <p>Material icon "unarchive": <i class="material-icons md-48">unarchive</i></p>
  static const IconData unarchive = const IconData(0xe169);

  /// <p>Material icon "undo": <i class="material-icons md-48">undo</i></p>
  static const IconData undo = const IconData(0xe166);

  /// <p>Material icon "unfold less": <i class="material-icons md-48">unfold_less</i></p>
  static const IconData unfold_less = const IconData(0xe5d6);

  /// <p>Material icon "unfold more": <i class="material-icons md-48">unfold_more</i></p>
  static const IconData unfold_more = const IconData(0xe5d7);

  /// <p>Material icon "update": <i class="material-icons md-48">update</i></p>
  static const IconData update = const IconData(0xe923);

  /// <p>Material icon "usb": <i class="material-icons md-48">usb</i></p>
  static const IconData usb = const IconData(0xe1e0);

  /// <p>Material icon "verified user": <i class="material-icons md-48">verified_user</i></p>
  static const IconData verified_user = const IconData(0xe8e8);

  /// <p>Material icon "vertical align bottom": <i class="material-icons md-48">vertical_align_bottom</i></p>
  static const IconData vertical_align_bottom = const IconData(0xe258);

  /// <p>Material icon "vertical align center": <i class="material-icons md-48">vertical_align_center</i></p>
  static const IconData vertical_align_center = const IconData(0xe259);

  /// <p>Material icon "vertical align top": <i class="material-icons md-48">vertical_align_top</i></p>
  static const IconData vertical_align_top = const IconData(0xe25a);

  /// <p>Material icon "vibration": <i class="material-icons md-48">vibration</i></p>
  static const IconData vibration = const IconData(0xe62d);

  /// <p>Material icon "video call": <i class="material-icons md-48">video_call</i></p>
  static const IconData video_call = const IconData(0xe070);

  /// <p>Material icon "video label": <i class="material-icons md-48">video_label</i></p>
  static const IconData video_label = const IconData(0xe071);

  /// <p>Material icon "video library": <i class="material-icons md-48">video_library</i></p>
  static const IconData video_library = const IconData(0xe04a);

  /// <p>Material icon "videocam": <i class="material-icons md-48">videocam</i></p>
  static const IconData videocam = const IconData(0xe04b);

  /// <p>Material icon "videocam off": <i class="material-icons md-48">videocam_off</i></p>
  static const IconData videocam_off = const IconData(0xe04c);

  /// <p>Material icon "videogame asset": <i class="material-icons md-48">videogame_asset</i></p>
  static const IconData videogame_asset = const IconData(0xe338);

  /// <p>Material icon "view agenda": <i class="material-icons md-48">view_agenda</i></p>
  static const IconData view_agenda = const IconData(0xe8e9);

  /// <p>Material icon "view array": <i class="material-icons md-48">view_array</i></p>
  static const IconData view_array = const IconData(0xe8ea);

  /// <p>Material icon "view carousel": <i class="material-icons md-48">view_carousel</i></p>
  static const IconData view_carousel = const IconData(0xe8eb);

  /// <p>Material icon "view column": <i class="material-icons md-48">view_column</i></p>
  static const IconData view_column = const IconData(0xe8ec);

  /// <p>Material icon "view comfy": <i class="material-icons md-48">view_comfy</i></p>
  static const IconData view_comfy = const IconData(0xe42a);

  /// <p>Material icon "view compact": <i class="material-icons md-48">view_compact</i></p>
  static const IconData view_compact = const IconData(0xe42b);

  /// <p>Material icon "view day": <i class="material-icons md-48">view_day</i></p>
  static const IconData view_day = const IconData(0xe8ed);

  /// <p>Material icon "view headline": <i class="material-icons md-48">view_headline</i></p>
  static const IconData view_headline = const IconData(0xe8ee);

  /// <p>Material icon "view list": <i class="material-icons md-48">view_list</i></p>
  static const IconData view_list = const IconData(0xe8ef);

  /// <p>Material icon "view module": <i class="material-icons md-48">view_module</i></p>
  static const IconData view_module = const IconData(0xe8f0);

  /// <p>Material icon "view quilt": <i class="material-icons md-48">view_quilt</i></p>
  static const IconData view_quilt = const IconData(0xe8f1);

  /// <p>Material icon "view stream": <i class="material-icons md-48">view_stream</i></p>
  static const IconData view_stream = const IconData(0xe8f2);

  /// <p>Material icon "view week": <i class="material-icons md-48">view_week</i></p>
  static const IconData view_week = const IconData(0xe8f3);

  /// <p>Material icon "vignette": <i class="material-icons md-48">vignette</i></p>
  static const IconData vignette = const IconData(0xe435);

  /// <p>Material icon "visibility": <i class="material-icons md-48">visibility</i></p>
  static const IconData visibility = const IconData(0xe8f4);

  /// <p>Material icon "visibility off": <i class="material-icons md-48">visibility_off</i></p>
  static const IconData visibility_off = const IconData(0xe8f5);

  /// <p>Material icon "voice chat": <i class="material-icons md-48">voice_chat</i></p>
  static const IconData voice_chat = const IconData(0xe62e);

  /// <p>Material icon "voicemail": <i class="material-icons md-48">voicemail</i></p>
  static const IconData voicemail = const IconData(0xe0d9);

  /// <p>Material icon "volume down": <i class="material-icons md-48">volume_down</i></p>
  static const IconData volume_down = const IconData(0xe04d);

  /// <p>Material icon "volume mute": <i class="material-icons md-48">volume_mute</i></p>
  static const IconData volume_mute = const IconData(0xe04e);

  /// <p>Material icon "volume off": <i class="material-icons md-48">volume_off</i></p>
  static const IconData volume_off = const IconData(0xe04f);

  /// <p>Material icon "volume up": <i class="material-icons md-48">volume_up</i></p>
  static const IconData volume_up = const IconData(0xe050);

  /// <p>Material icon "vpn key": <i class="material-icons md-48">vpn_key</i></p>
  static const IconData vpn_key = const IconData(0xe0da);

  /// <p>Material icon "vpn lock": <i class="material-icons md-48">vpn_lock</i></p>
  static const IconData vpn_lock = const IconData(0xe62f);

  /// <p>Material icon "wallpaper": <i class="material-icons md-48">wallpaper</i></p>
  static const IconData wallpaper = const IconData(0xe1bc);

  /// <p>Material icon "warning": <i class="material-icons md-48">warning</i></p>
  static const IconData warning = const IconData(0xe002);

  /// <p>Material icon "watch": <i class="material-icons md-48">watch</i></p>
  static const IconData watch = const IconData(0xe334);

  /// <p>Material icon "watch later": <i class="material-icons md-48">watch_later</i></p>
  static const IconData watch_later = const IconData(0xe924);

  /// <p>Material icon "wb auto": <i class="material-icons md-48">wb_auto</i></p>
  static const IconData wb_auto = const IconData(0xe42c);

  /// <p>Material icon "wb cloudy": <i class="material-icons md-48">wb_cloudy</i></p>
  static const IconData wb_cloudy = const IconData(0xe42d);

  /// <p>Material icon "wb incandescent": <i class="material-icons md-48">wb_incandescent</i></p>
  static const IconData wb_incandescent = const IconData(0xe42e);

  /// <p>Material icon "wb iridescent": <i class="material-icons md-48">wb_iridescent</i></p>
  static const IconData wb_iridescent = const IconData(0xe436);

  /// <p>Material icon "wb sunny": <i class="material-icons md-48">wb_sunny</i></p>
  static const IconData wb_sunny = const IconData(0xe430);

  /// <p>Material icon "wc": <i class="material-icons md-48">wc</i></p>
  static const IconData wc = const IconData(0xe63d);

  /// <p>Material icon "web": <i class="material-icons md-48">web</i></p>
  static const IconData web = const IconData(0xe051);

  /// <p>Material icon "web asset": <i class="material-icons md-48">web_asset</i></p>
  static const IconData web_asset = const IconData(0xe069);

  /// <p>Material icon "weekend": <i class="material-icons md-48">weekend</i></p>
  static const IconData weekend = const IconData(0xe16b);

  /// <p>Material icon "whatshot": <i class="material-icons md-48">whatshot</i></p>
  static const IconData whatshot = const IconData(0xe80e);

  /// <p>Material icon "widgets": <i class="material-icons md-48">widgets</i></p>
  static const IconData widgets = const IconData(0xe1bd);

  /// <p>Material icon "wifi": <i class="material-icons md-48">wifi</i></p>
  static const IconData wifi = const IconData(0xe63e);

  /// <p>Material icon "wifi lock": <i class="material-icons md-48">wifi_lock</i></p>
  static const IconData wifi_lock = const IconData(0xe1e1);

  /// <p>Material icon "wifi tethering": <i class="material-icons md-48">wifi_tethering</i></p>
  static const IconData wifi_tethering = const IconData(0xe1e2);

  /// <p>Material icon "work": <i class="material-icons md-48">work</i></p>
  static const IconData work = const IconData(0xe8f9);

  /// <p>Material icon "wrap text": <i class="material-icons md-48">wrap_text</i></p>
  static const IconData wrap_text = const IconData(0xe25b);

  /// <p>Material icon "youtube searched for": <i class="material-icons md-48">youtube_searched_for</i></p>
  static const IconData youtube_searched_for = const IconData(0xe8fa);

  /// <p>Material icon "zoom in": <i class="material-icons md-48">zoom_in</i></p>
  static const IconData zoom_in = const IconData(0xe8ff);

  /// <p>Material icon "zoom out": <i class="material-icons md-48">zoom_out</i></p>
  static const IconData zoom_out = const IconData(0xe900);

  /// <p>Material icon "zoom out map": <i class="material-icons md-48">zoom_out_map</i></p>
  static const IconData zoom_out_map = const IconData(0xe56b);
}
