#! /usr/bin/env shoes

Shoes.setup do
  gem 'sequel'
end

require 'sequel'

# Wrapper for getting information about a database
class Database

  def initialize connection_string
    @db = Sequel.connect connection_string
  end

  def table_names
    @db.tables
  end

  def column_names table_name
    # [ [:id, {...}], [:name, {...}] ]
    columns = @db.schema(table_name)
    columns.map {|column| column.first }
  end

  def first_10_rows table_name
    @db[table_name].limit(10).all
  end

  def first_10_rows_with_new_row table_name
    first_10_rows(table_name) + [{}]
  end

  def count table_name
    @db[table_name].count
  end

  def update_row table_name, id_primary_key, values
    if id_primary_key.strip != ''
      @db[table_name.to_sym].filter(:id => id_primary_key.to_i).update(values)
    else
      @db[table_name.to_sym].insert(values)
    end
  end

  def delete_row table_name, id_primary_key
    @db[table_name.to_sym].filter(:id => id_primary_key.to_i).delete
  end
end

class DatabaseGUI < Shoes
  url '/',             :index
  url '/tables/(\w+)', :table

  # Application variables
  class << self
    attr_accessor :database
  end

  # Elements
  attr_accessor :edit_connection_string

  def index
    database_info

    if database
      table_list :width => '20%'
      flow :width => '80%' do
        para '(select a table from the list on the left)'
      end
    else
      para 'No database loaded yet'
    end
  end

  def table table_name
    database_info

    if database
      table_list :width => '20%'
      column_list table_name, :width => '80%'
    else
      para 'No database loaded yet'
    end
  end

protected # VIEWS

  # Displays an edit_line that lets us enter a connection string.
  # Calls #connect("conn string") when a string is entered.
  def database_info
    flow do
      border black
      para 'Database Connection String:'
      self.edit_connection_string = edit_line 'sqlite://dogs.db'
      button 'Connect' do
        connect edit_connection_string.text
      end
    end
  end

  def table_list options = {}
    stack(options) do
      border blue
      database.table_names.each do |table_name|
        link_text = "#{table_name} (#{database.count(table_name)})"
        para link(link_text, :click => "/tables/#{ table_name }")
      end
    end
  end

  def column_list table_name, options = {}
    stack(options) do
      border red
      column_names = database.column_names table_name
      column_width = 100.0 / (column_names.length + 1) # +1 for the save button

      # column headers
      flow do
        column_names.each do |column_name|
          flow :width => "#{ column_width }%" do
            border black
            para strong(column_name)
          end
        end
      end

      # column values (rows)
      database.first_10_rows_with_new_row(table_name).each do |row|
        row_element = flow do
          column_names.each do |column_name|
            flow :width => "#{ column_width }%" do
              textbox = edit_line row[column_name], :width => '100%'
            end
          end
          flow :width => "#{ column_width }%" do
            button_text = row[:id] ? 'Save' : 'Create'
            button button_text do
              values = {}
              column_names.each_with_index do |column_name, i|
                values[column_name] = row_element.contents[i].contents.first.text
              end
              id = values.delete :id
              begin
                database.update_row table_name, id, values
                visit app.location # refresh
              rescue Exception => ex
                alert("Boom!  #{ ex.inspect }")
              end
            end

            if row[:id]
              button 'X' do
                values = {}
                column_names.each_with_index do |column_name, i|
                  values[column_name] = row_element.contents[i].contents.first.text
                end
                id = values.delete :id
                begin
                  database.delete_row table_name, id
                  visit app.location # refresh
                rescue Exception => ex
                  alert("Boom!  #{ ex.inspect }")
                end
              end
            end
          end
        end
      end

    end
  end

private

  # TODO should make it easy to delegate to application ... 
  #      maybe just app.database or something?
  def database
    DatabaseGUI.database
  end
  def database= value
    DatabaseGUI.database = value
  end

  def connect connection_string
    self.database = Database.new connection_string
    visit '/' # refresh
  end
end

Shoes.app :title => 'Database GUI'
