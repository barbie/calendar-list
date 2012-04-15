package Calendar::List;

use 5.006;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.08';

### CHANGES #########################################################
#   0.01   30/04/2003   Initial Release
#   0.02   08/06/2003   update for undef returns
#   0.03   09/06/2003   Time::Local offset fix
#   0.04   10/06/2003   SELECTED bug fix
#   0.05   25/06/2003   Tie::IxHash for preserving order
#                       use of => to identify a hash
#   0.06   07/08/2003	Fixed POD links
#   0.07   08/10/2003	META.yml added
#                   	POD updates
#	0.08   07/11/2003	delta_days changed after DateTime 0.16 :(
#####################################################################

#----------------------------------------------------------------------------

=head1 NAME

Calendar::List - A module for creating date lists

=head1 SYNOPSIS

  use Calendar::List;

  # basic usage
  my %hash = calendar_list('DD-MM-YYYY' => 'DD MONTH, YYYY' );
  my @list = calendar_list('MM-DD-YYYY');
  my $html = calendar_selectbox('DD-MM-YYYY' => 'DAY DDEXT MONTH, YYYY');

  # using the hash
  my %hash01 = (
  	'options'	=> 10,
  	'exclude'	=> { 'weekend' => 1 },
  	'start'		=> '01-05-2003',
  );

  my %hash02 = (
  	'exclude'	=> { 'monday' => 1,
                     'tuesday' => 1,
                     'wednesday' => 1 },
  	'start'		=> '01-05-2003',
  	'end'		=> '10-05-2003',
  	'name'		=> 'MyDates',
  	'selected'	=> '04-05-2003',
  );

  my %hash = calendar_list('DD-MM-YYYY' => 'DDEXT MONTH YEAR', \%hash01);
  my @list = calendar_list('DD-MM-YYYY', \%hash01);
  my $html = calendar_selectbox('DD-MM-YYYY',\%hash02);

=head1 DESCRIPTION

The module is intended to be used to return a simple list, hash or scalar
of calendar dates. This is achieved by two functions, calendar_list and
calendar_selectbox. The former allows a return of a list of dates and a
hash of dates, whereas the later returns a scalar containing a HTML code
snippet for use as a HTML Form field select box.

=head1 EXPORT

  calendar_list,
  calendar_selectbox

=cut

#----------------------------------------------------------------------------

#############################################################################
#Export Settings															#
#############################################################################

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	calendar_list
	calendar_selectbox
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

#############################################################################
#Library Modules															#
#############################################################################

use Calendar::Functions qw(:all);
use Clone qw(clone);
use Tie::IxHash;

#############################################################################
#Variables
#############################################################################

