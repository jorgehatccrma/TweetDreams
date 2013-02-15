import os
import sys
import optparse
import subprocess
import time
import getpass

SUCCESS_EXIT_CODE = 0
ERROR_EXIT_CODE = 1
ERROR_WRONG_ARGUMENT = 2


def getSearchTerms(file_path):
    if not os.path.isabs(file_path):
        file_path = os.path.join(sys.prefix, file_path)
    return open(file_path, 'r').read().split()


def optionParser():
    # create the option parser
    parser = optparse.OptionParser()

    # add main options
    parser.add_option('-l', '--local-word',
                      action="store", dest="local_word",
                      default="#TweetDreams",
                      help="Define the local search word (by default is #TweetDreams). If it contains " +
                      "a pound character (#), the whole word must be enclosed in single quotes (e.g. " +
                      "-l '#music')")

    parser.add_option('-f', '--words-file',
                      action="store", dest="words_file",
                      default="search_terms.txt",
                      help="Read the search words from the specified file")

    parser.add_option('--width',
                      action="store", dest="vis_width",
                      default="1024", type="int",
                      help="Width of the visualizer canvas")

    parser.add_option('--height',
                      action="store", dest="vis_height",
                      default="768", type="int",
                      help="Height of the visualizer canvas")

    # flag-options to enable/disbale different parts of TweetDreams
    flags_opts = optparse.OptionGroup(parser, "Flags",
                                      "This options will enable/disable locally running the different parts of TweetDreams.")

    flags_opts.add_option('-T', '--run-tweet-server',
                          action="store_true", dest="run_python",
                          default=True, help="Run the (python) tweet server")
    flags_opts.add_option('-t', '--no-tweet-server',
                          action="store_false", dest="run_python",
                          default=True, help="Don't run the (python) tweet server")

    flags_opts.add_option('-S', '--run-sound',
                          action="store_true", dest="run_chuck",
                          default=True,
                          help="Run the (chuck) sound server")
    flags_opts.add_option('-s', '--no-sound',
                          action="store_false", dest="run_chuck",
                          default=True,
                          help="Don't run the (chuck) sound server")

    flags_opts.add_option('-o', '--fake-tweets',
                          action="store_true", dest="use_fake_tweets",
                          default=False,
                          help="(Use only for development!) this will fake tweets to test the sound server")

    flags_opts.add_option('-V', '--run-visualizer',
                          action="store_true", dest="run_java",
                          default=False,
                          help="Run the (java) visualizer")
    flags_opts.add_option('-v', '--no-visualizer',
                          action="store_false",
                          dest="run_java", default=False,
                          help="Don't run the (java) visualizer")

    # specify IP addresses of different parts of TweetDreams
    ip_opts = optparse.OptionGroup(parser, "IP addresses",
                                   "This options specify the IP addresses of the different parts of TweetDreams.")

    ip_opts.add_option('-p', '--tweet-server-ip',
                       action="store", dest="python_ip", type="string", default="localhost")
    ip_opts.add_option('-c', '--sound-ip',
                       action="store", dest="chuck_ip", type="string", default="localhost")
    ip_opts.add_option('-j', '--visualizer-ip',
                       action="store", dest="java_ip", type="string", default="localhost")

    parser.add_option_group(flags_opts)
    parser.add_option_group(ip_opts)

    return parser


def startChuckServer(options, pwd):
    """Start the chuck process to play the sound"""
    os.chdir(os.path.join(pwd, 'src', 'chuck'))
    command = ['chuck']
    terms_as_chuck_args = ":".join(options.terms)
    if len(terms_as_chuck_args):
        terms_as_chuck_args = ":" + terms_as_chuck_args
    command.append('--bufsize2048')
    command.append('--srate44100')
    command.append('twtNodeSynth3.ck')
    command.append('twtSynthControlLOCAL3.ck')
    command.append("twtSynthControlMASTER.ck:%s:%s:%s%s" % (options.python_ip, options.java_ip, options.local_word, terms_as_chuck_args))
    if options.use_fake_tweets:
        command.append('twtTest5.ck')
    sys.stdout.write("Starting sound server ... ")
    try:
        p = subprocess.Popen(command)
        sys.stdout.write("[ok]\n")
    except:
        sys.stdout.write("[error]\n")
        p = None
    finally:
        os.chdir(pwd)
        sys.stdout.flush()
        return p


def startPythonServer(options, pwd):
    """
    Asks for a Twitter username and password and launches the tweet server
    """
    username = raw_input('Twitter Username: ')
    password = getpass.getpass('Twitter Password: ')

    command = [os.path.join(pwd, 'src', 'python', 'twt.py')]
    command.append(username)
    command.append(password)
    command.append(options.chuck_ip)
    command.append(options.local_word)
    for term in options.terms:
        command.append(term)
    sys.stdout.write("Starting tweets server ... ")
    try:
        p = subprocess.Popen(command)
        sys.stdout.write("[ok]\n")
    except:
        sys.stdout.write("[error]\n")
        p = None
    finally:
        os.chdir(pwd)
        sys.stdout.flush()
        return p


