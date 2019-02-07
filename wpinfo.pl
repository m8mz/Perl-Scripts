#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

my $config = 'wp-config.php';
my $hashref;

open(my $fh, '<', $config)
	or die "Could not open file '$config': $!";

while (my $line = <$fh>) {
	chomp $line;
	# (?<capture name>.*)
	my @match = $line =~ /^define\(\s*['"](?<key>DB_[NUPH]\w+)['"],\s*['"](?<value>.*)['"]/;
	# Group 1 grabs the key and group 2 has the value
	foreach (@match) {
		$hashref->{$+{"key"}} = $+{"value"};
	}
}
# close opened file
close $fh;

printf("Database: %-10s\nUsername: %-20s\nPassword: %-25s\nHost: %-15s\n", $hashref->{DB_NAME}, $hashref->{DB_USER}, $hashref->{DB_PASSWORD}, $hashref->{DB_HOST});
