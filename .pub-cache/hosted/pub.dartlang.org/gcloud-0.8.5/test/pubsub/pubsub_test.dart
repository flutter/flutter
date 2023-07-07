// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:gcloud/pubsub.dart';
import 'package:googleapis/pubsub/v1.dart' as pubsub;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../common.dart';
import '../common_e2e.dart';

const _hostName = 'pubsub.googleapis.com';
const _rootPath = '/v1/';

MockClient mockClient() => MockClient(_hostName, _rootPath);

void main() {
  group('api', () {
    var badTopicNames = [
      'projects/',
      'projects/topics',
      'projects/$testProject',
      'projects/$testProject/',
      'projects/$testProject/topics',
      'projects/$testProject/topics/'
    ];

    var badSubscriptionNames = [
      'projects/',
      'projects/subscriptions',
      'projects/$testProject',
      'projects/$testProject/',
      'projects/$testProject/subscriptions',
      'projects/$testProject/subscriptions/'
    ];

    group('topic', () {
      var name = 'test-topic';
      var absoluteName = 'projects/$testProject/topics/test-topic';

      test('create', () {
        var mock = mockClient();
        mock.register(
            'PUT',
            'projects/$testProject/topics/test-topic',
            expectAsync1((http.Request request) {
              expect(request.body, '{}');
              return mock.respond(pubsub.Topic()..name = absoluteName);
            }, count: 2));

        var api = PubSub(mock, testProject);
        return api.createTopic(name).then(expectAsync1((topic) {
          expect(topic.name, name);
          expect(topic.project, testProject);
          expect(topic.absoluteName, absoluteName);
          return api.createTopic(absoluteName).then(expectAsync1((topic) {
            expect(topic.name, name);
            expect(topic.absoluteName, absoluteName);
          }));
        }));
      });

      test('create-error', () {
        var mock = mockClient();
        var api = PubSub(mock, testProject);
        for (var name in badTopicNames) {
          expect(() => api.createTopic(name), throwsArgumentError);
        }
        for (var name in badSubscriptionNames) {
          expect(() => api.createTopic(name), throwsArgumentError);
        }
      });

      test('delete', () {
        var mock = mockClient();
        mock.register(
            'DELETE',
            'projects/test-project/topics/test-topic',
            expectAsync1((request) {
              expect(request.body.length, 0);
              return mock.respondEmpty();
            }, count: 2));

        var api = PubSub(mock, testProject);
        return api.deleteTopic(name).then(expectAsync1((result) {
          expect(result, isNull);
          return api.deleteTopic(absoluteName).then(expectAsync1((topic) {
            expect(result, isNull);
          }));
        }));
      });

      test('delete-error', () {
        var mock = mockClient();
        var api = PubSub(mock, testProject);
        for (var name in badTopicNames) {
          expect(() => api.deleteTopic(name), throwsArgumentError);
        }
        for (var name in badSubscriptionNames) {
          expect(() => api.deleteTopic(name), throwsArgumentError);
        }
      });

      test('lookup', () {
        var mock = mockClient();
        mock.register(
            'GET',
            'projects/test-project/topics/test-topic',
            expectAsync1((request) {
              expect(request.body.length, 0);
              return mock.respond(pubsub.Topic()..name = absoluteName);
            }, count: 2));

        var api = PubSub(mock, testProject);
        return api.lookupTopic(name).then(expectAsync1((topic) {
          expect(topic.name, name);
          expect(topic.project, testProject);
          expect(topic.absoluteName, absoluteName);
          return api.lookupTopic(absoluteName).then(expectAsync1((topic) {
            expect(topic.name, name);
            expect(topic.absoluteName, absoluteName);
          }));
        }));
      });

      test('lookup-error', () {
        var mock = mockClient();
        var api = PubSub(mock, testProject);
        for (var name in badTopicNames) {
          expect(() => api.lookupTopic(name), throwsArgumentError);
        }
        for (var name in badSubscriptionNames) {
          expect(() => api.lookupTopic(name), throwsArgumentError);
        }
      });

      group('query', () {
        void addTopics(
            pubsub.ListTopicsResponse response, int first, int count) {
          response.topics = [];
          for (var i = 0; i < count; i++) {
            response.topics!.add(pubsub.Topic()..name = 'topic-${first + i}');
          }
        }

        // Mock that expect/generates [n] topics in pages of page size
        // [pageSize].
        void registerQueryMock(
          MockClient mock,
          int n,
          int pageSize, [
          int? totalCalls,
        ]) {
          var totalPages = (n + pageSize - 1) ~/ pageSize;
          // No items still generate one request.
          if (totalPages == 0) totalPages = 1;
          // Can pass in total calls if this mock is overwritten before all
          // expected pages are done, e.g. when testing errors.
          totalCalls ??= totalPages;
          var pageCount = 0;
          mock.register(
              'GET',
              'projects/$testProject/topics',
              expectAsync1((request) {
                pageCount++;
                expect(request.url.queryParameters['pageSize'], '$pageSize');
                expect(request.body.length, 0);
                if (pageCount > 1) {
                  expect(request.url.queryParameters['pageToken'], 'next-page');
                }

                var response = pubsub.ListTopicsResponse();
                var first = (pageCount - 1) * pageSize + 1;
                if (pageCount < totalPages) {
                  response.nextPageToken = 'next-page';
                  addTopics(response, first, pageSize);
                } else {
                  addTopics(response, first, n - (totalPages - 1) * pageSize);
                }
                return mock.respond(response);
              }, count: totalCalls));
        }

        group('list', () {
          Future q(int count) {
            var mock = mockClient();
            registerQueryMock(mock, count, 50);

            var api = PubSub(mock, testProject);
            return api
                .listTopics()
                .listen(expectAsync1((_) {}, count: count))
                .asFuture();
          }

          test('simple', () {
            return q(0)
                .then((_) => q(1))
                .then((_) => q(1))
                .then((_) => q(49))
                .then((_) => q(50))
                .then((_) => q(51))
                .then((_) => q(99))
                .then((_) => q(100))
                .then((_) => q(101))
                .then((_) => q(170));
          });

          test('immediate-pause-resume', () {
            var mock = mockClient();
            registerQueryMock(mock, 70, 50);

            var api = PubSub(mock, testProject);
            api.listTopics().listen(expectAsync1(((_) {}), count: 70),
                onDone: expectAsync0(() {}))
              ..pause()
              ..resume()
              ..pause()
              ..resume();
          });

          test('pause-resume', () {
            var mock = mockClient();
            registerQueryMock(mock, 70, 50);

            var api = PubSub(mock, testProject);
            var count = 0;
            late StreamSubscription subscription;
            subscription = api.listTopics().listen(
                expectAsync1(((_) {
                  subscription
                    ..pause()
                    ..resume()
                    ..pause();
                  if ((count % 2) == 0) {
                    subscription.resume();
                  } else {
                    scheduleMicrotask(() => subscription.resume());
                  }
                  return;
                }), count: 70),
                onDone: expectAsync0(() {}))
              ..pause();
            scheduleMicrotask(() => subscription.resume());
            addTearDown(() => subscription.cancel());
          });

          test('immediate-cancel', () {
            var mock = mockClient();
            registerQueryMock(mock, 70, 50, 1);

            var api = PubSub(mock, testProject);
            api
                .listTopics()
                .listen((_) => throw 'Unexpected',
                    onDone: () => throw 'Unexpected')
                .cancel();
          });

          test('cancel', () {
            var mock = mockClient();
            registerQueryMock(mock, 170, 50, 1);

            var api = PubSub(mock, testProject);
            late StreamSubscription subscription;
            subscription = api.listTopics().listen(
                expectAsync1((_) => subscription.cancel()),
                onDone: () => throw 'Unexpected');
          });

          test('error', () {
            void runTest(bool withPause) {
              // Test error on first GET request.
              var mock = mockClient();
              mock.register('GET', 'projects/$testProject/topics',
                  expectAsync1((request) {
                return mock.respondError(500);
              }));
              var api = PubSub(mock, testProject);
              StreamSubscription subscription;
              subscription = api.listTopics().listen((_) => throw 'Unexpected',
                  onDone: expectAsync0(() {}),
                  onError:
                      expectAsync1((e) => e is pubsub.DetailedApiRequestError));
              if (withPause) {
                subscription.pause();
                scheduleMicrotask(() => subscription.resume());
              }
              addTearDown(() => subscription.cancel());
            }

            runTest(false);
            runTest(true);
          });

          test('error-2', () {
            // Test error on second GET request.
            void runTest(bool withPause) {
              var mock = mockClient();
              registerQueryMock(mock, 51, 50, 1);

              var api = PubSub(mock, testProject);

              var count = 0;
              late StreamSubscription subscription;
              subscription = api.listTopics().listen(
                    expectAsync1(((_) {
                      count++;
                      if (count == 50) {
                        if (withPause) {
                          subscription.pause();
                          scheduleMicrotask(() => subscription.resume());
                        }
                        mock.clear();
                        mock.register('GET', 'projects/$testProject/topics',
                            expectAsync1((request) {
                          return mock.respondError(500);
                        }));
                      }
                      return;
                    }), count: 50),
                    onDone: expectAsync0(() {}),
                    onError: expectAsync1(
                        (e) => e is pubsub.DetailedApiRequestError),
                  );
              addTearDown(() => subscription.cancel());
            }

            runTest(false);
            runTest(true);
          });
        });

        group('page', () {
          test('empty', () {
            var mock = mockClient();
            registerQueryMock(mock, 0, 50);

            var api = PubSub(mock, testProject);
            return api.pageTopics().then(expectAsync1((page) {
              expect(page.items.length, 0);
              expect(page.isLast, isTrue);
              expect(() => page.next(), throwsStateError);

              mock.clear();
              registerQueryMock(mock, 0, 20);
              return api.pageTopics(pageSize: 20).then(expectAsync1((page) {
                expect(page.items.length, 0);
                expect(page.isLast, isTrue);
                expect(() => page.next(), throwsStateError);
              }));
            }));
          });

          test('single', () {
            var mock = mockClient();
            registerQueryMock(mock, 10, 50);

            var api = PubSub(mock, testProject);
            return api.pageTopics().then(expectAsync1((page) {
              expect(page.items.length, 10);
              expect(page.isLast, isTrue);
              expect(() => page.next(), throwsStateError);

              mock.clear();
              registerQueryMock(mock, 20, 20);
              return api.pageTopics(pageSize: 20).then(expectAsync1((page) {
                expect(page.items.length, 20);
                expect(page.isLast, isTrue);
                expect(() => page.next(), throwsStateError);
              }));
            }));
          });

          test('multiple', () {
            Future<void> runTest(int n, int pageSize) {
              var totalPages = (n + pageSize - 1) ~/ pageSize;
              var pageCount = 0;

              var completer = Completer();
              var mock = mockClient();
              registerQueryMock(mock, n, pageSize);

              void handlePage(Page page) {
                pageCount++;
                expect(page.isLast, pageCount == totalPages);
                expect(page.items.length,
                    page.isLast ? n - (totalPages - 1) * pageSize : pageSize);
                if (!page.isLast) {
                  page.next().then(expectAsync1((page) {
                    handlePage(page);
                  }));
                } else {
                  expect(() => page.next(), throwsStateError);
                  expect(pageCount, totalPages);
                  completer.complete();
                }
              }

              var api = PubSub(mock, testProject);
              api.pageTopics(pageSize: pageSize).then(expectAsync1(handlePage));

              return completer.future;
            }

            return runTest(70, 50)
                .then((_) => runTest(99, 1))
                .then((_) => runTest(99, 50))
                .then((_) => runTest(99, 98))
                .then((_) => runTest(99, 99))
                .then((_) => runTest(99, 100))
                .then((_) => runTest(100, 1))
                .then((_) => runTest(100, 50))
                .then((_) => runTest(100, 100))
                .then((_) => runTest(101, 50));
          });
        });
      });
    });

    group('subscription', () {
      var name = 'test-subscription';
      var absoluteName =
          'projects/$testProject/subscriptions/test-subscription';
      var topicName = 'test-topic';
      var absoluteTopicName = 'projects/$testProject/topics/test-topic';

      test('create', () {
        var mock = mockClient();
        mock.register(
            'PUT',
            'projects/$testProject/subscriptions',
            expectAsync1((request) {
              var requestSubscription = jsonDecode(request.body) as Map;
              expect(requestSubscription['topic'], absoluteTopicName);
              return mock.respond(pubsub.Subscription()..name = absoluteName);
            }, count: 2));

        var api = PubSub(mock, testProject);
        return api
            .createSubscription(name, topicName)
            .then(expectAsync1((subscription) {
          expect(subscription.name, name);
          expect(subscription.absoluteName, absoluteName);
          return api
              .createSubscription(absoluteName, absoluteTopicName)
              .then(expectAsync1((subscription) {
            expect(subscription.name, name);
            expect(subscription.project, testProject);
            expect(subscription.absoluteName, absoluteName);
          }));
        }));
      });

      test('create-error', () {
        var mock = mockClient();
        var api = PubSub(mock, testProject);
        for (var name in badSubscriptionNames) {
          expect(() => api.createSubscription(name, 'test-topic'),
              throwsArgumentError);
        }
        for (var name in badTopicNames) {
          expect(() => api.createSubscription('test-subscription', name),
              throwsArgumentError);
        }
      });

      test('delete', () {
        var mock = mockClient();
        mock.register(
            'DELETE',
            'projects/$testProject/subscriptions',
            expectAsync1((request) {
              expect(request.body.length, 0);
              return mock.respondEmpty();
            }, count: 2));

        var api = PubSub(mock, testProject);
        return api.deleteSubscription(name).then(expectAsync1((result) {
          expect(result, isNull);
          return api
              .deleteSubscription(absoluteName)
              .then(expectAsync1((topic) {
            expect(result, isNull);
          }));
        }));
      });

      test('delete-error', () {
        var mock = mockClient();
        var api = PubSub(mock, testProject);
        for (var name in badSubscriptionNames) {
          expect(() => api.deleteSubscription(name), throwsArgumentError);
        }
        for (var name in badTopicNames) {
          expect(() => api.deleteSubscription(name), throwsArgumentError);
        }
      });

      test('lookup', () {
        var mock = mockClient();
        mock.register(
            'GET',
            RegExp('projects/$testProject/subscriptions'),
            expectAsync1((request) {
              expect(request.body.length, 0);
              return mock.respond(pubsub.Subscription()..name = absoluteName);
            }, count: 2));

        var api = PubSub(mock, testProject);
        return api.lookupSubscription(name).then(expectAsync1((subscription) {
          expect(subscription.name, name);
          expect(subscription.absoluteName, absoluteName);
          return api
              .lookupSubscription(absoluteName)
              .then(expectAsync1((subscription) {
            expect(subscription.name, name);
            expect(subscription.project, testProject);
            expect(subscription.absoluteName, absoluteName);
          }));
        }));
      });

      test('lookup-error', () {
        var mock = mockClient();
        var api = PubSub(mock, testProject);
        for (var name in badSubscriptionNames) {
          expect(() => api.lookupSubscription(name), throwsArgumentError);
        }
        for (var name in badTopicNames) {
          expect(() => api.lookupSubscription(name), throwsArgumentError);
        }
      });

      group('query', () {
        void addSubscriptions(
            pubsub.ListSubscriptionsResponse response, int first, int count) {
          response.subscriptions = [];
          for (var i = 0; i < count; i++) {
            response.subscriptions!
                .add(pubsub.Subscription()..name = 'subscription-${first + i}');
          }
        }

        // Mock that expect/generates [n] subscriptions in pages of page size
        // [pageSize].
        void registerQueryMock(MockClient mock, int n, int pageSize,
            {String? topic, int? totalCalls}) {
          var totalPages = (n + pageSize - 1) ~/ pageSize;
          // No items still generate one request.
          if (totalPages == 0) totalPages = 1;
          // Can pass in total calls if this mock is overwritten before all
          // expected pages are done, e.g. when testing errors.
          totalCalls ??= totalPages;
          var pageCount = 0;
          mock.register(
              'GET',
              'projects/$testProject/subscriptions',
              expectAsync1((request) {
                pageCount++;
                expect(request.url.queryParameters['pageSize'], '$pageSize');
                expect(request.body.length, 0);
                if (pageCount > 1) {
                  expect(request.url.queryParameters['pageToken'], 'next-page');
                }

                var response = pubsub.ListSubscriptionsResponse();
                var first = (pageCount - 1) * pageSize + 1;
                if (pageCount < totalPages) {
                  response.nextPageToken = 'next-page';
                  addSubscriptions(response, first, pageSize);
                } else {
                  addSubscriptions(
                      response, first, n - (totalPages - 1) * pageSize);
                }
                return mock.respond(response);
              }, count: totalCalls));
        }

        group('list', () {
          Future q(String? topic, int count) {
            var mock = mockClient();
            registerQueryMock(mock, count, 50, topic: topic);

            var api = PubSub(mock, testProject);
            return (topic == null
                    ? api.listSubscriptions()
                    : api.listSubscriptions(topic))
                .listen(expectAsync1((_) {}, count: count))
                .asFuture();
          }

          test('simple', () {
            return q(null, 0)
                .then((_) => q('topic', 0))
                .then((_) => q(null, 1))
                .then((_) => q('topic', 1))
                .then((_) => q(null, 10))
                .then((_) => q('topic', 10))
                .then((_) => q(null, 49))
                .then((_) => q('topic', 49))
                .then((_) => q(null, 50))
                .then((_) => q('topic', 50))
                .then((_) => q(null, 51))
                .then((_) => q('topic', 51))
                .then((_) => q(null, 99))
                .then((_) => q('topic', 99))
                .then((_) => q(null, 100))
                .then((_) => q('topic', 100))
                .then((_) => q(null, 101))
                .then((_) => q('topic', 101))
                .then((_) => q(null, 170))
                .then((_) => q('topic', 170));
          });

          test('immediate-pause-resume', () {
            var mock = mockClient();
            registerQueryMock(mock, 70, 50);

            var api = PubSub(mock, testProject);
            api.listSubscriptions().listen(expectAsync1(((_) {}), count: 70),
                onDone: expectAsync0(() {}))
              ..pause()
              ..resume()
              ..pause()
              ..resume();
          });

          test('pause-resume', () {
            var mock = mockClient();
            registerQueryMock(mock, 70, 50);

            var api = PubSub(mock, testProject);
            var count = 0;
            late StreamSubscription subscription;
            subscription = api.listSubscriptions().listen(
                expectAsync1(((_) {
                  subscription
                    ..pause()
                    ..resume()
                    ..pause();
                  if ((count % 2) == 0) {
                    subscription.resume();
                  } else {
                    scheduleMicrotask(() => subscription.resume());
                  }
                  return;
                }), count: 70),
                onDone: expectAsync0(() {}))
              ..pause();
            scheduleMicrotask(() => subscription.resume());
            addTearDown(() => subscription.cancel());
          });

          test('immediate-cancel', () {
            var mock = mockClient();
            registerQueryMock(mock, 70, 50, totalCalls: 1);

            var api = PubSub(mock, testProject);
            api
                .listSubscriptions()
                .listen((_) => throw 'Unexpected',
                    onDone: () => throw 'Unexpected')
                .cancel();
          });

          test('cancel', () {
            var mock = mockClient();
            registerQueryMock(mock, 170, 50, totalCalls: 1);

            var api = PubSub(mock, testProject);
            late StreamSubscription subscription;
            subscription = api.listSubscriptions().listen(
                expectAsync1((_) => subscription.cancel()),
                onDone: () => throw 'Unexpected');
          });

          test('error', () {
            void runTest(bool withPause) {
              // Test error on first GET request.
              var mock = mockClient();
              mock.register('GET', 'projects/$testProject/subscriptions',
                  expectAsync1((request) {
                return mock.respondError(500);
              }));
              var api = PubSub(mock, testProject);
              StreamSubscription subscription;
              subscription = api.listSubscriptions().listen(
                  (_) => throw 'Unexpected',
                  onDone: expectAsync0(() {}),
                  onError:
                      expectAsync1((e) => e is pubsub.DetailedApiRequestError));
              addTearDown(() => subscription.cancel());
              if (withPause) {
                subscription.pause();
                scheduleMicrotask(() => subscription.resume());
              }
            }

            runTest(false);
            runTest(true);
          });

          test('error-2', () {
            void runTest(bool withPause) {
              // Test error on second GET request.
              var mock = mockClient();
              registerQueryMock(mock, 51, 50, totalCalls: 1);

              var api = PubSub(mock, testProject);

              var count = 0;
              late StreamSubscription subscription;
              subscription = api.listSubscriptions().listen(
                    expectAsync1(((_) {
                      count++;
                      if (count == 50) {
                        if (withPause) {
                          subscription.pause();
                          scheduleMicrotask(() => subscription.resume());
                        }
                        mock.clear();
                        mock.register(
                            'GET', 'projects/$testProject/subscriptions',
                            expectAsync1((request) {
                          return mock.respondError(500);
                        }));
                      }
                      return;
                    }), count: 50),
                    onDone: expectAsync0(() {}),
                    onError: expectAsync1(
                        (e) => e is pubsub.DetailedApiRequestError),
                  );
              addTearDown(() => subscription.cancel());
            }

            runTest(false);
            runTest(true);
          });
        });

        group('page', () {
          Future<void> emptyTest(String? topic) {
            var mock = mockClient();
            registerQueryMock(mock, 0, 50, topic: topic);

            var api = PubSub(mock, testProject);
            return (topic == null
                    ? api.pageSubscriptions()
                    : api.pageSubscriptions(topic: topic))
                .then(expectAsync1((page) {
              expect(page.items.length, 0);
              expect(page.isLast, isTrue);
              expect(() => page.next(), throwsStateError);

              mock.clear();
              registerQueryMock(mock, 0, 20, topic: topic);
              return (topic == null
                      ? api.pageSubscriptions(pageSize: 20)
                      : api.pageSubscriptions(topic: topic, pageSize: 20))
                  .then(expectAsync1((page) {
                expect(page.items.length, 0);
                expect(page.isLast, isTrue);
                expect(() => page.next(), throwsStateError);
              }));
            }));
          }

          test('empty', () {
            emptyTest(null);
            emptyTest('topic');
          });

          Future<void> singleTest(String? topic) {
            var mock = mockClient();
            registerQueryMock(mock, 10, 50, topic: topic);

            var api = PubSub(mock, testProject);
            return (topic == null
                    ? api.pageSubscriptions()
                    : api.pageSubscriptions(topic: topic))
                .then(expectAsync1((page) {
              expect(page.items.length, 10);
              expect(page.isLast, isTrue);
              expect(() => page.next(), throwsStateError);

              mock.clear();
              registerQueryMock(mock, 20, 20, topic: topic);
              return (topic == null
                      ? api.pageSubscriptions(pageSize: 20)
                      : api.pageSubscriptions(topic: topic, pageSize: 20))
                  .then(expectAsync1((page) {
                expect(page.items.length, 20);
                expect(page.isLast, isTrue);
                expect(() => page.next(), throwsStateError);
              }));
            }));
          }

          test('single', () {
            singleTest(null);
            singleTest('topic');
          });

          Future<void> multipleTest(int n, int pageSize, String? topic) {
            var totalPages = (n + pageSize - 1) ~/ pageSize;
            var pageCount = 0;

            var completer = Completer();
            var mock = mockClient();
            registerQueryMock(mock, n, pageSize, topic: topic);

            void handlingPage(Page page) {
              pageCount++;
              expect(page.isLast, pageCount == totalPages);
              expect(page.items.length,
                  page.isLast ? n - (totalPages - 1) * pageSize : pageSize);
              if (!page.isLast) {
                page.next().then((page) {
                  handlingPage(page);
                });
              } else {
                expect(() => page.next(), throwsStateError);
                expect(pageCount, totalPages);
                completer.complete();
              }
            }

            var api = PubSub(mock, testProject);
            (topic == null
                    ? api.pageSubscriptions(pageSize: pageSize)
                    : api.pageSubscriptions(topic: topic, pageSize: pageSize))
                .then(handlingPage);

            return completer.future;
          }

          test('multiple', () {
            return multipleTest(70, 50, null)
                .then((_) => multipleTest(99, 1, null))
                .then((_) => multipleTest(99, 50, null))
                .then((_) => multipleTest(99, 98, null))
                .then((_) => multipleTest(99, 99, null))
                .then((_) => multipleTest(99, 100, null))
                .then((_) => multipleTest(100, 1, null))
                .then((_) => multipleTest(100, 50, null))
                .then((_) => multipleTest(100, 100, null))
                .then((_) => multipleTest(101, 50, null))
                .then((_) => multipleTest(70, 50, 'topic'))
                .then((_) => multipleTest(99, 1, 'topic'))
                .then((_) => multipleTest(99, 50, 'topic'))
                .then((_) => multipleTest(99, 98, 'topic'))
                .then((_) => multipleTest(99, 99, 'topic'))
                .then((_) => multipleTest(99, 100, 'topic'))
                .then((_) => multipleTest(100, 1, 'topic'))
                .then((_) => multipleTest(100, 50, 'topic'))
                .then((_) => multipleTest(100, 100, 'topic'))
                .then((_) => multipleTest(101, 50, 'topic'));
          });
        });
      });
    });
  });

  group('topic', () {
    var name = 'test-topic';
    var absoluteName = 'projects/$testProject/topics/test-topic';
    var message = 'Hello, world!';
    var messageBytes = utf8.encode(message);
    var messageBase64 = base64.encode(messageBytes);
    var attributes = {'a': '1', 'b': 'text'};

    void registerLookup(MockClient mock) {
      mock.register('GET', absoluteName, expectAsync1((request) {
        expect(request.body.length, 0);
        return mock.respond(pubsub.Topic()..name = absoluteName);
      }));
    }

    void registerPublish(
      MockClient mock,
      int count,
      Future<http.Response> Function(pubsub.PublishRequest) fn,
    ) {
      mock.register(
          'POST',
          'projects/test-project/topics/test-topic:publish',
          expectAsync1((request) {
            var publishRequest =
                pubsub.PublishRequest.fromJson(jsonDecode(request.body) as Map);
            return fn(publishRequest);
          }, count: count));
    }

    test('publish', () {
      var mock = mockClient();
      registerLookup(mock);

      var api = PubSub(mock, testProject);
      return api.lookupTopic(name).then(expectAsync1((topic) {
        mock.clear();
        registerPublish(mock, 4, ((request) {
          expect(request.messages!.length, 1);
          expect(request.messages![0].data, messageBase64);
          expect(request.messages![0].attributes, isNull);
          return mock.respond(pubsub.PublishResponse()..messageIds = ['0']);
        }));

        return topic.publishString(message).then(expectAsync1((result) {
          expect(result, isNull);
          return topic.publishBytes(messageBytes).then(expectAsync1((result) {
            expect(result, isNull);
            return topic
                .publish(Message.withString(message))
                .then(expectAsync1((result) {
              expect(result, isNull);
              return topic
                  .publish(Message.withBytes(messageBytes))
                  .then(expectAsync1((result) {
                expect(result, isNull);
              }));
            }));
          }));
        }));
      }));
    });

    test('publish-with-attributes', () {
      var mock = mockClient();
      registerLookup(mock);

      var api = PubSub(mock, testProject);
      return api.lookupTopic(name).then(expectAsync1((topic) {
        mock.clear();
        registerPublish(mock, 4, ((request) {
          expect(request.messages!.length, 1);
          expect(request.messages![0].data, messageBase64);
          expect(request.messages![0].attributes, isNotNull);
          expect(request.messages![0].attributes!.length, attributes.length);
          expect(request.messages![0].attributes, attributes);
          return mock.respond(pubsub.PublishResponse()..messageIds = ['0']);
        }));

        return topic
            .publishString(message, attributes: attributes)
            .then(expectAsync1((result) {
          expect(result, isNull);
          return topic
              .publishBytes(messageBytes, attributes: attributes)
              .then(expectAsync1((result) {
            expect(result, isNull);
            return topic
                .publish(Message.withString(message, attributes: attributes))
                .then(expectAsync1((result) {
              expect(result, isNull);
              return topic
                  .publish(
                      Message.withBytes(messageBytes, attributes: attributes))
                  .then(expectAsync1((result) {
                expect(result, isNull);
              }));
            }));
          }));
        }));
      }));
    });

    test('delete', () {
      var mock = mockClient();
      mock.register('GET', absoluteName, expectAsync1((request) {
        expect(request.body.length, 0);
        return mock.respond(pubsub.Topic()..name = absoluteName);
      }));

      var api = PubSub(mock, testProject);
      return api.lookupTopic(name).then(expectAsync1((topic) {
        expect(topic.name, name);
        expect(topic.absoluteName, absoluteName);

        mock.register('DELETE', absoluteName, expectAsync1((request) {
          expect(request.body.length, 0);
          return mock.respondEmpty();
        }));

        return topic.delete().then(expectAsync1((result) {
          expect(result, isNull);
        }));
      }));
    });
  });

  group('subscription', () {
    var name = 'test-subscription';
    var absoluteName = 'projects/$testProject/subscriptions/test-subscription';

    test('delete', () {
      var mock = mockClient();
      mock.register('GET', absoluteName, expectAsync1((request) {
        expect(request.body.length, 0);
        return mock.respond(pubsub.Topic()..name = absoluteName);
      }));

      var api = PubSub(mock, testProject);
      return api.lookupSubscription(name).then(expectAsync1((subscription) {
        expect(subscription.name, name);
        expect(subscription.absoluteName, absoluteName);

        mock.register('DELETE', absoluteName, expectAsync1((request) {
          expect(request.body.length, 0);
          return mock.respondEmpty();
        }));

        return subscription.delete().then(expectAsync1((result) {
          expect(result, isNull);
        }));
      }));
    });
  });

  group('push', () {
    var relativeSubscriptionName = 'sgjesse-managed-vm/test-push-subscription';
    var absoluteSubscriptionName = '/subscriptions/$relativeSubscriptionName';

    test('event', () {
      var requestBody = '''
{
  "message": {
    "data":"SGVsbG8sIHdvcmxkIDMwIG9mIDUwIQ==",
    "labels": [
      {
        "key":"messageNo",
        "numValue":"30"
      },
      {
        "key":"test",
        "strValue":"hello"
      }
    ]
  },
  "subscription":"$absoluteSubscriptionName"
}
''';
      var event = PushEvent.fromJson(requestBody);
      expect(event.message.asString, 'Hello, world 30 of 50!');
      expect(event.message.attributes['messageNo'], '30');
      expect(event.message.attributes['test'], 'hello');
      expect(event.subscriptionName, absoluteSubscriptionName);
    });

    test('event-short-subscription-name', () {
      var requestBody = '''
{
  "message": {
    "data":"SGVsbG8sIHdvcmxkIDMwIG9mIDUwIQ==",
    "labels": [
      {
        "key":"messageNo",
        "numValue":30
      },
      {
        "key":"test",
        "strValue":"hello"
      }
    ]
  },
  "subscription":"$relativeSubscriptionName"
}
''';
      var event = PushEvent.fromJson(requestBody);
      expect(event.message.asString, 'Hello, world 30 of 50!');
      expect(event.message.attributes['messageNo'], '30');
      expect(event.message.attributes['test'], 'hello');
      expect(event.subscriptionName, absoluteSubscriptionName);
    });
  });
}
