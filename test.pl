# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::Widgets::Menu;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my @data=(
	'plain html' => 'plain.html',
	'plain dir'=>'plain',
	'dir level 1'=>{
		url=>'level1',
		menu=>[
			'level 1.1'=>'level1.1',
			'level 1.2'=>{
				url=>'level1.2',
				menu => [
					'level 1 2 3'=>'level1.2.3'
				]
			}
		]
	},
	'dir level 2'=>{
		url=>'level2',
		menu => [
			'level 2.1'=>'level2.1.html',
			'level 2.2 dir' => 'level2.2'
		]
	}
);
my $home="/text/menu/";
$HTML::Widgets::Menu::DEBUG=0;
my $menu=HTML::Widgets::Menu->new(
		menu=>\@data,
		home=>$home
);

my $test=0;

foreach (qw( level1/level1.1 plain plain.html / level2/level2.1.html
			level2/level2.2)) {
	$ENV{REQUEST_URI}=$home.$_;
	$menu->show();
	my @active=@{$menu->{active}};
	$_=clean_uri($_);
	if( $active[-1] ne $_) {
		warn $active[-1]," eq ",$_,"\n";
		print "not ";
	}
	print "ok ",++$test,"\n";
}

$home="/users/frankie/";

@menu=(
    'my cats'=>{
		url=>"cats.html",
		menu=>[
			panda=>"panda_main.html",
     	],
    },
    computer=>{
		url=>"computers",
		menu=>[	
			download => 'download.zip',
			linux=>{
				url=>'linux.html',
				menu=>[
			  		'Linux.org'=>'http://www.linux.org',
			  		'HowTos'=>'http://metalab.unc.edu/mdw/HOWTO/'
				],
			},
			perl=>{
				url=>'perl',
		  		menu=>[
					links=>'perl_links.html',
			    ]
			},
			mysql=>'mysql.html'
		]
	}
);

my %format=(
	default=>{
		max_depth=>2,
		font=>"<FONT SIZE=2>\n",
		active_item_start=>"<IMG SRC=\"/users/frankie/img/blue_arrow.gif\" BORDER=0 WIDTH=6><B><I><FONT COLOR=\"BLUE\">",
		active_item_end=>"</FONT></I></B>\n",
		indent=>20
	},
	0=>{
		font=>"<FONT SIZE=3>\n",
		active_item_start=>"<IMG SRC=\"/users/frankie/img/blue_arrow.gif\" BORDER=0 WIDTH=10><B><I>",
		active_item_end=>"</I></B>\n",
	},
	'1'=>{indent=>10,
		text_placeholder=>"<text> *"
	},
	'2'=>{indent=>10}
);

$menu=HTML::Widgets::Menu->new(
	menu=>\@menu,
	format => \%format,
	home=>$home
);

foreach (qw( / /computers/ computers computers/ /computers 
	/computers/mysql.html computers/download.zip )) {
	$ENV{REQUEST_URI}=$home.$_;
	$menu->html;
	my @active=@{$menu->{active}};
	$_=clean_uri($_);
	if( $active[-1] ne $_) {
		warn $active[-1]," eq ",$_,"\n";
		print "not ";
	}
	print "ok ",++$test,"\n";
}

sub clean_uri {
	shift;
	$_.="/" unless /\w+:/ or /\.\w+/;
	s!^/!!;
	s!/+!/!g;
	s!^/$!!;
	my $back=tr!/!!;
	foreach my $cont (1..$back) {
		$_="../$_";
	}
	s!/+!/!g;
	return $_;
}
