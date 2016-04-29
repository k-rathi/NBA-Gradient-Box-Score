#!/usr/bin/perl
use strict;
#
package PlayerStat;

use JSONHelper;

sub new
{
    my $class = shift;
    my $self = {
        _name          => "-",
        _position      => "-",
        _min_sec       => "0",
        _fg_m          => "0",
        _fg_a          => "0",
        _pt3_m         => "0",
        _pt3_a         => "0",
        _ft_m          => "0",
        _ft_a          => "0",
        _plus_minus    => "",
        _reb_off       => "0",
        _reb_def       => "0",
        _reb_tot       => "0",
        _assits        => "0",
        _pfouls        => "0",
        _steals        => "0",
        _turnovers     => "0",
        _block_shots   => "0",
        _block_against => "0",
        _points        => "0",
    };
    bless $self, $class;
    return $self;
}

sub setPosition {
    my ( $self, $position ) = @_;
    $self->{_position} = $position if defined($position);
    return $self->{_position};
}

sub printOnePlayerStat()
{
    my $moduleName = "printOnePlayerStat";
    my ($self) = @_;
    printf "\n";
    printf "NAME           =%-40s\n",$self->{_name};
    printf "    position       =%-40s\n",$self->{_position};
    printf "    min_sec        =%-40s\n",$self->{_min_sec};
    printf "    fg_m           =%-40s\n",$self->{_fg_m};
    printf "    fg_a           =%-40s\n",$self->{_fg_a};
    printf "    pt3_m          =%-40s\n",$self->{_pt3_m};
    printf "    pt3_a          =%-40s\n",$self->{_pt3_a};
    printf "    ft_m           =%-40s\n",$self->{_ft_m};
    printf "    ft_a           =%-40s\n",$self->{_ft_a};
    printf "    plus_minus     =%-40s\n",$self->{_plus_minus};
    printf "    reb_off        =%-40s\n",$self->{_reb_off};
    printf "    reb_def        =%-40s\n",$self->{_reb_def};
    printf "    reb_tot        =%-40s\n",$self->{_reb_tot};
    printf "    assists        =%-40s\n",$self->{_assists};
    printf "    pfouls         =%-40s\n",$self->{_pfouls};
    printf "    steals         =%-40s\n",$self->{_steals};
    printf "    turnovers      =%-40s\n",$self->{_turnovers};
    printf "    block_shots    =%-40s\n",$self->{_block_shots};
    printf "    block_against  =%-40s\n",$self->{_block_against};
    printf "    points         =%-40s\n",$self->{_points};
    printf "\n";
}

sub printOnePlayerStatCSV()
{
    my $moduleName = "printOnePlayerStatCSV";
    my $SEP = "|";
    my ($self) = @_;
    my $stat_line = 
"$self->{_name}$SEP$self->{_position}$SEP$self->{_min_sec}$SEP$self->{_fg_m}$SEP$self->{_fg_a}$SEP$self->{_pt3_m}$SEP$self->{_pt3_a}$SEP$self->{_ft_m}$SEP$self->{_ft_a}$SEP$self->{_plus_minus}$SEP$self->{_reb_off}$SEP$self->{_reb_def}$SEP$self->{_reb_tot}$SEP$self->{_assists}$SEP$self->{_pfouls}$SEP$self->{_steals}$SEP$self->{_turnovers}$SEP$self->{_block_shots}$SEP$self->{_block_against}$SEP$self->{_points}$SEP";
    printf "$stat_line\n";
}

sub printOnePlayerStatJSON()
{
    my $moduleName = "printOnePlayerStatCSV";
    my ($self) = @_;
    my $prefix_spaces1 = "                ";
    my $prefix_spaces2 = "                    ";

    #JSONHelper::jprintObjectStart($prefix_spaces1, "PlayerStat");
    
    JSONHelper::jprintNameValue_Str($prefix_spaces2, "name", $self->{_name});
    JSONHelper::jprintNameValue_Str($prefix_spaces2, "position", $self->{_position});
    JSONHelper::jprintNameValue_Str($prefix_spaces2, "min_sec", $self->{_min_sec});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "fg_m", $self->{_fg_m});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "fg_a", $self->{_fg_a});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "pt3_m", $self->{_pt3_m});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "pt3_a", $self->{_pt3_a});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "ft_m", $self->{_ft_m});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "ft_a", $self->{_ft_a});
    JSONHelper::jprintNameValue_Str($prefix_spaces2, "plus_minus", $self->{_plus_minus});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "reb_off", $self->{_reb_off});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "reb_def", $self->{_reb_def});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "reb_tot", $self->{_reb_tot});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "assists", $self->{_assists});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "pfouls", $self->{_pfouls});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "steals", $self->{_steals});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "turnovers", $self->{_turnovers});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "block_shots", $self->{_block_shots});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "block_against", $self->{_block_against});
    JSONHelper::jprintNameValue_Num($prefix_spaces2, "points", $self->{_points}, "last");

    #JSONHelper::jprintObjectEnd($prefix_spaces1);
}

sub getOnePlayerStatJSONString()
{
    my $moduleName = "getOnePlayerStatJSONString";
    my ($self) = @_;
    my $prefix_spaces1 = "                ";
    my $prefix_spaces2 = "                    ";

    my $retString = ""
            . JSONHelper::jgetNameValue_Str($prefix_spaces2, "name", $self->{_name})
            . JSONHelper::jgetNameValue_Str($prefix_spaces2, "position", $self->{_position})
            . JSONHelper::jgetNameValue_Str($prefix_spaces2, "min_sec", $self->{_min_sec})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "fg_m", $self->{_fg_m})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "fg_a", $self->{_fg_a})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "pt3_m", $self->{_pt3_m})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "pt3_a", $self->{_pt3_a})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "ft_m", $self->{_ft_m})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "ft_a", $self->{_ft_a})
            . JSONHelper::jgetNameValue_Str($prefix_spaces2, "plus_minus", $self->{_plus_minus})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "reb_off", $self->{_reb_off})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "reb_def", $self->{_reb_def})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "reb_tot", $self->{_reb_tot})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "assists", $self->{_assists})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "pfouls", $self->{_pfouls})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "steals", $self->{_steals})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "turnovers", $self->{_turnovers})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "block_shots", $self->{_block_shots})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "block_against", $self->{_block_against})
            . JSONHelper::jgetNameValue_Num($prefix_spaces2, "points", $self->{_points}, "last")
    ;

    return $retString;
}
1;
