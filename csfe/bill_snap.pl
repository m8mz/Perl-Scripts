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
		canReload => 1,
		startCollapsed => 1,
		cacheLevel => 'none',
		miniDoc => 'Billing Snapshot that customers see',
		widgetName => 'billingSnapshot',
		username => $username,
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/billingSnapshot',
		title => 'Billing Snapshot',
		load_widget => 1,
		__got_widget_js => 1
	});
	if ($res) {
		#my @lines = split /\n/, $res;
		my @split = split /<tr class = "evenrowcolor">/, $res;
		my @filtered;
		foreach my $section (@split) {
			my @info = $section =~ /(<td.*)/g;
			push @filtered, \@info;
		}
		foreach my $fil_section (@filtered) {
			for (my $i = 0; $i < @$fil_section; $i++) {
				my $row = \$fil_section->[$i];
				while ($$row =~ /<(\w+).*?>(.*)<\s*\/\s*\1>/) {
					$$row = $2;
				}
			}
			printf "%-15s %-15s %-50s %-15s %-15s %-15s %-15s %-15s\n", (@$fil_section);
		}
	} else {
		die "Post request failed!\n";
	}
} else {
	die "Failed CSFE check_all().\n";
}

