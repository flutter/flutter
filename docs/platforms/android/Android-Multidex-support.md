# Dex Overview

Android apps are compiled into .dex (dalvik executable) files that run on the Dalvik virtual machine. Before Android API 21, apps compiled into a single .dex file, which has the limitation of only supporting 64k method names. This means that larger apps frequently exceed this limit, thus requiring enabling  "Multidex" support (see [https://android-doc.github.io/tools/building/multidex.html](https://android-doc.github.io/tools/building/multidex.html) for more details).

In Flutter applications, it is easy to exceed the single dex limit primarily through using plugins. Thus, even small apps may occasionally exceed the limit by importing a full suite of standard Google plugins. Even though unused methods are stripped from releases, the dex limit can still prevent apps from building.

# Multidex support

Flutter supports automatic multidex error detection and support for apps targeting API 20 and below. When apps fail to build due to the multidex error, Flutter will automatically prompt the user if multidex support should be enabled. Answering yes will add support and subsequent builds in the future will build with multidex support enabled.

You may pass the `--no-multidex` flag to temporarily disable multidex support during a build.

# API 21+

Apps that target API 21+ devices already have multidex natively supported. However, we do not recommend targeting API 21+ purely to resolve the multidex issue as this may inadvertently exclude potential users running older devices.