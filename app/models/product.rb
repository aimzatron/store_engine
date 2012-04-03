class Product < ActiveRecord::Base
  attr_accessible :title, :description, :activity, :price, :image_link

  validates_presence_of :title, :description
  validates_numericality_of :price, :greater_than => 0

  validates_uniqueness_of :title
end