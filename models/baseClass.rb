class BaseClass

    def self.delete_table()
        @db.execute("DROP TABLE [IF EXISTS] [schema_name.]#{@table_name}")
    end

    def self.table_name(table_name)
        @table_name = table_name
    end

    def self.columns(hash)
        @columns = hash
    end

    def self.create_table(db, use_row_id)
        @db = db
        unless self.table_exists?
            row_id_query = ""
            if !use_row_id
                row_id_query = "[WITHOUT ROWID]"
            end

            start_query = "CREATE TABLE [schema_name].#{@table_name}("
            columns_query = self.join_columns(@columns, use_row_id)

            final_query = start_query + columns_query + ")" + row_id_query
            @db.execute(final_query)
        end
    end

    def self.insert(hash)
        columns_query = ""
        values = []
        hash.each_pair do |key,value|
            if value.is_a? Array
                columns_query += key.to_s + ','
                result = self.requiremnet_checker(value[1][:requirements], key.to_s, value.first, values)
                if result.is_a? Array
                    p "result"
                    p result[1]
                    values = result[1]
                elsif result
                    p value[0]
                    values << value
                else
                    return false
                end

            else
                columns_query += key.to_s + ','
                values << value
            end
        end

        start_query = "INSERT INTO #{@table_name}(" + columns_query[0..columns_query.length-2] + ') '
        values_query = "VALUES("
        p values
        values.each do |value|
            values_query += '?,'
        end
        values_query[values_query.length-1] = ')'
        final_query = start_query + values_query
        p final_query
        @db.execute(final_query, values)
        return true
    end

    def self.table_exists?
        return @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='#{@table_name}'")
    end

    private

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

    def self.requiremnet_checker(requirements, column, value, values)
        requirements_met = true
        requirements.each do |requirement|

            if requirement.is_a? Password
                new_values = Password.encrypt(value, values)
                p "vvvv new values vvvv"
                p new_values
                sleep(20)
                condition_met = new_values
            elsif requirement == "no duplicate"
                condition_met = self.check_duplicate_in_database(value, column)
            elsif requirement == 'no space'
                condition_met = self.no_space(value)
            end

            if !condition_met && !new_values
                requirements_met = false
            end
        end
        return requirements_met, new_values if defined? new_values
        return requirements_met
    end

    def self.check_duplicate_in_database(value, column)
        data = @db.execute("SELECT #{column} FROM #{@table_name}")
        data.each do |data_value|
            if data_value.first == value
                return false
            end
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
