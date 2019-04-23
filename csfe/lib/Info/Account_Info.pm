package Info::Account_Info;

use CSFE;
use Exporter qw(import);

our @EXPORT = qw(Account_Information);

=pod

=head1 Account Information

=over 4

=item # Description

This module will return the account information for a username, domain, or email address.

=item # Usage/Examples

Requires a username, domain, or email address to run the script.

my %info = Account_Information("ipw.testmmstech");

my %info = Account_Information("munix.tech");

my %info = Account_Information("marcus.hancock-gaillard@endurance.com");

=item # Response

Will respond with a hash like the following example information:

=begin text

	$VAR1 = {
		'Created On' => '06/04/2018',
		'Deleted User' => 'No',
		'Answer' => 'Programmer/Hacker',
		'Last TOS Agreed On' => '06/04/2018',
		'Name' => 'Marcus Hancock-Gaillard',
		'Account Origin' => 'IPOWER Organic',
		'Question' => 'What was your dream job as a child?',
		'Account Type' => 'Permanent Test',
		'LiveAccountDate' => '06/04/2018',
		'Hosting Plan' => 'Managed VPS Optimum (VPS - Unix)',
		'Account Status' => '(Active)',
		'Email(s)' => 'marcus.hancock-gaillard@endurance.com',
		'Account Renewal Status' => 'Auto Renew',
		'First TOS Agreed On' => '06/04/2018'
        };


=end text

=item # Author

Author: Marcus Hancock-Gaillard - 4/2019

=back

=cut

sub Account_Information {

	die "Failed CSFE check_all()" unless csfe_check_all();

	my $arg = shift // die "Need to pass an argument to Account_Information!\n";

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
		username => $arg,
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
}

1;
