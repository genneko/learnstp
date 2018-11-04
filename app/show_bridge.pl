#!/usr/bin/env perl
use strict;
use Mojo::JSON qw(encode_json);
use FindBin;
use lib $FindBin::Bin;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
require "common.pl";

my $output_json;
my $output_json_for_visjs;
my $list_epaired_bridges;
my $list_epairs_on_bridge;
GetOptions(
    "output-json|j" => \$output_json,
    "output-json-for-visjs|J" => \$output_json_for_visjs,
    "list-epaired-bridges|e" => \$list_epaired_bridges,
    "list-epairs-on-bridge|E" => \$list_epairs_on_bridge
);

if($list_epaired_bridges){
    my $epair = shift @ARGV;
    print join(" ", get_epaired_bridges($epair)) . "\n";
}elsif($list_epairs_on_bridge){
    my $bridge = shift @ARGV;
    print join(" ", get_epairs_on_bridge($bridge)) . "\n";
}elsif($output_json){
    my $result = list_bridge();
    print encode_json($result);
}elsif($output_json_for_visjs){
    my $result = list_bridge();
    print encode_json(visjs_format($result));
}else{
    my $result = list_bridge();
    print pretty_format($result);
}

