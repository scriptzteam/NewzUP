#!/usr/bin/perl

###############################################################################
#     NewzUP - create backups of your files to the usenet.
##############################################################################


use warnings;
use strict;
use utf8;
use 5.018;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Net::NNTP::Uploader;
use NZB::Generator;
use Getopt::Long;
use Config::Tiny;
use Carp;
use File::Glob ':bsd_glob';
use threads;

main();


sub main{

  my ($server, $port, $username, $userpasswd, 
      $filesToUploadRef, $connections, $newsGroupsRef, 
      $commentsRef, $from, $meta)=parse_command_line();

  my @comments = @$commentsRef;
  my ($filesRef,$tempFilesRef) = compress_folders($filesToUploadRef);
  
  $filesRef = distribute_files_by_thread($connections, $filesRef); 

  my @threadsList = ();
  for (my $i = 0; $i<$connections; $i++) {
    push @threadsList, threads->create('start_upload',
				       $server, $port, $username, $userpasswd, 
     				       $filesRef->[$i], $connections, $newsGroupsRef, 
     				       $commentsRef, $from);    
    
  }

  my @nzbFilesList = ();
  for (my $i = 0; $i<$connections; $i++){
    push @nzbFilesList, $threadsList[$i]->join();
  }

  for my $tempFileName (@$tempFilesRef) {
    unlink $tempFileName;
  }

  my $nzbGen = NZB::Generator->new();
  say $nzbGen->create_nzb(\@nzbFilesList, $meta), " created!";

}

#Creates the required objects to upload and starts the upload
sub start_upload{

  my ($server, $port, $username, 
      $userpasswd, $filesToUploadRef, 
      $connections, $newsGroupsRef, $commentsRef, $from) = @_;

  my @comments = @$commentsRef;
  
  my $up = Net::NNTP::Uploader->new($server,$port,$username,$userpasswd);

  my ($initComment, $endComment);
  if ($#comments+1==2) {
    $initComment = $comments[0];
    $endComment = $comments[1];
  }elsif ($#comments+1==1) {
    $initComment = $comments[0];
  }

  my @filesList = $up->upload_files($filesToUploadRef,$from,$initComment,$endComment ,$newsGroupsRef);
  return @filesList;

}

#Checks if every element in the listRef is a directory.
#If it is a directory it compresses it in files of 10Megs
#Returns a list of the actual files to be uploaded and a list of the files created (so they can be removed later)
sub compress_folders{
  
  my $command = '7z a -mx0 -v10m "%s.7z" "%s"';
  my @files = @{shift()};
  my @realFilesToUpload = ();
  my @tempFiles = ();

  for my $file (@files){

    if (-d $file) {
      $file =~ s/\/\z//;
      system(sprintf($command, $file, $file));
      my @expandedCompressFiles = bsd_glob("$file.7z*");
      push @realFilesToUpload, @expandedCompressFiles;
      push @tempFiles, @expandedCompressFiles;
	
    }else {
      push @realFilesToUpload, $file;
    }
    
  }

  return (\@realFilesToUpload,\@tempFiles);

}

#Returns a bunch of options that it will be used on the upload. Options passed through command line have precedence over
#options on the config file
sub parse_command_line{

  my ($server, $port, $username, $userpasswd, @filesToUpload, $threads, @comments, $from);
  my @newsGroups = ();
  my $config = Config::Tiny->read( $ENV{"HOME"}.'/.config/newzup.conf' );
  my %metadata = %{$config->{metadata}};


  GetOptions('server=s'=>\$server,
	     'port=i'=>\$port,
	     'username=s'=>\$username,
	     'password=s'=>\$userpasswd,
	     'file=s'=>\@filesToUpload,
	     'comment=s'=>\@comments,
	     'uploader=s'=>\$from,
	     'newsgroup|group=s'=>\@newsGroups,
	     'connections'=>\$threads,
	     'metadata=s'=>\%metadata,);
  
  if (!defined $server) {
    $server = $config->{server}{server};
  }
  if (!defined $port) {
    $port = $config->{server}{port};
  }
  if (!defined $username) {
    $username = $config->{auth}{user};
  }
  if (!defined $userpasswd) {
    $userpasswd = $config->{auth}{password};
  }
  if (!defined $from) {
    $from = $config->{upload}{uploader};
  }

  $threads = $config->{server}{connections};

  if ($threads < 1) {
    croak "Please specify a correct number of connections!";    
  }

  if (@newsGroups==0) {
    croak "Please specify at least one news group!";
  }

  return ($server, $port, $username, $userpasswd, 
	  \@filesToUpload, $threads, \@newsGroups, 
	  \@comments, $from, \%metadata);
}

# takes number+arrayref, returns ref to array of arrays
sub distribute_files_by_thread {
    my ($threads, $array) = @_;

    my @parts;
    my $i = 0;
    foreach my $elem (@$array) {
        push @{ $parts[$i++ % $threads] }, $elem;
    };
    return \@parts;
};


