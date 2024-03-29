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
$VERSION = '0.12';

$DEBUG=0;

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
         ],

         # this is experimental.

         allowed => sub {
            my ($url)=shift;
            my $user=$ENV{REMOTE_USER};
            return 1 unless defined $user;
            return ($user eq "frankie"  && $url =~/^intranet/);
         }
      );


    print "<title>$menu->title</title>",
    print "<h2>$menu->path</h2>",
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
     # '<img src="/icons/<url>_active.gif">'
  active_item_end => '</B></I>',
     # '<img src="/icons/<url>_inactive.gif">'
  inactive_item_start => '',
  inactive_item_end => '',
  text_placeholder => '<text>',
           # example : <IMG SRC="<text>.gif" ALT="<text>">
           #                     ------           ------
  active_text_placeholder => '<text>'
			# same use as text_placeholder but for active items
  link_args=>'',
           # put javascript options here or other args
           # for the <A HREF tag
  indent => 8,
			# pixels for the indentation

  auto_br => 1, # Adds a <br> at the end of every line [default 1]

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
        active_text_placeholder=>"<font color='red'><u><text></u></font>",
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

=cut

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
			  active_item_start => '',
			   	active_item_end => '',
			inactive_item_start => '',
			  inactive_item_end => '',
			   text_placeholder => '',
							 # example : <IMG SRC="<text>.gif" ALT="<text>">
							 #				       ------		    ------
			active_text_placeholder=>'<b><i><text></i></b>',
							# same use as text_placeholder but for active items	
				link_args=>'',
							# put javascript options here or other args
							# for the <A HREF tag
					     indent => 0,
					    auto_br => 1
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
	$self->{auth}=$args->{allowed}  if exists $args->{allowed};
	return $self;
}

=head1 CONSTRUCTORS

=head2 new

  Read the beggining of this doc.

=cut

=head2 new_dbi

This constructor lets you read the menu data from a table.
Experimental, poorly tested and incredibly bad documented.

I<Example:>

  my $menu = HTML::Widgets::Menu -> new_dbi (
                 dbh => $dbh,
               table => menu,
            field_id => 'id',
     field_id_parent => 'id_parent',
          field_item => 'item',
           field_url => 'url'

  );

Read test.pl in the sources if you want to see more.

=cut

sub new_dbi {
    my $proto = shift;
    my $arg=parse_arg(\@_,qw(dbh table field_id field_item field_url
                                field_id_parent));
    $arg->{field_order}=$arg->{field_item}
        unless defined $arg->{field_order};
	$arg->{where}=''
		unless defined $arg->{where};
    my $menu_data=load_menu_data(%$arg);
    return new_arg(
        $proto,
        menu => $menu_data,
        format => $arg->{format},
        home => $arg->{home}
    );

}

sub new_arg {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $args=parse_arg(\@_);
    my $self={
        menu=>($args->{menu} or []),
        format=>($args->{format} or {}),
        home=>($args->{home} or '')
    };
    $self->{home}.="/" unless $self->{home}=~m!/$|\.html$!;
    bless ($self,$class);
    return $self;
}


sub load_menu_data {

    my %arg=@_;
    $arg{first_id}=0 unless exists $arg{first_id};
    my $dbh=$arg{dbh};
	my $where =  " WHERE $arg{field_id_parent}='$arg{first_id}' ";
	$where.= " AND $arg{where} "
		if length $arg{where};

    my $sth=$dbh->prepare(
        " SELECT $arg{field_id},$arg{field_item},$arg{field_url}    ".
        " FROM $arg{table}                                  ".
		" $where											".
        " ORDER BY $arg{field_order}                        "
    ) or die $DBI::errstr;
    my ($id,$item,$url);
    $sth->execute or die $DBI::errstr;
    $sth->bind_columns(\($id,$item,$url)) or die $DBI::errstr;
    my @menu;

    print "Sons of $arg{first_id}\n" if $DEBUG;
    while ($sth->fetch) {
        print "\t$id,$item,$url\n" if $DEBUG;
        push @menu,($item => {
                        url => $url,
                        _id => $id
                    }
		);
	}
    print "\n" if $DEBUG;
    $sth->finish;
    foreach (@menu) {
        next unless ref ;
        $_->{menu}=load_menu_data(%arg,first_id=> $_->{_id});
        delete $_->{_id};
    }
    return \@menu;
}


