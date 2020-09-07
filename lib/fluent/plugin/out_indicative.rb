require 'date'
require 'net/http'
require 'net/https'
require 'uri'

require 'fluent/plugin/output'


def flatten_hash(hash)
  hash.each_with_object({}) do |(k, v), h|
    if v.is_a? Hash
      flatten_hash(v).map do |h_k, h_v|
        h["#{k}.#{h_k}"] = h_v
      end
    elsif v.is_a? Array
      # Indicative doesn't support arrays so we use the value of the array as a key and set it to true
      v.each do |item|
        if item.is_a?(Hash) && item.has_key?("key") && item.has_key?("value")
          h["#{k}.#{item["key"]}"] = item["value"]
        end
      end
    else
      h[k] = v
    end
   end
end


class Fluent::Plugin::IndicativeOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('indicative', self)

  config_param :api_key, :string, secret: true
  config_param :api_url, :string, default: 'https://api.indicative.com/service/event/batch'
  config_param :batch_size, :integer, default: 15
  config_param :event_name_key, :string
  config_param :event_time_key, :string
  config_param :event_unique_id_keys, :array, value_type: :string
  config_param :event_filter_key, :string, default: nil

  def process(tag, es)
    es.each_slice(@batch_size) do |events|
      send_events(events.map {|time, record| record})
    end
  end

  def write(chunk)
    records = []
    chunk.each do |time, record|
      records << record
    end
    records.each_slice(@batch_size) do |events|
      send_events(events)
    end
  end

  def send_events(events)
    uri = URI.parse(@api_url)

    headers = {'Content-Type' => 'application/json'}

    payload = {
      apiKey: @api_key,
      events: events.filter {|data| data[@event_filter_key] != false}.map do |data|
        unique_id_key = @event_unique_id_keys.find {|k| data[k]}
        {
          eventName: data[@event_name_key],
          eventUniqueId: unique_id_key && data[unique_id_key],
          properties: flatten_hash(data),
          eventTime: DateTime.parse(data[@event_time_key]).rfc3339
        }
      end
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = payload.to_json
    response = http.request(request)

    if response.code != "200"
        log.warn("Indicative responded with error (code: #{response.code}): #{payload.to_json} -> #{response.body}")
    end
  end
end
