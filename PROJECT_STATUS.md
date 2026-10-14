# Project Status

## Last Updated

2026-10-14

## Repository State

- **Current branch:** `main` (up to date with `origin/main`)
- **Latest commit:** `16c22aff16c0a40e85dd2be60a749216efd69a19`
- **Latest commit message:** "Merge pull request #24 from cbotero9409/products_actions"
- **Latest commit date:** 2026-09-15
- **Uncommitted changes:** README, `to_do.txt` and this file were refreshed on 2026-10-14.
- Several stale feature branches exist locally/remotely (`cart_order_creation`, `devise_frontend`, `products_frontend`, `order_creation_frontend`, `products_api`, etc.) that appear to already be merged into `main`, plus open Dependabot branches.

## Current Implementation

### Domain / Models
- `User` (Devise-backed), `Product`, `Order`, `OrderItem` are implemented with associations: `User has_many :orders`, `Order belongs_to :user, has_many :order_items`, `OrderItem belongs_to :order/:product`.
- `Order` has a `status` enum (`pending`, `paid`, `cancelled`, `refunded`) with prefixed methods, and lifecycle methods `pay!`, `cancel!`, `refund!`, `add_product`.
- `User` has a `role` enum (`customer`, `admin`).
- `Order#calculate_total!` runs as a `before_validation` callback, deriving `total_amount` from `order_items`.

### Database
- Postgres schema with 4 tables: `users`, `products`, `orders`, `order_items` (5 migrations, latest adds Devise columns to `users`).
- Prices/amounts stored as integers (no floats), consistent with the README's stated decision.
- DB-level check constraints enforce: `quantity >= 1`, `unit_price > 0`, `total_amount >= 0`, `price > 0`, `stock >= 0`, minimum name/email lengths.
- Unique indexes: case-insensitive product name, case-insensitive user email, `(order_id, product_id)` on order_items.
- Foreign keys enforced at the DB level for `order_items` → `orders`/`products` and `orders` → `users`.

### Testing
- RSpec is the active test framework (FactoryBot, Shoulda Matchers, Faker configured). The default Rails `test/` (Minitest) directory still exists but appears to be leftover scaffolding, not the maintained suite (only one placeholder model test).
- Current run: **90 examples, 0 failures** (verified by running `bundle exec rspec` on 2026-10-14).
  - The pending helper/mailer stub specs were removed; the 302-vs-401 API failures were fixed by `Api::BaseController#force_json_format`.
- **CI does not run RSpec:** `.github/workflows/ci.yml` runs `bin/rails db:test:prepare test test:system` (Minitest), so the real suite is not exercised in CI.
- Coverage exists for: models (`Order`, `OrderItem`, `Product`, `User`), the `Orders::CreateOrder` service, `Orders::SendConfirmationJob`, and API request specs for auth/products/orders.
- Web controllers/views are intentionally not covered — test scope is limited to the critical path (models, services, API).

### Services / Business Logic
- `ApplicationService::Base` / `ApplicationService::Result` provide a small service-object pattern (`.call` class method, `success?`/`failure?`/`data`/`errors`).
- `Orders::CreateOrder` is the only service implemented: builds an order + order_items inside a transaction, copies `product.price` into `unit_price` at creation time, enqueues a confirmation job, and returns a `Result`. Used by both the web `OrdersController#create` and `Api::V1::OrdersController#create`.

### Authentication
- Devise is installed and wired for the `User` model (`database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`).
- Web: standard Devise session-based auth (`devise_for :users`, custom `Users::SessionsController` that preserves the cart in session across logout).
- API: a separate, hand-rolled Devise-based flow under `/api/v1/auth` (`signup`, `login`, `logout`, `me`) using `sign_in`/`sign_out` with Devise's warden helpers on an `ActionController::API` base — this reuses the same session-based mechanism rather than tokens/JWT.
- Devise views are present and customized (registrations, sessions, passwords, confirmations, unlocks).

