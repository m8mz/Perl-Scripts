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
		# FORMAT: 2019-04-15 12:49:03
		my ($year1, $month1, $day1, $hour1, $min1, $sec1) = split(/ |-|:/, $start_datestring);
		my $start_time = timelocal($sec1, $min1, $hour1, $day1, $month1-1, $year1);
		my ($end_datestring) = $end_session_match =~ /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;
		my ($year2, $month2, $day2, $hour2, $min2, $sec2) = split(/ |-|:/, $end_datestring);
		my $end_time = timelocal($sec2, $min2, $hour2, $day2, $month2-1, $year2);
		next SESS if $start_time >= $end_time; # some sessions start and end at same time making it irrelevant
		$session_hash{$session_id} = {
			ip => $address,
			start_time => $start_time,
			end_time => $end_time
		}
		
	}
}

#print Dumper \%session_hash;

my $cPanel_log_path = "/usr/local/cpanel/logs/";
my @logs = ('archive/access_log-12-2017.gz', 'archive/access_log-03-2018.gz', 'archive/access_log-07-2018.gz', 'archive/access_log-09-2018.gz', 'archive/access_log-01-2019.gz', 'archive/access_log-04-2019.gz', 'access_log');
@logs = map { $cPanel_log_path . $_ } @logs;

foreach my $key (keys %session_hash) {
	# do some more stuff
}
