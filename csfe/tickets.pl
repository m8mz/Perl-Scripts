#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname( abs_path $0 ) . '/lib';

use CSFE;

die "Failed CSFE check_all()" unless csfe_check_all();

my $username;
GetOptions('username|u=s' => \$username) or die "Usage: $0 [--username|-u] USER\n";
if (!$username) {
	die "Usage: $0 [--username|-u] USER\n";
}

my $res = csfe_post_request({
	defaultTier => 'tierIII',
	canExpand => 1,
	cacheTTL => '12 hours',
	canReload => 1,
	OSSFlag => 'CSFE_BASIC',
	cacheLevel => 'perCustomer',
	miniDoc => 'Displays recent Polaris and CSES contacts for this customer.',
	widgetName => 'recent_polaris',
	height => 350,
	username => $username,
	subsystemID => 3000,
	docPath => 'https://wiki.bizland.com/support/index.php/CSFE#CSES.2FPolaris_Activity',
	title => 'CSES/Polaris Activity',
	load_widget => 1,
	__got_widget_js => 1,
}) or die "Err: Issue with response!";

my @tickets;
while ($res =~ m`
\s*<td.*>\n
\s*<img.*title="(?<Status>\w+)\s?Polaris\s?Thread".*\n
.*\n
.*\n
.*href=".*ThreadID=(?<ID>\d+)".*title="(?<Subject>.*)".*\n
.*\n
.*\n
\s*(?<Date>\d{2}/\d{2}/\d{4})
`gix) {
        my $o = {
                ID => $+{ID},
                date => $+{Date},
                subject => $+{Subject},
                status => $+{Status}
        };
        unshift @tickets, $o;
}

print Dumper \@tickets;
