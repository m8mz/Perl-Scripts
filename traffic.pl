#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long qw(GetOptions);

my $regex = qr{(?<IP>(\d{1,3}.){3}\d{1,3}).*"(?<typeRequest>GET|POST)\s(?<content>\S*).*?"\s\d*\s(\d*|-)\s"(?<referrer>\S*)"\s"(?<userAgent>(.*\)|-))};

my $log_dir = (-d "/etc/httpd/domlogs") ? '/etc/httpd/domlogs' : '/etc/apache2/logs/domlogs';


opendir my $log_dirs, $log_dir or die "Can't open directory: $!";
my @logdir_list = readdir $log_dirs;
closedir $log_dirs;

foreach my $dir_name (@logdir_list) {
        next if $dir_name =~ /^((\.).*)/;
        my $dir_path = "${log_dir}/${dir_name}";
        next if (-f $dir_path); # skip if result is a file
        opendir my $temp_list, $dir_path or die "Can't open directory: $!";
        my @list = readdir $temp_list;
        closedir $temp_list;
        foreach my $item (@list) {
                next if $item =~ /^((\.).*)/;
                next if $item =~ /.*-ssl_log/;
                my $log = "${dir_path}/${item}";
                my $ssllog = $log . "-ssl_log";
                my @logs = ( $log, $ssllog );
                my %hash = (
                        IP => [],
                        typeofRequest => [],
                        content => [],
                        referrer => [],
                        userAgent => [],
                );
                foreach my $file (@logs) {
                        open(my $fh, '<', $file) or die "Could not open file '$file': $!";
                        while (my $line = <$fh>) {
                                chomp $line;
                                if ($line =~ $regex) {
                                        push @{$hash{'IP'}}, $+{IP};
                                        push @{$hash{'typeofRequest'}}, $+{typeRequest};
                                        push @{$hash{'content'}}, $+{content};
                                        push @{$hash{'referrer'}}, $+{referrer};
                                        push @{$hash{'userAgent'}}, $+{userAgent};
                                }
                        }
                        close $fh;
                }
                print uc "$item\n";
                print "\tTop 10 IP Addresses:\n";
                countit($hash{'IP'});
                print "\n\tNum. of Request Types:\n";
                countit($hash{'typeofRequest'});
                print "\n\tTop 10 Resources:\n";
                countit($hash{'content'});
                print "\n\tTop 10 Referrer:\n";
                countit($hash{'referrer'});
                print "\n\tTop 10 UserAgents:\n";
                countit($hash{'userAgent'});
                print "\n\n\n";
        }
}



# Sub-routines

sub countit {
        my $array = shift;
        my %temp;
        $temp{$_}++ foreach (@{$array});
        my $count = 0;
        foreach my $name (reverse sort { $temp{$a} <=> $temp{$b} } keys %temp) {
                if ($count < 9) {
                        printf "\t%8d: %-50s\n", $temp{$name}, $name;
                        ++$count;
                } else {
                        last;
                }
        }
}
