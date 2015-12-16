module CommonData
  extend self
  @instance_data = {}
  @instance_data[:email] = 'ststooling@va.gov'
  @instance_data[:team] = 'STS TOOLING'

  class << self
    attr_accessor :instance_data
  end

  def get_property(sym)
    @instance_data[sym]
  end
end
