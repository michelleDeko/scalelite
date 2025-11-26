# frozen_string_literal: true

class ParticipantCountService
  def initialize(tenant_id:)
    @tenant_id = tenant_id
  end

  def call
    # Fetch the maximum participants allowed for the tenant
    current_participant_count
  end

  def can_join?
    tenant = Tenant.find(@tenant_id)
    return true if tenant.max_participants.nil?

    current_count = current_participant_count
    max_participants = tenant.max_participants

    current_count < max_participants
  end

  private

  def current_participant_count
    meetings = Meeting.all(@tenant_id)
    meetings.sum do |_meeting|
      participant_count
    end
  end

  def participant_count
    0
  end
end
