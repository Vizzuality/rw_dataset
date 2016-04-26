require 'rails_helper'

RSpec.describe ConnectorServiceJob, type: :job do
  include ActiveJob::TestHelper
  let!(:body) { {"connector": {"id": "123", "dataset_url": "http://test.url.org"}} }
  subject(:job) { described_class.perform_later('JsonConnector', body) }

  it 'queues the job' do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'executes perform' do
    expect(ConnectorService).to receive(:connect_to_service).with('JsonConnector', body)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
