# recurring

A personal subscription tracker: what you pay, when it renews, and how spend adds up over time.

## Language

**Subscription**:
A service you pay for on a repeating schedule. It is in **trial**, **active**, or **cancelled**.
_Avoid_: plan, membership

**Renewal**:
The next calendar day a charge is due, or the day a trial converts to paid.
_Avoid_: billing date, next payment

**Cadence**:
How often a subscription renews after each charge: weekly, monthly, quarterly, yearly, or every N weeks or months.
_Avoid_: occurrence, frequency, interval

**Billed price**:
What the service lists on its invoice, in its currency. A label only; never spend.
_Avoid_: price, amount due

**Charge**:
One Singapore-dollar amount that left your account on a renewal date. Only **confirmed** charges count toward **cash**.
_Avoid_: payment, transaction, bill

**Run rate**:
The pace over a year if every current charge amount kept renewing at its cadence.
_Avoid_: total, annual cost, yearly total

**Coming year**:
Charges dated in the rolling twelve months from today.
_Avoid_: forecast, projected spend

**Cash**:
The sum of confirmed charges over a chosen period.
_Avoid_: spent, actuals

**Use**:
Whether a subscription is **personal** or **business** cost. Exactly one; never split across both.
_Avoid_: type, account

**Payment nickname**:
A short label for which account pays, such as “DBS Visa”. Not a card number.
_Avoid_: payment method, card

**Draft charge**:
A past charge the app proposed from a backfill date that does not count until you confirm it.
_Avoid_: pending, suggested

**Lead time**:
How many days before a renewal this device may notify you. Stored on the subscription; the on/off switch does not sync.
_Avoid_: reminder offset, alert days
