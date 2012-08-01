#!/usr/bin/env python

# reference http://mindtrove.info/virtualenv-bootstrapping/

import virtualenv
import sys
import os
import subprocess


def main(argv=None):
  if argv is None:
    argv = sys.argv
    
#    cwd = os.getcwd()
    cwd = os.curdir
    
    # creates a virtualenv in the current folder
    sys.stdout.write('Creating virtual environment in \'%s\' ... ' % (cwd))
    virtualenv.create_environment(os.getcwd())
    sys.stdout.write('[DONE]\n')
    sys.stdout.flush()
    
    # activate virtualevn
    activate = os.path.join(cwd, 'bin', 'activate')
    print activate
    subprocess.call(['source', activate])


def adjust_options(options, args):
  # force no site packages
  options.no_site_packages = True


virtualenv.adjust_options = adjust_options

if __name__ == '__main__':
  sys.exit(main())