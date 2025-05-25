class AccountMailer < ApplicationMailer
  def authentication_code(email, code)
    @code = code
    mail(
      to: email,
      subject: "ANYUR 認証コードのお知らせ"
    )
  end
  def password_reset(email, token)
    @email = email
    @token = token
    mail(
      to: email,
      subject: "ANYUR パスワードを再設定"
    )
  end
end
