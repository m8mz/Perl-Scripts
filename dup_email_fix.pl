#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

use Digest::MD5;
use File::Find;
use Cwd;
use Data::Dumper;

my @array; # array containing hashes of dirnames (email username) and dirpaths (full relative path to email user)
my %hash; # hash that will contain MD5 of email and the full path to email

if (getcwd() =~ /^\/home[0-9]?\/\w+\/mail$/) {
        getdir("./");
        foreach my $mailbox (@array) {
                getdir($mailbox->{'dirpath'});
        }
} else {
        print "Must execute script in cPanel user's mail directory. Ex: /home/testuser/mail\n";
}


# Sub-routines

sub getdir {
        my $path = shift;
        if ($path eq "./") {
                find(\&isit_email, $path);
        } else {
                find(\&get_email_list, $path);
        }
}

sub isit_email {
        my $item = $_;
        my $fullpath = $File::Find::name;
        if (-d $item) {
                if ($fullpath =~ /^\.\/\w+\.\w+\/\w+$/) {
                        push @array, { dirname => $item, dirpath => $fullpath };
                }
        }
}

sub get_email_list {
        my $item = $_;
        my $fullpath = $File::Find::name;
        if ($fullpath =~ /cur\/.*/) {
                print "$item\n";
                print "$fullpath\n";
                push @array
        }
}
