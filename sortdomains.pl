#!/usr/bin/env perl

# https://tld-list.com/tlds-from-a-z

use strict;
use warnings;
use Data::Dumper;

my @domains;
my $file = "domains.txt";

open ( my $fh, '<', $file ) or die "Could not open file '$file': $!";

while ( my $item = <$fh> ) {
  chomp $item;
  push @domains, $item;
}

close $fh;

#print Dumper \@domains;

my @ref;
foreach my $item (@domains) {
  my @entry = reverse split /\./, $item, 3;
  $entry[2] = defined($entry[2]) ? $entry[2] : "";
  push @ref, {
    tld => $entry[0],
    domain => $entry[1],
    subdomain => $entry[2],
  }
}

#print Dumper \@ref;

my @sorted = sort {
  $a->{'tld'} cmp $b->{'tld'} ||
  $a->{'domain'} cmp $b->{'domain'} ||
  $a->{'subdomain'} cmp $b->{'subdomain'}
} @ref;

print Dumper \@sorted;
