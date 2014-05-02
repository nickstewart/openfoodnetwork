collection Enterprise.is_distributor
attributes :name, :id

child :taxons do
  attributes :name, :id
end

child :address do
  attributes :city, :zipcode
  node :state do |address|
    address.state.abbr
  end
end

node :pickup do |hub|
  not hub.shipping_methods.where(:require_ship_address => false).empty?
end

node :delivery do |hub|
  not hub.shipping_methods.where(:require_ship_address => true).empty?
end

node :path do |hub|
  shop_enterprise_path(hub) 
end

node :active do |hub|
  @active_distributors.include?(hub)
end

node :orders_close_at do |hub|
  OrderCycle.first_closing_for(hub).andand.orders_close_at
end