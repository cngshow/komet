module InstrumentationConcern

  def byte_size()
    if (response.content_type.eql?('application/json'))
      @@instrument_hash ||= {}
      obj = response.body.to_java
      #json is utf-8
      bytes = obj.getBytes("UTF-8").length
      key = "#{params[:controller]}##{params[:action]}"
      if (@@instrument_hash.has_key?(key))
        v = @@instrument_hash[key]
        new_count = v.last.next
        new_bytes_avg = (v.last*v.first.to_f + bytes.to_f) / new_count.to_f
        @@instrument_hash[key] = [new_bytes_avg, new_count]
      else
        @@instrument_hash[key] = [bytes.to_f, 1]
      end
      $log.info("Byte size of passed object for #{key} is #{bytes}")
      $log.info("Average size for #{key} is #{@@instrument_hash[key].first}, with a call count of #{@@instrument_hash[key].last}")
      bytes
    end
  end
end
