class Product < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :available, -> { where(active: true).where("stock > 0") }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 2 }
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  def available?
    active && stock > 0
  end
end
