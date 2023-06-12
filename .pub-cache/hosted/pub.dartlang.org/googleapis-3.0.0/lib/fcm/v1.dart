// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Firebase Cloud Messaging API - v1
///
/// FCM send API that provides a cross-platform messaging solution to reliably
/// deliver messages at no cost.
///
/// For more information, see <https://firebase.google.com/docs/cloud-messaging>
///
/// Create an instance of [FirebaseCloudMessagingApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsMessagesResource]
library fcm.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// FCM send API that provides a cross-platform messaging solution to reliably
/// deliver messages at no cost.
class FirebaseCloudMessagingApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  FirebaseCloudMessagingApi(http.Client client,
      {core.String rootUrl = 'https://fcm.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsMessagesResource get messages => ProjectsMessagesResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsMessagesResource {
  final commons.ApiRequester _requester;

  ProjectsMessagesResource(commons.ApiRequester client) : _requester = client;

  /// Send a message to specified target (a registration token, topic or
  /// condition).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. It contains the Firebase project id (i.e. the unique
  /// identifier for your Firebase project), in the format of
  /// `projects/{project_id}`. For legacy support, the numeric project number
  /// with no padding is also supported in the format of
  /// `projects/{project_number}`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Message].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Message> send(
    SendMessageRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/messages:send';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Message.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Android specific options for messages sent through
/// [FCM connection server](https://goo.gl/4GLdUl).
class AndroidConfig {
  /// An identifier of a group of messages that can be collapsed, so that only
  /// the last message gets sent when delivery can be resumed.
  ///
  /// A maximum of 4 different collapse keys is allowed at any given time.
  core.String? collapseKey;

  /// Arbitrary key/value payload.
  ///
  /// If present, it will override google.firebase.fcm.v1.Message.data.
  core.Map<core.String, core.String>? data;

  /// If set to true, messages will be allowed to be delivered to the app while
  /// the device is in direct boot mode.
  ///
  /// See
  /// [Support Direct Boot mode](https://developer.android.com/training/articles/direct-boot).
  core.bool? directBootOk;

  /// Options for features provided by the FCM SDK for Android.
  AndroidFcmOptions? fcmOptions;

  /// Notification to send to android devices.
  AndroidNotification? notification;

  /// Message priority.
  ///
  /// Can take "normal" and "high" values. For more information, see
  /// [Setting the priority of a message](https://goo.gl/GjONJv).
  /// Possible string values are:
  /// - "NORMAL" : Default priority for data messages. Normal priority messages
  /// won't open network connections on a sleeping device, and their delivery
  /// may be delayed to conserve the battery. For less time-sensitive messages,
  /// such as notifications of new email or other data to sync, choose normal
  /// delivery priority.
  /// - "HIGH" : Default priority for notification messages. FCM attempts to
  /// deliver high priority messages immediately, allowing the FCM service to
  /// wake a sleeping device when possible and open a network connection to your
  /// app server. Apps with instant messaging, chat, or voice call alerts, for
  /// example, generally need to open a network connection and make sure FCM
  /// delivers the message to the device without delay. Set high priority if the
  /// message is time-critical and requires the user's immediate interaction,
  /// but beware that setting your messages to high priority contributes more to
  /// battery drain compared with normal priority messages.
  core.String? priority;

  /// Package name of the application where the registration token must match in
  /// order to receive the message.
  core.String? restrictedPackageName;

  /// How long (in seconds) the message should be kept in FCM storage if the
  /// device is offline.
  ///
  /// The maximum time to live supported is 4 weeks, and the default value is 4
  /// weeks if not set. Set it to 0 if want to send the message immediately. In
  /// JSON format, the Duration type is encoded as a string rather than an
  /// object, where the string ends in the suffix "s" (indicating seconds) and
  /// is preceded by the number of seconds, with nanoseconds expressed as
  /// fractional seconds. For example, 3 seconds with 0 nanoseconds should be
  /// encoded in JSON format as "3s", while 3 seconds and 1 nanosecond should be
  /// expressed in JSON format as "3.000000001s". The ttl will be rounded down
  /// to the nearest second.
  core.String? ttl;

  AndroidConfig();

  AndroidConfig.fromJson(core.Map _json) {
    if (_json.containsKey('collapseKey')) {
      collapseKey = _json['collapseKey'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('directBootOk')) {
      directBootOk = _json['directBootOk'] as core.bool;
    }
    if (_json.containsKey('fcmOptions')) {
      fcmOptions = AndroidFcmOptions.fromJson(
          _json['fcmOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('notification')) {
      notification = AndroidNotification.fromJson(
          _json['notification'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.String;
    }
    if (_json.containsKey('restrictedPackageName')) {
      restrictedPackageName = _json['restrictedPackageName'] as core.String;
    }
    if (_json.containsKey('ttl')) {
      ttl = _json['ttl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (collapseKey != null) 'collapseKey': collapseKey!,
        if (data != null) 'data': data!,
        if (directBootOk != null) 'directBootOk': directBootOk!,
        if (fcmOptions != null) 'fcmOptions': fcmOptions!.toJson(),
        if (notification != null) 'notification': notification!.toJson(),
        if (priority != null) 'priority': priority!,
        if (restrictedPackageName != null)
          'restrictedPackageName': restrictedPackageName!,
        if (ttl != null) 'ttl': ttl!,
      };
}

/// Options for features provided by the FCM SDK for Android.
class AndroidFcmOptions {
  /// Label associated with the message's analytics data.
  core.String? analyticsLabel;

  AndroidFcmOptions();

  AndroidFcmOptions.fromJson(core.Map _json) {
    if (_json.containsKey('analyticsLabel')) {
      analyticsLabel = _json['analyticsLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analyticsLabel != null) 'analyticsLabel': analyticsLabel!,
      };
}

/// Notification to send to android devices.
class AndroidNotification {
  /// The notification's body text.
  ///
  /// If present, it will override google.firebase.fcm.v1.Notification.body.
  core.String? body;

  /// Variable string values to be used in place of the format specifiers in
  /// body_loc_key to use to localize the body text to the user's current
  /// localization.
  ///
  /// See [Formatting and Styling](https://goo.gl/MalYE3) for more information.
  core.List<core.String>? bodyLocArgs;

  /// The key to the body string in the app's string resources to use to
  /// localize the body text to the user's current localization.
  ///
  /// See [String Resources](https://goo.gl/NdFZGI) for more information.
  core.String? bodyLocKey;

  /// The
  /// [notification's channel id](https://developer.android.com/guide/topics/ui/notifiers/notifications#ManageChannels)
  /// (new in Android O).
  ///
  /// The app must create a channel with this channel ID before any notification
  /// with this channel ID is received. If you don't send this channel ID in the
  /// request, or if the channel ID provided has not yet been created by the
  /// app, FCM uses the channel ID specified in the app manifest.
  core.String? channelId;

  /// The action associated with a user click on the notification.
  ///
  /// If specified, an activity with a matching intent filter is launched when a
  /// user clicks on the notification.
  core.String? clickAction;

  /// The notification's icon color, expressed in #rrggbb format.
  core.String? color;

  /// If set to true, use the Android framework's default LED light settings for
  /// the notification.
  ///
  /// Default values are specified in
  /// [config.xml](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/config.xml).
  /// If `default_light_settings` is set to true and `light_settings` is also
  /// set, the user-specified `light_settings` is used instead of the default
  /// value.
  core.bool? defaultLightSettings;

  /// If set to true, use the Android framework's default sound for the
  /// notification.
  ///
  /// Default values are specified in
  /// [config.xml](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/config.xml).
  core.bool? defaultSound;

  /// If set to true, use the Android framework's default vibrate pattern for
  /// the notification.
  ///
  /// Default values are specified in
  /// [config.xml](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/config.xml).
  /// If `default_vibrate_timings` is set to true and `vibrate_timings` is also
  /// set, the default value is used instead of the user-specified
  /// `vibrate_timings`.
  core.bool? defaultVibrateTimings;

  /// Set the time that the event in the notification occurred.
  ///
  /// Notifications in the panel are sorted by this time. A point in time is
  /// represented using
  /// [protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/java/com/google/protobuf/Timestamp).
  core.String? eventTime;

  /// The notification's icon.
  ///
  /// Sets the notification icon to myicon for drawable resource myicon. If you
  /// don't send this key in the request, FCM displays the launcher icon
  /// specified in your app manifest.
  core.String? icon;

  /// Contains the URL of an image that is going to be displayed in a
  /// notification.
  ///
  /// If present, it will override google.firebase.fcm.v1.Notification.image.
  core.String? image;

  /// Settings to control the notification's LED blinking rate and color if LED
  /// is available on the device.
  ///
  /// The total blinking time is controlled by the OS.
  LightSettings? lightSettings;

  /// Set whether or not this notification is relevant only to the current
  /// device.
  ///
  /// Some notifications can be bridged to other devices for remote display,
  /// such as a Wear OS watch. This hint can be set to recommend this
  /// notification not be bridged. See
  /// [Wear OS guides](https://developer.android.com/training/wearables/notifications/bridger#existing-method-of-preventing-bridging)
  core.bool? localOnly;

  /// Sets the number of items this notification represents.
  ///
  /// May be displayed as a badge count for launchers that support badging.See
  /// [Notification Badge](https://developer.android.com/training/notify-user/badges).
  /// For example, this might be useful if you're using just one notification to
  /// represent multiple new messages but you want the count here to represent
  /// the number of total new messages. If zero or unspecified, systems that
  /// support badging use the default, which is to increment a number displayed
  /// on the long-press menu each time a new notification arrives.
  core.int? notificationCount;

  /// Set the relative priority for this notification.
  ///
  /// Priority is an indication of how much of the user's attention should be
  /// consumed by this notification. Low-priority notifications may be hidden
  /// from the user in certain situations, while the user might be interrupted
  /// for a higher-priority notification. The effect of setting the same
  /// priorities may differ slightly on different platforms. Note this priority
  /// differs from `AndroidMessagePriority`. This priority is processed by the
  /// client after the message has been delivered, whereas
  /// [AndroidMessagePriority](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#androidmessagepriority)
  /// is an FCM concept that controls when the message is delivered.
  /// Possible string values are:
  /// - "PRIORITY_UNSPECIFIED" : If priority is unspecified, notification
  /// priority is set to `PRIORITY_DEFAULT`.
  /// - "PRIORITY_MIN" : Lowest notification priority. Notifications with this
  /// `PRIORITY_MIN` might not be shown to the user except under special
  /// circumstances, such as detailed notification logs.
  /// - "PRIORITY_LOW" : Lower notification priority. The UI may choose to show
  /// the notifications smaller, or at a different position in the list,
  /// compared with notifications with `PRIORITY_DEFAULT`.
  /// - "PRIORITY_DEFAULT" : Default notification priority. If the application
  /// does not prioritize its own notifications, use this value for all
  /// notifications.
  /// - "PRIORITY_HIGH" : Higher notification priority. Use this for more
  /// important notifications or alerts. The UI may choose to show these
  /// notifications larger, or at a different position in the notification
  /// lists, compared with notifications with `PRIORITY_DEFAULT`.
  /// - "PRIORITY_MAX" : Highest notification priority. Use this for the
  /// application's most important items that require the user's prompt
  /// attention or input.
  core.String? notificationPriority;

  /// The sound to play when the device receives the notification.
  ///
  /// Supports "default" or the filename of a sound resource bundled in the app.
  /// Sound files must reside in /res/raw/.
  core.String? sound;

  /// When set to false or unset, the notification is automatically dismissed
  /// when the user clicks it in the panel.
  ///
  /// When set to true, the notification persists even when the user clicks it.
  core.bool? sticky;

  /// Identifier used to replace existing notifications in the notification
  /// drawer.
  ///
  /// If not specified, each request creates a new notification. If specified
  /// and a notification with the same tag is already being shown, the new
  /// notification replaces the existing one in the notification drawer.
  core.String? tag;

  /// Sets the "ticker" text, which is sent to accessibility services.
  ///
  /// Prior to API level 21 (`Lollipop`), sets the text that is displayed in the
  /// status bar when the notification first arrives.
  core.String? ticker;

  /// The notification's title.
  ///
  /// If present, it will override google.firebase.fcm.v1.Notification.title.
  core.String? title;

  /// Variable string values to be used in place of the format specifiers in
  /// title_loc_key to use to localize the title text to the user's current
  /// localization.
  ///
  /// See [Formatting and Styling](https://goo.gl/MalYE3) for more information.
  core.List<core.String>? titleLocArgs;

  /// The key to the title string in the app's string resources to use to
  /// localize the title text to the user's current localization.
  ///
  /// See [String Resources](https://goo.gl/NdFZGI) for more information.
  core.String? titleLocKey;

  /// Set the vibration pattern to use.
  ///
  /// Pass in an array of
  /// [protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)
  /// to turn on or off the vibrator. The first value indicates the `Duration`
  /// to wait before turning the vibrator on. The next value indicates the
  /// `Duration` to keep the vibrator on. Subsequent values alternate between
  /// `Duration` to turn the vibrator off and to turn the vibrator on. If
  /// `vibrate_timings` is set and `default_vibrate_timings` is set to `true`,
  /// the default value is used instead of the user-specified `vibrate_timings`.
  core.List<core.String>? vibrateTimings;

  /// Set the
  /// [Notification.visibility](https://developer.android.com/reference/android/app/Notification.html#visibility)
  /// of the notification.
  /// Possible string values are:
  /// - "VISIBILITY_UNSPECIFIED" : If unspecified, default to
  /// `Visibility.PRIVATE`.
  /// - "PRIVATE" : Show this notification on all lockscreens, but conceal
  /// sensitive or private information on secure lockscreens.
  /// - "PUBLIC" : Show this notification in its entirety on all lockscreens.
  /// - "SECRET" : Do not reveal any part of this notification on a secure
  /// lockscreen.
  core.String? visibility;

  AndroidNotification();

  AndroidNotification.fromJson(core.Map _json) {
    if (_json.containsKey('body')) {
      body = _json['body'] as core.String;
    }
    if (_json.containsKey('bodyLocArgs')) {
      bodyLocArgs = (_json['bodyLocArgs'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('bodyLocKey')) {
      bodyLocKey = _json['bodyLocKey'] as core.String;
    }
    if (_json.containsKey('channelId')) {
      channelId = _json['channelId'] as core.String;
    }
    if (_json.containsKey('clickAction')) {
      clickAction = _json['clickAction'] as core.String;
    }
    if (_json.containsKey('color')) {
      color = _json['color'] as core.String;
    }
    if (_json.containsKey('defaultLightSettings')) {
      defaultLightSettings = _json['defaultLightSettings'] as core.bool;
    }
    if (_json.containsKey('defaultSound')) {
      defaultSound = _json['defaultSound'] as core.bool;
    }
    if (_json.containsKey('defaultVibrateTimings')) {
      defaultVibrateTimings = _json['defaultVibrateTimings'] as core.bool;
    }
    if (_json.containsKey('eventTime')) {
      eventTime = _json['eventTime'] as core.String;
    }
    if (_json.containsKey('icon')) {
      icon = _json['icon'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = _json['image'] as core.String;
    }
    if (_json.containsKey('lightSettings')) {
      lightSettings = LightSettings.fromJson(
          _json['lightSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('localOnly')) {
      localOnly = _json['localOnly'] as core.bool;
    }
    if (_json.containsKey('notificationCount')) {
      notificationCount = _json['notificationCount'] as core.int;
    }
    if (_json.containsKey('notificationPriority')) {
      notificationPriority = _json['notificationPriority'] as core.String;
    }
    if (_json.containsKey('sound')) {
      sound = _json['sound'] as core.String;
    }
    if (_json.containsKey('sticky')) {
      sticky = _json['sticky'] as core.bool;
    }
    if (_json.containsKey('tag')) {
      tag = _json['tag'] as core.String;
    }
    if (_json.containsKey('ticker')) {
      ticker = _json['ticker'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('titleLocArgs')) {
      titleLocArgs = (_json['titleLocArgs'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('titleLocKey')) {
      titleLocKey = _json['titleLocKey'] as core.String;
    }
    if (_json.containsKey('vibrateTimings')) {
      vibrateTimings = (_json['vibrateTimings'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('visibility')) {
      visibility = _json['visibility'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (body != null) 'body': body!,
        if (bodyLocArgs != null) 'bodyLocArgs': bodyLocArgs!,
        if (bodyLocKey != null) 'bodyLocKey': bodyLocKey!,
        if (channelId != null) 'channelId': channelId!,
        if (clickAction != null) 'clickAction': clickAction!,
        if (color != null) 'color': color!,
        if (defaultLightSettings != null)
          'defaultLightSettings': defaultLightSettings!,
        if (defaultSound != null) 'defaultSound': defaultSound!,
        if (defaultVibrateTimings != null)
          'defaultVibrateTimings': defaultVibrateTimings!,
        if (eventTime != null) 'eventTime': eventTime!,
        if (icon != null) 'icon': icon!,
        if (image != null) 'image': image!,
        if (lightSettings != null) 'lightSettings': lightSettings!.toJson(),
        if (localOnly != null) 'localOnly': localOnly!,
        if (notificationCount != null) 'notificationCount': notificationCount!,
        if (notificationPriority != null)
          'notificationPriority': notificationPriority!,
        if (sound != null) 'sound': sound!,
        if (sticky != null) 'sticky': sticky!,
        if (tag != null) 'tag': tag!,
        if (ticker != null) 'ticker': ticker!,
        if (title != null) 'title': title!,
        if (titleLocArgs != null) 'titleLocArgs': titleLocArgs!,
        if (titleLocKey != null) 'titleLocKey': titleLocKey!,
        if (vibrateTimings != null) 'vibrateTimings': vibrateTimings!,
        if (visibility != null) 'visibility': visibility!,
      };
}

/// [Apple Push Notification Service](https://goo.gl/MXRTPa) specific options.
class ApnsConfig {
  /// Options for features provided by the FCM SDK for iOS.
  ApnsFcmOptions? fcmOptions;

  /// HTTP request headers defined in Apple Push Notification Service.
  ///
  /// Refer to
  /// [APNs request headers](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)
  /// for supported headers, e.g. "apns-priority": "10".
  core.Map<core.String, core.String>? headers;

  /// APNs payload as a JSON object, including both `aps` dictionary and custom
  /// payload.
  ///
  /// See
  /// [Payload Key Reference](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification).
  /// If present, it overrides google.firebase.fcm.v1.Notification.title and
  /// google.firebase.fcm.v1.Notification.body.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  ApnsConfig();

  ApnsConfig.fromJson(core.Map _json) {
    if (_json.containsKey('fcmOptions')) {
      fcmOptions = ApnsFcmOptions.fromJson(
          _json['fcmOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('headers')) {
      headers = (_json['headers'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fcmOptions != null) 'fcmOptions': fcmOptions!.toJson(),
        if (headers != null) 'headers': headers!,
        if (payload != null) 'payload': payload!,
      };
}

/// Options for features provided by the FCM SDK for iOS.
class ApnsFcmOptions {
  /// Label associated with the message's analytics data.
  core.String? analyticsLabel;

  /// Contains the URL of an image that is going to be displayed in a
  /// notification.
  ///
  /// If present, it will override google.firebase.fcm.v1.Notification.image.
  core.String? image;

  ApnsFcmOptions();

  ApnsFcmOptions.fromJson(core.Map _json) {
    if (_json.containsKey('analyticsLabel')) {
      analyticsLabel = _json['analyticsLabel'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = _json['image'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analyticsLabel != null) 'analyticsLabel': analyticsLabel!,
        if (image != null) 'image': image!,
      };
}

/// Represents a color in the RGBA color space.
///
/// This representation is designed for simplicity of conversion to/from color
/// representations in various languages over compactness. For example, the
/// fields of this representation can be trivially provided to the constructor
/// of `java.awt.Color` in Java; it can also be trivially provided to UIColor's
/// `+colorWithRed:green:blue:alpha` method in iOS; and, with just a little
/// work, it can be easily formatted into a CSS `rgba()` string in JavaScript.
/// This reference page doesn't carry information about the absolute color space
/// that should be used to interpret the RGB value (e.g. sRGB, Adobe RGB,
/// DCI-P3, BT.2020, etc.). By default, applications should assume the sRGB
/// color space. When color equality needs to be decided, implementations,
/// unless documented otherwise, treat two colors as equal if all their red,
/// green, blue, and alpha values each differ by at most 1e-5. Example (Java):
/// import com.google.type.Color; // ... public static java.awt.Color
/// fromProto(Color protocolor) { float alpha = protocolor.hasAlpha() ?
/// protocolor.getAlpha().getValue() : 1.0; return new java.awt.Color(
/// protocolor.getRed(), protocolor.getGreen(), protocolor.getBlue(), alpha); }
/// public static Color toProto(java.awt.Color color) { float red = (float)
/// color.getRed(); float green = (float) color.getGreen(); float blue = (float)
/// color.getBlue(); float denominator = 255.0; Color.Builder resultBuilder =
/// Color .newBuilder() .setRed(red / denominator) .setGreen(green /
/// denominator) .setBlue(blue / denominator); int alpha = color.getAlpha(); if
/// (alpha != 255) { result.setAlpha( FloatValue .newBuilder()
/// .setValue(((float) alpha) / denominator) .build()); } return
/// resultBuilder.build(); } // ... Example (iOS / Obj-C): // ... static
/// UIColor* fromProto(Color* protocolor) { float red = \[protocolor red\];
/// float green = \[protocolor green\]; float blue = \[protocolor blue\];
/// FloatValue* alpha_wrapper = \[protocolor alpha\]; float alpha = 1.0; if
/// (alpha_wrapper != nil) { alpha = \[alpha_wrapper value\]; } return \[UIColor
/// colorWithRed:red green:green blue:blue alpha:alpha\]; } static Color*
/// toProto(UIColor* color) { CGFloat red, green, blue, alpha; if (!\[color
/// getRed:&red green:&green blue:&blue alpha:&alpha\]) { return nil; } Color*
/// result = \[\[Color alloc\] init\]; \[result setRed:red\]; \[result
/// setGreen:green\]; \[result setBlue:blue\]; if (alpha <= 0.9999) { \[result
/// setAlpha:floatWrapperWithValue(alpha)\]; } \[result autorelease\]; return
/// result; } // ... Example (JavaScript): // ... var protoToCssColor =
/// function(rgb_color) { var redFrac = rgb_color.red || 0.0; var greenFrac =
/// rgb_color.green || 0.0; var blueFrac = rgb_color.blue || 0.0; var red =
/// Math.floor(redFrac * 255); var green = Math.floor(greenFrac * 255); var blue
/// = Math.floor(blueFrac * 255); if (!('alpha' in rgb_color)) { return
/// rgbToCssColor(red, green, blue); } var alphaFrac = rgb_color.alpha.value ||
/// 0.0; var rgbParams = \[red, green, blue\].join(','); return \['rgba(',
/// rgbParams, ',', alphaFrac, ')'\].join(''); }; var rgbToCssColor =
/// function(red, green, blue) { var rgbNumber = new Number((red << 16) | (green
/// << 8) | blue); var hexString = rgbNumber.toString(16); var missingZeros = 6
/// - hexString.length; var resultBuilder = \['#'\]; for (var i = 0; i <
/// missingZeros; i++) { resultBuilder.push('0'); }
/// resultBuilder.push(hexString); return resultBuilder.join(''); }; // ...
class Color {
  /// The fraction of this color that should be applied to the pixel.
  ///
  /// That is, the final pixel color is defined by the equation: `pixel color =
  /// alpha * (this color) + (1.0 - alpha) * (background color)` This means that
  /// a value of 1.0 corresponds to a solid color, whereas a value of 0.0
  /// corresponds to a completely transparent color. This uses a wrapper message
  /// rather than a simple float scalar so that it is possible to distinguish
  /// between a default value and the value being unset. If omitted, this color
  /// object is rendered as a solid color (as if the alpha value had been
  /// explicitly given a value of 1.0).
  core.double? alpha;

  /// The amount of blue in the color as a value in the interval \[0, 1\].
  core.double? blue;

  /// The amount of green in the color as a value in the interval \[0, 1\].
  core.double? green;

  /// The amount of red in the color as a value in the interval \[0, 1\].
  core.double? red;

  Color();

  Color.fromJson(core.Map _json) {
    if (_json.containsKey('alpha')) {
      alpha = (_json['alpha'] as core.num).toDouble();
    }
    if (_json.containsKey('blue')) {
      blue = (_json['blue'] as core.num).toDouble();
    }
    if (_json.containsKey('green')) {
      green = (_json['green'] as core.num).toDouble();
    }
    if (_json.containsKey('red')) {
      red = (_json['red'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alpha != null) 'alpha': alpha!,
        if (blue != null) 'blue': blue!,
        if (green != null) 'green': green!,
        if (red != null) 'red': red!,
      };
}

/// Platform independent options for features provided by the FCM SDKs.
class FcmOptions {
  /// Label associated with the message's analytics data.
  core.String? analyticsLabel;

  FcmOptions();

  FcmOptions.fromJson(core.Map _json) {
    if (_json.containsKey('analyticsLabel')) {
      analyticsLabel = _json['analyticsLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analyticsLabel != null) 'analyticsLabel': analyticsLabel!,
      };
}

/// Settings to control notification LED.
class LightSettings {
  /// Set `color` of the LED with
  /// [google.type.Color](https://github.com/googleapis/googleapis/blob/master/google/type/color.proto).
  ///
  /// Required.
  Color? color;

  /// Along with `light_on_duration `, define the blink rate of LED flashes.
  ///
  /// Resolution defined by
  /// [proto.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)
  ///
  /// Required.
  core.String? lightOffDuration;

  /// Along with `light_off_duration`, define the blink rate of LED flashes.
  ///
  /// Resolution defined by
  /// [proto.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)
  ///
  /// Required.
  core.String? lightOnDuration;

  LightSettings();

  LightSettings.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color =
          Color.fromJson(_json['color'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lightOffDuration')) {
      lightOffDuration = _json['lightOffDuration'] as core.String;
    }
    if (_json.containsKey('lightOnDuration')) {
      lightOnDuration = _json['lightOnDuration'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!.toJson(),
        if (lightOffDuration != null) 'lightOffDuration': lightOffDuration!,
        if (lightOnDuration != null) 'lightOnDuration': lightOnDuration!,
      };
}

/// Message to send by Firebase Cloud Messaging Service.
class Message {
  /// Input only.
  ///
  /// Android specific options for messages sent through
  /// [FCM connection server](https://goo.gl/4GLdUl).
  AndroidConfig? android;

  /// Input only.
  ///
  /// [Apple Push Notification Service](https://goo.gl/MXRTPa) specific options.
  ApnsConfig? apns;

  /// Condition to send a message to, e.g. "'foo' in topics && 'bar' in topics".
  core.String? condition;

  /// Input only.
  ///
  /// Arbitrary key/value payload. The key should not be a reserved word
  /// ("from", "message_type", or any word starting with "google" or "gcm").
  core.Map<core.String, core.String>? data;

  /// Input only.
  ///
  /// Template for FCM SDK feature options to use across all platforms.
  FcmOptions? fcmOptions;

  /// The identifier of the message sent, in the format of `projects / *
  /// /messages/{message_id}`.
  ///
  /// Output only.
  core.String? name;

  /// Input only.
  ///
  /// Basic notification template to use across all platforms.
  Notification? notification;

  /// Registration token to send a message to.
  core.String? token;

  /// Topic name to send a message to, e.g. "weather".
  ///
  /// Note: "/topics/" prefix should not be provided.
  core.String? topic;

  /// Input only.
  ///
  /// [Webpush protocol](https://tools.ietf.org/html/rfc8030) options.
  WebpushConfig? webpush;

  Message();

  Message.fromJson(core.Map _json) {
    if (_json.containsKey('android')) {
      android = AndroidConfig.fromJson(
          _json['android'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('apns')) {
      apns = ApnsConfig.fromJson(
          _json['apns'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('fcmOptions')) {
      fcmOptions = FcmOptions.fromJson(
          _json['fcmOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notification')) {
      notification = Notification.fromJson(
          _json['notification'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
    if (_json.containsKey('webpush')) {
      webpush = WebpushConfig.fromJson(
          _json['webpush'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (android != null) 'android': android!.toJson(),
        if (apns != null) 'apns': apns!.toJson(),
        if (condition != null) 'condition': condition!,
        if (data != null) 'data': data!,
        if (fcmOptions != null) 'fcmOptions': fcmOptions!.toJson(),
        if (name != null) 'name': name!,
        if (notification != null) 'notification': notification!.toJson(),
        if (token != null) 'token': token!,
        if (topic != null) 'topic': topic!,
        if (webpush != null) 'webpush': webpush!.toJson(),
      };
}

/// Basic notification template to use across all platforms.
class Notification {
  /// The notification's body text.
  core.String? body;

  /// Contains the URL of an image that is going to be downloaded on the device
  /// and displayed in a notification.
  ///
  /// JPEG, PNG, BMP have full support across platforms. Animated GIF and video
  /// only work on iOS. WebP and HEIF have varying levels of support across
  /// platforms and platform versions. Android has 1MB image size limit. Quota
  /// usage and implications/costs for hosting image on Firebase Storage:
  /// https://firebase.google.com/pricing
  core.String? image;

  /// The notification's title.
  core.String? title;

  Notification();

  Notification.fromJson(core.Map _json) {
    if (_json.containsKey('body')) {
      body = _json['body'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = _json['image'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (body != null) 'body': body!,
        if (image != null) 'image': image!,
        if (title != null) 'title': title!,
      };
}

/// Request to send a message to specified target.
class SendMessageRequest {
  /// Message to send.
  ///
  /// Required.
  Message? message;

  /// Flag for testing the request without actually delivering the message.
  core.bool? validateOnly;

  SendMessageRequest();

  SendMessageRequest.fromJson(core.Map _json) {
    if (_json.containsKey('message')) {
      message = Message.fromJson(
          _json['message'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('validateOnly')) {
      validateOnly = _json['validateOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (message != null) 'message': message!.toJson(),
        if (validateOnly != null) 'validateOnly': validateOnly!,
      };
}

/// [Webpush protocol](https://tools.ietf.org/html/rfc8030) options.
class WebpushConfig {
  /// Arbitrary key/value payload.
  ///
  /// If present, it will override google.firebase.fcm.v1.Message.data.
  core.Map<core.String, core.String>? data;

  /// Options for features provided by the FCM SDK for Web.
  WebpushFcmOptions? fcmOptions;

  /// HTTP headers defined in webpush protocol.
  ///
  /// Refer to [Webpush protocol](https://tools.ietf.org/html/rfc8030#section-5)
  /// for supported headers, e.g. "TTL": "15".
  core.Map<core.String, core.String>? headers;

  /// Web Notification options as a JSON object.
  ///
  /// Supports Notification instance properties as defined in
  /// [Web Notification API](https://developer.mozilla.org/en-US/docs/Web/API/Notification).
  /// If present, "title" and "body" fields override
  /// \[google.firebase.fcm.v1.Notification.title\] and
  /// \[google.firebase.fcm.v1.Notification.body\].
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? notification;

  WebpushConfig();

  WebpushConfig.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('fcmOptions')) {
      fcmOptions = WebpushFcmOptions.fromJson(
          _json['fcmOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('headers')) {
      headers = (_json['headers'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('notification')) {
      notification =
          (_json['notification'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!,
        if (fcmOptions != null) 'fcmOptions': fcmOptions!.toJson(),
        if (headers != null) 'headers': headers!,
        if (notification != null) 'notification': notification!,
      };
}

/// Options for features provided by the FCM SDK for Web.
class WebpushFcmOptions {
  /// Label associated with the message's analytics data.
  core.String? analyticsLabel;

  /// The link to open when the user clicks on the notification.
  ///
  /// For all URL values, HTTPS is required.
  core.String? link;

  WebpushFcmOptions();

  WebpushFcmOptions.fromJson(core.Map _json) {
    if (_json.containsKey('analyticsLabel')) {
      analyticsLabel = _json['analyticsLabel'] as core.String;
    }
    if (_json.containsKey('link')) {
      link = _json['link'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analyticsLabel != null) 'analyticsLabel': analyticsLabel!,
        if (link != null) 'link': link!,
      };
}
