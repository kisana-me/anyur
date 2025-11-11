module SessionManagement
  # 複数サインイン版 ver 1.0.1
  # models/token_toolsが必須
  # Sessionに必要なカラム差分(名前 型)
  # - account references
  # Accountに必要なカラム(名前 型)
  # - deleted boolean

  COOKIE_NAME = "anyur"
  COOKIE_EXPIRES = 1.month # 2592000

  def current_account
    @current_account = nil
    return unless token = get_tokens().first
    db_session = Session.find_by_token("token", token)
    if db_session&.account && !db_session.account.deleted?
      @current_account = db_session.account
    else
      refresh_token()
      current_account()
    end
  end

  def sign_in(account)
    return false if account&.deleted?
    db_session = Session.new(account: account)
    token = db_session.generate_token("token", COOKIE_EXPIRES)
    tokens = get_tokens()
    tokens.unshift(token)
    tokens.uniq!()
    write_tokens(tokens)
    db_session.save()
  end

  def sign_out
    tokens = get_tokens()
    return unless token = tokens.first
    db_session = Session.find_by_token("token", token)
    return unless db_session
    tokens.delete(tokens.first)
    if tokens.empty?
      cookies.delete(COOKIE_NAME.to_sym)
    else
      write_tokens(tokens)
    end
    @current_account = nil
    db_session.update(status: :deleted)
  end

  def signed_in_accounts
    tokens = get_tokens()
    tokens.filter_map do |token|
      account = Session.find_by_token("token", token)&.account
      account unless account.deleted?
    end.uniq
  end

  def change_account(account_aid)
    tokens = get_tokens()
    scope_token = ""
    tokens.each do |token|
      account = Session.find_by_token("token", token)&.account
      if account && !account.deleted? && account_aid == account.aid
        scope_token = token
        break
      end
    end
    if scope_token.present?
      new_tokens = tokens.partition { |t| t == scope_token }.flatten
      write_tokens(new_tokens)
      true
    else
      false
    end
  end

  private

  def get_tokens
    Array.wrap(JSON.parse(cookies.encrypted[COOKIE_NAME.to_sym] || "[]"))
  end

  def refresh_token
    tokens = get_tokens()
    valid_tokens = tokens.select do |token|
      db_session = Session.find_by_token("token", token)
      db_session&.account && !db_session.account.deleted?
    end
    if valid_tokens.empty?
      cookies.delete(COOKIE_NAME.to_sym)
    else
      write_tokens(valid_tokens)
    end
  end

  def write_tokens(tokens)
    cookies.encrypted[COOKIE_NAME.to_sym] = {
      value: tokens.to_json,
      domain: :all,
      tld_length: 2,
      same_site: :lax,
      expires: Time.current + COOKIE_EXPIRES,
      secure: Rails.env.production?,
      httponly: true
    }
  end
end
