#/usr/bin/perl -w
use strict;

use Test::More;
use File::Find::Rule;

# only for developing, ignore otherwise
eval "use Pod::Coverage";

if ($@) {
    plan skip_all => "Pod::Coverage required for evaluating POD";

} else {
    Pod::Coverage->import;
    # find me some modules
    my @files = File::Find::Rule->file()->name( qr/\.pm$/ )->in('blib/lib');
    plan tests => scalar @files;
    foreach my $file (@files) {
        # get me the package name
        $file =~ s=^.*lib/|\.pm$==g;
        $file =~ s|/|::|g;
        # go for it
        checkpod($file);
    }
}

sub checkpod {
    my $pc = new Pod::Coverage package => $_[0];
    is($pc->coverage,1);
    # if it failed, tell me what we failed on
    print STDERR "$_[0] qw(".join(" ",$pc->uncovered).")\n"    if($pc->coverage < 1);
} 