require "find"
require "json"
require "csv"
require "tempfile"

sgs_headers = [
  "Profile",
  "AccountId",
  "Region",
  "IpVersion",
  "VpcId",
  "VpcName",
  "VpcCidrBlocks",
  "VpcIsDefault",
  "SubnetId",
  "SubnetName",
  "SubnetCidrBlocks",
  "InterfaceId",
  "InterfaceDescription",
  "InterfaceType",
  "InterfaceStatus",
  "InterfaceAddresses",
  "InterfacePublic",
  "GroupId",
  "GroupName",
  "GroupDescription",
  "IpFlow",
  "IpProtocol",
  "FromPort",
  "ToPort",
  "Cidr",
  "PairGroupId",
  "PairUserId",
  "PrefixListId"
]
sgs_output = []

Find.find(File.join(File.expand_path(File.dirname(__FILE__)), "account-data")).each do |path|
  next unless File.file? path
  sgs_path = path.match "([^\/]+)/([^\/]+)/ec2-describe-security-groups.json$"
  next unless sgs_path

  profile = sgs_path[1]
  region  = sgs_path[2]

  # VPCs
  sg_vpcs = {}
  vpc_path = File.join(File.expand_path(File.dirname(__FILE__)), "account-data", profile, region, "ec2-describe-vpcs.json")
  if File.exists?(vpc_path)
    vpc_doc = JSON.parse(File.read(vpc_path))
    vpc_doc["Vpcs"].each do |vpc|
      vpc_obj = vpc.slice("IsDefault").transform_keys(&"Vpc".method(:+))
      vpc_obj.update({
        "VpcName"           => (vpc["Tags"] || []).select { |t| t["Key"] == "Name" }.map { |t| t["Value"] }.first,
        "VpcIpv4CidrBlocks" => (vpc["CidrBlockAssociationSet"] || []).map { |b| b["CidrBlock"] }.join(" "),
        "VpcIpv6CidrBlocks" => (vpc["Ipv6CidrBlockAssociationSet"] || []).map { |b| b["Ipv6CidrBlock"] }.join(" ")
      })

      vpc_id = vpc["VpcId"]
      sg_vpcs[vpc_id] = vpc_obj
    end
  end

  # Subnets
  sg_subnets = {}
  subnet_path = File.join(File.expand_path(File.dirname(__FILE__)), "account-data", profile, region, "ec2-describe-subnets.json")
  if File.exists?(subnet_path)
    subnet_doc = JSON.parse(File.read(subnet_path))
    subnet_doc["Subnets"].each do |subnet|
      subnet_id = subnet["SubnetId"]
      subnet_obj = {
        "SubnetName"           => (subnet["Tags"] || []).select { |t| t["Key"] == "Name" }.map { |t| t["Value"] }.first,
        "SubnetIpv4CidrBlocks" => subnet["CidrBlock"],
        "SubnetIpv6CidrBlocks" => (subnet["Ipv6CidrBlockAssociationSet"] || []).map { |b| b["Ipv6CidrBlock"] }.join(" ")
      }
      sg_subnets[subnet_id] = subnet_obj
    end
  end

  # Network Interfaces
  sg_nics = {}
  nic_path = File.join(File.expand_path(File.dirname(__FILE__)), "account-data", profile, region, "ec2-describe-network-interfaces.json")
  if File.exists?(nic_path)
    nic_doc = JSON.parse(File.read(nic_path))
    nic_doc["NetworkInterfaces"].each do |nic|
      nic_obj = nic.slice("InterfaceType", "SubnetId")
      nic_obj.update(nic.slice("Description", "Status").transform_keys(&"Interface".method(:+)))
      nic_obj.update({
        "InterfaceId" => nic["NetworkInterfaceId"]
      })

      # Interface Addresses
      ipv4_addresses  = Array(nic["PrivateIpAddress"])
      ipv4_addresses << (nic["PrivateIpAddresses"] || []).map { |a| a["PrivateIpAddress"] }.join(" ")
      ipv4_public_ip  = (nic["Association"] || {})["PublicIp"]
      ipv4_addresses << ipv4_public_ip
      ipv6_addresses  = (nic["Ipv6Addresses"] || []).map { |a| a["Ipv6Address"] }
      nic_obj.update({
        "InterfaceIpv4Addresses" => ipv4_addresses.compact.uniq.join(" "),
        "InterfaceIpv6Addresses" => ipv6_addresses.compact.join(" "),
        "InterfacePublic" => !ipv4_public_ip.nil?
      })

      subnet_id = nic["SubnetId"]
      nic_obj.update(sg_subnets[subnet_id]) if sg_subnets.has_key?(subnet_id)

      nic["Groups"].each do |sg|
        sg_id = sg["GroupId"]
        sg_nics[sg_id] = nic_obj
      end
    end
  end

  # Security Groups
  sgs_doc = JSON.parse(File.read(path))
  sgs_doc["SecurityGroups"].each do |sg|
    sg_obj = sg.slice("GroupId", "GroupName", "VpcId")
    sg_obj.update({
      "Profile" => profile,
      "AccountId" => sg["OwnerId"],
      "Region" => region,
      "GroupDescription" => sg["Description"]
    })

    sg_id = sg["GroupId"]
    if sg_nics.has_key?(sg_id)
      sg_obj.update(sg_nics[sg_id])
    end

    vpc_id = sg["VpcId"]
    if sg_vpcs.has_key?(vpc_id)
      sg_obj.update(sg_vpcs[vpc_id])
    end

    {
      "Ingress" => "IpPermissions",
      "Egress"  => "IpPermissionsEgress"
    }.each do |ip_flow, sg_k|

      sg_obj.update("IpFlow" => ip_flow)
      (sg[sg_k] || []).each do |ip_permission|
        ip_obj = ip_permission.slice("IpProtocol", "FromPort", "ToPort")

        {
          "Ipv4" => "Ip",
          "Ipv6" => "Ipv6"
        }.each do |ip_version, ip_v_short|
          sg_obj.update("IpVersion" => ip_version)
          ip_permission["#{ip_v_short}Ranges"].each do |range|

            if sg_obj.has_key?("VpcId")
              sg_obj.update({
                "VpcCidrBlocks" => sg_obj["Vpc#{ip_version}CidrBlocks"]
              })
            end
            if sg_obj.has_key?("SubnetId")
              sg_obj.update({
                "SubnetCidrBlocks" => sg_obj["Subnet#{ip_version}CidrBlocks"]
              })
            end
            if sg_obj.has_key?("InterfaceId")
              sg_obj.update({
                "InterfaceAddresses" => sg_obj["Interface#{ip_version}Addresses"]
              })
            end

            sgs_output << sg_obj.merge(ip_obj.merge("Cidr" => range["Cidr#{ip_v_short}"]))
          end
        end # Ip Version

        sg_obj.update("IpVersion" => nil)
        ip_permission["UserIdGroupPairs"].each do |pair|
          sgs_output << sg_obj.merge(pair.slice("GroupId", "UserId").transform_keys(&"Pair".method(:+)))
        end
        ip_permission["PrefixListIds"].each do |prefix|
          sgs_output << sg_obj.merge(ip_obj.merge("PrefixListId" => prefix))
        end
      end

    end # Ip Flow
  end # Security Groups
end

output_file = Tempfile.new("output")
output_file.close

CSV.open(output_file.path, "wb", headers: sgs_headers, write_headers: true) do |csv|
  sgs_output.each do |sg|
    csv << sg
  end
end

puts File.read(output_file.path)
File.unlink(output_file.path)
