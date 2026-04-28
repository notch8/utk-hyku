# frozen_string_literal: true

RSpec.describe StatusController, type: :controller do
  let(:user) { FactoryBot.create(:superadmin) }

  before do
    login_as(user, scope: :user)
    allow(controller).to receive(:authorize!).and_return(true)
  end

  describe 'PATCH #update' do
    context 'when the endpoint is an FcrepoEndpoint and was last restarted more than 5 minutes ago' do
      let(:endpoint) do
        FactoryBot.create(:fcrepo_endpoint, last_restart: 10.minutes.ago)
      end

      it 'executes the hardcoded fcrepo restart command' do
        expect(controller).to receive(:system)
          .with("kubectl", "rollout", "restart", "deployment", "fcrepo")
        patch :update, params: { id: endpoint.id }
      end

      it 'does not raise an error' do
        allow(controller).to receive(:system)
        expect { patch :update, params: { id: endpoint.id } }.not_to raise_error
      end
    end

    context 'when the endpoint type is not in the allowlist' do
      let(:endpoint) do
        FactoryBot.create(:solr_endpoint, last_restart: 10.minutes.ago)
      end

      it 'does not execute a command' do
        expect(controller).not_to receive(:system)
        patch :update, params: { id: endpoint.id }
      end
    end

    context 'when the endpoint was restarted less than 5 minutes ago' do
      let(:endpoint) do
        FactoryBot.create(:fcrepo_endpoint, last_restart: 2.minutes.ago)
      end

      it 'does not execute a command' do
        expect(controller).not_to receive(:system)
        patch :update, params: { id: endpoint.id }
      end
    end
  end
end
