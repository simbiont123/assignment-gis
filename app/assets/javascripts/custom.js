$(document).ready(function() {
    L.mapbox.accessToken = 'pk.eyJ1Ijoic2ltYmlvbnQxMjM0NTYiLCJhIjoiY2pvN2xhdm1wMDNhMjN2azVraHViY2lybyJ9._-Hx7lWhlyWEPvYOYbq3gg';
    var map = L.mapbox.map('map').setView([55.751244, 37.618423], 10);
    L.mapbox.styleLayer('mapbox://styles/simbiont123456/cjp5ou0142sx12rpg9ajp8yyx').addTo(map);
    var Layers = L.mapbox.featureLayer().addTo(map);

    //set data from GeoJSON
    ajax = function(url){
        $.ajax({
            type: "GET",
            url: url,
            dataType: "json",
            success: function(data){
                console.log(data);
                Layers.setGeoJSON(data).addTo(map);
                $("#table-of-contents-navigation tbody").remove();
                var tbl_body = document.createElement("tbody");
                var odd_even = false;
                $.each(data, function() {
                    var tbl_row = tbl_body.insertRow();
                    tbl_row.className = odd_even ? "odd" : "even";
                    $.each(this, function(k , v) {
                        if ((k === 'title') || (k === "distance")) {
                            var cell = tbl_row.insertCell();
                            cell.append(document.createTextNode(v.toString()));
                        }
                    })
                    odd_even = !odd_even;
                })
                $("#table-of-contents-navigation").append(tbl_body);
            }
        });
    }

    // Change the selector if needed
    var $table = $('table-of-contents-navigation'),
        $bodyCells = $table.find('tbody tr:first').children(),
        colWidth;

    // Adjust the width of thead cells when window resizes
    $(window).resize(function() {
        // Get the tbody columns width array
        colWidth = $bodyCells.map(function() {
            return $(this).width();
        }).get();

        // Set the width of thead columns
        $table.find('thead tr').children().each(function(i, v) {
            $(v).width(colWidth[i]);
        });
    }).resize(); // Trigger resize handler

    // initialization
    var polygon = false;
    var home = false;
    var line = false;
    var all = false;

    // set and clear market after click (museums in range variables)
    var theMarker = null;
    var lat = null;
    var lon = null;

    // show museums within polygon (4 points selected)
    var theMarkersLat = [];
    var theMarkersLon = [];
    var theMarkers = [];
    var lat1 = null;
    var lon1 = null;

    // show all museums
    $("#home").click(function () {
        alert("Zvolte bod na mape!");
        polygon = false;
        home = true;
        line = false;
        all = false;
    })

    // show museums in polygon
    $("#polygon").click(function () {
        alert("Zvolte 4 body na mape!");
        polygon = true;
        home = false;
        line = false;
        all = false;
    })

    $("#line").click(function () {
        alert("Zvolte 2 body na mape!");
        polygon = false;
        home = false;
        line = true;
        all = false;
    })

    $("#all").click(function () {
        alert("Zvolte bod na mape!");
        polygon = false;
        home = false;
        line = false;
        all = true;
    })

    map.on('click',function(e){
        if (polygon){
            $("#table-of-contents-navigation th").remove();
            $('#table-of-contents-navigation thead tr').append('<th>Name</th>\n' +
                '    <th>Area (in meters^2)</th>');
            lat1 = e.latlng.lat;
            lon1 = e.latlng.lng;

            var marker = L.marker([lat1, lon1]).addTo(map);

            theMarkers.push(marker);
            theMarkersLat.push(lat1);
            theMarkersLon.push(lon1);
            if (theMarkers.length === 4) {
                map.setView([(theMarkersLat[0]+theMarkersLat[2])/2, (theMarkersLon[0]+theMarkersLon[2])/2], 12);
                ajax('museums/polygon?lat1=' + theMarkersLat.pop() + '&lon1=' + theMarkersLon.pop() + '&lat2=' + theMarkersLat.pop() + '&lon2=' + theMarkersLon.pop() + '&lat3=' + theMarkersLat.pop() + '&lon3=' + theMarkersLon.pop() + '&lat4=' + theMarkersLat.pop() + '&lon4=' + theMarkersLon.pop());
            }
        }
        else if (home) {
            $("#table-of-contents-navigation th").remove();
            $('#table-of-contents-navigation thead tr').append('<th>Name</th>\n' +
                '    <th>Distance to closest museums (in meters)</th>');
            lat = e.latlng.lat;
            lon = e.latlng.lng;

            if (theMarker != undefined) {
                map.removeLayer(theMarker);
            }

            //add a marker to show where you clicked.
            theMarker = L.marker([lat, lon]).addTo(map);
            if (theMarker != null) {
                var range = $('#range3').val();
                var range2 = $('#range2').val();
                map.setView([lat, lon], 12);
                ajax('museums/all?lat=' + lat + '&lon=' + lon + '&range=' + range + '&range2=' + range2);
            }
        }
        else if (all) {
            $("#table-of-contents-navigation th").remove();
            $('#table-of-contents-navigation thead tr').append('<th>Name</th>\n' +
                '    <th>Distance to point (in meters)</th>');
            lat = e.latlng.lat;
            lon = e.latlng.lng;

            if (theMarker != undefined) {
                map.removeLayer(theMarker);
            }

            //add a marker to show where you clicked.
            theMarker = L.marker([lat, lon]).addTo(map);
            if (theMarker != null) {
                var range = $('#range').val();
                map.setView([lat, lon], 12);
                ajax('museums/all_range?lat=' + lat + '&lon=' + lon + '&range=' + range);
            }
        }
        else if (line) {
            $("#table-of-contents-navigation th").remove();
            $('#table-of-contents-navigation thead tr').append('<th>Name</th>');
            lat1 = e.latlng.lat;
            lon1 = e.latlng.lng;

            var marker = L.marker([lat1, lon1]).addTo(map);

            theMarkers.push(marker);
            theMarkersLat.push(lat1);
            theMarkersLon.push(lon1);
            if (theMarkers.length === 2) {
                map.setView([(theMarkersLat[0]+theMarkersLat[1])/2, (theMarkersLon[0]+theMarkersLon[1])/2], 12);
                ajax('museums/line?lat=' + theMarkersLat.pop() + '&lon=' + theMarkersLon.pop() + '&lat1=' + theMarkersLat.pop() + '&lon1=' + theMarkersLon.pop());
            }
        }
    });

    //clear map
    $("#clear").click(function () {
        if (theMarker)
            map.removeLayer(theMarker);
        while (theMarkers.length != 0){
            map.removeLayer(theMarkers.pop());
        }
        theMarker = null;
        theMarkers = [];
        $("#table-of-contents-navigation tbody").remove();
        Layers.clearLayers();
        map.setView([55.751244, 37.618423], 10);
    })
});