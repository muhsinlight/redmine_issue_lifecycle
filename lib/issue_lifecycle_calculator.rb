# frozen_string_literal: true

class IssueLifecycleCalculator
  attr_reader :issue, :status_cache

  def initialize(issue, status_cache = nil)
    @issue = issue
    @status_cache = status_cache || IssueStatus.all.each_with_object({}) { |s, h| h[s.id] = s.name }
  end

  def calculate
    status_changes = extract_status_changes
    status_times = calculate_status_times(status_changes)

    {
      issue_id: issue.id,
      issue_subject: issue.subject,
      category_name: issue.category&.name,
      tracker_name: issue.tracker&.name,
      status_changes: status_changes,
      status_times: status_times,
      total_time: status_times.values.sum
    }
  end

  private

  def extract_status_changes
    changes = []
    initial_status = issue.status
    initial_time = issue.created_on

    status_journals = if issue.association(:journals).loaded?
      issue.journals.select { |j| j.details.any? { |d| d.prop_key == 'status_id' } }.sort_by(&:created_on)
    else
      issue.journals
           .includes(:user, :details)
           .joins(:details)
           .where(journal_details: { prop_key: 'status_id' })
           .order('journals.created_on ASC')
    end

    current_status_id = nil
    current_time = initial_time

    status_journals.each do |journal|
      detail = journal.details.find { |d| d.prop_key == 'status_id' }
      next unless detail

      old_status_id = detail.old_value.to_i
      new_status_id = detail.value.to_i
      duration = journal.created_on - current_time

      changes << {
        from_status_id: old_status_id,
        from_status_name: status_cache[old_status_id] || 'Unknown',
        to_status_id: new_status_id,
        to_status_name: status_cache[new_status_id] || 'Unknown',
        changed_at: journal.created_on,
        changed_by: journal.user,
        user_name: journal.user&.name || 'System',
        duration: duration
      }

      current_status_id = new_status_id
      current_time = journal.created_on
    end

    end_time = issue.closed_on || Time.current
    if current_time < end_time
      final_status_id = current_status_id || issue.status_id
      final_duration = end_time - current_time

      changes << {
        from_status_id: final_status_id,
        from_status_name: status_cache[final_status_id] || 'Unknown',
        to_status_id: final_status_id,
        to_status_name: status_cache[final_status_id] || 'Unknown',
        changed_at: end_time,
        changed_by: nil,
        user_name: 'Current',
        duration: final_duration
      }
    end

    changes
  end

  def calculate_status_times(status_changes)
    times = {}
    status_changes.each do |change|
      status_name = change[:from_status_name]
      duration = change[:duration] || 0
      times[status_name] ||= 0
      times[status_name] += duration
    end
    times
  end
end
