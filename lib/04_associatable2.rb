require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]


      through_table = through_options.table_name
      source_table = source_options.table_name
      self_foreign_key_value = self.send(through_options.foreign_key)

      join_key = "#{source_table}.#{source_options.primary_key} = " +
      "#{through_table}.#{through_options.primary_key}"
      where_line = "#{through_table}.#{through_options.primary_key} = ? "


      results = DBConnection.execute(<<-SQL, self_foreign_key_value)
        SELECT
          #{source_table}.*
        FROM
          #{source_table}
        JOIN
          #{through_table}
        ON
          #{join_key}
        WHERE
          #{where_line}
      SQL
      source_options.model_class.parse_all(results).first

    end
  end

  def has_many_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      self_table = self.class.table_name
      through_table = through_options.model_class.table_name
      source_table = source_options.model_class.table_name

      self_primary_key_value = self.send(through_options.primary_key)
      self_primary_key = through_options.primary_key
      through_foreign_key = through_options.foreign_key
      through_primary_key = source_options.primary_key
      source_foreign_key = source_options.foreign_key

      join_key_through = "#{self_table}.#{self_primary_key} = " +
      "#{through_table}.#{through_foreign_key}"

      join_key_source = "#{through_table}.#{through_primary_key} = " +
      "#{source_table}.#{source_foreign_key}"

      where_line = "#{self_table}.#{self_primary_key} = ? "

      results = DBConnection.execute(<<-SQL, self_primary_key_value)
        SELECT
          #{source_table}.*
        FROM
          #{self_table}
        JOIN
          #{through_table}
        ON
          #{join_key_through}
        JOIN
          #{source_table}
        ON
          #{join_key_source}
        WHERE
          #{where_line}
      SQL
      source_options.model_class.parse_all(results).

    end
  end
end
