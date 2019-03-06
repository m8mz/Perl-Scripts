#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard
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
	});
	if ($res) {
		my @lines = split /\n/, $res;
		my @info = grep { $_ =~ /(<strong>|width="80%"><a href="\?search=|renew)/i; } @lines; # grabs the lines that have useful info
		my %acct;
		foreach my $line (@info) {
			next if $line =~ /FaceBook|Twitter|Account Status|Account Type|Flip Date|telemarketing|Referral program|Tax Exemptions|Sales/;
			$line =~ s/^\s+//g;
			if ($line =~ m{<strong>(?<Name>.*)[:?]</strong>\s*(?<Value>.*)<?}) {
				my $value = $+{"Value"};
				my $name = $+{"Name"};
				while ($name =~ m{<.*>(.*)<.*>}) {
					$name = $1;
				}
				$value =~ s/<\/?\w+>//;
				if ($name =~ /MasterID/) {
					if ($value =~ m{/cs/OfferSummary\.cmp\?id=(?<ID>\d+)}) {
						$value = $+{ID};
					} else {
						$value = "N/A";
					}
				} elsif ($name =~ /LiveAccountDate/) {
					if ($value =~ m{<.*>(?<Date>.*)<.*>}) {
						$value = $+{Date};
					} else {
						$value = "N/A";
					}
				} elsif ($name =~ /Account Renewal Status/) {
					foreach (@info) {
						if ($_ =~ /(Auto Renew|Scheduled to NOT renew)/) {
							$value = $1;
						}
					}
				}

				$acct{$name} = $value;
			} elsif ($line =~ m{title="(?<Email>.*@.*)"}) {
				$acct{"Email"} = $+{Email};
			}
		}
		print Dumper \%acct;
	} else {
		die "Post request failed!\n";
	}
} else {
	die "Failed CSFE check_all().\n";
}
