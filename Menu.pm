package HTML::Widgets::Menu;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
@EXPORT_OK= qw(
	new menu format html show
	
);
$VERSION = '0.01';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

=head1 NAME

HTML::Widgets::Menu - Builds an HTML menu

=head1 SYNOPSIS

  use HTML::Widgets::Menu;
  my $main=HTML::Widgets::Menu->new(
         home	=> "/users/frankie/",

         format	=> {
            default=>{
                 # default format options #
            },
            0=>{
               #level 0 format  options#
            }
            # more levels
         },

         menu=> [
            item1=>{
                url=>"url for item 1",
                menu=>[
                      item1_1=>'url for item 1_1'
                ]
            },
            item2=>"url for item 2"
            # more items
         ]
      );

      my ($menu)=$main->show();

      <% $menu %>

=head1 DESCRIPTION

This module will help you build a menu for your HTML site.
You can use with CGI or any mod_perl module. I use it from Mason.
Every time you request to show a menu it will return the HTML tags.
It's smart enough it will highlight the current active items.

This software is in a very early stage. It works fine for me and
is used in production sites.
You can send me patches, bugs or suggestions.
I'm not likely to answer your questions.
This software is provided as is and you're using it at your own risk.
You agree to use it with the same license of perl itself.

Drawing a menu is a matter of :
    the items of the menu
    the format you want it to have

You also must supply the home directory for all the web you
want to add this menu.

=head2 ITEMS

The items is a list.

For example, a simple menu could be:

    my @menu=(
          homepage   =>'.',
          "my links" =>"links.html"
    );

You can add levels of depth to the menu:


    my @menu=(  
        homepage => '.',
        "my links=>{
                  url=>"links/",
                  menu=>[
                        perl  =>"perl_link.html",
                        "movies I like"=>'movies.html'
                  ],
         about=>"about.html"
     );

For every level you add instead of the url you must supply a
reference to a hash with the url and the menu.
Now you can get this menu printed without any format at all.

my $main=HTML::Widgets::Menu(menu=>\@menu,home=>"/users/frankie/");
 
my ($menu)=$main->show();


Later insert $menu in your page. With Mason I'd do:  <% $menu %>

If the url of the item is only the name of a directory (the final /
is not necessary), the path is added to the submenu. For the example
above you must write the files:
    index.html
    links/index.html
    links/perl_link.thml
    links/movies.html
    about.html


The format is the way you tell how to show the items of the menu
It's a hash where you define the options.
There should be a default entry and numbered entries for every level,
starting with 0.

Options available (with defaults):
  max_depth => 1,
        # max number of depth if items are not active
  start => '', #html to put at the start of the level
  end => '', #html to add at the end of the level
  font=>'<FONT>',
  active_item_start => '<B><I>',
  active_item_end => '</B></I>',
  inactive_item_start => '',
  inactive_item_end => '',
  text_placeholder => '<text>',
           # example : <IMG SRC="<text>.gif" ALT="<text>">
           #                     ------           ------
  link_args=>'',
           # put javascript options here or other args
           # for the <A HREF tag
  indent => 1,
			# pixels for the indentation

Example:
my %format={
   default=>{
        max_depth=>2,
        font=>"<FONT SIZE=2>\n",
        active_item_start=>"<IMG 
            SRC=\"/users/frankie/img/blue_arrow.gif\" 
            BORDER=0 WIDTH=6><B><I><FONT COLOR=\"BLUE\">",
        active_item_end=>"</FONT></I></B>\n",
        indent=>20
    },
    0=>{
        inactive_item_start=>"<FONT SIZE=\"5\">",
        inactive_item_end=>"</FONT>",
        text_placeholder=>"<IMG SRC=\"<text>.gif\".gif>",
        link_args=>"onmouseover='javascript thingie'",
    },
    1=>{
        indent=>10
    }
};

Try it like this:
 
my ($main)=HTML::Widgets::Menu->new(format=>\%format
                                    menu=>\@menu,
                                    home=>"/users/frankie");

When you want to request the html that shows the menu you
must call the show funcion. It will build it using home,
format and menu. The final links will always be related
to the current URL. 

The show function also returns a usefull thing: the active
items of the menu. In the former example if the user is in
the url:  "movies.html" it will return a reference to a list
like this:
	"my_links"=>"links"
	"movies I like "=>"links/movies.html"
so you can know the path of the currem item. Now you can add the
keys of it to the title for example.

my ($menu,$active)=$main->show();



=head1 AUTHOR

Francesc Guasch-Ortiz	 frankie@etsetb.upc.es

=head1 SEE ALSO

perl(1).
mod_perl

=cut

use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

sub parse_arg {
  my $arg=shift @_;
  warn $#$arg,(join "-",@$arg) unless $#$arg%2;
  my %arg=@$arg;
  foreach (@_) {
	die "$_ not present" unless exists $arg{$_} and length $arg{$_};
  }
  return \%arg;
}

