class IndexController < ApplicationController
  attr_accessor :technician_names, :workorders, :min_start_time, :max_start_time

#  @workorder = new Workorder

  def index
    # Get all technician records and save their names.
    params[:technician_names] = []
    Technician.all.each do |technician|
      params[:technician_names].append(technician["name"])
    end
    # Formatted query statement to extract date and duration from workorders by name
    query = <<~SQL
      SELECT date, duration, available FROM workorders
        INNER JOIN technicians ON technicians.id = technician_id AND name = '%s'
      ORDER BY (workorders.date);
    SQL

    # Technicians will not work before this time.
    params[:max_start_time] = Time.utc(2024, 10, 1, 6, 0)
    # Technicians will not work after this time.
    params[:max_end_time] = Time.utc(2024, 10, 1, 19, 0)

    records = {}
    all_technician_names.each do |technician_name|
      # Execute formatted query, getting all workorders for this technician.
      current_technician_times = ActiveRecord::Base.connection.execute(query % technician_name)

      # A list containing tuple elements that represent blocks in technician's schedule
      params[:workorders][technician_name] = [] 
      current_technician_times.each.with_index do |pair, idx|

        # Get start time for current workorder and add the
        # workorder's duration to get its ending time.
        current_workorder_start = pair["date"]
        current_workorder_duration = Float(pair["duration"]).minutes

        workorder_is_available = pair["available"]

        current_workorder_end = current_workorder_start + current_workorder_duration

        params[:workorders][technician_name].append([ 
          current_workorder_duration, 
          current_workorder_start, 
          current_workorder_end, 
          workorder_is_available ])
      end
    end
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

    return index
    
  end
end
