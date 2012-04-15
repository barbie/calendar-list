#!/usr/bin/perl -w
use strict;
use lib 't';

use Test::More;
use Init;
use Calendar::List;

# check we can load the module
eval "use Date::ICal";
if($@) { plan skip_all => "Date::ICal not installed."; exit; }
plan tests => 13;

# switch off DateTime if loaded
use Calendar::Functions qw(:test);
_caltest(0,1);

###########################################################################
# name: 22list-di.t
# desc: Dates for calendar_list function using Date::ICal
###########################################################################

# -------------------------------------------------------------------------
# The tests

# 1. testing the returned array
foreach my $test (1..4,9,10,11,13) {
	my @args = ();
	push @args, $tests{$test}->{f1}		if $tests{$test}->{f1};
	push @args, $tests{$test}->{f2}		if $tests{$test}->{f2};
	push @args, $tests{$test}->{hash}	if $tests{$test}->{hash};
	my @array = calendar_list(@args);

	if($tests{$test}->{hash}) {
		is(eq_array(\@array,$expected02{$test}),1);
	} else {
		is(scalar(@array),scalar(@{$expected02{$test}}));
	}
}

# 2. testing the returned hash
foreach my $test (5..8,12) {
	my @args = ();
	push @args, $tests{$test}->{f1}		if $tests{$test}->{f1};
	push @args, $tests{$test}->{f2}		if $tests{$test}->{f2};
	push @args, $tests{$test}->{hash}	if $tests{$test}->{hash};
dotrace("-- START test=$test --\n");
	my %hash = calendar_list(@args);

use Data::Dumper qw(DumperX);
dotrace("GOT:\n" . DumperX(\%hash) .
	"WANTED:\n" . DumperX($expected02{$test}) );
dotrace("-- END test=$test --\n");

	if($tests{$test}->{hash}) {
		is(eq_hash(\%hash,$expected02{$test}),1);
	} else {
		is(scalar(keys %hash),scalar(keys %{$expected02{$test}}));
	}
}

sub dotrace {
	open  FH, ">>trace.log" or die "cannot open file: $!\n";
	print FH @_;
	close FH;
}

