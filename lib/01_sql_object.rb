require_relative 'db_connection'
require_relative 'relations'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    first_row = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    first_row[0].map{ |col_name| col_name.to_sym }
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column.to_s) do
        @attributes[column]
      end
    end
    self.columns.each do |column|
      define_method("#{column}=") do |value|
        @attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    all_data = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    Relation.new(self)
  end

  def self.parse_all(results)
    objects = []
    results.each do |object|
      objects << self.new(object)
    end
    objects
  end

  def self.find(id)
    object_data = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    self.new(object_data.first)
  end

  def initialize(params = {})
    @attributes = Hash.new
    params.each do |attr_name, value|
      attribute_sym = attr_name.to_sym
      unless self.class.columns.include?(attribute_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=".to_sym, value)
    end
  end

  def attributes
    @attributes
  end

  def attribute_values
    self.class.columns.map{|attr| self.send(attr) }
  end

  def insert
    col_names = self.class.columns
    col_names_string = col_names.join(', ')
    question_marks = (["?"]* col_names.count).join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO
         #{self.class.table_name} (#{col_names_string})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns
    col_names_string = col_names.map{ |col| "#{col} = ?" }.join(",")
    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
      UPDATE
         #{self.class.table_name}
      SET
         #{col_names_string}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
