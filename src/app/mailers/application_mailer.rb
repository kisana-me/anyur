class ApplicationMailer < ActionMailer::Base
  default from: "ANYUR <kisana@anyur.com>"
  default charset: "UTF-8"
  default headers: { "Content-Language" => "ja" }
  layout "mailer"
end
