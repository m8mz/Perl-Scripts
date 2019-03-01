# One off situation needed to search through mailbox to get the subject line of each email

use strict;
use warnings;

my $dir = "cur";

opendir my $d, $dir or die "Err: $!";
my @files = readdir $d;
closedir $d;

my %hash;
my @array;

foreach my $file (@files) {
	$file = $dir . "/" . $file;
	open my $fh, $file or die "Err: $!";
	my $subject;
	while (my $line = <$fh>) {
		if ($line =~ /Subject:\s+(.*)/) {
			$subject = $1;
			if ($subject =~ /Warning: message .* delayed/) {
				push @array, $subject;
			}
		}
		last if defined $subject;
	}
	close $fh;
}

print scalar @array, "\n";

#foreach my $k (sort { $hash{$a} <=> $hash{$b} } keys %hash) {
#	my $count = 0;
#	if ($count < 10) {
#		print $hash{$k}, " - ", $k, "\n";
#		$count++;
#	} else {
#		last;
#	}
#}