sub call_auth {
	my $self=shift;
	return 1 unless exists $self->{auth};
	my $url=shift;
	$url=~s!^(\.\./)+!!g;
	my $ret=&{$self->{auth}}( $self->{home}.$url );
	warn "Not autorised to enter $self->{home}$url\n"
		unless $ret;
	return $ret;
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

=head1 METHODS

=head2 title

Returns a string suitable as title of the page. It uses
the active items of the menu for creating it.

    Products - Hardware - Mother Boards

I<arguments>

  You can pass an optional separator for the items. (default = '-')

	
=cut

sub title {
	my $self=shift;
	my $separator=(shift or '-');
	my $item;
	my $title="";
	foreach (@{$self->active}) {
		unless (defined $item) {
			$item=$_;
			next;
		}
		$title.=$separator if length $title;
		$title.=$item;
		undef $item;
	}
	return $title;
}

=head2 path


It returns a string with the path to the current items.
Every item is wrapped around its link.

   <a href="/products">products</a> / 
       <a href="/products/hardware">hardware</a> /
           <a href="/products/hardware/motherboards">motherboards</a>

I<arguments>

You an pass an optional separator. Default '/'

=cut

sub path {
	my $self=shift;
	my $separator=(shift or '/');
	my $item;
	my $path="";
	foreach (@{$self->active}) {
		unless (defined $item) {
			$item=$_;
			next;
		}
		$path.=$separator if length $path;
		$path.="<A HREF=\"$_\">$item</A>";
		undef $item;
	}
	return $path;
}



sub show {
	my $self=shift;
	my %arg=@_;
	$self->set_url();
	$self->build_active(menu=>$self->{menu});
	$self->{html}=$self->build_html(@_);
	return ($self->{html},$self->{active});
}

=head2 html

Renders the menu as html.

=cut

sub html {
	my $self=shift;
	$self->set_url();
	$self->build_active unless defined $self->{active};
	return $self->{html} if exists $self->{html}
							&& defined $self->{html};
	$self->{html}=$self->build_html(@_);
	return $self->{html};
}

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


=cut



sub active {
	my $self=shift;
	return $self->{active} if defined $self->{active};
	$self->set_url;
	$self->build_active;
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
				|| $url=~/\w+:/
				|| $url eq ""
				|| $url=~/\?/; #Alberto
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
	print "\nBuilding active for $self->{url}\n" if $DEBUG;
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
	print "path=$path\n" if $DEBUG;
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
		print "\titem=$_->{url}\n" if $DEBUG;
		$_->{url}=~s!/$!!;
		
		$_->{abs_url}=$_->{url};
		$_->{abs_url}=$path.$_->{url} unless $_->{url}=~/^\w+:/;
		$_->{abs_url}.="/" unless $_->{url}=~m!(\.\w+|/)$!
						|| $_->{url}=~/^\w+:/
						|| $_->{url}=~/\?/;
		my $next_path=$path;
		$next_path.=$_->{url} if $_->{abs_url}=~m!/$!;
		$next_path.="/" if $_->{abs_url}=~m!/$!;

		$next_path=~s#//+#/#g;

		unless ( $self->call_auth($_->{abs_url}) ){
			undef $key;
			next;
		}

		if ($self->recurse_build_active(menu=>$_->{menu},path=>$next_path) 
					or $_->{abs_url} eq $self->{url}) {
			$self->{active_url}->{$_->{abs_url}}++;
			my $active=$self->{active};
			push @$active,($key,$_->{abs_url}) ;
			$self->{active}=$active;
			$_->{active}++;
			$bActive=1;
		}
#		$_->{abs_url}.="index.html" if $_->{abs_url}=~m!/$!;
		print "\turl=".$_->{abs_url} if $DEBUG;
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
	($width)=$format->{active_item_start}=~/WIDTH=\"?(\d+)/i 
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
        unless ( $self->call_auth($_->{abs_url}) ){
            undef $key;
            next;
        }
    	my $sub_menu=$_->{menu};
		my $bActive=$_->{active};
    	my $nom_gif=$_->{abs_url};
		$nom_gif=~s/\.+//g;
		$nom_gif=~s/\///g;
		if ($bActive) {
			my $change=$format->{active_item_start};
			$change=~s/\<url\>/$nom_gif/;
			$ret.=$change;
	    	$ret.="<IMG SRC='/img/point.gif' WIDTH=$indent HEIGHT=3>"  
				if $indent;
    	} else {
			my $change=$format->{inactive_item_start};
			$change=~s/\<url\>/$nom_gif/;
	    	$ret.=$change;
	    	$ret.="<IMG SRC=\"/img/point.gif\" WIDTH=".($indent+$width)." HEIGHT=1>"  if $indent+$width;
    	}
		if (length $_->{abs_url}) {
			my $link_w="<A HREF=\"".$_->{abs_url}."\" $format->{link_args}>";
			$link_w=~s/\<text\>/$key/g;
			$ret.=$link_w;
		}
		$ret.=$format->{font} 
			if exists $format->{font} and length $format->{font};

		if ($bActive && defined $format->{active_text_placeholder}
					&& length $format->{active_text_placeholder}) {
				my $wrapp=$format->{active_text_placeholder};
				$wrapp=~s/\<text\>/$key/g;
				$ret.=$wrapp;
		} elsif (defined $format->{text_placeholder} 
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
    	$ret.="<BR>" unless (defined $format->{text_placeholder}
								&& length $format->{text_placeholder} 
								&& defined $format->{active_text_placeholder}
								&& length $format->{active_text_placeholder})
						|| !$format->{auto_br};
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


=head1 COOL USAGE

You can add tags to the format options that can be replaced
when the html is rendered. I'll say some examples:

=head2 Display an image near the item

You must have an image called like the item url.
Say you have two main options, make a gif for each one.

   /img/icons/products.gif
   /img/icons/services.gif

The path and extension are not mandatory.

Then in the format options type:

  active_item_start =>'<img src="/icons/<url>.gif">'

The url tag will be replaced by the url of the item.
It works also for inactive_item_start, so you can have
different images if it's inactive or active.

  active_item_start => '<img src="/icons/<url>_active.gif">',
  inactive_item_start => '<img src="/icons/<url>_inactive.gif">',

=head1 EXPERIMENTAL OPTIONS

The experimental options won't make your site crash
but may produce heavy load. Feedback wellcome.

Menus from databases is experimental, it hasn't been
fully tested and should be used at your own risk.

Authorisation is an expensive feature and should be
used in low load sites. 


=head1 PLEASE

Please send documentation improvements, examples of sites
using it are wellcome.
Please, tell me you're using it. I'll accept requests, comments,
suggestions, bug patches.


=head1 AUTHOR

Francesc Guasch-Ortiz	 frankie@etsetb.upc.es

=head1 SEE ALSO

perl(1).
mod_perl

=cut


