import sys, time
import threading
import common
import random
import os

class InitialTweets(threading.Thread):

  def __init__(self, queue, min_interval, max_interval):
    # assign the corresponding queue
    self.queue = queue
    
    # interval between initial tweets
    self.min_interval = min_interval
    self.max_interval = max_interval

    # call the thread initializer
    threading.Thread.__init__(self)
    
  def run(self):
    start_messages = open(os.path.join(sys.prefix,'initial_tweets.txt'), 'r').readlines()
    common.log("Starting initial tweets\n")
    self.running = True
    message_id = 0;
    while self.running and message_id < len(start_messages):
      msg = start_messages[message_id]
      # print "adding", msg
      self.queue.append({'text': msg, 'id': message_id+1, 'local': 1})
      message_id += 1
      time.sleep( random.uniform( self.min_interval, self.max_interval ) )
    

