#!/usr/bin/env bash
# Builds wuhu-rust-ffi for one target: loro-swift's Rust FFI and Wasmtime's C
# API in one staticlib with one Rust std. Usage: build.sh <rust target> <out dir>.
# Checks the result against the upstream artifacts it replaces: the same Loro
# header as loro-swift's xcframework, the same Wasmtime include tree as
# upstream's prebuilt C API, and every C API symbol of both upstream libraries.
set -euxo pipefail
umask 022
TARGET=$1
OUT=$2
LORO=1.17.1
WASMTIME=50.0.1
REVISION=1
RUST=1.99.0
case "$TARGET" in
  x86_64-unknown-linux-gnu)
    ASSET=x86_64-linux-gnu
    UPSTREAM=x86_64-linux
    UPSTREAM_SHA=e2c0c26e1aef52f82f0b9918ad6f34cc30f4b557aee3e261cb127a9462be8f4d
    ;;
  aarch64-apple-darwin)
    ASSET=aarch64-apple-darwin
    UPSTREAM=aarch64-macos
    UPSTREAM_SHA=a49327ca596fae51cd92e230265132112bb7896c5a24e4d58cd05b56612e26bb
    ;;
  *) echo "unsupported target $TARGET" >&2; exit 1 ;;
esac
LORO_SLICE=macos-arm64_x86_64
LORO_LINUX_SHA=d427995a994c28991c75e53b5201570a1ce8499f8bd46381bbad1cc502757e5f
XCFRAMEWORK_SHA=f2d172602cf43e0667d57067d5c8a93650ee0bc91139cce6aced8f469352daaf
NAME="wuhu-rust-ffi-$LORO-$WASMTIME-$REVISION-$ASSET"
SRC="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
fetch() { curl -sSfL -o "$2" "$1"; echo "$3  $2" | sha256 -c -; }
# Apple's nm cannot parse the compiler_builtins bitcode in Rust staticlibs and
# exits 1 after listing every other member.
symbols() { nm -g "$1" 2>/dev/null || true; }
# Global defined text symbols of the C API surfaces, without Mach-O's leading
# underscore; grep fails the build on a library that yields none.
api_symbols() {
  local lib
  for lib in "$@"; do
    symbols "$lib" | awk '$2 == "T" { sub(/^_/, "", $3); print $3 }' | grep -E '^(wasm|wasi|uniffi_|ffi_loro)'
  done | sort -u
}

if ! command -v rustup >/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain "$RUST" --no-modify-path
  export PATH="$HOME/.cargo/bin:$PATH"
fi
rustup toolchain install "$RUST" --profile minimal --target "$TARGET"
command -v cmake

cd "$SRC"
cargo "+$RUST" build --locked --release -p wuhu-rust-ffi --target "$TARGET"
LIB="target/$TARGET/release/libwuhu_rust_ffi.a"
cargo "+$RUST" run --locked --release -p uniffi-bindgen -- generate --library "$LIB" --no-format --language swift --out-dir "$WORK/gen"
INCLUDE=$(find "target/$TARGET/release/build" -path '*/wasmtime-c-api-impl-*/out/include' -type d)
test "$(echo "$INCLUDE" | wc -l)" -eq 1

DIST="$WORK/wuhu-rust-ffi"
mkdir -p "$DIST/lib"
cp "$LIB" "$DIST/lib/"
case "$TARGET" in
  *-linux-*) strip --strip-debug "$DIST/lib/libwuhu_rust_ffi.a" ;;
  *-apple-*) strip -S "$DIST/lib/libwuhu_rust_ffi.a" ;;
esac
cp -R "$INCLUDE" "$DIST/include"
# The crate's conf.h.in has CRLF endings; upstream's installed conf.h has LF.
sed 's/\r$//' "$DIST/include/wasmtime/conf.h" > "$WORK/conf.h"
mv "$WORK/conf.h" "$DIST/include/wasmtime/conf.h"
cp "$WORK/gen/loroFFI.h" "$DIST/include/"
cp ../LICENSE-loro "$DIST/LICENSE-loro"
mkdir -p "$DIST/recipe"
cp -R build.sh Cargo.toml Cargo.lock src uniffi-bindgen "$DIST/recipe/"

