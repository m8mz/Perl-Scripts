package Info::Tickets;
use strict;
use warnings;

use CSFE;
use Exporter qw(import);

our @EXPORT = qw(Tickets);

=pod

=head1 Tickets

=over 4

=item # Description

This module will return the Tickets for a vDeck username, domain, or email address.

=item # Usage/Examples

Requires a username, domain, or email address to run the script.

=begin text

		my @tickets = Tickets("ipw.testmmstech");
		my @tickets = Tickets("munix.tech");
		my @tickets = Tickets("marcus.hancock-gaillard@endurance.com");

=end text

=item # Response

Will respond with an array of tickets like the example below:

=begin text

	$VAR1 = [
		  {
		    'ID' => '16585572',
		    'subject' => 'EXAMPLE',
		    'date' => '06/21/2018',
		    'status' => 'Resolved'
		  },
		  {
		    'status' => 'Resolved',
		    'date' => '06/21/2018',
		    'subject' => 'this is a test *ignore*',
		    'ID' => '16585596'
		  }
		];

=end text

=item # Author

Author: Marcus Hancock-Gaillard (marcus.hancock-gaillard@endurance.com) - 04/2019

=back

=cut

sub Tickets {

	die "Failed CSFE check_all()" unless csfe_check_all();
	my $arg = shift // die "Pass an argument to Tickets!\n";

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
		username => $arg,
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php/CSFE#CSES.2FPolaris_Activity',
		title => 'CSES/Polaris Activity',
		load_widget => 1,
		__got_widget_js => 1,
	}) or die "Err: Issue with response!";

	my @tickets;
	while ($res =~ m`
	\s*<td.*>\n
	\s*<img.*title="(?<Status>\w+)\s?Polaris\s?Thread".*\n
	.*\n
	.*\n
	.*href=".*ThreadID=(?<ID>\d+)".*title="(?<Subject>.*)".*\n
	.*\n
	.*\n
	\s*(?<Date>\d{2}/\d{2}/\d{4})
	`gix) {
		my $o = {
			ID => $+{ID},
			date => $+{Date},
			subject => $+{Subject},
			status => $+{Status}
		};
		unshift @tickets, $o;
	}

	return @tickets;

}

1;
