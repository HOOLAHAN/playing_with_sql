# file: app.rb

require_relative 'lib/item'
require_relative 'lib/item_repository'
require_relative 'lib/order'
require_relative 'lib/order_repository'
require_relative 'lib/database_connection'

class Application

  def initialize(database_name, io, item_repository, order_repository)
    DatabaseConnection.connect(database_name)
    @io = io
    @item = ItemRepository.new
    @order = OrderRepository.new
  end

  def print_menu
    @io.puts "Welcome to the shop management program!"
    @io.puts "What would you like to do?"
    @io.puts "1 = list all shop items"
    @io.puts "2 = create a new item"
    @io.puts "3 = list all orders"
    @io.puts "4 = create a new order"
    @io.puts "5 = exit"
  end

  def run
    print_menu
    user_input = @io.gets.chomp
    if user_input == "1"
      return print_all_items
    elsif user_input == "2"
      return add_stock_item
    elsif user_input == "3"
      return list_all_orders
    elsif user_input == "4"
      return create_new_order
    elsif user_input == "5"
      @io.puts "Goodbye."
      return false
    else
      @io.puts "Input error."
      return false
    end
  end

  def print_all_items
    sql = 'SELECT id, item, price, stock FROM items;'
    result_set = DatabaseConnection.exec_params(sql, [])
    result_set.each do |cell|
      @io.puts cell.values.join(" - ")
    end
  end
 
  def add_stock_item
    @io.puts "Please enter item name:"
    item_name = @io.gets.chomp
    @io.puts "Please enter item unit price in pence:"
    item_price = @io.gets.chomp
    @io.puts "Please enter item stock quantity:"
    item_stock = @io.gets.chomp
    id = (@item.stock_list.length + 1).to_s
    sql = 'INSERT INTO items (id, item, price, stock) VALUES ($1, $2, $3, $4);'
    sql_params = [id, item_name, item_price, item_stock]
    result_set = DatabaseConnection.exec_params(sql, sql_params)
    return nil
  end

  def list_all_orders
    sql = 'SELECT id, name, date FROM orders;'
    result_set = DatabaseConnection.exec_params(sql, [])
    result_set.each do |cell|
      @io.puts cell.values.join(" - ")
    end
  end

  def print_an_item(id)
    sql = 'SELECT id, item, price FROM items WHERE id = $1;'
    sql_params = [id]
    result_set = DatabaseConnection.exec_params(sql, sql_params)
    result_set.each do |cell|
      @io.puts cell.values.join(" - ")
    end
  end

  def select_price(id)
    sql = 'SELECT price FROM items WHERE id = $1;'
    sql_params = [id]
    result_set = DatabaseConnection.exec_params(sql, sql_params)
    return result_set[0]['price']
  end

  def fill_order
    @order_array = []
    repo = ItemRepository.new
    total_in_shop = repo.stock_list.length  
    until false do
      @io.puts "Please confirm item number to be added to order. To complete type 'stop'"
      item = @io.gets.chomp
      if item == 'stop'
        break
      elsif  item.to_i > total_in_shop || item.to_i < 1
        @io.puts "Please enter a valid item number"
      else
        @order_array << item
      end
    end
    @io.puts "Here is your order:"
    @order_array.each do |item|
      print_an_item(item)
    end
    total = []
    @order_array.each do |item|
      total << select_price(item).to_f
    end
    @io.puts "TOTAL: £#{total.sum/100}"
  end

  def create_new_order
    fill_order
    @io.puts "Please enter customer name:"
    customer_name = @io.gets.chomp
    order_date = Time.new.strftime("%Y/%m/%d")
    id = (@order.order_history.length + 1).to_s
    sql = 'INSERT INTO orders (id, name, date) VALUES ($1, $2, $3);'
    sql_params = [id, customer_name, order_date]
    result_set = DatabaseConnection.exec_params(sql, sql_params)
    return nil
  end

end

if __FILE__ == $0
  app = Application.new(
    'shop_manager',
    Kernel,
    ItemRepository.new,
    OrderRepository.new
  )
  app.run
end