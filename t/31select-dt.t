#!/usr/bin/perl -w
use strict;
use lib 't';

use Test::More;
use TestData;
use Calendar::List;

# check we can load the module
eval "use DateTime";
if($@) {
	plan skip_all => "DateTime not installed.";
}

plan tests => 13;

###########################################################################
# name: 31select-dt.t
# desc: Dates for calendar_selectbox function
###########################################################################

# -------------------------------------------------------------------------
# The tests

# 1. testing the returned string
foreach my $test (1..13) {
	my @args = ();
	push @args, $tests{$test}->{f1}		if $tests{$test}->{f1};
	push @args, $tests{$test}->{f2}		if $tests{$test}->{f2};
	push @args, $tests{$test}->{hash}	if $tests{$test}->{hash};
	my $str = calendar_selectbox(@args);

	if($tests{$test}->{hash}) {
		is($str,$expected03{$test});
	} else {
		is(length $str,length $expected03{$test});
	}
}

