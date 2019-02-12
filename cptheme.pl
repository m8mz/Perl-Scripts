#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

my $cPaneldir = "/var/cpanel/users/";

opendir my $dir, $cPaneldir or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

# check list of files for valid cPanel users and push to the @users array
foreach my $user (@files) {
  # skip files that contains system and the navigation "." and ".."
  next unless $user =~ /^((?!\.|system).*)/;
  my $user_path = $cPaneldir . $user;
  open (my $fh, '<', $user_path) or die "Could not open file '$user_path': $!";
  while (my $row = <$fh>) {
    chomp $row;
    # grab the current theme set
    if ($row =~ /RS=(?<theme>\w+)/) {
      if ($+{theme} ne "paper_lantern") {
        system("whmapi1 modifyacct user=$user RS=paper_lantern &> /dev/null");
				print "Updated cPanel theme for ${user}.\n";
      }
			last;
    }
  }
	close $fh;
}