cd "$WORK"
fetch "https://github.com/bytecodealliance/wasmtime/releases/download/v$WASMTIME/wasmtime-v$WASMTIME-$UPSTREAM-c-api.tar.xz" wasmtime.tar.xz "$UPSTREAM_SHA"
tar xJf wasmtime.tar.xz
UP="wasmtime-v$WASMTIME-$UPSTREAM-c-api"
cp "$UP/LICENSE" "$DIST/LICENSE-wasmtime"
fetch "https://github.com/loro-dev/loro-swift/releases/download/$LORO/loroFFI.xcframework.zip" loro.zip "$XCFRAMEWORK_SHA"
unzip -q loro.zip
cmp "loroFFI.xcframework/$LORO_SLICE/Headers/loroFFI/loroFFI.h" "$DIST/include/loroFFI.h"
diff -r "$UP/include" "$DIST/include" -x loroFFI.h
# The Loro library this one replaces: our own Linux build, or the xcframework's.
case "$TARGET" in
  *-linux-*)
    fetch "https://github.com/wuhu-labs/loro-upstreams/releases/download/$LORO-linux.1/loro-ffi-$LORO-linux.1-x86_64-linux-gnu.tar.gz" loro-linux.tar.gz "$LORO_LINUX_SHA"
    tar xzf loro-linux.tar.gz
    LORO_LIB=loro-ffi-linux/lib/libloro_swift.a
    LORO_REF="loro-upstreams \`$LORO-linux.1\` (sha256 \`$LORO_LINUX_SHA\`)"
    ;;
  *-apple-*)
    lipo -thin arm64 "loroFFI.xcframework/$LORO_SLICE/libloro_swift.a" -output loro-thin.a
    LORO_LIB=loro-thin.a
    LORO_REF="loro-swift $LORO's \`loroFFI.xcframework\` \`$LORO_SLICE\` (sha256 \`$XCFRAMEWORK_SHA\`)"
    ;;
esac
api_symbols "$UP/lib/libwasmtime.a" "$LORO_LIB" > expected.syms
api_symbols "$DIST/lib/libwuhu_rust_ffi.a" > actual.syms
comm -23 expected.syms actual.syms > missing.syms
test ! -s missing.syms
test "$(symbols "$DIST/lib/libwuhu_rust_ffi.a" | grep -c ' T _\{0,1\}rust_eh_personality$')" -eq 1

cp "$SRC/PROVENANCE.md" "$DIST/PROVENANCE.md"
{
  echo
  echo "## This build"
  echo
  echo "- Target \`$TARGET\`, \`$(uname -srm)\`."
  echo "- \`$(rustc "+$RUST" -V)\`, \`$(cmake --version | head -1)\`."
  echo "- \`Cargo.lock\` sha256 \`$(sha256 "$SRC/Cargo.lock" | cut -d' ' -f1)\`."
  echo "- \`lib/libwuhu_rust_ffi.a\` sha256 \`$(sha256 "$DIST/lib/libwuhu_rust_ffi.a" | cut -d' ' -f1)\`."
  echo "- $(wc -l < actual.syms | tr -d ' ') C API symbols, covering all $(wc -l < expected.syms | tr -d ' ') of upstream \`$UP\` \`libwasmtime.a\` (sha256 \`$UPSTREAM_SHA\`) plus \`libloro_swift.a\` of $LORO_REF; \`loroFFI.h\` is byte-identical to the xcframework's and \`include/\` otherwise to upstream's."
} >> "$DIST/PROVENANCE.md"

mkdir -p "$OUT"
tar czf "$OUT/$NAME.tar.gz" wuhu-rust-ffi
sha256 "$OUT/$NAME.tar.gz"
