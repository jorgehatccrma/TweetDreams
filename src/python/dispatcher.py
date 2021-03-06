import threading
import time
import random
from collections import deque
import common
import distance
import cosineDistance
import sys
import traceback
import wordFilter as offensiveFilter


class Dispatcher(threading.Thread):
    queue = deque()
    low = 0
    high = 0
    name = "dispatcher"

    # constructor
    def __init__(self, name, oscManager, queue, low=0.2, high=0.2):
        # init the instance here
        self.oscMgr = oscManager
        self.queue = queue
        if low < 0:
            low = 0
        self.low = low
        if high < low:
            high = low
        self.high = high
        self.name = name
        self.running = False
        # call the thread initializer
        threading.Thread.__init__(self)

    def run(self):
        common.log("Starting " + self.name + "\n")
        self.running = True
        while self.running:
            #dispatched the next tweet randomizing the inter tweet time
            if len(self.queue) > 0:
                try:
                    self.sendNextTweet()
                    #common.log("tweet forwarded from " + self.name + " queue. Tweet queued:" + len(self.queue) + "\n")
                except:
                    common.log("Error forwarding tweet: tweet omitted.\n")
            if self.high > 0:
                t = random.uniform(self.low, self.high)  # in seconds
                time.sleep(t)

    def sendNextTweet(self):
        tweet = self.queue.popleft()
        #common.log( tweet['text'] + "\n" )

        # replace offensive words with '*'
        tweet['text'] = offensiveFilter.filter(tweet['text'])

        results = getClosestTweet(tweet)
        new = associateTweet(results['node'], str(results['closest_id']), results['dist'], results['closest_node'], tweet['local'])

        newTweet = new[0]
        triggers = new[1]

        self.oscMgr.sendNewNode(newTweet[0], newTweet[1], ('s', 's', 'f', 's', 'i'))
        for msg in triggers:
            #common.log( "triggering: " + msg[2] + "\n" )
            self.oscMgr.triggerNodes(msg[0], msg[1], msg[2], msg[3])


# computes the closest tweet and build new trees if necessary
def associateTweet(node, closest_id, dist, closest_node, local):
    tweet = node.tweet
    if ('text' in tweet):
        text = tweet['text'].encode('utf-8').strip()
        if ('id' in tweet):
            newTweet = (common.remote_port, (str(tweet['id']), closest_id, dist, text, local))
            try:
                common.sentNodes.append(closest_node)
            except:
                common.log("Unexpected error sending 'newNode':" + sys.exc_info()[0] + "\n")
                common.log("OSC newNode message not sent\n")
                traceback.print_exc()

            try:
                nodesToPlay = node.getUpperNodes()
                if nodesToPlay is None:
                    return
                common.echo_id += 1
                if common.echo_id > 99:
                    common.echo_id = 0    # for the chuck patch to work
                hop_level = 0
                triggers = []
                while len(nodesToPlay) > 0 and hop_level < common.max_num_hops:
                    nextNodeId = nodesToPlay.pop()
                    delay = common.min_delay
                    if hop_level > 0:
                        delay = common.initial_delay + hop_level * common.delay_inc
                        delay += hop_level * random.randint(-common.delay_rnd, common.delay_rnd)
                        if delay < common.min_delay:
                            delay = common.min_delay
                    node_delay_dict = {str(nextNodeId): delay}
                    triggers.append((common.remote_port, common.echo_id, node_delay_dict, hop_level))
                    hop_level += 1
                return (newTweet, triggers)
            except:
                common.log("Unexpected error sending 'triggerNodes':" + sys.exc_info()[0] + "\n")
                common.log("OSC triggerNode message not sent")
                traceback.print_exc()


# Find if there's a tweet close enough and adds the new tweet to it. If there's no tweet close enough, creates a new tree
def getClosestTweet(tweet):
    closest_node = None
    closest_id = 0
    dist = 0
    d = 0

    for node in common.nodes:
        twt = node.tweet
        # using longest common substring
        if common.distance_method == "lcs":
            subStrSet = distance.LCSubstr_set(tweet['text'].encode('utf-8'), twt['text'].encode('utf-8'))
            d = distance.totalDistance(subStrSet)
        # using cosine distance
        elif common.distance_method == "cosine":
            d = cosineDistance.compare(tweet['text'].encode('utf-8'), twt['text'].encode('utf-8'))
        #common.log( "Distance between " + tweet['id'] + " and " + twt['id'] + " is " + d + "\n" )

        if d >= dist:
            closest_node = node
            closest_id = twt['id']
            dist = d

    # add the new tweet to the Tweet-set (is important to do this after computing the closest tweet
    node = common.newNode(tweet)

    threshold = 0
    if common.distance_method == "lcs":
        threshold = common.lcs_threshold
    elif common.distance_method == "cosine":
        threshold = common.cosine_threshold

    if dist > threshold:
        closest_node.addChild(node)
        #common.log( node.tweet['id'] + "is now a child of " + closest_node.tweet['id'] + "\n" )
        return {'node': node, 'closest_id': closest_id, 'dist': dist, 'closest_node': closest_node}
    else:
        common.trees.add(node)
        #common.log( node.tweet['id'] + " forms a new tree\n" )
        return {'node': node, 'closest_id': 0, 'dist': 0, 'closest_node': None}
