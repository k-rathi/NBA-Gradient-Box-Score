#!/usr/bin/perl
#####################################################################################
#                            genCalendarDataHTML.pl
#
# Generates Calendar HTML based on calendar data stored in DATBASE or FILE.
#
# Input:
#    [FILE] Use FILE with pipe-delimited calendar data generated from
#           DTDWH.CI_Day_D or DTDWH.CI_Day2_D or table with same structure.
#
#    [DB]   Use following two tables:
#              DTDWH.CI_Day_D/DTDWH.CI_Day2_D (Calendar data)
#              DTOpt.Company                  (StartDOW)
#
# Output:
#    HTML files meant to show the calendar in Visual form, including
#        a) Yearly cadence
#        b) Quarterly Cadence
#        c) Monthly Cadence
#        d) Weekly Cadence
#        e) Errors & gaps
#        f) Summary
#
# Author: Ashok Rathi.
# Oct. 7, 2014
#
# Additional Features to be implemented:
#     TBD: Check for Duplicates
#
#     TBD: Check for contiguous Years, Weeks in year, Months in a year, Quarters in a year
#
#     TBD: Check if all weeks have 7 days, and month multiple of quarters, quarter multiple of months.
#
#     TBD: All dates within a week (day 1 - 7) must have the same Week/Month/Qtr/Year, and also
#          names are the same.
#
#     TBD: Name errors (Not clear)
#
#     TBD: Check for possible conditions
#          - YEAR Check:
#              - #Quarters > 4 in a Year
#              - #Months between 11-13 in a Year
#          - QUARTER Check:
#              - #Months between 3-4 in a Quarter
#              - #Weeks between 11-14 in a Quarter
#          - MONTH Check:
#              - #Weeks between 3-6 in a Month
#              - #Days between 21-35 in a Month
#          - WEEK Check:
#              - #Days exactly 7 in a Week
#
#     TBD: Use Customer provided file as an input (Major feature)
#
#     TBD: (Done) Validate StartDOW and cross-check with DTOpt.Company.StartDOW
#
#####################################################################################
use strict;

#####################################################################################
# Define CI_Day Object
#####################################################################################
package CIDay;
sub new {
    my($class)   = shift;
    my(%params) = @_;

    bless {
        "DAY_ID"                  => $params{ "DAY_ID"},
        "CAL_DATE"                => $params{ "CAL_DATE"},
        "CAL_WEEK"                => $params{ "CAL_WEEK"},
        "CAL_WEEK_ID"             => $params{ "CAL_WEEK_ID"},
        "CAL_MONTH"               => $params{ "CAL_MONTH"},
        "CAL_MONTH_ID"            => $params{ "CAL_MONTH_ID"},
        "CAL_YEAR"                => $params{ "CAL_YEAR"},
        "CAL_QTR"                 => $params{ "CAL_QTR"},
        "DAY_NAME"                => $params{ "DAY_NAME"},
        "DAY_OF_WEEK"             => $params{ "DAY_OF_WEEK"},
        "DAY_OF_MONTH"            => $params{ "DAY_OF_MONTH"},
        "DAY_OF_QUARTER"          => $params{ "DAY_OF_QUARTER"},
        "DAY_OF_YEAR"             => $params{ "DAY_OF_YEAR"},
        "DAY_AGO_DATE"            => $params{ "DAY_AGO_DATE"},
        "DAY_AGO_DATE_ID"         => $params{ "DAY_AGO_DATE_ID"},
        "WEEK_AGO_DATE"           => $params{ "WEEK_AGO_DATE"},
        "WEEK_AGO_DATE_ID"        => $params{ "WEEK_AGO_DATE_ID"},
        "MONTH_AGO_DATE"          => $params{ "MONTH_AGO_DATE"},
        "MONTH_AGO_DATE_ID"       => $params{ "MONTH_AGO_DATE_ID"},
        "QTR_AGO_DATE"            => $params{ "QTR_AGO_DATE"},
        "QTR_AGO_DATE_ID"         => $params{ "QTR_AGO_DATE_ID"},
        "YEAR_AGO_DATE"           => $params{ "YEAR_AGO_DATE"},
        "YEAR_AGO_DATE_ID"        => $params{ "YEAR_AGO_DATE_ID"},
        "CAL_WEEK_NAME"           => $params{ "CAL_WEEK_NAME"},
        "CAL_MONTH_NAME"          => $params{ "CAL_MONTH_NAME"},
        "CAL_QUARTER_NAME"        => $params{ "CAL_QUARTER_NAME"},
        "CAL_YEAR_NAME"           => $params{ "CAL_YEAR_NAME"},
        "CAL_QTR_ID"              => $params{ "CAL_QTR_ID"}
    }, $class;
}

#####################################################################################
# Define CI_Year Object (Though not being used yet)
#####################################################################################
package CI_Year;
sub new {
    my($class)   = shift;
    my(%params) = @_;

    bless {
        "BEG_DAY_ID"              => $params{ "BEG_DAY_ID"},
        "BEG_CAL_DATE"            => $params{ "BEG_CAL_DATE"},
        "BEG_DAY_OF_WEEK"         => $params{ "BEG_DAY_OF_WEEK"},
        "BEG_CAL_WEEK"            => $params{ "BEG_CAL_WEEK"},
        "BEG_CAL_MONTH"           => $params{ "BEG_CAL_MONTH"},
        "BEG_CAL_QTR"             => $params{ "BEG_CAL_QTR"},
        "BEG_CAL_YEAR"            => $params{ "BEG_CAL_YEAR"},

        "END_DAY_ID"              => $params{ "END_DAY_ID"},
        "END_CAL_DATE"            => $params{ "END_CAL_DATE"},
        "END_DAY_OF_WEEK"         => $params{ "END_DAY_OF_WEEK"},
        "END_CAL_WEEK"            => $params{ "END_CAL_WEEK"},
        "END_CAL_MONTH"           => $params{ "END_CAL_MONTH"},
        "END_CAL_QTR"             => $params{ "END_CAL_QTR"},
        "END_CAL_YEAR"            => $params{ "END_CAL_YEAR"}
    }, $class;
}

