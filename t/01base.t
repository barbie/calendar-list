#!/usr/bin/perl -w
use strict;

#########################

use Test::More tests => 2;

eval "use Calendar::Functions";
is($@,'');
eval "use Calendar::List";
is($@,'');

#########################

