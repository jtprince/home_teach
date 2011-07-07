require 'spec_helper'

require 'home_teach/assignment'

describe "Parsing a simple text doc (transformed from PDF with names changed)" do
  before do
    # a txt file created with pdftotxt from poppler
    @txt_file = TESTFILES + '/Home_Teaching_Assignments-mock.txt'
  end

  it 'works' do
    assignments = HomeTeach::Assignment.create(@txt_file)
    p assignments[0,3]
    1.is 1
  end
end
