require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :wms_connectors
    fixtures :datasets

    let!(:dataset_id) { Dataset.find_by(name: 'Wms test set 1').id }

    let!(:layers_data) {{
                           "data": [{"id": "57bc054f4f30010f00bbec71", "type": "layers", "attributes": { "dataset": "#{dataset_id}",
                                                                                                         "application": "prep",
                                                                                                         "name": "test-dataset-layer",
                                                                                                         "default": true,
                                                                                                         "iso": ["AUS", "BRA"],
                                                                                                         "description": "Lorem ipsum dolor...",
                                                                                                         "layerConfig": {
                                                                                                           "display": true,
                                                                                                           "max_date": "2016-02-14",
                                                                                                           "min_date": "2012-01-12",
                                                                                                           "fit_to_geom": true
                                                                                                         },
                                                                                                         "legendConfig": {
                                                                                                           "marks": {
                                                                                                             "type": "rect",
                                                                                                             "from": {
                                                                                                               "data": "table"
                                                                                                             }
                                                                                                           }
                                                                                                         },
                                                                                                         "applicationConfig": {
                                                                                                           "config one": {
                                                                                                             "type": "lorem",
                                                                                                             "from": {
                                                                                                               "data": "table"
                                                                                                             }
                                                                                                           }
                                                                                                         }
                                                                                                        }
                           }]
                         }}

    let!(:dataset_layers) {{
                           "data": [{"id": "57bc054f4f30010f00bbec71", "type": "layers", "attributes": { "dataset": "#{dataset_id}",
                                                                                                         "application": "prep",
                                                                                                         "layerConfig": { "organization": "University of Washington/Joe Casola" }
                                                                                                       }
                           },
                           {"id": "57bc054f4f30010f00bbec72", "type": "layers", "attributes": { "dataset": "c547146d-de0c-47ff-a406-5125667fd5c1",
                                                                                                           "application": "wrw",
                                                                                                           "layerConfig": { "organization": "University of Washington/Joe Casola" }
                                                                                              }
                           }]
                         }}

    before(:each) do
      ServiceSetting.create(name: 'api-gateway', listener: true, token: '3123123der324eewr434ewr4324', url: 'http://192.168.99.100:8000')
    end

    context 'Populate datasets with layer', redis: true do
      context 'datasets list' do
        before(:each) do
          stub_request(:post, "http://192.168.99.100:8000/layer/find-by-ids").
          with(:body => "{\"layer\":{\"ids\":[\"#{dataset_id}\"]}}",
               :headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(dataset_layers), :headers => {})
        end

        it 'Show layer for datasets' do
          get "/dataset?connector_type=wms&includes=layer"

          dataset_json = json[0]['attributes']

          expect(status).to eq(200)
          expect(json.length).to eq(1)
          expect(dataset_json['layer']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>"prep", "layerConfig"=>{"organization"=>"University of Washington/Joe Casola"}, "id"=>1}}])
        end
      end

      context 'specific dataset without app' do
        before(:each) do
          stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/layer").
          with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(layers_data), :headers => {})
        end

        it 'Show layer for specific dataset' do
          get "/dataset/#{dataset_id}?includes=layer"

          expect(status).to eq(200)
          expect(json_attr['layer']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a",
                                                            "application"=>"prep",
                                                            "name"=>"test-dataset-layer",
                                                            "default"=>true,
                                                            "iso"=>["AUS", "BRA"],
                                                            "description"=>"Lorem ipsum dolor...",
                                                            "layerConfig"=>
                                                             {"display"=>true,
                                                              "max_date"=>"2016-02-14",
                                                              "min_date"=>"2012-01-12",
                                                              "fit_to_geom"=>true},
                                                            "legendConfig"=>{"marks"=>{"type"=>"rect", "from"=>{"data"=>"table"}}},
                                                            "applicationConfig"=>
                                                             {"config one"=>{"type"=>"lorem", "from"=>{"data"=>"table"}}},
                                                            "id"=>1}}])
        end

        it 'Show empty layer for specific dataset' do
          get "/dataset/#{dataset_id}?includes="

          expect(status).to eq(200)
          expect(json_attr['layer']).to be_nil
        end

        it 'Show nil layer for specific dataset if layer not present' do
          get "/dataset/#{dataset_id}"

          expect(status).to eq(200)
          expect(json_attr['layer']).to be_nil
        end
      end

      context 'specific dataset' do
        before(:each) do
          stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/layer?app=prep").
          with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(layers_data), :headers => {})
        end

        it 'Show layer for specific dataset and application' do
          get "/dataset/#{dataset_id}?includes=layer&app=prep"

          expect(status).to eq(200)
          expect(json_attr['layer']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a",
                                                            "application"=>"prep",
                                                            "name"=>"test-dataset-layer",
                                                            "default"=>true,
                                                            "iso"=>["AUS", "BRA"],
                                                            "description"=>"Lorem ipsum dolor...",
                                                            "layerConfig"=>
                                                             {"display"=>true,
                                                              "max_date"=>"2016-02-14",
                                                              "min_date"=>"2012-01-12",
                                                              "fit_to_geom"=>true},
                                                            "legendConfig"=>{"marks"=>{"type"=>"rect", "from"=>{"data"=>"table"}}},
                                                            "applicationConfig"=>
                                                             {"config one"=>{"type"=>"lorem", "from"=>{"data"=>"table"}}},
                                                            "id"=>1}}])
        end
      end
    end

    context 'If layer service not reachable' do
      let!(:dataset_id) { Dataset.find_by(name: 'cartodb test set').id }

      before(:each) do
        stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/layer").
        to_timeout
      end

      it 'Show empty layer for specific dataset if layer not reachable' do
        get "/dataset/#{dataset_id}?includes=layer"

        expect(status).to eq(200)
        expect(json_attr['layer']).to eq([])
      end
    end
  end
end