def compileJavaApp(pwd, jarsFolder, openGLFolder, srcFolder):
    """Compile the java app (visualization) to the correct resolution"""
    jars = [os.curdir]
    # TODO: instead of specifying the jars by hand, we should read and use all the jars in the folder?
    jars.append(os.path.join(jarsFolder, 'core.jar'))
    jars.append(os.path.join(jarsFolder, 'nexttext.jar'))
    jars.append(os.path.join(jarsFolder, 'oscP5.jar'))
    jars.append(os.path.join(jarsFolder, 'physics.jar'))
    jars.append(os.path.join(jarsFolder, 'shapetween.jar'))
    jars.append(os.path.join(openGLFolder, 'opengl.jar'))
    jars.append(os.path.join(openGLFolder, 'jogl-all.jar'))
    jars.append(os.path.join(openGLFolder, 'gluegen-rt.jar'))

    # compile the java app
    # TODO: we shouldn't do this every time, but since is fast, is not too bad
    compileCommand = ['javac']
    compileCommand.append('-g')
    # compileCommand.append('-Xlint')
    # compileCommand.append('-verbose')
    compileCommand.append('-classpath')
    compileCommand.append(':'.join(jars))

    sources = []
    sources.append('Twt.java')

    for source in sources:
        compileCommand.append(source)

    os.chdir(srcFolder)
    try:
        sys.stdout.write('Compiling java app ...')
        sys.stdout.flush()
        subprocess.call(compileCommand)
        sys.stdout.write('[done]\n')
        sys.stdout.flush()
    except:
        sys.stdout.write('[failed]\n')
        sys.stdout.flush()
        raise Exception("Couldn't compile the Java App")
    finally:
        os.chdir(pwd)

    return jars


def startJavaApp(options, pwd):
    jarsFolder = os.path.join(pwd, 'src', 'java', 'dependencies')
    openGLFolder = os.path.join(jarsFolder, 'opengl')
    srcFolder = os.path.join(pwd, 'src', 'java', 'src')

    try:
        jars = compileJavaApp(pwd, jarsFolder, openGLFolder, srcFolder)
    except:
        raise

    # generate the run command
    command = ['java']
    command.append('-Djava.library.path=%s' % (openGLFolder))
    command.append('-classpath')
    command.append(':'.join(jars))
    command.append('Twt')
    command.append("width=%d" % options.vis_width)
    command.append("height=%d" % options.vis_height)

    sys.stdout.write("Starting visualizer app ... ")
    os.chdir(srcFolder)
    try:
        p = subprocess.Popen(command)
        sys.stdout.write("[ok]\n")
    except:
        sys.stdout.write("[error]\n")
        p = None
    finally:
        os.chdir(pwd)
        sys.stdout.flush()
        return p


def main(argv=None):
    """Parse the arguments and starts the processes required:
    sound and/or visualization and/or tweet server
    """
    # parse arguments
    if argv is None:
        argv = sys.argv
    try:
        parser = optionParser()
        options, args = parser.parse_args(argv[1:])
        # print options
    except:
        print >>sys.stderr, "for help use --help (-h)"
        return ERROR_WRONG_ARGUMENT

    # get the search terms and save them in the options object
    options.terms = getSearchTerms(options.words_file)

    # run the different processes
    pwd = os.getcwd()
    pids = set()

    # Visualizer (java app)
    if options.run_java:
        print "Running visualizer ..."
        try:
            startJavaApp(options, pwd)
            # FixMe: hack! (the java app takes a few seconds to be ready, so we'll wait a bit)
            time.sleep(5)
        except:
            return ERROR_EXIT_CODE
    else:
        print "Visualizer is running on '%s'" % (options.java_ip)

    # tweet server (python app)
    if options.run_python:
        p = startPythonServer(options, pwd)
        pids.add(p.pid)
    else:
        print "Tweet server is running on'%s'" % (options.python_ip)

    # sound server (chuck app)
    if options.run_chuck:
        p = startChuckServer(options, pwd)
        if not p:
            return ERROR_EXIT_CODE
        pids.add(p.pid)
    else:
        print "Sound server is running on'%s'" % (options.chuck_ip)

    # wait for all subprocesses to end
    try:
        while pids:
            pid, retval = os.wait()
            print('{p} finished'.format(p=pid))
            # pids.remove(pid)
    except KeyboardInterrupt:
        # unpon interrupt, kill all processes
        for pid in pids:
            try:
                os.kill(pid, 9)
            except:
                pass
            return SUCCESS_EXIT_CODE
    except:
        return ERROR_EXIT_CODE


if __name__ == '__main__':
    """Entry point"""
    sys.exit(main())
