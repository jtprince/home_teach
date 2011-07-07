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


SimplePerson = Struct.new(:last, :first, :email)

uniq = assignments.map(&:teachers).flatten.group_by {|teacher| [teacher.last, teacher.first] }.map {|k,v| v.first }

speople = uniq.map {|t| SimplePerson.new(t.last, t.first, t.email) }

(no_email, email) = speople.partition {|t| t.email.nil? }
puts "No email address:"
no_email.each do |p|
  puts "#{p.first} #{p.last}"
end

string = email.map do |p|
  %Q{"#{p.first.gsub(/\s+/,' ')} #{p.last.strip}" <#{p.email}>}
end.join(', ')
puts string