#####################################################################################
#                                   Main Package
#####################################################################################
package Main;
use Date::Calc qw(:all);
use File::Basename;
use Cwd qw(abs_path);
use DTUtil;

my $moduleName = "Main";

my %DAY_HMAP = (
    "1" => "Su",
    "2" => "Mo",
    "3" => "Tu",
    "4" => "We",
    "5" => "Th",
    "6" => "Fr",
    "7" => "Sa"
);

#########################
#-- Program variables
#########################
my $PROGNAME             = basename($0);
my $FULLPROG             = abs_path($0);
my $PROGDIR              = dirname ($FULLPROG);
our $CURTIMESTAMP        = `date +"%Y-%m-%d @ %H:%M:%S"`;
chop ( $CURTIMESTAMP );

#########################
#-- Files/Directories
#########################
my $CSV_CalendarFile;
my $StartDOWFile;
my $COMPANY_STARTDOW;
my $OUT_HTML             = "./index.html";
my $DBName;
my $DBUser;
my $DBPasswd;
my $DAYTABLE = "DTDWH.CI_Day_D";
my $CIDAY_EXPORT_SCRIPT = "ci_day_export.sh";
my $SHELL_PROG          = "bash";

#########################
#-- Constants
#########################
use constant false       => 0;                # True
use constant true        => 1;                # False
my $NDAYS_IN_WEEK = 7;

#########################
#-- Runtime variables
#########################
my @CID_ARRAY;                                # Array of records read from the CSV file
my $DBGLVL = 0;
my $CALENDAR_TYPE_STR = "Unknown Calendar";   # Populate Merchandising or Financial for header
my $CUSTOMER_NAME = "Acme";                   # Populate Customer Name from DTOpt.Company
my $SRC_TYPE = "";                            # FILE or DB
my $SHOW_ALL_MISSING_DAYS = true;             # true=Show all missing days, false=Show in compressed mode

#########################
#-- Data filters
#########################
my $START_YR="";
my $END_YR="";

#########################
#-- Processing variables
#########################
my $PI_TOTALRECORDS_READ=0 ;
my $PI_TOTALRECORDS_PROCESSED=0 ;
my $PI_TOTALRECORDS_FILTEREDOUT=0 ;
my $PI_TOTALRECORDS_MISSING=0 ;
my $PI_FIRST_DATE ;
my $PI_LAST_DATE ;
my $PI_AUTHOR = qq{<a href="mailto:ashok.rathi\@us.ibm.com?Subject=Question/Issue%20with%20$PROGNAME">Send Mail</a>};

#########################
#-- HTML variables
#########################
my $STYLE_HTML;
my $DAYNAME_HDR_HTML;
my @WEEKLY_ARRAY_HTML;
my $PROCESSING_INFO_HTML;
my $LEGEND_HTML;
my $TD_L1_START="<TD>\n";
my $TD_L1_END="</TD>\n";
my $TABLE_L2_START = qq{<TABLE BORDER="3" WIDTH="350" CELLPADDING="1" CELLSPACING="1">\n};
my $TABLE_L2_END = qq{</TABLE>\n};
my $TR_WKLY_START = qq{<tr align="center">};
my $TR_WKLY_END = "</tr>";

