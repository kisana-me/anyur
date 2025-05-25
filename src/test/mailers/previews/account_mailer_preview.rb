# Preview all emails at http://localhost:3000/rails/mailers/account_mailer
class AccountMailerPreview < ActionMailer::Preview
  def authentication_code
    account = Account.new(name: "test", email: "test@example.com")
    AccountMailer.authentication_code(account.email, "%06d" % 000000)
  end
  def password_reset
    account = Account.new(name: "test", email: "test@example.com")
    AccountMailer.password_reset(account.email, 12345678901234567890123456789012)
  end
end
