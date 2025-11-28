# frozen_string_literal: true

class ParticipantCountService
  def initialize(tenant_id:)
    @tenant_id = tenant_id
  end

  def can_join?
    tenant = Tenant.find(@tenant_id)
    limit = limit_setting

    # No limit set, allow joining
    return true if limit.nil?

    current_count = tenant.participants.to_i
    current_count < limit.to_i
  end

  private

  def limit_setting
    settings = TenantSetting.all(@tenant_id)
    limit = settings.find { |s| s.param == 'limitParticipants' }
    limit&.value
  end
end
