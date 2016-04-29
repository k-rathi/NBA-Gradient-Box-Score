use strict;
use warnings;
use CGI qw(:standard);
use Cwd;
use File::Basename;


my $date = param('date');

chdir("Kunal_NBA");
print header();
print "$date \n";

my $outJSONfl = "scoreboard/$date.json";
my $url = 'http://stats.nba.com/stats/scoreboardv2/?GameDate=$date&LeagueID=00&DayOffset=00';
my @sysargs = (
	"'/usr/bin/curl' '-H' 'Host: stats.nba.com' '-H' 'Referer: stats.nba.com/scores/' '-H' 'User-Agent:(Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36' 'http://stats.nba.com/stats/scoreboardv2/?GameDate=$date&LeagueID=00&DayOffset=00' '-o' '$outJSONfl'"
	);
print(@sysargs);
system(@sysargs);