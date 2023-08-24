# evo-siigo
Integration between different CRM platforms using [Temporal](https://temporal.io/)

## Getting started

```env
#.env
EVO_USERNAME=foo
EVO_PASSWORD=hackme
SIIGO_USERNAME=foo
SIIGO_ACCESS_KEY=hackme
SIIGO_ADDRESS_CSV_URL="https://raw.githubusercontent.com/klarkc/evo-siigo/main/SiigoAddress.csv"
```

```bash
nix develop
```

## Endpoints

- `/process-sale`: Process a Evo sale event, add a webhook in evo pointing to this address for `AlterReceivables`, `ClearedDebt` and `NewSale` events.
