load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# This just silences warnings about canonical reproducible forms.
_KNOWN_RELEASE_HASHES = {
    "1.0.20-rc1": "914c4c66f4d6582fb19afc92aa8274f11e0745a93a02593e3bcc2ee7c6048e23",
    "1.0.20": "cb057190ba0a961768224e4dc6883104c6f945b2bf2ef90d7da39e7c1834f7ff",
    "1.0.21": "7dce9cce9a81194b7065ee912bcd55eeffebab694ea403ffb91b67db66b1824b",
    "1.0.22": "75aeb9d59a4fdb800d329a545c2e6799f732362193b465ea198f2aa275518157",
    "1.0.23": "db11c06e958a82dac52cf3c65cb4dd2c3f339c8a988665110e0d24d19312ad8d",
    "1.0.24": "7efd2685f7b327326dcfb85cee426d9b871fd70e22caa15bb68d595ce2a2b12a",
    "1.0.25": "8a28ef197a797ebac2702f095e81975e2b02b2eeff2774fa909c78a74ef50849",
    "1.0.26": "12ce7a61fc9854d1d2a1ffe095f7b5fac19ddba095c259e6067a46500381b5a5",
    "1.0.27": "ffaa41d741a8a3bee244ac8e54a72ea05bf2879663c098c82fc5757853441575",
}

def _version_parts(ver_string):
    """Converts version parts into a list of integers.

    Every version integer list will be four parts to ensure that release
    candidates are properly handled. Final releases are akin to a
    release candidate 9999999999.
    """
    parts = ver_string.split(".")
    if "-" in parts[-1]:
        rc = parts[-1].split("-")
        if len(rc) > 2:
            fail("Unknown version string format:", ver_string)
        parts[-1] = rc[0]
        parts.append(rc[1].lower().lstrip("rc"))
    else:
        parts.append(9999999999)
    return [int(p) for p in parts]

def _version_less_than(a, b):
    a_parts = _version_parts(a)
    b_parts = _version_parts(b)
    for i in range(len(a_parts)):
        if a_parts[i] == b_parts[i]:
            continue
        return a_parts[i] < b_parts[i]

    # Must be equal.
    return False

def _libusb_impl(module_ctx):
    """ Fetches libusb sources as requested by Bazel modules.

    Intended behavior:
        The minimum supported version is selected, per usual bzlmod behavior.
    """
    root_module = True
    min_versions = {}
    max_versions = {}
    for module in module_ctx.modules:
        for release in module.tags.source_release:
            if release.min_version:
                if release.min_version not in min_versions:
                    min_versions[release.min_version] = []
                min_versions[release.min_version].append(module.name)
            if release.max_version:
                if release.max_version not in max_versions:
                    max_versions[release.max_version] = []
                max_versions[release.max_version].append(module.name)

    version_to_use = None
    for v, m in min_versions.items():
        if version_to_use == None or _version_less_than(version_to_use, v):
            version_to_use = v

    for v, m in max_versions.items():
        if _version_less_than(v, version_to_use):
            fail("Minimum supported libusb version for", min_versions[version_to_use], "is", version_to_use, "but", max_versions[v], "require at most", v)

    http_archive(
        name = "libusb",
        urls = ["https://github.com/libusb/libusb/releases/download/v{}/libusb-{}.tar.bz2".format(version_to_use, version_to_use)],
        build_file = "@rules_libusb//:libusb.BUILD",
        strip_prefix = "libusb-" + version_to_use,
        sha256 = _KNOWN_RELEASE_HASHES.get(version_to_use, None),
    )

libusb = module_extension(
    doc = "Bzlmod extension for pulling in libusb sources.",
    implementation = _libusb_impl,
    tag_classes = {
        "source_release": tag_class(
            doc = "Controls the source code version to use when building libusb.",
            attrs = {
                "min_version": attr.string(
                    doc = "Minimum supported version of libusb required",
                ),
                "max_version": attr.string(
                    doc = "Maximum supported version of libusb required",
                ),
            },
        ),
    },
)
