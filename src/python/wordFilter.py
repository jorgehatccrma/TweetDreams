# Class to replace (offensive) words with '*'

import re
import sys
import os

#print "DEBUG", sys.prefix

offensive_words = open(os.path.join(sys.prefix,'offensive_words.txt'), 'r').read().split()

def printWords():
  for w in offensive_words:
    print w
  
def filter( text ):
  for w in offensive_words:
    r = re.compile(w, re.IGNORECASE)
    text = r.sub('*'*len(w), text, 0)
  return text
    
    
