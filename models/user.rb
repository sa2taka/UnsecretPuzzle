require 'digest'
require 'bcrypt'

require_relative '../models.rb'

class User < ActiveRecord::Base
  validates :id, presence: true, uniqueness: true
  validates :password, presence: true

  has_many :styles

  def self.create(name, new_password)
    user = User.new
    user.id = name
    user.password = encrypt(new_password)
    user.sessionid = generate_sessionid(name + new_password)
    user.save
    user
  end

  def authenticate(confirmed)
    BCrypt::Password.new(self.password) == confirmed
  end

  private

  def self.encrypt(new_password)
    if new_password.present?
      return BCrypt::Password.create(new_password)
    else
      raise ArgumentError
    end
  end

  def self.generate_sessionid(string)
    bin = Digest::SHA512.digest(string).split('').map { |c| c.ord > 127 ? '1' : '0'}.join
    bin.scan(/.{1,8}/).map { |b| b.to_i(2).to_s(16) }.join('_')
  end
end
