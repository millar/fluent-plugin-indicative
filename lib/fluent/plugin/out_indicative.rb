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
    else 
      h[k] = v
    end
   end
end


class Fluent::Plugin::IndicativeOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('indicative', self)

  config_param :api_key, :string, secret: true
  config_param :api_url, :string, default: 'https://api.indicative.com/service/event'
  config_param :event_name_key, :string
  config_param :event_time_key, :string
  config_param :event_unique_id_keys, :array, value_type: :string

  def process(tag, es)
    es.each do |time, record|
      send_event(record)
    end
  end

  def send_event(data)
    uri = URI.parse(@api_url)

    headers = {'Content-Type' => 'application/json'}

    unique_id_key = @event_unique_id_keys.find {|k| data[k]}

    payload = {
      apiKey: @api_key,
      eventName: data[@event_name_key],
      eventUniqueId: unique_id_key && data[unique_id_key],
      properties: flatten_hash(data),
      eventTime: data[@event_time_key]
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = payload.to_json
    response = http.request(request)
  end
end
