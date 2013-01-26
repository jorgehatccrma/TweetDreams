#!/usr/bin/env python

"""
"""

import tweetstream
import oscManager
import common
import initialTweets
import sys
# import liblo, sys
# import random
import traceback
import time
import dispatcher
import re
# from collections import deque


# Handles OSC communication
osc = oscManager.OSCManager()

# To delay the tweets and send them one at a time (random wait between 0.5 and 1.5 seconds)
common.general_dispatcher = dispatcher.Dispatcher("general dispatcher", osc, common.newTweetsQueue, 0.5, 1.5)
common.keyword_dispatcher = dispatcher.Dispatcher("keyword dispatcher", osc, common.keywordTweetsQueue)

# process to trigger the initial fake tweets
common.initial_tweets = initialTweets.InitialTweets(common.keywordTweetsQueue, 5.0, 7.0)

# URL pattern (used to remove URLs from tweets)
url_pattern = re.compile('(https?://)(www\.)?([a-zA-Z0-9_%\.]*)([a-zA-Z]{2})?((/[a-zA-Z0-9_%~]*)+)?(\.[a-zA-Z]*)?(\?([a-zA-Z0-9_%~=&])*)?')


#####################################################
# Different methods to consume the stream of tweets
#####################################################
# only tweets containing at least one of the provided terms
def searchTweets(username, password, terms):
    global common
    while True:
        try:
            # This was an old hack, but I don't think we use it anymore
            #terms = common.keywords.union(common.search_terms.union(common.exclusion_terms))

            common.log("Starting connection ...\n")
            ts = tweetstream.FilterStream(username, password, track=terms)
            with ts as stream:
                if stream:
                    common.connection = True
                    for tweet in stream:
                        if ('id' in tweet) and (tweet['id'] not in common.receivedTweetIDs):
                            common.receivedTweetIDs.add(tweet['id'])
                            parseTweet(tweet)
        except tweetstream.ConnectionError, e:
                common.log("Disconnected from twitter. Reason: %s\n" % (e.reason))
                common.log("It should reconnect automatically\n")
        except tweetstream.AuthenticationError, e:
                common.log("Disconnected from twitter. Reason: %s\n" % (e))
                common.log("It should reconnect automatically\n")
    common.log("Twitter stream stopped\n")


#####################################################
# End of methods for consuming the tweet stream
#####################################################

#####################################################
# Utility functions
#####################################################

def printTweet(tweet):
    global common, url_patter
    if 'text' in tweet:
        common.log("-" * 60 + "\n")
        common.log(tweet['text'] + "\n")
        text = tweet['text'].encode('utf-8')
        # remove URLs from tweets
        text = re.sub(url_pattern, '', text)
        if len(common.clients) > 0:
            return
        if ('user' in tweet) and ('screen_name' in tweet['user']):
            common.log("Got tweet from '" + tweet['user']['screen_name'].encode('utf-8') + "' : " + text + "\n")
        else:
            common.log("Got tweet from <anonymous> : " + text + "\n")


# handle an incoming tweet
def parseTweet(tweet):
    global url_patter, common
    # sys.stdout.write('.')
    # sys.stdout.flush()

    # ignore retweeted messages
    if 'retweeted' in tweet:
        if tweet['retweeted']:
            return

    # TODO: should we filter out non-english messages?
    # in theory we could use the 'lang' attibute, but many non-english
    # tweets use lang=en anyways, so is not very robust.
    # A more scientific was is to use a language detection tool, such as https://github.com/saffsd/langid.py

    if 'text' in tweet:
        # filter out any URL in the tweet
        tweet['text'] = re.sub(url_pattern, '', tweet['text'])
        #replace &gt and &lt (TODO: are there other special characters for Twitter? Should we use some generic HTML decoding?)
        tweet['text'] = tweet['text'].replace('&lt;', '<')
        tweet['text'] = tweet['text'].replace('&gt;', '>')

        if ('user' in tweet) and ('screen_name' in tweet['user']):
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

        if irrelevant:
            return

        if tweet['local']:
            common.keywordTweetsQueue.append(tweet)
        else:
            common.newTweetsQueue.append(tweet)

        # printTweet(tweet)

        #common.log("Number of trees:" + len(common.trees) + "\n")
        #for tree in common.trees:
        #    common.log("this tree has" + tree.numChildren() + "nodes\n")

#####################################################
# End of Utility functions
#####################################################


def waitSomeTime():
    time.sleep(10)


def main():

    global osc

    # username and password used for authentication
    if len(sys.argv) < 3:
        print "I need valid twitter account credentials!"
        return 1
    username = sys.argv[1]
    password = sys.argv[2]

    if len(sys.argv) > 3:
        common.register(sys.argv[3])

    common.log("Clients: " + "\n".join(common.clients))

    # Start the thread that handles incoming OSC messages
    osc.start()
    common.general_dispatcher.start()
    common.keyword_dispatcher.start()

    # dramatic pause!
    waitSomeTime()

    # start initial (fake) tweets
    common.initial_tweets.start()

    # Start the streaming
    terms = set(sys.argv[4:])
    searchTweets(username, password, terms)


def killAll():
    # Remember to stop any Thread you might have running
    # (you must implement a 'running' attribute in the Thread)
    if osc:
        osc.running = False
    if common.general_dispatcher:
        common.general_dispatcher.running = False
    if common.keyword_dispatcher:
        common.keyword_dispatcher.running = False
    if common.initial_tweets:
        common.initial_tweets.running = False

# Run the app
if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        common.connection = False
        common.log('\nGoodbye!\n')
    except SystemExit:
        common.log("\nQuiting because of SystemExit\n")
    except:
        common.log("Unexpected error: %s %s\n" % (sys.exc_info()[0], sys.exc_info()[1]))
        traceback.print_exc()
        raise
    finally:
        killAll()
        sys.exit(0)
