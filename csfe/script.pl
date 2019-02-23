#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname( abs_path $0 ) . '/lib';

use CSFE;

my $check = check_config();
my ($key, $value) = keys %{$check};

if ($key) {
	print "$value!\n";
} else {
	my $r = set_config('user', { username => 'marcus' });
}

my $hash = get_all_config();
foreach my $k (keys %{$hash}) {
	if (defined $hash->{$k}) {
		print $hash->{$k}, "\n";
	} else {
		warn "Empty value for key $k\n";
	}
}
