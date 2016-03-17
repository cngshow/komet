module KometDashboardHelper

  def rest_cache_to_str
    r_val = ""
    $rest_cache.each do |k|
      url  = k.to_a[0]
      r_val << "<b>#{url}</b><br>"
    end
    r_val
  end

end
