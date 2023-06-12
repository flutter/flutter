// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http;
import 'package:http_multi_server/http_multi_server.dart';
import 'package:http_multi_server/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('with multiple HttpServers', () {
    late HttpMultiServer multiServer;
    late HttpServer subServer1;
    late HttpServer subServer2;
    late HttpServer subServer3;

    setUp(() {
      return Future.wait([
        HttpServer.bind('localhost', 0).then((server) => subServer1 = server),
        HttpServer.bind('localhost', 0).then((server) => subServer2 = server),
        HttpServer.bind('localhost', 0).then((server) => subServer3 = server)
      ]).then((servers) => multiServer = HttpMultiServer(servers));
    });

    tearDown(() => multiServer.close());

    test('listen listens to all servers', () {
      multiServer.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      expect(_read(subServer1), completion(equals('got request')));
      expect(_read(subServer2), completion(equals('got request')));
      expect(_read(subServer3), completion(equals('got request')));
    });

    test('serverHeader= sets the value for all servers', () {
      multiServer.serverHeader = 'http_multi_server test';

      multiServer.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      expect(
          _get(subServer1).then((response) {
            expect(
                response.headers['server'], equals('http_multi_server test'));
          }),
          completes);

      expect(
          _get(subServer2).then((response) {
            expect(
                response.headers['server'], equals('http_multi_server test'));
          }),
          completes);

      expect(
          _get(subServer3).then((response) {
            expect(
                response.headers['server'], equals('http_multi_server test'));
          }),
          completes);
    });

    test('autoCompress= sets the value for all servers', () {
      multiServer.autoCompress = true;

      multiServer.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      expect(
          _get(subServer1).then((response) {
            expect(response.headers['content-encoding'], equals('gzip'));
          }),
          completes);

      expect(
          _get(subServer2).then((response) {
            expect(response.headers['content-encoding'], equals('gzip'));
          }),
          completes);

      expect(
          _get(subServer3).then((response) {
            expect(response.headers['content-encoding'], equals('gzip'));
          }),
          completes);
    });

    test('headers.set sets the value for all servers', () {
      multiServer.defaultResponseHeaders
          .set('server', 'http_multi_server test');

      multiServer.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      expect(
          _get(subServer1).then((response) {
            expect(
                response.headers['server'], equals('http_multi_server test'));
          }),
          completes);

      expect(
          _get(subServer2).then((response) {
            expect(
                response.headers['server'], equals('http_multi_server test'));
          }),
          completes);

      expect(
          _get(subServer3).then((response) {
            expect(
                response.headers['server'], equals('http_multi_server test'));
          }),
          completes);
    });

    test('connectionsInfo sums the values for all servers', () {
      var pendingRequests = 0;
      var awaitingResponseCompleter = Completer();
      var sendResponseCompleter = Completer();
      multiServer.listen((request) {
        sendResponseCompleter.future.then((_) {
          request.response.write('got request');
          request.response.close();
        });

        pendingRequests++;
        if (pendingRequests == 2) awaitingResponseCompleter.complete();
      });

      // Queue up some requests, then wait on [awaitingResponseCompleter] to
      // make sure they're in-flight before we check [connectionsInfo].
      expect(_get(subServer1), completes);
      expect(_get(subServer2), completes);

      return awaitingResponseCompleter.future.then((_) {
        var info = multiServer.connectionsInfo();
        expect(info.total, equals(2));
        expect(info.active, equals(2));
        expect(info.idle, equals(0));
        expect(info.closing, equals(0));

        sendResponseCompleter.complete();
      });
    });
  });

  group('HttpMultiServer.loopback', () {
    late HttpServer server;

    setUp(() {
      return HttpMultiServer.loopback(0).then((s) => server = s);
    });

    tearDown(() => server.close());

    test('listens on all localhost interfaces', () async {
      server.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      if (await supportsIPv4) {
        expect(http.read(Uri.http('127.0.0.1:${server.port}', '/')),
            completion(equals('got request')));
      }

      if (await supportsIPv6) {
        expect(http.read(Uri.http('[::1]:${server.port}', '/')),
            completion(equals('got request')));
      }
    });
  });

  group('HttpMultiServer.bind', () {
    test("listens on all localhost interfaces for 'localhost'", () async {
      final server = await HttpMultiServer.bind('localhost', 0);
      server.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      if (await supportsIPv4) {
        expect(http.read(Uri.http('127.0.0.1:${server.port}', '/')),
            completion(equals('got request')));
      }

      if (await supportsIPv6) {
        expect(http.read(Uri.http('[::1]:${server.port}', '/')),
            completion(equals('got request')));
      }
    });

    test("listens on all localhost interfaces for 'any'", () async {
      final server = await HttpMultiServer.bind('any', 0);
      server.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      if (await supportsIPv4) {
        expect(http.read(Uri.http('127.0.0.1:${server.port}', '/')),
            completion(equals('got request')));
      }

      if (await supportsIPv6) {
        expect(http.read(Uri.http('[::1]:${server.port}', '/')),
            completion(equals('got request')));
      }
    });

    test("uses the correct server address for 'any'", () async {
      final server = await HttpMultiServer.bind('any', 0);

      if (!await supportsIPv6) {
        expect(server.address, InternetAddress.anyIPv4);
      } else {
        expect(server.address, InternetAddress.anyIPv6);
      }
    });

    test('listens on specified hostname', () async {
      if (!await supportsIPv4) return;
      final server = await HttpMultiServer.bind(InternetAddress.anyIPv4, 0);
      server.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      expect(http.read(Uri.http('127.0.0.1:${server.port}', '/')),
          completion(equals('got request')));

      if (await supportsIPv6) {
        expect(http.read(Uri.http('[::1]:${server.port}', '/')),
            throwsA(isA<SocketException>()));
      }
    });
  });

  group('HttpMultiServer.bindSecure', () {
    late http.Client client;
    late SecurityContext context;
    setUp(() async {
      context = SecurityContext()
        ..setTrustedCertificatesBytes(_sslCert)
        ..useCertificateChainBytes(_sslCert)
        ..usePrivateKeyBytes(_sslKey, password: 'dartdart');
      client = http.IOClient(HttpClient(context: context));
    });
    test('listens on all localhost interfaces for "localhost"', () async {
      final server = await HttpMultiServer.bindSecure('localhost', 0, context);
      server.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      if (await supportsIPv4) {
        expect(client.read(Uri.https('127.0.0.1:${server.port}', '')),
            completion(equals('got request')));
      }

      if (await supportsIPv6) {
        expect(client.read(Uri.https('[::1]:${server.port}', '')),
            completion(equals('got request')));
      }
    });

    test('listens on all localhost interfaces for "any"', () async {
      final server = await HttpMultiServer.bindSecure('any', 0, context);
      server.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      if (await supportsIPv4) {
        expect(client.read(Uri.https('127.0.0.1:${server.port}', '')),
            completion(equals('got request')));
      }

      if (await supportsIPv6) {
        expect(client.read(Uri.https('[::1]:${server.port}', '')),
            completion(equals('got request')));
      }
    });

    test('listens on specified hostname', () async {
      if (!await supportsIPv4) return;
      final server =
          await HttpMultiServer.bindSecure(InternetAddress.anyIPv4, 0, context);
      server.listen((request) {
        request.response.write('got request');
        request.response.close();
      });

      expect(client.read(Uri.https('127.0.0.1:${server.port}', '')),
          completion(equals('got request')));

      if (await supportsIPv6) {
        expect(client.read(Uri.https('[::1]:${server.port}', '')),
            throwsA(isA<SocketException>()));
      }
    });
  });
}

