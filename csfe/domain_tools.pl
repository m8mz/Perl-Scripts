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
}) or die "Err: Issue with response!";

my %obj = (
	id => '',
	mx => '',
	dns => [],
	history => []
);
while ($res =~ m`
.*name="CurrentMX"\s+value="(?<Mx_ID>\d+)"> |
.*name="domain_id"\s+value="(?<Domain_ID>\d+)" |
<td\s+colspan="2"><a\shref="/csfe/general\.html\?username=(?<Username>.*)">.*\n\s*<td>(?<Date>.*)</td> |
<tr>\n
\s*<td>(?<ID>\d+)</td>\n
.*\n
\s*<input.*value="(?<Type>.*)".*\n
.*\n
\s*<input.*value="(?<Name>.*)".*\n
\s*<td><input.*value="(?<Record>.*)".*\n
(.*name="oldprio.*value="(?<Priority>\d+)")?
`gix) {
	if (exists $+{Mx_ID}) {
		$obj{'mx'} = $+{Mx_ID};
	} elsif (exists $+{Domain_ID}) {
		$obj{'id'} = $+{Domain_ID};
	}

	if (exists $+{Username} and exists $+{Date}) {
		push @{$obj{'history'}}, { user => $+{Username}, date => $+{Date} };
	}

	if (exists $+{ID} and exists $+{Type} and exists $+{Name} and exists $+{Record}) {
		my $o = {
			id => $+{ID},
			type => $+{Type},
			name => $+{Name},
			record => $+{Record}
		};
		if (exists $+{Priority}) {
			$o->{'priority'} = $+{Priority};
		}

		push @{$obj{'dns'}}, $o;
	}

}

print Dumper \%obj;
