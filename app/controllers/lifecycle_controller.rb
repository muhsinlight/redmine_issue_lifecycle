 # frozen_string_literal: true

 class LifecycleController < ApplicationController
   layout 'base'
   menu_item :lifecycle

   before_action :find_project
   before_action :authorize

  helper :issues

  def index
    @issues = @project.issues.includes(:status, :author, :category, :assigned_to, :journals => :details)

    @rows = []
    @category_totals = Hash.new(0)
    @user_totals = Hash.new(0)

    @issues.each do |issue|
      lifecycle = IssueLifecycleCalculator.new(issue).calculate
      segments  = lifecycle[:segments]

      segments.each do |seg|
        duration = seg.duration
        next if duration <= 0

        category_name = issue.category&.name || l(:label_none)
        user_name     = seg.user&.name || l(:label_anonymous)

        @category_totals[category_name] += duration
        @user_totals[user_name]         += duration

        @rows << {
          issue: issue,
          status: seg.status,
          user: seg.user,
          category: issue.category,
          duration: duration,
          from: seg.from,
          to: seg.to,
          total_time: lifecycle[:total_time]
        }
      end
    end

    sort_column = params[:sort].presence || 'issue_id'
    sort_direction = params[:direction] == 'desc' ? 'desc' : 'asc'

    @rows = @rows.sort_by do |row|
      case sort_column
      when 'subject'
        row[:issue].subject.to_s.downcase
      when 'category'
        row[:category]&.name.to_s.downcase
      when 'user'
        row[:user]&.name.to_s.downcase
      when 'total_time'
        row[:total_time].to_i
      else 
        row[:issue].id
      end
    end
    @rows.reverse! if sort_direction == 'desc'

    @category_totals = normalize_totals(@category_totals)
    @user_totals     = normalize_totals(@user_totals)
  end

   private

   def find_project
     @project = Project.find(params[:project_id])
   rescue ActiveRecord::RecordNotFound
     render_404
   end

   def authorize
     render_403 unless User.current.allowed_to?(:view_issue_lifecycle, @project)
   end

   def normalize_totals(hash)
     total = hash.values.sum.to_f
     return [] if total <= 0

     hash.map do |name, seconds|
       {
         name: name,
         seconds: seconds,
         percent: ((seconds.to_f / total) * 100.0).round(1)
       }
     end.sort_by { |h| -h[:seconds] }
   end
 end
