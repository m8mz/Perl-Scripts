use strict;
use warnings;

use Data::Dumper;

my $file = "text.txt";

open(my $fh, '<', $file) or die "Can't open file!: $!";

my $line = <$fh>;
chomp $line;

while ($line =~ /(\w+)=([A-Za-z0-9\.:\/_ ]*)/g) {
	print $1, " = ", $2, "\n";
}
