require "spec_helper"

describe Toku do
  it "has a version number" do
    expect(Toku::VERSION).not_to be nil
  end

  let(:origin_database) do
    pg_db('origin')
  end

  let(:destination_database) do
    pg_db('destination')
  end

  let(:origin_uri) do
    "postgres://origin@localhost:6433/origin"
  end

  let(:destination_uri) do
    "postgres://destination@localhost:6433/destination"
  end

  let!(:origin_setup) { origin_database.setup }
  let!(:destination_setup) { destination_database.setup }

  before do
    origin_connection = sequel_connection(origin_setup)
    destination_connection = sequel_connection(destination_setup)
    [origin_connection, destination_connection].each do |connection|
      connection.create_table :table_a do
        primary_key :id
        String :first_name
        String :last_name
        String :email
      end
    end
    @table_a_1 = origin_connection.from(:table_a)
    @table_a_2 = destination_connection.from(:table_a)
    @table_a_1.insert(
      first_name: 'Paskal',
      last_name: 'Kamovich',
      email: 'paskal.kamovich@gmail.ru'
    )
  end

  after do
    origin_database.teardown
    destination_database.teardown
  end

  context 'config file mentions all columns of each table' do
    let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/good_config.yml' }

    it "pours anonymized data from one db to another" do
      allow(Faker::Name).to receive(:first_name) { 'Michale' }
      allow(Faker::Name).to receive(:last_name) { 'Pechovitz' }
      allow(Faker::Internet).to receive(:email) { 'michale.pechovitz@gmail.ru' }

      expect(@table_a_2.select.to_a).to be_empty
      Toku::Anonymizer.new(config_file).run(origin_uri, destination_uri)
      expect(@table_a_2.select.to_a.first).to eq(
        {
          id: 1,
          first_name: 'Michale',
          last_name: 'Pechovitz',
          email: 'michale.pechovitz@gmail.ru'
        }
      )
    end
  end

  context 'config file omits 1 or more colums' do
    let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/bad_config.yml' }
    it 'raises Toku::FilterMissingError' do
      expect do
        Toku::Anonymizer.new(config_file).run(origin_uri, destination_uri)
      end.to raise_error Toku::FilterMissingError
    end
  end
end
