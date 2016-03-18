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

  /// Material icon "3d rotation": <i class="material-icons md-48">3d_rotation</i>
  static const IconData threed_rotation = const IconData(0xe84d); // 3d_rotation isn't a valid identifier.

  /// Material icon "ac unit": <i class="material-icons md-48">ac_unit</i>
  static const IconData ac_unit = const IconData(0xeb3b);

  /// Material icon "access alarm": <i class="material-icons md-48">access_alarm</i>
  static const IconData access_alarm = const IconData(0xe190);

  /// Material icon "access alarms": <i class="material-icons md-48">access_alarms</i>
  static const IconData access_alarms = const IconData(0xe191);

  /// Material icon "access time": <i class="material-icons md-48">access_time</i>
  static const IconData access_time = const IconData(0xe192);

  /// Material icon "accessibility": <i class="material-icons md-48">accessibility</i>
  static const IconData accessibility = const IconData(0xe84e);

  /// Material icon "accessible": <i class="material-icons md-48">accessible</i>
  static const IconData accessible = const IconData(0xe914);

  /// Material icon "account balance": <i class="material-icons md-48">account_balance</i>
  static const IconData account_balance = const IconData(0xe84f);

  /// Material icon "account balance wallet": <i class="material-icons md-48">account_balance_wallet</i>
  static const IconData account_balance_wallet = const IconData(0xe850);

  /// Material icon "account box": <i class="material-icons md-48">account_box</i>
  static const IconData account_box = const IconData(0xe851);

  /// Material icon "account circle": <i class="material-icons md-48">account_circle</i>
  static const IconData account_circle = const IconData(0xe853);

  /// Material icon "adb": <i class="material-icons md-48">adb</i>
  static const IconData adb = const IconData(0xe60e);

  /// Material icon "add": <i class="material-icons md-48">add</i>
  static const IconData add = const IconData(0xe145);

  /// Material icon "add a photo": <i class="material-icons md-48">add_a_photo</i>
  static const IconData add_a_photo = const IconData(0xe439);

  /// Material icon "add alarm": <i class="material-icons md-48">add_alarm</i>
  static const IconData add_alarm = const IconData(0xe193);

  /// Material icon "add alert": <i class="material-icons md-48">add_alert</i>
  static const IconData add_alert = const IconData(0xe003);

  /// Material icon "add box": <i class="material-icons md-48">add_box</i>
  static const IconData add_box = const IconData(0xe146);

  /// Material icon "add circle": <i class="material-icons md-48">add_circle</i>
  static const IconData add_circle = const IconData(0xe147);

  /// Material icon "add circle outline": <i class="material-icons md-48">add_circle_outline</i>
  static const IconData add_circle_outline = const IconData(0xe148);

  /// Material icon "add location": <i class="material-icons md-48">add_location</i>
  static const IconData add_location = const IconData(0xe567);

  /// Material icon "add shopping cart": <i class="material-icons md-48">add_shopping_cart</i>
  static const IconData add_shopping_cart = const IconData(0xe854);

  /// Material icon "add to photos": <i class="material-icons md-48">add_to_photos</i>
  static const IconData add_to_photos = const IconData(0xe39d);

  /// Material icon "add to queue": <i class="material-icons md-48">add_to_queue</i>
  static const IconData add_to_queue = const IconData(0xe05c);

  /// Material icon "adjust": <i class="material-icons md-48">adjust</i>
  static const IconData adjust = const IconData(0xe39e);

  /// Material icon "airline seat flat": <i class="material-icons md-48">airline_seat_flat</i>
  static const IconData airline_seat_flat = const IconData(0xe630);

  /// Material icon "airline seat flat angled": <i class="material-icons md-48">airline_seat_flat_angled</i>
  static const IconData airline_seat_flat_angled = const IconData(0xe631);

  /// Material icon "airline seat individual suite": <i class="material-icons md-48">airline_seat_individual_suite</i>
  static const IconData airline_seat_individual_suite = const IconData(0xe632);

  /// Material icon "airline seat legroom extra": <i class="material-icons md-48">airline_seat_legroom_extra</i>
  static const IconData airline_seat_legroom_extra = const IconData(0xe633);

  /// Material icon "airline seat legroom normal": <i class="material-icons md-48">airline_seat_legroom_normal</i>
  static const IconData airline_seat_legroom_normal = const IconData(0xe634);

  /// Material icon "airline seat legroom reduced": <i class="material-icons md-48">airline_seat_legroom_reduced</i>
  static const IconData airline_seat_legroom_reduced = const IconData(0xe635);

  /// Material icon "airline seat recline extra": <i class="material-icons md-48">airline_seat_recline_extra</i>
  static const IconData airline_seat_recline_extra = const IconData(0xe636);

  /// Material icon "airline seat recline normal": <i class="material-icons md-48">airline_seat_recline_normal</i>
  static const IconData airline_seat_recline_normal = const IconData(0xe637);

  /// Material icon "airplanemode active": <i class="material-icons md-48">airplanemode_active</i>
  static const IconData airplanemode_active = const IconData(0xe195);

  /// Material icon "airplanemode inactive": <i class="material-icons md-48">airplanemode_inactive</i>
  static const IconData airplanemode_inactive = const IconData(0xe194);

  /// Material icon "airplay": <i class="material-icons md-48">airplay</i>
  static const IconData airplay = const IconData(0xe055);

  /// Material icon "airport shuttle": <i class="material-icons md-48">airport_shuttle</i>
  static const IconData airport_shuttle = const IconData(0xeb3c);

  /// Material icon "alarm": <i class="material-icons md-48">alarm</i>
  static const IconData alarm = const IconData(0xe855);

  /// Material icon "alarm add": <i class="material-icons md-48">alarm_add</i>
  static const IconData alarm_add = const IconData(0xe856);

  /// Material icon "alarm off": <i class="material-icons md-48">alarm_off</i>
  static const IconData alarm_off = const IconData(0xe857);

  /// Material icon "alarm on": <i class="material-icons md-48">alarm_on</i>
  static const IconData alarm_on = const IconData(0xe858);

  /// Material icon "album": <i class="material-icons md-48">album</i>
  static const IconData album = const IconData(0xe019);

  /// Material icon "all inclusive": <i class="material-icons md-48">all_inclusive</i>
  static const IconData all_inclusive = const IconData(0xeb3d);

  /// Material icon "all out": <i class="material-icons md-48">all_out</i>
  static const IconData all_out = const IconData(0xe90b);

  /// Material icon "android": <i class="material-icons md-48">android</i>
  static const IconData android = const IconData(0xe859);

  /// Material icon "announcement": <i class="material-icons md-48">announcement</i>
  static const IconData announcement = const IconData(0xe85a);

  /// Material icon "apps": <i class="material-icons md-48">apps</i>
  static const IconData apps = const IconData(0xe5c3);

  /// Material icon "archive": <i class="material-icons md-48">archive</i>
  static const IconData archive = const IconData(0xe149);

  /// Material icon "arrow back": <i class="material-icons md-48">arrow_back</i>
  static const IconData arrow_back = const IconData(0xe5c4);

  /// Material icon "arrow downward": <i class="material-icons md-48">arrow_downward</i>
  static const IconData arrow_downward = const IconData(0xe5db);

  /// Material icon "arrow drop down": <i class="material-icons md-48">arrow_drop_down</i>
  static const IconData arrow_drop_down = const IconData(0xe5c5);

  /// Material icon "arrow drop down circle": <i class="material-icons md-48">arrow_drop_down_circle</i>
  static const IconData arrow_drop_down_circle = const IconData(0xe5c6);

  /// Material icon "arrow drop up": <i class="material-icons md-48">arrow_drop_up</i>
  static const IconData arrow_drop_up = const IconData(0xe5c7);

  /// Material icon "arrow forward": <i class="material-icons md-48">arrow_forward</i>
  static const IconData arrow_forward = const IconData(0xe5c8);

  /// Material icon "arrow upward": <i class="material-icons md-48">arrow_upward</i>
  static const IconData arrow_upward = const IconData(0xe5d8);

  /// Material icon "art track": <i class="material-icons md-48">art_track</i>
  static const IconData art_track = const IconData(0xe060);

  /// Material icon "aspect ratio": <i class="material-icons md-48">aspect_ratio</i>
  static const IconData aspect_ratio = const IconData(0xe85b);

  /// Material icon "assessment": <i class="material-icons md-48">assessment</i>
  static const IconData assessment = const IconData(0xe85c);

  /// Material icon "assignment": <i class="material-icons md-48">assignment</i>
  static const IconData assignment = const IconData(0xe85d);

  /// Material icon "assignment ind": <i class="material-icons md-48">assignment_ind</i>
  static const IconData assignment_ind = const IconData(0xe85e);

  /// Material icon "assignment late": <i class="material-icons md-48">assignment_late</i>
  static const IconData assignment_late = const IconData(0xe85f);

  /// Material icon "assignment return": <i class="material-icons md-48">assignment_return</i>
  static const IconData assignment_return = const IconData(0xe860);

  /// Material icon "assignment returned": <i class="material-icons md-48">assignment_returned</i>
  static const IconData assignment_returned = const IconData(0xe861);

  /// Material icon "assignment turned in": <i class="material-icons md-48">assignment_turned_in</i>
  static const IconData assignment_turned_in = const IconData(0xe862);

  /// Material icon "assistant": <i class="material-icons md-48">assistant</i>
  static const IconData assistant = const IconData(0xe39f);

  /// Material icon "assistant photo": <i class="material-icons md-48">assistant_photo</i>
  static const IconData assistant_photo = const IconData(0xe3a0);

  /// Material icon "attach file": <i class="material-icons md-48">attach_file</i>
  static const IconData attach_file = const IconData(0xe226);

  /// Material icon "attach money": <i class="material-icons md-48">attach_money</i>
  static const IconData attach_money = const IconData(0xe227);

  /// Material icon "attachment": <i class="material-icons md-48">attachment</i>
  static const IconData attachment = const IconData(0xe2bc);

  /// Material icon "audiotrack": <i class="material-icons md-48">audiotrack</i>
  static const IconData audiotrack = const IconData(0xe3a1);

  /// Material icon "autoreconst": <i class="material-icons md-48">autoreconst</i>
  static const IconData autoreconst = const IconData(0xe863);

  /// Material icon "av timer": <i class="material-icons md-48">av_timer</i>
  static const IconData av_timer = const IconData(0xe01b);

  /// Material icon "backspace": <i class="material-icons md-48">backspace</i>
  static const IconData backspace = const IconData(0xe14a);

  /// Material icon "backup": <i class="material-icons md-48">backup</i>
  static const IconData backup = const IconData(0xe864);

  /// Material icon "battery alert": <i class="material-icons md-48">battery_alert</i>
  static const IconData battery_alert = const IconData(0xe19c);

  /// Material icon "battery charging full": <i class="material-icons md-48">battery_charging_full</i>
  static const IconData battery_charging_full = const IconData(0xe1a3);

  /// Material icon "battery full": <i class="material-icons md-48">battery_full</i>
  static const IconData battery_full = const IconData(0xe1a4);

  /// Material icon "battery std": <i class="material-icons md-48">battery_std</i>
  static const IconData battery_std = const IconData(0xe1a5);

  /// Material icon "battery unknown": <i class="material-icons md-48">battery_unknown</i>
  static const IconData battery_unknown = const IconData(0xe1a6);

  /// Material icon "beach access": <i class="material-icons md-48">beach_access</i>
  static const IconData beach_access = const IconData(0xeb3e);

  /// Material icon "beenhere": <i class="material-icons md-48">beenhere</i>
  static const IconData beenhere = const IconData(0xe52d);

  /// Material icon "block": <i class="material-icons md-48">block</i>
  static const IconData block = const IconData(0xe14b);

  /// Material icon "bluetooth": <i class="material-icons md-48">bluetooth</i>
  static const IconData bluetooth = const IconData(0xe1a7);

  /// Material icon "bluetooth audio": <i class="material-icons md-48">bluetooth_audio</i>
  static const IconData bluetooth_audio = const IconData(0xe60f);

  /// Material icon "bluetooth connected": <i class="material-icons md-48">bluetooth_connected</i>
  static const IconData bluetooth_connected = const IconData(0xe1a8);

  /// Material icon "bluetooth disabled": <i class="material-icons md-48">bluetooth_disabled</i>
  static const IconData bluetooth_disabled = const IconData(0xe1a9);

  /// Material icon "bluetooth searching": <i class="material-icons md-48">bluetooth_searching</i>
  static const IconData bluetooth_searching = const IconData(0xe1aa);

  /// Material icon "blur circular": <i class="material-icons md-48">blur_circular</i>
  static const IconData blur_circular = const IconData(0xe3a2);

  /// Material icon "blur linear": <i class="material-icons md-48">blur_linear</i>
  static const IconData blur_linear = const IconData(0xe3a3);

  /// Material icon "blur off": <i class="material-icons md-48">blur_off</i>
  static const IconData blur_off = const IconData(0xe3a4);

  /// Material icon "blur on": <i class="material-icons md-48">blur_on</i>
  static const IconData blur_on = const IconData(0xe3a5);

  /// Material icon "book": <i class="material-icons md-48">book</i>
  static const IconData book = const IconData(0xe865);

  /// Material icon "bookmark": <i class="material-icons md-48">bookmark</i>
  static const IconData bookmark = const IconData(0xe866);

  /// Material icon "bookmark border": <i class="material-icons md-48">bookmark_border</i>
  static const IconData bookmark_border = const IconData(0xe867);

  /// Material icon "border all": <i class="material-icons md-48">border_all</i>
  static const IconData border_all = const IconData(0xe228);

  /// Material icon "border bottom": <i class="material-icons md-48">border_bottom</i>
  static const IconData border_bottom = const IconData(0xe229);

  /// Material icon "border clear": <i class="material-icons md-48">border_clear</i>
  static const IconData border_clear = const IconData(0xe22a);

  /// Material icon "border color": <i class="material-icons md-48">border_color</i>
  static const IconData border_color = const IconData(0xe22b);

  /// Material icon "border horizontal": <i class="material-icons md-48">border_horizontal</i>
  static const IconData border_horizontal = const IconData(0xe22c);

  /// Material icon "border inner": <i class="material-icons md-48">border_inner</i>
  static const IconData border_inner = const IconData(0xe22d);

  /// Material icon "border left": <i class="material-icons md-48">border_left</i>
  static const IconData border_left = const IconData(0xe22e);

  /// Material icon "border outer": <i class="material-icons md-48">border_outer</i>
  static const IconData border_outer = const IconData(0xe22f);

  /// Material icon "border right": <i class="material-icons md-48">border_right</i>
  static const IconData border_right = const IconData(0xe230);

  /// Material icon "border style": <i class="material-icons md-48">border_style</i>
  static const IconData border_style = const IconData(0xe231);

  /// Material icon "border top": <i class="material-icons md-48">border_top</i>
  static const IconData border_top = const IconData(0xe232);

  /// Material icon "border vertical": <i class="material-icons md-48">border_vertical</i>
  static const IconData border_vertical = const IconData(0xe233);

  /// Material icon "branding watermark": <i class="material-icons md-48">branding_watermark</i>
  static const IconData branding_watermark = const IconData(0xe06b);

  /// Material icon "brightness 1": <i class="material-icons md-48">brightness_1</i>
  static const IconData brightness_1 = const IconData(0xe3a6);

  /// Material icon "brightness 2": <i class="material-icons md-48">brightness_2</i>
  static const IconData brightness_2 = const IconData(0xe3a7);

  /// Material icon "brightness 3": <i class="material-icons md-48">brightness_3</i>
  static const IconData brightness_3 = const IconData(0xe3a8);

  /// Material icon "brightness 4": <i class="material-icons md-48">brightness_4</i>
  static const IconData brightness_4 = const IconData(0xe3a9);

  /// Material icon "brightness 5": <i class="material-icons md-48">brightness_5</i>
  static const IconData brightness_5 = const IconData(0xe3aa);

  /// Material icon "brightness 6": <i class="material-icons md-48">brightness_6</i>
  static const IconData brightness_6 = const IconData(0xe3ab);

  /// Material icon "brightness 7": <i class="material-icons md-48">brightness_7</i>
  static const IconData brightness_7 = const IconData(0xe3ac);

  /// Material icon "brightness auto": <i class="material-icons md-48">brightness_auto</i>
  static const IconData brightness_auto = const IconData(0xe1ab);

  /// Material icon "brightness high": <i class="material-icons md-48">brightness_high</i>
  static const IconData brightness_high = const IconData(0xe1ac);

  /// Material icon "brightness low": <i class="material-icons md-48">brightness_low</i>
  static const IconData brightness_low = const IconData(0xe1ad);

  /// Material icon "brightness medium": <i class="material-icons md-48">brightness_medium</i>
  static const IconData brightness_medium = const IconData(0xe1ae);

  /// Material icon "broken image": <i class="material-icons md-48">broken_image</i>
  static const IconData broken_image = const IconData(0xe3ad);

  /// Material icon "brush": <i class="material-icons md-48">brush</i>
  static const IconData brush = const IconData(0xe3ae);

  /// Material icon "bubble chart": <i class="material-icons md-48">bubble_chart</i>
  static const IconData bubble_chart = const IconData(0xe6dd);

  /// Material icon "bug report": <i class="material-icons md-48">bug_report</i>
  static const IconData bug_report = const IconData(0xe868);

  /// Material icon "build": <i class="material-icons md-48">build</i>
  static const IconData build = const IconData(0xe869);

  /// Material icon "burst mode": <i class="material-icons md-48">burst_mode</i>
  static const IconData burst_mode = const IconData(0xe43c);

  /// Material icon "business": <i class="material-icons md-48">business</i>
  static const IconData business = const IconData(0xe0af);

  /// Material icon "business center": <i class="material-icons md-48">business_center</i>
  static const IconData business_center = const IconData(0xeb3f);

  /// Material icon "cached": <i class="material-icons md-48">cached</i>
  static const IconData cached = const IconData(0xe86a);

  /// Material icon "cake": <i class="material-icons md-48">cake</i>
  static const IconData cake = const IconData(0xe7e9);

  /// Material icon "call": <i class="material-icons md-48">call</i>
  static const IconData call = const IconData(0xe0b0);

  /// Material icon "call end": <i class="material-icons md-48">call_end</i>
  static const IconData call_end = const IconData(0xe0b1);

  /// Material icon "call made": <i class="material-icons md-48">call_made</i>
  static const IconData call_made = const IconData(0xe0b2);

  /// Material icon "call merge": <i class="material-icons md-48">call_merge</i>
  static const IconData call_merge = const IconData(0xe0b3);

  /// Material icon "call missed": <i class="material-icons md-48">call_missed</i>
  static const IconData call_missed = const IconData(0xe0b4);

  /// Material icon "call missed outgoing": <i class="material-icons md-48">call_missed_outgoing</i>
  static const IconData call_missed_outgoing = const IconData(0xe0e4);

  /// Material icon "call received": <i class="material-icons md-48">call_received</i>
  static const IconData call_received = const IconData(0xe0b5);

  /// Material icon "call split": <i class="material-icons md-48">call_split</i>
  static const IconData call_split = const IconData(0xe0b6);

  /// Material icon "call to action": <i class="material-icons md-48">call_to_action</i>
  static const IconData call_to_action = const IconData(0xe06c);

  /// Material icon "camera": <i class="material-icons md-48">camera</i>
  static const IconData camera = const IconData(0xe3af);

  /// Material icon "camera alt": <i class="material-icons md-48">camera_alt</i>
  static const IconData camera_alt = const IconData(0xe3b0);

  /// Material icon "camera enhance": <i class="material-icons md-48">camera_enhance</i>
  static const IconData camera_enhance = const IconData(0xe8fc);

  /// Material icon "camera front": <i class="material-icons md-48">camera_front</i>
  static const IconData camera_front = const IconData(0xe3b1);

  /// Material icon "camera rear": <i class="material-icons md-48">camera_rear</i>
  static const IconData camera_rear = const IconData(0xe3b2);

  /// Material icon "camera roll": <i class="material-icons md-48">camera_roll</i>
  static const IconData camera_roll = const IconData(0xe3b3);

  /// Material icon "cancel": <i class="material-icons md-48">cancel</i>
  static const IconData cancel = const IconData(0xe5c9);

  /// Material icon "card giftcard": <i class="material-icons md-48">card_giftcard</i>
  static const IconData card_giftcard = const IconData(0xe8f6);

  /// Material icon "card membership": <i class="material-icons md-48">card_membership</i>
  static const IconData card_membership = const IconData(0xe8f7);

  /// Material icon "card travel": <i class="material-icons md-48">card_travel</i>
  static const IconData card_travel = const IconData(0xe8f8);

  /// Material icon "casino": <i class="material-icons md-48">casino</i>
  static const IconData casino = const IconData(0xeb40);

  /// Material icon "cast": <i class="material-icons md-48">cast</i>
  static const IconData cast = const IconData(0xe307);

  /// Material icon "cast connected": <i class="material-icons md-48">cast_connected</i>
  static const IconData cast_connected = const IconData(0xe308);

  /// Material icon "center focus strong": <i class="material-icons md-48">center_focus_strong</i>
  static const IconData center_focus_strong = const IconData(0xe3b4);

  /// Material icon "center focus weak": <i class="material-icons md-48">center_focus_weak</i>
  static const IconData center_focus_weak = const IconData(0xe3b5);

  /// Material icon "change history": <i class="material-icons md-48">change_history</i>
  static const IconData change_history = const IconData(0xe86b);

  /// Material icon "chat": <i class="material-icons md-48">chat</i>
  static const IconData chat = const IconData(0xe0b7);

  /// Material icon "chat bubble": <i class="material-icons md-48">chat_bubble</i>
  static const IconData chat_bubble = const IconData(0xe0ca);

  /// Material icon "chat bubble outline": <i class="material-icons md-48">chat_bubble_outline</i>
  static const IconData chat_bubble_outline = const IconData(0xe0cb);

  /// Material icon "check": <i class="material-icons md-48">check</i>
  static const IconData check = const IconData(0xe5ca);

  /// Material icon "check box": <i class="material-icons md-48">check_box</i>
  static const IconData check_box = const IconData(0xe834);

  /// Material icon "check box outline blank": <i class="material-icons md-48">check_box_outline_blank</i>
  static const IconData check_box_outline_blank = const IconData(0xe835);

  /// Material icon "check circle": <i class="material-icons md-48">check_circle</i>
  static const IconData check_circle = const IconData(0xe86c);

  /// Material icon "chevron left": <i class="material-icons md-48">chevron_left</i>
  static const IconData chevron_left = const IconData(0xe5cb);

  /// Material icon "chevron right": <i class="material-icons md-48">chevron_right</i>
  static const IconData chevron_right = const IconData(0xe5cc);

  /// Material icon "child care": <i class="material-icons md-48">child_care</i>
  static const IconData child_care = const IconData(0xeb41);

  /// Material icon "child friendly": <i class="material-icons md-48">child_friendly</i>
  static const IconData child_friendly = const IconData(0xeb42);

  /// Material icon "chrome reader mode": <i class="material-icons md-48">chrome_reader_mode</i>
  static const IconData chrome_reader_mode = const IconData(0xe86d);

  /// Material icon "class": <i class="material-icons md-48">class</i>
  static const IconData class_ = const IconData(0xe86e); // class is a reserved word in Dart.

  /// Material icon "clear": <i class="material-icons md-48">clear</i>
  static const IconData clear = const IconData(0xe14c);

  /// Material icon "clear all": <i class="material-icons md-48">clear_all</i>
  static const IconData clear_all = const IconData(0xe0b8);

  /// Material icon "close": <i class="material-icons md-48">close</i>
  static const IconData close = const IconData(0xe5cd);

  /// Material icon "closed caption": <i class="material-icons md-48">closed_caption</i>
  static const IconData closed_caption = const IconData(0xe01c);

  /// Material icon "cloud": <i class="material-icons md-48">cloud</i>
  static const IconData cloud = const IconData(0xe2bd);

  /// Material icon "cloud circle": <i class="material-icons md-48">cloud_circle</i>
  static const IconData cloud_circle = const IconData(0xe2be);

  /// Material icon "cloud done": <i class="material-icons md-48">cloud_done</i>
  static const IconData cloud_done = const IconData(0xe2bf);

  /// Material icon "cloud download": <i class="material-icons md-48">cloud_download</i>
  static const IconData cloud_download = const IconData(0xe2c0);

  /// Material icon "cloud off": <i class="material-icons md-48">cloud_off</i>
  static const IconData cloud_off = const IconData(0xe2c1);

  /// Material icon "cloud queue": <i class="material-icons md-48">cloud_queue</i>
  static const IconData cloud_queue = const IconData(0xe2c2);

  /// Material icon "cloud upload": <i class="material-icons md-48">cloud_upload</i>
  static const IconData cloud_upload = const IconData(0xe2c3);

  /// Material icon "code": <i class="material-icons md-48">code</i>
  static const IconData code = const IconData(0xe86f);

  /// Material icon "collections": <i class="material-icons md-48">collections</i>
  static const IconData collections = const IconData(0xe3b6);

  /// Material icon "collections bookmark": <i class="material-icons md-48">collections_bookmark</i>
  static const IconData collections_bookmark = const IconData(0xe431);

  /// Material icon "color lens": <i class="material-icons md-48">color_lens</i>
  static const IconData color_lens = const IconData(0xe3b7);

  /// Material icon "colorize": <i class="material-icons md-48">colorize</i>
  static const IconData colorize = const IconData(0xe3b8);

  /// Material icon "comment": <i class="material-icons md-48">comment</i>
  static const IconData comment = const IconData(0xe0b9);

  /// Material icon "compare": <i class="material-icons md-48">compare</i>
  static const IconData compare = const IconData(0xe3b9);

  /// Material icon "compare arrows": <i class="material-icons md-48">compare_arrows</i>
  static const IconData compare_arrows = const IconData(0xe915);

  /// Material icon "computer": <i class="material-icons md-48">computer</i>
  static const IconData computer = const IconData(0xe30a);

  /// Material icon "confirmation number": <i class="material-icons md-48">confirmation_number</i>
  static const IconData confirmation_number = const IconData(0xe638);

  /// Material icon "contact mail": <i class="material-icons md-48">contact_mail</i>
  static const IconData contact_mail = const IconData(0xe0d0);

  /// Material icon "contact phone": <i class="material-icons md-48">contact_phone</i>
  static const IconData contact_phone = const IconData(0xe0cf);

  /// Material icon "contacts": <i class="material-icons md-48">contacts</i>
  static const IconData contacts = const IconData(0xe0ba);

  /// Material icon "content copy": <i class="material-icons md-48">content_copy</i>
  static const IconData content_copy = const IconData(0xe14d);

  /// Material icon "content cut": <i class="material-icons md-48">content_cut</i>
  static const IconData content_cut = const IconData(0xe14e);

  /// Material icon "content paste": <i class="material-icons md-48">content_paste</i>
  static const IconData content_paste = const IconData(0xe14f);

  /// Material icon "control point": <i class="material-icons md-48">control_point</i>
  static const IconData control_point = const IconData(0xe3ba);

  /// Material icon "control point duplicate": <i class="material-icons md-48">control_point_duplicate</i>
  static const IconData control_point_duplicate = const IconData(0xe3bb);

  /// Material icon "copyright": <i class="material-icons md-48">copyright</i>
  static const IconData copyright = const IconData(0xe90c);

  /// Material icon "create": <i class="material-icons md-48">create</i>
  static const IconData create = const IconData(0xe150);

  /// Material icon "create const folder": <i class="material-icons md-48">create_const_folder</i>
  static const IconData create_const_folder = const IconData(0xe2cc);

  /// Material icon "credit card": <i class="material-icons md-48">credit_card</i>
  static const IconData credit_card = const IconData(0xe870);

  /// Material icon "crop": <i class="material-icons md-48">crop</i>
  static const IconData crop = const IconData(0xe3be);

  /// Material icon "crop 16 9": <i class="material-icons md-48">crop_16_9</i>
  static const IconData crop_16_9 = const IconData(0xe3bc);

  /// Material icon "crop 3 2": <i class="material-icons md-48">crop_3_2</i>
  static const IconData crop_3_2 = const IconData(0xe3bd);

  /// Material icon "crop 5 4": <i class="material-icons md-48">crop_5_4</i>
  static const IconData crop_5_4 = const IconData(0xe3bf);

  /// Material icon "crop 7 5": <i class="material-icons md-48">crop_7_5</i>
  static const IconData crop_7_5 = const IconData(0xe3c0);

  /// Material icon "crop din": <i class="material-icons md-48">crop_din</i>
  static const IconData crop_din = const IconData(0xe3c1);

  /// Material icon "crop free": <i class="material-icons md-48">crop_free</i>
  static const IconData crop_free = const IconData(0xe3c2);

  /// Material icon "crop landscape": <i class="material-icons md-48">crop_landscape</i>
  static const IconData crop_landscape = const IconData(0xe3c3);

  /// Material icon "crop original": <i class="material-icons md-48">crop_original</i>
  static const IconData crop_original = const IconData(0xe3c4);

  /// Material icon "crop portrait": <i class="material-icons md-48">crop_portrait</i>
  static const IconData crop_portrait = const IconData(0xe3c5);

  /// Material icon "crop rotate": <i class="material-icons md-48">crop_rotate</i>
  static const IconData crop_rotate = const IconData(0xe437);

  /// Material icon "crop square": <i class="material-icons md-48">crop_square</i>
  static const IconData crop_square = const IconData(0xe3c6);

  /// Material icon "dashboard": <i class="material-icons md-48">dashboard</i>
  static const IconData dashboard = const IconData(0xe871);

  /// Material icon "data usage": <i class="material-icons md-48">data_usage</i>
  static const IconData data_usage = const IconData(0xe1af);

  /// Material icon "date range": <i class="material-icons md-48">date_range</i>
  static const IconData date_range = const IconData(0xe916);

  /// Material icon "dehaze": <i class="material-icons md-48">dehaze</i>
  static const IconData dehaze = const IconData(0xe3c7);

  /// Material icon "delete": <i class="material-icons md-48">delete</i>
  static const IconData delete = const IconData(0xe872);

  /// Material icon "delete forever": <i class="material-icons md-48">delete_forever</i>
  static const IconData delete_forever = const IconData(0xe92b);

  /// Material icon "delete sweep": <i class="material-icons md-48">delete_sweep</i>
  static const IconData delete_sweep = const IconData(0xe16c);

  /// Material icon "description": <i class="material-icons md-48">description</i>
  static const IconData description = const IconData(0xe873);

  /// Material icon "desktop mac": <i class="material-icons md-48">desktop_mac</i>
  static const IconData desktop_mac = const IconData(0xe30b);

  /// Material icon "desktop windows": <i class="material-icons md-48">desktop_windows</i>
  static const IconData desktop_windows = const IconData(0xe30c);

  /// Material icon "details": <i class="material-icons md-48">details</i>
  static const IconData details = const IconData(0xe3c8);

  /// Material icon "developer board": <i class="material-icons md-48">developer_board</i>
  static const IconData developer_board = const IconData(0xe30d);

  /// Material icon "developer mode": <i class="material-icons md-48">developer_mode</i>
  static const IconData developer_mode = const IconData(0xe1b0);

  /// Material icon "device hub": <i class="material-icons md-48">device_hub</i>
  static const IconData device_hub = const IconData(0xe335);

  /// Material icon "devices": <i class="material-icons md-48">devices</i>
  static const IconData devices = const IconData(0xe1b1);

  /// Material icon "devices other": <i class="material-icons md-48">devices_other</i>
  static const IconData devices_other = const IconData(0xe337);

  /// Material icon "dialer sip": <i class="material-icons md-48">dialer_sip</i>
  static const IconData dialer_sip = const IconData(0xe0bb);

  /// Material icon "dialpad": <i class="material-icons md-48">dialpad</i>
  static const IconData dialpad = const IconData(0xe0bc);

  /// Material icon "directions": <i class="material-icons md-48">directions</i>
  static const IconData directions = const IconData(0xe52e);

  /// Material icon "directions bike": <i class="material-icons md-48">directions_bike</i>
  static const IconData directions_bike = const IconData(0xe52f);

  /// Material icon "directions boat": <i class="material-icons md-48">directions_boat</i>
  static const IconData directions_boat = const IconData(0xe532);

  /// Material icon "directions bus": <i class="material-icons md-48">directions_bus</i>
  static const IconData directions_bus = const IconData(0xe530);

  /// Material icon "directions car": <i class="material-icons md-48">directions_car</i>
  static const IconData directions_car = const IconData(0xe531);

  /// Material icon "directions railway": <i class="material-icons md-48">directions_railway</i>
  static const IconData directions_railway = const IconData(0xe534);

  /// Material icon "directions run": <i class="material-icons md-48">directions_run</i>
  static const IconData directions_run = const IconData(0xe566);

  /// Material icon "directions subway": <i class="material-icons md-48">directions_subway</i>
  static const IconData directions_subway = const IconData(0xe533);

  /// Material icon "directions transit": <i class="material-icons md-48">directions_transit</i>
  static const IconData directions_transit = const IconData(0xe535);

  /// Material icon "directions walk": <i class="material-icons md-48">directions_walk</i>
  static const IconData directions_walk = const IconData(0xe536);

  /// Material icon "disc full": <i class="material-icons md-48">disc_full</i>
  static const IconData disc_full = const IconData(0xe610);

  /// Material icon "dns": <i class="material-icons md-48">dns</i>
  static const IconData dns = const IconData(0xe875);

  /// Material icon "do not disturb": <i class="material-icons md-48">do_not_disturb</i>
  static const IconData do_not_disturb = const IconData(0xe612);

  /// Material icon "do not disturb alt": <i class="material-icons md-48">do_not_disturb_alt</i>
  static const IconData do_not_disturb_alt = const IconData(0xe611);

  /// Material icon "do not disturb off": <i class="material-icons md-48">do_not_disturb_off</i>
  static const IconData do_not_disturb_off = const IconData(0xe643);

  /// Material icon "do not disturb on": <i class="material-icons md-48">do_not_disturb_on</i>
  static const IconData do_not_disturb_on = const IconData(0xe644);

  /// Material icon "dock": <i class="material-icons md-48">dock</i>
  static const IconData dock = const IconData(0xe30e);

  /// Material icon "domain": <i class="material-icons md-48">domain</i>
  static const IconData domain = const IconData(0xe7ee);

  /// Material icon "done": <i class="material-icons md-48">done</i>
  static const IconData done = const IconData(0xe876);

  /// Material icon "done all": <i class="material-icons md-48">done_all</i>
  static const IconData done_all = const IconData(0xe877);

  /// Material icon "donut large": <i class="material-icons md-48">donut_large</i>
  static const IconData donut_large = const IconData(0xe917);

  /// Material icon "donut small": <i class="material-icons md-48">donut_small</i>
  static const IconData donut_small = const IconData(0xe918);

  /// Material icon "drafts": <i class="material-icons md-48">drafts</i>
  static const IconData drafts = const IconData(0xe151);

  /// Material icon "drag handle": <i class="material-icons md-48">drag_handle</i>
  static const IconData drag_handle = const IconData(0xe25d);

  /// Material icon "drive eta": <i class="material-icons md-48">drive_eta</i>
  static const IconData drive_eta = const IconData(0xe613);

  /// Material icon "dvr": <i class="material-icons md-48">dvr</i>
  static const IconData dvr = const IconData(0xe1b2);

  /// Material icon "edit": <i class="material-icons md-48">edit</i>
  static const IconData edit = const IconData(0xe3c9);

  /// Material icon "edit location": <i class="material-icons md-48">edit_location</i>
  static const IconData edit_location = const IconData(0xe568);

  /// Material icon "eject": <i class="material-icons md-48">eject</i>
  static const IconData eject = const IconData(0xe8fb);

  /// Material icon "email": <i class="material-icons md-48">email</i>
  static const IconData email = const IconData(0xe0be);

  /// Material icon "enhanced encryption": <i class="material-icons md-48">enhanced_encryption</i>
  static const IconData enhanced_encryption = const IconData(0xe63f);

  /// Material icon "equalizer": <i class="material-icons md-48">equalizer</i>
  static const IconData equalizer = const IconData(0xe01d);

  /// Material icon "error": <i class="material-icons md-48">error</i>
  static const IconData error = const IconData(0xe000);

  /// Material icon "error outline": <i class="material-icons md-48">error_outline</i>
  static const IconData error_outline = const IconData(0xe001);

  /// Material icon "euro symbol": <i class="material-icons md-48">euro_symbol</i>
  static const IconData euro_symbol = const IconData(0xe926);

  /// Material icon "ev station": <i class="material-icons md-48">ev_station</i>
  static const IconData ev_station = const IconData(0xe56d);

  /// Material icon "event": <i class="material-icons md-48">event</i>
  static const IconData event = const IconData(0xe878);

  /// Material icon "event available": <i class="material-icons md-48">event_available</i>
  static const IconData event_available = const IconData(0xe614);

  /// Material icon "event busy": <i class="material-icons md-48">event_busy</i>
  static const IconData event_busy = const IconData(0xe615);

  /// Material icon "event note": <i class="material-icons md-48">event_note</i>
  static const IconData event_note = const IconData(0xe616);

  /// Material icon "event seat": <i class="material-icons md-48">event_seat</i>
  static const IconData event_seat = const IconData(0xe903);

  /// Material icon "exit to app": <i class="material-icons md-48">exit_to_app</i>
  static const IconData exit_to_app = const IconData(0xe879);

  /// Material icon "expand less": <i class="material-icons md-48">expand_less</i>
  static const IconData expand_less = const IconData(0xe5ce);

  /// Material icon "expand more": <i class="material-icons md-48">expand_more</i>
  static const IconData expand_more = const IconData(0xe5cf);

  /// Material icon "explicit": <i class="material-icons md-48">explicit</i>
  static const IconData explicit = const IconData(0xe01e);

  /// Material icon "explore": <i class="material-icons md-48">explore</i>
  static const IconData explore = const IconData(0xe87a);

  /// Material icon "exposure": <i class="material-icons md-48">exposure</i>
  static const IconData exposure = const IconData(0xe3ca);

  /// Material icon "exposure neg 1": <i class="material-icons md-48">exposure_neg_1</i>
  static const IconData exposure_neg_1 = const IconData(0xe3cb);

  /// Material icon "exposure neg 2": <i class="material-icons md-48">exposure_neg_2</i>
  static const IconData exposure_neg_2 = const IconData(0xe3cc);

  /// Material icon "exposure plus 1": <i class="material-icons md-48">exposure_plus_1</i>
  static const IconData exposure_plus_1 = const IconData(0xe3cd);

  /// Material icon "exposure plus 2": <i class="material-icons md-48">exposure_plus_2</i>
  static const IconData exposure_plus_2 = const IconData(0xe3ce);

  /// Material icon "exposure zero": <i class="material-icons md-48">exposure_zero</i>
  static const IconData exposure_zero = const IconData(0xe3cf);

  /// Material icon "extension": <i class="material-icons md-48">extension</i>
  static const IconData extension = const IconData(0xe87b);

  /// Material icon "face": <i class="material-icons md-48">face</i>
  static const IconData face = const IconData(0xe87c);

  /// Material icon "fast forward": <i class="material-icons md-48">fast_forward</i>
  static const IconData fast_forward = const IconData(0xe01f);

  /// Material icon "fast rewind": <i class="material-icons md-48">fast_rewind</i>
  static const IconData fast_rewind = const IconData(0xe020);

  /// Material icon "favorite": <i class="material-icons md-48">favorite</i>
  static const IconData favorite = const IconData(0xe87d);

  /// Material icon "favorite border": <i class="material-icons md-48">favorite_border</i>
  static const IconData favorite_border = const IconData(0xe87e);

  /// Material icon "featured play list": <i class="material-icons md-48">featured_play_list</i>
  static const IconData featured_play_list = const IconData(0xe06d);

  /// Material icon "featured video": <i class="material-icons md-48">featured_video</i>
  static const IconData featured_video = const IconData(0xe06e);

  /// Material icon "feedback": <i class="material-icons md-48">feedback</i>
  static const IconData feedback = const IconData(0xe87f);

  /// Material icon "fiber dvr": <i class="material-icons md-48">fiber_dvr</i>
  static const IconData fiber_dvr = const IconData(0xe05d);

  /// Material icon "fiber manual record": <i class="material-icons md-48">fiber_manual_record</i>
  static const IconData fiber_manual_record = const IconData(0xe061);

  /// Material icon "fiber const": <i class="material-icons md-48">fiber_const</i>
  static const IconData fiber_const = const IconData(0xe05e);

  /// Material icon "fiber pin": <i class="material-icons md-48">fiber_pin</i>
  static const IconData fiber_pin = const IconData(0xe06a);

  /// Material icon "fiber smart record": <i class="material-icons md-48">fiber_smart_record</i>
  static const IconData fiber_smart_record = const IconData(0xe062);

  /// Material icon "file download": <i class="material-icons md-48">file_download</i>
  static const IconData file_download = const IconData(0xe2c4);

  /// Material icon "file upload": <i class="material-icons md-48">file_upload</i>
  static const IconData file_upload = const IconData(0xe2c6);

  /// Material icon "filter": <i class="material-icons md-48">filter</i>
  static const IconData filter = const IconData(0xe3d3);

  /// Material icon "filter 1": <i class="material-icons md-48">filter_1</i>
  static const IconData filter_1 = const IconData(0xe3d0);

  /// Material icon "filter 2": <i class="material-icons md-48">filter_2</i>
  static const IconData filter_2 = const IconData(0xe3d1);

  /// Material icon "filter 3": <i class="material-icons md-48">filter_3</i>
  static const IconData filter_3 = const IconData(0xe3d2);

  /// Material icon "filter 4": <i class="material-icons md-48">filter_4</i>
  static const IconData filter_4 = const IconData(0xe3d4);

  /// Material icon "filter 5": <i class="material-icons md-48">filter_5</i>
  static const IconData filter_5 = const IconData(0xe3d5);

  /// Material icon "filter 6": <i class="material-icons md-48">filter_6</i>
  static const IconData filter_6 = const IconData(0xe3d6);

  /// Material icon "filter 7": <i class="material-icons md-48">filter_7</i>
  static const IconData filter_7 = const IconData(0xe3d7);

  /// Material icon "filter 8": <i class="material-icons md-48">filter_8</i>
  static const IconData filter_8 = const IconData(0xe3d8);

  /// Material icon "filter 9": <i class="material-icons md-48">filter_9</i>
  static const IconData filter_9 = const IconData(0xe3d9);

  /// Material icon "filter 9 plus": <i class="material-icons md-48">filter_9_plus</i>
  static const IconData filter_9_plus = const IconData(0xe3da);

  /// Material icon "filter b and w": <i class="material-icons md-48">filter_b_and_w</i>
  static const IconData filter_b_and_w = const IconData(0xe3db);

  /// Material icon "filter center focus": <i class="material-icons md-48">filter_center_focus</i>
  static const IconData filter_center_focus = const IconData(0xe3dc);

  /// Material icon "filter drama": <i class="material-icons md-48">filter_drama</i>
  static const IconData filter_drama = const IconData(0xe3dd);

  /// Material icon "filter frames": <i class="material-icons md-48">filter_frames</i>
  static const IconData filter_frames = const IconData(0xe3de);

  /// Material icon "filter hdr": <i class="material-icons md-48">filter_hdr</i>
  static const IconData filter_hdr = const IconData(0xe3df);

  /// Material icon "filter list": <i class="material-icons md-48">filter_list</i>
  static const IconData filter_list = const IconData(0xe152);

  /// Material icon "filter none": <i class="material-icons md-48">filter_none</i>
  static const IconData filter_none = const IconData(0xe3e0);

  /// Material icon "filter tilt shift": <i class="material-icons md-48">filter_tilt_shift</i>
  static const IconData filter_tilt_shift = const IconData(0xe3e2);

  /// Material icon "filter vintage": <i class="material-icons md-48">filter_vintage</i>
  static const IconData filter_vintage = const IconData(0xe3e3);

  /// Material icon "find in page": <i class="material-icons md-48">find_in_page</i>
  static const IconData find_in_page = const IconData(0xe880);

  /// Material icon "find replace": <i class="material-icons md-48">find_replace</i>
  static const IconData find_replace = const IconData(0xe881);

  /// Material icon "fingerprint": <i class="material-icons md-48">fingerprint</i>
  static const IconData fingerprint = const IconData(0xe90d);

  /// Material icon "first page": <i class="material-icons md-48">first_page</i>
  static const IconData first_page = const IconData(0xe5dc);

  /// Material icon "fitness center": <i class="material-icons md-48">fitness_center</i>
  static const IconData fitness_center = const IconData(0xeb43);

  /// Material icon "flag": <i class="material-icons md-48">flag</i>
  static const IconData flag = const IconData(0xe153);

  /// Material icon "flare": <i class="material-icons md-48">flare</i>
  static const IconData flare = const IconData(0xe3e4);

  /// Material icon "flash auto": <i class="material-icons md-48">flash_auto</i>
  static const IconData flash_auto = const IconData(0xe3e5);

  /// Material icon "flash off": <i class="material-icons md-48">flash_off</i>
  static const IconData flash_off = const IconData(0xe3e6);

  /// Material icon "flash on": <i class="material-icons md-48">flash_on</i>
  static const IconData flash_on = const IconData(0xe3e7);

  /// Material icon "flight": <i class="material-icons md-48">flight</i>
  static const IconData flight = const IconData(0xe539);

  /// Material icon "flight land": <i class="material-icons md-48">flight_land</i>
  static const IconData flight_land = const IconData(0xe904);

  /// Material icon "flight takeoff": <i class="material-icons md-48">flight_takeoff</i>
  static const IconData flight_takeoff = const IconData(0xe905);

  /// Material icon "flip": <i class="material-icons md-48">flip</i>
  static const IconData flip = const IconData(0xe3e8);

  /// Material icon "flip to back": <i class="material-icons md-48">flip_to_back</i>
  static const IconData flip_to_back = const IconData(0xe882);

  /// Material icon "flip to front": <i class="material-icons md-48">flip_to_front</i>
  static const IconData flip_to_front = const IconData(0xe883);

  /// Material icon "folder": <i class="material-icons md-48">folder</i>
  static const IconData folder = const IconData(0xe2c7);

  /// Material icon "folder open": <i class="material-icons md-48">folder_open</i>
  static const IconData folder_open = const IconData(0xe2c8);

  /// Material icon "folder shared": <i class="material-icons md-48">folder_shared</i>
  static const IconData folder_shared = const IconData(0xe2c9);

  /// Material icon "folder special": <i class="material-icons md-48">folder_special</i>
  static const IconData folder_special = const IconData(0xe617);

  /// Material icon "font download": <i class="material-icons md-48">font_download</i>
  static const IconData font_download = const IconData(0xe167);

  /// Material icon "format align center": <i class="material-icons md-48">format_align_center</i>
  static const IconData format_align_center = const IconData(0xe234);

  /// Material icon "format align justify": <i class="material-icons md-48">format_align_justify</i>
  static const IconData format_align_justify = const IconData(0xe235);

  /// Material icon "format align left": <i class="material-icons md-48">format_align_left</i>
  static const IconData format_align_left = const IconData(0xe236);

  /// Material icon "format align right": <i class="material-icons md-48">format_align_right</i>
  static const IconData format_align_right = const IconData(0xe237);

  /// Material icon "format bold": <i class="material-icons md-48">format_bold</i>
  static const IconData format_bold = const IconData(0xe238);

  /// Material icon "format clear": <i class="material-icons md-48">format_clear</i>
  static const IconData format_clear = const IconData(0xe239);

  /// Material icon "format color fill": <i class="material-icons md-48">format_color_fill</i>
  static const IconData format_color_fill = const IconData(0xe23a);

  /// Material icon "format color reset": <i class="material-icons md-48">format_color_reset</i>
  static const IconData format_color_reset = const IconData(0xe23b);

  /// Material icon "format color text": <i class="material-icons md-48">format_color_text</i>
  static const IconData format_color_text = const IconData(0xe23c);

  /// Material icon "format indent decrease": <i class="material-icons md-48">format_indent_decrease</i>
  static const IconData format_indent_decrease = const IconData(0xe23d);

  /// Material icon "format indent increase": <i class="material-icons md-48">format_indent_increase</i>
  static const IconData format_indent_increase = const IconData(0xe23e);

  /// Material icon "format italic": <i class="material-icons md-48">format_italic</i>
  static const IconData format_italic = const IconData(0xe23f);

  /// Material icon "format line spacing": <i class="material-icons md-48">format_line_spacing</i>
  static const IconData format_line_spacing = const IconData(0xe240);

  /// Material icon "format list bulleted": <i class="material-icons md-48">format_list_bulleted</i>
  static const IconData format_list_bulleted = const IconData(0xe241);

  /// Material icon "format list numbered": <i class="material-icons md-48">format_list_numbered</i>
  static const IconData format_list_numbered = const IconData(0xe242);

  /// Material icon "format paint": <i class="material-icons md-48">format_paint</i>
  static const IconData format_paint = const IconData(0xe243);

  /// Material icon "format quote": <i class="material-icons md-48">format_quote</i>
  static const IconData format_quote = const IconData(0xe244);

  /// Material icon "format shapes": <i class="material-icons md-48">format_shapes</i>
  static const IconData format_shapes = const IconData(0xe25e);

  /// Material icon "format size": <i class="material-icons md-48">format_size</i>
  static const IconData format_size = const IconData(0xe245);

  /// Material icon "format strikethrough": <i class="material-icons md-48">format_strikethrough</i>
  static const IconData format_strikethrough = const IconData(0xe246);

  /// Material icon "format textdirection l to r": <i class="material-icons md-48">format_textdirection_l_to_r</i>
  static const IconData format_textdirection_l_to_r = const IconData(0xe247);

  /// Material icon "format textdirection r to l": <i class="material-icons md-48">format_textdirection_r_to_l</i>
  static const IconData format_textdirection_r_to_l = const IconData(0xe248);

  /// Material icon "format underlined": <i class="material-icons md-48">format_underlined</i>
  static const IconData format_underlined = const IconData(0xe249);

  /// Material icon "forum": <i class="material-icons md-48">forum</i>
  static const IconData forum = const IconData(0xe0bf);

  /// Material icon "forward": <i class="material-icons md-48">forward</i>
  static const IconData forward = const IconData(0xe154);

  /// Material icon "forward 10": <i class="material-icons md-48">forward_10</i>
  static const IconData forward_10 = const IconData(0xe056);

  /// Material icon "forward 30": <i class="material-icons md-48">forward_30</i>
  static const IconData forward_30 = const IconData(0xe057);

  /// Material icon "forward 5": <i class="material-icons md-48">forward_5</i>
  static const IconData forward_5 = const IconData(0xe058);

  /// Material icon "free breakfast": <i class="material-icons md-48">free_breakfast</i>
  static const IconData free_breakfast = const IconData(0xeb44);

  /// Material icon "fullscreen": <i class="material-icons md-48">fullscreen</i>
  static const IconData fullscreen = const IconData(0xe5d0);

  /// Material icon "fullscreen exit": <i class="material-icons md-48">fullscreen_exit</i>
  static const IconData fullscreen_exit = const IconData(0xe5d1);

  /// Material icon "functions": <i class="material-icons md-48">functions</i>
  static const IconData functions = const IconData(0xe24a);

  /// Material icon "g translate": <i class="material-icons md-48">g_translate</i>
  static const IconData g_translate = const IconData(0xe927);

  /// Material icon "gamepad": <i class="material-icons md-48">gamepad</i>
  static const IconData gamepad = const IconData(0xe30f);

  /// Material icon "games": <i class="material-icons md-48">games</i>
  static const IconData games = const IconData(0xe021);

  /// Material icon "gavel": <i class="material-icons md-48">gavel</i>
  static const IconData gavel = const IconData(0xe90e);

  /// Material icon "gesture": <i class="material-icons md-48">gesture</i>
  static const IconData gesture = const IconData(0xe155);

  /// Material icon "get app": <i class="material-icons md-48">get_app</i>
  static const IconData get_app = const IconData(0xe884);

  /// Material icon "gif": <i class="material-icons md-48">gif</i>
  static const IconData gif = const IconData(0xe908);

  /// Material icon "golf course": <i class="material-icons md-48">golf_course</i>
  static const IconData golf_course = const IconData(0xeb45);

  /// Material icon "gps fixed": <i class="material-icons md-48">gps_fixed</i>
  static const IconData gps_fixed = const IconData(0xe1b3);

  /// Material icon "gps not fixed": <i class="material-icons md-48">gps_not_fixed</i>
  static const IconData gps_not_fixed = const IconData(0xe1b4);

  /// Material icon "gps off": <i class="material-icons md-48">gps_off</i>
  static const IconData gps_off = const IconData(0xe1b5);

  /// Material icon "grade": <i class="material-icons md-48">grade</i>
  static const IconData grade = const IconData(0xe885);

  /// Material icon "gradient": <i class="material-icons md-48">gradient</i>
  static const IconData gradient = const IconData(0xe3e9);

  /// Material icon "grain": <i class="material-icons md-48">grain</i>
  static const IconData grain = const IconData(0xe3ea);

  /// Material icon "graphic eq": <i class="material-icons md-48">graphic_eq</i>
  static const IconData graphic_eq = const IconData(0xe1b8);

  /// Material icon "grid off": <i class="material-icons md-48">grid_off</i>
  static const IconData grid_off = const IconData(0xe3eb);

  /// Material icon "grid on": <i class="material-icons md-48">grid_on</i>
  static const IconData grid_on = const IconData(0xe3ec);

  /// Material icon "group": <i class="material-icons md-48">group</i>
  static const IconData group = const IconData(0xe7ef);

  /// Material icon "group add": <i class="material-icons md-48">group_add</i>
  static const IconData group_add = const IconData(0xe7f0);

  /// Material icon "group work": <i class="material-icons md-48">group_work</i>
  static const IconData group_work = const IconData(0xe886);

  /// Material icon "hd": <i class="material-icons md-48">hd</i>
  static const IconData hd = const IconData(0xe052);

  /// Material icon "hdr off": <i class="material-icons md-48">hdr_off</i>
  static const IconData hdr_off = const IconData(0xe3ed);

  /// Material icon "hdr on": <i class="material-icons md-48">hdr_on</i>
  static const IconData hdr_on = const IconData(0xe3ee);

  /// Material icon "hdr strong": <i class="material-icons md-48">hdr_strong</i>
  static const IconData hdr_strong = const IconData(0xe3f1);

  /// Material icon "hdr weak": <i class="material-icons md-48">hdr_weak</i>
  static const IconData hdr_weak = const IconData(0xe3f2);

  /// Material icon "headset": <i class="material-icons md-48">headset</i>
  static const IconData headset = const IconData(0xe310);

  /// Material icon "headset mic": <i class="material-icons md-48">headset_mic</i>
  static const IconData headset_mic = const IconData(0xe311);

  /// Material icon "healing": <i class="material-icons md-48">healing</i>
  static const IconData healing = const IconData(0xe3f3);

  /// Material icon "hearing": <i class="material-icons md-48">hearing</i>
  static const IconData hearing = const IconData(0xe023);

  /// Material icon "help": <i class="material-icons md-48">help</i>
  static const IconData help = const IconData(0xe887);

  /// Material icon "help outline": <i class="material-icons md-48">help_outline</i>
  static const IconData help_outline = const IconData(0xe8fd);

  /// Material icon "high quality": <i class="material-icons md-48">high_quality</i>
  static const IconData high_quality = const IconData(0xe024);

  /// Material icon "highlight": <i class="material-icons md-48">highlight</i>
  static const IconData highlight = const IconData(0xe25f);

  /// Material icon "highlight off": <i class="material-icons md-48">highlight_off</i>
  static const IconData highlight_off = const IconData(0xe888);

  /// Material icon "history": <i class="material-icons md-48">history</i>
  static const IconData history = const IconData(0xe889);

  /// Material icon "home": <i class="material-icons md-48">home</i>
  static const IconData home = const IconData(0xe88a);

  /// Material icon "hot tub": <i class="material-icons md-48">hot_tub</i>
  static const IconData hot_tub = const IconData(0xeb46);

  /// Material icon "hotel": <i class="material-icons md-48">hotel</i>
  static const IconData hotel = const IconData(0xe53a);

  /// Material icon "hourglass empty": <i class="material-icons md-48">hourglass_empty</i>
  static const IconData hourglass_empty = const IconData(0xe88b);

  /// Material icon "hourglass full": <i class="material-icons md-48">hourglass_full</i>
  static const IconData hourglass_full = const IconData(0xe88c);

  /// Material icon "http": <i class="material-icons md-48">http</i>
  static const IconData http = const IconData(0xe902);

  /// Material icon "https": <i class="material-icons md-48">https</i>
  static const IconData https = const IconData(0xe88d);

  /// Material icon "image": <i class="material-icons md-48">image</i>
  static const IconData image = const IconData(0xe3f4);

  /// Material icon "image aspect ratio": <i class="material-icons md-48">image_aspect_ratio</i>
  static const IconData image_aspect_ratio = const IconData(0xe3f5);

  /// Material icon "import contacts": <i class="material-icons md-48">import_contacts</i>
  static const IconData import_contacts = const IconData(0xe0e0);

  /// Material icon "import export": <i class="material-icons md-48">import_export</i>
  static const IconData import_export = const IconData(0xe0c3);

  /// Material icon "important devices": <i class="material-icons md-48">important_devices</i>
  static const IconData important_devices = const IconData(0xe912);

  /// Material icon "inbox": <i class="material-icons md-48">inbox</i>
  static const IconData inbox = const IconData(0xe156);

  /// Material icon "indeterminate check box": <i class="material-icons md-48">indeterminate_check_box</i>
  static const IconData indeterminate_check_box = const IconData(0xe909);

  /// Material icon "info": <i class="material-icons md-48">info</i>
  static const IconData info = const IconData(0xe88e);

  /// Material icon "info outline": <i class="material-icons md-48">info_outline</i>
  static const IconData info_outline = const IconData(0xe88f);

  /// Material icon "input": <i class="material-icons md-48">input</i>
  static const IconData input = const IconData(0xe890);

  /// Material icon "insert chart": <i class="material-icons md-48">insert_chart</i>
  static const IconData insert_chart = const IconData(0xe24b);

  /// Material icon "insert comment": <i class="material-icons md-48">insert_comment</i>
  static const IconData insert_comment = const IconData(0xe24c);

  /// Material icon "insert drive file": <i class="material-icons md-48">insert_drive_file</i>
  static const IconData insert_drive_file = const IconData(0xe24d);

  /// Material icon "insert emoticon": <i class="material-icons md-48">insert_emoticon</i>
  static const IconData insert_emoticon = const IconData(0xe24e);

  /// Material icon "insert invitation": <i class="material-icons md-48">insert_invitation</i>
  static const IconData insert_invitation = const IconData(0xe24f);

  /// Material icon "insert link": <i class="material-icons md-48">insert_link</i>
  static const IconData insert_link = const IconData(0xe250);

  /// Material icon "insert photo": <i class="material-icons md-48">insert_photo</i>
  static const IconData insert_photo = const IconData(0xe251);

  /// Material icon "invert colors": <i class="material-icons md-48">invert_colors</i>
  static const IconData invert_colors = const IconData(0xe891);

  /// Material icon "invert colors off": <i class="material-icons md-48">invert_colors_off</i>
  static const IconData invert_colors_off = const IconData(0xe0c4);

  /// Material icon "iso": <i class="material-icons md-48">iso</i>
  static const IconData iso = const IconData(0xe3f6);

  /// Material icon "keyboard": <i class="material-icons md-48">keyboard</i>
  static const IconData keyboard = const IconData(0xe312);

  /// Material icon "keyboard arrow down": <i class="material-icons md-48">keyboard_arrow_down</i>
  static const IconData keyboard_arrow_down = const IconData(0xe313);

  /// Material icon "keyboard arrow left": <i class="material-icons md-48">keyboard_arrow_left</i>
  static const IconData keyboard_arrow_left = const IconData(0xe314);

  /// Material icon "keyboard arrow right": <i class="material-icons md-48">keyboard_arrow_right</i>
  static const IconData keyboard_arrow_right = const IconData(0xe315);

  /// Material icon "keyboard arrow up": <i class="material-icons md-48">keyboard_arrow_up</i>
  static const IconData keyboard_arrow_up = const IconData(0xe316);

  /// Material icon "keyboard backspace": <i class="material-icons md-48">keyboard_backspace</i>
  static const IconData keyboard_backspace = const IconData(0xe317);

  /// Material icon "keyboard capslock": <i class="material-icons md-48">keyboard_capslock</i>
  static const IconData keyboard_capslock = const IconData(0xe318);

  /// Material icon "keyboard hide": <i class="material-icons md-48">keyboard_hide</i>
  static const IconData keyboard_hide = const IconData(0xe31a);

  /// Material icon "keyboard return": <i class="material-icons md-48">keyboard_return</i>
  static const IconData keyboard_return = const IconData(0xe31b);

  /// Material icon "keyboard tab": <i class="material-icons md-48">keyboard_tab</i>
  static const IconData keyboard_tab = const IconData(0xe31c);

  /// Material icon "keyboard voice": <i class="material-icons md-48">keyboard_voice</i>
  static const IconData keyboard_voice = const IconData(0xe31d);

  /// Material icon "kitchen": <i class="material-icons md-48">kitchen</i>
  static const IconData kitchen = const IconData(0xeb47);

  /// Material icon "label": <i class="material-icons md-48">label</i>
  static const IconData label = const IconData(0xe892);

  /// Material icon "label outline": <i class="material-icons md-48">label_outline</i>
  static const IconData label_outline = const IconData(0xe893);

  /// Material icon "landscape": <i class="material-icons md-48">landscape</i>
  static const IconData landscape = const IconData(0xe3f7);

  /// Material icon "language": <i class="material-icons md-48">language</i>
  static const IconData language = const IconData(0xe894);

  /// Material icon "laptop": <i class="material-icons md-48">laptop</i>
  static const IconData laptop = const IconData(0xe31e);

  /// Material icon "laptop chromebook": <i class="material-icons md-48">laptop_chromebook</i>
  static const IconData laptop_chromebook = const IconData(0xe31f);

  /// Material icon "laptop mac": <i class="material-icons md-48">laptop_mac</i>
  static const IconData laptop_mac = const IconData(0xe320);

  /// Material icon "laptop windows": <i class="material-icons md-48">laptop_windows</i>
  static const IconData laptop_windows = const IconData(0xe321);

  /// Material icon "last page": <i class="material-icons md-48">last_page</i>
  static const IconData last_page = const IconData(0xe5dd);

  /// Material icon "launch": <i class="material-icons md-48">launch</i>
  static const IconData launch = const IconData(0xe895);

  /// Material icon "layers": <i class="material-icons md-48">layers</i>
  static const IconData layers = const IconData(0xe53b);

  /// Material icon "layers clear": <i class="material-icons md-48">layers_clear</i>
  static const IconData layers_clear = const IconData(0xe53c);

  /// Material icon "leak add": <i class="material-icons md-48">leak_add</i>
  static const IconData leak_add = const IconData(0xe3f8);

  /// Material icon "leak remove": <i class="material-icons md-48">leak_remove</i>
  static const IconData leak_remove = const IconData(0xe3f9);

  /// Material icon "lens": <i class="material-icons md-48">lens</i>
  static const IconData lens = const IconData(0xe3fa);

  /// Material icon "library add": <i class="material-icons md-48">library_add</i>
  static const IconData library_add = const IconData(0xe02e);

  /// Material icon "library books": <i class="material-icons md-48">library_books</i>
  static const IconData library_books = const IconData(0xe02f);

  /// Material icon "library music": <i class="material-icons md-48">library_music</i>
  static const IconData library_music = const IconData(0xe030);

  /// Material icon "lightbulb outline": <i class="material-icons md-48">lightbulb_outline</i>
  static const IconData lightbulb_outline = const IconData(0xe90f);

  /// Material icon "line style": <i class="material-icons md-48">line_style</i>
  static const IconData line_style = const IconData(0xe919);

  /// Material icon "line weight": <i class="material-icons md-48">line_weight</i>
  static const IconData line_weight = const IconData(0xe91a);

  /// Material icon "linear scale": <i class="material-icons md-48">linear_scale</i>
  static const IconData linear_scale = const IconData(0xe260);

  /// Material icon "link": <i class="material-icons md-48">link</i>
  static const IconData link = const IconData(0xe157);

  /// Material icon "linked camera": <i class="material-icons md-48">linked_camera</i>
  static const IconData linked_camera = const IconData(0xe438);

  /// Material icon "list": <i class="material-icons md-48">list</i>
  static const IconData list = const IconData(0xe896);

  /// Material icon "live help": <i class="material-icons md-48">live_help</i>
  static const IconData live_help = const IconData(0xe0c6);

  /// Material icon "live tv": <i class="material-icons md-48">live_tv</i>
  static const IconData live_tv = const IconData(0xe639);

  /// Material icon "local activity": <i class="material-icons md-48">local_activity</i>
  static const IconData local_activity = const IconData(0xe53f);

  /// Material icon "local airport": <i class="material-icons md-48">local_airport</i>
  static const IconData local_airport = const IconData(0xe53d);

  /// Material icon "local atm": <i class="material-icons md-48">local_atm</i>
  static const IconData local_atm = const IconData(0xe53e);

  /// Material icon "local bar": <i class="material-icons md-48">local_bar</i>
  static const IconData local_bar = const IconData(0xe540);

  /// Material icon "local cafe": <i class="material-icons md-48">local_cafe</i>
  static const IconData local_cafe = const IconData(0xe541);

  /// Material icon "local car wash": <i class="material-icons md-48">local_car_wash</i>
  static const IconData local_car_wash = const IconData(0xe542);

  /// Material icon "local convenience store": <i class="material-icons md-48">local_convenience_store</i>
  static const IconData local_convenience_store = const IconData(0xe543);

  /// Material icon "local dining": <i class="material-icons md-48">local_dining</i>
  static const IconData local_dining = const IconData(0xe556);

  /// Material icon "local drink": <i class="material-icons md-48">local_drink</i>
  static const IconData local_drink = const IconData(0xe544);

  /// Material icon "local florist": <i class="material-icons md-48">local_florist</i>
  static const IconData local_florist = const IconData(0xe545);

  /// Material icon "local gas station": <i class="material-icons md-48">local_gas_station</i>
  static const IconData local_gas_station = const IconData(0xe546);

  /// Material icon "local grocery store": <i class="material-icons md-48">local_grocery_store</i>
  static const IconData local_grocery_store = const IconData(0xe547);

  /// Material icon "local hospital": <i class="material-icons md-48">local_hospital</i>
  static const IconData local_hospital = const IconData(0xe548);

  /// Material icon "local hotel": <i class="material-icons md-48">local_hotel</i>
  static const IconData local_hotel = const IconData(0xe549);

  /// Material icon "local laundry service": <i class="material-icons md-48">local_laundry_service</i>
  static const IconData local_laundry_service = const IconData(0xe54a);

  /// Material icon "local library": <i class="material-icons md-48">local_library</i>
  static const IconData local_library = const IconData(0xe54b);

  /// Material icon "local mall": <i class="material-icons md-48">local_mall</i>
  static const IconData local_mall = const IconData(0xe54c);

  /// Material icon "local movies": <i class="material-icons md-48">local_movies</i>
  static const IconData local_movies = const IconData(0xe54d);

  /// Material icon "local offer": <i class="material-icons md-48">local_offer</i>
  static const IconData local_offer = const IconData(0xe54e);

  /// Material icon "local parking": <i class="material-icons md-48">local_parking</i>
  static const IconData local_parking = const IconData(0xe54f);

  /// Material icon "local pharmacy": <i class="material-icons md-48">local_pharmacy</i>
  static const IconData local_pharmacy = const IconData(0xe550);

  /// Material icon "local phone": <i class="material-icons md-48">local_phone</i>
  static const IconData local_phone = const IconData(0xe551);

  /// Material icon "local pizza": <i class="material-icons md-48">local_pizza</i>
  static const IconData local_pizza = const IconData(0xe552);

  /// Material icon "local play": <i class="material-icons md-48">local_play</i>
  static const IconData local_play = const IconData(0xe553);

  /// Material icon "local post office": <i class="material-icons md-48">local_post_office</i>
  static const IconData local_post_office = const IconData(0xe554);

  /// Material icon "local printshop": <i class="material-icons md-48">local_printshop</i>
  static const IconData local_printshop = const IconData(0xe555);

  /// Material icon "local see": <i class="material-icons md-48">local_see</i>
  static const IconData local_see = const IconData(0xe557);

  /// Material icon "local shipping": <i class="material-icons md-48">local_shipping</i>
  static const IconData local_shipping = const IconData(0xe558);

  /// Material icon "local taxi": <i class="material-icons md-48">local_taxi</i>
  static const IconData local_taxi = const IconData(0xe559);

  /// Material icon "location city": <i class="material-icons md-48">location_city</i>
  static const IconData location_city = const IconData(0xe7f1);

  /// Material icon "location disabled": <i class="material-icons md-48">location_disabled</i>
  static const IconData location_disabled = const IconData(0xe1b6);

  /// Material icon "location off": <i class="material-icons md-48">location_off</i>
  static const IconData location_off = const IconData(0xe0c7);

  /// Material icon "location on": <i class="material-icons md-48">location_on</i>
  static const IconData location_on = const IconData(0xe0c8);

  /// Material icon "location searching": <i class="material-icons md-48">location_searching</i>
  static const IconData location_searching = const IconData(0xe1b7);

  /// Material icon "lock": <i class="material-icons md-48">lock</i>
  static const IconData lock = const IconData(0xe897);

  /// Material icon "lock open": <i class="material-icons md-48">lock_open</i>
  static const IconData lock_open = const IconData(0xe898);

  /// Material icon "lock outline": <i class="material-icons md-48">lock_outline</i>
  static const IconData lock_outline = const IconData(0xe899);

  /// Material icon "looks": <i class="material-icons md-48">looks</i>
  static const IconData looks = const IconData(0xe3fc);

  /// Material icon "looks 3": <i class="material-icons md-48">looks_3</i>
  static const IconData looks_3 = const IconData(0xe3fb);

  /// Material icon "looks 4": <i class="material-icons md-48">looks_4</i>
  static const IconData looks_4 = const IconData(0xe3fd);

  /// Material icon "looks 5": <i class="material-icons md-48">looks_5</i>
  static const IconData looks_5 = const IconData(0xe3fe);

  /// Material icon "looks 6": <i class="material-icons md-48">looks_6</i>
  static const IconData looks_6 = const IconData(0xe3ff);

  /// Material icon "looks one": <i class="material-icons md-48">looks_one</i>
  static const IconData looks_one = const IconData(0xe400);

  /// Material icon "looks two": <i class="material-icons md-48">looks_two</i>
  static const IconData looks_two = const IconData(0xe401);

  /// Material icon "loop": <i class="material-icons md-48">loop</i>
  static const IconData loop = const IconData(0xe028);

  /// Material icon "loupe": <i class="material-icons md-48">loupe</i>
  static const IconData loupe = const IconData(0xe402);

  /// Material icon "low priority": <i class="material-icons md-48">low_priority</i>
  static const IconData low_priority = const IconData(0xe16d);

  /// Material icon "loyalty": <i class="material-icons md-48">loyalty</i>
  static const IconData loyalty = const IconData(0xe89a);

  /// Material icon "mail": <i class="material-icons md-48">mail</i>
  static const IconData mail = const IconData(0xe158);

  /// Material icon "mail outline": <i class="material-icons md-48">mail_outline</i>
  static const IconData mail_outline = const IconData(0xe0e1);

  /// Material icon "map": <i class="material-icons md-48">map</i>
  static const IconData map = const IconData(0xe55b);

  /// Material icon "markunread": <i class="material-icons md-48">markunread</i>
  static const IconData markunread = const IconData(0xe159);

  /// Material icon "markunread mailbox": <i class="material-icons md-48">markunread_mailbox</i>
  static const IconData markunread_mailbox = const IconData(0xe89b);

  /// Material icon "memory": <i class="material-icons md-48">memory</i>
  static const IconData memory = const IconData(0xe322);

  /// Material icon "menu": <i class="material-icons md-48">menu</i>
  static const IconData menu = const IconData(0xe5d2);

  /// Material icon "merge type": <i class="material-icons md-48">merge_type</i>
  static const IconData merge_type = const IconData(0xe252);

  /// Material icon "message": <i class="material-icons md-48">message</i>
  static const IconData message = const IconData(0xe0c9);

  /// Material icon "mic": <i class="material-icons md-48">mic</i>
  static const IconData mic = const IconData(0xe029);

  /// Material icon "mic none": <i class="material-icons md-48">mic_none</i>
  static const IconData mic_none = const IconData(0xe02a);

  /// Material icon "mic off": <i class="material-icons md-48">mic_off</i>
  static const IconData mic_off = const IconData(0xe02b);

  /// Material icon "mms": <i class="material-icons md-48">mms</i>
  static const IconData mms = const IconData(0xe618);

  /// Material icon "mode comment": <i class="material-icons md-48">mode_comment</i>
  static const IconData mode_comment = const IconData(0xe253);

  /// Material icon "mode edit": <i class="material-icons md-48">mode_edit</i>
  static const IconData mode_edit = const IconData(0xe254);

  /// Material icon "monetization on": <i class="material-icons md-48">monetization_on</i>
  static const IconData monetization_on = const IconData(0xe263);

  /// Material icon "money off": <i class="material-icons md-48">money_off</i>
  static const IconData money_off = const IconData(0xe25c);

  /// Material icon "monochrome photos": <i class="material-icons md-48">monochrome_photos</i>
  static const IconData monochrome_photos = const IconData(0xe403);

  /// Material icon "mood": <i class="material-icons md-48">mood</i>
  static const IconData mood = const IconData(0xe7f2);

  /// Material icon "mood bad": <i class="material-icons md-48">mood_bad</i>
  static const IconData mood_bad = const IconData(0xe7f3);

  /// Material icon "more": <i class="material-icons md-48">more</i>
  static const IconData more = const IconData(0xe619);

  /// Material icon "more horiz": <i class="material-icons md-48">more_horiz</i>
  static const IconData more_horiz = const IconData(0xe5d3);

  /// Material icon "more vert": <i class="material-icons md-48">more_vert</i>
  static const IconData more_vert = const IconData(0xe5d4);

  /// Material icon "motorcycle": <i class="material-icons md-48">motorcycle</i>
  static const IconData motorcycle = const IconData(0xe91b);

  /// Material icon "mouse": <i class="material-icons md-48">mouse</i>
  static const IconData mouse = const IconData(0xe323);

  /// Material icon "move to inbox": <i class="material-icons md-48">move_to_inbox</i>
  static const IconData move_to_inbox = const IconData(0xe168);

  /// Material icon "movie": <i class="material-icons md-48">movie</i>
  static const IconData movie = const IconData(0xe02c);

  /// Material icon "movie creation": <i class="material-icons md-48">movie_creation</i>
  static const IconData movie_creation = const IconData(0xe404);

  /// Material icon "movie filter": <i class="material-icons md-48">movie_filter</i>
  static const IconData movie_filter = const IconData(0xe43a);

  /// Material icon "multiline chart": <i class="material-icons md-48">multiline_chart</i>
  static const IconData multiline_chart = const IconData(0xe6df);

  /// Material icon "music note": <i class="material-icons md-48">music_note</i>
  static const IconData music_note = const IconData(0xe405);

  /// Material icon "music video": <i class="material-icons md-48">music_video</i>
  static const IconData music_video = const IconData(0xe063);

  /// Material icon "my location": <i class="material-icons md-48">my_location</i>
  static const IconData my_location = const IconData(0xe55c);

  /// Material icon "nature": <i class="material-icons md-48">nature</i>
  static const IconData nature = const IconData(0xe406);

  /// Material icon "nature people": <i class="material-icons md-48">nature_people</i>
  static const IconData nature_people = const IconData(0xe407);

  /// Material icon "navigate before": <i class="material-icons md-48">navigate_before</i>
  static const IconData navigate_before = const IconData(0xe408);

  /// Material icon "navigate next": <i class="material-icons md-48">navigate_next</i>
  static const IconData navigate_next = const IconData(0xe409);

  /// Material icon "navigation": <i class="material-icons md-48">navigation</i>
  static const IconData navigation = const IconData(0xe55d);

  /// Material icon "near me": <i class="material-icons md-48">near_me</i>
  static const IconData near_me = const IconData(0xe569);

  /// Material icon "network cell": <i class="material-icons md-48">network_cell</i>
  static const IconData network_cell = const IconData(0xe1b9);

  /// Material icon "network check": <i class="material-icons md-48">network_check</i>
  static const IconData network_check = const IconData(0xe640);

  /// Material icon "network locked": <i class="material-icons md-48">network_locked</i>
  static const IconData network_locked = const IconData(0xe61a);

  /// Material icon "network wifi": <i class="material-icons md-48">network_wifi</i>
  static const IconData network_wifi = const IconData(0xe1ba);

  /// Material icon "const releases": <i class="material-icons md-48">const_releases</i>
  static const IconData const_releases = const IconData(0xe031);

  /// Material icon "next week": <i class="material-icons md-48">next_week</i>
  static const IconData next_week = const IconData(0xe16a);

  /// Material icon "nfc": <i class="material-icons md-48">nfc</i>
  static const IconData nfc = const IconData(0xe1bb);

  /// Material icon "no encryption": <i class="material-icons md-48">no_encryption</i>
  static const IconData no_encryption = const IconData(0xe641);

  /// Material icon "no sim": <i class="material-icons md-48">no_sim</i>
  static const IconData no_sim = const IconData(0xe0cc);

  /// Material icon "not interested": <i class="material-icons md-48">not_interested</i>
  static const IconData not_interested = const IconData(0xe033);

  /// Material icon "note": <i class="material-icons md-48">note</i>
  static const IconData note = const IconData(0xe06f);

  /// Material icon "note add": <i class="material-icons md-48">note_add</i>
  static const IconData note_add = const IconData(0xe89c);

  /// Material icon "notifications": <i class="material-icons md-48">notifications</i>
  static const IconData notifications = const IconData(0xe7f4);

  /// Material icon "notifications active": <i class="material-icons md-48">notifications_active</i>
  static const IconData notifications_active = const IconData(0xe7f7);

  /// Material icon "notifications none": <i class="material-icons md-48">notifications_none</i>
  static const IconData notifications_none = const IconData(0xe7f5);

  /// Material icon "notifications off": <i class="material-icons md-48">notifications_off</i>
  static const IconData notifications_off = const IconData(0xe7f6);

  /// Material icon "notifications paused": <i class="material-icons md-48">notifications_paused</i>
  static const IconData notifications_paused = const IconData(0xe7f8);

  /// Material icon "offline pin": <i class="material-icons md-48">offline_pin</i>
  static const IconData offline_pin = const IconData(0xe90a);

  /// Material icon "ondemand video": <i class="material-icons md-48">ondemand_video</i>
  static const IconData ondemand_video = const IconData(0xe63a);

  /// Material icon "opacity": <i class="material-icons md-48">opacity</i>
  static const IconData opacity = const IconData(0xe91c);

  /// Material icon "open in browser": <i class="material-icons md-48">open_in_browser</i>
  static const IconData open_in_browser = const IconData(0xe89d);

  /// Material icon "open in const": <i class="material-icons md-48">open_in_const</i>
  static const IconData open_in_const = const IconData(0xe89e);

  /// Material icon "open with": <i class="material-icons md-48">open_with</i>
  static const IconData open_with = const IconData(0xe89f);

  /// Material icon "pages": <i class="material-icons md-48">pages</i>
  static const IconData pages = const IconData(0xe7f9);

  /// Material icon "pageview": <i class="material-icons md-48">pageview</i>
  static const IconData pageview = const IconData(0xe8a0);

  /// Material icon "palette": <i class="material-icons md-48">palette</i>
  static const IconData palette = const IconData(0xe40a);

  /// Material icon "pan tool": <i class="material-icons md-48">pan_tool</i>
  static const IconData pan_tool = const IconData(0xe925);

  /// Material icon "panorama": <i class="material-icons md-48">panorama</i>
  static const IconData panorama = const IconData(0xe40b);

  /// Material icon "panorama fish eye": <i class="material-icons md-48">panorama_fish_eye</i>
  static const IconData panorama_fish_eye = const IconData(0xe40c);

  /// Material icon "panorama horizontal": <i class="material-icons md-48">panorama_horizontal</i>
  static const IconData panorama_horizontal = const IconData(0xe40d);

  /// Material icon "panorama vertical": <i class="material-icons md-48">panorama_vertical</i>
  static const IconData panorama_vertical = const IconData(0xe40e);

  /// Material icon "panorama wide angle": <i class="material-icons md-48">panorama_wide_angle</i>
  static const IconData panorama_wide_angle = const IconData(0xe40f);

  /// Material icon "party mode": <i class="material-icons md-48">party_mode</i>
  static const IconData party_mode = const IconData(0xe7fa);

  /// Material icon "pause": <i class="material-icons md-48">pause</i>
  static const IconData pause = const IconData(0xe034);

  /// Material icon "pause circle filled": <i class="material-icons md-48">pause_circle_filled</i>
  static const IconData pause_circle_filled = const IconData(0xe035);

  /// Material icon "pause circle outline": <i class="material-icons md-48">pause_circle_outline</i>
  static const IconData pause_circle_outline = const IconData(0xe036);

  /// Material icon "payment": <i class="material-icons md-48">payment</i>
  static const IconData payment = const IconData(0xe8a1);

  /// Material icon "people": <i class="material-icons md-48">people</i>
  static const IconData people = const IconData(0xe7fb);

  /// Material icon "people outline": <i class="material-icons md-48">people_outline</i>
  static const IconData people_outline = const IconData(0xe7fc);

  /// Material icon "perm camera mic": <i class="material-icons md-48">perm_camera_mic</i>
  static const IconData perm_camera_mic = const IconData(0xe8a2);

  /// Material icon "perm contact calendar": <i class="material-icons md-48">perm_contact_calendar</i>
  static const IconData perm_contact_calendar = const IconData(0xe8a3);

  /// Material icon "perm data setting": <i class="material-icons md-48">perm_data_setting</i>
  static const IconData perm_data_setting = const IconData(0xe8a4);

  /// Material icon "perm device information": <i class="material-icons md-48">perm_device_information</i>
  static const IconData perm_device_information = const IconData(0xe8a5);

  /// Material icon "perm identity": <i class="material-icons md-48">perm_identity</i>
  static const IconData perm_identity = const IconData(0xe8a6);

  /// Material icon "perm media": <i class="material-icons md-48">perm_media</i>
  static const IconData perm_media = const IconData(0xe8a7);

  /// Material icon "perm phone msg": <i class="material-icons md-48">perm_phone_msg</i>
  static const IconData perm_phone_msg = const IconData(0xe8a8);

  /// Material icon "perm scan wifi": <i class="material-icons md-48">perm_scan_wifi</i>
  static const IconData perm_scan_wifi = const IconData(0xe8a9);

  /// Material icon "person": <i class="material-icons md-48">person</i>
  static const IconData person = const IconData(0xe7fd);

  /// Material icon "person add": <i class="material-icons md-48">person_add</i>
  static const IconData person_add = const IconData(0xe7fe);

  /// Material icon "person outline": <i class="material-icons md-48">person_outline</i>
  static const IconData person_outline = const IconData(0xe7ff);

  /// Material icon "person pin": <i class="material-icons md-48">person_pin</i>
  static const IconData person_pin = const IconData(0xe55a);

  /// Material icon "person pin circle": <i class="material-icons md-48">person_pin_circle</i>
  static const IconData person_pin_circle = const IconData(0xe56a);

  /// Material icon "personal video": <i class="material-icons md-48">personal_video</i>
  static const IconData personal_video = const IconData(0xe63b);

  /// Material icon "pets": <i class="material-icons md-48">pets</i>
  static const IconData pets = const IconData(0xe91d);

  /// Material icon "phone": <i class="material-icons md-48">phone</i>
  static const IconData phone = const IconData(0xe0cd);

  /// Material icon "phone android": <i class="material-icons md-48">phone_android</i>
  static const IconData phone_android = const IconData(0xe324);

  /// Material icon "phone bluetooth speaker": <i class="material-icons md-48">phone_bluetooth_speaker</i>
  static const IconData phone_bluetooth_speaker = const IconData(0xe61b);

  /// Material icon "phone forwarded": <i class="material-icons md-48">phone_forwarded</i>
  static const IconData phone_forwarded = const IconData(0xe61c);

  /// Material icon "phone in talk": <i class="material-icons md-48">phone_in_talk</i>
  static const IconData phone_in_talk = const IconData(0xe61d);

  /// Material icon "phone iphone": <i class="material-icons md-48">phone_iphone</i>
  static const IconData phone_iphone = const IconData(0xe325);

  /// Material icon "phone locked": <i class="material-icons md-48">phone_locked</i>
  static const IconData phone_locked = const IconData(0xe61e);

  /// Material icon "phone missed": <i class="material-icons md-48">phone_missed</i>
  static const IconData phone_missed = const IconData(0xe61f);

  /// Material icon "phone paused": <i class="material-icons md-48">phone_paused</i>
  static const IconData phone_paused = const IconData(0xe620);

  /// Material icon "phonelink": <i class="material-icons md-48">phonelink</i>
  static const IconData phonelink = const IconData(0xe326);

  /// Material icon "phonelink erase": <i class="material-icons md-48">phonelink_erase</i>
  static const IconData phonelink_erase = const IconData(0xe0db);

  /// Material icon "phonelink lock": <i class="material-icons md-48">phonelink_lock</i>
  static const IconData phonelink_lock = const IconData(0xe0dc);

  /// Material icon "phonelink off": <i class="material-icons md-48">phonelink_off</i>
  static const IconData phonelink_off = const IconData(0xe327);

  /// Material icon "phonelink ring": <i class="material-icons md-48">phonelink_ring</i>
  static const IconData phonelink_ring = const IconData(0xe0dd);

  /// Material icon "phonelink setup": <i class="material-icons md-48">phonelink_setup</i>
  static const IconData phonelink_setup = const IconData(0xe0de);

  /// Material icon "photo": <i class="material-icons md-48">photo</i>
  static const IconData photo = const IconData(0xe410);

  /// Material icon "photo album": <i class="material-icons md-48">photo_album</i>
  static const IconData photo_album = const IconData(0xe411);

  /// Material icon "photo camera": <i class="material-icons md-48">photo_camera</i>
  static const IconData photo_camera = const IconData(0xe412);

  /// Material icon "photo filter": <i class="material-icons md-48">photo_filter</i>
  static const IconData photo_filter = const IconData(0xe43b);

  /// Material icon "photo library": <i class="material-icons md-48">photo_library</i>
  static const IconData photo_library = const IconData(0xe413);

  /// Material icon "photo size select actual": <i class="material-icons md-48">photo_size_select_actual</i>
  static const IconData photo_size_select_actual = const IconData(0xe432);

  /// Material icon "photo size select large": <i class="material-icons md-48">photo_size_select_large</i>
  static const IconData photo_size_select_large = const IconData(0xe433);

  /// Material icon "photo size select small": <i class="material-icons md-48">photo_size_select_small</i>
  static const IconData photo_size_select_small = const IconData(0xe434);

  /// Material icon "picture as pdf": <i class="material-icons md-48">picture_as_pdf</i>
  static const IconData picture_as_pdf = const IconData(0xe415);

  /// Material icon "picture in picture": <i class="material-icons md-48">picture_in_picture</i>
  static const IconData picture_in_picture = const IconData(0xe8aa);

  /// Material icon "picture in picture alt": <i class="material-icons md-48">picture_in_picture_alt</i>
  static const IconData picture_in_picture_alt = const IconData(0xe911);

  /// Material icon "pie chart": <i class="material-icons md-48">pie_chart</i>
  static const IconData pie_chart = const IconData(0xe6c4);

  /// Material icon "pie chart outlined": <i class="material-icons md-48">pie_chart_outlined</i>
  static const IconData pie_chart_outlined = const IconData(0xe6c5);

  /// Material icon "pin drop": <i class="material-icons md-48">pin_drop</i>
  static const IconData pin_drop = const IconData(0xe55e);

  /// Material icon "place": <i class="material-icons md-48">place</i>
  static const IconData place = const IconData(0xe55f);

  /// Material icon "play arrow": <i class="material-icons md-48">play_arrow</i>
  static const IconData play_arrow = const IconData(0xe037);

  /// Material icon "play circle filled": <i class="material-icons md-48">play_circle_filled</i>
  static const IconData play_circle_filled = const IconData(0xe038);

  /// Material icon "play circle outline": <i class="material-icons md-48">play_circle_outline</i>
  static const IconData play_circle_outline = const IconData(0xe039);

  /// Material icon "play for work": <i class="material-icons md-48">play_for_work</i>
  static const IconData play_for_work = const IconData(0xe906);

  /// Material icon "playlist add": <i class="material-icons md-48">playlist_add</i>
  static const IconData playlist_add = const IconData(0xe03b);

  /// Material icon "playlist add check": <i class="material-icons md-48">playlist_add_check</i>
  static const IconData playlist_add_check = const IconData(0xe065);

  /// Material icon "playlist play": <i class="material-icons md-48">playlist_play</i>
  static const IconData playlist_play = const IconData(0xe05f);

  /// Material icon "plus one": <i class="material-icons md-48">plus_one</i>
  static const IconData plus_one = const IconData(0xe800);

  /// Material icon "poll": <i class="material-icons md-48">poll</i>
  static const IconData poll = const IconData(0xe801);

  /// Material icon "polymer": <i class="material-icons md-48">polymer</i>
  static const IconData polymer = const IconData(0xe8ab);

  /// Material icon "pool": <i class="material-icons md-48">pool</i>
  static const IconData pool = const IconData(0xeb48);

  /// Material icon "portable wifi off": <i class="material-icons md-48">portable_wifi_off</i>
  static const IconData portable_wifi_off = const IconData(0xe0ce);

  /// Material icon "portrait": <i class="material-icons md-48">portrait</i>
  static const IconData portrait = const IconData(0xe416);

  /// Material icon "power": <i class="material-icons md-48">power</i>
  static const IconData power = const IconData(0xe63c);

  /// Material icon "power input": <i class="material-icons md-48">power_input</i>
  static const IconData power_input = const IconData(0xe336);

  /// Material icon "power settings const": <i class="material-icons md-48">power_settings_const</i>
  static const IconData power_settings_const = const IconData(0xe8ac);

  /// Material icon "pregnant woman": <i class="material-icons md-48">pregnant_woman</i>
  static const IconData pregnant_woman = const IconData(0xe91e);

  /// Material icon "present to all": <i class="material-icons md-48">present_to_all</i>
  static const IconData present_to_all = const IconData(0xe0df);

  /// Material icon "print": <i class="material-icons md-48">print</i>
  static const IconData print = const IconData(0xe8ad);

  /// Material icon "priority high": <i class="material-icons md-48">priority_high</i>
  static const IconData priority_high = const IconData(0xe645);

  /// Material icon "public": <i class="material-icons md-48">public</i>
  static const IconData public = const IconData(0xe80b);

  /// Material icon "publish": <i class="material-icons md-48">publish</i>
  static const IconData publish = const IconData(0xe255);

  /// Material icon "query builder": <i class="material-icons md-48">query_builder</i>
  static const IconData query_builder = const IconData(0xe8ae);

  /// Material icon "question answer": <i class="material-icons md-48">question_answer</i>
  static const IconData question_answer = const IconData(0xe8af);

  /// Material icon "queue": <i class="material-icons md-48">queue</i>
  static const IconData queue = const IconData(0xe03c);

  /// Material icon "queue music": <i class="material-icons md-48">queue_music</i>
  static const IconData queue_music = const IconData(0xe03d);

  /// Material icon "queue play next": <i class="material-icons md-48">queue_play_next</i>
  static const IconData queue_play_next = const IconData(0xe066);

  /// Material icon "radio": <i class="material-icons md-48">radio</i>
  static const IconData radio = const IconData(0xe03e);

  /// Material icon "radio button checked": <i class="material-icons md-48">radio_button_checked</i>
  static const IconData radio_button_checked = const IconData(0xe837);

  /// Material icon "radio button unchecked": <i class="material-icons md-48">radio_button_unchecked</i>
  static const IconData radio_button_unchecked = const IconData(0xe836);

  /// Material icon "rate review": <i class="material-icons md-48">rate_review</i>
  static const IconData rate_review = const IconData(0xe560);

  /// Material icon "receipt": <i class="material-icons md-48">receipt</i>
  static const IconData receipt = const IconData(0xe8b0);

  /// Material icon "recent actors": <i class="material-icons md-48">recent_actors</i>
  static const IconData recent_actors = const IconData(0xe03f);

  /// Material icon "record voice over": <i class="material-icons md-48">record_voice_over</i>
  static const IconData record_voice_over = const IconData(0xe91f);

  /// Material icon "redeem": <i class="material-icons md-48">redeem</i>
  static const IconData redeem = const IconData(0xe8b1);

  /// Material icon "redo": <i class="material-icons md-48">redo</i>
  static const IconData redo = const IconData(0xe15a);

  /// Material icon "refresh": <i class="material-icons md-48">refresh</i>
  static const IconData refresh = const IconData(0xe5d5);

  /// Material icon "remove": <i class="material-icons md-48">remove</i>
  static const IconData remove = const IconData(0xe15b);

  /// Material icon "remove circle": <i class="material-icons md-48">remove_circle</i>
  static const IconData remove_circle = const IconData(0xe15c);

  /// Material icon "remove circle outline": <i class="material-icons md-48">remove_circle_outline</i>
  static const IconData remove_circle_outline = const IconData(0xe15d);

  /// Material icon "remove from queue": <i class="material-icons md-48">remove_from_queue</i>
  static const IconData remove_from_queue = const IconData(0xe067);

  /// Material icon "remove red eye": <i class="material-icons md-48">remove_red_eye</i>
  static const IconData remove_red_eye = const IconData(0xe417);

  /// Material icon "remove shopping cart": <i class="material-icons md-48">remove_shopping_cart</i>
  static const IconData remove_shopping_cart = const IconData(0xe928);

  /// Material icon "reorder": <i class="material-icons md-48">reorder</i>
  static const IconData reorder = const IconData(0xe8fe);

  /// Material icon "repeat": <i class="material-icons md-48">repeat</i>
  static const IconData repeat = const IconData(0xe040);

  /// Material icon "repeat one": <i class="material-icons md-48">repeat_one</i>
  static const IconData repeat_one = const IconData(0xe041);

  /// Material icon "replay": <i class="material-icons md-48">replay</i>
  static const IconData replay = const IconData(0xe042);

  /// Material icon "replay 10": <i class="material-icons md-48">replay_10</i>
  static const IconData replay_10 = const IconData(0xe059);

  /// Material icon "replay 30": <i class="material-icons md-48">replay_30</i>
  static const IconData replay_30 = const IconData(0xe05a);

  /// Material icon "replay 5": <i class="material-icons md-48">replay_5</i>
  static const IconData replay_5 = const IconData(0xe05b);

  /// Material icon "reply": <i class="material-icons md-48">reply</i>
  static const IconData reply = const IconData(0xe15e);

  /// Material icon "reply all": <i class="material-icons md-48">reply_all</i>
  static const IconData reply_all = const IconData(0xe15f);

  /// Material icon "report": <i class="material-icons md-48">report</i>
  static const IconData report = const IconData(0xe160);

  /// Material icon "report problem": <i class="material-icons md-48">report_problem</i>
  static const IconData report_problem = const IconData(0xe8b2);

  /// Material icon "restaurant": <i class="material-icons md-48">restaurant</i>
  static const IconData restaurant = const IconData(0xe56c);

  /// Material icon "restaurant menu": <i class="material-icons md-48">restaurant_menu</i>
  static const IconData restaurant_menu = const IconData(0xe561);

  /// Material icon "restore": <i class="material-icons md-48">restore</i>
  static const IconData restore = const IconData(0xe8b3);

  /// Material icon "restore page": <i class="material-icons md-48">restore_page</i>
  static const IconData restore_page = const IconData(0xe929);

  /// Material icon "ring volume": <i class="material-icons md-48">ring_volume</i>
  static const IconData ring_volume = const IconData(0xe0d1);

  /// Material icon "room": <i class="material-icons md-48">room</i>
  static const IconData room = const IconData(0xe8b4);

  /// Material icon "room service": <i class="material-icons md-48">room_service</i>
  static const IconData room_service = const IconData(0xeb49);

  /// Material icon "rotate 90 degrees ccw": <i class="material-icons md-48">rotate_90_degrees_ccw</i>
  static const IconData rotate_90_degrees_ccw = const IconData(0xe418);

  /// Material icon "rotate left": <i class="material-icons md-48">rotate_left</i>
  static const IconData rotate_left = const IconData(0xe419);

  /// Material icon "rotate right": <i class="material-icons md-48">rotate_right</i>
  static const IconData rotate_right = const IconData(0xe41a);

  /// Material icon "rounded corner": <i class="material-icons md-48">rounded_corner</i>
  static const IconData rounded_corner = const IconData(0xe920);

  /// Material icon "router": <i class="material-icons md-48">router</i>
  static const IconData router = const IconData(0xe328);

  /// Material icon "rowing": <i class="material-icons md-48">rowing</i>
  static const IconData rowing = const IconData(0xe921);

  /// Material icon "rss feed": <i class="material-icons md-48">rss_feed</i>
  static const IconData rss_feed = const IconData(0xe0e5);

  /// Material icon "rv hookup": <i class="material-icons md-48">rv_hookup</i>
  static const IconData rv_hookup = const IconData(0xe642);

  /// Material icon "satellite": <i class="material-icons md-48">satellite</i>
  static const IconData satellite = const IconData(0xe562);

  /// Material icon "save": <i class="material-icons md-48">save</i>
  static const IconData save = const IconData(0xe161);

  /// Material icon "scanner": <i class="material-icons md-48">scanner</i>
  static const IconData scanner = const IconData(0xe329);

  /// Material icon "schedule": <i class="material-icons md-48">schedule</i>
  static const IconData schedule = const IconData(0xe8b5);

  /// Material icon "school": <i class="material-icons md-48">school</i>
  static const IconData school = const IconData(0xe80c);

  /// Material icon "screen lock landscape": <i class="material-icons md-48">screen_lock_landscape</i>
  static const IconData screen_lock_landscape = const IconData(0xe1be);

  /// Material icon "screen lock portrait": <i class="material-icons md-48">screen_lock_portrait</i>
  static const IconData screen_lock_portrait = const IconData(0xe1bf);

  /// Material icon "screen lock rotation": <i class="material-icons md-48">screen_lock_rotation</i>
  static const IconData screen_lock_rotation = const IconData(0xe1c0);

  /// Material icon "screen rotation": <i class="material-icons md-48">screen_rotation</i>
  static const IconData screen_rotation = const IconData(0xe1c1);

  /// Material icon "screen share": <i class="material-icons md-48">screen_share</i>
  static const IconData screen_share = const IconData(0xe0e2);

  /// Material icon "sd card": <i class="material-icons md-48">sd_card</i>
  static const IconData sd_card = const IconData(0xe623);

  /// Material icon "sd storage": <i class="material-icons md-48">sd_storage</i>
  static const IconData sd_storage = const IconData(0xe1c2);

  /// Material icon "search": <i class="material-icons md-48">search</i>
  static const IconData search = const IconData(0xe8b6);

  /// Material icon "security": <i class="material-icons md-48">security</i>
  static const IconData security = const IconData(0xe32a);

  /// Material icon "select all": <i class="material-icons md-48">select_all</i>
  static const IconData select_all = const IconData(0xe162);

  /// Material icon "send": <i class="material-icons md-48">send</i>
  static const IconData send = const IconData(0xe163);

  /// Material icon "sentiment dissatisfied": <i class="material-icons md-48">sentiment_dissatisfied</i>
  static const IconData sentiment_dissatisfied = const IconData(0xe811);

  /// Material icon "sentiment neutral": <i class="material-icons md-48">sentiment_neutral</i>
  static const IconData sentiment_neutral = const IconData(0xe812);

  /// Material icon "sentiment satisfied": <i class="material-icons md-48">sentiment_satisfied</i>
  static const IconData sentiment_satisfied = const IconData(0xe813);

  /// Material icon "sentiment very dissatisfied": <i class="material-icons md-48">sentiment_very_dissatisfied</i>
  static const IconData sentiment_very_dissatisfied = const IconData(0xe814);

  /// Material icon "sentiment very satisfied": <i class="material-icons md-48">sentiment_very_satisfied</i>
  static const IconData sentiment_very_satisfied = const IconData(0xe815);

  /// Material icon "settings": <i class="material-icons md-48">settings</i>
  static const IconData settings = const IconData(0xe8b8);

  /// Material icon "settings applications": <i class="material-icons md-48">settings_applications</i>
  static const IconData settings_applications = const IconData(0xe8b9);

  /// Material icon "settings backup restore": <i class="material-icons md-48">settings_backup_restore</i>
  static const IconData settings_backup_restore = const IconData(0xe8ba);

  /// Material icon "settings bluetooth": <i class="material-icons md-48">settings_bluetooth</i>
  static const IconData settings_bluetooth = const IconData(0xe8bb);

  /// Material icon "settings brightness": <i class="material-icons md-48">settings_brightness</i>
  static const IconData settings_brightness = const IconData(0xe8bd);

  /// Material icon "settings cell": <i class="material-icons md-48">settings_cell</i>
  static const IconData settings_cell = const IconData(0xe8bc);

  /// Material icon "settings ethernet": <i class="material-icons md-48">settings_ethernet</i>
  static const IconData settings_ethernet = const IconData(0xe8be);

  /// Material icon "settings input antenna": <i class="material-icons md-48">settings_input_antenna</i>
  static const IconData settings_input_antenna = const IconData(0xe8bf);

  /// Material icon "settings input component": <i class="material-icons md-48">settings_input_component</i>
  static const IconData settings_input_component = const IconData(0xe8c0);

  /// Material icon "settings input composite": <i class="material-icons md-48">settings_input_composite</i>
  static const IconData settings_input_composite = const IconData(0xe8c1);

  /// Material icon "settings input hdmi": <i class="material-icons md-48">settings_input_hdmi</i>
  static const IconData settings_input_hdmi = const IconData(0xe8c2);

  /// Material icon "settings input svideo": <i class="material-icons md-48">settings_input_svideo</i>
  static const IconData settings_input_svideo = const IconData(0xe8c3);

  /// Material icon "settings overscan": <i class="material-icons md-48">settings_overscan</i>
  static const IconData settings_overscan = const IconData(0xe8c4);

  /// Material icon "settings phone": <i class="material-icons md-48">settings_phone</i>
  static const IconData settings_phone = const IconData(0xe8c5);

  /// Material icon "settings power": <i class="material-icons md-48">settings_power</i>
  static const IconData settings_power = const IconData(0xe8c6);

  /// Material icon "settings remote": <i class="material-icons md-48">settings_remote</i>
  static const IconData settings_remote = const IconData(0xe8c7);

  /// Material icon "settings system daydream": <i class="material-icons md-48">settings_system_daydream</i>
  static const IconData settings_system_daydream = const IconData(0xe1c3);

  /// Material icon "settings voice": <i class="material-icons md-48">settings_voice</i>
  static const IconData settings_voice = const IconData(0xe8c8);

  /// Material icon "share": <i class="material-icons md-48">share</i>
  static const IconData share = const IconData(0xe80d);

  /// Material icon "shop": <i class="material-icons md-48">shop</i>
  static const IconData shop = const IconData(0xe8c9);

  /// Material icon "shop two": <i class="material-icons md-48">shop_two</i>
  static const IconData shop_two = const IconData(0xe8ca);

  /// Material icon "shopping basket": <i class="material-icons md-48">shopping_basket</i>
  static const IconData shopping_basket = const IconData(0xe8cb);

  /// Material icon "shopping cart": <i class="material-icons md-48">shopping_cart</i>
  static const IconData shopping_cart = const IconData(0xe8cc);

  /// Material icon "short text": <i class="material-icons md-48">short_text</i>
  static const IconData short_text = const IconData(0xe261);

  /// Material icon "show chart": <i class="material-icons md-48">show_chart</i>
  static const IconData show_chart = const IconData(0xe6e1);

  /// Material icon "shuffle": <i class="material-icons md-48">shuffle</i>
  static const IconData shuffle = const IconData(0xe043);

  /// Material icon "signal cellular 4 bar": <i class="material-icons md-48">signal_cellular_4_bar</i>
  static const IconData signal_cellular_4_bar = const IconData(0xe1c8);

  /// Material icon "signal cellular connected no internet 4 bar": <i class="material-icons md-48">signal_cellular_connected_no_internet_4_bar</i>
  static const IconData signal_cellular_connected_no_internet_4_bar = const IconData(0xe1cd);

  /// Material icon "signal cellular no sim": <i class="material-icons md-48">signal_cellular_no_sim</i>
  static const IconData signal_cellular_no_sim = const IconData(0xe1ce);

  /// Material icon "signal cellular null": <i class="material-icons md-48">signal_cellular_null</i>
  static const IconData signal_cellular_null = const IconData(0xe1cf);

  /// Material icon "signal cellular off": <i class="material-icons md-48">signal_cellular_off</i>
  static const IconData signal_cellular_off = const IconData(0xe1d0);

  /// Material icon "signal wifi 4 bar": <i class="material-icons md-48">signal_wifi_4_bar</i>
  static const IconData signal_wifi_4_bar = const IconData(0xe1d8);

  /// Material icon "signal wifi 4 bar lock": <i class="material-icons md-48">signal_wifi_4_bar_lock</i>
  static const IconData signal_wifi_4_bar_lock = const IconData(0xe1d9);

  /// Material icon "signal wifi off": <i class="material-icons md-48">signal_wifi_off</i>
  static const IconData signal_wifi_off = const IconData(0xe1da);

  /// Material icon "sim card": <i class="material-icons md-48">sim_card</i>
  static const IconData sim_card = const IconData(0xe32b);

  /// Material icon "sim card alert": <i class="material-icons md-48">sim_card_alert</i>
  static const IconData sim_card_alert = const IconData(0xe624);

  /// Material icon "skip next": <i class="material-icons md-48">skip_next</i>
  static const IconData skip_next = const IconData(0xe044);

  /// Material icon "skip previous": <i class="material-icons md-48">skip_previous</i>
  static const IconData skip_previous = const IconData(0xe045);

  /// Material icon "slideshow": <i class="material-icons md-48">slideshow</i>
  static const IconData slideshow = const IconData(0xe41b);

  /// Material icon "slow motion video": <i class="material-icons md-48">slow_motion_video</i>
  static const IconData slow_motion_video = const IconData(0xe068);

  /// Material icon "smartphone": <i class="material-icons md-48">smartphone</i>
  static const IconData smartphone = const IconData(0xe32c);

  /// Material icon "smoke free": <i class="material-icons md-48">smoke_free</i>
  static const IconData smoke_free = const IconData(0xeb4a);

  /// Material icon "smoking rooms": <i class="material-icons md-48">smoking_rooms</i>
  static const IconData smoking_rooms = const IconData(0xeb4b);

  /// Material icon "sms": <i class="material-icons md-48">sms</i>
  static const IconData sms = const IconData(0xe625);

  /// Material icon "sms failed": <i class="material-icons md-48">sms_failed</i>
  static const IconData sms_failed = const IconData(0xe626);

  /// Material icon "snooze": <i class="material-icons md-48">snooze</i>
  static const IconData snooze = const IconData(0xe046);

  /// Material icon "sort": <i class="material-icons md-48">sort</i>
  static const IconData sort = const IconData(0xe164);

  /// Material icon "sort by alpha": <i class="material-icons md-48">sort_by_alpha</i>
  static const IconData sort_by_alpha = const IconData(0xe053);

  /// Material icon "spa": <i class="material-icons md-48">spa</i>
  static const IconData spa = const IconData(0xeb4c);

  /// Material icon "space bar": <i class="material-icons md-48">space_bar</i>
  static const IconData space_bar = const IconData(0xe256);

  /// Material icon "speaker": <i class="material-icons md-48">speaker</i>
  static const IconData speaker = const IconData(0xe32d);

  /// Material icon "speaker group": <i class="material-icons md-48">speaker_group</i>
  static const IconData speaker_group = const IconData(0xe32e);

  /// Material icon "speaker notes": <i class="material-icons md-48">speaker_notes</i>
  static const IconData speaker_notes = const IconData(0xe8cd);

  /// Material icon "speaker notes off": <i class="material-icons md-48">speaker_notes_off</i>
  static const IconData speaker_notes_off = const IconData(0xe92a);

  /// Material icon "speaker phone": <i class="material-icons md-48">speaker_phone</i>
  static const IconData speaker_phone = const IconData(0xe0d2);

  /// Material icon "spellcheck": <i class="material-icons md-48">spellcheck</i>
  static const IconData spellcheck = const IconData(0xe8ce);

  /// Material icon "star": <i class="material-icons md-48">star</i>
  static const IconData star = const IconData(0xe838);

  /// Material icon "star border": <i class="material-icons md-48">star_border</i>
  static const IconData star_border = const IconData(0xe83a);

  /// Material icon "star half": <i class="material-icons md-48">star_half</i>
  static const IconData star_half = const IconData(0xe839);

  /// Material icon "stars": <i class="material-icons md-48">stars</i>
  static const IconData stars = const IconData(0xe8d0);

  /// Material icon "stay current landscape": <i class="material-icons md-48">stay_current_landscape</i>
  static const IconData stay_current_landscape = const IconData(0xe0d3);

  /// Material icon "stay current portrait": <i class="material-icons md-48">stay_current_portrait</i>
  static const IconData stay_current_portrait = const IconData(0xe0d4);

  /// Material icon "stay primary landscape": <i class="material-icons md-48">stay_primary_landscape</i>
  static const IconData stay_primary_landscape = const IconData(0xe0d5);

  /// Material icon "stay primary portrait": <i class="material-icons md-48">stay_primary_portrait</i>
  static const IconData stay_primary_portrait = const IconData(0xe0d6);

  /// Material icon "stop": <i class="material-icons md-48">stop</i>
  static const IconData stop = const IconData(0xe047);

  /// Material icon "stop screen share": <i class="material-icons md-48">stop_screen_share</i>
  static const IconData stop_screen_share = const IconData(0xe0e3);

  /// Material icon "storage": <i class="material-icons md-48">storage</i>
  static const IconData storage = const IconData(0xe1db);

  /// Material icon "store": <i class="material-icons md-48">store</i>
  static const IconData store = const IconData(0xe8d1);

  /// Material icon "store mall directory": <i class="material-icons md-48">store_mall_directory</i>
  static const IconData store_mall_directory = const IconData(0xe563);

  /// Material icon "straighten": <i class="material-icons md-48">straighten</i>
  static const IconData straighten = const IconData(0xe41c);

  /// Material icon "streetview": <i class="material-icons md-48">streetview</i>
  static const IconData streetview = const IconData(0xe56e);

  /// Material icon "strikethrough s": <i class="material-icons md-48">strikethrough_s</i>
  static const IconData strikethrough_s = const IconData(0xe257);

  /// Material icon "style": <i class="material-icons md-48">style</i>
  static const IconData style = const IconData(0xe41d);

  /// Material icon "subdirectory arrow left": <i class="material-icons md-48">subdirectory_arrow_left</i>
  static const IconData subdirectory_arrow_left = const IconData(0xe5d9);

  /// Material icon "subdirectory arrow right": <i class="material-icons md-48">subdirectory_arrow_right</i>
  static const IconData subdirectory_arrow_right = const IconData(0xe5da);

  /// Material icon "subject": <i class="material-icons md-48">subject</i>
  static const IconData subject = const IconData(0xe8d2);

  /// Material icon "subscriptions": <i class="material-icons md-48">subscriptions</i>
  static const IconData subscriptions = const IconData(0xe064);

  /// Material icon "subtitles": <i class="material-icons md-48">subtitles</i>
  static const IconData subtitles = const IconData(0xe048);

  /// Material icon "subway": <i class="material-icons md-48">subway</i>
  static const IconData subway = const IconData(0xe56f);

  /// Material icon "supervisor account": <i class="material-icons md-48">supervisor_account</i>
  static const IconData supervisor_account = const IconData(0xe8d3);

  /// Material icon "surround sound": <i class="material-icons md-48">surround_sound</i>
  static const IconData surround_sound = const IconData(0xe049);

  /// Material icon "swap calls": <i class="material-icons md-48">swap_calls</i>
  static const IconData swap_calls = const IconData(0xe0d7);

  /// Material icon "swap horiz": <i class="material-icons md-48">swap_horiz</i>
  static const IconData swap_horiz = const IconData(0xe8d4);

  /// Material icon "swap vert": <i class="material-icons md-48">swap_vert</i>
  static const IconData swap_vert = const IconData(0xe8d5);

  /// Material icon "swap vertical circle": <i class="material-icons md-48">swap_vertical_circle</i>
  static const IconData swap_vertical_circle = const IconData(0xe8d6);

  /// Material icon "switch camera": <i class="material-icons md-48">switch_camera</i>
  static const IconData switch_camera = const IconData(0xe41e);

  /// Material icon "switch video": <i class="material-icons md-48">switch_video</i>
  static const IconData switch_video = const IconData(0xe41f);

  /// Material icon "sync": <i class="material-icons md-48">sync</i>
  static const IconData sync = const IconData(0xe627);

  /// Material icon "sync disabled": <i class="material-icons md-48">sync_disabled</i>
  static const IconData sync_disabled = const IconData(0xe628);

  /// Material icon "sync problem": <i class="material-icons md-48">sync_problem</i>
  static const IconData sync_problem = const IconData(0xe629);

  /// Material icon "system update": <i class="material-icons md-48">system_update</i>
  static const IconData system_update = const IconData(0xe62a);

  /// Material icon "system update alt": <i class="material-icons md-48">system_update_alt</i>
  static const IconData system_update_alt = const IconData(0xe8d7);

  /// Material icon "tab": <i class="material-icons md-48">tab</i>
  static const IconData tab = const IconData(0xe8d8);

  /// Material icon "tab unselected": <i class="material-icons md-48">tab_unselected</i>
  static const IconData tab_unselected = const IconData(0xe8d9);

  /// Material icon "tablet": <i class="material-icons md-48">tablet</i>
  static const IconData tablet = const IconData(0xe32f);

  /// Material icon "tablet android": <i class="material-icons md-48">tablet_android</i>
  static const IconData tablet_android = const IconData(0xe330);

  /// Material icon "tablet mac": <i class="material-icons md-48">tablet_mac</i>
  static const IconData tablet_mac = const IconData(0xe331);

  /// Material icon "tag faces": <i class="material-icons md-48">tag_faces</i>
  static const IconData tag_faces = const IconData(0xe420);

  /// Material icon "tap and play": <i class="material-icons md-48">tap_and_play</i>
  static const IconData tap_and_play = const IconData(0xe62b);

  /// Material icon "terrain": <i class="material-icons md-48">terrain</i>
  static const IconData terrain = const IconData(0xe564);

  /// Material icon "text fields": <i class="material-icons md-48">text_fields</i>
  static const IconData text_fields = const IconData(0xe262);

  /// Material icon "text format": <i class="material-icons md-48">text_format</i>
  static const IconData text_format = const IconData(0xe165);

  /// Material icon "textsms": <i class="material-icons md-48">textsms</i>
  static const IconData textsms = const IconData(0xe0d8);

  /// Material icon "texture": <i class="material-icons md-48">texture</i>
  static const IconData texture = const IconData(0xe421);

  /// Material icon "theaters": <i class="material-icons md-48">theaters</i>
  static const IconData theaters = const IconData(0xe8da);

  /// Material icon "thumb down": <i class="material-icons md-48">thumb_down</i>
  static const IconData thumb_down = const IconData(0xe8db);

  /// Material icon "thumb up": <i class="material-icons md-48">thumb_up</i>
  static const IconData thumb_up = const IconData(0xe8dc);

  /// Material icon "thumbs up down": <i class="material-icons md-48">thumbs_up_down</i>
  static const IconData thumbs_up_down = const IconData(0xe8dd);

  /// Material icon "time to leave": <i class="material-icons md-48">time_to_leave</i>
  static const IconData time_to_leave = const IconData(0xe62c);

  /// Material icon "timelapse": <i class="material-icons md-48">timelapse</i>
  static const IconData timelapse = const IconData(0xe422);

  /// Material icon "timeline": <i class="material-icons md-48">timeline</i>
  static const IconData timeline = const IconData(0xe922);

  /// Material icon "timer": <i class="material-icons md-48">timer</i>
  static const IconData timer = const IconData(0xe425);

  /// Material icon "timer 10": <i class="material-icons md-48">timer_10</i>
  static const IconData timer_10 = const IconData(0xe423);

  /// Material icon "timer 3": <i class="material-icons md-48">timer_3</i>
  static const IconData timer_3 = const IconData(0xe424);

  /// Material icon "timer off": <i class="material-icons md-48">timer_off</i>
  static const IconData timer_off = const IconData(0xe426);

  /// Material icon "title": <i class="material-icons md-48">title</i>
  static const IconData title = const IconData(0xe264);

  /// Material icon "toc": <i class="material-icons md-48">toc</i>
  static const IconData toc = const IconData(0xe8de);

  /// Material icon "today": <i class="material-icons md-48">today</i>
  static const IconData today = const IconData(0xe8df);

  /// Material icon "toll": <i class="material-icons md-48">toll</i>
  static const IconData toll = const IconData(0xe8e0);

  /// Material icon "tonality": <i class="material-icons md-48">tonality</i>
  static const IconData tonality = const IconData(0xe427);

  /// Material icon "touch app": <i class="material-icons md-48">touch_app</i>
  static const IconData touch_app = const IconData(0xe913);

  /// Material icon "toys": <i class="material-icons md-48">toys</i>
  static const IconData toys = const IconData(0xe332);

  /// Material icon "track changes": <i class="material-icons md-48">track_changes</i>
  static const IconData track_changes = const IconData(0xe8e1);

  /// Material icon "traffic": <i class="material-icons md-48">traffic</i>
  static const IconData traffic = const IconData(0xe565);

  /// Material icon "train": <i class="material-icons md-48">train</i>
  static const IconData train = const IconData(0xe570);

  /// Material icon "tram": <i class="material-icons md-48">tram</i>
  static const IconData tram = const IconData(0xe571);

  /// Material icon "transfer within a station": <i class="material-icons md-48">transfer_within_a_station</i>
  static const IconData transfer_within_a_station = const IconData(0xe572);

  /// Material icon "transform": <i class="material-icons md-48">transform</i>
  static const IconData transform = const IconData(0xe428);

  /// Material icon "translate": <i class="material-icons md-48">translate</i>
  static const IconData translate = const IconData(0xe8e2);

  /// Material icon "trending down": <i class="material-icons md-48">trending_down</i>
  static const IconData trending_down = const IconData(0xe8e3);

  /// Material icon "trending flat": <i class="material-icons md-48">trending_flat</i>
  static const IconData trending_flat = const IconData(0xe8e4);

  /// Material icon "trending up": <i class="material-icons md-48">trending_up</i>
  static const IconData trending_up = const IconData(0xe8e5);

  /// Material icon "tune": <i class="material-icons md-48">tune</i>
  static const IconData tune = const IconData(0xe429);

  /// Material icon "turned in": <i class="material-icons md-48">turned_in</i>
  static const IconData turned_in = const IconData(0xe8e6);

  /// Material icon "turned in not": <i class="material-icons md-48">turned_in_not</i>
  static const IconData turned_in_not = const IconData(0xe8e7);

  /// Material icon "tv": <i class="material-icons md-48">tv</i>
  static const IconData tv = const IconData(0xe333);

  /// Material icon "unarchive": <i class="material-icons md-48">unarchive</i>
  static const IconData unarchive = const IconData(0xe169);

  /// Material icon "undo": <i class="material-icons md-48">undo</i>
  static const IconData undo = const IconData(0xe166);

  /// Material icon "unfold less": <i class="material-icons md-48">unfold_less</i>
  static const IconData unfold_less = const IconData(0xe5d6);

  /// Material icon "unfold more": <i class="material-icons md-48">unfold_more</i>
  static const IconData unfold_more = const IconData(0xe5d7);

  /// Material icon "update": <i class="material-icons md-48">update</i>
  static const IconData update = const IconData(0xe923);

  /// Material icon "usb": <i class="material-icons md-48">usb</i>
  static const IconData usb = const IconData(0xe1e0);

  /// Material icon "verified user": <i class="material-icons md-48">verified_user</i>
  static const IconData verified_user = const IconData(0xe8e8);

  /// Material icon "vertical align bottom": <i class="material-icons md-48">vertical_align_bottom</i>
  static const IconData vertical_align_bottom = const IconData(0xe258);

  /// Material icon "vertical align center": <i class="material-icons md-48">vertical_align_center</i>
  static const IconData vertical_align_center = const IconData(0xe259);

  /// Material icon "vertical align top": <i class="material-icons md-48">vertical_align_top</i>
  static const IconData vertical_align_top = const IconData(0xe25a);

  /// Material icon "vibration": <i class="material-icons md-48">vibration</i>
  static const IconData vibration = const IconData(0xe62d);

  /// Material icon "video call": <i class="material-icons md-48">video_call</i>
  static const IconData video_call = const IconData(0xe070);

  /// Material icon "video label": <i class="material-icons md-48">video_label</i>
  static const IconData video_label = const IconData(0xe071);

  /// Material icon "video library": <i class="material-icons md-48">video_library</i>
  static const IconData video_library = const IconData(0xe04a);

  /// Material icon "videocam": <i class="material-icons md-48">videocam</i>
  static const IconData videocam = const IconData(0xe04b);

  /// Material icon "videocam off": <i class="material-icons md-48">videocam_off</i>
  static const IconData videocam_off = const IconData(0xe04c);

  /// Material icon "videogame asset": <i class="material-icons md-48">videogame_asset</i>
  static const IconData videogame_asset = const IconData(0xe338);

  /// Material icon "view agenda": <i class="material-icons md-48">view_agenda</i>
  static const IconData view_agenda = const IconData(0xe8e9);

  /// Material icon "view array": <i class="material-icons md-48">view_array</i>
  static const IconData view_array = const IconData(0xe8ea);

  /// Material icon "view carousel": <i class="material-icons md-48">view_carousel</i>
  static const IconData view_carousel = const IconData(0xe8eb);

  /// Material icon "view column": <i class="material-icons md-48">view_column</i>
  static const IconData view_column = const IconData(0xe8ec);

  /// Material icon "view comfy": <i class="material-icons md-48">view_comfy</i>
  static const IconData view_comfy = const IconData(0xe42a);

  /// Material icon "view compact": <i class="material-icons md-48">view_compact</i>
  static const IconData view_compact = const IconData(0xe42b);

  /// Material icon "view day": <i class="material-icons md-48">view_day</i>
  static const IconData view_day = const IconData(0xe8ed);

  /// Material icon "view headline": <i class="material-icons md-48">view_headline</i>
  static const IconData view_headline = const IconData(0xe8ee);

  /// Material icon "view list": <i class="material-icons md-48">view_list</i>
  static const IconData view_list = const IconData(0xe8ef);

  /// Material icon "view module": <i class="material-icons md-48">view_module</i>
  static const IconData view_module = const IconData(0xe8f0);

  /// Material icon "view quilt": <i class="material-icons md-48">view_quilt</i>
  static const IconData view_quilt = const IconData(0xe8f1);

  /// Material icon "view stream": <i class="material-icons md-48">view_stream</i>
  static const IconData view_stream = const IconData(0xe8f2);

  /// Material icon "view week": <i class="material-icons md-48">view_week</i>
  static const IconData view_week = const IconData(0xe8f3);

  /// Material icon "vignette": <i class="material-icons md-48">vignette</i>
  static const IconData vignette = const IconData(0xe435);

  /// Material icon "visibility": <i class="material-icons md-48">visibility</i>
  static const IconData visibility = const IconData(0xe8f4);

  /// Material icon "visibility off": <i class="material-icons md-48">visibility_off</i>
  static const IconData visibility_off = const IconData(0xe8f5);

  /// Material icon "voice chat": <i class="material-icons md-48">voice_chat</i>
  static const IconData voice_chat = const IconData(0xe62e);

  /// Material icon "voicemail": <i class="material-icons md-48">voicemail</i>
  static const IconData voicemail = const IconData(0xe0d9);

  /// Material icon "volume down": <i class="material-icons md-48">volume_down</i>
  static const IconData volume_down = const IconData(0xe04d);

  /// Material icon "volume mute": <i class="material-icons md-48">volume_mute</i>
  static const IconData volume_mute = const IconData(0xe04e);

  /// Material icon "volume off": <i class="material-icons md-48">volume_off</i>
  static const IconData volume_off = const IconData(0xe04f);

  /// Material icon "volume up": <i class="material-icons md-48">volume_up</i>
  static const IconData volume_up = const IconData(0xe050);

  /// Material icon "vpn key": <i class="material-icons md-48">vpn_key</i>
  static const IconData vpn_key = const IconData(0xe0da);

  /// Material icon "vpn lock": <i class="material-icons md-48">vpn_lock</i>
  static const IconData vpn_lock = const IconData(0xe62f);

  /// Material icon "wallpaper": <i class="material-icons md-48">wallpaper</i>
  static const IconData wallpaper = const IconData(0xe1bc);

  /// Material icon "warning": <i class="material-icons md-48">warning</i>
  static const IconData warning = const IconData(0xe002);

  /// Material icon "watch": <i class="material-icons md-48">watch</i>
  static const IconData watch = const IconData(0xe334);

  /// Material icon "watch later": <i class="material-icons md-48">watch_later</i>
  static const IconData watch_later = const IconData(0xe924);

  /// Material icon "wb auto": <i class="material-icons md-48">wb_auto</i>
  static const IconData wb_auto = const IconData(0xe42c);

  /// Material icon "wb cloudy": <i class="material-icons md-48">wb_cloudy</i>
  static const IconData wb_cloudy = const IconData(0xe42d);

  /// Material icon "wb incandescent": <i class="material-icons md-48">wb_incandescent</i>
  static const IconData wb_incandescent = const IconData(0xe42e);

  /// Material icon "wb iridescent": <i class="material-icons md-48">wb_iridescent</i>
  static const IconData wb_iridescent = const IconData(0xe436);

  /// Material icon "wb sunny": <i class="material-icons md-48">wb_sunny</i>
  static const IconData wb_sunny = const IconData(0xe430);

  /// Material icon "wc": <i class="material-icons md-48">wc</i>
  static const IconData wc = const IconData(0xe63d);

  /// Material icon "web": <i class="material-icons md-48">web</i>
  static const IconData web = const IconData(0xe051);

  /// Material icon "web asset": <i class="material-icons md-48">web_asset</i>
  static const IconData web_asset = const IconData(0xe069);

  /// Material icon "weekend": <i class="material-icons md-48">weekend</i>
  static const IconData weekend = const IconData(0xe16b);

  /// Material icon "whatshot": <i class="material-icons md-48">whatshot</i>
  static const IconData whatshot = const IconData(0xe80e);

  /// Material icon "widgets": <i class="material-icons md-48">widgets</i>
  static const IconData widgets = const IconData(0xe1bd);

  /// Material icon "wifi": <i class="material-icons md-48">wifi</i>
  static const IconData wifi = const IconData(0xe63e);

  /// Material icon "wifi lock": <i class="material-icons md-48">wifi_lock</i>
  static const IconData wifi_lock = const IconData(0xe1e1);

  /// Material icon "wifi tethering": <i class="material-icons md-48">wifi_tethering</i>
  static const IconData wifi_tethering = const IconData(0xe1e2);

  /// Material icon "work": <i class="material-icons md-48">work</i>
  static const IconData work = const IconData(0xe8f9);

  /// Material icon "wrap text": <i class="material-icons md-48">wrap_text</i>
  static const IconData wrap_text = const IconData(0xe25b);

  /// Material icon "youtube searched for": <i class="material-icons md-48">youtube_searched_for</i>
  static const IconData youtube_searched_for = const IconData(0xe8fa);

  /// Material icon "zoom in": <i class="material-icons md-48">zoom_in</i>
  static const IconData zoom_in = const IconData(0xe8ff);

  /// Material icon "zoom out": <i class="material-icons md-48">zoom_out</i>
  static const IconData zoom_out = const IconData(0xe900);

  /// Material icon "zoom out map": <i class="material-icons md-48">zoom_out_map</i>
  static const IconData zoom_out_map = const IconData(0xe56b);
}
