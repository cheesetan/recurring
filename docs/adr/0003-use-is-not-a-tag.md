# Use is not a tag

**Use** (personal or business) is a required field on each subscription. It is not a tag and not stored on individual charges; changing use rebuckets every confirmed charge for that subscription in filtered views. Use describes whose cost it is (see ADR 0004 for why service-type labels were removed). We rejected personal/business as tags, a “both” value, and splitting one charge by percentage, because grouping spend that way would double-count or hide business costs mixed with personal ones.
