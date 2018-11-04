#!/usr/bin/env perl
use strict;
use Mojolicious::Lite;
use FindBin;
use lib $FindBin::Bin;
require "common.pl";

get '/bridge' => sub {
    my $c = shift;
    my $data = list_bridge();
    $c->render(json => $data);
};

get '/bridge/visjs' => sub {
    my $c = shift;
    my $data = list_bridge();
    my $visjsdata = visjs_format($data);
    $c->render(json => $visjsdata);
};

app->start;

