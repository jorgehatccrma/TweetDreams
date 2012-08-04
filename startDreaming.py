import os
import sys
import optparse
import subprocess


SUCCESS_EXIT_CODE = 0
ERROR_EXIT_CODE = 1


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
                    
  parser.add_option('-w', '--words-file', 
                    action="store", dest="words_file", 
                    default="search_terms.txt", 
                    help="Read the search words from the specified file")
  

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
  flags_opts.add_option('-f', '--fake-tweets', 
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
  os.chdir(os.path.join(pwd, 'src', 'chuck'))
  if False: # this was the old way, but is too obscure
    command = [os.path.join(os.getcwd(), 'twtChuckServer.sh')]
    if options.use_fake_tweets:
      command.append('-t')
  else:
    command = ['chuck']
    terms_as_chuck_args = ":".join(options.terms)
    if len(terms_as_chuck_args): terms_as_chuck_args = ":" + terms_as_chuck_args
    command.append('--bufsize2048')
    command.append('--srate44100')
    command.append('twtNodeSynth3.ck')
    command.append('twtSynthControlLOCAL3.ck')
    command.append("twtSynthControlMASTER.ck:%s:%s:%s%s" % (options.python_ip, options.java_ip, options.local_word, terms_as_chuck_args) )
    if options.use_fake_tweets:
      command.append('twtTest5.ck')
    print command
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
  command = [os.path.join(pwd, 'src', 'python', 'twt.py')]
  command.append(options.local_word)
  for term in options.terms: command.append(term)
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
  
  
def startJavaApp(options, pwd):
  pass

        
def main(argv=None):
  # parse arguments
  if argv is None:
    argv = sys.argv
  try:
    parser = optionParser()
    options, args = parser.parse_args(argv[1:])
    # print options
  except:
    print >>sys.stderr, "for help use --help (-h)"
    return 2
  
  # get the search terms and save them in the options object
  options.terms = getSearchTerms(options.words_file)
      
  # run the different processes
  pwd = os.getcwd()
  pids=set()

  # Visualizer (java app)
  if options.run_java:
    print "Running visualizer ..."
    # TODO: implement this
    startJavaApp(options, pwd)
  else:
    print "Visualizer is running on '%s'" % (options.java_ip)

  # sound server (chuck app)
  if options.run_chuck:
    p = startChuckServer(options, pwd)
    if not p: return ERROR_EXIT_CODE
    pids.add(p.pid)
  else:
    print "Sound server is running on'%s'" % (options.chuck_ip)

  # tweet server (python app)
  if options.run_python:
    p = startPythonServer(options, pwd)
    pids.add(p.pid)
  else:
    print "Tweet server is running on'%s'" % (options.python_ip)


  
  # wait for all subprocesses to end
  try:
    while pids:
      pid, retval = os.wait()
      print('{p} finished'.format(p=pid))
      pids.remove(pid)
  except KeyboardInterrupt:
    try:
      for pid in pids:
        os.kill(pid,9)
      return SUCCESS_EXIT_CODE
    except:
      return ERROR_EXIT_CODE
  except:
    return ERROR_EXIT_CODE


if __name__ == '__main__':
  sys.exit(main())