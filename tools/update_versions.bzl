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

"""Starlark rules and repository extension for updating versions.json."""

load("//:extensions.bzl", "version_parts")

_LIST_RELEASES_URL = "https://api.github.com/repos/libusb/libusb/releases?page={page}"
_DOWNLOAD_URL = "https://github.com/libusb/libusb/releases/download/v{version}/{asset}"
_MAX_PAGES = 10

def _libusb_updated_versions_repo_impl(rctx):
    existing_content = rctx.read(rctx.path(rctx.attr.versions_file))
    versions_dict = json.decode(existing_content)

    for page in range(1, _MAX_PAGES + 1):
        url = _LIST_RELEASES_URL.format(page = page)
        page_file = "releases_page_{}.json".format(page)
        rctx.report_progress("Fetching libusb releases from GitHub (page {})".format(page))
        rctx.download(
            url = url,
            output = page_file,
        )
        releases = json.decode(rctx.read(page_file))
        if not releases:
            break

        stop_pagination = False
        for release in releases:
            if release.get("draft"):
                continue

            tag = release.get("tag_name", "")
            if not tag.startswith("v"):
                continue
            ver = tag[1:]

            if ver in versions_dict and versions_dict[ver]:
                stop_pagination = True
                break

            asset_name = "libusb-{}.tar.bz2".format(ver)
            sha256 = None
            for asset in release.get("assets", []):
                if asset.get("name") != asset_name:
                    continue
                digest = asset.get("digest")
                if digest and digest.startswith("sha256:"):
                    sha256 = digest.removeprefix("sha256:")
                else:
                    asset_url = asset.get(
                        "browser_download_url",
                        _DOWNLOAD_URL.format(version = ver, asset = asset_name),
                    )
                    rctx.report_progress("Downloading {} to compute sha256".format(asset_name))
                    dl = rctx.download(
                        url = asset_url,
                        output = asset_name,
                    )
                    sha256 = dl.sha256
                break

            if sha256:
                versions_dict[ver] = sha256

        if stop_pagination:
            break

    sorted_keys = sorted(versions_dict.keys(), key = version_parts)
    lines = ["{"]
    for i, k in enumerate(sorted_keys):
        comma = "," if i + 1 < len(sorted_keys) else ""
        lines.append("    {}: {}{}".format(
            json.encode(k),
            json.encode(versions_dict[k]),
            comma,
        ))
    lines.append("}\n")

    rctx.file(
        "versions.json",
        content = "\n".join(lines),
    )
    rctx.file(
        "BUILD.bazel",
        content = 'exports_files(["versions.json"])\n',
    )

_libusb_updated_versions_repo = repository_rule(
    implementation = _libusb_updated_versions_repo_impl,
    attrs = {
        "versions_file": attr.label(
            default = Label("//:versions.json"),
            allow_single_file = True,
        ),
    },
    local = True,
    doc = "Queries GitHub releases for libusb and produces an updated versions.json.",
)

def _update_versions_ext_impl(_module_ctx):
    _libusb_updated_versions_repo(name = "libusb_updated_versions")

update_versions_ext = module_extension(
    implementation = _update_versions_ext_impl,
    doc = "Dev-only extension that fetches latest libusb release hashes on demand.",
)

def _update_versions_rule_impl(ctx):
    out_json = ctx.actions.declare_file("versions.json")
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = out_json,
        substitutions = {},
    )

    runner = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.write(
        output = runner,
        is_executable = True,
        content = """#!/usr/bin/env sh
set -e
if cmp -s "{current_short_path}" "{out_short_path}"; then
  echo "versions.json is already up to date."
else
  echo "Run 'cp {out_path} versions.json' to update the versions.json file."
fi
""".format(
            current_short_path = ctx.file.current.short_path,
            out_path = out_json.path,
            out_short_path = out_json.short_path,
        ),
    )

    return [
        DefaultInfo(
            executable = runner,
            files = depset([out_json]),
            runfiles = ctx.runfiles(files = [out_json, ctx.file.current]),
        ),
    ]

_update_versions_rule = rule(
    implementation = _update_versions_rule_impl,
    executable = True,
    attrs = {
        "current": attr.label(
            default = Label("//:versions.json"),
            allow_single_file = True,
        ),
        "src": attr.label(
            default = Label("@libusb_updated_versions//:versions.json"),
            allow_single_file = True,
        ),
    },
)

def update_versions(name, **kwargs):
    tags = kwargs.pop("tags", [])
    if "manual" not in tags:
        tags = tags + ["manual"]
    _update_versions_rule(
        name = name,
        tags = tags,
        **kwargs
    )
