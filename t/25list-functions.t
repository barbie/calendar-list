#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More qw(no_plan);
#use Test::More test => 69;
use TestData;
use Calendar::List;

# Note this test is for the base functions that don't rely on other modules

# arg validation
foreach my $inx (keys %setargs) {
	my $str = Calendar::List::_setargs($setargs{$inx}->{hash});
	is($str,$setargs{$inx}->{result},".. matches result for $inx index");
}
