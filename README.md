# Weebox

Releases of Weebox, an anime streaming app for Windows and Android.

Download the latest version from the [Releases](../../releases/latest) page.

## Video player libraries (LGPL)

On Android, Weebox plays video with [libmpv](https://mpv.io) and [FFmpeg](https://ffmpeg.org),
loaded as separate, replaceable shared libraries. They are built here, from
[mpv-android](https://github.com/mpv-android/mpv-android)'s own build scripts at a pinned commit,
with two changes only (see [`android-libmpv/build.sh`](android-libmpv/build.sh)):

- FFmpeg is configured with `--enable-version3` and without `--enable-gpl`: it is under the
  **LGPL v3 or later**.
- mpv is configured with `-Dgpl=false`: libmpv is under the **LGPL v2.1 or later**.

The build refuses its result if either still reports GPL. Each release that ships these
libraries also carries the exact corresponding source (`source.tar.xz`: build scripts, patch and
every source tree) and the list of versions and checksums (`MANIFEST.txt`).

To rebuild them: run the **libmpv Android (LGPL)** workflow, or `bash android-libmpv/build.sh`
on Linux.
