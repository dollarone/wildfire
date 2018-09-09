var express = require('express');
var bodyParser = require('body-parser');
var request = require('request');
var app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false} ));
//app.use(express.methodOverride());
//app.use(bodyParser.json());
var numlevels = 2;

app.use(function(req, res, next) {
   res.header("Access-Control-Allow-Origin", "http://localhost:8081");
   res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
   res.header('Access-Control-Allow-Methods', 'PUT, POST, GET, DELETE, OPTIONS');
   next();
});

app.get("/wildfire/v1/numlevels", function(req, res) {
    console.log("/wildfire/v1/numlevels " + numlevels);
    res.send(JSON.stringify({ numlevels: numlevels }, null, 3));
});

app.get("/wildfire/v1/level", function(req, res) {
    console.log("GET " + req.query.level );
    if (req.query.level != null) {
        if (req.query.level < numlevels) {

        }
    }

    var fs = require('fs');
    var obj;

    // Read the file and send to the callback
    fs.readFile('./maps.json', handleFile)

    // Write the callback function
    function handleFile(err, data) {
        var statuscode=1
        if (err) throw err
        var all = JSON.parse(data);
         numlevels=all.maps.length;
        for(var i = 0; i < all.maps.length; i++) {
            var obj2 = all.maps[i];
            if(obj2.num == req.query.level) {
                console.log("GETLEVEL MATCH");
                found = i
               // i = all.maps.length;
                //statuscode=1
                leveldata = all.maps[i];
                delete leveldata.secretdata;
                delete leveldata.secret;
                res.send(JSON.stringify(leveldata), null, 3);
                console.log("returning " + JSON.stringify(leveldata));
                return
            }
        }

        res.send(JSON.stringify({ statuscode: 2 }, null, 3));
    }
});

app.put("/wildfire/v1/level", function(req, res) {
    console.log("PUT " + req.body.levelname);
    /*
    if (req.body["levelname"] != null &&
        req.body["author"] != null &&
        req.body["secret"] != null &&
        req.body["map"] != null) {
        // happy path

    }
    else {
    }
    var data = {
        author: "",
        levelname: "",
        code: "",
        hash: "",
        levelnamedata: [],
        authordata: [],
        secretdata: [],
        mapdata: []
    };
    */

    var fs = require('fs');
    var obj;

    // Read the file and send to the callback
    fs.readFile('./maps.json', handleFile)

    // Write the callback function
    function handleFile(err, data) {
        var statuscode=1
        if (err) throw err
         var all = JSON.parse(data);
        var cont=true
        for(var i = 0; i < all.maps.length; i++) {
            var obj2 = all.maps[i];

            console.log(obj2.hash);
            if(obj2.hash == req.body.hash) {
                console.log("MATCH");
                if(obj2.secret == req.body.secret) {
                    // replace

                    //delete all.maps[i];
                    //req.body.num = obj2.num
                    //all['maps'].push(req.body);
                    all.maps[i] = req.body;
                    all.maps[i].num = obj2.num
                    console.log("REPLACED " + obj2.num);
                    i = all.maps.length;
                    statuscode=2
                    //res.send(JSON.stringify({ statuscode: statuscode }, null, 3));
                    cont=false
                }
                else {
                    statuscode=3
                    console.log("WRONG SECRET for " + obj2.num);
                    i = all.maps.length;
                    //res.send(JSON.stringify({ statuscode: statuscode }, null, 3));
                    cont=false

                }
            }
        }
        if (cont) {
            all = updateMaps(all);
           // writeToFile(all);
            //numlevels=all.maps.length
            console.log("new number " + numlevels);
        }
        writeToFile(all);
        //res.send(obj);
        res.send(JSON.stringify({ statuscode: statuscode }, null, 3));
    }
    
    function updateMaps(data) {
        var hash = req.body.hash;
        var secret = req.body.secret;
        /*
        var levelname = req.body["levelname"]; 
        var author = req.body["author"];
        var secret = req.body["secret"];
        */
        var all = data;//JSON.parse(data);
        //console.log(all)
        numlevels=all.maps.length+1
        req.body.num = numlevels
        all['maps'].push(req.body);

        console.log("adding " + hash + " with secret: " + secret);
        return all;
    }

    function writeToFile(data) {
        var path = './maps.json';

        fs.writeFile(path, JSON.stringify(data, null, 4), function(err) {

            if(err) {
                console.log(err);
            } else {
                console.log("maps.JSON ("  + ") saved to " + path);
            }       
        }); 
    }
});

var server = app.listen(9081, function() {
    var host = server.address().address;
    var port = server.address().port;

    console.log("App listening at http://%s:%s", host, port);
});

