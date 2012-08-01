"""
Script to install TweeetDreams python server with its dependencies in an 
isolated environment using virtualenv.

Note: since we want to install the files in a virtual environment, instead 
of specifying the traditional shebang at the top of the script 
(#!/usr/bin/env python) we need to call this script using 
"python install.py" inside the virtualenv directory.

Hacked by Jorge Herrera (jorgeh@ccrma.stanford.edu)
July 2012
"""

import sys
from setuptools.command import easy_install
from subprocess import call
import os
import tarfile

dependencies_directory = 'osc_dependencies'

class NoVirtualenv(Exception):
  """
  Virtualenv related exxception
  """
  def __init__(self, value):
    self.value = value
  def __str__(self):
    return repr(self.value)



def checkVirtualenv():
  """
  Checks if the script is being run in an active virtualenv directory and 
  raises an exception if not
  """
  sys.stdout.write('Determining if running inside a virtualenv directory ... ')
  # from http://stackoverflow.com/questions/1871549/python-determine-if-running-inside-virtualenv
  if hasattr(sys, 'real_prefix'): 
    sys.stdout.write('[OK]\n')
    sys.stdout.flush()
  else:
    sys.stdout.write('[FAILED]\n')
    sys.stdout.flush()
    # if it failed, it could be cause virtualenv is not installed or 
    # because it hasn't been activated in the folder
    try:
      import virtualenv
      raise NoVirtualenv('This directory is not a virtual environment (virtualenv).\nMaybe you forgot to activate it ("source bin/activate")?')
    except ImportError:
      # TODO: this hasn't been tested
      raise NoVirtualenv('Apparently virtualenv has not been installed in your system. You need to install it!')    


def easyInstall(package):  
  """
  Generic method to install a package using the easy_install module, only if
  required.
  """
  sys.stdout.write('\nSearching for installed %s ... ' % package)
  sys.stdout.flush()
  notFound = False
  try:
    __import__(package)
    sys.stdout.write('[FOUND]')
  except ImportError:
    sys.stdout.write('[NOT FOUND]')
    notFound = True
    
  if notFound:
    sys.stdout.write('\nInstalling %s:\n' % package)
    try:
      easy_install.main( ["-U", package] )
      sys.stdout.write('[OK]\n')
    except:
      print "\nUnexpected error when trying to easy_install %s:\n" % (package), sys.exc_info()[0], sys.exc_info()[1]
      raise
      
  sys.stdout.flush()



def compileAndInstallLiblo():
  """
  Method that unpacks liblo source code, compiles it and installs it in the 
  default virtualenv lib/ and include/ folders (because that's where pyliblo 
  will look for them).
  """
  sys.stdout.write('\n\nCompiling liblo ...\n')
  sys.stdout.flush()
  
  # uncompress the source code and cd into the directory
  cwd = os.getcwd()
  theTarFile = os.path.join(cwd, dependencies_directory, "liblo-0.26.tar.gz")
  tfile = tarfile.open(theTarFile)
  tfile.extractall(cwd)

  libloSource = os.path.join(cwd, "liblo-0.26")
	
	# configure, make & install
  os.chdir(libloSource)
  call([os.path.join(os.getcwd(), "configure"), "--prefix", cwd])
  call(["make",])
  call(["make", "install"])
  
  # finally, remove the source code folder
  os.chdir(os.pardir)
  call(["rm", "-Rf", libloSource])
  
  
  sys.stdout.write('[OK]\n')
  sys.stdout.flush()

def installPyliblo():
  """
  Builds and install PyLiblo, looking for a custom liblo library (see 
  compileAndInstallLiblo), to avoid having to install a system-wide liblo.
  """
  try:
    sys.stdout.write('\n\nInstalling pyliblo ...\n')
    sys.stdout.flush()

    # uncompress the source code and cd into the directory
    cwd = os.getcwd()
    
    theTarFile = os.path.join(cwd, dependencies_directory, "pyliblo-0.8.1.gz")
    tfile = tarfile.open(theTarFile)
    tfile.extractall(cwd)
    
    pylibloSource = os.path.join(cwd, "pyliblo-0.8.1")
    os.chdir(pylibloSource)

    # create a custom setup.cfg file to use the liblo installed using
    # compileAndInstallLiblo()
    setupFileName = "setup.cfg"
    setupFile = open(setupFileName, 'w')
    setupFile.write("[build_ext]\n")
    setupFile.close()
    setupFile = open(setupFileName, 'a')
    setupFile.write("include_dirs=%s\n" % (os.path.join(os.pardir,"include")))
    setupFile.write("library_dirs=%s\n" % (os.path.join(os.pardir,"lib")))
    setupFile.close()

  	# build and install
    call([os.path.join(os.curdir, "setup.py"), "build"])
    call([os.path.join(os.curdir, "setup.py"), "install"])

    # finally, remove the source code folder
    os.chdir(os.pardir)
    call(["rm", "-Rf", pylibloSource])

    sys.stdout.write('[OK]\n')
    sys.stdout.flush()
  except:
    raise


def installDependencies():
  """
  Install TweetDreams python server dependencies.
  """
  sys.stdout.write('Installing dependencies:\n')
  try:
    import easy_install
    easyInstall('tweetstream')
    easyInstall('numpy')
    # since pyliblo depends on liblo (c library), but we want an isolated 
    # install, we need to handle this differntly
    compileAndInstallLiblo()
    installPyliblo()
  except ImportError:
    raise
  except:
    raise
  finally:
    pass


# Run the app
if __name__ == '__main__':
  """
  Entry point to the installation script.
  """
  
  if len(sys.argv) > 1:
    dependencies_directory = sys.argv[1]
  
  
  try:
    checkVirtualenv()
    installDependencies()
  except NoVirtualenv as err:
    print "\nVirtualenv error:" , err.value
    print "Bye!\n"
    sys.exit(-1)
  except ImportError as err:
    print "ImportError:", err
  except:
    print "\nUnexpected error:", sys.exc_info()[0], sys.exc_info()[1]
    raise
  finally:
    sys.exit(0)

    


