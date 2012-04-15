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
} elsif(defined $DateTime::VERSION && $DateTime::VERSION > 0.16) {
	plan skip_all => "DateTime after 0.16 is not supported.";
}

plan tests => 13;

###########################################################################
# name: 21list-dt.t
# desc: Dates for calendar_list function using DateTime
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
		is_deeply(\@array,$expected02{$test});
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
#use Data::Dumper qw(DumperX);
#print STDERR "\n===\ntest=$test\nhash=".DumperX(calendar_list(@args));
	my %hash = calendar_list(@args);

	if($tests{$test}->{hash}) {
		is_deeply(\%hash,$expected02{$test});
	} else {
#use Data::Dumper qw(DumperX);
#print STDERR "\n===\ntest=$test\nhash=".DumperX(\%hash).
#			 "expected=".DumperX($expected02{$test})."\n===\n";
		is(scalar(keys %hash),scalar(keys %{$expected02{$test}}));
	}
}

