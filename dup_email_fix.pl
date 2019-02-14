#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

use Digest::MD5;
use File::Find;
use Cwd;
#use Data::Dumper;

my %h; # hash containing key (email address) associated with an array ref that contains a list of emails (full relative path to email)
my @array1; # TEMP array to sort through emails then gets emptied on each folder iteration

if (getcwd() =~ /^\/home[0-9]?\/\w+\/mail$/) {
        getdir("./");
        foreach my $mailbox (keys %h) {
                foreach my $folder (@{$h{$mailbox}}) {
                        getdir($folder);
                        my %hash;
                        while (@array1) {
                                my $email = pop @array1;
                                open (my $fh, '<', $email) or die "Can't open file '$email': $!";
                                binmode($fh);
                                my $digest = Digest::MD5->new->addfile($fh)->hexdigest;
                                close $fh;
                                if ($hash{$digest}) {
                                        # push to existing key
                                        push($hash{$digest}, $email);
                                } else {
                                        # initiate new key and add email
                                        $hash{$digest} = [$email];
                                }
                        }
                        foreach my $k (keys %hash) {
                                my $num = @{$hash{$k}};
                                if ($num > 1) {
                                        my @delete_list = splice @{$hash{$k}}, 1;
                                        my $num_del = unlink @delete_list;
                                        print "Deleted $num_del duplicate emails in $mailbox.\n";
                                }
                        }
                }
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
                find(sub {
                        if ($File::Find::dir =~ /$path\/(cur|new|tmp)$/) {
                                push @array1, $File::Find::name;
                        }
                }, $path);
        }
}

sub isit_email {
        my $item = $_;
        my $fullpath = $File::Find::name;
        if (-d $item) {
                if ($fullpath =~ /^\.\/(?<domain>\w+\.\w+)\/(?<user>\w+)($|\/\.\w*$)/) {
                        if ($h{"$+{user}\@$+{domain}"}) {
                                push $h{"$+{user}\@$+{domain}"}, $fullpath;
                        } else {
                                $h{"$+{user}\@$+{domain}"} = [$fullpath];
                        }
                }
        }
}
