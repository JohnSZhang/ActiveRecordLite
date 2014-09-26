require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.to_s.constantize
  end

  def table_name
    self.model_class::table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.class_name = options[:class_name] ||= name.to_s.camelize
    self.foreign_key = options[:foreign_key] ||= (name.to_s + "_id").to_sym
    self.primary_key = options[:primary_key] ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.class_name = options[:class_name] || name.to_s.singularize.camelize

    self.foreign_key = options[:foreign_key] || (self_class_name.to_s.underscore + "_id").to_sym

    self.primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    self.assoc_options[name] = options

    define_method(name.to_sym) do
      klass = options.model_class
      foreign_key_value = self.send(options.foreign_key)
      klass.where( options.primary_key => foreign_key_value).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method(name.to_sym) do
      klass = options.model_class
      primary_key_value = self.send(:id)
      klass.where( options.foreign_key => primary_key_value )
    end
  end

  def assoc_options
    @assoc_options ||= Hash.new
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
  # Mixin Associatable here...
end
