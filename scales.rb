#! /usr/bin/env ruby

def colored?
  ($*.include?('--colored') || $*.include?('--color-on')) && !$*.include?('--color-off')
end

class String
  def green
    "\033[0;32m" + self + "\033[0m"
  end

  def red
    "\033[0;31m" + self + "\033[0m"
  end

  def underlined(char = '=')
    self + "\n" + char * self.length
  end
end

class Array
  def circular(range)
    return at(range % size) if range.is_a?(Fixnum)
    range = (range.begin..(size + range.end)) if range.end < range.begin
    range.map do |index|
      at(index % size)
    end
  end
end

class Scale
  TONES = %w(c c# d d# e f f# g g# a a# b)
  STEPS = [2, 2, 1, 2, 2, 2, 1]
  MAJMIN = [:major, :minor, :minor, :major, :major, :minor, :diminished]
  SPACE = 4
  
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

  def self.chromatic_tones(basis = 'c', count = 2)
    basis = basis.downcase
    start = TONES.index(basis)
    TONES.circular(start..start - 1)*count
  end

  def self.all(start_with = 'C')
    start = TONES.index(start_with.downcase)
    tonality = Scale.new(start_with).tonality
    TONES.circular(start..(start - 1)).map do |tonic|
      self.new(tonality == :major ? tonic.upcase : tonic.downcase )
    end
  end

  def self.expand(basis = 'C')
    Scale.new(basis).tones.map do |tonic|
      self.new(tonic) rescue nil
    end.compact
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
        sum += STEPS.circular(i - 2)
      else
        sum += STEPS.circular(i + 4)
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
    tone = TONES.circular(pos_to_index(pos))
    with_case(tone, pos)
  end

  def with_case(tone, pos)
    look_pos = tonality == :major ? pos - 1 : pos + 4
    if MAJMIN.circular(look_pos) == :major
      tone.upcase
    elsif MAJMIN.circular(look_pos) == :diminished
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
      tones.map { |t| t.downcase.gsub('0', '') }.index(tone.downcase.gsub('0', '')) + 1 rescue nil
    else
      tones.index(tone) + 1 rescue nil
    end
  end

  def tone_like?(tone)
    p = pos(tone, :case_sensitive => false)
    tone(p) if p
  end

  def to_s(range = 1..7)
    tones(range).map do |tone|
      tone.ljust(SPACE)
    end.join('  ')
  end

  def matrix(basis)
    str = ''
    start_output = colored? ? true : nil
    base_tones = Scale.new(basis).tones
    tones = []
    Scale.chromatic_tones(basis, 2).each do |tone|
      start_output ||= tone_like?(tone) == tonic
      next str << ' '.ljust(SPACE) if !start_output || (!colored? && tones.include?(tone))
      if (t = tone_like?(tone)) && start_output
        if t == tonic && colored?
          str << t.ljust(SPACE).red
        elsif base_tones.include?(t) && colored?
          str << t.ljust(SPACE).green
        else
          str << t.ljust(SPACE)
        end
      else
        str << '-'.ljust(SPACE)
      end
      tones << tone
    end
    str
  end
end

default = 'C'

start = $*.select { |arg| !(arg =~ /^--/) } .last || default
puts "Expanded #{start} scale:".underlined
Scale.expand(start).each do |scale|
  puts scale.matrix(start)
end

puts
puts "#{Scale.new(start).tonality.to_s.capitalize} scales:".underlined
Scale.all(start).each do |scale|
  puts scale.matrix(start)
end