use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'Calendar::List',
    'VERSION_FROM'	=> 'lib/Calendar/List.pm',
    'PREREQ_PM'		=> {
		Clone       => 0,
		Tie::IxHash	=> 0,
		Time::Local	=> 0,
		Test::More	=> 0.47,	# for testing
	},
	NO_META			=> 1,

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT	=> 'A module for creating date lists',
       AUTHOR	=> 'Barbie <barbie@cpan.org>') : ()),
);
