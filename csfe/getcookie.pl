use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Cookies;

my $cookie_jar = HTTP::Cookies->new(ignore_discard => 1, autosave => 1, file => "$ENV{'HOME'}/temp/cookies/csfeperl");
my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
$ua->agent('Mozilla/5.0');
my $url = "https://enduranceoss.com/cs/oss_login.html";

my $res = $ua->post( $url, {
	oss_redirect => 'https://admin.enduranceoss.com/cs/',
	oss_user_name => 'mhancock-gaillard',
	oss_password => '##########',
	oss_login => 'Login'
} );


print Dumper $res;
