package DateTime::Format::Mail;
# $Id$

=head1 NAME

DateTime::Format::Mail - Convert between DateTime and RFC2822/822 formats

=cut

use strict;
use 5.005;
use Carp;
use DateTime 0.08;
use Params::Validate qw( validate SCALAR );
use vars qw( $VERSION );

$VERSION = '0.24';

=head1 SYNOPSIS

    use DateTime::Format::Mail;

    # From RFC2822 via class method:

    my $datetime = DateTime::Format::Mail->parse_datetime(
	"Sat, 29 Mar 2003 22:11:18 -0800"
    );
    print $datetime->ymd('.'); # "2003.03.29"

    #  or via an object
    
    my $pf = DateTime::Format::Mail->new();
    print $pf->parse_datetime(
	"Fri, 23 Nov 2001 21:57:24 -0600"
    )->ymd; # "2001-11-23"

    # Back to RFC2822 date
    
    use DateTime;
    my $dt = DateTime->new(
	year => 1979, month => 7, day => 16,
	hour => 16, minute => 45, second => 20,
	time_zone => "Australia/Sydney"
    );
    my $str = DateTime::Format::Mail->format_datetime( $dt );
    print $str; # "Mon, 16 Jul 1979 16:45:20 +1000"

    # or via an object
    $str = $pf->format_datetime( $dt );
    print $str; # "Mon, 16 Jul 1979 16:45:20 +1000"

=head1 DESCRIPTION

RFC2822 introduces a slightly different format of date than that
used by RFC822. The main correction is that the format is more
limited, and thus easier to parse.

=head1 CONSTRUCTORS

=head2 new

Creates a new DateTime::Format::Mail instance. This is generally
not required for simple operations. If you wish to use a different
parsing style from the default then you'll need to create an object.

   my $parser = DateTime::Format::Mail->new()
   my $copy = $parser->new();

If called on an existing object then it clones the object.

It has one, optional, parameter.

=over 4

=item *

C<loose> should be a true value if you want a loose parser,
else either don't specify it or give it a false value.

=back

    my $loose = DateTime::Format::Mail->new( loose => 1 );

=cut

my $set_parse_method = sub {
    my $self = shift;
    croak "Calling object method as class method!" unless ref $self;
    $self->{parser_method} = shift;
    return $self;
};

my $get_parse_method = sub {
    my $self = shift;
    my $method = ref($self) ? $self->{parser_method} : '';
    $method ||= '_parse_strict';
};

sub new
{
    my $class = shift;
    my %args = validate( @_, {
	    loose => { type => SCALAR, default => 0 },
	    year_cutoff => { type => SCALAR, default => 60 },
	});

    my $self = bless {}, ref($class)||$class;
    if (ref $class)
    {
	# If called on an object, clone
	$self->$set_parse_method( $self->$get_parse_method );
	$self->set_year_cutoff( $self->year_cutoff );
	# but as we have nothing to clone...
	# and that's it. we don't store that much info per object
    }
    $self->loose() if $args{loose};
    $self->set_year_cutoff( $args{year_cutoff} ) if $args{year_cutoff};

    $self;
}

=head2 clone

For those who prefer to explicitly clone via a method called C<clone()>.
If called as a class method it will die.

   my $clone = $original->clone();

=cut

sub clone
{
    my $self = shift;
    croak "Calling object method as class method!" unless ref $self;
    return $self->new();
}

=head1 PARSING METHODS

These methods work on either our objects or as class methods.

=head2 loose, strict

These methods set the parsing strictness.

    my $parser = DateTime::Format::Mail->new;
    $parser->loose;
    $parser->strict; # (the default)

    my $p = DateTime::Format::Mail->new->loose;

=cut

sub loose
{
    my $self = shift;
    return $self->$set_parse_method( '_parse_loose' );
}

sub strict
{
    my $self = shift;
    return $self->$set_parse_method( '_parse_strict' );
}

=head2 parse_datetime

Given an RFC2822 or 822 datetime string, return a C<DateTime> object
representing that date and time. Unparseable strings will cause
the method to die.

See the L<synopsis|/SYNOPSIS> for examples.

=cut

sub _parse_strict
{
    my $self = shift;
    my $date = shift;

    # Wed, 12 Mar 2003 13:05:00 +1100
    my @parsed = $date =~ m!
	^ \s* # optional 
	(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun) , # Day name + comma
	   # (empirically optional)
	\s*
	(\d{1,2})  # day of month
	\s*
	(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) # month
	\s*
	((?:\d\d)?\d\d) # year
	\s+
	(\d\d):(\d\d):(\d\d) # time
	(?:
	    \s+ (
		[+-] \d{4}	# standard form
		| [A-Z]+	# obsolete form (mostly ignored)
		) # time zone (optional)
	)?
	\s* $
    !x;
    croak "Invalid format for date!" unless @parsed;
    my %when;
    @when{qw( day month year hour minute second time_zone)} = @parsed;
    return \%when;
}

