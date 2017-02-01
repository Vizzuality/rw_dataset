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

      it 'Allows to access datasets list filtering by type rest' do
        get '/dataset?connectorType=rest'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(8)
        expect(dataset['provider']).to      eq('gee')
        expect(dataset['connectorType']).to eq('rest')
      end

      it 'Allows to access datasets list filtering by type json' do
        get '/dataset?connectorType=json'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(2)
        expect(dataset['provider']).to      eq('rwjson')
        expect(dataset['connectorType']).to eq('json')
      end

      it 'Allows to access datasets list filtering by provider rwjson' do
        get '/dataset?provider=rwjson'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(2)
        expect(dataset['provider']).to      eq('rwjson')
        expect(dataset['connectorType']).to eq('json')
      end

      it 'Allows to access datasets list filtering by provider cartodb' do
        get '/dataset?provider=cartodb'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(5)
        expect(dataset['provider']).to      eq('cartodb')
        expect(dataset['connectorType']).to eq('rest')
      end

      it 'Allows to access datasets list filtering by provider featureservice' do
        get '/dataset?provider=featureservice'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(2)
        expect(dataset['provider']).to      eq('featureservice')
        expect(dataset['connectorType']).to eq('rest')
      end

      it 'Allows to access datasets list filtering by provider gee' do
        get '/dataset?provider=gee'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(1)
        expect(dataset['provider']).to      eq('gee')
        expect(dataset['connectorType']).to eq('rest')
      end

      it 'Allows to access datasets list filtering by provider csv' do
        get '/dataset?provider=csv'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(1)
        expect(dataset['provider']).to      eq('csv')
        expect(dataset['connectorType']).to eq('document')
      end

      it 'Allows to access datasets list filtering by provider wms' do
        get '/dataset?provider=wms'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(1)
        expect(dataset['provider']).to      eq('wms')
        expect(dataset['connectorType']).to eq('wms')
      end

      it 'Allows to access datasets list filtering by non existing provider' do
        get '/dataset?provider=nonexisting'

        expect(status).to eq(200)
        expect(json.length).to eq(0)
      end

      it 'Allows to access datasets list filtering by all providers' do
        get '/dataset?provider=all'

        expect(status).to eq(200)
        expect(json.length).to eq(10)
      end

      it 'Allows to access datasets list filtering by type wms' do
        get '/dataset?connectorType=wms'

        dataset = json[0]['attributes']
        expect(status).to eq(200)
        expect(json.length).to              eq(1)
        expect(dataset['provider']).to      eq('wms')
        expect(dataset['connectorType']).to eq('wms')
      end

      it 'Show list of all datasets using status filter all' do
        get '/dataset?status=all'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
      end

      it 'Show list of datasets with pending status' do
        get '/dataset?status=pending'

        expect(status).to eq(200)
        expect(json.size).to eq(1)
      end

      it 'Show list of datasets with active status' do
        get '/dataset?status=active'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
      end

      it 'Show list of datasets with disabled status' do
        get '/dataset?status=disabled'

        expect(status).to eq(200)
        expect(json.size).to eq(1)
      end

      it 'Show list of datasets for app GFW' do
        get '/dataset?app=GFw'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
        expect(json[0]['attributes']['application'][0]).to eq('gfw')
      end

      it 'Show list of datasets for app WRW' do
        get '/dataset?app=wrw'

        expect(status).to eq(200)
        expect(json.size).to eq(1)
      end

      it 'Show list of datasets for app WRW and GFW' do
        get '/dataset?app=wrw,gfw'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
      end

      it 'Show list of datasets for app WRW or GFW' do
        get '/dataset?app=wrw;gfw'

        expect(status).to eq(200)
        expect(json.size).to eq(1)
      end

      it 'Show blank list of datasets for not existing app' do
        get '/dataset?app=notexisting'

        expect(status).to eq(200)
        expect(json.size).to eq(0)
      end

      it 'Show list of datasets for all apps' do
        get '/dataset?app=all'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
      end

      it 'Show list of datasets for all apps and second page (for total items 13)' do
        get '/dataset?page[number]=2&page[size]=10&status=all'

        expect(status).to eq(200)
        expect(json.size).to eq(4)
      end

      it 'Show list of datasets for all apps first page' do
        get '/dataset?page[number]=1&page[size]=10&status=all'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
      end

      it 'Show list of datasets for all apps first page with per pege param' do
        get '/dataset?page[number]=1&page[size]=100&status=all'

        expect(status).to eq(200)
        expect(json.size).to eq(14)
      end

      it 'Show list of layers for all apps sort by name' do
        get '/dataset?sort=name&status=all'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
        expect(json[0]['attributes']['name']).to eq('arcgis test set')
      end

      it 'Show list of datasets for all apps sort by name DESC' do
        get '/dataset?sort=-name&status=all'

        expect(status).to eq(200)
        expect(json.size).to eq(10)
        expect(json[0]['attributes']['name']).to eq('Wms test set 1')
      end

      context "Filter on ids" do
        let!(:id_1) { Dataset.find_by(name: 'cartodb test set').id }
        let!(:id_2) { Dataset.find_by(name: 'arcgis test set').id  }

        it 'Show list of datasets for specific ids' do
          get "/dataset?ids=#{id_1},#{id_2}"

          expect(status).to eq(200)
          expect(json.size).to eq(2)
        end
      end
    end
  end
end
