# frozen_string_literal: true

class ParticipantCountService
  def self.can_join?(tenant_id)
    new(tenant_id: tenant_id).can_join?
  end

  def initialize(tenant_id:)
    @tenant_id = tenant_id
  end

  def can_join?
    # If multitenancy is disabled, allow joining
    return true unless Rails.configuration.x.multitenancy_enabled

    # If no tenant, allow joining (no limit)
    return true if @tenant_id.nil?

    begin
      tenant = Tenant.find(@tenant_id)
    rescue RecordNotFound
      return true
    end

    limit = limit_setting

    # No limit set, allow joining
    return true if limit.nil?

    # Ensure limit is a valid integer string. If not numeric, treat as no limit.
    return true unless limit.to_s.match?(/\A\d+\z/)

    limit_int = limit.to_i

    # A limit of 0 means no participants allowed
    return false if limit_int == 0

    current_count = tenant.participants.to_i
    current_count <= limit_int
  end

  private

  def limit_setting
    settings = TenantSetting.all(@tenant_id)
    limit = settings.find { |s| s.param == 'limitParticipants' }
    limit&.value
  end
end
