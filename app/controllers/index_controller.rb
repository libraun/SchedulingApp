class IndexController < ApplicationController
  attr_accessor :technician_names, :workorders, :min_start_time, :max_start_time
  def index
    # Technicians will not work before this time.
    params[:min_start_time] = Time.utc(2024, 10, 1, 6, 0)
    # Technicians will not work after this time.
    params[:max_end_time] = Time.utc(2024, 10, 1, 19, 0)

    records = Hash.new
    
    Technician.pluck(:name).each do |name|

      records[name] = []
    end

    # Iterate through technicians to build a schedule for each.
    Technician.all.each do |technician|
      technician_schedule = Workorder.where(technician_id: technician.id).order("date")
      # If technician is available b/w "min_work_time" & their first workorder, pad their schedule with a free block.
      if technician_schedule.first.date > params[:min_start_time]
        records[ technician.name ].append([ 
            params[ :min_start_time ],
            get_minutes_difference(
              technician_schedule.first.date, 
              params[ :min_start_time ] ),
            technician_schedule.first.date, 
            nil 
        ])
      end
      technician_schedule.each do |workorder|
        #next_workorder_start = technician_schedule.limit(1).where("date > ?", workorder.date).first
        # Add this workorder's duration as a non-available block
        workorder_end = workorder.date + workorder.duration.minutes
        next_workorder = technician_schedule.order(:date).where(
            "date > ?", workorder.date).first

        records[technician.name].append([
          workorder.date,
          workorder.duration, 
          workorder_end, 
          workorder.location_id])
        if next_workorder != nil 
          records[technician.name].append([
            workorder_end,
            get_minutes_difference(next_workorder.date, workorder_end),
            next_workorder.date,
            nil
          ])
        else 
          records[ technician.name ].append([ 
            workorder_end,             
            get_minutes_difference(
              params[ :max_end_time ], 
              workorder_end ),
            params[ :max_end_time ], 
            nil ])
        end
      end
    end
    params[:workorders] = records
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
        entry.save
      end
    rescue ActiveRecord::RecordInvalid => exception
      throw exception
    end
    return index
    
  end

  private

  def get_minutes_difference(time_a, time_b) 
    return (time_a - time_b) / 1.minutes
  end
end
