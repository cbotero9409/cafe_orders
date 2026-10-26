# To do

## API first

### User management API
- [ ] Own account: `PATCH /api/v1/auth/me` (name, email, password with current password), maybe `DELETE`. Reuse `Users::UpdateProfile` (already used by the web edit page).
- [ ] Admin: `GET /api/v1/users`, `GET /api/v1/users/:id`, `PATCH /api/v1/users/:id` (role, details), deactivate user.
- [ ] Rules in services (e.g. `Users::UpdateRole`: can't demote yourself, can't remove the last admin).
- [ ] `UserSerializer` (jsonapi-serializer) instead of rendering the raw model in `auth#me`.
- [ ] Decide: `active` flag on users (migration) for soft delete, like `Product`.

### Orders API
- [ ] Expose order `pay!` / `cancel!` / `refund!` through the API (refund admin-only).
- [ ] Remove the commented-out `require_admin!` in `Api::V1::OrdersController`.

### Auth
- [ ] Token-based API auth (API currently relies on session cookies).

## Maintenance
- [ ] Upgrade Rails 8.0.4 -> 8.1.x (support ends 2026-11-07; Brakeman EOLRails fails the `scan_ruby` CI job; see dependabot branch `rails-8.1.3`).
- [ ] Test `rails-reviewer` on a deliberately flawed change (missing `includes`, missing `require_admin!`, spec without expectation) on a throwaway branch, to check it catches them.

## Web (after the API version)
- [ ] Web user administration by admin.
- [ ] Wire up `cart_controller.js` (quantity +/-) in the cart view, or delete it.

## Small cleanups
- [ ] Add text version of `OrderMailer#confirmation` email.
- [ ] `db/seeds.rb`: seed sample products for development (dev users incl. admin already seeded).
- [ ] Authorization policies (Pundit) to replace ad-hoc `role_admin?` checks.

## Ideas for later
- `order_historic` table: record each order status change (pending/paid/cancelled/refunded) with who changed it and when.
