# Change Directory Quickly

This bash script and its companion perl script:
* Hook builtin shell commands changing current directory (`cd`, `pushd`, `popd`) to memorize directories jumped to.
* Add a builtin (`cdq`) displaying all memorized directories and prompting user for a directory to jump to.

## Installation

Download:

    $ cd ~/somewhere
    $ git clone https://github.com/nthery/cdq.git

Add following to `~/.bashrc`:

    . ~/somewhere/cdq/cdq.sourceme.bash

## Tutorial: memorizing directories in global file

Let's create a few directories:

    $ cd /tmp
    $ mkdir -p this/is/a/dir
    $ mkdir -p this/is/another/dir

The cd command silently memorizes where it jumps to:

    $ cd this/is/a/dir
    $ cd ../../another/dir
    $ cd ../../../..
    $ pwd
    /tmp

The `cdq` command lists all directories jumped to so far and prompts for a
directory to jump to:

    $ cdq
    1) /tmp
    2) /tmp/this/is/another/dir
    3) /tmp/this/is/a/dir
    #? 3

    $ pwd
    /tmp/this/is/a/dir

The `cdq` command lists the most frequently cd'ed to directories first:

    $ cd `pwd`
    $ cd `pwd`
    $ cd `pwd`

    $ cdq
    1) /tmp/this/is/a/dir
    2) /tmp
    3) /tmp/this/is/another/dir
    #? 2

The memorized directories are stored with their usage count in the home directory:

    $ cat ~/.cdq_global_dirs
    5       /tmp/this/is/a/dir
    1       /tmp/this/is/another/dir
    2       /tmp

Let's create a project tree:

    $ mkdir -p prj/this/is/a/dir
    $ mkdir -p prj/this/is/another/dir

 Let's create a local file for storing memorized directories at the root of
 this project tree:

    $ touch prj/.cdq_local_dirs

Let's jump around in this project:

    $ cd prj/this/is/a/dir
    $ cd ../../another/dir

When inside the project tree, `cdq` display both local and global memorized directories:

    $ cdq
    1) /tmp/prj/this/is/another/dir  4) /tmp
    2) /tmp/prj/this/is/a/dir        5) /tmp/this/is/another/dir
    3) /tmp/this/is/a/dir
    #? 4

    $ pwd
    /tmp

When outside a project tree, `cdq` displays only the global directories:

    $ cdq
    1) /tmp/this/is/a/dir
    2) /tmp
    3) /tmp/this/is/another/dir
