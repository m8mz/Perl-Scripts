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
}) or die "Err: Issue with reponse!";

my @transactions;
while ($res =~ m`
<tr\s*class\s*=\s*"evenrowcolor">\n
\s*<td>(?<RenewDate>.*)</td>
\s*<td>(?<BillDate>.*)</td>
\s*<td>(?<Product>.*)</td>
\s*<td>(?<Amount>.*)</td>
\s*<td>(?<SalesAmount>.*)</td>
\s*<td>(?<TotalAmount>.*)</td>
\s*<td><nobr>(?<PaymentMethod>.*)</nobr></td>
\s*<td>(?<Status>.*)</td>
`gix) {
        my $o = {
                renewDate => $+{RenewDate},
                billDate => $+{BillDate},
                product => $+{Product},
                amount => $+{Amount},
                salesAmount => $+{SalesAmount},
                totalAmount => $+{TotalAmount},
                paymentMethod => $+{PaymentMethod},
                status => $+{Status}
        };
        push @transactions, $o;
}

print Dumper \@transactions;
