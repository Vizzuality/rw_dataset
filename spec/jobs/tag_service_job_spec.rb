require 'rails_helper'

RSpec.describe TagServiceJob, type: :job do
  include ActiveJob::TestHelper
  let!(:tags_body)   { {"tag": {"tags_list": ["123", '456'], "taggable_id": "c547146d-de0c-47ff-a406-5125667fd5e1",
                           "taggable_type": "Dataset", "taggable_slug": nil}} }
  let!(:topics_body) { {"topic": {"topics_list": ["123", '456'], "topicable_id": "c547146d-de0c-47ff-a406-5125667fd5e1",
                        "topicable_type": "Dataset", "topicable_slug": nil}} }

  subject(:job) { described_class.perform_later('Dataset', tags_body, topics_body) }

  it 'queues the job' do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'executes perform' do
    expect(TagService).to receive(:connect_to_service).with('Dataset', tags_body, topics_body)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
