#!/usr/bin/env perl
# Description: This will interact with the database fields for home and siteurl in WordPress databases.
# Use:
# wpurl - Running this script with no arguments will print out the current home and siteurl fields from the database.
# -n) wpurl -n https://www.wordpress.org - This will update both the home and siteurl fields.
# -h) wpurl -h https://www.wordpress.org - This will only update the home field.
# -s) wpurl -s https://www.wordpress.org - This will only update the site field.
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;
use feature qw(say);
use DBI;

######################### Help Menu ########################
my $help_message = qq|Description: This will interact with the database fields for home and siteurl in WordPress databases.
Use:
wpurl - Running this script with no arguments will print out the current home and siteurl fields from the database.
-n) wpurl -n https://www.wordpress.org - This will update both the home and siteurl fields.
-h) wpurl -h https://www.wordpress.org - This will only update the home field.
-s) wpurl -s https://www.wordpress.org - This will only update the site field.|;



my $file = "wp-config.php";
my $dbname;
my $prefix;

if (-f $file) {
	open(my $fh, '<', $file) or die "Couldn't open file: $!";
	while (my $line = <$fh>) {
		chomp $line;
		# Stop the while loop if both variables are not empty
		if ($dbname && $prefix) {
			last;
		}
		# Grabs the database name
		if (($line =~ /^define\('DB_NAME', '(.*)'/) && (!$dbname)) {
			$dbname = $1;
			next;
		}
		# Grabs the table prefix
		if (($line =~ /table_prefix\s+= '(.*)'/) && (!$prefix)) {
			$prefix = $1;
			next;
		}
	}
	# say $dbname;
	# say $prefix;
	close $fh;
} else {
	say "File Error: No wp-config.php in CWD.";
	exit;
}

# check if the user running the script is root && start database connection
my $dbh;
if ( $ENV{USER} eq "root" ) {
	$dbh = DBI->connect("DBI:mysql:$dbname", 'root')
			or die "Couldn't connect to $dbname: " . DBI->errstr;
} else {
	say "Requires root execution.";
	exit;
}

if (@ARGV) {
	# arguments passed to the script
	# looking for [-n], [-h], and [-s] for the first argument
	my $flag = shift;
	my $url = shift;
	if ($flag eq "-n") {
		run_query($url);
		display_urls();
	} elsif ($flag eq "-h") {
		target_query($url, "home");
		display_urls();
	} elsif ($flag eq "-s") {
		target_query($url, "siteurl");
		display_urls();
	} else {
		# TODO will need to add a help/usage message explaining basic usage of the script.
		say $help_message;
		exit;
	}
} else {
	# no arguments passed just print out the home and siteurl fields
	display_urls();
}

################################################## Functions #######################################################

sub display_urls {
	my $sth = $dbh->prepare("SELECT option_name, option_value FROM ${prefix}options WHERE option_name = 'siteurl' OR option_name = 'home'")
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
	while (my @data = $sth->fetchrow_array()) {
		my $option_name = uc $data[0];
		printf("%-7s: ", $option_name);
		say $data[1];
	}
}

# will update both siteurl and home fields
sub run_query {
	my $url = shift;
	my $sth = $dbh->prepare("UPDATE ${prefix}options SET option_value = ? WHERE option_name = 'siteurl' OR option_name = 'home'")
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute($url) or die "Couldn't execute statement: " . $sth->errstr;
}

# will target either home or siteurl fields
sub target_query {
	my $url = shift;
	my $option_name = shift;
	my $sth = $dbh->prepare("UPDATE ${prefix}options SET option_value = ? WHERE option_name = ?")
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute($url, $option_name) or die "Couldn't execute statement: " . $sth->errstr;
}
