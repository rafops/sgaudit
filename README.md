# AWS Security Groups Audit Tool

Reads [CloudMapper](https://github.com/duo-labs/cloudmapper) `account-data` directory and outputs a CSV file with [security groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) and its associated permissions, network interfaces, addresses, CIDR blocks, vpcs and subnets.

The CSV can be imported to a spreadsheet editor like Google Docs for a convenient auditing of security groups.

## Usage

Build `sgaudit` container:

```
./docker_build.sh
```

Run `sgaudit` specifying the path for `account-data` directory:

```
./docker_run.sh ~/cloudmapper/account-data > output.csv
```

Here's an example of output with CloudMapper's demo account-data:

|Profile|AccountId   |Region   |IpVersion|VpcId       |VpcName|VpcCidrBlocks|VpcIsDefault|SubnetId       |SubnetName|SubnetCidrBlocks|InterfaceId |InterfaceDescription                                                              |InterfaceType|InterfaceStatus|InterfaceAddresses     |InterfacePublic|GroupId    |GroupName     |GroupDescription               |IpFlow |IpProtocol|FromPort|ToPort|Cidr      |PairGroupId|PairUserId  |PrefixListId|
|-------|------------|---------|---------|------------|-------|-------------|------------|---------------|----------|----------------|------------|----------------------------------------------------------------------------------|-------------|---------------|-----------------------|---------------|-----------|--------------|-------------------------------|-------|----------|--------|------|----------|-----------|------------|------------|
|demo   |123456789012|us-east-1|         |vpc-12345678|Prod   |             |true        |subnet-00000001|Public 1a |                |eni-00000001|arn:aws:ecs:us-east-1:653711331788:attachment/ed8fed01-82d0-4bf6-86cf-fe3115c23ab8|interface    |in-use         |                       |true           |sg-00000008|Public        |Public access                  |Ingress|          |        |      |          |sg-00000002|123456789012|            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |subnet-00000001|Public 1a |10.0.0.0/24     |eni-00000001|arn:aws:ecs:us-east-1:653711331788:attachment/ed8fed01-82d0-4bf6-86cf-fe3115c23ab8|interface    |in-use         |172.31.48.168 3.80.3.41|true           |sg-00000008|Public        |Public access                  |Ingress|tcp       |443     |443   |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |subnet-00000001|Public 1a |10.0.0.0/24     |eni-00000001|arn:aws:ecs:us-east-1:653711331788:attachment/ed8fed01-82d0-4bf6-86cf-fe3115c23ab8|interface    |in-use         |172.31.48.168 3.80.3.41|true           |sg-00000008|Public        |Public access                  |Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|         |vpc-12345678|Prod   |             |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000007|Bastion access|Bastion only access            |Ingress|          |        |      |          |sg-00000002|123456789012|            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000007|Bastion access|Bastion only access            |Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|         |vpc-12345678|Prod   |             |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000006|Endpoint      |Endpoint access                |Ingress|          |        |      |          |sg-00000004|123456789012|            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000006|Endpoint      |Endpoint access                |Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|         |vpc-12345678|Prod   |             |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000005|Database      |Database                       |Ingress|          |        |      |          |sg-00000004|123456789012|            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000005|Database      |Database                       |Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|         |vpc-12345678|Prod   |             |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000004|Internal web  |Internal web                   |Ingress|          |        |      |          |sg-00000003|123456789012|            |
|demo   |123456789012|us-east-1|         |vpc-12345678|Prod   |             |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000004|Internal web  |Internal web                   |Ingress|          |        |      |          |sg-00000002|123456789012|            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000004|Internal web  |Internal web                   |Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000003|Public web    |Public web access              |Ingress|tcp       |443     |443   |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000003|Public web    |Public web access              |Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000002|Bastion       |Only allow SSH from the offices|Ingress|tcp       |22      |22    |1.1.1.1/32|           |            |            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000002|Bastion       |Only allow SSH from the offices|Ingress|tcp       |22      |22    |2.2.2.2/28|           |            |            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000002|Bastion       |Only allow SSH from the offices|Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
|demo   |123456789012|us-east-1|         |vpc-12345678|Prod   |             |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000001|default       |default VPC security group     |Ingress|          |        |      |          |sg-00000001|123456789012|            |
|demo   |123456789012|us-east-1|Ipv4     |vpc-12345678|Prod   |10.0.0.0/16  |true        |               |          |                |            |                                                                                  |             |               |                       |               |sg-00000001|default       |default VPC security group     |Egress |-1        |        |      |0.0.0.0/0 |           |            |            |
