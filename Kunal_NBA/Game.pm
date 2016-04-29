#!/usr/bin/perl
#use strict;
#
package Game;

use DTUtil;
use Team;
use JSONHelper;

sub new
{
    my $class = shift;
    my $self = {
        _time                  => shift,
        _team1                 => shift,
        _team2                 => shift,
    };
    bless $self, $class;
    return $self;
}

sub printGame()
{
    my $moduleName = "printGame";
    my ($self) = @_;

    printf "\n";
    printf "=================================== PRINTING GAME ================================================\n";
    printf "Game Time          =%-40s\n",$self->{_time};

    my $t = $self->{_team1};
    bless($t, Team);
#printDebug 2, "$moduleName", "----------------------------- Team_1 Reference:".$t;
    $t->printTeam();

    $t = $self->{_team2};
    bless($t, Team);
#printDebug 2, "$moduleName", "----------------------------- Team_2 Reference:".$t;
    $t->printTeam();

    printf "=================================== END GAME ================================================\n";
}

sub printGameCSV()
{
    my $moduleName = "printGame";
    my ($self) = @_;

    printf "=================================== PRINTING GAME ================================================\n";

    my $t = $self->{_team1};
    bless($t, Team);
printDebug 2, "$moduleName", "----------------------------- Team_1 Reference:".$t;
    $t->printTeamCSV();

    $t = $self->{_team2};
    bless($t, Team);
printDebug 2, "$moduleName", "----------------------------- Team_2 Reference:".$t;
    $t->printTeamCSV();

    printf "=================================== END GAME ================================================\n";
}

sub printGameJSON()
{
    my $moduleName = "printGame";
    my ($self) = @_;
    my $prefix_spaces1 = "";
    my $prefix_spaces2 = "    ";
    
    JSONHelper::jprintStartTag($prefix_spaces1);
    JSONHelper::jprintObjectStart($prefix_spaces2, "Game");

    my $t = $self->{_team1};
    bless($t, Team);
    $t->printTeamJSON("HomeTeam");

    JSONHelper::jprintSeparator($prefix_spaces2);

    $t = $self->{_team2};
    bless($t, Team);
    $t->printTeamJSON("AwayTeam");

    JSONHelper::jprintObjectEnd($prefix_spaces2);
    JSONHelper::jprintEndTag($prefix_spaces1);
}

sub printGameJSONFile(@)
{
    my $moduleName = "printGame";
    my ($self, $JSON_FILE) = @_;
    my $prefix_spaces1 = "";
    my $prefix_spaces2 = "    ";
    
    my $JSON_FL;
    if ( uc $JSON_FILE eq "STDOUT" ) {
        $JSON_FL = STDOUT;
    } else {
        open $JSON_FL, ">$JSON_FILE" or die "**ERROR**: Can't open JSON output File = $JSON_FILE." ;
        # Assign variable for the game object.
        print $JSON_FL "var game = \n";
    }

    print $JSON_FL JSONHelper::jgetStartTag($prefix_spaces1);
    print $JSON_FL JSONHelper::jgetObjectStart($prefix_spaces2, "Game");

    my $t = $self->{_team1};
    bless($t, Team);
    my $str = $t->getTeamJSONString("AwayTeam");
    print $JSON_FL $str;

    print $JSON_FL JSONHelper::jgetSeparator($prefix_spaces2);

    $t = $self->{_team2};
    bless($t, Team);
    $str = $t->getTeamJSONString("HomeTeam", $JSON_FL);
    print $JSON_FL $str;

    print $JSON_FL JSONHelper::jgetObjectEnd($prefix_spaces2);
    print $JSON_FL JSONHelper::jgetEndTag($prefix_spaces1);

    if ( uc $JSON_FILE ne "STDOUT" ) {
        close $JSON_FL;
    }
}
1;
