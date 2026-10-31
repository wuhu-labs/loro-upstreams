# loro-ffi-linux 1.17.1-linux.1

The Rust FFI library behind [loro-swift](https://github.com/loro-dev/loro-swift) built for Linux, which loro-swift's release (`loroFFI.xcframework`) covers only for Apple platforms. Consumers compile loro-swift's own `Sources/Loro` Swift files, unmodified, against this archive.

- Upstream: `https://github.com/loro-dev/loro-swift`, tag `1.17.1` (source sha `e222b3e1124e9e7e58e5e99658a3de75fcb0ec38` per its `release-artifact.json`), crate `loro-swift/` (loro-ffi 1.17.1, uniffi 0.31.1).
- `loro-swift/Cargo.lock` sha256 `662f7004709d3136cfea9073c6a85beebfe428a43fb3d708ad9eb132629ef106`, built with `--locked`.
- Toolchain: rustc 1.90.0 (1159e78c4 2025-09-14), target `x86_64-unknown-linux-gnu`, `cargo build --release --features cli`.
- `lib/libloro_swift.a`: the crate's staticlib, debug info stripped (`strip --strip-debug`).
- `include/loroFFI.h`: `uniffi-bindgen generate --language swift` from the same build; the Swift file it generates alongside is byte-identical to the tag's `Sources/Loro/LoroFFI.swift` after upstream's `scripts/refine_trait.sh`.
- `LICENSE`: Loro's MIT license, as in the upstream repository.
- `build.sh`: the exact recipe.
