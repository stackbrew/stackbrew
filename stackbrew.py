#!/usr/bin/env python


import os
from os import chdir, listdir
import sys
import shutil
from shutil import copytree, rmtree, copy
import subprocess
from time import strftime
from random import random
from multiprocessing import Process

import yaml


def log(msg):
    print "----- " + msg

def call(cmd):
    log(cmd)
    return subprocess.call(cmd, shell=True)

def fork(fn):
    def wrapper(*args, **kwargs):
        p = Process(target=fn, args=args, kwargs=kwargs)
        p.start()
        p.join()
    return wrapper

def detect_services(path):
    path = os.path.abspath(path)
    if not os.path.exists(path):
        raise IOError("No such file or directory: '{path}'".format(path=path))
    for filename in ['Stackfile', 'stackfile', 'dotcloud.yml', 'dotcloud_build.yml']:
        filepath = os.path.join(path, filename)
        if os.path.exists(filepath):
            return yaml.load(file(filepath))
    return { "main": {} }

def get_root(app):
    path = os.path.expanduser("~/.stackbrew/{app}".format(app=app))
    return "{path}".format(
        path            = path
    )

def get_src(service):
    return os.path.join(os.environ.get("SERVICES_LIBRARY", "."), service)

def get_build(app, service=None):
    return "{root}/build/{service}".format(root=get_root(app), service = service or "")

def do_build():
    app = os.path.basename(os.getcwd())
    if os.path.exists(get_root(app)):
        print "Build already exists: {root}".format(root=get_root(app))
        sys.exit(1)
    build = get_build(app)
    if os.path.exists(build):
        print "removing {build}".format(build=build)
    src = "."
    for (name, settings) in detect_services(src).items():
        build_service(
            name    = name,
            source  = src,
            dest    = "{build}/{service}".format(build=build, service=name),
            **settings
        )

def do_run(app, service, *cmd):
    with pushdir(get_build(app, service)):
        subprocess.call("[ -e profile ] && . profile; {cmd}".format(cmd=" ".join(cmd)),
                shell=True,
                env=dict(os.environ,
                        PATH=".:" + os.environ["PATH"],
                        HOME=".")
            )


def main():
    eval("do_{cmd}".format(cmd=sys.argv[1]))(*sys.argv[2:])


def execute_script(path, home):
    """ Execute `path`, if it exists, with HOME set to `home`. """
    if os.path.exists(path):
        os.environ["OLDHOME"] = os.environ["HOME"]
        os.environ["HOME"] = home 
        log("Executing {path:<30} in {cwd}".format(path=path, cwd=os.getcwd()))
        subprocess.call(path)
        os.environ["HOME"] = os.environ["OLDHOME"]


class pushdir:
    def __init__(self, dir):
        self.dir = dir
    def __enter__(self):
        self.olddir = os.getcwd()
        os.chdir(self.dir)
    def __exit__(self, *args):
        os.chdir(self.olddir)



def build_service(name, source, dest, type=None, **settings):
    source = os.path.abspath(source)
    sources = [source]
    dest = os.path.abspath(dest)
    log("Building  {name:<30} to {dest}".format(name=name, dest=dest))
    # Move to the code directory
    with pushdir(source):
        with pushdir(settings.get("approot", ".")):
            if type:
                # Recursively build the parent service first
                sources += build_service(type, get_src(type), dest, **settings)
                # If the parent service has an 'extend' script, run it
                for src in sources:
                    execute_script("{src}/extend".format(src=src), home=dest)
            # Create dest
            if not os.path.exists(dest):
                os.makedirs(dest)
            # Call build script
            execute_script("./build", home=dest)
            # Copy execution files
            if os.path.exists("profile"):
                copy("profile", dest)
            if os.path.exists("run"):
                copy("run", dest)
    return sources

if __name__ == '__main__':
    main()
