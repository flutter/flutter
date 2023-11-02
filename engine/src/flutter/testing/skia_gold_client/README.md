# skia_gold_client

This package allows to create a Skia gold client in the engine repo.

The client uses the `goldctl` tool on LUCI builders to upload screenshots,
and verify if a new screenshot matches the baseline screenshot.

The web UI is available on https://flutter-engine-gold.skia.org/.

## Using the client

1. In `.ci.yaml`, ensure that the task has a dependency on `goldctl`:

```yaml
  dependencies: [{"dependency": "goldctl"}]
```

2. In the builder `.json` file, ensure the drone has a dependency on `goldctl`:

```yaml
            "dependencies": [
                {
                    "dependency": "goldctl",
                    "version": "git_revision:<sha>"
                }
            ],
```

3. Add dependency in `pubspec.yaml`:

```yaml
dependencies:
  # needed for skia_gold_client to avoid a cache miss.
  engine_repo_tools:
    path: <relative-path>/tools/pkg/engine_repo_tools
  skia_gold_client:
    path: <relative-path>/testing/skia_gold_client
```

4. Use the client:

```dart
import 'package:skia_gold_client/skia_gold_client.dart';

Future<void> main() {
    final Directory tmpDirectory = Directory.current.createTempSync('skia_gold_wd');
    final SkiaGoldClient client = SkiaGoldClient(
        tmpDirectory,
        dimensions: <String, String> {'<attribute-name>': '<attribute-value>'},
    );

    try {
        if (isSkiaGoldClientAvailable) {
            await client.auth();

            await client.addImg(
                '<file-name>',
                File('gold-file.png'),
                screenshotSize: 1024,
            );
        }
    } catch (error) {
        // Failed to authenticate or compare pixels.
        stderr.write(error.toString());
        rethrow;
    } finally {
        tmpDirectory.deleteSync(recursive: true);
    }
}
```
