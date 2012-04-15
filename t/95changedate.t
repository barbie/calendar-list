use Test::More;
use IO::File;
use Calendar::List;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

my $fh = IO::File->new('Changes','r')   or plan skip_all => "Cannot open Changes file";

plan no_plan;

my $latest = 0;
while(<$fh>) {
    next        unless(m!^\d!);
    $latest = 1 if(m!^$Calendar::List::VERSION!);
    like($_, qr!\d[\d._]+\s+(\d{2}/\d{2}/\d{4}|\w{3}\s+\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+([A-Z]+\s+)?\d{4})!,'... version has a date');
}

is($latest,1,'... latest version not listed');
