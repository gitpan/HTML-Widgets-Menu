use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::Widgets::Menu',
    'VERSION_FROM' => 'Menu.pm', # finds $VERSION
	'PREREQ_PM' => {DBI => 1.14 },
);
