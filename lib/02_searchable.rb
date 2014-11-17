require_relative 'db_connection'
require_relative '01_sql_object'
require_relative '03_associatable'

module Searchable
  def where(params)
    # where_line = params.keys.map{|key| " #{ key } = ?"}.join(' AND ')
    # results = DBConnection.execute(<<-SQL, params.values)
    #   SELECT
    #     *
    #   FROM
    #     #{self.table_name}
    #   WHERE
    #     #{where_line}
    # SQL
    Relation.new(self).where(params)


  end
end

class SQLObject

  # Mixin Searchable here...
  extend Searchable
end
