// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.pubsub;

class _PubSubImpl implements PubSub {
  @override
  final String project;
  final pubsub.PubsubApi _api;
  final String _topicPrefix;
  final String _subscriptionPrefix;

  _PubSubImpl(http.Client client, this.project)
      : _api = pubsub.PubsubApi(client),
        _topicPrefix = 'projects/$project/topics/',
        _subscriptionPrefix = 'projects/$project/subscriptions/';

  _PubSubImpl.rootUrl(http.Client client, this.project, String rootUrl)
      : _api = pubsub.PubsubApi(client, rootUrl: rootUrl),
        _topicPrefix = 'projects/$project/topics/',
        _subscriptionPrefix = 'projects/$project/subscriptions/';

  String _fullTopicName(String name) {
    return name.startsWith('projects/') ? name : '$_topicPrefix$name';
  }

  String _fullSubscriptionName(String name) {
    return name.startsWith('projects/') ? name : '$_subscriptionPrefix$name';
  }

  Future<pubsub.Topic> _createTopic(String name) {
    return _api.projects.topics.create(pubsub.Topic(), name);
  }

  Future _deleteTopic(String name) {
    // The Pub/Sub delete API returns an instance of Empty.
    return _api.projects.topics.delete(name).then((_) => null);
  }

  Future<pubsub.Topic> _getTopic(String name) {
    return _api.projects.topics.get(name);
  }

  Future<pubsub.ListTopicsResponse> _listTopics(
      int pageSize, String? nextPageToken) {
    return _api.projects.topics.list('projects/$project',
        pageSize: pageSize, pageToken: nextPageToken);
  }

  Future<pubsub.Subscription> _createSubscription(
      String name, String topic, Uri? endpoint) {
    var subscription = pubsub.Subscription()..topic = topic;
    if (endpoint != null) {
      var pushConfig = pubsub.PushConfig()..pushEndpoint = endpoint.toString();
      subscription.pushConfig = pushConfig;
    }
    return _api.projects.subscriptions.create(subscription, name);
  }

  Future _deleteSubscription(String name) {
    // The Pub/Sub delete API returns an instance of Empty.
    return _api.projects.subscriptions
        .delete(_fullSubscriptionName(name))
        .then((_) => null);
  }

  Future<pubsub.Subscription> _getSubscription(String name) {
    return _api.projects.subscriptions.get(name);
  }

  Future<pubsub.ListSubscriptionsResponse> _listSubscriptions(
      String? topic, int pageSize, String? nextPageToken) {
    return _api.projects.subscriptions.list('projects/$project',
        pageSize: pageSize, pageToken: nextPageToken);
  }

  Future _modifyPushConfig(String subscription, Uri? endpoint) {
    var pushConfig = pubsub.PushConfig()..pushEndpoint = endpoint?.toString();
    var request = pubsub.ModifyPushConfigRequest()..pushConfig = pushConfig;
    return _api.projects.subscriptions.modifyPushConfig(request, subscription);
  }

  Future _publish(
      String topic, List<int> message, Map<String, String> attributes) {
    var request = pubsub.PublishRequest()
      ..messages = [
        (pubsub.PubsubMessage()
          ..dataAsBytes = message
          ..attributes = attributes.isEmpty ? null : attributes)
      ];
    // TODO(sgjesse): Handle PublishResponse containing message ids.
    return _api.projects.topics.publish(request, topic).then((_) => null);
  }

  Future<pubsub.PullResponse> _pull(
      String subscription, bool returnImmediately) {
    var request = pubsub.PullRequest()
      ..maxMessages = 1
      ..returnImmediately = returnImmediately;
    return _api.projects.subscriptions.pull(request, subscription);
  }

  Future _ack(String ackId, String subscription) {
    var request = pubsub.AcknowledgeRequest()..ackIds = [ackId];
    // The Pub/Sub acknowledge API returns an instance of Empty.
    return _api.projects.subscriptions
        .acknowledge(request, subscription)
        .then((_) => null);
  }

