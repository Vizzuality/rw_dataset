require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :wms_connectors
    fixtures :datasets

    let!(:dataset_id) { Dataset.find_by(name: 'Wms test set 1').id }

    let!(:vocabularies_data) {{"data": [
                                  {
                                    "id": "voc_1",
                                    "type": "vocabulary",
                                    "attributes": {
                                      "tags": [
                                        "tag_1",
                                        "tag_2"
                                      ],
                                      "name": "voc_1"
                                    }
                                  },
                                  {
                                    "id": "legacy",
                                    "type": "vocabulary",
                                    "attributes": {
                                      "tags": [
                                        "test tag 1",
                                        "tag_1",
                                        "tag_2"
                                      ],
                                      "name": "legacy"
                                    }
                                  }
                                ]
                              }}

    let!(:dataset_vocabularies) {{"data": [
                                    {
                                      "id": "legacy",
                                      "type": "vocabulary",
                                      "attributes": {
                                        "resource": {
                                          "id": "#{dataset_id}",
                                          "type": "dataset"
                                        },
                                        "tags": [
                                          "test tag 1",
                                          "tag_1",
                                          "tag_2"
                                        ],
                                        "name": "legacy"
                                      }
                                    }
                                  ]
                                }}

    let!(:dataset_vocabularies_faild) {{"data": [
                                                  {
                                                    "id": "voc_1",
                                                    "type": "vocabulary",
                                                    "attributes": {
                                                      "resource": {
                                                        "id": "#{dataset_id}",
                                                        "type": "dataset"
                                                      },
                                                      "tags": [
                                                        "tag_1",
                                                        "tag_2"
                                                      ],
                                                      "name": "voc_1"
                                                    }
                                                  },
                                                  {
                                                    "id": "voc_1",
                                                    "type": "vocabulary",
                                                    "attributes": {
                                                      "resource": {
                                                        "id": "#{dataset_id}",
                                                        "type": "dataset"
                                                      },
                                                      "tags": [
                                                        "test tag 1",
                                                        "tag_1",
                                                        "tag_2"
                                                      ],
                                                      "name": "legacy"
                                                    }
                                                  }
                                                ]
                                       }}

    before(:each) do
      ServiceSetting.create(name: 'api-gateway', listener: true, token: '3123123der324eewr434ewr4324', url: 'http://192.168.99.100:8000')
    end

    context 'Populate datasets with vocabulary', redis: true do
      context 'datasets list' do
        before(:each) do
          stub_request(:post, "http://192.168.99.100:8000/dataset/vocabulary/find-by-ids").
          with(:body => "{\"ids\":[\"#{dataset_id}\"]}",
               :headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324', 'Content-Type'=>'application/json'}).
          to_return(:status => 200, :body => Oj.dump(dataset_vocabularies), :headers => {})
        end

        it 'Show vocabulary for datasets' do
          get "/dataset?connector_type=wms&includes=vocabulary"

          dataset_json = json[0]['attributes']

          expect(status).to eq(200)
          expect(json.length).to eq(1)
          expect(dataset_json['vocabulary']).to eq([{"attributes"=>{"resource"=>{"id"=>"#{dataset_id}", "type"=>"dataset"}, "tags"=>["test tag 1", "tag_1", "tag_2"], "name"=>"legacy"}}])
        end
      end

      context 'datasets list with wrong vocabularies' do
        before(:each) do
          stub_request(:post, "http://192.168.99.100:8000/dataset/vocabulary/find-by-ids").
          with(:body => "{\"ids\":[\"#{dataset_id}\"]}",
               :headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324', 'Content-Type'=>'application/json'}).
          to_return(:status => 200, :body => Oj.dump(dataset_vocabularies_faild), :headers => {})
        end

        it 'Generate uuids for vocabulary' do
          get "/dataset?connector_type=wms&includes=vocabulary"

          dataset_json = json[0]['attributes']

          expect(status).to eq(200)
          expect(json.length).to eq(1)
          expect(dataset_json['vocabulary']).not_to be_nil
        end
      end

      context 'specific dataset' do
        before(:each) do
          stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/vocabulary").
          with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(vocabularies_data), :headers => {})
        end

        it 'Show vocabulary for specific dataset' do
          get "/dataset/#{dataset_id}?includes=vocabulary"

          expect(status).to eq(200)
          expect(json_attr['vocabulary']).to eq([{"attributes"=>{"tags"=>["tag_1", "tag_2"], "name"=>"voc_1", "id"=>"voc_1"}}, {"attributes"=>{"tags"=>["test tag 1", "tag_1", "tag_2"], "name"=>"legacy", "id"=>"legacy"}}])
        end

        it 'Show empty vocabulary for specific dataset' do
          get "/dataset/#{dataset_id}?includes="

          expect(status).to eq(200)
          expect(json_attr['vocabulary']).to be_nil
        end

        it 'Show nil vocabulary for specific dataset if vocabulary not present' do
          get "/dataset/#{dataset_id}"

          expect(status).to eq(200)
          expect(json_attr['vocabulary']).to be_nil
        end
      end
    end

    context 'If vocabulary service not reachable' do
      let!(:dataset_id) { Dataset.find_by(name: 'cartodb test set').id }

      before(:each) do
        stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/vocabulary").
        to_timeout
      end

      it 'Show empty vocabulary for specific dataset if vocabulary not reachable' do
        get "/dataset/#{dataset_id}?includes=vocabulary"

        expect(status).to eq(200)
        expect(json_attr['vocabulary']).to eq([])
      end
    end
  end
end
