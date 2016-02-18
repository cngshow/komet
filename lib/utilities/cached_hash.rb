class CachedHash
  include Enumerable

  attr_accessor :max_size

  def initialize(max_size)
    self.max_size = max_size
    @lease = {}
    @backing_hash = {}
    @mutex = Mutex.new
  end

  def []=(key, value)
    @mutex.synchronize do
      clean
      @lease[key] = Time.now
      @backing_hash[key] = value
    end

  end

  def store(key, value)
    @mutex.synchronize do
      clean
      @lease[key] = Time.now
      @backing_hash[key] = value
    end
  end


  def [] key
    @mutex.synchronize do
      @lease[key] = Time.now unless @backing_hash[key].nil?
      @backing_hash[key]
    end
  end

  def each(&block)
    @mutex.synchronize do
      @backing_hash.each do |key|
        block.call(key)
      end
    end
  end

  def to_s
    @backing_hash.to_s
  end


  private
  def clean
    while (@backing_hash.size >= self.max_size)
      oldest = get_oldest
      @backing_hash.delete(oldest)
      @lease.delete(oldest)
    end
  end

  def get_oldest
    oldest = [@lease.keys.first, @lease.values.first]
    p @lease
    @lease.each_pair do |k, v|
      puts "key #{k}, value #{v}:"
      oldest = [k, v] if v <= oldest.last
    end
    oldest.first
  end
end