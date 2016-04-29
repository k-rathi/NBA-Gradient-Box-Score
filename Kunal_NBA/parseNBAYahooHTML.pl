#!/usr/bin/perl
#####################################################################################
#                            parseNBAYahooHTML.pl
#
# Parses Yahoo NBA Output file and collects real time game stats
#
#####################################################################################
use strict;

#####################################################################################
#                                   Main Package
#####################################################################################
package Main;
use File::Basename;
use Cwd qw(abs_path);
use DTUtil;
use YahooScorecard;
use NBAGameInfo;

my $moduleName = "Main";

#########################
#-- Program variables
#########################
my $PROGNAME             = basename($0);
my $FULLPROG             = abs_path($0);
my $PROGDIR              = dirname ($FULLPROG);
our $CURTIMESTAMP        = `date +"%Y-%m-%d @ %H:%M:%S"`;
chop ( $CURTIMESTAMP );

#########################
#-- Constants
#########################
use constant false       => 0;                # True
use constant true        => 1;                # False

my $DBGLVL = 0;

#################################################
#-- Print Usage
#################################################
sub printUsage() {
print <<EOF ;
********************************************************************************************************
                                        $PROGNAME
********************************************************************************************************

Synopsis:
    Parses Yahoo NBA Live game page, and extracts player related statistics

Usage:
    $PROGNAME -gamedate [YYYYMMDD] -T1 [TEAM_1] -T2 [TEAM_2] -outJSONfile [JSON_OUTPUT_FILE]
      OR
    $PROGNAME -nbaGameURL [NBAGameURL] -outJSONfile [JSON_OUTPUT_FILE]
    
Notes:
    -gamedate [YYYYMMDD]
              Game Date in [YYYYMMDD] format, such as, 20160405 for April 5, 2016

    -T1 [TEAM_1]               <<< Home
    -T2 [TEAM_2]               <<< Away
              Teams in 3-letter notation, such as GSW = Golden State Warriors, BOS = Boston Celtics, LAC = LA Clippers.
              T1/T2 respectively denote HOME and AWAY Teams

    -nbaGameURL [NBAGameURL]:
              Provide NBA.com Game URL

    -outJSONfile [JSON_OUTPUT_FILE]
              JSON Output file containing game info for each team. 

    $PROGNAME -help

EOF
}

#################################################
#-- Parse parameters
#################################################
my $argCnt = $#ARGV + 1;
if ( $argCnt == 0 ) {
    printUsage();
    exit 0;
}
my $cnt = 0;
my $newArgi = 0;

my $IN_HTML_FILE = "";
my $OUT_STATS_FILE = "";

my $DO_UNKNOWN = "unknown";
my $DO_ONE_GAMEINFO = "nbaGameInfo";
my $DO_SCORECARD = "nbaScorecard";
my $ACTION = $DO_ONE_GAMEINFO;       # hard-coded for now

my $GAME_DATE_YYYYMMDD = "";
my $TEAM_1 = "";
my $TEAM_2 = "";
my $JSON_OUTPUT_FILE = "";
my $NBA_GAME_URL = "";

while($cnt < $argCnt) {
    $_ = $ARGV[$cnt] ;
    SWITCH: {
        /^-gamedate$/ && do {
               $cnt = $cnt + 1 ;
               $GAME_DATE_YYYYMMDD = $ARGV[$cnt];
               last SWITCH ;
            };
        #/^-action$/ && do {
        #       $cnt = $cnt + 1 ;
        #       $ACTION = $ARGV[$cnt];
        #       last SWITCH ;
        #    };
        /^-T1$/ && do {
               $cnt = $cnt + 1 ;
               $TEAM_1 = $ARGV[$cnt];
               last SWITCH ;
            };
        /^-T2$/ && do {
               $cnt = $cnt + 1 ;
               $TEAM_2 = $ARGV[$cnt];
               last SWITCH ;
            };
        /^-nbaGameURL$/ && do {
               $cnt = $cnt + 1 ;
               $NBA_GAME_URL = $ARGV[$cnt];
               last SWITCH ;
            };
        /^-outJSONfile$/ && do {
               $cnt = $cnt + 1 ;
               $JSON_OUTPUT_FILE = $ARGV[$cnt];
               last SWITCH ;
            };
        /^-debug$/ && do {
               $cnt = $cnt + 1 ;
               $DBGLVL = $ARGV[$cnt];
               if ( $DBGLVL > 1 ) { $DBGLVL = 2; } else { $DBGLVL = 1; }
               setDebugLevel $DBGLVL ;
               last SWITCH ;
            };
        /^-help$/ && do {
               $cnt = $cnt + 1 ;
               printUsage();
               exit 0;
               last SWITCH ;
            };
        /^-/ && do {
               printUsage();
               printErrorMsg "$moduleName", "Incorrect option = $_ . Exiting...";
               exit 1;
               last SWITCH ;
            };
    }
    $cnt = $cnt + 1 ;
}

