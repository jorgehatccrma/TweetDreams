#!/bin/bash

# Set up a virtual environment, activates it and install the python dependencies required
#
# Hacked by jorgeh@ccrma.stanford.edu
# August 1, 2012


# TODO: gracefull error handling!

echo 'Creating virtual environment ...'
# TODO: check for existance of virtualenv
virtualenv .
echo 'done!'

echo 'Actiating virtual environment ...'
source ./bin/activate
echo 'done!'

echo 'Installing python server dependencies ...'
python src/python/install.py src/python/osc_dependencies
echo 'done!'

echo ''
echo '**** READ THIS ****'
echo 'You might see some error saying "RuntimeWarning: Parent module '\''numpy.distutils'\'
echo 'not found while handling absolute import". This seems to be a bug when'
echo 'installing NumPy using easy_install, but the code actually works.'