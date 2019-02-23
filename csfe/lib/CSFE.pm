package CSFE;
use strict;
use warnings;

use LWP::UserAgent;
use Data::Dumper;
use HTTP::Cookies;
use Config::Simple;
use Exporter qw(import);

our @EXPORT = qw(
	set_csfe_cookie
	check_config
	set_config
	get_all_config
);

sub set_csfe_cookie {
	my $username = shift or die "Missing username param for set_csfe_cookie in $0";
	my $password = shift or die "Missing password param for set_csfe_cookie in $0";
	my $cookie_file = $ENV{'HOME'} . "/temp/cookies/csfeperl";
	my $cookie_jar = HTTP::Cookies->new(ignore_discard => 1, autosave => 1, file => $cookie_file);
	my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
	$ua->agent('Mozilla/5.0');
	my $url = "https://enduranceoss.com/cs/oss_login.html";
	
	my $res = $ua->post( $url, {
		oss_redirect => 'https://admin.enduranceoss.com/cs/',
		oss_user_name => $username,
		oss_password => $password,
		oss_login => 'Login'
	} );
	
	if ($res->code eq 302) { # returns 302 status when successful
		return { 1 => "Successful login for $username" };
	} else {
		return { 0 => "Failed login for $username" };
	}
}

{
	# Config Sub-Routines
	my $c = 'lib/config.ini';
	my $cfg = new Config::Simple(syntax => 'ini');
	$cfg->autosave(1);

	sub check_config {
		if (-f $c) {
			$cfg->read($c) or die $cfg->error(); # read config file TODO: add error check for corrupt file
			my %c = $cfg->vars(); # save current config values to hash
			if (!defined $c{"user.username"}) {
				return { 0 => 'No username value in config!' };
			} else {
				return { 1 => $c{"user.username"} };
			}
		} else {
			return { 0 => 'Config file doesnt exist!' }; # TODO: change all returns to an anonymous hash
		}
	}

	sub set_config {
		my $block = shift or die "Missing block param for set_config in $0";
		my $set = shift or die "Missing set hash param for set_config in $0";
		my %config = $cfg->vars();
		foreach my $k (keys %$set) { # Add new key, value pair(s) to current config
			my $key = $block . '.' . $k;
			$config{$k} = $set->{$k};
		}
		$cfg->set_block($block, \%config);
		$cfg->save($c);
		my $temp = $cfg->get_block($block);
		foreach my $k (keys %config) {
			if (!defined $temp->{$k}) {
				return { 0 => 'Issue with updating config values.' };
				last;
			}
		}
		return { 1 => 'Configuration file updated.' };
	}

	sub get_all_config {
		my %config = $cfg->vars();
		return \%config;
	}

}
	

1;
