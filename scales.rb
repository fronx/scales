#! /usr/bin/env ruby
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

  def pos(tone)
    tones.index(tone) + 1 rescue nil
  end
  
  def to_s(range = 1..7)
    tones(range).map do |tone|
      tone.ljust(3)
    end.join('  ')
  end
  
  def matrix
    tones.map do |tonic|
      Scale.new(tonic).tones rescue nil
    end
  end
end


def print_with_indentation(scales)
  indent = 0
  scales.each do |scale|
    puts ' ' * indent + scale.to_s if scale
    indent += 5
  end
end

class String
  def underlined(char = '=')
    self + "\n" + char * self.length
  end
end

start = $*.first || 'E'
puts "Expanded #{start} scale:".underlined
print_with_indentation(Scale.expand(start))
puts 
puts "All #{Scale.new(start).tonality} scales starting with #{start}:".underlined
print_with_indentation(Scale.all(start))