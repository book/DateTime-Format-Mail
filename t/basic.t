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
    ok( $@ and $@ =~ /takes no param/, "Too many parameters exception" );

    my $obj = eval { $class->new() };
    ok( !$@, "Created object" );
    isa_ok( $obj, $class );

}

