#!/usr/bin/env python

import os
import sys
import json
import yaml
import shutil
import subprocess

import hurl

def load_stack(app_dir):
    """ Load stack description from an app's directory """
    for filename in ['Stackfile', 'stackfile', 'dotcloud.yml', 'dotcloud_build.yml']:
        filepath = os.path.join(app_dir, filename)
        if os.path.exists(filepath):
            return dict(
                (key, value if type(value) == str else value.get("type"))
                for key, value in yaml.load(file(filepath)).items()
            )


def get_remote_buildpack(buildpack):
    url = hurl.parse(buildpack)
    dl_cache = '/tmp/stackbrew'
    if (url.get('proto') == 'http' and url.get('path').endswith('.git')) or (url.get('proto') == 'git'):
        dl_path = '{dl_cache}/{host}/{path}'.format(dl_cache=dl_cache, **url)
        if os.path.exists(dl_path):
            shutil.rmtree(dl_path)
        os.makedirs(dl_path)
        subprocess.call('git clone {buildpack} {dl_path}'.format(**locals()), shell=True)
        return dl_path
    return None


def get_local_buildpack(buildpack):
    if os.path.exists(buildpack):
        return buildpack
    for buildpack_dir in os.environ.get("BUILDPACK_PATH", "").split(":"):
        path = os.path.join(buildpack_dir, buildpack)
        print "Checking for {path}".format(path=path)
        if os.path.exists(path):
            return path
    return None


def get_buildpack_dir(buildpack):
    remote = get_remote_buildpack(buildpack)
    if remote:
        return remote
    local = get_local_buildpack(buildpack)
    if local:
        return local
    if not dir:
        raise KeyError("No such buildpack: {buildpack}".format(**locals()))


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
    release_script = "{buildpack}/bin/release".format(buildpack=buildpack_dir)
    if not os.path.exists(release_script):
        return {}
    return dict(yaml.load(subprocess.Popen([release_script, build_dir], stdout=subprocess.PIPE).stdout.read()))


def copy(src, dst):
    print "Copying {src} to {dst}".format(**locals())
    shutil.copytree(src, dst)


def build_app(source_dir, build_dir):
    """ Build the application source code at `source_dir` into `build_dir`.
        The build will fail if build_dir alread exists.
    """
    os.makedirs(build_dir)
    config = {}
    for (service, buildpack) in load_stack(source_dir).items():
        print "{service} -> {buildpack}".format(service=service, buildpack=buildpack)
        service_build_dir = "{build_dir}/{service}".format(**locals())
        copy(source_dir, service_build_dir)
        config[service] = build_service(service, service_build_dir, buildpack)
    file("{build_dir}/deploy.json".format(**locals()), "w").write(json.dumps(config, indent=1))


def main():
    build_app(sys.argv[1], sys.argv[2])

if __name__ == '__main__':
    main()
