#!/usr/bin/env perl

use strict;
use warnings;
# use Data::Dumper;

my $file = "newlist";
my $max_number = 250;
my @domains;

open (my $fh, '<', $file) or die "Can't open file '$file': $!";
while (my $row = <$fh>) {
	chomp $row;
	push @domains, $row;
}
close $fh;

# print Dumper \@domains;

while (@domains) {
	my @array;
	for ( my $i = 0; $i < 250; $i++ ) {
		if (@domains) {
			my $domain = shift @domains;
			push @array, $domain;
		} else {
			next;
		}
	}
	# print Dumper \@array;
	my $list = join("', '", @array);
	print qq|SELECT a.id, a.email, b.domain
FROM customer a
INNER JOIN domain b ON a.id = b.account_id
WHERE b.domain in ('$list');\n\n\n|;
	undef @array;
}
