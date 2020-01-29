require 'helper'

class IndicativeOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  STREAM_CONFIG = %[
    api_key               INDICATIVE_API_KEY
    event_name_key        event_name
    event_time_key        created_at
    event_unique_id_keys  user_id, session_id
  ]

  BUFFER_CONFIG = %[
    api_key               INDICATIVE_API_KEY
    event_name_key        event_name
    event_time_key        created_at
    event_unique_id_keys  user_id, session_id

    <buffer>
      chunk_limit_records 50
    </buffer>
  ]

  def create_driver(conf=STREAM_CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::IndicativeOutput).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver(STREAM_CONFIG)
    assert_equal 'INDICATIVE_API_KEY', d.instance.api_key
    assert_equal 'event_name', d.instance.event_name_key
    assert_equal 'created_at', d.instance.event_time_key
    assert_equal ['user_id', 'session_id'], d.instance.event_unique_id_keys
  end


  def test_emit_stream
    d = create_driver(STREAM_CONFIG)
    stub_request(:any, d.instance.api_url)
    d.run(default_tag: 'test') do
      d.feed({'event_name' => 'screen_view', 'created_at' => '2015-01-01T10:00:00.000Z', 'session_id' => 'a3bd2', 'user_id' => nil, 'screen' => {'id' => 'index'}})
    end
    events = d.events
    assert_equal 0, events.length
    assert_requested :post, d.instance.api_url,
      headers: {'Content-Type' => 'application/json'}, body: {
        'apiKey' => 'INDICATIVE_API_KEY',
        'events' => [{
          'eventName' => 'screen_view',
          'eventUniqueId' => 'a3bd2',
          'properties' => {
            'event_name' => 'screen_view',
            'created_at' => '2015-01-01T10:00:00.000Z',
            'session_id' => 'a3bd2',
            'user_id' => nil,
            'screen.id' => 'index'
          },
          'eventTime' => '2015-01-01T10:00:00+00:00'
        }]
      }.to_json, times: 1
  end

  def test_emit_buffer
    d = create_driver(BUFFER_CONFIG)
    stub_request(:any, d.instance.api_url)
    d.run(default_tag: 'test') do
      5.times do
        d.feed({'event_name' => 'screen_view', 'created_at' => '2015-01-01T10:00:00.000Z', 'session_id' => 'a3bd2', 'user_id' => nil, 'screen' => {'id' => 'index'}})
      end
    end
    events = d.events
    assert_equal 0, events.length
    assert_requested :post, d.instance.api_url, times: 1
  end

  def test_array_transformation
    d = create_driver(STREAM_CONFIG)
    stub_request(:any, d.instance.api_url)
    d.run(default_tag: 'test') do
      d.feed({'event_name' => 'screen_view', 'created_at' => '2015-01-01T10:00:00.000Z', 'session_id' => 'a3bd2', 'experiments': ['a', 'c']})
    end
    events = d.events
    assert_equal 0, events.length
    assert_requested :post, d.instance.api_url,
      headers: {'Content-Type' => 'application/json'}, body: {
        'apiKey' => 'INDICATIVE_API_KEY',
        'events' => [{
          'eventName' => 'screen_view',
          'eventUniqueId' => 'a3bd2',
          'properties' => {
            'event_name' => 'screen_view',
            'created_at' => '2015-01-01T10:00:00.000Z',
            'session_id' => 'a3bd2',
            'experiments.a' => true,
            'experiments.c' => true
          },
          'eventTime' => '2015-01-01T10:00:00+00:00'
        }]
      }.to_json, times: 1
  end

  def test_key_value_object_transformation
    d = create_driver(STREAM_CONFIG)
    stub_request(:any, d.instance.api_url)
    d.run(default_tag: 'test') do
      d.feed({'event_name' => 'screen_view', 'created_at' => '2015-01-01T10:00:00.000Z', 'session_id' => 'a3bd2', 'experiments': [{'key': 'a', 'value': 1}, {'key': 'b', 'value': 2}]})
    end
    events = d.events
    assert_equal 0, events.length
    assert_requested :post, d.instance.api_url,
      headers: {'Content-Type' => 'application/json'}, body: {
        'apiKey' => 'INDICATIVE_API_KEY',
        'events' => [{
          'eventName' => 'screen_view',
          'eventUniqueId' => 'a3bd2',
          'properties' => {
            'event_name' => 'screen_view',
            'created_at' => '2015-01-01T10:00:00.000Z',
            'session_id' => 'a3bd2',
            'experiments.a' => 1,
            'experiments.b' => 2
          },
          'eventTime' => '2015-01-01T10:00:00+00:00'
        }]
      }.to_json, times: 1
  end
end
