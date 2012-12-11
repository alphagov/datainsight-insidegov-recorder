class Response

  def self.build(data, source, update_date)
    {
        response_info: {status: "ok"},
        details: {
            source: source,
            data: data
        },
        updated_at: update_date
    }
  end

end