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

{
    local *DATES;

    # Smart open since 5.008 will need to do a raw read rather
    # than interpret the data as anything other than bytes.
    do { if ( $] >= 5.008 ) {
        eval "open DATES, '<:raw', 'sample_dates'";
    } else {
        open DATES, '< sample_dates';
    } } or die "Cannot open date samples: $!";

    while (<DATES>)
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
    close DATES;
}

ok($ok == $tests, "Sample date tests.");
