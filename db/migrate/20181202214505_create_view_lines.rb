class CreateViewLines < ActiveRecord::Migration[5.1]
  def up
    self.connection.execute %Q( CREATE materialized view lines_footway AS
          SELECT * FROM planet_osm_line l
          WHERE highway = 'footway'
          )
  end
end
