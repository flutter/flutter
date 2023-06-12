# Requirements for Linux

## Debian

### Dev Dependencies

[Flutter](https://docs.flutter.dev/get-started/install/linux#additional-linux-requirements) dependencies:

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

[GStreamer](https://gstreamer.freedesktop.org/documentation/installing/on-linux.html?gi-language=c):

```bash
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

### App Dependencies

Optional GStreamer Plugins (e.g. for `.m3u8`):

```bash
sudo apt-get install gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
```

## ArchLinux

For Arch, simply install gstreamer and its plugins via `pacman`:

```bash
sudo pacman -S gstreamer gst-libav gst-plugins-base gst-plugins-good
```

You can install additional plugins as needed following [the Wiki](https://wiki.archlinux.org/title/GStreamer).
