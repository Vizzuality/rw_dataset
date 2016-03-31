require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :datasets

    context 'For specific dataset' do
      let!(:dataset) { RestConnector.first }

      it 'Allows to access dataset details' do
        get "/datasets/#{dataset.id}"

        data = json

        expect(status).to eq(200)
        expect(data['connector_name']).not_to be_nil
        expect(data['provider']).not_to       be_nil
        expect(data['format']).to             be_present
        expect(data['dataset_meta']['connector_url']).to  be_present
        expect(data['dataset_meta']['connector_path']).to be_present
        expect(data['dataset_meta']['table_name']).to     be_present
      end

      it 'Allows to create dataset' do
        post "/datasets", params: {"dataset": {"connector_name": "Carto test api", "connector_url": "https://rschumann.cartodb.com/api/v2/sql?q=select%20*%20from%20public.carts_test_endoint", "connector_format": 0, "connector_provider": 0, "connector_path": "rows", "attributes_path": "fields", "dataset_attributes": {"table_name": "public.carts_test_endoint"}}}

        data = json

        expect(status).to eq(201)
        expect(data['connector_name']).not_to be_nil
        expect(data['provider']).not_to       be_nil
        expect(data['format']).to             be_present
        expect(data['dataset_meta']['connector_url']).to  be_present
        expect(data['dataset_meta']['connector_path']).to be_present
        expect(data['dataset_meta']['table_name']).to     be_present
      end

      it 'Allows to update dataset' do
        put "/datasets/#{dataset.id}", params: {"dataset": {"connector_name": "Carto test api update"}}

        data = json

        expect(status).to eq(201)
        expect(data['connector_name']).to eq('Carto test api update')
        expect(data['provider']).not_to       be_nil
        expect(data['format']).to             be_present
        expect(data['dataset_meta']['connector_url']).to  be_present
        expect(data['dataset_meta']['connector_path']).to be_present
        expect(data['dataset_meta']['table_name']).to     be_present
      end

      it 'Allows to delete dataset' do
        delete "/datasets/#{dataset.id}"

        data = json

        expect(status).to eq(200)
        expect(json['message']).to eq('Dataset deleted')
      end
    end
  end
end
