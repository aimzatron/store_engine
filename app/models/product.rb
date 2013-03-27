class Product < ActiveRecord::Base
  attr_accessible :title, :description, :price_in_dollars_and_cents, :active

  validates_uniqueness_of :title
  validates_presence_of :title, :description, :price
  validates :price, :numericality => {:greater_than => 0}
  
  def active?
    if self.active == false
      "retired"
    else
      "active"
    end
  end

  def price_in_dollars_and_cents
    #price.to_i / 100.0
    "%.2f" % (price.to_i / 100.0)
  end

  def price_in_dollars_and_cents=(value)
    self.price = value.to_f * 100.0
  end

end
