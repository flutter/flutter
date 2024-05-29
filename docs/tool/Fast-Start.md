# Fast Start

Fast Start is an experimental development for Flutter on Android that should startup faster on slower hardware. The APK used to install Flutter will only contain a minimal bootstrap application, which will require it to be rebuilt and reinstalled less frequently. This workflow may not work if you're using android_alarm_manager, or other plugins which start background isolates.

Fast start can be used by providing --fast-start as a command line option to flutter run. The first time this is used an APK must still be built, but on subsequent runs it will start up much faster. Note switching between --fast-start and regular development modes will still require the APK to be rebuilt.