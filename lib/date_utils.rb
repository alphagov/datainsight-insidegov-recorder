module DateUtils
  def self.last_sunday_for(date_time)
    date_time - date_time.wday
  end

  def self.sunday_before(date_time)
    date_time - (date_time.wday == 0 ? 7 : date_time.wday)
  end

  def self.saturday_before(date_time)
    date_time - (date_time.wday + 1)
  end
end