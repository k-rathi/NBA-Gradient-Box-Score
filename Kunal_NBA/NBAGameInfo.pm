#!/usr/bin/perl
#####################################################################################
#                           NBAGameInfo.pm
#
# Parses Yahoo NBA Output file and collects real time game stats
#
#####################################################################################
package NBAGameInfo;
use strict;
use warnings;
use Exporter;
#################################################################
our @ISA       = qw( Exporter );
our @EXPORT    = qw( parseNBAComOneGameInfoParams parseNBAComOneGameInfoURL );
#################################################################

use File::Basename;
use Cwd qw(abs_path);
use DTUtil;
use Game;
use Team;
use PlayerStat;

#########################
#-- Constants
#########################
use constant false       => 0;                # True
use constant true        => 1;                # False

#########################
#-- Runtime variables
#########################
my @TEAM_1_player_stat_array;                 # Array of each player stats object
my @TEAM_2_player_stat_array;                 # Array of each player stats object

#################################################
#-- Extract player name
#################################################
sub getPlayerName(@)
{
    my $moduleName = "parsePlayerName";

    # <td id="nbaGIBoxNme" class="b"><a href="/playerfile/james_michael_mcadoo/index.html">J. McAdoo</a></td>
    my ($PlayerLine) = @_;
    #printDebug 2, "$moduleName", "Orig: $PlayerLine";
    my $part = $PlayerLine =~ s/.*index.html">//gr;
    if ( "$part" eq "$PlayerLine") {
         #<td id="nbaGIBoxNme" class="b">A. Drummond</td>
         $part = $PlayerLine =~ s/.*?<td.*?\>//gr;
    }
    #printDebug 2, "$moduleName", "part 1: $part";
    $part =~ s/<(.*)//;
    #printDebug 2, "$moduleName", "part 2: $part";

    return $part;
}

#################################################
#-- Extract Team KEY from THEAD
#################################################
sub getTeamKey(@)
{
    my $moduleName = "getTeamKey";

    # e.g. <thead class="nbaGITimberwolves">
    my ($THeadLine) = @_;
    printDebug 2, "$moduleName", "   THEAD CLASS: $THeadLine";
    my $part = $THeadLine =~ s/.*class="nbaGI//gr;
    printDebug 2, "$moduleName", "Team Key Part 1: $part";
    $part =~ s/"(.*)//;
    printDebug 2, "$moduleName", "Team Key Part 2: $part";

    return $part;
}