  void _checkTopicName(String name) {
    if (name.startsWith('projects/') && !name.contains('/topics/')) {
      throw ArgumentError(
          'Illegal topic name. Absolute topic names must have the form '
          "'projects/[project-id]/topics/[topic-name]");
    }
    if (name.endsWith('/topics/')) {
      throw ArgumentError(
          'Illegal topic name. Relative part of the name cannot be empty');
    }
  }

  void _checkSubscriptionName(String name) {
    if (name.startsWith('projects/') && !name.contains('/subscriptions/')) {
      throw ArgumentError(
          'Illegal subscription name. Absolute subscription names must have '
          "the form 'projects/[project-id]/subscriptions/[subscription-name]");
    }
    if (name.endsWith('/subscriptions/')) {
      throw ArgumentError(
          'Illegal subscription name. Relative part of the name cannot be '
          'empty');
    }
  }

  @override
  Future<Topic> createTopic(String name) {
    _checkTopicName(name);
    return _createTopic(_fullTopicName(name))
        .then((top) => _TopicImpl(this, top));
  }

  @override
  Future deleteTopic(String name) {
    _checkTopicName(name);
    return _deleteTopic(_fullTopicName(name));
  }

  @override
  Future<Topic> lookupTopic(String name) {
    _checkTopicName(name);
    return _getTopic(_fullTopicName(name)).then((top) => _TopicImpl(this, top));
  }

  @override
  Stream<Topic> listTopics() {
    Future<Page<Topic>> firstPage(int pageSize) {
      return _listTopics(pageSize, null)
          .then((response) => _TopicPageImpl(this, pageSize, response));
    }

    return StreamFromPages<Topic>(firstPage).stream;
  }

  @override
  Future<Page<Topic>> pageTopics({int pageSize = 50}) {
    return _listTopics(pageSize, null).then((response) {
      return _TopicPageImpl(this, pageSize, response);
    });
  }

  @override
  Future<Subscription> createSubscription(String name, String topic,
      {Uri? endpoint}) {
    _checkSubscriptionName(name);
    _checkTopicName(topic);
    return _createSubscription(
            _fullSubscriptionName(name), _fullTopicName(topic), endpoint)
        .then((sub) => _SubscriptionImpl(this, sub));
  }

  @override
  Future deleteSubscription(String name) {
    _checkSubscriptionName(name);
    return _deleteSubscription(_fullSubscriptionName(name));
  }

  @override
  Future<Subscription> lookupSubscription(String name) {
    _checkSubscriptionName(name);
    return _getSubscription(_fullSubscriptionName(name))
        .then((sub) => _SubscriptionImpl(this, sub));
  }

  @override
  Stream<Subscription> listSubscriptions([String? query]) {
    Future<Page<Subscription>> firstPage(int pageSize) {
      return _listSubscriptions(query, pageSize, null).then(
          (response) => _SubscriptionPageImpl(this, query, pageSize, response));
    }

    return StreamFromPages<Subscription>(firstPage).stream;
  }

  @override
  Future<Page<Subscription>> pageSubscriptions(
      {String? topic, int pageSize = 50}) {
    return _listSubscriptions(topic, pageSize, null).then((response) {
      return _SubscriptionPageImpl(this, topic, pageSize, response);
    });
  }
}

/// Message class for messages constructed through 'new Message()'. It stores
/// the user supplied body as either String or bytes.
class _MessageImpl implements Message {
  // The message body, if it is a `String`. In that case, [bytesMessage] is
  // null.
  final String? _stringMessage;

  // The message body, if it is a byte list. In that case, [stringMessage] is
  // null.
  final List<int>? _bytesMessage;

  @override
  final Map<String, String> attributes;

  _MessageImpl.withString(
    this._stringMessage, {
    Map<String, String>? attributes,
  })  : _bytesMessage = null,
        attributes = attributes ?? <String, String>{};

