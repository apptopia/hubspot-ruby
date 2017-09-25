module Hubspot
  #
  # HubSpot Engagements API
  #
  # {https://developers.hubspot.com/docs/methods/engagements/engagements-overview}
  #
  class Engagement
    ALL_ENGAGEMENTS_PATH    = '/engagements/v1/engagements/paged'
    RECENT_ENGAGEMENTS_PATH = '/engagements/v1/engagements/recent/modified'

    attr_reader :id, :portal_id, :active, :created_at
    attr_reader :last_updated, :created_by, :modified_by
    attr_reader :owner_id, :type, :timestamp

    def initialize(response_hash)
      @id           = response_hash['engagement']['id']
      @portal_id    = response_hash['engagement']['portalId']
      @active       = response_hash['engagement']['active']
      @created_at   = Time.at response_hash['engagement']['createdAt'] / 1000
      @last_updated = Time.at response_hash['engagement']['lastUpdated'] / 1000
      @created_by   = response_hash['engagement']['createdBy']
      @modified_by  = response_hash['engagement']['modifiedBy']
      @owner_id     = response_hash['engagement']['ownerId']
      @type         = response_hash['engagement']['type']
      @timestamp    = Time.at response_hash['engagement']['timestamp'] / 1000
    end
  end
end
