package HTML::Widgets::Menu;


use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG);

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
$VERSION = '0.02';

$DEBUG=0;


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
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
							font=>'',
			  active_item_start => '<B><I>',
			   	active_item_end => '</B></I>',
			inactive_item_start => '',
			  inactive_item_end => '',
			   text_placeholder => '',
							 # example : <IMG SRC="<text>.gif" ALT="<text>">
							 #				       ------		    ------
					link_args=>'',
							# put javascript options here or other args
							# for the <A HREF tag
					     indent => 0,
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
	$self->{home}.="/" unless $self->{home}=~m!/$|\.html$!;
#	print "home=$self->{home}\n";
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
	my %arg=@_;
	$self->set_url();
	$self->build_active(menu=>$self->{menu});
	$self->{html}=$self->build_html(@_);
	return ($self->{html},$self->{active});
}

sub html {
	my $self=shift;
	$self->set_url();
	$self->build_active unless defined $self->{active};
	my $html=($self->{html} or $self->build_html);
	$self->{html}=$html;
	return $self->{html};
}

sub active {
	my $self=shift;
	$self->build_active unless defined $self->{active};
	return $self->{active};
}

sub set_url {
	my $self=shift;
	return if defined $self->{url} and $self->{url} eq $self->{old_url};
	croak "Undefined REQUEST_URI" unless defined $ENV{REQUEST_URI};
	$self->{old_url}=$ENV{REQUEST_URI};
	delete $self->{html};
	delete $self->{active};
	my $home=$self->home;
	my $url=$ENV{REQUEST_URI};
	print "url=$url ->" if $DEBUG;
	$url=~s!/\.$!/!;
	$url=~s!/+!/!g;
	$url=~s/$home//; # clean the home part
	$url=~s/\?.*$//; # and clean the args if any
	$url.="/" unless $url=~m!(\.\w+|/)$!
				or $url=~/\w+:/
				or $url eq "";
  	$url=~s!//+!/!g;	#strip //
#	$url.='index.html' if $url=~m!/$!;
	$self->{path}="";
	foreach (1 .. $url=~ tr!/!! ) {
		$self->{path}.="../";
	}
	$self->{url}=$self->{path}.$url;
	print $self->{url},"\n" if $DEBUG;
}

sub build_active {
	my $self=shift;
	return if defined $self->{active};
	$self->recurse_build_active();
	my $active=$self->{active};
	my @rev;
	my $key;
	foreach (@$active) {
		unless (defined $key) {
			$key=$_;
			next;
		}
		push @rev,($_,$key);
		undef $key;
	}
	my @rev2=reverse @rev;
	$self->{active}=\@rev2;
}
	
sub recurse_build_active {
	# returns true if one of the entries is active
	my $self=shift;
	my %arg=@_;
	my $menu=($arg{menu}
				or $self->{menu}
				or []);
	my $path=($arg{path} or $self->{path} or "");
	my $key;
	my $bActive=0;
	foreach (@$menu) {
		unless (defined $key ) {
			$key=$_;
			next;
		}
		unless (ref $_) {
			$_={
				url=>$_,
				menu=>[]
			};
		} else {
			delete $_->{active};
			delete $_->{abs_url};
			foreach (keys %$_) {
				die "Unknown key $_\n" unless $_=~/^(url|menu)$/;
			}
		}
		unless (exists $_->{url} and exists $_->{menu}) {
			undef $key;
			next;
		}
		$_->{url}=~s!/$!!;
		$_->{abs_url}=$_->{url};
		$_->{abs_url}=$path.$_->{url} unless $_->{url}=~/^\w+:/;
		$_->{abs_url}.="/" unless $_->{url}=~m!(\.\w+|/)$!
						or $_->{url}=~/^\w+:/;
		my $next_path="";
		$next_path=$_->{abs_url} if $_->{abs_url}=~m!/$!;
		if ($self->recurse_build_active(menu=>$_->{menu},path=>$next_path) 
					or $_->{abs_url} eq $self->{url}) {
			$self->{active_url}->{$_->{abs_url}}++;
			my $active=$self->{active};
			push @$active,($key,$_->{abs_url});
			$self->{active}=$active;
			$_->{active}++;
			$bActive=1;
		}
#		$_->{abs_url}.="index.html" if $_->{abs_url}=~m!/$!;
		print $_->{abs_url} if $DEBUG;
		print "*" if $DEBUG and $bActive;;
		print "\n" if $DEBUG;
		undef $key;
	}
	return $bActive;
}