#################################################
#-- Print Usage
#################################################
sub printUsage() {
print <<EOF ;
********************************************************************************************************
                                        $PROGNAME
********************************************************************************************************

Synopsis:
    Generates Calendar HTML based on calendar data in flat file or in database

Usage:
    $PROGNAME -infile [CSV_CalendarDataFile] { -html [HTML_OUTPUT_FILE] } { [DATA_FILTERS] } { -debug [DBGLevel] }

    $PROGNAME -db2 [user/pwd\@db] { -daytable [DayTable] } { -html [HTML_OUTPUT_FILE] } { [DATA_FILTERS] } { -debug [DBGLevel] }

    $PROGNAME -help

    -infile [CSV_CalendarDataFile]
        (REQUIRED) Calendar data file as an input. Fields must be separated by pipe '|'.
        You can use DB2 Export to generate this input file using either of the two tables.
              - DTDWH.CI_Day_D , or
              - DTDWH.CI_Day2_D

    -html [HTML_OUTPUT_FILE]
        (OPTIONAL) HTML filename where this program will output the calendar. You can view this file using
        browser of your choice.

    -db2 [user/pwd\@db]
        (REQUIRED) Provide DB2 connection information for Optimization DB.

    -daytable [DayTable]
        (OPTIONAL) Provide DB2 table that be used as a basis to generate calendar data. By default, we would
        be using DTDWH.CI_Day_D  table.

    -debug [DBGLevel]
        Set Debug level 1 or 2 to print additional debugging statements

    [DATA_FILTERS]
        -years [start_yr] [end_yr]:  Process data for only this range of years. Ignore the rest.

    -help
        Print usage

    Examples
    ========

    Ex 1: Generate "index.html" output file from table DTDWH.CI_DAY_D in DATABASE
        $PROGNAME -db2 dtuser/Welcome1\@dtdev

    Ex 2: Use calendar data only from a file
        $PROGNAME -infile /tmp/sjltgto1_CI_D.csv

    Ex 3: Use calendar data only from Year 2012-2015
        $PROGNAME -infile /tmp/sjltgto1_CI_D.csv -year 2012 2015

EOF
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
          "* Input File                  = $CSV_CalendarFile                                  "."\n".
          "* HTML Output File            = $OUT_HTML                                          "."\n".
          "* DB Connection Params        = $DBName/$DBUser/*****                              "."\n".
          "* Day Table                   = $DAYTABLE                                          "."\n".
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

    if ( "$CSV_CalendarFile" ) {
        if ( ! -e "$CSV_CalendarFile" ) {
            printErrorMsg "$moduleName", "Input file $CSV_CalendarFile does not exist. Exiting...";
            exit 1;
        }

        if ( "$COMPANY_STARTDOW" and ! ("$COMPANY_STARTDOW" >= 1 and "$COMPANY_STARTDOW" <= 7 ) ) {
            printErrorMsg "$moduleName", "Incorrect StartDOW value '$COMPANY_STARTDOW'. This must be between 1 and 7. Exiting...";
            exit 1;
        }

        $SRC_TYPE = "FILE";
    } else {
        if ( ! ( "$DBName" and "$DBUser" and "$DBPasswd" ) ) {
            printErrorMsg "$moduleName", "Missing or Incorrect DB Connection params. Exiting...";
            exit 1;
        }
        $SRC_TYPE = "DB";

        $CSV_CalendarFile = "/tmp/$DBName"."_CI_Day.csv";
        $StartDOWFile = "/tmp/$DBName"."_StartDOW.csv";
    }
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
while($cnt < $argCnt) {
    $_ = $ARGV[$cnt] ;
    SWITCH: {
        /^-infile$/ && do {
               $cnt = $cnt + 1 ;
               # $CSV_CalendarFile = abs_path($ARGV[$cnt]);
               $CSV_CalendarFile = $ARGV[$cnt];
               last SWITCH ;
            };
        /^-html$/ && do {
               $cnt = $cnt + 1 ;
               $OUT_HTML = $ARGV[$cnt];
               last SWITCH ;
            };
        /^-db2$/ && do {
               $cnt = $cnt + 1 ;
               ($DBName, $DBUser, $DBPasswd) = parseDBConnParams($ARGV[$cnt]) ;
               last SWITCH ;
            };
        /^-daytable$/ && do {
               $cnt = $cnt + 1 ;
               $DAYTABLE = $ARGV[$cnt];
               last SWITCH ;
            };
        /^-years$/ && do {
               $cnt = $cnt + 1 ;
               $START_YR = $ARGV[$cnt];
               $cnt = $cnt + 1 ;
               $END_YR = $ARGV[$cnt];
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

my $InputFile_StartDOW;

#################################################
#-- Read Calendar Input file and populate
#   CID_ARRAY with all the records. Input file
#   is assumed to be with Pipe-separated fields
#################################################
sub readCalInputFile(@)
{
    my ($CAL_CSV_FILE) = @_;
    my $line = "";
    my $row = 0;
    my $moduleName = "readCalInputFile";

    open CAL_FL, "<$CAL_CSV_FILE" or die "**ERROR**: Can't open file $CAL_CSV_FILE." ;
    while ( $line = <CAL_FL> ) {
        chop($line);
        if ( $line =~ /^#/ ) {       # ignore commented records
            next ;
        }
        
        $line =~ s/\"//g ;      # Remove double quotes
        printDebug 2, "$moduleName", "$line";
        my (
          $DAY_ID,
          $CAL_DATE,
          $CAL_WEEK,
          $CAL_WEEK_ID,
          $CAL_MONTH,
          $CAL_MONTH_ID,
          $CAL_YEAR,
          $CAL_QTR,
          $DAY_NAME,
          $DAY_OF_WEEK,
          $DAY_OF_MONTH,
          $DAY_OF_QUARTER,
          $DAY_OF_YEAR,
          $DAY_AGO_DATE,
          $DAY_AGO_DATE_ID,
          $WEEK_AGO_DATE,
          $WEEK_AGO_DATE_ID,
          $MONTH_AGO_DATE,
          $MONTH_AGO_DATE_ID,
          $QTR_AGO_DATE,
          $QTR_AGO_DATE_ID,
          $YEAR_AGO_DATE,
          $YEAR_AGO_DATE_ID,
          $CAL_WEEK_NAME,
          $CAL_MONTH_NAME,
          $CAL_QUARTER_NAME,
          $CAL_YEAR_NAME,
          $CAL_QTR_ID
        ) = split /\|/, $line, 28;
        $row = $row + 1;
        printDebug 2, "$moduleName", "Row = $row, Day_ID = $DAY_ID, CAL_DATE = $CAL_DATE, CAL_WEEK_ID = $CAL_WEEK_ID, CAL_MONTH_ID = $CAL_MONTH_ID, CAL_QTR_ID = $CAL_QTR_ID";

        if ( ! $InputFile_StartDOW ) {
            if ( $DAY_OF_WEEK == 1 ) {
                ############################################################
                # [Attention]: Translate Perl StartDOW to DT-Company StartDOW
                # 
                # Day of Week (DOW)
                #     Perl       : 1=Mon, 2=Tue,...,7=Sun
                #     DT Company : 1=Sun, 2=Mon,...,7=Sat
                ############################################################
                my ($year,$month,$day) = Decode_Date_US2($CAL_DATE) ;
                $InputFile_StartDOW = ( Day_of_Week($year,$month, $day) % 7 ) + 1;

                ############################################################
                # COMPANY_STARTDOW would exist only if read from DB
                # If exists, we would match this with StartDOW from InputFile
                #         If match fails, EXIT
                # If NOT exist, copy StartDOW from Input File.
                ############################################################
                if ( $COMPANY_STARTDOW ) {
                    if ( $COMPANY_STARTDOW != $InputFile_StartDOW ) {
                        printErrorMsg "$moduleName",
                           "(Company_StartDOW=$COMPANY_STARTDOW, Input_File_StartDOW=$InputFile_StartDOW) does NOT match.\n". 
                           " Used this input record to verify: CAL_DATE=$CAL_DATE, DAY_ID=$DAY_ID.". 
                           " Exiting...";
                        exit 1;
                    }
                } else {
                    $COMPANY_STARTDOW = $InputFile_StartDOW;
                }
            }
        }

        my $cid = CIDay->new(
            "DAY_ID"                  => $DAY_ID,
            "CAL_DATE"                => $CAL_DATE,
            "CAL_WEEK"                => $CAL_WEEK,
            "CAL_WEEK_ID"             => $CAL_WEEK_ID,
            "CAL_MONTH"               => $CAL_MONTH,
            "CAL_MONTH_ID"            => $CAL_MONTH_ID,
            "CAL_YEAR"                => $CAL_YEAR,
            "CAL_QTR"                 => $CAL_QTR,
            "DAY_NAME"                => $DAY_NAME,
            "DAY_OF_WEEK"             => $DAY_OF_WEEK,
            "DAY_OF_MONTH"            => $DAY_OF_MONTH,
            "DAY_OF_QUARTER"          => $DAY_OF_QUARTER,
            "DAY_OF_YEAR"             => $DAY_OF_YEAR,
            "DAY_AGO_DATE"            => $DAY_AGO_DATE,
            "DAY_AGO_DATE_ID"         => $DAY_AGO_DATE_ID,
            "WEEK_AGO_DATE"           => $WEEK_AGO_DATE,
            "WEEK_AGO_DATE_ID"        => $WEEK_AGO_DATE_ID,
            "MONTH_AGO_DATE"          => $MONTH_AGO_DATE,
            "MONTH_AGO_DATE_ID"       => $MONTH_AGO_DATE_ID,
            "QTR_AGO_DATE"            => $QTR_AGO_DATE,
            "QTR_AGO_DATE_ID"         => $QTR_AGO_DATE_ID,
            "YEAR_AGO_DATE"           => $YEAR_AGO_DATE,
            "YEAR_AGO_DATE_ID"        => $YEAR_AGO_DATE_ID,
            "CAL_WEEK_NAME"           => $CAL_WEEK_NAME,
            "CAL_MONTH_NAME"          => $CAL_MONTH_NAME,
            "CAL_QUARTER_NAME"        => $CAL_QUARTER_NAME,
            "CAL_YEAR_NAME"           => $CAL_YEAR_NAME,
            "CAL_QTR_ID"              => $CAL_QTR_ID
        );


        #-- Filter by Year Range
        if ( $START_YR ne "" and $END_YR ne "" ) {
            if ( $CAL_YEAR >= $START_YR and $CAL_YEAR <= $END_YR) {
                push(@CID_ARRAY, $cid);
            } else {
                $PI_TOTALRECORDS_FILTEREDOUT += 1;
            }
        } else {
            push(@CID_ARRAY, $cid);
        }
    }
    $PI_TOTALRECORDS_READ=$row ;
}

#################################################
#-- Print one CID record from an array. 
#################################################
my $tmpXc;               # Using these as  global (TBD: find out how to pass object reference in Perl)
my $tmpXprev;
my $tmpXcur;
sub printOneCIDRecord()
{
    my $moduleName = "printOneCIDRecord";
    printf "\n";
    printf "[DAY_ID]               =%-40s\n",%{$tmpXc}->{ "DAY_ID"};
    printf "    CAL_DATE           =%-40s\n",%{$tmpXc}->{ "CAL_DATE"};
    printf "    CAL_WEEK           =%-40s",%{$tmpXc}->{ "CAL_WEEK"};
    printf "    CAL_WEEK_ID        =%-40s\n",%{$tmpXc}->{ "CAL_WEEK_ID"};
    printf "    CAL_MONTH          =%-40s",%{$tmpXc}->{ "CAL_MONTH"};
    printf "    CAL_MONTH_ID       =%-40s\n",%{$tmpXc}->{ "CAL_MONTH_ID"};
    printf "    CAL_YEAR           =%-40s",%{$tmpXc}->{ "CAL_YEAR"};
    printf "    CAL_QTR            =%-40s\n",%{$tmpXc}->{ "CAL_QTR"};
    printf "    DAY_NAME           =%-40s",%{$tmpXc}->{ "DAY_NAME"};
    printf "    DAY_OF_WEEK        =%-40s\n",%{$tmpXc}->{ "DAY_OF_WEEK"};
    printf "    DAY_OF_MONTH       =%-40s",%{$tmpXc}->{ "DAY_OF_MONTH"};
    printf "    DAY_OF_QUARTER     =%-40s\n",%{$tmpXc}->{ "DAY_OF_QUARTER"};
    printf "    DAY_OF_YEAR        =%-40s",%{$tmpXc}->{ "DAY_OF_YEAR"};
    printf "    DAY_AGO_DATE       =%-40s\n",%{$tmpXc}->{ "DAY_AGO_DATE"};
    printf "    DAY_AGO_DATE_ID    =%-40s",%{$tmpXc}->{ "DAY_AGO_DATE_ID"};
    printf "    WEEK_AGO_DATE      =%-40s\n",%{$tmpXc}->{ "WEEK_AGO_DATE"};
    printf "    WEEK_AGO_DATE_ID   =%-40s",%{$tmpXc}->{ "WEEK_AGO_DATE_ID"};
    printf "    MONTH_AGO_DATE     =%-40s\n",%{$tmpXc}->{ "MONTH_AGO_DATE"};
    printf "    MONTH_AGO_DATE_ID  =%-40s",%{$tmpXc}->{ "MONTH_AGO_DATE_ID"};
    printf "    QTR_AGO_DATE       =%-40s\n",%{$tmpXc}->{ "QTR_AGO_DATE"};
    printf "    QTR_AGO_DATE_ID    =%-40s",%{$tmpXc}->{ "QTR_AGO_DATE_ID"};
    printf "    YEAR_AGO_DATE      =%-40s\n",%{$tmpXc}->{ "YEAR_AGO_DATE"};
    printf "    YEAR_AGO_DATE_ID   =%-40s",%{$tmpXc}->{ "YEAR_AGO_DATE_ID"};
    printf "    CAL_WEEK_NAME      =%-40s\n",%{$tmpXc}->{ "CAL_WEEK_NAME"};
    printf "    CAL_MONTH_NAME     =%-40s",%{$tmpXc}->{ "CAL_MONTH_NAME"};
    printf "    CAL_QUARTER_NAME   =%-40s\n",%{$tmpXc}->{ "CAL_QUARTER_NAME"};
    printf "    CAL_YEAR_NAME      =%-40s",%{$tmpXc}->{ "CAL_YEAR_NAME"};
    printf "    CAL_QTR_ID         =%-40s\n",%{$tmpXc}->{ "CAL_QTR_ID"};
}

#################################################
#-- Print Array of all the records read
#   from Pipe-delimited calendar input file.
#################################################
sub printCIDArray()
{
    my $moduleName = "printCIDArray";
    my $c;
    foreach $c (@CID_ARRAY)
    {
         # set global variable to be used by called function to print
         $tmpXc = $c; printOneCIDRecord ;
    }
}

#################################################
#-- Set HTML Style header for proper
#   formatting/color/fonts etc.
#################################################
sub setStyleHTML()
{
    my $moduleName = "setStyleHTML";
    $STYLE_HTML = "
    <style>
	.month {
		border:1px solid #C0C0C0;
		border-collapse:collapse;
		padding:5px;
	}
	.month th {
		border:1px solid #C0C0C0;
		padding:5px;
		background:#F0F0F0;
	}
	.month td {
		border:1px solid #C0C0C0;
                text-align:center;
		padding:5px;
	}
	td.month {
                background: lightblue;
                font-weight:bold;
                font-size: 1.00em; /* 40px/16=2.5em */
		border:1px solid #C0C0C0;
                text-align:center;
	}
	td.qtr {
                background: yellow;
                font-weight:bold;
                font-size: 1.25em; /* 40px/16=2.5em */
		border:1px solid #C0C0C0;
                text-align:center;
	}
	td.year {
                background: lightgreen;
                font-weight:bold;
                font-size: 1.5em; /* 40px/16=2.5em */
		border:1px solid #C0C0C0;
                text-align:center;
	}
	td.day_ul {
                font-weight:bold;
                text-align:center;
                color: blue;
                font-size: 1.25em; /* 40px/16=2.5em */
	}
	td.day_normal {
                font-weight:bold;
                text-align:center;
	}
	td.day_error {
                font-weight:bold;
                background: red;
                text-align:center;
	}
	td.pi_errors {
                font-weight:bold;
                background: red;
                color: white;
	}
	td.pi_noerrors {
                font-weight:bold;
                background: green;
                color: white;
	}
	th.dayname {
                background: aliceblue;
                font-weight:bold;
                font-size: 1.15em; /* 40px/16=2.5em */
		border:1px solid #C0C0C0;
                text-align:center;
	}
    </style>
    " ;
}

#################################################
#-- Set HTML for Processing Summary.
#################################################
sub setProcessingInfoHTML()
{
    my $moduleName = "setProcessingInfoHTML";

    my $yrRangeFilter_Str = "All";
    if ( $START_YR ne "" and $END_YR ne "" ) {
       $yrRangeFilter_Str = "Yr$START_YR - Yr$END_YR";
    }

    my $db_conn_str = "Unknown";
    my $db_table_str = "Unknown";
    if ( $SRC_TYPE eq "FILE" ) {
        $db_conn_str = "[File]";
        $db_table_str = "[File]";
    }
    elsif ( $SRC_TYPE eq "DB" ) {
        $db_conn_str = "$DBName/$DBUser/****";
        $db_table_str = "$DAYTABLE";
    }

    my $missingRecords_html;
    if ( $PI_TOTALRECORDS_MISSING > 0 ) {
        $missingRecords_html = qq{<td class="pi_errors">$PI_TOTALRECORDS_MISSING</td>};
    } else {
        $missingRecords_html = qq{<td class="pi_noerrors">$PI_TOTALRECORDS_MISSING</td>};
    }

    my $opHTML = "<b>PROCESSING INFO</b>" ;
    $opHTML = $opHTML.qq{
       <div>
         <table border="3" valign="top" cellpadding="5">
           <tr>
              <td>DB Connection Params</td><td><b>$db_conn_str</td></b>
           </tr>
           <tr>
              <td>Day Table</td><td><b>$db_table_str</td></b>
           </tr>
           <tr>
              <td>Input File</td><td><b>$CSV_CalendarFile</td></b>
           </tr>
           <tr>
              <td>Start Day of Week</td><td><b>$COMPANY_STARTDOW ($DAY_HMAP{$COMPANY_STARTDOW})</b></td>
           </tr>
           <tr>
              <td>Start Day of Week (Input File) </td><td><b>$InputFile_StartDOW ($DAY_HMAP{$InputFile_StartDOW})</b></td>
           </tr>
           <tr>
              <td>Total Records Read/Processed</td><td><b>$PI_TOTALRECORDS_READ / $PI_TOTALRECORDS_PROCESSED</b></td>
           </tr>
           <tr>
              <td>Year Range Filter</td><td><b>$yrRangeFilter_Str</b></td>
           </tr>
           <tr>
              <td>Total Records Filtered Out</td><td><b>$PI_TOTALRECORDS_FILTEREDOUT</b></td>
           </tr>
           <tr>
              <td>Date Range Read</td><td><b>$PI_FIRST_DATE - $PI_LAST_DATE</td></b>
           </tr>
           <tr>
              <td>HTML Output File</td><td><b>$OUT_HTML</td></b>
           </tr>
           <tr>
              <td>Generated By</td><td><b>$PROGNAME<br>$CURTIMESTAMP</td></b>
           </tr>
           <tr>
              <td>Questions/Issues</td><td><b>$PI_AUTHOR</td></b>
           </tr>
           <tr>
              <td>Total Records Missing</td>$missingRecords_html
           </tr>
         </table>
       </div>
       } ;

    $PROCESSING_INFO_HTML = $opHTML ;
}

#################################################
#-- Set HTML for Day names for Monday thru Sunday
#   based on Company's Start DOW.
#################################################
sub setDayNameHTML()
{
    my $moduleName = "setDayNameHTML";
    my $days = 7;
    my $dayNameHTML = "<tr>\n<th></th>\n";
    my $i = $COMPANY_STARTDOW;
    while($days > 0) {
        if ( $i == 8 ) {
            $i = 1;
        }
        printDebug 1, $moduleName, "DayName-$i = $DAY_HMAP{$i}";
        $dayNameHTML = $dayNameHTML."<th class=\"dayname\">".$DAY_HMAP{$i}."</th>"."\n";
        $i += 1;
        $days -= 1;
    }
    $dayNameHTML = $dayNameHTML."</tr>"."\n";
    printDebug 1, $moduleName, "Day Header HTML: $dayNameHTML";
    $DAYNAME_HDR_HTML = $dayNameHTML;
}

#################################################
#-- Set HTML for legend info
#################################################
sub setLegend()
{
    my $moduleName = "setLegend";

    $LEGEND_HTML = qq{
             <p>\n
             <b>Legend:</b>\n
             <span style="background-color: lightgreen; font-size: large;">Year</span>\n
             <span style="font-size: large;">      </span>\n
             <span style="background-color: yellow; font-size: large;">Quarter</span>\n
             <span style="font-size: large;">      </span>\n
             <span style="background-color: lightblue; font-size: large;">Month</span>\n
             <span style="font-size: large;">      </span>\n
             <span style="background-color: red; font-size: large;">Errors</span>\n
             </p>\n
             };
}

#################################################
#-- Populate HTML Weekly rows for each day
#   This generates an array with HTML fragments
#   for entire calendar.
#################################################
sub populateWeeklyHTML()
{
    my $prev_c;
    my $bIgnore = true;
    my $c;
    my $iDay = 0;
    my $tmp_wk_html = "<td>&nbsp;</td>\n";
    my $prev_year_c;
    my $prev_qtr_c;
    my $prev_month_c;
    my $moduleName = "populateWeeklyHTML";
    my $bFirstRec = true;
    my $rows_processed = 0;
    my $nRecordMissing;
    my $tmpMissingRecordHTML="";
    my $bFirstYearTable = true;

    foreach $c (@CID_ARRAY)
    {
        my $nRecordMissing = 0;
        if ( $bFirstRec ) {
            $PI_FIRST_DATE = %{$c}->{ "CAL_DATE"};
            $bFirstRec = false;
        }

        ######################################################
        # Ignore (Skip) initial set of calendar data until we
        # hit beginning of the quarter. This helps us with a
        # good starting point. 
        ######################################################
        if ( $bIgnore ) {
            if ( %{$c}->{ "CAL_QTR"} == 1 && %{$c}->{ "CAL_MONTH"} == 1 && %{$c}->{ "CAL_WEEK"} == 1 ) {
                my ($year,$month,$day) = Decode_Date_US2(%{$c}->{ "CAL_DATE"});
                ###########################################################
                # Day of Week
                #     Perl       : 1=Mon, 2=Tue,...,7=Sun
                #     DT Company : 1=Sun, 2=Mon,...,7=Sat
                ###########################################################
                if ( (Day_of_Week($year,$month, $day) + 1)%7 == $COMPANY_STARTDOW ) {
                    $bIgnore = false;
                }
            }
        }

        ##################################################################
        # - Generate HTML as we process one record at a time.
        #
        # - Once we generate HTML for one week, Push this HTML into an
        #   ARRAY that would be used to generate a HTML output file later
        #
        # - Generate special headers as we cross Year/Quarter/Month
        #
        # - Handle any missing records by marking them with red color
        ##################################################################
        if ( $bIgnore == false ) {
            printDebug 2, $moduleName, sprintf("CAL_DATE=%s, CAL_QTR=%s, CAL_MONTH=%s, CAL_WEEK=%s",
                             %{$c}->{ "CAL_DATE"}, %{$c}->{ "CAL_QTR"}, %{$c}->{ "CAL_MONTH"}, %{$c}->{ "CAL_WEEK"}) ;
            my ($c_year,$c_month,$c_day) = Decode_Date_US2(%{$c}->{ "CAL_DATE"});
            my ($p_year,$p_month,$p_day);
            if ( $prev_c ) {
                ($p_year,$p_month,$p_day) = Decode_Date_US2(%{$prev_c}->{ "CAL_DATE"});
                printDebug 2, "$moduleName", "current_date = ".%{$c}->{ "CAL_DATE"}.", previous_date = ". %{$prev_c}->{ "CAL_DATE"};
            } else {
                ($p_year,$p_month,$p_day) = Add_Delta_Days($c_year, $c_month, $c_day, -1);
            }

            $nRecordMissing = (Date_to_Days ($c_year,$c_month, $c_day) - Date_to_Days ($p_year,$p_month, $p_day)) - 1;
            if ( $nRecordMissing > 0 ) {
                $PI_TOTALRECORDS_MISSING += $nRecordMissing ;
                # Previous and Current Date are not contiguous dates - hence some missing dates
                if ( $prev_c ) {
                    printErrorMsg $moduleName,
                        "Missing Calendar Date record(s) between ".%{$prev_c}->{"CAL_DATE"}.
                        " and ".%{$c}->{"CAL_DATE"}.", Count = ".$nRecordMissing ;
                    my $k = 0;
                    my $nSkipCellCount = $nRecordMissing;
                    if ( $SHOW_ALL_MISSING_DAYS == false ) {
                        # for example, nRecordingMissing = 25 --> 8, nRecordingMissing = 10 --> 10, 
                        if ($nRecordMissing >= $NDAYS_IN_WEEK * 2) {
                            $nSkipCellCount = ( $NDAYS_IN_WEEK * 2) + $nRecordMissing % $NDAYS_IN_WEEK
                        } elsif ($nRecordMissing >= $NDAYS_IN_WEEK) {
                            $nSkipCellCount = ( $NDAYS_IN_WEEK ) + $nRecordMissing % $NDAYS_IN_WEEK
                        }
                    }
                    #$nSkipCellCount = ($nSkipCellCount == 0) ? $NDAYS_IN_WEEK : $nSkipCellCount;
                    while($k < $nSkipCellCount)
                    {
                        printDebug 1, $moduleName, "Loop: nSkipCellCount = $nSkipCellCount, iDay = $iDay, k=$k" ;
                        $k += 1;
                        if ( $iDay == 0 ) {
                            $tmpMissingRecordHTML = $tmpMissingRecordHTML.qq{<td class="day_error">Wx</td>\n};
                        }
                        $tmpMissingRecordHTML = $tmpMissingRecordHTML.qq{<td class="day_error">X</td>\n};

                        $iDay += 1;
                        if ( $iDay == $NDAYS_IN_WEEK ) {
                            $iDay = 0;
                            push(@WEEKLY_ARRAY_HTML, "$TR_WKLY_START".$tmp_wk_html.$tmpMissingRecordHTML."$TR_WKLY_END" );
                            $tmpMissingRecordHTML="";
                            $tmp_wk_html = "";
                        }
                    }
                    printDebug 1, $moduleName, "End: nSkipCellCount = $nSkipCellCount, iDay = $iDay, k=$k" ;
                } else {
                    printErrorMsg $moduleName, "Missing record(s) found right before:".%{$c}->{"CAL_DATE"}.", Count = ".$nRecordMissing ;
                }
            }

            if ( $tmpMissingRecordHTML  ne "" ) {
                 printDebug 1, $moduleName, "tmpMissingRecordHTML:$tmpMissingRecordHTML, iDay = $iDay" ;
                 $tmp_wk_html = $tmp_wk_html.$tmpMissingRecordHTML;
            }
            if ( $iDay == 0 ) {
                 if ( $tmpMissingRecordHTML  ne "" ) {
                     push(@WEEKLY_ARRAY_HTML, "$TR_WKLY_START".$tmpMissingRecordHTML."$TR_WKLY_END");
                 }
                 my $week_str = "W".%{$c}->{ "CAL_WEEK"};
                 $tmp_wk_html = "<td>$week_str</td>\n";
            }
            $tmpMissingRecordHTML="";
            my $day_str = sprintf("%d", $c_day);   # 1-31
            if ( $day_str == 1 ) {
                $tmp_wk_html = $tmp_wk_html.
		    qq{<td class="day_ul"><u><b>$day_str</b></u></td>\n};
            } else {
                $tmp_wk_html = $tmp_wk_html.
		    qq{<td class="day_normal">$day_str</td>\n};
            }

            $iDay += 1;
            if ( $iDay == $NDAYS_IN_WEEK ) {
                $iDay = 0;
                push(@WEEKLY_ARRAY_HTML, "$TR_WKLY_START".$tmp_wk_html."$TR_WKLY_END");
                $tmp_wk_html = "";
            }

            #######################################
            #-- Handle as we cross YEAR boundary
            #######################################
            if ( %{$c}->{ "CAL_YEAR"} != %{$prev_year_c}->{ "CAL_YEAR"} ) {
                my $year_str = %{$c}->{ "CAL_YEAR_NAME"};
                if ( ! $bFirstYearTable ) {
                    push(@WEEKLY_ARRAY_HTML, $TABLE_L2_END);
                    push(@WEEKLY_ARRAY_HTML, $TD_L1_END);
                    push(@WEEKLY_ARRAY_HTML, $TD_L1_START);
                    push(@WEEKLY_ARRAY_HTML, $TABLE_L2_START);
                }
                $bFirstYearTable = false;
                push(@WEEKLY_ARRAY_HTML, $TR_WKLY_START.qq{<td colspan="8"></td>}.$TR_WKLY_END);
                push(@WEEKLY_ARRAY_HTML, $TR_WKLY_START.qq{<td colspan="8" class="year">$year_str</td>}.$TR_WKLY_END);
                $prev_year_c = $c;
            }

            #######################################
            #-- Handle as we cross QUARTER boundary
            #######################################
            if ( %{$c}->{ "CAL_QTR"} != %{$prev_qtr_c}->{ "CAL_QTR"} ) {
                my $qtr_str = %{$c}->{ "CAL_QUARTER_NAME"};
                push(@WEEKLY_ARRAY_HTML, $TR_WKLY_START.qq{<td colspan="8"></td>}.$TR_WKLY_END);
                push(@WEEKLY_ARRAY_HTML, $TR_WKLY_START.qq{<td colspan="8" class="qtr"><b>$qtr_str</b></td>}.$TR_WKLY_END);
                $prev_qtr_c = $c;
            }

            #######################################
            #-- Handle as we cross MONTH boundary
            #######################################
            if ( %{$c}->{ "CAL_MONTH"} != %{$prev_month_c}->{ "CAL_MONTH"} ) {
                my $month_str = %{$c}->{ "CAL_MONTH_NAME"};
                push(@WEEKLY_ARRAY_HTML, $TR_WKLY_START.qq{<td colspan="8"></td>}.$TR_WKLY_END);
                push(@WEEKLY_ARRAY_HTML, $TR_WKLY_START.qq{<td colspan="8" class="month">$month_str</td>}.$TR_WKLY_END);
                push(@WEEKLY_ARRAY_HTML, "$TR_WKLY_START"."$DAYNAME_HDR_HTML"."$TR_WKLY_END");
                $prev_month_c = $c;
            }
            $rows_processed += 1;
        }
        $prev_c = $c;
    }
    if ( $prev_c ) {
        $PI_LAST_DATE = %{$prev_c}->{"CAL_DATE"};
    }
    $PI_TOTALRECORDS_PROCESSED = $rows_processed;
}

#################################################
#-- Generate final HTML
#################################################
sub genHTML()
{
    my $moduleName = "genHTML";

    ($STYLE_HTML) = setStyleHTML ;
    printDebug 2, "$moduleName", "Style: $STYLE_HTML";

    setDayNameHTML ;
    populateWeeklyHTML ;

    setLegend ;
    setProcessingInfoHTML ;

    #################################################################
    # Generate HTML file
    #################################################################
    open INDEX_HTML_FL, ">$OUT_HTML" or die "**ERROR**: Can't open file $OUT_HTML." ;
    print INDEX_HTML_FL "$LEGEND_HTML\n";
    print INDEX_HTML_FL "$STYLE_HTML\n";

    my $Customer_Str = "$CUSTOMER_NAME/$CALENDAR_TYPE_STR";
    my $DIV_START = qq{<div align="center">\n};
    my $DIV_END = "</div>\n";
    my $TABLE_L1_START = qq{
        <TABLE BORDER="3" CELLPADDING="1" CELLSPACING="50">\n
	<caption>\n
            <b><p style="font-size:150%">$Customer_Str</p></b>\n
        </caption>\n} ;
    my $TABLE_L1_END = "</TABLE>\n" ;
    my $TR_L1_START = qq{<TR valign="top">\n};

    my $TR_L1_END = "</TR>\n";

    print INDEX_HTML_FL "$DIV_START";
    print INDEX_HTML_FL "$TABLE_L1_START";
    print INDEX_HTML_FL "$TR_L1_START";
    print INDEX_HTML_FL "$TD_L1_START";
    print INDEX_HTML_FL "$TABLE_L2_START";

    foreach my $c (@WEEKLY_ARRAY_HTML) 
    {
        #print INDEX_HTML_FL "\n<tr>\n$c\n</tr>\n";
        print INDEX_HTML_FL "\n$c\n";
    }

    print INDEX_HTML_FL "$TABLE_L2_END";
    print INDEX_HTML_FL "$TD_L1_END";
    print INDEX_HTML_FL "$TR_L1_END\n";
    print INDEX_HTML_FL "$TABLE_L1_END\n";
    print INDEX_HTML_FL "$DIV_END";

    print INDEX_HTML_FL "<br><br>"."$PROCESSING_INFO_HTML\n";

    printMsg $moduleName, "Generated HTML file = $OUT_HTML . Open this file in your favorite browser to view the Calendar\n";
}

#################################################
#-- Export Calendar Data from DTDWH.CI_Day_D/
#   or DTDWH.CI_Day2_D table.
#
#   Also, Retrieve Start DOW from DTopt.Company
#################################################
sub exportCalDataFile()
{
    my $moduleName = "exportCalDataFile";

    if ( ! $DBName ) { return; }

    #########################################################
    #-- Call shell script to EXPORT in Pipe-delimited format.
    #      - CI Day data
    #      - StartDOW from DTOpt.Company
    #########################################################
    my @progargs = (
        "$SHELL_PROG $PROGDIR/$CIDAY_EXPORT_SCRIPT $DBName '$DBUser' '$DBPasswd' '$CSV_CalendarFile' '$StartDOWFile' '$DAYTABLE'"
    );
    system(@progargs) ;

    #########################################################
    #-- Merchandising or Financial
    #########################################################
    if ( uc($DAYTABLE) eq "DTDWH.CI_DAY_D" ) { 
        $CALENDAR_TYPE_STR = "Merchandising Calendar";
    } elsif ( uc($DAYTABLE) eq "DTDWH.CI_DAY2_D" ) { 
        $CALENDAR_TYPE_STR = "Financial Calendar";
    } else {
        $CALENDAR_TYPE_STR = "Unknown Calendar";
    }

    #########################################################
    #-- Retrieve StartDOW from file
    #########################################################
    if ( ! $COMPANY_STARTDOW ) {
        my $line, my $junk;
        open DOW_FL, "<$StartDOWFile" or die "**ERROR**: Can't open file $StartDOWFile." ;
        $line = <DOW_FL> ;
        $line =~ s/\"//g ;      # Remove double quotes
        ($COMPANY_STARTDOW, $CUSTOMER_NAME, $junk) = split /\|/, $line, 3;
        printMsg $moduleName, "Company_StartDOW=$COMPANY_STARTDOW, Customer_Name=$CUSTOMER_NAME";
   }
}

#-- validate parameters
checkParams ;

#-- Export data if DB
exportCalDataFile ;

#-- Print all parameters
printParams ;

#-- Read calendar data file
readCalInputFile "$CSV_CalendarFile";

#-- Print all records in the Array.
#printCIDArray ;

#-- Generate HTML file
genHTML ;
