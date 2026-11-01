# Weebox

Releases of Weebox, a free anime app for Windows, Android and Android TV: watch, read, and
share it all with your friends.

Download the latest version from the [Releases](../../releases/latest) page.

## Sources

Weebox hosts no video, and you have nothing to set up: when you open an anime, Weebox installs
the sources that have it, in your language (the 18+ ones only once 18+ is unlocked in Settings).
The same source lists are in the app's Store, added in one tap.

You can also add them by link, in Settings › Plugins:

| Source repository | Content | Link |
|---|---|---|
| Anix extensions (by [MaidLover69](https://github.com/MaidLover69/Anix), Anix's author) | Subtitles and dubs in English, Hindi, Spanish, Portuguese, French, German, Italian, Russian, Arabic, Indonesian, Turkish and more | https://anix-linux.vercel.app/extensions |
| Sources FR | French anime, VF and VOSTFR | https://drive.google.com/file/d/1mj_4l7ZpEQexcmdx4XhLv7VtaErJawbr/view?usp=sharing |
| Sources +18 | Adult catalogue (18+ only) | https://drive.google.com/file/d/1P351e7jv-g6JHq-M79G0Mzwp-OtF1jHy/view?usp=sharing |

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
