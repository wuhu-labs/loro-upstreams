#!/usr/bin/env bash
# Builds loro-ffi-linux for x86_64-unknown-linux-gnu from loro-swift's own
# Rust crate, at the tag whose Sources/Loro Swift bindings consume it.
set -euxo pipefail
TAG=1.17.1
RUST=1.90.0
TARGET=x86_64-unknown-linux-gnu
WORK="$(mktemp -d)"
cd "$WORK"
if ! command -v rustup >/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain "$RUST" --no-modify-path
  export PATH="$HOME/.cargo/bin:$PATH"
fi
rustup toolchain install "$RUST" --profile minimal
mkdir src
curl -sSL "https://github.com/loro-dev/loro-swift/archive/refs/tags/$TAG.tar.gz" | tar xz -C src --strip-components=1
cd src/loro-swift
cargo "+$RUST" build --locked --release --features cli --target "$TARGET"
OUT="target/$TARGET/release"
"$OUT/uniffi-bindgen" generate --library "$OUT/libloro_swift.so" --no-format --language swift --out-dir "$WORK/gen"
mkdir -p "$WORK/loro-ffi-linux/lib" "$WORK/loro-ffi-linux/include"
cp "$OUT/libloro_swift.a" "$WORK/loro-ffi-linux/lib/"
strip --strip-debug "$WORK/loro-ffi-linux/lib/libloro_swift.a"
cp "$WORK/gen/loroFFI.h" "$WORK/loro-ffi-linux/include/"
cp ../LICENSE "$WORK/loro-ffi-linux/LICENSE"
echo "$WORK/loro-ffi-linux"
