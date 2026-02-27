 # frozen_string_literal: true

 class LifecycleController < ApplicationController
   layout 'base'
   menu_item :lifecycle

   before_action :find_project
   before_action :authorize

  helper :issues

  def index
    @limit = per_page_option
    @issue_count = @project.issues.count
    @issue_pages = Paginator.new @issue_count, @limit, params['page']
    @offset = @issue_pages.offset

    @issues_on_page = @project.issues
                        .includes(:status, :author, :category, :assigned_to, :journals => :details)
                        .offset(@offset).limit(@limit)

    @rows = []
    @issues_on_page.each do |issue|
      lifecycle = IssueLifecycleCalculator.new(issue).calculate
      lifecycle[:segments].each do |seg|
        @rows << {
          issue: issue,
          status: seg.status,
          user: seg.user,
          category: issue.category,
          duration: seg.duration,
          from: seg.from,
          to: seg.to,
          total_time: lifecycle[:total_time]
        }
      end
    end

    calculate_project_totals

    sort_rows
  end

  private

  def calculate_project_totals
    @category_totals_hash = Hash.new(0)
    @user_totals_hash = Hash.new(0)

    @project.issues.includes(:category, :journals => :details).each do |issue|
      lifecycle = IssueLifecycleCalculator.new(issue).calculate
      lifecycle[:segments].each do |seg|
        duration = seg.duration
        next if duration <= 0
        @category_totals_hash[issue.category&.name || l(:label_none)] += duration
        @user_totals_hash[seg.user&.name || l(:label_anonymous)] += duration
      end
    end

    @category_totals = normalize_totals(@category_totals_hash)
    @user_totals     = normalize_totals(@user_totals_hash)
  end

  def sort_rows
    sort_column = params[:sort].presence || 'issue_id'
    sort_direction = params[:direction] == 'desc' ? 'desc' : 'asc'

    @rows = @rows.sort_by do |row|
      case sort_column
      when 'subject'     then row[:issue].subject.to_s.downcase
      when 'category'    then row[:category]&.name.to_s.downcase
      when 'user'        then row[:user]&.name.to_s.downcase
      when 'total_time'  then row[:total_time].to_i
      when 'duration'    then row[:duration].to_i
      else row[:issue].id
      end
    end
    @rows.reverse! if sort_direction == 'desc'
  end

  def show
    @issue = @project.issues.find(params[:id])
    render partial: 'issue_lifecycle/issue_panel', locals: { issue: @issue }
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
