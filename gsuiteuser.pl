#!/usr/bin/env perl
# Description: This will interact with the main and mail DB connections to grab the GSuite information for a specific account or mailbox to help with the process of escalating JIRAs.
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;
use DBI;
use Data::Dumper;

######################### Help Menu ########################
my $help_message = qq|Examples of Usage:
gsuiteacct ipg.anexampleonly\n|;



my $dbmain_port = "3300";
my $dbmail_port = "3301";
my $db_billing = "billing";
my $db_mailsettings = "mailsettings";
my $db_user = "support";
my $db_pass = "t1wamfn";
my $db_host = "walsupporthub01";

my $dbh_1;
my $dbh_2;

# initiate db connections
$dbh_1 = DBI->connect("DBI:mysql:$db_billing:$db_host:$dbmain_port", $db_user, $db_pass, { RaiseError => 1 }) or die "Couldn't connect to $db_billing: " . DBI->errstr;

if (@ARGV) {
	my $account = shift;
	my $mailbox = shift || undef;
	if ($mailbox) {
		my $sth1 = $dbh_1->prepare("SELECT * FROM GoogleApps WHERE Mailbox = ?") or die "Couldn't prepare statement: " . $dbh_1->errstr;
		# checking if anything returned from db statement
		if (my $rows = $sth1->execute($mailbox)) {
			if ($rows == 0) {
				# if nothing found check for an available aclid credit to be applied
				my @users = gsuiteall($account);
				my $length = scalar @users;
				for ( my $count = 0; $count < @users; $count++ ) {
					if ($users[3] eq "fulfillable") {
						print "Next Available ACLID = $users[0]\n";
						print "\t{code}UPDATE GoogleApps SET Mailbox = $mailbox, Status = 'fulfilled' WHERE ACLID = '$users[0]' LIMIT 1;{code}\n";
						last;
					} elsif ( $count+1 == scalar @users ) {
						print "None available\n";
					}
				}
			} else {
				printf("%-10s %-20s %-30s %-15s\n", "ACLID", "UserName", "Mailbox", "Status");
				while (my @data = $sth1->fetchrow_array()) {
					printf("%-10s %-20s %-30s %-15s\n", $data[1], $data[3], $data[4], $data[5]);
				}
			}
		}
	} else {
		gsuiteall($account);
	}
} else {
	print "No argument was provide. Please read below.\n";
	print $help_message;
}


# sub-routines

sub gsuiteall {
	# query for all gsuite users associated with the username
	my @allaccounts;
	my $account = shift;
	my $sth1 = $dbh_1->prepare("SELECT ACLID, UserName, Mailbox, Status FROM GoogleApps where UserName = ?") or die "Couldn't prepare statement: " . $dbh_1->errstr;
	$sth1->execute($account) or die "Couldn't execute statement: " . $sth1->errstr;
	while (my @data = $sth1->fetchrow_array()) {
		if ($data[2] eq "") {
			$data[2] = 'Available';
		}
		# insert data in the @allaccounts array
		splice @allaccounts, 0, 0, \@data;
	}
	# since splice is adding each data entry in the beginning of the index it creates the array in reverse order hence the reason we return the reverse @allaccounts
	return reverse @allaccounts;
}
