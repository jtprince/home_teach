require 'spec_helper'

require 'home_teach/assignment'

describe "Parsing a simple text doc (transformed from PDF with names changed)" do
  before do
    # a txt file created with pdftotxt from poppler
    @txt_file = TESTFILES + '/Home_Teaching_Assignments-mock.txt'
  end

  it 'reads assignments' do
    assignments = HomeTeach::Assignment.create(@txt_file)
    teachers = assignments.map(&:teachers).flatten(1)
    teachers.size.is 8
  end
end
