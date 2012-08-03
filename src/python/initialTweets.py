import sys, time
import threading
import common
import random

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
    #print "Starting keyboard listener\n"
    start_messages = ["ccrma: Welcome to TweetDreams! - #EncounterData",
                    "ccrma: TweetDreams makes music from Twitter data - #EncounterData",
                    "ccrma: You can be part of TweetDreams - #EncounterData",
                    "ccrma: Tweet with #EncounterData to play - #EncounterData",
                    "ccrma: Similar tweets create trees of related melodies - #EncounterData",
                    "ccrma: Search terms are shown in the upper left - #EncounterData",
                    "ccrma: What are TweetDreams made of? - #EncounterData",
                    "ccrma: TweetDreams are made of cheese :-P  #EncounterData",
                    ]  
#     start_messages = ["Welcome to #modulations!",
#                     "This piece is called TweetDreams (#modulations)",
#                     "TweetDreams makes music from real-time Twitter data (#modulations)",
#                     "You, the audience, can be part of #TweetDreams (#modulations)",
#                     "When you tweet with the word #modulations you help create TweetDreams",
#                     "All tweets with #modulations are shown and play a melody",
#                     "Similar tweets create trees of related melodies (#modulations)",
#                     "What are TweetDreams made of? (#modulations)",
#                     "TweetDreams are made of #modulations :-/",
#                     "Help, I'm in a petri dish of TweetDreams, and there are #modulations!",
#                     "#modulations is music and technology.  Participate!",
#                     "TweetDreams also uses tweets with other terms (#modulations)",
#                     "Search terms are shown in the upper left (#modulations)",]  
#     start_messages = ["Welcome to #TweetDreams",
#                     "What is #TweetDreams?",
#                     "#TweetDreams makes music from real-time Twitter data",
#                     "I use twitter. How can I be part of #TweetDreams?",
#                     "During a performance anyone can participate by tweeting with the word #TweetDreams",
#                     "What are #TweetDreams made of?",
#                     "#TweetDreams are made of these!",
#                     "I'm in a petri dish full of #TweetDreams!",
#                     "#TweetDreams is interactive art made with technology",
#                     "#TweetDreams was made at CCRMA!",
#                     "#TweetDreams also uses tweets with other terms, such as....", ]  
    self.running = True
    message_id = 0;
    while self.running and message_id < len(start_messages):
      msg = start_messages[message_id]
      # print "adding", msg
      self.queue.append({'text': msg, 'id': message_id+1, 'local': 1})
      #check for keypress every 100 ms
      #sys.stdout.write(".")
      #sys.stdout.flush()
      message_id += 1
      time.sleep( random.uniform( self.min_interval, self.max_interval ) )
    

