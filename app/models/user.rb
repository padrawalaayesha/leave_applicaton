class User < ApplicationRecord
  # include Doorkeeper::UserMixin
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :employees
  
  def self.authenticate(email, password)
    user = User.find_by(email: email)
    user&.valid_password?(password) ? user : nil
  end
end
