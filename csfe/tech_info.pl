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
		canExpand => 1,
		defaultTier => 'tierIII',
		canReload => 1,
		startCollapsed => 1,
		cacheLevel => 'none',
		widgetName => 'Technical',
		username => $username,
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/Technical',
		title => 'Technical Information',
		load_widget => 1,
		__got_widget_js => 1
	});
	if ($res) {
		my @lines = split /\n/, $res;
		my @info = grep { $_ =~ m{<p>.*} } @lines;
		foreach my $line (@info) {
			my @m = $line =~ m{<p><strong>(?<Name>.*)</strong>\s*(?<Value>.*)<?};
			next if $m[0] =~ /FTP|Server|Container/;
			$m[1] =~ s/<\/p>//;
			if ($m[0] =~ /Platform/) {
				$m[1] =~ s/<.*>\s*//;
			}
			print "$m[0] $m[1]\n";
		}
	} else {
		print "failed\n";
	}
} else {
	print "Something went wrong.\n";
}
