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
	canExpand => 1,
	defaultTier => 'global',
	canReload => 1,
	cacheTTL => '1 day',
	cacheLevel => 'perCustomer',
	OSSFlag => 'CSFE_BASIC',
	miniDoc => 'Displays basic account information for this user.',
	startCollapsed => 1,
	cacheLevel => 'none',
	widgetName => 'user_information',
	username => $username,
	subsystemID => 3000,
	docPath => 'https://wiki.bizland.com/support/index.php?title=CSFE#Account_Information',
	title => 'Account Information',
	clear_widget_cache => 1,
	__got_widget_js => 1
}) or die "Err: Issue with response!";

my %acct;
while ($res =~ m`
<strong>(?<Key>.*)[:?]{1}</strong>(\s*(?<Value>.*)<.?\w+>|.*\n\s*(?<Value>.*)(\s\n\s+)?<\/p>) |
Admin:</td>\n.*title="(?<Email>.*)">
`gix) {
	if ($+{Email}) {
		$acct{"Email(s)"} = $+{Email};
		next;
	}
	my $key = $+{Key};
	my $value = $+{Value};
	next if $key =~ /Flip Date|TwitterUserName|Role|FaceBookUserName|Sales/;
	if ($key eq "LiveAccountDate") {
		($value) = $value =~ /<.*>(.*)<\/\w+>/;
	}
	$acct{"$key"} = $value;
}

print Dumper \%acct;
