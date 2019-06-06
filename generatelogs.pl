use strict;
use warnings;

use Data::Dumper;
use Time::Local;

my $file = "sessions";

open(my $fh, '<', $file) or die "Can't open '$file': $!";
my @sessions = <$fh>;
close $fh;
chomp(@sessions);

my @start_session;
my @end_session;
foreach my $line (@sessions) {
	if ($line =~ /\bNEW\b/) {
		push @start_session, $line;
	} elsif ($line =~ /\bPURGE\b/) {
		push @end_session, $line;
	}
}

my %session_hash;
SESS: foreach my $sess (@start_session) {
	while ($sess =~ /(?<DateString>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*\s(?<Address>[0-9.]+)\s.*:(?<SessionID>\w+):create_/g) {
		my $regex = qr/$+{SessionID}/;
		my $session_id = $+{SessionID};
		my $address = $+{Address};
		my $start_datestring = $+{DateString};
		my ($end_session_match) = grep { $_ =~ $regex } @end_session;
		next SESS unless defined $end_session_match; # if there is no purge of the start session move to next session in list
		# DATE FORMAT: 2019-04-15 12:49:03
		my ($year1, $month1, $day1, $hour1, $min1, $sec1) = split(/ |-|:/, $start_datestring);
		my $start_time = timelocal($sec1, $min1, $hour1, $day1, $month1-1, $year1);
		my ($end_datestring) = $end_session_match =~ /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;
		my ($year2, $month2, $day2, $hour2, $min2, $sec2) = split(/ |-|:/, $end_datestring);
		my $end_time = timelocal($sec2, $min2, $hour2, $day2, $month2-1, $year2);
		next SESS if $start_time >= $end_time; # some sessions start and end at same time making it irrelevant
		$session_hash{$session_id} = {
			ip => $address,
			start_time => $start_time,
			end_time => $end_time,
			activity => []
		}
		
	}
}

#print Dumper \%session_hash;

my $cPanel_log_path = "/usr/local/cpanel/logs/";
my @logs = ('archive/access_log-12-2017.gz', 'archive/access_log-03-2018.gz', 'archive/access_log-07-2018.gz', 'archive/access_log-09-2018.gz', 'archive/access_log-01-2019.gz', 'archive/access_log-04-2019.gz', 'access_log');
@logs = map { $cPanel_log_path . $_ } @logs;

foreach my $log (@logs) {
	my ($first_entry, $last_entry);
	my $fh; # my file handler will be opening an closing files 3 times
	open($fh, '<', $log) or die "Can't open '$log': $!";
	while (<$fh>) { chomp; $first_entry = $_; last; }
	close $fh;
	open($fh, "tac $log |") or die "Can't open '$log': $!";
	while (<$fh>) { chomp; $last_entry = $_; last; }
	close $fh;
	# Retrieved the first and last entry of the current log, next section will find date & time of these entries and find all the session_id's that fall in between this time frame
	# WHY: To prevent having to search the entire hash for each line in every log, in my head this would be more efficient.. better safe than sorry
	# DATE FORMAT: 06/06/2019:04:28:10
	my $regex = qr|(\d{2}/\d{2}/\d{4}:\d{2}:\d{2}:\d{2})|;
	my ($first_entry_datetime) = $first_entry =~ $regex;
	my ($last_entry_datetime) = $last_entry =~ $regex;
	
	my ($month1, $day1, $year1, $hour1, $min1, $sec1) = split(/\/|:/, $first_entry_datetime);
	my ($month2, $day2, $year2, $hour2, $min2, $sec2) = split(/\/|:/, $last_entry_datetime);
	my $first_entry_time = timelocal($sec1, $min1, $hour1, $day1, $month1-1, $year1); # epoch time
	my $last_entry_time = timelocal($sec2, $min2, $hour2, $day2, $month2-1, $year2); # epoch time

	my %filtered_sessions;
	for my $key (keys %session_hash) {
		if ($session_hash{$key}{'start_time'} >= $first_entry_time && $session_hash{$key}{'start_time'} <= $last_entry_time) ||
		$session_hash{$key}{'end_time'} >= $first_entry_time && $session_hash{$key}{'end_time'} <= $last_entry_time) {
			$filtered_sessions{$key} = $session_hash{$key};
		}
	} # have filtered sessions that are in current log, next section will push each line that matches to its appropriate key on the main session hash's activity array

	open($fh, '<' $log) or die "Can't open '$log': $!";
	while (my $line = <$fh>) {
		my ($datetime) = $line =~ $regex;
		my ($month, $day, $year, $hour, $min, $sec) = split(/\/|:/, $datetime);
		my $epoch_time = timelocal($sec, $min, $hour, $day1, $month-1, $year);
		foreach my $key (keys %filtered_sessions) {
			if ($filtered_sessions{$key}{'start_time'} <= $epoch_time && $filtered_sessions{$key}{'end_time'} >= $epoch_time) { # true if current line's epoch time is between a session's start and end time
				push @{$session_hash{$key}{'activity'}}, $line;
			}
		}
	}
	close $fh;
}

print Dumper \%session_hash;
