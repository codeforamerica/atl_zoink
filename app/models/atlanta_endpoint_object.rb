class AtlantaEndpointObject < ActiveRecord::Base
  belongs_to :endpoint, :class_name => AtlantaEndpoint, :inverse_of => :rows
end
