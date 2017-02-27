require 'sqlite3'

module Selection
  def find(*ids)
    if ids.kind_of? String || ids <= 0
      puts "must enter a postive number"
    elsif ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(row)
    end
  end

  def find_one(id)
    if ids.kind_of? String || ids <= 0
      puts "must enter a postive number"
    else
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    end
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  # Find every record
  # for each record, transform it to a Model
  # yield each model individually
  def find_each(options = {})

    items = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{options.size} OFFSET #{options.start};
    SQL

    items.each do |item|
      yield init_object_from_row(item)
    end

  end

  # Find every record
  # for each record, transform it to a Model
  # yield every model at once
  def find_in_batches(options = {})

    items = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{options.size} OFFSET #{options.start};
    SQL

    rows_to_array(items)

  end

  # find_each("dog", "cat", "fish", options = {start: 4000, size: 300}})

  # method conditional for any 'find_by' method past.  Conditionals should be met with those in SQL table, otherwise
  def method_missing(method, *args)

    if method.to_s[0...7] == "find_by" # if random method starts with `find_by`, method will be accepted
      if args.length > 1
        puts "please provide only one argument"
        method_missing(method, *args)
      end

      attribute = nil
      value = nil
      attribute = method.to_s[7...method.length].downcase
      attribute.slice!(0) if attribute[0] == "_"

      if self.attributes.include?(attribute)
        puts "im here here"
        args.each do |arg|
          if arg.class == String
            value = arg
          else
            value = arg.to_s
          end
        end

        find_by(attribute, value)
      else
        # return back to normal method_missing
        super
      end

    else
      # return back to normal method_missing
      super
    end

  end

  def take(num=1)
    return nil if num.kind_of? String

    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(row)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    # handle array input
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      #handle String input
    when String
        expression = args.first
      #handle Hash input
    when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key} = #{BlocRecord::Utility.sql_strings(value)}"}.join("and")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end


  def order(*args)
    if args.count > 1
      order = args.join(",")
    else
      order = args.first.to_s
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL

    rows_to_array(row)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
      rows = connection.execute <<-SQL
        SELECT * FROM #{table}
        INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
      SQL
    end

    rows_to_array(rows)
  end

  private

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  # Wraps each row in a record object
  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end

end
