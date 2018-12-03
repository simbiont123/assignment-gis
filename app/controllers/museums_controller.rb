class MuseumsController < ApplicationController

  def get_all_with_distance
    render json: Museum.get_all_with_distance(lat_lon_range_range2)
  end

  def get_all_within_polygon
    render json: Museum.get_all_within_polygon(lat_lon_many)
  end

  def get_all_within_line
    render json: Museum.get_all_within_line(lat_lon_line)
  end

  def get_all_with_range
    render json: Museum.get_all_with_range(lat_lon_range)
  end

  private

  def lat_lon_range_range2
    params.permit(:lat, :lon, :range, :range2)
  end

  def lat_lon_many
    params.permit(:lat1, :lon1, :lat2, :lon2, :lat3, :lon3, :lat4, :lon4)
  end

  def lat_lon_line
    params.permit(:lat, :lon, :lat1, :lon1)
  end

  def lat_lon_range
    params.permit(:lat, :lon, :range)
  end
end
