package vDeck;
use strict;
use warnings;

use CSFE;

sub new {
	my $class = shift;
	my $self = {
		user => shift,
	};

	init();

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
	}) or die "Err: Issue with response!";

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

	return \@tickets;
}

sub vps_info {
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
	}) or die "Err: Issue with response!";

	my %info;
	while ($res =~ m`
	<td.*>\n?\s*<strong>(?<Key>.*):</strong>\n?\s*</td>\n?\s*<td>\n?\s*(<a.*>(?<Value>.*)</a>|(?<Value>.*))\n?\s*</td>
	`gix) {
		next if $+{Key} =~ /Container Status|\w+ Login/;
		$info{"$+{Key}"} = $+{Value};
	}

	return \%info;
}

1;
