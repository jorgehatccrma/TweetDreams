import os
import sys
import optparse

class Usage(Exception):
  def __init__(self, msg):
    self.msg = msg
        
        
def main(argv=None):
  
  parser = optparse.OptionParser()
  
  flags_opts = optparse.OptionGroup(parser, "Flags",
                      "This options will enable/disable locally running the different parts of TweetDreams.")
  
  flags_opts.add_option('-T', '--run-tweet-server', action="store_true", dest="run_python", default=True, help="Run the (python) tweet server")
  flags_opts.add_option('-t', '--no-tweet-server', action="store_false", dest="run_python", default=True, help="Don't run the (python) tweet server")
  
  flags_opts.add_option('-S', '--run-sound', action="store_true", dest="run_chuck", default=True, help="Run the (chuck) sound server")
  flags_opts.add_option('-s', '--no-sound', action="store_false", dest="run_chuck", default=True, help="Don't run the (chuck) sound server")
  
  flags_opts.add_option('-V', '--run-visualizer', action="store_true", dest="run_java", default=False, help="Run the (java) visualizer")
  flags_opts.add_option('-v', '--no-visualizer', action="store_false", dest="run_java", default=False, help="Don't run the (java) visualizer")
  
  ip_opts = optparse.OptionGroup(parser, "IP addresses",
                      "This options specify the IP addresses of the different parts of TweetDreams.")
  
  ip_opts.add_option('-p', '--tweet-server-ip', action="store", dest="python_ip", type="string", default="localhost")
  ip_opts.add_option('-c', '--sound-ip', action="store", dest="chuck_ip", type="string", default="localhost")
  ip_opts.add_option('-j', '--visualizer-ip', action="store", dest="java_ip", type="string", default="localhost")
    
  parser.add_option_group(flags_opts)
  parser.add_option_group(ip_opts)
  
  
  if argv is None:
    argv = sys.argv
  try:
    options, args = parser.parse_args(argv[1:])
    # print options
  except:
    # if there's an exception, display the help message and quit (optparse will do that for us)
    parser.parse_args(["-h"])
    return 2
  
  if options.run_java:
    print "Running visualizer on ip '%s'" % (options.java_ip)
  if options.run_chuck:
    print "Running sound server on ip '%s'" % (options.chuck_ip)
  if options.run_python:
    print "Running tweet server on ip '%s'" % (options.python_ip)


if __name__ == '__main__':
  sys.exit(main())