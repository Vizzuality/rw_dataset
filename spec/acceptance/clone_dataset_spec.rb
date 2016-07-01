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
          post "/datasets/#{dataset_id}/clone", params: {"dataset": {"dataset_url": "http://ec2-52-23-163-254.compute-1.amazonaws.com/query/4?select[]=iso,population&filter=(iso=='ESP','AUS')&aggr_by[]=iso&aggr_func=sum&order[]=-iso"} }

          expect(status).to eq(201)
          expect(json['name']).to                         match('_copy')
          expect(json['provider']).to                     eq('rwjson')
          expect(json['cloned_host']['host_type']).to     eq('RestConnector')
          expect(json['cloned_host']['host_provider']).to eq('cartodb')
        end
      end

      context 'Json dataset' do
        let!(:dataset_id) { Dataset.find_by(name: 'Json test set').id }

        it 'Allows to clone json dataset' do
          post "/datasets/#{dataset_id}/clone", params: {"dataset": {"dataset_url": "http://ec2-52-23-163-254.compute-1.amazonaws.com/query/4?select[]=iso,population&filter=(iso=='ESP','AUS')&aggr_by[]=iso&aggr_func=sum&order[]=-iso"} }

          expect(status).to eq(201)
          expect(json['name']).to                         match('_copy')
          expect(json['provider']).to                     eq('rwjson')
          expect(json['cloned_host']['host_type']).to     eq('JsonConnector')
          expect(json['cloned_host']['host_provider']).to eq('rwjson')
        end
      end
    end
  end
end
