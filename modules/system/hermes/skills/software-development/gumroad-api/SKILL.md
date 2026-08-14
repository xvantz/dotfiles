---
name: gumroad-api
description: Automates Gumroad creator workflows including product management, sales tracking, license verification, and webhook setup. Use when the user says "Gumroad", "verify license", "list my products", "check sales", "set up webhooks", or asks to build Gumroad integrations or scripts. Handles OAuth authentication and API calls to api.gumroad.com.
trigger: "Gumroad API, license verification, webhooks, subscriptions"
---

# Gumroad API Integration

## Required Environment Variables

This skill requires the following environment variables to be set:

**GUMROAD_ACCESS_TOKEN** (required for authenticated API calls)
- Your personal access token from Gumroad
- Get it at: [https://app.gumroad.com/settings/advanced#application-form](https://app.gumroad.com/settings/advanced#application-form)
- Used for: Product management, sales data, webhooks, refunds
- **Security:** Never commit tokens to version control

**GUMROAD_PRODUCT_ID** (optional)
- Your product ID for license verification workflows
- Find it in your Gumroad product settings

How you set these environment variables is up to you:
- System environment variables
- Shell profile (.zshrc, .bashrc, .profile)
- IDE/editor configuration
- Secrets manager (1Password, AWS Secrets Manager, etc.)
- Container/deployment environment

> For production OAuth applications serving multiple users, see `references/authentication.md`

## Instructions

### Step 1: Verify Authentication

Before making any API calls, verify the GUMROAD_ACCESS_TOKEN environment variable is set:

**Test authentication:**
```bash
curl -H "Authorization: Bearer $GUMROAD_ACCESS_TOKEN" \
  https://api.gumroad.com/v2/user
```

**Expected success response:**
```json
{
  "success": true,
  "user": {
    "id": "...",
    "name": "...",
    "email": "..."
  }
}
```

**If authentication fails:**
- Check that GUMROAD_ACCESS_TOKEN is set in the environment
- Verify the token is valid (not expired or revoked)
- Get a new token at [Gumroad Advanced Settings](https://app.gumroad.com/settings/advanced#application-form)

**Token scopes** (for OAuth apps):
- Product management: `edit_products`
- Sales data: `view_sales`
- Webhooks: `view_sales`
- Refunds: `refund_sales`
- License verification: No authentication required

**Note:** Personal access tokens have full account access. For OAuth apps serving multiple users, see `references/authentication.md`.

### Step 2: Execute Common Workflows

Choose the workflow based on user request:

> **Reference Files:**
> - Full endpoint documentation: `references/endpoints.md`
> - Example API responses: `references/examples/responses.md`
> - Rate limiting and pagination: `references/examples/rate-limiting.md`

#### Workflow: List Products

```bash
curl -H "Authorization: Bearer ACCESS_TOKEN" \
  https://api.gumroad.com/v2/products
```

- Returns array of products with id, name, price, sales data
- Requires `view_public` scope minimum
- Sales counts require `view_sales` scope

**Creating products:** Use templates from `templates/` folder:
- Digital products: `templates/digital-product.json`
- Memberships: `templates/membership-product.json`
- Physical products: `templates/physical-product.json`

**IMPORTANT:** Product descriptions use **HTML, not Markdown**. Use `<h2>`, `<p>`, `<ul>`, `<li>`, `<strong>`, `<em>` tags for formatting.

**API Limitations:**

*Product Cover Images:*
- Cover images and thumbnails **cannot** be uploaded via the REST API
- The API accepts image files but does not process them
- Product covers must be uploaded manually through the Gumroad web dashboard at [app.gumroad.com/products](https://app.gumroad.com/products)
- This applies to all product update endpoints including `PUT /v2/products/:id`

*Product Content Files:*
- Product content files (PDFs, ZIPs, etc.) **cannot** be uploaded via the REST API
- No file upload endpoint exists in the REST API
- Product files must be uploaded manually through the Gumroad web dashboard at [app.gumroad.com/products](https://app.gumroad.com/products)
- Tested endpoints that don't exist: `POST /v2/products/:id/files`

#### Workflow: Verify License Key

```bash
curl -X POST https://api.gumroad.com/v2/licenses/verify \
  -d "license_key=LICENSE_KEY" \
  -d "product_id=PRODUCT_ID"
```

**CRITICAL:** This endpoint does NOT require authentication - it’s designed for client-side use.

Parameters:
- `license_key` (required)
- `product_id` (strongly recommended)
- `increment_uses_count=false` (optional - use for checks without incrementing counter)

Success response: `{"success": true, "purchase": {...}, "uses": N}`

**Implementation example:** See `templates/license-validator.js` for complete client-side validation code

#### Workflow: Fetch Sales Data

```bash
curl -H "Authorization: Bearer ACCESS_TOKEN" \
  "https://api.gumroad.com/v2/sales?page_key=PAGE_KEY"
```

**IMPORTANT:** Use cursor pagination with `page_key`, NOT the deprecated `page` parameter.

- Requires `view_sales` scope
- Returns ~10 sales per page
- Get next page: Use `next_page_key` from response
- Filter options: `after`, `before` (YYYY-MM-DD), `email`, `product_id`, `order_id`

#### Workflow: Set Up Webhooks

```bash
curl -X PUT -H "Authorization: Bearer ACCESS_TOKEN" \
  https://api.gumroad.com/v2/resource_subscriptions \
  -d "resource_name=sale" \
  -d "post_url=https://example.com/webhook"
```

- Requires `view_sales` scope
- Resource names: `sale`, `refund`, `cancellation`, `subscription_ended`, `subscription_restarted`, `subscription_updated`, `dispute`, `dispute_won`
- `post_url` must be publicly accessible (no localhost)
- **Security:** Verify webhook authenticity by cross-checking data with GET /v2/sales/:id

**Implementation example:** See `templates/webhook-handler.py` for complete webhook receiver with verification

### Step 3: Handle Responses

**CRITICAL:** Always check the `success` field in the response body:

```json
{
  "success": true,  // Check this FIRST
  "data": {...}
}
```

Even HTTP 200 responses may contain `"success": false` with error details.

Common HTTP codes:
- `200`: Request processed (check `success` in body)
- `401`: Authentication failed
- `404`: Resource not found
- `422`: Validation error
- `429`: Rate limited (back off exponentially)

> For complete error handling guide, see `references/error-codes.md`

## Examples

### Example 1: Build License Verification Script

User says: "Help me verify Gumroad licenses in my app"

Actions:
1. Explain that license verification does NOT require authentication
2. Show how to POST to `/v2/licenses/verify` with `license_key` and `product_id`
3. Demonstrate handling `success: false` for invalid/disabled licenses
4. Recommend using `increment_uses_count=false` for non-activating checks

Result: Working license verification code that handles all edge cases

### Example 2: Sales Analytics Script

User says: "Fetch all my sales from last month"

Actions:
1. Verify `view_sales` scope is available
2. Calculate date range: `after=YYYY-MM-DD&before=YYYY-MM-DD`
3. Implement cursor pagination with `page_key`
4. Aggregate results across all pages
5. Handle rate limits with exponential backoff

Result: Complete sales data for the specified period

### Example 3: Webhook Integration

User says: "Set up a webhook to notify me of new sales"

Actions:
1. Confirm `view_sales` scope
2. Create webhook: `PUT /v2/resource_subscriptions` with `resource_name=sale`
3. Provide endpoint URL handling code
4. Explain webhook verification strategy
5. Show how to test with a real purchase

Result: Working webhook that triggers on new sales

## Troubleshooting

### Error: "Token not provided"

**Cause:** Missing or incorrectly formatted Authorization header

**Solution:**
- Use: `Authorization: Bearer YOUR_TOKEN`
- NOT: `Authorization: YOUR_TOKEN`
- Verify token is not expired

### Error: "Invalid license key"

**Cause:** License key doesn’t exist, was refunded, or is disabled

**Solution:**
- Check `success: false` in response body
- Verify `product_id` matches the license
- Check if license has been disabled or refunded via dashboard
- Inspect `purchase` object in successful responses for status

### Error: Rate limit (429)

**Cause:** Too many requests in short time

**Solution:**
- Implement exponential backoff (wait 2s, 4s, 8s, etc.)
- Use webhooks instead of polling for real-time data
- Cache responses when appropriate

### Pagination Timing Out

**Cause:** Using deprecated `page` parameter on large datasets

**Solution:**
- Switch to cursor pagination with `page_key`
- Use: `GET /v2/sales?page_key=CURSOR_FROM_PREVIOUS_RESPONSE`
- Continue until `next_page_key` is null

## API Reference Quick Links

**Base URL:** `https://api.gumroad.com/v2`

**Key Endpoints:**
- User: `GET /user`
- Products: `GET/POST /products`, `GET/PUT/DELETE /products/:id`
- Sales: `GET /sales`, `GET /sales/:id`
- Licenses: `POST /licenses/verify`, `PUT /licenses/enable`, `PUT /licenses/disable`
- Webhooks: `GET /resource_subscriptions`, `PUT /resource_subscriptions`, `DELETE /resource_subscriptions/:id`

**Documentation:** [gumroad.com/api](https://gumroad.com/api)

## Security Best Practices

- **Never hardcode tokens:** Use environment variables or secrets manager
- **Use Bearer auth:** Avoid query-string tokens (they appear in logs)
- **Implement CSRF protection:** Use `state` parameter in OAuth flow
- **Verify webhook signatures:** Cross-check webhook data with API lookups
- **Rotate compromised tokens:** Immediately regenerate if tokens are exposed
