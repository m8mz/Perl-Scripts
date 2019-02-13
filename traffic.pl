#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;
use Data::Dumper;

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
		my $log = "${dir_path}/${item}";
		my $filesize = -s $log;
		if ($filesize > 20000) {
			my %hash = (
				IP => [],
				typeofRequest => [],
				content => [],
				referrer => [],
				userAgent => [],
			);
			open(my $fh, '<', $log) or die "Could not open file '$log': $!";
			while (my $line = <$fh>) {
				chomp $line;
				if ($line =~ /(?<IP>(\d{1,3}.){3}\d{1,3}).*"(?<typeRequest>GET|POST)\s(?<content>\S*).*?"\s\d*\s\d*\s"(?<referrer>\S*)"\s"(?<userAgent>.*\))/) {
					push @{$hash{'IP'}}, $+{IP};
					push @{$hash{'typeofRequest'}}, $+{typeRequest};
					push @{$hash{'content'}}, $+{content};
					push @{$hash{'referrer'}}, $+{referrer};
					push @{$hash{'userAgent'}}, $+{userAgent};
				}
			}
			close $fh;
			print uc "$log\n";
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
		} else {
			print "\n\nFilesize under 20K.. skipping $log.\n\n";
			next;
		}
	}
}


# Sub-routines

sub countit {
	my $array = shift;
	my %temp;
	my @top10;
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
