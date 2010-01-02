#! /usr/bin/env shoes

Shoes.setup do
  gem 'sequel'
end

require 'sequel'

class DatabaseGUI < Shoes
  url '/',             :index
  url '/tables/(\w+)', :table

  class << self
    attr_accessor :db # cache the DB object on the object so it's available
  end

  # shortcut to the DB object
  def db() DatabaseGUI.db end

  def index
    database_info

    if db
      table_list :width => '20%'
      flow :width => '80%' do
        para '(select a table from the list on the left)'
      end
    else
      para 'No database loaded yet', :align => 'center'
    end
  end

  def table table_name
    @table = db[table_name.to_sym]
    @rows  = @table.limit(10).all # get some rows

    database_info
    table_list :width => '20%'
    column_list table_name, :width => '80%'
  end

protected # VIEWS

  # Displays an edit_line that lets us enter a connection string.
  # Calls #connect("conn string") when a string is entered.
  def database_info
    flow do
      para 'Database Connection String:'
      @edit_connection_string = edit_line 'sqlite://dogs.db', :width => 350, :margin_left => 5
      button 'Connect' do
        connect @edit_connection_string.text
      end
    end

    # separator
    stack :height => 1 do
      background black
    end
  end

  # Displays a list of links to table names
  def table_list options = {}
    stack(options) do
      db.tables.each do |table_name|
        link_text = "#{table_name} (#{db[table_name].count})"
        para link(link_text, :click => "/tables/#{ table_name }")
      end
    end
  end

  # Displays column information and a few rows for the given table
  def column_list table_name, options = {}
    stack(options) do
      column_names = @table.columns
      column_width = 100.0 / (column_names.length + 1) # +1 for the save button

      # column headers
      flow do
        column_names.each do |column_name|
          flow :width => "#{ column_width }%" do
            para strong(column_name)
          end
        end
      end

      # column values (rows)
      (@rows + [{}]).each do |row|
        row_element = flow do

          # edit box for attribute
          column_names.each do |column_name|
            flow :width => "#{ column_width }%" do
              textbox = edit_line row[column_name], :width => '100%'
            end
          end

          # buttons
          flow :width => "#{ column_width }%" do

            # Save/Create button
            button_text = row[:id] ? 'Save' : 'Create'
            button button_text do
              values = {}
              column_names.each_with_index do |column_name, i|
                values[column_name] = row_element.contents[i].contents.first.text
              end
              id = values.delete :id
              begin
                if id.strip != ''
                  @table.filter(:id => id.to_i).update(values)
                else
                  @table.insert(values)
                end
                visit app.location # refresh
              rescue Exception => ex
                alert("Boom!  #{ ex.inspect }")
              end
            end

            # Delete button
            if row[:id]
              button 'X' do
                values = {}
                column_names.each_with_index do |column_name, i|
                  values[column_name] = row_element.contents[i].contents.first.text
                end
                id = values.delete :id
                begin
                  @table.filter(:id => id.to_i).delete
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

  def connect connection_string
    DatabaseGUI.db = Sequel.connect connection_string
    visit '/' # refresh home screen
  end
end

Shoes.app :title => 'Database GUI', :width => 750
