"use strict";
var canvas;
var initialized;
var network;
var nodes;
var edges;

function remove(data){
    nodes.forEach(function(item){
        if(! data.nodeidmap[item.id]){
            nodes.remove(item.id);
        }
    });
    edges.forEach(function(item){
        if(! data.edgeidmap[item.id]){
            edges.remove(item.id);
        }
    });
}

function update(data){
    remove(data);
    nodes.update(data.nodes);
    edges.update(data.edges);
}

function initialize(data){
    nodes = new vis.DataSet(data.nodes);
    edges = new vis.DataSet(data.edges);
    network = new vis.Network(canvas, {
        nodes: nodes,
        edges: edges
    }, {
        layout: {
            randomSeed: 644621
        }
    });
    initialized = true;
}

function resize(){
    $(canvas).height($(window).innerHeight() - $('#title').innerHeight() - 50);
}

function draw(data){
    if(! initialized){
        initialize(data);
    }else{
        update(data);
    }
}

function query(){
    $.ajax({
        url: "/bridge/visjs",
        dataType: 'json',
        async: true,
        success: function(data){
            draw(data);
        }
    });
}

$(function(){
    canvas = document.getElementById('canvas');
    $(window).resize(function(){
        resize();
    });
    resize();
    query();
    setInterval(query, 2000);
});
