class CachedHash
  include Enumerable

  attr_accessor :max_size

  def initialize(max_size)
    self.max_size = max_size
    @lease = {}
    @backing_hash = {}
    @mutex = Mutex.new #Not re-entrant, but lock acquires in 1/2 the time (After JVM is warm and toasty).
    #@mutex = Monitor.new #re-entrant
  end

  def keys
    @mutex.synchronize do
      @backing_hash.keys
    end
  end

  def []=(key, value)
    save(key, value)
  end

  def store(key, value)
    save(key, value)
  end

  def [] key
    @mutex.synchronize do
      @lease[key] = Time.now unless @backing_hash[key].nil?
      @backing_hash[key]
    end
  end

  def clear_cache(key_starts_with:)
    @mutex.synchronize do
      @backing_hash.delete_if do
        |key_hash|
        url, params = key_hash.first
        url.start_with? key_starts_with.to_s
      end
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

  def save(key, value)
    @mutex.synchronize do
      clean
      @lease[key] = Time.now
      @backing_hash[key] = value
    end
  end

  def clean
    while (@backing_hash.size >= self.max_size)
      oldest = get_oldest
      @backing_hash.delete(oldest)
      @lease.delete(oldest)
    end
  end

  def get_oldest
    oldest = [@lease.keys.first, @lease.values.first]
    @lease.each_pair do |k, v|
      #puts "key #{k}, value #{v}:"
      oldest = [k, v] if v <= oldest.last
    end
    oldest.first
  end
end