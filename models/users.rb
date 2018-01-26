class User
  attr_reader :name, :username, :mail, :redirectURL
  def initialize(name, username, mail)
    @register_error = "/register"
    @name = name
    @username = username
    @mail = mail
    if @username == @register_error
      @redirectURL = "#{@register_error}"
    else
      @redirectURL = "/user/#{@username}"
    end
  end

  def self.create(name, username, mail, password, session)
    db = SQLite3::Database.open('db/Västtrafik.sqlite')

    if !self.valid_password(password, session) || !self.valid_username(username, db, session)|| !self.valid_mail(mail, db, session)
      return self.new("error", "/register", "error")
    end

    hashed_password = BCrypt::Password.create(password)
    db.execute('INSERT INTO users (name,username,mail,password) VALUES (?,?,?,?)', [name,username,mail,hashed_password])
    return self.new(name,username,mail)

  end

  def self.valid_password(password,session)

    if password.empty?
      session[:invalidPassword] = true
      return false
    end

    if password.include?(' ')
      session[:invalidPassword] = true
      return false
    end

    session[:invalidPassword] = false
    return true

  end

  def self.valid_username(username, db, session)
    usernames = db.execute('SELECT username FROM users')

    usernames.each do |name|
      if name.first == username
        session[:invalidUsername] = true
        return false
      end
    end

    if username.include?(' ')
      session[:invalidUsername] = true
      return false
    end

    session[:invalidUsername] = false
    return true

  end

  def self.valid_mail(mail, db, session)
    mails = db.execute('SELECT mail FROM users')

    mails.each do |mail_|
      if mail_.first == mail
        session[:invalidMail] = true
        return false
      end
    end

    if mail.include?(' ')
      session[:invalidMail] = true
      return false
    end

    session[:invalidMail] = false
    return true

  end

end
