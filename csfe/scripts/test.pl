use strict;
use warnings;
use Data::Dumper;

my $string = '<td><nobr>Credit card</nobr></td>';

while (1) {
	if ($string =~ /<(\w+).*?>(.*)<\/\1>/) {
		print $2, "\n";
		$string = $2;
	} else {
		last;
	}
}
