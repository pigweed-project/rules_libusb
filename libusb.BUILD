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

load("@rules_cc//cc:cc_import.bzl", "cc_import")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_shared_library.bzl", "cc_shared_library")
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

alias(
    name = "libusb_dynamic",
    actual = ":libusb-1.0",
    visibility = ["//visibility:public"],
)

cc_shared_library(
    name = "libusb-1.0",
    # Always use exactly these names.
    shared_lib_name = select({
        "@platforms//os:macos": "libusb-1.0.dylib",
        "@platforms//os:windows": "libusb-1.0.dll",
        "//conditions:default": "libusb-1.0.so",
    }),
    visibility = ["//visibility:private"],
    win_def_file = select({
        "@platforms//os:windows": "libusb/libusb-1.0.def",
        "//conditions:default": None,
    }),
    deps = [":libusb_core"],
)

# This is needed for Windows to be able to properly link. If this
# is omitted, the .if.lib will never end up in the link invocation.
filegroup(
    name = "libusb_interface_lib",
    srcs = [":libusb-1.0"],
    output_group = "interface_library",
    visibility = ["//visibility:private"],
)

# This intermediate helper forces libusb to be dynamically linked.
cc_import(
    name = "libusb_force_dynamic",
    interface_library = ":libusb_interface_lib",
    shared_library = ":libusb_dynamic",
    visibility = ["//visibility:private"],
    deps = [
        ":libusb_config",
        ":libusb_headers",
    ],
)

cc_library(
    name = "libusb_core",
    srcs = glob(["libusb/*.c"]),
    linkopts = select({
        "@platforms//os:windows": [
            "-DEFAULTLIB:AdvAPI32.Lib",
            "-DEFAULTLIB:User32.Lib",
        ],
        "//conditions:default": [],
    }),
    target_compatible_with = select({
        "@platforms//os:linux": [],
        "@platforms//os:macos": [],
        "@platforms//os:windows": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    visibility = ["//visibility:private"],
    deps = select({
        "@platforms//os:linux": [":libusb_linux"],
        "@platforms//os:macos": [":libusb_macos"],
        "@platforms//os:windows": [":libusb_windows"],
        "//conditions:default": [],
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
    srcs = glob([
        "libusb/os/*_windows.c",
        "libusb/os/windows_*.c",
    ]),
    hdrs = glob([
        "libusb/os/*_windows.h",
        "libusb/os/windows_*.h",
    ]),
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

cc_library(
    name = "libusb_linux",
    srcs = glob(
        ["libusb/os/linux_*.c"],
        exclude = [
            "libusb/os/linux_netlink.c",
            "libusb/os/linux_udev.c",
        ],
    ) + select({
        "@rules_libusb//:use_udev": ["libusb/os/linux_udev.c"],
        "@rules_libusb//:use_netlink": ["libusb/os/linux_netlink.c"],
    }),
    hdrs = glob(["libusb/os/linux_*.h"]),
    # linux_netlink.c passes a buffer pointer (`unsigned char*`) to a function
    # expecting `char*`.
    copts = ["-Wno-pointer-sign"],
    linkopts = select({
        "@rules_libusb//:use_udev": ["-ludev"],
        # When using netlink, `-lnl` doesn't appear to be necessary (adding it
        # makes gcc complain the library can't be found).
        "//conditions:default": [],
    }),
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
