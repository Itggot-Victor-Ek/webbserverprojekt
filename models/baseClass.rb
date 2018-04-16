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

end
