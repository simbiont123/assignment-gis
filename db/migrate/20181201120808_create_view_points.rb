class CreateViewPoints < ActiveRecord::Migration[5.1]
  def up
    self.connection.execute %Q( CREATE materialized view museums_points AS
          SELECT * FROM planet_osm_point
          WHERE name IS NOT NULL AND (tourism = 'museum' OR tourism = 'gallery')
          )
  end
end
