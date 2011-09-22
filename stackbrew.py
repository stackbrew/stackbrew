#!/usr/bin/env python


import os
import sys
import shutil
import subprocess
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
    for filename in ['Stackfile', 'stackfile', 'dotcloud.yml', 'dotcloud_build.yml']:
        filepath = os.path.join(path, filename)
        if os.path.exists(filepath):
            return yaml.load(file(filepath))
    return { "main": {} }


def main():
    services = detect_services(".")
    log("Detected services: {0}".format(", ".join(services)))
    build = os.path.expanduser("~/.stackbrew/builds/{id}".format(id=os.path.basename(os.getcwd())))
    if os.path.exists(build):
        shutil.rmtree(build)
    for (name, settings) in services.items():
        build_service(
            name    = name,
            source  = '.',
            dest    = os.path.join(build, name),
            **settings
        )

def build_service(name, source, dest, **settings):
    source = os.path.abspath(source)
    dest = os.path.abspath(dest)
    def build():
        log("Building '{name}' to '{dest}'".format(name=name, dest=dest))
        # Move to the code directory
        os.chdir(source)
        if "approot" in settings:
            os.chdir(settings["approot"])
        # Check source
        if os.path.exists("profile"):
            print "Warning: 'profile' is a reserved file name - contents may be overwritten."
        # Create dest
        if not os.path.exists(dest):
            os.makedirs(dest)
        # Setup environment
        os.environ["HOME"] = dest
        # Call build script
        if os.path.exists("build"):
            call("./build")
    build()

if __name__ == '__main__':
    main()
