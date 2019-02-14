#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;

use Digest::MD5;
use File::Find;
use Cwd;
#use Data::Dumper;

my %h; # hash containing key (email address) associated with an array ref that contains a list of email folders (relative path to folder)
my @array1; # TEMP array to sort through emails then gets emptied on each folder iteration

if (getcwd() =~ /^\/home[0-9]?\/\w+\/mail$/) {
        getdir("./");
        foreach my $mailbox (keys %h) { # loop through each mailbox found
                foreach my $folder (@{$h{$mailbox}}) { # loop through each folder that mailbox has
                        getdir($folder);
                        my %hash; # hash to hold MD5 digest of an email and a list of emails that match that digest
                        while (@array1) { # array holds a list of emails for the current folder
                                my $email = pop @array1;
                                open (my $fh, '<', $email) or die "Can't open file '$email': $!";
                                binmode($fh);
                                my $digest = Digest::MD5->new->addfile($fh)->hexdigest; # MD5 digest
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
                                if ($num > 1) { # if the list of emails associated with the hash is greater than 1 means there is duplicates
                                        my @delete_list = splice @{$hash{$k}}, 1; # add all emails except for the first one in the list
                                        my $num_del = unlink @delete_list; # delete list
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
                        if ($File::Find::dir =~ /$path\/(cur|new|tmp)$/) { # prevents find from getting all emails in other folders specifically to fix getting list of emails in the INBOX
                                push @array1, $File::Find::name;
                        }
                }, $path);
        }
}

sub isit_email { # gets the email address and list of email folders
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
