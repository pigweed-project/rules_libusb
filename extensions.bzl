# Copyright 2026 The Pigweed Authors
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

"""Bzlmod module extension for fetching libusb release archives."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def version_parts(ver_string):
    """Converts version parts into a list of integers.

    Every version integer list will be four parts to ensure that release
    candidates are properly handled. Final releases are akin to a
    release candidate 9999999999.

    Args:
      ver_string: Version string to parse (e.g. "1.0.20" or "1.0.20-rc1").

    Returns:
      A 4-element list of integers representing the parsed version components.
    """
    parts = ver_string.split(".")
    if "-" in parts[-1]:
        rc = parts[-1].split("-")
        if len(rc) > 2:
            fail("Unknown version string format: {}".format(ver_string))
        parts[-1] = rc[0]
        parts.append(rc[1].lower().lstrip("rc"))
    else:
        parts.append(9999999999)
    return [int(p) for p in parts]

def _version_less_than(a, b):
    return version_parts(a) < version_parts(b)

def _add_release_hash(known_release_hashes, hash_sources, version, sha256, source):
    sha256 = sha256.removeprefix("sha256:")
    existing = known_release_hashes.get(version)
    if existing and existing != sha256:
        fail(
            "Conflicting SHA-256 hashes for libusb version {}: {} (from {}) vs {} (from {})".format(
                version,
                existing,
                hash_sources[version],
                sha256,
                source,
            ),
        )
    known_release_hashes[version] = sha256
    hash_sources[version] = source

def _libusb_impl(module_ctx):
    """Fetches libusb sources as requested by Bazel modules.

    Intended behavior:
        The minimum supported version is selected, per usual bzlmod behavior.

    Args:
      module_ctx: The module extension context.
    """
    default_versions_file = Label("@rules_libusb//:versions.json")
    known_release_hashes = {}
    hash_sources = {}
    for ver, sha in json.decode(module_ctx.read(default_versions_file)).items():
        _add_release_hash(
            known_release_hashes,
            hash_sources,
            ver,
            sha,
            str(default_versions_file),
        )

    min_versions = {}
    max_versions = {}
    for module in module_ctx.modules:
        for release in module.tags.source_release:
            if release.versions_file != None:
                custom_versions = json.decode(
                    module_ctx.read(release.versions_file),
                )
                for ver, sha in custom_versions.items():
                    _add_release_hash(
                        known_release_hashes,
                        hash_sources,
                        ver,
                        sha,
                        str(release.versions_file),
                    )
            for ver, sha in release.versions.items():
                _add_release_hash(
                    known_release_hashes,
                    hash_sources,
                    ver,
                    sha,
                    "module '{}' versions".format(module.name),
                )
            if release.min_version:
                if release.min_version not in min_versions:
                    min_versions[release.min_version] = []
                min_versions[release.min_version].append(module.name)
            if release.max_version:
                if release.max_version not in max_versions:
                    max_versions[release.max_version] = []
                max_versions[release.max_version].append(module.name)

    version_to_use = None
    for v in min_versions:
        if version_to_use == None or _version_less_than(version_to_use, v):
            version_to_use = v

    for v in max_versions:
        if _version_less_than(v, version_to_use):
            fail(
                "Minimum supported libusb version for {} is {} but {} require at most {}".format(
                    min_versions[version_to_use],
                    version_to_use,
                    max_versions[v],
                    v,
                ),
            )

    sha256 = known_release_hashes.get(version_to_use, None)
    if not sha256:
        fail(
            "libusb version {} has no pinned SHA-256; specify `versions` in `libusb.source_release()`".format(
                version_to_use,
            ),
        )

    http_archive(
        name = "libusb",
        urls = [
            "https://github.com/libusb/libusb/releases/download/v{}/libusb-{}.tar.bz2".format(
                version_to_use,
                version_to_use,
            ),
        ],
        build_file = "@rules_libusb//:libusb.BUILD",
        strip_prefix = "libusb-{}".format(version_to_use),
        sha256 = sha256,
    )

libusb = module_extension(
    doc = "Bzlmod extension for pulling in libusb sources.",
    implementation = _libusb_impl,
    tag_classes = {
        "source_release": tag_class(
            doc = "Controls the source code version to use when building libusb.",
            attrs = {
                "min_version": attr.string(
                    doc = "Minimum supported version of libusb required.",
                ),
                "max_version": attr.string(
                    doc = "Maximum supported version of libusb required.",
                ),
                "versions": attr.string_dict(
                    doc = "Optional mapping of libusb version strings to SHA-256 digests, allowing consumers to supply hashes for releases not yet listed in `versions.json`.",
                ),
                "versions_file": attr.label(
                    allow_single_file = True,
                    doc = "Optional JSON file mapping libusb version strings to SHA-256 digests.",
                ),
            },
        ),
    },
)
