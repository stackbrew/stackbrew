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


def mkversion():
    return strftime("%Y-%m-%dT%Hh%Mm%Ss")

def get_root(app, version=None):
    path = os.path.expanduser("~/.stackbrew/{app}".format(app=app))
    return "{path}/{version}".format(
        path            = path,
        version         = version if version else sorted(listdir(path))[-1]
    )

def get_src(app, version=None):
    return "{root}/src".format(root=get_root(app, version))

def get_build(app, version=None):
    return "{root}/build".format(root=get_root(app, version))


def main():
    app = os.path.basename(os.getcwd())
    version = mkversion()
    build = get_build(app, version)
    src = get_src(app, version)
    copytree(".", src)
    for (name, settings) in detect_services(src).items():
        build_service(
            name    = name,
            source  = src,
            dest    = "{build}/{service}".format(build=build, service=name),
            **settings
        )

def execute_script(path, home):
    if os.path.exists(path):
        os.environ["OLDHOME"] = os.environ["HOME"]
        os.environ["HOME"] = home 
        subprocess.call(path)
        os.environ["HOME"] = os.environ["OLDHOME"]

def build_service(name, source, dest, type=None, **settings):
    source = os.path.abspath(source)
    dest = os.path.abspath(dest)
    def build():
        log("Building '{name}' to '{dest}'".format(name=name, dest=dest))
        # Move to the code directory
        os.chdir(source)
        if "approot" in settings:
            os.chdir(settings["approot"])
        if type:
            build_service(type, get_src(type), dest, **settings)
            execute_script("{src}/extend".format(src=get_src(type)), home=dest)
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
    p = Process(target=build)
    p.start()
    p.join()


if __name__ == '__main__':
    main()
