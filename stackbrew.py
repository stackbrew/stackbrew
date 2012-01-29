#!/usr/bin/env python

import os
import sys
import yaml
import shutil
import subprocess


def load_stack(app_dir):
    """ Load stack description from an app's directory """
    for filename in ['Stackfile', 'stackfile', 'dotcloud.yml', 'dotcloud_build.yml']:
        filepath = os.path.join(app_dir, filename)
        if os.path.exists(filepath):
            return dict(
                (key, value if type(value) == str else value.get("type"))
                for key, value in yaml.load(file(filepath)).items()
            )


def get_buildpack_dir(buildpack):
    if os.path.exists(buildpack):
        return buildpack
    for buildpack_dir in os.environ.get("BUILDPACK_PATH", "").split(":"):
        path = os.path.join(buildpack_dir, buildpack)
        print "Checking for {path}".format(path=path)
        if os.path.exists(path):
            return path
    raise IOError("No such file or directory: {buildpack}".format(buildpack=buildpack))


def build_service(service_name, build_dir, buildpack):
    """ Build the service in-place at `build_dir` using `buildpack`.
        `service_name` is provided as a convenience.
    """
    buildpack_dir = get_buildpack_dir(buildpack)
    cache_dir = "{buildpack}/_cache".format(buildpack=buildpack_dir)
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)
    print "['{build_dir}'] building service '{service_name}' with buildpack '{buildpack}' and cache '{cache_dir}'".format(**locals())
    subprocess.call(["{buildpack}/bin/compile".format(buildpack=buildpack_dir), build_dir, cache_dir])


def copy(src, dst):
    print "Copying {src} to {dst}".format(**locals())
    shutil.copytree(src, dst)


def build_app(source_dir, build_dir):
    """ Build the application source code at `source_dir` into `build_dir`.
        The build will fail if build_dir alread exists.
    """
    os.makedirs(build_dir)
    for (service, buildpack) in load_stack(source_dir).items():
        print "{service} -> {buildpack}".format(service=service, buildpack=buildpack)
        service_build_dir = "{build_dir}/{service}".format(**locals())
        copy(source_dir, service_build_dir)
        build_service(service, service_build_dir, buildpack)


def main():
    build_app(sys.argv[1], sys.argv[2])

if __name__ == '__main__':
    main()
