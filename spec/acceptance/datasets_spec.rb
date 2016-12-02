require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :wms_connectors
    fixtures :doc_connectors
    fixtures :datasets

    context 'For datasets list', redis: true do
      it 'Allows to access datasets list without filtering' do
        get '/dataset'

        dataset_json = json[0]['attributes']
        dataset_rest = json[3]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(10)
        expect(dataset_json['provider']).to eq('rwjson')
        expect(dataset_rest['provider']).to eq('cartodb')
      end
    end

    context 'For specific dataset' do
      context 'Rest dataset' do
        let!(:dataset_id)    { Dataset.find_by(name: 'cartodb test set').id }
        let!(:dataset_fs_id) { Dataset.find_by(name: 'arcgis test set').id }

        it 'Allows to access dataset details' do
          get "/dataset/#{dataset_id}"

          expect(status).to eq(200)
          expect(json_attr['name']).to         eq('cartodb test set')
          expect(json_attr['provider']).to     eq('cartodb')
          expect(json_attr['connectorUrl']).to be_present
          expect(json_attr['dataPath']).to     be_present
          expect(json_attr['tableName']).to    be_present
        end

        it 'Allows to create rest dataset without tags' do
          post '/dataset', params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "cartodb", "tableName": "public.carts_test_endoint", "application": ["gfw"],
                                                 "connectorUrl": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint",
                                                 "name": "Carto test api", "format": 0, "data_path": "rows", "attributesPath": "fields"}}

          expect(status).to eq(201)
          expect(json_attr['name']).not_to     be_nil
          expect(json_attr['provider']).to     eq('cartodb')
          expect(json_attr['connectorUrl']).to be_present
          expect(json_attr['dataPath']).to     be_present
          expect(json_attr['tableName']).to    be_present
          expect(json_attr['tags']).to         be_empty
        end

        it 'Allows to create rest dataset by a admin with tags and topics' do
          post '/dataset', params: {"loggedUser": {"role": "admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "cartodb", "tableName": "public.carts_test_endoint", "application": ["gfw"],
                                                 "connectorUrl": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint",
                                                 "name": "mydataset(prep)", "format": 0, "data_path": "rows", "attributesPath": "fields",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"], "topics": ["topic1", "topic1", "Topic1", "topic2"]}
                                    }

          expect(status).to eq(201)
          expect(json_attr['name']).to         eq('mydataset(prep)')
          expect(json_attr['provider']).to     eq('cartodb')
          expect(json_attr['connectorUrl']).to be_present
          expect(json_attr['dataPath']).to     be_present
          expect(json_attr['tableName']).to    be_present
          expect(json_attr['tags']).to         eq(['tag1', 'tag2'])
          expect(json_attr['topics']).to       eq(['topic1', 'topic2'])
          expect(json_attr['userId']).to       eq('3242-32442-432')
        end

        it 'Allows to create rest dataset by a admin with tags and topics extracting table name from url' do
          post '/dataset', params: {"loggedUser": {"role": "admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "cartodb", "application": ["gfw"],
                                                 "connectorUrl": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint",
                                                 "name": "Carto test api", "format": 0, "data_path": "rows", "attributesPath": "fields",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"], "topics": ["topic1", "topic1", "Topic1", "topic2"]}
                                    }

          expect(status).to eq(201)
          expect(json_attr['name']).not_to     be_nil
          expect(json_attr['provider']).to     eq('cartodb')
          expect(json_attr['connectorUrl']).to be_present
          expect(json_attr['dataPath']).to     be_present
          expect(json_attr['tableName']).to    eq('public.carts_test_endoint')
          expect(json_attr['tags']).to         eq(['tag1', 'tag2'])
          expect(json_attr['topics']).to       eq(['topic1', 'topic2'])
          expect(json_attr['userId']).to       eq('3242-32442-432')
        end

        it 'Allows to create rest dataset owned by an manager, without tags and only required attributes' do
          post '/dataset', params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "cartodb", "application": ["gfw"],
                                                 "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                 "name": "Carto test api"}}

          expect(status).to eq(201)
          expect(json_attr['name']).not_to     be_nil
          expect(json_attr['provider']).to     eq('cartodb')
          expect(json_attr['connectorUrl']).to be_present
          expect(json_attr['dataPath']).not_to be_present
          expect(json_attr['tableName']).to    eq('cait_2_0_country_ghg_emissions_filtered')
        end

        it 'Do not allows to create rest dataset by an user' do
          post '/dataset', params: {"loggedUser": {"role": "user", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "cartodb", "application": ["gfw"],
                                                 "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                 "name": "Carto test api"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized!')
        end

        it 'Do not allows to create rest dataset by manager user if not in apps' do
          post '/dataset', params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "cartodb", "application": ["wri", "gfw"],
                                                 "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                 "name": "Carto test api"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized!')
        end

        it 'Do not allows to create rest dataset by admin user if wrong attribute' do
          post '/dataset', params: {"loggedUser": {"role": "admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "cartodb", "application": ["gfw"],
                                                 "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                 "names": "Carto test api"}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq("unknown attribute 'names' for RestConnector.")
        end

        it 'Allows to update rest dataset by admin user if in apps' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw", "wrw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"application": ["prep", "gfw"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "name": "Carto test api"}}

          expect(status).to eq(200)
          expect(json_attr['name']).to         eq('Carto test api')
          expect(json_attr['provider']).not_to be_nil
          expect(json_attr['application']).to  eq(["prep", "gfw"])
        end

        it 'Do not allows to update rest dataset by admin user if not valid attribute' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw", "wrw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"applications": ["prep", "gfw"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "name": "Carto test api"}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq("unknown attribute 'applications' for RestConnector.")
        end

        it 'Do not allow to update rest dataset by admin user if not in apps' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"application": ["prep", "gfw"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "name": "Carto test api"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized!')
        end

        it 'Do not allow to update user_id on dataset if user is an admin' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"name": "Carto test api update", "user_id": "123"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized to update UserId')
        end

        it 'Do not allow to update user_id on dataset if user is a manager' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"name": "Carto test api update", "user_id": "123"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized to update UserId')
        end

        it 'Allows to update user_id on dataset if user is a supermanager' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "superadmin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"name": "Carto test api update", "user_id": "123"}}

          expect(status).to eq(200)
          expect(json_attr['name']).to   eq('Carto test api update')
          expect(json_attr['userId']).to eq('123')
        end

        it 'Do not allows to update rest dataset by admin user if not in apps' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"application": ["testapp"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "name": "Carto test api"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized!')
        end

        it 'Allows to update rest dataset by superadmin user' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Superadmin", "extraUserData": { }, "id": "3242-32442-436"},
                                                   "dataset": {"application": ["testapp"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               }}

          expect(status).to eq(200)
          expect(json_attr['name']).to         eq('cartodb test set')
          expect(json_attr['provider']).not_to be_nil
          expect(json_attr['application']).to  eq(["testapp"])
        end

        it 'Allows to update rest dataset by superadmin user' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Superadmin", "extraUserData": { }, "id": "3242-32442-436"},
                                                   "dataset": {"application": ["testapp"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "name": "Carto test api"}}

          expect(status).to eq(200)
          expect(json_attr['name']).to          eq('Carto test api')
          expect(json_attr['provider']).not_to  be_nil
          expect(json_attr['application']).to   eq(["testapp"])
          expect(json_attr['provider']).to      eq('cartodb')
          expect(json_attr['connectorType']).to eq('rest')
          expect(json_attr['tableName']).to     eq('cait_2_0_country_ghg_emissions_filtered')
        end

        it 'Allows to update rest dataset of type featureservice by superadmin user and generate table name' do
          patch "/dataset/#{dataset_fs_id}", params: {"loggedUser": {"role": "Superadmin", "extraUserData": { }, "id": "3242-32442-436"},
                                                      "dataset": {"application": ["testapp"],
                                                                  "connectorUrl": "https://services.arcgis.com/uDTUpUPbk8X8mXwl/arcgis/rest/services/Public_Schools_in_Onondaga_County/FeatureServer/0?f=json",
                                                                  "name": "Arcgis test api",
                                                                  "data_path": "features", "attributesPath": "fields"}}

          expect(status).to eq(200)
          expect(json_attr['name']).to          eq('Arcgis test api')
          expect(json_attr['provider']).not_to  be_nil
          expect(json_attr['application']).to   eq(["testapp"])
          expect(json_attr['provider']).to      eq('featureservice')
          expect(json_attr['connectorType']).to eq('rest')
          expect(json_attr['tableName']).to     eq('Public_Schools_in_Onondaga_County')
        end

        it 'Do not allows to update rest dataset by superadmin user if table_name, provider or connector_type present' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Superadmin", "extraUserData": { }, "id": "3242-32442-436"},
                                                   "dataset": {"provider": "featureservice", "application": ["testapp"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "tableName": "not_valid",
                                                               "connectorType": "not_valid",
                                                               "name": "Carto test api"}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq('The attributes: tableName, connectorType and provider can not be changed')
        end

        it 'Do not allows to update rest dataset by admin user if not in apps check begore table_name, provider or connector_type not allowed' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "admin", "extraUserData": { "apps": ["blablaapp"] }, "id": "3242-32442-436"},
                                                   "dataset": {"provider": "featureservice", "application": ["testapp"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "tableName": "not_valid",
                                                               "connectorType": "not_valid",
                                                               "name": "Carto test api"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized!')
        end

        it 'Allows to update rest dataset by admin user if in apps changing apps' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw", "wrw", "prep","testapp"] }, "id": "3242-32442-436"},
                                                   "dataset": {"application": ["gfw", "wrw" ,"testapp"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "name": "Carto test api additional apps"}}

          expect(status).to eq(200)
          expect(json_attr['name']).to         eq('Carto test api additional apps')
          expect(json_attr['provider']).not_to be_nil
          expect(json_attr['application']).to  eq(["gfw", "wrw", "testapp"])
        end

        it 'Do not allows to update rest dataset by admin user if not in apps' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw","prep"] }, "id": "3242-32442-436"},
                                                   "dataset": {"application": ["wri", "gfw"],
                                                               "connectorUrl": "https://insights.cartodb.com/tables/cait_2_0_country_ghg_emissions_filtered/public/map",
                                                               "name": "Carto test api"}}

          expect(status).to eq(401)
          expect(json_main['errors'][0]['title']).to eq('Not authorized!')
        end

        it 'Allows to update dataset' do
          put "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                                  "dataset": {"name": "Carto test api update",
                                                  "data": [{"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                           {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json_attr['name']).to         eq('Carto test api update')
          expect(json_attr['provider']).not_to be_nil
          expect(json_attr['tags']).to         eq(["tag1", "tag3", "tag2"])
        end

        it 'Allows to update dataset' do
          put "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw","wrw","test"] }, "id": "3242-32442-432"},
                                                  "dataset": {"name": "Carto test api update",
                                                  "data": [{"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                           {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json_attr['name']).to         eq('Carto test api update')
          expect(json_attr['provider']).not_to be_nil
          expect(json_attr['tags']).to         eq(["tag1", "tag3", "tag2"])
        end

        it 'Allows to update dataset' do
          put "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "Admin", "extraUserData": { "apps": ["gfw"] }, "id": "3242-32442-432"},
                                                  "dataset": {"name": "Carto test api update",
                                                  "data": [{"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                           {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json_attr['name']).to         eq('Carto test api update')
          expect(json_attr['provider']).not_to be_nil
          expect(json_attr['tags']).to         eq(["tag1", "tag3", "tag2"])
        end

        it 'Allows to add tags to existing dataset' do
          put "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                                 "dataset": {"tags": ["tag1", "tag1", "Tag1", "tag2"]}}

          expect(status).to eq(200)
          expect(json_attr['tags']).to eq(["tag1", "tag2"])
        end

        it 'Allows to delete dataset' do
          delete "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset would be deleted!')
        end

        it 'Allows to create rest dataset for arcgis with tags' do
          post '/dataset', params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "featureservice", "application": ["gfw"],
                                                 "connectorUrl": "https://services.arcgis.com/uDTUpUPbk8X8mXwl/arcgis/rest/services/Public_Schools_in_Onondaga_County/FeatureServer/0?f=json",
                                                 "name": "arcgis test api", "format": 0, "data_path": "features", "attributesPath": "fields",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"]}}

          expect(status).to eq(201)
          expect(json_attr['name']).not_to     be_nil
          expect(json_attr['provider']).to     eq('featureservice')
          expect(json_attr['connectorUrl']).to be_present
          expect(json_attr['dataPath']).to     be_present
          expect(json_attr['tags']).to         eq(["tag1", "tag2"])
        end

        it 'Validation of name' do
          post '/dataset', params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "featureservice", "application": ["gfw"],
                                                 "connectorUrl": "https://services.arcgis.com/uDTUpUPbk8X8mXwl/arcgis/rest/services/Public_Schools_in_Onondaga_County/FeatureServer/0?f=json",
                                                 "name": ["a", "b"], "format": 0, "data_path": "features", "attributesPath": "fields",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"]}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq(["Dataset name must be a valid string"])
        end

        it 'Do not allow to overwrite not a json dataset' do
          post "/dataset/#{dataset_id}/data-overwrite", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                                                 "dataset": {"data": [
                                                                             {"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                                             {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq("Not a fuction")
        end
      end

      context 'Json dataset' do
        let!(:dataset_id)        { Dataset.find_by(name: 'Json test set').id   }
        let!(:locked_dataset_id) { Dataset.find_by(name: 'Json test set 2').id }

        it 'Allows to update dataset' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                                   "dataset": {"name": "Json test api update with patch"},
                                                   "connectorUrl": "http://test.qwerty",
                                                   "data": [{"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                            {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}

          expect(status).to eq(200)
          expect(json_attr['name']).to eq('Json test api update with patch')
        end

        it 'Allows to update dataset from internal microservice' do
          patch "/dataset/#{dataset_id}", params: {"loggedUser": {"id": "microservice"},
                                                   "dataset": {"status": 1}}

          expect(status).to eq(200)
          expect(Dataset.find(dataset_id).status).to  eq(1)
          expect(Dataset.find(dataset_id).user_id).to eq('3242-32442-432')
        end

        it 'Allows to create json dataset with tags' do
          post '/dataset', params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                    "dataset": {
                                      "connectorType": "json", "application": ["gfw"],
                                      "provider": "rwjson",
                                      "name": "Json test api", "format": 0, "tags": ["tag1", "tag1", "Tag1", "tag2"],
                                      "data": [
                                        {"cartodbId": 1,"iso": "BRA","name": "Brazil","year": "2012","population": 218613196},
                                        {"cartodbId": 5,"iso": "BRA","name": "Brazil","year": "2015","population": 198739269},
                                        {"cartodbId": 7,"iso": "BRA","name": "Brazil","year": "2010","population": 178865342}
                                      ],
                                      "data_attributes": {"iso": {"type": "string"} }
                                    }}

          expect(status).to eq(201)
          expect(json_attr['name']).to     eq('Json test api')
          expect(json_attr['provider']).to eq('rwjson')
          expect(json_attr['tags']).to     eq(["tag1", "tag2"])
        end

        it 'Allows to create json dataset from json url' do
          post '/dataset', params: {"loggedUser": {"role": "Manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                    "dataset": {
                                      "connectorType": "json", "application": ["gfw"],
                                      "name": "Json external data test api", "dataPath": "data",
                                      "connectorUrl": "http://api.resourcewatch.org:81/query/3db3a4cd-f654-41bd-b26b-8c865f02f933?limit=10"
                                    }}

          expect(status).to eq(201)
          expect(json_attr['name']).to     eq('Json external data test api')
          expect(json_attr['provider']).to eq('rwjson')
        end

        it 'Allows to delete dataset' do
          delete "/dataset/#{dataset_id}", params: {"loggedUser": "{\"role\": \"manager\", \"extraUserData\": { \"apps\": [\"gfw\",\"wrw\"] }, \"id\": \"3242-32442-432\"}"}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset would be deleted!')
        end

        it 'Allows to update dataset data' do
          post "/dataset/#{dataset_id}/data", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["Gfw", "gfw","wrw"] }, "id": "3242-32442-432"},
                                                       "dataset": {"data": [
                                                       {"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                       {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset data update in progress')
        end

        it 'Allows to overwrite json dataset data' do
          post "/dataset/#{dataset_id}/data-overwrite", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                                                 "dataset": {"data": [
                                                                                {"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                                                {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset data update in progress')
        end

        it 'Do not allow to overwrite locked json dataset data' do
          post "/dataset/#{locked_dataset_id}/data-overwrite", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                                                        "dataset": {"data": [
                                                                                       {"cartodbId": 10,"iso": "BRA","name": "Brazil","year": "2016","population": 999999},
                                                                                       {"cartodbId": 11,"iso": "BRA","name": "Brazil","year": "2016","population": 888888}]}}

          expect(status).to eq(422)
          expect(json_main['errors'][0]['title']).to eq("Dataset data is locked and can't be updated")
        end

        it 'Allows to delete dataset data' do
          delete "/dataset/#{dataset_id}/data/e3b4acca-d34d-46b9-833f-08c3a14fe2f5", params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"}}

          expect(status).to eq(200)
          expect(json_main['message']).to eq('Dataset data deleted')
        end
      end

      context 'Doc dataset' do
        let!(:csv_dataset_id) { Dataset.find_by(name: 'Csv test set 1').id }

        it 'Allows to create csv dataset with tags' do
          post '/dataset', params: {"loggedUser": {"role": "Manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                    "dataset": {"connectorType": "document", "application": ["gfw"],
                                                 "connectorUrl": "https://test-csv.csv",
                                                 "tableName": "my_table",
                                                 "polygon": "Madrid alcobendas",
                                                 "point": { "lat": "23233233", "long": "66565676" },
                                                 "name": "csv file", "tags": ["tag1", "tag1", "Tag1", "tag2"]}}

          expect(status).to eq(201)
          expect(json_attr['name']).not_to     be_nil
          expect(json_attr['provider']).to     eq('csv')
          expect(json_attr['connectorUrl']).to be_present
          expect(json_attr['tags']).to         eq(["tag1", "tag2"])
        end

        it 'Allows to overwrite csv dataset data' do
          post "/dataset/#{csv_dataset_id}/data-overwrite", params: {"loggedUser": {"role": "Manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                                                     "dataset": {"connector_url": "http://new-url.org",
                                                                                 "polygon": "Madrid alcobendas",
                                                                                 "point": { "lat": "23233233", "long": "66565676" }}}

          expect(status).to eq(200)
          expect(DocConnector.find(csv_dataset_id).connector_url).to  eq('http://new-url.org')
          expect(DocConnector.find(csv_dataset_id).table_name).not_to be_present
          expect(json_main['message']).to                             eq('Dataset data update in progress')
        end

        it 'Allows to update dataset table_name from internal microservice' do
          patch "/dataset/#{csv_dataset_id}", params: {"loggedUser": {"id": "microservice"},
                                                       "dataset": {"status": 1, "tableName": "test_table_name"}}

          expect(status).to eq(200)
          expect(Dataset.find(csv_dataset_id).status).to          eq(1)
          expect(Dataset.find(csv_dataset_id).user_id).to         eq('3242-32442-432')
          expect(DocConnector.find(csv_dataset_id).table_name).to eq('test_table_name')
        end
      end

      context 'Find datasets by name' do
        it 'Allows to find datasets by name' do
          get '/dataset?name=json test'

          expect(status).to eq(200)
          expect(json.length).to eq(2)
        end

        it 'Allows to find datasets by name' do
          get '/dataset?name=ArcGIS'

          expect(status).to eq(200)
          expect(json.length).to eq(1)
        end
      end

      context 'Find datasets by tags' do
        it 'Allows to find datasets by name' do
          get '/dataset?tags=tag1'

          expect(status).to eq(200)
          expect(json.length).to eq(3)
        end

        it 'Allows to find datasets by tags' do
          get '/dataset?tags=tag2,tag4'

          expect(status).to eq(200)
          expect(json.length).to eq(4)
        end
      end

      context 'Create dataset with valid legend' do
        it 'Allows to create dataset with valid legend' do
          post '/dataset', params: {"loggedUser": {"role": "manager", "extraUserData": { "apps": ["gfw","wrw"] }, "id": "3242-32442-432"},
                                    "dataset": {"provider": "featureservice", "application": ["gfw"],
                                                 "legend": {"long": "123", "lat": "123", "country": "pais", "region": "barrio", "date": ["start_date", "end_date"]},
                                                 "connectorUrl": "https://services.arcgis.com/uDTUpUPbk8X8mXwl/arcgis/rest/services/Public_Schools_in_Onondaga_County/FeatureServer/0?f=json",
                                                 "name": "Test dataset", "format": 0, "data_path": "features", "attributesPath": "fields",
                                                  "tags": ["tag1", "tag1", "Tag1", "tag2"]}}

          expect(status).to eq(201)
          expect(json_attr['name']).to   eq('Test dataset')
          expect(json_attr['legend']).to eq({"long" => "123", "lat" => "123", "country" => "pais", "region" => "barrio", "date" => ["start_date", "end_date"]})
        end
      end
    end
  end
end
