NewzUP
======

NewzUP a binary usenet uploader/poster. Backup your personal files to the usenet!
It will run on any platform that supports perl (Windows, *nix, bsd)

# Intro

This program will upload binary files to the usenet and generate a NZB file. It supports SSL and multiple connections.
This program is licensed with GPLv3.

# What does this program do

It will upload a file or folder to the usenet. 
If it is a folder it will create a 7zip archive (it can consist of multiple 10Megs file with *no password*).
The compressed format will be 7z (although it won't really compress. The level of compression is 0).
A NZB file will be generated for later retrieving.

## What doesn't do

* Create archive passworded files 
* Create compressed archive files to upload [1]
* Create rars [1]
* Create zips [1]
* Create parity archives


### Notes
1- If you are uploading a folder it will create a 7zip file containing the folder and all the files inside. This 7zip will be split in 10 meg volumes.
The 7zip will not have any password and no compression.


#Requirements:
* Perl (5.018 -> i can change it to a version >= 5.10)
* Perl modules: Config::Tiny, IO::Socket::SSL, String::CRC32, XML::LibXML (all other modules should exist on core.)

# Installation
1. Check if you have all the requirements installed.
2. Copy the sample.conf file ~/.config/newzup.conf and edit the options as appropriate. This step is optional since everything can be done by command line.

# Running
The most basic way to run it (please check the options section) is:
$ perl newzup.pl -file my_file -con 2 -news alt.binaries.test

Everytime the newzup runs, it will create a NZB file for later retrieval of the uploaded files. The filename will consist on the unixepoch of the creation.


## Options

## Config file
This file doesn't support all the options of the command line. Everytime an option from the command line and an option from the config file, the command line takes precedence.
Check sample newzup.conf for the available options

### Command line options

-username: credential for authentication on the server.

-password: credential for authentication on the server.

-server: server where the files will be uploaded to (SSL supported)

-port: port. For non SSL upload use 119, for SSL upload use 563 or 995

-file: the file or folder you want to upload. You can have as many as you want. If the you're uploading a folder then it will compress it and split it in files of 10Megs for uploading. These temp files are then removed. 

-comment: comment. Subject will have your comment. You can use two. The subject created will be something like "[first comment] my file's name [second comment]"

-uploader: the email of the one who is uploading, so it can be later emailed for whoever sees the post. Usually this value is a bogus one.

-newsgroup: newsgroups. You can have as many as you want. This will crosspost the file.

-groups: alias for newsgroups option

-connections: number of connections (or threads) for uploading the files (default: 2). Tip: you can use this to throttle your bandwidth usage :-P

-metadata: metadata for the nzb. You can put every text you want! Example: 
```bash
-metadata powered=newzup -metadata subliminar_message="NewzUP: the best usenet autoposter crossplatform"
```

The NZB file It will have on the ```<head>``` tag the childs:
```html 
<metadata type="powered">NewzUP</metadata>
<metadata type="subliminar_message">NewzUP: the best usenet autoposter crossplatform</metadata>