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

  def setup_test_records(size)
    origin_connection = sequel_connection(origin_setup)
    table_a_1 = origin_connection.from(:table_a)
    table_b_1 = origin_connection.from(:table_b)
    [table_a_1, table_b_1].each do |t|
      t.truncate if t.to_a.any?
    end
    table_a_1.insert(
      first_name: 'Paskal',
      last_name: 'Kamovich',
      email: 'paskal.kamovich@gmail.ru',
      created_at: Date.parse('2017-01-20')
    )
    table_a_1.insert(
      first_name: 'Paulo',
      last_name: 'Bedo',
      email: 'paulo@bedo.lol',
      created_at: Date.parse('2017-01-03')
    )
    table_b_1.insert(
      something: 'lol',
      something_else: 'lol_else'
    )
    table_a_1.import(
      [
        :created_at,
        :first_name,
        :last_name,
        :email
      ],
      [
        [
          Date.parse('2017-01-31'),
          'Anon',
          'Anon',
          'assange@nicaragua.fr'
        ]
      ] * size
    )
    origin_connection.disconnect
  end

  let!(:origin_setup) { origin_database.setup }
  let(:destination_setup) { destination_database.setup }
  let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/good_config.yml' }

  context 'integration test' do
    context 'config file mentions all columns of each table' do
      before do
        origin_connection = sequel_connection(origin_setup)
        origin_connection.create_table :table_a do
          primary_key :id
          Date :created_at
          String :first_name
          String :last_name
          String :email
        end
        origin_connection.create_table :table_b do
          primary_key :id
          String :something
          String :something_else
        end
        origin_connection.disconnect
      end

      it "pours anonymized data from one source db to a truncated destination db and uses row and column filters to format data" do
        allow(Faker::Name).to receive(:first_name) { 'Michale' }
        allow(Faker::Name).to receive(:last_name) { 'Pechovitz' }
        allow(Faker::Internet).to receive(:email) { 'michale.pechovitz@gmail.ru' }

        anonymizer = Toku::Anonymizer.new(
          config_file,
          {},
          max_creation_date: Toku::RowFilter::MaxCreationDate
        )

        size = 100000
        setup_test_records(size)
        GC.start
        before = ObjectSpace.memsize_of_all
        anonymizer.run(origin_uri, destination_uri)
        after = ObjectSpace.memsize_of_all

        destination_connection = sequel_connection(destination_setup)
        @table_b_2 = destination_connection.from(:table_b)
        @table_a_2 = destination_connection.from(:table_a)
        expect(@table_a_2.select.to_a.size).to eq size + 1
        expect(@table_a_2.select.to_a.first).to include(
          first_name: 'Michale',
          last_name: 'Pechovitz',
          created_at: Date.parse('2017-01-20'),
          email: 'michale.pechovitz@gmail.ru'
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
end
