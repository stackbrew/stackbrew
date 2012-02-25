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
            return dict(yaml.load(file(filepath)))

def get_service_root(app_dir, service):
    """ Return the root directory a service (as defined by its "approot" property in the stackfile) """
    return os.path.join(app_dir, load_stack(app_dir)[service].get("approot", "."))

def get_service_buildpack(app_dir, service):
    return load_stack(app_dir)[service]["type"]

def get_service_buildscript(app_dir, service):
    """ Return the path to a service's build script (as defined by its "buildscript" property in the stackfile). """
    return mkpath((app_dir, load_stack(app_dir)[service]["buildscript"]))


def get_buildpack_dir(buildpack):
    """ Search for `buildpack` using the BUILDPACK_PATH environment variable.
        Default to the litteral filesystem path.
    """
    if os.path.exists(buildpack):
        return buildpack
    for buildpack_dir in os.environ.get("BUILDPACK_PATH", "").split(":"):
        path = os.path.join(buildpack_dir, buildpack)
        if os.path.exists(path):
            return path
    raise KeyError("No such buildpack: {buildpack}".format(**locals()))


def get_buildpack_requirements(buildpack_dir, build_dir):
    """ Return the env requirements of a buildpack, as returned by its bin/require. """
    p = call_script(os.path.join(buildpack_dir, "bin/require"), build_dir, stdout=subprocess.PIPE)
    if not p:
        return []
    return [l.strip() for l in p.stdout.readlines()]


def build_service(service_name, build_dir, buildpack):
    """ Build the service in-place at `build_dir` using `buildpack`.
        `service_name` is provided as a convenience.
    """
    buildpack_dir = get_buildpack_dir(buildpack)
    cache_dir = "{buildpack}/_cache".format(buildpack=buildpack_dir)
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)
    print "['{build_dir}'] building service '{service_name}' with buildpack '{buildpack}' and cache '{cache_dir}'".format(**locals())
    call_script(os.path.join(buildpack_dir, "bin/compile"), build_dir, cache_dir)
    p = call_script(os.path.join(buildpack_dir, "bin/release"), build_dir, stdout=subprocess.PIPE)
    if not p:
        return {}
    return dict(yaml.load(p.stdout.read()))


def call_script(path, *args, **kw):
    if not os.path.exists(path):
        return None
    os.chmod(mkpath(path), 0700)
    p = subprocess.Popen((path,) + args, **kw)
    p.wait()
    return p


def mkpath(path):
    if type(path) == str:
        return path
    return os.path.join(*path)

def copy(src, dst):
    """ Copy a directory from `src` to `dst`. """
    src = mkpath(src)
    dst = mkpath(dst)
    print "Copying {src} to {dst}".format(**locals())
    shutil.copytree(src, dst)

def mkfile(path, x=False, **kw):
    """ Create a file, and the enclosing directory if it doesn't exist.
        Extra keywords are passed to the file constructor.
    """
    path = mkpath(path)
    dir = os.path.dirname(path)
    if not os.path.exists(dir):
        os.makedirs(dir)
    f = file(path, "w", **kw)
    if x:
        # FIXME: this is me being too lazy to look up how to do `chmod +x` cleanly in python
        os.chmod(path, 0700)
    return f


def getfile(path):
    return file(mkpath(path))


def cmd_buildreqs(source_dir):
    reqs = set()
    for service in load_stack(source_dir):
        buildpack_dir = get_buildpack_dir(get_service_buildpack(source_dir, service))
        reqs.update(get_buildpack_requirements(buildpack_dir, source_dir))
    for req in reqs:
        print req

def cmd_build(source_dir, build_dir):
    """ Build the application source code at `source_dir` into `build_dir`.
        The build will fail if build_dir alread exists.
    """
    os.makedirs(build_dir)
    config = {}
    for (service, config) in load_stack(source_dir).items():
        buildpack = get_service_buildpack(source_dir, service)
        print "{service} -> {buildpack}".format(service=service, buildpack=buildpack)
        service_build_dir = "{build_dir}/{service}".format(**locals())
        copy(source_dir, service_build_dir)
        config[service] = build_service(service, service_build_dir, buildpack)
    file("{build_dir}/deploy.json".format(**locals()), "w").write(json.dumps(config, indent=1))

def cmd_info(source_dir):
    """ Dump the contents of an application stack. """
    print json.dumps(load_stack(source_dir), indent=1)

def cmd_convert(source_dir, service, dest):
    """ Extract a custom service from an application, and convert it to a buildpack. """
    stack = load_stack(source_dir)
    if stack[service].get("type", "custom") != "custom":
        raise Exception("Only custom services can be converted to a buildpack.")
    # Copy service directory
    copy(
        (source_dir, stack[service].get("approot", ".")),
        dest)
    # Copy build script to bin/compile
    print "Copying build script to bin/compile"
    buildscript_src = file(get_service_buildscript(source_dir, service))
    buildscript_dest = mkfile((dest, "bin/compile"))
    buildscript_dest.write(buildscript_src.read())
    # Encapsulate relevant service config in a bin/release
    print "Copying config to bin/release"
    mkfile((dest, "bin/release"), x=True).write(
"""#!/bin/sh

###
### This release script was generated by stackbrew,
### using configuration from a dotCloud custom service.
###
### See http://github.com/shykes/stackbrew for details.
###

cat <<EOF
{config}
EOF
""".format(config = yaml.dump(stack[service]))
    )

def cmd_buildscript(source_dir, service):
    print file(get_service_buildscript(source_dir, service)).read()

def cmd_services(source_dir):
    for service in sorted(load_stack(source_dir)):
        print service

def main():
    cmd, args = sys.argv[1], sys.argv[2:]
    eval("cmd_{cmd}".format(cmd=cmd))(*args)

if __name__ == '__main__':
    main()
