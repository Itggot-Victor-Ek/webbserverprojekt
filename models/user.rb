class User < BaseClass

    table_name "users"
    column id: "integer"
    column name: "text"
    column username: "text"
    column mail: "text"
    column password: "text"
    create_table('db/Västtrafik.sqlite', false)
    update({ username: ["Joey Dangers", requirements:[:unique, :no_space]]}, "test")
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
        if insert({
                    name: name,
                    username: [username, requirements: [:unique, :no_space]],
                    mail: [mail, requirements: [:unique, :no_space]],
                    password: [password, requirements: [Password]]
                    })

            session[:invalidMail] = false
            session[:invalidPassword] = false
            session[:invalidUsername] = false
            session[:logged_in] = true
            new(name, username, mail, session)
        else
            session[:logged_in] = false
            new('error', '/register', 'error', session)
        end
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

    def self.change_username(new_username)
        result = update({username: [new_username, requirement:[:unique, :no_space]]}, @username)
        unless result
            @username = result
        end
    end

    private

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
    end
end
