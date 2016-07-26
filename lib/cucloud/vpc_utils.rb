module Cucloud
  # Utilities library for interacting with VPC
  class VpcUtils
    # Define utility class to hold protocol constants
    # see http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
    class PROTOCOL
      # Protocl number for ICMP
      ICMP = '1'.freeze
      # Protocl number for TCP
      TCP = '6'.freeze
      # Protocl number for UDP
      UDP = '17'.freeze
      # Protocl number that denotes the use of all protocols
      ALL = '-1'.freeze
    end

    def initialize(vpc_client = Aws::EC2::Client.new)
      @vpc = vpc_client
    end

    # Compare NACLS in a list of regions with a specified rule set
    # @param regions [Array] List of AWS regions to compare rule set against
    # @param rules [Array]  List of ACL rules to compart with AWS
    # @param skip_acl [Array] List of ACL ids to skip in comparison
    # @return [Hash]
    #   * resp.region.network_acl_id.missing #=> Array
    #     * resp.region.network_acl_id.missing[0].cidr #=> String
    #     * resp.region.network_acl_id.missing[0].protocol #=> String
    #     * resp.region.network_acl_id.missing[0].egress #=> String
    #     * resp.region.network_acl_id.missing[0].to #=> String
    #     * resp.region.network_acl_id.missing[0].from #=> String
    #   * resp.region.network_acl_id.additional #=> Array
    #     * resp.region.network_acl_id.additional[0].cidr #=> String
    #     * resp.region.network_acl_id.additional[0].protocol #=> String
    #     * resp.region.network_acl_id.additional[0].egress #=> String
    #     * resp.region.network_acl_id.additional[0].to #=> String
    #     * resp.region.network_acl_id.additional[0].from #=> String
    def compare_nacls(regions, rules, skip_acl = [])
      raise ArgumentError, 'regions is not an array' unless regions.is_a? Array
      raise ArgumentError, 'rules is not an array' unless rules.is_a? Array
      compared_rules = {}
      initial_region = Cucloud.region

      regions.each do |region|
        Cucloud.region = region
        nacls = @vpc.describe_network_acls({})
        compared_rules[region] = {}

        nacls.network_acls.each do |acl|
          next if skip_acl.include?(acl.network_acl_id)
          compared_rules[region][acl.network_acl_id] = {}
          check_acls(acl, compared_rules)
        end
      end
      Cucloud.region = initial_region
      compared_rules
    end

    # Does the current region have vpc flow logs?
    # @reutrn [boolean]
    def flow_logs?
      @vpc.describe_flow_logs({}).empty?
    end

    private

    # Compare ACL entries aganinst a rule set
    def check_acls(acl, compared_rules)
      acl.entries.each do |entry|
        next unless entry.rule_number < 32_767
        missing_entries = rules
        additional_entries = []

        find_rule = lambda do |rule|
          test = rule[:cidr] == entry.cidr_block && rule[:protocol] == entry.protocol && rule[:egress] == entry.egress
          unless entry.port_range.nil?
            test &= rule[:to] == entry.port_range.to && rule[:from] == entry.port_range.from
          end
          test
        end

        found_at = missing_entries.find_index(&find_rule)

        if found_at
          missing_entries.delete_at(found_at)
        else
          additional_entries.push(cidr: entry.cidr_block,
                                  protocol: entry.protocol,
                                  egress: entry.egress,
                                  to: entry.port_range.nil? ? '-1' : entry.port_range.to,
                                  from: entry.port_range.nil? ? '-1' : entry.port_range.from)
        end
        compared_rules[region][acl.network_acl_id][:missing] = missing_entries
        compared_rules[region][acl.network_acl_id][:additional] = additional_entries
      end
    end
  end
end
