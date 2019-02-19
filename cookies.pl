#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard

use strict;
use warnings;
use HTTP::Cookies;
use Data::Dumper;
use WWW::Mechanize();

my $url = "https://enduranceoss.com/cs/oss_login.html";
my $cookie_jar = HTTP::Cookies->new(
	file => "$ENV{'HOME'}/csfecookie.dat",
	autosave => 1
);

my $mech = WWW::Mechanize->new( cookie_jar => $cookie_jar );

$mech->get($url);
$mech->form_name('loginForm');
$mech->set_fields(
	oss_user_name => 'mhancock-gaillard',
	oss_password => 'Supermahg36!!',
);

my $res = $mech->submit();

# print Dumper $res;
$mech->cookie_jar->extract_cookies($res);

print $mech->get('https://admin.enduranceoss.com/WidgetWrapper.cmp?defaultTier=tierIII&canExpand=1&canReload=1&startCollapsed=1&cacheLevel=none&widgetName=Technical&username=apo%2Esteveserviceagroup&subsystemID=3000&docPath=https%3A%2F%2Fwiki%2Ebizland%2Ecom%2Fwiki%2Findex%2Ephp%2FWidgets%2FTechnical&title=Technical%20Information&load_widget=1&clear_widget_cache=1&__got_widget_js=1');
print $mech->cookies_jar;
