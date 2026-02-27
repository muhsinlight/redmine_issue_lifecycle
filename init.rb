# frozen_string_literal: true

Redmine::Plugin.register :redmine_issue_lifecycle do
  name ' Issue Lifecycle '
  author 'xxxxx xxxxx'
  description 'Shows issue status lifecycle transitions and time spent in each status'
  version '1.0.0'
  url ''
  author_url ''


  project_module :issue_lifecycle do
    permission :view_issue_lifecycle, { :lifecycle => [:index] }, :require => :member
  end

  menu :project_menu, :lifecycle, { :controller => 'lifecycle', :action => 'index' },
       :caption => :label_lifecycle,
       :param => :project_id,
       :after => :issues,
       :if => Proc.new { |p| p.module_enabled?(:issue_lifecycle) }
end
