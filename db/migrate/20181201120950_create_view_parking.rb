class CreateViewParking < ActiveRecord::Migration[5.1]
  def up
    self.connection.execute %Q( CREATE materialized view museums_parking AS
          SELECT * FROM planet_osm_polygon
          WHERE building = 'parking'
          )
  end
end
