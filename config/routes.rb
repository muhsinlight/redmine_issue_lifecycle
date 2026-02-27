# frozen_string_literal: true

get 'projects/:project_id/lifecycle', :to => 'lifecycle#index', :as => 'project_lifecycle'
