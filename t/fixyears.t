use strict;
use Test::More tests => 18;
use vars qw( $class );
BEGIN {
    $class = 'DateTime::Format::Mail';
    use_ok $class;
}

sub run_our_tests
{
    my ($fn, $testsuite) = @_;
    for my $label (sort keys %$testsuite)
    {
	my $tests = $testsuite->{$label};
	for my $input (sort keys %$tests)
	{
	    my $expected = $tests->{$input};
	    is $fn->( $input ) => $expected => "$label ($input)";
	}
    }
}

# Test defaults

{
    my $fn = sub {
	$class->fix_year( @_ );
    };

    my %testsuite = (
	'valid' => {
	    '1900' => '1900',
	    '2000' => '2000',
	    '2900' => '2900',
	},
	'low' => {
	    '10' => '2010',
	    '40' => '2040',
	},
	'high' => {
	    '70' => '1970',
	    '90' => '1990',
	},
    );
    run_our_tests( $fn => \%testsuite );
}

# Test customs

{
    my $parser = $class->new();
    isa_ok( $parser => $class );
    is( $parser->year_cutoff => 60, "Default is default." );
    $parser->set_year_cutoff( 20 );
    is( $parser->year_cutoff => 20, "Default overriden." );
}

{
    my $parser = $class->new( year_cutoff => 20 );
    my $fn = sub {
	$parser->fix_year( @_ );
    };

    my %testsuite = (
	'valid' => {
	    '1900' => '1900',
	    '2000' => '2000',
	    '2900' => '2900',
	},
	'low' => {
	    '10' => '2010',
	},
	'high' => {
	    '40' => '1940',
	    '70' => '1970',
	    '90' => '1990',
	},
    );
    run_our_tests( $fn => \%testsuite );
}
