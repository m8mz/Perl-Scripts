use Encode;
use URI::Escape;

my $in = "%C3%B3";
my $text = Encode::decode('utf8', uri_unescape($in));

print length($text);    # Should print 1
