require 'acceptance_helper'

module V1
  describe 'Clone Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :datasets

    context 'For specific dataset' do
      it 'Allows to clone rest dataset' do
        post "/datasets/1/clone", params: {"dataset": {"dataset_url": "http://ec2-52-23-163-254.compute-1.amazonaws.com/query/4?select[]=iso,population&filter=(iso=='ESP','AUS')&aggr_by[]=iso&aggr_func=sum&order[]=-iso"} }

        data = json

        expect(status).to eq(201)
        expect(data['connector_name']).not_to be_nil
        expect(data['provider']).to           eq('RwJson')
        expect(data['format']).to             be_present
        expect(data['connector_url']).not_to  be_present
        expect(data['connector_path']).to     be_present
        expect(data['table_name']).not_to     be_present
        expect(data['data_attributes']).to    be_present
        expect(data['cloned_host']['host_type']).to eq('RestConnector')
      end

      it 'Allows to clone json dataset' do
        post "/datasets/3/clone", params: {"dataset": {"dataset_url": "http://ec2-52-23-163-254.compute-1.amazonaws.com/query/4?select[]=iso,population&filter=(iso=='ESP','AUS')&aggr_by[]=iso&aggr_func=sum&order[]=-iso"} }

        data = json

        expect(status).to eq(201)
        expect(data['connector_name']).not_to be_nil
        expect(data['provider']).to           eq('RwJson')
        expect(data['format']).to             be_present
        expect(data['connector_url']).not_to  be_present
        expect(data['connector_path']).to     be_present
        expect(data['table_name']).not_to     be_present
        expect(data['data_attributes']).to    be_present
        expect(data['cloned_host']['host_type']).to eq('JsonConnector')
      end
    end
  end
end