sub build_html {
	my $self=shift;
	my $arg=parse_arg(\@_);
	my $rMenu=($arg->{menu} 
				or $self->{menu} 
				or []);
	
	my $level=0;
	$level=$arg->{level} if exists $arg->{level};

	my $indent=0;
	$indent= $arg->{indent} if exists $arg->{indent};

	my $url=$self->{abs_url};

	my $format=format_options(($arg->{format} or $self->{format}),$level);
	$indent+=$format->{indent};
	my $width=0;
	($width)=$format->{active_item_start}=~/WIDTH=(\d+)/i 
		if exists $format->{active_item_start};
	$width=0 unless defined $width;
	my $ret="";
	my $key;
	

	foreach (@$rMenu) {
		$ret.=$format->{start};
    	if (!defined $key) {
        	$key=$_;
        	next;
    	}
		unless ( exists $_->{menu} ) {
			undef $key;
			next;
		}
    	my $sub_menu=$_->{menu};
		my $bActive=$_->{active};
    	if ($bActive) {
	    	$ret.="<IMG SRC='/img/point.gif' WIDTH=$indent HEIGHT=3>"  
				if $indent;
		    $ret.=$format->{active_item_start};
    	} else {
	    	$ret.=$format->{inactive_item_start};
	    	$ret.="<IMG SRC=\"/img/point.gif\" WIDTH=".($indent+$width)." HEIGHT=1>"  if $indent+$width;
    	}
		if (length $_->{abs_url}) {
			my $link_w="<A HREF=\"".$_->{abs_url}."\" $format->{link_args}>";
			$link_w=~s/\<text\>/$key/g;
			$ret.=$link_w;
		}
		$ret.=$format->{font} 
			if exists $format->{font} and length $format->{font};

		if (defined $format->{text_placeholder} 
					and length $format->{text_placeholder}) {
			my $wrap=$format->{text_placeholder};
			$wrap=~s/\<text\>/$key/g;
    		$ret.=$wrap;
		} else {
			$ret.=$key;
		}
		$ret.="</FONT>" if exists $format->{font} and length $format->{font};

    	$ret.="</A>";

    	if ($bActive and length $_->{url}) {
	    	$ret.=$format->{active_item_end};
    	} else {
	    	$ret.=$format->{inactive_item_end};
    	}
    	$ret.="<BR>" unless defined $format->{text_placeholder}
						and length $format->{text_placeholder};
		$ret.="\n";
    	if ($level<$format->{max_depth} or $bActive) {
	  		my $subMenu	=$self->build_html(
					menu=>$sub_menu,
					format=>$arg->{format},
					level=>$level+1,
					indent=>$indent+$width,
			);
     		$ret.=$subMenu if defined $subMenu;
    	}
    	undef $key;
    	$ret.=$format->{end};
	}
	return $ret;
}

1;
__END__

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


    print $menu->html;

=head1 DESCRIPTION

This module will help you build a menu for your HTML site.
You can use with CGI or any mod_perl module. I use it from HTML::Mason.
Every time you request to show a menu it will return the HTML tags.
It's smart enough it will highlight the current active items.

You can see an example of this here: http://www.etsetb.upc.es/~frankie

This software is more mature that latest version. It works fine for me and
is used in production sites. The very first version was almost unusable
if you didn't had very strict rules for creating the menu, now it's
much improved and useful. Tell me if you like it or not.

You can send me patches, bugs or suggestions.

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

You can add depth to the menu:


    my @menu=(  
        homepage   => '.',
        "my links" => {
                  url=>"links/",
                  menu=>[
                        perl  =>"perl_link.html",
                        "movies I like"=>'movies.html'
                  ],
         about=>"about.html"
     );

For every level you add instead of the url you must supply a
reference to a hash with the url and the submenu.
Now you can get this menu printed in html easily and get the
list of active items.

my $main=HTML::Widgets::Menu->new(menu=>\@menu,home=>"/users/frankie/");
 
print $main->html(); # this renders the html
my @active_items= @{$main->active}; # list of active items



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
        # max number of depth shown if items are not active
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
  indent => 8,
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
 
my $main=HTML::Widgets::Menu->new(format=>\%format
                                    menu=>\@menu,
                                    home=>"/users/frankie");

When you want to request the html that shows the menu you
must call the html method. It will build it using home,
format and menu. The final links will always be related
to the current URL. 


The pixel indentation is done using the url /img/point.gif.

If you define an active format with an image like this:
    active_item_start=> ' <IMG SRC="arrow.gif" WIDTH="10">'

this WIDTH is added to the indentation so it looks pretty cool
in the screen:


       not active
       another url
    => this is the active
       another one

			
The other items have been indented the width of the image, in addition
to the indent tag in the format.


The activation of the items work automagically reading the environment 
variable provided by the web server: $ENV{REQUEST_URI}

=head2 Active Items

The active method returns a usefull thing: the active
items of the menu. In the former example if the user is in
the url:  "movies.html" it will return a reference to a list
like this:
	"my_links"=>"links"
	"movies I like "=>"links/movies.html"

What can I do with the active items ?

once the menu is built you can retrieve its active items this way:

	$menu->active;

This method returns an array with the items and links this way:

	item1 , link1 , item2, link2

You can use it to build a title or path like this: 

	print $menu->html; # that builds the menu


	my $title="Main Title";
	my $path="";
	my $item;
	foreach (@{$menu->active}) {
		$item=$_ and next unless defined $item;

		$title.=" - $item";

		$path.="/" if length $path;
		$path.="<A HREF=\"$_\">$item</A>";

		undef $item;

	}
	# now I have a title and path variables


=head1 AUTHOR

Francesc Guasch-Ortiz	 frankie@etsetb.upc.es

=head1 SEE ALSO

perl(1).
mod_perl

=cut


