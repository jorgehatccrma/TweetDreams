# Class to replace (offensive) words with '*'

import re
import sys
import os
import common

offensive_words = open(os.path.join(sys.prefix,'offensive_words.txt'), 'r').read().split()

def printWords():
  common.log("List of offensive words: " + ", ".join(offensive_words))
  
def filter( text ):
  for w in offensive_words:
    r = re.compile(w, re.IGNORECASE)
    text = r.sub('*'*len(w), text, 0)
  return text
    
    