#################################################
#-- Print parameters values
#################################################
sub printParams() {
    my $moduleName = "printParams";
    printMsg $moduleName, "\n".
          "***********************************************************************************"."\n".
          "*                                 PARAMETER VALUES                                 "."\n".
          "*                                                                                  "."\n".
          "* Program                     = $PROGNAME                                          "."\n".
          "* Program with Absolute Path  = $FULLPROG                                          "."\n".
          "* Team 1 (Home)               = $TEAM_1                                            "."\n".
          "* Team 2 (Away)               = $TEAM_2                                            "."\n".
          "* Game Date                   = $GAME_DATE_YYYYMMDD                                "."\n".
          "* NBA Game URL                = $NBA_GAME_URL                                      "."\n".
          "* JSON Output File            = $JSON_OUTPUT_FILE                                  "."\n".
          "*                                                                                  "."\n".
          "* Current Timestamp           = $CURTIMESTAMP                                      "."\n".
          "*                                                                                  "."\n".
          "***********************************************************************************"."\n".
    "\n";
}

#################################################
#-- Check/Verify parameters
#################################################
sub checkParams() {
    my $moduleName = "checkParams" ;


    if ( "$ACTION" && $ACTION ne 'nbaGameInfo' ) {
        printErrorMsg "$moduleName", "Action='$ACTION' is NOT valid. Exiting...";
        exit 1;
    }

    if ( ! "$NBA_GAME_URL" ) {
        if ( ! ("$TEAM_1" && length($TEAM_1) == 3) ) {
            printErrorMsg "$moduleName", "Team_1='$TEAM_1' is MISSING OR it's length is different from 3 character long. Exiting...";
            exit 1;
        }

        if ( ! ("$TEAM_2" && length($TEAM_2) == 3) ) {
            printErrorMsg "$moduleName", "Team_2='$TEAM_2' is MISSING OR it's length is NOT exactly 3 character long. Exiting...";
            exit 1;
        }

        if ( ! ("$GAME_DATE_YYYYMMDD" && length($GAME_DATE_YYYYMMDD) == 8) ) {
            printErrorMsg "$moduleName", "Game Date='$GAME_DATE_YYYYMMDD' is MISSING OR it's length is NOT exactly 8 character long - must be in YYYYMMDD format. Exiting...";
            exit 1;
        }
    }

    if ( ! ("$JSON_OUTPUT_FILE") ) {
        printErrorMsg "$moduleName", "JSON Output File='$JSON_OUTPUT_FILE' param is missing. Exiting...";
        exit 1;
    }
}

#printParams ;
checkParams ;

$_ = "$ACTION";

SWITCH: {
    /^$DO_SCORECARD/ && do {
print "Calling parseYahooScorecard....$IN_HTML_FILE\n";
       parseYahooScorecard $IN_HTML_FILE;
       last SWITCH ;
    };
    /^$DO_ONE_GAMEINFO/ && do {
       if ( "$NBA_GAME_URL" ) {
           parseNBAComOneGameInfoURL($NBA_GAME_URL, $JSON_OUTPUT_FILE);
       } else {
           parseNBAComOneGameInfoParams($GAME_DATE_YYYYMMDD, $TEAM_1, $TEAM_2, $JSON_OUTPUT_FILE);
       }
       last SWITCH ;
    };
    /^$DO_UNKNOWN/ && do {
       printUsage();
       last SWITCH ;
    };
    /^*/ && do {
       printUsage();
       exit 1;
       last SWITCH ;
    };
}