### Authorization
- Role-based, enum-driven (`User#role`: `customer`/`admin`).
- API: `Api::BaseController#require_admin!` returns 403 for non-admins, applied to product `create`/`update`/`destroy`.
- Web: `ApplicationController#require_admin!` redirects non-admins to root with an alert, applied to `ProductsController` `new`/`create`/`edit`/`update`/`destroy`.
- Checks are ad hoc (`role_admin?`), no policy objects.

### API
- Namespaced under `/api/v1`: `products` (full CRUD), `orders` (`index`, `create`, `show`), and `auth` (`signup`, `login`, `logout`, `me`).
- JSON responses are built with `jsonapi-serializer` (`ProductSerializer`, `OrderSerializer`, `OrderItemSerializer`).
- `Api::BaseController` requires authentication by default; `products#index/show` and `auth#signup/login` opt out.
- `Api::BaseController` forces the request format to JSON (`force_json_format`) so Devise returns `401` rather than redirecting when a client omits the `Accept` header.

### Web Frontend
- Server-rendered ERB views styled with Tailwind CSS, using Turbo Frames (`products_grid`) for filtering/search without full page reloads.
- Stimulus controllers: `products_controller.js` (filter tabs + debounced search, submits the form via `requestSubmit`), `cart_controller.js` (client-side quantity increment/decrement, not yet wired into a view), plus the default `hello_controller.js` scaffold.
- Product listing (`/products`) supports filter (`available`/`active`/`all`) and search (`ILIKE` on name); product cards link to a show page.
- Admin-only product `new`/`edit`/`destroy` (soft delete) on the web, sharing a `_form` partial.

### Shopping Cart
- Implemented as a **session-based** cart (no `Cart`/`CartItem` model): `session[:cart]` is a hash of `product_id => quantity`, managed entirely by `CartsController` (`show`, `add`, `remove`, `update`).
- Cart survives logout via `Users::SessionsController#destroy` re-assigning `session[:cart]` after Devise's sign-out.

### Orders / Checkout
- Web checkout: `OrdersController#create` (requires login) reads the session cart, calls `Orders::CreateOrder`, clears the cart session on success, and redirects to the created order or back to the cart with an error.
- `orders#index` and `orders#show` (web) scope orders to `current_user` and render `app/views/orders/index.html.erb` / `show.html.erb`.
- No update/cancel/refund actions are exposed through any controller (web or API) even though the `Order` model has `pay!`/`cancel!`/`refund!` methods — these are currently unreachable from outside a Rails console or test.

### Background Jobs
- `Orders::SendConfirmationJob` (ActiveJob) is enqueued by `Orders::CreateOrder` and calls `OrderMailer.confirmation(order_id).deliver_now`.
- `solid_queue` is the configured Active Job adapter in production (`config.active_job.queue_adapter = :solid_queue`); development/test rely on Rails' default (inline/async) adapter since no explicit adapter is set there.

### Mailers
- `OrderMailer#confirmation` sends an order confirmation email; HTML view exists (`app/views/order_mailer/confirmation.html.erb`), text view does not appear to exist.
- Development delivery uses `letter_opener`; `OrderMailer` has no dedicated spec (covered indirectly via the job spec).

## Feature Status

- [x] Product catalog (browse, filter, search) — web + API
- [x] Session-based shopping cart (add/update/remove)
- [x] Order creation/checkout (web + API), via `Orders::CreateOrder` service
- [x] Order history and detail view (web + API), scoped to current user
- [x] User authentication (Devise, web sessions + API session-based auth)
- [x] Admin authorization — `require_admin!` on product CRUD in both web and API
- [x] Product API — full CRUD, correct 401/403 handling
- [x] Product management UI on the web (show/new/edit/destroy, admin-only)
- [ ] Order lifecycle actions (pay/cancel/refund) exposed via any controller — model methods exist but are unreachable
- [ ] User profile page and admin user management (web)
- [ ] CI running the RSpec suite

