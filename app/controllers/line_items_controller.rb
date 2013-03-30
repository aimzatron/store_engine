class LineItemsController < ApplicationController

  def create
    puts "in create"
    @cart = current_cart
    product = Product.find(params[:product_id])
    @line_item = @cart.add_product(product.id)
    @line_item.product = product
      
    respond_to do |format|
      if @line_item.save
        format.html { redirect_to product_path(product) }
        format.js   { @current_item = @line_item }
        format.json { render json: @line_item, status: :created, location: @line_item} 
      else
        format.html { redirect_to product_path(product), notice: 'An error occurred, please try again' }
        format.json { render json: @line_item.errors, status: :unprocessable_entity }
      end
    end
  end

end