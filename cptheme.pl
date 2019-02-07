#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

my $cPaneldir = "/var/cpanel/users";
my @users;

opendir my $dir, $cPaneldir or die "Cannot open directory: $!";
my @files = readdir $dir;

# check each file for valid cPanel users and push to the @users array
foreach my $file (@files) {
	next unless $file =~ /^((?!\.|system).*)/;
	push @users, $1;
}

print "$_\n" foreach(@users);
closedir $dir;
