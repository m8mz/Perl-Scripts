#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname( abs_path $0 ) . '/lib';
use HTML::Parser;

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
		cacheTTL => '8 hours',
		canReload => 1,
		cacheLevel => 'perOssUserAndCustomer',
		OSSFlag => 'CSFE_BASIC',
		widgetName => 'account_information',
		username => $username,
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php?title=CSFE#Account_Information',
		title => 'Billing Information',
		load_widget => 1,
		__got_widget_js => 1
	});
	if ($res) {
		my @array;
		my $p = HTML::Parser->new(
			handlers => {
				text => [\@array, '@{text}'],
			});
		$res =~ s/\s{2,}/ /g;
		$p->parse($res);
		my @info;
		foreach my $row (@array) {
			if ($row =~ /\w+/) {
				if ($row =~ /(Billing Information|Account Information|Caller ID|Edit)/) {
					next;
				}
				$row =~ s/^\s+//;
				$row =~ s/\s+$//;
				push @info, $row;
			}
		}
		my $k = 0; #variable to check if 1st iteration
		foreach my $item (@info) {
			if ($k and $item =~ /:/) {
				print "\n";
			}
			$k++;
			print $item, " ";
			if ($k == @info) {
				print "\n";
			}
		}
	} else {
		die "Post request failed!\n";
	}
} else {
	die "Failed CSFE check_all().\n";
}

