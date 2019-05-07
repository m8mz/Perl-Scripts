# Author: Marcus Hancock-Gaillard
package CSFE;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use Config::Simple;
use Exporter qw(import);
use Term::ReadKey;
use Carp;

our @EXPORT = qw(
        get_request
        post_request
	init
	search
);
our @EXPORT_OK = qw(
        _set_cookie
        _check_cookie
);

my $username = "mhancock-gaillard";
my $cookie_file = $ENV{'HOME'} . "/local/cookies/csfecookie";

sub _set_cookie {
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
}

sub _check_cookie {
        # check if cookie file exists > get modification time of cookie file > check if modified under 8 hours and size is above 1500KB
        return 0 unless -f $cookie_file; 
	my $limit = 28800; # 8 hours in seconds
	my $mtime = (stat($cookie_file))[9];
        my $time_since = time() - $mtime;
	my $size = -s $cookie_file;
	if ($time_since < $limit && $size == 215) {
		return 1;
	} else {
		return 0;
	}
}

sub get_request {
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
                print Dumper($res);
		croak "Err: No content or response code not 200!\n";
	}
}

sub post_request {
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

	# check if response has redirect to login meaning a bad password when user inputed password for cookie
	if ($res->header('x-redirect')) {
		croak "Err: Would suggest that the cookie file is bad/corrupt. Remove '$cookie_file'.\n";
	}

        if ($res->code == 200 and $res->content) {
                return $res->content;
        } else {
		print Dumper($res);
                croak "Err: No content or response code not 200!\n";
        }
}

sub _pass {
	print "Password: ";
	ReadMode('noecho');
	my $password = ReadLine(0);
	chomp $password;
	ReadMode('normal');
	print "\n";
	return $password;
}

sub init {
        if (_check_cookie()) {
		return 1;
        } else {
        	print "Cookie is either expired or does not exist!\n";
                my $_pass = _pass();
                if (_set_cookie($_pass)) {
                        print "Success!\n";
			print "Cookie is valid for 8 hours.\n";
                        return 1;
                } else {
                        croak "Failed to login!";
                }                
        }
}

sub search {
	# search for vDeck username from IP address, domain, or email address
	my $arg = shift or croak "Need an argument to search for a vDeck username!\n";
	my $link = 'https://admin.enduranceoss.com/csfe/search.html';
	my %o = (
		advanced_search => $arg
	);
	if ($arg =~ /(\d{1,3}\.){3}\d{1,3}/) {
		$o{"search_type"} = "VPSIP";
	} else {
		$o{"search_type"} = "domain";
	}
	my $res = post_request(\%o, $link);
	if ($res =~ m`<a\s+href="/csfe/general\.html\?username=([\w\.0-9]+)"`gix) {
		return $1;
	} else {
		return 0;
	}
}

1;
