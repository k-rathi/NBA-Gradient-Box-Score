use strict;
use warnings;
use CGI;
use Cwd;
use File::Basename;

my $dir = Cwd::getcwd;
my $FULLPROG = Cwd::abs_path($0);

my $query = new CGI;

my $date = $query->param('date');

chdir("Kunal_NBA");
print "Content-type: text/plain; charset=iso-8859-1\n\n";
print "$date \n";
print "$dir \n";
foreach my $var (sort(keys(%ENV))) {
    my $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "${var}=\"${val}\"\n";
}
my $outJSONfl = "scoreboard/$date.json";
my $url = 'http://stats.nba.com/stats/scoreboardv2/?GameDate=$date&LeagueID=00&DayOffset=00';
my @sysargs = (
	"'/usr/bin/curl' '$url' '-o' '$outJSONfl'"
	);
print(@sysargs);
system(@sysargs);