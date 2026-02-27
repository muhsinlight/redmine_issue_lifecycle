  # frozen_string_literal: true
  
 class IssueLifecycleCalculator
   Segment = Struct.new(:issue, :status, :user, :from, :to) do
     def duration
       ((to || Time.current) - (from || Time.current)).to_i
     end
   end

   attr_reader :issue

   def initialize(issue)
     @issue = issue
   end

   def calculate
     segs = segments

     status_times = Hash.new(0)
     segs.each do |seg|
       next unless seg.status

       status_times[seg.status.name] += seg.duration
     end

     total = status_times.values.sum

     {
       issue_id: issue.id,
       issue_subject: issue.subject,
       status_times: status_times,
       total_time: total,
       segments: segs
     }
   end

   def segments
     @segments ||= begin
       result = []

       current_status = issue.status
       current_user   = issue.author
       current_from   = issue.created_on

       status_journals = issue.journals.
         includes(:user, :details).
         reorder(:created_on).
         select { |j| j.details.any? { |d| d.property == 'attr' && d.prop_key == 'status_id' } }

       status_journals.each do |journal|
         to_time = journal.created_on
         if current_from && to_time && to_time > current_from
           result << Segment.new(issue, current_status, current_user, current_from, to_time)
         end

         detail = journal.details.detect { |d| d.property == 'attr' && d.prop_key == 'status_id' }
         if detail
           new_status = IssueStatus.find_by(id: detail.value)
           current_status = new_status if new_status
         end

         current_user = journal.user || current_user
         current_from = to_time
       end

       end_time = issue.closed_on || Time.current
       if current_from && end_time && end_time > current_from
         result << Segment.new(issue, current_status, current_user, current_from, end_time)
       end

       result
     end
   end
 end

