#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More;
use TestData;
use Calendar::Functions qw(:all);

# check we can load the module
eval "use DateTime";
if($@) {
	plan skip_all => "DateTime not installed.";
}

DateTime->import;
plan qw|no_plan|;

###########################################################################
# name: 11datetime.t
# desc: Functionality check with DateTime
###########################################################################

foreach my $test (@datetest) {
	my $date = encode_date(@{$test->{array}});
	my @date = decode_date($date);
	is_deeply(\@date,$test->{array});
}

foreach my $test (@diffs) {
	my $date1 = encode_date(@{$test->{from}});
	my $date2 = encode_date(@{$test->{to}});
	is(compare_dates($date1,$date2),$test->{compare},
            sprintf ".. [%02d/%02d/%04d] => [%02d/%02d/%04d]",
                $test->{from}[0],$test->{from}[1],$test->{from}[2],
                $test->{to}[0],$test->{to}[1],$test->{to}[2]);
}

# fail_range
is(fail_range(1899),0);
is(fail_range(1965),0);
is(fail_range(1999),0);
is(fail_range(2000),0);
is(fail_range(2038),0);
