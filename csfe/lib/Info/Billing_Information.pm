package Info::Billing_Information;
use strict;
use warnings;

use CSFE;
use Exporter qw(import);

our @EXPORT = qw(Billing_Information);

=pod

=head1 Billing Information

=over 4

=item #Description

This module will return the billing information for a vDeck username, domain, or email address.

=back

=over 4

=item #Usage/Examples

Requires a username, domain, or email address to run the script.

=begin text

	my %info = Billing_Information("ipw.testmmstech");
	my %info = Billing_Information("munix.tech");
	my %info = Billing_Information("marcus.hancock-gaillard@endurance.com");

=end text


=back

=over 4

=item #Response

Will respond with a hash like the following example:

=begin text

	$VAR1 = {
		'Last Name' => 'Hancock-Gaillard',
		'Caller ID' => '',
		'Business Name' => '',
		'Phone' => '1 602-503-0536',
		'Exp. Date' => '01/23',
		'Card Type' => 'Visa',
		'Billing Address' => '10 Corporate Dr. Burlington, MA 01803 USA',
		'Card Holder Name' => 'Marcus Hancock-Gaillard',
		'Card Number' => '41XXXXXXXXXX1111',
		'Company Address' => '10 Corporate Dr. Burlington, MA 01803 USA',
		'First Name' => 'Marcus'
        };

=end text

=back

=over 4

=item #Author

Author: Marcus Hancock-Gaillard (marcus.hancock-gaillard@endurance.com) - 04/2019

=back

=cut

sub Billing_Information {

	die "Failed CSFE check_all()" unless csfe_check_all();
	my $arg = shift || die "Need to pass an argument to Billing_Information!\n";

	my $res = csfe_post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		cacheTTL => '8 hours',
		canReload => 1,
		cacheLevel => 'perOssUserAndCustomer',
		OSSFlag => 'CSFE_BASIC',
		widgetName => 'account_information',
		username => $arg,
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php?title=CSFE#Account_Information',
		title => 'Billing Information',
		load_widget => 1,
		__got_widget_js => 1
	}) or die "Err: Issue with response!";

	my %info;
	while ($res =~ m`
	<strong>(?<Key>.*):</strong>\s*(?<Value>.*)< |
	<dt>(?<Key>.*):</dt>\n
	\s*<dd>(?<Value>.*)</dd>
	(\s*<dd>(?<Value1>.*\n?.*)</dd>\n
	\s*<dd>(?<Value2>.*)</dd>)?
	`gix) {

		my $key = $+{Key};
		my $value = $+{Value};
		if ($+{Value1}) {
			my $value1 = $+{Value1};
			my $value2 = $+{Value2};
			$value1 =~ s/\s*\n\s*/ /;
			$value = $value . ' ' . $value1 . ' ' . $value2;
		}

		$info{"$key"} = $value;

	}

	return %info;

}

1;

