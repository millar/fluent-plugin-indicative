# fluent-plugin-indicative

Fluentd output plugin to send events to [Indicative](https://www.indicative.com/)

## Configuration

```
<match tag>
  @type indicative

  api_key               INDICATIVE_API_KEY
  event_name_key        event_name
  event_time_key        created_at
  event_unique_id_keys  user_id, cookie_id, session_id  # keys to search for unique user ID value, in order of priority
</match>
```
