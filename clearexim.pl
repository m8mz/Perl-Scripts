#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;
# use Data::Dumper;

my $input_dir = "/var/spool/exim/input";
my $msglog_dir = "/var/spool/exim/msglog";
my @email_list;

system("/etc/init.d/exim stop");
sleep 3;

opendir my $procdir, "/proc/" or die "Cannot open directory: $!";
my @files = readdir $procdir;
closedir $procdir;

foreach my $file (@files) {
	next unless -d "/proc/$file";
	if ($file =~ /\d+/) {
		my $cmd = "/proc/$file/cmdline"; # cmd running for process
		open (my $fh, '<', $cmd) or die "Couldn't open file '$cmd': $!";
		while (my $line = <$fh>) {
			# searching for exim processes to kill
			if ($line =~ /exim-daemon/) {
				# send sigkill to process
				kill 9, $file;
			}
		}
		close $fh;
	}
}

sleep 3;
print "Killed exim processes.\n";
print "Clearing Exim queue... this may take some time.\n";

# get list of files/emails from input/msglog and push to global var @email_list
grab_list($input_dir);
grab_list($msglog_dir);
# print Dumper \@email_list;
# delete all files in the array
my $unlinked = unlink @email_list;
print "Deleted $unlinked file(s)\n";

# start exim
system("/etc/init.d/exim start");
sleep 3;
print "Exim cleared!\n";

## Sub-routines

sub grab_list {
	my $dir = shift || '';
	opendir my $exim_dir_list, $dir or die "Can't open directory: $!";
	my @exim_list = readdir $exim_dir_list;
	closedir $exim_dir_list;

	foreach my $dir_name (@exim_list) {
		next if $dir_name =~ /^((\.).*)/;
		my $dir_path = "${dir}/${dir_name}";
		opendir my $temp_list, $dir_path or die "Can't open directory: $!";
		my @list = readdir $temp_list;
		closedir $temp_list;
		foreach my $item (@list) {
			next if $item =~ /^((\.).*)/;
			push @email_list, "${dir_path}/${item}";
		}
	}
}
