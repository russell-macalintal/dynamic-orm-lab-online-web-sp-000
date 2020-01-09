require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info(#{self.table_name})"
    table_info = DB[:conn].execute(sql)
    # sql = "PRAGMA table_info(?)"
    # table_info = DB[:conn].execute(sql, self.table_name)
    column_names = []

    table_info.each do |column|
      column_names << column["name"]
    end

    column_names.compact
  end

  def initialize(options = {})
    options.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    col_names = self.class.column_names
    col_names.delete_if {|name| name == "id"}
    col_names.join(", ")
  end

  def values_for_insert
    values = []

    self.class.column_names.each do |name|
      values << "'#{send(name)}'" unless send(name).nil?
    end

    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
      SQL

    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name} WHERE name = ?
      SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(attr_hash)
    sql = <<-SQL
      SELECT * FROM #{self.table_name} WHERE #{attr_hash.keys[0].to_s} = ?
      SQL

    DB[:conn].execute(sql, attr_hash.values[0])
  end
end
