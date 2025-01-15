class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def create_record 
    puts "hey"

    query = <<~TEXT
      INSERT INTO workorders VALUES(?, ?, ?)
        INNER JOIN technicians ON technicians.id = technician_id AND name = '%s'
      ORDER BY (workorders.date);
    TEXT
    connection.execute query,
      params[:create-record-form]
  end
end
