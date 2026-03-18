# Café Orders

A Ruby on Rails backend application for managing café orders.

The system models a simple commerce domain where users can place orders containing multiple products.

## Domain Model

Core entities:

- **User** – represents a customer or admin
- **Product** – items available for purchase
- **Order** – a purchase made by a user
- **OrderItem** – a product within an order

Relationships:

User
→ has many Orders

Order
→ belongs to User
→ has many OrderItems

OrderItem
→ belongs to Order
→ belongs to Product

Product
→ referenced by OrderItems

## Key Design Decisions

- Prices are stored as integers (COP) to avoid floating point errors.
- OrderItem stores `unit_price` to preserve historical pricing.
- Orders store `total_amount` as a financial snapshot.
- Database constraints enforce critical invariants:
  - quantity ≥ 1
  - price > 0
  - stock ≥ 0
- Orders are treated as financial records and cannot be destroyed once items exist.

## Tech Stack

- Ruby on Rails
- PostgreSQL
- RSpec
- FactoryBot
- Shoulda Matchers

## Setup

- Clone the repository:

    git clone https://github.com/cbotero9409/cafe_orders.git
    cd cafe_orders

- Install dependencies:

    bundle install


- Setup the database:

    rails db:create
    rails db:migrate


- Run the test suite:

    bundle exec rspec


## Future Improvements

- Authentication with Devise
- Order services (checkout, refunds)
- Admin interface for product management
- Authorization policies