class IndexController < ApplicationController
  attr_accessor :technician_names, :workorders, :min_start_time, :max_start_time

#  @workorder = new Workorder

  def index
    # Get all technician records and save their names.
    all_technician_names = []
    Technician.all.each do |technician|
      all_technician_names.append(technician["name"])
    end
    # Formatted query statement to extract date and duration from workorders by name
    query = <<~SQL
      SELECT date, duration FROM workorders
        INNER JOIN technicians ON technicians.id = technician_id AND name = '%s'
      ORDER BY (workorders.date);
    SQL

    # Technicians will not work before this time.
    min_start_time = Time.utc(2024, 10, 1, 6, 0)
    # Technicians will not work after this time.
    max_end_time = Time.utc(2024, 10, 1, 19, 0)

    # "records" maps each technician name to a list of "time blocks", also containing a boolean
    # value indicating whether or not that block has been scheduled (i.e., is a workorder)
    records = {}
    # Iterate through technician names to build a schedule for each.
    all_technician_names.each { |technician_name|
      # Execute formatted query, getting all workorders for this technician.
      current_technician_times = ActiveRecord::Base.connection.execute(query % technician_name)

      # A list containing tuple elements that represent blocks in technician's schedule
      technician_schedule = []

      # If technician is available b/w "min_work_time" & their first workorder,
      # then left-pad their schedule with a free block.
      if current_technician_times.getvalue(0, 0) > min_start_time

        first_workorder_time = current_technician_times.getvalue(0, 0)
        # Get the number of minutes starting at 6 AM until their first appointment.
        first_available_block = (first_workorder_time - min_start_time) / 1.minutes
        
        if first_available_block.to_i > 0
          
          technician_schedule.append([ first_available_block, min_start_time, first_workorder_time, 1 ])
        end
      end
      # Iterate through this technician's active workorders
      # to find any availabilities in their schedule.
      current_technician_times.each.with_index { |pair, idx|

        # Get start time for current workorder and add the
        # workorder's duration to get its ending time.
        current_workorder_start = pair["date"]
        current_workorder_duration = Float(pair["duration"])

        current_workorder_end = current_workorder_start + current_workorder_duration.minutes

        # If this is the last workorder in the technicians queue, then get
        # the offset in minutes from max_end_time to this workorder as the last available block.
        if idx == current_technician_times.ntuples - 1
          next_workorder_start = max_end_time
        # Else, get the difference between this workorder and the next as the next available block.
        else
          next_workorder_start = current_technician_times.getvalue(idx+1, 0)
        end
        # Save the difference b/w this workorder's starting time and the next workorder's start time as available block
        next_available_block_duration = Float((next_workorder_start - current_workorder_end) / 1.minutes)
        # Add this workorder's duration as a non-available block
        technician_schedule.append([ current_workorder_duration, current_workorder_start, current_workorder_end, 0 ])
        if next_available_block_duration > 0

          technician_schedule.append([ next_available_block_duration, current_workorder_end, next_workorder_start, 1 ])
          # technician_schedule.append([ next_available_block, end_time, next_start_time, 1 ])
        end
      }
      records[technician_name] = technician_schedule
    }

    # Set global parameters to be used by index.html.erb
    params[:technician_names] = all_technician_names
    params[:workorders] = records

    params[:min_start_time] = min_start_time
    params[:max_end_time] = max_end_time
    
    respond_to do |format|
      format.html { render :index }
    end
  end

  def show

    respond_to do |format|
      format.html { render :show }
    end
  end

  def create_workorder

    start_time = (Time.strptime "10/01/2024 " + params[:w_begin], "%m/%d/%Y %H:%M:%S")  - 5.hours
    end_time = (Time.strptime "10/01/2024 " + params[:w_end], "%m/%d/%Y %H:%M:%S") - 5.hours

    duration = (end_time - start_time).minutes / 3600;

    technician_id = Technician.where(name: params[:name]).take.id
    
    begin

      entry = Workorder.create(
        id: Workorder.all.length+1, technician_id: technician_id, location_id: 1,
        date: start_time.to_s, duration: duration, price: 0.0)

      entry.save

    rescue ActiveRecord::RecordInvalid => exception
      
      throw exception
    end
    return index
    
  end
end
