class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :shift_periods, dependent: :destroy
  has_many :shift_days, through: :shift_periods
  has_many :shift_assignments, through: :shift_days
  has_many :leave_requests, through: :shift_days
  has_many :employees, dependent: :destroy

  validates :name, presence: true
end