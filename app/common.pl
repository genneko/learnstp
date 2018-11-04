my $PORTSTATE = {
    unknown => {bg => "Gray", fg => "Black"},
    disabled => {bg => "#555555", fg => "White"},
    listening => {bg => "Orange", fg => "Black"},
    learning => {bg => "Yellow", fg => "Black"},
    forwarding => {bg => "Green", fg => "White"},
    blocking => {bg => "Pink", fg => "Black"},
    discarding => {bg => "Red", fg => "White"}
};
my $PORTROLE = {
    unknown => {abbr => "?"},
    disabled => {abbr => "X"},
    root => {abbr => "R"},
    designated => {abbr => "D"},
    alternate => {abbr => "A"},
    backup => {abbr => "B"}
};

sub list_bridge{
    my(@brlist) = @_;
    if(@brlist < 1){
        @brlist = split("\n", `ifconfig -g bridge`);
    }
    my $data = [];
    for my $brname (@brlist){
        push(@$data, get_bridge($brname));
    }
    return $data;
}

sub add_portinfo{
    my($list, $info) = @_;
    push(@$list, $info);
}

sub get_bridge{
    my($brname) = @_;
    my $portlist = [];
    my($id, $priority, $hellotime, $fwddelay, $rootid, $rootpriority, $rootcost, $rootport);
    my($portinfo, $portname, $portbasename);
    my @line = split(/\n/, `ifconfig $brname 2>/dev/null`);
    for(@line){
        if(/id ([0-9a-fA-F:]+) priority (\d+) hellotime (\d+) fwddelay (\d+)/){
            ($id, $priority, $hellotime, $fwddelay) = ($1, $2, $3, $4);
        }elsif(/root id ([0-9a-fA-F:]+) priority (\d+) ifcost (\d+) port (\d+)/){
            ($rootid, $rootpriority, $rootcost, $rootport) = ($1, $2, $3, $4);
        }elsif(/member: (\w+)/){
            if($portinfo){
                add_portinfo($portlist, $portinfo);
            }
            $portname = $portbasename = $1;
            $portbasename =~ s/[ab]$//;
            $portinfo = {};
            $portinfo->{name} = $portname;
            $portinfo->{basename} = $portbasename;
            $portinfo->{role} = "unknown";
            $portinfo->{state} = "unknown";
        }elsif($portinfo && /role (\w+) state (\w+)/){
            $portinfo->{role} = $1;
            $portinfo->{state} = $2;
            add_portinfo($portlist, $portinfo);
            $portinfo = undef;
        }elsif($portinfo && /port (\d+) priority (\d+) path cost (\d+) proto (\w+)/){
            $portinfo->{id} = $1;
            $portinfo->{priority} = $2;
            $portinfo->{pathcost} = $3;
            $portinfo->{proto} = $4;
        }
    }
    add_portinfo($portlist, $portinfo) if $portinfo;
    @$portlist = sort {$a->{name} cmp $b->{name}} @$portlist;
    return {
        name => $brname,
        id => $id,
        priority => $priority,
        hellotime => $hellotime,
        forwarddelay => $fwddelay,
        rootid => $rootid,
        rootpriority => $rootpriority,
        rootcost => $rootcost,
        rootport => $rootport,
        is_root => ($rootid ne "00:00:00:00:00:00" && $rootid eq $id && $rootpriority eq $priority),
        port => $portlist
    };
}

sub get_epairs_on_bridge{
    my($bridge) = @_;
    return () if !$bridge;
    my $br = get_bridge($bridge);
    return map { $_->{name} } @{$br->{port}};
}

sub get_epaired_bridges{
    my($epair) = @_;
    return () if !$epair;
    $epair =~ s/[ab]$//;
    my $data = list_bridge();
    my($a, $b, @list);
    foreach my $br (@$data){
        foreach my $po (@{$br->{port}}){
            if($po->{name} =~ /${epair}a/){
                $a = $br->{name};
            }elsif($po->{name} =~ /${epair}b/){
                $b = $br->{name};
            }
        }
    }
    push(@list, $a) if $a;
    push(@list, $b) if $b;
    return @list;
}

sub pretty_format{
    my($list) = @_;
    my($data, $init);
    foreach my $bridge (@$list){
        $data .= sprintf("%s%s %d.%s%s%s\n", ($init++ ? "\n" : ""), @{$bridge}{"name", "priority", "id"},
            ($bridge->{is_root} ? " [root]" : ""),
            ($bridge->{is_root} ? "" : " desig root $bridge->{rootpriority}.$bridge->{rootid} cost $bridge->{rootcost}")) if !$list_port;
        foreach my $port (@{$bridge->{port}}){
            $data .= sprintf("  %-8s proto %-4s  id %3d.%-3d cost %6d: %10s / %10s\n",
                @{$port}{"name", "proto", "priority", "id", "pathcost", "role", "state"});
        }
    }
    return $data;
}

