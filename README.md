# rules_libusb

A small wrapper Bazel module that builds libusb from sources. Supports Windows,
macOS, and Linux.

This wrapper is maintained by [Pigweed](https://pigweed.dev/). Please file bug
reports at https://issues.pigweed.dev/.

## Getting Started

At this time, rules_libusb only supports bzlmod projects. Legacy `WORKSPACE`
projects are not explicitly supported.

### bzlmod

Add rules_libusb to your `MODULE.bazel` file:
```python
bazel_dep(name = "rules_libusb", version = "0.1.0-rc2")

libusb = use_extension("@rules_libusb//:extensions.bzl", "libusb")
# Versioning constraints are optional.
libusb.source_release(min_version = "1.0.30")
use_repo(libusb, "libusb")
```

Note: `source_release` constraints follow bzlmod behavior of minimal version
selection.

If you need to use a `libusb` release that is not yet listed in `versions.json`,
any module can supply additional version-to-SHA-256 mappings on
`libusb.source_release()` via `versions` (a dictionary mapping version strings
to SHA-256 digests) or `versions_file` (a JSON file with the same format as
`versions.json`). All supplied mappings across modules are merged before the
selected version is resolved:
```python
libusb.source_release(
    min_version = "1.0.30",
    versions = {
        "1.0.30": "fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf",
    },
)
```

Then add to the tool that requires libusb:
```python
cc_binary(
    name = "my_tool",
    srcs = ["main.cc"],
    deps = ["@libusb//:libusb"],
)
```

## Linking libusb

The libusb build file offers two targets to help guide link behavior:

* `//:libusb`: The generic `cc_library` for libusb. Most build targets should
  just use this.
* `//:libusb_dynamic`: The actual libusb dynamic/shared library (e.g.
  `libusb-1.0.so`).

By default, `@libusb//:libusb` will always dynamically link. This can be
disabled by toggling the flag that controls this:
```sh
bazelisk build //... --@rules_libusb//:force_dynamic_linkage=False
```

When `@rules_libusb//:force_dynamic_linkage` is disabled, the link behavior is
fully controlled by your build system, and can be controlled on a per-binary
basis by specifying `dynamic_deps` on build targets that require dynamic
linkage of libusb:
```python
cc_binary(
    name = "my_tool",
    srcs = ["main.cc"],
    deps = ["@libusb//:libusb"],
    dynamic_deps = ["@libusb//:libusb_dynamic"],
)
```

## Building and testing this repo

To build the libusb shared library directly, run:
```sh
bazelisk build @libusb//:libusb_dynamic
```

To build and run the example test in `examples/basic_usage`, run:
```sh
cd examples/basic_usage
bazelisk test //...
```

## Updating libusb versions

Release versions and SHA-256 digests are stored in `versions.json`. To fetch
new releases from GitHub and generate an updated `versions.json`, run:
```sh
bazelisk run //tools:update_versions
```
Then run the `cp` command printed in the output to update `versions.json` in
the workspace.
