use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'DateTime::Format::Mail',
    VERSION_FROM	=> 'lib/DateTime/Format/Mail.pm',
    PREREQ_PM => {
		'DateTime' => 0.09,
		'Params::Validate' => 0.58,
		'Test::More' => 0.47,
	    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/DateTime/Format/Mail.pm',
      AUTHOR     => 'Iain Truskett <spoon@cpan.org>') : ()),
);


