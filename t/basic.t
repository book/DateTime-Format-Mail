# $Id$
use strict;
use Test::More tests => 4;

BEGIN {
    use_ok 'DateTime::Format::Mail';
}

my $class = 'DateTime::Format::Mail';

# Does new() work properly?
{
    eval { $class->new('fnar') };
    ok( ($@ and $@ =~ /^Odd number/), "Odd number of args spotted." );

    my $obj = eval { $class->new() };
    ok( !$@, "Created object" );
    isa_ok( $obj, $class );

}

