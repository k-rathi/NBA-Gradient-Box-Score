#!/usr/bin/perl
#####################################################################################
#                            JSONHelper.pm
#
# Print out JSON Values
#
#####################################################################################
package JSONHelper;
use strict;
use warnings;
use Exporter;
#################################################################
our @ISA       = qw( Exporter );
our @EXPORT    = qw( jprintStartTag jprintEndTag jprintObjectStart jprintObjectEnd jprintListStart jprintListEnd jprintNameValue_Num jprintNameValue_Str jgetStartTag jgetEndTag jgetObjectStart jgetObjectEnd jgetListStart jgetListEnd jgetNameValue_Num jgetNameValue_Str );
#################################################################

#use Date::Calc qw(:all);
use File::Basename;
use Cwd qw(abs_path);
use DTUtil;

sub jprintStartTag(@)
{
    my $moduleName = "jprintStartTag";
    my ($pfx) = @_;
    printf ("$pfx\{\n");
}

sub jprintEndTag(@)
{
    my $moduleName = "jprintEndTag";
    my ($pfx) = @_;
    printf ("$pfx\}\n");
}

sub jprintArrayElementStart(@)
{
    my $moduleName = "jprintArrayElementStart";
    my ($pfx) = @_;
    printf ("$pfx\{\n");
}

sub jprintSeparator(@)
{
    my $moduleName = "jprintArrayElementSeparator";
    my ($pfx) = @_;
    printf ("$pfx,\n");
}

sub jprintArrayElementEnd(@)
{
    my $moduleName = "jprintArrayElementEnd";
    my ($pfx) = @_;
    printf ("$pfx\}\n");
}

sub jprintObjectStart(@)
{
    my $moduleName = "jprintObjectStart";
    my ($pfx, $n) = @_;
    printf ("$pfx\"$n\": {\n");
}

sub jprintObjectEnd(@)
{
    my $moduleName = "jprintEndTag";
    my ($pfx) = @_;
    printf ("$pfx\}\n");
}

sub jprintListStart(@)
{
    my $moduleName = "jprintListStart";
    my ($pfx, $n) = @_;
    printf ("$pfx\"$n\": [\n");
}

sub jprintListEnd(@)
{
    my $moduleName = "jprintListEnd";
    my ($pfx) = @_;
    printf ("$pfx],\n");
}

sub jprintNameValue_Str(@)
{
    my $moduleName = "jprintNameValue_Str";
    my ($pfx, $n, $v, $lastE) = @_;
#    if ( length($lastE) ) {
#        $lastE = "no";
#    }

    if ( length($lastE) && $lastE eq "last" ) {
        printf ("$pfx\"$n\": \"$v\"\n");
    } else {
        printf ("$pfx\"$n\": \"$v\",\n");
    }
}

sub jprintNameValue_Num(@)
{
    my $moduleName = "jprintNameValue_Num";
    my ($pfx, $n, $v, $lastE) = @_;
 
    if ( length($lastE) && $lastE eq "last" ) {
        printf ("$pfx\"$n\": $v\n");
    } else {
        printf ("$pfx\"$n\": $v,\n");
    }
}

sub jgetStartTag(@)
{
    my $moduleName = "jgetStartTag";
    my ($pfx) = @_;
    return "$pfx"."\{"."\n";
}

sub jgetEndTag(@)
{
    my $moduleName = "jgetEndTag";
    my ($pfx) = @_;
    return "$pfx"."\}"."\n";
}

sub jgetArrayElementStart(@)
{
    my $moduleName = "jgetArrayElementStart";
    my ($pfx) = @_;
    return "$pfx"."\{"."\n";
}

sub jgetSeparator(@)
{
    my $moduleName = "jgetArrayElementSeparator";
    my ($pfx) = @_;
    return "$pfx".","."\n";
}

sub jgetArrayElementEnd(@)
{
    my $moduleName = "jgetArrayElementEnd";
    my ($pfx) = @_;
    return "$pfx"."\}"."\n";
}

sub jgetObjectStart(@)
{
    my $moduleName = "jgetObjectStart";
    my ($pfx, $n) = @_;
    return "$pfx"."\"$n\"".": {"."\n";
}

sub jgetObjectEnd(@)
{
    my $moduleName = "jgetEndTag";
    my ($pfx) = @_;
    return "$pfx"."\}"."\n";
}

sub jgetListStart(@)
{
    my $moduleName = "jgetListStart";
    my ($pfx, $n) = @_;
    return "$pfx"."\"$n\"".": ["."\n";
}

sub jgetListEnd(@)
{
    my $moduleName = "jgetListEnd";
    my ($pfx) = @_;
    return "$pfx"."\],"."\n";
}

sub jgetNameValue_Str(@)
{
    my $moduleName = "jgetNameValue_Str";
    my ($pfx, $n, $v, $lastE) = @_;

    if ( length($lastE) && $lastE eq "last" ) {
        return "$pfx"."\"$n\"".": \"$v\""."\n";
    } else {
        return "$pfx"."\"$n\"".": \"$v\"".",\n";
    }
}

sub jgetNameValue_Num(@)
{
    my $moduleName = "jgetNameValue_Num";
    my ($pfx, $n, $v, $lastE) = @_;
 
    if ( length($lastE) && $lastE eq "last" ) {
        return "$pfx"."\"$n\"".": $v"."\n";
    } else {
        return "$pfx"."\"$n\"".": $v,"."\n";
    }
}
1;
