package Info::VPS_Info;
use strict;
use warnings;

use CSFE;
use Carp;
use Exporter qw(import);

our @EXPORT = qw(VPS_Info);

=pod

=head1 VPS Information

=over 4

=item # Description

This module will return the VPS information for a vDeck username, domain, or email address.

=item # Usage/Examples

Requires a username, domain, or email address to run the script.

=begin text

		my %info = VPS_Information("ipw.testmmstech");
		my %info = VPS_Information("munix.tech");
		my %info = VPS_Information("marcus.hancock-gaillard@endurance.com");

=end text

=item # Response

Will respond with a hash like the example below:

=begin text

	$VAR1 = {
		  'Host Node' => 'NA',
		  'IPs' => '192.163.208.126',
		  'Date Updated' => '2018-06-04',
		  'Plesk Domains' => '1',
		  'Date Created' => '2018-06-04',
		  'RAM' => '8192 MB',
		  'Fulfillment Status' => 'Active',
		  'Disk Space' => '122880 MB',
		  'Container ID' => 'NA',
		  'Bandwidth' => '0 MB'
		};

=end text

=item # Author

Author: Marcus Hancock-Gaillard (marcus.hancock-gaillard@endurance.com) - 04/2019

=back

=cut

sub VPS_Info {

	my $arg = shift or croak "Pass an argument to VPS_Information!\n";

	my $res = post_request({
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
	while ($res =~ m`
	<td.*>\n?\s*<strong>(?<Key>.*):</strong>\n?\s*</td>\n?\s*<td>\n?\s*(<a.*>(?<Value>.*)</a>|(?<Value>.*))\n?\s*</td>
	`gix) {
		next if $+{Key} =~ /Container Status|\w+ Login/;
		$info{"$+{Key}"} = $+{Value};
	}

	return %info;

}

1;
