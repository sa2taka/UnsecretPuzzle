require_relative '../models.rb'

class Style < ActiveRecord::Base
  belongs_to :user
end
