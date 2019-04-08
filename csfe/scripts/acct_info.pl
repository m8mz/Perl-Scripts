#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use File::Basename qw(dirname);
use CSFE;

=pod

=head1 Account Information

=over 4

=item Description

This module will return the account information for a username, domain, or email address.

=back

=over 4

=item Usage/Examples

Requires a username, domain, or email address to run the script.

my %info = Account_Information("ipw.testmmstech");

my %info = Account_Information("munix.tech");

my %info = Account_Information("marcus.hancock-gaillard@endurance.com");

=back

=over 4

=item Response

Will respond with a hash with the following information:

=begin text

		Name:
		Question:
		Answer:
		Email:
		Hosting Plan:
		Creation Date:
		TOS Agreement:
		Deleted:
		Live Account Date:
		Account Origin:
		Account Type:
		Renewal Status:


=end text

=back

=over 4

=item Author

Author: Marcus Hancock-Gaillard - 4/2019

=back

=cut

die "Failed CSFE check_all()" unless csfe_check_all();

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
}) or die "Err: Issue with response!";

my %acct;
while ($res =~ m`
<strong>(?<Key>.*)[:?]{1}</strong>(\s*(?<Value>.*)<.?\w+>|.*\n\s*(?<Value>.*)(\s\n\s+)?<\/p>) |
Admin:</td>\n.*title="(?<Email>.*)">
`gix) {
	if ($+{Email}) {
		$acct{"Email(s)"} = $+{Email};
		next;
	}
	my $key = $+{Key};
	my $value = $+{Value};
	next if $key =~ /Flip Date|TwitterUserName|Role|FaceBookUserName|Sales/;
	if ($key eq "LiveAccountDate") {
		($value) = $value =~ /<.*>(.*)<\/\w+>/;
	}
	$acct{"$key"} = $value;
}

return %acct;
