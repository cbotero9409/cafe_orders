# Project Status

## Last Updated

2026-08-31

## Repository State

- **Current branch:** `main` (up to date with `origin/main`)
- **Latest commit:** `a9532f6f78136f88dea1235f13ae2085a386d5ae`
- **Latest commit message:** "Merge pull request #23 from cbotero9409/order_creation_frontend"
- **Latest commit date:** 2026-06-11
- **Uncommitted changes:** Yes — `to_do.txt` is modified (unstaged). It was previously an empty file and now contains a short task list: "products index, show", "products new, edit, destroy only admin", "devise views". This appears to be in-progress note-taking, not yet committed.
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
- Current run: **94 examples, 5 failures, 4 pending** (verified by running `bundle exec rspec`).
  - Pending: 4 auto-generated helper/mailer spec stubs (`Api::V1::AuthHelper`, `Api::V1::ProductsHelper`, `OrdersHelper`, `OrderMailer`) — never filled in.
  - Failing: 5 examples in `spec/requests/api/v1/auth_spec.rb` and `spec/requests/api/v1/products_spec.rb`, all expecting `401 Unauthorized` for unauthenticated API requests but receiving `302 Found` (a redirect) instead — see [Discrepancies](#discrepancies).
- Coverage exists for: models (`Order`, `OrderItem`, `Product`, `User`), the `Orders::CreateOrder` service, `Orders::SendConfirmationJob`, and API request specs for auth/products/orders.
- No request/system specs exist for the web controllers (`ProductsController`, `CartsController`, `OrdersController` web views) or for Devise web flows.

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
- Enforced only in the API: `Api::BaseController#require_admin!` returns 403 for non-admins, applied to product `create`/`update`/`destroy`.
- No authorization is enforced on the web side (no admin-only web controllers/views exist — `to_do.txt` lists this as still to do).

### API
- Namespaced under `/api/v1`: `products` (full CRUD), `orders` (`index`, `create`, `show`), and `auth` (`signup`, `login`, `logout`, `me`).
- JSON responses are built with `jsonapi-serializer` (`ProductSerializer`, `OrderSerializer`, `OrderItemSerializer`).
- `Api::BaseController` requires authentication by default; `products#index/show` and `auth#signup/login` opt out.
- Known issue: unauthenticated requests to protected API endpoints redirect (302) instead of returning `401 Unauthorized` JSON — see [Discrepancies](#discrepancies).

### Web Frontend
- Server-rendered ERB views styled with Tailwind CSS, using Turbo Frames (`products_grid`) for filtering/search without full page reloads.
- Stimulus controllers: `products_controller.js` (filter tabs + debounced search, submits the form via `requestSubmit`), `cart_controller.js` (client-side quantity increment/decrement, not yet wired into a view), plus the default `hello_controller.js` scaffold.
- Product listing (`/products`) supports filter (`available`/`active`/`all`) and search (`ILIKE` on name) — index only, no show/new/edit/destroy views for products on the web side.

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
- Development delivery uses `letter_opener`; the `OrderMailer` itself has no meaningful spec coverage (stub only).

## Feature Status

- [x] Product catalog (browse, filter, search) — web + API
- [x] Session-based shopping cart (add/update/remove)
- [x] Order creation/checkout (web + API), via `Orders::CreateOrder` service
- [x] Order history and detail view (web + API), scoped to current user
- [x] User authentication (Devise, web sessions + API session-based auth)
- [~] Admin authorization — enforced in API (`require_admin!` on product CRUD) but not on the web
- [~] Product API — full CRUD implemented, but unauthenticated-access handling returns the wrong status code (302 instead of 401) in 5 failing specs
- [ ] Product management UI on the web (new/edit/destroy) — explicitly listed as not-yet-done in `to_do.txt`
- [ ] Order lifecycle actions (pay/cancel/refund) exposed via any controller — model methods exist but are unreachable
- [ ] Background job / mailer test coverage — job has minimal coverage, mailer spec is an empty pending stub

## Current Development Focus

Based on the repository state (uncommitted `to_do.txt`, most recent commits building out web order creation and Devise auth), the project has just finished the core "browse → cart → checkout → order history" flow for logged-in customers. The uncommitted `to_do.txt` indicates the next intended focus is **admin-only web product management** (new/edit/destroy views), consistent with the README's "Future Improvements" list (admin interface, authorization policies) and the fact that admin authorization currently only exists on the API side.

## Recommended Next Steps

1. **Fix the failing API auth specs (already implemented, currently broken):** unauthenticated requests to `Api::BaseController`-protected endpoints return 302 instead of 401 — configure a JSON-aware Warden failure app for the API scope.
2. **Partially implemented → finish:** extend role-based authorization to the web (admin-only routes/controllers), matching what already exists in the API.
3. **Not yet implemented, per `to_do.txt`:** build web views/controllers for product `show`, `new`, `edit`, and `destroy`, restricted to admins.
4. **Not yet implemented:** expose the existing `Order#pay!` / `cancel!` / `refund!` model methods through controller actions (web and/or API) — the domain logic exists but isn't reachable.
5. **Test debt:** fill in the pending stub specs (`OrderMailer`, the three helper specs) or delete them if the corresponding helpers/mailers don't warrant dedicated tests; add request/system specs for the web `ProductsController`, `CartsController`, and `OrdersController`.

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

- **Implemented/practiced:** ActiveRecord associations and enums, DB-level constraints, service objects, ActiveJob background jobs, ActionMailer, Devise authentication (both web and hand-integrated with an API-only controller), JSON serialization with `jsonapi-serializer`, Hotwire (Turbo Frames + Stimulus) for a dynamic filtering UI, session-based state (cart) as an alternative to a persisted model, RSpec/FactoryBot/Shoulda Matchers testing conventions.
- **Partially explored:** role-based authorization (implemented for the API only, not the web); request/failure-mode handling for APIs (the 302-vs-401 issue reflects an incomplete understanding of Warden's failure app per controller type).
- **Not yet explored (per `to_do.txt` and current gaps):** admin-restricted web CRUD flows, exposing state-machine-like transitions (`pay!`/`cancel!`/`refund!`) through controllers, system/feature testing (Capybara is installed but no system specs exist), authorization policy objects (e.g., Pundit/CanCanCan — currently authorization is done ad hoc via `role_admin?` checks).

## Discrepancies

- **README.md "Future Improvements"** lists "Authentication with Devise", "Order services (checkout, refunds)", and "Admin interface for product management" as future work. Devise authentication and the checkout order service (`Orders::CreateOrder`) are already implemented — the README is out of date. "Admin interface for product management" and "Authorization policies" remain accurate as still-outstanding (web-side admin UI and authorization are not implemented).
- **`to_do.txt`** lists "devise views" as a to-do item, but Devise views are already present and customized in `app/views/devise/`. This item appears to already be complete despite being listed as pending, and the file itself is currently uncommitted.
- **Test suite is not fully green:** 5 specs currently fail (`spec/requests/api/v1/auth_spec.rb`, `spec/requests/api/v1/products_spec.rb`) due to unauthenticated API requests returning 302 instead of 401. This is not documented anywhere but is directly observable by running `bundle exec rspec`.
- **`Order#pay!`/`cancel!`/`refund!`** exist and are unit-tested at the model level, which could give the impression that order status transitions are a usable feature end-to-end. In fact no controller (web or API) exposes these actions, so they are not reachable by users.
