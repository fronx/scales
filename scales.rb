#! /usr/bin/env ruby

class String
  def green
    "\033[0;32m" + self + "\033[0m"
  end
  
  def underlined(char = '=')
    self + "\n" + char * self.length
  end
end

class Scale
  TONES = %w(c c# d d# e f f# g g# a a# b)*2
  STEPS = [2, 2, 1, 2, 2, 2, 1]*2
  MAJMIN = [:major, :minor, :minor, :major, :major, :minor, :diminished]*2
  
  class << self
    TONES.each do |tone|
      [tone, tone.gsub('#', 'is'), tone.upcase, tone.upcase.gsub('#', 'is')].each do |name|
        define_method name do
          self.new(tone)
        end
      end
    end
  end
  
  def initialize(tonic)
    raise "bad tonic: #{tonic.downcase}" unless TONES.include?(tonic.downcase)
    @tonic = tonic
    @offset = TONES.index(@tonic.downcase)
  end
  
  def self.all(start_with = 'C')
    start = TONES.index(start_with.downcase)
    tonality = Scale.new(start_with).tonality
    TONES[start..(start + 11)].map do |tonic|
      self.new(tonality == :major ? tonic.upcase : tonic.downcase )
    end
  end

  def self.expand(basis = 'C')
    Scale.new(basis).tones.map do |tonic|
      self.new(tonic) rescue nil
    end
  end
  
  def tonic; tone(1); end
  def subdominant; tone(4); end
  def dominant; tone(5); end

  def tones(range = 1..7)
    range.map do |pos|
      tone(pos)
    end
  end
  
  def step_sum_for_pos(pos)
    sum = 0
    pos = bound_pos(pos)
    (2..pos).each do |i|
      if tonality == :major
        sum += STEPS[i - 2]
      else
        sum += STEPS[i + 4]
      end
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
    with_case(tone, pos)
  end
  
  def with_case(tone, pos)
    look_pos = tonality == :major ? pos - 1 : pos + 4
    if MAJMIN[look_pos] == :major
      tone.upcase
    elsif MAJMIN[look_pos] == :diminished
      tone.upcase + '0'
    else
      tone.downcase
    end
  end
  
  def tonality
    @tonic.upcase == @tonic ? :major : :minor
  end

  def pos(tone, options = {})
    if options[:case_sensitive] == false
      tones.map { |t| t.downcase }.index(tone.downcase) + 1 rescue nil
    else
      tones.index(tone) + 1 rescue nil
    end
  end
  
  def to_s(range = 1..7, options = {})
    tones(range).map do |tone|
      if options[:colored] && options[:colored].include?(tone)
        tone.ljust(4).green
      else
        tone.ljust(4)
      end
    end.join('  ')
  end
  
  def matrix
    tones.map do |tonic|
      Scale.new(tonic).tones rescue nil
    end
  end
end

def print_with_indentation(scales)
  basis = scales.first
  indent = 0
  scales.compact.each do |scale|
    pos = basis.pos(scale.tonic, :case_sensitive => false)
    if pos
      indent = (pos - 1) * 6
      puts ' ' * indent + scale.to_s(1..7, :colored => basis.tones) if scale
    else
      indent += 3
      puts ' ' * indent + scale.to_s if scale
    end
  end
end

start = $*.first || 'C'
puts "Expanded #{start} scale:".underlined
print_with_indentation(Scale.expand(start))
puts 
puts "#{Scale.new(start).tonality.to_s.capitalize} scales:".underlined
print_with_indentation(Scale.all(start))