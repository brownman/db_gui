#! /usr/bin/env shoes
# vim:set ft=ruby:

Shoes.setup { gem 'sequel' }
require 'sequel'

class DatabaseGUI < Shoes
  url '/',             :index
  url '/tables/(\w+)', :table

  class << self
    attr_accessor :db # cache the DB object on the object so it's available
  end

  def db() DatabaseGUI.db end

  def index
    database_info
    if db
      table_list :width => '20%'
      flow       :width => '80%' do
        para '(select a table from the list on the left)'
      end
    else
      para 'No database loaded yet', :align => 'center'
    end
  end

  def table table_name
    @table        = db[table_name.to_sym]
    @columns      = @table.columns
    @column_width = 100.0 / (@columns.length + 1) # + 1 extra column for save/delete buttons
    @rows         = @table.limit(10).all # get some rows
    database_info
    table_list                :width => '20%'
    table_columns table_name, :width => '80%'
  end

  def database_info
    flow do
      para 'Database Connection String:'
      @edit_connection_string = edit_line 'sqlite://dogs.db', :width => 350, :margin_left => 5
      button 'Connect' do
        DatabaseGUI.db = Sequel.connect @edit_connection_string.text
        visit '/' # refresh the home screen (new database)
      end
    end
    stack(:height => 1){ background black } # separator
  end

  def table_list options = {}
    stack(options) do
      db.tables.each do |table_name|
        link_text = "#{table_name} (#{db[table_name].count})"
        para link(link_text, :click => "/tables/#{ table_name }")
      end
    end
  end

  def table_columns table_name, options = {}
    stack(options) do
      column_headers
      column_rows
    end
  end

  def column_headers
    flow do
      @columns.each do |column|
        flow :width => "#{ @column_width }%" do
          para strong(column)
        end
      end
    end
  end

  # returns Hash like { :name => 'value of text box' } given the UI row element
  def row_values row_element
    values = {}
    @columns.each_with_index do |column_name, i|
      values[column_name] = row_element.contents[i].contents.first.text # get the value from the UI element
    end
    values
  end

  def save_button
    button 'Save' do |btn|
      values = row_values btn.parent.parent
      id     = values.delete :id
      @table.filter(:id => id.to_i).update(values)
      visit app.location # refresh
    end
  end

  def create_button
    button 'Create' do |btn|
      values = row_values btn.parent.parent
      values.delete :id
      @table.insert(values)
      visit app.location # refresh
    end
  end

  def delete_button
    button 'X' do |btn|
      values = row_values btn.parent.parent
      @table.filter(:id => values[:id].to_i).delete
      visit app.location # refresh
    end
  end

  def column_rows
    (@rows + [{}]).each do |row|
      flow do
        @columns.each do |column|
          flow :width => "#{ @column_width }%" do
            textbox = edit_line row[column], :width => '100%'
          end
        end

        flow :width => "#{ @column_width }%" do
          if row[:id].nil? # new record
            create_button
          else
            save_button
            delete_button
          end
        end
      end
    end
  end

end

Shoes.app :title => 'Database GUI', :width => 750
