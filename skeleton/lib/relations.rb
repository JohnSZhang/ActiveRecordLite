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
    self.params[:having] = []
    @query = {}
  end

  def method_missing(name, *args)
    self.eval.send(name, *args)
  end

  def joins(*params)
    if params.count = 1 && params[0].is_a?(String)
      self.params[:joins] << params[0]
    elsif params.count = 1 && params.is_a?(Symbol)
      options = parent.assoc_options[params.first]

      #add join and find foreign keys and tables
    elsif params.all?{ |el| el.is_a?(Symbol) }
      #add multiple joins on multiple keys and tables.
    else
      self.argument_error
    end
    self
  end

  def where(params)
    self.params[:where].merge!(params)
    self
  end

  def select(params)
    if params.is_a?(String)
      self.params[:select] = [params]
    elsif params.is_a?(Symbol)
      self.params[:select] = [params.to_s]
    elsif params.is_a?(Array)
      self.params[:select] = params.map { |el| el.to_s }.join(', ')
    else
      raise self.argument_error
    end
    self
  end

  def group(params)
    if params.is_a?(String)
      self.params[:group].merge!(params)
    elsif params.is_a?(Symbol)
      self.params[:group] << params.to_s
    elsif params.is_a?(Array)
      self.params[:group] << (params.map{ |el| el.to_s }.join(', '))
    else
      raise self.argument_error
    end
    self
  end

  def having(params)
    self.params[:having] << params
    self
  end

  def build_clause
    if not self.params[:having].nil && self.params[:group].nil?
      raise "Need To Have A Having Clause"
    end

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

  def argument_error
    "Invalid Argument Type"
  end
end