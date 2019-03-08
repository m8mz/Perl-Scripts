#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname( abs_path $0 ) . '/lib';

use CSFE;

if (csfe_check_all()) {
	my $username;
	my $domain;
	GetOptions(
		'username|u=s' => \$username,
		'domain|d=s' => \$domain
	) or die "Usage: $0 [--username|-u] USER\n";
	if (!$username or !$domain) {
		die "Usage: $0 [--username|-u] USER [--domain|-d] DOMAIN\n";
	}
	my $res = csfe_post_request({
		canExpand => 1,
		defaultTier => 'tierIII',
		canReload => 1,
		cacheLevel => 'none',
		tool => '/csfe/tools/domainconsole.cmp',
		widgetName => 'tech_tools_popup',
		Domain => $domain,
		username => $username,
		subsystemID => 1100,
		PropertyID => 33,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/tech_tools_popup',
		title => 'Tools',
		load_widget => 1,
		__got_widget_js => 1
	});
	if ($res) {
		my %obj; # hash containing response ( id => $domain_id, mx => $mx_id, dns => [], history => [] )
		my @m = $res =~ /<tr>(.*?)?<\/tr>/gs; # split into tr sections
		map { $_ =~ s/^\s*//g; $_ =~ s/\s*$//g; } @m; # remove whitespace
		my @array = grep /name="CurrentMX"|name="domain_id"|<td colspan="2"><a|<td>\d+<\/td>/, @m; # filter the sections needed, later holds just the dns records after filter below
		my ($index) = grep { $array[$_] =~ /<td>\d+<\/td>/ } (0 .. @array-1); # index of when dns records start
		my @history = splice @array, 0, $index;
		my $domain_id = pop @history; # domain_id will be the last item in @history
		($domain_id) = $domain_id =~ /<input type="hidden" name="domain_id" value="(\d+)">/; # grab the id
		$obj{'id'} = $domain_id;
		my $mx_id = pop @history; #mx_id will be the last item in @history (after domain_id is popped)
		($mx_id) = $mx_id =~ /name="CurrentMX" value="(.*)"/;
		$obj{'mx_id'} = $mx_id;
		my @hist; # array of domain ownership history
		my @dns; # array of dns for domain
		foreach my $item (@history) { # DOMAIN OWNERSHIP HISTORY
			my %o; # structure { date => $date, username => $user, duid => $duid }
			my ($userstring) = $item =~ m{<td colspan="2"><a href=".*\?(.*)">.*</a>};
			my ($date) = $item =~ m{<td>(\w{3,4} .* \d{4})</td>};
			$o{'date'} = $date;
			if ($userstring =~ /&/) {
				my (undef,$user,undef,$duid) = split /&|=/, $userstring; # split up params
				$o{'username'} = $user;
				$o{'duid'} = $duid;
			} else {
				my (undef,$user) = split /=/, $userstring;
				$o{'username'} = $user;
			}
			unshift @hist, \%o;
		}
		$obj{'history'} = \@hist;
		foreach my $entry (@array) {
			my @lines = split /\n/, $entry;
			my ($record_id) = $lines[0] =~ /<td>(\d+)<\/td>/;
			my ($record_type) = $lines[2] =~ /value="(.*)"/;
			my ($record_name) = $lines[4] =~ /value="(.*)"/;
			my ($record_record) = $lines[5] =~ /value="(.*)"/;
			my %o = (
				id => $record_id,
				type => $record_type,
				name => $record_name,
				record => $record_record
			);
			push @dns, \%o;
		}
		$obj{'dns'} = \@dns;

		print Dumper \%obj;
	} else {
		die "Post request failed!\n";
	}
} else {
	die "Failed CSFE check_all().\n";
}

