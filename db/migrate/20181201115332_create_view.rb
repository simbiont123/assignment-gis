class CreateView < ActiveRecord::Migration[5.1]
  def up
    self.connection.execute %Q( CREATE materialized view museums AS
          SELECT * FROM planet_osm_polygon
          WHERE name IS NOT NULL AND (tourism = 'museum' OR tourism = 'gallery')
          )
  end
end
