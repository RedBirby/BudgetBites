# BudgetBite backend contracts

Flutter clients should call an app-owned backend instead of storing provider
secrets in the web or mobile bundle. Restrict the backend by origin, application
attestation, rate limit, and authenticated account where appropriate.

## Nearby stores

`GET {PLACES_PROXY_URL}?lat=34.1478&lng=-118.1445&radius=8000`

Response:

```json
[
  {
    "id": "provider-place-id",
    "name": "Example Market",
    "address": "123 Main St, Pasadena, CA 91101",
    "lat": 34.1478,
    "lng": -118.1445,
    "website": "https://example.com/products"
  }
]
```

Return only grocery-related results and normalize provider-specific fields at the
server boundary. Cache short-lived results to control provider cost.

## Store-local tax estimate

`GET {TAX_PROXY_URL}?zip=91101&address=123%20Main%20St%2C%20Pasadena%2C%20CA%2091101`

Response:

```json
{
  "rate": 10.25,
  "label": "Pasadena estimated combined rate"
}
```

`rate` is a percentage, not a decimal fraction. The app applies it to the entered
subtotal automatically and lets the user override it. Grocery taxability varies
by jurisdiction and product, so the result must remain visibly labeled as an
estimate.

## Inventory integration

Use retailer-approved product or inventory APIs only. Normalize product results
to a separate endpoint, for example:

`GET /v1/stores/{storeId}/products?query=tomato`

```json
{
  "storeId": "provider-place-id",
  "items": [
    {
      "name": "Roma Tomato",
      "price": 1.49,
      "currency": "USD",
      "availability": "in_stock",
      "productUrl": "https://retailer.example/products/roma-tomato",
      "checkedAt": "2026-08-27T12:00:00Z"
    }
  ]
}
```

If a retailer has no approved inventory feed, return `unknown` and show the
retailer's product-search page. Do not scrape websites whose terms prohibit it.

