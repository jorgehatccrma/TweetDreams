#!/usr/bin/env python

"""
"""

import tweetstream
import oscManager
import common
import initialTweets
import sys
#import liblo, sys
import random
import traceback
import time
import dispatcher
import re
from collections import deque


# Singleton class to hold common data (hack used for inter-thread communication)
common = common.CommonData()

# Handles OSC communication
osc = oscManager.OSCManager()

# To delay the tweets and send them one at a time (random wait between 0.5 and 1.5 seconds)
common.general_dispatcher = dispatcher.Dispatcher("general dispatcher", osc, common, common.newTweetsQueue, 0.5, 1.5)
common.keyword_dispatcher = dispatcher.Dispatcher("keyword dispatcher", osc, common, common.keywordTweetsQueue)

# process to trigger the initial fake tweets
common.initial_tweets = initialTweets.InitialTweets( common.keywordTweetsQueue, 5.0, 7.0 )

# URL pattern (used to remove URLs from tweets)
url_pattern = re.compile('(https?://)(www\.)?([a-zA-Z0-9_%\.]*)([a-zA-Z]{2})?((/[a-zA-Z0-9_%~]*)+)?(\.[a-zA-Z]*)?(\?([a-zA-Z0-9_%~=&])*)?')


#####################################################
# Different methods to consume the stream of tweets
#####################################################
# only tweets containing at least one of the provided terms
def searchTweets(username, password, terms):
  global common
  while True:
    common.showSearchTerms()
    try:
      
      # This was an old hack, but I don't think we use it anymore
      #terms = common.keywords.union(common.search_terms.union(common.exclusion_terms))
      
      # terms = set(['tweetdreams', '#tweetdreams', 'music', 'technology', 'participate'])
      # terms = set(['TEDxSV','#TEDxSV','social','innovation','numbers','art','music'])
      # terms = set(['makerfaire','#makerfaire','make','music','technology','participate'])
      # terms = set(['EncounterData', '#EncounterData', 'data','numbers','music','visualization','play'])
      
      print "Starting connection ..."
      ts = tweetstream.FilterStream(username, password, track=terms)
      with ts as stream:
        if stream:
          common.connection = True
          for tweet in stream:
            if tweet.has_key('id') and tweet['id'] not in common.receivedTweetIDs:
              common.receivedTweetIDs.add(tweet['id'])
              parseTweet(tweet)
            #print stream.connected
            #if common.connection == False:
            #  break
    except tweetstream.ConnectionError, e:
        print "Disconnected from twitter. Reason:", e.reason
        print "It should reconnect automatically"
    except tweetstream.AuthenticationError, e:
        print "Disconnected from twitter. ReasonB:", e.reason
        print "It should reconnect automatically"
    #print stream.connected
  print "searching stopped"


#####################################################
# End of methods for consuming the tweet stream
#####################################################








#####################################################
# Utilitary functions
#####################################################

def printTweet(tweet):
  global common, url_patter
  if tweet.has_key('text'):
    print "-"*60
    print tweet['text']
    text = tweet['text'].encode('utf-8')
    # remove URLs from tweets
    text = re.sub(url_pattern, '', text)
    if len(common.clients) > 0: return
    if tweet.has_key('user') and tweet['user'].has_key('screen_name'):
      print "Got tweet from '" + tweet['user']['screen_name'].encode('utf-8') + "' : " + text
    else:
      print "Got tweet from <anonymous> : " + text  

# handle an incomming tweet
def parseTweet(tweet):  
  global url_patter, common
  # sys.stdout.write('.')
  # sys.stdout.flush()
  
  # ignore retweeted messages
  if tweet.has_key('retweeted'):
    if tweet['retweeted']: return
  
  if tweet.has_key('text'):
    # filter out any URL in the tweet
    tweet['text'] = re.sub(url_pattern, '', tweet['text'])
    
    if tweet.has_key('user') and tweet['user'].has_key('screen_name'):
      tweet['text'] = tweet['user']['screen_name'].encode('utf-8') + ": " + tweet['text']
    else:
      tweet['text'] = "anonymous: " + tweet['text']
    
    # For some reason, sometimes we get tweets without any relevant word (why?). 
    # We need to check for that case. Also, we need to distinguish "local" tweets from "world" 
    # tweets
    irrelevant = True
    for term in common.search_terms:
      if tweet['text'].lower().find(term.lower()) >= 0:
        irrelevant = False
        break
    
    tweet['local'] = 0
    for term in common.keywords:
      if tweet['text'].lower().find(term.lower()) >= 0:
        irrelevant = False
        tweet['local'] = 1
        break

    if irrelevant: return    
    
    if tweet['local']:
      common.keywordTweetsQueue.append(tweet)
    else:
      common.newTweetsQueue.append(tweet)

    # printTweet(tweet)

    #print "Number of trees:", len(common.trees)
    #for tree in common.trees:
    #  print "this tree has", tree.numChildren(), "nodes"

#####################################################
# End of Utilitary functions
#####################################################


def waitSomeTime():  
  time.sleep(1)


def main():

  global osc

  # username and password used for autentication
  username = "democratwitt"
  password = "twitit"

  # Start the thread that handles incomming OSC messages
  
  osc.start()
  common.general_dispatcher.start()
  common.keyword_dispatcher.start()
    
  waitSomeTime()

  # start initial tweets
  common.initial_tweets.start()  
  
  # Start the streaming  
  terms = set(sys.argv[1:])
  searchTweets(username, password, terms)
  
def killAll():
  # Remember to stop any Thread you might have running 
  # (you must implement a 'running' attribute in the Thread)
  if osc: osc.running = False
  if common.general_dispatcher: common.general_dispatcher.running = False
  if common.keyword_dispatcher: common.keyword_dispatcher.running = False
  if common.initial_tweets: common.initial_tweets.running = False

# Run the app
if __name__ == '__main__':
  try:
    main()
  except KeyboardInterrupt:
    common.connection = False
    print '\nGoodbye!'
  except SystemExit:
    print "\nQuiting because of SystemExit"
  except:
    print "Unexpected error:", sys.exc_info()[0], sys.exc_info()[1]
    raise
  finally:
    killAll()
    sys.exit(0)
