# $Id$
use strict;
use Test::More tests => 2;
use DateTime;

BEGIN {
    use_ok 'DateTime::Format::Mail';
}

my $class = 'DateTime::Format::Mail';
my $f = $class->new()->loose();

# Can we parse?

chdir 't' if -d 't';
my $tests = my $ok = 0;

open my $dates, '<', 'sample_dates' or die "Cannot open date samples: $!";
while (<$dates>)
{
    chomp;
    my $p = eval { $f->parse_datetime( $_ ) };
    if (defined $p and ref $p and not $@) {
	$ok++;
    } else {
	diag "Could not parse $_";
    }
    $tests++;
}
close $dates;

ok($ok == $tests, "Sample date tests.");
