Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # root_path
  root 'home#home'

  get 'museums/all' => 'museums#get_all_with_distance'
  get 'museums/all_range' => 'museums#get_all_with_range'
  get 'museums/polygon' => 'museums#get_all_within_polygon'
  get 'museums/line' => 'museums#get_all_within_line'

end
