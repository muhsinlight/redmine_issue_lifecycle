# frozen_string_literal: true

class IssueLifecycleHooks < Redmine::Hook::ViewListener
  render_on :view_issues_show_details_bottom,
            partial: 'issue_lifecycle/issue_panel'
end
