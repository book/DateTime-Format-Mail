# $Id$
use strict;
use Test::More tests => 7;

BEGIN {
    use_ok 'DateTime::Format::Mail';
}

my $class = 'DateTime::Format::Mail';

# Can we format?

{
    my $parse = sub {
	my $type = shift;
	my $obj = shift;
	my $dates = shift || [
	[ 1047278957 => '+0900' => 'Mon, 10 Mar 2003 15:49:17 +0900' ],
	[ 1047278958 => '-0500' => 'Mon, 10 Mar 2003 01:49:18 -0500' ],
	[ time() => '+1000' => qr{^[A-Z][a-z][a-z],\s\d\d
	    \s[A-Z][a-z][a-z]\s\d{4}\s\d\d:\d\d:\d\d\s[\+\-]\d{4}$}x ],

	];

	for my $data (@$dates)
	{
	    my ($epoch, $tz, $expected) = @$data;
	    my $dt = DateTime->from_epoch( epoch => $epoch );
	    $dt->set_time_zone( $tz );
	    my $back = $obj->format_datetime( $dt );
	    if (ref $expected eq 'Regexp')
	    {
		like ( $back => $expected,
		    "($type) Format of $epoch ($tz) is $expected" );
	    }
	    else
	    {
		is ( $back => $expected,
		    "($type) Format of $epoch ($tz) is $expected" );
	    }
	}
    };

    $parse->( 'obj', $class->new );
    $parse->( 'class', $class );
}
