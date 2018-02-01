class StationHandler

  def self.getAllStations
    db = SQLite3::Database.open('db/Västtrafik.sqlite')
    return db.execute('SELECT stop_name FROM all_stops')
  end

end
