#!/usr/bin/env ruby

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

assignments = Assignment.create_assignments(pdf)
assignments.group_by(&:district_supervisor).each do |supervisor, assignments|
  supervisor
  assignment.each do |asgn|
    asgn.teachers.each do |teacher|
    end
  end
end
