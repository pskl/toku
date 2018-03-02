require "spec_helper"

describe Toku do
  subject { Toku::Anonymizer.new(config_file) }

  it "has a version number" do
    expect(Toku::VERSION).not_to be nil
  end

  let(:origin_uri) do
    "postgres://pskl@localhost:#{PG_PORT}/postgres"
  end

  let(:destination_uri) do
    "postgres://pskl@localhost:#{PG_PORT}/destination"
  end

  let(:origin_connection) { Sequel.connect(origin_uri) }
  let(:destination_connection) { Sequel.connect(destination_uri) }
  let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/good_config.yml' }

  context 'integration test' do
    context 'config file mentions all columns of each table' do
      before do
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
        destination_connection.disconnect
        puts "#{after - before} bytes consumed"
      end
    end

    context 'config file omits 1 or more colums' do
      let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/bad_config.yml' }
      it 'raises Toku::FilterMissingError' do
        expect do
          subject.run(origin_uri, destination_uri)
        end.to raise_error Toku::ColumnFilterMissingError
      end
    end

    describe '#transform' do
      let(:config_file) {  File.expand_path('../', __FILE__) + '/fixtures/good_config.yml' }

      it 'sequentially instantiate and calls each filter in the filter stack and outputs a csv string' do
        allow(Faker::Name).to receive(:first_name) { 'Michale' }
        allow(Faker::Name).to receive(:last_name) { 'Pechovitz' }
        allow(Faker::Internet).to receive(:email) { 'michale.pechovitz@gmail.ru' }
        expect(Toku::ColumnFilter::Passthrough).to receive(:new).at_least(:once).and_call_original
        expect(Toku::ColumnFilter::FakerLastName).to receive(:new).exactly(:once).and_call_original
        expect(
          subject.send(
            :transform,
            {
              :id=>1,
              :created_at=> Date.parse('2017-01-20'),
              :first_name=>"Paskal",
              :last_name=>"Kamovich",
              :email=>"paskal.kamovich@gmail.ru"
            },
            :table_a
            )
        ).to eq "1,2017-01-20,Michale,Pechovitz,michale.pechovitz@gmail.ru\n"
      end
    end
  end
end
