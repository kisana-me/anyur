class AccountMailer < ApplicationMailer
  def authentication_code(account, code)
    @account = account
    @code = code
    mail(
      to: account.email,
      subject: "ANYUR 認証コードのお知らせ"
    )
  end
  def authentication_page(account)
    @account = account
    mail(
      to: account.email,
      subject: "ANYUR 認証ページのお知らせ"
    )
  end
  def password_reset(account)
    @account = account
    mail(
      to: account.email,
      subject: "ANYUR パスワードを再設定"
    )
  end
end
