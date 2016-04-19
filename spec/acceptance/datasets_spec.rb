require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :datasets

    context 'For datasets list' do
      it 'Allows to access datasets list without filtering' do
        get '/datasets'

        data = json
        expect(status).to eq(200)
        expect(data.length).to eq(4)
      end

      it 'Allows to access datasets list filtering by type rest' do
        get '/datasets?connector_type=rest'

        data    = json
        dataset = json[0]
        expect(status).to eq(200)
        expect(data.length).to eq(2)
        expect(dataset['provider']).to eq('CartoDb')
      end

      it 'Allows to access datasets list filtering by type json' do
        get '/datasets?connector_type=json'

        data    = json
        dataset = json[0]
        expect(status).to eq(200)
        expect(data.length).to eq(2)
        expect(dataset['provider']).to eq('RwJson')
      end
    end

    context 'For specific dataset' do
      it 'Allows to access dataset details' do
        get '/datasets/1'

        data = json

        expect(status).to eq(200)
        expect(data['connector_name']).not_to be_nil
        expect(data['provider']).not_to       be_nil
        expect(data['format']).to             be_present
        expect(data['connector_url']).to      be_present
        expect(data['connector_path']).to     be_present
        expect(data['table_name']).to         be_present
      end

      it 'Allows to create rest dataset' do
        post '/datasets', params: {"dataset": {"table_name": "public.carts_test_endoint", "connector_name": "Carto test api", "connector_url": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint", "connector_format": 0, "connector_provider": 0, "connector_path": "rows", "attributes_path": "fields"}}

        data = json

        expect(status).to eq(201)
        expect(data['connector_name']).not_to be_nil
        expect(data['provider']).to           eq('CartoDb')
        expect(data['format']).to             be_present
        expect(data['connector_url']).to      be_present
        expect(data['connector_path']).to     be_present
        expect(data['table_name']).to         be_present
        expect(data['data_attributes']).to    be_present
      end

      it 'Allows to create json dataset' do
        post '/datasets', params: {"dataset": {
                                    "connector_type": "json",
                                    "connector_name": "Carto test api copy", "connector_format": 0, "connector_path": "rows",
                                    "attributes_path": "fields",
                                    "dataset_attributes": {
                                      "data_columns": {
                                        "iso": {"type": "string" },
                                        "name": {"type": "string" },
                                        "year": {"type": "string" },
                                        "the_geom": {"type": "geometry" },
                                        "cartodb_id": {"type": "number" },
                                        "population": {"type": "number" },
                                        "the_geom_webmercator": {"type": "geometry" }
                                      },
                                      "data": [
                                        {"cartodb_id": 1,"iso": "BRA","name": "Brazil","year": "2012","population": 218613196},
                                        {"cartodb_id": 5,"iso": "BRA","name": "Brazil","year": "2015","population": 198739269},
                                        {"cartodb_id": 7,"iso": "BRA","name": "Brazil","year": "2010","population": 178865342}
                                      ]
                                    }
                                    }
                                  }

        data = json

        expect(status).to eq(201)
        expect(data['connector_name']).not_to be_nil
        expect(data['provider']).to           eq('RwJson')
        expect(data['format']).to             be_present
        expect(data['data_attributes']).to    be_present
      end

      it 'Allows to update dataset' do
        put '/datasets/1', params: {"dataset": {"connector_name": "Carto test api update"}}

        data = json

        expect(status).to eq(201)
        expect(data['connector_name']).to eq('Carto test api update')
        expect(data['provider']).not_to       be_nil
        expect(data['format']).to             be_present
      end

      it 'Allows to delete dataset' do
        delete '/datasets/1'

        data = json

        expect(status).to eq(200)
        expect(json['message']).to eq('Dataset deleted')
      end
    end
  end
end
