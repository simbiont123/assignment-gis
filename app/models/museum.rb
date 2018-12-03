class Museum < ApplicationRecord

  # get all museums and galleries with range to parking
  def self.get_all_with_distance(params)
    build_geoJSON_all_with_distance(ActiveRecord::Base.connection.execute(<<SQL))
    WITH m AS (SELECT m.*, ST_Distance(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography) AS distance2
    FROM museums_points m
    WHERE ST_DWithin(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography, '#{params[:range]}'))
    SELECT m.name,m.distance2,ST_AsGeoJSON(p.way) AS geometry,ST_AsGeoJSON(m.way) AS geometry2,ST_Distance(m.way::geography, p.way::geography) AS distance FROM m
    CROSS JOIN museums_parking p 
    WHERE ST_DWithin(m.way::geography, p.way::geography, '#{params[:range2]}')
    ORDER BY distance ASC
SQL
  end

  # get all museums as area within 4 points (polygon)
  def self.get_all_within_polygon(params)
    build_geoJSON_all_with_polygon(ActiveRecord::Base.connection.execute(<<SQL))
    SELECT name,amenity,shop, ST_Area(way::geography)*POWER(0.3048,2) AS distance, ST_AsGeoJSON(way) AS geometry
    FROM museums
    WHERE ST_Contains(ST_SetSRID(ST_MakePolygon(ST_GeomFromText('LINESTRING(#{params[:lon1]} #{params[:lat1]},#{params[:lon2]} #{params[:lat2]},#{params[:lon3]} #{params[:lat3]},#{params[:lon4]} #{params[:lat4]},#{params[:lon1]} #{params[:lat1]})')),4326)::geometry, way::geometry)
    ORDER BY distance ASC
SQL
  end

  # get all museums intersect line
  def self.get_all_within_line(params)
    build_geoJSON_all_with_line(ActiveRecord::Base.connection.execute(<<SQL))
    WITH m AS (SELECT name,amenity,shop,way AS way2, ST_AsGeoJSON(way) AS geometry
    FROM museums
    WHERE ST_Intersects(ST_SetSRID(ST_MakeLine(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'), ST_MakePoint('#{params[:lon1]}', '#{params[:lat1]}')),4326)::geometry, way::geometry))
    SELECT m.*, ST_AsGeoJSON(l.way) AS geometry2
    FROM m
    CROSS JOIN lines_footway l 
    WHERE ST_Intersects(m.way2::geometry, l.way::geometry)
SQL
  end

  # get all museums and galleries with range to point of interest
  def self.get_all_with_range(params)
   build_museums_geoJSON(ActiveRecord::Base.connection.execute(<<SQL))
  SELECT name,amenity,shop, ST_Distance(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography) AS distance,
      ST_AsGeoJSON(way) as geometry
  FROM museums_points
  WHERE ST_DWithin(ST_SetSRID(ST_MakePoint('#{params[:lon]}', '#{params[:lat]}'),4326)::geography, way::geography, '#{params[:range]}')
  ORDER BY distance ASC

SQL
  end

  # descritpion for all museums and galleries with range to point of interest
  def self.build_museums_geoJSON (museums)
    geoJSON = []

    museums.each do |museum|
      amenity = museum["amenity"]
      unless amenity
        amenity = "not available"
      end

      shop = museum["shop"]
      unless shop
        shop = "not available"
      end

      distance = museum["distance"].round(2)
      unless distance
        distance = "not available"
      end

      geoJSON << {
          "title": museum["name"],
          "distance": "#{distance}",
          "type": "Feature",
          "geometry": JSON.parse(museum["geometry"]),
          "properties": {
              "title": museum["name"],
              "description": "Amenity: #{amenity} | #{"\nShop: "} #{shop} | Distance to point: #{distance} m",
              "marker-color": color(museum["distance"]),
              "marker-size": "large",
              "marker-symbol": "museum"
          }
      }
    end
    geoJSON
  end

  # descritpion for all museums and galleries with range to parking
  def self.build_geoJSON_all_with_distance(museums)
    geoJSON = []

    museums.each do |museum|
      amenity = museum["amenity"]
      unless amenity
        amenity = "not available"
      end

      shop = museum["shop"]
      unless shop
        shop = "not available"
      end

      distance = museum["distance"].round(2)
      unless distance
        distance = "not available"
      end

      geoJSON << {
          "title": museum["name"],
          "distance": "#{distance}",
          "type": "Feature",
          "geometry": JSON.parse(museum["geometry"]),
          "properties": {
              "title": museum["name"],
              "description": "Amenity: #{amenity} | #{"\nShop: "} #{shop} | Distance to closest museum: #{distance} m",
              "marker-color": color(museum["distance"]),
          }
      }
    end

    museums.each do |museum|
      amenity = museum["amenity"]
      unless amenity
        amenity = "not available"
      end

      shop = museum["shop"]
      unless shop
        shop = "not available"
      end

      distance = museum["distance"]
      unless distance
        distance = "not available"
      end

      distance2 = museum["distance2"].round(2)
      unless distance2
        distance2 = "not available"
      end

      geoJSON << {
          "type": "Feature",
          "geometry": JSON.parse(museum["geometry2"]),
          "properties": {
              "title": museum["name"],
              "description": "Amenity: #{amenity} | #{"\nShop: "} #{shop} | Distance to closest parking: #{distance} m | #{"\nDistance to point: "} #{distance2} m",
              "marker-color": color(museum["distance"]),
              "marker-size": "large",
              "marker-symbol": "museum"
          }
      }
      end
    geoJSON
  end

  # description of all museums within polygon
  def self.build_geoJSON_all_with_polygon(museums)
    geoJSON = []

    museums.each do |museum|
      amenity = museum["amenity"]
      unless amenity
        amenity = "not available"
      end

      shop = museum["shop"]
      unless shop
        shop = "not available"
      end

      distance = museum["distance"].round(2)
      unless distance
        distance = "not available"
      end

      geoJSON << {
          "title": museum["name"],
          "distance": "#{distance}",
          "type": "Feature",
          "geometry": JSON.parse(museum["geometry"]),
          "properties": {
              "title": museum["name"],
              "description": "Amenity: #{amenity} | #{"\nShop: "} #{shop} | Area: #{distance} m^2",
              "color": "#ffffff"
          }
      }
    end
    geoJSON
  end

  # desc for all museums intersect line
  def self.build_geoJSON_all_with_line(museums)
    geoJSON = []

    museums.each do |museum|
      amenity = museum["amenity"]
      unless amenity
        amenity = "not available"
      end

      shop = museum["shop"]
      unless shop
        shop = "not available"
      end

      geoJSON << {
          "title": museum["name"],
          "type": "Feature",
          "geometry": JSON.parse(museum["geometry"]),
          "properties": {
              "title": museum["name"],
              "description": "Amenity: #{amenity} | #{"\nShop: "} #{shop}",
          }
      }
    end

    museums.each do |museum|
      geoJSON << {
          "type": "Feature",
          "geometry": JSON.parse(museum["geometry2"]),
      }
    end
    geoJSON
  end

  # distance colors
  def self.color(distance)
    if distance < 500
      "#00FF00"
    elsif distance < 1200
      "#00cc00"
    elsif distance < 1900
      "#009900"
    elsif distance < 2600
      "#006600"
    elsif distance < 3300
      "#003300"
    else
      "#000000"
    end
  end
end

