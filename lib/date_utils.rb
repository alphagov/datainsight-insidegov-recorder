require "tzinfo"

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

  def self.localise(date_time)
    # Convert a DateTime to the same time but in the Europe/London timezone
    # ie. 2012-08-08T00:00:00+00:00 -> 2012-08-08T00:00:00+01:00
    tz = TZInfo::Timezone.get("Europe/London")
    if tz.period_for_utc(date_time).utc_total_offset_rational > 0
      date_time = date_time.new_offset(tz.period_for_utc(date_time).utc_total_offset_rational) - Rational(1, 24)
    end
    date_time
  end
end