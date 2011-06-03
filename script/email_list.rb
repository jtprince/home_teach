#!/usr/bin/env ruby

# collects all email addresses

require 'trollop'
require 'home_teaching_assignments'

parser = Trollop::Parser.new do
  banner "usage: #{File.basename(__FILE__)} <file>.pdf"
end

opt = parser.parse(ARGV)

if ARGV.size == 0
  parser.educate && exit
end

pdf = ARGV.shift

assignments = Assignment.create_assignments(pdf, :merge => true)

uniq = assignments.map(&:teachers).flatten.group_by {|teacher| [teacher.last, teacher.first] }.map {|k,v| v.first }
uniq.each do |person|
end
emails = uniq.map {|person| %Q{"#{person.first} #{person.last}" <#{person.email}>} }.join(', ')
p emails
