class AccountMailer < ApplicationMailer
  def authentication_code(account)
    @account = account
    mail(
      to: account.email,
      subject: 'ANYUR 認証コードのお知らせ'
    )
  end
  def password_reset(account)
    @account = account
    mail(
      to: account.email,
      subject: 'ANYUR パスワードを再設定'
    )
  end
end
