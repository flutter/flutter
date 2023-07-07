// @dart = 2.9
import 'dart:convert';
import 'dart:io';

main() async {
  var path = '/Users/scheglov/tmp/333/co19-20200310.json';
  var content = File(path).readAsStringSync();
  var resultList = json.decode(content) as List<Object>;

  var shouldBeFixed = 0;
  var nonFunctionalTypeAliases = 0;
  for (var resultObject in resultList) {
    var resultMap = resultObject as Map<String, Object>;
    var testName = resultMap['test_name'] as String;

    var logsList = resultMap['logs'] as List<Object>;
    var logMap = logsList.first as Map<String, Object>;
    var logLink = logMap['link'];
    var logContent = await _downloadLog(logLink);

    if (logContent.contains('nonfunction-type-aliases')) {
      print('$testName [nonfunction-type-aliases]');
      nonFunctionalTypeAliases++;
    } else {
      print(testName);
      shouldBeFixed++;
    }
  }
  print('');
  print('nonFunctionalTypeAliases: $nonFunctionalTypeAliases');
  print('shouldBeFixed: $shouldBeFixed');
}

Future<String> _downloadLog(String logLink) async {
  try {
    var logRequest = await HttpClient().getUrl(Uri.parse(logLink));
    var logResponse = await logRequest.close();
    return await logResponse.transform(utf8.decoder).single;
  } catch (e) {
    return '<Exception>';
  }
//  nonfunction-type-aliases
}
