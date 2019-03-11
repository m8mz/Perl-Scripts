# Author: Marcus Hancock-Gaillard
package CSFE;
use strict;
use warnings;

use LWP::UserAgent;
use Data::Dumper;
use HTTP::Cookies;
use Config::Simple;
use Exporter qw(import);
use Term::ReadKey;
use Carp;

our @EXPORT = qw(
        csfe_get_request
        csfe_post_request
	csfe_check_all
);
our @EXPORT_OK = qw(
        csfe_set_cookie
        check_config
        set_config
        get_all_config
        csfe_check_cookie
);

my $home = $ENV{'HOME'};
my $cookie_file = $home . "/local/cookies/csfecookie";
my $c = $home . "/local/config.ini";
my $LOCAL = 1;

sub csfe_set_cookie {
        # Get user/pass and set login URL. Created cookie and attached to useragent
	my $username = shift or croak "Missing \$username param for set_csfe_cookie in $0";
	my $password = shift or croak "Missing \$password param for set_csfe_cookie in $0";
	my $url = "https://enduranceoss.com/cs/oss_login.html";
	my $cookie_jar = HTTP::Cookies->new(
		ignore_discard => 1,
		autosave => 1,
		file => $cookie_file
	);
	my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
	$ua->agent('Mozilla/5.0');
	
        # Send login request. 302 response code means successful
	my $res = $ua->post( $url, {
		oss_redirect => 'https://admin.enduranceoss.com/cs/',
		oss_user_name => $username,
		oss_password => $password,
		oss_login => 'Login'
	} );
	
	if ($res->code eq 302) {
		return 1;
	} else {
		return 0;
	}
} # END

{
	# Config Sub-Routines
	my $cfg = new Config::Simple(syntax => 'ini');
	$cfg->autosave(1);

	sub check_config {
                # check if config file exists > read the file and save values to hash > check if the username field exists
		if (-f $c) {
			$cfg->read($c) or croak $cfg->error();
			my %c = $cfg->vars();
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
                # set block, receive hash ref (set), save current config > add new set to current config > set and save block
		my $block = 'user';
		my $set = shift or croak "Missing \\\%set param for set_config in $0";
		my %config = $cfg->vars();
		foreach my $k (keys %$set) { # Add new key, value pair(s) to current config
			my $key = $block . '.' . $k;
			$config{$k} = $set->{$k};
		}
		$cfg->set_block($block, \%config);
		$cfg->save($c) or croak $cfg->error();

                # get config after update > check if updated correctly or return 0
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
                # return hash of config
		my %config = $cfg->vars();
		return \%config;
	}

} # END

sub csfe_check_cookie {
        # check if cookie file exists > get modification time of cookie file > check if modified under 8 hours and size is above 1500KB
        return 0 unless -f $cookie_file; 
	my $limit = 28800; # 8 hours in seconds
	my $mtime = (stat($cookie_file))[9];
        my $time_since = time() - $mtime;
	my $size = -s $cookie_file;
	if ($time_since < $limit && $size > 1500) {
		return 1;
	} else {
		return 0;
	}
} # END

sub csfe_get_request {
        # get req params and get url or set default url > create cookie and save to useragent
        my $o = shift or croak "No params sent with GET request";
	my $url = shift // "https://admin.enduranceoss.com/WidgetWrapper.cmp";
	my $cookie_jar = HTTP::Cookies->new(
		file => $cookie_file
	);
	my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
	$ua->agent('Mozilla/5.0');

        # send GET request > if response code 200 and content exists then return content or return 0
	my $res = $ua->get($url, $o);
	if ($res->code == 200 and $res->content) {
		return $res->content;
	} else {
                carp Dumper($res);
		return 0;
	}
} # END

sub csfe_post_request {
        if ($LOCAL) { # LOCAL ENVIRONMENT
                my $name = shift or croak "Provide a filename";
                my $file = '../example_responses/' . $name . '.txt';
                open(my $fh, '<', $file) or die "Err: Can't open '$file' $!";
                my $res = do { local $/; <$fh> };
                return $res;
        }
        # post req params and post url or set default url > create cookie and save to useragent
        my $o = shift or croak "No params sent with POST request.";
	my $url = shift // "https://admin.enduranceoss.com/WidgetWrapper.cmp";
	my $cookie_jar = HTTP::Cookies->new(
		file => $cookie_file
	);
	my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
	$ua->agent('Mozilla/5.0');

        # send POST request > if response code 200 and content exists then return content or return 0
        my $res = $ua->post($url, $o);
        if ($res->code == 200 and $res->content) {
                return $res->content;
        } else {
		carp Dumper($res);
                return 0;
        }
} # END

sub user_n_pass {
        # return username and/or password
	my $x = shift; # ask for Username if arg is true but if arg is false statement only asks for password
	my $username;
	if ($x) {
		print "Username: ";
		$username = <STDIN>;
		chomp $username;
	}
	print "Password: ";
	ReadMode('noecho');
	my $password = ReadLine(0);
	chomp $password;
	ReadMode('normal');
	print "\n";
	return ($username) ? { username => $username, password => $password } : $password;
} # END

sub csfe_check_all {
        return 1 if $LOCAL;
        if (csfe_check_cookie()) {
		return 1;
        } else {
                print "Cookie is either expired or does not exist!\n";
                if (check_config()) {
                        my $c = get_all_config();
                        my $password = user_n_pass(0);
			if (csfe_set_cookie($c->{'user.username'}, $password)) {
				return 1;
			} else {
				croak "Failed to login!";
			}
                } else {
                        my $user_or_pass = user_n_pass(1);
                        if (csfe_set_cookie($user_or_pass->{'username'}, $user_or_pass->{'password'})) {
                                print "Successfully updated configuration and set CSFE cookie!\n" if set_config('user', { username => $user_or_pass->{'username'}});
                                return 1;
                        } else {
                                croak "Failed to login!";
                        }
                }
        }
} # END

1;
