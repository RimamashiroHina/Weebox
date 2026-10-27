# Weebox

Releases of Weebox, an anime streaming app for Windows and Android.

Download the latest version from the [Releases](../../releases/latest) page.

## Sources

Weebox comes empty: it hosts no video. Copy one of these links and paste it into the app (the
tutorial shown at first launch explains where), or later in Settings › Sources.

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
