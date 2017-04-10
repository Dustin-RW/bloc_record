require 'sqlite3'

module Selection
  def find(*ids)
    puts "WHRE AM I"
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
    puts "I AM HERE"

    if id.kind_of? String || id <= 0
      puts "must enter a postive number"
    else
      sql = <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      puts sql

      row = connection.execute sql

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
  def find_each(*options)

    if options.nil?
      items = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
      SQL
    else
      items = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{options.size} OFFSET #{options.start};
      SQL
    end

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

    #check if items are nil.  If not, yield rows as an entire batch
    if items.nil?
      nil
    else
      yield rows_to_array(items)
    end

  end

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
        args.each do |arg|
          if arg.class == String
            value = arg
          else
            value = arg.to_s
          end
        end

        find_by(attribute, value)
      else
        super
      end

    elsif method.to_s[0...5] == "update"
      attribute = nil
      value = nil
      attribute = method.to_s[7...method.length].downcase
      attribute.slice!(0) if attribute[0] == "_"

      if self.attributes.include?(attribute)
        args.each do |arg|
          if arg.class == String
            value = arg
          else
            value = arg.to_s
          end
        end

        self.update_attribute(attribute, value)
      else
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
    orders = []

    if args
      #assend_descent verifys ASC or DESC, otherwise applies defaults ASC (see private methods)
      args.each do |arg|
        if arg.kind_of? String
          orders << assend_descend(arg)
        elsif arg.kind_of? Symbol
          orders << assend_descend(arg.to_s)
        elsif arg.kind_of? Hash
          orders << assend_descend(arg.map{|k,v| "#{k} #{v}"}.join(''))
        end
      end
    end

    orders.join(',')


    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{orders};
    SQL

    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id;
        SQL
      when Hash
        key = args.first.keys[0]
        value = args.first.values[0]
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id
          INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id
        SQL
      end
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
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end

  #string provided includes a ASC or DESC.  If not, provided default ASC for SQL
  def assend_descend(string)
    if string.include?(" asc") || string.include?(" ASC") || string.include?(" desc") || string.include?(" DESC")
      string
    else
      string << " ASC"
    end
  end
end
