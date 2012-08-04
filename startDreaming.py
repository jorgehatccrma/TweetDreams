import os
import sys
import optparse

class Usage(Exception):
  def __init__(self, msg):
    self.msg = msg
        
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
  
  # print "local word: %s" % (options.local_word)
  
  # get the search terms
  terms = getSearchTerms(options.words_file)
  # print terms
  
  
  if options.run_java:
    print "Running visualizer on ip '%s'" % (options.java_ip)
  if options.run_chuck:
    print "Running sound server on ip '%s'" % (options.chuck_ip)
  if options.run_python:
    print "Running tweet server on ip '%s'" % (options.python_ip)


if __name__ == '__main__':
  sys.exit(main())