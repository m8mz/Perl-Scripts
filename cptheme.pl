#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

my $cPaneldir = "/var/cpanel/users/";
#my @users;

opendir my $dir, $cPaneldir or die "Cannot open directory: $!";
my @files = readdir $dir;

# check list of files for valid cPanel users and push to the @users array
foreach my $file (@files) {
        next unless $file =~ /^((?!\.|system).*)/;
        $file = $cPaneldir . $file;
        open (my $fh, '<', $file) or die "Could not open file '$file': $!";
        while (my $row = <$fh>) {
                chomp $row;
                if ($row =~ /RS=(?<theme>\w+)/) {
                        print "$+{theme}\n";
                }
        }
        close $fh;
}

closedir $dir;
