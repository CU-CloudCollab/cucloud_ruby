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

    # Compare NACLS in a the current region with a specified rule set
    # @param rules [Array]  List of ACL rules to compart with AWS
    # @param skip_acl [Array] List of ACL ids to skip in comparison
    # @return [Array<Hash <String, String>>]
    #   * resp[0].acl #=> String
    #   * resp[0].missing[0] #=> Array
    #     * resp[0].missing[0].cidr #=> String
    #     * resp[0]missing[0].protocol #=> String
    #     * resp[0]missing[0].egress #=> String
    #     * resp[0]missing[0].to #=> String
    #     * resp[0]missing[0].from #=> String
    #   * resp[0].additional #=> Array
    #     * resp[0]additional[0].cidr #=> String
    #     * resp[0]additional[0].protocol #=> String
    #     * resp[0]additional[0].egress #=> String
    #     * resp[0]additional[0].to #=> String
    #     * resp[0]additional[0].from #=> String
    def compare_nacls(rules, skip_acl = [])
      raise ArgumentError, 'rules is not an array' unless rules.is_a? Array
      compared_rules = []

      nacls = @vpc.describe_network_acls({})

      nacls.network_acls.each do |acl|
        next if skip_acl.include?(acl.network_acl_id)
        compared_rules.push(check_acls(acl, rules))
      end
      compared_rules
    end

    # Does the current region have vpc flow logs?
    # @return [boolean]
    def flow_logs?
      vpc_flow_log_status.find { |x| !x[:flow_logs_active] }.nil?
    end

    # Does the current region have vpc flow logs?
    # @return [Array<Hash>]
    def vpc_flow_log_status
      @vpc.describe_vpcs.vpcs.map do |vpc|
        {
          vpc_id: vpc.vpc_id,
          flow_logs_active: !@vpc.describe_flow_logs(
            filter: [{ name: 'resource-id', values: [vpc.vpc_id] }]
          ).flow_logs.empty?
        }
      end
    end

    private

    # Compare ACL entries aganinst a rule set
    def check_acls(acl, rules)
      missing_entries = rules.dup
      additional_entries = []

      acl.entries.each do |entry|
        next unless entry.rule_number < 32_767

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
      end
      { acl: acl.network_acl_id, missing: missing_entries, additional: additional_entries }
    end
  end
end
