require 'acceptance_helper'

module V1
  describe 'Clone Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :datasets

    context 'For specific dataset' do
      context 'Rest dataset' do
        let!(:dataset_id) { Dataset.find_by(name: 'cartodb test set').id }

        it 'Allows to clone cartodb dataset' do
          post "/datasets/#{dataset_id}/clone", params: {"dataset": {"datasetUrl": "http://ec2-52-23-163-254.compute-1.amazonaws.com/query/4?select[]=iso,population&filter=(iso=='ESP','AUS')&aggrBy[]=iso&aggrFunc=sum&order[]=-iso"} }

          expect(status).to eq(201)
          expect(json_attr['name']).to                       match('_copy')
          expect(json_attr['provider']).to                   eq('rwjson')
          expect(json_attr['clonedHost']['hostType']).to     eq('RestConnector')
          expect(json_attr['clonedHost']['hostProvider']).to eq('cartodb')
        end
      end

      context 'Json dataset' do
        let!(:dataset_id) { Dataset.find_by(name: 'Json test set').id }
        let!(:settings)   { ServiceSetting.create(name: 'api-gateway', listener: true, token: '3123123der324eewr434ewr4324', url: 'http://192.168.99.100:8000') }

        it 'Allows to clone json dataset' do
          post "/datasets/#{dataset_id}/clone", params: {"dataset": {"datasetUrl": "http://192.168.99.100:8000/query/4?select[]=iso,population&filter=(iso=='ESP','AUS')&aggrBy[]=iso&aggrFunc=sum&order[]=-iso"} }

          expect(status).to eq(201)
          expect(json_attr['name']).to                       match('_copy')
          expect(json_attr['provider']).to                   eq('rwjson')
          expect(json_attr['clonedHost']['hostType']).to     eq('JsonConnector')
          expect(json_attr['clonedHost']['hostProvider']).to eq('rwjson')
          expect(json_attr['clonedHost']['hostUrl']).to      eq("http://192.168.99.100:8000/query/4?select[]=iso,population&filter=(iso=='ESP','AUS')&aggrBy[]=iso&aggrFunc=sum&order[]=-iso")
        end
      end
    end
  end
end