/// Makes a GET request to the root of [server] and returns the response.
Future<http.Response> _get(HttpServer server) => http.get(_urlFor(server));

/// Makes a GET request to the root of [server] and returns the response body.
Future<String> _read(HttpServer server) => http.read(_urlFor(server));

/// Returns the URL for the root of [server].
Uri _urlFor(HttpServer server) =>
    Uri.http('${server.address.host}:${server.port}', '/');

final _sslCert = utf8.encode('''
-----BEGIN CERTIFICATE-----
MIIDZDCCAkygAwIBAgIBATANBgkqhkiG9w0BAQsFADAgMR4wHAYDVQQDDBVpbnRl
cm1lZGlhdGVhdXRob3JpdHkwHhcNMTUxMDI3MTAyNjM1WhcNMjUxMDI0MTAyNjM1
WjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
ggEKAoIBAQCkg/Qr8RQeLTOSgCkyiEX2ztgkgscX8hKGHEHdvlkmVK3JVEIIwkvu
/Y9LtHZUia3nPAgqEEbexzTENZjSCcC0V6I2XW/e5tIE3rO0KLZyhtZhN/2SfJ6p
KbOh0HLr1VtkKJGp1tzUmHW/aZI32pK60ZJ/N917NLPCJpCaL8+wHo3+w3oNqln6
oJsfgxy9SUM8Bsc9WMYKMUdqLO1QKs1A5YwqZuO7Mwj+4LY2QDixC7Ua7V9YAPo2
1SBeLvMCHbYxSPCuxcZ/kDkgax/DF9u7aZnGhMImkwBka0OQFvpfjKtTIuoobTpe
PAG7MQYXk4RjnjdyEX/9XAQzvNo1CDObAgMBAAGjgbQwgbEwPAYDVR0RBDUwM4IJ
bG9jYWxob3N0ggkxMjcuMC4wLjGCAzo6MYcEfwAAAYcQAAAAAAAAAAAAAAAAAAAA
ATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBSvhJo6taTggJQBukEvMo/PDk8tKTAf
BgNVHSMEGDAWgBS98L4T5RaIToE3DkBRsoeWPil0eDAOBgNVHQ8BAf8EBAMCA6gw
EwYDVR0lBAwwCgYIKwYBBQUHAwEwDQYJKoZIhvcNAQELBQADggEBAHLOt0mL2S4A
B7vN7KsfQeGlVgZUVlEjem6kqBh4fIzl4CsQuOO8oJ0FlO1z5JAIo98hZinymJx1
phBVpyGIKakT/etMH0op5evLe9dD36VA3IM/FEv5ibk35iGnPokiJXIAcdHd1zam
YaTHRAnZET5S03+7BgRTKoRuszhbvuFz/vKXaIAnVNOF4Gf2NUJ/Ax7ssJtRkN+5
UVxe8TZVxzgiRv1uF6NTr+J8PDepkHCbJ6zEQNudcFKAuC56DN1vUe06gRDrNbVq
2JHEh4pRfMpdsPCrS5YHBjVq/XHtFHgwDR6g0WTwSUJvDeM4OPQY5f61FB0JbFza
PkLkXmoIod8=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDLjCCAhagAwIBAgIBAjANBgkqhkiG9w0BAQsFADAYMRYwFAYDVQQDDA1yb290
YXV0aG9yaXR5MB4XDTE1MTAyNzEwMjYzNVoXDTI1MTAyNDEwMjYzNVowIDEeMBwG
A1UEAwwVaW50ZXJtZWRpYXRlYXV0aG9yaXR5MIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEA6GndRFiXk+2q+Ig7ZOWKKGta+is8137qyXz+eVFs5sA0ajMN
ZBAMWS0TIXw/Yks+y6fEcV/tfv91k1eUN4YXPcoxTdDF97d2hO9wxumeYOMnQeDy
VZVDKQBZ+jFMeI+VkNpMEdmsLErpZDGob/1dC8tLEuR6RuRR8X6IDGMPOCMw1jLK
V1bQjPtzqKadTscfjLuKxuLgspJdTrzsu6hdcl1mm8K6CjTY2HNXWxs1yYmwfuQ2
Z4/8sOMNqFqLjN+ChD7pksTMq7IosqGiJzi2bpd5f44ek/k822Y0ATncJHk4h1Z+
kZBnW6kgcLna1gDri9heRwSZ+M8T8nlHgIMZIQIDAQABo3sweTASBgNVHRMBAf8E
CDAGAQH/AgEAMB0GA1UdDgQWBBS98L4T5RaIToE3DkBRsoeWPil0eDAfBgNVHSME
GDAWgBRxD5DQHTmtpDFKDOiMf5FAi6vfbzAOBgNVHQ8BAf8EBAMCAgQwEwYDVR0l
BAwwCgYIKwYBBQUHAwEwDQYJKoZIhvcNAQELBQADggEBAD+4KpUeV5mUPw5IG/7w
eOXnUpeS96XFGuS1JuFo/TbgntPWSPyo+rD4GrPIkUXyoHaMCDd2UBEjyGbBIKlB
NZA3RJOAEp7DTkLNK4RFn/OEcLwG0J5brL7kaLRO4vwvItVIdZ2XIqzypRQTc0MG
MmF08zycnSlaN01ryM67AsMhwdHqVa+uXQPo8R8sdFGnZ33yywTYD73FeImXilQ2
rDnFUVqmrW1fjl0Fi4rV5XI0EQiPrzKvRtmF8ZqjGATPOsRd64cwQX6V+P5hNeIR
9pba6td7AbNGausHfacRYMyoGJWWWkFPd+7jWOCPqW7Fk1tmBgdB8GzXa3inWIRM
RUE=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIC+zCCAeOgAwIBAgIBATANBgkqhkiG9w0BAQsFADAYMRYwFAYDVQQDDA1yb290
YXV0aG9yaXR5MB4XDTE1MTAyNzEwMjYzNFoXDTI1MTAyNDEwMjYzNFowGDEWMBQG
A1UEAwwNcm9vdGF1dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBAMl+dcraUM/E7E6zl7+7hK9oUJYXJLnfiMtP/TRFVbH4+2aEN8vXzPbzKdR3
FfaHczXQTwnTCaYA4u4uSDvSOsFFEfxEwYORsdKmQEM8nGpVX2NVvKsMcGIhh8kh
ZwJfkMIOcAxmGIHGdMhF8VghonJ8uGiuqktxdfpARq0g3fqIjDHsF9/LpfshUfk9
wsRyTF0yr90U/dsfnE+u8l7GvVl8j2Zegp0sagAGtLaNv7tP17AibqEGg2yDBrBN
9r9ihe4CqMjx+Q2kQ2S9Gz2V2ReO/n6vm2VQxsPRB/lV/9jh7cUcS0/9mggLYrDy
cq1v7rLLQrWuxMz1E3gOhyCYJ38CAwEAAaNQME4wHQYDVR0OBBYEFHEPkNAdOa2k
MUoM6Ix/kUCLq99vMB8GA1UdIwQYMBaAFHEPkNAdOa2kMUoM6Ix/kUCLq99vMAwG
A1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBABrhjnWC6b+z9Kw73C/niOwo
9sPdufjS6tb0sCwDjt3mjvE4NdNWt+/+ZOugW6dqtvqhtqZM1q0u9pJkNwIrqgFD
ZHcfNaf31G6Z2YE+Io7woTVw6fFobg/EFo+a/qwbvWL26McmiRL5yiSBjVjpX4a5
kdZ+aPQUCBaLrTWwlCDqzSVIULWUQvveRWbToMFKPNID58NtEpymAx3Pgir7YjV9
UnlU2l5vZrh1PTCqZxvC/IdRESUfW80LdHaeyizRUP+6vKxGgSz2MRuYINjbd6GO
hGiCpWlwziW2xLV1l2qSRLko2kIafLZP18N0ThM9zKbU5ps9NgFOf//wqSGtLaE=
-----END CERTIFICATE-----
''');

