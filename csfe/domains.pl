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
	GetOptions('username|u=s' => \$username) or die "Usage: $0 [--username|-u] USER\n";
	if (!$username) {
		die "Usage: $0 [--username|-u] USER\n";
	}
	my $res = csfe_post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		cacheTTL => '1 day',
		canReload => 1,
		startCollapsed => 1,
		OSSFlag => 'CSFE_BASIC',
		cacheLevel => 'perCustomer',
		miniDoc => 'Displays the domains currently registered for this user, as well as tools to administer them.',
		widgetName => 'user_domains',
		height => 550,
		username => $username,
		subsystemID => 3000,
		docPath => 'https =>//wiki.bizland.com/support/index.php/Category:Domains',
		title => 'Domains',
		load_widget => 1,
		clear_widget_cache => 1,
		__got_widget_js => 1,
	});
	if ($res) {
		my @list = split /<tr\s*\w+="\w+"\s*\w+=".*">/, $res;
		shift @list; # remove the first entry since doesnt contain info
		my @domain_list;
		my @dates;
		my %domains;
		foreach my $section (@list) {
			if ($section =~ /<a.*?>(?<Domain>[\d|\w]+\.\w+)<br\/>/) {
				push @domain_list, $+{Domain};
			}
			if ($section =~ /<td\s+class="even"\s*>\n\s+(?<Date>.*)\n\s+<\/td>/) {
				push @dates, $+{Date};
			}
		}
		for (my $i = 0; $i < @domain_list; $i++) {
			$domains{$domain_list[$i]} = $dates[$i];
		}
		print Dumper \%domains;
	} else {
		die "Post request failed!\n";
	}
} else {
	die "Failed CSFE check_all().\n";
}

