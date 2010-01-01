#! /usr/bin/env shoes

Shoes.setup do
  gem 'sequel'
end

require 'sequel'

Shoes.app do

  def connect connection_string
    begin
      @db = Sequel.connect connection_string
      update_tables
    rescue Exception => ex
      alert "Connection failed: #{ ex.message }"
    end
  end

  def update_tables
    @tables.clear
    @db.tables.each do |table|
      @tables.append do 
        stack do
          title table

          @db.schema(table).each do |column|
            # [:id, {:type => :integer, ...}]
            name = column.first
            type = column.last[:type]
            para "#{ name } [#{ type }]"
          end
        end
      end
    end
  end

  # Top of the screen, where we enter the database info
  flow do
    border black
    para 'Database Connection String:'
    @connection_string = edit_line 'sqlite://dogs.db'
    button('Connect'){ connect @connection_string.text }
  end

  # The list of tables
  @tables = stack do
  end

end