List<int> _sslKey = utf8.encode('''
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIE4zAcBgoqhkiG9w0BDAEBMA4ECBMCjlg8JYZ4AgIIAASCBMFd9cBoZ5xcTock
AVQcg/HzYJtMceKn1gtMDdC7mmXuyN0shoxhG4BpQInHkFARL+nenesXFxEm4X5e
L603Pcgw72/ratxVpTW7hPMjiLTEBqza0GjQm7Sarbdy+Vzdp/6XFrAcPfFl1juY
oyYzbozPsvFHz3Re44y1KmI4HAzU/qkjJUbNTTiPPVI2cDP6iYN2XXxBb1wwp8jR
iqdZqFG7lU/wvPEbD7BVPpmJBHWNG681zb4ea5Zn4hW8UaxpiIBiaH0/IWc2SVZd
RliAFo3NEsGxCcsnBo/n00oudGbOJxdOp7FbH5hJpeqX2WhCyJRxIeHOWmeuMAet
03HFriiEmJ99m2nEJN1x0A3QUUM7ji6vZAb4qb1dyq7LlX4M2aaqixRnaTcQkapf
DOxX35DEBXSKrDpyWp6Rx4wNpUyi1TKyhaVnYgD3Gn0VfC/2w86gSFlrf9PMYGM0
PvFxTDzTyjOuPBRa728gZOGXgDOL7qvdInU/opVew7kFeRQHXxHzFCLK5dD+Vrig
5fS3m0++f55ODkxqHXB8gbXbd3GMmsW6MrGpU7VsCNtbVPdSMW0FalovEB0M+2lj
1VfuvL+0F5huTe+BgZAt6xgET/CIcZXdNMRPVhraqUjqWtI9Rdk4STPCpU1rDkjG
YDl/fo4W2T6qQWFUpiC9IvVVGkVxaqfZZ4Qu+V5xPUi6vk95QiTNkN1t+m+sCCgS
Llkea8Um0aHMy33Lj3NsfL0LMrnpniqcAks8BvcgIZwk1VRqcj7BQVCygJSYrmAR
DBhMpjWlXuSggnyVPuduZDtnTN+8lCHLOKL3a3bDb6ySaKX49Km6GutDLfpDtEA0
3mQvmEG4XVm7zy+AlN72qFbtSLDRi/D/uQh2q/ZrFQLOBQBQB56TvEbKouLimUDM
ascQA3aUyhOE7e+d02NOFIFTozwc/C//CIFeA+ZEwxyfha/3Bor6Jez7PC/eHNxZ
w7YMXzPW9NhcCcerhYGebuCJxLwzqJ+IGdukjKsGV2ytWDoB2xZiJNu096j4RKcq
YSJoen0R7IH8N4eDujXR8m9kAl724Uqs1OoAs4VNICvzTutbsgVZ6Z+NMOcfnPw9
jZkFhot16w8znD+OmhBR7/bzOLpaeUhk7EhNq5M6U0NNWx3WwkDlvU/jx+6/EQe3
iLEHptH2HYBF1xscaKGbtKNtuQsfdzgWpOX0qK2YbK3yCKvL/xIm1DQmDZDKkWdW
VNh8oGV1H96CivWlvxhAgXKz9F/83CjMw8YXRk7RJvWR4vtNvXFAvGkFIYCN9Jv9
p+1ukaYoxSLGBik907I6gWSHqumJiCprUyAX/bVfZfNiYh4hzeA3lhwxZSax3JG4
7QFPvyepOmF/3AAzS/Pusx6jOZnuCMCkfQi6Wpem1o3s4x+fP7kz00Xuj01ErucM
S10ixfIh84kXBN3dTRDtDdeCyoMsBKO0W5jDBBlWL02YfdF6Opo1Q4cPh2DYgXMh
XEszNZSK5LB0y+f3A6Kdx/hkZzHVvMONA70OyrkoZzGyWENhcB0c7ntTJyPPD2qM
s0HRA2VwF/0ypU3OKERM1Ua5NSkTgvnnVTlV9GO90Tkn5v4fxdl8NzIuJLyGguTP
Xc0tRM34Lg==
-----END ENCRYPTED PRIVATE KEY-----
''');
