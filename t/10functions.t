#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More qw(no_plan);
#use Test::More test => 69;
use TestData;
use Calendar::Functions qw(:form);

# Note this test is for the base functions that don't rely on other modules

# The basic functions
foreach my $test (keys %exts) { is(ext($test),$exts{$test}) }
foreach my $test (keys %monthtest) { is(moty($test),$monthtest{$test}) }
foreach my $test (keys %daytest) { is(dotw($test),$daytest{$test}) }

# date formatting
foreach my $test (@format01) {
	my $str = format_date(@{$test->{array}});
	is($str,$test->{result});
}

foreach my $test (@format02) {
	my $str = reformat_date(@{$test->{array}});
#	is($str,$test->{result});
}
