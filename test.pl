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

use strict;

my @data=(
	'index' => 'index.html',
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
				],
			},
			'level 1.3'=> {
				url => 'level.1.3.html',
				menu => [
						'level 1 3 1' => 'level1.3.1.html'
				]
			}
		]
	},
	empty => '',
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

foreach my $link (qw( level1/level1.1 plain plain.html / level2/level2.1.html
			level2/level2.2 level1 level1/ level1/. )) {
	$ENV{REQUEST_URI}=$home.$link;
	$menu->html();
	my @active=@{$menu->{active}};
	my $clean_link=clean_uri($link);
	if(defined $active[-1] and $active[-1] ne $clean_link ) {
		warn "html=".$menu->html,"\n";
		warn $active[-1]," eq $clean_link ($link)\n";
		print "not ";
		exit;
	}
	if ($menu->title ne title(\@active)){
		warn "wrong title: ".$menu->title." eq ". title(\@active);
		print "not ";
		exit;
	}
	if ($menu->path ne path(\@active)) {
		warn "wrong path: ".$menu->path." eq ".path(@active);
		print "not ";
		exit;
	}
	print "ok ",++$test,"\n";
}

$home="/users/frankie/blah/";

my @menu=(
    'my cats'=>{
		url=>"cats",
		menu=>[
			panda=> {
				url => 'panda.html',
				menu => [
					'panda mail' => "panda_main.html",
				]
			}
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
			mysql=>'mysql.html',
#			empty => {
#				menu => [
#					first_empty => 'first_empty.html',
#				]
#			},
			undefined => undef
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

my $menu2= [
			'Web ETSETB' => {
				url => 'index.html',
				menu => [
					Objectius => 'objectius.html',
				],
			},
			configuracio => {
				url => 'configuracio',
				menu =>  [ 
						software => {
							url => 'software.html',
							menu => [
								apache => 'apache.html',
								squid  => 'squid.html'
							],
						},
						hardware => 'hardware.html'
				]
			},
			disseny => {
				url => 'disseny.html',
				menu => [
					'Imatge Corporativa' => 'imatge_corporativa',
					Estil	=> {
						url => 'estil.html',
						menu => [
							'Lletres' => 'fonts.html',
							'icones'  => 'icones.html'
						]
					}
				]
			},
			estructura => {
				url => 'estructura.html',
				menu => [
					plana_principal => {
						 url => 'plana_principal.html',
						menu => [

							Seccions => {
								url => 'seccions.html',
								menu => [
								]
							},
							Impactes => 'impactes.html',
							Links => 'links.html'
						]
					},
					navegacio => {
						url => 'navegacio.html',
						menu => [
							menu => 'menu.html',
							menu_inferior => 'menu_inferior.html'
						],
					},
					titols => 'titols.html',
					subtitols => 'subtitols.html',
					links_relacionats => 'links_relacionats.hml',
					novetats => 'novetats.html',
					buscar   => 'buscar.html'
				]
	}, # d'estructura
			programacio => {
				url => 'programacio',
				menu => [
					treballar => {
						 url => 'treballar.html',
						menu => [
							servidors => 'servidors.html',
							entorn => 'entorn.html',# la primera vegada
													# apache, mason, etc.
							eines => 'eines.html',
							estil => {
								url => 'estil',
								menu => [
									databases => 'estil/.html',
									html => 'estil/html.html',
									perl => 'estil/perl.html'
								]
							}
						]
					},
					moduls => {
						url => 'moduls',
						menu => [
							'Ocupaci&oacute;ns' => 'ocupacions.html',
							'llistes de classe' => 'llistes_classe.html',
							'missatges' => 'missatges.html',
							'guia docent' => 'guia_docent.html',
							'gesti&oacute; de links' => 'gestio_links.html',
							horaris => 'horaris.html',
							enquestes => 'enquestes.html'
						],
					},
					disseny => 'disseny.html' # CSS
				]
			}
		]

;

for my $menu_ref((\@menu) ) {
$menu=HTML::Widgets::Menu->new(
	menu=>$menu_ref,
	format => \%format,
	home=>$home,
	auth => sub {
	#	print shift;
		return 1;
	}
);

my @test=qw( cats cats/panda_main.html / /computers/ computers computers/ /computers 
	/computers/mysql.html computers/download.zip 
	);
push @test,"";
foreach (@test) {
	$ENV{REQUEST_URI}=$home.$_;
#	print "$_\t";
	$menu->html;
	my @active=@{$menu->{active}};
	$_=clean_uri($_);
#	print "$active[-1]\n";
	if( $active[-1] ne $_) {
		warn "\"$active[-1]\" == \"$_\"\n";
		print "not ";
		die;
	}
	print "ok ",++$test,"\n";
}
}


#test_dbi();



sub clean_uri {
	$_=shift;
	s!/\.$!/!;
	$_.="/" unless /\w+:/ or /\.\w+/;
	s!^/!!;
	s!/+!/!g;
	s!^/$!!;
	my $back=tr!/!!;
	foreach my $cont (1..$back) {
		$_="../$_";
	}
	s!/+!/!g;
#	s!index.html$!!;
	return $_;
}

sub title {
	my $active=shift;
	my $title="";
	my $item;
	foreach (@$active) {
		unless (defined $item) {
			$item=$_;
			next;
		}
		$title.="-" if length $title;
		$title.=$item;
		undef $item;
	}
	return $title;
}


sub path {
	my $active=shift;
	my $item;
	my $path="";
	foreach (@$active) {
		unless (defined $item) {
			$item=$_;
			next;
		}
		$path.='/' if length $path;
		$path.="<A HREF=\"$_\">$item</A>";
		undef $item;
	}
	return $path;
}

sub test_dbi {

	print "Testing DB: ";

	my $dbh=DBI->connect("DBI:mysql:test") or die $DBI::errstr;
	$dbh->do("DROP TABLE test_menu") or warn $DBI::errstr;
	$dbh->do("
		CREATE TABLE test_menu (
		       id 	int auto_increment primary key,
		id_parent 	int not null,
			 item   char(20),
		      url   char(80)
		)
	") or die $DBI::errstr;
	my $menu_data=<<EOT;
1:0:a:a.html
2:0:b:b
3:1:b1:b1.html
4:1:b2:b2
5:4:b21:b21.html
6:4:b22:b22.html
EOT

	foreach my $line (split/\n/,$menu_data) {
		$line =~ s/:/','/g;
		$dbh->do(" INSERT INTO test_menu values('$line')") or die $DBI::errstr;
	}

	my $menu=HTML::Widgets::Menu->new_dbi (
		  dbh => $dbh,
		table => 'test_menu',
		field_id => 'id',
		field_id_parent => 'id_parent',
		field_item => 'item',
		field_url => 'url'
		
	);

	$dbh->disconnect;

	print "ok.\n";

}
