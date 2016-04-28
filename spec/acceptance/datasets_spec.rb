require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :datasets
    fixtures :json_connectors

    context 'For datasets list' do
      it 'Allows to access datasets list without filtering' do
        get '/datasets'

        dataset_json = json[0]
        dataset_rest = json[3]
        expect(status).to eq(200)
        expect(json.length).to eq(4)
        expect(dataset_json['provider']).to eq('RwJson')
        expect(dataset_rest['provider']).to eq('CartoDb')
      end

      it 'Allows to access datasets list filtering by type rest' do
        get '/datasets?connector_type=rest'

        dataset = json[0]
        expect(status).to eq(200)
        expect(json.length).to eq(2)
        expect(dataset['provider']).to eq('CartoDb')
      end

      it 'Allows to access datasets list filtering by type json' do
        get '/datasets?connector_type=json'

        dataset = json[0]
        expect(status).to eq(200)
        expect(json.length).to eq(2)
        expect(dataset['provider']).to eq('RwJson')
      end
    end

    context 'For specific dataset' do
      context 'Rest dataset' do
        let!(:dataset_id) { Dataset.find_by(name: 'CartoDb test set').id }

        it 'Allows to access dataset details' do
          get "/datasets/#{dataset_id}"

          expect(status).to eq(200)
          expect(json['name']).to           eq('CartoDb test set')
          expect(json['provider']).to       eq('CartoDb')
          expect(json['format']).to         eq('JSON')
          expect(json['connector_url']).to  be_present
          expect(json['data_path']).to      be_present
          expect(json['table_name']).to     be_present
        end

        it 'Allows to create rest dataset' do
          post '/datasets', params: {"dataset": {"connector_provider": 0, "table_name": "public.carts_test_endoint", "connector_url": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint", "dataset_attributes": {"name": "Carto test api", "format": 0, "data_path": "rows", "attributes_path": "fields"}}}

          expect(status).to eq(201)
          expect(json['name']).not_to        be_nil
          expect(json['provider']).to        eq('CartoDb')
          expect(json['format']).to          be_present
          expect(json['connector_url']).to   be_present
          expect(json['data_path']).to       be_present
          expect(json['table_name']).to      be_present
        end

        it 'Allows to update dataset' do
          put "/datasets/#{dataset_id}", params: {"dataset": {"dataset_attributes": {"name": "Carto test api update"}}}

          expect(status).to eq(201)
          expect(json['name']).to         eq('Carto test api update')
          expect(json['provider']).not_to be_nil
          expect(json['format']).to       be_present
        end

        it 'Allows to delete dataset' do
          delete "/datasets/#{dataset_id}"

          expect(status).to eq(200)
          expect(json['message']).to eq('Dataset would be deleted!')
        end
      end

      context 'Json dataset' do
        let!(:dataset_id) { Dataset.find_by(name: 'Json test set').id }

        it 'Allows to update dataset' do
          put "/datasets/#{dataset_id}", params: {"dataset": {"dataset_attributes": {"name": "Json test api update"}}}

          expect(status).to eq(201)
          expect(json['name']).to eq('Json test api update')
        end

        it 'Allows to create json dataset' do
          post '/datasets', params: {"dataset": {
                                      "connector_type": "json",
                                      "dataset_attributes": {"name": "Json test api", "format": 0},
                                      "data": [
                                        {"cartodb_id": 1,"iso": "BRA","name": "Brazil","year": "2012","population": 218613196},
                                        {"cartodb_id": 5,"iso": "BRA","name": "Brazil","year": "2015","population": 198739269},
                                        {"cartodb_id": 7,"iso": "BRA","name": "Brazil","year": "2010","population": 178865342}
                                      ],
                                      "data_attributes": {"iso": {"type": "string"} }
                                    }}

          expect(status).to eq(201)
          expect(json['name']).to     eq('Json test api')
          expect(json['provider']).to eq('RwJson')
          expect(json['format']).to   be_present
        end

        it 'Allows to delete dataset' do
          delete "/datasets/#{dataset_id}"

          expect(status).to eq(200)
          expect(json['message']).to eq('Dataset would be deleted!')
        end
      end
    end
  end
end
