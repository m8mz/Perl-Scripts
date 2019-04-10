package Info::Tech_Info;
use strict;
use warnings;

use CSFE;
use Exporter qw(import);

our @EXPORT = qw(Tech_Information);

=pod

=head1 Technical Information

=over 4

=item # Description

This module will return the technical information for a vDeck username, domain, or email address.

=item # Usage/Examples

Requires a username, domain, or email address to run the script.

=begin text

		my %info = Tech_Information("ipw.testmmstech");
		my %info = Tech_Information("munix.tech");
		my %info = Tech_Information("marcus.hancock-gaillard@endurance.com");

=end text

=item # Response

Will respond with a hash like the following example:

=begin text

	$VAR1 = {
		  'RAM' => '8192 MB',
		  'Bandwidth' => '0 MB',
		  'Fulfillment Status' => 'Active',
		  'IPs' => '192.163.208.126',
		  'Disk Space' => '122880 MB',
		  'Host Node' => 'NA',
		  'Container ID' => 'NA',
		  'Date Created' => '2018-06-04',
		  'Date Updated' => '2018-06-04',
		  'Plesk Domains' => '1'
		};

=end text

=item # Author

Author: Marcus Hancock-Gaillard (marcus.hancock-gaillard@endurance.com) - 04/2019

=back

=cut

sub Tech_Information {

	die "Failed CSFE check_all()" unless csfe_check_all();
	my $arg = shift // die "Pass an argument to Tech_Information!\n";

	my $res = csfe_post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		canReload => 1,
		cacheLevel => 'none',
		OSSFlag => 'CSFE_BASIC',
		widgetName => 'vps_info_new',
		username => $arg,
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/vps_info_new',
		title => 'VPS Info',
		load_widget => 1,
		__got_widget_js => 1,
	}) or die "Err: Issue with response!";

	my %info;
	while ( $res =~ m`<strong>(?<Key>.*):</strong>\n?\s*</td>\n?\s*<td>\s*(<a\s*href=".*"\s*target="_blank">(?<Value>.*)</a>|(?<Value>[a-zA-Z0-9 -]+))\n?\s*</td>`gix ) {
		$info{"$+{Key}"} = $+{Value};
	}

	return %info;

}

1;