#################################################
#-- Extract Team Name with Record
#################################################
sub getTeamNameRecord(@)
{
    my $moduleName = "getTeamNameRecord";

    # e.g.     <th colspan="17">Golden State Warriors (63-7)</th>
    my ($TH_Name) = @_;
    printDebug 2, "$moduleName", "   THEAD Team name/Record: $TH_Name";
    my $part = $TH_Name =~ s/.*<th colspan="17">//gr;
    printDebug 2, "$moduleName", "Team Name Part 1: $part";
    $part =~ s/<(.*)//;
    printDebug 2, "$moduleName", "Team Name Part 2: $part";
    my $name = $part =~ s/ \((.*)//gr;
    printDebug 2, "$moduleName", "Team Name: $name";
    my $record = $part =~ s/(.*)\(//gr;
    printDebug 2, "$moduleName", "Team Record Part 1: $record";
    $record =~ s/\)(.*)$//;
    printDebug 2, "$moduleName", "Team Record: $record";

    return ($name, $record);
}

#################################################
#-- Extract player position (G/F/C)
#################################################
sub getPlayerPosition(@)
{
    my $moduleName = "parsePlayerPosition";

    # <td class="nbaGIPosition">F</td>
    my ($PositionLine) = @_;
    #printDebug 2, "$moduleName", "Orig: $PositionLine";
    my $part = $PositionLine =~ s/.*nbaGIPosition">//gr;
    #printDebug 2, "$moduleName", "part 1: $part";
    $part =~ s/<(.*)//;
    #printDebug 2, "$moduleName", "part 2: $part";

    if ( ! (($part eq "G") || ($part eq "F") || ($part eq "C")) ) {
        $part = "X";
    }

    return $part;
}

sub removeNewLineChars(@)
{
    my ($inputString) = @_;
    chomp($inputString);
    $inputString =~ s/\r//;
     
    return $inputString;
}

#################################################
#-- Extract Team & Player list (comma-separated)
#   e.g. <li><span class="nbaGIbold">Rockets:</span> Dekker, Harrell
#################################################
sub getTeam_n_PlayerListString(@)
{
    my $moduleName = "getTeam_n_PlayerListString";

    # <td class="nbaGIPosition">F</td>
    my ($inputString) = @_;
    printDebug 2, "$moduleName", "Orig: $inputString";
    my $part = $inputString =~ s/.*nbaGIbold">//gr;
    printDebug 2, "$moduleName", "part 1: $part";
    my $team = $part =~ s/:(.*)//gr;
    printDebug 2, "$moduleName", "team: $team";
    my $players = $part =~ s/(.*)<\/span> //gr;
    printDebug 2, "$moduleName", "players = $players";
    $team = removeNewLineChars($team);
    $players = removeNewLineChars($players);

    return ($team, $players) ;
}

#################################################
#-- Get Value embedded between TD tag
#################################################
sub getTDValue(@)
{
    my ($TD_LINE) = @_;
    my $val = $TD_LINE =~ s/.*<td>//gr;
    $val =~ s/<\/td>(.*)//;
    return $val;
}

#################################################
#-- Get Totals embedded nbaGIScrTot tag
#   e.g.      <td class="nbaGIScrTot">240</td>
#################################################
sub getScrTotalValue(@)
{
    my ($TOT_LINE) = @_;
    my $val = $TOT_LINE =~ s/.*"nbaGIScrTot">//gr;
    $val =~ s/<\/td>(.*)//;
    return $val;
}


#################################################
#-- Split and return made-attempted into two parts
#################################################
sub getMadeAttempted(@)
{
    my ($made_attempted) = @_;
    my ($m, $a) = ("0", "0");
    if ( $made_attempted =~ /-/ ) {       # ignore commented records
        ($m, $a) = split('-', $made_attempted);
    }
#    if ( ! "$m" ) {
#        $m = "0";
#    }
#    if ( ! "$a" ) {
#        $a = "0";
#    }
    return ($m, $a);
}

#################################################
#-- Plus or Minus
#################################################
sub getPlusMinus(@)
{
    my ($str) = @_;
    my $v = getTDValue($str);
    if ( "$v" eq "-" || "$v" eq "+" ) {
        $v = "0";
    }
    return $v;
}

#################################################
#-- Print Array Player stats objects
#################################################
#sub printPlayerStatArray()
#{
#    my $moduleName = "printPlayerStatArray";
#    printf "Total Players: %d\n", scalar(@curTeam_player_stat_array);
#    my $c;
#    foreach $c (@curTeam_player_stat_array)
#    {
#         #$p = bless($c, PlayerStat);
#         $c->printOnePlayerStat();
#    }
#}

my $gi_game;
my $gi_team_1;
my $gi_team_2;
my $tmp_team;

#################################################
#-- Parse HTML and extract data points
#################################################
sub parseNBAComOneGameInfoParams(@)
{
    my $moduleName = "parseNBAComOneGameInfo";

    my ($YYYYMMDD, $TEAM_1_STR, $TEAM_2_STR, $outJSONFile) = @_;

    $gi_game = new Game;
    $gi_team_1 = new Team;
    $gi_team_2 = new Team;

    my $tmpCurlHTMLFile = "/tmp/curlOuput_$$.html";

    printDebug 2, "$moduleName", "Invoking executeCurlCommand...";
    executeCurlCommandParams($YYYYMMDD, $TEAM_1_STR, $TEAM_2_STR, $tmpCurlHTMLFile);

    _parseNBAComOneGameInfo("$tmpCurlHTMLFile");
    $gi_game->printGameJSONFile($outJSONFile);
}

#################################################
#-- Parse HTML and extract data points
#################################################
sub parseNBAComOneGameInfoURL(@)
{
    my $moduleName = "parseNBAComOneGameInfoURL";

    my ($GameURL, $outJSONFile) = @_;

    $gi_game = new Game;
    $gi_team_1 = new Team;
    $gi_team_2 = new Team;

    my $tmpCurlHTMLFile = "/tmp/curlOuput_$$.html";

    printDebug 2, "$moduleName", "Invoking executeCurlCommandURL...";
    executeCurlCommandURL($GameURL, $tmpCurlHTMLFile);

    _parseNBAComOneGameInfo("$tmpCurlHTMLFile");
    $gi_game->printGameJSONFile($outJSONFile);
}

#################################################
#-- Parse GameInfo HTML
#################################################
sub _parseNBAComOneGameInfo(@)
{
    my ($HTML_FILE) = @_;
    my $line = "";
    my $row = 0;
    my $moduleName = "_parseNBAComOneGameInfo";

    open HTML_FL, "<$HTML_FILE" or die "**ERROR**: Can't open file Input HTML File = $HTML_FILE." ;

    printDebug 2, "$moduleName", "Testing 1...";

    my $i=0;
    my $S_UNKNOWN                     = -1;
    my $S_TEAM_THEAD                  = $i++;
    my $S_TEAM_NAME                   = $i++;
    my $S_ODD_EVEN                    = $i++;
    my $S_GIBOXNME                    = $i++;
    my $S_GIPOSITION                  = $i++;
    my $S_GITOTAL                     = $i++;

    # Related to Inactive Players
    my $S_GISTATUS                    = $i++;;
    my $S_GIPLAYERSTATES              = $i++;;
    my $S_GIINACTIVE                  = $i++;;
    my $S_GIINACTIVE_PLAYERSTATUS     = $i++;;

    my $myLastState    = $S_UNKNOWN ;

    ###
    #  Read HTML File
    #
    # Sample Data to parse:
    #    <td id="nbaGIBoxNme" class="b"><a href="/playerfile/james_michael_mcadoo/index.html">J. McAdoo</a></td>
    #    <td class="nbaGIPosition">F</td>
    #    <td>17:34</td>
    #    <td>3-8</td>
    #    <td>0-0</td>
    #    <td>1-2</td>
    #    <td>+3</td>
    #    <td>4</td>
    #    <td>2</td>
    #    <td>6</td>
    #    <td>0</td>
    #    <td>2</td>
    #    <td>1</td>
    #    <td>0</td>
    #    <td>0</td>
    #    <td>2</td>
    #    <td>7</td>
    ###
    my $cnt = 0;
    my $stat_counter = -99;
    my $value = "";

    my $NEXT_TEAM = 0;

    $gi_game->{_team1} = $gi_team_1;
    $gi_game->{_team2} = $gi_team_2;

    my  $curPlayer;
    my  $totalPlayer;
    while ( $line = <HTML_FL> ) {
        chop($line);
        printDebug 2, "$moduleName", "Line: $line";
        #####
        # PlayerStat object elements
        #  _min_sec       => shift,
        #  _fg_m          => shift,
        #  _fg_a          => shift,
        #  _pt3_m         => shift,
        #  _pt3_a         => shift,
        #  _ft_m          => shift,
        #  _ft_a          => shift,
        #  _plus_minus    => shift,
        #  _reb_off       => shift,
        #  _reb_def       => shift,
        #  _reb_tot       => shift,
        #  _assits        => shift,
        #  _pfouls        => shift,
        #  _steals        => shift,
        #  _turnovers     => shift,
        #  _block_shots   => shift,
        #  _block_against => shift,
        #  _points        => shift,
        #####
        if ( $myLastState == $S_GIPOSITION )  {
            if ( $stat_counter == 0 ) {
                $value = getTDValue($line);
                $curPlayer->{_min_sec} = $value;
                printDebug 2, "$moduleName", "   MIN_SEC: $value";
            } elsif ( $stat_counter == 1 ) {
                $value = getTDValue($line);
                my ($m, $a) = getMadeAttempted($value);
                $curPlayer->{_fg_m} = $m;
                $curPlayer->{_fg_a} = $a;
                printDebug 2, "$moduleName", "   FGM_A: $value";
            } elsif ( $stat_counter == 2 ) {
                $value = getTDValue($line);
                my ($m, $a) = getMadeAttempted($value);
                $curPlayer->{_pt3_m} = $m;
                $curPlayer->{_pt3_a} = $a;
                printDebug 2, "$moduleName", "   3PTM_A: $value";
            } elsif ( $stat_counter == 3 ) {
                $value = getTDValue($line);
                my ($m, $a) = getMadeAttempted($value);
                $curPlayer->{_ft_m} = $m;
                $curPlayer->{_ft_a} = $a;
                printDebug 2, "$moduleName", "   FTM_A: $value";
            } elsif ( $stat_counter == 4 ) {
                $value = getPlusMinus($line);
                $curPlayer->{_plus_minus} = $value;
                printDebug 2, "$moduleName", "   +-: $value";
            } elsif ( $stat_counter == 5 ) {
                $value = getTDValue($line);
                $curPlayer->{_reb_off} = $value;
                printDebug 2, "$moduleName", "   REB_OFF: $value";
            } elsif ( $stat_counter == 6 ) {
                $value = getTDValue($line);
                $curPlayer->{_reb_def} = $value;
                printDebug 2, "$moduleName", "   REB_DEF: $value";
            } elsif ( $stat_counter == 7 ) {
                $value = getTDValue($line);
                $curPlayer->{_reb_tot} = $value;
                printDebug 2, "$moduleName", "   REB_TOT: $value";
            } elsif ( $stat_counter == 8 ) {
                $value = getTDValue($line);
                $curPlayer->{_assists} = $value;
                printDebug 2, "$moduleName", "   ASSISTS: $value";
            } elsif ( $stat_counter == 9 ) {
                $value = getTDValue($line);
                $curPlayer->{_pfouls} = $value;
                printDebug 2, "$moduleName", "   P Fouls: $value";
            } elsif ( $stat_counter == 10 ) {
                $value = getTDValue($line);
                $curPlayer->{_steals} = $value;
                printDebug 2, "$moduleName", "   Steals: $value";
            } elsif ( $stat_counter == 11 ) {
                $value = getTDValue($line);
                $curPlayer->{_turnovers} = $value;
                printDebug 2, "$moduleName", "   Turnovers: $value";
            } elsif ( $stat_counter == 12 ) {
                $value = getTDValue($line);
                $curPlayer->{_block_shots} = $value;
                printDebug 2, "$moduleName", "   Blocks: $value";
            } elsif ( $stat_counter == 13 ) {
                $value = getTDValue($line);
                $curPlayer->{_block_against} = $value;
                printDebug 2, "$moduleName", "   Blocks_Agaist: $value";
            } elsif ( $stat_counter == 14 ) {
                $value = getTDValue($line);
                $curPlayer->{_points} = $value;
                printDebug 2, "$moduleName", "   Points: $value";
                if ( $NEXT_TEAM == 1 ) {
                    push(@TEAM_1_player_stat_array, $curPlayer);
                } else {
                    push(@TEAM_2_player_stat_array, $curPlayer);
                }
#printDebug 2, "$moduleName", "----------------------------- Pushing NEW Player into ARRAY:".$curPlayer;
#$curPlayer->printOnePlayerStat();
#$gi_game->printGame();
#printDebug 2, "$moduleName", "----------------------------- END Printing GAME";
                $myLastState = $S_UNKNOWN;
            }
            $stat_counter = $stat_counter + 1;
        } elsif ( $myLastState == $S_GITOTAL )  {
            if ( $stat_counter == 0 ) {
                # ignore
            } elsif ( $stat_counter == 1 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_min_sec} = $value;
                printDebug 2, "$moduleName", "   MIN_SEC: $value";
            } elsif ( $stat_counter == 2 ) {
                $value = getScrTotalValue($line);
                my ($m, $a) = getMadeAttempted($value);
                $totalPlayer->{_fg_m} = $m;
                $totalPlayer->{_fg_a} = $a;
                printDebug 2, "$moduleName", "   FGM_A: $value";
            } elsif ( $stat_counter == 3 ) {
                $value = getScrTotalValue($line);
                my ($m, $a) = getMadeAttempted($value);
                $totalPlayer->{_pt3_m} = $m;
                $totalPlayer->{_pt3_a} = $a;
                printDebug 2, "$moduleName", "   3PTM_A: $value";
            } elsif ( $stat_counter == 4 ) {
                $value = getScrTotalValue($line);
                my ($m, $a) = getMadeAttempted($value);
                $totalPlayer->{_ft_m} = $m;
                $totalPlayer->{_ft_a} = $a;
                printDebug 2, "$moduleName", "   FTM_A: $value";
            } elsif ( $stat_counter == 5 ) {
                # ignore
            } elsif ( $stat_counter == 6 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_reb_off} = $value;
                printDebug 2, "$moduleName", "   REB_OFF: $value";
            } elsif ( $stat_counter == 7 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_reb_def} = $value;
                printDebug 2, "$moduleName", "   REB_DEF: $value";
            } elsif ( $stat_counter == 8 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_reb_tot} = $value;
                printDebug 2, "$moduleName", "   REB_TOT: $value";
            } elsif ( $stat_counter == 9 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_assists} = $value;
                printDebug 2, "$moduleName", "   ASSISTS: $value";
            } elsif ( $stat_counter == 10 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_pfouls} = $value;
                printDebug 2, "$moduleName", "   P Fouls: $value";
            } elsif ( $stat_counter == 11 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_steals} = $value;
                printDebug 2, "$moduleName", "   Steals: $value";
            } elsif ( $stat_counter == 12 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_turnovers} = $value;
                printDebug 2, "$moduleName", "   Turnovers: $value";
            } elsif ( $stat_counter == 13 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_block_shots} = $value;
                printDebug 2, "$moduleName", "   Blocks: $value";
            } elsif ( $stat_counter == 14 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_block_against} = $value;
                printDebug 2, "$moduleName", "   Blocks_Agaist: $value";
            } elsif ( $stat_counter == 15 ) {
                $value = getScrTotalValue($line);
                $totalPlayer->{_points} = $value;
                printDebug 2, "$moduleName", "   Points: $value";
                if ( $NEXT_TEAM == 1 ) {
                    push(@TEAM_1_player_stat_array, $totalPlayer);
                } else {
                    push(@TEAM_2_player_stat_array, $totalPlayer);
                }
#printDebug 2, "$moduleName", "----------------------------- Pushing NEW Player into ARRAY:".$curPlayer;
#$curPlayer->printOnePlayerStat();
#$gi_game->printGame();
#printDebug 2, "$moduleName", "----------------------------- END Printing GAME";
                $myLastState = $S_UNKNOWN;
            }
            $stat_counter = $stat_counter + 1;
        } else {
            $_ = $line;
            SWITCH: {
                # <thead class="nbaGIWarriors">
                # <tr>
                #     <th colspan="17">Golden State Warriors (63-7)</th>
                # </tr>
                # </thead>
                (/^[ ]*<thead class=\"nbaGI/) && do {
                       $cnt = $cnt + 1 ;
                       printDebug 2, "$moduleName", "  FOUND Team Head: $line";
                       my $val = getTeamKey($line);
                       $NEXT_TEAM += 1;
                       if ( $NEXT_TEAM == 1 ) {
                           $tmp_team = $gi_team_1;
                           $tmp_team->{_playerArray} = \@TEAM_1_player_stat_array;
printDebug 2, "$moduleName", "----------------------------- FOUND Assigned Team_1";
                       } else {
                           $tmp_team = $gi_team_2;
                           $tmp_team->{_playerArray} = \@TEAM_2_player_stat_array;
printDebug 2, "$moduleName", "----------------------------- FOUND Assigned Team_2";
                       }
                       $tmp_team->{_name_key} = $val;
                       $myLastState = $S_TEAM_THEAD;   
                       last SWITCH ;
                    };
                (/<th colspan="17">(.*)<\/th>/) && do {
                       $cnt = $cnt + 1 ;
                       if ( $myLastState == $S_TEAM_THEAD )  {  
                           printDebug 2, "$moduleName", "   FOUND Team Name/Record: $line";
                           my ($val, $rec) = getTeamNameRecord($line);
                           $tmp_team->{_name} = $val;
                           $myLastState = $S_TEAM_NAME;
                       } else {
                           $myLastState = $S_UNKNOWN
                       }
                       last SWITCH ;
                    };
                (/<tr class="odd">/ || /<tr class="even">/) && do {
                       $cnt = $cnt + 1 ;
                       printDebug 2, "$moduleName", "   FOUND ODD/EVEN: $line";
                       $myLastState = $S_ODD_EVEN;
                       last SWITCH ;
                    };
                (/<td id="nbaGIBoxNme" class="nbaGIScrTot">Total<\/td>/) && do {
                       $stat_counter = 0;
                       $cnt = $cnt + 1 ;
                       if ( $myLastState == $S_ODD_EVEN )  {  
                           printDebug 2, "$moduleName", "   FOUND PLAYER NAME(nbaGIBoxNme): $line";
                           my $val = "Total";
                           $myLastState = $S_GITOTAL;   
                           printDebug 2, "$moduleName", "----------------------------- Creating TOTAL Player object = $val";
                           $totalPlayer = new PlayerStat;
                           $totalPlayer->{_name} = $val;
                       } else {
                           $myLastState = $S_UNKNOWN
                       }
                       last SWITCH ;
                    };
                (/<td id="nbaGIBoxNme"/) && do {
                       $cnt = $cnt + 1 ;
                       if ( $myLastState == $S_ODD_EVEN )  {  
                           printDebug 2, "$moduleName", "   FOUND PLAYER NAME(nbaGIBoxNme): $line";
                           my $val = getPlayerName($line);
                           $myLastState = $S_GIBOXNME;   
                           printDebug 2, "$moduleName", "----------------------------- Creating NEW Player object = $val";
                           $curPlayer = new PlayerStat;
                           $curPlayer->{_name} = $val;
                       } else {
                           $myLastState = $S_UNKNOWN
                       }
                       last SWITCH ;
                    };
                (/<td class="nbaGIPosition"/) && do {
                       $stat_counter = 0;
                       $cnt = $cnt + 1 ;
                       if ( $myLastState == $S_GIBOXNME )  {  
                           printDebug 2, "$moduleName", "   PLAYER POSITION(nbaGIPosition): $line";
                           my $val = getPlayerPosition($line);
                           $curPlayer->{_position} = $val;
                           $myLastState = $S_GIPOSITION;
                       } else {
                           $myLastState = $S_UNKNOWN
                       }
                       last SWITCH ;
                    };
                (/<div id="nbaGIStatus">/) && do {
                       $stat_counter = 0;
                       $cnt = $cnt + 1 ;
                       printDebug 2, "$moduleName", "   GIStatus: $line";
                       $myLastState = $S_GISTATUS;
                       last SWITCH ;
                    };
                (/<div id="nbaGIPlyrStates">/) && do {
                       $stat_counter = 0;
                       $cnt = $cnt + 1 ;
                       printDebug 2, "$moduleName", "   GIPlayerStates: $line";
                       if ( $myLastState == $S_GISTATUS )  {  
                           $myLastState = $S_GIPLAYERSTATES;
                           printDebug 2, "$moduleName", "   FOUND GIPlayerStates: $line";
                       }
                       last SWITCH ;
                    };
                (/<p>inactive<\/p>/) && do {
                       $stat_counter = 0;
                       $cnt = $cnt + 1 ;
                       printDebug 2, "$moduleName", "   InActive: $line";
                       if ( $myLastState == $S_GIPLAYERSTATES )  {  
                           $myLastState = $S_GIINACTIVE;
                           printDebug 2, "$moduleName", "   FOUND InActive: $line";
                       }
                       last SWITCH ;
                    };
                (/<ul id="nbaGIPlyrStatus">/) && do {
                       $stat_counter = 0;
                       $cnt = $cnt + 1 ;
                       printDebug 2, "$moduleName", "   Player Status: $line";
                       if ( $myLastState == $S_GIINACTIVE )  {  
                           $myLastState = $S_GIINACTIVE_PLAYERSTATUS;
                           printDebug 2, "$moduleName", "   FOUND InActive Player Status: $line";
                       }
                       last SWITCH ;
                    };
                (/<span class="nbaGIbold">/) && do {
                       $stat_counter = 0;
                       $cnt = $cnt + 1 ;
                       printDebug 2, "$moduleName", "   GI Bold Status: $line";
                       if ( $myLastState == $S_GIINACTIVE_PLAYERSTATUS )  {  
                           my ($t, $players) = getTeam_n_PlayerListString($line);
                           printDebug 2, "$moduleName", "   FOUND GI Inactive Team: $t, Players = $players";
                           if ( $gi_team_1->{_name_key} eq "$t" ) {
                               printDebug 2, "$moduleName", "   FOUND Inactive for Team-1: $t";
                               $gi_team_1->{_inactivePlayers} = "$players" ;
                           } elsif ( $gi_team_2->{_name_key} eq "$t" ) {
                               printDebug 2, "$moduleName", "   FOUND Inactive for Team-2: $t";
                               $gi_team_2->{_inactivePlayers} = "$players" ;
                           }
                       }
                       last SWITCH ;
                    };
            }
        }
        $cnt = $cnt + 1 ;
    }
    close HTML_FL;
    #$gi_game->printGameJSON();
}

my $CURL_PROG = "curl";
sub executeCurlCommandParams(@)
{
    my $moduleName = "executeCurlCommandParams";

    my ($yyyymmdd, $T1_3letter, $T2_3letter, $outHtmlFile) = @_;

    my $URL = "http://www.nba.com/games/${yyyymmdd}/${T1_3letter}${T2_3letter}/gameinfo.html?ls=iref:nba:scoreboard";
    executeCurlCommandURL($URL, $outHtmlFile);
    #printDebug 2, "$moduleName", "URL = $URL";
    #my @progargs = (
    #     "$CURL_PROG '$URL' > '$outHtmlFile'"
    # );
    # system(@progargs) ;
}

sub executeCurlCommandURL(@)
{
    my $moduleName = "executeCurlCommandURL";

    my ($URL, $outHtmlFile) = @_;
    printDebug 2, "$moduleName", "URL = $URL";
    my @progargs = (
         "$CURL_PROG '$URL' >'$outHtmlFile' 2>/dev/null"
     );
     system(@progargs) ;
}
1;
