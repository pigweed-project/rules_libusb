# Copyright 2024 The Pigweed Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@rules_license//rules:license.bzl", "license")

package(
    default_applicable_licenses = [":license"],
    default_visibility = ["//visibility:private"],
)

license(
    name = "license",
    package_name = "libusb",
    license_kinds = ["@rules_license//licenses/spdx:LGPL-2.1"],
    license_text = "COPYING",
)

alias(
    name = "libusb",
    actual = select({
        "@rules_libusb//:force_dynamic_linkage_enabled": ":libusb_force_dynamic",
        "//conditions:default": ":libusb_core",
    }),
    visibility = ["//visibility:public"],
)

cc_shared_library(
    name = "libusb_dynamic",
    # Always use exactly these names.
    shared_lib_name = select({
        "@platforms//os:macos": "libusb-1.0.dylib",
        "@platforms//os:windows": "libusb-1.0.dll",
        "//conditions:default": "libusb-1.0.so",
    }),
    visibility = ["//visibility:public"],
    win_def_file = select({
        "@platforms//os:windows": "libusb/libusb-1.0.def",
        "//conditions:default": None,
    }),
    deps = [":libusb_core"],
)

# This intermediate helper forces libusb to be dynamically linked.
cc_library(
    name = "libusb_force_dynamic",
    srcs = [":libusb_dynamic"],
    visibility = ["//visibility:private"],
    deps = [
        ":libusb_config",
        ":libusb_headers",
    ],
)

cc_library(
    name = "libusb_core",
    srcs = glob(["libusb/*.c"]),
    visibility = ["//visibility:private"],
    deps = select({
        "@platforms//os:linux": [":libusb_linux"],
        "@platforms//os:macos": [":libusb_macos"],
        "@platforms//os:windows": [":libusb_windows"],
        "//conditions:default": ["@platforms//:incompatible"],
    }) + [
        ":libusb_config",
        ":libusb_headers",
    ],
)

label_flag(
    name = "libusb_config",
    build_setting_default = "@rules_libusb//:default_libusb_config",
)

# To use this `config.h`, include it as `msvc/config.h` from your actual
# `config.h`.
cc_library(
    name = "libusb_msvc_config",
    hdrs = ["msvc/config.h"],
    visibility = ["//visibility:public"],
)

# To use this `config.h`, include it as `Xcode/config.h` from your actual
# `config.h`.
cc_library(
    name = "libusb_macos_config",
    hdrs = ["Xcode/config.h"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "libusb_headers",
    hdrs = glob(["libusb/*.h"]),
    includes = ["libusb"],
    visibility = ["//visibility:private"],
    deps = [":libusb_config"],
)

cc_library(
    name = "libusb_windows",
    srcs = glob(["libusb/os/*_windows.c"]),
    hdrs = glob(["libusb/os/*_windows.h"]),
    visibility = ["//visibility:private"],
    deps = [
        ":libusb_config",
        ":libusb_headers",
    ],
)

cc_library(
    name = "libusb_posix",
    srcs = glob(["libusb/os/*_posix.c"]),
    hdrs = glob(["libusb/os/*_posix.h"]),
    visibility = ["//visibility:private"],
    deps = [
        ":libusb_config",
        ":libusb_headers",
    ],
)

# TODO: Consider upstreaming a build-system-independent method for detecting
# udev vs netlink.
_GENERATED_UDEV_OR_NETLINK = """
#include "config.h"

#if HAVE_LIBUDEV
#include "libusb/os/linux_udev.c"
#else
#include "libusb/os/linux_netlink.c"
#endif  // HAVE_LIBUDEV
"""

genrule(
    name = "autodetect_udev",
    outs = ["udev_or_netlink.c"],
    cmd = "echo '{}' > $@".format(_GENERATED_UDEV_OR_NETLINK),
)

cc_library(
    name = "libusb_linux",
    srcs = glob(
        ["libusb/os/linux_*.c"],
        exclude = [
            "libusb/os/linux_netlink.c",
            "libusb/os/linux_udev.c",
        ],
    ) + [
        "udev_or_netlink.c",
    ],
    hdrs = glob(["libusb/os/linux_*.h"]) + [
        # These are listed as `hdrs` because they're selected by
        # an `#include` in the generated `udev_or_netlink.c`.
        "libusb/os/linux_netlink.c",
        "libusb/os/linux_udev.c",
    ],
    visibility = ["//visibility:private"],
    deps = [
        ":libusb_config",
        ":libusb_headers",
        ":libusb_posix",
    ],
)

cc_library(
    name = "libusb_macos",
    srcs = glob(["libusb/os/darwin_*.c"]),
    hdrs = glob(["libusb/os/darwin_*.h"]),
    linkopts = [
        "-framework CoreFoundation",
        "-framework IOKit",
        "-framework Security",
    ],
    visibility = ["//visibility:private"],
    deps = [
        ":libusb_config",
        ":libusb_headers",
        ":libusb_posix",
    ],
)
