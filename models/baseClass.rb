class BaseClass

    def self.delete_table()

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
            columns_query = self.join_columns(@columns)

            final_query = start_query + columns_query + ")" + row_id_query

            @db.execute(final_query)
        end
    end

    def self.insert(hash)

    end

    def self.table_exists?
        return @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='#{@table_name}'")
    end

    private

    def self.join_columns(hash)    #parse_columns instead of join_columns?
        final_string = ""
        hash.each_pair do |key,value|
            final_string += "#{key.to_s} #{value},"
        end
        #quick fix to remoce the last comma
        final_string = final_string[0..-2]
        return final_string
    end

end
