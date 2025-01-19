class IndexController < ApplicationController
  attr_accessor :technician_names, :workorders, :min_start_time, :max_start_time

#  @workorder = new Workorder

  def index

    # Technicians will not work before this time.
    params[:min_start_time] = Time.utc(2024, 10, 1, 6, 0)
    # Technicians will not work after this time.
    params[:max_end_time] = Time.utc(2024, 10, 1, 19, 0)

    params[:workorders] = {}
    # Iterate through technician names to build a schedule for each.
    Technician.left_joins(:workorders).each { |technician_data|

      # Execute formatted query, getting all workorders for this technician.
      technician_workorders = technician_data.workorders

      # A list containing tuple elements that represent blocks in technician's schedule
      params[:workorders][technician_data.name] = []
      # If technician is available b/w "min_work_time" & their first workorder, pad their schedule with a free block.
      if technician_workorders.first.date > params[:min_start_time]
        # Get the number of minutes starting at 6 AM until their first appointment.
        params[:workorders][technician_data.name].append([ 
            get_minutes_difference(technician_workorders.first.date, params[:min_start_time]), 
            params[:min_start_time], 
            technician_workorders.first.date, 
            nil 
        ])
      end
      # Iterate through this technician's active workorders
      # to find any availabilities in their schedule.
      technician_workorders.workorders.each.with_index do |workorder, idx|

        # Get start time for current workorder and add the
        current_workorder_end = workorder.date + workorder.duration.minutes

        # Check if workorder is this technician's last; if true, add an available block b/w workorder.end
        # and max_end_time.
        if workorder == technician_workorders.last
          next_workorder_start = params[:max_end_time]
        else
          next_workorder_start = technician_workorders.limit(1).offset(idx + 1).first.date
        end
        
        # Add this workorder's duration as a non-available block
        params[:workorders][technician_data.name].append([ 
            workorder.date, 
            get_minutes_difference(next_workorder_start, current_workorder_end), 
            workorder.date + workorder.duration.minutes, 
            workorder.location
        ])
        # Add the next
        if next_available_block_duration > 0
          params[:workorders][technician.name].append([ 
              next_available_block_duration, 
              current_workorder_end, 
              next_workorder_start, 
              nil 
          ])
        end
      end
    }
    
    respond_to do |format|
      format.html { render :index }
    end
  end

  def show

    respond_to do |format|
      format.html { render :show }
    end
    # Get a list of technician names as headers
  end

  def create_workorder

    start_time = (Time.strptime "10/01/2024 " + params[:w_begin], "%m/%d/%Y %H:%M:%S")  - 5.hours
    end_time = (Time.strptime "10/01/2024 " + params[:w_end], "%m/%d/%Y %H:%M:%S") - 5.hours

    duration = (end_time - start_time).minutes / 3600;

    technician_id = Technician.where(name: params[:name]).take.id
    
    begin
      entry = Workorder.create(
          id: Workorder.all.length+1, 
          technician_id: technician_id, 
          location_id: 1,
          date: start_time.to_s, 
          duration: duration, 
          price: 0.0
      )
      ActiveRecord::Base.transaction do 
        entry.save!
      end
    rescue ActiveRecord::RecordInvalid => exception
      throw exception
    end
    return index
    
  end

  private

  def get_minutes_difference(time_a, time_b) 
    (time_a - time_b) / 1.minutes
  end
end
