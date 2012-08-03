import re
import porter
from numpy import zeros,dot
from numpy.linalg import norm

__all__=['compare']

# import real stop words
stop_words = [ 'i', 'in', 'a', 'to', 'the', 'it', 'have', 'haven\'t', 'was', 'but', 'is', 'be', 'from' ]
#stop_words = [w.strip() for w in open('english.stop','r').readlines()]
#print stop_words

splitter=re.compile ( "[a-z\-']+", re.I )
stemmer=porter.PorterStemmer()

def add_word(word,d):
 """
    Adds a word the a dictionary for words/count
    first checks for stop words
	the converts word to stemmed version
 """
 w=word.lower() 
 if w not in stop_words:
  ws=stemmer.stem(w,0,len(w)-1)
  d.setdefault(ws,0)
  d[ws] += 1

def doc_vec(doc,key_idx):
 v=zeros(len(key_idx))
 for word in splitter.findall(doc):
  keydata=key_idx.get(stemmer.stem(word,0,len(word)-1).lower(), None)
  if keydata: v[keydata[0]] = 1
 return v

def compare(doc1,doc2):

 # strip all punctuation but - and '
 # convert to lower case
 # store word/occurance in dict
 all_words=dict()

 for dat in [doc1,doc2]:
  [add_word(w,all_words) for w in splitter.findall(dat)]
 
 # build an index of keys so that we know the word positions for the vector
 key_idx=dict() # key-> ( position, count )
 keys=all_words.keys()
 keys.sort()
 #print keys
 for i in range(len(keys)):
  key_idx[keys[i]] = (i,all_words[keys[i]])
 del keys
 del all_words

 v1=doc_vec(doc1,key_idx)
 v2=doc_vec(doc2,key_idx)
 return float(dot(v1,v2) / (norm(v1) * norm(v2)))
 
 
if __name__ == '__main__':
 print "Running Test..." 
 doc1="I like to eat chicken\nnoodle soup."
 doc2="I have read the book \"Chicken noodle soup for the soul\"."
 print "Using Doc1: %s\n\nUsing Doc2: %s\n" % ( doc1, doc2 )
 print "Similarity %s" % compare(doc1,doc2)

 print "Running Test..." 
 doc1="I like to eat chicken\nnoodle soup."
 doc2="have read the book \"soul\"."
 print "Using Doc1: %s\n\nUsing Doc2: %s\n" % ( doc1, doc2 )
 print "Similarity %s" % compare(doc1,doc2)


