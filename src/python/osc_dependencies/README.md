Why not using _easy\_install_ _pyliblo_, you wonder?

Well, pyliblo is just a wrapper around liblo, a C library. That means that pyliblo requires liblo to be installed in orther to work. One could use _easy\_install_ _pyliblo_ provided liblo is installed in the computer, but:

1. the user would have to install liblo first
1. _easy\_install_ will try to look for liblo in the default location, which goes against our idea of having an isolated virtual environment

Solution
--------

We provide the source code for both liblo and pyliblo and configure them to install themselves in the isolated virtualenv
