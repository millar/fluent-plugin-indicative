require 'helper'

class IndicativeOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    api_key               INDICATIVE_API_KEY
    event_name_key        event_name
    event_time_key        created_at
    event_unique_id_keys  user_id, session_id
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::IndicativeOutput).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver CONFIG
    assert_equal 'INDICATIVE_API_KEY', d.instance.api_key
    assert_equal 'event_name', d.instance.event_name_key
    assert_equal 'created_at', d.instance.event_time_key
    assert_equal ['user_id', 'session_id'], d.instance.event_unique_id_keys
  end


  def test_emit
    d = create_driver(CONFIG)
    stub_request(:any, d.instance.api_url)
    d.run(default_tag: 'test') do
      d.feed({'event_name' => 'screen_view', 'created_at' => '2015-01-01T00:00:00.000Z', 'session_id' => 'a3bd2', 'user_id' => nil, 'screen' => {'id' => 'index'}})
    end
    events = d.events
    assert_equal 0, events.length
    assert_requested :post, d.instance.api_url,
      headers: {'Content-Type' => 'application/json'}, body: {
        'apiKey' => 'INDICATIVE_API_KEY',
        'eventName' => 'screen_view',
        'eventUniqueId' => 'a3bd2',
        'properties' => {
          'event_name' => 'screen_view',
          'created_at' => '2015-01-01T00:00:00.000Z',
          'session_id' => 'a3bd2',
          'user_id' => nil,
          'screen.id' => 'index'
        },
        'eventTime' => '2015-01-01T00:00:00.000Z'
      }.to_json, times: 1
  end
end
