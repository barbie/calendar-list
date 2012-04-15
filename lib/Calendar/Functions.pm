package Calendar::Functions;

use 5.006;
use strict;
use warnings;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '0.11';

### CHANGES #########################################################
#	0.01	30/04/2003	Initial Release
#	0.02	08/06/2003	fix to diff_dates and undef returns
#	0.03	09/06/2003	Time::Local offset fix
#	0.04	11/06/2003	Time::Local fix now uses timegm()
#	0.05	25/06/2003	More Date Formats
#	0.06	07/08/2003	Another fix to cope with Time::Local
#                       dotw problems
#                       POD updates 
#                       More Date Formats
#	0.07	08/10/2003	POD updates
#	0.08	07/11/2003	delta_days changed after DateTime 0.16 :(
#	0.09	10/11/2003	added Time::Piece for the EPOCH date format
#	0.10	16/12/2003	Fixed the VERSION test if DateTime not loaded
#	0.11	22/04/2004	All Time::Local dates based from 12 midday
#####################################################################

#----------------------------------------------------------------------------

=head1 NAME

Calendar::Functions - A module containing functions for dates and calendars.

=head1 SYNOPSIS

  use Calendar::Functions qw();
  $ext = ext($day);
  $moty = moty($monthname);
  $monthname = moty($moty);
  $dotw = dotw($dayname);
  $dayname = dotw($dotw);

  use Calendar::Functions qw(:dates);
  my $dateobj = encode_date($day,$month,$year);
  ($day,$month,$year) = decode_date($dateobj);
  $duration = diff_dates($dateobj1, $dateobj2);
  $hash = month_list($month,$year);
  $days = month_days($month,$year);

  use Calendar::Functions qw(:form);
  $str = format_date( $fmt, $day, $month, $year, $dotw);
  $str = reformat_date( $date, $fmt1, $fmt2 );

  use Calendar::Functions qw(:all);
  $dotw = dotw3($day,$month,$year);
  $dotw = dotw3($dateobj);
  fail_range($year);

=head1 DESCRIPTION

The module is intended to provide numerous support functions for other
date and/or calendar functions

=head1 EXPORT

  ext, moty, dotw

  dates:    encode_date, decode_date, diff_dates,
            month_list, month_days

  form:     format_date, reformat_date

  all:      encode_date, decode_date, diff_dates,
            month_list, month_days,
            format_date, reformat_date,
            ext, moty, dotw,
            dotw3, fail_range

=cut

#----------------------------------------------------------------------------

#############################################################################
#Export Settings															#
#############################################################################

require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS = (
	'basic' => [ qw( ext moty dotw ) ],
	'dates' => [ qw( encode_date decode_date diff_dates month_list
					month_days ext moty dotw ) ],
	'form'  => [ qw( format_date reformat_date ext moty dotw ) ],
	'all'   => [ qw( dotw3 fail_range
					encode_date decode_date diff_dates month_list
					month_days format_date reformat_date ext moty dotw ) ],
	'test'	=> [ qw( _caltest ) ],
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, @{ $EXPORT_TAGS{'test'} } );
@EXPORT = ( @{ $EXPORT_TAGS{'basic'} } );

#############################################################################
#Library Modules															#
#############################################################################

use Time::Local;
eval "use Date::ICal";
my $di = ! $@;
eval "use DateTime";
my $dt = ($@ ? 0 : (defined $DateTime::VERSION && $DateTime::VERSION < 0.17 ? 1 : 0));
eval "use Time::Piece";
my $tp = ! $@;

if($tp) {
	require Time::Piece;
}


#############################################################################
#Variables
#############################################################################

# prime our print out names
my @months	= qw(	NULL January February March April May June July
                    August September October November December );
