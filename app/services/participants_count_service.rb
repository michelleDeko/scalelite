# frozen_string_literal: true

class ParticipantCountService
  def initialize(tenant_id:)
    @tenant_id = tenant_id
  end

  def can_join?
    tenant = Tenant.find(@tenant_id)
    limit = get_limit

    # No limit set, allow joining
    return true if limit.nil?

    current_count = tenant.participants.to_i
    current_count < limit.to_i
  end

  private

  def get_limit
    settings = TenantSetting.all(@tenant_id)
    limit_setting = settings.find { |s| s.param == 'limitParticipants' }
    limit_setting&.value
  end
end
