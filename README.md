TweetDreams
===========

Real-time sonification and visualization of Twitter data.

More information at: https://ccrma.stanford.edu/groups/tweetdreams/


Requirements
------------

You'll need a machine with the following:

1. Python (only 2.6 or 2.7 have been tested), with the `virtualenv` module installed
2. Java
3. Chuck

**Note:** the code should be cross-platform, but it has only been tested in OS X (10.5 and 10.6)


Installation
------------

**1) Get the code**

	> git clone git@github.com:jorgehatccrma/TweetDreams.git
	
or download it from  https://github.com/jorgehatccrma/TweetDreams/zipball/master


**2) Initialize**

Go to the root folder of the downloaded code and type

	> source init.sh
	
(the containing folder will become a virtual python environment and all the dependencies will be 
downloaded and installed in this isolated virtual environment)


**3) Configure for a performance**

In a performance/installation, is possible to run all three parts of in the same machine, but they 
can also run in different machines (or any combination).

The only change required to run TweetDreams in different machine configurations is to specify the 
ip addresses of the involved machines.

(To Do: explain where to change them)

**4) Run it** 
(all these instructions assume you are in the root folder of the virtualenv)

Python server alone:

	> src/python/twt.py
	
Chuck server and client alone:

(To Do)

Java visualizer:

(To Do)




Authors
-------
* Luke Dahl (lukedahl@ccrma.stanford.edu)
* Jorge Herrera (jorgeh@ccrma.stanford.edu)
* Carr Wilkerson (carrlane@ccrma.stanford.edu)
