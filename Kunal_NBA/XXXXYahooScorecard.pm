#!/usr/bin/perl
#####################################################################################
#                            parseYahooScorecard.pm
#
# Parses Yahoo NBA Output file and collects real time game stats
#
#####################################################################################
package YahooScorecard;
use strict;
use warnings;
use Exporter;
#################################################################
our @ISA       = qw( Exporter );
our @EXPORT    = qw( parseYahooScorecard );
#################################################################

#use Date::Calc qw(:all);
use File::Basename;
use Cwd qw(abs_path);
use DTUtil;

#########################
#-- Constants
#########################
use constant false       => 0;                # True
use constant true        => 1;                # False



#################################################
#-- Extract Game "Date"
#################################################
sub getGameDate(@)
{
    my $moduleName = "getGameDate";

    # </td></tr><tr class="date"><th colspan="5" scope="row"><h3>Tuesday, March 29</h3></th></tr><tr class="game  link" data-url="/nba/chicago-bulls-indiana-pacers-2016032911/" data-index="1" data-gid="nba.g.2016032911">            <td class="summary">
    my ($dateline) = @_;
    printDebug 2, "$moduleName", "   Date Line: $dateline";
    my $part = $dateline =~ s/.*<h3>//gr;
    printDebug 2, "$moduleName", "               Part 1: $part";
    $part =~ s/<\/h3>(.*)//;
    printDebug 2, "$moduleName", "               *********************** Part 2: $part";

    return $part;
}

#################################################
#-- Extract Game "Date Live"
#################################################
sub getGameDateLive(@)
{
    my $moduleName = "getGameDateLive";

    # <tr class="date live"><th colspan="5"><h3>LIVE</h3></th></tr><tr class="game live link" data-url="/nba/houston-rockets-cleveland-cavaliers-2016032905/" data-index="0" data-gid="nba.g.2016032905">            <td class="summary">
    my ($dateline) = @_;
    printDebug 2, "$moduleName", "   Date Line: $dateline";
    my $part = $dateline =~ s/.*<h3>//gr;
    printDebug 2, "$moduleName", "               Part 1: $part";
    $part =~ s/<\/h3>(.*)//;
    printDebug 2, "$moduleName", "               *********************** Part 2: $part";

    return $part;
}

#################################################
#-- Extract Game "Time Left" in Live Game
#################################################
sub getGameTimeLeft(@)
{
    my $moduleName = "getGameTimeLeft";

    # e.g. <span class="time">11:46 4th</span> <span class="tv">TNT, FSOH</span>
    my ($dateline) = @_;
    printDebug 2, "$moduleName", "   Date Line: $dateline";
    my $part = $dateline =~ s/.*time">//gr;
    printDebug 2, "$moduleName", "               Part 1: $part";
    $part =~ s/<\/span>(.*)//;
    printDebug 2, "$moduleName", "               *********************** Part 2: $part";

    return $part;
}

#################################################
#-- Extract Team
#################################################
sub _getTeam(@)
{
    my $moduleName = "_getTeam";

    # e.g. <span class="team  ">  <em>Houston</em> <span class="logo yom-logo-nba large hou nba.t.10"></span></span>  
    my ($teamline) = @_;
    printDebug 2, "$moduleName", "   Team Line: $teamline";
    my $part = $teamline =~ s/.*<em>//gr;
    printDebug 2, "$moduleName", "               Part 1: $part";
    $part =~ s/<\/em>(.*)//;
    printDebug 2, "$moduleName", "               *********************** Part 2: $part";

    return $part;
}

#################################################
#-- Extract "Away" Team
#################################################
sub getAwayTeam(@)
{
#    return _getTeam(@_);
    my $a = 1;
}

#################################################
#-- Extract "Home" Team
#################################################
sub getHomeTeam(@)
{
#    return _getTeam(@_);
    my $a = 1;
}


#################################################
#-- Parse HTML and extract data points
#################################################
sub parseYahooScorecard(@)
{
    my $moduleName = "parseYahooScorecard";
    printDebug 2, "$moduleName", "Testing...";
    _parseYahooScorecard(@_);
}

