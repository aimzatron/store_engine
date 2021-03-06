class Category < ActiveRecord::Base
  attr_accessible :name

  validates_uniqueness_of :name
  validates_presence_of :name
  has_many :product_categories
  has_many :products, through: :product_categories

  def to_s
    name
  end
end
