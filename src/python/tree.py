# The tree can be implemented easily by abstracting the class Node
# See the example at the bottom

class Node(object):
  def __init__(self, tweet, parent = None):
    self.tweet = tweet
    self.children = []
    self.parent = parent

  def addChild(self, obj):
    if type(obj) is not Node:
      print "I was expecting a node!!!"
      return
    self.children.append(obj)
    obj.parent = self
  
  def display(self, level = 0):
    print "-"*level + ">", self.tweet
    for c in self.children:
      c.display(level+2)
  
  def traverseUp(self, level = 0):
    print "-"*level + ">", self.tweet
    if self.parent == None:
      return
    self.parent.traverseUp(level+2)
  
  def numChildren(self):
    num = 1
    for child in self.children:
      num += child.numChildren()
    return num
  
  def getUpperNodes(self, level = 1):
    if self.parent == None:
      return [self.tweet['id'],]
    following_nodes = self.parent.getUpperNodes(level+1)
    following_nodes.append(self.tweet['id'])
    return following_nodes




if __name__ == '__main__':
  
  n1 = Node("Tweet obj 1")
  n2 = Node(2)
  n3 = Node(3.0)
  n4 = Node(True)
  n5 = Node("Some other object")
  n6 = Node("etc.")
  n7 = Node(False)
  
  n1.addChild(n2)
  n1.addChild(n3)
  n2.addChild(n4)
  n2.addChild(n5)
  n3.addChild(n6)
  n3.addChild(n7)
  
  print "\nContents of n1:"
  n1.display()
  
  print ""
  print "+"*10
  print "\nNow traversing up n7:"
  
  n7.traverseUp()
  