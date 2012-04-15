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
		is(dotw3(@{$test->{array}}),$test->{dotw});

		my $date = encode_date(@{$test->{array}});
		my @date = decode_date($date);
		is_deeply(\@date,$test->{array});

	# expecting undef values
	} else {
		is(dotw3(@{$test->{array}}),undef);

		my $date = encode_date(@{$test->{array}});
		is($date,undef);
		is(decode_date(undef),undef);
	}
}

foreach my $test (@diffs) {
	# before the epoch, skipping
	next	if(!$on_unix && $test->{tl} == 2);

	my $date1 = encode_date(@{$test->{from}});
	my $date2 = encode_date(@{$test->{to}});

	is(diff_dates($date2,$date1),($test->{tl} ? $test->{duration} : undef));
}

foreach my $test (@monthlists) {
	# cant do dates before the epoch
	next	if(!$on_unix && $test->{array}->[1] < 1970);

	my $hash = month_list(@{$test->{array}});
	is_deeply($hash,$test->{hash});
	my $days = month_days(@{$test->{array}});
	is($days,scalar(keys %$hash));
}


# fail_range
is(fail_range(1899),1);
is(fail_range(1965),0);
is(fail_range(1999),0);
is(fail_range(2000),0);
is(fail_range(2038),1);

