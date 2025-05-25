class EmailForm
  include ActiveModel::Model

  attr_accessor :email

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  validates :email, presence: true,
                    length: { in: 5..120 },
                    format: { with: VALID_EMAIL_REGEX, message: :invalid_email_format }
end
