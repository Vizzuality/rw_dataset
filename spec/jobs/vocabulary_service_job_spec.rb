require 'rails_helper'

RSpec.describe VocabularyServiceJob, type: :job do
  include ActiveJob::TestHelper
  let!(:tags_body)         { {"legacy": { "tags": ["123", '456'] }}}
  let!(:vocabularies_body) { {"voc_1":  { "tags": ["123", '456'] }}}

  subject(:job) { described_class.perform_later('Dataset', 'c547146d-de0c-47ff-a406-5125667fd5c1', tags_body, vocabularies_body) }

  it 'queues the job' do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'executes perform' do
    expect(VocabularyService).to receive(:connect_to_service).with('Dataset', 'c547146d-de0c-47ff-a406-5125667fd5c1', tags_body, vocabularies_body)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