sub _by_id{
    $a->{id} cmp $b->{id}
}

sub simplify_bid{
    my($list) = @_;
    my $i = 0;
    foreach my $bridge (sort _by_id @$list){
        $bridge->{id0} = $i++;
    }
    return $list;
}

sub visjs_format{
    my($list) = @_;
    my $nodes = [];
    my $edges = [];
    my $edgemap = {};
    my $nodeidmap = {};
    my $edgeidmap = {};
    my $edge;

    foreach my $bridge (@{simplify_bid($list)}){
        push(@$nodes, {
                id => $bridge->{name},
                label => sprintf("%s\n%d.%02x\n(%s)", @{$bridge}{"name","priority","id0"}, ($bridge->{is_root} ? "Root" : $bridge->{rootcost})),
                title => sprintf("%s%s<br>id: %d.%s<br>rootid: %d.%s<br>rootcost: %d",
                    $bridge->{name},
                    ($bridge->{is_root} ? " [root]" : ""),
                    $bridge->{priority},
                    $bridge->{id},
                    $bridge->{rootpriority},
                    $bridge->{rootid},
                    $bridge->{rootcost}
                ),
                color => {
                    background => ($bridge->{is_root} ? "gold" : "silver"),
                },
                shape => 'box',
                borderWidth => 2,
                font => {
                    size => 14
                },
                margin => 5,
                size => 10,
                chosen => \0,
                objType => 'bridge',
                objData => $bridge
            });
        $nodeidmap->{$bridge->{name}} = 1;

        foreach my $port (@{$bridge->{port}}){
            push(@$nodes, {
                    id => $port->{name},
                    label => $PORTROLE->{$port->{role}}->{abbr},
                    title => sprintf("%s<br>proto: %s<br>role: %s<br>state: %s<br>pathcost: %d<br>id: %d.%s",
                        $port->{name},
                        $port->{proto},
                        $port->{role},
                        $port->{state},
                        $port->{pathcost},
                        $port->{priority},
                        $port->{id}
                    ),
                    color => {
                        background => ($port->{role} eq "disabled" ? $PORTSTATE->{"disabled"}->{bg} : $PORTSTATE->{$port->{state}}->{bg}),
                    },
                    font => {
                        color => ($port->{role} eq "disabled" ? $PORTSTATE->{"disabled"}->{fg} : $PORTSTATE->{$port->{state}}->{fg}),
                    },
                    shape => 'circle',
                    size => 10,
                    mass => 0.7,
                    chosen => \0,
                    objType => 'port',
                    objData => $port
                });
            $nodeidmap->{$port->{name}} = 1;
            push(@$edges, {
                    id => $bridge->{name} . "_" . $port->{name},
                    label => sprintf("%s\n%d.%d", @{$port}{"name","priority","id"}),
                    from => $bridge->{name},
                    to => $port->{name},
                    selectionWidth => 0,
                    length => 35,
                    chosen => \0,
                    objType => 'bplink'
                });
            $edgeidmap->{$bridge->{name} . "_" . $port->{name}} = 1;
            if($edge = $edgemap->{$port->{basename}}){
                $edge->{to} = $port->{name};
                $edge->{toState} = $port->{state};
                $edge->{toRole} = $port->{role};
                if($edge->{fromState} eq "forwarding" && $edge->{toState} eq "forwarding"){
                    $edge->{width} = 6;
                    $edge->{dashes} = \0;
                    $edge->{color}->{color} = 'dodgerblue';
                }elsif($edge->{fromRole} eq "disabled" && $edge->{toRole} eq "disabled"){
                    $edge->{width} = 1;
                    $edge->{dashes} = 1;
                    $edge->{color}->{color} = 'grey';
                }
            }else{
                $edgemap->{$port->{basename}} = {
                    id => $port->{basename},
                    label => $port->{basename},
                    from => $port->{name},
                    selectionWidth => 0,
                    length => 250,
                    smooth => {
                        type => 'dynamic'
                    },
                    color => {
                        color => 'dodgerblue'
                    },
                    chosen => \0,
                    objType => 'pplink',
                    fromState => $port->{state},
                    fromRole => $port->{role},
                    width => 1,
                    dashes => \0 
                };
                $edgeidmap->{$port->{basename}} = 1;
            }
        }
    }

    foreach my $edgename (sort {$a cmp $b} keys %$edgemap){
        push(@$edges, $edgemap->{$edgename});
    }
    return {
        nodes => $nodes,
        edges => $edges,
        nodeidmap => $nodeidmap,
        edgeidmap => $edgeidmap
    };
}

1;
