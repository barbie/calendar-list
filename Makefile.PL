use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Calendar::List',
    'VERSION_FROM'	=> 'lib/Calendar/List.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Clone => 0,
		Tie::IxHash => 0,
		Time::Local => 0,
		Test::More => 0,	# for testing
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT	=> 'A module for creating date lists',
       AUTHOR	=> 'Barbie <barbie@cpan.org>') : ()),
);
