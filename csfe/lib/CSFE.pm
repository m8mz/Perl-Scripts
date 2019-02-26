package CSFE;
use strict;
use warnings;

use LWP::UserAgent;
# use Data::Dumper;
use HTTP::Cookies;
use Config::Simple;
use Exporter qw(import);
use Term::ReadKey;

our @EXPORT = qw(
	csfe_set_cookie
	check_config
	set_config
	get_all_config
	csfe_check_cookie
        csfe_get_request
        csfe_post_request
);

my $home = $ENV{'HOME'};
my $cookie_file = $home . "/temp/cookies/csfeperl";
my $c = $home . "/temp/config/config.ini";

sub csfe_set_cookie {
	my $username = shift or die "Missing username param for set_csfe_cookie in $0";
	my $password = shift or die "Missing password param for set_csfe_cookie in $0";
	my $cookie_jar = HTTP::Cookies->new(
		ignore_discard => 1,
		autosave => 1,
		file => $cookie_file
	);
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
		return 1;
	} else {
		return 0;
	}
}

{
	# Config Sub-Routines
	my $cfg = new Config::Simple(syntax => 'ini');
	$cfg->autosave(1);

	sub check_config {
		if (-f $c) {
			$cfg->read($c) or die $cfg->error(); # read config file TODO: add error check for corrupt file
			my %c = $cfg->vars(); # save current config values to hash
			if (!defined $c{"user.username"}) {
				return 0;
			} else {
				return 1;
			}
		} else {
			return 0;
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
				return 0;
				last;
			}
		}
		return 1;
	}

	sub get_all_config {
		my %config = $cfg->vars();
		return \%config;
	}

}

sub csfe_check_cookie {
        return 0 unless -f $cookie_file; # cookie file doesn't exist
	my $limit = 28800; # 8 hours in second
	my $mtime = (stat($cookie_file))[9];
        my $time_since = time() - $mtime;
	if ($time_since < $limit) {
		return 1;
	} else {
		return 0;
	}
}

sub csfe_get_request {
        my $url = shift || "https://admin.enduranceoss.com/WidgetWrapper.cmp";
        my $o = shift or die "No params sent with GET request.";
	my $cookie_jar = HTTP::Cookies->new(
		file => $cookie_file
	);
	my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
	$ua->agent('Mozilla/5.0');
	my $res = $ua->get($url, $o);
	if ($res->code == 200 and $res->content) {
		return $res->content;
	} else {
		return 0;
	}
}

sub csfe_post_request {
        my $url = shift || "https://admin.enduranceoss.com/WidgetWrapper.cmp";
        my $o = shift or die "No params sent with POST request.";
	my $cookie_jar = HTTP::Cookies->new(
		file => $cookie_file
	);
	my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
	$ua->agent('Mozilla/5.0');
        my $res = $ua->post($url, $o);
        if ($res->code == 200 and $res->content) {
                return $res->content;
        } else {
                return 0;
        }
}

sub csfe_check_all {
        my $username;
        my $password;
        sub user_n_pass {
                my $x = shift || 1; # by default asks for Username but if passed 0 will skip
                if ($x) {
                        print "Username: ";
                        $username = <STDIN>;
                        chomp $username;
                }
                print "Password: ";
                ReadMode('noecho');
                $password = ReadLine(0);
                chomp $password;
                ReadMode('normal');
        }

        if (csfe_check_cookie()) {

        } else {
                print "Cookie is either expired or does not exist!\n";
                if (check_config()) {
                        my $c = get_all_config();
                        user_n_pass(0);
                } else {
                        user_n_pass();
                        if (csfe_set_cookie($username, $password) {
                                print "Successfully updated configuration and set CSFE cookie!\n" if set_config('user', $username);
                                return 1;
                        } else {
                                print "Failed to set cookie!\n";
                                return 0;
                        }
                }
        }

1;
