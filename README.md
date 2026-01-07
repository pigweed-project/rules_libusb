# rules_libusb

A small wrapper Bazel module that builds libusb from sources. Supports Windows,
macOS, and Linux.

This wrapper is maintained by [Pigweed](https://pigweed.dev/). Please file bug
reports at https://issues.pigweed.dev/.

## Getting Started

At this time, rules_libusb only supports bzlmod projects. Legacy `WORKSPACE`
projects are not explicitly supported.

### blzmod

Add rules_libusb to your `MODULE.bazel` file:
```
bazel_dep(name = "rules_libusb", version="0.1.0-rc1")

libusb = use_extension("@rules_libusb//:extensions.bzl", "libusb")
# Versioning constraints are optional.
libusb.source_release(min_version = "1.0.27")
use_repo(libusb, "libusb")
```

Note: `source_release` constraints follow bzlmod behavior of minimal version
selection.

Then add to the tool that requires libusb:
```
cc_binary(
    name = "my_tool",
    srcs = ["main.cpp"],
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
```
bazel build //... --@rules_libusb//:force_dynamic_linkage=False
```

When `@rules_libusb//:force_dynamic_linkage` is disabled, the link behavior is
fully controlled by your build system, and can be controlled on a per-binary
basis by specifying `dynamic_deps` on build targets that require dynamic
linkage of libusb:
```
cc_binary(
    name = "my_tool",
    srcs = ["main.cpp"],
    deps = ["@libusb//:libusb"],
    dynamic_deps = ["@libusb//:libusb_dynamic"],
)
```

## Building this repo

To build this repo, run:
```
bazel build @libusb//:libusb
```
