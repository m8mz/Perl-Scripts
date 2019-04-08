use strict;
use warnings;

my $dir = "/home/indianv5/mail/new";

opendir my $d, $dir or die "Err: $!";
my @files = readdir $d;
closedir $d;

my @emails;
my $count = 0;

FILE: foreach my $file (@files) {
	open my $fh, $file or die "Err: $!";
	while (my $line = <$fh>) {
		if ($line =~ /Subject:\s+Cron <indianv5\@server>/) {
			$count++;
			print $count, "\n";
			push @emails, $file;
			next FILE;
		}
	}
	close $fh;
}

unlink @emails;

print "Emails are gone!\n";
