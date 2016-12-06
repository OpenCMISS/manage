#!/usr/bin/env python
# This file contains information about installed virtual environments 

import os
import sys
import importlib


virtualenvs = []
info_file_dir = os.path.dirname(os.path.realpath(__file__))
saved_working_directory = os.getcwd()

os.chdir(info_file_dir)
try:
    sys.path.append(info_file_dir)
    for item in os.listdir(info_file_dir):
        if os.path.isfile(item) and item.startswith("bindings") and item.endswith('.py'):
            module_name = item[:-3]
            module = importlib.import_module(module_name)
            virtualenvs.append(module.info)
            
except Exception as e:
    print('boom')
    print(e)
finally:
    os.chdir(saved_working_directory)
    

def list():
    print("Available python environments:")
    print("Index -- Configuration")
    for index, venv in enumerate(virtualenvs):
        print("{0: <5} -- compiler: {1}, mpi: {2}, mpi build type: {3}, build type: {4}".format(index, venv["compiler"], venv["mpi"], venv["mpi_buildtype"], venv["buildtype"]))
        

def shell_source(script):
    """Sometime you want to emulate the action of "source" in bash,
    settings some environment variables. Here is a way to do it."""
    import subprocess, os
    pipe = subprocess.Popen(". %s; env" % script, stdout=subprocess.PIPE, shell=True)
    output = pipe.communicate()[0]
    env = dict((line.split("=", 1) for line in output.splitlines()))
    os.environ.update(env)


def activate(index):
    print("source {0}".format(virtualenvs[index]["activate"]))


if __name__ == "__main__":
    if len(sys.argv) == 1:
        list()
    elif len(sys.argv) == 2:
        index = int(sys.argv[1])
        activate(index)