sub format_options {
	my ($format,$level)=@_;
	my %format_option=(
					  max_depth => 1,
				# max number of depth if items are not active
						  start => '',
							end => '',
							font=>'<FONT>',
			  active_item_start => '<B><I>',
			   	active_item_end => '</B></I>',
			inactive_item_start => '',
			  inactive_item_end => '',
			   text_placeholder => '<text>',
							 # example : <IMG SRC="<text>.gif" ALT="<text>">
							 #				       ------		    ------
					link_args=>'',
							# put javascript options here or other args
							# for the <A HREF tag
					     indent => 1,
	);
	my $default_format=$format->{default};
	foreach (keys %$default_format) {
		warn "$_ is not a format option anymore\n" 
			unless exists $format_option{$_};
		$format_option{$_}=$default_format->{$_};
	}
	my $current_level_format=$format->{$level};
	foreach (keys %$current_level_format) {
		warn "$_ is not a format option anymore\n" 
			unless exists $format_option{$_};
		$format_option{$_}=$current_level_format->{$_};
	}
	return \%format_option;
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $args=parse_arg(\@_);
	my $self={
		menu=>($args->{menu} or []),
		format=>($args->{format} or {}),
		home=>($args->{home} or '')
	};
	bless ($self,$class);
	return $self;
}

sub menu {
	my $self=shift;
	my $menu=shift;
	return $self->{menu} unless defined $menu;
	$self->{menu}=$menu;
}

sub format {
	my ($self,$format)=@_;
	return $self->{format} unless defined $format;
	$self->{format}=$format;
}

sub home {
	my ($self,$home)=@_;
	return $self->{home} unless defined $home;
	$self->{home}=$home;
}

sub show {
	my $self=shift;
	my $arg=parse_arg(\@_);
	my $rMenu=($arg->{menu} 
				or $self->{menu} 
				or []);
	
	my $level=0;
	$level=$arg->{level} if exists $arg->{level};

	my $indent=0;
	$indent= $arg->{indent} if exists $arg->{indent};

	my $home=($arg->{home} or $self->{home});
	my $url=$ENV{REQUEST_URI};
	$url=~s/$home//; # clean the home part
	$url=~s/\?.*$//; # and clean the args if any
  	$url.='/' unless $url=~m[(\.html$)|^$|/$]; 
								# add / if it's a directory
  	$url=~s!/+!/!g;	#strip //
  	$url="." unless length $url;
 	my $path="";
	$path=$arg->{path} if exists $arg->{path};

	my $format=format_options(($arg->{format} or $self->{format}),$level);
	$indent+=$format->{indent};
	my ($width)=($format->{active_item_start}=~/WIDTH=(\d+)/i or 0);

	my $ret="";
	my @active=();
	my $key;
	
	$ret.=$format->{font};

	foreach (@$rMenu) {
		$ret.=$format->{start};
    	if (!defined $key) {
        	$key=$_;
        	next;
    	}
		unless (ref $_) {
			$_={
				url=>$_,
				menu=>[]
			};
		}
		$_->{url}.="/" unless $_->{url}=~m!(\.html$)!;
    	my $sub_menu=$_->{menu};
    	my $bActive=0;
    	$bActive=($url=~m!^$path$_->{url}!);
    	if ($bActive) {
	    	$ret.="<IMG SRC='/img/point.gif' WIDTH=$indent HEIGHT=3>"  
				if ($indent);
		    $ret.=$format->{active_item_start};
	    	$active[++$#active]=$key;
    	} else {
	    	$ret.=$format->{inactive_item_star};
	    	$ret.="<IMG SRC='/img/point.gif' WIDTH=".($indent+$width)." HEIGHT=1>" ;
    	}
		my $link="";
    	my $dir_level=($url=~tr!/!!);
			if (length $_->{url}) {
    		if ($dir_level) {
    			for (my $cont=1;$cont<=$dir_level;$cont++) {
					$link.="../";
    			}
    		}
			if ($_->{url}=~/(^http)|(^ftp)/) {
				$link.=$_->{url};
			} else {
    			$link.="$path$_->{url}";
			}
			my $link_w="<A HREF=\"$link\" $format->{link_args}>";
			$link_w=~s/\<text\>/$key/g;
			$ret.=$link_w;
		}
		if (defined $format->{text_placeholder}) {
			my $wrap=$format->{text_placeholder};
			$wrap=~s/\<text\>/$key/g;
    		$ret.=$wrap;
		} else {
			$ret.=$key;
		}
    	$ret.="</A>";

    	if ($bActive and length $link) {
	    	$active[++$#active]=$link;
	    	$ret.=$format->{active_item_end};
    	} else {
	    	$ret.=$format->{inactive_item_end};
    	}
    	$ret.="<BR>\n";
    	if ($level<$format->{max_depth} or $bActive) {
			my $path_son=${path};
			$path_son.=$_->{url} unless $_->{url}=~/html$/;
    		my ($subMenu,$rSubActive)
	  			=$self->show(
					menu=>$sub_menu,
					format=>$arg->{format},
					level=>$level+1,
					indent=>$indent+$width,
					home=>$home,
					path=>$path_son
			);
     		$ret.=$subMenu if defined $subMenu;
    		push @active,@$rSubActive if defined ($rSubActive);
    	}
    	undef $key;
    	$ret.=$format->{end};
	}
	$ret.="</FONT>";
	return ($ret,\@active);
}

1;
__END__
