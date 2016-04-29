#!/usr/bin/perl
package DTUtil;
use strict;
use warnings;
use Exporter;
#################################################################
our @ISA       = qw( Exporter );
our @EXPORT    = qw( printMsg printDebug printMilestone setDebugLevel printErrorMsg printBlankline parseDBConnParams );
#################################################################

my $DEBUGLEVEL            = 0  ;  #0=no debug, 3=very verbose
my $SHORTNAME_LENGTH      = 20 ;
my $NONE                  = '' ;

###############################
# Print Debug Msg
###############################
sub printDebug(@) {
    my ($dbglevel, $shortName, $msg) = @_;
    $shortName = substr "$shortName                    ", 0, $SHORTNAME_LENGTH ;
    $dbglevel <= $DEBUGLEVEL && printf "[%s] [DEBUG-%d] %s\n", $shortName, $dbglevel, $msg;
}

###############################
# Print Milestone
###############################
sub printMilestone(@) {
    my ($shortName, $msg) = @_;
    $shortName = substr "$shortName                    ", 0, $SHORTNAME_LENGTH ;
    my $tmpcurtimestamp = `date +"%Y-%m-%d %H:%M:%S"`;
    chop ( $tmpcurtimestamp );
    printf "[%s] %s\n", $shortName, "[*****MILESTONE*****] $msg";
}

###############################
# Set Debug Level
###############################
sub setDebugLevel(@) {
    my ($dbglevel) = @_;
    if ( $dbglevel >= 0 and $dbglevel <= 3 ) {
        $DEBUGLEVEL = $dbglevel ;
        printMilestone "setDebugLevel", "New Debug Level set = $DEBUGLEVEL"; 
    }
}

###############################
# Print Message
###############################
sub printMsg(@) {
    my ($shortName, $msg) = @_;
    $shortName = substr "$shortName                    ", 0, $SHORTNAME_LENGTH ;
    printf "[%s] %s\n", $shortName, $msg;
}

###############################
# Print Error Message
###############################
sub printErrorMsg(@) {
    my ($shortName, $msg) = @_;
    $shortName = substr "$shortName                    ", 0, $SHORTNAME_LENGTH ;
    printf "[%s] %s\n", $shortName, "[*****ERROR*****] $msg";
}

###############################
# Print Blank line
###############################
sub printBlankline(@) {
    my ($shortName) = @_;
    $shortName = substr "$shortName                    ", 0, $SHORTNAME_LENGTH ;
    printf "[%s]\n", $shortName;
}

###############################
# Parset and return three DB
# Connection parameters.
# Input Value format:
#    user/pwd@db
# Return Values:
#    First = DB
#    Second = UserID
#    Third = Password
###############################
sub parseDBConnParams(@) {
    my $myProc = "parseDBConnParams";
    my ($dbConnStr) = @_, my $rest=$NONE;
    my $TmpUser=$NONE, my $TmpPwd=$NONE, my $TmpDB=$NONE;
    ($TmpUser, $rest) = split /\//, $dbConnStr, 2 ;
    printDebug 1, "$myProc", "dbConnStr=$dbConnStr" ;
    ($TmpPwd, $TmpDB) = split /\@/, $rest, 2 ;
    printDebug 1, "$myProc", "TmpUser=$TmpUser, TmpPwd=$TmpPwd, TmpDB=$TmpDB" ;
    if ( "$TmpUser" eq $NONE || "$TmpPwd" eq $NONE || "$TmpDB" eq $NONE ) {
        printErrorMsg "$myProc", "Incorrect DB Connection format = '$dbConnStr'. Use 'user/password\@db' format. Exiting...";
        exit 1;
    }
    return ( "$TmpDB", "$TmpUser", "$TmpPwd" );
}


1;
