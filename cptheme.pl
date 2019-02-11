#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

# my $cPaneldir = "/var/cpanel/users/";
my $cPaneldir = "./users/";
#my @users;

opendir my $dir, $cPaneldir or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

# check list of files for valid cPanel users and push to the @users array
foreach my $file (@files) {
  # skip files that contains system and the navigation "." and ".."
  next unless $file =~ /^((?!\.|system).*)/;
  $file = $cPaneldir . $file;
  open (my $fh, '<', $file) or die "Could not open file '$file': $!";
  while (my $row = <$fh>) {
    chomp $row;
    # grab the current theme set
    if ($row =~ /RS=(?<theme>\w+)/) {
      if ($+{theme} ne "paper_lantern") {
        # do the whmapi1 call to update theme
      }
    }
  }
close $fh;
}
