require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :wms_connectors
    fixtures :datasets

    let!(:metadata_data) {{
                           "data": [{"id": "57bc054f4f30010f00bbec71", "type": "metadata", "attributes": { "dataset": "baca8364-3aa8-5d74-8100-44ef25885e9a",
                                                                                                           "application": "prep",
                                                                                                           "attributes": { "organization": "University of Washington/Joe Casola" }
                                                                                                         }
                           }]
                         }}

    let!(:dataset_metas) {{
                           "data": [{"id": "57bc054f4f30010f00bbec71", "type": "metadata", "attributes": { "dataset": "baca8364-3aa8-5d74-8100-44ef25885e9a",
                                                                                                           "application": "prep",
                                                                                                           "attributes": { "organization": "University of Washington/Joe Casola" }
                                                                                                         }
                           },
                           {"id": "57bc054f4f30010f00bbec72", "type": "metadata", "attributes": { "dataset": "gaca8364-3aa8-5d74-8100-44ef25885e9a",
                                                                                                           "application": "prep",
                                                                                                           "attributes": { "organization": "University of Washington/Joe Casola" }
                                                                                                         }
                           }]
                         }}

    context 'Populate datasets with metadata' do
      before(:each) do
        ServiceSetting.create(name: 'api-gateway', listener: true, token: '3123123der324eewr434ewr4324', url: 'http://192.168.99.100:8000')

        stub_request(:get, /192.168.99.100:8000/).
        with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324', 'User-Agent'=>'Typhoeus - https://github.com/typhoeus/typhoeus'}).
        to_return(:status => 200, :body => Oj.dump(metadata_data), :headers => {})

        stub_request(:post, "http://192.168.99.100:8000/metadata/find-by-ids").
        with(:body => "app&ids=%5B%22baca8364-3aa8-5d74-8100-44ef25885e9a%22%5D",
             :headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324', 'User-Agent'=>'Typhoeus - https://github.com/typhoeus/typhoeus'}).
        to_return(:status => 200, :body => Oj.dump(metadata_data), :headers => {})
      end

      it 'Show metadata for datasets' do
        get "/datasets?connector_type=wms&includes=metadata"

        dataset_json = json[0]

        expect(status).to eq(200)
        expect(json.length).to eq(1)
        expect(dataset_json['metadata']).to eq([{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>"prep", "attributes"=>{"organization"=>"University of Washington/Joe Casola"}}])
      end

      it 'Show metadata for specific dataset and application' do
        get "/datasets/baca8364-3aa8-5d74-8100-44ef25885e9a?includes=metadata&app=prep"

        expect(status).to eq(200)
        expect(json['metadata']).to eq([{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>"prep", "attributes"=>{"organization"=>"University of Washington/Joe Casola"}}])
      end

      it 'Show metadata for specific dataset' do
        get "/datasets/baca8364-3aa8-5d74-8100-44ef25885e9a?includes=metadata"

        expect(status).to eq(200)
        expect(json['metadata']).to eq([{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>"prep", "attributes"=>{"organization"=>"University of Washington/Joe Casola"}}])
      end

      it 'Show empty metadata for specific dataset' do
        get "/datasets/baca8364-3aa8-5d74-8100-44ef25885e9a?includes="

        expect(status).to eq(200)
        expect(json['metadata']).to be_nil
      end

      it 'Show nil metadata for specific dataset if metadata not present' do
        get "/datasets/baca8364-3aa8-5d74-8100-44ef25885e9a"

        expect(status).to eq(200)
        expect(json['metadata']).to be_nil
      end
    end

    context 'If metadata service not reachable' do
      before(:each) do
        ServiceSetting.create(name: 'api-gateway', listener: true, token: '3123123der324eewr434ewr4324', url: 'http://192.168.99.100:8000')

        stub_request(:get, /192.168.99.100:8000/).to_timeout
      end

      it 'Show empty metadata for specific dataset if metadata not reachable' do
        get "/datasets/baca8364-3aa8-5d74-8100-44ef25885e9a?includes=metadata&app=prep"

        expect(status).to eq(200)
        expect(json['metadata']).to eq('Meta data not reachable')
      end
    end
  end
end
