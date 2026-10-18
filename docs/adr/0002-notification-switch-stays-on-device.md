# Notification switch stays on device

Renewal **lead time** syncs through iCloud with the subscription. Whether this device sends renewal alerts does not sync: the switch lives in local settings so an iPad that copied “notifications on” from iCloud would alert you twice. This iPhone defaults to on; other devices default to off until you enable them there. We rejected a synced master switch because local notifications are scheduled per device and there is no server to deduplicate alerts.
