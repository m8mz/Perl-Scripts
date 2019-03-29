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
	canReload => 1,
	cacheLevel => 'none',
	OSSFlag => 'CSFE_BASIC',
	widgetName => 'vps_info_new',
	username => $username,
	subsystemID => 3000,
	docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/vps_info_new',
	title => 'VPS Info',
	load_widget => 1,
	__got_widget_js => 1,
}) or die "Err: Issue with response!";

my %info;
while ( $res =~ m`<strong>(?<Key>.*):</strong>\n?\s*</td>\n?\s*<td>\s*(<a\s*href=".*"\s*target="_blank">(?<Value>.*)</a>|(?<Value>[a-zA-Z0-9 -]+))\n?\s*</td>`gix ) {
	$info{"$+{Key}"} = $+{Value};
}

print Dumper \%info;
