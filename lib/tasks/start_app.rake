task start_app: [ :environment ] do
  INPUT_ARGS = ARGV

  Rake::Task["db:drop"].invoke
  Rake::Task["db:create"].invoke

  Rake::Task["db:schema:load"].invoke


  # Technicians will not work before this time.
  MIN_START_TIME = Time.utc(2024, 10, 1, 6, 0)
  # Technicians will not work after this time.
  MAX_END_TIME = Time.utc(2024, 10, 1, 19, 0)

  # Extracts rows from csv file.
  #
  # @param csv_path The (string) path, separated by newline characters
  # @return A list of rows from the (.csv) path, EXCLUDING headers.
  def self._get_csv_values(csv_path)
    csv_items = []
    File.open(csv_path, mode="r") do |text_content|
      # Iterate through each line in text, appending rows to output
      text_content.read.each_line(chomp: true) do |line|
        # Split line by comma and append to result
        csv_row = line.split(",")
        csv_items.append(csv_row)
      end
    end
    # Return all rows from csv file EXCEPT headers.
    csv_items.drop(1)
  end

  # Drop all table records, starting with dependent records
  Workorder.destroy_all
  Location.destroy_all
  Technician.destroy_all

  # Drop trigger to remove entries with an invalid date
  ActiveRecord::Base.connection.execute(
    "DROP TRIGGER IF EXISTS comp_date ON workorders CASCADE;")
  # Drop function that generates comp_date trigger
  ActiveRecord::Base.connection.execute(
    "DROP FUNCTION IF EXISTS create_trigger;")
  # PLPGSQL function that returns a trigger to check each row in workorders for
  # an invalid time (i.e., an appointment that occurs before the last chronological
  # appointment is set to end)

  # Specifically, this function checks to see whether the time for the next workorder
  # (for the given technician) overlaps with the time for the NEW workorder plus its duration.
  # If the NEW time + duration is greater than the next workorder begin time,
  # then the NEW workorder is dropped.
  trigger_function_def = <<~SQL
    CREATE FUNCTION create_trigger() RETURNS TRIGGER AS $$
    DECLARE
      next_workorder_begin TIME;
      new_workorder_end TIME;
    BEGIN
      SELECT date::time FROM workorders INTO next_workorder_begin
        WHERE date::time > NEW.date::time and technician_id = NEW.technician_id
      ORDER BY date LIMIT 1;
      new_workorder_end := NEW.date + (NEW.duration * interval '1 minute');
      IF new_workorder_end > next_workorder_begin THEN RETURN NULL;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  SQL
  # PLPGSQL trigger that executes previous function on each row
  # when a new entry is inserted or deleted. (See above for details)
  trigger_def = <<~SQL
    CREATE TRIGGER comp_date
      BEFORE INSERT OR UPDATE ON workorders
      FOR EACH ROW
      EXECUTE FUNCTION create_trigger();
  SQL

  # Create previous trigger and function.
  ActiveRecord::Base.connection.execute(trigger_function_def)
  ActiveRecord::Base.connection.execute(trigger_def)

  # Load data from csv files.
  locations_data = self._get_csv_values("storage/locations.csv")
  technicians_data = self._get_csv_values("storage/technicians.csv")
  workorders_data = self._get_csv_values("storage/work_orders.csv")

  # Insert technicians into db.
  technicians_data.each do |technician|
    entry = Technician.create!(
      id: technician.at(0), name: technician.at(1))
    entry.save!
  end

  # Insert locations into db.
  locations_data.each do |location|
    entry = Location.create!(
      id: location.at(0), name: location.at(1), city: location.at(2))
    entry.save!
  end

  # Insert work_orders into db.
  workorders_data.each do |order|
    date_str = order.at(3)

    # A 2-tuple which represents the date and the time, respectively
    datetime = date_str.split(" ")

    # Because of how Ruby parses Time objects, we need to
    # preprocess the "year" part of each datetime
    datepart = datetime[0].split("/")

    # If the "year" part comprises only two characters, then we need to add
    # "20" (the current century) as a prefix.
    if datepart[-1].length == 2
      # Add prefix to year
      datepart[-1] = "20" + datepart[-1]

      # Join results to produce the original date, with "20" prepended to the year
      datepart = (datepart * "/").to_s
      date_str = ([ datepart, datetime[1] ] * " ").to_s
    end

    # Format the time according to the csv, and subtract the offset of Ruby's standard timezone
    # to get the final date.
    date = Time.strptime(date_str, "%m/%d/%Y %H:%M") - 5.hours
    date = date.to_s

    entry = Workorder.create!(
      id: order.at(0), technician_id: order.at(1), location_id: order.at(2),
      date: date, duration: order.at(4), price: order.at(5))
    entry.save!
  end
  
  # Formatted query statement to extract date and duration from workorders by name
  workorder_time_query = <<~SQL
    SELECT date, duration, technician_id FROM workorders
      INNER JOIN technicians ON technicians.id = technician_id AND name='%s'
    ORDER BY (workorders.date);
  SQL

  # Technicians will not work before this time.
  min_start_time = Time.utc(2024, 10, 1, 6, 0)
  # Technicians will not work after this time.
  max_end_time = Time.utc(2024, 10, 1, 19, 0)

  all_technician_names = []
  Technician.all.each do |technician|
    all_technician_names.append(technician["name"])
  end

  # Iterate through all technicians to add unscheduled (potential) workorders to the table.
  all_technician_names.each do | name |
    
    # Execute formatted query, getting all time-related workorder info for this technician.
    workorder_info = ActiveRecord::Base.connection.execute(workorder_time_query % name)

    # Add an available workorder if technician is available b/w "min_work_time" & their first workorder
    if workorder_info.getvalue(0, 0) > MIN_START_TIME

      first_scheduled_workorder_time = workorder_info.getvalue(0, 0)
      first_available_block_duration = (first_scheduled_workorder_time - min_start_time) / 1.minutes
      
      # Create an available workorder iff there is enough time b/w technician's 
      # min_start_time and this technician's first scheduled workorder
      if first_available_block_duration.to_i > 0
        
        unscheduled_workorder = Workorder.create!(
            id: Workorder.all.length+1,
            technician_id: workorder_info.getvalue(0, 2), 
            date: min_start_time,
            duration: first_available_block_duration)

        unscheduled_workorder.save!
      end
    end
    # Check each workorder if there is time between workorder[i] and workorder[i+1] 
    workorder_info.each.with_index do |pair, i|

      # Get start time for current workorder and add the
      # workorder's duration to get its ending time.
      workorder_start = pair["date"]
      workorder_duration = Float(pair["duration"]).minutes

      technician_id = pair["technician_id"]

      workorder_end = workorder_start + workorder_duration

      if i == workorder_info.ntuples - 1 

        next_workorder_start = MAX_END_TIME
      else

        next_workorder_start = workorder_info.getvalue(i+1, 0)
      end

      # Save the difference b/w this workorder's starting time and the next workorder's start time as available block
      next_available_block_duration = Float((next_workorder_start - workorder_end) / 1.minutes)
      # Add an available workorder for this technician if its duration > 0
      if next_available_block_duration > 0

        unscheduled_workorder = Workorder.create!(
            id: Workorder.all.length+1,
            technician_id: technician_id, 
            date: workorder_end,
            duration: next_available_block_duration)

        unscheduled_workorder.save!
      end
    end
  end
end
