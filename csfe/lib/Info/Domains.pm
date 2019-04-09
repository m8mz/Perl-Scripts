package Info::Domains;
use strict;
use warnings;

use CSFE;
use Exporter qw(import);

our @EXPORT = qw(Domains);

=pod

=head1 Domains

=over 4

=item # Description

This module will return the domains that are associated with the vDeck username, domain, or email address.

=item # Usage/Examples

Requires a username, domain, or email address to run the script.

=begin text

		my @domains = Domains("ipw.testmmstech");
		my @domains = Domains("munix.tech");
		my @domains = Domains("marcus.hancock-gaillard@endurance.com");

=end text

=item # Response

Will respond with an array of domains like the example below:

=begin text

	$VAR1 = [
		  {
		    'expires' => '07/31/2019',
		    'domain' => 'munix.space',
		    'registrar' => 'OpenHRS'
		  },
		  {
		    'expires' => '06/04/2023',
		    'registrar' => 'OpenHRS',
		    'domain' => 'munix.tech'
		  }
		];

=end text

=item # Author

Author: Marcus Hancock-Gaillard (marcus.hancock-gaillard@endurance.com) - 04/2019

=back

=cut

sub Domains {

	die "Failed CSFE check_all()" unless csfe_check_all();
	my $arg = shift // die "Pass an argument to Domains!\n";

	my $res = csfe_post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		cacheTTL => '1 day',
		canReload => 1,
		startCollapsed => 1,
		OSSFlag => 'CSFE_BASIC',
		cacheLevel => 'perCustomer',
		miniDoc => 'Displays the domains currently registered for this user, as well as tools to administer them.',
		widgetName => 'user_domains',
		height => 550,
		username => $arg,
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php/Category:Domains',
		title => 'Domains',
		showAll => 1,
		load_widget => 1,
		clear_widget_cache => 1,
		__got_widget_js => 1,
	}) or die "Err: Issue with response!";

	my @domains;
	while ($res =~ m`
	<td\s+class="odd">\n\s*<a\s+href=".*"\s+target="_blank">(?<Domain>.*)<br/>\n.*\n.*\n.*\n.*
	<td\s+class="even">\n\s*(?<Expires>[0-9\/]+)\n.*\n\s*
	<td\s+class="odd"\s+style="white-space:nowrap">(?<Registrar>.*)<br/>`gix) {
		my %h;
		$h{"domain"} = $+{"Domain"};
		$h{"expires"} = $+{"Expires"};
		$h{"registrar"} = $+{"Registrar"};
		push @domains, \%h;
	}

	return @domains;

}
