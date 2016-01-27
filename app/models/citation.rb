class Citation < ActiveRecord::Base
  #belongs_to :violation, :reverse_of => :citations
  #has_many :appointments, :reverse_of => :citation
end
