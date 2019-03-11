#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname( abs_path $0 ) . '/lib';

use CSFE;

die "Failed CSFE check_all()" unless csfe_check_all();

# Required Variables
my $username;
my $domain;

# Add DNS Record
my $type;
my $name;
my $record;
my $priority = '';


GetOptions(
	'username|u=s' => \$username,
	'domain|d=s' => \$domain,
	'type|t=s' => \$type,
	'name|n=s' => \$name,
	'record|r=s' => \$record,
	'priority|p=s' => \$priority,
) or die "Usage: $0 [--username|-u] USER\n"; # TODO: add help message
if (!$username or !$domain) {
	die "Usage: $0 [--username|-u] USER [--domain|-d] DOMAIN\n";
}

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
print "here\n";

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
print "here\n";
#print Dumper \%obj;


# ==== Sub Routines ====

sub add_record {
	my $property_id = substr $obj{'mx'}, 0, 2;
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

	foreach my $r (@{$obj{'dns'}}) {
		my $oldrecordtype = 'oldrecordtype_' . $r->{'id'};
		my $oldrecordname = 'oldrecordname_' . $r->{'id'};
		my $oldrecord = 'oldrecord_' . $r->{'id'};
		my $record = 'record_' . $r->{'id'};
		my $oldprio = 'oldprio_' . $r->{'id'};
		my $prio = 'prio_' . $r->{'id'};

		$params{"$oldrecordtype"} = $r->{'type'};
		$params{"$oldrecordname"} = $r->{'name'};
		$params{"$oldrecord"} = $r->{'record'};
		$params{"$record"} = $r->{'record'};
		if ($r->{'priority'}) {
			$params{"$oldprio"} = $r->{'priority'};
			$params{"$prio"} = $r->{'priority'};
		}
	}

	#print Dumper \%params;
	my $res = csfe_post_request(\%params);
	if ($res) {
		print "Added record.\n";
	}
}

if (defined $type && defined $name && defined $record) {
	add_record($type, $name, $record);
}
