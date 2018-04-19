class Password
        def self.encrypt(password)
            if valid_password(password)
                return hashed_password = BCrypt::Password.create(password)
            else
                return "what should i return?"
            end
        end


        private

        def valid_password(password)
            if password.empty? || password.include?(' ')
                return false
            end
            true
        end


end
