The Problem
-----------

Why not using `easy_install pyliblo`, you wonder?

Well, `pyliblo` is just a wrapper around `liblo`, a C library. That means that `pyliblo` requires `liblo` to be installed in order to work. One could use `easy_install pyliblo` provided `liblo` is installed in the computer, but:

1. the user would have to install `liblo` first.
2. `easy_install` will look for `liblo` in the default location, which goes against our idea of having an isolated virtual environment.

The Solution
------------

We provide the source code for both `liblo` and `pyliblo` and configure them to install themselves in the isolated virtualenv
