sed -i.bak -e 's/ToolContext get toolContext => super.toolContext;/ToolContext get toolContext => super.toolContext!;/g' packages/flutter_tools/lib/src/commands/emulators.dart
sed -i.bak -e 's/globals.doctor.workflows/globals.doctor!.workflows/g' packages/flutter_tools/lib/src/commands/emulators.dart
sed -i.bak -e 's/emulatorManager.getEmulatorsMatching/emulatorManager!.getEmulatorsMatching/g' packages/flutter_tools/lib/src/commands/emulators.dart
sed -i.bak -e 's/emulatorManager.createEmulator/emulatorManager!.createEmulator/g' packages/flutter_tools/lib/src/commands/emulators.dart
sed -i.bak -e 's/emulatorManager.getAllAvailableEmulators/emulatorManager!.getAllAvailableEmulators/g' packages/flutter_tools/lib/src/commands/emulators.dart
# Add context.dart import if missing for testUsingContext and Generator
if ! grep -q "src/context.dart" packages/flutter_tools/test/commands.shard/hermetic/emulators_test.dart; then
    sed -i.bak '/import '"'"'..\/..\/src\/common.dart'"'"';/a import '"'"'..\/..\/src\/context.dart'"'"';' packages/flutter_tools/test/commands.shard/hermetic/emulators_test.dart
fi
