#!/usr/bin/env perl
# Description: This will interact with the main and mail DB connections to grab the GSuite information for a specific account or mailbox to help with the process of escalating JIRAs.
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;
use DBI;
#use Data::Dumper; only used to check variables

######################### Help Menu ########################
my $help_message = qq|Examples of Usage:
gsuiteuser ipg.anexampleonly
gsuiteuser ipg.anexampleonly test\@admin.com
gsuiteuser [USERNAME] <MAILBOX>\n|;



my $dbmain_port = "3300";
my $dbmail_port = "3301";
my $db_billing = "billing";
my $db_mailsettings = "mailsettings";
my $db_user = "support";
my $db_pass = "t1wamfn";
my $db_host = "walsupporthub01";

# initiate db connections
my $dbh_1 = DBI->connect("DBI:mysql:$db_billing:$db_host:$dbmain_port", $db_user, $db_pass, { RaiseError => 1 }) or die "Couldn't connect to $db_billing: " . DBI->errstr;
my $dbh_2 = DBI->connect("DBI:mysql:$db_mailsettings:$db_host:$dbmail_port", $db_user, $db_pass, { RaiseError => 1 }) or die "Couldn't connect to $db_mailsettings: " . DBI->errstr;

if (@ARGV) {
	my $account = shift;
	my $mailbox = shift || undef;
	if ($mailbox) {
		my $sth1 = $dbh_1->prepare("SELECT ACLID, UserName, Mailbox, Status FROM GoogleApps WHERE Mailbox = ?") or die "Couldn't prepare statement: " . $dbh_1->errstr;
		# checking if anything returned from db statement
		if (my $rows = $sth1->execute($mailbox)) {
			if ($rows == 0) {
				$sth1->finish;
				# if nothing found check for an available aclid credit to be applied
				my @users = gsuiteall($account);
				my $count = 0;
				foreach my $user (@users) {
					if ($user->[3] eq "fulfillable") {
						print "Next Available ACLID = $user->[0]\n";
						print "\t{code}UPDATE GoogleApps SET Mailbox = $mailbox, Status = 'fulfilled' WHERE ACLID = '$user->[0]' LIMIT 1;{code}\n";
						my $sth2 = $dbh_2->prepare("SELECT * FROM MailUserTable WHERE MailBox = ?") or die "Couldn't prepare statement: " . $dbh_2->errstr;
						$sth2->execute($mailbox) or die "Couldn't execute statement: " . $sth2->errstr;
						while (my @data = $sth2->fetchrow_array()) {
							# check if mailbox handler is set to Google
							if ($data[13] eq '' or $data[13] eq 'POP') {
								print "\t{code}UPDATE MailUserTable SET Handler = 'Google' WHERE MailBox = $mailbox LIMIT 1;{code}\n";
							}
						}
						$sth2->finish;
						last;
					} elsif ( $count+1 == scalar @users ) { # check if this is the last iteration through the loop
						print "The mailbox doesn't exist for Gsuite and there is no available ACLID credit that can be applied. Customer will need to purchase more licenses or swap that mailbox with an active Gsuite user.\n";
					}
					$count++;
				}
			} else {
				printf("%-10s %-20s %-30s %-15s\n", "ACLID", "UserName", "Mailbox", "Status");
				while (my @data = $sth1->fetchrow_array()) {
					printf("%-10s %-20s %-30s %-15s\n", $data[0], $data[1], $data[2], $data[3]);
				}
				$sth1->finish;
			}
		}
	} else {
		printf("%-10s %-20s %-30s %-15s\n", "ACLID", "UserName", "Mailbox", "Status");
		my @users = gsuiteall($account);
		#print Dumper \@users;
		foreach my $user (@users) {
			printf("%-10s %-20s %-30s %-15s\n", $user->[0], $user->[1], $user->[2], $user->[3]);
		}
	}
} else {
	print "No argument was provide. Please read below.\n";
	print $help_message;
}

$dbh_1->disconnect;
$dbh_2->disconnect;

# sub-routines

sub gsuiteall {
	# query for all gsuite users associated with the username
	my @allaccounts;
	my $account = shift;
	my $sth1 = $dbh_1->prepare("SELECT ACLID, UserName, Mailbox, Status FROM GoogleApps where UserName = ?") or die "Couldn't prepare statement: " . $dbh_1->errstr;
	$sth1->execute($account) or die "Couldn't execute statement: " . $sth1->errstr;
	while (my @data = $sth1->fetchrow_array()) {
		my $isdata2 = defined($data[2]) ? $data[2] : "";
		if ($isdata2 eq "" and $data[3] eq "fulfillable") {
			$data[2] = 'Available';
		} elsif ($data[3] eq "cancelled") {
			$data[2] = 'Not Available';
		}
		# insert data in the @allaccounts array
		splice @allaccounts, 0, 0, \@data;
	}
	$sth1->finish;
	# since splice is adding each data entry in the beginning of the index it creates the array in reverse order hence the reason we return the reverse @allaccounts
	return reverse @allaccounts;
}