my @dotw	= qw(	Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

my $MinYear		= 1902;
my $MaxYear		= 2037;
my $EpoYear		= 1970;

#----------------------------------------------------------------------------

#############################################################################
#Interface Functions														#
#############################################################################

=head1 METHODS

=over 4

=item encode_date( DD, MM, YYYY )

Translates the given date values into a date object or number.

=cut

# name:	encode_date
# args: day,month,year .... standard numerical day/month/year values
# retv: date object or number
# desc:	Translates the given date values into a date object or number.

sub encode_date {
	my ($day,$mon,$year) = @_;
	my $this = undef;

	if($dt) {		# DateTime.pm loaded
    	$this = DateTime->new(day=>$day,month=>$mon,year=>$year);
	} elsif($di) {	# Date::ICal loaded
		$this = new Date::ICal(day=>$day,month=>$mon,year=>$year,offset=>0);
	} else {		# using Time::Local
		return	if(fail_range($year));
		$this = timegm(0,0,12,$day,$mon-1,$year);
	}

	return $this
}

=item decode_date( date )

Translates the given date values into a date object or number.

=cut

# name:	decode_date
# args: date1 .... date object or number
# retv: the standard numerical day/month/year values
# desc:	Translates the date object or number into date values.

sub decode_date {
	my $date = shift;
	my ($day,$month,$year) = ();
	return	unless($date);

	if($dt || $di) {		# DateTime.pm or Date::ICal loaded
		($day,$month,$year) = ($date->day,$date->month,$date->year);
	} else {		# using Time::Local
		($day,$month,$year) = (localtime($date))[3..5];
		(undef,undef,undef,$day,$month,$year) = (localtime($date));
		$month++;
		$year+=1900;
	}

	return $day,$month,$year;
}

=item diff_dates( date, date )

Using the appropriate module finds the duration between the two dates.

=cut

# name:	diff_dates
# args: date1 .... date object or string
#		date2 .... date object or string
# retv: the duration betwwen the two dates
# desc:	Using the loaded module finds the duration between the two dates.

sub diff_dates {
	my ($d1,$d2) = @_;
	my $duration;
	return	unless($d1 && $d2);

	my $diff = $d1 - $d2;

	if($dt)		{ $duration = $diff->delta_days; }
	elsif($di)	{ $duration = $diff->as_days; }
	else		{ $duration = $diff ? int($diff/86400) : 0; }

	return $duration;
}

=item month_list( month, year )

Given a numerical month (1-12) and year, a hash of days for that month are
returned, with each day being the key and the day of the week being the value.

=cut

# name:	month_list
# args: month .... numerical (1-12) month representation
#		year ..... numerical year
# retv: a hash of days
# desc:	Returns the days for the given month, with day of the week.

sub month_list {
	my ($mon,$year) = @_;
	return	if(fail_range($year));

	my $dotw = dotw3(1,$mon,$year);
	my $mdays = month_days($mon,$year);
	my %hash = ();

	foreach my $day (1..$mdays) {
		$hash{$day} = $dotw;
		$dotw++;
		$dotw = $dotw % 7;
	}

	return \%hash;
}

=item dotw3( day, month, year | dateobj )

Given a numerical representation of a date (day, month (1-12) and year),
or a date object (as provided by encode_date), the value for day of the
week is calculated and returned.

=cut

# name:	dotw3
# args: day ....... numerical day
#		month ..... numerical (1-12) month representation
#		year ...... numerical year
#		dateobj ... if using encode_date [above 3 not required]
# retv: numerical day of the week.
# desc:	Calclulates the day of the week value from the given date.

sub dotw3 {
	my $dotw;
	my $date = $_[0];

	if($dt) {
		$date = new DateTime(day => $_[0],month => $_[1],year => $_[2])
			if(@_ > 1);
		$dotw = $date->day_of_week;
		$dotw = $dotw % 7;		# DateTime uses 7 as Sunday
	} elsif($di) {
		$date = new Date::ICal(day=>$_[0],month=>$_[1],year=>$_[2],offset=>0)
			if(@_ > 1);
		$dotw = $date->day_of_week;
	} else {
		return	if(fail_range($_[2]));
		# pick the middle of the day to avoid Daylight Saving offsets
		$date = timegm 0, 0, 12, $_[0], $_[1] -1, $_[2]
			if(@_ > 1);
		$dotw = (localtime $date)[6];
	}

	return $dotw;
}

=item month_days( month, year )

For any given month (1-12) and year, will return the number of days in that
month. Note that this relies on other modules to give an accurate leap year
calculation.

=cut

# name:	month_days
# args: month .... numerical (1-12) month representation
#		year ..... numerical year
# retv: number of days for the month
# desc:	Given a specific month and year, calculates the number of days.

sub month_days {
	my ($date1,$date2);

	my ($month1,$year1) = @_;
	my ($month2,$year2) = @_;
	$month2++;
	if($month2>12)	{$year2++;$month2=1}

	if($dt) {
		$date1 = new DateTime(day => 1,month => $month1,year => $year1);
		$date2 = new DateTime(day => 1,month => $month2,year => $year2);
	} elsif($di) {
		$date1 = new Date::ICal(day=>1,month=>$month1,year=>$year1,offset=>0);
		$date2 = new Date::ICal(day=>1,month=>$month2,year=>$year2,offset=>0);
	} else {
		return	if(fail_range($year1));
		$date1 = timegm 0, 0, 12, 1, $month1-1, $year1;
		$date2 = timegm 0, 0, 12, 1, $month2-1, $year2;
	}

	return diff_dates($date2,$date1);
}

=item format_date( fmt, day, mon, year [, dotw])

transposes the standard date values into a formatted string.

=cut

# name:	format_date
# args: fmt ............. format string
#		day/mon/year .... standard date values
#		dotw ............ day of the week number (optional)
# retv: newly formatted date
# desc:	Transposes the format string and date values into a correctly
#		formatted date string.

sub format_date {
	my ($fmt,$day,$mon,$year,$dotw) = @_;
	return	unless($day && $mon && $year);

	# create date mini strings
	my $fday	= sprintf "%02d", $day;
	my $fmon	= sprintf "%02d", $mon;
	my $fyear	= sprintf "%04d", $year;
	my $fmonth	= sprintf "%s",   $months[$mon];
	my $fdotw	= sprintf "%s",   (defined $dotw ? $dotw[$dotw] : '');
	my $fddext	= sprintf "%d%s", $day, ext($day);
	my $amonth	= substr($fmonth,0,3);
	my $adotw	= substr($fdotw,0,3);
	my $epoch	= -1;	# an arbitory number

	# epoch only supports the same dates in the 32-bit range
	if($tp && $fmt =~ /\bEPOCH\b/ && $year >= $EpoYear && $year <= $MaxYear) {
		my $date = timegm 0, 0, 12, $day, $mon -1, $year;
		my $t = Time::Piece::gmtime($date);
		$epoch = $t->epoch	if($t);
	}

	# transpose format string into a date string
	$fmt =~ s/\bDMY\b/$fday-$fmon-$fyear/i;
	$fmt =~ s/\bMDY\b/$fmon-$fday-$fyear/i;
	$fmt =~ s/\bYMD\b/$fyear-$fmon-$fday/i;
	$fmt =~ s/\bMABV\b/$amonth/i;
	$fmt =~ s/\bDABV\b/$adotw/i;
	$fmt =~ s/\bMONTH\b/$fmonth/i;
	$fmt =~ s/\bDAY\b/$fdotw/i;
	$fmt =~ s/\bDDEXT\b/$fddext/i;
	$fmt =~ s/\bYYYY\b/$fyear/i;
	$fmt =~ s/\bMM\b/$fmon/i;
	$fmt =~ s/\bDD\b/$fday/i;
	$fmt =~ s/\bEPOCH\b/$epoch/i;

	return $fmt;
}

=item reformat_date( date, form1, form1 )

transposes the standard date values into a formatted string.

=cut

# name:	reformat_date
# args: date ..... date string
#		form1 .... format string
#		form2 .... format string
# retv: converted date string
# desc:	Transposes the date from one format to another.

sub reformat_date {
	my ($date,$form1,$form2) = @_;
	my ($year,$mon,$day,$dotw) = ();

	while($form1) {
		if($form1 =~ /^YYYY/) {
			($year) = ($date =~ /^(\d{4})/);
			$form1 =~ s/^....//;
			$date =~ s/^....//;

		} elsif($form1 =~ /^MONTH/) {
			my ($month) = ($date =~ /^(\w+)/);
			$mon = moty($month);
			$form1 =~ s/^\w+//;
			$date =~ s/^\w+//;

		} elsif($form1 =~ /^MM/) {
			($mon) = ($date =~ /^(\d{2})/);
			$form1 =~ s/^..//;
			$date =~ s/^..//;

		} elsif($form1 =~ /^DDEXT/) {
			($day) = ($date =~ /^(\d{2})/);
			$form1 =~ s/^....//;
			$date =~ s/^....//;

		} elsif($form1 =~ /^DD/) {
			($day) = ($date =~ /^(\d{2})/);
			$form1 =~ s/^..//;
			$date =~ s/^..//;

		} elsif($form1 =~ /^DAY/) {
			my ($wday) = ($date =~ /^(\w+)/);
			$dotw = dotw($wday);
			$form1 =~ s/^\w+//;
			$date =~ s/^\w+//;

		} else {
			$form1 =~ s/^.//;
			$date =~ s/^.//;
		}
	}

	# return original date if badly formed date
	return $_[0]	unless($day && $mon && $year);

	# get the day of the week, if we need it
	$dotw = dotw($day,$mon,$year)	if($form2 =~ /DAY/ && !$dotw);

	# rebuild date into second format
	return format_date($form2,$day,$mon,$year);
}

=item ext( day )

Returns the extension associated with the given day value.

=cut

# name:	ext
# args: day .... day value
# retv: day value extension
# desc:	Returns the extension associated with the given day value.

sub ext {
	return 'st'	if($_[0] == 1 ||$_[0] == 21 || $_[0] == 31);
	return 'nd'	if($_[0] == 2 ||$_[0] == 22);
	return 'rd'	if($_[0] == 3 ||$_[0] == 23);
	return 'th';
}

=item dotw( day | dayname )

Returns the day number (0..6) if passed the day name, or the day name if
passed a numeric.

=cut

sub dotw {
	return $dotw[$_[0]]	if($_[0] =~ /\d/);

	foreach my $inx (0..6) {
		return $inx	if($_[0] =~ /$dotw[$inx]/i);
	}
}

=item moty( month | monthname )

Returns the month number (1..12) if passed the month name, or the month
name if passed a numeric.

=cut

sub moty {
	return $months[$_[0]]	if($_[0] =~ /\d/);

	foreach my $inx (1..12) {
		return $inx	if($_[0] =~ /$months[$inx]/i);
	}
}

=item fail_range( year )

Returns true or false based on whether the date given will break the
basic date range, 01-01-1902 to 31-12-2037.

=cut

sub fail_range {
	return 1	unless($_[0]);
	return 0	if($dt || $di);
	return 1	if($_[0] < $MinYear || $_[0] > $MaxYear);
	return 0;
}

sub _caltest {
	$dt = $_[0]	if($dt);
	$di = $_[1]	if($di);
}

1;

__END__

#----------------------------------------------------------------------------

=back

=head1 DATE FORMATS

=over 4

=item Parameters

The date formatting parameters passed to the two formatting functions can
take many different formats. A formatting string can contain several key
strings, which will be replaced with date components. The following are
key strings which are currently supported:

  DD
  MM
  YYYY
  DAY
  MONTH
  DDEXT
  DMY
  MDY
  YMD
  MABV
  DABV

The first three are tranlated into the numerical day/month/year strings.
The DAY format is translated into the day of the week name, and MONTH
is the month name. DDEXT is the day with the appropriate suffix, eg 1st,
22nd or 13th. DMY, MDY and YMD default to '13-09-1965' (DMY) style strings.
MABV and DABV provide 3 letter abbreviations of MONTH and DAY respectively.

=back

=head1 DATE MODULES

Internal to this module is some date comparison code. As a consequence this
requires some date modules that can handle a wide range of dates. There are
three modules which are tested for you, these are, in order of preference,
DateTime, Date::ICal and Time::Local.

Each module has the ability to handle dates, although only Time::Local exists
in the core release of Perl. Unfortunately Time::Local is limited by the
Operating System. On a 32bit machine this limit means dates before 1st January
1902 and after 31st December 2037 will not be represented. If this date range
is well within your scope, then you can safely allow the module to use
Time::Local. However, should you require a date range that exceedes this
range, then it is recommended that you install one of the two other modules.

=head1 ERROR HANDLING

In the event that Time::Local is being used and dates that exceed the range
of 1st January 1902 to 31st December 2037 are passed, an undef is returned.

=head1 SEE ALSO

  L<perl>
  L<Date::ICal>
  L<DateTime>
  L<Time::Local>
  L<Time::Piece>

The Calendar FAQ at http://www.tondering.dk/claus/calendar.html

=head1 BUGS & ENHANCEMENTS

There appears to be a problem with Time::Local not returning the correct
number of seconds for localtime to distinguish the correct day of the week.
I suspect, even though timegm() is being used, offsets are getting set.
Now using 12:00pm as the time of day to try and avoid offset strangeness.

DateTime after 0.16 implements delta_days differently from previous versions.
Until I have time to rewrite this module to be compatible with versions after
0.16, I won't be supporting DateTime 0.17 or greater.

If you think you've found a bug, send details and
patches (if you have one) to E<lt>modules@missbarbell.co.ukE<gt>.

If you have a suggestion for an enhancement, though I can't promise to
implement it, please send details to E<lt>modules@missbarbell.co.ukE<gt>.

=head1 AUTHOR

  Barbie, E<lt>barbie@cpan.orgE<gt>
  for Miss Barbell Productions L<http://www.missbarbell.co.uk>.

=head1 THANKS TO

Dave Cross, E<lt>dave@dave.orgE<gt> for creating Calendar::Simple, the
newbie poster on a technical message board who inspired me to write the
original wrapper code and Richard Clamp E<lt>richardc@unixbeard.co.ukE<gt>
for testing the beta versions.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2003 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=cut
