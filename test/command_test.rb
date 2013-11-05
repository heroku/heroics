require 'helper'
require 'stringio'

class CommandTest < MiniTest::Test
  # Command.name returns the name of the command, which is made up by joining
  # the resource name and link title with a colon.
  def test_name
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][0]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)
    assert_equal('resource:list', command.name)
  end

  # Command.description returns a description for the command.
  def test_description
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][0]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)
    assert_equal('Show all sample resources', command.description)
  end

  # Command.run calls the correct method on the client when no link parameters
  # are provided.
  def test_run_without_parameters
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][0]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)

    body = ['Hello', 'World!']
    Excon.stub(method: :get) do |request|
      assert_equal('/resource', request[:path])
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(body)}
    end

    command.run
    assert_equal(MultiJson.dump(body), output.string)
  end

  # Command.run calls the correct method on the client and passes link
  # parameters when they're provided.
  def test_run_with_parameters
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][1]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)

    uuid = '1ab1c589-df46-40aa-b786-60e83b1efb10'
    body = {'Hello' => 'World!'}
    Excon.stub(method: :get) do |request|
      assert_equal("/resource/#{uuid}", request[:path])
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(body)}
    end

    command.run(uuid)
    assert_equal(MultiJson.dump(body), output.string)
  end

  # Command.run calls the correct method on the client and passes a request
  # body to the link when it's provided.
  def test_run_with_request_body_and_text_response
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][2]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)

    body = {'Hello' => 'World!'}
    Excon.stub(method: :post) do |request|
      assert_equal('/resource', request[:path])
      assert_equal('application/json', request[:headers]['Content-Type'])
      assert_equal(body, MultiJson.load(request[:body]))
      Excon.stubs.pop
      {status: 201}
    end

    command.run(body)
    assert_equal('', output.string)
  end

  # Command.run calls the correct method on the client and converts the result
  # to an array, if a range response is received, before writing it out.
  def test_run_with_range_response
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][0]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)

    Excon.stub(method: :get) do |request|
      Excon.stubs.shift
      {status: 206, headers: {'Content-Type' => 'application/json',
                              'Content-Range' => 'id 1..2; max=200'},
       body: MultiJson.dump([2])}
    end

    Excon.stub(method: :get) do |request|
      Excon.stubs.shift
      {status: 206, headers: {'Content-Type' => 'application/json',
                              'Content-Range' => 'id 0..1; max=200',
                              'Next-Range' => '201'},
       body: MultiJson.dump([1])}
    end

    command.run
    assert_equal(MultiJson.dump([1, 2]), output.string)
  end

  # Command.run calls the correct method on the client and passes parameters
  # and a request body to the link when they're provided.
  def test_run_with_request_body_and_parameters
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][3]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)

    uuid = '1ab1c589-df46-40aa-b786-60e83b1efb10'
    body = {'Hello' => 'World!'}
    result = {'Goodbye' => 'Universe!'}
    Excon.stub(method: :patch) do |request|
      assert_equal("/resource/#{uuid}", request[:path])
      assert_equal('application/json', request[:headers]['Content-Type'])
      assert_equal(body, MultiJson.load(request[:body]))
      Excon.stubs.pop
      {status: 200, headers: {'Content-Type' => 'application/json'},
       body: MultiJson.dump(result)}
    end

    command.run(uuid, body)
    assert_equal(MultiJson.dump(result), output.string)
  end

  # Command.run raises an ArgumentError if too few parameters are provided.
  def test_run_with_too_few_parameters
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][1]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)
    assert_raises ArgumentError do
      command.run
    end
  end

  # Command.run raises an ArgumentError if too many parameters are provided.
  def test_run_with_too_many_parameters
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][1]
    properties = SAMPLE_SCHEMA['definitions']['resource']['definitions']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)
    assert_raises ArgumentError do
      command.run('too', 'many', 'parameters')
    end
  end

  # Command.usage displays usage information.
  def test_usage
    client = Heroics::client_from_schema(SAMPLE_SCHEMA, 'https://example.com')
    schema = SAMPLE_SCHEMA['definitions']['resource']['links'][3]
    properties = SAMPLE_SCHEMA['definitions']['resource']['properties']
    output = StringIO.new
    command = Heroics::Command.new('cli', 'resource', schema, properties,
                                   client, output)
    command.usage
    expected = <<-USAGE
Usage: cli resource:update <uuid_field> <body>

Description:
  Update a sample resource
USAGE
    assert_equal(expected, output.string)
  end
end
