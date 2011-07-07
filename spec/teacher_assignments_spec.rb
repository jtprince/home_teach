require 'spec_helper'


require 'home_teaching_assignments'

describe "TeacherAssignments: parsing household info" do
  it "parses info from household lines without phone or email" do
    lines = ["Doogie", "3967 Winston Drive", "Gallant, ID 88877"]
    reply = Assignment::Parser.new.parse_person_and_contact(lines)
    reply.enums ["Doogie", nil, nil, nil, ["3967 Winston Drive", "Gallant, ID 88877"]]
  end
  it "parses info from household lines with phone and email" do
    # notice the phone number with a space in it!
    lines = ["SomeFirstname", "4279 Banana Lane", "Greenborough, WI 99887", "221 260-3955", "somebody@yahoo.com"]
    reply = Assignment::Parser.new.parse_person_and_contact(lines)
    reply.enums ["SomeFirstname", nil, "221 260-3955", "somebody@yahoo.com", ["4279 Banana Lane", "Greenborough, WI 99887",] ]
  end
end

describe "Parsing a simple text doc (transformed from PDF with names changed)" do
  before do
  end

  it 'works' do
  end
end
