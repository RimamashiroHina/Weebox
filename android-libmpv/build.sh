#!/bin/bash
# Builds the LGPL libmpv + FFmpeg that Weebox ships on Android (arm64-v8a), with mpv-android's
# own build scripts at a pinned commit and two changes only:
#   - FFmpeg: --enable-version3 without --enable-gpl  (FFmpeg under LGPL v3)
#   - mpv:    -Dgpl=false                             (libmpv under LGPL v2.1+)
# The result is refused if either still reports GPL, or if a library is not aligned for 16 KB
# pages. Output: out/lib (the libraries), out/MANIFEST.txt, and out/source.tar.xz, the
# corresponding source of everything in out/lib (build scripts, patches and all sources).
set -euo pipefail

MPV_ANDROID_REPO=https://github.com/mpv-android/mpv-android
# Release 2026-09-17 of mpv-android.
MPV_ANDROID_COMMIT=fdf74f6830c47dbaa8a22ac79726e8303f1db5af

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="${WORK:-$here/work}"
out="${OUT:-$here/out}"
rm -rf "$out"
mkdir -p "$work" "$out/lib"

if [ ! -d "$work/mpv-android" ]; then
	git clone "$MPV_ANDROID_REPO" "$work/mpv-android"
fi
cd "$work/mpv-android"
git checkout --quiet "$MPV_ANDROID_COMMIT"
git reset --quiet --hard
cd buildscripts

# --- the LGPL changes, each checked to apply exactly once
replace() { # file old new
	local count
	count=$(grep -cF -- "$2" "$1" || true)
	[ "$count" = 1 ] || { echo "Expected one '$2' in $1, found $count" >&2; exit 1; }
	sed -i "s|$(printf '%s' "$2" | sed 's/[][\.*^$|]/\\&/g')|$3|" "$1"
}
replace scripts/ffmpeg.sh '--enable-{gpl,version3}' '--enable-version3'
replace scripts/mpv.sh '-Dlibmpv=true -Dcplayer=false' '-Dlibmpv=true -Dcplayer=false -Dgpl=false'
git diff > "$out/lgpl.patch"

# --- toolchain and sources (FFmpeg at mpv-android's CI tag, the rest as its scripts fetch them)
if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ] && [ ! -e sdk/android-sdk-linux ]; then
	mkdir -p sdk
	ln -s "$ANDROID_HOME" sdk/android-sdk-linux
fi
IN_CI=1 ./include/download-sdk.sh
IN_CI=1 ./include/download-deps.sh

# --- build (dependencies, FFmpeg, then libmpv) for arm64
./buildall.sh --arch arm64 mpv

prefix="$PWD/prefix/arm64"
. ./include/depinfo.sh
ndk="$PWD/sdk/android-ndk-$v_ndk"
readelf="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"

# --- licence checks
grep -q '^#define CONFIG_GPL 0$' deps/ffmpeg/_build_arm64/config.h || { echo "FFmpeg was configured as GPL" >&2; exit 1; }
grep -q '^#define CONFIG_NONFREE 0$' deps/ffmpeg/_build_arm64/config.h || { echo "FFmpeg was configured as nonfree" >&2; exit 1; }
grep -q '^#define HAVE_GPL 0$' deps/mpv/_build_arm64/config.h || { echo "mpv was configured as GPL" >&2; exit 1; }

# --- the libraries: libmpv, what it needs from the prefix, and the NDK's C++ runtime
cp -L "$prefix/lib/libmpv.so" "$out/lib/"
for lib in libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale; do
	cp -L "$prefix/lib/$lib.so" "$out/lib/"
done
cp -L "$ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "$out/lib/"
# Debug information is not shipped (mpv-android builds FFmpeg with --disable-stripping).
for so in "$out"/lib/*.so; do
	"$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" --strip-debug "$so"
done
# Every library a shipped one needs must be shipped too, or be part of Android.
system_libs='libc.so libm.so libdl.so liblog.so libandroid.so libEGL.so libGLESv2.so libGLESv3.so libOpenSLES.so libmediandk.so libz.so libvulkan.so libaaudio.so'
for so in "$out"/lib/*.so; do
	for need in $("$readelf" -d "$so" | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p'); do
		if [ ! -f "$out/lib/$need" ] && ! grep -qw -- "$need" <<<"$system_libs"; then
			echo "$(basename "$so") needs $need, which is not shipped" >&2
			exit 1
		fi
	done
	# 16 KB pages: every LOAD segment aligned to at least 0x4000.
	for align in $("$readelf" -lW "$so" | awk '$1=="LOAD" { print $NF }'); do
		if (( align < 16384 )); then
			echo "$(basename "$so") is not aligned for 16 KB pages ($align)" >&2
			exit 1
		fi
	done
done
strings "$out/lib/libavcodec.so" | grep -q 'LGPL version 3 or later' || { echo "libavcodec does not report LGPL v3" >&2; exit 1; }

# --- what went in
{
	echo "mpv-android $MPV_ANDROID_REPO @ $MPV_ANDROID_COMMIT (+ lgpl.patch)"
	echo "NDK $v_ndk ($v_ndk_n)"
	for dep in deps/*/; do
		name=$(basename "$dep")
		if [ -d "$dep/.git" ]; then
			echo "$name $(git -C "$dep" describe --tags --always 2>/dev/null) $(git -C "$dep" rev-parse HEAD)"
		fi
	done
	echo "mbedtls $v_mbedtls, freetype $v_freetype, fribidi $v_fribidi, harfbuzz $v_harfbuzz, unibreak $v_unibreak, libxml2 $v_libxml2, fontconfig $v_fontconfig, lua $v_lua, curl $v_curl"
	echo
	echo "FFmpeg licence: $(strings "$out/lib/libavcodec.so" | grep -m1 'LGPL version')"
	echo "mpv: $(grep -m1 'HAVE_GPL' deps/mpv/_build_arm64/config.h)"
	echo
	(cd "$out/lib" && sha256sum *.so)
} > "$out/MANIFEST.txt"

# --- corresponding source: the patched build scripts and every source tree, without build dirs
cd "$work"
tar --exclude='_build*' --exclude='.git' --exclude='mpv-android/buildscripts/sdk' \
	--exclude='mpv-android/buildscripts/prefix' -cJf "$out/source.tar.xz" mpv-android
cp "$here/build.sh" "$out/"
echo "Done:"
cat "$out/MANIFEST.txt"
