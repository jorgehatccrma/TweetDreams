from tree import Node
from collections import deque
import sys

class Singleton(object):
  """Singleton class"""

  def __new__(cls, *args, **kwargs):
    if '_inst' not in vars(cls):
      cls._inst = super(Singleton, cls).__new__(cls, *args, **kwargs)
    return cls._inst
  

class CommonData(Singleton):
  """Singleton class to hold common data"""
 
  def __init__(self):
  
    ##############################################
    # DO NOT EDIT THESE VARIABLES
    ##############################################
  
    # local port (port listening for incomming OSC messages)
    self.local_port = 8888
    # remote port (port that will receive the OSC messages in the client machine)
    # TODO: this could be client-specific. To handle that, instead of a list of 
    #       clients we should have a map of clients
    self.remote_port = 8890
    #self.remote_port = 8892


    self.connection = False
    self.triggerLengthThreshold = 8
    self.receivedTweetIDs = set([])
    self.nodes = []
    # set of trees in the app
    self.trees = set([])
    self.sentNodes = []
    # autoincremental id of the echoes
    self.echo_id = 0
    self.newTweetsQueue = deque([])
    self.keywordTweetsQueue = deque([])    
    #
    self.waitingForChuck = True
    self.waitingForProcessing = True
    self.general_dispatcher = None
    self.keyword_dispatcher = None
    self.initial_tweets = None

    # echo params
    self.initial_delay = 1000 # in ms
    self.delay_inc = 250 # in ms
    self.delay_rnd = 30
    self.min_delay = 0
    self.max_num_hops = 12


    ##############################################
    # EDITABLE VARIABLES
    ##############################################

    # distance metric to be used
    #self.distance_method = "lcs"
    self.distance_method = "cosine"


    # keyword ("local term") of the piece. Can be more than one.
    # We have decided that 'chuck' will take care of informing python of this, 
    # so it should start empty
    self.keywords = set([])
    #self.keywords = set(["#mito", "mito"])
    
    # other search terms. According to tha last determination, it will start empty, 
    # although it could be populated initially
    self.search_terms = set([])
    #self.search_terms = set(["love","technology"])
    
    # THE ULTIMATE HACK !!!
    # add popular term(s) here, but that you won't use in the piece
    self.exclusion_terms = set(["justin"])
    
    # IP addresses OSC messages will be sent to (in other words, the chuck IP)
    # self.clients = set([])
    self.clients = set(["127.0.0.1"])
    
    self.lcs_threshold = 0.0
    self.cosine_threshold = 0.25
    
    # Dequeuing time limits
    self.lower_dequeuing_limit = 0.1
    
    
    ##############################################
    # END OF EDITABLE VARIABLES
    ##############################################


      
  def register(self, ip_str):
    self.clients.add(ip_str)

  def unregister(self, ip_str):
    if ip_str in self.clients:
      self.clients.remove(ip_str)

  def showClients(self):
    print "Current clients:"
    for client in self.clients:
      print client
  
  def newNode(self, tweet):
    node = Node(tweet)
    self.nodes.append(node)
    return node
  
  def getNodeByTweetID(self, tweet_id):
    for node in self.nodes:
      if node.tweet['id'] == tweet_id:
        return node
    return None

  def showSearchTerms(self):
    self.log("SEARCH TERMS:\t" + ", ".join(self.search_terms) + "\n")
    sys.stdout.flush()

  def log(self, message, with_prefix=True):
    if with_prefix:
      message = "[tweets server] %s" % (message)
    sys.stdout.write(message)
    sys.stdout.flush()
      
