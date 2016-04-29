#!/usr/bin/perl

# To permit this cgi, replace # on the first line above with the
# appropriate #!/path/to/perl shebang, and on Unix / Linux also
# set this script executable with chmod 755.
#
# ***** !!! WARNING !!! *****
# This script echoes the server environment variables and therefore
# leaks information - so NEVER use it in a live server environment!
# It is provided only for testing purpose.
# Also note that it is subject to cross site scripting attacks on
# MS IE and any other browser which fails to honor RFC2616. 

##
##  printenv -- demo CGI program which just prints its environment
##
use strict;
use warnings;
use CGI;
use Cwd;
use File::Basename;



my $dir = Cwd::getcwd;
my $FULLPROG = Cwd::abs_path($0);

my $query = new CGI;
my $url = $query->param('url');
chdir("Kunal_NBA");
print "Content-type: text/plain; charset=iso-8859-1\n\n";
print "$url \n";
print "$dir \n";
foreach my $var (sort(keys(%ENV))) {
    my $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "${var}=\"${val}\"\n";
}
my $outJSONfl = "output/nbaGame_$$.json";
my @sysargs = (
	"'/usr/bin/perl' 'parseNBAYahooHTML.pl' '-nbaGameURL' '$url' '-outJSONfile' '$outJSONfl'"
	);
print(@sysargs);
system(@sysargs);
