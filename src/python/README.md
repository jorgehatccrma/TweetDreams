TweetDreams Python Server
=========================

This component of TweetDreams is in charge of getting real-time tweets (via the Twitter API, using the tweetstream python module).

The tweets are associated by this server and then forwarded to the chuck server (via OSC) for audio synthesis.



Dependencies
------------

In case you want to know, our python tweet server has the following explicit dependencies:

1. `tweetstream`
2. `NumPy`
3. `pyliblo`

But you really shouldn't care, as our init.sh script will take care of installing them for you, in a non-invasive, isolated way, using `virtualenv`


Notes
-----

Currently `NumPy` is a dependency, but that's an overkill. We only need a few, very simple functions implemented in `NumPy`, but to use them the whole `NumPy` module is installed. For the time being, we'll leave it like that, but we should implement the required functions ourselves (or find a lightweight python module to replace `NumPy`).