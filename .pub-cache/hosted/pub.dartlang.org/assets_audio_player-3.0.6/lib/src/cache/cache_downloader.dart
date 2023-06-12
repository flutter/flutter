import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

class CacheDownloadInfos {
  const CacheDownloadInfos({
    required this.received,
    required this.total,
  });

  final int received;
  final int total;

  double get percent {
    if (total == 0) {
      return 0;
    } else {
      return received / total;
    }
  }
}

typedef CacheDownloadListener = Function(CacheDownloadInfos infos);

class _DownloadWaiter {
  _DownloadWaiter({this.downloadInfosListener});

  final Completer completer = Completer();
  final CacheDownloadListener? downloadInfosListener;

  void pingInfos(CacheDownloadInfos infos) {
    if (downloadInfosListener != null) {
      downloadInfosListener!(infos);
    }
  }
}

class CacheDownloader {
  final List<_DownloadWaiter> _waiters = [];

  void _dispose() {
    _waiters.clear();
  }

  Future<void> downloadAndSave({
    required String url,
    required String savePath,
    Map<String, String>? headers,
  }) async {
    final client = http.Client();
    final uri = Uri.parse(url);
    final request = http.Request('GET', uri);

    if (headers != null && headers.isNotEmpty) {
      request.headers.addAll(headers);
    }

    request.followRedirects = false;

    final response = client.send(request);

    final file = File(savePath);
    final raf = file.openSync(mode: FileMode.write);
    final responseChunk = <List<int>>[];
    var downloadedLength = 0;

    final completer = Completer();
    response.asStream().listen((http.StreamedResponse r) {
      r.stream.listen((List<int> chunk) {
        raf.writeFromSync(chunk);
        responseChunk.add(chunk);
        downloadedLength += chunk.length;
        final infos = CacheDownloadInfos(
          received: downloadedLength,
          total: r.contentLength ?? 0,
        );
        for (final waiter in _waiters) {
          waiter.pingInfos(infos);
        }
      }, onDone: () async {
        await raf.close();

        for (final waiter in _waiters) {
          waiter.completer.complete();
        }
        _dispose();

        completer.complete();
      }, onError: (dynamic e) {
        for (final waiter in _waiters) {
          waiter.completer.completeError(e);
        }
        _dispose();
        completer.completeError(e);
      });
    });

    await completer.future;
  }

  Future<String> wait(CacheDownloadListener downloadListener) async {
    final waiter = _DownloadWaiter(downloadInfosListener: downloadListener);
    _waiters.add(waiter);
    return await waiter.completer.future;
  }
}
