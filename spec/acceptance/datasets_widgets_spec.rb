require 'acceptance_helper'

module V1
  describe 'Datasets', type: :request do
    fixtures :rest_connectors
    fixtures :json_connectors
    fixtures :wms_connectors
    fixtures :datasets

    let!(:dataset_id) { Dataset.find_by(name: 'Wms test set 1').id }

    let!(:widgets_data) {{
                           "data": [{"id": "57bc054f4f30010f00bbec71", "type": "widgets", "attributes": { "dataset": "#{dataset_id}",
                                                                                                          "application": ["prep"],
                                                                                                          "name": "test-dataset-widget",
                                                                                                          "default": true,
                                                                                                          "iso": ["AUS", "BRA"],
                                                                                                          "description": "Lorem ipsum dolor...",
                                                                                                          "widgetConfig": {
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

    let!(:dataset_widgets) {{
                           "data": [{"id": "57bc054f4f30010f00bbec71", "type": "widgets", "attributes": { "dataset": "#{dataset_id}",
                                                                                                          "application": ["prep"],
                                                                                                          "widgetConfig": { "organization": "University of Washington/Joe Casola" }
                                                                                                        }
                           },
                           {"id": "57bc054f4f30010f00bbec72", "type": "widgets", "attributes": { "dataset": "c547146d-de0c-47ff-a406-5125667fd5c1",
                                                                                                            "application": ["wrw"],
                                                                                                            "widgetConfig": { "organization": "University of Washington/Joe Casola" }
                                                                                               }
                           }]
                         }}

    before(:each) do
      ServiceSetting.create(name: 'api-gateway', listener: true, token: '3123123der324eewr434ewr4324', url: 'http://192.168.99.100:8000')
    end

    context 'Populate datasets with widget', redis: true do
      context 'datasets list' do
        before(:each) do
          stub_request(:post, "http://192.168.99.100:8000/widget/find-by-ids").
          with(:body => "{\"widget\":{\"ids\":[\"#{dataset_id}\"]}}",
               :headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(dataset_widgets), :headers => {})
        end

        it 'Show widget for datasets' do
          get "/dataset?connector_type=wms&includes=widget"

          dataset_json = json[0]['attributes']

          expect(status).to eq(200)
          expect(json.length).to eq(1)
          expect(dataset_json['widget']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a", "application"=>["prep"], "widgetConfig"=>{"organization"=>"University of Washington/Joe Casola"}, "id"=>"57bc054f4f30010f00bbec71"}}])
        end
      end

      context 'specific dataset without app' do
        before(:each) do
          stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/widget").
          with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(widgets_data), :headers => {})
        end

        it 'Show widget for specific dataset' do
          get "/dataset/#{dataset_id}?includes=widget"

          expect(status).to eq(200)
          expect(json_attr['widget']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a",
                                                             "application"=>["prep"],
                                                             "name"=>"test-dataset-widget",
                                                             "default"=>true,
                                                             "iso"=>["AUS", "BRA"],
                                                             "description"=>"Lorem ipsum dolor...",
                                                             "widgetConfig"=>
                                                              {"display"=>true,
                                                               "max_date"=>"2016-02-14",
                                                               "min_date"=>"2012-01-12",
                                                               "fit_to_geom"=>true},
                                                             "legendConfig"=>{"marks"=>{"type"=>"rect", "from"=>{"data"=>"table"}}},
                                                             "applicationConfig"=>
                                                              {"config one"=>{"type"=>"lorem", "from"=>{"data"=>"table"}}},
                                                             "id"=>"57bc054f4f30010f00bbec71"}}])
        end

        it 'Show empty widget for specific dataset' do
          get "/dataset/#{dataset_id}?includes="

          expect(status).to eq(200)
          expect(json_attr['widget']).to be_nil
        end

        it 'Show nil widget for specific dataset if widget not present' do
          get "/dataset/#{dataset_id}"

          expect(status).to eq(200)
          expect(json_attr['widget']).to be_nil
        end
      end

      context 'specific dataset' do
        before(:each) do
          stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/widget?app=prep").
          with(:headers => {'Accept'=>'application/json', 'Authentication'=>'3123123der324eewr434ewr4324'}).
          to_return(:status => 200, :body => Oj.dump(widgets_data), :headers => {})
        end

        it 'Show widget for specific dataset and application' do
          get "/dataset/#{dataset_id}?includes=widget&app=prep"

          expect(status).to eq(200)
          expect(json_attr['widget']).to eq([{"attributes"=>{"dataset"=>"baca8364-3aa8-5d74-8100-44ef25885e9a",
                                                             "application"=>["prep"],
                                                             "name"=>"test-dataset-widget",
                                                             "default"=>true,
                                                             "iso"=>["AUS", "BRA"],
                                                             "description"=>"Lorem ipsum dolor...",
                                                             "widgetConfig"=>
                                                              {"display"=>true,
                                                               "max_date"=>"2016-02-14",
                                                               "min_date"=>"2012-01-12",
                                                               "fit_to_geom"=>true},
                                                             "legendConfig"=>{"marks"=>{"type"=>"rect", "from"=>{"data"=>"table"}}},
                                                             "applicationConfig"=>
                                                              {"config one"=>{"type"=>"lorem", "from"=>{"data"=>"table"}}},
                                                             "id"=>"57bc054f4f30010f00bbec71"}}])
        end
      end
    end

    context 'If widget service not reachable' do
      let!(:dataset_id) { Dataset.find_by(name: 'cartodb test set').id }

      before(:each) do
        stub_request(:get, "http://192.168.99.100:8000/dataset/#{dataset_id}/widget").
        to_timeout
      end

      it 'Show empty widget for specific dataset if widget not reachable' do
        get "/dataset/#{dataset_id}?includes=widget"

        expect(status).to eq(200)
        expect(json_attr['widget']).to eq([])
      end
    end
  end
end
