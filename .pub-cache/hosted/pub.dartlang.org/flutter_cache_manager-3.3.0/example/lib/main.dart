import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:example/plugin_example/download_page.dart';
import 'package:example/plugin_example/floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() {
  runApp(BaseflowPluginExample(
    pluginName: 'Flutter Cache Manager',
    githubURL: 'https://github.com/Baseflow/flutter_cache_manager',
    pubDevURL: 'https://pub.dev/packages/flutter_cache_manager',
    pages: [CacheManagerPage.createPage()],
  ));
  CacheManager.logLevel = CacheManagerLogLevel.verbose;
}

const url = 'https://blurha.sh/assets/images/img1.jpg';

/// Example [Widget] showing the functionalities of flutter_cache_manager
class CacheManagerPage extends StatefulWidget {
  const CacheManagerPage({Key key}) : super(key: key);

  static ExamplePage createPage() {
    return ExamplePage(Icons.save_alt, (context) => const CacheManagerPage());
  }

  @override
  _CacheManagerPageState createState() => _CacheManagerPageState();
}

class _CacheManagerPageState extends State<CacheManagerPage> {
  Stream<FileResponse> fileStream;

  void _downloadFile() {
    setState(() {
      fileStream = DefaultCacheManager().getFileStream(url, withProgress: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (fileStream == null) {
      return Scaffold(
        appBar: null,
        body: const ListTile(
            title: Text('Tap the floating action button to download.')),
        floatingActionButton: Fab(
          downloadFile: _downloadFile,
        ),
      );
    }
    return DownloadPage(
      fileStream: fileStream,
      downloadFile: _downloadFile,
      clearCache: _clearCache,
      removeFile: _removeFile,
    );
  }

  void _clearCache() {
    DefaultCacheManager().emptyCache();
    setState(() {
      fileStream = null;
    });
  }

  void _removeFile() {
    DefaultCacheManager().removeFile(url).then((value) {
      //ignore: avoid_print
      print('File removed');
    }).onError((error, stackTrace) {
      //ignore: avoid_print
      print(error);
    });
    setState(() {
      fileStream = null;
    });
  }
}
