# Stockwise Inventory System

Private, owner-only inventory system. Product records and stock movements are stored in Supabase Postgres and accessed through Supabase Auth with row-level security. The app has no fictional sample records or browser-only inventory storage.

## Set up Supabase

1. Create a Supabase project.
2. Run `supabase/schema.sql` once in the Supabase SQL Editor.
3. In Supabase Authentication, create the owner's email/password user. Public sign-ups are not part of this app.
4. Copy the project URL and the browser-safe Publishable key from the Supabase project settings. Do not use or expose a `service_role` or secret key.

## Connect Vercel

Set these Vercel project environment variables for Production (and Preview if needed):

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

The `/api/config` function returns only those public client settings. Database access is protected by row-level security; the server secret key is never sent to the browser. Redeploy after adding environment variables.

## Importing the product master

- Use **Import CSV** to load product files exported from Google Sheets.
- The importer recognizes columns such as `ITEMCODE`, `DESCRIPTION`, `CATEGORY`, `QTY PER CASE`, `COST`, and `PRICE`. If a file has no principal column, it asks for the principal name for that sheet.
- Product master import contains SKU, description, principal, category, case pack, cost, and list price. It does not import old stock counts or audit values unless opening-stock columns are intentionally included.
- Existing SKUs update product master fields without deleting movement history. Missing price fields preserve the existing price.
- Export a CSV at any time to download the current product master or reports.

## Inventory records

- The owner signs in with the Supabase Auth account created for this system.
- Product master updates and stock entries are saved in the shared database and appear after sign-in on other devices.
- Stock history is append-only. Correct a prior entry with an adjustment rather than deleting the original record.
- Every movement stores the case pack used at that time, so a later pack-size update does not rewrite old quantities.
- Physical Count Beginning establishes the quantity baseline; later dated receipts and deductions update system stock. Physical Count Ending is the audit count.
- Cost before/after count = case-equivalent quantity × owning cost per case ÷ 1.12.
- Price before/after count = case-equivalent quantity × list price per case.

The system does not contain the Google Sheet's product list until the owner imports it into the configured private database.