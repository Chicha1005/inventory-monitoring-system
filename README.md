# Stockwise Inventory Monitor

Standalone, mobile-friendly inventory demo built with plain HTML, CSS, and JavaScript. It is separate from the portfolio and does not connect to the Google Sheet or a shared warehouse database.

## Open locally

Open `index.html` in a browser, or open this folder in VS Code and use the Live Server extension.

## Fast product setup with CSV

- Choose **Export CSV** to download the product master as an editable template.
- Add rows or edit product descriptions, principals, categories, case pack, prices, opening stock, and reorder levels in Excel or Google Sheets. Save/download as CSV, then choose **Import CSV**.
- Existing item codes are updated while their data-entry movement history stays in place. New item codes are added. Rows missing item code, description, principal, or a valid case pack are skipped and counted in the import result.
- Prices in the template use **owning cost per case including VAT** and **list price per case**. The importer also accepts common item-code/product/principal and case-price column names.

## Included workflow

- Dashboard with stock value, physical count value, variance by principal, low-stock review, and a live before/after chart by principal. The chart refreshes automatically after product imports, manual entries, or principal changes.
- Product master with case pack, opening stock, owning cost, list price, and reorder level.
- Data entry matching the sheet's date, mode, document number, principal, item code, CS, and PC fields.
- Audit results with quantity variance, owning-cost variance, list-price variance, principal totals, and count coverage.
- CSV exports for products, entries, and audit results.
- Demo changes stored in the current browser using localStorage. Reset sample data from the sidebar.

## Calculations adapted from the workbook

- Case-equivalent quantity = cases + pieces ÷ pieces per case.
- Cost before count = case-equivalent quantity × owning cost per case ÷ 1.12.
- Cost after count = physical case-equivalent quantity × owning cost per case ÷ 1.12.
- Price before/after count = corresponding case-equivalent quantity × list price per case.
- Quantity variance = physical count − system stock; cost variance = cost after − cost before.
- Totals roll up by principal and then into the overall total.

Sample products and counts are fictional. Browser storage does not sync across devices or users, so this remains a front-end demo rather than a shared production inventory system.