# prime our print out names
my @dotw = qw(	Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

# THE DEFAULTS
my $Format		= 'DD-MM-YYYY';
my @order		= qw( day month year );

my %Defaults = (
	maxcount => 30,
	selectname => 'calendar',
	selected => [],
	startdate => undef,
	enddate => undef,
	start => [1,1,1970],
	end => [31,12,2037],
	exclude => [ 0,0,0,0,0,0,0 ],
);

my (%Settings);

#----------------------------------------------------------------------------

#############################################################################
#Interface Functions														#
#############################################################################

=head1 METHODS

=over 4

=item calendar_list([DATEFORMAT] [,DATEFORMAT] [,OPTIONSHASH])

Returns a list in an array context or a hash reference in any other context.
All paramters are optional, one or two date formats can be specified for the
date formats returned in the list/hash. A hash of user defined settings can
also be passed into the function. See below for further details.

Note that a second date format is not required when returning a list. A
single date format when returning a hash reference, will be used in both
key and value portions.

=cut

sub calendar_list {
	my $wantarray = (@_ < 2 || ref($_[1]) eq 'HASH') ? 1 : 0;
	my ($fmt1,$fmt2,$hash) = _thelist(@_);
	return _callist($fmt1,$fmt2,$hash,$wantarray);
}

=item calendar_selectbox([DATEFORMAT] [,DATEFORMAT] [,OPTIONSHASH])

Returns a scalar containing a HTML string. The HTML snippet consists of an
HTML form field select box. All paramters are optional, one or two date
formats can be specified for the date formats returned in the value
attribute and data portion. A hash of user defined settings can
also be passed into the function. See below for further details.

Note that a single date format will be used in both value attribute and
data portions.

=cut

sub calendar_selectbox {
	my ($fmt1,$fmt2,$hash) = _thelist(@_);
	return _calselect($fmt1,$fmt2,$hash);
}

#############################################################################
#Internal Functions															#
#############################################################################

# name:	_thelist
# args: format string 1 .... optional
# 		format string 2 .... optional
# 		settings hash ...... optional
# retv: undef if invalid settings, otherwise a hash of dates, keyed by
#		an incremental counter.
# desc:	The heart of the engine. Arranges the parameters passed to the
#		the interface function, calls for the settings to be decided,
#		them creates the main hash table of dates.
#		Stops when either the end date is reached, or the maximum number
#		of entries have been found.

sub _thelist {
	my $format1 = shift	unless(ref($_[0]) eq 'HASH');
	my $format2 = shift	unless(ref($_[0]) eq 'HASH');
	my $usrhash = shift	if(ref($_[0]) eq 'HASH');
	$format1 = $Format	unless($format1);
	$format2 = $format1	unless($format2);

	return undef	if _setargs($usrhash,$format1);

	my ($nowday,$nowmon,$nowyear) = decode_date($Settings{startdate});
	
	my $optcount = 0;	# our option counter
	my %DateHash = ();
	tie(%DateHash, 'Tie::IxHash');

	while($optcount < $Settings{maxcount}) {
		# get the calendar for one month
		my $thismonth = month_list($nowmon,$nowyear);

		foreach my $day (sort {$a <=> $b} keys %$thismonth) {
			# end if we have enough options
			last	if($optcount > $Settings{maxcount});

			# ignore days prior to start date
			next	unless($optcount || $day >= $nowday);

			# ignore days we're not interested in
			my $dotw = $thismonth->{$day};
			next	if($Settings{exclude}->[$dotw]);

			# stop if reached end date
			if(_nomore($day,$nowmon,$nowyear)) {
				$Settings{maxcount}=0;
				last;
			}

			# store date
			$DateHash{$optcount} = [$day,$nowmon,$nowyear,$dotw];
			$optcount++;
		}

		# increment to next month (and year if applicable)
		$nowmon++;
		if($nowmon > 12) { $nowmon = 1; $nowyear++; }
	}

	return $format1,$format2,\%DateHash;
}

# name:	_callist
# args: format string 1 .... optional
# 		format string 2 .... optional
# 		settings hash ...... optional
# retv: undef if invalid settings, otherwise an array if zero or one
#		date format provided, in ascending order, or a hash if two
#		date formats.
# desc:	The cream on top. Takes the hash provided by _thelist and uses
#		it to create a formatted array or hash.

sub _callist {
	my ($fmt1,$fmt2,$hash,$wantarray) = @_;
	return undef	unless($hash);

	my (@returns,%returns) = ();
	tie(%returns, 'Tie::IxHash');

	foreach my $key (sort {$a <=> $b} keys %$hash) {
		my $date1 = format_date($fmt1,@{$hash->{$key}});
		if($wantarray) {
			push @returns, $date1;
		} else {
			my $date2 = format_date($fmt2,@{$hash->{$key}});
			$returns{$date1} = $date2;
		}
	}

#print STDERR "\n\n===[".scalar(each %returns)."]===\n\n";
	return @returns	if($wantarray);
#use Data::Dumper qw(DumperX);
#open  FH, ">>trace.log" or die "cannot open file:$!\n";
#print FH "STORED:\n".DumperX(\%returns)."\n";
#close FH;
#exit;
#	while(my (@temp) = each %returns) {
#		push @returns, @temp;
#	}
		
#	map { push @returns, $_->[0],$_->[1] } each %returns;
#	return @returns;
	return %returns;
}


# name:	_calselect
# args: format string 1 .... optional
# 		format string 2 .... optional
# 		settings hash ...... optional
# retv: undef if invalid settings, otherwise a hash of dates, keyed by
#		an incremental counter.
# desc:	The cream on top. Takes the hash provided by _thelist and uses
#		it to create a HTML select box form field, making use of any
#		user defined settings.

sub _calselect {
	my ($fmt1,$fmt2,$hash) = @_;
	return undef	unless($hash);

	# open SELECT tag
	my $select = "<select name='$Settings{selectname}'>\n";

	# add an OPTION elements
	foreach my $key (sort {$a <=> $b} keys %$hash) {
		my $selected = 0;

		# check whether this option has been selected
		$selected = 1
			if(	@{$Settings{selected}} &&
				$hash->{$key}->[0] == $Settings{selected}->[0] &&
				$hash->{$key}->[1] == $Settings{selected}->[1] &&
				$hash->{$key}->[2] == $Settings{selected}->[2]);

		# format date strings
		my $date1 = format_date($fmt1,@{$hash->{$key}});
		my $date2 = format_date($fmt2,@{$hash->{$key}});

		# create the option
		$select .= "<option value='$date1'";
		$select .= ' SELECTED'	if($selected);
		$select .= ">$date2</option>\n";
	}

	# close SELECT tag
	$select .= "</select>\n";
	return $select;
}

# name:	_setargs
# args: settings hash ...... optional
# retv: 1 to indicate any bad settings, otherwise undef.
# desc:	Sets defaults, then deciphers user defined settings.

sub _setargs {
	my $hash = shift;
	my $format1 = shift;

	# set the current date
	my @now = localtime();
	my @today = ( $now[3], $now[4]+1, $now[5]+1900 );

	%Settings = ();
	%Settings = %{ clone(\%Defaults) };
	$Settings{startdate} = encode_date(@today);

	# if no user hash table provided, lets go
	return	unless($hash);


	# store excluded days
	if($hash->{'exclude'}) {
		my $hash2 = $hash->{'exclude'};
		foreach my $inx (0..6) {
			my $key = lc($dotw[$inx]);
			$Settings{exclude}->[$inx] = 1	if $hash2->{"$key"};
		}

		# check for weekend setting
		if($hash2->{'weekend'}) {
			$Settings{exclude}->[0] = 1;
			$Settings{exclude}->[6] = 1;
		}

		# check for weekday setting
		if($hash2->{'weekday'}) {
			foreach my $inx (1..5) { $Settings{exclude}->[$inx] = 1; }
		}

		# ensure we aren't wasting time
		my $count = 0;
		foreach my $inx (0..6) { $count++	if($Settings{exclude}->[$inx]) }
		die "all days ignore\n"	if($count == 7);
	}


	# store selected date
	if($hash->{'select'}) {
		my @dates = ($hash->{'select'} =~ /(\d+)/g);
		$Settings{selected} = \@dates;
	}


	# store start date
	if($hash->{'start'}) {
		my @dates = ($hash->{'start'} =~ /(\d+)/g);
		$Settings{startdate} = encode_date(@dates);
	}


	# store end date
	if($hash->{'end'}) {
		$Settings{maxcount}=9999;
		my @dates = ($hash->{'end'} =~ /(\d+)/g);
		$Settings{enddate} = encode_date(@dates);

		# check whether we have a bad start/end dates
		return 1	if(diff_dates($Settings{enddate},$Settings{startdate}) < 0);
	}


	# store user defined values
	$Settings{maxcount}		= $hash->{'options'}	if($hash->{'options'});
	$Settings{selectname}	= $hash->{'name'}		if($hash->{'name'});

	return 0;
}

# name:	_nomore
# args: day,month,year .... standard numerical day/month/year values
# retv: 1 if end date reached, otherwise 0
# desc:	Checks whether the given dates has gone passed the end date.

sub _nomore {
	return 0	unless($Settings{enddate});

	my $NowDate = encode_date($_[0], $_[1], $_[2]);
	my $duration = diff_dates($Settings{enddate},$NowDate);
	return 0	unless($duration < 0);

	return 1;
}


1;

__END__

#----------------------------------------------------------------------------

=back

=head1 DATE FORMATS

=over 4

=item Parameters

The date formatted parameters passed to the two exported functions can take
many different formats. If a single array is required then only one date
format string is required.

Each format string can have the following components:

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

=item Options

In the optional hash that can be passed to either function, it should be
noted that all 3 date formatted strings MUST be in the format 'DD-MM-YYYY'.

=back

=head1 OPTIONAL SETTINGS

An optional hash of settings can be passed as the last parameter to each
external function, which consists of user defined limitations. Each
setting will effect the contents of the returned lists. This may lead to
conflicts, which will result in an undefined reference being returned.

=over 4

=item options

The maximum number of items to be returned in the list.

=item name

Used by calendar_selectbox. Names the select box form field.

=item select

Used by calendar_selectbox. Predefines the selected entry in a select box.

=item exclude

The exclude key allows the user to defined which days they wish to exclude
from the returned list. This can either consist of individual days or the
added flexibility of 'weekend' and 'weekday' to exclude a traditional
group of days. Full list is:

  weekday
  monday
  tuesday
  wednesday
  thursday
  friday
  weekend
  saturday
  sunday

=item start

References a start date in the format DD-MM-YYYY.

=item end

References an end date in the format DD-MM-YYYY. Note that if an end
date has been set alongside a setting for the maximum number of options,
the limit will be defined by which one is reached first.

=back

=head1 DATE MODULES

Internal to the Calendar::Functions module, there is some date comparison
code. As a consequence, this requires some date modules that can handle a
wide range of dates. There are three modules which are tested for you,
these are, in order of preference, Date::ICal, DateTime and Time::Local.

Each module has the ability to handle dates, although only Time::Local exists
in the core release of Perl. Unfortunately Time::Local is limited by the
Operating System. On a 32bit machine this limit means dates before the epoch
(1st January, 1970) and after the rollover (January 2038) will not be
represented. If this date range is well within your scope, then you can safely
allow the module to use Time::Local. However, should you require a date range
that exceedes this range, then it is recommend that you install one of the two
other modules.

=head1 SEE ALSO

  L<perl>
  L<Calendar::Functions>
  L<Clone>

=head1 BUGS & ENHANCEMENTS

No bugs reported as yet.

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

