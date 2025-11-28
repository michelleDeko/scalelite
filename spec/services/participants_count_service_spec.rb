require 'rails_helper'

RSpec.describe ParticipantCountService do
  describe '.can_join?' do
    context 'when multitenancy is disabled' do
      before do
        Rails.configuration.x.multitenancy_enabled = false
      end

      it 'returns true (no tenant checks)' do
        result = described_class.can_join?(nil)
        expect(result).to be true
      end

      it 'returns true even if passed a tenant_id' do
        result = described_class.can_join?(123)
        expect(result).to be true
      end
    end

    context 'when multitenancy is enabled' do
      before do
        Rails.configuration.x.multitenancy_enabled = true
      end

      context 'when tenant_id is nil' do
        it 'returns true (no tenant, no limit)' do
          result = described_class.can_join?(nil)
          expect(result).to be true
        end
      end

      context 'when tenant exists but has no limitParticipants setting' do
        let!(:tenant) { create(:tenant, participants: 5) }

        it 'returns true (no limit configured)' do
          result = described_class.can_join?(tenant.id)
          expect(result).to be true
        end

        it 'returns true even with high participant count' do
          tenant.participants = 1000
            tenant.save!
            result = described_class.can_join?(tenant.id)
          expect(result).to be true
        end
      end

      context 'when tenant has limitParticipants setting' do
        let!(:tenant) { create(:tenant, participants: 5) }
        let!(:limit_setting) do
          create(:tenant_setting, tenant_id: tenant.id, param: 'limitParticipants', value: '10', sl_param: 'true')
        end

        context 'and participant count is below limit' do
          it 'returns true' do
            result = described_class.can_join?(tenant.id)
            expect(result).to be true
          end
        end

        context 'and participant count equals limit' do
          before do
            tenant.participants = 10
            tenant.save!
          end

          it 'returns true (at capacity is allowed)' do
            result = described_class.can_join?(tenant.id)
            expect(result).to be true
          end
        end

        context 'and participant count exceeds limit' do
          before do
            tenant.participants = 11
            tenant.save!
          end

          it 'returns false (limit exceeded)' do
            result = described_class.can_join?(tenant.id)
            expect(result).to be false
          end
        end

        context 'and participant count is much higher than limit' do
          before do
            tenant.participants = 100
            tenant.save!
          end

          it 'returns false' do
            result = described_class.can_join?(tenant.id)
            expect(result).to be false
          end
        end
      end

      context 'when limitParticipants is set to 0' do
        let!(:tenant) { create(:tenant, participants: 0) }
        let!(:limit_setting) do
          create(:tenant_setting, tenant_id: tenant.id, param: 'limitParticipants', value: '0', sl_param: 'true')
        end

        it 'returns false (limit is 0)' do
          result = described_class.can_join?(tenant.id)
          expect(result).to be false
        end
      end

      context 'when limitParticipants is set to a large value' do
        let!(:tenant) { create(:tenant, participants: 999_999) }
        let!(:limit_setting) do
          create(:tenant_setting, tenant_id: tenant.id, param: 'limitParticipants', value: '1000000', sl_param: 'true')
        end

        it 'returns true (below large limit)' do
          result = described_class.can_join?(tenant.id)
          expect(result).to be true
        end
      end

      context 'when tenant has nil participants value' do
        let!(:tenant) { create(:tenant, participants: nil) }
        let!(:limit_setting) do
          create(:tenant_setting, tenant_id: tenant.id, param: 'limitParticipants', value: '10', sl_param: 'true')
        end

        it 'returns true (nil treated as 0)' do
          result = described_class.can_join?(tenant.id)
          expect(result).to be true
        end
      end

      context 'when limitParticipants value is invalid (non-numeric)' do
        let!(:tenant) { create(:tenant, participants: 5) }
        let!(:limit_setting) do
          create(:tenant_setting, tenant_id: tenant.id, param: 'limitParticipants', value: 'invalid', sl_param: 'true')
        end

        it 'returns true (invalid limit is treated as no limit)' do
          result = described_class.can_join?(tenant.id)
          expect(result).to be true
        end
      end

      context 'with negative participant count' do
        let!(:tenant) { create(:tenant, participants: -5) }
        let!(:limit_setting) do
          create(:tenant_setting, tenant_id: tenant.id, param: 'limitParticipants', value: '10', sl_param: 'true')
        end

        it 'returns true (negative counts treated as below limit)' do
          result = described_class.can_join?(tenant.id)
          expect(result).to be true
        end
      end
    end
  end
end
