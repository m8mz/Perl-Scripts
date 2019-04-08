#!/usr/bin/env perl
package Info::Billing_Snapshot;
use strict;
use warnings;

use CSFE;
use Exporter qw(import);

our @EXPORT = qw(Billing_Snapshot);

=pod

=head1 Billing Snapshot

=over 4

=item # Description

This module will return a snapshot of the billing transaction for a vDeck username, domain, or email address.

=back

=over 4

=item # Usage/Examples

Requires a username, domain, or email address to run the script.

=begin text

		my @transactions = Billing_Snapshot("ipw.testmmstech");
		my @transactions = Billing_Snapshot("munix.tech");
		my @transactions = Billing_Snapshot("marcus.hancock-gaillard@endurance.com");

=end text

=back

=over 4

=item # Response

Will respond with an array of transactions like the example below.

=begin text

$VAR1 = [
          {
            'billDate' => '2018-06-04',
            'paymentMethod' => 'Credit card',
            'totalAmount' => '$49.95',
            'renewDate' => '2018-06-04',
            'salesAmount' => '$0.00',
            'status' => 'Paid| 60',
            'amount' => '$49.95',
            'product' => 'Domain Privacy '
          },
          {
            'amount' => '$1631.84',
            'product' => 'Managed VPS Optimum',
            'salesAmount' => '$0.00',
            'status' => 'Paid| 24',
            'totalAmount' => '$1631.84',
            'renewDate' => '2018-06-04',
            'paymentMethod' => 'Credit card',
            'billDate' => '2018-06-04'
          },
          {
            'paymentMethod' => 'Credit card',
            'renewDate' => '2018-06-04',
            'totalAmount' => '$75.96',
            'billDate' => '2018-06-04',
            'product' => '.tech register - 4 year',
            'amount' => '$75.96',
            'status' => 'Paid| o',
            'salesAmount' => '$0.00'
          },
          {
            'billDate' => '2018-06-04',
            'paymentMethod' => 'Credit card',
            'totalAmount' => '$49.95',
            'renewDate' => '2018-06-04',
            'status' => 'Paid| 60',
            'salesAmount' => '$0.00',
            'product' => 'Domain Privacy ',
            'amount' => '$49.95'
          },
          {
            'billDate' => '2018-06-04',
            'paymentMethod' => 'Credit card',
            'totalAmount' => '$98.95',
            'renewDate' => '2018-06-04',
            'salesAmount' => '$0.00',
            'status' => 'Paid| o',
            'product' => '.tech register - 5 year',
            'amount' => '$98.95'
          },
          {
            'salesAmount' => '$0.00',
            'status' => 'Paid| a',
            'product' => '.space register - 1 year',
            'amount' => '$2.99',
            'billDate' => '2018-07-31',
            'totalAmount' => '$2.99',
            'renewDate' => '2018-07-31',
            'paymentMethod' => 'Credit card'
          },
          {
            'billDate' => '2018-07-31',
            'paymentMethod' => 'Credit card',
            'totalAmount' => '$9.99',
            'renewDate' => '2018-07-31',
            'salesAmount' => '$0.00',
            'status' => 'Paid| a',
            'product' => 'Domain Privacy ',
            'amount' => '$9.99'
          },
          {
            'status' => 'Pending| a',
            'salesAmount' => '$0.81',
            'amount' => '$12.99',
            'product' => 'Domain Privacy - 1 Year',
            'billDate' => '2019-07-16',
            'renewDate' => '2019-07-31',
            'totalAmount' => '$13.80',
            'paymentMethod' => 'Credit card'
          }
        ];

=end text

=back

=over 4

=item # Author

Author: Marcus Hancock-Gaillard (marcus.hancock-gaillard@endurance.com) - 04/2019

=back

=cut

sub Billing_Snapshot {
	die "Failed CSFE check_all()" unless csfe_check_all();

	my $arg = shift || die "Pass an argument to Billing_Snapshot!\n";

	my $res = csfe_post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		canReload => 1,
		startCollapsed => 1,
		cacheLevel => 'none',
		miniDoc => 'Billing Snapshot that customers see',
		widgetName => 'billingSnapshot',
		username => $arg,
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
	(\s*<td>(?<SalesAmount>.*)</td>
	\s*<td>(?<TotalAmount>.*)</td>)?
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

	return @transactions;

}

1;
