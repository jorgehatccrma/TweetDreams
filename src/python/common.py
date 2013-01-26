from tree import Node
from collections import deque
import sys

"""
This module is used as a "singleton class", to store "app-wide" data
"""


##############################################
# DO NOT EDIT THESE VARIABLES
##############################################

# local port (port listening for incomming OSC messages)
local_port = 8888
# remote port (port that will receive the OSC messages in the client machine)
# TODO: this could be client-specific. To handle that, instead of a list of
#             clients we should have a map of clients
remote_port = 8890


connection = False
triggerLengthThreshold = 8
receivedTweetIDs = set([])
nodes = []

# set of trees in the app
trees = set([])
sentNodes = []

# autoincremental id of the echoes
echo_id = 0
newTweetsQueue = deque([])
keywordTweetsQueue = deque([])

#
general_dispatcher = None
keyword_dispatcher = None
initial_tweets = None

# echo params
initial_delay = 1000  # in ms
delay_inc = 250  # in ms
delay_rnd = 30
min_delay = 0
max_num_hops = 12


##############################################
# EDITABLE VARIABLES
##############################################

# distance metric to be used
#distance_method = "lcs"
distance_method = "cosine"


# keyword ("local term") of the piece. Can be more than one.
# We have decided that 'chuck' will take care of informing python of this,
# so it should start empty
keywords = set([])
#keywords = set(["#mito", "mito"])

# other search terms. According to tha last determination, it will start empty,
# although it could be populated initially
search_terms = set([])
#search_terms = set(["love","technology"])

# THE ULTIMATE HACK !!!
# add popular term(s) here, but that you won't use in the piece
exclusion_terms = set(["justin"])

# IP addresses OSC messages will be sent to (in other words, the chuck IP)
# clients = set([])
clients = set(["localhost"])

lcs_threshold = 0.0
cosine_threshold = 0.25

# Dequeuing time limits
lower_dequeuing_limit = 0.1


##############################################
# END OF EDITABLE VARIABLES
##############################################


def register(ip_str):
    clients.add(ip_str)


def unregister(ip_str):
    if ip_str in clients:
        clients.remove(ip_str)


def showClients():
    print "Current clients:"
    for client in clients:
        log(client + "\n")


def newNode(tweet):
    node = Node(tweet)
    nodes.append(node)
    return node


def getNodeByTweetID(tweet_id):
    for node in nodes:
        if node.tweet['id'] == tweet_id:
            return node
    return None


def showSearchTerms():
    log("SEARCH TERMS:\t" + ", ".join(search_terms) + "\n")
    sys.stdout.flush()


def log(message, with_prefix=True):
    if with_prefix:
        message = "[tweets server] %s" % (message)
    sys.stdout.write(message)
    sys.stdout.flush()
