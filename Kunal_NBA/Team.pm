#!/usr/bin/perl
#use strict;
#
package Team;

use DTUtil;
use PlayerStat;
use JSONHelper;

sub new
{
    my $class = shift;
    my $self = {
        _name_key          => shift,
        _name              => shift,
        _inactivePlayers   => shift,
        _playerArray       => [@_],
    };
    bless $self, $class;
    return $self;
}

sub printTeam()
{
    my $moduleName = "printTeam";
    my ($self) = @_;


    my @PL_ARRAY = @{ $self->{_playerArray} };
    printf "\n";
    printf "Team NAME          =%-40s (%s)\n",$self->{_name}, $self->{_name_key};

    printf "Total Players: %d\n", scalar(@PL_ARRAY);
    my $c;
    foreach $c (@PL_ARRAY)
    {
         bless($c, PlayerStat);
printDebug 2, "$moduleName", "----------------------------- Player Reference:".$c;
         $c->printOnePlayerStat();
         $i++;
    }
    printf "\n";
}

sub printTeamCSV()
{
    my $moduleName = "printTeamCSV";
    my ($self) = @_;
    my $SEP = "|";

    my $team_header = "$self->{_name_key}$SEP";
    printf "$team_header\n";

    my @PL_ARRAY = @{ $self->{_playerArray} };

    my $c;
    foreach $c (@PL_ARRAY)
    {
         bless($c, PlayerStat);
         $c->printOnePlayerStatCSV();
    }
}

sub printTeamJSON(@)
{
    my $moduleName = "printTeamJSON";
    my ($self, $HomeOrAway) = @_;
    my $prefix_spaces1 = "        ";
    my $prefix_spaces2 = "            ";

    JSONHelper::jprintObjectStart($prefix_spaces1, "$HomeOrAway");

    JSONHelper::jprintNameValue_Str($prefix_spaces2, "NameKey", "$self->{_name_key}");
    JSONHelper::jprintNameValue_Str($prefix_spaces2, "Name", "$self->{_name}");

    my @PL_ARRAY = @{ $self->{_playerArray} };

    JSONHelper::jprintListStart($prefix_spaces2, "PlayerStatsList");
    my $i = 0;
    my $c;
    foreach $c (@PL_ARRAY)
    {
         if ($i > 0) {
             JSONHelper::jprintSeparator($prefix_spaces2);
         }
         bless($c, PlayerStat);
         JSONHelper::jprintArrayElementStart($prefix_spaces2);
         $c->printOnePlayerStatJSON();
         JSONHelper::jprintArrayElementEnd($prefix_spaces2);
         $i++;
    }
    JSONHelper::jprintListEnd($prefix_spaces2);

    JSONHelper::jprintNameValue_Str($prefix_spaces2, "InactivePlayers", "$self->{_inactivePlayers}", "last");

    JSONHelper::jprintObjectEnd($prefix_spaces1);
}

sub getTeamJSONString(@)
{
    my $moduleName = "getTeamJSONString";
    my ($self, $HomeOrAway) = @_;
    my $prefix_spaces1 = "        ";
    my $prefix_spaces2 = "            ";

    my $retString = ""
        . JSONHelper::jgetObjectStart($prefix_spaces1, "$HomeOrAway")
        . JSONHelper::jgetNameValue_Str($prefix_spaces2, "NameKey", "$self->{_name_key}")
        . JSONHelper::jgetNameValue_Str($prefix_spaces2, "Name", "$self->{_name}");

    my @PL_ARRAY = @{ $self->{_playerArray} };

    $retString = $retString
        . JSONHelper::jgetListStart($prefix_spaces2, "PlayerStatsList");

    my $i = 0;
    my $c;
    foreach $c (@PL_ARRAY)
    {
         if ($i > 0) {
             $retString = $retString . JSONHelper::jgetSeparator($prefix_spaces2)
         }
         bless($c, PlayerStat);
         $retString = $retString
             . JSONHelper::jgetArrayElementStart($prefix_spaces2)
             . $c->getOnePlayerStatJSONString()
             . JSONHelper::jgetArrayElementEnd($prefix_spaces2);
         $i++;
    }

    $retString = $retString
        . JSONHelper::jgetListEnd($prefix_spaces2)
        . JSONHelper::jgetNameValue_Str($prefix_spaces2, "InactivePlayers", "$self->{_inactivePlayers}", "last")
        . JSONHelper::jgetObjectEnd($prefix_spaces1);

    return $retString;

}
1;
