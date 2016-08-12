require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :wms_connectors
    fixtures :datasets

    context 'For datasets list' do
      it 'Allows to access datasets list without filtering' do
        get '/datasets'

        dataset_json = json[0]
        dataset_rest = json[3]
        expect(status).to eq(200)
        expect(json.length).to eq(5)
        expect(dataset_json['attributes']['provider']).to eq('rwjson')
        expect(dataset_rest['attributes']['provider']).to eq('cartodb')
      end

      it 'Allows to access datasets list filtering by type rest' do
        get '/datasets?connector_type=rest'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to eq(2)
        expect(dataset['provider']).to eq('cartodb')
      end

      it 'Allows to access datasets list filtering by type json' do
        get '/datasets?connector_type=json'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to eq(2)
        expect(dataset['provider']).to eq('rwjson')
      end

      it 'Allows to access datasets list filtering by type wms' do
        get '/datasets?connector_type=wms'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to eq(1)
        expect(dataset['provider']).to eq('wms')
      end

      it 'Show list of all datasets using status filter all' do
        get '/datasets?status=all'

        expect(status).to eq(200)
        expect(json.size).to eq(7)
      end

      it 'Show list of datasets with pending status' do
        get '/datasets?status=pending'

        expect(status).to eq(200)
        expect(json.size).to eq(1)
      end

      it 'Show list of datasets with active status' do
        get '/datasets?status=active'

        expect(status).to eq(200)
        expect(json.size).to eq(5)
      end

      it 'Show list of datasets with disabled status' do
        get '/datasets?status=disabled'

        expect(status).to eq(200)
        expect(json.size).to eq(1)
      end

      it 'Show list of datasets for app GFW' do
        get '/datasets?app=GFw'

        expect(status).to eq(200)
        expect(json.size).to                           eq(2)
        expect(json[0]['attributes']['layers'][0]['application']).to eq('gfw')
        expect(json[0]['attributes']['application'][0]).to           eq('gfw')
      end

      it 'Show list of datasets for app WRW' do
        get '/datasets?app=wrw'

        expect(status).to eq(200)
        expect(json_main.size).to eq(1)
      end

      it 'Show blank list of datasets for not existing app' do
        get '/datasets?app=notexisting'

        expect(status).to eq(200)
        expect(json.size).to eq(0)
      end

      it 'Show blank list of datasets for not existing app' do
        get '/datasets?app=all'

        expect(status).to eq(200)
        expect(json.size).to eq(5)
      end
    end

    context 'For specific dataset' do
      context 'Rest dataset' do
        let!(:dataset_id) { Dataset.find_by(name: 'cartodb test set').id }

        it 'Allows to access dataset details' do
          get "/datasets/#{dataset_id}"

          expect(status).to eq(200)
          expect(json['attributes']['name']).to          eq('cartodb test set')
          expect(json['attributes']['provider']).to      eq('cartodb')
          expect(json['attributes']['format']).to        eq('JSON')
          expect(json['attributes']['connector_url']).to be_present
          expect(json['attributes']['data_path']).to     be_present
          expect(json['attributes']['table_name']).to    be_present
        end

        it 'Allows to create rest dataset without tags' do
          post '/datasets', params: {"dataset": {"connector_provider": "cartodb", "table_name": "public.carts_test_endoint",
                                                 "connector_url": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint",
                                                 "dataset_attributes": {"name": "Carto test api", "format": 0, "data_path": "rows", "attributes_path": "fields"}}}

          expect(status).to eq(201)
          expect(json['attributes']['name']).not_to      be_nil
          expect(json['attributes']['provider']).to      eq('cartodb')
          expect(json['attributes']['format']).to        be_present
          expect(json['attributes']['connector_url']).to be_present
          expect(json['attributes']['data_path']).to     be_present
          expect(json['attributes']['table_name']).to    be_present
          expect(json['attributes']['tags']).to          be_empty
        end

        it 'Allows to create rest dataset with tags' do
          post '/datasets', params: {"dataset": {"connector_provider": "cartodb", "table_name": "public.carts_test_endoint",
                                                 "connector_url": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint",
                                                 "dataset_attributes": {"name": "Carto test api", "format": 0, "data_path": "rows", "attributes_path": "fields",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"]}}}

          expect(status).to eq(201)
          expect(json['attributes']['name']).not_to      be_nil
          expect(json['attributes']['provider']).to      eq('cartodb')
          expect(json['attributes']['format']).to        be_present
          expect(json['attributes']['connector_url']).to be_present
          expect(json['attributes']['data_path']).to     be_present
          expect(json['attributes']['table_name']).to    be_present
          expect(json['attributes']['tags']).to          eq(["tag1", "tag2"])
        end

        it 'Allows to create rest dataset without tags and only required attributes' do
          post '/datasets', params: {"dataset": {"connector_provider": "cartodb",
                                                 "connector_url": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                 "dataset_attributes": {"name": "Carto test api"}}}

          expect(status).to eq(201)
          expect(json['attributes']['name']).not_to       be_nil
          expect(json['attributes']['provider']).to       eq('cartodb')
          expect(json['attributes']['format']).to         be_present
          expect(json['attributes']['connector_url']).to  be_present
          expect(json['attributes']['data_path']).not_to  be_present
          expect(json['attributes']['table_name']).to     eq('cait_2_0_country_ghg_emissions_filtered')
        end

        it 'Allows to update dataset' do
          put "/datasets/#{dataset_id}", params: {"dataset": {"dataset_attributes": {"name": "Carto test api update"},
                                                  "data": [{"cartodb_id": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                           {"cartodb_id": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json['attributes']['name']).to         eq('Carto test api update')
          expect(json['attributes']['provider']).not_to be_nil
          expect(json['attributes']['format']).to       be_present
          expect(json['attributes']['tags']).to         eq(["tag1", "tag3", "tag2"])
        end

        it 'Allows to add tags to existing dataset' do
          put "/datasets/#{dataset_id}", params: {"dataset": {"dataset_attributes": {"tags": ["tag1", "tag1", "Tag1", "tag2"]}}}

          expect(status).to eq(200)
          expect(json['attributes']['tags']).to eq(["tag1", "tag2"])
        end

        it 'Allows to add layers to existing dataset' do
          put "/datasets/#{dataset_id}/layer", params: {"dataset": {"dataset_attributes": {"layer_info": {"application": "wrw", "default": true, "layer_id": "b9ff59c8-8756-4dca-b6c3-02740a54e30l"}}}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset layer info update in progress')
          expect(Dataset.find(dataset_id).layer_info.size).to eq(2)
        end

        it 'Allows to add layers to existing dataset' do
          put "/datasets/#{dataset_id}/layer", params: {"dataset": {"dataset_attributes": {"layer_info": {"application": "wrw", "default": true, "layer_id": "b9ff59c8-8756-4dca-b6c3-02740a54e30m"}}}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset layer info update in progress')
          expect(Dataset.find(dataset_id).layer_info.size).to eq(1)
          expect(Dataset.find(dataset_id).layer_info[0]['default']).to eq('true')
        end

        it 'Allows to delete dataset' do
          delete "/datasets/#{dataset_id}"

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset would be deleted!')
        end

        it 'Allows to create rest dataset for arcgis with tags' do
          post '/datasets', params: {"dataset": {"connector_provider": "featureservice",
                                                 "connector_url": "https://services.arcgis.com/uDTUpUPbk8X8mXwl/arcgis/rest/services/Public_Schools_in_Onondaga_County/FeatureServer/0?f=json",
                                                 "dataset_attributes": {"name": "arcgis test api", "format": 0, "data_path": "features", "attributes_path": "fields",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"]}}}

          expect(status).to eq(201)
          expect(json['attributes']['name']).not_to      be_nil
          expect(json['attributes']['provider']).to      eq('featureservice')
          expect(json['attributes']['format']).to        be_present
          expect(json['attributes']['connector_url']).to be_present
          expect(json['attributes']['data_path']).to     be_present
          expect(json['attributes']['tags']).to          eq(["tag1", "tag2"])
        end

        it 'Do not allow to overwrite not a json dataset' do
          post "/datasets/#{dataset_id}/data-overwrite", params: {"dataset": {"data": [
                                                                             {"cartodb_id": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                                             {"cartodb_id": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq("Not a fuction")
        end
      end

      context 'Json dataset' do
        let!(:dataset_id)        { Dataset.find_by(name: 'Json test set').id   }
        let!(:locked_dataset_id) { Dataset.find_by(name: 'Json test set 2').id }

        it 'Allows to update dataset' do
          put "/datasets/#{dataset_id}", params: {"dataset": {"dataset_attributes": {"name": "Json test api update"},
                                                  "connector_url": "http://test.qwerty",
                                                  "data": [{"cartodb_id": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                           {"cartodb_id": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json['attributes']['name']).to eq('Json test api update')
        end

        it 'Allows to create json dataset with tags' do
          post '/datasets', params: {"dataset": {
                                      "connector_type": "json",
                                      "connector_provider": "rwjson",
                                      "dataset_attributes": {"name": "Json test api", "format": 0, "tags": ["tag1", "tag1", "Tag1", "tag2"]},
                                      "data": [
                                        {"cartodb_id": 1,"iso": "BRA","name": "Brazil","year": "2012","population": 218613196},
                                        {"cartodb_id": 5,"iso": "BRA","name": "Brazil","year": "2015","population": 198739269},
                                        {"cartodb_id": 7,"iso": "BRA","name": "Brazil","year": "2010","population": 178865342}
                                      ],
                                      "data_attributes": {"iso": {"type": "string"} }
                                    }}

          expect(status).to eq(201)
          expect(json['attributes']['name']).to     eq('Json test api')
          expect(json['attributes']['provider']).to eq('rwjson')
          expect(json['attributes']['format']).to   be_present
          expect(json['attributes']['tags']).to     eq(["tag1", "tag2"])
        end

        it 'Allows to create json dataset from json url' do
          post '/datasets', params: {"dataset": {
                                      "connector_type": "json",
                                      "dataset_attributes": {"name": "Json external data test api", "data_path": "data"},
                                      "connector_url": "http://api.resourcewatch.org:81/query/3db3a4cd-f654-41bd-b26b-8c865f02f933?limit=10"
                                    }}

          expect(status).to eq(201)
          expect(json['attributes']['name']).to     eq('Json external data test api')
          expect(json['attributes']['provider']).to eq('rwjson')
        end

        it 'Allows to delete dataset' do
          delete "/datasets/#{dataset_id}"

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset would be deleted!')
        end

        it 'Allows to update dataset data' do
          post "/datasets/#{dataset_id}/data", params: {"dataset": {"data": [
                                                       {"cartodb_id": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                       {"cartodb_id": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset data update in progress')
        end

        it 'Allows to overwrite json dataset data' do
          post "/datasets/#{dataset_id}/data-overwrite", params: {"dataset": {"data": [
                                                                                {"cartodb_id": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                                                {"cartodb_id": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset data update in progress')
        end

        it 'Do not allow to overwrite locked json dataset data' do
          post "/datasets/#{locked_dataset_id}/data-overwrite", params: {"dataset": {"data": [
                                                                                       {"cartodb_id": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                                                       {"cartodb_id": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq("Dataset data is locked and can't be updated")
        end

        it 'Allows to delete dataset data' do
          delete "/datasets/#{dataset_id}/data/e3b4acca-d34d-46b9-833f-08c3a14fe2f5"

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset data deleted')
        end
      end

      context 'Doc dataset' do
        it 'Allows to create csv dataset with tags' do
          post '/datasets', params: {"dataset": {"connector_type": "document",
                                                 "connector_url": "https://test-csv.csv",
                                                 "table_name": "my_table",
                                                 "dataset_attributes": {"name": "csv file", "tags": ["tag1", "tag1", "Tag1", "tag2"]}}}

          expect(status).to eq(201)
          expect(json['attributes']['name']).not_to      be_nil
          expect(json['attributes']['provider']).to      eq('csv')
          expect(json['attributes']['format']).to        be_present
          expect(json['attributes']['connector_url']).to be_present
          expect(json['attributes']['tags']).to          eq(["tag1", "tag2"])
        end
      end

      context 'Wms dataset' do
        it 'Allows to create wms dataset with tags' do
          post '/datasets', params: {"dataset": {"connector_type": "wms", "dataset_attributes": {"name": "Wms test api",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"]}}}

          expect(status).to eq(201)
          expect(json['attributes']['name']).not_to          be_nil
          expect(json['attributes']['provider']).to          eq('wms')
          expect(json['attributes']['format']).to            be_present
          expect(json['attributes']['connector_url']).not_to be_present
          expect(json['attributes']['data_path']).not_to     be_present
          expect(json['attributes']['table_name']).not_to    be_present
          expect(json['attributes']['tags']).to              eq(["tag1", "tag2"])
        end
      end
    end
  end
end
