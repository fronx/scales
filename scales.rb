class Scale
  TONES = %w(c c# d d# e f f# g g# a a# b)
  STEPS = [2, 2, 1, 2, 2, 2, 1]
  MAJMIN = [:major, :minor, :minor, :major, :major, :minor, :diminished]
  
  class << self
    TONES.each do |tone|
      [tone, tone.gsub('#', 'is')].each do |name|
        define_method name do
          self.new(tone)
        end
      end
    end
  end
  
  def initialize(tonic)
    raise "bad tonic: #{tonic}" unless TONES.include?(tonic)
    @tonic = tonic
    @offset = TONES.index(tonic)
  end
  
  def tonic; tone(1); end
  def subdominant; tone(4); end
  def dominant; tone(5); end

  def tones(range = 1..8)
    range.map do |pos|
      tone(pos)
    end
  end
  
  def step_sum_for_pos(pos)
    sum = 0
    pos = bound_pos(pos)
    (2..pos).each do |i|
      sum += STEPS[i - 2]
    end
    sum
  end
  
  def pos_to_index(pos)
    bound_index(@offset + step_sum_for_pos(pos))
  end
  
  def bound_index(index) # ok
    index % TONES.size
  end
  
  def bound_pos(pos)
    ((pos - 1) % 7) + 1
  end
  
  def tone(pos)
    pos = bound_pos(pos)
    tone = TONES[pos_to_index(pos)]
    major?(pos) ? tone.upcase : tone.downcase
  end
  
  def major?(pos)
    MAJMIN[pos - 1] == :major
  end

  def minor?(pos)
    MAJMIN[pos - 1] == :minor
  end
  
  def pos(tone)
    tones.index(tone) + 1 rescue nil
  end
  
  def to_s(range = 1..8)
    tones(range).map do |tone|
      tone.ljust(3)
    end.join('  ')
  end
end

Scale::TONES.each do |tonic|
  puts Scale.__send__(tonic).to_s
end