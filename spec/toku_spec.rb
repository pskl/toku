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
    "postgres://origin@localhost:#{PG_PORT}/origin"
  end

  let(:destination_uri) do
    "postgres://destination@localhost:#{PG_PORT}/destination"
  end

  let!(:origin_setup) { origin_database.setup }
  let!(:destination_setup) { destination_database.setup }
  let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/good_config.yml' }

  context 'integration test' do
    after do
      origin_database.teardown
      destination_database.teardown
    end

    before do
      origin_connection = sequel_connection(origin_setup)
      destination_connection = sequel_connection(destination_setup)
      [origin_connection, destination_connection].each do |connection|
        connection.create_table :table_a do
          primary_key :id
          Date :created_at
          String :first_name
          String :last_name
          String :email
        end
        connection.create_table :table_b do
          primary_key :id
          String :something
          String :something_else
        end
      end
      @table_a_1 = origin_connection.from(:table_a)
      @table_b_1 = origin_connection.from(:table_b)
      @table_b_2 = destination_connection.from(:table_b)
      @table_a_2 = destination_connection.from(:table_a)
      @table_a_1.insert(
        first_name: 'Paskal',
        last_name: 'Kamovich',
        email: 'paskal.kamovich@gmail.ru',
        created_at: Date.parse('2017-01-20')
      )
      @table_a_1.insert(
        first_name: 'Paulo',
        last_name: 'Bedo',
        email: 'paulo@bedo.lol',
        created_at: Date.parse('2017-01-03')
      )
      @table_b_1.insert(
        something: 'lol',
        something_else: 'lol_else'
      )
    end
    context 'config file mentions all columns of each table' do
      it "pours anonymized data from one db to another and uses row and column filters" do
        allow(Faker::Name).to receive(:first_name) { 'Michale' }
        allow(Faker::Name).to receive(:last_name) { 'Pechovitz' }
        allow(Faker::Internet).to receive(:email) { 'michale.pechovitz@gmail.ru' }

        expect(@table_a_2.select.to_a).to be_empty
        Toku::Anonymizer.new(
          config_file,
          {},
          {
            max_creation_date: Toku::RowFilter::MaxCreationDate
          }
        ).run(origin_uri, destination_uri)
        expect(@table_a_2.select.to_a.count).to eq 1
        expect(@table_a_2.select.to_a.first).to eq(
          {
            id: 1,
            first_name: 'Michale',
            last_name: 'Pechovitz',
            created_at: Date.parse('2017-01-20'),
            email: 'michale.pechovitz@gmail.ru'
          }
        )
        expect(@table_b_2.select.to_a).to eq []
      end
    end

    context 'config file omits 1 or more colums' do
      let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/bad_config.yml' }
      it 'raises Toku::FilterMissingError' do
        expect do
          Toku::Anonymizer.new(config_file).run(origin_uri, destination_uri)
        end.to raise_error Toku::ColumnFilterMissingError
      end
    end
  end

  context 'schema is different between origin and destination table' do
    before do
      origin_connection = sequel_connection(origin_setup)
      destination_connection = sequel_connection(destination_setup)
      origin_connection.create_table :table_a do
        primary_key :id
        Date :created_at
        String :first_name
        String :last_name
        String :email
      end
      destination_connection.create_table :table_a do
        primary_key :id
        Date :created_at
        String :first_name
        String :last_name
      end
    end

    it 'raise an error' do
      expect do
        Toku::Anonymizer.new(config_file).run(origin_uri, destination_uri)
      end.to raise_error Toku::SchemaMismatchError
    end
  end
end
