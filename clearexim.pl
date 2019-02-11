#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

# system("/etc/init.d/exim stop");
# sleep 5;

opendir my $dir, "/proc/" or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

foreach my $file (@files) {
  next unless -d "/proc/$file";
  if ($file =~ /\d+/) {
    my $cmd = "/proc/$file/cmdline"; # cmd running for process
    open (my $fh, '<', $cmd) or die "Couldn't open file '$cmd': $!";
    while (my $line = <$fh>) {
      # searching for exim processes to kill
      if ($line =~ /exim/) {
        # send sigkill to process
        kill 9, $file;
      }
    }
    close $fh;
    sleep 5;
    print "Killed exim processes.\n";
    print "Clearing Exim queue... this may take some time.\n";
    # get list of files
    # unlink filename to delete the file ( need to see file structure of /var/spool/exim )

    # if eximstats db exists then delete /var/spool/exim/db files
    # truncate eximstats db tables
    # delete exim message log /var/spool/exim/msglog/

    # start exim
  }
}
