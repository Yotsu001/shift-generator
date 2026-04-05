class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
    has_many :user_zones, dependent: :destroy
    has_many :zones, through: :user_zones
    has_one :employee, dependent: :nullify

  validates :name, presence: true
end