  _MessageImpl.withBytes(this._bytesMessage, {Map<String, String>? attributes})
      : _stringMessage = null,
        attributes = attributes ?? <String, String>{};

  @override
  List<int> get asBytes => _bytesMessage ?? utf8.encode(_stringMessage!);

  @override
  String get asString => _stringMessage ?? utf8.decode(_bytesMessage!);
}

/// Message received using [Subscription.pull].
///
/// Contains the [pubsub.PubsubMessage] received from Pub/Sub, and
/// makes the message body and labels available on request.
///
/// The labels map is lazily created when first accessed.
class _PullMessage implements Message {
  final pubsub.PubsubMessage _message;
  List<int>? _bytes;
  String? _string;

  _PullMessage(this._message);

  @override
  List<int> get asBytes {
    _bytes ??= _message.dataAsBytes;
    return _bytes!;
  }

  @override
  String get asString {
    _string ??= utf8.decode(_message.dataAsBytes);
    return _string!;
  }

  @override
  Map<String, String> get attributes =>
      _message.attributes ?? <String, String>{};
}

/// Message received through Pub/Sub push delivery.
///
/// Stores the message body received from Pub/Sub as the Base64 encoded string
/// from the wire protocol.
///
/// The labels have been decoded into a Map.
class _PushMessage implements Message {
  final String _base64Message;
  @override
  final Map<String, String> attributes;

  _PushMessage(this._base64Message, this.attributes);

  @override
  List<int> get asBytes => base64.decode(_base64Message);

  @override
  String get asString => utf8.decode(asBytes);
}

/// Pull event received from Pub/Sub pull delivery.
///
/// Stores the pull response received from Pub/Sub.
class _PullEventImpl implements PullEvent {
  /// Pub/Sub API object.
  final _PubSubImpl _api;

  /// Subscription this was received from.
  final String _subscriptionName;

  /// Low level response received from Pub/Sub.
  final pubsub.PullResponse _response;
  @override
  final Message message;

  _PullEventImpl(
      this._api, this._subscriptionName, pubsub.PullResponse response)
      : _response = response,
        message = _PullMessage(response.receivedMessages![0].message!);

  @override
  Future acknowledge() {
    return _api._ack(_response.receivedMessages![0].ackId!, _subscriptionName);
  }
}

/// Push event received from Pub/Sub push delivery.
///
/// decoded from JSON encoded push HTTP request body.
class _PushEventImpl implements PushEvent {
  static const _prefix = '/subscriptions/';
  final Message _message;
  final String _subscriptionName;

  @override
  Message get message => _message;

  @override
  String get subscriptionName => _subscriptionName;

  _PushEventImpl(this._message, this._subscriptionName);

  factory _PushEventImpl.fromJson(String json) {
    Map body = jsonDecode(json) as Map<String, dynamic>;
    var data = body['message']['data'] as String;
    Map<String, String> labels = HashMap();
    body['message']['labels'].forEach((label) {
      var key = label['key'] as String;
      var value = label['strValue'];
      value ??= label['numValue'];
      labels[key] = value.toString();
    });
    var subscription = body['subscription'] as String;
    // TODO(#1): Remove this when the push event subscription name is prefixed
    // with '/subscriptions/'.
    if (!subscription.startsWith(_prefix)) {
      subscription = _prefix + subscription;
    }
    return _PushEventImpl(_PushMessage(data, labels), subscription);
  }
}

class _TopicImpl implements Topic {
  final _PubSubImpl _api;
  final pubsub.Topic _topic;

  _TopicImpl(this._api, this._topic);

  @override
  String get name {
    assert(_topic.name!.startsWith(_api._topicPrefix));
    return _topic.name!.substring(_api._topicPrefix.length);
  }

  @override
  String get project {
    assert(_topic.name!.startsWith(_api._topicPrefix));
    return _api.project;
  }

  @override
  String get absoluteName => _topic.name!;

  @override
  Future publish(Message message) {
    return _api._publish(_topic.name!, message.asBytes, message.attributes);
  }