## Current Development Focus

The customer flow (browse → cart → checkout → order history) and admin product management are complete on both web and API. `to_do.txt` points next at **user-facing account pages** (own profile, admin user management) and **exposing order lifecycle transitions** (`pay!`/`cancel!`/`refund!`).

## Recommended Next Steps

1. **Make CI run RSpec:** replace `bin/rails test test:system` in `ci.yml` with `bundle exec rspec` and delete the leftover Minitest `test/` directory.
2. **Order lifecycle:** expose `pay!`/`cancel!`/`refund!` through controller actions (API and/or web), with admin-only refunds.
3. **User accounts:** a web page for users to view/edit their own info, and admin user management.
4. **Small cleanups:** remove the commented-out `require_admin!` in `Api::V1::OrdersController`; wire `cart_controller.js` into the cart view or delete it; add a text version of the confirmation email.
5. **Dev experience:** seed an admin user and sample products in `db/seeds.rb`.
6. **Later:** authorization policies (Pundit) and token-based API auth.

## Architectural Notes

- **Service objects:** business logic for order creation is isolated in `Orders::CreateOrder` (via a small `ApplicationService::Base`/`Result` convention), shared by both web and API controllers — the only service in the codebase so far.
- **Web/API separation:** the app serves both a server-rendered Tailwind/Turbo frontend and a JSON API under `/api/v1`, with `Api::BaseController` (`ActionController::API`) separate from `ApplicationController` (`ActionController::Base`). Both reuse the same Devise-backed `User` model and session mechanism rather than token-based auth for the API.
- **Pricing representation:** all money values (`price`, `unit_price`, `total_amount`) are stored as integers, avoiding floating-point currency, reinforced by DB check constraints.
- **Order price snapshots:** `OrderItem#unit_price` is copied from `Product#price` at order-creation time, and `Order#total_amount` is computed via a `before_validation` callback — this is a deliberate financial snapshot pattern (product prices can change later without altering historical orders).
- **Order immutability:** `Order has_many :order_items, dependent: :restrict_with_error` — orders with items cannot be destroyed, consistent with the README's stated intent to treat orders as financial records.
- **Soft deletion:** `Product` uses an `active` boolean flag rather than hard deletion; `Api::V1::ProductsController#destroy` deactivates (`update!(active: false)`) rather than deleting rows.
- **Session-based cart:** the cart is not a persisted model — it lives entirely in the Rails session as a plain hash, which is simple but means it is not shared across devices and is lost if the session/cookie is cleared.
- **Background processing:** `solid_queue` is configured as the production Active Job adapter; order confirmation emails are dispatched asynchronously via `Orders::SendConfirmationJob`, though the job itself calls `deliver_now` (synchronous mail delivery within the async job).

## Learning Progress

- **Implemented/practiced:** ActiveRecord associations and enums, DB-level constraints, service objects, ActiveJob background jobs, ActionMailer, Devise authentication (web and hand-integrated with an API-only controller, including Warden failure-app behavior per request format), role-based authorization on web and API, JSON serialization with `jsonapi-serializer`, Hotwire (Turbo Frames + Stimulus), session-based state (cart), RSpec/FactoryBot/Shoulda Matchers.
- **Not yet explored:** exposing state-machine-like transitions (`pay!`/`cancel!`/`refund!`) through controllers, authorization policy objects (Pundit/CanCanCan), token-based API auth.

## Discrepancies

- **CI vs. test suite:** CI runs Minitest (`test/` only has a placeholder), so a green CI build says nothing about the RSpec suite.
- **`Order#pay!`/`cancel!`/`refund!`** exist and are unit-tested at the model level, but no controller (web or API) exposes them, so they are not reachable by users.
- **`cart_controller.js`** exists but is not attached to any view.
