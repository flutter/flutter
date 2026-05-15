# Flutter Embedder Engine GLFW Example
## Description
This is an example of how to use Flutter Engine Embedder in order to get a
Flutter project rendering in a new host environment.  The intended audience is
people who need to support host environment other than the ones already provided
by Flutter.  This is an advanced topic and not intended for beginners.

In this example we are demonstrating rendering a Flutter project inside of the GUI
library [GLFW](https://www.glfw.org/).  For more information about using the
embedder you can read the wiki article [Custom Flutter Engine Embedders](/docs/engine/Custom-Flutter-Engine-Embedders.md).

## Running Instructions

This example is built and tested on Linux. It uses GLFW with the Flutter
Engine's OpenGL ES embedder path, which is not enabled for macOS builds because
Metal is the recommended rendering API on macOS. The macOS dependency commands
below are useful if you are experimenting with an OpenGL-on-Metal layer such as
ANGLE or MoltenVK, or with a different Metal-backed embedder implementation, but
the example is not expected to build or run on macOS as-is.

The example has the following dependencies:
 * [GLFW](https://www.glfw.org/) - This can be installed with your system package manager, such as `sudo apt install libglfw3-dev` on Ubuntu or `brew install glfw` on macOS.
 * [CMake](https://cmake.org/) - This can be installed with your system package manager, such as `sudo apt install cmake` on Ubuntu or `brew install cmake` on macOS.
 * [Flutter](https://flutter.dev/) - This can be installed from the [Flutter webpage](https://docs.flutter.dev/get-started)
 * [Flutter Engine](https://flutter.dev) - This can be built or downloaded, see [Custom Flutter Engine Embedders](/docs/engine/Custom-Flutter-Engine-Embedders.md) for more information.

In order to **build** and **run** the example you should be able to go into this directory and run
`./run.sh`.

## Troubleshooting
There are a few things you might have to tweak in order to get your build working:
 * Flutter Engine Location - Inside the `CMakeList.txt` file you will see that it is set up to search for the header and library for the Flutter Engine in specific locations, those might not be the location of your Flutter Engine.
 * Pixel Ratio - If the project runs but is drawing at the wrong scale you may have to tweak the `kPixelRatio` variable in `FlutterEmbedderGLFW.cc` file.
 * GLFW Location - Inside the `CMakeLists.txt` we are searching for the GLFW library, if CMake can't find it you may have to edit that.
