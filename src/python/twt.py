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


# Singleton class to hold common data (used for inter-thread communication)
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
def searchTweets(username, password):
  global common
  while True:
    print "Start searching"
    common.showSearchTerms()
    try:
      terms = common.keywords.union(common.search_terms.union(common.exclusion_terms))
      # terms = set(['tweetdreams', '#tweetdreams', 'music', 'technology', 'participate'])
      # terms = set(['TEDxSV','#TEDxSV','social','innovation','numbers','art','music'])
      # terms = set(['makerfaire','#makerfaire','make','music','technology','participate'])
      terms = set(['EncounterData', '#EncounterData', 'data','numbers','music','visualization','play'])
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
  #print "."
  
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
    
    # For some reason, sometimes we get tweets without any relevant word. 
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

    #printTweet(tweet)

    #print "Number of trees:", len(common.trees)
    #for tree in common.trees:
    #  print "this tree has", tree.numChildren(), "nodes"

#####################################################
# End of Utilitary functions
#####################################################


def waitForTheRest():
  global common
  
  args = sys.argv
  app_name = args.pop(0)
  #print "App name: ", app_name

  common.waitingForChuck = False
  common.waitingForProcessing = False
#  common.waitingForChuck = True
#  common.waitingForProcessing = True
  
  for arg in args:
    if arg == "-c":
      print "Waiting for Chuck registration"
      common.waitingForChuck = True
    elif arg == "-p":
      print "Waiting for Processing registration"
      common.waitingForProcessing = True
    elif arg == "-b":
      print "Waiting for Chuck and Processing registrations"
      common.waitingForChuck = True
      common.waitingForProcessing = True
    else:
      print "Unknown argument", arg

  while common.waitingForChuck or common.waitingForProcessing:
    time.sleep(0.2)
  
  time.sleep(10)


def main():

  global osc

  # username and password used for autentication
  username = "democratwitt"
  password = "twitit"

  # Start the thread that handles incomming OSC messages
  
  osc.start()
  common.general_dispatcher.start()
  common.keyword_dispatcher.start()
  
  ## Chuck is taking care of this now
  #for term in common.keywords: 
  #  oscManager.send_keyword_term(term)
  #for term in common.search_terms: 
  #  oscManager.send_search_term(term)
  
  waitForTheRest()

  # start initial tweets
  common.initial_tweets.start()  
  
  # Start the streaming  
  searchTweets(username, password)
  
def killAll():
  # Remember to stop any Thread you might have running 
  # (you'll have to implement the 'running' attribute in the Thread)
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
