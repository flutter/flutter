import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

class UploadError extends Error {
  UploadError(this.message);
  final String message;
  @override
  String toString() => message;
}

class Upload {
  Upload(this.fromPath, this.largeName, this.smallName);

  static math.Random random;
  static final String uriAuthority = 'www.googleapis.com';
  static final String uriPath = 'upload/storage/v1/b/flutter-catalog/o';

  final String fromPath;
  final String largeName;
  final String smallName;

  List<int> largeImage;
  List<int> smallImage;
  bool largeImageSaved;
  int retryCount = 0;
  bool isComplete = false;

  String get authorizationToken {
    return 'ya29.GltbBPbYSY0dwggdk0vCOSzWExNF37SbkjCfZt3XxkJktabF2rS9_Ui1taYBGtU9LdPuoRRXXVKczC-ohbjqn8zJdfL2MyhvDwFTd9FOZu3nrhBU5Bx-5q8O4MXL';
  }

  Duration get timeLimit {
    if (retryCount == 0)
      return const Duration(milliseconds: 1000);
    random ??= new math.Random();
    return new Duration(milliseconds: random.nextInt(1000) + math.pow(2, retryCount) * 1000);
  }

  Future<bool> save(HttpClient client, String name, List<int> content) async {
    try {
      final Uri uri = new Uri.https(uriAuthority, uriPath, {
        'uploadType': 'media',
        'name': name,
      });
      final HttpClientRequest request = await client.postUrl(uri);
      request
        ..headers.contentType = 'image/png'
        ..headers.add('Authorization', 'Bearer $authorizationToken')
        ..add(content);

      final HttpClientResponse response = await request.close().timeout(timeLimit);
      await response.drain<Null>();
      return response.statusCode == HttpStatus.OK;
    } on TimeoutException catch (_) {
      // TBD log a message about timing out
      return false;
    }
  }

  Future<bool> run(HttpClient client) async {
    assert(!isComplete);
    if (retryCount > 4)
      throw new UploadError('upload of "$fromPath" to "$largeName" and "$smallName" failed after 4 retries');

    largeImage ??= await new File(fromPath).readAsBytes();
    smallImage ??= encodePng(copyResize(decodePng(largeImage), 400));

    if (!largeImageSaved)
      largeImageSaved = await save(client, largeName, largeImage);
    isComplete = largeImageSaved && await save(client, smallName, smallImage);

    retryCount += 1;
    return isComplete;
  }

  static bool isNotComplete(Upload upload) => !upload.isComplete;
}

Future<Null> saveScreenshots(List<String> fromPaths, List<String> largeNames, List<String> smallNames) async {
  assert(fromPaths.length == toPaths.length);

  List<Upload> uploads = new List<Upload>(fromPaths.length);
  for (int index = 0; index < uploads.length; index += 1)
    uploads[index] = new Upload(fromPaths[index], largeNames[index], smallNames[index]);

  final HttpClient client = new HttpClient();
  while(uploads.any(Upload.isNotComplete)) {
    uploads = uploads.where(Upload.isNotComplete).toList();
    await Future.wait(uploads.map((Upload upload) => upload.run(client)));
  }

  client.close();
}
