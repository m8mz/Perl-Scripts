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
        });
	if ($res) {
                #my $file = 'example_responses/tickets.txt';
                #open my $fh, '<', $file or die "Err: $!";
                #my $res = do { local $/; <$fh> };
                my @sections = split /<tr class="\w+">/, $res;
                shift @sections;
                foreach my $section (@sections) {
                        my %info;
                        my @lines = split /\n/, $section;
                        foreach my $line (@lines) {
                                if ($line =~ /<img .* alt="(\w+) Polaris Thread" .* \/>/) {
                                        $info{status} = $1;
                                } elsif ($line =~ m{<a href="/polaris/\?ThreadID=(\d+)" target="_blank" title="(.*)">\d+</a>}) {
                                        $info{ticket} = $1;
                                        $info{subject} = $2;
                                } elsif ($line =~ /^\s*((\d{2}\/){2}\d{4})\s*$/) {
                                        $info{date} = $1;
                                }
                        }
                        print Dumper \%info;
                }
	} else {
		die "Post request failed!\n";
	}
} else {
	die "Failed CSFE check_all().\n";
}

