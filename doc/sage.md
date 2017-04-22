## Name

Sage - package manager utility

## Synopsis

    sage <operation> [option] [targets]

## Description

Sage is a package management utility that tracks installed packages on a Cygwin
system. Invoking Sage involves specifying an operation with any potential
options and targets to operate on. A target is usually a package name, file
name, URL, or a search string. Targets can be provided as command line
arguments.

## Operations

* install

  Install package(s).

* remove

  Remove package(s) from the system.

* update

  Download a fresh copy of the master package list (setup.ini) from the server
  defined in setup.rc.

* download

  Retrieve package(s) from the server, but do not install/upgrade anything.

* show

  Display information on given package(s).

* depends

  Produce a dependency tree for a package.

* rdepends

  Produce a tree of packages that depend on the named package.

* list

  Search each locally-installed package for names that match regexp. If no
  package names are provided in the command line, all installed packages will be
  queried.

* listall

  This will search each package in the master package list (setup.ini) for names
  that match regexp.

* category

  Display all packages that are members of a named category.

* listfiles

  List all files owned by a given package.

* search

  Search for downloaded packages that own the specified file(s). The path can be
  relative or absolute, and one or more files can be specified.

* searchall

  Search cygwin.com to retrieve file information about packages. The provided
  target is considered to be a filename and searchall will return the package(s)
  which contain this file.

* mirror

  Set the mirror; a full URL to a location where the database, packages, and
  signatures for this repository can be found. If no URL is provided, display
  current mirror.

* cache

  Set the package cache directory. If a file is not found in cache directory, it
  will be downloaded. Unix and Windows forms are accepted, as well as absolute
  or regular paths. If no directory is provided, display current cache.

* version

  Display version and exit.

## Option

* --nodeps

  Specify this option to skip all dependency checks.
