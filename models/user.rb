class User < BaseClass

    table_name "users"
    columns id: "integer", name: "text", username: "text", mail: "text", password: "text"
    #create_table creates a table in the specefied database and if the last argument i returned false
    create_table(SQLite3::Database.open('db/Västtrafik.sqlite'), false)

    attr_reader :name, :username, :mail, :redirectURL

    def initialize(name, username, mail, session)
        @register_error_URL = '/register'
        @login_error_URL = '/login'
        @name = name
        @username = username
        @mail = mail
        if @username == @register_error_URL
            @redirectURL = @register_error_URL.to_s
        elsif @username == @login_error_URL
            @redirectURL = @login_error_URL.to_s
        else
            @redirectURL = "/user/#{@username}"
            session[:username] = @username
        end
    end

    def self.create(name, username, mail, password, session)
        db = SQLite3::Database.open('db/Västtrafik.sqlite')

        if !valid_password(password, session, [false]) || !valid_username(username, db, session, false) || !valid_mail(mail, db, session, false)
            return new('error', '/register', 'error', session)
        end

        hashed_password = BCrypt::Password.create(password)
        db.execute('INSERT INTO users (name,username,mail,password) VALUES (?,?,?,?)', [name, username, mail, hashed_password])
        new(name, username, mail, session)
    end

    def self.valid_password(password, session, login)

        if login[0]
            db = SQLite3::Database.open('db/Västtrafik.sqlite')
            dbpassword = db.execute('SELECT password FROM users WHERE username IS ?', [login[1]])
            decrypted_password = BCrypt::Password.new(dbpassword[0][0])
            if decrypted_password == password
                session[:invalidPassword] = false
                session[:logged_in] = true
                return true
            else
                session[:invalidPassword] = true
                session[:logged_in] = false
                return false
            end
        end

        if password.empty? || password.include?(' ')
            session[:invalidPassword] = true
            session[:logged_in] = false
            return false
        end
        session[:invalidPassword] = false
        session[:logged_in] = true
        true
    end

    def self.valid_username(username, db, session, login)
        usernames = db.execute('SELECT username FROM users')

        if login
            usernames.each do |name|
                if name.first == username
                    session[:invalidUsername] = false
                    session[:logged_in] = true
                    return true
                end
            end
            session[:invalidUsername] = true
            session[:logged_in] = false
            return false
        end

        usernames.each do |name|
            if name.first == username
                session[:invalidUsername] = true
                session[:logged_in] = false
                return false
            end
        end

        if username.include?(' ')
            session[:invalidUsername] = true
            session[:logged_in] = false
            return false
        end

        session[:invalidUsername] = false
        session[:logged_in] = true
        true
    end

    def self.valid_mail(mail, db, session, login)
        mails = db.execute('SELECT mail FROM users')

        if login
            mails.each do |mail_|
                if mail_.first == mail
                    session[:invalidMail] = false
                    session[:logged_in] = true
                    return true
                end
            end
            session[:invalidMail] = true
            session[:logged_in] = false
            return false
        end

        mails.each do |mail_|
            if mail_.first == mail
                session[:invalidMail] = true
                session[:logged_in] = false
                return false
            end
        end

        if mail.include?(' ')
            session[:invalidMail] = true
            session[:logged_in] = false
            return false
        end

        session[:invalidMail] = false
        session[:logged_in] = true
        true
    end

    def self.login(name_option, password, session)
        db = SQLite3::Database.open('db/Västtrafik.sqlite')

        if valid_username(name_option, db, session, true) || valid_mail(name_option, db, session, true)
            username = db.execute('SELECT username FROM users WHERE mail IS ?', [name_option])[0][0] if valid_mail(name_option, db, session, true)
            mail = db.execute('SELECT mail FROM users WHERE username IS ?', [name_option])[0][0] if valid_username(name_option, db, session, true)
            username = name_option if username.nil?
            mail = name_option if username.nil?
            if valid_password(password, session, [true, username])
                name = db.execute('SELECT name FROM users WHERE mail IS ?', [mail])
                return new(name, username, mail, session)
            end
        end
        new('error', '/login', 'error', session)
    end
end
