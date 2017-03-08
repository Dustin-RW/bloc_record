module BlocRecord
  class Collection < Array

    def update_all(updates)
      ids = self.map(&:id)

      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(limit=1)
      # return somehow collection of self.rows, limit to 1 unless passed a different limit
      if self.any?
        self[0...limit]
      else
        nil
      end
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

      #method only within #where scope
      def not
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
            if args.first.keys[0] == nil
              expression_hash = BlocRecord::Utility.convert_keys(args.first)
              expression = expression_hash.map { |key, value| "#{key} IS NOT NULL" }
            else
              expression_hash = BlocRecord::Utility.convert_keys(args.first)
              expression = expression_hash.map { |key, value| "#{key} = #{BlocRecord::Utility.sql_strings(value)}"}.join("<>")
            end
          end

          sql = <<-SQL
            SELECT #{columns.join ","} FROM #{table}
            WHERE #{expression};
          SQL

          rows = connection.execute(sql, params)
          rows_to_array(rows)
        end
      end
    end

  end
end
