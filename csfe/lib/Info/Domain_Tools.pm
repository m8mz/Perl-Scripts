package Info::Domain_Tools;
use strict;
use warnings;

use CSFE;
use Exporter qw(import);

our @EXPORT_OK = qw(Domain_Info Add_Record);

=pod

=head1 Domain Tools

=over 4

=item # Description

This module will work with a domain's DNS records for a vDeck username, domain, or email address. You will be able to list, add, change, and delete DNS records.

=item # Usage/Examples

To get a hash of the DNS records the script requires the domain name. Example:

=begin text

	my %dns = Domain_Info("munix.tech");

=end text

To add a DNS record it requires the domain name, type of record [TXT,A,CNAME,MX...], name of the record [default._domainkey, munix.tech...], the value of the record, and if it applies the priority of the record. Example:

=begin text

	Add_Record("munix.tech", "TXT", "munix.tech", "v=spf1 +a +mx +ip4:192.163.208.126 ~all");
	Add_Record("munix.tech", "MX", "munix.tech", "mail.munix.tech", "10");

=end text

More to be added...

=item # Response

Will either respond with a hash of the DNS records or true/false based on if method used was successful. Example of hash below:

=begin text

	$VAR1 = {
          'history' => [
                         {
                           'date' => 'Mon Jun 04 16:16:24 2018',
                           'user' => 'ipw.testmmstech'
                         }
                       ],
          'id' => '44411137',
          'dns' => [
                     {
                       'record' => '192.163.208.126',
                       'type' => 'A',
                       'name' => '*.munix.tech',
                       'id' => '939528858'
                     },
                     {
                       'type' => 'A',
                       'name' => 'ns2.munix.tech',
                       'id' => '940064259',
                       'record' => '192.163.208.126'
                     },
                     {
                       'name' => 'ns1.munix.tech',
                       'type' => 'A',
                       'id' => '940064197',
                       'record' => '192.163.208.126'
                     },
                     {
                       'record' => '192.163.208.126',
                       'id' => '939528857',
                       'name' => 'munix.tech',
                       'type' => 'A'
                     },
                     {
                       'record' => 'mail.munix.tech',
                       'priority' => '5',
                       'id' => '939528859',
                       'name' => 'munix.tech',
                       'type' => 'MX'
                     },
                     {
                       'id' => '939528855',
                       'name' => 'munix.tech',
                       'type' => 'NS',
                       'record' => 'ns1.yourhostingaccount.com'
                     },
                     {
                       'record' => 'ns2.yourhostingaccount.com',
                       'id' => '939528856',
                       'type' => 'NS',
                       'name' => 'munix.tech'
                     },
                     {
                       'record' => 'ns1.yourhostingaccount.com admin.yourhostingaccount.com 2018060465 10800 3600 604800 3600',
                       'type' => 'SOA',
                       'name' => 'munix.tech',
                       'id' => '939528854'
                     },
                     {
                       'type' => 'TXT',
                       'name' => 'munix.tech',
                       'id' => '957501667',
                       'record' => 'testing this record'
                     }
                   ],
          'mx' => '33405'
        };

=end text

=item # Author

Author: Marcus Hancock-Gaillard (marcus.hancock-gaillard@endurance.com) - 04/2019

=back

=cut

sub Domain_Info {

	die "Failed CSFE check_all()" unless csfe_check_all();
	my $domain = shift // die "Must pass the domain name to Domain_Info!\n";
	my $username = csfe_search($domain);

	my $res = csfe_post_request({
		canExpand => 1,
		defaultTier => 'tierIII',
		canReload => 1,
		cacheLevel => 'none',
		tool => '/csfe/tools/domainconsole.cmp',
		widgetName => 'tech_tools_popup',
		Domain => $domain,
		username => $username,
		subsystemID => 1100,
		PropertyID => 33,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/tech_tools_popup',
		title => 'Tools',
		load_widget => 1,
		__got_widget_js => 1
	}) or die "Err: Issue with response!";

	my %obj = (
		id => '',
		mx => '',
		dns => [],
		history => []
	);
	while ($res =~ m`
	.*name="CurrentMX"\s+value="(?<Mx_ID>\d+)"> |
	.*name="domain_id"\s+value="(?<Domain_ID>\d+)" |
	<td\s+colspan="2"><a\shref="/csfe/general\.html\?username=(?<Username>.*)">.*\n\s*<td>(?<Date>.*)</td> |
	<tr>\n
	\s*<td>(?<ID>\d+)</td>\n
	.*\n
	\s*<input.*value="(?<Type>.*)".*\n
	.*\n
	\s*<input.*value="(?<Name>.*)".*\n
	\s*<td><input.*value="(?<Record>.*)".*\n
	(.*name="oldprio.*value="(?<Priority>\d+)")?
	`gix) {
		if (exists $+{Mx_ID}) {
			$obj{'mx'} = $+{Mx_ID};
		} elsif (exists $+{Domain_ID}) {
			$obj{'id'} = $+{Domain_ID};
		}

		if (exists $+{Username} and exists $+{Date}) {
			push @{$obj{'history'}}, { user => $+{Username}, date => $+{Date} };
		}

		if (exists $+{ID} and exists $+{Type} and exists $+{Name} and exists $+{Record}) {
			my $o = {
				id => $+{ID},
				type => $+{Type},
				name => $+{Name},
				record => $+{Record}
			};
			if (exists $+{Priority}) {
				$o->{'priority'} = $+{Priority};
			}

			push @{$obj{'dns'}}, $o;
		}

	}

	return %obj;

}


sub Add_Record {
	die "Adding a record requires a minimum of 4 arguments!\n" unless scalar @_ >= 4;
	my ($domain, $type, $name, $record, $priority) = @_;
	my $username = csfe_search($domain);
	my %params = (
		UserName => $username,
		Domain => $domain,
		NewOwner => '',
		add_db_record => 'Add Record',
		CurrentMX => $obj{'mx'},
		newmx => 'new',
		MX => $obj{'mx'},
		domaintemplate => 2,
		oldtype => 1,
		Native => 1,
		master => '',
		domain_id => $obj{'id'},
		newtype => $type,
		newname => $name,
		newcontent => $record,
		newpriority => $priority,
		notification => 1,
		defaultTier => 'tierIII',
		canExpand => 1,
		canReload => 1,
		cacheLevel => 'none',
		tool => '/csfe/tools/domainconsole.cmp',
		widgetName => 'tech_tools_popup',
		username => $username,
		subsystemID => 1100,
		PropertyID => $property_id,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/tech_tools_popup',
		title => 'Tools',
		load_widget => 1,
		clear_widget_cache => 1,
		__got_widget_js => 1
	);

	my $res = csfe_post_request(\%params);
	if ($res) {
		return 1;
	} else {
		return 0;
	}
}

1;
