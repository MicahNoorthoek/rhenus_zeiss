class User < ApplicationRecord
  extend Enumerize

  before_validation :downcase_email

  validates :username, presence: true,
            uniqueness: { case_sensitive: true },
            length: { minimum: 3, maximum: 25 }
            
  validates :email, presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 105 },
            format: { with: /\A[^@\s]+@([^@.\s]+\.)+[^@.\s]+\z/ }

  validates :company, presence: true

  has_secure_password

  #enum role: { agent: "agent", customer: "customer" }, _suffix: true
  enumerize :role, in: { agent: 'agent', customer: 'customer' }, predicates: true, scope: true

  scope :get_user_by_username_and_company, -> (username, company) { where(username: username, company: company) }
  scope :get_user_by_last_sign_in_before, -> (days) { where("last_sign_in_at < ?", days.days.ago) }

  def auto_timeout
    15.minutes
  end
  
  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

   def self.ransackable_attributes(auth_object = nil)
    ["admin", "auto_email", "client_admin", "company", "created_at", "email", "id", "id_value", "last_sign_in_at", "logged_in", "login_attempts", "password", "password_digest", "precisionaudit_support", "recent_warehouse", "role", "undo_shipments_lock", "updated_at", "user_actions", "user_lock", "username"]
   end
end
