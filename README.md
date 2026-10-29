# Café Orders

A Ruby on Rails application for managing café orders.

Customers browse a product catalog, fill a cart and check out; admins manage the catalog. The app serves both a server-rendered web frontend (Tailwind + Hotwire) and a JSON API under `/api/v1`.

## Features

- **Product catalog** – browse, filter (`available` / `active` / `all`) and search products, with Turbo Frames for in-place updates
- **Shopping cart** – session-based cart (add, update quantity, remove) that survives logout
- **Checkout & order history** – place orders from the cart and view your past orders
- **Authentication** – Devise (web sessions + JSON auth endpoints)
- **Admin product management** – admins can create, edit and deactivate products (web and API)
- **Order confirmation emails** – sent asynchronously via a background job

## Domain Model

Core entities:

- **User** – a customer or admin (`role` enum: `customer`, `admin`)
- **Product** – items available for purchase
- **Order** – a purchase made by a user (`status` enum: `pending`, `paid`, `cancelled`, `refunded`)
- **OrderItem** – a product within an order

Relationships:

```
User      → has many Orders
Order     → belongs to User, has many OrderItems
OrderItem → belongs to Order, belongs to Product
Product   → referenced by OrderItems
```

## Key Design Decisions

- Prices are stored as integers (COP) to avoid floating point errors.
- OrderItem stores `unit_price` to preserve historical pricing.
- Orders store `total_amount` as a financial snapshot.
- Database constraints enforce critical invariants:
  - quantity ≥ 1
  - price > 0
  - stock ≥ 0
- Orders are treated as financial records and cannot be destroyed once items exist.
- Products are soft-deleted (`active: false`) rather than removed.
- Business logic lives in service objects (`Orders::CreateOrder`), shared by web and API controllers.
- The cart lives in the session, not the database.

## Tech Stack

- Ruby on Rails 8
- PostgreSQL
- Devise (authentication)
- Tailwind CSS, Turbo, Stimulus
- jsonapi-serializer (API responses)
- Solid Queue (background jobs)
- RSpec, FactoryBot, Shoulda Matchers, Faker
- GitHub Actions (CI: RuboCop, Brakeman, RSpec)

## API

All endpoints are under `/api/v1` and return JSON. Authentication is session-based (cookie set by `login` / `signup`).

| Method | Path | Access |
| ------ | ---- | ------ |
| `POST` | `/auth/signup` | public |
| `POST` | `/auth/login` | public |
| `DELETE` | `/auth/logout` | signed in |
| `GET` | `/auth/me` | signed in |
| `GET` | `/products`, `/products/:id` | public |
| `POST` / `PATCH` / `DELETE` | `/products`, `/products/:id` | admin |
| `GET` | `/orders`, `/orders/:id` | signed in (own orders) |
| `POST` | `/orders` | signed in |

Unauthenticated requests to protected endpoints return `401`; non-admins hitting admin endpoints get `403`.

## Setup

Clone the repository:

```bash
git clone https://github.com/cbotero9409/cafe_orders.git
cd cafe_orders
```

Install dependencies:

```bash
bundle install
```

Set up the database:

```bash
bin/rails db:create db:migrate
```

Run the app (Rails server + Tailwind watcher):

```bash
bin/dev
```

Then open http://localhost:3000. In development, emails open in the browser via `letter_opener`.

To make a user an admin, from `bin/rails console`:

```ruby
User.find_by(email: "you@example.com").role_admin!
```

Run the test suite:

```bash
bundle exec rspec
```

### Testing and debugging in VS Code

With the Ruby LSP extension, the Testing sidebar lists the RSpec specs (via the `ruby-lsp-rspec` gem). Run or debug any spec, file or folder from there. Reload the window after the first `bundle install`.

`.vscode/launch.json` has three configurations for the Ruby LSP extension (uses the `debug` gem):

- **Debug current spec file**: runs `bundle exec rspec` on the open file. Set breakpoints in app code or inside `it` blocks.
- **Debug Rails server**: runs `bin/rails server`; send requests from the browser or `requests.http` (REST Client extension).
- **Attach to running process**: attaches to a process started with the debugger enabled.

### Code quality and review

CI (GitHub Actions) runs RuboCop, Brakeman and the RSpec suite. Brakeman can also be run locally with `bin/brakeman`. A read-only `rails-reviewer` subagent for Claude Code reviews changes for risks, test quality and docs sync.

## Future Improvements

- Order lifecycle actions (pay, cancel, refund) exposed through controllers
- User management API and admin user management
- Authorization policies (e.g. Pundit) instead of ad-hoc role checks
- Token-based API authentication
- Seed data for development
