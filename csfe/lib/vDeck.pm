package vDeck;
use strict;
use warnings;

use CSFE;
use Carp;

sub new {
	my $class = shift;
	my $self = {
		user => shift
	};

	init();

	if ($self->{'user'} =~ /(\d{1,3}\.){3}\d{1,3}/) {
		$self->{'user'} = search($self->{'user'});
	}

	bless $self, $class;
	return $self;
}

sub account_info {
	my $self = shift;

	my $res = post_request({
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
		username => $self->{'user'},
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php?title=CSFE#Account_Information',
		title => 'Account Information',
		clear_widget_cache => 1,
		__got_widget_js => 1
	}) or croak "Err: Issue with response!\n";

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

	return \%acct;

}

sub bill_info {
	my $self = shift;

	my $res = post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		cacheTTL => '8 hours',
		canReload => 1,
		cacheLevel => 'perOssUserAndCustomer',
		OSSFlag => 'CSFE_BASIC',
		widgetName => 'account_information',
		username => $self->{'user'},
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php?title=CSFE#Account_Information',
		title => 'Billing Information',
		load_widget => 1,
		__got_widget_js => 1
	}) or croak "Err: Issue with response!\n";

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

	return \%info;
}

sub bill_snap {
	my $self = shift;

	my $res = post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		canReload => 1,
		startCollapsed => 1,
		cacheLevel => 'none',
		miniDoc => 'Billing Snapshot that customers see',
		widgetName => 'billingSnapshot',
		username => $self->{'user'},
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/billingSnapshot',
		title => 'Billing Snapshot',
		load_widget => 1,
		__got_widget_js => 1
	}) or croak "Err: Issue with reponse!\n";

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

	return \@transactions;
}

sub domains {
	my $self = shift;

	my $res = post_request({
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
		username => $self->{'user'},
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php/Category:Domains',
		title => 'Domains',
		showAll => 1,
		load_widget => 1,
		clear_widget_cache => 1,
		__got_widget_js => 1,
	}) or croak "Err: Issue with response!\n";

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

	return \@domains;
}

sub tech_info {
	my $self = shift;

	my $res = post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		canReload => 1,
		cacheLevel => 'none',
		OSSFlag => 'CSFE_BASIC',
		widgetName => 'vps_info_new',
		username => $self->{'user'},
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/vps_info_new',
		title => 'VPS Info',
		load_widget => 1,
		__got_widget_js => 1,
	}) or croak "Err: Issue with response!\n";

	my %info;
	while ( $res =~ m`<strong>(?<Key>.*):</strong>\n?\s*</td>\n?\s*<td>\s*(<a\s*href=".*"\s*target="_blank">(?<Value>.*)</a>|(?<Value>[a-zA-Z0-9 -]+))\n?\s*</td>`gix ) {
		$info{"$+{Key}"} = $+{Value};
	}

	return \%info;
}

sub tickets {
	my $self = shift;

	my $res = post_request({
		defaultTier => 'tierIII',
		canExpand => 1,
		cacheTTL => '12 hours',
		canReload => 1,
		OSSFlag => 'CSFE_BASIC',
		cacheLevel => 'perCustomer',
		miniDoc => 'Displays recent Polaris and CSES contacts for this customer.',
		widgetName => 'recent_polaris',
		height => 350,
		username => $self->{'user'},
		subsystemID => 3000,
		docPath => 'https://wiki.bizland.com/support/index.php/CSFE#CSES.2FPolaris_Activity',
		title => 'CSES/Polaris Activity',
		load_widget => 1,
		__got_widget_js => 1,
	}) or croak "Err: Issue with response!\n";

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

	return \@tickets;
}

sub dns_records {
	my $self = shift;

	$self->{'domain'} = $self->{'user'};
	$self->{'user'} = search($self->{'domain'});


	my $res = post_request({
		canExpand => 1,
		defaultTier => 'tierIII',
		canReload => 1,
		cacheLevel => 'none',
		tool => '/csfe/tools/domainconsole.cmp',
		widgetName => 'tech_tools_popup',
		Domain => $self->{'domain'},
		username => $self->{'user'},
		subsystemID => 1100,
		PropertyID => 33,
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/tech_tools_popup',
		title => 'Tools',
		load_widget => 1,
		__got_widget_js => 1
	}) or croak "Err: Issue with response!\n";

	my %obj = (
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
			$self->{'mx'} = $+{Mx_ID};
			$self->{'property_id'} = substr($self->{'mx'}, 0, 2);
		} elsif (exists $+{Domain_ID}) {
			$self->{'id'} = $+{Domain_ID};
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

	return \%obj;
}

sub dns_add {
	my $self = shift;
	my $domain = shift;

	if (!defined $self->{'domain'} || !$self->{'domain'} eq $domain) {
		$self->{'domain'} = $domain;
		$self->{'user'} = search($self->{'domain'});
		
		my $res = post_request({
			canExpand => 1,
			defaultTier => 'tierIII',
			canReload => 1,
			cacheLevel => 'none',
			tool => '/csfe/tools/domainconsole.cmp',
			widgetName => 'tech_tools_popup',
			Domain => $self->{'domain'},
			username => $self->{'user'},
			subsystemID => 1100,
			PropertyID => 33,
			docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/tech_tools_popup',
			title => 'Tools',
			load_widget => 1,
			__got_widget_js => 1
		}) or croak "Err: Issue with response!\n";

		while ($res =~ m`
		.*name="CurrentMX"\s+value="(?<Mx_ID>\d+)"> |
		.*name="domain_id"\s+value="(?<Domain_ID>\d+)"
		`gix) {
			if (exists $+{Mx_ID}) {
				$self->{'mx'} = $+{Mx_ID};
				$self->{'property_id'} = substr($self->{'mx'}, 0, 2);
			} elsif (exists $+{Domain_ID}) {
				$self->{'id'} = $+{Domain_ID};
			}
		}
	}

	croak "Adding a record requires a minimum of 4 arguments!\n" unless scalar @_ >= 3;
	my ($type, $name, $record, $priority) = @_;
	$type = uc $type;
	croak "Unable to add '$type' DNS record!\n" unless $type =~ /^A|CNAME|MX|TXT|NS|SOA$/;

	my %params = (
		UserName => $self->{'user'},
		Domain => $self->{'domain'},
		NewOwner => '',
		add_db_record => 'Add Record',
		CurrentMX => $self->{'mx'},
		newmx => 'new',
		MX => $self->{'mx'},
		domaintemplate => 2,
		oldtype => 1,
		Native => 1,
		master => '',
		domain_id => $self->{'id'},
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
		username => $self->{'user'},
		subsystemID => 1100,
		PropertyID => $self->{'property_id'},
		docPath => 'https://wiki.bizland.com/wiki/index.php/Widgets/tech_tools_popup',
		title => 'Tools',
		load_widget => 1,
		clear_widget_cache => 1,
		__got_widget_js => 1
	);

	my $res = post_request(\%params);
        if ($res) {
                return 1;
        } else {
                croak "Err: Unable to create $type record '$name => $record'\n";
        }

}
	

1;
