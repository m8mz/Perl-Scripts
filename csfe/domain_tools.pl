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
		my @m = $res =~ /<tr>(.*?)?<\/tr>/gs;
		map { $_ =~ s/^\s*//g; $_ =~ s/\s*$//g; } @m;
		my @array = grep /<td colspan="2"><a|<td>\d+<\/td>/, @m;
		print Dumper \@array;
	} else {
		die "Post request failed!\n";
	}
} else {
	die "Failed CSFE check_all().\n";
}

