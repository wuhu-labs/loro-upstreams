# loro-upstreams

Prebuilt [Loro](https://github.com/loro-dev/loro) FFI libraries for platforms that [loro-swift](https://github.com/loro-dev/loro-swift)'s own release does not cover. Each release is one archive built from an exact upstream tag with the recipe in this repository; its `PROVENANCE.md` records the upstream tag, lockfile hash and toolchain.

- `linux/`: `libloro_swift.a` + `loroFFI.h` for `x86_64-unknown-linux-gnu`, to compile loro-swift's unmodified `Sources/Loro` on Linux. Releases `<loro-swift tag>-linux.<n>`. Superseded by `rust-ffi/`.
- `rust-ffi/`: `libwuhu_rust_ffi.a`, loro-swift's FFI and Wasmtime's C API in one staticlib with one Rust std, plus `loroFFI.h` and Wasmtime's headers, for `x86_64-unknown-linux-gnu` and `aarch64-apple-darwin`. Two Rust staticlibs cannot share a binary (both define `rust_eh_personality`). The `rust-ffi` workflow builds both archives with `rust-ffi/build.sh`, which also checks them against the upstream artifacts they replace; its artifacts are uploaded as release `rust-ffi-<loro-swift tag>-<wasmtime version>-<n>`.

Loro is MIT licensed (`LICENSE-loro`), Wasmtime Apache-2.0 WITH LLVM-exception; every archive carries its licenses.
