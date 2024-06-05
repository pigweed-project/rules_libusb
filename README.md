# rules_libusb

A small wrapper Bazel module that builds libusb from sources. Supports Windows,
macOS, and Linux.

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

Then add to the tool that requires libusb:
```
cc_binary(
    name = "my_tool",
    srcs = ["main.cpp"],
    deps = ["@libusb//:libusb_core"],  # Required for headers.
    dynamic_deps = ["@libusb//:libusb"],  # Link against shared lib.
)
```

Note: `source_release` constraints follow bzlmod behavior of minimal version
selection.

## Building this repo

To build this repo, run:
```
bazel build @libusb//:libusb
```
