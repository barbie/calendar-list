#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More qw|no_plan|;
use TestData;
use Calendar::Functions qw(:all :test);

###########################################################################
# name: 13timelocal.t
# desc: Functionality check with Time::Local
###########################################################################

# switch off DateTime and Date::ICal, if loaded
_caltest(0,0);

foreach my $test (@datetest) {

	# before the epoch, skipping
	next	if(!$on_unix && $test->{tl} == 2);

	# should have real values
	if($test->{tl}) {
		my $date = encode_date(@{$test->{array}});
		my @date = decode_date($date);
		is_deeply(\@date,$test->{array});

	# expecting undef values
	} else {
		my $date = encode_date(@{$test->{array}});
		is($date,undef);
		is(decode_date(undef),undef);
	}
}

foreach my $test (@diffs) {
	# outside the epoch range, skipping
	next	if(!$on_unix && $test->{tl} == 2);
	next	if($test->{tl} == 0);

	my $date1 = encode_date(@{$test->{from}});
	my $date2 = encode_date(@{$test->{to}});

	is(compare_dates($date1,$date2),$test->{compare},
            sprintf ".. [%02d/%02d/%04d] => [%02d/%02d/%04d]",
                $test->{from}[0],$test->{from}[1],$test->{from}[2],
                $test->{to}[0],$test->{to}[1],$test->{to}[2]);
}

foreach my $test (@monthlists) {
	# cant do dates before the epoch
	next	if(!$on_unix && $test->{array}->[1] < 1970);
}


# fail_range
is(fail_range(1899),1);
is(fail_range(1965),0);
is(fail_range(1999),0);
is(fail_range(2000),0);
is(fail_range(2038),1);

