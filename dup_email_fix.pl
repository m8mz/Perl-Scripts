#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

use Digest::MD5;
use Cwd;

if (getcwd() =~ /^\/home[1-9]\/[a-z0-9]+\/mail\/$/) {
	opendir my $temp_list, "./" or die "Can't open directory: $!";
	my @list = readdir $temp_list;
	closedir $temp_list;

} else {
	print "Must execute script in cPanel user's mail directory. Ex: /home/testuser/mail\n";
}