sub _parse_loose
{
    my $self = shift;
    my $date = shift;

    # Wed, 12 Mar 2003 13:05:00 +1100
    my @parsed = $date =~ m!
	^ \s* # optional 
	(?i: (?:Mon|Tue|Wed|Thu|Fri|Sat|Sun|[A-Z][a-z][a-z]) ,?)? # Day name + comma
	   # (empirically optional)
	\s*
	(\d{1,2})  # day of month
	[-\s]*
	(?i: (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ) # month
	[-\s]*
	((?:\d\d)?\d\d) # year
	\s+
	(\d?\d):(\d?\d) (?: :(\d?\d) )? # time
	(?:
	    \s+ "? (
		[+-] \d{4}	# standard form
		| [A-Z]+	# obsolete form (mostly ignored)
		| GMT [+-] \d+	# empirical (converted)
		| [A-Z]+\d+	# bizarre empirical (ignored)
		| [a-zA-Z/]+	# linux style (ignored)
		| [+-]{0,2} \d{3,5}	# corrupted standard form
		) "? # time zone (optional)
	)?
	    (?: \s+ \([^\)]+\) )? # (friendly tz name; empirical)
	\s* \.? $
    !x;
    croak "Invalid format for date!" unless @parsed;
    my %when;
    @when{qw( day month year hour minute second time_zone)} = @parsed;
    $when{month} = "\L\u$when{month}";
    $when{second} ||= 0;
    return \%when;
}

sub parse_datetime
{
    my $self = shift;
    croak "No date specified." unless @_;
    my $date = shift;

    # Wed, 12 Mar 2003 13:05:00 +1100
    my $method = $self->$get_parse_method();
    my %when = %{ $self->$method($date) };
    $when{time_zone} ||= '-0000';

    my %months = do { my $i = 1;
	map { $_, $i++ } qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    };
    $when{month} = $months{$when{month}} or croak "Invalid month [$when{month}].";

    $when{year} = $self->fix_year( $when{year} );
    $when{time_zone} = $self->determine_timezone( $when{time_zone} );

    my $date_time = DateTime->new( %when );

    return $date_time;
}

{
    my %timezones = qw(
	EDT -0400	EST -0500	CDT -0500	CST -0600
	MDT -0600	MST -0700	PDT -0700	PST -0800
	GMT +0000	UTC +0000
    );

    sub determine_timezone
    {
	my $self = shift;

	my $tz = shift;
	return $tz if /^[+-]\d{4}$/; # return quickly if nothing needed

	$tz =~ s/ ^ [+-] (?=[+-]) //x; # for when there are two signs

	if (exists $timezones{$tz}) {
	    $tz = $timezones{$tz};
	} elsif (substr($tz, 0, 3) eq 'GMT' and length($tz)  > 4) {
	    $tz = sprintf "%5.5s", substr($tz,3)."0000";
	} elsif ( $tz =~ /^ ([+-]?) (\d+) $/x) {
	    my $p = $1||'+';
	    $tz = sprintf "%s%04d", $p, $2;
	} else {
	    $tz = "-0000";
	}

	return $tz;
    }
}

=head2 set_year_cutoff

Two digit years are treated as valid in the loose translation and are
translated up to a 19xx or 20xx figure. By default, if the year is 
greater than '60', it's treated as being in the 20th century (19xx).
If lower, or equal, then the 21st (20xx).

set_year_cutoff() allows you to modify this behaviour by specifying
a different cutoff, where the default is 60.

The return value is the object itself.

=cut

sub set_year_cutoff
{
    my $self = shift;
    croak "Calling object method as class method!" unless ref $self;
    croak "Wrong number of arguments (should be 1) to set_year_cutoff"
	unless @_ == 1;
    my $cutoff = shift;
    $self->{year_cutoff} = $cutoff;
    return $self;
}

=head2 year_cutoff

Returns the current cutoff. Can be used as either a class or object method.

=cut

sub year_cutoff
{
    my $self = shift;
    croak "Too many arguments (should be 0) to year_cutoff" if @_;
    (ref $self and $self->{year_cutoff}) or 60;
}

=head2 fix_year

Takes a year and returns it normalized.

=cut

sub fix_year
{
    my $self = shift;
    my $year = shift;
    return $year if length $year >= 4; # Return quickly if we can

    my $cutoff = $self->year_cutoff;
    $year += $year > $cutoff ? 1900 : 2000;
    return $year;
}

=head1 FORMATTING METHODS

=head2 format_datetime

Given a C<DateTime> object, return it as an RFC2822 compliant string.

    use DateTime;
    use DateTime::Format::Mail;
    my $dt = DateTime->new(
	year => 1979, month => 7, day => 16, time_zone => 'UTC'
    );
    my $mail = DateTime::Format::Mail->format_datetime( $dt );
    print $mail, "\n"; 

    # or via an object
    my $formatter = DateTime::Format::Mail->new();
    my $rfcdate = $formatter->format_datetime( $dt );
    print $rfcdate, "\n";

=cut

sub format_datetime
{
    my $self = shift;
    croak "No DateTime object specified." unless @_;
    my $dt = $_[0]->clone;
    $dt->set( language => 'en-us' );

    my $rv = $dt->strftime( "%a, %d %b %Y %H:%M:%S %z" );
    $rv =~ s/\+0000$/-0000/;
    $rv;
}

1;

__END__

=head1 THANKS

Dave Rolsky (DROLSKY) for kickstarting the DateTime project.

Roderick A. Anderson for noting where the documentation was incomplete
in places.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

Alternatively, log them via the CPAN RT system via the web or email:

    http://perl.dellah.org/rt/dtmail
    bug-datetime-format-mail@rt.cpan.org

This makes it much easier for me to track things and thus means
your problem is less likely to be neglected.

=head1 LICENSE AND COPYRIGHT

Copyright E<copy> Iain Truskett, 2003. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> and
F<COPYING> files included with this module.

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 SEE ALSO

C<datetime@perl.org> mailing list.

L<http://datetime.perl.org/>

L<perl>, L<DateTime>

=cut
