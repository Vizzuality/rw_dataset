require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :wms_connectors
    fixtures :datasets

    let!(:dataset_id) { Dataset.find_by(name: 'Wms test set 1').id }

    let!(:metadata_data) {{
                           "data": [{"id": "57bc054f4f30010f00bbec73", "type": "metadata", "attributes": { "dataset": "#{dataset_id}",
                                                                                                           "application": "prep",
                                                                                                           "info": { "organization": "University of Washington/Joe Casola" }
                                                                                                         }
                           }]
                         }}

    let!(:dataset_metas) {{
                           "data": [{"id": "57bc054f4f30010f00bbec71", "type": "metadata", "attributes": { "dataset": "#{dataset_id}",
                                                                                                           "application": "prep",
                                                                                                           "info": { "organization": "University of Washington/Joe Casola" }
                                                                                                         }
                           },
                           {"id": "57bc054f4f30010f00bbec72", "type": "metadata", "attributes": { "dataset": "c547146d-de0c-47ff-a406-5125667fd5c1",
                                                                                                           "application": "prep",
                                                                                                           "info": { "organization": "University of Washington/Joe Casola" }
                                                                                                         }
                           }]
                         }}

    before(:each) do
      ServiceSetting.create(name: 'api-gateway', listener: true, token: '3123123der324eewr434ewr4324', url: 'http://192.168.99.100:8000')
    end

    context 'Populate datasets with metadata', redis: true do
      context 'datasets list' do
        before(:each) do
          stub_request(:post, "http://192.168.99.100:8000/dataset/metadata/find-by-ids").
          with(:body => "{\"ids\":[\"#{dataset_id}\"]}",
               :headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(dataset_metas), :headers => {})
        end

        it 'Show metadata for datasets' do
          get "/dataset?connector_type=wms&includes=metadata"

          dataset_json = json[0]['attributes']

          expect(status).to eq(200)
          expect(json.length).to eq(1)
          expect(dataset_json['metadata']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>"prep", "info"=>{"organization"=>"University of Washington/Joe Casola"}, "id"=>"57bc054f4f30010f00bbec71"}}])
        end
      end

      context 'specific dataset without app' do
        before(:each) do
          stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/metadata").
          with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(metadata_data), :headers => {})
        end

        it 'Show metadata for specific dataset' do
          get "/dataset/#{dataset_id}?includes=metadata"

          expect(status).to eq(200)
          expect(json_attr['metadata']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>"prep", "info"=>{"organization"=>"University of Washington/Joe Casola"}, "id"=>"57bc054f4f30010f00bbec73"}}])
        end

        it 'Show empty metadata for specific dataset' do
          get "/dataset/#{dataset_id}?includes="

          expect(status).to eq(200)
          expect(json_attr['metadata']).to be_nil
        end

        it 'Show nil metadata for specific dataset if metadata not present' do
          get "/dataset/#{dataset_id}"

          expect(status).to eq(200)
          expect(json_attr['metadata']).to be_nil
        end
      end

      context 'specific dataset' do
        before(:each) do
          stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/metadata?application=prep").
          with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(metadata_data), :headers => {})
        end

        it 'Show metadata for specific dataset and application' do
          get "/dataset/#{dataset_id}?includes=metadata&app=prep"

          expect(status).to eq(200)
          expect(json_attr['metadata']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>"prep", "info"=>{"organization"=>"University of Washington/Joe Casola"}, "id"=>"57bc054f4f30010f00bbec73"}}])
        end
      end
    end

    context 'If metadata service not reachable' do
      let!(:dataset_id) { Dataset.find_by(name: 'cartodb test set').id }

      before(:each) do
        stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/metadata").
        to_timeout
      end

      it 'Show empty metadata for specific dataset if metadata not reachable' do
        get "/dataset/#{dataset_id}?includes=metadata"

        expect(status).to eq(200)
        expect(json_attr['metadata']).to eq([])
      end
    end
  end
end