  @override
  Future delete() => _api._deleteTopic(_topic.name!);

  @override
  Future publishString(String message, {Map<String, String>? attributes}) {
    attributes ??= <String, String>{};
    return _api._publish(_topic.name!, utf8.encode(message), attributes);
  }

  @override
  Future publishBytes(List<int> message, {Map<String, String>? attributes}) {
    attributes ??= <String, String>{};
    return _api._publish(_topic.name!, message, attributes);
  }
}

class _SubscriptionImpl implements Subscription {
  final _PubSubImpl _api;
  final pubsub.Subscription _subscription;

  _SubscriptionImpl(this._api, this._subscription);

  @override
  String get name {
    assert(_subscription.name!.startsWith(_api._subscriptionPrefix));
    return _subscription.name!.substring(_api._subscriptionPrefix.length);
  }

  @override
  String get project {
    assert(_subscription.name!.startsWith(_api._subscriptionPrefix));
    return _api.project;
  }

  @override
  String get absoluteName => _subscription.name!;

  @override
  Topic get topic {
    var topic = pubsub.Topic()..name = _subscription.topic;
    return _TopicImpl(_api, topic);
  }

  @override
  Future delete() => _api._deleteSubscription(_subscription.name!);

  @override
  Future<PullEvent?> pull({bool wait = true}) {
    return _api._pull(_subscription.name!, !wait).then((response) {
      // The documentation says 'Returns an empty list if there are no
      // messages available in the backlog'. However the receivedMessages
      // property can also be null in that case.
      if (response.receivedMessages == null ||
          response.receivedMessages!.isEmpty) {
        return null;
      }
      return _PullEventImpl(_api, _subscription.name!, response);
    }).catchError((e) => null,
        test: (e) => e is pubsub.DetailedApiRequestError && e.status == 400);
  }

  @override
  Uri? get endpoint => null;

  @override
  bool get isPull => endpoint == null;

  @override
  bool get isPush => endpoint != null;

  @override
  Future updatePushConfiguration(Uri endpoint) {
    return _api._modifyPushConfig(_subscription.name!, endpoint);
  }
}

class _TopicPageImpl implements Page<Topic> {
  final _PubSubImpl _api;
  final int _pageSize;
  final String? _nextPageToken;
  @override
  final List<Topic> items = [];

  _TopicPageImpl(this._api, this._pageSize, pubsub.ListTopicsResponse response)
      : _nextPageToken = response.nextPageToken {
    final topics = response.topics;
    if (topics != null) {
      items.addAll(topics.map((t) => _TopicImpl(_api, t)));
    }
  }

  @override
  bool get isLast => _nextPageToken == null;

  @override
  Future<Page<Topic>> next({int? pageSize}) async {
    throwIfIsLast();
    final pageSize_ = pageSize ?? _pageSize;

    return _api._listTopics(pageSize_, _nextPageToken).then((response) {
      return _TopicPageImpl(_api, pageSize_, response);
    });
  }
}

class _SubscriptionPageImpl implements Page<Subscription> {
  final _PubSubImpl _api;
  final String? _topic;
  final int _pageSize;
  final String? _nextPageToken;
  @override
  final List<Subscription> items = [];

  _SubscriptionPageImpl(this._api, this._topic, this._pageSize,
      pubsub.ListSubscriptionsResponse response)
      : _nextPageToken = response.nextPageToken {
    final subscriptions = response.subscriptions;
    if (subscriptions != null) {
      items.addAll(subscriptions.map((s) => _SubscriptionImpl(_api, s)));
    }
  }

  @override
  bool get isLast => _nextPageToken == null;

  @override
  Future<Page<Subscription>> next({int? pageSize}) {
    throwIfIsLast();
    final pageSize_ = pageSize ?? _pageSize;

    return _api
        ._listSubscriptions(_topic, pageSize_, _nextPageToken)
        .then((response) {
      return _SubscriptionPageImpl(_api, _topic, pageSize_, response);
    });
  }
}
