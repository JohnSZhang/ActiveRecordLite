require_relative '04_associatable2'
require 'active_support/inflector'

class Relation
  attr_accessor :params, :parent
  def initialize(parent)
    @parent = parent #SQLOBJECT CLASS
    self.params = {}
    self.params[:select] = ["#{@parent.table_name}.*"]
    self.params[:from] = [ @parent.table_name ]
    self.params[:where] = {}

  end

  def method_missing(name, *args)
    self.eval.send(name, *args)
  end

  def joins()
    self
  end

  def where(params)
    self.params[:where].merge!(params)
    self
  end

  def select()
    self
  end

  def group()
    self
  end

  def having()
    self
  end

  def build
    select_clause = self.params[:select].join(", ")
    from_clause = self.params[:from].join(", ")
    where_clause = []
    self.params[:where].each do |key,value|
      where_clause << "#{ key } = '#{ value }'"
    end
    where_clause = where_clause.join(" AND ")
    DBConnection.execute(<<-SQL)
      SELECT #{ select_clause }
      FROM #{ from_clause }
      #{ "WHERE " + where_clause unless where_clause == "" }
    SQL

  end

  def eval
    collection = []
    objects = self.build
    objects.each do |object|
      collection << self.parent.new(object)
    end
    collection
  end

end