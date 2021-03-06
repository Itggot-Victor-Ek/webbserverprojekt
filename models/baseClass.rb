class BaseClass

    # Deletes the table which it is connected to 😥
    #
    # @return [nil]
    def self.delete_table()
        @db.execute("DROP TABLE #{@table_name}")
        return nil
    end

    # Stores the table name 📖
    #
    # @param table_name [String] takes the name as a string
    # @return [nil]
    def self.table_name(table_name)
        @table_name = table_name
        return nil
    end

    # Store all column names and the type it is 🌞
    #
    # @param hash [Hash] the column name and type eg. columnName: "type"
    # @return [nil]
    def self.column(hash)
        @columns ||= {}
        @columns.merge!(hash)
    end

    # Creates the table and database if it doesn't exist 🙀
    #
    # @param db [String] the path to the database eg. '/db/db.sqlite'
    # @param use_row_id [Boolean] if you want the databae to create a
    #   id column or if you created one yourself
    # @return [nil]
    def self.create_table(db, use_row_id)

        @db = SQLite3::Database.new(db)
        unless self.table_exists?
            start_query = "CREATE TABLE #{@table_name}("
            columns_query = self.join_columns(@columns, use_row_id)

            final_query = start_query + columns_query + ")"
            @db.execute(final_query)
            return nil
        end
        return nil
    end

    # Insert specified value/s into specified column/s with requirements 💁
    #
    # @param hash [Hash] the basic way follows: 'columnName: new_value'. to pass
    #   through requirements the value of the has has to be an array where the
    #   first element is the new value and the second element is the key
    #   requirements: and has an array with the requirement as a symbol.
    #   example: column: [new_value, requirements: [:unique, :no_space]]
    # @return [Boolean] returns if the action was successfull or not
    def self.insert(hash)
        result = extract_values(hash)
        values = []
        columns = []
        if result
            values = result[0]
            columns = result[1]
        else
            return false
        end

        columns_query = ""
        columns.each do |column|
            columns_query += column + ','
        end
        columns_query = columns_query[0..columns_query.length-2]
        start_query = "INSERT INTO #{@table_name}(" + columns_query + ') '
        values_query = "VALUES("
        values.each do |value|
            values_query += '?,'
        end
        values_query[values_query.length-1] = ')'
        final_query = start_query + values_query
        p final_query
        p values
        @db.execute(final_query, values)
        return true
    end

    # Updates specified value in the specified column with requirements 📈
    #
    # @param hash [Hash] the basic way follows: 'columnName: new_value'. to pass
    #   through requirements please refer to the insert method.
    # @param old_value [String] Takes the old value you want to change
    # @return [Boolean] returns if the action was successfull or not
    def self.update(hash, old_value)
        result = extract_values(hash)
        values = []
        column = []
        if result
            values = result[0]
            column = result[1]
        else
            return false
        end

        start_query = "UPDATE #{@table_name} "
        update_columns_query = "SET #{column.first} = ?"
        where_query = "WHERE #{column[0]} IS #{old_value}"

        final_query = start_query + update_columns_query + where_query
        @db.execute(final_query, values)
        return values[0]
    end

    private

    def self.table_exists?
        return @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='#{@table_name}'")[0]
    end

    def self.extract_values(hash)
        columns = []
        values = []
        hash.each_pair do |key,value|
            if value.is_a? Array
                columns << key.to_s
                result = self.valid_requirements?(value[1][:requirements], key.to_s, value.first, values)
                if result.is_a? Array
                    values = result[1]
                elsif result
                    values << value[0]
                else
                    return false
                end

            else
                columns << key.to_s
                values << value
            end
        end
        return values, columns
    end

    #takes in a hash and joins the key and value to make a sqlite query
    def self.join_columns(hash, use_row_id)
        final_string = ""
        i = 0
        hash.each_pair do |key,value|
            if !use_row_id && i == 0
                final_string += "#{key.to_s} #{value} PRIMARY KEY,"
            else
                final_string += "#{key.to_s} #{value},"
            end
            i+=1
        end
        #quick fix to remove the last comma
        final_string = final_string[0..-2]
        return final_string
    end

    def self.valid_requirements?(requirements, column, value, values)
        requirements_met = true
        requirements.each do |requirement|
            if requirement.is_a? Password
                @new_values = Password.encrypt(value, values)
                condition_met = @new_values
            elsif requirement == :unique
                condition_met = self.check_duplicate_in_database(value, column)
            elsif requirement == :no_space
                condition_met = self.no_space(value)
            end

            if !condition_met && !@new_values
                requirements_met = false
            end
        end
        if defined? @new_values
            return [requirements_met, @new_values]
        end
        return requirements_met
    end

    def self.check_duplicate_in_database(value, column)
        data = @db.execute("SELECT #{column} FROM #{@table_name} WHERE #{column} IS ?",[value])
        if data != []
            return false
        end
        return true
    end

    def self.no_space(value)
        if value.include?(' ')
            return false
        end
        return true
    end
end
