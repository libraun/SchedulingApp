class IndexController < ApplicationController
  attr_accessor :headers, :current_table, :min_start_time, :max_start_time

#  @workorder = new Workorder

  def index
    # Get all technician records and save their names.
    technician_names = []
    Technician.all.each do |technician|
      technician_names.append(technician["name"])
    end
    # Formatted query statement to extract date and duration from workorders by name
    query = <<~TEXT
      SELECT date, duration FROM workorders
        INNER JOIN technicians ON technicians.id = technician_id AND name = '%s'
      ORDER BY (workorders.date);
    TEXT

    # Technicians will not work before this time.
    min_start_time = Time.utc(2024, 10, 1, 6, 0)
    # Technicians will not work after this time.
    max_end_time = Time.utc(2024, 10, 1, 19, 0)

    # "Records" is a dictionary that represents each technician's schedule.
    # It uses technician names (the headers) as keys, where each value is a list
    # of tuples containing the number of minutes in a given "time block" and a boolean
    # value indicating whether or not that block has been scheduled (i.e., is a workorder)
    records = {}
    # Iterate through technician names to build a schedule for each.
    technician_names.each { |technician_name|
      # Execute formatted query, getting all workorders for this technician.
      current_technician_times = ActiveRecord::Base.connection.execute(query % technician_name)

      # A list containing tuple elements that represent blocks in technician's schedule
      technician_schedule = []

      # If this technician has free time between the start of the day and their first workorder,
      # then left-pad their schedule with a free block.

      if current_technician_times.getvalue(0, 0) > min_start_time

        first_workorder_time = current_technician_times.getvalue(0, 0)
        # Get the number of minutes starting at 6 AM until their first appointment.
        first_available_block = (first_workorder_time - min_start_time) / 1.minutes
        if first_available_block.to_i != 0
          technician_schedule.append([ first_available_block, min_start_time, first_workorder_time, 1 ])
        end
      end
      # Iterate through this technician's active workorders
      # to find any availabilities in their schedule.
      current_technician_times.each.with_index { |pair, i|

        # Get start time for current workorder and add the
        # workorder's duration to get its ending time.
        start_time = pair["date"]
        workorder_duration = pair["duration"]

        end_time = start_time + workorder_duration.minutes

        # If this is the last workorder in the technicians queue, then get
        # the offset in minutes from max_end_time to this workorder as the last available block.
        if i == current_technician_times.ntuples - 1
          next_start_time = max_end_time
        # Else, get the difference between this workorder and the next as the next available block.
        else
          next_start_time = current_technician_times.getvalue(i+1, 0)
        end
        # Get the difference between the next workorder's start time and this workorder's
        # end time, and save it as a free availability (if nonzero).
        next_available_block = Float((next_start_time - end_time) / 1.minutes)

        # Add this workorder's duration as a non-available block
        technician_schedule.append([ Float(workorder_duration), start_time, end_time, 0 ])
        if next_available_block > 0
          technician_schedule.append([ next_available_block, end_time, next_start_time, 1 ])
          # technician_schedule.append([ next_available_block, end_time, next_start_time, 1 ])
        end
      }
      records[technician_name] = technician_schedule
    }
    params[:headers] = technician_names
    params[:current_table] = records

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
    # Get a list of technician names as headers
  end
  def create_workorder
    start_time = (Time.strptime ("10/01/2024 " + params[:w_begin]), "%m/%d/%Y %H:%M:%S")  - 5.hours
    duration = ((Time.strptime("10/01/2024 " + params[:w_end] ,"%m/%d/%Y %H:%M:%S") -5.hours)- start_time).minutes / 3600;
    
    entry = Workorder.create(
      id: 13131, technician_id: 1, location_id: 1,
      date: start_time.to_s, duration: duration, price: 0.0)
    entry.save!

    return index
    
  end
end
