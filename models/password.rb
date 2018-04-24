class Password
        def self.encrypt(password, values)
            if self.valid_password(password)
                hashed_password = BCrypt::Password.create(password)
                values << hashed_password
                return values
            else
                return false
            end
        end

        def self.is_a?(obj)
            if obj == self
                return true
            else
                return false
            end
        end

        private

        def self.valid_password(password)
            if password.empty? || password.include?(' ')
                return false
            end
            return true
        end


end