sub _parseYahooScorecard(@)
{
    my ($HTML_FILE) = @_;
    my $line = "";
    my $row = 0;
    my $moduleName = "_parseYahooScorecard";

    open HTML_FL, "<$HTML_FILE" or die "**ERROR**: Can't open file $HTML_FILE." ;

    printDebug 2, "$moduleName", "Testing 1...";

    my $i = 1;
    my $S_UNKNOWN                          = -1;
    my $S_SCOREBOARD_THEAD_START           = $i++;
    my $S_SCOREBOARD_GAMES_NOT_STARTED_YET = $i++;
    my $S_SCOREBOARD_THEAD_END             = $i++;
    my $S_SCOREBOARD_TBODY_START           = $i++;
    my $S_SCOREBOARD_DATE                  = $i++;
    my $S_SCOREBOARD_DATELIVE              = $i++;
    my $S_SCOREBOARD_TIMELEFT              = $i++;
    my $S_SCOREBOARD_AWAY                  = $i++;
    my $S_SCOREBOARD_AWAY_TEAM             = $i++;
    my $S_SCOREBOARD_SCORE_START           = $i++;
    my $S_SCOREBOARD_SCORE_IFGAME          = $i++;
    my $S_SCOREBOARD_HOME                  = $i++;
    my $S_SCOREBOARD_HOME_TEAM             = $i++;
    my $S_SCOREBOARD_TBODY_END             = $i++;

    my $myLastState                        = $S_UNKNOWN ;

    ###
    #  Read HTML File
    #
    # Sample Data to parse:
    #  <thead>
    #    <tr>
    #      <th>Home</th>
    #      <th>Score</th>
    #      <th>Away</th>
    #    </tr>
    #  </thead>
    #  <tbody>
    #    <tr class="date live"><th colspan="5"><h3>LIVE</h3></th></tr><tr class="game live link" data-url="/nba/houston-rockets-cleveland-cavaliers-2016032905/ " data-index="0" data-gid="nba.g.2016032905">            <td class="summary">
    #         <span class="time">11:46 4th</span> <span class="tv">TNT, FSOH</span>
    #        <br/>
    #    </td>
    #    <td class="away">
    #      <span class="state">
    #      </span>
    #            <span class="team  ">  <em>Houston</em> <span class="logo yom-logo-nba large hou nba.t.10"></span></span>
    #    </td>
    #    <td class="score">
    #      <h4 class="vs"><a href="/nba/houston-rockets-cleveland-cavaliers-2016032905/" data-ylk="lt:s;sec:mod-sch;slk:game;itc:0;ltxt:;tar:sports.yahoo.com;" ><span class="away ">71</span> - <span class="home ">84</span></a></h4>
    #    </td>
    #    <td class="home">
    #             <span class="team  "><span class="logo yom-logo-nba large cle nba.t.5"></span>  <em>Cleveland</em> </span>
    #    </td>        <td class="details">
    #</td></tr><tr class="date"><th colspan="5" scope="row"><h3>Tuesday, March 29</h3></th></tr><tr class="game  link" data-url="/nba/chicago-bulls-indiana-pacers-2016032911/" data-index="1" data-gid="nba.g.2016032911">            <td class="summary">
    #        <br/>
    #    </td>
    #    <td class="away">
    #      <span class="state">
    ###
    my $cnt = 0;
    my $stat_counter = -99;
    my $value = "";

    my $games_date;
    my $games_date_live;
    my $game_away_team;
    my $game_score;
    my $game_home_team;

    my $G_UNKNOWN = -1;
    my $G_DATE_YES = 1;
    my $G_DATE_LIVE_YES = 2;
    my $G_GAP_YES = 3;
    my $G_STATE = $G_UNKNOWN;

    while ( $line = <HTML_FL> ) {
        chop($line);
        #printDebug 2, "$moduleName", "Line: $line";
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
        $_ = $line;
        $cnt = $cnt + 1 ;
        SWITCH: {
            /<thead>/ && do {
                   printDebug 2, "$moduleName", "  FOUND Team Head(#$cnt): $line";
                   $myLastState = $S_SCOREBOARD_THEAD_START;
                   last SWITCH ;
                };
            /<\/thead>/ && do {
                   if ( $myLastState == $S_SCOREBOARD_THEAD_START)  {  
                       printDebug 2, "$moduleName", "   FOUND End of Team Head(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_THEAD_END;
                   }
                   last SWITCH ;
                };
            /<tbody>/ && do {
                   if ( $myLastState == $S_SCOREBOARD_THEAD_END)  {  
                       printDebug 2, "$moduleName", "   FOUND Start of TBODY(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_TBODY_START;
                   }
                   last SWITCH ;
                };
                 
            /<tr class="gap">/ && do {
                   # Games NOT STARTED YET
                   if ( $myLastState == $S_SCOREBOARD_TBODY_START)  {  
                       my $G_STATE = $G_GAP_YES;
                       printDebug 2, "$moduleName", "   FOUND Game Time(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_GAMES_NOT_STARTED_YET;
                   }
                   last SWITCH ;
                };
            /<tr class="date">/ && do {
                   # FINISHED GAMES
                   if ( $myLastState != $S_UNKNOWN )  {  
                       printDebug 2, "$moduleName", "          FOUND Game Date(#$cnt): $line";
                       my $G_STATE = $G_DATE_YES;
                       $games_date = getGameDate($line);
                       $myLastState = $S_SCOREBOARD_DATE;
                   }
                   last SWITCH ;
                };
            /<tr class="date live">/ && do {
                   # LIVE GAMES
                   if ( $myLastState == $S_SCOREBOARD_TBODY_START )  {  
                       printDebug 2, "$moduleName", "   FOUND Game Time(#$cnt): $line";
                       my $G_STATE = $G_DATE_LIVE_YES;
                       $games_date_live = getGameDateLive($line);
                       $myLastState = $S_SCOREBOARD_DATELIVE;
                   }
                   last SWITCH ;
                };
            /<span class="time">/ && do {
                   # Time Left in LIVE GAMES
                   if ( $myLastState == $S_SCOREBOARD_DATELIVE )  {  
                       printDebug 2, "$moduleName", "   FOUND Game Time(#$cnt): $line";
                       my $game_time_left = getGameTimeLeft($line);
                   }
                   last SWITCH ;
                };
            /<\/tbody>/ && do {
                   if ( $myLastState == $S_SCOREBOARD_TBODY_START )  {  
                       printDebug 2, "$moduleName", "FOUND End of TBODY(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_TBODY_END;
                   }
                   last SWITCH ;
                };
            /<td class="away">/ && do {
                   if ( $myLastState == $S_SCOREBOARD_TBODY_START || $myLastState == $S_SCOREBOARD_HOME )  {  
                       printDebug 2, "$moduleName", "   FOUND Away(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_AWAY;
                   }
                   last SWITCH ;
                };
            /<span class="team  ">/ && do {
                   $game_away_team = getAwayTeam($line);
                   if ( $myLastState == $S_SCOREBOARD_TBODY_START || $myLastState == $S_SCOREBOARD_HOME )  {  
                       printDebug 2, "$moduleName", "   FOUND Away(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_AWAY;
                   }
                   last SWITCH ;
                };
            /<span class="team(.*)">/ && do {
                   if ( $myLastState == $S_SCOREBOARD_AWAY ) {
                       printDebug 2, "$moduleName", "   FOUND Away Team(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_AWAY_TEAM;
                   } elsif ( $myLastState == $S_SCOREBOARD_HOME ) {
                       printDebug 2, "$moduleName", "   FOUND Home Team(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_HOME_TEAM;
                   }
                   last SWITCH ;
                };
            /<td class="score">/ && do {
                   if ( $myLastState == $S_SCOREBOARD_AWAY_TEAM )  {  
                       printDebug 2, "$moduleName", "   FOUND Start of Score(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_SCORE_START;
                   }
                   last SWITCH ;
                };
            /<h4 class="vs"><a href="/ && do {
                   if ( $myLastState == $S_SCOREBOARD_SCORE_START )  {  
                       printDebug 2, "$moduleName", "   FOUND Game Status(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_SCORE_IFGAME;
                   }
                   last SWITCH ;
                };
            /<td class="home">/ && do {
                   if ( $myLastState == $S_SCOREBOARD_SCORE_IFGAME )  {  
                       printDebug 2, "$moduleName", "   FOUND Home(#$cnt): $line";
                       $myLastState = $S_SCOREBOARD_HOME;
                   }
                   last SWITCH ;
                };
        }
    }
}
1;
