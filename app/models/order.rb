class Order < ActiveRecord::Base
  attr_accessible :total_price, :user_id, :stripe_card_token
  attr_accessor :stripe_card_token

  has_many :line_items
  has_many :events, class_name: "OrderEvent"

  belongs_to :user
  validates_presence_of :total_price, :user_id

  def self.create_from_cart(cart, order_details, user)

    order = new(order_details)
    order.add_line_items(cart)
    order.total_price = order.total_price_from_cart(cart)
    order.user = user

    order.save_with_payment
    order
  end

  def save_with_payment
    if valid?
      Stripe::Charge.create(amount: self.total_price * 100, currency: "usd",
        card: stripe_card_token, description: self.user.email)
      save!
      self.paid
    end
  rescue Stripe::InvalidRequestError => e
    logger.error "Stripe error while creating customer: #{e.message}"
    errors.add :base, "There was a problem with your credit card."
    false
  end

  def self.pending
    Order.all.select{|o| o.pending?}
  end

  def self.cancelled
    Order.all.select{|o| o.cancelled?}
  end

  def self.paid
    Order.all.select{|o| o.paid?}
  end

  def self.shipped
    Order.all.select{|o| o.shipped?}
  end

  def self.returned
    Order.all.select{|o| o.returned?}
  end

  def add_line_items(cart)
    cart.line_items.each do |li|
      li.cart_id = nil
      line_items << li
    end
  end

  def send_text_message

    if user.can_receive_messages?
      number_to_send_to = self.user.phone #params[:number_to_send_to]

      twilio_sid = ENV["TWILIO_SID"]
      twilio_token = ENV["TWILIO_TOKEN"]
      twilio_phone_number = "12402930574"

      @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token

      @twilio_client.account.sms.messages.create(
        :from => "+1#{twilio_phone_number}",
        :to => number_to_send_to,
        :body => "Your order has been shipped and will be delivered on Monday April 7th, 2013. Thank you!!!")
    end
  end

  def total_price_from_cart(cart)
    self.total_price = cart.total_price
    total_price
  end

  def add_quantity(line_item)
    current_item = line_items.find(line_item)
    current_item.quantity += 1
    current_item.save
  end

  def decrease_quantity(line_item)
    current_item = line_items.find(line_item)
    current_item.quantity -= 1
    current_item.save
  end


  STATUSES = %w[pending cancelled paid shipped returned]
  delegate :pending?, :cancelled?, :paid?, :shipped?, :returned?,
  to: :current_status

  def self.pending_orders
    joins(:events).merge OrderEvent.with_last_status("pending")
  end

  def current_status
    (events.last.try(:status) || STATUSES.first).inquiry
  end

  # def purchase(valid_payment = true)
  #   if incomplete?
  #     # process purchase ...
  #     events.create! status: "open" if valid_payment
  #   end
  # end

  def paid
    events.create! status: "paid" if pending?
  end

  def cancel
    events.create! status: "cancelled" if pending?
  end

  def return
    events.create! status: "returned" if shipped?
  end

  def ship
    events.create! status: "shipped" if paid?
  end
end
