*TweetDreams*
=============

Real-time sonification and visualization of Twitter data.

More information at: [http://ccrma.stanford.edu/groups/tweetdreams/](https://ccrma.stanford.edu/groups/tweetdreams/)


Requirements
============

You'll need a machine with the following:

1. Python (only 2.6 or 2.7 have been tested)
1. Python's `virtualenv` module installed
1. Java
1. Chuck

**Note:** the code should be cross-platform, but it has only been tested in OS X (10.5 and 10.6)


Installation / Set Up / Perform
===============================

1) Get the code
---------------

	> git clone git@github.com:jorgehatccrma/TweetDreams.git

or download it from  https://github.com/jorgehatccrma/TweetDreams/zipball/master


2) Initialize the Virtual Environment
-------------------------------------

Go to the root folder of the downloaded code and type

	> source init.sh

(the containing folder will become a virtual python environment and all the dependencies will be
downloaded and installed in this isolated virtual environment)


3) Configuring a performance
----------------------------

 * In a performance/installation, is possible to run all three parts (visual, audio, *tweet server*) in the same machine, but they
can also run in different machines (or any combination).
The only change required to run *TweetDreams* in different machine configurations is to specify the
ip addresses of the involved machines.

 * **Local Term:** this is the term, usually a *hash-tag* (e.g. #TweetDreams), that will be treated with
particular prominence during the performance.
This term is specified as an argument passed to the launch script (see next section)

 * **Search terms:** tweets containing any of these terms will also be displayed during the performance.
To change them, edit the `search_terms.txt` file in the root folder. Is also possible to specify a
different file (see next section).

 * **IP addresses:** If different parts of *TweetDreams* are run in different machines, each one needs to
know the IP addresses where the others are running.

 * **Initial Tweets:** Is possible to pre-define a set of "fake" tweets to be displayed at the beginning of the performance. These are defined in `initial_tweets.txt`.

 * **Banned terms:** For some performances we have been asked to remove some offensive words. The words declared in the `offensive_words.txt` file will be replaced with as many asterisks (*) as letters in the word.


4) Run it
---------
To run *TweetDreams*, run the `startDreaming.py` script from the root folder:

	> python startDreaming.py -l \#YourHashTag -j 192.168.1.2

**Note:** the *backslash* (\\) is only necessary to escape the pound (#) symbol. If you don't want a pound symbol in you *local_term*, then you need to omit the \\.

The above example will launch the tweets server (python) and sound (chuck) server locally (localhost) and will send OSC
messages to the visualizer (java) app running at 192.168.1.2.

There are many other arguments that can be passed to this script. For a complete list run:

	> python startDreaming.py -h


5) Interactions
---------------

### Audio (ChucK)

 * `1/2`: available waveforms for next tree
 * `3/4`: available melodies for next tree
 * `5/6`: the timing for the next tree
 * `7/8`: the mode for the next tree (currently I think should stay in one mode)
 * `9/0`: increase/decrease the dry level for all sounds

### Tweets (Python)

 * `g/h`: inc/dec min global queue time (by 100 msec)
 * `j/k`: inc/dec max global queue time (by 100 msec)
 * `z,x,v,b,n,m`: (bottom row of keyboard) add/remove search terms

### Visuals (Java+Processing)

 * `i/o`: zoom in/out
 * `w/a`: horizontal plane spin
 * `a/d`: vertical plane spin

You can also control the following parameter using a MIDI device:

 * zoom
 * spin-x
 * spin-y
 * root-length
 * tree-length
 * text-size
 * "trace"
 * drag (viscosity)

For details dig into `src/java/src/MidiManager.java`.


Authors
=======
* Luke Dahl (lukedahl@ccrma.stanford.edu)
* Jorge Herrera (jorgeh@ccrma.stanford.edu)
* Carr Wilkerson (carrlane@ccrma.stanford.edu)
